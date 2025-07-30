-- resources/[thegreatwar]/thegreatwar-loot/server/loot-manager.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Active loot crates and drops
local ActiveLootCrates = {}
local ActiveDeathDrops = {}
local ActiveSupplyDrops = {}
local CurrentMap = nil

-- Generate loot from table
local function GenerateLoot(lootTable)
    local loot = {}
    
    for _, item in ipairs(lootTable) do
        if math.random(100) <= item.probability then
            local quantity = item.quantity
            if item.min and item.max then
                quantity = math.random(item.min, item.max)
            end
            
            table.insert(loot, {
                item = item.item,
                quantity = quantity
            })
        end
    end
    
    return loot
end

-- Create loot crate
local function CreateLootCrate(coords, crateType, loot)
    local crateId = #ActiveLootCrates + 1
    local model = LootConfig.CrateModels[crateType] or `prop_box_guncase_02a`
    
    local crate = {
        id = crateId,
        coords = coords,
        type = crateType,
        loot = loot,
        model = model,
        looted = false,
        created = GetGameTimer()
    }
    
    ActiveLootCrates[crateId] = crate
    
    -- Spawn crate for all clients
    TriggerClientEvent('thegreatwar:loot:spawnCrate', -1, crate)
    
    return crateId
end

-- Initialize loot system for map
local function InitializeLootSystem(mapName)
    CurrentMap = mapName
    
    -- Clear existing loot
    ActiveLootCrates = {}
    ActiveDeathDrops = {}
    ActiveSupplyDrops = {}
    
    -- Spawn map loot crates
    local locations = LootConfig.SpawnLocations[mapName]
    if locations then
        for _, location in ipairs(locations) do
            local lootTable = LootConfig.LootTables[location.type]
            if lootTable then
                local loot = GenerateLoot(lootTable)
                CreateLootCrate(location.coords, location.type, loot)
            end
        end
    end
    
    print("^2[Loot System] ^7Initialized for map: " .. mapName)
end

