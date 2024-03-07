if SERVER then
    hook.Add("Initialize", "CRX_Database_Init", function()
        local database = CRX:GetDatabase()

        database:Initialize()
    end)

    hook.Add("PlayerFullLoad", "CRX_Net_PlayerInit", function(ply)
        local cNet = CRX:GetNet()

        -- Networks all users and usergroups to the connected player.
        cNet:Initialize(ply)
    end)
else
    -- TODO: Make this shared
    hook.Add("Think", "CRX_Core_Think", function()
        if !CRX then return end

        CRX:Think()
    end)
end