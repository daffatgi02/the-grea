-- resources/[thegreatwar]/thegreatwar-core/client/respawn.lua
local QBCore = exports['qb-core']:GetCoreObject()
local isDead = false
local respawnTime = 10 -- seconds

-- Death handler
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        
        if victim == PlayerPedId() and IsEntityDead(victim) then
            HandlePlayerDeath(attacker)
        end
    end
end)

function HandlePlayerDeath(attacker)
    if isDead then return end
    isDead = true
    
    -- Disable controls
    DisableAllControlActions(0)
    
    -- Show death screen
    SendNUIMessage({
        action = "showDeathScreen",
        respawnTime = respawnTime,
        killer = GetPlayerName(NetworkGetPlayerIndexFromPed(attacker))
    })
    
    -- Count down respawn
    CreateThread(function()
        local timeLeft = respawnTime
        while timeLeft > 0 and isDead do
            SendNUIMessage({
                action = "updateRespawnTimer",
                time = timeLeft
            })
            Wait(1000)
            timeLeft = timeLeft - 1
        end
        
        if isDead then
            TriggerServerEvent('thegreatwar:requestRespawn')
        end
    end)
end

RegisterNetEvent('thegreatwar:respawnPlayer', function(spawnCoords)
    if not isDead then return end
    
    -- Respawn player
    local model = `mp_m_freemode_01`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    
    -- Teleport to spawn
    SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z)
    SetEntityHeading(PlayerPedId(), spawnCoords.h or 0.0)
    
    -- Reset health
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 100)
    
    -- Enable controls
    EnableAllControlActions(0)
    
    -- Hide death screen
    SendNUIMessage({action = "hideDeathScreen"})
    
    isDead = false
    
    -- Give basic equipment
    TriggerServerEvent('thegreatwar:giveRespawnEquipment')
end)

-- Prevent normal hospital respawn
RegisterNetEvent('hospital:client:Revive', function()
    CancelEvent()
end)