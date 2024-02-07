CRXCommandClass = CRXCommandClass or chicagoRP.NewClass()

local CommandClass = CRXCommandClass

function CommandClass:__constructor()
	self.Parameters = {}

	self.TargetParameter = false
	self.DefaultPermissions = CRX_SUPERADMIN
end

local classString = "[CRX] - Command: %s"
local invalidString = "[NULL]"

function CommandClass:__tostring()
	return string.format(classString, (self:IsValid() and self.Name) or invalidString)
end

function CommandClass:__eq(other)
	-- If either command lacks a name, they are not equal.
	if !self:IsValid() or !other:IsValid() then return false end

	return self.Name == other:GetName()
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

function CommandClass:GetDescription()
	return self.Description
end

function CommandClass:SetDescription(description)
	-- Set the new command description.
	self.Description = description
end

function CommandClass:GetParameters()
	return self.Parameters
end

function CommandClass:AddParameter(typ, name)
	if !typ or !name then return end

	local parameter = CRXParameterClass()

	-- Set the new parameter type.
	parameter.Type = typ

	-- Set the new parameter name.
	parameter.Name = name

	-- Set the new parameter's parent (command).
	parameter.Parent = self

	-- Hacky method of avoiding table.HasValue where we store the type to avoid a break loop.
	if !self.TargetParameter and typ == 4 then
		self.TargetParameter = parameter
		self.TargetIndex = #self.Parameters + 1

		parameter.IsTarget = true
	end

	table.insert(self.Parameters, parameter)
end

function CommandClass:GetCallback(func)
	return self.Callback
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
	local inheritance = CAMI.InheritanceRoot(userGroupName)
	local permissions = groupPermissions[inheritance]

	-- True if our group is equal or higher than the permissions enum.
	return permissions >= self.DefaultPermissions
end

local invalidParameterString = "invalid parameter at index '%i'."

function CommandClass:IsSyntaxValid(args)
	for i = 1, #parameters do
		local parameter = parameters[i]
		local argString = args[i]

		if !parameter:IsValid() then return false, string.format(invalidParameterString, i) end

		local isValid, errorMessage = parameter:IsStringArgValid(argString)

		if !isValid then return isValid, errorMessage end
	end

	return true
end

function CommandClass:ProcessArgStrings(strings, caller)
	local processedArgs = {}

	for i = 1, #parameters do
    	-- TODO
    end

    return processedArgs
end

function CommandClass:DoCommand(ply, cmd, args, argstring)
	-- We process the args by converting from strings to their expected types and values.
	local processedArgs, targets = self:ProcessArgStrings(args, ply)
	local unpackedArgs = unpack(processedArgs)

	-- If we have targets, then we need to do a loop to invoke the command once for each target.
	if self.TargetParameter and targets then
		for i = 1, #targets do
			local target = targets[i]

			if !IsValid(target) then continue end

			-- We invoke the command's callback for this target and leave it to them.
			local notifyMessage = self.Callback(ply, target, unpackedArgs)

			-- TODO: MsgC + chat.AddText on client.
		end

		-- Return end to stop the callback from being called again.
		return
	end

	-- Finally, we invoke the command's callback and leave it to them.
	local notifyMessage = self.Callback(ply, unpackedArgs)

	-- TODO: MsgC + chat.AddText on client.
end