local PLAYER = FindMetaTable("Player")
local userString = "user"

-- TODO: Should we even use the main CRX class for this?

function PLAYER:GetUserGroup()
	return CRX:GetUser(ply) or CAMI.GetUsergroup(userString)
end

function PLAYER:SetUserGroup(group)
	if CLIENT then return false end

	CRX:SetUser(self, group)

	-- TODO: Implement database
	-- CLXDatabase:SetUserGroup
end

function PLAYER:IsUserGroup(group)
	return (self:GetUserGroup() == group)
end

local adminString = "admin"
local superAdminString = "superadmin"

function PLAYER:IsAdmin()
	local userGroup = self:GetUserGroup()

	if !string.IsValid(userGroup) then return false end
	if userGroup == superAdminString or userGroup == adminString then return true end
	if userGroup == adminString then return true end

	return false
end

function PLAYER:IsSuperAdmin()
	if self:IsUserGroup("superadmin") then return true end

	return false
end