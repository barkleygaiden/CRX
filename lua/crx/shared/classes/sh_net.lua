CRXNetClass = {}
CRXNetClass.__index = CRXNetClass

local NetClass = CRXNetClass
local emptystring = ""

function NetClass:Initialize(ply)
	if CLIENT then return end

	sql.Begin()
	local userGroups = sql.Query("SELECT * FROM 'CRX_Groups'")
	local users = sql.Query("SELECT * FROM 'CRX_Users'")
	sql.Commit()

	if !userGroups then return end

	self:NetworkAllUserGroups(userGroups, ply)

	if !users then return end

	self:NetworkAllUsers(users, ply)
end

local classString = "[CRX] - Net Class"

function NetClass:__tostring()
	return classString
end

-- SERVER --> CLIENT
-- Networks all usergroups to clients.
function NetClass:NetworkAllUserGroups(groups, ply)
	if CLIENT then return end
	if !groups then return end

	local userGroupCount = #groups

	-- Usergroup net message
	net.Start("CRX_NetworkUserGroup")
	net.WriteBool(true)
	net.WriteUInt(userGroupCount, 12)

	for i = 1, userGroupCount do
		local userGroup = userGroups[i]

		net.WriteString(userGroup.Name)
		net.WriteString(userGroup.Inherits)
	end

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

-- SERVER --> CLIENT
-- Networking usergroups to clients
-- Networking usergroup changes to clients
function NetClass:NetworkUserGroup(group, delete)
	if CLIENT then return end
	if delete == nil then delete = true end

	local groupName = (istable(group) and group.Name) or group

	net.Start("CRX_NetworkUserGroup")

	-- True: Add/Keep
	-- False: Delete
	net.WriteBool(delete)
	net.WriteUInt(1, 12)

	net.WriteString(groupName)

	-- If we're deleting the group, send the net message as-is.
	if !delete then net.Broadcast() return end

	net.WriteString(group.Inherits)
	net.Broadcast()
end

-- CLIENT
-- Receives networked usergroup.
function NetClass:ReceiveUserGroup(len)
	if SERVER then return end

	-- Get our database object outside of the loop.
	local database = CRX:GetDatabase()
	local shouldKeep = net.ReadBool()
	local userGroupCount = net.ReadUInt(12)

	for i = 1, userGroupCount do
		local groupName = net.ReadString()

		if !shouldKeep then
			database:RemoveUserGroup(groupName)

			continue
		end

		local inheritance = net.ReadString()

		database:AddUserGroup(groupName, inheritance)
	end
end

-- SERVER --> CLIENT
-- Networks all usergroups to clients.
function NetClass:NetworkAllUsers(users, ply)
	if CLIENT then return end
	if !users then return end

	local userCount = #users

	-- Users net message
	net.Start("CRX_NetworkUser")
	net.WriteUInt(userCount, 12)

	for i = 1, userCount do
		local user = users[i]

		net.WriteString(user.SteamID)
		net.WriteString(user.Group or emptystring)
	end

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

-- SERVER --> CLIENT
-- Networking users to clients
-- Networking user changes to clients
function NetClass:NetworkUser(steamid, group)
	if CLIENT then return end

	-- Users net message
	net.Start("CRX_NetworkUser")
	net.WriteUInt(1, 12)
	net.WriteString(steamid)
	net.WriteString(group or emptystring)
	net.Broadcast()
end

-- CLIENT
-- Receives networked user.
function NetClass:ReceiveUser(len)
	if SERVER then return end

	-- Get our database object outside of the loop.
	local database = CRX:GetDatabase()
	local userCount = net.ReadUInt(12)

	for i = 1, userCount do
		local steamID = net.ReadString()
		local groupName = net.ReadString() or userString

		database:SetUserGroup(steamID, groupName)
	end
end

-- CLIENT --> SERVER
-- Requesting server to change someone's usergroup
-- Requesting server to change a CAMI_USERGROUP value
function NetClass:RequestUserChange(steamid, group)
	if SERVER then return end

	-- We reuse the net message so we don't have to add another network string.
	net.Start("CRX_NetworkUser")
	net.WriteString(steamid)
	net.WriteString(group or emptyString)
	net.SendToServer()
end

-- SERVER
-- Changes user's assigned usergroup.
function NetClass:ReceiveUserChange(len, ply)
	if CLIENT then return end
	if !ply:IsSuperAdmin() then return end

	local steamID = sql.SQLStr(net.ReadString())
	local IDLength = #steamID

	-- SteamID64's are NEVER above or below 17 characters.
	if IDLength != 17 then return end

	local newGroup = sql.SQLStr(net.ReadString())

	CRXDatabase:SetUserGroup(steamID, newGroup)
