CRXClass = CRXClass or chicagoRP.NewClass()

function CRXClass:__constructor()
	self.Categories = {}
	self.Commands = {}

    -- Adds the primary command
    concommand.Add("crx", self:DoCommand)
end

local classString = "[CRX] - Core Class"

function CRXClass:__tostring()
	return classString
end

function CRXClass:GetCommands()
	return self.Commands
end

function CRXClass:GetCommand(name)
	if !string.IsValid(name) then return end

	return self.Commands[name]
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

function CRXClass:AddCategory(category)
	if !category then return end

	local name = category:GetName()

	self.Categories[name] = category
end

-- I don't know why you would want to remove a category but here you go ¯\_(ツ)_/¯
function CRXClass:RemoveCategory(category)
	if !category then return end

	local name = category:GetName()

	self.Categories[name] = nil
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
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Help: crx help")

		return
	end

	local commandString = args[1]

	-- Menu command triggered, open the GUI menu.
	if commandString == menuString then
		CRXGUI:OpenMenu()

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