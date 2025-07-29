-- resources/[thegreatwar]/thegreatwar-core/server/anticheat.lua
local QBCore = exports['qb-core']:GetCoreObject()
local suspiciousActivity = {}
local killCooldowns = {}

-- Track suspicious kills
RegisterNetEvent('thegreatwar:validateKill', function(victimId, weapon, distance, headshot)
    local killerId = source
    local currentTime = os.time()
    
    -- Initialize tracking for killer
    if not suspiciousActivity[killerId] then
        suspiciousActivity[killerId] = {
            kills = 0,
            lastKillTime = 0,
            rapidKills = 0,
            impossibleShots = 0
        }
    end
    
    local killer = suspiciousActivity[killerId]
    
    -- Check for rapid kills (more than 3 kills in 10 seconds)
    if currentTime - killer.lastKillTime < 10 then
        killer.rapidKills = killer.rapidKills + 1
        if killer.rapidKills >= 3 then
            TriggerEvent('thegreatwar:suspiciousActivity', killerId, 'rapid_kills', {
                kills = killer.rapidKills,
                timeframe = currentTime - killer.lastKillTime
            })
        end
    else
        killer.rapidKills = 0
    end
    
    -- Check for impossible shot distances
    local maxRange = GetWeaponRange(weapon)
    if distance > maxRange * 1.5 then
        killer.impossibleShots = killer.impossibleShots + 1
        TriggerEvent('thegreatwar:suspiciousActivity', killerId, 'impossible_shot', {
            weapon = weapon,
            distance = distance,
            maxRange = maxRange
        })
    end
    
    -- Check kill cooldown (prevent instakills)
    if killCooldowns[killerId] and currentTime - killCooldowns[killerId] < 1 then
        TriggerEvent('thegreatwar:suspiciousActivity', killerId, 'no_cooldown', {
            timeDiff = currentTime - killCooldowns[killerId]
        })
        return false
    end
    
    -- Update tracking
    killer.kills = killer.kills + 1
    killer.lastKillTime = currentTime
    killCooldowns[killerId] = currentTime
    
    return true
end)

-- Suspicious activity handler
RegisterNetEvent('thegreatwar:suspiciousActivity', function(playerId, type, data)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return end
    
    local logData = {
        player = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname,
        type = type,
        data = data,
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    -- Log to database for admin review
    MySQL.Async.execute('INSERT INTO thegreatwar_anticheat_logs (player_id, suspicious_type, data, timestamp) VALUES (?, ?, ?, ?)', {
        Player.PlayerData.citizenid, type, json.encode(data), os.date('%Y-%m-%d %H:%M:%S')
    })
    
    -- Auto-kick for severe violations
    if type == 'impossible_shot' then
        DropPlayer(playerId, 'Suspicious activity detected: Impossible shot')
    end
    
    print(string.format('^1[ANTICHEAT] ^7%s (%s) - %s: %s', 
        logData.name, logData.player, type, json.encode(data)))
end)