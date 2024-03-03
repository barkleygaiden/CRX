CRXParameterClass = {}
CRXParameterClass.__index = CRXParameterClass

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
	[CRX_PARAMETER_PLAYER] = "PLAYER"
}

function ParameterClass:__tostring()
	local typeString = enumConversions[self.Type]

	return string.format(classString, typeString or invalidString, self.Name or invalidString)
end

function ParameterClass:__eq(other)
	-- If either command lacks a type or name, they are not equal.
	if !self:IsValid() or !other:IsValid() then return false end

	return self.Name == other:GetName() and self.Type == other:GetType()
end

function ParameterClass:IsValid()
	local validType = isnumber(self.Type) and self.Type >= 1 and self.Type <= 4

	return validType and string.IsValid(self.Name)
end

function ParameterClass:New()
	local newParameter = setmetatable({}, self)

	return newParameter
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

local argFormatString = "(%i)"
local insertionString = ",%i"

local function PlayerArgToString(arg)
	if !arg then return end

	local argString = ""
	local pairsFunc = (arg[1] and ipairs) or pairs

	for _, ply in pairsFunc(arg) do
		if !IsValid(ply) then return end

		-- UserID takes up less space than :EntIndex() and is more reliable.
		local userID = ply:UserID()

		-- Next returns the next key in memory, nil if we are on the last key.
		local isLastEnt = next(arg) == nil

		-- Insert the player ID into the string, and insert a comma along with a integer format % if this is not the last player.
		argString = string.format(argFormatString, userID, !isLastEnt and insertionString)
	end

	return argString
end

