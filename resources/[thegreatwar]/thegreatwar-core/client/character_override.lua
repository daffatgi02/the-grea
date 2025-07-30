-- resources/[thegreatwar]/thegreatwar-core/client/character_override.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Override default character selection
RegisterNetEvent('qb-multicharacter:client:chooseChar', function()
    -- Skip character selection, use default character
    local defaultChar = {
        citizenid = QBCore.Functions.GetPlayerData().citizenid or GenerateCitizenId(),
        charinfo = {
            firstname = "Warrior",
            lastname = "#" .. math.random(1000, 9999),
            birthdate = "01/01/2000",
            gender = 0,
            nationality = "Unknown",
            phone = "000-0000",
            account = "000000000"
        }
    }
    
    -- Force spawn into gamemode
    TriggerServerEvent('qb-multicharacter:server:loadUserData', defaultChar)
end)

-- Skip character creation
RegisterNetEvent('qb-multicharacter:client:createNewChar', function()
    -- Auto-create default character
    TriggerEvent('qb-multicharacter:client:chooseChar')
end)

-- Override spawn selection
RegisterNetEvent('qb-spawn:client:openUI', function()
    -- Skip normal spawn UI, wait for gamemode spawn
    TriggerEvent('thegreatwar:waitForGameSpawn')
end)

RegisterNetEvent('thegreatwar:waitForGameSpawn', function()
    QBCore.Functions.Notify("🎮 Waiting for The Great War session...", "info", 5000)
    
    -- Wait for gamemode to handle spawning
    CreateThread(function()
        while true do
            Wait(1000)
            -- Check if gamemode has started
            TriggerServerEvent('thegreatwar:requestGameState')
        end
    end)
end)

function GenerateCitizenId()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, 8 do
        local rand = math.random(#charset)
        result = result .. string.sub(charset, rand, rand)
    end
    return result
end