-- resources/[thegreatwar]/thegreatwar-core/server/statistics.lua
local QBCore = exports['qb-core']:GetCoreObject()

function SavePlayerStats(sessionId, playerId, stats)
    MySQL.Async.execute('INSERT INTO thegreatwar_player_stats (session_id, player_id, nickname, crew_name, role, kills, deaths, assists, survival_time, money_earned) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        sessionId, playerId, stats.nickname, stats.crew, stats.role, stats.kills, stats.deaths, stats.assists, stats.survivalTime, stats.money
    })
end

function UpdateLeaderboard(playerId, stats)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.Async.execute([[
        INSERT INTO thegreatwar_leaderboard (player_id, nickname, total_kills, total_deaths, total_sessions, total_money_earned) 
        VALUES (?, ?, ?, ?, 1, ?) 
        ON DUPLICATE KEY UPDATE 
        total_kills = total_kills + ?, 
        total_deaths = total_deaths + ?, 
        total_sessions = total_sessions + 1, 
        total_money_earned = total_money_earned + ?
    ]], {
        citizenid, stats.nickname, stats.kills, stats.deaths, stats.money,
        stats.kills, stats.deaths, stats.money
    })
end

function GetTopPlayers(limit)
    local result = MySQL.Sync.fetchAll('SELECT * FROM thegreatwar_leaderboard ORDER BY total_kills DESC LIMIT ?', {limit or 10})
    return result
end

-- Network Events
RegisterNetEvent('thegreatwar:getLeaderboard', function()
    local src = source
    local leaderboard = GetTopPlayers(10)
    TriggerClientEvent('thegreatwar:showLeaderboard', src, leaderboard)
end)

-- Exports
exports('SavePlayerStats', SavePlayerStats)
exports('UpdateLeaderboard', UpdateLeaderboard)
exports('GetTopPlayers', GetTopPlayers)