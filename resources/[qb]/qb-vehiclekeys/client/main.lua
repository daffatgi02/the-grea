-----------------------
----   Variables   ----
-----------------------
local QBCore = exports['qb-core']:GetCoreObject()
local KeysList = {}
local isTakingKeys = false
local isCarjacking = false
local canCarjack = true
local AlertSend = false
local lastPickedVehicle = nil
local IsHotwiring = false
local trunkclose = true
local looped = false

local function robKeyLoop()
    if looped then return end

    looped = true
    while true do
        local sleep = 1000
        if LocalPlayer.state.isLoggedIn then
            sleep = 100

            local ped = PlayerPedId()
            local entering = GetVehiclePedIsTryingToEnter(ped)
            local carIsImmune = false
            if entering ~= 0 and not isBlacklistedVehicle(entering) then
                sleep = 2000
                local plate = QBCore.Functions.GetPlate(entering)

                local driver = GetPedInVehicleSeat(entering, -1)
                for _, veh in ipairs(Config.ImmuneVehicles) do
                    if GetEntityModel(entering) == joaat(veh) then
                        carIsImmune = true
                    end
                end
                -- Driven vehicle logic
                if driver ~= 0 and not IsPedAPlayer(driver) and not HasKeys(plate) and not carIsImmune then
                    if IsEntityDead(driver) then
                        if not isTakingKeys then
                            isTakingKeys = true

                            TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 1)
                            QBCore.Functions.Progressbar('steal_keys', Lang:t('progress.takekeys'), 2500, false, false, {
                                disableMovement = false,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true
                            }, {}, {}, {}, function() -- Done
                                TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
                                isTakingKeys = false
                            end, function()
                                isTakingKeys = false
                            end)
                        end
                    elseif Config.LockNPCDrivingCars then
                        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 2)
                    else
                        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 1)
                        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)

                        --Make passengers flee
                        local pedsInVehicle = GetPedsInVehicle(entering)
                        for _, pedInVehicle in pairs(pedsInVehicle) do
                            if pedInVehicle ~= GetPedInVehicleSeat(entering, -1) then
                                MakePedFlee(pedInVehicle)
                            end
                        end
                    end
                    -- Parked car logic
                elseif driver == 0 and entering ~= lastPickedVehicle and not HasKeys(plate) and not isTakingKeys then
                    QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:checkPlayerOwned', function(playerOwned)
                        if not playerOwned then
                            if Config.LockNPCParkedCars then
                                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 2)
                            else
                                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 1)
                            end
                        end
                    end, plate)
                end
            end

            -- Hotwiring while in vehicle, also keeps engine off for vehicles you don't own keys to
            if IsPedInAnyVehicle(ped, false) and not IsHotwiring then
                sleep = 1000
                local vehicle = GetVehiclePedIsIn(ped)
                local plate = QBCore.Functions.GetPlate(vehicle)

                if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() and not HasKeys(plate) and not isBlacklistedVehicle(vehicle) and not AreKeysJobShared(vehicle) then
                    sleep = 0

                    local vehiclePos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 1.0, 0.5)
                    DrawText3D(vehiclePos.x, vehiclePos.y, vehiclePos.z, Lang:t('info.skeys'))
                    SetVehicleEngineOn(vehicle, false, false, true)

                    if IsControlJustPressed(0, 74) then
                        Hotwire(vehicle, plate)
                    end
                end
            end

            if Config.CarJackEnable and canCarjack then
                local playerid = PlayerId()
                local aiming, target = GetEntityPlayerIsFreeAimingAt(playerid)
                if aiming and (target ~= nil and target ~= 0) then
                    if DoesEntityExist(target) and IsPedInAnyVehicle(target, false) and not IsEntityDead(target) and not IsPedAPlayer(target) then
                        local targetveh = GetVehiclePedIsIn(target)
                        for _, veh in ipairs(Config.ImmuneVehicles) do
                            if GetEntityModel(targetveh) == joaat(veh) then
                                carIsImmune = true
                            end
                        end
                        if GetPedInVehicleSeat(targetveh, -1) == target and not IsBlacklistedWeapon() then
                            local pos = GetEntityCoords(ped, true)
                            local targetpos = GetEntityCoords(target, true)
                            if #(pos - targetpos) < 5.0 and not carIsImmune then
                                CarjackVehicle(target)
                            end
                        end
                    end
                end
            end
            if entering == 0 and not IsPedInAnyVehicle(ped, false) and GetSelectedPedWeapon(ped) == `WEAPON_UNARMED` then
                looped = false
                break
            end
        end
        Wait(sleep)
    end
