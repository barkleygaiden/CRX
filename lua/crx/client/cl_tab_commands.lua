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
        local selectedCommand = parent:GetSelectedCommand()

        if !selectedCommand then return end

        local entityParameter = selectedCommand.EntityType
        local entTable = (entityParameter == CRX_PARAMETER_PLAYER and player.Iterator()) or ents.Iterator()

        for i, ent in entTable do
            if !IsValid(ent) then continue end

            -- TODO: Check if entity is frozen.

            BuildEntityRow(self, ent, entityParameter)
        end
    end

    function entityList:Invalidate()
        local selectedCommand = parent:GetSelectedCommand()
        local entityParameter = selectedCommand.EntityType

        -- If a new command is selected and the entity parameter is the same, do nothing.
        if selectedCommand and entityParameter == self.EntityType then return end

        -- Clear all existing columns.
        self:ClearInternalPanels("Columns")

        -- Clear all existing rows.
        self:ClearInternalPanels("Lines")

        -- Enable the panel in case it's disabled.
        self:SetEnabled(true)

        -- This command doesn't have an entity parameter, so disable the list.
        if !selectedCommand or !selectedCommand.HasEntityParameter then
            self:AddColumn("N/A")
            self:SetEnabled(false)

            -- Set the current entity parameter to nothing so the first check isn't true.
            self.EntityType = 1

            return
        end
        
        local columnName = (entityParameter == CRX_PARAMETER_ENTITY and "Distance") or "SteamID"

        -- Adds the parameter columns.
        self:AddColumn("Name")
        self:AddColumn(columnName)

        -- Build our list's rows.
        self:BuildRows()

        -- Set the current entity parameter for later use.
        self.EntityType = entityParameter
    end

    return entityList
end

local noneString = "*no command*"
local actionString = "Do '%s'"

local function BuildParameterList(parent)
    if !IsValid(parent) then return end

    local parameterList = vgui.Create("DPanel", parent)
    parameterList:DockMargin(5, 5, 5, 5)
    parameterList:Dock(RIGHT)

    local oldInitialize = parameterList.Initialize

    function parameterList:Initialize()
        self.ParameterPanels = {}
    end

    function parameterList:ClearParameters()
        if table.IsEmpty(self.ParameterPanels) then return end

        for i = 1, #self.ParameterPanels do
            local panel = self.ParameterPanels[i]

            if !IsValid(panel) then continue end

            panel:Remove()
        end
    end

    function parameterList:GetButton()
        return self.DoButton
    end

    function parameterList:Invalidate()
        -- Clears all children except for the do command button.
        self:ClearParameters()

        local command = parent:GetSelectedCommand()

        if !command or !command:IsValid() then return end

        -- Create parameter panels.
    end

    local doButton = vgui.Create("DButton", parent)
    doButton:DockMargin(5, 5, 5, 5)
    doButton:Dock(BOTTOM)
    doButton:SetEnabled(false)
    doButton:SetText(noneString)

    -- Possibilities:
    -- No command selected
    -- All good, can do command
    -- Missing parameter
    -- No targets selected

    function doButton:InvalidateText()
        -- TODO

        self:SetText(newText)
    end

    parameterList.DoButton = doButton

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