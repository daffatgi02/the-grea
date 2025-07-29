-- resources/[thegreatwar]/thegreatwar-core/client/durability.lua
local QBCore = exports['qb-core']:GetCoreObject()
local weaponDurability = {}

-- Initialize weapon durability
RegisterNetEvent('thegreatwar:setWeaponDurability', function(weapon, durability)
    weaponDurability[weapon] = durability
end)

-- Handle weapon usage
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local weapon = GetSelectedPedWeapon(ped)
            if weaponDurability[weapon] then
                weaponDurability[weapon] = weaponDurability[weapon] - 1
                
                if weaponDurability[weapon] <= 0 then
                    -- Weapon broke
                    RemoveWeaponFromPed(ped, weapon)
                    TriggerServerEvent('thegreatwar:weaponBroken', weapon)
                    QBCore.Functions.Notify("Weapon broke from overuse!", "error")
                    weaponDurability[weapon] = nil
                else
                    -- Update server
                    TriggerServerEvent('thegreatwar:updateWeaponDurability', weapon, weaponDurability[weapon])
                end
            end
        end
        Wait(100)
    end
end)

-- Server-side durability handler