-- Handle player death drops
local function CreateDeathDrop(coords, playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return end
    
    -- Generate death drop loot
    local loot = {}
    
    -- Always drop items
    for _, item in ipairs(LootConfig.DeathDrops.alwaysDrop) do
        local hasItem = Player.Functions.GetItemByName(item)
        if hasItem and hasItem.amount > 0 then
            table.insert(loot, {
                item = item,
                quantity = math.min(hasItem.amount, 3)
            })
        end
    end
    
    -- Chance drop items
    for _, chanceItem in ipairs(LootConfig.DeathDrops.chanceDrop) do
        if math.random(100) <= chanceItem.chance then
            if chanceItem.item == "money" then
                local money = Player.Functions.GetMoney('cash')
                if money > 0 then
                    local dropAmount = math.random(chanceItem.min, math.min(chanceItem.max, money))
                    table.insert(loot, {
                        item = "money",
                        quantity = dropAmount
                    })
                end
            else
                local hasItem = Player.Functions.GetItemByName(chanceItem.item)
                if hasItem and hasItem.amount > 0 then
                    table.insert(loot, {
                        item = chanceItem.item,
                        quantity = math.min(hasItem.amount, 2)
                    })
                end
            end
        end
    end
    
    -- Create death drop if we have loot
    if #loot > 0 then
        local dropId = #ActiveDeathDrops + 1
        local deathDrop = {
            id = dropId,
            coords = coords,
            loot = loot,
            created = GetGameTimer(),
            owner = playerId
        }
        
        ActiveDeathDrops[dropId] = deathDrop
        
        -- Spawn drop for all clients
        TriggerClientEvent('thegreatwar:loot:spawnDeathDrop', -1, deathDrop)
        
        -- Remove drop after configured time
        SetTimeout(LootConfig.DeathDrops.despawnTime, function()
            ActiveDeathDrops[dropId] = nil
            TriggerClientEvent('thegreatwar:loot:removeDrop', -1, dropId, 'death')
        end)
    end
end

-- Start supply drop
local function StartSupplyDrop()
    if not CurrentMap or not LootConfig.SupplyDrops.enabled then return end
    
    local locations = LootConfig.SupplyDrops.locations[CurrentMap]
    if not locations or #locations == 0 then return end
    
    local location = locations[math.random(#locations)]
    local dropId = #ActiveSupplyDrops + 1
    
    -- Generate high-tier loot
    local loot = GenerateLoot(LootConfig.SupplyDrops.lootTable)
    
    local supplyDrop = {
        id = dropId,
        coords = location.coords,
        name = location.name,
        loot = loot,
        phase = "announced", -- announced -> incoming -> landed -> active -> expired
        created = GetGameTimer()
    }
    
    ActiveSupplyDrops[dropId] = supplyDrop
    
    -- Announce supply drop
    TriggerClientEvent('thegreatwar:loot:announceSupplyDrop', -1, supplyDrop)
    TriggerClientEvent('QBCore:Notify', -1, 
        "📦 Supply Drop incoming at " .. location.name .. "! ETA: 30 seconds", "warning", 5000)
    
    -- Start supply drop sequence
    SetTimeout(LootConfig.SupplyDrops.announceTime, function()
        supplyDrop.phase = "incoming"
        TriggerClientEvent('thegreatwar:loot:supplyDropIncoming', -1, supplyDrop)
        
        SetTimeout(LootConfig.SupplyDrops.landingTime - LootConfig.SupplyDrops.announceTime, function()
            supplyDrop.phase = "landed"
            supplyDrop.coords = vector3(location.coords.x, location.coords.y, 
                                      GetGroundZFor_3dCoord(location.coords.x, location.coords.y, location.coords.z, 0))
            TriggerClientEvent('thegreatwar:loot:supplyDropLanded', -1, supplyDrop)
            
            SetTimeout(LootConfig.SupplyDrops.activeTime, function()
                supplyDrop.phase = "expired"
                ActiveSupplyDrops[dropId] = nil
                TriggerClientEvent('thegreatwar:loot:removeDrop', -1, dropId, 'supply')
            end)
        end)
    end)
end

-- Handle crate looting
RegisterNetEvent('thegreatwar:loot:lootCrate', function(crateId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local crate = ActiveLootCrates[crateId]
    if not crate or crate.looted then
        TriggerClientEvent('QBCore:Notify', src, "This crate is empty or already looted", "error")
        return
    end
    
    -- Mark as looted
    crate.looted = true
    
    -- Give loot to player
    local itemsGiven = 0
    for _, lootItem in ipairs(crate.loot) do
        if lootItem.item == "money" then
            Player.Functions.AddMoney('cash', lootItem.quantity)
            TriggerClientEvent('QBCore:Notify', src, 
                "Found $" .. lootItem.quantity .. " in the crate!", "success")
        else
            Player.Functions.AddItem(lootItem.item, lootItem.quantity)
            TriggerClientEvent('QBCore:Notify', src, 
                "Found " .. lootItem.quantity .. "x " .. lootItem.item, "success")
        end
        itemsGiven = itemsGiven + 1
    end
    
    if itemsGiven == 0 then
        TriggerClientEvent('QBCore:Notify', src, "The crate was empty...", "error")
    end
    
    -- Update crate for all clients
    TriggerClientEvent('thegreatwar:loot:crateLooted', -1, crateId)
    
    -- Respawn crate after 2 minutes
    SetTimeout(120000, function()
        local lootTable = LootConfig.LootTables[crate.type]
        if lootTable then
            crate.loot = GenerateLoot(lootTable)
            crate.looted = false
            TriggerClientEvent('thegreatwar:loot:respawnCrate', -1, crate)
        end
    end)
end)

-- Handle death drop looting
RegisterNetEvent('thegreatwar:loot:lootDeathDrop', function(dropId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local drop = ActiveDeathDrops[dropId]
    if not drop then
        TriggerClientEvent('QBCore:Notify', src, "This drop is no longer available", "error")
        return
    end
    
    -- Give loot to player
    for _, lootItem in ipairs(drop.loot) do
        if lootItem.item == "money" then
            Player.Functions.AddMoney('cash', lootItem.quantity)
            TriggerClientEvent('QBCore:Notify', src, 
                "Picked up $" .. lootItem.quantity, "success")
        else
            Player.Functions.AddItem(lootItem.item, lootItem.quantity)
            TriggerClientEvent('QBCore:Notify', src, 
                "Picked up " .. lootItem.quantity .. "x " .. lootItem.item, "success")
        end
    end
    
    -- Remove death drop
    ActiveDeathDrops[dropId] = nil
    TriggerClientEvent('thegreatwar:loot:removeDrop', -1, dropId, 'death')
end)

-- Handle supply drop looting
RegisterNetEvent('thegreatwar:loot:lootSupplyDrop', function(dropId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local drop = ActiveSupplyDrops[dropId]
    if not drop or drop.phase ~= "landed" then
        TriggerClientEvent('QBCore:Notify', src, "Supply drop is not available for looting", "error")
        return
    end
    
    -- Give loot to player
    for _, lootItem in ipairs(drop.loot) do
        if lootItem.item == "money" then
            Player.Functions.AddMoney('cash', lootItem.quantity)
            TriggerClientEvent('QBCore:Notify', src, 
                "Found $" .. lootItem.quantity .. " in supply drop!", "success")
        else
            Player.Functions.AddItem(lootItem.item, lootItem.quantity)
            TriggerClientEvent('QBCore:Notify', src, 
                "Found " .. lootItem.quantity .. "x " .. lootItem.item .. " in supply drop!", "success")
        end
    end
    
    -- Remove supply drop
    ActiveSupplyDrops[dropId] = nil
    TriggerClientEvent('thegreatwar:loot:removeDrop', -1, dropId, 'supply')
    
    TriggerClientEvent('QBCore:Notify', -1, 
        Player.PlayerData.charinfo.firstname .. " has claimed the supply drop!", "info", 3000)
end)

-- Session events
RegisterNetEvent('thegreatwar:sessionStarted', function(sessionData)
    InitializeLootSystem(sessionData.map)
    
    -- Start supply drop timer
    if LootConfig.SupplyDrops.enabled then
        CreateThread(function()
            Wait(LootConfig.SupplyDrops.interval)
            while true do
                StartSupplyDrop()
                Wait(LootConfig.SupplyDrops.interval)
            end
        end)
    end
end)

-- Player death event
RegisterNetEvent('thegreatwar:playerDied', function(coords)
    local src = source
    CreateDeathDrop(coords, src)
end)

-- Export functions
exports('GetActiveCrates', function() return ActiveLootCrates end)
exports('GetActiveDrops', function() return ActiveDeathDrops end)
exports('GetActiveSupplyDrops', function() return ActiveSupplyDrops end)
exports('CreateCustomLoot', CreateLootCrate)