end

-- CLIENT --> SERVER
-- Requesting server to change someone's usergroup
-- Requesting server to change a CAMI_USERGROUP value
function NetClass:RequestGroupChange(group, name)
	if SERVER then return end

	-- We reuse the net message so we don't have to add another network string.
	net.Start("CRX_NetworkUserGroup")

	-- True: Changing usergroup's name
	-- False: Changing usergroup's inheritance
	net.WriteBool(true)
	net.WriteString(group or emptyString)
	net.WriteString(name)
	net.SendToServer()
end

-- CLIENT --> SERVER
-- Requesting server to change CAMI_USERGROUP's name or inheritance
function NetClass:RequestInheritChange(group, inheritance)
	if SERVER then return end

	-- We reuse the net message so we don't have to add another network string.
	net.Start("CRX_NetworkUserGroup")

	-- True: Changing usergroup's name
	-- False: Changing usergroup's inheritance
	net.WriteBool(false)
	net.WriteString(group)
	net.WriteString(inheritance or emptyString)
	net.SendToServer()
end

-- SERVER
-- Changes CAMI_USERGROUP's name or inheritance
function NetClass:ReceiveGroupChange(len, ply)
	if CLIENT then return end
	if !ply:IsSuperAdmin() then return end

	local database = CRX:GetDatabase()
	local changingName = net.ReadBool()
	local groupName = sql.SQLStr(net.ReadString())
	local nameOrInheritance = sql.SQLStr(net.ReadString())

	if changingName then
		-- Make sure new name is not already taken.
		if CAMI.GetUserGroup(nameOrInheritance) then return end

		database:ChangeUserGroupName(groupName, nameOrInheritance)
	else
		-- Make sure our new inheritor exists.
		if CAMI.GetUserGroup(nameOrInheritance) then return end

		database:ChangeUserGroupInheritance(groupName, nameOrInheritance)
	end
end

local argWrites = {
	["string"] = function(arg)
		net.WriteUInt(1, 2)
		net.WriteString(arg)
	end,
	["player"] = function(arg)
		net.WriteUInt(2, 2)
		net.WritePlayer(arg)
	end,
	["table"] = function(arg)
		net.WriteUInt(3, 2)
		net.WriteColor(arg, false)
	end
}

-- SERVER --> CLIENT
-- Networking notifications done via CoreClass:Notify to clients.
function NetClass:NetworkNotification(ply, ...)
	if CLIENT then return end

	local notifyArgs = {...}
	local argCount = #notifyArgs

	net.Start("CRX_NetworkNotification")
	net.WriteUInt(argCount, 12)

	for i = 1, argCount do
		local arg = notifyArgs[i]
		local argType = type(arg)
		local writeFunc = argWrites[argType]

		writeFunc(arg)
	end

	net.Send(ply)
end

local argWrites = {
	function()
		return net.ReadString()
	end,
	function()
		return net.ReadPlayer()
	end,
	function()
		return net.ReadColor()
	end
}

-- CLIENT
-- Receives a networked notification from the server.
function NetClass:ReceiveNotification(len)
	if SERVER then return end

	local notifyArgs = {}
	local argCount = net.ReadUInt(12)

	for i = 1, argCount do
		local argType = net.ReadUInt(2)
		local readFunc = argReads[argType]
		local arg = readFunc()

		table.insert(notifyArgs, arg)
	end

	local unpackedArgs = unpack(notifyArgs)

	-- Print the notification in the player's console and chat box.
	chat.AddText(unpackedArgs)
	MsgC(unpackedArgs)
end

setmetatable(NetClass, {
    __call = function(tbl, ...)
        local instance = setmetatable({}, NetClass)

        if instance.__constructor then
            instance:__constructor(...)
        end

        return instance
    end
})

-- Net Receivers
if SERVER then
	net.Receive("CRX_NetworkUser", function(len, ply)
		local cNet = CRX:GetNet()

		cNet:ReceiveUserChange(len, ply)
	end)

	net.Receive("CRX_NetworkUserGroup", function(len, ply)
		local cNet = CRX:GetNet()

		cNet:ReceiveGroupChange(len, ply)
	end)
else
	net.Receive("CRX_NetworkUser", function(len)
		local cNet = CRX:GetNet()

		cNet:ReceiveUser(len)
	end)

	net.Receive("CRX_NetworkUserGroup", function(len)
		local cNet = CRX:GetNet()

		cNet:ReceiveUserGroup(len)
	end)

	net.Receive("CRX_NetworkNotification", function(len)
		local cNet = CRX:GetNet()

		cNet:ReceiveNotification(len)
	end)
end