end

function isBlacklistedVehicle(vehicle)
    local isBlacklisted = false
    for _, v in ipairs(Config.NoLockVehicles) do
        if joaat(v) == GetEntityModel(vehicle) then
            isBlacklisted = true
            break;
        end
    end
    if Entity(vehicle).state.ignoreLocks or GetVehicleClass(vehicle) == 13 then isBlacklisted = true end
    return isBlacklisted
end

function addNoLockVehicles(model)
    Config.NoLockVehicles[#Config.NoLockVehicles + 1] = model
end

exports('addNoLockVehicles', addNoLockVehicles)

function removeNoLockVehicles(model)
    for k, v in pairs(Config.NoLockVehicles) do
        if v == model then
            Config.NoLockVehicles[k] = nil
        end
    end
end

exports('removeNoLockVehicles', removeNoLockVehicles)



-----------------------
---- Client Events ----
-----------------------
RegisterKeyMapping('togglelocks', Lang:t('info.tlock'), 'keyboard', 'L')
RegisterCommand('togglelocks', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        ToggleVehicleLocksWithoutNui(GetVehicle())
    elseif Config.UseKeyfob then
        OpenMenu()
    else
        ToggleVehicleLocksWithoutNui(GetVehicle())
    end
end)

RegisterKeyMapping('engine', Lang:t('info.engine'), 'keyboard', 'G')
RegisterCommand('engine', function()
    local vehicle = GetVehicle()
    if not vehicle then return end
    if not IsPedInVehicle(PlayerPedId(), vehicle) then return end

    ToggleEngine(vehicle)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() and QBCore.Functions.GetPlayerData() ~= {} then
        GetKeys()
    end
end)

-- Handles state right when the player selects their character and location.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    GetKeys()
end)

-- Resets state on logout, in case of character change.
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    KeysList = {}
end)

RegisterNetEvent('qb-vehiclekeys:client:AddKeys', function(plate)
    KeysList[plate] = true
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local vehicle = GetVehiclePedIsIn(ped)
    local vehicleplate = QBCore.Functions.GetPlate(vehicle)
    if plate ~= vehicleplate then return end

    SetVehicleEngineOn(vehicle, false, false, false)
end)

RegisterNetEvent('qb-vehiclekeys:client:RemoveKeys', function(plate)
    KeysList[plate] = nil
end)

RegisterNetEvent('qb-vehiclekeys:client:ToggleEngine', function()
    local EngineOn = GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId()))
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if HasKeys(QBCore.Functions.GetPlate(vehicle)) then
        SetVehicleEngineOn(vehicle, not EngineOn, false, true)
    end
end)

RegisterNetEvent('qb-vehiclekeys:client:GiveKeys', function(id)
    local targetVehicle = GetVehicle()
    if not targetVehicle then return end

    local targetPlate = QBCore.Functions.GetPlate(targetVehicle)
    if not HasKeys(targetPlate) then
        QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
        return
    end

    if id and type(id) == 'number' then -- Give keys to specific ID
        GiveKeys(id, targetPlate)
    elseif IsPedSittingInVehicle(PlayerPedId(), targetVehicle) then -- Give keys to everyone in vehicle
        local otherOccupants = GetOtherPlayersInVehicle(targetVehicle)
        for p = 1, #otherOccupants do
            TriggerServerEvent('qb-vehiclekeys:server:GiveVehicleKeys', GetPlayerServerId(NetworkGetPlayerIndexFromPed(otherOccupants[p])), targetPlate)
        end
    else -- Give keys to closest player
        GiveKeys(GetPlayerServerId(QBCore.Functions.GetClosestPlayer()), targetPlate)
    end
end)

