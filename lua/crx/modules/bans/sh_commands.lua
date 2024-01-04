local kickCommand = CRXCommand:New()
kickCommand:SetName("kick")
kickCommand:AddParam(CRX_PARAM_PLAYER, "target")
kickCommand:AddParam(CRX_PARAM_STRING, "reason")
kickCommand:SetDefaultPermissions(CRX_SUPERADMIN)

local noneString = "n/a"
local kickedString = "You were kicked by %s.\nReason: %s"
local invalidTargetString = "Kick failed, target invalid."

function kickCommand:Callback(ply, ...)
	local args = {...}
	local target = args[1]

	if !IsValid(target) then return false, invalidTargetString end

	-- Set reason as n/a if none is provided, insert arg otherwise
	local reason = string.format(kickedString, ply:Nick(), (string.IsValid(args[2]) and args[2]) or noneString)

	target:Kick(reason)

	return true
end