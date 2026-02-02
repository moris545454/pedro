local petEntity = nil
local followMode = false
local currentModel = Config.DefaultModel
local petName = 'Buddy'
local hunger = 100
local stamina = 100
local affection = 100
local xp = 0
local level = 1
local uiOpen = false

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function calculateLevel(currentXp)
    local currentLevel = 1
    for index, threshold in ipairs(Config.LevelThresholds) do
        if currentXp >= threshold then
            currentLevel = index
        end
    end
    return currentLevel
end

local function getNextLevelXp(currentLevel)
    local nextThreshold = Config.LevelThresholds[currentLevel + 1]
    if nextThreshold == nil then
        return Config.LevelThresholds[#Config.LevelThresholds]
    end
    return nextThreshold
end

local function getMood()
    if hunger <= Config.LowHungerThreshold or stamina <= Config.LowStaminaThreshold then
        return 'Tired'
    end
    if affection >= Config.MoodThresholds.happy then
        return 'Happy'
    end
    if affection >= Config.MoodThresholds.content then
        return 'Content'
    end
    return 'Grumpy'
end

local function notify(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
end

local function isAllowedModel(model)
    for _, allowed in ipairs(Config.AllowedModels) do
        if allowed == model then
            return true
        end
    end
    return false
end

local function loadModel(model)
    local modelHash = GetHashKey(model)
    if not IsModelInCdimage(modelHash) then
        return false
    end

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end

    return modelHash
end

local function spawnPet(model)
    if petEntity and DoesEntityExist(petEntity) then
        DeleteEntity(petEntity)
        petEntity = nil
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local modelHash = loadModel(model)

    if not modelHash then
        notify('Invalid pet model.')
        return
    end

    petEntity = CreatePed(28, modelHash, coords.x + 1.0, coords.y + 1.0, coords.z, 0.0, true, true)
    SetEntityAsMissionEntity(petEntity, true, true)
    SetBlockingOfNonTemporaryEvents(petEntity, true)
    SetPedFleeAttributes(petEntity, 0, false)
    SetPedCanRagdollFromPlayerImpact(petEntity, false)
    SetPedDiesWhenInjured(petEntity, false)
    SetPedKeepTask(petEntity, true)

    currentModel = model
    followMode = true
    hunger = 100
    stamina = 100
    affection = clamp(affection + 10, 0, 100)
    xp = xp + Config.XPPerAction
    level = calculateLevel(xp)
    notify('Pet spawned. Use /pet follow or /pet stay.')
    sendUiState()
end

local function followPlayer()
    if not (petEntity and DoesEntityExist(petEntity)) then
        notify('No pet to command.')
        return
    end

    followMode = true
    notify('Pet will follow you.')
end

local function stay()
    if not (petEntity and DoesEntityExist(petEntity)) then
        notify('No pet to command.')
        return
    end

    followMode = false
    ClearPedTasks(petEntity)
    TaskStartScenarioInPlace(petEntity, 'WORLD_DOG_SITTING', 0, true)
    notify('Pet will stay.')
end

local function dismissPet()
    if petEntity and DoesEntityExist(petEntity) then
        DeleteEntity(petEntity)
        petEntity = nil
        followMode = false
        notify('Pet dismissed.')
    else
        notify('No pet to dismiss.')
    end
end

local function rewardPet(amount)
    xp = xp + amount
    level = calculateLevel(xp)
    affection = clamp(affection + 2, 0, 100)
end

local function setUiVisible(visible)
    uiOpen = visible
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        action = visible and 'open' or 'close',
        models = Config.AllowedModels,
        currentModel = currentModel,
        name = petName,
        stats = {
            hunger = hunger,
            stamina = stamina,
            affection = affection
        },
        progress = {
            xp = xp,
            level = level,
            nextXp = getNextLevelXp(level)
        },
        mood = getMood()
    })
end

local function sendUiState()
    if not uiOpen then
        return
    end

    SendNUIMessage({
        action = 'state',
        name = petName,
        currentModel = currentModel,
        stats = {
            hunger = hunger,
            stamina = stamina,
            affection = affection
        },
        progress = {
            xp = xp,
            level = level,
            nextXp = getNextLevelXp(level)
        },
        mood = getMood()
    })
end

CreateThread(function()
    while true do
        if followMode and petEntity and DoesEntityExist(petEntity) then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local petCoords = GetEntityCoords(petEntity)
            local distance = #(playerCoords - petCoords)
            local speedMultiplier = 1.0

            if hunger <= Config.LowHungerThreshold then
                speedMultiplier = 0.6
            elseif stamina <= Config.LowStaminaThreshold then
                speedMultiplier = 0.7
            end

            if distance > Config.FollowDistance + 0.5 then
                TaskFollowToOffsetOfEntity(
                    petEntity,
                    playerPed,
                    0.0,
                    -Config.FollowDistance,
                    0.0,
                    Config.FollowSpeed * speedMultiplier,
                    -1,
                    1.0,
                    true
                )
            end
        end

        Wait(500)
    end
end)

CreateThread(function()
    while true do
        if petEntity and DoesEntityExist(petEntity) then
            hunger = clamp(hunger - Config.HungerDecay, 0, 100)
            if followMode then
                stamina = clamp(stamina - Config.StaminaDecay, 0, 100)
            else
                stamina = clamp(stamina + Config.StatRecovery, 0, 100)
            end

            if hunger == 0 and followMode then
                followMode = false
                ClearPedTasks(petEntity)
                TaskStartScenarioInPlace(petEntity, 'WORLD_DOG_SITTING', 0, true)
                notify('Your pet is too hungry to follow.')
            end

            if hunger <= Config.LowHungerThreshold or stamina <= Config.LowStaminaThreshold then
                affection = clamp(affection - 1, 0, 100)
            end

            sendUiState()
        end
        Wait(Config.StatDecayIntervalMs)
    end
end)

