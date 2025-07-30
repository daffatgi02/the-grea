-- resources/[thegreatwar]/thegreatwar-core/server/integration.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Integration with UI System
RegisterNetEvent('thegreatwar:integration:updateChampion', function(champion)
    TriggerClientEvent('thegreatwar:ui:updateChampion', -1, champion)
end)

-- Integration with Combat System
RegisterNetEvent('thegreatwar:playerKilled', function(killerId, victimId, weaponHash, distance, coords)
    -- Update main game stats
    local GameState = exports['thegreatwar-core']:GetGameState()
    
    if GameState.players[killerId] then
        GameState.players[killerId].kills = GameState.players[killerId].kills + 1
        
        -- Check kill streak
        local combatData = exports['thegreatwar-combat']:GetPlayerCombatData(killerId)
        if combatData and combatData.killStreak then
            TriggerClientEvent('thegreatwar:ui:showKillStreak', killerId, 
                combatData.killStreak, GameState.players[killerId].nickname)
        end
    end
    
    if GameState.players[victimId] then
        GameState.players[victimId].deaths = GameState.players[victimId].deaths + 1
        
        -- Create death drop
        TriggerEvent('thegreatwar:loot:createDeathDrop', coords, victimId)
    end
    
    -- Send kill feed to UI
    TriggerClientEvent('thegreatwar:ui:killFeed', -1, {
        killer = GameState.players[killerId] and GameState.players[killerId].nickname or "Unknown",
        victim = GameState.players[victimId] and GameState.players[victimId].nickname or "Unknown",
        weapon = weaponHash,
        distance = distance
    })
    
    -- Update champion if necessary
    local newChampion = exports['thegreatwar-core']:CalculateChampion()
    if newChampion and (not GameState.champion or newChampion.kills > GameState.champion.kills) then
        GameState.champion = newChampion
        TriggerEvent('thegreatwar:integration:updateChampion', newChampion)
    end
end)

-- Session integration
RegisterNetEvent('thegreatwar:sessionStarted', function(sessionData)
    -- Initialize all systems
    TriggerEvent('thegreatwar:ui:sessionStarted', sessionData)
    TriggerEvent('thegreatwar:combat:sessionStarted', sessionData)
    TriggerEvent('thegreatwar:loot:sessionStarted', sessionData)
end)

RegisterNetEvent('thegreatwar:sessionEnded', function(champion)
    -- Cleanup all systems
    TriggerEvent('thegreatwar:ui:sessionEnded', champion)
    TriggerEvent('thegreatwar:combat:sessionEnded', champion)
    TriggerEvent('thegreatwar:loot:sessionEnded', champion)
end)