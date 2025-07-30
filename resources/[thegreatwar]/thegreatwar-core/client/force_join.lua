-- resources/[thegreatwar]/thegreatwar-core/client/force_join.lua
local QBCore = exports['qb-core']:GetCoreObject()
local isInGamemode = false

RegisterNetEvent('thegreatwar:forceGamemodeJoin', function()
    if isInGamemode then return end
    isInGamemode = true
    
    print("^2[The Great War Client] ^7Forcing gamemode join...")
    
    -- Hide all roleplay UI
    SendNUIMessage({
        action = "hideAllRP",
        resource = GetCurrentResourceName()
    })
    
    -- Clear screen
    DoScreenFadeOut(1000)
    Wait(1000)
    
    -- Show gamemode intro
    QBCore.Functions.Notify("🎮 Welcome to The Great War!", "success", 5000)
    QBCore.Functions.Notify("⚔️ Match-Based Warfare System", "info", 5000)
    
    -- Wait for session status
    CreateThread(function()
        while true do
            Wait(2000)
            TriggerServerEvent('thegreatwar:requestGameState')
            break
        end
    end)
    
    DoScreenFadeIn(2000)
end)

-- Handle gamemode state updates
RegisterNetEvent('thegreatwar:gameStateResponse', function(gameState)
    if gameState.status == "lobby" then
        QBCore.Functions.Notify("🗳️ Lobby phase - Vote for next map!", "info", 3000)
    elseif gameState.status == "active" then
        QBCore.Functions.Notify("⚔️ Battle is active! Choose your spawn point!", "success", 3000)
        if gameState.currentMap then
            TriggerEvent('thegreatwar:showSpawnSelection', gameState.currentMap)
        end
    elseif gameState.status == "ended" then
        QBCore.Functions.Notify("🏆 Session ended! Next lobby starting soon...", "info", 3000)
    end
end)

-- Prevent normal roleplay interactions
CreateThread(function()
    while isInGamemode do
        -- Disable normal interactions
        DisableControlAction(0, 288, true) -- F1 (Phone)
        DisableControlAction(0, 289, true) -- F2 (Inventory)  
        DisableControlAction(0, 170, true) -- F3 (Animations)
        DisableControlAction(0, 167, true) -- F6 (Job menu)
        
        -- Allow only gamemode controls
        DisableControlAction(0, 243, true) -- ~ (Console, but allow for testing)
        
        Wait(0)
    end
end)