-- resources/[thegreatwar]/thegreatwar-combat/shared/combat-config.lua
CombatConfig = {}

-- Weapon Configurations
CombatConfig.Weapons = {
    -- Assault Rifles
    [`WEAPON_ASSAULTRIFLE`] = {
        name = "AK-47",
        damage = 40,
        range = 200.0,
        accuracy = 0.7,
        durability = 500,
        roleRestriction = {"assault", "support"},
        cost = 500,
        ammoType = "rifle_ammo",
        category = "assault_rifle"
    },
    [`WEAPON_CARBINERIFLE`] = {
        name = "M4A1",
        damage = 35,
        range = 180.0,
        accuracy = 0.8,
        durability = 600,
        roleRestriction = {"assault", "support"},
        cost = 400,
        ammoType = "rifle_ammo",
        category = "assault_rifle"
    },
    
    -- SMGs
    [`WEAPON_SMG`] = {
        name = "MP5",
        damage = 25,
        range = 80.0,
        accuracy = 0.6,
        durability = 400,
        roleRestriction = {"medic", "support"},
        cost = 300,
        ammoType = "pistol_ammo",
        category = "smg"
    },
    
    -- Sniper Rifles
    [`WEAPON_SNIPERRIFLE`] = {
        name = "AWP",
        damage = 120,
        range = 500.0,
        accuracy = 0.95,
        durability = 200,
        roleRestriction = {"recon"},
        cost = 800,
        ammoType = "sniper_ammo",
        category = "sniper"
    },
    
    -- Pistols
    [`WEAPON_PISTOL`] = {
        name = "Glock 17",
        damage = 20,
        range = 50.0,
        accuracy = 0.5,
        durability = 300,
        roleRestriction = {"all"},
        cost = 100,
        ammoType = "pistol_ammo",
        category = "pistol"
    },
    [`WEAPON_COMBATPISTOL`] = {
        name = "Combat Pistol",
        damage = 25,
        range = 60.0,
        accuracy = 0.6,
        durability = 350,
        roleRestriction = {"all"},
        cost = 150,
        ammoType = "pistol_ammo",
        category = "pistol"
    },
    
    -- Explosives
    [`WEAPON_GRENADELAUNCHER`] = {
        name = "Grenade Launcher",
        damage = 200,
        range = 150.0,
        accuracy = 0.4,
        durability = 100,
        roleRestriction = {"assault"},
        cost = 1000,
        ammoType = "explosive_ammo",
        category = "explosive"
    }
}

-- Role-based damage multipliers
CombatConfig.RoleDamageMultipliers = {
    assault = {
        outgoing = 1.2,  -- 20% more damage dealt
        incoming = 1.0   -- Normal damage received
    },
    support = {
        outgoing = 0.9,  -- 10% less damage dealt
        incoming = 0.9   -- 10% less damage received
    },
    medic = {
        outgoing = 0.8,  -- 20% less damage dealt
        incoming = 0.8   -- 20% less damage received
    },
    recon = {
        outgoing = 1.5,  -- 50% more damage with sniper rifles
        incoming = 1.1   -- 10% more damage received
    }
}

-- Armor Configuration
CombatConfig.Armor = {
    maxArmor = 100,
    maxArmorKits = 3,
    armorRepairAmount = 50,
    armorDecayRate = 0.5, -- per hit
    autoPickup = true
}

-- Health Configuration
CombatConfig.Health = {
    maxHealth = 100,
    medkitHealAmount = 30,
    maxMedkits = 5,
    bloodEffectThreshold = 50,
    criticalHealthThreshold = 25
}

-- Kill Streak Configuration
CombatConfig.KillStreaks = {
    {kills = 3, name = "Killing Spree", reward = 100},
    {kills = 5, name = "Dominating", reward = 200},
    {kills = 7, name = "Rampage", reward = 300},
    {kills = 10, name = "Unstoppable", reward = 500},
    {kills = 15, name = "Godlike", reward = 1000}
}

-- Anti-Cheat Configuration
CombatConfig.AntiCheat = {
    maxKillsPerMinute = 10,
    maxDamagePerSecond = 500,
    impossibleShotDistance = 1000.0,
    minTimeBetweenKills = 500, -- milliseconds
    suspiciousKillStreakThreshold = 20
}