RegisterNetEvent('QBCore:Client:VehicleInfo', function(data)
    if data.event == 'Entering' then
        robKeyLoop()
    end
end)

RegisterNetEvent('qb-weapons:client:DrawWeapon', function()
    Wait(2000)
    robKeyLoop()
end)

RegisterNetEvent('lockpicks:UseLockpick', function(isAdvanced)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local vehicle = QBCore.Functions.GetClosestVehicle()

    if vehicle == nil or vehicle == 0 then return end
    if HasKeys(QBCore.Functions.GetPlate(vehicle)) then return end
    if #(pos - GetEntityCoords(vehicle)) > 2.5 then return end
    if GetVehicleDoorLockStatus(vehicle) <= 0 then return end

    local difficulty = isAdvanced and 'easy' or 'medium' -- Easy for advanced lockpick, medium by default
    local success = exports['qb-minigames']:Skillbar(difficulty)

    local chance = math.random()
    TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
    if success then
        lastPickedVehicle = vehicle

        if GetPedInVehicleSeat(vehicle, -1) == ped then
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', QBCore.Functions.GetPlate(vehicle))
        else
            QBCore.Functions.Notify(Lang:t('notify.vlockpick'), 'success')
            TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(vehicle), 1)
        end
    else
        AttemptPoliceAlert('steal')
    end

    local threshold = isAdvanced and Config.RemoveLockpickAdvanced or Config.RemoveLockpickNormal
    local pickType = isAdvanced and 'advancedlockpick' or 'lockpick'

    if chance <= threshold then
        TriggerServerEvent('qb-vehiclekeys:server:breakLockpick', pickType)
    end
end)
-- Backwards Compatibility ONLY -- Remove at some point --
RegisterNetEvent('vehiclekeys:client:SetOwner', function(plate)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
end)
-- Backwards Compatibility ONLY -- Remove at some point --

-----------------------
----   Functions   ----
-----------------------
function OpenMenu()
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'key', 0.3)
    SendNUIMessage({ casemenue = 'open' })
    SetNuiFocus(true, true)
end

function ToggleEngine(veh)
    if not veh then return end

    if isBlacklistedVehicle(veh) then return end

    if not HasKeys(QBCore.Functions.GetPlate(veh)) and not AreKeysJobShared(veh) then return end

    local EngineOn = GetIsVehicleEngineRunning(veh)
    if EngineOn then
        SetVehicleEngineOn(veh, false, false, true)
    else
        SetVehicleEngineOn(veh, true, true, true)
    end
end

function ToggleVehicleLocksWithoutNui(veh)
    if not veh then return end

    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    if not HasKeys(QBCore.Functions.GetPlate(veh)) and not AreKeysJobShared(veh) then
        QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
        return
    end

    local ped = PlayerPedId()
    local vehLockStatus, curVeh = GetVehicleDoorLockStatus(veh), GetVehiclePedIsIn(ped, false)
    local object = 0

    if curVeh == 0 then
        if Config.LockToggleAnimation.Prop then
            object = CreateObject(joaat(Config.LockToggleAnimation.Prop), 0, 0, 0, true, true, true)
            while not DoesEntityExist(object) do Wait(1) end
            AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, Config.LockToggleAnimation.PropBone),
                0.1, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        end

        loadAnimDict(Config.LockToggleAnimation.AnimDict)
        TaskPlayAnim(ped, Config.LockToggleAnimation.AnimDict, Config.LockToggleAnimation.Anim, 8.0, -8.0, -1, 52, 0, false, false, false)
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5.0, Config.LockAnimSound, 0.5)
    end

    Citizen.CreateThread(function()
        if curVeh == 0 then Wait(Config.LockToggleAnimation.WaitTime) end
        if IsEntityPlayingAnim(ped, Config.LockToggleAnimation.AnimDict, Config.LockToggleAnimation.Anim, 3) then
            StopAnimTask(ped, Config.LockToggleAnimation.AnimDict, Config.LockToggleAnimation.Anim, 8.0)
        end
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, Config.LockToggleSound, 0.3)

        if object ~= 0 and DoesEntityExist(object) then
            DeleteObject(object)
            object = 0
        end
    end)

    NetworkRequestControlOfEntity(veh)
    if vehLockStatus == 1 then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 2)
        QBCore.Functions.Notify(Lang:t('notify.vlock'), 'primary')
    else
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        QBCore.Functions.Notify(Lang:t('notify.vunlock'), 'success')
    end

    SetVehicleLights(veh, 2)
    Wait(250)
    SetVehicleLights(veh, 1)
    Wait(200)
    SetVehicleLights(veh, 0)
    Wait(300)
    ClearPedTasks(ped)
