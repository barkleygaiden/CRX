CRXDatabaseClass = CRXDatabaseClass or chicagoRP.NewClass()

local DatabaseClass = CRXDatabaseClass

function DatabaseClass:__constructor()
	-- [steamid] -- CAMI_USERGROUP.Name
	self.Users = {}

	-- True if our SQL database was initialized.
	self.Valid = false
end

local createGroupTableQuery = "CREATE TABLE IF NOT EXISTS 'CRX_Groups' ('Name' VARCHAR(48) PRIMARY KEY, 'Inherits' VARCHAR(48))"
local createUserTableQuery = "CREATE TABLE IF NOT EXISTS 'CRX_Users' ('SteamID' VARCHAR(18) PRIMARY KEY, 'Group' VARCHAR(48))"
local createIndexQuery = "CREATE INDEX IF NOT EXISTS 'CRX_Users' ON 'CRX_Users' ('Group')"

function DatabaseClass:Initialize()
	if SERVER then
	    sql.Begin()
	    sql.Query(createGroupTableQuery)
	    sql.Query(createUserTableQuery)
	    sql.Query(createIndexQuery)
	    sql.Commit()
	end

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

function DatabaseClass:GetUserGroup(steamid)
	if !string.IsValid(steamid) then return end

	steamid = (string.IsValid(steamid) and steamid) or (IsValid(steamid) and steamid:SteamID64())

	local userGroupName = self.Users[steamid] or userString

	return CAMI.GetUsergroup(userGroupName)
end

local setUserGroupQuery = "INSERT OR REPLACE INTO 'CRX_Users'('SteamID', 'Group') VALUES('%s', '%s')"

function DatabaseClass:SetUserGroup(steamid, group)
	if !string.IsValid(steamid) then return end

	-- Set group to user if nil.
	group = (string.IsValid(group) and group) or userString

	-- Get SteamID64 if the provided arg is not a string.
	steamid = (string.IsValid(steamid) and steamid) or (IsValid(steamid) and steamid:SteamID64())

	-- Make sure usergroup exists and is registered.
	if !CAMI.GetUserGroup(group) then return end

	-- Cache the usergroup change.
	self.Users[steamid] = group

	-- Networking and SQL is serverside only.
	if CLIENT then return end

	local nett = CRX:GetNet()

	-- Network the new user change to all clients.
	nett:NetworkUser(steamid, group)

	-- TODO: How does string.format handle nil?
	local query = string.format(setUserGroupQuery, steamid, group)

	sql.Begin()
	sql.Query(query)
	sql.Commit()
end

local removeUserGroupQuery = "DELETE FROM 'CRX_Groups' WHERE 'Name'='%s'"
local changeUserGroupQuery = "INSERT OR REPLACE INTO 'CRX_Groups'('Name', 'Inherits') VALUES('%s', '%s')"

function DatabaseClass:ChangeUserGroupName(group, name)
	if CLIENT then return end
	if !string.IsValid(group) then return end

	-- Assemble query BEFORE the usergroup's name is changed.
	local deleteQuery = string.format(removeUserGroupQuery, group)

	-- Make changes to CAMI_USERGROUP object.
	local userGroup = CAMI.GetUsergroup(group)
	userGroup.Name = shouldDelete or userGroup.Name

	local nett = CRX:GetNet()

	-- Network the new CAMI_USERGROUP changes to all clients.
	nett:NetworkUserGroup(userGroup)

	-- TODO: How does string.format handle nil?
	local changeQuery = string.format(changeUserGroupQuery, userGroup.Name, userGroup.Inherits)

	sql.Begin()
	sql.Query(deleteQuery)
	sql.Query(changeQuery)
	sql.Commit()
end

function DatabaseClass:ChangeUserGroupInheritance(group, inheritance)
	if !string.IsValid(group) then return end

	-- Make changes to CAMI_USERGROUP object.
	local userGroup = CAMI.GetUsergroup(group)
	userGroup.Inherits = inheritance

	-- Net class is stored in our main class
	local nett = CRX:GetNet()

	-- Network the new CAMI_USERGROUP changes to all clients.
	nett:NetworkUserGroup(userGroup)

	-- TODO: How does string.format handle nil?
	local changeQuery = string.format(changeUserGroupQuery, userGroup.Name, userGroup.Inherits)

	sql.Begin()
	sql.Query(changeQuery)
	sql.Commit()
end

local sourceString = "CRX"
local adminString = "admin"
local superAdminString = "superadmin"
local addUserGroupQuery = "INSERT OR REPLACE INTO 'CRX_Groups'('Name', 'Inherits') VALUES('%s', '%s')"

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
	CAMI.RegisterUsergroup(userGroup, sourceString)

	-- Networking and SQL is serverside only.
	if CLIENT then return end

	local nett = CRX:GetNet()

	-- Network the new CAMI_USERGROUP object to all clients.
	nett:NetworkUserGroup(userGroup)

	local query = string.format(addUserGroupQuery, group, inheritance)

	sql.Begin()
	sql.Query(query)
	sql.Commit()
end

local removeUsersQuery = "DELETE FROM 'CRX_Users' WHERE 'Group'='%s'"

function DatabaseClass:RemoveUserGroup(group)
	if !string.IsValid(group) then return end

	-- Prevent default usergroups from being unregistered.
	if group == userString or group == adminString or group == superAdminString then return end

	-- Return if usergroup doesn't exist.
	if !self:UserGroupExists(group) then return end

	-- Unregister the usergroup from CAMI.
	CAMI.UnregisterUsergroup(group, sourceString)

	-- Networking and SQL is serverside only.
	if CLIENT then return end

	local nett = CRX:GetNet()

	-- Network the CAMI_USERGROUP removal to all clients.
	nett:NetworkUserGroup(group, true)

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