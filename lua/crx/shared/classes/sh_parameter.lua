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

	-- If the string is quoted, we don't need to add quotes.
	if string.Left(arg, 1) == quoteChar and string.Right(arg, 1) == quoteChar then return arg end

	return string.concat(quoteChar, arg, quoteChar)
end

local argString = "(%i)"
local insertionString = ",%i"

local function EntityArgToString(arg)
	if !arg then return end

	local argString = ""
	local pairsFunc = (arg[1] and ipairs) or pairs

	for _, ent in pairsFunc(arg) do
		if !IsValid(ent) then return end

		-- UserID takes up less space than the index of an entity and is more reliable.
		local entID = (ent:IsPlayer() and ent:UserID()) or ent:EntIndex()

		-- Next returns the next key in memory, nil if we are on the last key.
		local isLastEnt = next(arg) == nil

		-- Insert the entity ID into the string, and insert a comma along with a integer format % if this is not the last entity.
		string.format(argString, entID, !isLastEnt and insertionString)
	end

	return argString
end

local argToStringParsers = {
	[CRX_PARAMETER_BOOL] = BoolArgToString,
	[CRX_PARAMETER_NUMBER] = tostring,
	[CRX_PARAMETER_STRING] = StringArgToString,
	[CRX_PARAMETER_ENTITY] = EntityArgToString,
	[CRX_PARAMETER_PROP] = EntityArgToString,
	[CRX_PARAMETER_PLAYER] = EntityArgToString
}

function ParameterClass:ArgToString(arg)
	if !arg then return end

	local argParser = argToStringParsers[self.Type]

	return argParser(arg)
end

local trueBoolString = "true"
local trueNumberString = "1"
local falseBoolString = "false"
local falseNumberString = "0"

local function BoolStringToArg(str)
	if !str then return end

	local isTrue = (trueBoolString or trueNumberString) and true
	local isFalse = (falseBoolString or falseNumberString) and false

	return isTrue or isFalse
end

local leftParenthesis = "("
local rightParenthesis = ")"

local function ProcessEntityTable(str)
	if string.sub(str, 1, 1) != leftParenthesis or string.sub(str, -1) != rightParenthesis then return end

	local entities = {}
	local splitIDs = string.Split(string.sub(str, 1, -1), ",")

	for i = 1, #splitIDs do
		local entID = tonumber(splitIDs[i])
		local ent = (self.Type == CRX_PARAMETER_PLAYER and Player(entID)) or Entity(entID)

		if !IsValid(ent) then return end

		table.insert(entities, ent)
	end

	return entities
end

local function ProcessEntityTargeter(str)
end

local function ProcessEntityName(str)
	local players = {}
	local hasSpaces = string.match(str, "%s") != nil

	for i, ply in player.Iterator() do
		local plyName = ply:Nick()

		-- If the search term has a space in it, it's a quoted string that must be exact same as the player's name.
		if hasSpaces and str != plyName then continue end

		-- Otherwise, if the search term doesn't have a space in it, select every player with the word in their name.
		if !hasSpaces and !string.find(plyName, str) then continue end

		table.insert(players, ply)
	end

	return players
end

local function EntityStringToArg(str)
	if !str then return end

	local firstChar = string.sub(str, 1, 1)

	-- If the string uses parenthesis syntax, it must be a table.
	if firstChar == leftParenthesis then return ProcessEntityTable(str) end

	-- If the string uses any special characters, it must be using targeting syntax.
	if string.match(firstChar, "[@^*$#%!]") then return ProcessEntityTargeter(str) end

	-- Otherwise, the string is just a player name or a search operator.
	return ProcessEntityName(str)
end

local stringToArgParsers = {
	[CRX_PARAMETER_BOOL] = BoolStringToArg,
	[CRX_PARAMETER_NUMBER] = tonumber,
	[CRX_PARAMETER_STRING] = function(str) return str end,
	[CRX_PARAMETER_ENTITY] = EntityStringToArg,
	[CRX_PARAMETER_PROP] = EntityStringToArg,
	[CRX_PARAMETER_PLAYER] = EntityStringToArg
}

function ParameterClass:StringToArg(arg)
	if !string.IsValid(arg) then return end

	local stringParser = stringToArgParsers[self.Type]

	return stringParser(arg)
end