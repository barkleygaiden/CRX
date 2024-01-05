-- Construct CRX Class
CRX = CRX or CRXClass()

-- Construct Database Class
CRXDatabase = CRXDatabaseClass()

-- Hooks below
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

    local userGroups = CRXDatabase:GetUserGroups()

 	-- TODO: Make net class
    for steamID, userGroup in pairs(userGroups) do end
end)