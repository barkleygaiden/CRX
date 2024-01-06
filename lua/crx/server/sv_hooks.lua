hook.Add("Initialize", "CRXDatabaseInit", function()
    if !CRXDatabase then return end

    CRXDatabase:Initialize()
end)

local loadQueue = {}

hook.Add("PlayerInitialSpawn", "CRXPlayerInit", function(ply)
    loadQueue[ply] = true
end)

hook.Add("SetupMove", "CRXPlayerInit", function(ply, mv, cmd)
    if !Atmos:GetEnabled() then return end
    if !IsValid(ply) then return end

    -- Check if networking has already been done
    if !(loadQueue[ply] and !cmd:IsForced()) then return end

    loadQueue[ply] = nil

 	-- TODO: Make net class
end)