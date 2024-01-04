AddCSLuaFile("crx/shared/sh_core.lua")
include("crx/shared/sh_core.lua")

-- Module loader
local folderString = "crx/modules/%s"
local _, folders = file.Find("crx/modules/*", "LUA")

for _, folder in ipairs(folders) do
    local moduleFolder = string.format(folderString, folder)
    local clFiles = file.Find(table.concat({moduleFolder, "/cl_*.lua"}), "LUA")
    local shFiles = file.Find(table.concat({moduleFolder, "/sh_*.lua"}), "LUA")
    local svFiles = file.Find(table.concat({moduleFolder, "/sv_*.lua"}), "LUA")

    for _, f in ipairs(shFiles) do
        include(moduleFolder .. "/" .. f)
        AddCSLuaFile(moduleFolder .. "/" .. f)
    end

    if SERVER then
        for _, f in ipairs(svFiles) do
            include(moduleFolder .. "/" .. f)
        end
    end

    for _, f in ipairs(clFiles) do
        if SERVER then
            AddCSLuaFile(moduleFolder .. "/" .. f)
        else
            include(moduleFolder .. "/" .. f)
        end
    end
end