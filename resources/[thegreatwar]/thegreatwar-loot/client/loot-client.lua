-- resources/[thegreatwar]/thegreatwar-loot/client/loot-client.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Client loot state
local LootObjects = {}
local LootBlips = {}

-- Create loot crate object
local function CreateLootObject(lootData)
    local model = lootData.model or `prop_box_guncase_02a`
    local coords = lootData.coords
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    
    local object = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    SetEntityAsMissionEntity(object, true, true)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)
    
    -- Create interaction
    exports['qb-target']:AddTargetEntity(object, {
        options = {
            {
                type = "client",
                event = "thegreatwar:loot:openCrate",
                icon = "fas fa-box-open",
                label = "Open " .. (lootData.type:gsub("_", " ")):gsub("^%l", string.upper),
                crateId = lootData.id,
                canInteract = function()
                    return not lootData.looted
                end
            }
        },
        distance = 2.0
    })
    
    -- Create blip
    local blip = AddBlipForEntity(object)
    SetBlipSprite(blip, GetBlipSpriteForCrateType(lootData.type))
    SetBlipColour(blip, GetBlipColorForCrateType(lootData.type))
    SetBlipScale(blip, 0.7)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(lootData.type:gsub("_", " "):gsub("^%l", string.upper))
    EndTextCommandSetBlipName(blip)
    
    LootObjects[lootData.id] = {
        object = object,
        blip = blip,
        data = lootData
    }
end

-- Get blip sprite for crate type
function GetBlipSpriteForCrateType(crateType)
    local sprites = {
        weapon_crate = 110,
        armor_crate = 175,
        medical_crate = 153,
        ammo_crate = 106,
        supply_drop = 478
    }
    return sprites[crateType] or 108
end

-- Get blip color for crate type
function GetBlipColorForCrateType(crateType)
    local colors = {
        weapon_crate = 1,  -- Red
        armor_crate = 3,   -- Blue
        medical_crate = 2, -- Green
        ammo_crate = 5,    -- Yellow
        supply_drop = 17   -- Orange
    }
    return colors[crateType] or 0
end

-- Create death drop
local function CreateDeathDrop(dropData)
    local coords = dropData.coords
    
    -- Create bag object
    local model = `prop_cs_shopping_bag`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    
    local object = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    SetEntityAsMissionEntity(object, true, true)
    PlaceObjectOnGroundProperly(object)
    
    -- Add interaction
    exports['qb-target']:AddTargetEntity(object, {
        options = {
            {
                type = "client",
                event = "thegreatwar:loot:lootDeathDrop",
                icon = "fas fa-hand-paper",
                label = "Loot Death Drop",
                dropId = dropData.id
            }
        },
        distance = 2.0
    })
    
    LootObjects[dropData.id] = {
        object = object,
        data = dropData,
        type = "death"
    }
end

-- Create supply drop
local function CreateSupplyDrop(dropData)
    if dropData.phase ~= "landed" then return end
    
    local coords = dropData.coords
    local model = LootConfig.CrateModels.supply_drop or `prop_box_ammo05a`
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    
    local object = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    SetEntityAsMissionEntity(object, true, true)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)
    
    -- Create special effect
    UseParticleFxAssetNextCall("core")
    local effect = StartNetworkedParticleFxLoopedOnEntity("ent_amb_smoke_flare", object, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
    
    -- Add interaction
    exports['qb-target']:AddTargetEntity(object, {
        options = {
            {
                type = "client",
                event = "thegreatwar:loot:lootSupplyDrop",
                icon = "fas fa-parachute-box",
                label = "Loot Supply Drop",
                dropId = dropData.id
            }
        },
        distance = 3.0
    })
    
    -- Create blip
    local blip = AddBlipForEntity(object)
    SetBlipSprite(blip, 478)
    SetBlipColour(blip, 17)
    SetBlipScale(blip, 1.2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Supply Drop")
    EndTextCommandSetBlipName(blip)
    
    LootObjects[dropData.id] = {
        object = object,
        blip = blip,
        effect = effect,
        data = dropData,
        type = "supply"
    }
end

-- Events
RegisterNetEvent('thegreatwar:loot:spawnCrate', function(crateData)
    CreateLootObject(crateData)
end)

RegisterNetEvent('thegreatwar:loot:spawnDeathDrop', function(dropData)
    CreateDeathDrop(dropData)
end)

RegisterNetEvent('thegreatwar:loot:supplyDropLanded', function(dropData)
    CreateSupplyDrop(dropData)
end)

RegisterNetEvent('thegreatwar:loot:announceSupplyDrop', function(dropData)
    -- Show supply drop announcement
    QBCore.Functions.Notify("📦 Supply Drop announced at " .. dropData.name .. "!", "warning", 5000)
end)

RegisterNetEvent('thegreatwar:loot:supplyDropIncoming', function(dropData)
    -- Play sound and show incoming notification
    PlaySoundFrontend(-1, "Air_Defences_Activated", "DLC_sum20_Business_Battle_AC_Sounds", 1)
    QBCore.Functions.Notify("📦 Supply Drop incoming! Take cover!", "error", 3000)
end)

RegisterNetEvent('thegreatwar:loot:crateLooted', function(crateId)
    local lootObject = LootObjects[crateId]
    if lootObject and lootObject.data then
        lootObject.data.looted = true
        
        -- Change blip color to indicate looted
        if lootObject.blip then
            SetBlipColour(lootObject.blip, 8) -- Dark grey
        end
    end
end)

RegisterNetEvent('thegreatwar:loot:respawnCrate', function(crateData)
    local lootObject = LootObjects[crateData.id]
    if lootObject then
        lootObject.data = crateData
        
        -- Reset blip color
        if lootObject.blip then
            SetBlipColour(lootObject.blip, GetBlipColorForCrateType(crateData.type))
        end
    end
end)

RegisterNetEvent('thegreatwar:loot:removeDrop', function(dropId, dropType)
    local lootObject = LootObjects[dropId]
    if lootObject then
        if lootObject.object and DoesEntityExist(lootObject.object) then
            DeleteEntity(lootObject.object)
        end
        if lootObject.blip then
            RemoveBlip(lootObject.blip)
        end
        if lootObject.effect then
            StopParticleFxLooped(lootObject.effect, 0)
        end
        
        LootObjects[dropId] = nil
    end
end)

-- Interaction events
RegisterNetEvent('thegreatwar:loot:openCrate', function(data)
    local crateId = data.crateId
    TriggerServerEvent('thegreatwar:loot:lootCrate', crateId)
end)

RegisterNetEvent('thegreatwar:loot:lootDeathDrop', function(data)
    local dropId = data.dropId
    TriggerServerEvent('thegreatwar:loot:lootDeathDrop', dropId)
end)

RegisterNetEvent('thegreatwar:loot:lootSupplyDrop', function(data)
    local dropId = data.dropId
    TriggerServerEvent('thegreatwar:loot:lootSupplyDrop', dropId)
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, lootObject in pairs(LootObjects) do
        if lootObject.object and DoesEntityExist(lootObject.object) then
            DeleteEntity(lootObject.object)
        end
        if lootObject.blip then
            RemoveBlip(lootObject.blip)
        end
        if lootObject.effect then
            StopParticleFxLooped(lootObject.effect, 0)
        end
    end
end)