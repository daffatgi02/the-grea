-- resources/[thegreatwar]/thegreatwar-core/config.lua
Config = {}

-- Game Session Settings
Config.SessionDuration = 60 * 60 * 1000 -- 1 jam dalam milliseconds
Config.LobbyDuration = 30 * 1000 -- 30 detik voting
Config.MaxPlayers = 48

-- Maps Configuration
Config.Maps = {
    ["city"] = {
        name = "Perkotaan (City)",
        spawns = {
            {x = 215.0, y = -810.0, z = 30.8, h = 342.0},
            {x = -1037.0, y = -2737.0, z = 20.2, h = 240.0},
            {x = 1729.0, y = 3320.0, z = 41.2, h = 195.0}
        },
        safezone = {x = -1037.8, y = -2674.0, z = 13.8, radius = 100.0},
        description = "Urban warfare in Los Santos"
    },
    ["sandy"] = {
        name = "Sandy Shores",
        spawns = {
            {x = 1836.0, y = 3672.0, z = 34.3, h = 210.0},
            {x = 1961.0, y = 3740.0, z = 32.3, h = 30.0},
            {x = 1697.0, y = 3596.0, z = 35.4, h = 220.0}
        },
        safezone = {x = 1693.0, y = 3584.0, z = 35.6, radius = 80.0},
        description = "Desert combat zone"
    },
    ["paleto"] = {
        name = "Paleto Bay",
        spawns = {
            {x = -378.0, y = 6045.0, z = 31.5, h = 45.0},
            {x = -140.0, y = 6200.0, z = 31.9, h = 135.0},
            {x = -558.0, y = 5348.0, z = 70.2, h = 70.0}
        },
        safezone = {x = -378.0, y = 6045.0, z = 31.5, radius = 90.0},
        description = "Northern wilderness battle"
    }
}

-- Combat Settings
Config.Combat = {
    MaxHealth = 100,
    MaxArmor = 100,
    MaxArmorKits = 3,
    KillReward = 100,
    FriendlyFire = true,
    WeaponDurability = true
}

-- Role System
Config.Roles = {
    ["assault"] = {
        name = "Assault",
        icon = "💥",
        abilities = {
            damage_multiplier = 1.2,
            heavy_weapons = true,
            armor_boost = 0
        },
        weapons = {"WEAPON_ASSAULTRIFLE", "WEAPON_COMBATPISTOL", "WEAPON_GRENADELAUNCHER"}
    },
    ["support"] = {
        name = "Support",
        icon = "🎯",
        abilities = {
            ammo_capacity = 2.0,
            share_ammo = true,
            armor_boost = 0
        },
        weapons = {"WEAPON_CARBINERIFLE", "WEAPON_PISTOL", "WEAPON_SMOKEGRENADE"}
    },
    ["medic"] = {
        name = "Medic",
        icon = "⚕️",
        abilities = {
            revive_speed = 2.0,
            medical_kit_bonus = 2,
            armor_boost = 0
        },
        weapons = {"WEAPON_SMG", "WEAPON_PISTOL"}
    },
    ["recon"] = {
        name = "Recon",
        icon = "👁️",
        abilities = {
            radar_range = 2.0,
            mark_enemies = true,
            armor_boost = 0
        },
        weapons = {"WEAPON_SNIPERRIFLE", "WEAPON_COMBATPISTOL"}
    }
}

-- Economy Settings
Config.Economy = {
    KillReward = 100,
    AssistReward = 50,
    SurvivalBonus = 10, -- per minute survived
    ShopItems = {
        ["weapon_assaultrifle"] = 500,
        ["weapon_carbinerifle"] = 400,
        ["armor"] = 100,
        ["bandage"] = 50
    }
}

-- Zone Colors for Dynamic Map
Config.ZoneColors = {
    red = {255, 0, 0, 100},    -- High activity
    yellow = {255, 255, 0, 100}, -- Medium activity  
    white = {255, 255, 255, 50}  -- Low activity
}