end

function GiveKeys(id, plate)
    local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(id))))
    if distance <= 0.0 or distance >= 1.5 then
        QBCore.Functions.Notify(Lang:t('notify.nonear'), 'error')
        return
    end

    TriggerServerEvent('qb-vehiclekeys:server:GiveVehicleKeys', id, plate)
end

function GetKeys()
    QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:GetVehicleKeys', function(keysList)
        KeysList = keysList
    end)
end

function HasKeys(plate)
    return KeysList[plate]
end

exports('HasKeys', HasKeys)

function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(0)
    end
end

-- If in vehicle returns that, otherwise tries 3 different raycasts to get the vehicle they are facing.
-- Raycasts picture: https://i.imgur.com/FRED0kV.png

function GetVehicle()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    while vehicle == 0 do
        vehicle = QBCore.Functions.GetClosestVehicle()
        if #(pos - GetEntityCoords(vehicle)) > Config.LockToggleDist then
            -- TODO: Assess adding vehicle or nil here.
            return
        end
    end
    if not IsEntityAVehicle(vehicle) then vehicle = nil end
    return vehicle
end

function AreKeysJobShared(veh)
    local vehName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    local vehPlate = QBCore.Functions.GetPlate(veh)
    local jobName = QBCore.Functions.GetPlayerData().job.name
    local onDuty = QBCore.Functions.GetPlayerData().job.onduty
    for job, v in pairs(Config.SharedKeys) do
        if job == jobName then
            if Config.SharedKeys[job].requireOnduty and not onDuty then return false end
            for _, vehicle in pairs(v.vehicles) do
                if string.upper(vehicle) == string.upper(vehName) then
                    if not HasKeys(vehPlate) then
                        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', vehPlate)
                    end
                    return true
                end
            end
        end
    end
    return false
end

function ToggleVehicleLocks(veh)
    if not veh then return end

    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    if not HasKeys(QBCore.Functions.GetPlate(veh)) and not AreKeysJobShared(veh) then
        QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
        return
    end

    local ped = PlayerPedId()
    local vehLockStatus = GetVehicleDoorLockStatus(veh)
    loadAnimDict('anim@mp_player_intmenu@key_fob@')
    TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'lock', 0.3)
    NetworkRequestControlOfEntity(veh)
    while NetworkGetEntityOwner(veh) ~= 128 do
        NetworkRequestControlOfEntity(veh)
        Wait(0)
    end
    if vehLockStatus == 1 then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 2)
        QBCore.Functions.Notify(Lang:t('notify.vlock'), 'primary')
    end
    SetVehicleLights(veh, 2)
    Wait(250)
    SetVehicleLights(veh, 1)
    Wait(200)
    SetVehicleLights(veh, 0)
    Wait(300)
    ClearPedTasks(ped)
end

