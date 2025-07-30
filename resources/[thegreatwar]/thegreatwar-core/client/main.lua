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

-- Wait for config to be loaded
CreateThread(function()
    while not Config or not Config.maps do
        Wait(100)
    end
    print("^2[The Great War Client] ^7Config loaded")
end)

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
    QBCore.Functions.Notify("🎮 The Great War has begun! Map: " .. (Config.maps[sessionData.map] and Config.maps[sessionData.map].name or sessionData.map), "success", 5000)
    
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
    local mapDisplayName = Config.maps and Config.maps[mapName] and Config.maps[mapName].name or mapName
    QBCore.Functions.Notify("Vote received: " .. mapDisplayName, "success", 2000)
end)

RegisterNetEvent('thegreatwar:roleSelected', function(roleName)
    GameState.myRole = roleName
    if Config.roles and Config.roles[roleName] then
        local role = Config.roles[roleName]
        QBCore.Functions.Notify("Role selected: " .. role.icon .. " " .. role.name, "success", 3000)
    end
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
    if not Config.maps or not Config.maps[mapName] then 
        QBCore.Functions.Notify("Map configuration not found", "error")
        return 
    end
    
    local map = Config.maps[mapName]
    local spawnOptions = {}
    
    for i, spawn in ipairs(map.spawns) do
        table.insert(spawnOptions, {
            header = "📍 Spawn Point " .. i,
            txt = "Teleport to this spawn point",
            params = {
                event = "thegreatwar:selectSpawn",
                args = {coords = spawn}
            }
        })
    end
    
    -- Add header
    table.insert(spawnOptions, 1, {
        header = "🗺️ " .. map.name,
        txt = map.description,
        isMenuHeader = true
    })
    
    table.insert(spawnOptions, 1, {
        header = "Select Spawn Location",
        isMenuHeader = true
    })
    
    -- Show spawn selection menu
    exports['qb-menu']:openMenu(spawnOptions)
end

function ShowRoleSelection()
    if not Config.roles then
        QBCore.Functions.Notify("Role configuration not found", "error")
        return
    end
    
    local roleOptions = {{
        header = "⚔️ Select Your Role",
        isMenuHeader = true
    }}
    
    for roleId, role in pairs(Config.roles) do
        table.insert(roleOptions, {
            header = role.icon .. " " .. role.name,
            txt = "Select this role",
            params = {
                event = "thegreatwar:selectRole",
                args = {role = roleId}
            }
        })
    end
    
    exports['qb-menu']:openMenu(roleOptions)
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

RegisterCommand('tgw_spawn', function()
    if GameState.currentMap then
        ShowSpawnSelection(GameState.currentMap)
    else
        QBCore.Functions.Notify("No active map", "error")
    end
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