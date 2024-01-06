local PLAYER = FindMetaTable("Player")
local userString = "user"

function PLAYER:GetUserGroup()
	return CLX:Database:GetUserGroup(self:SteamID64()) or userString
end

function PLAYER:SetUserGroup(group)
	if CLIENT then return end

	-- Check if the usergroup exists.
	if !CAMI.GetUserGroup(group) then return end

	-- Signal to CAMI that our usergroup has changed.
	CAMI.SignalUserGroupChanged(ply, ply:GetUserGroup(), group, "CRX")

	CLXDatabase:SetUserGroup(self:SteamID64(), group)
end

function PLAYER:IsUserGroup(group)
	return (self:GetUserGroup() == group)
end

local adminString = "admin"
local superAdminString = "superadmin"

function PLAYER:IsAdmin()
	local userGroup = self:GetUserGroup()

	-- Check if we are superadmin or admin.
	if userGroup == superAdminString or userGroup == adminString then return true end

	-- If we are a user, no need to check our usergroup inheritance.
	if userGroup == userString then return false end

	-- Get our usergroups inheritance.
	local inheritance = CAMI.InheritanceRoot(userGroup)

	-- Check if our usergroup is inherited from superadmin or admin.
	if string.IsValid(inheritance) and (inheritance == superAdminString or inheritance == adminString) then return true end

	return false
end

function PLAYER:IsSuperAdmin()
	if self:IsUserGroup(superAdminString) then return true end

	local userGroup = self:GetUserGroup()

	-- If we are admin or user, then no need to check our usergroup inheritance.
	if userGroup == adminString or userGroup == userString then return false end

	-- Get our usergroups inheritance.
	local inheritance = CAMI.InheritanceRoot(userGroup)

	-- Check if our usergroup is inherited from superadmin.
	if string.IsValid(inheritance) and inheritance == superAdminString then return true end

	return false
end