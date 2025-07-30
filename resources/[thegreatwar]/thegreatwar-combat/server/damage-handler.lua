-- resources/[thegreatwar]/thegreatwar-combat/server/damage-handler.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Player combat data
local PlayerCombatData = {}
local LastDamageTime = {}

-- Initialize player combat data
local function InitPlayerCombatData(src)
    PlayerCombatData[src] = {
        killStreak = 0,
        lastKillTime = 0,
        totalDamageDealt = 0,
        totalDamageTaken = 0,
        weaponDamageDealt = {},
        role = nil
    }
end

-- Get player role damage multiplier
local function GetDamageMultiplier(src, damageType)
    local playerRole = exports['thegreatwar-core']:GetPlayerRole(src)
    if not playerRole or not CombatConfig.RoleDamageMultipliers[playerRole] then
        return 1.0
    end
    
    return CombatConfig.RoleDamageMultipliers[playerRole][damageType] or 1.0
end

-- Calculate weapon damage
local function CalculateWeaponDamage(weaponHash, distance, isHeadshot, attackerRole)
    local weaponConfig = CombatConfig.Weapons[weaponHash]
    if not weaponConfig then return 50 end -- Default damage
    
    local baseDamage = weaponConfig.damage
    local maxRange = weaponConfig.range
    
    -- Distance damage falloff
    local damageMultiplier = 1.0
    if distance > maxRange * 0.5 then
        damageMultiplier = math.max(0.3, 1.0 - (distance - maxRange * 0.5) / (maxRange * 0.5))
    end
    
    -- Headshot multiplier
    if isHeadshot then
        damageMultiplier = damageMultiplier * 2.0
    end
    
    -- Role-based damage multiplier
    local roleMultiplier = 1.0
    if attackerRole and CombatConfig.RoleDamageMultipliers[attackerRole] then
        roleMultiplier = CombatConfig.RoleDamageMultipliers[attackerRole].outgoing
    end
    
    -- Special case for recon with sniper rifles
    if attackerRole == "recon" and weaponConfig.category == "sniper" then
        roleMultiplier = roleMultiplier * 1.5
    end
    
    return math.floor(baseDamage * damageMultiplier * roleMultiplier)
end

-- Validate damage for anti-cheat
local function ValidateDamage(attackerId, victimId, damage, weaponHash, distance)
    local currentTime = GetGameTimer()
    
    -- Initialize data if needed
    if not PlayerCombatData[attackerId] then
        InitPlayerCombatData(attackerId)
    end
    
    -- Check damage per second limit
    if not LastDamageTime[attackerId] then
        LastDamageTime[attackerId] = currentTime
        PlayerCombatData[attackerId].damageThisSecond = 0
    end
    
    if currentTime - LastDamageTime[attackerId] > 1000 then
        PlayerCombatData[attackerId].damageThisSecond = 0
        LastDamageTime[attackerId] = currentTime
    end
    
    PlayerCombatData[attackerId].damageThisSecond = (PlayerCombatData[attackerId].damageThisSecond or 0) + damage
    
    -- Anti-cheat checks
    if PlayerCombatData[attackerId].damageThisSecond > CombatConfig.AntiCheat.maxDamagePerSecond then
        TriggerEvent('thegreatwar:antiCheat:suspiciousDamage', attackerId, {
            damagePerSecond = PlayerCombatData[attackerId].damageThisSecond,
            limit = CombatConfig.AntiCheat.maxDamagePerSecond
        })
        return false
    end
    
    -- Distance validation
    if distance > CombatConfig.AntiCheat.impossibleShotDistance then
        TriggerEvent('thegreatwar:antiCheat:impossibleShot', attackerId, {
            distance = distance,
            weapon = weaponHash
        })
        return false
    end
    
    -- Weapon-specific max damage check
    local weaponConfig = CombatConfig.Weapons[weaponHash]
    if weaponConfig and damage > weaponConfig.damage * 3 then -- Allow 3x max for headshots etc
        TriggerEvent('thegreatwar:antiCheat:excessiveDamage', attackerId, {
            damage = damage,
            maxExpected = weaponConfig.damage * 3,
            weapon = weaponHash
        })
        return false
    end
    
    return true
end

