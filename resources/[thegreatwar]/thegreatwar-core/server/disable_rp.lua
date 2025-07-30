-- resources/[thegreatwar]/thegreatwar-core/server/disable_rp.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Load resource config
local function LoadResourceConfig()
    local file = LoadResourceFile(GetCurrentResourceName(), 'resource_config.json')
    if file then
        return json.decode(file)
    end
    return nil
end

-- Smart resource management
CreateThread(function()
    Wait(3000) -- Wait for resources to load
    
    local config = LoadResourceConfig()
    if not config then
        print("^1[The Great War] ^7Resource config not found, using defaults")
        return
    end
    
    print("^3[The Great War] ^7Starting smart resource management...")
    
    -- Auto-stop blacklisted resources
    if config.resources.blacklist then
        for _, resource in ipairs(config.resources.blacklist) do
            if GetResourceState(resource) == 'started' then
                StopResource(resource)
                print("^1[Disabled] ^7" .. resource)
            end
        end
    end
    
    -- Pattern-based stopping
    if config.resources.patterns and config.resources.patterns.stop then
        for i = 0, GetNumResources() - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName and GetResourceState(resourceName) == 'started' then
                
                for _, pattern in ipairs(config.resources.patterns.stop) do
                    if string.match(resourceName, pattern) then
                        -- Check if it's not in essential list
                        local isEssential = false
                        for _, essential in ipairs(config.resources.essential) do
                            if essential == resourceName then
                                isEssential = true
                                break
                            end
                        end
                        
                        if not isEssential then
                            StopResource(resourceName)
                            print("^1[Pattern Disabled] ^7" .. resourceName)
                        end
                    end
                end
            end
        end
    end
    
    print("^2[The Great War] ^7Resource management complete!")
end)

-- Override QBCore defaults (keep existing code)
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- Clear ALL roleplay data
        Player.Functions.SetMoney('cash', 1000)
        Player.Functions.SetMoney('bank', 0)
        Player.Functions.SetMoney('crypto', 0)
        Player.Functions.SetJob('unemployed', 0)
        Player.Functions.ClearInventory()
        Player.Functions.SetMetaData('hunger', 100)
        Player.Functions.SetMetaData('thirst', 100)
        Player.Functions.SetMetaData('stress', 0)
        
        SetTimeout(2000, function()
            TriggerClientEvent('thegreatwar:forceGamemodeJoin', src)
        end)
    end
end)