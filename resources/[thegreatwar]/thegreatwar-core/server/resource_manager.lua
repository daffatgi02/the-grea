-- resources/[thegreatwar]/thegreatwar-core/server/resource_manager.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Define resource categories
local ResourceCategories = {
    -- Core resources yang HARUS tetap jalan
    essential = {
        'mapmanager', 'chat', 'spawnmanager', 'sessionmanager', 'basic-gamemode', 
        'baseevents', 'oxmysql', 'qb-core', 'qb-menu', 'qb-input', 'qb-target',
        'interact-sound', 'pma-voice', 'qb-radio', 'thegreatwar-core'
    },
    
    -- Resource roleplay yang harus di-stop
    roleplay = {
        'qb-ambulancejob', 'qb-policejob', 'qb-banking', 'qb-houses', 'qb-apartments',
        'qb-vehicleshop', 'qb-busjob', 'qb-cityhall', 'qb-crafting', 'qb-crypto',
        'qb-diving', 'qb-doorlock', 'qb-drugs', 'qb-fuel', 'qb-garages',
        'qb-garbagejob', 'qb-hotdogjob', 'qb-houserobbery', 'qb-jewelery',
        'qb-lapraces', 'qb-management', 'qb-mechanicjob', 'qb-newsjob',
        'qb-pawnshop', 'qb-phone', 'qb-prison', 'qb-radialmenu', 'qb-recyclejob',
        'qb-scrapyard', 'qb-shops', 'qb-storerobbery', 'qb-streetraces',
        'qb-taxijob', 'qb-towjob', 'qb-truckrobbery', 'qb-vehiclekeys',
        'qb-vehiclesales', 'qb-vineyard', 'qb-weed', 'qb-bankrobbery',
        'qb-hud', 'qb-inventory', 'qb-weapons', 'qb-spawn', 'qb-multicharacter',
        'qb-scoreboard', 'qb-smallresources', 'qb-clothing'
    },
    
    -- Resource optional yang boleh jalan
    optional = {
        'bob74_ipl', 'connectqueue', 'PolyZone', 'progressbar', 'safecracker',
        'menuv', 'yarn', 'webpack', 'screenshot-basic'
    },
    
    -- Map resources
    maps = {
        'dealer_map', 'hospital_map', 'prison_canteen', 'prison_main', 'prison_meeting',
        'fivem-map-hipster', 'fivem-map-skater'
    }
}

-- Auto-detect and categorize resources
function AutoDetectResources()
    local allResources = {}
    local detectedRP = {}
    
    -- Get all running resources
    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName and resourceName ~= '' then
            table.insert(allResources, resourceName)
            
            -- Auto-detect roleplay resources by pattern
            if string.match(resourceName, '^qb%-') and 
               not IsInArray(ResourceCategories.essential, resourceName) then
                table.insert(detectedRP, resourceName)
            end
        end
    end
    
    print("^3[Resource Manager] ^7Detected " .. #allResources .. " total resources")
    print("^3[Resource Manager] ^7Detected " .. #detectedRP .. " roleplay resources")
    
    return allResources, detectedRP
end

function IsInArray(array, value)
    for _, v in ipairs(array) do
        if v == value then return true end
    end
    return false
end

-- Stop roleplay resources
function StopRoleplayResources()
    local _, detectedRP = AutoDetectResources()
    local stoppedCount = 0
    
    -- Stop predefined roleplay resources
    for _, resource in ipairs(ResourceCategories.roleplay) do
        if GetResourceState(resource) == 'started' then
            StopResource(resource)
            stoppedCount = stoppedCount + 1
            print("^1[Resource Manager] ^7Stopped: " .. resource)
        end
    end
    
    -- Stop auto-detected roleplay resources
    for _, resource in ipairs(detectedRP) do
        if not IsInArray(ResourceCategories.roleplay, resource) and 
           GetResourceState(resource) == 'started' then
            StopResource(resource)
            stoppedCount = stoppedCount + 1
            print("^1[Resource Manager] ^7Auto-stopped: " .. resource)
        end
    end
    
    print("^2[Resource Manager] ^7Stopped " .. stoppedCount .. " roleplay resources")
end

-- Start essential resources only
function StartEssentialResources()
    for _, resource in ipairs(ResourceCategories.essential) do
        if GetResourceState(resource) == 'stopped' then
            StartResource(resource)
            print("^2[Resource Manager] ^7Started essential: " .. resource)
        end
    end
end

-- Resource management commands
RegisterCommand('tgw_stop_rp', function(source, args)
    if source == 0 then -- Server console only
        StopRoleplayResources()
    end
end, true)

RegisterCommand('tgw_start_essential', function(source, args)
    if source == 0 then -- Server console only
        StartEssentialResources()
    end
end, true)

RegisterCommand('tgw_resource_status', function(source, args)
    if source == 0 then -- Server console only
        local allResources, detectedRP = AutoDetectResources()
        
        print("^6=== RESOURCE STATUS ===^7")
        print("^2Essential Resources:^7")
        for _, resource in ipairs(ResourceCategories.essential) do
            local state = GetResourceState(resource)
            local color = state == 'started' and '^2' or '^1'
            print("  " .. color .. resource .. " (" .. state .. ")^7")
        end
        
        print("^1Roleplay Resources:^7")
        for _, resource in ipairs(ResourceCategories.roleplay) do
            local state = GetResourceState(resource)
            if state ~= 'missing' then
                local color = state == 'stopped' and '^2' or '^1'
                print("  " .. color .. resource .. " (" .. state .. ")^7")
            end
        end
        
        print("^3Auto-detected RP:^7")
        for _, resource in ipairs(detectedRP) do
            local state = GetResourceState(resource)
            local color = state == 'stopped' and '^2' or '^1'
            print("  " .. color .. resource .. " (" .. state .. ")^7")
        end
    end
end, true)

-- Initialize on server start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^3[Resource Manager] ^7Initializing...")
    
    -- Delay to let other resources load first
    SetTimeout(2000, function()
        StopRoleplayResources()
        print("^2[Resource Manager] ^7The Great War gamemode ready!")
    end)
end)

-- Export functions
exports('StopRoleplayResources', StopRoleplayResources)
exports('StartEssentialResources', StartEssentialResources)
exports('AutoDetectResources', AutoDetectResources)