-- Panels here

hook.Add("CRX_Initialized", "GUI_BaseTab_Groups", function()
    local GUI = CRX:GetGUI()

    -- Usergroups tab
    GUI:AddTab("Groups", "icon16/group.png", BuildGroupsTab)
end)