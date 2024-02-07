local function BuildCommandButton(parent, categorylist, command)
    if !IsValid(parent) or IsValid(categorylist) then return end

    -- If the command is invalid, don't add it.
    if !command:IsValid() then return end

    -- Don't add the button if we don't have permissions for the command.
    if !command:HasPermissions(LocalPlayer()) then return end

    local commandButton = categorylist:Add(command:GetName())
    local oldInitialize = commandButton.Initialize

    function commandButton:Initialize()
        oldInitialize(self)

        self.Command = command

        local description = command:GetDescription()

        if !description then return end

        -- If the command has a description, create a tooltip for it.
        self:SetTooltip(description)
    end

    function commandButton:DoClick()
        local selectedCommand = parent:GetSelectedCommand()

        -- Unselect all commands if one is selected.
        if selectedCommand and selectedCommand:IsValid() then
            parent.CategoryList:UnselectAll()
        end

        -- If the selected command is already this one, set selected command to nothing.
        if selectedCommand and selectedCommand == self.Command then
            parent:SetSelectedCommand(nil)
        else
            parent:SetSelectedCommand(self.Command)
        end

        if !IsValid(parent.EntityList) then return end

        parent.EntityList:Invalidate()

        if !IsValid(parent.ParameterList) then return end

        parent.ParameterList:Invalidate()
    end

    return commandButton
end

local function BuildCommandList(parent)
    if !IsValid(parent) then return end

    local categoryList = vgui.Create("DCategoryList", parent)
    categoryList:DockMargin(5, 5, 5, 5)
    categoryList:Dock(LEFT)

    local categories = CRX:GetCategories()

    for _, category in SortedPairs(categories) do
        -- If the category is invalid, don't add it.
        if !category:IsValid() then continue end

        local categoryName = category:GetName()
        local collapsibleCategory = categoryList:Add(categoryName)

        -- This shouldn't ever happen.
        if !IsValid(collapsibleCategory) then return end

        local commands = category:GetCommands()

        for _, command in SortedPairs(commands) do
            -- Local function to avoid pyramid hell.
            BuildCommandButton(command)
        end
    end

    -- DCategoryList has some internal scaling in it's PerformLayout.
    categoryList:InvalidateLayout(true)

    return categoryList
end

local function GetPlayerText(ent, parameter)
    local firstText = ent:Nick()
    local secondText = parameter == CRX_PARAMETER_PLAYER and ent:SteamID64()

    return firstText, secondText
end

local emptyString = ""

local function BuildEntityRow(entitylist, ent, parameter)
    if !IsValid(entitylist) then return end

    local row = entitylist:AddLine(emptyString, emptyString)
    local oldInitialize = row.Initialize

    -- TODO: If all other rows in list selected, enable this row.

    function row:Initialize()
        oldInitialize(self)

        AccessorFunc(self, "Entity", "Entity")
        AccessorFunc(self, "Parameter", "Parameter")

        self.Entity = ent
        self.Parameter = parameter

        -- This gets the name of the player and their SteamID64.
        local firstText, secondText = GetPlayerText(ent, parameter)

        self:SetColumnText(1, firstText)
        self:SetColumnText(2, secondText)
    end

    local oldSetEnabled = row.SetEnabled

    function row:SetEnabled(bool)
        oldSetEnabled(self, bool)

        local listView = self:GetParent():GetParent()
        local id = self:GetID()
        local selectedStatus = listView.SelectedRows[id] != nil

        -- If the selected status is already the same as the bool, halt.
        if bool == selectedStatus then return end

        -- Add or remove the row from our selected rows table.
        if bool then
            listView.SelectedRows[id] = self.Entity
        else
            listView.SelectedRows[id] = nil
        end

        -- Add or subtract 1 from our selected rows count.
        listView.SelectedCount = listView.SelectedCount + ((selectedStatus and 1) or -1)

        local parameterList = listView:GetParent():GetParameterList()

        if !parameterList then return end

        local currentArgs = parameterList:GetArgs()
        local argIndex = parameter:GetParent().TargetIndex

        -- Insert the target table into our args table using the parameter's parent's index.
        currentArgs[argIndex] = listView:GetTargetList()
    end
end

local hookName = "CRX_GUI_Commands%i"
local entAddHook = "OnEntityCreated"
local entRemoveHook = "EntityRemoved"

