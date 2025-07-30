-- resources/[thegreatwar]/thegreatwar-core/server/performance.lua
local performanceData = {
    tickCount = 0,
    lastTick = GetGameTimer(),
    averageTickTime = 0,
    memoryUsage = 0,
    playerCount = 0,
    activeEvents = 0
}

-- Monitor server performance
CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        local tickTime = currentTime - performanceData.lastTick
        
        performanceData.tickCount = performanceData.tickCount + 1
        performanceData.lastTick = currentTime
        performanceData.averageTickTime = (performanceData.averageTickTime + tickTime) / 2
        performanceData.playerCount = GetNumPlayerIndices()
        
        -- Log performance every 5 minutes
        if performanceData.tickCount % 300 == 0 then
            print(string.format("^6[Performance] ^7Avg Tick: %.2fms | Players: %d | Memory: %.2fMB", 
                performanceData.averageTickTime, 
                performanceData.playerCount,
                collectgarbage("count") / 1024))
        end
        
        Wait(1000)
    end
end)

-- Performance command
RegisterCommand('tgw_performance', function(source, args)
    if source ~= 0 then return end
    
    print("^6=== THE GREAT WAR PERFORMANCE REPORT ===^7")
    print("^6Server Uptime:^7 " .. math.floor(GetGameTimer() / 1000) .. " seconds")
    print("^6Average Tick Time:^7 " .. string.format("%.2f", performanceData.averageTickTime) .. "ms")
    print("^6Current Players:^7 " .. performanceData.playerCount)
    print("^6Memory Usage:^7 " .. string.format("%.2f", collectgarbage("count") / 1024) .. "MB")
    
    -- Check resource states
    local resources = {'thegreatwar-core', 'thegreatwar-ui', 'thegreatwar-combat', 'thegreatwar-loot'}
    print("^6Resource States:^7")
    for _, resource in ipairs(resources) do
        local state = GetResourceState(resource)
        local color = state == 'started' and '^2' or '^1'
        print("  " .. color .. resource .. ": " .. state .. "^7")
    end
    
    -- Game state info
    local gameState = exports['thegreatwar-core']:GetGameState()
    if gameState then
        print("^6Game State:^7")
        print("  Status: " .. gameState.status)
        print("  Current Map: " .. (gameState.currentMap or "None"))
        print("  Active Players: " .. (gameState.players and #gameState.players or 0))
        print("  Session ID: " .. (gameState.currentSession or "None"))
    end
    
    print("^6==========================================^7")
end, true)