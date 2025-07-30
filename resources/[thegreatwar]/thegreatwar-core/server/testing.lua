-- resources/[thegreatwar]/thegreatwar-core/server/testing.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Test Phase 1 Systems
RegisterCommand('tgw_test_phase1', function(source, args)
    if source ~= 0 then return end -- Server console only
    
    print("^3[Testing] ^7Starting Phase 1 system tests...")
    
    -- Test 1: UI System
    print("^3[Test 1] ^7Testing UI System...")
    local testChampion = {
        name = "TestPlayer#123",
        kills = 15,
        type = "solo",
        displayName = "🏆 CHAMPION: TestPlayer#123 — 15 KILLS"
    }
    TriggerClientEvent('thegreatwar:ui:updateChampion', -1, testChampion)
    TriggerClientEvent('thegreatwar:ui:showKillStreak', -1, 5, "TestPlayer")
    print("^2[Test 1] ^7UI System test completed")
    
    -- Test 2: Combat System
    print("^3[Test 2] ^7Testing Combat System...")
    local weaponConfig = exports['thegreatwar-combat']:GetWeaponConfig(`WEAPON_ASSAULTRIFLE`)
    if weaponConfig then
        print("^2[Test 2] ^7Combat System - Weapon config loaded: " .. weaponConfig.name)
    else
        print("^1[Test 2] ^7Combat System - ERROR: Weapon config not found")
    end
    
    -- Test 3: Loot System
    print("^3[Test 3] ^7Testing Loot System...")
    local activeCrates = exports['thegreatwar-loot']:GetActiveCrates()
    print("^2[Test 3] ^7Loot System - Active crates: " .. #activeCrates)
    
    -- Test 4: Integration
    print("^3[Test 4] ^7Testing Integration...")
    local gameState = exports['thegreatwar-core']:GetGameState()
    if gameState then
        print("^2[Test 4] ^7Integration - Game state accessible, status: " .. gameState.status)
    else
        print("^1[Test 4] ^7Integration - ERROR: Game state not accessible")
    end
    
    print("^2[Testing] ^7Phase 1 system tests completed!")
end, true)

-- Test individual systems
RegisterCommand('tgw_test_ui', function(source, args)
    if source ~= 0 then return end
    
    print("^3[UI Test] ^7Testing UI components...")
    
    -- Test champion display
    TriggerClientEvent('thegreatwar:ui:updateChampion', -1, {
        name = "UITest#999",
        kills = 25,
        type = "crew",
        displayName = "🏆 CHAMPION: TESTCREW_UITest#999 — 25 KILLS"
    })
    
    -- Test kill streak
    TriggerClientEvent('thegreatwar:ui:showKillStreak', -1, 10, "UITest")
    
    -- Test voting UI
    local testMaps = {
        city = {name = "Test City", description = "Urban test environment"},
        sandy = {name = "Test Sandy", description = "Desert test environment"}
    }
    TriggerClientEvent('thegreatwar:ui:showMapVoting', -1, testMaps, 15)
    
    print("^2[UI Test] ^7UI test commands sent to all clients")
end, true)

RegisterCommand('tgw_test_combat', function(source, args)
    if source ~= 0 then return end
    
    print("^3[Combat Test] ^7Testing combat system...")
    
    -- Test weapon configurations
    local weapons = {`WEAPON_PISTOL`, `WEAPON_ASSAULTRIFLE`, `WEAPON_SNIPERRIFLE`}
    for _, weapon in ipairs(weapons) do
        local config = exports['thegreatwar-combat']:GetWeaponConfig(weapon)
        if config then
            print("^2[Combat Test] ^7" .. config.name .. " - Damage: " .. config.damage .. ", Range: " .. config.range)
        else
            print("^1[Combat Test] ^7ERROR: Config not found for weapon " .. weapon)
        end
    end
    
    print("^2[Combat Test] ^7Combat system test completed")
end, true)

RegisterCommand('tgw_test_loot', function(source, args)
    if source ~= 0 then return end
    
    print("^3[Loot Test] ^7Testing loot system...")
    
    -- Get active loot
    local crates = exports['thegreatwar-loot']:GetActiveCrates()
    local drops = exports['thegreatwar-loot']:GetActiveDrops()
    local supplies = exports['thegreatwar-loot']:GetActiveSupplyDrops()
    
    print("^2[Loot Test] ^7Active Crates: " .. #crates)
    print("^2[Loot Test] ^7Active Death Drops: " .. #drops)
    print("^2[Loot Test] ^7Active Supply Drops: " .. #supplies)
    
    -- Create test loot
    local testCoords = vector3(0.0, 0.0, 72.0)
    exports['thegreatwar-loot']:CreateCustomLoot(testCoords, "weapon_crate", {
        {item = "WEAPON_PISTOL", quantity = 1},
        {item = "pistol_ammo", quantity = 100}
    })
    
    print("^2[Loot Test] ^7Test loot crate created at city center")
end, true)