local function BuildEntityList(parent)
    if !IsValid(parent) then return end

    local entityList = vgui.Create("DListView", parent)
    entityList:DockMargin(5, 5, 5, 5)
    entityList:Dock(FILL)
    entityList:SetEnabled(false)

    local oldInitialize = entityList.Initialize

    function entityList:Initialize()
        oldInitialize(self)

        AccessorFunc(self, "SelectedCount", "SelectedCount")
        AccessorFunc(self, "EntityRows", "EntityRows")
        AccessorFunc(self, "SelectedRows", "SelectedRows")

        self.EntityType = 1
        self.SelectedCount = 0

        self.EntityRows = {}
        self.SelectedRows = {}
    end

    function entityList:ClearInternalPanels(tbl)
        local panels = self[tbl]

        -- If we don't have any panels in the table or it doesn't exist, then don't clear.
        if !panels or table.IsEmpty(panels) then return end

        for i = 1, #panels do
            local panel = panels[i]

            if !IsValid(panel) then continue end

            panel:Remove()
        end

        -- Empties the internal panel table.
        self[tbl] = {}
    end

    function entityList:BuildRows()
        local command = parent:GetSelectedCommand()

        if !command then return end

        local parameterType = entityParameter:GetType()

        for _, ply in player.Iterator() do
            if !IsValid(ply) then continue end

            local row = BuildEntityRow(self, ply, parameterType)

            -- Add the row to our hashtable.
            self.EntityRows[ply] = row
        end
    end

    function entityList:RemoveRow(ent)
        if IsValid(ent) then return end

        local row = self.EntityRows[ent]

        if !IsValid(row) then return end

        -- Remove the row from our SelectedRows table.
        row:SetEnabled(false)

        self:RemoveLine(row:GetID())

        -- Remove the row from our hashtable.
        self.EntityRows[ent] = nil
    end

    function entityList:GetTargetList()
        local targets = self.SelectedRows

        if !targets then return end

        -- Compares the length of the list's line table to our selected count, if false we are not selecting everyone/everything.
        if #self.Lines != self.SelectedCount then return targets end

        return "*"
    end

    function entityList:AddHooks()
        -- If we have a valid hook identifier, then remove hooks if they exist.
        if self.HookName then self:RemoveHooks() end

        self.HookName = string.format(hookName, math.random(1, 16384))

        hook.Add(entAddHook, self.HookName, function(ent, fullupdate)
            if fullupdate then return end

            timer.Simple(0, function()
                if !IsValid(ent) then return end

                local row = BuildEntityRow(self, ent, self.EntityType)

                -- Add the row to our hashtable.
                self.EntityRows[ent] = row
            end)
        end)

        hook.Add(entRemoveHook, self.HookName, function(ent, fullupdate)
            if fullupdate then return end

            timer.Simple(0, function()
                self:RemoveRow(ent)
            end)
        end)
    end

    function entityList:RemoveHooks()
        if !self.HookName then return end

        local hooks = hook.GetTable()

        if hooks[entAddHook][self.HookName] then
            hook.Remove(entAddHook, self.HookName)
        end

        if hooks[entRemoveHook][self.HookName] then
            hook.Remove(entRemoveHook, self.HookName)
        end

        self.HookName = nil
    end

    function entityList:Invalidate()
        local command = parent:GetSelectedCommand()
        local targetParameter = command and command.TargetParameter
        local entityType = targetParameter and targetParameter:GetType()

        -- If our target parameter does not allow multiple targets, then disallow multiselect.
        if targetParameter then
            self:SetMultiSelect(targetParameter:CanTargetMultiple())
        end

        -- If a new command is selected and a valid target parameter is present, do nothing.
        if command and (entityType or 0) == self.EntityType then return end

        -- Clear all existing columns.
        self:ClearInternalPanels("Columns")

        -- Clear all existing rows.
        self:ClearInternalPanels("Lines")

        -- Enable the panel in case it's disabled.
        self:SetEnabled(true)

        -- Clear our row hashtable.
        self.EntityRows = {}

        -- Set our selected rows count to 0.
        self.SelectedCount = 0

        -- This command doesn't have a target parameter, so disable the list.
        if !command or !targetParameter then
            self:AddColumn("N/A")
            self:SetEnabled(false)

            -- Set the current entity parameter to nothing so the first check isn't true.
            self.EntityType = 1

            -- Remove our hooks if we have any.
            self:RemoveHooks()

            return
        end

        -- Adds the parameter columns.
        self:AddColumn("Name")
        self:AddColumn("SteamID")

        -- Build our list's rows.
        self:BuildRows()

        -- Add our hooks and remove the old ones if they exist.
        self:AddHooks()

        -- Set the current entity parameter for later use.
        self.EntityType = entityType
    end

    return entityList
