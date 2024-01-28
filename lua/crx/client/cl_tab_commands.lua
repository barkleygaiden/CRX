local function BuildCommandButton(parent, categorylist, command)
    if !IsValid(parent) or IsValid(categorylist) then return end

    -- If the command is invalid, don't add it.
    if !command:IsValid() then return end

    -- Don't add the button if we don't have permissions for the command.
    if !command:HasPermissions(LocalPlayer()) then return end

    local commandButton = categorylist:Add(command:GetName())
    local oldInitialize = commandButton.Initialize

    function commandButton:Initialize()
        self.Command = command
    end

    function commandButton:DoClick()
        local command = parent:GetSelectedCommand()

        -- Unselect all commands if one is selected.
        if command and command:IsValid() then
            parent.CategoryList:UnselectAll()
        end

        -- If the selected command is already this one, set selected command to nothing.
        if command and command == self.Command then
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

    for _, category in pairs(categories) do
        -- If the category is invalid, don't add it.
        if !category:IsValid() then continue end

        local categoryName = category:GetName()
        local collapsibleCategory = categoryList:Add(categoryName)

        -- This shouldn't ever happen.
        if !IsValid(collapsibleCategory) then return end

        local commands = CRX:GetCommandsFromCategory(category)

        for i = 1, #commands do
            local command = commands[i]

            -- Local function to avoid pyramid hell.
            BuildCommandButton(command)
        end
    end

    -- DCategoryList has some internal scaling in it's PerformLayout.
    categoryList:InvalidateLayout(true)

    return categoryList
end

local emptyString = ""
local propString = "prop_"
local nullModelString = "NULL"
local propNameString = "%s(%s)"
local mouseLeftOrRight = bit.bor(MOUSE_LEFT, MOUSE_RIGHT)

local function BuildEntityRow(entitylist, ent, parameter)
    if !IsValid(entitylist) then return end

    local class = ent:GetClass()

    -- If parameter is props only and our entity isn't a prop, then don't add it as a row.
    if parameter == CRX_PARAMETER_PROP and string.sub(class, 1, 5) != propString then return end

    -- We don't want internal map entites being included in our list.
    if parameter == CRX_PARAMETER_ENTITY and ent:CreatedByMap() then return end

    local row = entitylist:AddLine(emptyString, emptyString)
    local oldInitialize = row.Initialize

    function row:Initialize()
        oldInitialize(self)

        self.Entity = ent
        self.Parameter = parameter

        local firstText, secondText = self:GetRowText()

        self:SetColumnText(1, firstText)

        if parameter != CRX_PARAMETER_PLAYER then return end

        self:SetColumnText(2, secondText)
    end

    local oldSetEnabled = row.SetEnabled

    function row:SetEnabled(bool)
        oldSetEnabled(self, bool)

        local listView = self:GetParent():GetParent()
        local id = self:GetID()

        if bool then
            listView.SelectedRows[id] = true
        else
            listView.SelectedRows[id] = nil
        end
    end

    function row:GetEntity()
        return self.Entity
    end

    function row:GetParameter()
        return self.Parameter
    end

    function row:GetRowText()
        local firstText = (parameter == CRX_PARAMETER_PLAYER and ent:Nick()) or ent:GetName()

        if parameter == CRX_PARAMETER_PROP then
            local model = string.GetFileFromFilename(ent:GetModel()) or nullModelString

            firstText = string.format(propNameString, firstText, model)
        end

        local secondText = parameter == CRX_PARAMETER_PLAYER and ent:SteamID64()

        return firstText, secondText
    end

    -- Players don't need to have their position checked.
    if parameter == CRX_PARAMETER_PLAYER then return end

    function row:Think()
        local curTime = CurTime()

        if (self.LastThink or 0) + 1 >= curTime then return end
        if !IsValid(self.Entity) then return end

        local feetDistance = math.Round(self.Entity:Distance() / 16, 2)
        local distanceString = string.format(distFormatString, feetDistance)

        -- Updates distance. 
        self:SetColumnText(2, distanceString)

        self.LastThink = curTime
    end
end

