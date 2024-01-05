CRXDatabaseClass = CRXDatabaseClass or CRX:NewClass()

local DatabaseClass = CRXDatabaseClass

function DatabaseClass:__constructor()
	self.Initialized = false
	self.Valid = false

	self.Users = {}
end

local createGroupTableQuery = "CREATE TABLE IF NOT EXISTS 'CRX_Groups' ('Group' PRIMARY KEY, 'Inheritance')"
local createUserTableQuery = "CREATE TABLE IF NOT EXISTS 'CRX_Users' ('Steamid' PRIMARY KEY, 'Group')"
local createIndexQuery = "CREATE INDEX IF NOT EXISTS 'CRX_Users' ON 'CRX_Users' ('Group')"

function DatabaseClass:Initialize()
    sql.Begin()
    sql.Query(createGroupTableQuery)
    sql.Query(createUserTableQuery)
    sql.Query(createIndexQuery)
    sql.Commit()

	self.IsValid = true
end

function DatabaseClass:IsValid()
	return self.IsValid
end

local getUserGroupsQuery = "SELECT * FROM 'CRX_Users'"

function DatabaseClass:GetUserGroups()
	if !table.IsEmpty(self.Users) then return self.Users end

	sql.Begin()
	local userGroups = sql.Query(getUserGroupsQuery)
	sql.Commit()

	for i = 1, #userGroups do
		local userGroupInfo = userGroups[i]

		self.Users[userGroupInfo.Group] = userGroupInfo.SteamID
	end

	return self.Users
end

local setUserGroupQuery = "INSERT OR REPLACE INTO 'CRX_Users'('SteamID', 'Group') VALUES('%s', '%s')"

function DatabaseClass:SetUserGroup(steamid, group)
	steamid = (string.IsValid(steamid) and steamid) or (IsValid(steamid) and steamid:SteamID64())

	local query = string.format(setUserGroupQuery, steamid, group)

	sql.Begin()
	sql.Query(query)
	sql.Commit()
end