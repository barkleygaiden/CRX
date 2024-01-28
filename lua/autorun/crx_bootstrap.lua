-- CSLua
AddCSLuaFile("crx/shared/sh_enum.lua")
AddCSLuaFile("crx/shared/classes/sh_crx.lua")
AddCSLuaFile("crx/shared/classes/sh_category.lua")
AddCSLuaFile("crx/shared/classes/sh_command.lua")
AddCSLuaFile("crx/shared/classes/sh_database.lua")
AddCSLuaFile("crx/shared/classes/sh_net.lua")
AddCSLuaFile("crx/shared/classes/sh_parameter.lua")

if SERVER then
    AddCSLuaFile("crx/client/classes/cl_gui.lua")
    AddCSLuaFile("crx/client/cl_tab_commands.lua")
    AddCSLuaFile("crx/client/cl_tab_groups.lua")
    AddCSLuaFile("crx/client/cl_tab_settings.lua")
end

-- Core can only be loaded after all the class files are
AddCSLuaFile("crx/shared/sh_core.lua")
AddCSLuaFile("crx/shared/sh_hooks.lua")
AddCSLuaFile("crx/shared/sh_meta.lua")

-- Includes
include("crx/shared/sh_enum.lua")
include("crx/shared/classes/sh_crx.lua")
include("crx/shared/classes/sh_category.lua")
include("crx/shared/classes/sh_command.lua")
include("crx/shared/classes/sh_database.lua")
include("crx/shared/classes/sh_net.lua")
include("crx/shared/classes/sh_parameter.lua")

if CLIENT then
    include("crx/client/classes/cl_gui.lua")
    include("crx/client/cl_tab_commands.lua")
    include("crx/client/cl_tab_groups.lua")
    include("crx/client/cl_tab_settings.lua")
end

-- Core can only be loaded after all the class files are
include("crx/shared/sh_enum.lua")
include("crx/shared/sh_core.lua")
include("crx/shared/sh_hooks.lua")
include("crx/shared/sh_meta.lua")

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