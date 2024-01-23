local function BuildCommandButton(parent, command)
    -- If the command is invalid, don't add it.
    if !command:IsValid() then return end

    -- Don't add the button if we don't have permissions for the command.
    if !command:HasPermissions(LocalPlayer()) then return end

    local commandButton = collapsibleCategory:Add(command:GetName())

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

local function BuildCommandsTab(parent)
    if !IsValid(parent) then return end

    parent.CategoryList = vgui.Create("DCategoryList", parent)
    parent.CategoryList:DockMargin(5, 5, 5, 5)
    parent.CategoryList:Dock(LEFT)

    local categories = CRX:GetCategories()

    for _, category in pairs(categories) do
        -- If the category is invalid, don't add it.
        if !category:IsValid() then continue end

        local categoryName = category:GetName()
        local collapsibleCategory = parent.CategoryList:Add(categoryName)

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
    parent.CategoryList:InvalidateLayout(true)

    -- TODO: Build parent.EntityList and parent.ParameterList.

    function parent:GetSelectedCommand()
        return self.SelectedCommand
    end

    function parent:SetSelectedCommand(command)
        self.SelectedCommand = command
    end
end

hook.Add("CRX_Initialized", "GUI_BaseTabs", function()
    local GUI = CRX:GetGUI()

	-- Commands tab
    GUI:AddTab("Commands", "icon16/script_code.png", BuildCommandsTab)

    -- Usergroups tab
    GUI:AddTab("Groups", "icon16/group.png", BuildGroupsTab, PerformLayoutGroups)

    -- Settings tab
    -- TODO: Make this always be the last tab.
    GUI:AddTab("Settings", "icon16/cog.png", BuildSettingsTab, PerformLayoutSettings)
end)