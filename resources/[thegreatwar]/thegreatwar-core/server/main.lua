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
    GameState.sessionEndTime = os.time() + (Config.SessionDuration / 1000)
    
    -- Create session in database
    MySQL.Async.insert('INSERT INTO thegreatwar_sessions (map_name, champion_type, champion_name) VALUES (?, ?, ?)', {
        mapName, 'solo', 'TBD'
    }, function(sessionId)
        GameState.currentSession = sessionId
        
        -- Notify all players
        TriggerClientEvent('thegreatwar:sessionStarted', -1, {
            sessionId = sessionId,
            map = mapName,
            duration = Config.SessionDuration / 1000
        })
        
        -- Start session timer
        SetTimeout(Config.SessionDuration, function()
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
            name = bestSolo.player.nickname,
            kills = bestSolo.kills,
            displayName = "🏆 CHAMPION: " .. bestSolo.player.nickname .. " — " .. bestSolo.kills .. " KILLS"
        }
    end
end

local function StartLobbyPhase()
    GameState.status = "lobby"
    GameState.votes = {}
    
    -- Notify all players to show voting UI
    TriggerClientEvent('thegreatwar:showMapVoting', -1, Config.Maps)
    
    -- Start voting timer
    SetTimeout(Config.LobbyDuration, function()
        local winningMap = CountVotes()
        StartNewSession(winningMap)
    end)
end

local function CountVotes()
    local voteCounts = {}
    
    for mapName, _ in pairs(Config.Maps) do
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

RegisterNetEvent('thegreatwar:playerLeft', function()
    local src = source
    if GameState.players[src] then
        GameState.players[src] = nil
    end
end)

-- Vote Handling
RegisterNetEvent('thegreatwar:voteMap', function(mapName)
    local src = source
    if GameState.status ~= "lobby" then return end
    if not Config.Maps[mapName] then return end
    
    GameState.votes[src] = mapName
    TriggerClientEvent('thegreatwar:voteReceived', src, mapName)
end)

-- Role Selection
RegisterNetEvent('thegreatwar:selectRole', function(roleName)
    local src = source
    if not Config.Roles[roleName] then return end
    if not GameState.players[src] then return end
    
    GameState.players[src].role = roleName
    TriggerClientEvent('thegreatwar:roleSelected', src, roleName)
    
    -- Give role-specific items
    GiveRoleEquipment(src, roleName)
end)

local function GiveRoleEquipment(src, roleName)
    local role = Config.Roles[roleName]
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Clear inventory first
    Player.Functions.ClearInventory()
    
    -- Give role weapons
    for _, weapon in ipairs(role.weapons) do
        Player.Functions.AddItem(weapon, 1)
    end
    
    -- Give role-specific items
    if roleName == "medic" then
        Player.Functions.AddItem("bandage", 5 + role.abilities.medical_kit_bonus)
    elseif roleName == "support" then
        Player.Functions.AddItem("pistol_ammo", math.floor(250 * role.abilities.ammo_capacity))
        Player.Functions.AddItem("rifle_ammo", math.floor(500 * role.abilities.ammo_capacity))
    end
    
    -- Give basic items to all roles
    Player.Functions.AddItem("armor", 3) -- 3 armor kits
end

-- Kill/Death Tracking
RegisterNetEvent('thegreatwar:playerKilled', function(killerId, victimId, weapon, distance, coords)
    if GameState.status ~= "active" then return end
    
    local killer = GameState.players[killerId]
    local victim = GameState.players[victimId]
    
    if not killer or not victim then return end
    
    -- Update stats
    killer.kills = killer.kills + 1
    killer.money = killer.money + Config.Combat.KillReward
    victim.deaths = victim.deaths + 1
    
    -- Update crew stats if applicable
    if killer.crew then
        if not GameState.crews[killer.crew] then
            GameState.crews[killer.crew] = {totalKills = 0, members = {}, topPlayer = killer}
        end
        GameState.crews[killer.crew].totalKills = GameState.crews[killer.crew].totalKills + 1
        
        -- Update top player in crew
        if killer.kills > GameState.crews[killer.crew].topPlayer.kills then
            GameState.crews[killer.crew].topPlayer = killer
        end
    end
    
    -- Log kill to database
    MySQL.Async.insert('INSERT INTO thegreatwar_kill_log (session_id, killer_id, victim_id, weapon, distance, location_x, location_y, location_z) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        GameState.currentSession, killerId, victimId, weapon, distance, coords.x, coords.y, coords.z
    })
    
    -- Notify all players of kill
    TriggerClientEvent('thegreatwar:killFeed', -1, {
        killer = killer.nickname,
        victim = victim.nickname,
        weapon = weapon,
        distance = distance
    })
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^2[The Great War] ^7Starting gamemode...")
    
    -- Start with lobby phase
    StartLobbyPhase()
end)

-- Exports
exports('GetGameState', function()
    return GameState
end)

exports('GetCurrentSession', function()
    return GameState.currentSession
end)