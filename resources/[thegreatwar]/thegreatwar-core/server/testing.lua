-- resources/[thegreatwar]/thegreatwar-core/server/testing.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Test Phase 1 Systems
RegisterCommand('tgw_test_phase1', function(source, args)
    if source ~= 0 then return end -- Server console only
    
    print("^3[Testing] ^7Starting Phase 1 system tests...")
    
    -- Test 1: Resource States
    print("^3[Test 1] ^7Checking resource states...")
    local resources = {'thegreatwar-core', 'thegreatwar-ui', 'thegreatwar-combat', 'thegreatwar-loot'}
    for _, resource in ipairs(resources) do
        local state = GetResourceState(resource)
        local color = state == 'started' and '^2' or '^1'
        print("  " .. color .. resource .. ": " .. state .. "^7")
    end
    
    -- Test 2: UI System
    print("^3[Test 2] ^7Testing UI System...")
    local testChampion = {
        name = "TestPlayer#123",
        kills = 15,
        type = "solo",
        displayName = "🏆 CHAMPION: TestPlayer#123 — 15 KILLS"
    }
    TriggerClientEvent('thegreatwar:showChampion', -1, {champion = testChampion})
    print("^2[Test 2] ^7UI System test completed")
    
    -- Test 3: Combat System
    print("^3[Test 3] ^7Testing Combat System...")
    if GetResourceState('thegreatwar-combat') == 'started' then
        print("^2[Test 3] ^7Combat System - Resource running")
    else
        print("^1[Test 3] ^7Combat System - ERROR: Resource not started")
    end
    
    -- Test 4: Loot System
    print("^3[Test 4] ^7Testing Loot System...")
    if GetResourceState('thegreatwar-loot') == 'started' then
        print("^2[Test 4] ^7Loot System - Resource running")
    else
        print("^1[Test 4] ^7Loot System - ERROR: Resource not started")
    end
    
    -- Test 5: Integration
    print("^3[Test 5] ^7Testing Integration...")
    local gameState = exports['thegreatwar-core']:GetGameState()
    if gameState then
        print("^2[Test 5] ^7Integration - Game state accessible, status: " .. gameState.status)
    else
        print("^1[Test 5] ^7Integration - ERROR: Game state not accessible")
    end
    
    print("^2[Testing] ^7Phase 1 system tests completed!")
end, true)

-- Simple test commands
RegisterCommand('tgw_test', function(source, args)
    if source ~= 0 then return end
    print("^2[TGW Test] ^7Commands are working! Resource: thegreatwar-core is running")
    print("^2[TGW Test] ^7Available commands: tgw_test_phase1, tgw_start, tgw_end, tgw_status")
end, true)

RegisterCommand('tgw_resources', function(source, args)
    if source ~= 0 then return end
    print("^6=== THE GREAT WAR RESOURCE STATUS ===^7")
    local resources = {'thegreatwar-core', 'thegreatwar-ui', 'thegreatwar-combat', 'thegreatwar-loot'}
    for _, resource in ipairs(resources) do
        local state = GetResourceState(resource)
        local color = state == 'started' and '^2' or '^1'
        print("  " .. color .. resource .. ": " .. state .. "^7")
    end
    print("^6=====================================^7")
end, true)