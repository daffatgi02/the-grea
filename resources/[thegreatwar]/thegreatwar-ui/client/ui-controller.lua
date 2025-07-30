-- resources/[thegreatwar]/thegreatwar-ui/client/ui-controller.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- UI State Management
local UIState = {
    championHUD = false,
    votingInterface = false,
    sessionTimer = false,
    killFeed = true
}

-- Champion HUD Management
RegisterNetEvent('thegreatwar:ui:updateChampion', function(champion)
    if not UIState.championHUD then return end
    
    SendNUIMessage({
        action = "updateChampion",
        champion = champion
    })
end)

RegisterNetEvent('thegreatwar:ui:showKillStreak', function(streak, playerName)
    SendNUIMessage({
        action = "showKillStreak",
        streak = streak,
        player = playerName,
        type = "personal"
    })
end)

RegisterNetEvent('thegreatwar:ui:updateSessionTimer', function(timeLeft, status)
    SendNUIMessage({
        action = "updateSessionTimer",
        timeLeft = timeLeft,
        status = status
    })
end)

-- Voting Interface Management
RegisterNetEvent('thegreatwar:ui:showMapVoting', function(maps, duration)
    UIState.votingInterface = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = "showVoting",
        maps = maps,
        duration = duration or 30
    })
end)

RegisterNetEvent('thegreatwar:ui:hideMapVoting', function()
    UIState.votingInterface = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = "hideVoting"
    })
end)

RegisterNetEvent('thegreatwar:ui:updateVotes', function(votes)
    if not UIState.votingInterface then return end
    
    SendNUIMessage({
        action = "updateVotes",
        votes = votes
    })
end)

-- NUI Callbacks
RegisterNUICallback('voteMap', function(data, cb)
    TriggerServerEvent('thegreatwar:voteMap', data.map)
    cb('ok')
end)

RegisterNUICallback('closeVoting', function(data, cb)
    UIState.votingInterface = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- UI Toggle Functions
function ShowChampionHUD()
    UIState.championHUD = true
    SendNUIMessage({action = "showChampionHUD"})
end

function HideChampionHUD()
    UIState.championHUD = false
    SendNUIMessage({action = "hideChampionHUD"})
end

-- Initialize UI on gamemode join
RegisterNetEvent('thegreatwar:playerJoined', function()
    ShowChampionHUD()
end)

-- Session Events
RegisterNetEvent('thegreatwar:sessionStarted', function(sessionData)
    ShowChampionHUD()
    
    -- Start session timer
    CreateThread(function()
        local endTime = GetGameTimer() + sessionData.duration
        
        while GetGameTimer() < endTime do
            local timeLeft = endTime - GetGameTimer()
            TriggerEvent('thegreatwar:ui:updateSessionTimer', timeLeft, 'ACTIVE')
            Wait(1000)
        end
    end)
end)

RegisterNetEvent('thegreatwar:sessionEnded', function(champion)
    -- Update champion display
    TriggerEvent('thegreatwar:ui:updateChampion', champion)
    
    -- Show session end notification
    QBCore.Functions.Notify("🏆 Session ended! Champion: " .. champion.name, "success", 5000)
end)

-- Export functions for other resources
exports('ShowChampionHUD', ShowChampionHUD)
exports('HideChampionHUD', HideChampionHUD)
exports('IsUIActive', function(uiType) return UIState[uiType] or false end)