end

local descriptionHyphen = "%s - %s"

local function BuildBoolBox(parent, parameter, index)
    if !IsValid(parent) then return end

    local canvasPanel = vgui.Create("DPanel", parent)
    canvasPanel:Dock(TOP)
    canvasPanel:DockMargin(5, 5, 5, 5)

    -- Set checked status to default, false if optional, true otherwise.
    local defaultStatus = parameter:GetDefault() or (parameter:IsOptional() and false) or true
    local oldInitialize = canvasPanel.Initialize

    function canvasPanel:Initialize()
        oldInitialize(self)

        self.Parameter = parameter
        self.ArgIndex = index

        local name = parameter:GetName()
        local description = parameter:GetDescription()
        local labelText = (description and string.format(descriptionHyphen, name, description)) or name

        self.NameLabel = vgui.Create("DLabel", self)
        self.NameLabel:Dock(TOP)
        self.NameLabel:SetText(labelText)
    end

    local checkBox = vgui.Create("DCheckBox", canvasPanel)
    checkBox:Dock(FILL)
    checkBox:SetChecked(defaultStatus)

    function checkBox:OnValueChange(val)
        local parameterList = canvasPanel:GetParent()
        local args = parameterList:GetArgs()

        if !args then return end

        args[canvasPanel.ArgIndex] = val
    end

    return canvasPanel
end

local function BuildNumberBox(parent, parameter, index)
    if !IsValid(parent) then return end

    local canvasPanel = vgui.Create("DPanel", parent)
    canvasPanel:Dock(TOP)
    canvasPanel:DockMargin(5, 5, 5, 5)

    -- Gets default number if we have one.
    local defaultNumber = parameter:GetDefault()
    local oldInitialize = canvasPanel.Initialize

    function canvasPanel:Initialize()
        oldInitialize(self)

        self.Parameter = parameter
        self.ArgIndex = index

        local name = parameter:GetName()
        local description = parameter:GetDescription()
        local labelText = (description and string.format(descriptionHyphen, name, description)) or name

        self.NameLabel = vgui.Create("DLabel", self)
        self.NameLabel:Dock(TOP)
        self.NameLabel:SetText(labelText)
    end

    local numberBox = vgui.Create("DNumberWang", canvasPanel)
    numberBox:Dock(FILL)
    numberBox:SetMin(0)

    if defaultNumber then
        numberBox:SetValue(defaultNumber)
    end

    function numberBox:OnValueChange(val)
        local parameterList = canvasPanel:GetParent()
        local args = parameterList:GetArgs()

        if !args then return end

        args[canvasPanel.ArgIndex] = val or defaultNumber
    end

    return canvasPanel
end

local function BuildTextBox(parent, parameter, index)
    if !IsValid(parent) then return end

    local canvasPanel = vgui.Create("DPanel", parent)
    canvasPanel:Dock(TOP)
    canvasPanel:DockMargin(5, 5, 5, 5)

    -- Gets default string if we have one.
    local defaultString = parameter:GetDefault()
    local oldInitialize = canvasPanel.Initialize

    function canvasPanel:Initialize()
        oldInitialize(self)

        self.Parameter = parameter
        self.ArgIndex = index

        local name = parameter:GetName()
        local description = parameter:GetDescription()
        local labelText = (description and string.format(descriptionHyphen, name, description)) or name

        self.NameLabel = vgui.Create("DLabel", self)
        self.NameLabel:Dock(TOP)
        self.NameLabel:SetText(labelText)
    end

    local textBox = vgui.Create("DTextEntry", canvasPanel)
    textBox:Dock(FILL)

    if defaultString then
        textBox:SetValue(defaultString)
    end

    function textBox:OnValueChange(val)
        local parameterList = canvasPanel:GetParent()
        local args = parameterList:GetArgs()

        if !args then return end

        args[canvasPanel.ArgIndex] = val or defaultString
    end

    return canvasPanel
end

