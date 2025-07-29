-- resources/[thegreatwar]/thegreatwar-core/server/zones.lua
local QBCore = exports['qb-core']:GetCoreObject()
local activeZones = {}
local zoneUpdateTimer = 30000 -- 30 seconds

-- Track combat activity
local combatActivity = {}

RegisterNetEvent('thegreatwar:trackCombat', function(coords, type)
    local src = source
    local zone = GetZoneFromCoords(coords)
    
    if not combatActivity[zone] then
        combatActivity[zone] = {
            activity = 0,
            lastActivity = os.time(),
            coords = coords
        }
    end
    
    combatActivity[zone].activity = combatActivity[zone].activity + (type == 'kill' and 10 or 5)
    combatActivity[zone].lastActivity = os.time()
end)

-- Update zones every 30 seconds
CreateThread(function()
    while true do
        UpdateZones()
        Wait(zoneUpdateTimer)
    end
end)

function UpdateZones()
    local currentTime = os.time()
    local newZones = {}
    
    for zone, data in pairs(combatActivity) do
        local timeSince = currentTime - data.lastActivity
        
        -- Decay activity over time
        data.activity = math.max(0, data.activity - (timeSince / 10))
        
        -- Determine zone level
        local level = "white"
        if data.activity > 50 then
            level = "red"
        elseif data.activity > 20 then
            level = "yellow"
        end
        
        if data.activity > 0 then
            table.insert(newZones, {
                zone = zone,
                level = level,
                activity = data.activity,
                coords = data.coords
            })
        end
    end
    
    -- Send to all clients
    TriggerClientEvent('thegreatwar:updateZones', -1, newZones)
end

function GetZoneFromCoords(coords)
    -- Simple zone calculation based on coordinates
    local x = math.floor(coords.x / 500)
    local y = math.floor(coords.y / 500)
    return string.format("zone_%d_%d", x, y)
end