function ToggleVehicleunLocks(veh)
    if not veh then return end

    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    if not HasKeys(QBCore.Functions.GetPlate(veh)) and not AreKeysJobShared(veh) then
        QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
        return
    end

    local ped = PlayerPedId()
    local vehLockStatus = GetVehicleDoorLockStatus(veh)
    loadAnimDict('anim@mp_player_intmenu@key_fob@')
    TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'lock', 0.3)
    NetworkRequestControlOfEntity(veh)
    if vehLockStatus == 2 then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        QBCore.Functions.Notify(Lang:t('notify.vunlock'), 'success')
    end
    SetVehicleLights(veh, 2)
    Wait(250)
    SetVehicleLights(veh, 1)
    Wait(200)
    SetVehicleLights(veh, 0)
    Wait(300)
    ClearPedTasks(ped)
end

function ToggleVehicleTrunk(veh)
    if not veh then return end

    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    if not HasKeys(QBCore.Functions.GetPlate(veh)) and not AreKeysJobShared(veh) then
        QBCore.Functions.Notify(Lang:t('notify.ydhk'), 'error')
        return
    end

    local ped = PlayerPedId()
    local boot = GetEntityBoneIndexByName(GetVehiclePedIsIn(PlayerPedId(), false), 'boot')
    loadAnimDict('anim@mp_player_intmenu@key_fob@')
    TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'lock', 0.3)
    NetworkRequestControlOfEntity(veh)

   if boot == -1 and not DoesEntityExist(veh) then return end

    SetVehicleLights(veh, 2)
    Wait(150)
    SetVehicleLights(veh, 0)
    Wait(150)
    SetVehicleLights(veh, 2)
    Wait(150)
    SetVehicleLights(veh, 0)
    Wait(150)
    if trunkclose then
        SetVehicleDoorOpen(veh, 5)
    else
        SetVehicleDoorShut(veh, 5)
    end
    trunkclose = not trunkclose
    ClearPedTasks(ped)
end

