CRXCommandClass = CRXCommandClass or chicagoRP.NewClass()

local CommandClass = CRXCommandClass

function CommandClass:__constructor()
	self.Parameters = {}

	self.EntityParameter = false
	self.DefaultPermissions = CRX_SUPERADMIN
end

local classString = "[CRX] - Command: %s"
local invalidString = "[NULL]"

function CommandClass:__tostring()
	return string.format(classString, (self:IsValid() and self.Name) or invalidString)
end

function CommandClass:__eq(other)
	-- If either command doesn't have a name, they are not equal.
	if !self:IsValid() or !other:IsValid() then return false end

	return self:GetName() == other:GetName()
end

function CommandClass:IsValid()
	return string.IsValid(self.Name) and isfunction(self.Callback)
end

function CommandClass:Remove()
	local commands = CRX:GetCommands()

	-- Removes command from the main class' commands table
	commands[self.Name] = nil

	-- TODO: Does this even do what I think it does?
	setmetatable(self, nil)
end

function CommandClass:GetName()
	return self.Name
end

function CommandClass:SetName(name)
	local category = self:GetCategory()

	-- Removes command from the current category's table.
	if category then
		category.Commands[self.Name] = nil
	end

	local commands = CRX:GetCommands()

	-- Removes command from the main class' commands table.
	commands[self.Name] = nil

	-- Set the new command name.
	self.Name = name

	-- Readds command to the main class' commands table.
	commands[self.Name] = self
end

function CommandClass:GetCategory()
	return self.Category
end

function CommandClass:SetCategory(category)
	category = (string.IsValid(category) and category) or CRX:GetCategory(category)

	self.Category = category

	if !IsValid(category) then return end

	category:AddCommand(self)
end

function CommandClass:GetParameters()
	return self.Parameters
end

function CommandClass:AddParameter(typ, name)
	if !typ or !name then return end

	local parameter = CRXParameterClass()

	-- Set the new parameter type.
	self.Type = typ

	-- Set the new parameter name.
	self.Name = name

	-- Set the new parameter's parent (command).
	self.Parent = self

	-- Hacky method of avoiding table.HasValue where we store the type to avoid a break loop.
	if !self.EntityParameter and typ >= 4 then
		self.EntityParameter = typ
	end

	table.insert(self.Parameters, parameter)
end

function CommandClass:GetDefaultPermissions()
	return self.DefaultPermissions
end

function CommandClass:SetDefaultPermissions(perms)
	if !perms then return end

	self.DefaultPermissions = perms
end

local groupPermissions = {
	user = CRX_USER,
	admin = CRX_ADMIN,
	superadmin = CRX_SUPERADMIN
}

function CommandClass:HasPermissions(object)
	-- Object can be player or a usergroup name.
	if !object then return end

	-- No, you cannot use non-player entities with this.
	if IsEntity(object) and object:IsPlayer() then return end

	local isString = isstring(object)

	-- Usergroup name must be valid.
	if isString and !string.IsValid(object) then return end

	-- Get our usergroup name if the object is a player.
	local userGroupName = (isString and object) or object:GetUserGroup()

	-- Get our usergroup's root inheritance.
	local inheritance = CAMI.InheritanceRoot(object)
	local permissions = groupPermissions[inheritance]

	-- True if our group is equal or higher than the permissions enum.
	return permissions >= self.DefaultPermissions
end

function CommandClass:GetCallback(func)
	return self.Callback
end