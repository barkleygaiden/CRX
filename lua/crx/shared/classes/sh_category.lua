CRXCategoryClass = CRXCategoryClass or chicagoRP.NewClass()

local CategoryClass = CRXCategoryClass

function CategoryClass:__constructor()
	self.Commands = {}
end

local classString = "[CRX] - Category: %s"
local invalidString = "[NULL]"

function CategoryClass:__tostring()
	return string.format(classString, (self:IsValid() and self.Name) or invalidString)
end

function CategoryClass:__eq(other)
	-- If either command doesn't have a name, they are not equal.
	if !self:IsValid() or !other:IsValid() then return false end

	return self:GetName() == other:GetName()
end

function CategoryClass:IsValid()
	return string.IsValid(self.Name)
end

function CategoryClass:Remove()
	-- Removes category from the main class table.
	CRX:RemoveCategory(self)

	-- TODO: Does this even do what I think it does?
	setmetatable(self, nil)
end

function CategoryClass:GetName()
	return self.Name
end

function CategoryClass:SetName(name)
	self.Name = name
end

function CategoryClass:GetCommands()
	return self.Commands
end

function CategoryClass:GetCommand(name)
	return self.Commands[name]
end

function CategoryClass:AddCommand(command)
	if !command or !command:IsValid() then return end

	local name = command:GetName()

	self.Commands[name] = command

	local categoryCommands = CRX:GetCommandsFromCategory(self)

	-- Adds the command to our category's hashtable.
	table.insert(categoryCommands[self.Name], command)
end

function CategoryClass:RemoveCommand(command)
	if !command or !command:IsValid() then return end

	local name = command:GetName()

	self.Commands[name] = nil

	local categoryCommands = CRX:GetCommandsFromCategory(self)

	-- Removes the command from our category's hashtable.
	-- We have to do a loop as the commands are stored sequentially.
	table.RemoveByValue(categoryCommands[self.Name], command)
end

function CategoryClass:HasCommand(name)
	return self.Commands[name]
end