function GetOtherPlayersInVehicle(vehicle)
    local otherPeds = {}
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
        if IsPedAPlayer(pedInSeat) and pedInSeat ~= PlayerPedId() then
            otherPeds[#otherPeds + 1] = pedInSeat
        end
    end
    return otherPeds
end

function GetPedsInVehicle(vehicle)
    local otherPeds = {}
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
        if not IsPedAPlayer(pedInSeat) and pedInSeat ~= 0 then
            otherPeds[#otherPeds + 1] = pedInSeat
        end
    end
    return otherPeds
end

function IsBlacklistedWeapon()
    local weapon = GetSelectedPedWeapon(PlayerPedId())
    if weapon == nil then return false end

    for _, v in pairs(Config.NoCarjackWeapons) do
        if weapon == joaat(v) then
            return true
        end
    end
    return false
end

function Hotwire(vehicle, plate)
    local hotwireTime = math.random(Config.minHotwireTime, Config.maxHotwireTime)
    local ped = PlayerPedId()
    IsHotwiring = true

    SetVehicleAlarm(vehicle, true)
    SetVehicleAlarmTimeLeft(vehicle, hotwireTime)
    QBCore.Functions.Progressbar('hotwire_vehicle', Lang:t('progress.hskeys'), hotwireTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        anim = 'machinic_loop_mechandplayer',
        flags = 16
    }, {}, {}, function() -- Done
        StopAnimTask(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 1.0)
        TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
        if (math.random() <= Config.HotwireChance) then
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        else
            QBCore.Functions.Notify(Lang:t('notify.fvlockpick'), 'error')
        end
        Wait(Config.TimeBetweenHotwires)
        IsHotwiring = false
    end, function() -- Cancel
        StopAnimTask(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 1.0)
        IsHotwiring = false
    end)
    SetTimeout(10000, function()
        AttemptPoliceAlert('steal')
    end)
    IsHotwiring = false
end

function CarjackVehicle(target)
    if not Config.CarJackEnable then return end
    
    isCarjacking = true
    canCarjack = false
    loadAnimDict('mp_am_hold_up')
    local vehicle = GetVehiclePedIsUsing(target)
    local occupants = GetPedsInVehicle(vehicle)
    for p = 1, #occupants do
        local ped = occupants[p]
        CreateThread(function()
            TaskPlayAnim(ped, 'mp_am_hold_up', 'holdup_victim_20s', 8.0, -8.0, -1, 49, 0, false, false, false)
            PlayPain(ped, 6, 0)
            FreezeEntityPosition(vehicle, true)
            SetVehicleUndriveable(vehicle, true)
        end)
        Wait(math.random(200, 500))
    end
    -- Cancel progress bar if: Ped dies during robbery, car gets too far away
    CreateThread(function()
        while isCarjacking do
            local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(target))
            if IsPedDeadOrDying(target) or distance > 7.5 then
                TriggerEvent('progressbar:client:cancel')
                FreezeEntityPosition(vehicle, false)
                SetVehicleUndriveable(vehicle, false)
            end
            Wait(100)
        end
    end)
    QBCore.Functions.Progressbar('rob_keys', Lang:t('progress.acjack'), Config.CarjackingTime, false, true, {}, {}, {}, {}, function()
        local hasWeapon, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
        if not hasWeapon or not isCarjacking then return end

        local carjackChance
        if Config.CarjackChance[tostring(GetWeapontypeGroup(weaponHash))] then
            carjackChance = Config.CarjackChance[tostring(GetWeapontypeGroup(weaponHash))]
        else
            carjackChance = 0.5
        end
            
        if math.random() <= carjackChance then
            local plate = QBCore.Functions.GetPlate(vehicle)
            for p = 1, #occupants do
                local ped = occupants[p]
                CreateThread(function()
                    FreezeEntityPosition(vehicle, false)
                    SetVehicleUndriveable(vehicle, false)
                    TaskLeaveVehicle(ped, vehicle, 0)
                    PlayPain(ped, 6, 0)
                    Wait(1250)
                    ClearPedTasksImmediately(ped)
                    PlayPain(ped, math.random(7, 8), 0)
                    MakePedFlee(ped)
                end)
            end
            TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        else
            QBCore.Functions.Notify(Lang:t('notify.cjackfail'), 'error')
            FreezeEntityPosition(vehicle, false)
            SetVehicleUndriveable(vehicle, false)
            MakePedFlee(target)
            TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
        end
        isCarjacking = false
        Wait(2000)
        AttemptPoliceAlert('carjack')
        Wait(Config.DelayBetweenCarjackings)
        canCarjack = true
    end, function()
        MakePedFlee(target)
        isCarjacking = false
        Wait(Config.DelayBetweenCarjackings)
        canCarjack = true
    end)
end

function AttemptPoliceAlert(type)
    if AlertSend then return end

    local chance = Config.PoliceAlertChance
    if GetClockHours() >= 1 and GetClockHours() <= 6 then
        chance = Config.PoliceNightAlertChance
    end
    if math.random() <= chance then
        TriggerServerEvent('police:server:policeAlert', Lang:t('info.palert') .. type)
    end
    AlertSend = true
    SetTimeout(Config.AlertCooldown, function()
        AlertSend = false
    end)
end

function MakePedFlee(ped)
    SetPedFleeAttributes(ped, 0, 0)
    TaskReactAndFleePed(ped, PlayerPedId())
end

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    if GetConvar('qb_locale', 'en') == 'en' then
        SetTextFont(4)
    else
        SetTextFont(1)
    end
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-----------------------
----   NUICallback   ----
-----------------------
RegisterNUICallback('closui', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('unlock', function()
    ToggleVehicleunLocks(GetVehicle())
    SetNuiFocus(false, false)
end)

RegisterNUICallback('lock', function()
    ToggleVehicleLocks(GetVehicle())
    SetNuiFocus(false, false)
end)

RegisterNUICallback('trunk', function()
    ToggleVehicleTrunk(GetVehicle())
    SetNuiFocus(false, false)
end)

RegisterNUICallback('engine', function()
    ToggleEngine(GetVehicle())
    SetNuiFocus(false, false)
end)
