CRXCategoryClass = CRXCategoryClass or CRX:NewClass()

local CategoryClass = CRXCategoryClass

function CategoryClass:__constructor()
	self.Commands = {}
	self.CommandLookup = {}
	self.CommandCount = 0
end

local classString = "[CRX] - Category: %s"
local invalidString = "Invalid!"

function CategoryClass:__tostring()
	return string.format(classString, (self:IsValid() and self.Name) or invalidString)
end

function CategoryClass:IsValid()
	return string.IsValid(self.Name)
end

function CategoryClass:New(name)
	-- Without a name, we can't possibly know what category the invoker wants.
	if !string.IsValid(name) then return end

	local fetchedCatgeory = CRX:GetCategory(name)

	-- If a category with the same name already exists, return it.
	if fetchedCatgeory and fetchedCatgeory:IsValid() then return fetchedCatgeory end

	local newCategory = setmetatable({}, self)

	-- Sets our new category's name
	self.Name = name

	-- Adds category to the main class table
	CRX:AddCategory(newCategory)

	return newCategory
end

function CategoryClass:Remove()
	-- Removes category from the main class table
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

function CategoryClass:AddCommand(command)
	if !command or !command:IsValid() then return end

	local name = command:GetName()

	self.Commands[name] = command
end

function CategoryClass:RemoveCommand(command)
	if !command or !command:IsValid() then return end

	local name = command:GetName()

	self.Commands[name] = nil
end

function CategoryClass:HasCommand(name)
	return self.CommandLookup[name]
end