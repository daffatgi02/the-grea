-- resources/[thegreatwar]/thegreatwar-core/server/roles.lua
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerRoles = {}

function SetPlayerRole(src, roleName)
    if not Config.roles[roleName] then return false end
    
    PlayerRoles[src] = roleName
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- Clear inventory
    Player.Functions.ClearInventory()
    
    -- Give role-specific equipment
    local role = Config.roles[roleName]
    for _, weapon in ipairs(role.weapons) do
        Player.Functions.AddItem(weapon, 1)
    end
    
    -- Give role-specific items
    if roleName == "medic" then
        Player.Functions.AddItem("bandage", 5)
    elseif roleName == "support" then
        Player.Functions.AddItem("pistol_ammo", 500)
        Player.Functions.AddItem("rifle_ammo", 1000)
    elseif roleName == "assault" then
        Player.Functions.AddItem("armor", 5)
    end
    
    TriggerClientEvent('thegreatwar:roleEquipped', src, role)
    return true
end

function GetPlayerRole(src)
    return PlayerRoles[src]
end

function ApplyRoleAbilities(src, abilityType, value)
    local role = GetPlayerRole(src)
    if not role or not Config.roles[role] then return value end
    
    local abilities = Config.roles[role].abilities
    if abilities[abilityType] then
        return value * abilities[abilityType]
    end
    
    return value
end

-- Network Events
RegisterNetEvent('thegreatwar:selectRole', function(roleName)
    local src = source
    if SetPlayerRole(src, roleName) then
        TriggerClientEvent('QBCore:Notify', src, "Role selected: " .. Config.roles[roleName].name, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Invalid role", "error")
    end
end)

-- Exports
exports('GetPlayerRole', GetPlayerRole)
exports('ApplyRoleAbilities', ApplyRoleAbilities)