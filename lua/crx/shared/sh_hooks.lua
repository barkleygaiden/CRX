if SERVER then
    hook.Add("Initialize", "CRXDatabaseInit", function()
        if !CRX then return end

        local database = CRX:GetDatabase()

        database:Initialize()
    end)

    local loadQueue = {}

    hook.Add("PlayerInitialSpawn", "CRXPlayerInit", function(ply)
        loadQueue[ply] = true
    end)

    hook.Add("SetupMove", "CRXPlayerInit", function(ply, mv, cmd)
        if !IsValid(ply) then return end

        -- Check if networking has already been done
        if !(loadQueue[ply] and !cmd:IsForced()) then return end

        loadQueue[ply] = nil

        local cNet = CRX:GetNet()

        -- Networks all users and usergroups to the connected player.
        cNet:Initialize(ply)
    end)
else
    -- TODO: Make this shared
    hook.Add("Think", "CRXThink", function()
        if !CRX then return end

        CRX:Think()
    end)
end