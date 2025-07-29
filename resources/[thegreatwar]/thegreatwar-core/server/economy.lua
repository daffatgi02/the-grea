-- resources/[thegreatwar]/thegreatwar-core/server/economy.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Shop Functions
function OpenWeaponShop(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local money = Player.Functions.GetMoney('cash')
    local shopItems = {}
    
    for item, price in pairs(Config.economy.shopItems) do
        table.insert(shopItems, {
            item = item,
            price = price,
            canAfford = money >= price
        })
    end
    
    TriggerClientEvent('thegreatwar:openShop', src, shopItems)
end

function PurchaseItem(src, item, price)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local money = Player.Functions.GetMoney('cash')
    if money < price then
        TriggerClientEvent('QBCore:Notify', src, "Not enough money", "error")
        return false
    end
    
    Player.Functions.RemoveMoney('cash', price)
    Player.Functions.AddItem(item, 1)
    TriggerClientEvent('QBCore:Notify', src, "Item purchased: " .. item, "success")
    return true
end

-- Reward Functions
function RewardKill(killerId, victimId)
    local Killer = QBCore.Functions.GetPlayer(killerId)
    if not Killer then return end
    
    local reward = Config.economy.killReward
    Killer.Functions.AddMoney('cash', reward)
    
    TriggerClientEvent('QBCore:Notify', killerId, "Kill reward: $" .. reward, "success")
end

function RewardAssist(assisterId)
    local Player = QBCore.Functions.GetPlayer(assisterId)
    if not Player then return end
    
    local reward = Config.economy.assistReward
    Player.Functions.AddMoney('cash', reward)
    
    TriggerClientEvent('QBCore:Notify', assisterId, "Assist reward: $" .. reward, "success")
end

-- Network Events
RegisterNetEvent('thegreatwar:openShop', function()
    local src = source
    OpenWeaponShop(src)
end)

RegisterNetEvent('thegreatwar:buyItem', function(item, price)
    local src = source
    PurchaseItem(src, item, price)
end)

-- Exports
exports('RewardKill', RewardKill)
exports('RewardAssist', RewardAssist)