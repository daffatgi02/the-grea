-- resources/[thegreatwar]/thegreatwar-loot/shared/loot-config.lua
LootConfig = {}

-- Loot spawn locations per map
LootConfig.SpawnLocations = {
    city = {
        {coords = vector3(215.0, -810.0, 30.8), type = "weapon_crate"},
        {coords = vector3(-1037.0, -2737.0, 20.2), type = "armor_crate"},
        {coords = vector3(1729.0, 3320.0, 41.2), type = "medical_crate"},
        {coords = vector3(-47.0, -1757.0, 29.4), type = "ammo_crate"},
        {coords = vector3(441.0, -981.0, 30.7), type = "weapon_crate"}
    },
    sandy = {
        {coords = vector3(1697.0, 3596.0, 35.4), type = "weapon_crate"},
        {coords = vector3(1836.0, 3672.0, 34.3), type = "armor_crate"},
        {coords = vector3(1961.0, 3740.0, 32.3), type = "medical_crate"}
    },
    paleto = {
        {coords = vector3(-378.0, 6045.0, 31.5), type = "weapon_crate"},
        {coords = vector3(-140.0, 6200.0, 31.9), type = "armor_crate"},
        {coords = vector3(-558.0, 5348.0, 70.2), type = "medical_crate"}
    }
}

-- Loot tables
LootConfig.LootTables = {
    weapon_crate = {
        {item = "WEAPON_PISTOL", probability = 30, quantity = 1},
        {item = "WEAPON_SMG", probability = 25, quantity = 1},
        {item = "WEAPON_ASSAULTRIFLE", probability = 20, quantity = 1},
        {item = "WEAPON_CARBINERIFLE", probability = 15, quantity = 1},
        {item = "pistol_ammo", probability = 50, quantity = 100},
        {item = "rifle_ammo", probability = 40, quantity = 50}
    },
    
    armor_crate = {
        {item = "armor", probability = 80, quantity = 1},
        {item = "armor_kit", probability = 60, quantity = 2},
        {item = "heavy_armor", probability = 20, quantity = 1}
    },
    
    medical_crate = {
        {item = "bandage", probability = 90, quantity = 3},
        {item = "medkit", probability = 70, quantity = 2},
        {item = "painkillers", probability = 50, quantity = 1},
        {item = "adrenaline", probability = 30, quantity = 1}
    },
    
    ammo_crate = {
        {item = "pistol_ammo", probability = 80, quantity = 200},
        {item = "rifle_ammo", probability = 70, quantity = 150},
        {item = "sniper_ammo", probability = 40, quantity = 50},
        {item = "explosive_ammo", probability = 20, quantity = 10}
    }
}

-- Death drop configuration
LootConfig.DeathDrops = {
    dropChance = 80, -- 80% chance to drop items on death
    maxItems = 3,    -- Maximum items to drop
    dropRadius = 2.0, -- Radius around death location
    despawnTime = 300000, -- 5 minutes in milliseconds
    
    -- Items that always drop
    alwaysDrop = {
        "armor",
        "medkit",
        "bandage"
    },
    
    -- Items that sometimes drop
    chanceDrop = {
        {item = "pistol_ammo", chance = 60},
        {item = "rifle_ammo", chance = 50},
        {item = "money", chance = 90, min = 50, max = 200}
    }
}

-- Supply drop configuration
LootConfig.SupplyDrops = {
    enabled = true,
    interval = 300000, -- 5 minutes
    announceTime = 30000, -- 30 seconds warning
    landingTime = 45000, -- 45 seconds to land
    activeTime = 180000, -- 3 minutes active
    
    locations = {
        city = {
            {coords = vector3(0.0, 0.0, 200.0), name = "Downtown"},
            {coords = vector3(-500.0, -500.0, 200.0), name = "South LS"},
            {coords = vector3(500.0, 500.0, 200.0), name = "North LS"}
        },
        sandy = {
            {coords = vector3(1700.0, 3600.0, 200.0), name = "Sandy Center"}
        },
        paleto = {
            {coords = vector3(-400.0, 6000.0, 200.0), name = "Paleto Center"}
        }
    },
    
    lootTable = {
        {item = "WEAPON_SNIPERRIFLE", probability = 15, quantity = 1},
        {item = "WEAPON_GRENADELAUNCHER", probability = 10, quantity = 1},
        {item = "heavy_armor", probability = 40, quantity = 2},
        {item = "sniper_ammo", probability = 60, quantity = 100},
        {item = "explosive_ammo", probability = 30, quantity = 20},
        {item = "money", probability = 100, quantity = 1000}
    }
}

-- Crate models
LootConfig.CrateModels = {
    weapon_crate = `prop_box_guncase_02a`,
    armor_crate = `prop_box_ammo04a`,
    medical_crate = `prop_box_ammo02a`,
    ammo_crate = `prop_box_ammo03a`,
    supply_drop = `prop_box_ammo05a`
}