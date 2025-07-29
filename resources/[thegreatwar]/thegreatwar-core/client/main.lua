-- resources/[thegreatwar]/thegreatwar-core/client/main.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Client State
local GameState = {
    inGame = false,
    currentMap = nil,
    myRole = nil,
    myCrew = nil,
    champion = nil,
    sessionActive = false
}

-- UI Elements
local championDisplay = nil
local voteUI = false

-- Events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('thegreatwar:playerJoined')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    TriggerServerEvent('thegreatwar:playerLeft')
end)

RegisterNetEvent('thegreatwar:gameStateUpdate', function(serverGameState)
    GameState.currentMap = serverGameState.currentMap
    GameState.champion = serverGameState.champion
    GameState.sessionActive = serverGameState.status == "active"
    
    if GameState.champion then
        ShowChampionDisplay(GameState.champion.displayName)
    end
end)

RegisterNetEvent('thegreatwar:sessionStarted', function(sessionData)
    GameState.sessionActive = true
    GameState.currentMap = sessionData.map
    
    -- Hide voting UI
    if voteUI then
        SetNuiFocus(false, false)
        SendNUIMessage({action = "hideVoting"})
        voteUI = false
    end
    
    -- Show session start notification
    QBCore.Functions.Notify("🎮 The Great War has begun! Map: " .. Config.Maps[sessionData.map].name, "success", 5000)
    
    -- Enable spawn selection
    ShowSpawnSelection(sessionData.map)
end)

RegisterNetEvent('thegreatwar:sessionEnded', function(champion)
    GameState.sessionActive = false
    GameState.champion = champion
    
    -- Show champion announcement
    ShowChampionAnnouncement(champion)
    
    QBCore.Functions.Notify("⚔️ The Great War has ended!", "info", 3000)
end)

RegisterNetEvent('thegreatwar:showMapVoting', function(maps)
    ShowMapVotingUI(maps)
end)

RegisterNetEvent('thegreatwar:voteReceived', function(mapName)
    QBCore.Functions.Notify("Vote received: " .. Config.Maps[mapName].name, "success", 2000)
end)

RegisterNetEvent('thegreatwar:roleSelected', function(roleName)
    GameState.myRole = roleName
    local role = Config.Roles[roleName]
    QBCore.Functions.Notify("Role selected: " .. role.icon .. " " .. role.name, "success", 3000)
end)

RegisterNetEvent('thegreatwar:killFeed', function(killData)
    ShowKillFeed(killData)
end)

-- Functions
function ShowChampionDisplay(championText)
    championDisplay = championText
    
    CreateThread(function()
        while championDisplay do
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 215, 0, 255) -- Gold color
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(championDisplay)
            DrawText(0.02, 0.02) -- Top left corner
            Wait(0)
        end
    end)
end

function ShowMapVotingUI(maps)
    voteUI = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = "showVoting",
        maps = maps
    })
end

function ShowSpawnSelection(mapName)
    local map = Config.Maps[mapName]
    if not map then return end
    
    local spawnOptions = {}
    for i, spawn in ipairs(map.spawns) do
        table.insert(spawnOptions, {
            label = "Spawn Point " .. i,
            coords = spawn
        })
    end
    
    -- Show spawn selection menu
    exports['qb-menu']:openMenu({
        {
            header = "Select Spawn Location",
            isMenuHeader = true
        },
        {
            header = "📍 " .. map.name,
            txt = map.description,
            isMenuHeader = true
        }
    })
    
    for i, option in ipairs(spawnOptions) do
        exports['qb-menu']:openMenu({
            {
                header = option.label,
                txt = "Teleport to this spawn point",
                params = {
                    event = "thegreatwar:selectSpawn",
                    args = {coords = option.coords}
                }
            }
        })
    end
end

function ShowRoleSelection()
    local roleOptions = {}
    
    for roleId, role in pairs(Config.Roles) do
        table.insert(roleOptions, {
            header = role.icon .. " " .. role.name,
            txt = "Select this role",
            params = {
                event = "thegreatwar:selectRole",
                args = {role = roleId}
            }
        })
    end
    
    exports['qb-menu']:openMenu({
        {
            header = "⚔️ Select Your Role",
            isMenuHeader = true
        },
        table.unpack(roleOptions)
    })
end

function ShowKillFeed(killData)
    local killText = killData.killer .. " eliminated " .. killData.victim
    if killData.distance > 50 then
        killText = killText .. " (" .. math.floor(killData.distance) .. "m)"
    end
    
    -- Show kill feed notification
    SendNUIMessage({
        action = "showKillFeed",
        killer = killData.killer,
        victim = killData.victim,
        weapon = killData.weapon,
        distance = killData.distance
    })
end

function ShowChampionAnnouncement(champion)
    SendNUIMessage({
        action = "showChampion",
        champion = champion
    })
    
    -- Update champion display
    ShowChampionDisplay(champion.displayName)
end

-- Events
RegisterNetEvent('thegreatwar:selectSpawn', function(data)
    local coords = data.coords
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
    SetEntityHeading(PlayerPedId(), coords.h)
    
    exports['qb-menu']:closeMenu()
    
    -- Show role selection after spawn
    ShowRoleSelection()
end)

RegisterNetEvent('thegreatwar:selectRole', function(data)
    TriggerServerEvent('thegreatwar:selectRole', data.role)
    exports['qb-menu']:closeMenu()
end)

-- NUI Callbacks
RegisterNUICallback('voteMap', function(data, cb)
    TriggerServerEvent('thegreatwar:voteMap', data.map)
    cb('ok')
end)

RegisterNUICallback('closeVoting', function(data, cb)
    SetNuiFocus(false, false)
    voteUI = false
    cb('ok')
end)

-- Commands
RegisterCommand('tgw_role', function()
    if GameState.sessionActive then
        ShowRoleSelection()
    else
        QBCore.Functions.Notify("No active session", "error")
    end
end)

RegisterCommand('tgw_stats', function()
    -- Show personal stats
    TriggerServerEvent('thegreatwar:getMyStats')
end)

-- Disable normal spawning during active session
AddEventHandler('playerSpawned', function()
    if GameState.sessionActive then
        -- Prevent normal spawn, wait for game spawn selection
        Wait(1000)
        if GameState.currentMap then
            ShowSpawnSelection(GameState.currentMap)
        end
    end
end)