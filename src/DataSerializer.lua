local ArgumentBuilder = script.Parent.ArgumentBuilder

local Insert = table.insert
local Concat = table.concat
local Format = string.format
local Rep = string.rep
local Sub = string.sub
local ToString = tostring
local GetType = type
local Byte = string.byte
local Dump = string.dump
local Gsub = string.gsub
local Pairs = pairs

local EscapeStringExpected = { Str = { Type = 'string'} }
local EscapeStringParseArgs = ArgumentBuilder.BuildArguments({ Expected = EscapeStringExpected, TypeCheck = true, SetDefaults = false })
local function EscapeString(...)
    local Args = EscapeStringParseArgs(...)
    local Str = Args.Str

    local Escapes = {
        ["\n"] = "\\n",
        ["\t"] = "\\t",
        ['"'] = '\\"',
        ["'"] = "\\'",
        ["\\"] = "\\\\",
        ["\r"] = "\\r",
        ["\b"] = "\\b",
        ["\f"] = "\\f",
        ["\v"] = "\\v",
        ["\a"] = "\\a",
    }
    return (Str:gsub(".", Escapes))
end

local SerializeStringExpected = { Value = { Type = "string" } }
local SerializeStringParseArgs = ArgumentBuilder.BuildArguments({ Expected = SerializeStringExpected, TypeCheck = true, SetDefaults = false })
local function SerializeString(...)
    local Args = SerializeStringParseArgs(...)
    return Format("%q", EscapeString({Str = Args.Value}))
end

local SerializeNumberExpected = { Value = { Type = "number" } }
local SerializeNumberParseArgs = ArgumentBuilder.BuildArguments({ Expected = SerializeNumberExpected, TypeCheck = true, SetDefaults = false })
local function SerializeNumber(...)
    local Args = SerializeNumberParseArgs(...)
    return ToString(Args.Value)
end

local SerializeFunctionExpected = { Value = { Type = "function" } }
local SerializeFunctionParseArgs = ArgumentBuilder.BuildArguments({ Expected = SerializeFunctionExpected, TypeCheck = true, SetDefaults = false })
local function SerializeFunction(...)
    local Args = SerializeFunctionParseArgs(...)
    return Format("loadstring(\"%s\")", Gsub(Dump(Args.Value), ".", function(k) return "\\" .. Byte(k)
end))
end

local SerializeTable
local SerializeAnyExpected = { Value = { Type = "any" }, Compress = { Type = "boolean", Value = false } }
local SerializeAnyParseArgs = ArgumentBuilder.BuildArguments({ Expected = SerializeAnyExpected, TypeCheck = true, SetDefaults = true })
local function SerializeAny(...)
    local Args = SerializeAnyParseArgs(...)
    local Value = Args.Value
    local Compress = Args.Compress

    local ValueType = GetType(Value)
    if ValueType == "string" then
        return SerializeString({ Value = Value })
    elseif ValueType == "number" then
        return SerializeNumber({ Value = Value })
    elseif ValueType == "function" then
        return SerializeFunction({ Value = Value })
    elseif ValueType == "table" then
        return SerializeTable({ Value = Value, Compress = Compress})
    else
        return ToString(Value)
    end
end

local SerializeTableExpected = { Value = { Type = "table", Value = {} }, Compress = { Type = "boolean", Value = false }, Level = { Type = "number", Value = 1 } }
local SerializeTableParseArgs = ArgumentBuilder.BuildArguments({ Expected = SerializeTableExpected, TypeCheck = true, SetDefaults = true })
SerializeTable = function(...)
    local Args = SerializeTableParseArgs(...)
    local Compress = Args.Compress
    local Level = Args.Level

    local Result = { Compress and '{' or '{\n' }
    for i, v in Pairs(Args.Value) do
        local Type = GetType(v)
        if Type ~= "table" then
            if Compress then
                Insert(Result, Format('[%s]=%s,', SerializeAny({Value = i}) or '', SerializeAny({Value = v})))
            else
                Insert(Result, Format('%s[%s] = %s,\n', Rep("\t", Level), SerializeAny({Value = i}) or '', SerializeAny({Value = v})))
            end
        else
            if Compress then
                Insert(Result, Format('[%s]=%s,', SerializeAny({Value = i}) or '', SerializeTable({Value = v, Level = Level + 1, Compress = Compress})))
            else
                Insert(Result, Format('%s[%s] = %s,\n', Rep("\t", Level), SerializeAny({Value = i}), SerializeTable({Value = v, Level = Level + 1})))
            end
        end
    end

    if Compress then
        Result[#Result] = Sub(Result[#Result], 1, -2)
        Insert(Result, '}')
		Result = Concat(Result)
    else
        Result = Concat(Result)
        Result = Format("%s\n%s}", Sub(Result, 0, #Result - 2), Rep("\t", Level - 1))
    end

    return Result
end

return {
    SerializeString = SerializeString,
    SerializeNumber = SerializeNumber,
    SerializeFunction = SerializeFunction,
    SerializeTable = SerializeTable,
    SerializeAny = SerializeAny,
}