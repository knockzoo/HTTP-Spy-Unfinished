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

-- Designed with Ro-Exec (Krampus) in mind for
-- both the bypasses, and the hooks themselves

-- This is a WIP, and is not finished - yet.
-- Use any source code used in this project
-- or it's methods at your own discretion.

local RequestArgs = ArgumentBuilder.BuildArguments({
    Expected = { Url = { Type = "string" }, Method = { Type = "string" }, Body = { Type = "string" }, Headers = { Type = "table" }},
    TypeCheck = true,
    SetDefaults = false
})

local RequestHook = function(Old, Options) -- Krampus pushed an update which made it pretty easy to detect hooks unless you use matching parameters
    -- Will require doing more in-depth analysis to get more accurate debug information
    -- As of now, with a few careful `pcall` checks you can easily detect this hook by comparing errors

    local NewOptions = Utils:CloneTable({Table = Options, Method = 1})

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

for i,v in pairs(Settings.Hook) do
    local Old = v
    Old = hookfunction(v, newcclosure(function(...)
        return RequestHook(Old, ...)
    end))
end

