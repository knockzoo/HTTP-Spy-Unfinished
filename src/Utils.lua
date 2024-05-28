local ArgumentBuilder = require(script.Parent.ArgumentBuilder)
local Bit, Random = require(script.Parent.Bit), require(script.Parent.Random)
local Gsub, Format, Upper, Lower, Match = clonefunction(string.gsub), clonefunction(string.format), clonefunction(string.upper), clonefunction(string.lower), clonefunction(string.match)

local MaliciousUrls = {
    "ipify.org",
    "api.ipify.org",
    "httpbin.org",
    "discord.com/api",
    "webhook.lewisakura.moe/api",
    "hooks.hyra.io",
    "ip-api.com",
    "ipinfo.io",
    "ipapi.co",
    "seeip.org"
}

local Utils = {}
local JSON = {}

local GetMT = clonefunction(getrawmetatable)

local Services = setmetatable({}, {
	__index = function(self, index)
		return game:GetService(index)
	end,
})

local HTTP = Services.HttpService

function JSON:Encode(Table)
	return HTTP:JSONEncode(Table)
end

function JSON:Decode(Table)
	return HTTP:JSONDecode(Table)
end

local HiddenGC = {}

function Utils:Remove(Table, Index)
    if Index == nil then
        Index = #Table
    end
    local Result = Table[Index]
    for i = Index, #Table - 1 do
        Table[i] = Table[i + 1]
    end
    Table[#Table] = nil
    return Result
end

local IsOurClosure = clonefunction(isexecutorclosure or isourclosure)
local GetConstants = clonefunction(debug.getconstants) -- Unlike the GetConstants in Main, this will be called long after execution - so it needs to remain unhooked
local Pcall = clonefunction(pcall)
local Tostring = clonefunction(tostring)

local OldGC = clonefunction(getgc)
OldGC = hookfunction(getgc, function(...)
    local Result = OldGC(...)
    Result = Utils:CloneTable(Result)

    for i,v in pairs(Result) do -- Technically you could hook pairs and do a hard coded EQ against what you predict to be in the garbage collector (force known values to be garbage collected) to ultimately see if the GC results are being ran through pairs - but too many scripts do this so it'd be unreliable in a WL, it'd only work as a POC
        if HiddenGC[v] then
            Utils:Remove(Result, i)
        else -- You can take what anti HTTP spies do when looking through the garbage collector, apply the exact same logic, and just remove the objects LOL
            if type(v) == 'function' then
                if IsOurClosure(v) then
                    local Success, Constants = Pcall(GetConstants, v)
                    if Success then
                        setmetatable(Constants, { -- Just to prevent anyone defining a function with an L closure and embeding specific constants, so they can check if those constants are showing up in the garbage collector more then expected
                            __mode = "kv"
                        })

                        local ConstantIndex = 0
                        local HookCount = 0
                        while true do
                            ConstantIndex = ConstantIndex + 1
                            if ConstantIndex == #Constants then
                                break
                            end

                            local AsString = Tostring(Constants[ConstantIndex])

                            if AsString == 'hookfunction' or AsString == 'hookmetamethod' then -- I still don't know why anti HTTP spies do this, it's so unreliable
                                HookCount = HookCount + 1

                                if HookCount > 2 then
                                    Utils:Remove(Result, i) -- Censorship!!
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return Result
end)

function Utils:HideFromGC(Object)
    HiddenGC[Object] = true
end

function Utils:UnhideFromGC(Object) -- Not really used anywhere, just added for funsies
    HiddenGC[Object] = nil
end

function Utils:BulkHide(Objects)
    Utils:HideFromGC(Objects)
    for i,v in pairs(Objects) do
        Utils:HideFromGC(v)
        if type(v) == 'table' then
            Utils:BulkHide(v)
        end
    end
end

local HiddenMT = {}

function Utils:HideMetatable(Object)
    HiddenMT[#HiddenMT + 1] = Object
    return Object
end

local OldGetMT = clonefunction(getmetatable)
OldGetMT = hookfunction(getmetatable, newcclosure(function(...)
    local Success, Result = Pcall(OldGetMT, ...)
    Utils:HideFromGC(Result)
    if Success then
        local AsTable = (...)
        Utils:HideFromGC(AsTable)

        if HiddenMT[AsTable] then
            return nil
        end
    end

    return Result
end))

local SetMetatable = clonefunction(setmetatable)

local OldTraceback = clonefunction(debug.gettraceback)
OldTraceback = hookfunction(debug.traceback, newcclosure(function(...)
    local RealTraceback = OldTraceback(...) - 1

    local Metatable = Utils:HideMetatable({}, {
        __eq = function(self, Other)
            if RealTraceback > Other then
                if RealTraceback - Other < 2 then -- The request hook can add an extra traceback level, so anything like 'SuperRequest' could very easily detect this HTTP spy, unless the traceback info is smartly hooked
                    return true
                end
            end

            return false
        end,
        __metatable = nil
    })

    Utils:HideFromGC(Metatable)
    return Metatable
end))

local CloneTableArgs = ArgumentBuilder.BuildArguments({
    Expected = { Table = { Type = "table" }, Method = { Type = "number" }, Cloned = { Type = "table" } },
    TypeCheck = true,
    SetDefaults = true
})

function Utils:CloneTable(...)
    local Args = CloneTableArgs(...)
    local Table, Method, Cloned = Args.Table, Args.Method, Args.Cloned

    local MT = GetMT(Table)
    if Method == 1 then -- most definitely getting detected the moment this goes public
        return JSON:Decode(JSON:Encode(Table)) -- kinda surprised i hadnt thought of this earlier, pretty straight forward
    elseif Method == 2 then -- actually worked on UWP based executors, not sure how this bug even worked but it did | patched in krampus
        local idkwhythisworksLOL = setmetatable({}, { __add = function(self, other) return other end })
        Table = Table + idkwhythisworksLOL

        Utils:HideFromGC(idkwhythisworksLOL)
        Utils:HideMetatable(idkwhythisworksLOL)

        for i, v in next, Table, nil do
            if type(v) == "table" then
                Cloned[i] = Utils:CloneTable(v)
            else
                Cloned[i] = v
            end
        end

        return Cloned
    end
end

function Utils:GenerateIP() -- thanks chatgpt
    local startipdec = 0
    local endipdec = 4294967295

    local randomipdec = Random.int(startipdec, endipdec)

    local a = Bit.rshift(Bit.band(randomipdec, 0xFF000000), 24)
    local b = Bit.rshift(Bit.band(randomipdec, 0x00FF0000), 16)
    local c = Bit.rshift(Bit.band(randomipdec, 0x0000FF00), 8)
    local d = Bit.band(randomipdec, 0x000000FF)

    return Format("%d.%d.%d.%d", a, b, c, d)
end

function Utils:GenerateHWID() -- thanks chatgpt
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return Upper(Gsub(template, '[xy]', function(c)
        local v = (c == 'x') and Random.int(0, 15) or Random.int(8, 11)
        return Format('%x', v)
    end))
end

local FakeIP, FakeHWID = Utils:GenerateIP(), Utils:GenerateHWID()
local ActualHWID, ActualIP = Services.RbxAnalyticsService:GetClientId(), game:HttpGet("https://api.ipify.org/")

local SanitizeArgs = ArgumentBuilder.BuildArguments({
    Expected = { String = { Type = "string" }, IP = { Type = "bool" }, HWID = { Type = "bool" } },
    TypeCheck = true,
    SetDefaults = false
})

function Utils:Sanitize(...)
    local Args = SanitizeArgs(...)
    return Gsub(Gsub(Args.String, Args.IP and ActualIP or "", FakeIP, 1000), Args.HWID and ActualHWID or "", FakeHWID, 1000)
end

function Utils:MaliciousSearch(String)
    String = Lower(String)

    if Match(String, ActualIP) or Match(String, FakeIP) then
        return true
    end

    for i,v in pairs(MaliciousUrls) do
        if Match(String, v) then
            return true
        end
    end

    return false
end

Utils:BulkHide({Utils, JSON, Hidden, Services, HTTP, OldGC, GetMT, HiddenMT, OldTraceback, MaliciousUrls, FakeIP, FakeHWID, ActualIP, ActualHWID})
return { Utils = Utils, JSON = JSON, Services = Services }