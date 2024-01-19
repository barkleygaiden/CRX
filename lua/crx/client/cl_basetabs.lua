hook.Add("CRX_Initialized", "GUI_BaseTabs", function()
    local GUI = CRX:GetGUI()

	-- Commands tab
    GUI:AddTab("Commands", "icon16/script_code.png", BuildCommandsTab)

    -- Usergroups tab
    GUI:AddTab("Groups", "icon16/group.png", BuildGroupsTab)

    -- Settings tab
    -- TODO: Make this always be the last tab.
    GUI:AddTab("Settings", "icon16/cog.png", BuildSettingsTab)
end)