-- resources/[thegreatwar]/thegreatwar-core/server/main.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Game State Variables
local GameState = {
    status = "lobby", -- lobby, active, ended
    currentSession = nil,
    currentMap = nil,
    sessionStartTime = nil,
    sessionEndTime = nil,
    players = {},
    crews = {},
    votes = {},
    champion = nil
}

-- Session Management
local function StartNewSession(mapName)
    GameState.status = "active"
    GameState.currentMap = mapName
    GameState.sessionStartTime = os.time()
    GameState.sessionEndTime = os.time() + (Config.gameSession.duration / 1000)
    
    -- Create session in database
    MySQL.Async.insert('INSERT INTO thegreatwar_sessions (map_name, champion_type, champion_name) VALUES (?, ?, ?)', {
        mapName, 'solo', 'TBD'
    }, function(sessionId)
        GameState.currentSession = sessionId
        
        -- Notify all players
        TriggerClientEvent('thegreatwar:sessionStarted', -1, {
            sessionId = sessionId,
            map = mapName,
            duration = Config.gameSession.duration / 1000
        })
        
        -- Start session timer
        SetTimeout(Config.gameSession.duration, function()
            EndCurrentSession()
        end)
    end)
end

local function EndCurrentSession()
    if GameState.status ~= "active" then return end
    
    GameState.status = "ended"
    
    -- Calculate champion
    local champion = CalculateChampion()
    GameState.champion = champion
    
    -- Update database
    MySQL.Async.execute('UPDATE thegreatwar_sessions SET ended_at = NOW(), champion_type = ?, champion_name = ?, champion_kills = ? WHERE id = ?', {
        champion.type, champion.name, champion.kills, GameState.currentSession
    })
    
    -- Save all player stats
    SaveAllPlayerStats()
    
    -- Notify players of session end
    TriggerClientEvent('thegreatwar:sessionEnded', -1, champion)
    
    -- Start lobby phase
    SetTimeout(5000, function() -- 5 second delay
        StartLobbyPhase()
    end)
end

local function CalculateChampion()
    local bestSolo = {kills = 0, player = nil}
    local bestCrew = {kills = 0, crew = nil, topPlayer = nil}
    
    -- Find best solo player
    for playerId, playerData in pairs(GameState.players) do
        if playerData.kills > bestSolo.kills and not playerData.crew then
            bestSolo.kills = playerData.kills
            bestSolo.player = playerData
        end
    end
    
    -- Find best crew
    for crewName, crewData in pairs(GameState.crews) do
        if crewData.totalKills > bestCrew.kills then
            bestCrew.kills = crewData.totalKills
            bestCrew.crew = crewData
            bestCrew.topPlayer = crewData.topPlayer
        end
    end
    
    -- Determine champion type
    if bestCrew.kills > bestSolo.kills then
        return {
            type = "crew",    
            name = bestCrew.crew.name .. "_" .. bestCrew.topPlayer.nickname,
            kills = bestCrew.kills,
            displayName = "🏆 CHAMPION: " .. bestCrew.crew.name .. "_" .. bestCrew.topPlayer.nickname .. " — " .. bestCrew.kills .. " KILLS"
        }
    else
        return {
            type = "solo",
            name = bestSolo.player and bestSolo.player.nickname or "Unknown",
            kills = bestSolo.kills,
            displayName = "🏆 CHAMPION: " .. (bestSolo.player and bestSolo.player.nickname or "Unknown") .. " — " .. bestSolo.kills .. " KILLS"
        }
    end
end

local function StartLobbyPhase()
    GameState.status = "lobby"
    GameState.votes = {}
    
    -- Notify all players to show voting UI
    TriggerClientEvent('thegreatwar:showMapVoting', -1, Config.maps)
    
    -- Start voting timer - Fix: use proper config value
    local lobbyDuration = Config.gameSession and Config.gameSession.lobbyDuration or 30000
    SetTimeout(lobbyDuration, function()
        local winningMap = CountVotes()
        StartNewSession(winningMap)
    end)
end

local function CountVotes()
    local voteCounts = {}
    
    for mapName, _ in pairs(Config.maps) do
        voteCounts[mapName] = 0
    end
    
    for playerId, vote in pairs(GameState.votes) do
        if voteCounts[vote] then
            voteCounts[vote] = voteCounts[vote] + 1
        end
    end
    
    -- Find map with most votes
    local winningMap = "city" -- default
    local maxVotes = 0
    
    for mapName, votes in pairs(voteCounts) do
        if votes > maxVotes then
            maxVotes = votes
            winningMap = mapName
        end
    end
    
    return winningMap
end
-- Player Management
RegisterNetEvent('thegreatwar:playerJoined', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    GameState.players[src] = {
        id = src,
        citizenid = Player.PlayerData.citizenid,
        nickname = Player.PlayerData.charinfo.firstname .. "#" .. string.sub(Player.PlayerData.citizenid, -3),
        kills = 0,
        deaths = 0,
        assists = 0,
        money = 0,
        role = nil,
        crew = nil,
        joinedAt = os.time()
    }
    
    -- Send current game state to player
    TriggerClientEvent('thegreatwar:gameStateUpdate', src, GameState)
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^2[The Great War] ^7Starting gamemode...")
    
    -- Wait for config to be loaded
    CreateThread(function()
        while not Config.gameSession do
            Wait(100)
        end
        
        -- Start with lobby phase
        StartLobbyPhase()
    end)
end)

-- Exports
exports('GetGameState', function()
    return GameState
end)

exports('GetCurrentSession', function()
    return GameState.currentSession
end)