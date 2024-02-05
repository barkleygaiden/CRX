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

	return newCommand
end

function CRXClass:CommandExists(name)
	local command = self.Commands[name]

	return command and command:IsValid()
end

local leftParenthesis = "("
local rightParenthesis = ")"

function CRXClass:FormatArgs(args)
	local queuedRemovals = {}
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
		    table.insert(queuedRemovals, i)
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
	for i = 1, #queuedRemovals do
		table.remove(args, queuedRemovals[i] - amountRemoved)

		-- Because we removed a key, we need to shift all future removals down by 1.
		amountRemoved = amountRemoved + 1
	end

	return args
end

function CRXClass:IsSyntaxValid(args)
	for i = 1, #args
		local arg = args[i]

		-- TODO: check target keyword validity
		-- TODO: check if self can be targeted
		-- TODO: check if we can target multiple people
		-- TODO: check if bool is valid
		-- TODO: check if number is number
	end

	return true
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
	local validSyntax, errorMessage = self:IsSyntaxValid(formattedArgs)

	-- TODO: MsgC + chat.AddText on client.
	if !validSyntax then return end

	-- Process the command inside of it's object.
	command:DoCommand(ply, cmd, formattedArgs, argstr)
end