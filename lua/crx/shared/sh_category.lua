CRXCategory = {}
CRXCategory.__index = CRXCategory

function CRXCategory:__constructor()
	self.Commands = {}
	self.CommandCount = 0
end

function CRXCategory:New()
	local newCategory = setmetatable({}, self)

	if !IsValid(newCategory) then return end

	-- Adds category to the main class table
	CRX:AddCategory(newCategory)

	return newCategory
end

function CRXCategory:Remove()
	-- Removes category from the main class table
	CRX:RemoveCategory(self)

	setmetatable(self, nil)
end

function CRXCommand:GetName()
	return self.Name
end

function CRXCommand:SetName(name)
	self.Name = name
end

function CRXCategory:AddCommand(command)
	table.insert(self.Commands, command)

	-- Storing table count saves a bit of performance
	-- Using #tbl requires C bridge (Lua -> C -> Lua)
	self.CommandCount = self.CommandCount + 1
end

function CRXCategory:RemoveCommand(command)
	-- We have to find the index manually :|
	table.RemoveByValue(self.Commands, command)

	self.CommandCount = self.CommandCount - 1
end