-- resources/[thegreatwar]/thegreatwar-core/client/zones.lua
local QBCore = exports['qb-core']:GetCoreObject()

local zones = {}
local inSafeZone = false
local currentHotZones = {}

-- Wait for config to be loaded
CreateThread(function()
    while not Config or not Config.maps do
        Wait(100)
    end
    print("^2[The Great War Zones] ^7Config loaded")
end)

-- Zone creation and management
function CreateSafeZone(coords, radius)
    local zone = {
        coords = coords,
        radius = radius,
        type = "safe",
        active = true
    }
    
    table.insert(zones, zone)
    return zone
end

function CreateHotZone(coords, radius, level)
    local zone = {
        coords = coords,
        radius = radius,
        type = "hot",
        level = level, -- red, yellow, white
        active = true,
        created = GetGameTimer()
    }
    
    table.insert(zones, zone)
    currentHotZones[#currentHotZones + 1] = zone
    
    -- Auto-remove hot zone after 5 minutes
    SetTimeout(300000, function()
        RemoveZone(zone)
    end)
    
    return zone
end

function RemoveZone(targetZone)
    for i, zone in ipairs(zones) do
        if zone == targetZone then
            zone.active = false
            table.remove(zones, i)
            break
        end
    end
end

-- Zone checking thread
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local wasInSafeZone = inSafeZone
        inSafeZone = false
        
        -- Check all zones
        for _, zone in ipairs(zones) do
            if zone.active then
                local distance = #(playerCoords - zone.coords)
                
                if distance <= zone.radius then
                    if zone.type == "safe" then
                        inSafeZone = true
                        
                        if not wasInSafeZone then
                            OnEnterSafeZone()
                        end
                    elseif zone.type == "hot" then
                        OnInHotZone(zone.level)
                    end
                end
            end
        end
        
        -- Check if left safe zone
        if wasInSafeZone and not inSafeZone then
            OnLeaveSafeZone()
        end
        
        Wait(1000) -- Check every second
    end
end)

-- Zone event handlers
function OnEnterSafeZone()
    TriggerEvent('thegreatwar:enteredSafeZone')
    QBCore.Functions.Notify("🛡️ Entered Safe Zone - No combat allowed", "success")
    
    -- Disable combat
    DisableControlAction(0, 24, true) -- Attack
    DisableControlAction(0, 25, true) -- Aim
    DisableControlAction(0, 140, true) -- Melee Attack Light
    DisableControlAction(0, 141, true) -- Melee Attack Heavy
    DisableControlAction(0, 142, true) -- Melee Attack Alternate
end

function OnLeaveSafeZone()
    TriggerEvent('thegreatwar:leftSafeZone')
    QBCore.Functions.Notify("⚔️ Left Safe Zone - Combat enabled", "error")
end

function OnInHotZone(level)
    local color = {255, 255, 255} -- white default
    
    if level == "red" then
        color = {255, 0, 0} -- red
    elseif level == "yellow" then
        color = {255, 255, 0} -- yellow
    end
    
    -- Show zone indicator on minimap
    DrawMarker(1, GetEntityCoords(PlayerPedId()), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 5.0, 1.0, color[1], color[2], color[3], 100, false, true, 2, nil, nil, false)
end

-- Network events for zone updates
RegisterNetEvent('thegreatwar:createHotZone', function(coords, radius, level)
    CreateHotZone(coords, radius, level)
    
    local levelText = level == "red" and "🔴 Heavy Combat" or level == "yellow" and "🟡 Combat Activity" or "⚪ Recent Combat"
    QBCore.Functions.Notify("📢 " .. levelText .. " detected nearby!", "info", 3000)
end)

RegisterNetEvent('thegreatwar:updateZones', function(zoneData)
    -- Clear existing hot zones
    for i = #zones, 1, -1 do
        if zones[i].type == "hot" then
            table.remove(zones, i)
        end
    end
    
    -- Add new zones
    for _, zone in ipairs(zoneData) do
        CreateHotZone(vector3(zone.x, zone.y, zone.z), zone.radius, zone.level)
    end
end)

-- Initialize safe zones when session starts
RegisterNetEvent('thegreatwar:sessionStarted', function(sessionData)
    if not Config.maps or not Config.maps[sessionData.map] then return end
    
    local map = Config.maps[sessionData.map]
    if map and map.safezone then
        CreateSafeZone(vector3(map.safezone.x, map.safezone.y, map.safezone.z), map.safezone.radius)
    end
end)

-- Combat disable in safe zones
CreateThread(function()
    while true do
        if inSafeZone then
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 140, true) -- Melee Attack Light
            DisableControlAction(0, 141, true) -- Melee Attack Heavy
            DisableControlAction(0, 142, true) -- Melee Attack Alternate
            
            -- Prevent weapon damage
            SetPlayerCanDoDriveBy(PlayerId(), false)
            SetCanAttackFriendly(PlayerPedId(), false, false)
        end
        Wait(0)
    end
end)