-- Columns
-- CRX_PARAMETER_ENTITY (name // distance)
-- CRX_PARAMETER_PLAYER (name // steamid)

local distFormatString = "%aft"
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

        self.EntityType = 1

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

        local entityParameter = command.EntityParameter
        local entTable = (entityParameter == CRX_PARAMETER_PLAYER and player.Iterator()) or ents.Iterator()

        for i, ent in entTable do
            if !IsValid(ent) then continue end

            -- TODO: Check if entity is frozen.

            local row = BuildEntityRow(self, ent, entityParameter)

            -- Add the row to our hashtable.
            self.EntityRows[ent] = row
        end
    end

    function entityList:RemoveRow(ent)
        if IsValid(ent) then return end

        local row = self.EntityRows[ent]

        if !IsValid(row) then return end

        self:RemoveLine(row:GetID())

        -- Remove the row from our hashtable.
        self.EntityRows[ent] = nil
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
        local entityParameter = command.EntityParameter

        -- If a new command is selected and the entity parameter is the same, do nothing.
        if command and (entityParameter or 0) == self.EntityType then return end

        -- Clear all existing columns.
        self:ClearInternalPanels("Columns")

        -- Clear all existing rows.
        self:ClearInternalPanels("Lines")

        -- Enable the panel in case it's disabled.
        self:SetEnabled(true)

        -- Clear our row hashtable.
        self.EntityRows = {}

        -- This command doesn't have an entity parameter, so disable the list.
        if !command or !command.EntityParameter then
            self:AddColumn("N/A")
            self:SetEnabled(false)

            -- Set the current entity parameter to nothing so the first check isn't true.
            self.EntityType = 1

            -- Remove our hooks if we have any.
            self:RemoveHooks()

            return
        end
        
        local columnName = (entityParameter == CRX_PARAMETER_ENTITY and "Distance") or "SteamID"

        -- Adds the parameter columns.
        self:AddColumn("Name")
        self:AddColumn(columnName)

        -- Build our list's rows.
        self:BuildRows()

        -- Add our hooks and remove the old ones if they exist.
        self:AddHooks()

        -- Set the current entity parameter for later use.
        self.EntityType = entityParameter
    end

    return entityList
end

local noneString = "*no command*"
local noTargetsString = "*no targets selected*"
local missingString = "*missing '%s'"
local actionString = "Do '%s'"

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

        self.ParameterPanels = {}
        self.Parameters = {}
        self.Args = {}
    end

    function parameterList:GetButton()
        return self.DoButton
    end

    function parameterList:SetButton(button)
        self.DoButton = button
    end

    function parameterList:GetArgs()
        return self.Args
    end

    function parameterList:GetParameters()
        return self.Parameters
    end

    function parameterList:BuildParameterPanels()
        for i = 1, #parameters do
            local parameter = parameters[i]

            if !parameter:IsValid() then continue end

            local parameterType = parameter:GetType()

            -- TODO: Finish this (DCheckBox, DNumberWang, DTextEntry)
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

    function doButton:InvalidateText()
        local command = parent:GetSelectedCommand()

        -- If no command is selected, return end.
        if !command or !command:IsValid() then
            self:SetText(noneString)

            return
        end

        local targetList = parent.EntityList.SelectedRows

        -- If we have an entity parameter and no targets are selected, return end.
        if command.EntityParameter and table.IsEmpty(targetList) then
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
    end

    return parameterList
end

local function BuildCommandsTab(parent)
    if !IsValid(parent) then return end

    parent.CategoryList = BuildCommandList(parent)
    parent.EntityList = BuildEntityList(parent)
    parent.ParameterList = BuildParameterList(parent)

    -- TODO: Build parent.EntityList and parent.ParameterList.

    function parent:GetSelectedCommand()
        return self.SelectedCommand
    end

    function parent:SetSelectedCommand(command)
        self.SelectedCommand = command
    end
end

hook.Add("CRX_Initialized", "GUI_BaseTab_Commands", function()
    local GUI = CRX:GetGUI()

    -- Commands tab
    GUI:AddTab("Commands", "icon16/script_code.png", BuildCommandsTab)
end)