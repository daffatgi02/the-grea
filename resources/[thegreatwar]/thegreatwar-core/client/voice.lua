-- resources/[thegreatwar]/thegreatwar-core/client/voice.lua
local QBCore = exports['qb-core']:GetCoreObject()
local currentCrewFreq = nil

-- Auto-assign crew radio frequency
RegisterNetEvent('thegreatwar:joinedCrew', function(crewName)
    -- Generate frequency based on crew name
    local freq = tonumber(string.format("%.1f", 100.0 + (string.byte(crewName, 1) % 100)))
    currentCrewFreq = freq
    
    -- Connect to crew radio
    exports['qb-radio']:JoinRadio(freq)
    
    QBCore.Functions.Notify("🔊 Connected to crew radio: " .. freq .. " MHz", "success")
end)

RegisterNetEvent('thegreatwar:leftCrew', function()
    if currentCrewFreq then
        exports['qb-radio']:LeaveRadio()
        currentCrewFreq = nil
        QBCore.Functions.Notify("📻 Disconnected from crew radio", "info")
    end
end)