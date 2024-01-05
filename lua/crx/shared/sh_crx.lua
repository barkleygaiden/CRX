-- helper for creating classes
local function NewClass()
    local newclass = {}

    local metatable = {}
    newclass.__index = newclass

    metatable.__call = function(tbl, ...)
        local obj = setmetatable({}, newclass)

        if obj.__constructor then
            obj:__constructor(...)
        end

        return obj
    end

    setmetatable(newclass, metatable)

    return newclass
end

CRXClass = CRXClass or NewClass()

function CRXClass:__constructor()
	self.Categories = {}
	self.Commands = {}
	self.CategoryCount = 0

	self.Font = "DermaDefault"
	self.InfoString = string.format("CLX Admin Mod :: CRP Collective | CRX v%i", CRX_VERSION)

    self.ThemeColor = chicagoRP.GetSecondaryColor(true)
    self.ThemeColor.a = 200

    -- Adds the primary command
    concommand.Add("crx", self:DoCommand)
end

local dateParams = "%I:%M:%S %p"

function CRXClass:OpenMenu()
    self.Frame = vgui.Create("DFrame")
    self.Frame:SetSize(1200, 840)
    self.Frame:Center()
    self.Frame:SetTitle("")
    self.Frame:MakePopup()
    self.Frame:SetKeyboardInputEnabled(false)

    self.Sheet = vgui.Create("DPropertySheet", self.Frame)

    self.InfoBar = vgui.Create("DPanel", self.Frame)
    self.InfoBar:SetSize(1200 - (1200 * 0.05), 840 - (840 * 0.95))
    self.InfoBar:CenterHorizontal()
    self.InfoBar:SetY(839)
    self.InfoBar:NoClipping(true)

    function self.InfoBar:Paint(w, h)
    	draw.RoundedBoxEx(4, 0, 1, w, h, self.ThemeColor, false, false, true, true)

    	local centerY = h * 0.5 - select(2, surface.GetTextSize(self.InfoString)) * 0.5

    	-- Version text
    	surface.SetTextPos(5, centerY)
    	surface.SetTextColor(0, 0, 0, 255)
    	surface.DrawText(self.InfoString)

    	-- Time text
    	local timeString = os.date(dateParams)

    	draw.DrawText(timeString, self.Font, w - 5, centerY, color_black, TEXT_ALIGN_RIGHT)
    end
end

function CRXClass:CloseMenu()
	if !IsValid(self.Frame) then return end

	self.Frame:AlphaTo(0, 0.5, 0, function(data, panel)
		if !IsValid(self.Frame) then return end

		self.Frame:Close()
	end)
end

function CRXClass:GetCommand(cmd)
	if !string.IsValid(cmd) then return end

	return self.Commands[cmd]
end

function CRXClass:GetCommands()
	return self.Commands
end

local helpString = "help"
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

function CRXClass:GetCategories()
	return self.Categories
end

function CRXClass:AddCategory(category)
	table.insert(self.Categories, category)

	-- Storing table count saves a bit of performance
	-- Using #tbl requires C bridge (Lua -> C -> Lua)
	self.CategoryCount = self.CategoryCount + 1
end

-- I don't know why you would want to remove a category but here you go ¯\_(ツ)_/¯
function CRXClass:RemoveCategory(category)
	table.insert(self.Categories, category)

	-- We have to find the index manually :|
	table.RemoveByValue(self.Categories, category)

	self.CategoryCount = self.CategoryCount - 1
end

-- NOTE: Helper for creating new classes
function CRXClass:NewClass()
	return NewClass()
end