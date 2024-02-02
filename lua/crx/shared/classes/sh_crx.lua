CRXClass = CRXClass or chicagoRP.NewClass()

function CRXClass:__constructor()
	self.Categories = {}
	self.CategoryCommands = {}
	self.Commands = {}

	-- Construct our database class.
	self.Database = CRXDatabaseClass()

	-- Construct our net class.
	self.Net = CRXNetClass()

	-- Construct our GUI class.
	if CLIENT then
		self.GUI = CRXGUIClass()
	end

    -- Adds the primary command.
    concommand.Add("crx", self:DoCommand)

    -- Runs our initialization hook.
    hook.Run("CRX_Initialized")
end

local classString = "[CRX] - Core Class"

function CRXClass:__tostring()
	return classString
end

function CRXClass:Think()
	if CLIENT and self.GUI then
		self.GUI:Think()
	end
end

function CRXClass:GetDatabase()
	return self.Database
end

function CRXClass:GetNet()
	return self.Net
end

function CRXClass:GetGUI()
	return self.GUI
end

function CRXClass:GetCategories()
	return self.Categories
end

function CRXClass:GetCategory(name)
	if !string.IsValid(name) then return end

	return self.Categories[name]
end

function CRXClass:Category(name)
	-- Without a name, we can't possibly know what category the invoker wants.
	if !string.IsValid(name) then return end

	local fetchedCatgeory = self:GetCategory(name)

	-- If a category with the same name already exists, return it.
	if fetchedCatgeory and fetchedCatgeory:IsValid() then return fetchedCatgeory end

	local newCategory = setmetatable({}, CRXCategoryClass())

	-- Sets our new category's name
	newCategory.Name = name

	-- Adds category to the main class table.
	self.Categories[name] = category

	return newCategory
end

function CRXClass:CategoryExists(name)
	local category = self.Categories[name]

	return category and category:IsValid()
end

function CRXClass:GetCommands()
	return self.Commands
end

function CRXClass:GetCommand(name)
	if !string.IsValid(name) then return end

	return self.Commands[name]
end

function CRXClass:Command(name)
	-- Without a name, command cannot possibly be valid.
	if !string.IsValid(name) then return end

	local fetchedCommand = self:GetCommand(name)

	-- If a command with the same name already exists, return it.
	if fetchedCommand and fetchedCommand:IsValid() then return fetchedCommand end

	local newCommand = setmetatable({}, CRXCommandClass())

	-- Sets our new command's name
	newCommand.Name = name

	return newCommand
end

function CRXClass:CommandExists(name)
	local command = self.Commands[name]

	return command and command:IsValid()
end

local helpString = "help"
local menuString = "menu"
local CRXColor = Color(200, 0, 0, 255)
local clientColor = Color(255, 241, 122, 200)
local serverColor = Color(136, 221, 255, 255)

local function GetStateColor()
	if CLIENT then
		return clientColor
	else
		return serverColor
	end
end

function CRXClass:DoInternalCommand(ply, cmd, args, argstring)
	-- No command provided, print help command
	if !args then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "No command entered. If you need help, please type 'crx help' in your console.")

		return true
	end

	local commandName = args[1]

	-- Menu command triggered, open the GUI menu.
	if commandName == menuString then
		local GUI = CRX:GetGUI()

		GUI:OpenMenu()

		return true
	end

	-- Help command triggered but with no arg provided, show more help
	if commandName == helpString and !args[2] then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Show all commands: crx help *")
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Show specific command: crx help <string>:command")

		return true
	-- Non-help command triggered without args, print syntax
	elseif commandName != helpString and !args[2] then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Command usage: crx <string>:command <any>:args")

		return true
	end

	local command = self.Commands[commandName]

	if !command or !command:IsValid() then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Command invalid, contact your server's admin.")

		return true
	end

	return false
end

function CRXClass:DoCommand(ply, cmd, args, argstring)
	-- Process our internal commands if needed (menu, help, etc)
	local processed = self:DoInternalCommand(ply, cmd, args, argstring)

	-- If an internal command was processed, then stop.
	if processed then return end

	-- Fetch the command object from our internal table.
	local command = self.Commands[args[1]]

	-- After fetching the command, the first argument (the command name) is irrelevant.
	-- Therefore, we remove it before processing the args.
	table.remove(args, 1)

	-- Then, we process the args by converting from strings to their expected types and values.
	local processedArgs, targets = command:ProcessArgStrings(args)
	local unpackedArgs = unpack(processedArgs)
	local targetParameter = command.TargetParameter

	-- If we have targets, then we need to do a loop to invoke the command once for each target.
	if targets then
		for i = 1, #targets do
			local target = targets[i]

			if !IsValid(target) then continue end

			-- Finally, we invoke the command's callback for this target and leave it to them.
			local notifyMessage = command:Callback(ply, target, unpackedArgs)

			-- TODO: MsgC + chat.AddText on client.
		end

		return
	end

	-- Finally, we invoke the command's callback and leave it to them.
	local notifyMessage = command:Callback(ply, unpackedArgs)

	-- TODO: MsgC + chat.AddText on client.
end