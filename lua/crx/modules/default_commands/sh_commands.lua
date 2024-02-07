-- Creates a new category object, returns existing object if category already exists
local utilityCategory = CRX:Category("utility")

-- Creates a new command object
local kickCommand = CRX:Command("kick")
kickCommand:SetDescription("Kicks a player with the specified reason.")
kickCommand:AddParameter(CRX_PARAMETER_PLAYER, "target")

local reasonParameter = kickCommand:AddParameter(CRX_PARAMETER_STRING, "reason")
reasonParameter:SetDefault("n/a")

local reasonString = "You were kicked by %s.\nReason: %s"
local successString = "You kicked %s for Reason: %s"

function kickCommand:Callback(ply, target, reason)
	-- Format our reason string, default reason is done internally if needed.
	local formattedReason = string.format(reasonString, ply:Nick(), reason)

	target:Kick(formattedReason)

	return true, string.format(successString, ply:Nick(), reasonArg)
end

-- Add command to the category object
utilityCategory:AddCommand(kickCommand)