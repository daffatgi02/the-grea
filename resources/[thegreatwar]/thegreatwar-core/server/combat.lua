-- resources/[thegreatwar]/thegreatwar-core/server/combat.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Combat event handlers
RegisterNetEvent('thegreatwar:onPlayerDamaged', function(damage, weaponHash, coords)
    local src = source
    local attacker = GetPlayerFromCoords(coords, 10.0) -- Find nearby players as potential attackers
    
    if attacker and attacker ~= src then
        -- Validate damage for anti-cheat
        if ValidateDamage(src, attacker, damage, weaponHash) then
            ProcessDamage(src, attacker, damage, weaponHash, coords)
        end
    end
end)

RegisterNetEvent('thegreatwar:onPlayerKill', function(victimId, weaponHash, coords)
    local killerId = source
    local distance = CalculateDistance(killerId, victimId)
    
    -- Validate kill
    if ValidateKill(killerId, victimId, weaponHash, distance) then
        TriggerEvent('thegreatwar:playerKilled', killerId, victimId, weaponHash, distance, coords)
        
        -- Handle respawn
        HandlePlayerRespawn(victimId)
    end
end)

function ValidateDamage(victim, attacker, damage, weapon)
    -- Basic anti-cheat validation
    local maxDamage = GetWeaponMaxDamage(weapon)
    local distance = CalculateDistance(attacker, victim)
    
    -- Check if damage is reasonable
    if damage > maxDamage * 1.2 then -- Allow 20% tolerance
        print("^1[ANTICHEAT] Suspicious damage from " .. attacker .. " to " .. victim)
        return false
    end
    
    -- Check distance (prevent impossible long-range kills with pistols)
    local weaponRange = GetWeaponRange(weapon)
    if distance > weaponRange then
        print("^1[ANTICHEAT] Impossible range kill from " .. attacker)
        return false
    end
    
    return true
end

function ValidateKill(killer, victim, weapon, distance)
    local GameState = exports['thegreatwar-core']:GetGameState()
    
    -- Check if session is active
    if GameState.status ~= "active" then
        return false
    end
    
    -- Check if both players are in the game
    if not GameState.players[killer] or not GameState.players[victim] then
        return false
    end
    
    -- Prevent self-kill
    if killer == victim then
        return false
    end
    
    -- Check for friendly fire in crew
    local killerData = GameState.players[killer]
    local victimData = GameState.players[victim]
    
    if killerData.crew and victimData.crew and killerData.crew == victimData.crew then
        -- Friendly fire is allowed but give warning
        TriggerClientEvent('QBCore:Notify', killer, "Friendly fire! Be careful!", "error")
    end
    
    return true
end

function HandlePlayerRespawn(playerId)
    SetTimeout(3000, function() -- 3 second respawn delay
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            -- Respawn at random spawn point of current map
            local GameState = exports['thegreatwar-core']:GetGameState()
            if GameState.currentMap then
                local spawns = Config.Maps[GameState.currentMap].spawns
                local randomSpawn = spawns[math.random(#spawns)]
                
                TriggerClientEvent('thegreatwar:respawnPlayer', playerId, randomSpawn)
            end
        end
    end)
end

function CalculateDistance(player1, player2)
    local ped1 = GetPlayerPed(player1)
    local ped2 = GetPlayerPed(player2)
    
    if not ped1 or not ped2 then return 0 end
    
    local coords1 = GetEntityCoords(ped1)
    local coords2 = GetEntityCoords(ped2)
    
    return #(coords1 - coords2)
end

function GetWeaponMaxDamage(weaponHash)
    -- Define max damage for different weapon types
    local weaponDamage = {
        [`WEAPON_PISTOL`] = 40,
        [`WEAPON_COMBATPISTOL`] = 45,
        [`WEAPON_ASSAULTRIFLE`] = 60,
        [`WEAPON_CARBINERIFLE`] = 55,
        [`WEAPON_SMG`] = 35,
        [`WEAPON_SNIPERRIFLE`] = 150,
        [`WEAPON_GRENADELAUNCHER`] = 200
    }
    
    return weaponDamage[weaponHash] or 50 -- Default damage
end

function GetWeaponRange(weaponHash)
    -- Define effective range for different weapons
    local weaponRange = {
        [`WEAPON_PISTOL`] = 50.0,
        [`WEAPON_COMBATPISTOL`] = 60.0,
        [`WEAPON_ASSAULTRIFLE`] = 200.0,
        [`WEAPON_CARBINERIFLE`] = 180.0,
        [`WEAPON_SMG`] = 80.0,
        [`WEAPON_SNIPERRIFLE`] = 500.0,
        [`WEAPON_GRENADELAUNCHER`] = 150.0
    }
    
    return weaponRange[weaponHash] or 100.0 -- Default range
end