local Utils = require(script.Parent.Utils)
local DataSerializer = require(script.Parent.DataSerializer)
local Random = require(script.Parent.Random)
local ArgumentBuilder = require(script.Parent.ArgumentBuilder)

local Utils, JSON = Utils.Utils, Utils.JSON

local Settings = getfenv().Settings or {
    SpoofIP = true,
    SpoofHWID = true,
    BlockFlagged = false,
    BlockMessage = "Blocked",
    Proxy = {
        Enabled = false,
        EndPoint = "https://httpspy.iplogging.lol/api/proxy",
        Build = function(EndPoint, OriginalArguments)
            return {
                Url = EndPoint,
                Method = "POST",
                Body = JSON:Encode(OriginalArguments),
                Headers = {
                    ["Content-Type"] = "application/json"
                }
            }
        end
    },
    Hook = {
        request
    }
}

Utils:HideFromGC(Settings)

-- Designed with Ro-Exec (Krampus) in mind for | Nevermind, fuck you krampus
-- both the bypasses, and the hooks themselves

-- This is a WIP, and is not finished - yet.
-- Use any source code used in this project
-- or it's methods at your own discretion.

-- Debug info based bypasses

local OldDebugInfo = {}
local GetConstants, GetUpvalues, GetProtos, GetInfo = debug.getconstants, debug.getupvalues, debug.getprotos, debug.getinfo
--[[
    Structure:
        OldDebugInfo[func] = {
            Constants = {

            },
            Upvalues = {

            },
            Protos = {

            },
            Info = {

            }
        }
]]--

local DebugHook = function(Type, Old, Function, ...) -- Type: Constants/Upvalues/Info, Old: The original function, Function: Every debug function being hooked here expects a function as the first parameter
    assert(Function, "i actually need to put proper debug info here at some point")

    local SpoofedValue = OldDebugInfo[Function]
    if SpoofedValue then
        return SpoofedValue[Type]
    end

    return Old(Function, ...)
end

local OldGetConstants
OldGetConstants = hookfunction(GetConstants, newcclosure(function(Function, ...)
    return DebugHook("Constants", OldGetConstants, Function, ...)
end))

local OldGetUpvalues
OldGetUpvalues = hookfunction(GetUpvalues, newcclosure(function(Function, ...)
    return DebugHook("Upvalues", OldGetUpvalues, Function, ...)
end))

local OldGetProtos
OldGetProtos = hookfunction(GetProtos, newcclosure(function(Function, ...)
    return DebugHook("Protos", OldGetProtos, Function, ...)
end))

local OldGetInfo
OldGetInfo = hookfunction(GetInfo, newcclosure(function(Function, ...) -- I don't actually remember if getinfo's response is dynamic and based off of the environment/level it was called from, but cba to check
    return DebugHook("Info", OldGetInfo, Function, ...)
end))

Utils:BulkHide({OldDebugInfo, GetConstants, GetUpvalues, GetInfo, DebugHook, OldGetConstants, OldGetUpvalues, GetProtos, OldGetInfo}) -- Some inferior anti HTTP spies will look for debug usage in the garbage collector

for Index, Function in pairs(Settings.Hook) do
    local Constants, Upvalues, Protos, Info = GetConstants(Function), GetUpvalues(Function), GetProtos(Function), GetInfo(Function) -- Since these are only getting called once and they're getting called immediately, there's no point in using clonefunction
    
    OldDebugInfo[Function] = {
        Constants = Constants,
        Upvalues = Upvalues,
        Protos = Protos,
        Info = Info
    }

    Utils:BulkHide({Constants, Upvalues, Protos, Info})
end

-- Environment based bypasses
-- Misleading, I only have one :(

local OldGetFenv
OldGetFenv = hookfunction(getfenv, newcclosure(function(Level)
    local Result = OldGetFenv(Level)

    if Level == 0 then
        local New = Utils:CloneTable(Result)

        if New.script then
            New.Script:SetAttribute('name', 'LocalScript') -- on UWP executors, getfenv(0).script.name always returned 'LocalScript' - so I don't actually know if this still works, of if SetAttribute functions like I think it does bug GG regardless, this is a cool method
        end
    end
end))

-- Actual request hooking

local RequestArgs = ArgumentBuilder.BuildArguments({
    Expected = { Url = { Type = "string" }, Method = { Type = "string" }, Body = { Type = "string" }, Headers = { Type = "table" }},
    TypeCheck = true,
    SetDefaults = false
})

local RequestHook = function(Old, Options) -- Krampus pushed an update which made it pretty easy to detect hooks unless you use matching parameters
    -- Will require doing more in-depth analysis to get more accurate debug information
    -- As of now, with a few careful `pcall` checks you can easily detect this hook by comparing errors

    local NewOptions = Utils:CloneTable({Table = Options, Method = 1})
    setmetatable(NewOptions, {
        __mode = "kv" -- Extra layer of UD
    })

    local Args = RequestArgs(NewOptions)
    Utils:HideFromGC(Args)

    if Settings.Proxy.Enabled then
        Args = Settings.Proxy.Build(Settings.Proxy.EndPoint, Args)
    end

    local URL = Args.Url
    local Method = Args.Method or "GET"
    local Body = Args.Body or ""
    local Headers = Args.Headers or {}

    if Settings.SpoofIP or Settings.SpoofHWID then
        URL = Utils:Sanitize(URL, Settings.SpoofIP, Settings.SpoofHWID)
        Body = Utils:Sanitize(Body, Settings.SpoofIP, Settings.SpoofHWID)
    end

    local Flagged = Utils:MaliciousSearch(URL) or Utils:MaliciousSearch(Body)

    if Settings.BlockFlagged and Flagged then
        return { StatusCode = 403, Body = Settings.BlockMessage }
    end

    NewOptions.Url = URL
    NewOptions.Method = Method
    NewOptions.Body = Body
    NewOptions.Headers = Headers

    local Result = Old(NewOptions)

    if Result.Body then
        Result.Body = Utils:Sanitize(Result.Body, Settings.SpoofIP, Settings.SpoofHWID)
    end

    local Sent = DataSerializer.SerializeTable(NewOptions)
    local Received = DataSerializer.SerializeTable(Result)

    Utils:BulkHide({NewOptions, URL, Method, Body, Headers, Result, Sent, Received})

    print("Request made to", URL, "with method", Method, "and body", Body, "and headers", Headers, "and received", Result)

    return Result
end

Utils:HideFromGC(RequestHook)

for i,v in pairs(Settings.Hook) do
    local Old = v
    Old = hookfunction(v, newcclosure(function(...)
        return RequestHook(Old, ...)
    end))
end

