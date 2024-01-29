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

function CRXClass:GetCommands()
	return self.Commands
end

function CRXClass:GetCommandsFromCategory(category)
	return self.CategoryCommands[category:GetName()]
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
	self:AddCategory(newCategory)

	return newCategory
end

function CRXClass:AddCategory(category)
	if !category then return end

	local name = category:GetName()

	self.Categories[name] = category

	-- Creates the hashtable used to fetch categories commands more quickly.
	self.CategoryCommands[name] = {}
end

-- I don't know why you would want to remove a category but here you go ¯\_(ツ)_/¯
function CRXClass:RemoveCategory(category)
	if !category then return end

	local name = category:GetName()

	self.Categories[name] = nil
	self.CategoryCommands[name] = nil
end

function CRXClass:CategoryExists(name)
	local category = self.Categories[name]

	return category and category:IsValid()
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

function CRXClass:DoCommand(ply, cmd, args, argstring)
	-- No command provided, print help command
	if !args then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "No command entered. If you need help, please type 'crx help' in your console.")

		return
	end

	local commandString = args[1]

	-- Menu command triggered, open the GUI menu.
	if commandString == menuString then
		local GUI = CRX:GetGUI()

		GUI:OpenMenu()

		return
	end

	-- Help command triggered but with no arg provided, show more help
	if commandString == helpString and !args[2] then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Show all commands: crx help *")
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Show specific command: crx help <string>:command")

		return
	-- Non-help command triggered without args, print syntax
	elseif commandString != helpString and !args[2] then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Command usage: crx <string>:command <any>:args")

		return
	end

	local command = self.AllCommands[commandString]

	if !command or !command:IsValid() then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Command invalid, contact your server's admin.")

		return
	end
end