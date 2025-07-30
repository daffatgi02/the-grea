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

-- Forward declarations
local StartNewSession
local EndCurrentSession
local StartLobbyPhase
local CountVotes
local CalculateChampion
local SaveAllPlayerStats

-- Count votes function
CountVotes = function()
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
    
    print("^2[The Great War] ^7Map voting results:")
    for mapName, votes in pairs(voteCounts) do
        print("^3" .. mapName .. ": ^7" .. votes .. " votes")
    end
    print("^2Winner: ^7" .. winningMap)
    
    return winningMap
end

-- Calculate champion function
CalculateChampion = function()
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

-- Save all player stats function
SaveAllPlayerStats = function()
    if not GameState.currentSession then return end
    
    for playerId, playerData in pairs(GameState.players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            -- Calculate survival time
            local survivalTime = os.time() - playerData.joinedAt
            
            -- Save to database
            MySQL.Async.execute('INSERT INTO thegreatwar_player_stats (session_id, player_id, nickname, crew_name, role, kills, deaths, assists, survival_time, money_earned) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                GameState.currentSession,
                playerId,
                playerData.nickname,
                playerData.crew,
                playerData.role,
                playerData.kills,
                playerData.deaths,
                playerData.assists,
                survivalTime,
                playerData.money
            })
            
            -- Update leaderboard
            if exports['thegreatwar-core'] and exports['thegreatwar-core'].UpdateLeaderboard then
                exports['thegreatwar-core']:UpdateLeaderboard(playerId, playerData)
            end
        end
    end
    
    print("^2[The Great War] ^7Player stats saved for session " .. GameState.currentSession)
end

-- Start lobby phase function
StartLobbyPhase = function()
    GameState.status = "lobby"
    GameState.votes = {}
    
    print("^2[The Great War] ^7Starting lobby phase...")
    
    -- Notify all players to show voting UI
    TriggerClientEvent('thegreatwar:showMapVoting', -1, Config.maps)
    
    -- Start voting timer
    local lobbyDuration = Config.gameSession and Config.gameSession.lobbyDuration or 30000
    print("^3[The Great War] ^7Lobby duration: " .. lobbyDuration .. "ms")
    
    SetTimeout(lobbyDuration, function()
        local winningMap = CountVotes()
        StartNewSession(winningMap)
    end)
end

-- Start new session function
StartNewSession = function(mapName)
    GameState.status = "active"
    GameState.currentMap = mapName
    GameState.sessionStartTime = os.time()
    GameState.sessionEndTime = os.time() + (Config.gameSession.duration / 1000)
    
    print("^2[The Great War] ^7Starting new session on map: " .. mapName)
    
    -- Create session in database
    MySQL.Async.insert('INSERT INTO thegreatwar_sessions (map_name, champion_type, champion_name) VALUES (?, ?, ?)', {
        mapName, 'solo', 'TBD'
    }, function(sessionId)
        GameState.currentSession = sessionId
        print("^2[The Great War] ^7Session created with ID: " .. sessionId)
        
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

-- End current session function
EndCurrentSession = function()
    if GameState.status ~= "active" then return end
    
    GameState.status = "ended"
    
    print("^2[The Great War] ^7Ending current session...")
    
    -- Calculate champion
    local champion = CalculateChampion()
    GameState.champion = champion
    
    -- Update database
    if GameState.currentSession then
        MySQL.Async.execute('UPDATE thegreatwar_sessions SET ended_at = NOW(), champion_type = ?, champion_name = ?, champion_kills = ? WHERE id = ?', {
            champion.type, champion.name, champion.kills, GameState.currentSession
        })
    end
    
    -- Save all player stats
    SaveAllPlayerStats()
    
    -- Notify players of session end
    TriggerClientEvent('thegreatwar:sessionEnded', -1, champion)
    
    print("^2[The Great War] ^7Champion: " .. champion.displayName)
    
    -- Start lobby phase after delay
    SetTimeout(5000, function() -- 5 second delay
        StartLobbyPhase()
    end)
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
    
    print("^2[The Great War] ^7Player joined: " .. GameState.players[src].nickname)
    
    -- Send current game state to player
    TriggerClientEvent('thegreatwar:gameStateUpdate', src, GameState)
end)

RegisterNetEvent('thegreatwar:playerLeft', function()
    local src = source
    if GameState.players[src] then
        print("^2[The Great War] ^7Player left: " .. GameState.players[src].nickname)
        GameState.players[src] = nil
    end
end)

-- Add to resources/[thegreatwar]/thegreatwar-core/server/main.lua

