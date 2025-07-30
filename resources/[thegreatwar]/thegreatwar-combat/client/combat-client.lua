-- resources/[thegreatwar]/thegreatwar-combat/client/combat-client.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Client combat state
local CombatState = {
    inCombat = false,
    lastDamageTime = 0,
    currentHealth = 200,
    currentArmor = 100,
    isDead = false,
    hasGodMode = false
}

-- Damage indicators
local DamageIndicators = {}

-- Player health management
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local armor = GetPedArmour(ped)
        
        -- Update combat state
        CombatState.currentHealth = health
        CombatState.currentArmor = armor
        CombatState.isDead = health <= 100
        
        -- Check for damage taken
        if health < 200 and not CombatState.isDead then
            CombatState.inCombat = true
            CombatState.lastDamageTime = GetGameTimer()
        end
        
        -- Exit combat after 10 seconds of no damage
        if CombatState.inCombat and GetGameTimer() - CombatState.lastDamageTime > 10000 then
            CombatState.inCombat = false
        end
        
        -- Disable regeneration
        SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
        
        Wait(100)
    end
end)

-- Weapon damage detection
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        
        if HasEntityBeenDamagedByAnyPed(ped) or HasEntityBeenDamagedByAnyVehicle(ped) then
            local attacker = GetPedSourceOfDamage(ped)
            
            if attacker and attacker ~= ped and IsPedAPlayer(attacker) then
                local attackerId = NetworkGetPlayerIndexFromPed(attacker)
                local weaponHash = GetDamagingWeaponHash()
                local coords = GetEntityCoords(ped)
                local isHeadshot = HasPedBeenDamagedByWeapon(ped, weaponHash, 0) and 
                                 GetPedLastDamageBone(ped) == 31086 -- Head bone
                
                -- Calculate damage taken
                local previousHealth = CombatState.currentHealth
                local currentHealth = GetEntityHealth(ped)
                local damageTaken = previousHealth - currentHealth
                
                if damageTaken > 0 then
                    -- Send damage event to server
                    TriggerServerEvent('thegreatwar:combat:playerDamaged', 
                        GetPlayerServerId(attackerId), damageTaken, weaponHash, coords, isHeadshot)
                    
                    -- Show damage indicator
                    ShowDamageIndicator(damageTaken, isHeadshot)
                end
            end
            
            ClearEntityLastDamageEntity(ped)
        end
        
        Wait(0)
    end
end)

-- Death detection
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local weaponHash = args[5] or GetHashKey("WEAPON_UNARMED")
        
        if victim == PlayerPedId() and IsEntityDead(victim) then
            local attackerId = nil
            if attacker and IsPedAPlayer(attacker) then
                attackerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker))
            end
            
            -- Determine if headshot
            local isHeadshot = GetPedCauseOfDeath(victim) == weaponHash and 
                             GetEntityBoneIndexByName(victim, "SKEL_HEAD") == GetPedLastDamageBone(victim)
            
            -- Send kill event to server
            TriggerServerEvent('thegreatwar:combat:playerKilled', 
                attackerId, weaponHash, GetEntityCoords(victim), isHeadshot)
            
            CombatState.isDead = true
        end
    end
end)

-- Take damage event from server
RegisterNetEvent('thegreatwar:combat:takeDamage', function(damage, attackerId, weaponHash)
    local ped = PlayerPedId()
    local currentHealth = GetEntityHealth(ped)
    local newHealth = math.max(100, currentHealth - damage)
    
    SetEntityHealth(ped, newHealth)
    
    -- Play damage effects
    PlayDamageEffects(damage)
    
    -- Update UI
    TriggerEvent('thegreatwar:ui:updateHealth', newHealth - 100, GetPedArmour(ped))
end)

-- Damage dealt feedback
RegisterNetEvent('thegreatwar:combat:damageDealt', function(damage, isHeadshot, distance)
    -- Show hit marker
    ShowHitMarker(damage, isHeadshot, distance)
    
    -- Play hit sound
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
end)