local function BuildEntityBox(parent, parameter, index)
    if !IsValid(parent) then return end

    local canvasPanel = vgui.Create("DPanel", parent)
    canvasPanel:Dock(TOP)
    canvasPanel:DockMargin(5, 5, 5, 5)

    local oldInitialize = canvasPanel.Initialize

    function canvasPanel:Initialize()
        oldInitialize(self)

        self.Parameter = parameter
        self.ArgIndex = index

        local name = parameter:GetName()
        local description = parameter:GetDescription()
        local labelText = (description and string.format(descriptionHyphen, name, description)) or name

        self.NameLabel = vgui.Create("DLabel", self)
        self.NameLabel:Dock(TOP)
        self.NameLabel:SetText(labelText)
    end

    local entityBox = vgui.Create("DComboBox", canvasPanel)
    entityBox:Dock(FILL)

    function entityBox:OnMenuOpened(menu)
        local selectedPlayer = self:GetSelected()

        for _, ply in player.Iterator() do
            if !IsValid(ply) then continue end

            -- This gets the name of an player and their SteamID64.
            local firstText, secondText = GetEntityText(ply, parameter)

            -- Format to get the final choice string.
            local choiceText = string.format(descriptionHyphen, firstText, secondText)

            -- If we have a selected player and it is this player, then select the choice after adding it.
            local shouldSelect = IsValid(selectedPlayer) and selectedPlayer == ply

            self:AddChoice(choiceText, ply, shouldSelect)

            local doButton = parent:GetButton()

            -- Invalidates the docommand button, checking to see if the command can be done or not.
            doButton:InvalidateText()
        end
    end

    function entityBox:OnSelect(index_, text, data)
        local parameterList = canvasPanel:GetParent()
        local args = parameterList:GetArgs()

        if !args then return end

        args[canvasPanel.ArgIndex] = data
    end

    return canvasPanel
end

local CRXColor = Color(200, 0, 0, 255)
local commandPrefix = "crx"
local noneString = "*no command*"
local noTargetsString = "*no targets selected*"
local missingString = "*missing '%s'"
local actionString = "Do '%s'"
local buildFunctions = {
    [CRX_PARAMETER_BOOL] = BuildBoolBox,
    [CRX_PARAMETER_NUMBER] = BuildNumberBox,
    [CRX_PARAMETER_STRING] = BuildTextBox,
    [CRX_PARAMETER_PLAYER] = BuildEntityBox
}

