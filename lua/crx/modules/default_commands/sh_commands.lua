-- Creates a new category object, returns existing object if category already exists
local utilityCategory = CRX:Category("utility")

-- Creates a new command object
local kickCommand = CRX:Command("kick")
kickCommand:AddParameter(CRX_PARAMETER_PLAYER, "target")
kickCommand:AddParameter(CRX_PARAMETER_STRING, "reason")

local noneString = "n/a"
local reasonString = "You were kicked by %s.\nReason: %s"
local successString = "You kicked %s for Reason: %s"
local invalidTargetString = "Kick failed, target invalid."

function kickCommand:Callback(ply, ...)
	local args = {...}
	local target = args[1]

	if !IsValid(target) then return false, invalidTargetString end

	-- Set reason as n/a if none is provided, insert arg otherwise
	local reasonArg = (string.IsValid(args[2]) and args[2]) or noneString
	local reason = string.format(reasonString, ply:Nick(), reasonArg)

	target:Kick(reason)

	return true, string.format(successString, ply:Nick(), reasonArg)
end

-- Add command to the category object
utilityCategory:AddCommand(kickCommand)