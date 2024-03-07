-- Creates a new category object, returns existing object if category already exists
local utilityCategory = CRX:Category("utility")

-- Creates a new command object
local kickCommand = CRX:Command("kick")
kickCommand:SetDescription("Kicks a player with the specified reason.")

local targetParameter = kickCommand:AddParameter(CRX_PARAMETER_PLAYER, "target")
reasonParameter:SetDescription("Players to ban.")

local reasonParameter = kickCommand:AddParameter(CRX_PARAMETER_STRING, "reason")
reasonParameter:SetDescription("Reason for banning the players.")
reasonParameter:SetDefault("n/a")

local reasonString = "You were kicked by %s.\nReason: %s"
local successString = "#c kicked #t for '%s'"

function kickCommand:Callback(ply, targets, reason)
	if SERVER then
		-- Format our reason string, default reason is provided internally if needed.
		local formattedReason = string.format(reasonString, ply:Nick(), reason)

		for i = 1, #targets do
			local target = targets[i]

			target:Kick(formattedReason)
		end
	end

	CRX:Notify(ply, CRX_ADMIN, successString, targets, reason)
end

-- Add command to the category object
utilityCategory:AddCommand(kickCommand)