RegisterCommand(Config.CommandPrefix, function(_, args)
    local action = args[1]

    if action == 'spawn' then
        local model = args[2] or Config.DefaultModel
        if not isAllowedModel(model) then
            notify('Model not allowed.')
            return
        end
        spawnPet(model)
    elseif action == 'follow' then
        followPlayer()
    elseif action == 'stay' then
        stay()
    elseif action == 'dismiss' then
        dismissPet()
    elseif action == 'ui' then
        setUiVisible(true)
    elseif action == 'feed' then
        hunger = clamp(hunger + 25, 0, 100)
        affection = clamp(affection + 5, 0, 100)
        rewardPet(Config.XPPerAction)
        sendUiState()
        notify('You fed your pet.')
    elseif action == 'heal' then
        if petEntity and DoesEntityExist(petEntity) then
            SetEntityHealth(petEntity, GetEntityMaxHealth(petEntity))
            notify('Pet healed.')
        else
            notify('No pet to heal.')
        end
    elseif action == 'rename' then
        local name = table.concat(args, ' ', 2)
        if name == nil or name == '' then
            notify('Usage: /pet rename [name]')
            return
        end
        petName = name
        rewardPet(5)
        sendUiState()
        notify(('Pet renamed to %s.'):format(petName))
    elseif action == 'whistle' then
        if petEntity and DoesEntityExist(petEntity) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            SetEntityCoords(petEntity, playerCoords.x + 1.0, playerCoords.y + 1.0, playerCoords.z, false, false, false, false)
            notify('Pet recalled.')
        else
            notify('No pet to recall.')
        end
    elseif action == 'play' then
        stamina = clamp(stamina - 10, 0, 100)
        affection = clamp(affection + 8, 0, 100)
        rewardPet(10)
        notify('You played with your pet.')
        sendUiState()
    elseif action == 'trick' then
        local trick = args[2] or 'sit'
        local scenario = Config.TrickScenarios[trick]
        if scenario and petEntity and DoesEntityExist(petEntity) then
            ClearPedTasks(petEntity)
            TaskStartScenarioInPlace(petEntity, scenario, 0, true)
            rewardPet(8)
            sendUiState()
            notify(('Pet performs: %s'):format(trick))
        else
            notify('Unknown trick or no pet.')
        end
    elseif action == 'model' then
        notify(('Current model: %s'):format(currentModel))
    else
        notify('Usage: /pet spawn [model], /pet follow, /pet stay, /pet dismiss, /pet ui, /pet feed, /pet heal, /pet rename, /pet whistle, /pet play, /pet trick [sit|bark|beg]')
    end
end, false)

RegisterKeyMapping(Config.CommandPrefix .. ' ui', 'Open pet UI', 'keyboard', 'F6')

RegisterNUICallback('spawn', function(data, cb)
    local model = data.model or Config.DefaultModel
    if not isAllowedModel(model) then
        notify('Model not allowed.')
        cb({ ok = false })
        return
    end
    spawnPet(model)
    cb({ ok = true })
end)

RegisterNUICallback('follow', function(_, cb)
    followPlayer()
    cb({ ok = true })
end)

RegisterNUICallback('stay', function(_, cb)
    stay()
    cb({ ok = true })
end)

RegisterNUICallback('dismiss', function(_, cb)
    dismissPet()
    cb({ ok = true })
end)

RegisterNUICallback('feed', function(_, cb)
    hunger = clamp(hunger + 25, 0, 100)
    affection = clamp(affection + 5, 0, 100)
    rewardPet(Config.XPPerAction)
    sendUiState()
    cb({ ok = true })
end)

RegisterNUICallback('heal', function(_, cb)
    if petEntity and DoesEntityExist(petEntity) then
        SetEntityHealth(petEntity, GetEntityMaxHealth(petEntity))
    end
    cb({ ok = true })
end)

RegisterNUICallback('rename', function(data, cb)
    local name = data.name or ''
    if name ~= '' then
        petName = name
        rewardPet(5)
        sendUiState()
    end
    cb({ ok = true })
end)

RegisterNUICallback('whistle', function(_, cb)
    if petEntity and DoesEntityExist(petEntity) then
        local playerCoords = GetEntityCoords(PlayerPedId())
        SetEntityCoords(petEntity, playerCoords.x + 1.0, playerCoords.y + 1.0, playerCoords.z, false, false, false, false)
    end
    cb({ ok = true })
end)

RegisterNUICallback('play', function(_, cb)
    stamina = clamp(stamina - 10, 0, 100)
    affection = clamp(affection + 8, 0, 100)
    rewardPet(10)
    sendUiState()
    cb({ ok = true })
end)

RegisterNUICallback('trick', function(data, cb)
    local trick = data.trick or 'sit'
    local scenario = Config.TrickScenarios[trick]
    if scenario and petEntity and DoesEntityExist(petEntity) then
        ClearPedTasks(petEntity)
        TaskStartScenarioInPlace(petEntity, scenario, 0, true)
        rewardPet(8)
        sendUiState()
    end
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    setUiVisible(false)
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if uiOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
        end
        Wait(0)
    end
end)