-- Handle player damage
RegisterNetEvent('thegreatwar:combat:playerDamaged', function(attackerId, damage, weaponHash, coords, isHeadshot)
    local victimId = source
    local distance = 0
    
    -- Calculate distance if attacker exists
    if attackerId and attackerId ~= victimId then
        local attackerPed = GetPlayerPed(attackerId)
        local victimPed = GetPlayerPed(victimId)
        
        if attackerPed and victimPed then
            local attackerCoords = GetEntityCoords(attackerPed)
            local victimCoords = GetEntityCoords(victimPed)
            distance = #(attackerCoords - victimCoords)
        end
    end
    
    -- Validate damage
    if not ValidateDamage(attackerId, victimId, damage, weaponHash, distance) then
        return
    end
    
    -- Get player roles
    local attackerRole = attackerId and exports['thegreatwar-core']:GetPlayerRole(attackerId)
    local victimRole = exports['thegreatwar-core']:GetPlayerRole(victimId)
    
    -- Calculate final damage
    local finalDamage = CalculateWeaponDamage(weaponHash, distance, isHeadshot, attackerRole)
    
    -- Apply victim role damage reduction
    if victimRole then
        local defenseMultiplier = GetDamageMultiplier(victimId, "incoming")
        finalDamage = math.floor(finalDamage * defenseMultiplier)
    end
    
    -- Update combat data
    if attackerId and PlayerCombatData[attackerId] then
        PlayerCombatData[attackerId].totalDamageDealt = PlayerCombatData[attackerId].totalDamageDealt + finalDamage
        
        if not PlayerCombatData[attackerId].weaponDamageDealt[weaponHash] then
            PlayerCombatData[attackerId].weaponDamageDealt[weaponHash] = 0
        end
        PlayerCombatData[attackerId].weaponDamageDealt[weaponHash] = PlayerCombatData[attackerId].weaponDamageDealt[weaponHash] + finalDamage
    end
    
    if not PlayerCombatData[victimId] then
        InitPlayerCombatData(victimId)
    end
    PlayerCombatData[victimId].totalDamageTaken = PlayerCombatData[victimId].totalDamageTaken + finalDamage
    
    -- Apply damage to victim
    TriggerClientEvent('thegreatwar:combat:takeDamage', victimId, finalDamage, attackerId, weaponHash)
    
    -- Send damage feedback to attacker
    if attackerId and attackerId ~= victimId then
        TriggerClientEvent('thegreatwar:combat:damageDealt', attackerId, finalDamage, isHeadshot, distance)
    end
    
    -- Track combat activity for zones
    if coords then
        TriggerEvent('thegreatwar:zones:trackCombat', coords, 'damage')
    end
end)

-- Handle player kill
RegisterNetEvent('thegreatwar:combat:playerKilled', function(killerId, weaponHash, coords, isHeadshot)
    local victimId = source
    local currentTime = GetGameTimer()
    
    -- Anti-cheat: Check minimum time between kills
    if killerId and PlayerCombatData[killerId] then
        if currentTime - PlayerCombatData[killerId].lastKillTime < CombatConfig.AntiCheat.minTimeBetweenKills then
            TriggerEvent('thegreatwar:antiCheat:rapidKills', killerId, {
                timeBetween = currentTime - PlayerCombatData[killerId].lastKillTime,
                minimum = CombatConfig.AntiCheat.minTimeBetweenKills
            })
            return
        end
        
        PlayerCombatData[killerId].lastKillTime = currentTime
        PlayerCombatData[killerId].killStreak = PlayerCombatData[killerId].killStreak + 1
        
        -- Check for suspicious kill streak
        if PlayerCombatData[killerId].killStreak > CombatConfig.AntiCheat.suspiciousKillStreakThreshold then
            TriggerEvent('thegreatwar:antiCheat:suspiciousKillStreak', killerId, {
                killStreak = PlayerCombatData[killerId].killStreak
            })
        end
        
        -- Check for kill streak rewards
        for _, streak in ipairs(CombatConfig.KillStreaks) do
            if PlayerCombatData[killerId].killStreak == streak.kills then
                -- Award kill streak bonus
                local Player = QBCore.Functions.GetPlayer(killerId)
                if Player then
                    Player.Functions.AddMoney('cash', streak.reward)
                    TriggerClientEvent('QBCore:Notify', killerId, 
                        "🔥 " .. streak.name .. "! Bonus: $" .. streak.reward, "success", 3000)
                    
                    -- Show kill streak to all players
                    TriggerClientEvent('thegreatwar:ui:showKillStreak', -1, 
                        PlayerCombatData[killerId].killStreak, Player.PlayerData.charinfo.firstname)
                end
                break
            end
        end
    end
    
    -- Reset victim's kill streak
    if PlayerCombatData[victimId] then
        PlayerCombatData[victimId].killStreak = 0
    end
    
    -- Process kill for main game system
    TriggerEvent('thegreatwar:playerKilled', killerId, victimId, weaponHash, 
                #(GetEntityCoords(GetPlayerPed(killerId)) - GetEntityCoords(GetPlayerPed(victimId))), coords)
    
    -- Track combat activity
    if coords then
        TriggerEvent('thegreatwar:zones:trackCombat', coords, 'kill')
    end
end)

-- Reset player death
RegisterNetEvent('thegreatwar:combat:playerDied', function()
    local src = source
    if PlayerCombatData[src] then
        PlayerCombatData[src].killStreak = 0
    end
end)

-- Clean up on player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    PlayerCombatData[src] = nil
    LastDamageTime[src] = nil
end)

-- Export functions
exports('GetPlayerCombatData', function(src)
    return PlayerCombatData[src]
end)

exports('GetWeaponConfig', function(weaponHash)
    return CombatConfig.Weapons[weaponHash]
end)

exports('ResetPlayerKillStreak', function(src)
    if PlayerCombatData[src] then
        PlayerCombatData[src].killStreak = 0
    end
end)