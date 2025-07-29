-- resources/[thegreatwar]/thegreatwar-core/server/disable_rp.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Disable default QBCore features
CreateThread(function()
    -- Disable spawning at apartments/houses
    exports['qb-apartments']:DisableSpawning()
    
    -- Disable civilian jobs
    if GetResourceState('qb-ambulancejob') == 'started' then
        StopResource('qb-ambulancejob')
    end
    
    if GetResourceState('qb-policejob') == 'started' then
        StopResource('qb-policejob')
    end
    
    -- Disable banking system for gamemode
    if GetResourceState('qb-banking') == 'started' then
        StopResource('qb-banking')
    end
    
    -- Disable housing
    if GetResourceState('qb-houses') == 'started' then
        StopResource('qb-houses')
    end
    
    print("^3[The Great War] ^7Roleplay elements disabled")
end)

-- Override default player loading
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- Clear default money
        Player.Functions.SetMoney('cash', 0)
        Player.Functions.SetMoney('bank', 0)
        
        -- Clear default job
        Player.Functions.SetJob('unemployed', 0)
        
        -- Give gamemode money
        Player.Functions.SetMoney('cash', 1000) -- Starting money for weapon purchases
        
        -- Force join The Great War
        TriggerClientEvent('thegreatwar:forceJoin', src)
    end
end)

-- Prevent civilian vehicle spawning
RegisterNetEvent('QBCore:Server:SpawnVehicle', function()
    local src = source
    TriggerClientEvent('QBCore:Notify', src, "Vehicle spawning disabled in The Great War", "error")
end)