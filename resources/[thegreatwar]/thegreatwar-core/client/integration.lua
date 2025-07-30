-- resources/[thegreatwar]/thegreatwar-core/client/integration.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize all client systems
CreateThread(function()
    while not QBCore do
        Wait(100)
    end
    
    -- Wait for all resources to load
    while GetResourceState('thegreatwar-ui') ~= 'started' or
          GetResourceState('thegreatwar-combat') ~= 'started' or
          GetResourceState('thegreatwar-loot') ~= 'started' do
        Wait(1000)
    end
    
    print("^2[The Great War] ^7All Phase 1 systems loaded and integrated!")
    
    -- Initialize UI
    exports['thegreatwar-ui']:ShowChampionHUD()
    
    -- Initialize combat system
    TriggerEvent('thegreatwar:combat:playerReady')
    
    -- Request current game state
    TriggerServerEvent('thegreatwar:requestGameState')
end)

-- Handle game state updates
RegisterNetEvent('thegreatwar:gameStateResponse', function(gameState)
    -- Update UI with current champion
    if gameState.champion then
        TriggerEvent('thegreatwar:ui:updateChampion', gameState.champion)
    end
    
    -- Update session timer
    if gameState.status == "active" and gameState.sessionEndTime then
        local timeLeft = (gameState.sessionEndTime * 1000) - GetGameTimer()
        TriggerEvent('thegreatwar:ui:updateSessionTimer', timeLeft, gameState.status)
    end
end)