-- Handle game state requests
RegisterNetEvent('thegreatwar:requestGameState', function()
    local src = source
    TriggerClientEvent('thegreatwar:gameStateResponse', src, GameState)
end)

-- Force all new players into gamemode
RegisterNetEvent('thegreatwar:playerConnected', function()
    local src = source
    SetTimeout(5000, function() -- Give time for QBCore to load
        TriggerClientEvent('thegreatwar:forceGamemodeJoin', src)
    end)
end)

-- Handle player disconnection from server
AddEventHandler('playerDropped', function(reason)
    local src = source
    if GameState.players[src] then
        print("^2[The Great War] ^7Player disconnected: " .. GameState.players[src].nickname)
        GameState.players[src] = nil
    end
end)

-- Vote handling
RegisterNetEvent('thegreatwar:voteMap', function(mapName)
    local src = source
    if Config.maps[mapName] then
        GameState.votes[src] = mapName
        print("^2[The Great War] ^7Player " .. src .. " voted for: " .. mapName)
        TriggerClientEvent('thegreatwar:voteReceived', src, mapName)
    end
end)

-- Kill tracking
RegisterNetEvent('thegreatwar:playerKilled', function(killerId, victimId, weapon, distance, coords)
    if GameState.status ~= "active" then return end
    
    if GameState.players[killerId] then
        GameState.players[killerId].kills = GameState.players[killerId].kills + 1
    end
    
    if GameState.players[victimId] then
        GameState.players[victimId].deaths = GameState.players[victimId].deaths + 1
    end
    
    -- Update crew stats if applicable
    if GameState.players[killerId] and GameState.players[killerId].crew then
        local crewName = GameState.players[killerId].crew
        if GameState.crews[crewName] then
            GameState.crews[crewName].totalKills = GameState.crews[crewName].totalKills + 1
        end
    end
    
    -- Send kill feed to all players
    TriggerClientEvent('thegreatwar:killFeed', -1, {
        killer = GameState.players[killerId] and GameState.players[killerId].nickname or "Unknown",
        victim = GameState.players[victimId] and GameState.players[victimId].nickname or "Unknown",
        weapon = weapon,
        distance = distance
    })
    
    -- Reward kill
    if exports['thegreatwar-core'] and exports['thegreatwar-core'].RewardKill then
        exports['thegreatwar-core']:RewardKill(killerId, victimId)
    end
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^2[The Great War] ^7Starting gamemode...")
    
    -- Wait for config to be loaded
    CreateThread(function()
        local attempts = 0
        while not Config.gameSession and attempts < 50 do
            Wait(100)
            attempts = attempts + 1
        end
        
        if Config.gameSession then
            print("^2[The Great War] ^7Config loaded, starting lobby phase...")
            -- Start with lobby phase
            StartLobbyPhase()
        else
            print("^1[The Great War] ^7Failed to load config, using defaults...")
            -- Use default config values
            Config.gameSession = {
                duration = 3600000,
                lobbyDuration = 30000,
                maxPlayers = 48
            }
            Config.maps = {
                city = {
                    name = "Perkotaan (City)",
                    spawns = {{x = 215.0, y = -810.0, z = 30.8, h = 342.0}},
                    safezone = {x = -1037.8, y = -2674.0, z = 13.8, radius = 100.0},
                    description = "Urban warfare in Los Santos"
                }
            }
            StartLobbyPhase()
        end
    end)
end)

-- Exports
exports('GetGameState', function()
    return GameState
end)

exports('GetCurrentSession', function()
    return GameState.currentSession
end)

-- Admin commands for testing
RegisterCommand('tgw_start', function(source, args)
    if source == 0 then -- Server console only
        local mapName = args[1] or "city"
        print("^2[The Great War] ^7Admin forcing session start: " .. mapName)
        StartNewSession(mapName)
    end
end, true)

RegisterCommand('tgw_end', function(source, args)
    if source == 0 then -- Server console only
        print("^2[The Great War] ^7Admin forcing session end")
        EndCurrentSession()
    end
end, true)

RegisterCommand('tgw_lobby', function(source, args)
    if source == 0 then -- Server console only
        print("^2[The Great War] ^7Admin forcing lobby phase")
        StartLobbyPhase()
    end
end, true)

RegisterCommand('tgw_status', function(source, args)
    if source == 0 then -- Server console only
        print("^2[The Great War] ^7Current status: " .. GameState.status)
        print("^2[The Great War] ^7Current map: " .. (GameState.currentMap or "none"))
        print("^2[The Great War] ^7Players online: " .. GetNumPlayerIndices())
        print("^2[The Great War] ^7Players in game: " .. #GameState.players)
    end
end, true)