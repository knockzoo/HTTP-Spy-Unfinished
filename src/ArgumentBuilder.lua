local type = type
local pairs = pairs
local error = error

local function MissingArg(Object)
	return error(string.format("[MissingArg] missing argument: '%s' (%s)", Object.Name, Object.Type))
end

local function UnexpectedArg(Type, Value)
	return error(string.format("[UnexpectedArg] unexpected argument: '%s' (%s)", Type, Value))
end

local function IncorrectType(Object, Type)
	return error(string.format("[IncorrectType] incorrect argument: '%s' (%s), received: '%s'", Object.Name, Object.Type, Type))
end

local TypeToValueIndex = {
	table = {},
	string = "",
	number = 1,
	["function"] = function() end,
	["nil"] = nil,
}

local function Cleanse(Value, Object, ForceType)
	if Object.Type ~= type(Value) then
		if Object.Type == "any" then
			return Value
		end

		if ForceType then
			Value = TypeToValueIndex[Object.Type]
		else
			return IncorrectType(Object, type(Value))
		end
	end

	return Value
end

local function BuildArgument(Name, Type, Value)
	Value = Value or TypeToValueIndex[Type]

	local Object = {
		Default = Value,
		Name = Name,
		Type = Type,
	}

	return Object
end

local function BuildArguments(Options)
	if not Options.Expected then
		return error("expected arguments not provided")
	end

	Options.TypeCheck = Options.TypeCheck ~= false
	Options.SetDefaults = Options.SetDefaults or false
	Options.ForceType = Options.ForceType or false

	return function(...)
		local AsTab = ...

		if type(AsTab) ~= "table" then
			return error("invalid top level argument: expected table")
		end

		local CleansedArguments = {}

		if Options.TypeCheck then
			for i, v in pairs(Options.Expected) do
				local ReceivedArg = AsTab[i]

				if not ReceivedArg then
					if Options.SetDefaults then
						AsTab[i] = v.Value
					else
						return MissingArg(v)
					end
				end
			end

			for i, v in pairs(AsTab) do
				local ExpectedObj = Options.Expected[i]
				if not ExpectedObj then
					return UnexpectedArg(i, v)
				end

				if Options.TypeCheck then
					CleansedArguments[i] = Cleanse(v, ExpectedObj, Options.ForceType)
				else
					CleansedArguments[i] = v
				end
			end
		end

		return CleansedArguments
	end
end

return {
	BuildArgument = BuildArgument,
	BuildArguments = BuildArguments,
	Cleanse = Cleanse,
	MissingArg = MissingArg,
	UnexpectedArg = UnexpectedArg,
	IncorrectType = IncorrectType,
	TypeToValueIndex = TypeToValueIndex,
}
