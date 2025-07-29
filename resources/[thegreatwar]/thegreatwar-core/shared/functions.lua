-- resources/[thegreatwar]/thegreatwar-core/shared/functions.lua
Config = {}

-- Load JSON config
function LoadConfig()
    local file = LoadResourceFile(GetCurrentResourceName(), 'config.json')
    if file then
        Config = json.decode(file)
        print("^2[The Great War] ^7Config loaded successfully")
    else
        print("^1[The Great War] ^7Failed to load config.json")
    end
end

-- Initialize config on resource start
LoadConfig()

-- Utility functions
function Config.GetRandomSpawn(mapName)
    if not Config.maps[mapName] then return nil end
    local spawns = Config.maps[mapName].spawns
    return spawns[math.random(#spawns)]
end

function Config.IsInSafeZone(coords, mapName)
    if not Config.maps[mapName] or not Config.maps[mapName].safezone then return false end
    local safezone = Config.maps[mapName].safezone
    local distance = #(coords - vector3(safezone.x, safezone.y, safezone.z))
    return distance <= safezone.radius
end

-- Export functions
exports('GetConfig', function() return Config end)
exports('GetRandomSpawn', Config.GetRandomSpawn)
exports('IsInSafeZone', Config.IsInSafeZone)