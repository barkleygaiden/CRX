CRXClass = {}
CRXClass.__index = CRXClass

local CoreClass = CRXClass

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
    concommand.Add("crx", self:ProcessCommand)

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

	-- Adds command to the core class's commands table.
	self.Commands[name] = newCommand

	return newCommand
end

function CRXClass:CommandExists(name)
	local command = self.Commands[name]

	return command and command:IsValid()
end

local leftParenthesis = "("
local rightParenthesis = ")"

function CRXClass:FormatArgs(args)
	local argsToRemove = {}
	local startIndex = 0
	local insideParenthesis = false
	local tableString = leftParenthesis

	for i = 1, #args do
		local argString = args[i]
	    local currentChar = string.sub(argString, i, i)

	    -- We are inside a parenthesis table, so concat the current arg with our table string.
		if insideParenthesis then
		    tableString = string.concat(tableString, argString)

		    -- Stash the arg's index for arg removal later.
		    table.insert(argsToRemove, i)
		end

		-- If the arg is a left parenthesis character, it's the start of a table.
	    if argString == leftParenthesis then
	    	-- Stash the current index as the beginning arg.
	    	startIndex = i

	    	insideParenthesis = true
	    -- If the arg is a right parenthesis character, it's the end of a table.
	    elseif argString == rightParenthesis then
	    	-- Change the beginning arg (left parenthesis character) to the final table string.
	    	args[startIndex] = tableString

	    	insideParenthesis = false

	    	-- Reset our table string to a left parenthesis character.
	    	tableString = leftParenthesis
	    end
	end

	local amountRemoved = 0

	-- Loop through the table to remove the irrelevant args that were merged into table args.
	for i = 1, #argsToRemove do
		table.remove(args, argsToRemove[i] - amountRemoved)

		-- Because we removed a key, we need to shift all future removals down by 1.
		amountRemoved = amountRemoved + 1
	end

	return args
end

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

function CRXClass:DoInternalCommand(ply, cmd, args, argstr)
	-- No command provided, print help command
	if !args then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "No command entered. If you need help, please type 'crx help' in your console.")

		return true
	end

	local commandName = args[1]

	-- Menu command triggered, open the GUI menu.
	if commandName == "menu" then
		local GUI = CRX:GetGUI()

		GUI:OpenMenu()

		return true
	end

	-- Help command triggered but with no arg provided, show more help
	if commandName == "help" and !args[2] then
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Show all commands: crx help *")
		MsgC(color_white, "[", CRXColor, "CRX", color_white, "] - ", GetStateColor(), "Show specific command: crx help <string>:command")

		return true
	-- Non-help command triggered without args, print syntax
	elseif commandName != "help" and !args[2] then
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

local commandQueue = {}

function CRXClass:ProcessCommand(ply, cmd, args, argstr)
	-- Prevent players from sending commands too fast. Doesn't affect server console.
	if (commandQueue[ply] or 0) > CurTime() + 0.5 then return end

	-- Reset the players queue value if command wasn't called from server console.
	if IsValid(ply) then
		commandQueue[ply] = CurTime()
	end

	-- Process our internal commands if needed (menu, help, etc)
	local processed = self:DoInternalCommand(ply, cmd, args, argstr)

	-- If an internal command was processed, then stop.
	if processed then return end

	-- Fetch the command object from our internal table.
	local command = self.Commands[args[1]]

	-- Fuck off skids.
	if !command:HasPermissions(ply) then return end

	-- After fetching the command, the first argument (the command name) is irrelevant.
	-- Therefore, we remove it before processing the args.
	table.remove(args, 1)

	-- Format our command's arguments to merge table args - the in-engine arg parser HATES parenthesis.
	local formattedArgs = self:FormatArgs(args)

	-- Check to make sure our syntax is valid, and throw a halting error message if it isn't.
	local validSyntax, errorMessage = command:IsSyntaxValid(formattedArgs, caller)

	if !validSyntax then
		-- If an error message was provided, print it for the caller in their chat and console.
		CRXClass:Notify(caller, errorMessage, true, args, targets)

		return
	end

	-- Process the command inside of it's object.
	command:DoCommand(ply, cmd, formattedArgs, argstr)
end

local errorColor = Color(255, 140, 40)
local errorString = "Error: "
local emptyString = ""

function CRXClass:ErrorMessage(caller, ...)
	local isRCon = SERVER and !IsValid(caller)
	local firstArg = {...}[1]
	local shouldInsertColor = firstArg and !IsColor(firstArg)

	-- Only print for client, and server console if the caller is invalid.
	if isRCon or CLIENT then
		-- Since this is an error, concat an error prefix.
		MsgC(errorColor, errorString, (shouldInsertColor and color_white) or emptyString, ...)
	end

	-- If this was called on SERVER or the caller is not valid, don't add text to chat.
	if isRCon or SERVER then return end

	chat.AddText(errorColor, errorString, (shouldInsertColor and color_white) or emptyString, ...)
end

local commaSeparater = ", "
local finalSeparater = ", and "

local function BuildTargetString(tbl, targets)
	if !targets or table.IsEmpty(targets) then
		table.insert(tbl, "NONE")

		return
	end

	local targetCount = #targets

	for k = 1, targetCount do
		local target = targets[k]

		table.insert(tbl, target)

		if k != targetCount then
			table.insert(tbl, commaSeparater)
		elseif k == targetCount - 1 then
			table.insert(tbl, finalSeparater)
		end
	end
end

local valueColor = Color(0, 255, 0)
local callerKeyword = "c"
local targetKeyword = "t"

-- TODO: Use net system to have clients parse this on their own.
function CRXClass:Notify(caller, notify, targets, ...)
	-- We can't possibly know what the player is trying to notify us of 
	if !string.IsValid(notify) then return end

	local args = {...}

    -- If the targets var is a table with entities, keep it.
    -- Otherwise, assume it is an arg and merge it into the varargs table.
	if !(istable(targets) and isentity(targets[1])) then
		table.insert(args, 1, targets)
	end

	local notifyArgs = {}
    local currentArg = 1

    -- NOTE: Old pattern was "([^#]*)#([%.%d]*[%a])([^#]*)"
	string.gsub(notify, "([^#]*)#[%a]([^#]*)", function(prefix, tag, suffix)
		local arg = args[currentArg]
		local internalArg = false

		if string.IsValid(prefix) then
			table.insert(notifyArgs, color_white)
			table.insert(notifyArgs, prefix)
		end

		local keyword = string.sub(tag, -1, -1)

		if keyword == callerKeyword then
			local isRCon = !IsValid(caller)

			if isRCon then
				table.insert(notifyArgs, serverColor)
			end

			table.insert(notifyArgs, (!isRCon and caller) or "SERVER")

			internalArg = true
		elseif keyword == targetKeyword then
			BuildTargetString(notifyArgs, targets)

			internalArg = true
    	else
			table.insert(notifyArgs, valueColor)
			table.insert(notifyArgs, string.format(tag, tostring(arg)))
    	end

		if string.IsValid(suffix) then
			table.insert(notifyArgs, color_white)
			table.insert(notifyArgs, suffix)
		end

    	if !internalArg then
    		currentArg = currentArg + 1
    	end
	end)

	-- Network args to players and input them into CRXClass:Notify.
	-- OR
	-- Network finished msg table to players and have them use that.
end

setmetatable(CoreClass, {
	__call = function(tbl, ...)
		local instance = setmetatable({}, CoreClass)

        if instance.__constructor then
            instance:__constructor(...)
        end

		return instance
	end
})