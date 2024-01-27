-- Panels here

hook.Add("CRX_Initialized", "GUI_BaseTab_Settings", function()
    local GUI = CRX:GetGUI()

    -- Usergroups tab
    GUI:AddTab("Settings", "icon16/group.png", BuildGroupsTab)
end)