-- Visual damage indicator
function ShowDamageIndicator(damage, isHeadshot)
    local indicator = {
        damage = damage,
        isHeadshot = isHeadshot,
        alpha = 255,
        time = GetGameTimer(),
        x = math.random(-50, 50),
        y = math.random(-30, -10)
    }
    
    table.insert(DamageIndicators, indicator)
    
    -- Remove after 2 seconds
    SetTimeout(2000, function()
        for i, ind in ipairs(DamageIndicators) do
            if ind == indicator then
                table.remove(DamageIndicators, i)
                break
            end
        end
    end)
end

-- Hit marker system
function ShowHitMarker(damage, isHeadshot, distance)
    local hitMarker = {
        damage = damage,
        isHeadshot = isHeadshot,
        distance = distance,
        alpha = 255,
        time = GetGameTimer(),
        scale = isHeadshot and 1.2 or 1.0
    }
    
    -- Draw hit marker on screen
    CreateThread(function()
        local startTime = GetGameTimer()
        
        while GetGameTimer() - startTime < 1000 do -- Show for 1 second
            local alpha = math.floor(255 * (1 - (GetGameTimer() - startTime) / 1000))
            
            -- Draw crosshair hit marker
            local screenW, screenH = GetActiveScreenResolution()
            local centerX, centerY = screenW / 2, screenH / 2
            
            -- Hit marker color
            local r, g, b = 255, 255, 255
            if isHeadshot then
                r, g, b = 255, 0, 0 -- Red for headshot
            end
            
            -- Draw hit marker lines
            DrawLine2D(centerX - 10, centerY - 10, centerX - 5, centerY - 5, r, g, b, alpha)
            DrawLine2D(centerX + 10, centerY - 10, centerX + 5, centerY - 5, r, g, b, alpha)
            DrawLine2D(centerX - 10, centerY + 10, centerX - 5, centerY + 5, r, g, b, alpha)
            DrawLine2D(centerX + 10, centerY + 10, centerX + 5, centerY + 5, r, g, b, alpha)
            
            -- Draw damage number
            SetTextFont(4)
            SetTextScale(0.4 * hitMarker.scale, 0.4 * hitMarker.scale)
            SetTextColour(r, g, b, alpha)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(tostring(damage))
            DrawText(0.51, 0.48)
            
            Wait(0)
        end
    end)
end

-- Play damage effects
function PlayDamageEffects(damage)
    -- Screen damage effect
    SetFlash(0, 0, 100, 500, 100)
    
    -- Camera shake for heavy damage
    if damage > 50 then
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.3)
    end
    
    -- Blood effect for very heavy damage
    if damage > 75 then
        StartScreenEffect("RaceTurbo", 1000, 0)
    end
end

-- Draw damage indicators
CreateThread(function()
    while true do
        for i = #DamageIndicators, 1, -1 do
            local indicator = DamageIndicators[i]
            local timeDiff = GetGameTimer() - indicator.time
            
            if timeDiff > 2000 then
                table.remove(DamageIndicators, i)
            else
                -- Fade out over time
                indicator.alpha = math.floor(255 * (1 - timeDiff / 2000))
                indicator.y = indicator.y - 1 -- Float upward
                
                -- Draw damage text
                local screenW, screenH = GetActiveScreenResolution()
                local x = (screenW / 2 + indicator.x) / screenW
                local y = (screenH / 2 + indicator.y) / screenH
                
                SetTextFont(4)
                SetTextScale(0.5, 0.5)
                SetTextColour(255, indicator.isHeadshot and 0 or 100, indicator.isHeadshot and 0 or 100, indicator.alpha)
                SetTextOutline()
                SetTextEntry("STRING")
                AddTextComponentString("-" .. indicator.damage .. (indicator.isHeadshot and " HS" or ""))
                DrawText(x, y)
            end
        end
        Wait(0)
    end
end)

-- Export combat state
exports('GetCombatState', function()
    return CombatState
end)

exports('IsInCombat', function()
    return CombatState.inCombat
end)

exports('IsDead', function()
    return CombatState.isDead
end)