-- resources/[thegreatwar]/thegreatwar-core/shared/functions.lua
Config = {}

-- Load JSON config
function LoadConfig()
    local file = LoadResourceFile(GetCurrentResourceName(), 'config.json')
    if file then
        local success, decoded = pcall(json.decode, file)
        if success then
            Config = decoded
            print("^2[The Great War] ^7Config loaded successfully")
            return true
        else
            print("^1[The Great War] ^7Failed to parse config.json")
            return false
        end
    else
        print("^1[The Great War] ^7Failed to load config.json")
        return false
    end
end

-- Initialize config on resource start
if not LoadConfig() then
    -- Fallback config
    Config = {
        gameSession = {
            duration = 3600000,
            lobbyDuration = 30000,
            maxPlayers = 48
        },
        maps = {
            city = {
                name = "Perkotaan (City)",
                spawns = {
                    {x = 215.0, y = -810.0, z = 30.8, h = 342.0},
                    {x = -1037.0, y = -2737.0, z = 20.2, h = 240.0}
                },
                safezone = {x = -1037.8, y = -2674.0, z = 13.8, radius = 100.0},
                description = "Urban warfare in Los Santos"
            }
        }
    }
    print("^3[The Great War] ^7Using fallback config")
end

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