local argToStringParsers = {
	[CRX_PARAMETER_BOOL] = BoolArgToString,
	[CRX_PARAMETER_NUMBER] = tostring,
	[CRX_PARAMETER_STRING] = StringArgToString,
	[CRX_PARAMETER_PLAYER] = PlayerArgToString
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

	local isTrue = (str == trueBoolString or str == trueNumberString) and true
	local isFalse = (str == falseBoolString or str == falseNumberString) and false

	return isTrue or isFalse
end

-- TODO: Add IP address support?
-- local isIPAddress = string.match(str, "%d") != nil

local function GetPlayerFromID(str)
	local isSteamID = string.sub(str, 1, 6) == "STEAM_"
	local isSteamID64 = #str == 17

	if isSteamID or isSteamID64 then
		str = (isSteamID64 and str) or util.SteamIDTo64(str)

		return chicagoRP.GetPlayerBySteamID64(str)
	else
		local userID = tonumber(str)

		return Player(userID)
	end
end

local function ProcessPlayerTable(str)
	local players = {}
	local splitTerms = string.Split(string.sub(str, 1, -1), ",")

	for i = 1, #splitTerms do
		local userID = splitTerms[i]
		local ply = GetPlayerFromID(userID)

		if !IsValid(ply) then return end

		table.insert(players, ply)
	end

	return players
end

local function GetPlayerFromTrace(caller)
	local eyePos = caller:EyePos()

	local tr = util.TraceLine({
		start = eyePos,
		endpos = eyePos + caller:EyeAngles():Forward() * 10000
	})

	return IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity
end

-- ^ - yourself
-- * - everyone
-- @ - player in front of you
-- #<group> - target by group
-- %<group> - target by group (inheritance counts)
local selfKeyword = "^"
local everyoneKeyword = "*"
local frontKeyword = "@"
local groupKeyword = "#"
local groupInheritanceKeyword = "%"
local negationKeyword = "!"

local function ProcessPlayerTargeter(str, caller)
	local players = {}
	local oppositePlayers = {}
	local firstChar, secondChar = string.sub(str, 1, 1), string.sub(str, 2, 2)
	local mainKeyword = (string.IsValid(secondChar) and secondChar) or firstChar

	-- Get the player in front of the caller (self) if they exist.
	local tracePly = (mainKeyword == frontKeyword and GetPlayerFromTrace(caller)) or nil

	-- Subtract any keywords from the provided string in order to get the provided usergroup (if present).
	local targetedGroup = string.gsub(str, "[!#]")

	for i, ply in player.Iterator() do
		local passedArg = false

		-- If the player is the caller (self), insert them.
		if mainKeyword == selfKeyword and caller == ply then
			passedArg = true
		-- Insert every player.
		elseif mainKeyword == everyoneKeyword then
			passedArg = true
		-- If the player is in front of the caller (self), insert them.
		elseif tracePly and tracePly == ply then
			passedArg = true
		-- If the player is in the provided usergroup, insert them.
		elseif mainKeyword == groupKeyword then
			local userGroup = ply:GetUserGroup()

			passedArg = userGroup == targetedGroup
		-- If the player is in the provided usergroup or is in a usergroup that inherits from it, insert them.
		elseif mainKeyword == groupKeyword then
			local userGroup = ply:GetUserGroup()
			local inheritor = CAMI.UsergroupInherits(userGroup, targetedGroup)

			passedArg = userGroup == targetedGroup or inheritor
		end

		-- If the player is included in the main keyword, insert them into the primary table.
		if passedArg then
			table.insert(players, ply)
		-- Otherwise, insert them into the opposite table.
		else
			table.insert(oppositePlayers, ply)
		end
	end

	-- Negation keyword present, so return the opposite player table.
	if firstChar == negationKeyword then
		return oppositePlayers
	end
		
	return players
end

local function ProcessPlayerName(str)
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

local leftParenthesis = "("

local function PlayerStringToArg(str)
	if !str then return end

	local firstChar = string.sub(str, 1, 1)

	-- If our string uses parenthesis syntax, remove the parenthesis from the string.
	if firstChar == leftParenthesis then
		str = string.sub(str, 2, -2)
	end

	-- If the string uses parenthesis syntax, it must be a table.
	if firstChar == leftParenthesis then return ProcessPlayerTable(str) end

	-- If the string uses any special characters, it must be using targeting syntax.
	if string.match(firstChar, "[@^*$#%!]") then return ProcessPlayerTargeter(str) end

	-- Otherwise, the string is just a player name or a search operator.
	return ProcessPlayerName(str)
end

local stringToArgParsers = {
	[CRX_PARAMETER_BOOL] = BoolStringToArg,
	[CRX_PARAMETER_NUMBER] = tonumber,
	[CRX_PARAMETER_STRING] = function(str) return str end,
	[CRX_PARAMETER_PLAYER] = PlayerStringToArg
}

function ParameterClass:StringToArg(arg, caller)
	if !string.IsValid(arg) then return end

	local stringParser = stringToArgParsers[self.Type]

	return stringParser(arg, caller)
end

local boolError = "'boolean' expected for argument index '%i'."
local numberError = "'number' expected for argument index '%i'."
local targetKeywordError = "valid 'target' keyword expected for argument index '%i'."

function ParameterClass:IsStringArgValid(argstr, caller)
	local isValid = true

	-- If the arg is empty, the arg is invalid.
	if !string.IsValid(argstr) then
		isValid = false
	-- If the string is supposed to be a boolean and is not true/false or 0/1, the arg is invalid.
	elseif parameterType == CRX_PARAMETER_BOOL and !(
		argString == trueBoolString or
		argString == trueNumberString or
		argString == falseBoolString or
		argString == falseNumberString) then

		isValid = false
		errorMessage = string.format(boolError, i)
	-- If the string has any non-numerical or non-digit characters, the arg is invalid.
	elseif parameterType == CRX_PARAMETER_NUMBER and string.match(argString, "[^%d%.]") then
		isValid = false
		errorMessage = string.format(numberError, i)
	elseif parameterType == CRX_PARAMETER_PLAYER then
		local firstChar, secondChar = string.sub(str, 1, 1), string.sub(str, 2, -2)

		-- If we're trying to select the caller (self) and they aren't valid, the arg is invalid.
		local selectedNil = (firstChar == selfKeyword or secondChar == selfKeyword) and !IsValid(caller)

		-- If we're trying to select everyone and negate it, the arg is invalid because that selects nobody.
		local selectedNobody = secondChar and (firstChar == negationKeyword and secondChar == everyoneKeyword)

		-- If we're trying to select the caller (self) and they aren't valid, the arg is invalid.
		if (firstChar == negationKeyword and !secondChar) or
			selectedNil or selectedNobody or
			-- If we're trying to select the player in front of the caller (self) and they aren't valid, the arg is invalid.
			(firstChar == frontKeyword and !IsValid(GetPlayerFromTrace(caller))) then

			isValid = false
			errorMessage = string.format(targetKeywordError, i)
		end
	end

	-- If the provided arg string is invalid and there's no fallback, return false.
	if !isValid and !(parameter:GetDefault() or parameter:IsOptional()) then
		return false, errorMessage
	end

	return true
end

setmetatable(ParameterClass, {
	__call = function(tbl, ...)
		local newParameter = ParameterClass:New(...)

		if newParameter.__constructor then
			newParameter:__constructor(...)
		end

		return newParameter
	end
})