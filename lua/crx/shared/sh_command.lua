CRXCommand = {}
CRXCommand.__index = CRXCommand

function CRXCommand:__constructor()
	self.Params = {}
	self.DefaultPermissions = CRX_SUPERADMIN
end

function CRXCommand:New()
	local newCommand = setmetatable({}, self)

	return newCommand
end

function CRXCommand:Remove()
	local commands = CRX:GetCommands()

	-- Removes command from the main class' commands table
	commands[self.Name] = nil

	setmetatable(self, nil)
end

function CRXCommand:IsValid()
	return string.IsValid(self.Name) and isfunction(self.Callback)
end

function CRXCommand:GetCategory(category)
	return self.Category
end

function CRXCommand:SetCategory(category)
	self.Category = category

	if !IsValid(category) then return end

	category:AddCommand(self)
end

function CRXCommand:GetName()
	return self.Name
end

function CRXCommand:SetName(name)
	self.Name = name

	local commands = CRX:GetCommands()

	-- Adds command to the main class' commands table
	commands[self.Name] = self
end

function CRXCommand:GetParameters()
	return self.Parameters
end

function CRXCommand:AddParameter(typ)
	if !typ then return end

	table.insert(self.Parameters, typ)
end

function CRXCommand:GetDefaultPermissions()
	return self.DefaultPermissions
end

function CRXCommand:SetDefaultPermissions(perms)
	if !perms then return end

	self.DefaultPermissions = perms
end

function CRXCommand:GetCallback(func)
	return self.Callback
end