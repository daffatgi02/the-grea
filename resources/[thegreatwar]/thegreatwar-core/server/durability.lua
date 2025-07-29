-- resources/[thegreatwar]/thegreatwar-core/server/durability.lua
local QBCore = exports['qb-core']:GetCoreObject()
local playerWeaponDurability = {}

RegisterNetEvent('thegreatwar:updateWeaponDurability', function(weapon, durability)
    local src = source
    if not playerWeaponDurability[src] then
        playerWeaponDurability[src] = {}
    end
    playerWeaponDurability[src][weapon] = durability
end)

RegisterNetEvent('thegreatwar:weaponBroken', function(weapon)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    Player.Functions.RemoveItem(weapon, 1)
    
    if playerWeaponDurability[src] then
        playerWeaponDurability[src][weapon] = nil
    end
end)

function GiveWeaponWithDurability(src, weapon, durability)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    Player.Functions.AddItem(weapon, 1)
    
    if not playerWeaponDurability[src] then
        playerWeaponDurability[src] = {}
    end
    playerWeaponDurability[src][weapon] = durability or 100
    
    TriggerClientEvent('thegreatwar:setWeaponDurability', src, weapon, durability or 100)
    return true
end

exports('GiveWeaponWithDurability', GiveWeaponWithDurability)