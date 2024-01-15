CRXCommandClass = CRXCommandClass or chicagoRP.NewClass()

local CommandClass = CRXCommandClass

function CommandClass:__constructor()
	self.Params = {}
	self.DefaultPermissions = CRX_SUPERADMIN
end

local classString = "[CRX] - Command: %s"
local invalidString = "Invalid!"

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

function CommandClass:New(name)
	-- Without a name, command cannot possibly be valid.
	if !string.IsValid(name) then return end

	local fetchedCommand = CRX:GetCommand(name)

	-- If a command with the same name already exists, return it.
	if fetchedCommand and fetchedCommand:IsValid() then return fetchedCommand end

	local newCommand = setmetatable({}, self)

	-- Sets our new command's name
	self.Name = name

	return newCommand
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

	local commands = CRX:GetCommands()

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

function CommandClass:AddParameter(typ)
	if !typ then return end

	table.insert(self.Parameters, typ)
end

function CommandClass:GetDefaultPermissions()
	return self.DefaultPermissions
end

function CommandClass:SetDefaultPermissions(perms)
	if !perms then return end

	self.DefaultPermissions = perms
end

function CommandClass:GetCallback(func)
	return self.Callback
end