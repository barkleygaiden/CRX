-- CSLua
AddCSLuaFile("crx/shared/sh_enum.lua")
AddCSLuaFile("crx/shared/sh_crx.lua")
AddCSLuaFile("crx/shared/sh_core.lua")
AddCSLuaFile("crx/shared/sh_category.lua")
AddCSLuaFile("crx/shared/sh_command.lua")
AddCSLuaFile("crx/shared/sh_database.lua")
AddCSLuaFile("crx/shared/sh_net.lua")
AddCSLuaFile("crx/shared/sh_meta.lua")

-- Includes
include("crx/shared/sh_enum.lua")
include("crx/shared/sh_crx.lua")
include("crx/shared/sh_core.lua")
include("crx/shared/sh_category.lua")
include("crx/shared/sh_command.lua")
include("crx/shared/sh_database.lua")
include("crx/shared/sh_net.lua")
include("crx/shared/sh_meta.lua")

if SERVER then
    include("crx/shared/sv_hooks.lua")
end

-- Module loader
local folderString = "crx/modules/%s/%s"
local _, folders = file.Find("crx/modules/*", "LUA")

for _, folder in ipairs(folders) do
    local moduleFolder = string.format(folderString, folder)
    local clFiles = file.Find(string.format(moduleFolder, "/cl_*.lua"), "LUA")
    local shFiles = file.Find(string.format(moduleFolder, "/sh_*.lua"), "LUA")
    local svFiles = file.Find(string.format(moduleFolder, "/sv_*.lua"), "LUA")

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