local function BuildParameterList(parent)
    if !IsValid(parent) then return end

    local canvasPanel = vgui.Create("DPanel", parent)
    canvasPanel:DockMargin(5, 5, 5, 5)
    canvasPanel:Dock(RIGHT)

    local parameterList = vgui.Create("DScrollPanel", canvasPanel)
    parameterList:Dock(FILL)

    local oldInitialize = parameterList.Initialize

    function parameterList:Initialize()
        oldInitialize(self)

        AccessorFunc(self, "Parameters", "Parameters")
        AccessorFunc(self, "Args", "Args")
        AccessorFunc(self, "DoButton", "Button")

        self.ParameterPanels = {}
        self.Parameters = {}
        self.Args = {}
    end

    function parameterList:BuildParameterPanels()
        for i = 1, #self.Parameters do
            local parameter = self.Parameters[i]

            if !parameter:IsValid() then continue end

            -- If this is the target parameter, skip it since it's handled in the entitylist panel.
            if parameter:IsTarget() then continue end

            local parameterType = parameter:GetType()
            local buildPanel = buildFunctions[parameterType]

            -- Better safe than sorry :P
            if !buildPanel then return end

            -- Builds our parameter panel based on the type (DCheckBox, DNumberWang, etc).
            local parameterPanel = buildPanel(self, parameter, i)

            -- Insert the parameter panel in our table for future removal.
            table.insert(self.ParameterPanels, parameterPanel)
        end
    end

    function parameterList:ClearParameterPanels()
        if table.IsEmpty(self.ParameterPanels) then return end

        for i = 1, #self.ParameterPanels do
            local panel = self.ParameterPanels[i]

            if !IsValid(panel) then continue end

            panel:Remove()
        end

        -- Empties the panel table.
        self.ParameterPanels = {}
    end

    function parameterList:Invalidate()
        -- Clears all parameter panels.
        self:ClearParameterPanels()

        -- Empties our inputted arguments table and command parameters table.
        self.Parameters = {}
        self.Args = {}

        local command = parent:GetSelectedCommand()

        if !command or !command:IsValid() then return end

        -- Store the command's parameters for future use.
        self.Parameters = command:GetParameters()

        -- Build our parameter panels.
        self:BuildParameterPanels()
    end

    local doButton = vgui.Create("DButton", canvasPanel)
    doButton:Dock(BOTTOM)
    doButton:SetEnabled(false)
    doButton:SetText(noneString)
    parameterList:SetButton(doButton)

    -- Command Scenarios:
    -- [PLAYER - CLIENT] GUI/Console
    -- [PLAYER - SERVER] PlayerSay
    -- [NONPLAYER - SERVER] Console

    function doButton:DoClick()
        local command = parent:GetSelectedCommand()

        -- If no command is selected somehow, return end.
        if !command or !command:IsValid() then
            chat.AddText(color_white, "[", CRXColor, "CRX", color_white, "] - Command is invalid, contact the server owner!")

            return
        end

        local commandLength = 0
        local parameters = self:GetParameters()
        local assembledArgs, currentArgs = {}, self:GetParent():GetArgs()

        for i = 1, #currentArgs do
            local parameter = parameters[i]
            local arg = currentArgs[i]

            -- Check if our parameter requires valid input.
            local argRequired = !(parameter:GetDefault() or parameter:IsOptional())

            -- If there is no arg, the parameter has no default, and it is not optional, then halt.
            if !arg and argRequired then return end

            local argString = parameter:ArgToString(arg)

            table.insert(assembledArgs, argString)

            -- Add to our command's character count.
            commandLength = commandLength + #argString
        end

        -- Console inputs are limited to ~255 characters.
        if commandLength > 240 then
            chat.AddText(color_white, "[", CRXColor, "CRX", color_white, "] - Command is too long, reduce your argument(s) length.")

            return
        end

        -- table.concat is much more efficient than unpack.
        local unpackedArgs = table.concat(assembledArgs, " ")

        -- Assemble and run our command string.
        RunConsoleCommand(commandPrefix, command:GetName(), unpackedArgs)

        local entityList = parent:GetEntityList()

        -- If the entity (target) list is disabled, we don't need to invalidate it.
        if !entityList:IsEnabled() then return end

        -- Invalidate the entity (target) list in case a player was kicked.
        entityList:Invalidate()
    end

    function doButton:InvalidateText()
        -- Disable the button as early as possible if the below checks don't pass.
        self:SetEnabled(false)

        local command = parent:GetSelectedCommand()

        -- If no command is selected, return end.
        if !command or !command:IsValid() then
            self:SetText(noneString)

            return
        end

        local targetList = parent:GetEntityList():GetSelectedRows()

        -- If we have a target parameter and no targets are selected, return end.
        if command.TargetParameter and table.IsEmpty(targetList) then
            self:SetText(noTargetsString)

            return
        end

        local isMissingParameter = false
        local parameters = self:GetParameters()
        local currentArgs = self:GetArgs()

        for i = 1, #parameters do
            local parameter = parameters[i]
            local arg = currentArgs[i]

            -- If there is no arg, the parameter has no default, and it is not optional, then throw a warning.
            if arg or parameter:GetDefault() or parameter:IsOptional() then continue end

            local missingText = string.format(missingString, parameter:GetName())

            self:SetText(missingText)

            isMissingParameter = true

            break
        end

        -- If we're missing a parameter then we don't set the docommand text.
        if isMissingParameter then return end

        local doText = string.format(actionString, command:GetName())

        self:SetText(doText)
        self:SetEnabled(true)
    end

    return parameterList
end

local function BuildCommandsTab(parent)
    if !IsValid(parent) then return end

    local categoryList = BuildCommandList(parent)
    local entityList = BuildEntityList(parent)
    local parameterList = BuildParameterList(parent)

    AccessorFunc(parent, "CategoryList", "CategoryList")
    AccessorFunc(parent, "EntityList", "EntityList")
    AccessorFunc(parent, "ParameterList", "ParameterList")
    AccessorFunc(parent, "SelectedCommand", "SelectedCommand")

    parent:SetCategoryList(categoryList)
    parent:SetEntityList(entityList)
    parent:SetParameterList(parameterList)
end

hook.Add("CRX_Initialized", "GUI_BaseTab_Commands", function()
    local GUI = CRX:GetGUI()

    -- Commands tab
    GUI:AddTab("Commands", "icon16/script_code.png", BuildCommandsTab)
end)