CRXDatabaseClass = CRXDatabaseClass or CRX:NewClass()

local DatabaseClass = CRXDatabaseClass

function DatabaseClass:__constructor()
	self.Valid = false
end

local createGroupTableQuery = "CREATE TABLE IF NOT EXISTS 'CRX_Groups' ('Group' VARCHAR(48) PRIMARY KEY, 'Inheritance' VARCHAR(48))"
local createUserTableQuery = "CREATE TABLE IF NOT EXISTS 'CRX_Users' ('SteamID' VARCHAR(18) PRIMARY KEY, 'Group' VARCHAR(48))"
local createIndexQuery = "CREATE INDEX IF NOT EXISTS 'CRX_Users' ON 'CRX_Users' ('Group')"

function DatabaseClass:Initialize()
    sql.Begin()
    sql.Query(createGroupTableQuery)
    sql.Query(createUserTableQuery)
    sql.Query(createIndexQuery)
    sql.Commit()

	self.Valid = true
end

local classString = "[CRX] - Database Class"

function DatabaseClass:__tostring()
	return classString
end

function DatabaseClass:IsValid()
	return self.Valid
end

local userString = "user"
local getUserGroupQuery = "SELECT 'Group' FROM 'CRX_Users' WHERE 'SteamID'='%s'"

function DatabaseClass:GetUserGroup(steamid)
	if !string.IsValid(steamid) then return end

	steamid = (string.IsValid(steamid) and steamid) or (IsValid(steamid) and steamid:SteamID64())

	local query = string.format(getUserGroupQuery, steamid)

	sql.Begin()
	local userGroup = sql.Query(query)
	sql.Commit()

	return userGroup[1]
end

local setUserGroupQuery = "INSERT OR REPLACE INTO 'CRX_Users'('SteamID', 'Group') VALUES('%s', '%s')"

function DatabaseClass:SetUserGroup(steamid, group)
	if !string.IsValid(steamid) or !string.IsValid(group) then return end

	-- Get SteamID64 if the provided arg is not a string.
	steamid = (string.IsValid(steamid) and steamid) or (IsValid(steamid) and steamid:SteamID64())

	-- Return if the usergroup doesn't exist.
	if !CAMI.GetUserGroup(group) then return end

	net.Start("CLXNetworkUserGroup")
	net.WriteString(self:SteamID64())
	net.WriteString(group)
	net.Broadcast()

	-- TODO: Network with net class.

	local query = string.format(setUserGroupQuery, steamid, group)

	sql.Begin()
	sql.Query(query)
	sql.Commit()
end

local userString = "user"
local adminString = "admin"
local superAdminString = "superadmin"
local addUserGroupQuery = "INSERT OR REPLACE INTO 'CRX_Groups'('Group', 'Inheritance') VALUES('%s', '%s')"

function DatabaseClass:AddUserGroup(group, inheritance)
	if !string.IsValid(group) then return end

	-- If no inheritance is provided, set it to user.
	inheritance = inheritance or userString

	-- Prevent default usergroups from being overridden.
	if group == userString or group == adminString or group == superAdminString then return end

	-- Prevent the same usergroup from being created.
	if self:UserGroupExists(group) then return end

	-- Construct our CAMI_USERGROUP table.
	local userGroup = {}
	userGroup.Name = group
	userGroup.Inherits = inheritance

	-- Register the usergroup with CAMI.
	CAMI.RegisterUsergroup(userGroup, "CRX")

	-- TODO: Network with net class.

	local query = string.format(addUserGroupQuery, group, inheritance)

	sql.Begin()
	sql.Query(query)
	sql.Commit()
end

local removeUserGroupQuery = "DELETE FROM 'CRX_Groups' WHERE 'Group'='%s'"
local removeUsersQuery = "DELETE FROM 'CRX_Users' WHERE 'Group'='%s'"

function DatabaseClass:RemoveUserGroup(group)
	if !string.IsValid(group) then return end

	-- Prevent default usergroups from being unregistered.
	if group == userString or group == adminString or group == superAdminString then return end

	-- Return if usergroup doesn't exist.
	if !self:UserGroupExists(group) then return end

	-- Unregister the usergroup from CAMI.
	CAMI.UnregisterUsergroup(userGroup, "CRX")

	-- TODO: Network with net class.

	local groupQuery = string.format(removeUserGroupQuery, group)
	local userQuery = string.format(removeUsersQuery, group)

	sql.Begin()
	sql.Query(groupQuery)
	sql.Query(userQuery)
	sql.Commit()
end

function DatabaseClass:UserGroupExists(group)
	if !string.IsValid(group) then return end

	-- Usergroup will be registered in CAMI by the time this function is reasonably used.
	return CAMI.GetUsergroup(group)
end