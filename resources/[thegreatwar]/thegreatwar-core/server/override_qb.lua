-- resources/[thegreatwar]/thegreatwar-core/server/override_qb.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Override default player loading
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        print("^2[The Great War] ^7Player loading override for: " .. Player.PlayerData.citizenid)
        
        -- Clear ALL roleplay data
        Player.Functions.SetMoney('cash', 1000) -- Starting gamemode money
        Player.Functions.SetMoney('bank', 0)
        Player.Functions.SetMoney('crypto', 0)
        
        -- Remove job
        Player.Functions.SetJob('unemployed', 0)
        
        -- Clear inventory
        Player.Functions.ClearInventory()
        
        -- Remove hunger/thirst
        Player.Functions.SetMetaData('hunger', 100)
        Player.Functions.SetMetaData('thirst', 100)
        Player.Functions.SetMetaData('stress', 0)
        
        -- Force gamemode join
        SetTimeout(2000, function()
            TriggerClientEvent('thegreatwar:forceGamemodeJoin', src)
        end)
    end
end)

-- Override spawn system
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    TriggerClientEvent('thegreatwar:playerJoined', src)
end)

-- Disable hunger/thirst system
CreateThread(function()
    while true do
        local players = QBCore.Functions.GetQBPlayers()
        for k, v in pairs(players) do
            v.Functions.SetMetaData('hunger', 100)
            v.Functions.SetMetaData('thirst', 100)
            v.Functions.SetMetaData('stress', 0)
        end
        Wait(60000) -- Every minute
    end
end)

-- Prevent roleplay vehicle spawning
RegisterNetEvent('QBCore:Server:SpawnVehicle', function()
    -- Block all vehicle spawning
    CancelEvent()
end)

-- Override money system for gamemode only
local originalAddMoney = QBCore.Functions.AddMoney
QBCore.Functions.AddMoney = function(src, moneytype, amount, reason)
    if moneytype == 'cash' and reason and string.find(reason, 'thegreatwar') then
        return originalAddMoney(src, moneytype, amount, reason)
    end
    -- Block other money additions
    return false
end