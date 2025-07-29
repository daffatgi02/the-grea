-- resources/[thegreatwar]/thegreatwar-core/server/crews.lua
local QBCore = exports['qb-core']:GetCoreObject()
local Crews = {}

-- Crew Management Functions
function CreateCrew(creatorId, crewName)
    if Crews[crewName] then
        return false, "Crew name already exists"
    end
    
    Crews[crewName] = {
        name = crewName,
        leader = creatorId,
        members = {[creatorId] = true},
        memberCount = 1,
        totalKills = 0,
        created = os.time()
    }
    
    return true, "Crew created successfully"
end

function JoinCrew(playerId, crewName)
    if not Crews[crewName] then
        return false, "Crew does not exist"
    end
    
    if Crews[crewName].memberCount >= 6 then -- Max 6 members
        return false, "Crew is full"
    end
    
    -- Remove from previous crew
    LeaveCrew(playerId)
    
    Crews[crewName].members[playerId] = true
    Crews[crewName].memberCount = Crews[crewName].memberCount + 1
    
    return true, "Joined crew successfully"
end

function LeaveCrew(playerId)
    for crewName, crew in pairs(Crews) do
        if crew.members[playerId] then
            crew.members[playerId] = nil
            crew.memberCount = crew.memberCount - 1
            
            -- Delete crew if empty
            if crew.memberCount == 0 then
                Crews[crewName] = nil
            end
            return true
        end
    end
    return false
end

-- Network Events
RegisterNetEvent('thegreatwar:createCrew', function(crewName)
    local src = source
    local success, message = CreateCrew(src, crewName)
    TriggerClientEvent('QBCore:Notify', src, message, success and "success" or "error")
end)

RegisterNetEvent('thegreatwar:joinCrew', function(crewName)
    local src = source
    local success, message = JoinCrew(src, crewName)
    TriggerClientEvent('QBCore:Notify', src, message, success and "success" or "error")
end)

-- Exports
exports('GetCrews', function() return Crews end)
exports('GetPlayerCrew', function(playerId)
    for crewName, crew in pairs(Crews) do
        if crew.members[playerId] then
            return crewName, crew
        end
    end
    return nil
end)