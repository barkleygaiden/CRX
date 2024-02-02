CRXParameterClass = CRXParameterClass or chicagoRP.NewClass()

local ParameterClass = CRXParameterClass

function ParameterClass:__constructor()
	self.IsOptional = false
	self.CanTargetMultiple = true
end

local classString = "[CRX] - Parameter [%s]: %s"
local invalidString = "[NULL]"
local enumConversions = {
	[CRX_PARAMETER_BOOL] = "BOOL",
	[CRX_PARAMETER_NUMBER] = "NUMBER",
	[CRX_PARAMETER_STRING] = "STRING",
	[CRX_PARAMETER_ENTITY] = "ENTITY",
	[CRX_PARAMETER_PROP] = "PROP",
	[CRX_PARAMETER_PLAYER] = "PLAYER"
}

function ParameterClass:__tostring()
	local typeString = enumConversions[self.Type]

	return string.format(classString, typeString or invalidString, self.Name or invalidString)
end

function ParameterClass:__eq(other)
	-- If either command doesn't have a type or name, they are not equal.
	if !self:IsValid() or !other:IsValid() then return false end

	return self:GetName() == other:GetName()
end

function ParameterClass:IsValid()
	local validType = isnumber(self.Type) and self.Type >= 1 and self.Type <= 6

	return validType and string.IsValid(self.Name)
end

function ParameterClass:Remove()
	local parameters = self.Parent:GetParameters()

	-- Removes this parameter from our parent's parameter's table.
	table.RemoveByValue(parameters, self)

	-- TODO: Does this even do what I think it does?
	setmetatable(self, nil)
end

function ParameterClass:GetName()
	return self.Name
end

function ParameterClass:SetName(name)
	if !string.IsValid(name) then return end

	-- Set the new parameter name.
	self.Name = name
end

function ParameterClass:GetParent()
	return self.Parent
end

function ParameterClass:GetDescription()
	return self.Description
end

function ParameterClass:SetDescription(description)
	-- Set the new parameter description.
	self.Description = description
end

function ParameterClass:GetType()
	return self.Type
end

function ParameterClass:SetType(typ)
	if !typ then return end

	-- Make sure the new type is a valid enum.
	if typ < 1 and typ > 6 then return end

	-- Set the new parameter type.
	self.Type = typ
end

function ParameterClass:GetDefault()
	return self.DefaultArg
end

local argTypeCheck = {
	[CRX_PARAMETER_BOOL] = function(arg)
		return isbool(arg)
	end,

	[CRX_PARAMETER_NUMBER] = function(arg)
		return isnumber(arg)
	end,

	[CRX_PARAMETER_STRING] = function(arg)
		return isstring(arg) and string.IsValid(arg)
	end
}

function ParameterClass:SetDefault(arg)
	local isValidArg = argTypeCheck[self.Type]

	-- If a valid arg is provided and it doesn't match our assigned type, return end.
	if arg and !isValidArg(arg) then return end

	-- Set the new default arg.
	self.DefaultArg = arg
end

function ParameterClass:IsOptional()
	return self.IsOptional
end

function ParameterClass:SetOptional(optional)
	if optional == nil then return end

	-- Set the new optional status.
	self.IsOptional = IsOptional
end

function ParameterClass:IsTarget()
	return self.IsTarget
end

function ParameterClass:CanTargetMultiple()
	return self.CanTargetMultiple
end

function ParameterClass:SetTargetMultiple(multiple)
	-- Set the new targeting status.
	self.CanTargetMultiple = multiple
end

local trueString = "1"
local falseString = "0"

local function BoolArgToString(arg)
	if arg == nil then return end

	return (arg and trueString) or falseString
end

local quoteChar = string.char(34)

local function StringArgToString(arg)
	if arg == nil then return end

	if string.Left(arg, 1) != quoteChar and string.Right(arg, 1) != quoteChar then return end

	return string.sub(arg, 1, -1)
end

local argToStringParsers = {
	[CRX_PARAMETER_BOOL] = BoolArgToString,
	[CRX_PARAMETER_NUMBER] = tonumber,
	[CRX_PARAMETER_STRING] = StringArgToString,
	[CRX_PARAMETER_ENTITY] = EntityArgToString,
	[CRX_PARAMETER_PROP] = EntityArgToString,
	[CRX_PARAMETER_PLAYER] = PlayerArgToString
}

function ParameterClass:ArgToString(arg)
	if !arg then return end
end

-- local hasSpaces = string.match(str, "%s") != nil

local stringToArgParsers = {
	[CRX_PARAMETER_BOOL] = "BOOL",
	[CRX_PARAMETER_NUMBER] = "NUMBER",
	[CRX_PARAMETER_STRING] = "STRING",
	[CRX_PARAMETER_ENTITY] = "ENTITY",
	[CRX_PARAMETER_PROP] = "PROP",
	[CRX_PARAMETER_PLAYER] = "PLAYER"
}

function ParameterClass:StringToArg(arg)
	if !string.IsValid(arg) then return end
end