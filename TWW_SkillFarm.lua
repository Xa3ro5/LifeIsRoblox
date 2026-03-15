local env = (getgenv and getgenv()) or _G
env.TWW = env.TWW or {}
local TWW = env.TWW

if TWW._skillFarmLoaded then
    return
end
TWW._skillFarmLoaded = true

local Services = TWW.Services
if not Services then
    Services = {
        ["Players"] = game:GetService("Players"),
        ["Workspace"] = game:GetService("Workspace"),
        ["RunService"] = game:GetService("RunService"),
        ["CoreGui"] = game:GetService("CoreGui"),
        ["GuiService"] = game:GetService("GuiService"),
        ["PathfindingService"] = game:GetService("PathfindingService"),
        ["Lighting"] = game:GetService("Lighting"),
        ["ReplicatedStorage"] = game:GetService("ReplicatedStorage"),
        ["SoundService"] = game:GetService("SoundService"),
        ["UserInputService"] = game:GetService("UserInputService"),
        ["CollectionService"] = game:GetService("CollectionService"),
        ["VirtualInputManager"] = nil,
    }
    TWW.Services = Services
end

pcall(function()
    if Services.VirtualInputManager == nil then
        Services.VirtualInputManager = game:GetService("VirtualInputManager")
    end
end)

local LocalPlayer = TWW.LocalPlayer or Services.Players.LocalPlayer
TWW.LocalPlayer = LocalPlayer

local SkillFarm = TWW.SkillFarm or {}
TWW.SkillFarm = SkillFarm

SkillFarm.skills = SkillFarm.skills or {}
SkillFarm.skillInfo = SkillFarm.skillInfo or {}
SkillFarm.skillOrder = SkillFarm.skillOrder or {}
SkillFarm.handlers = SkillFarm.handlers or {}

local GlobalCache = nil

local function getGlobal()
    if GlobalCache then
        return GlobalCache
    end
    local ok, mod = pcall(function()
        return require(Services.ReplicatedStorage.SharedModules.Global)
    end)
    if ok then
        GlobalCache = mod
        return GlobalCache
    end
    return nil
end

local function notify(msg)
    local win = TWW.Window
    if win and win.Notify then
        win:Notify(tostring(msg), 2)
        return
    end
    print("[SkillFarm] " .. tostring(msg))
end

local function getEsp()
    return TWW.Esp or {}
end

local function getLocalPlayerModel()
    local esp = getEsp()
    if esp.getLocalPlayerModel then
        return esp.getLocalPlayerModel()
    end
    local entities = Services.Workspace:FindFirstChild("WORKSPACE_Entities")
    local playersFolder = entities and entities:FindFirstChild("Players") or nil
    return playersFolder and playersFolder:FindFirstChild(LocalPlayer.Name) or nil
end

local function getLocalHumanoid()
    local esp = getEsp()
    if esp.getLocalHumanoid then
        return esp.getLocalHumanoid()
    end
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return humanoid
        end
    end
    local model = getLocalPlayerModel()
    if model then
        return model:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function getLocalRootPart()
    local esp = getEsp()
    if esp.getLocalRootPart then
        return esp.getLocalRootPart()
    end
    local humanoid = getLocalHumanoid()
    local model = humanoid and humanoid.Parent or nil
    if model then
        local root = model:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            return root
        end
    end
    local character = LocalPlayer.Character
    if character then
        local charRoot = character:FindFirstChild("HumanoidRootPart")
        if charRoot and charRoot:IsA("BasePart") then
            return charRoot
        end
    end
    local fallback = getLocalPlayerModel()
    local root = fallback and fallback:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function getModelPart(model)
    if not model then
        return nil
    end
    if model:IsA("BasePart") then
        return model
    end
    if not model:IsA("Model") then
        return nil
    end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    return nil
end

local function moveToPosition(targetPos, stopDistance, timeout)
    local humanoid = getLocalHumanoid()
    local root = getLocalRootPart()
    if not humanoid or not root or not targetPos then
        return false
    end
    stopDistance = stopDistance or 6
    timeout = timeout or 6
    local start = os.clock()
    humanoid:MoveTo(targetPos)
    while os.clock() - start < timeout do
        root = getLocalRootPart()
        if not root then
            return false
        end
        if (root.Position - targetPos).Magnitude <= stopDistance then
            return true
        end
        task.wait(0.1)
    end
    return false
end

local function faceTarget(part)
    if not part then
        return
    end
    local root = getLocalRootPart()
    if not root then
        return
    end
    local pos = root.Position
    root.CFrame = CFrame.new(pos, Vector3.new(part.Position.X, pos.Y, part.Position.Z))
end

local function getMousePosition()
    local pos = Services.UserInputService:GetMouseLocation()
    local inset = Services.GuiService:GetGuiInset()
    return Vector2.new(pos.X - inset.X, pos.Y - inset.Y)
end

local mouseDown = false

local function setMouseDown(state)
    if mouseDown == state then
        return
    end
    mouseDown = state
    if type(mouse1press) == "function" and type(mouse1release) == "function" then
        if state then
            pcall(mouse1press)
        else
            pcall(mouse1release)
        end
        return
    end
    if Services.VirtualInputManager then
        local pos = getMousePosition()
        if pos then
            pcall(function()
                Services.VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, state, game, 0)
            end)
        end
    end
end

local function clickMouse()
    if type(mouse1click) == "function" then
        pcall(mouse1click)
        return
    end
    setMouseDown(true)
    task.wait(0.05)
    setMouseDown(false)
end

local function pressKey(keyCode, duration)
    if not Services.VirtualInputManager then
        return
    end
    local hold = duration or 0.05
    pcall(function()
        Services.VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    end)
    task.wait(hold)
    pcall(function()
        Services.VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

local function getEquippedTool()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChildOfClass("Tool")
    end
    return nil
end

local function equipTool(predicate)
    local equipped = getEquippedTool()
    if equipped and predicate(equipped) then
        return equipped
    end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        return equipped
    end
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and predicate(item) then
            local humanoid = getLocalHumanoid()
            if humanoid then
                humanoid:EquipTool(item)
                return item
            end
        end
    end
    return equipped
end

local function getEntitiesFolder()
    return Services.Workspace:FindFirstChild("WORKSPACE_Entities")
end

local function getAnimalsFolder()
    local entities = getEntitiesFolder()
    return entities and entities:FindFirstChild("Animals") or nil
end

local function getDeadAnimalsFolder()
    local entities = getEntitiesFolder()
    return entities and entities:FindFirstChild("DeadAnimals") or nil
end

local function getNpcFolder()
    local entities = getEntitiesFolder()
    return entities and entities:FindFirstChild("NPCs") or nil
end

local function findDescendantPart(model, name)
    if not model then
        return nil
    end
    local part = model:FindFirstChild(name, true)
    if part and part:IsA("BasePart") then
        return part
    end
    return nil
end

local function findHumanoid(model)
    if not model then
        return nil
    end
    return model:FindFirstChildOfClass("Humanoid", true)
end

local function resolveNpcModel(container)
    if not container then
        return nil
    end
    if container:IsA("Model") then
        local hum = findHumanoid(container)
        if hum then
            return container
        end
    end
    local direct = container:FindFirstChild("Model")
    if direct and direct:IsA("Model") then
        return direct
    end
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Model") then
            local hum = findHumanoid(child)
            if hum then
                return child
            end
        end
    end
    return nil
end

local function getAnimalPart(model)
    if not model then
        return nil
    end
    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return getModelPart(model)
end

local function getAnimalHealth(model)
    if not model then
        return nil
    end
    local value = model:FindFirstChild("Health")
    if value and value:IsA("ValueBase") then
        return tonumber(value.Value)
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.Health
    end
    return nil
end

local function isAnimalDead(model)
    if not model or not model.Parent then
        return true
    end
    local health = getAnimalHealth(model)
    if health and health <= 0 then
        return true
    end
    local deadFolder = getDeadAnimalsFolder()
    if deadFolder and model.Parent == deadFolder then
        return true
    end
    return false
end

local function getTreeHealthValue(tree)
    if not tree then
        return nil
    end
    local info = tree:FindFirstChild("TreeInfo") or tree:FindFirstChild("TreeInfo", true)
    if not info then
        return nil
    end
    local health = info:FindFirstChild("Health")
    if health and health:IsA("ValueBase") then
        return health
    end
    return nil
end

local function isTreeAlive(tree)
    if not tree or not tree.Parent then
        return false
    end
    local health = getTreeHealthValue(tree)
    if health then
        return tonumber(health.Value) > 0
    end
    return true
end

local function collectTaggedModels(tagNames)
    local found = {}
    local results = {}
    for _, tagName in ipairs(tagNames) do
        local tagged = Services.CollectionService:GetTagged(tagName)
        for _, inst in ipairs(tagged) do
            local model = inst:IsA("Model") and inst or inst:FindFirstAncestorOfClass("Model")
            if model and not found[model] then
                found[model] = true
                table.insert(results, model)
            end
        end
    end
    return results
end

local function findNearestModel(models, maxDistance, partResolver, extraFilter)
    local root = getLocalRootPart()
    if not root then
        return nil, nil
    end
    local best = nil
    local bestDist = nil
    for _, model in ipairs(models) do
        if model and model.Parent then
            if not extraFilter or extraFilter(model) then
                local part = partResolver(model)
                if part then
                    local dist = (root.Position - part.Position).Magnitude
                    if not maxDistance or dist <= maxDistance then
                        if not bestDist or dist < bestDist then
                            bestDist = dist
                            best = model
                        end
                    end
                end
            end
        end
    end
    return best, bestDist
end

local function findNearestTree(maxDistance)
    local trees = collectTaggedModels({ "CuttableTree", "Tree" })
    if #trees == 0 then
        return nil, nil
    end
    return findNearestModel(trees, maxDistance, getModelPart, isTreeAlive)
end

local function findNearestAnimal(maxDistance)
    local animalsFolder = getAnimalsFolder()
    if not animalsFolder then
        return nil, nil
    end
    local models = {}
    for _, model in ipairs(animalsFolder:GetChildren()) do
        if model:IsA("Model") then
            table.insert(models, model)
        end
    end
    return findNearestModel(models, maxDistance, getAnimalPart, function(model)
        return not isAnimalDead(model)
    end)
end

local function findNearestNpc(maxDistance)
    local npcFolder = getNpcFolder()
    if not npcFolder then
        return nil, nil
    end
    local models = {}
    for _, container in ipairs(npcFolder:GetChildren()) do
        local model = resolveNpcModel(container)
        if model then
            table.insert(models, model)
        end
    end
    return findNearestModel(models, maxDistance, getModelPart, function(model)
        local hum = findHumanoid(model)
        return hum and hum.Health > 0
    end)
end

local function findNearestPlayerNeedingHeal(maxDistance)
    local root = getLocalRootPart()
    if not root then
        return nil, nil
    end
    local best = nil
    local bestDist = nil
    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local character = plr.Character
            if character then
                local hum = character:FindFirstChildOfClass("Humanoid")
                local r = character:FindFirstChild("HumanoidRootPart")
                if hum and r and hum.Health < hum.MaxHealth and hum.Health > 0 then
                    local dist = (root.Position - r.Position).Magnitude
                    if not maxDistance or dist <= maxDistance then
                        if not bestDist or dist < bestDist then
                            bestDist = dist
                            best = plr
                        end
                    end
                end
            end
        end
    end
    return best, bestDist
end

local function findPromptOnModel(model)
    if not model then
        return nil
    end
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("ProximityPrompt") then
            return child
        end
    end
    return nil
end

local function findClickDetectorOnModel(model)
    if not model then
        return nil
    end
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("ClickDetector") then
            return child
        end
    end
    return nil
end

local function triggerPrompt(prompt)
    if not prompt then
        return false
    end
    if type(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
        return true
    end
    if prompt.KeyboardKeyCode then
        pressKey(prompt.KeyboardKeyCode)
        return true
    end
    return false
end

local function triggerClickDetector(detector)
    if not detector then
        return false
    end
    if type(fireclickdetector) == "function" then
        pcall(fireclickdetector, detector)
        return true
    end
    return false
end

local function tryInteract(model)
    if not model then
        return false
    end
    local prompt = findPromptOnModel(model)
    if prompt and triggerPrompt(prompt) then
        return true
    end
    local detector = findClickDetectorOnModel(model)
    if detector and triggerClickDetector(detector) then
        return true
    end
    clickMouse()
    return true
end

local function ensureAxeEquipped()
    return equipTool(function(tool)
        return tostring(tool.Name):lower():find("axe", 1, true) ~= nil
    end)
end

local function ensureFishingPoleEquipped()
    return equipTool(function(tool)
        return tostring(tool.Name):lower():find("fishing", 1, true) ~= nil
    end)
end

local function ensurePanEquipped()
    return equipTool(function(tool)
        local name = tostring(tool.Name):lower()
        return name:find("pan", 1, true) ~= nil
    end)
end

local function tryBandagePlayer(player)
    local global = getGlobal()
    if not global then
        return false
    end
    local repChar = global.RepCharHandler:GetRepChar(player)
    if not repChar then
        return false
    end
    local ref = global.Network:GetReference(repChar, "Character")
    if not ref then
        return false
    end
    global.Network:FireServer("AttemptBandage", ref)
    return true
end

local function setMiningEnabled(stateOn)
    local farm = TWW.Farm
    if not farm or not farm.setOreFarmEnabled then
        return
    end
    if stateOn then
        if TWW.Esp and TWW.Esp.rebuildOreFolders then
            TWW.Esp.rebuildOreFolders()
        end
        if TWW.Esp and TWW.Esp.oreState and TWW.Esp.oreState.oreFolders and TWW.Esp.setOreSelection then
            for oreName in pairs(TWW.Esp.oreState.oreFolders) do
                TWW.Esp.setOreSelection(oreName, true)
            end
        end
    end
    farm.setOreFarmEnabled(stateOn)
end

local function defaultConfig(state, defaults)
    state.config = state.config or {}
    for key, value in pairs(defaults) do
        if state.config[key] == nil then
            state.config[key] = value
        end
    end
end

SkillFarm.handlers.Mining = function(state)
    setMiningEnabled(state.enabled)
end

SkillFarm.handlers.Logging = function(state, session)
    state.running = true
    defaultConfig(state, {
        maxDistance = 350,
        chopDistance = 7,
        moveTimeout = 8,
        chopTimeout = 10,
        scanInterval = 0.4,
        clickInterval = 0.12,
    })
    while state.enabled and session == state.session do
        ensureAxeEquipped()
        local tree = nil
        if os.clock() - (state.lastScan or 0) >= state.config.scanInterval then
            state.lastScan = os.clock()
            tree = findNearestTree(state.config.maxDistance)
        else
            tree = state.target
        end
        if not tree or not isTreeAlive(tree) then
            state.target = nil
            setMouseDown(false)
            task.wait(0.2)
            continue
        end
        state.target = tree
        local part = getModelPart(tree)
        if part then
            moveToPosition(part.Position, state.config.chopDistance, state.config.moveTimeout)
        end
        if not isTreeAlive(tree) then
            state.target = nil
            setMouseDown(false)
            task.wait(0.1)
            continue
        end
        faceTarget(part)
        setMouseDown(true)
        local start = os.clock()
        while state.enabled and session == state.session and isTreeAlive(tree) do
            if os.clock() - start >= state.config.chopTimeout then
                break
            end
            task.wait(state.config.clickInterval)
        end
        setMouseDown(false)
        state.target = nil
        task.wait(0.1)
    end
    setMouseDown(false)
    state.running = false
end

SkillFarm.handlers.Hunting = function(state, session)
    state.running = true
    defaultConfig(state, {
        maxDistance = 450,
        attackDistance = 35,
        moveTimeout = 10,
        clickInterval = 0.18,
        harvest = true,
        scanInterval = 0.4,
    })
    while state.enabled and session == state.session do
        local animal = nil
        if os.clock() - (state.lastScan or 0) >= state.config.scanInterval then
            state.lastScan = os.clock()
            animal = findNearestAnimal(state.config.maxDistance)
        else
            animal = state.target
        end
        if not animal or isAnimalDead(animal) then
            state.target = nil
            task.wait(0.2)
            continue
        end
        state.target = animal
        local part = getAnimalPart(animal)
        if part then
            moveToPosition(part.Position, state.config.attackDistance, state.config.moveTimeout)
        end
        local attackStart = os.clock()
        while state.enabled and session == state.session and not isAnimalDead(animal) do
            if os.clock() - attackStart >= state.config.moveTimeout then
                break
            end
            faceTarget(part)
            clickMouse()
            task.wait(state.config.clickInterval)
        end
        if state.config.harvest and isAnimalDead(animal) then
            local deadPart = getAnimalPart(animal)
            if deadPart then
                moveToPosition(deadPart.Position, 6, 6)
                tryInteract(animal)
            end
        end
        state.target = nil
        task.wait(0.2)
    end
    state.running = false
end

SkillFarm.handlers.Combat = function(state, session)
    state.running = true
    defaultConfig(state, {
        maxDistance = 450,
        attackDistance = 45,
        moveTimeout = 10,
        clickInterval = 0.15,
        scanInterval = 0.4,
    })
    while state.enabled and session == state.session do
        local npc = nil
        if os.clock() - (state.lastScan or 0) >= state.config.scanInterval then
            state.lastScan = os.clock()
            npc = findNearestNpc(state.config.maxDistance)
        else
            npc = state.target
        end
        if not npc then
            state.target = nil
            task.wait(0.25)
            continue
        end
        state.target = npc
        local part = getModelPart(npc)
        if part then
            moveToPosition(part.Position, state.config.attackDistance, state.config.moveTimeout)
        end
        local hum = findHumanoid(npc)
        local attackStart = os.clock()
        while state.enabled and session == state.session and hum and hum.Health > 0 do
            if os.clock() - attackStart >= state.config.moveTimeout then
                break
            end
            faceTarget(part)
            clickMouse()
            task.wait(state.config.clickInterval)
            hum = findHumanoid(npc)
        end
        state.target = nil
        task.wait(0.2)
    end
    state.running = false
end

SkillFarm.handlers.Doctor = function(state, session)
    state.running = true
    defaultConfig(state, {
        healRange = 20,
        cooldown = 1.2,
    })
    while state.enabled and session == state.session do
        local target = findNearestPlayerNeedingHeal(state.config.healRange)
        if target then
            tryBandagePlayer(target)
            task.wait(state.config.cooldown)
        else
            task.wait(0.4)
        end
    end
    state.running = false
end

SkillFarm.handlers.Exploration = function(state, session)
    state.running = true
    defaultConfig(state, {
        roamRadius = 120,
        roamInterval = 6,
        interactDistance = 8,
    })
    local lastRoam = 0
    while state.enabled and session == state.session do
        local chests = collectTaggedModels({ "ClueScrollChest", "ClueChest" })
        local chest, _ = findNearestModel(chests, 600, getModelPart, nil)
        if chest then
            local part = getModelPart(chest)
            if part then
                moveToPosition(part.Position, state.config.interactDistance, 12)
                tryInteract(chest)
            end
            task.wait(1)
        else
            local now = os.clock()
            if now - lastRoam >= state.config.roamInterval then
                lastRoam = now
                local root = getLocalRootPart()
                if root then
                    local dx = math.random(-state.config.roamRadius, state.config.roamRadius)
                    local dz = math.random(-state.config.roamRadius, state.config.roamRadius)
                    local targetPos = root.Position + Vector3.new(dx, 0, dz)
                    moveToPosition(targetPos, 6, 8)
                end
            end
            task.wait(0.4)
        end
    end
    state.running = false
end

SkillFarm.handlers.Fishing = function(state, session)
    state.running = true
    defaultConfig(state, {
        castHold = 0.8,
        reelDuration = 4.5,
        castCooldown = 2.0,
    })
    while state.enabled and session == state.session do
        local tool = ensureFishingPoleEquipped()
        if tool and tool.Activate and tool.Deactivate then
            pcall(function()
                tool:Activate()
            end)
            task.wait(state.config.castHold)
            pcall(function()
                tool:Deactivate()
            end)
            setMouseDown(true)
            local reelStart = os.clock()
            while state.enabled and session == state.session and os.clock() - reelStart < state.config.reelDuration do
                task.wait(0.1)
            end
            setMouseDown(false)
            task.wait(state.config.castCooldown)
        else
            task.wait(1)
        end
    end
    setMouseDown(false)
    state.running = false
end

SkillFarm.handlers.Panning = function(state, session)
    state.running = true
    defaultConfig(state, {
        panInterval = 1.0,
    })
    while state.enabled and session == state.session do
        local tool = ensurePanEquipped()
        if tool then
            clickMouse()
            task.wait(state.config.panInterval)
        else
            task.wait(1)
        end
    end
    state.running = false
end

SkillFarm.handlers.Inactive = function(state, session, info)
    if not state.warned then
        notify(info.name .. " je v Saved Things jako inactive. Autofarm zatím jen placeholder.")
        state.warned = true
    end
    state.running = true
    while state.enabled and session == state.session do
        task.wait(1)
    end
    state.running = false
end

SkillFarm.handlers.Default = function(state, session, info)
    if not state.warned then
        notify(info.name .. " nemá specifický handler. Autofarm běží v fallback režimu.")
        state.warned = true
    end
    state.running = true
    while state.enabled and session == state.session do
        task.wait(1)
    end
    state.running = false
end

local SKILL_DEFS = {
    { name = "Doctor", active = true, handler = "Doctor" },
    { name = "Exploration", active = true, handler = "Exploration" },
    { name = "Hitman", active = true, handler = "Combat" },
    { name = "Hunting", active = true, handler = "Hunting" },
    { name = "Justice", active = true, handler = "Combat" },
    { name = "Logging", active = true, handler = "Logging" },
    { name = "Militia", active = true, handler = "Combat" },
    { name = "Mining", active = true, handler = "Mining" },
    { name = "Outlaw", active = true, handler = "Combat" },
    { name = "Primary", active = true, handler = "Combat" },
    { name = "Sidearms", active = true, handler = "Combat" },
    { name = "Tracking", active = true, handler = "Hunting" },
    { name = "Barkeep", active = false, handler = "Inactive" },
    { name = "Bartering", active = false, handler = "Inactive" },
    { name = "Brawling", active = false, handler = "Combat" },
    { name = "Building", active = false, handler = "Inactive" },
    { name = "Fishing", active = false, handler = "Fishing" },
    { name = "Mayor", active = false, handler = "Inactive" },
    { name = "Musician", active = false, handler = "Inactive" },
    { name = "Panning", active = false, handler = "Panning" },
}

local function ensureSkillState(def)
    if not SkillFarm.skills[def.name] then
        SkillFarm.skills[def.name] = {
            enabled = false,
            running = false,
            session = 0,
            target = nil,
            lastScan = 0,
            warned = false,
            config = {},
        }
    end
    if not SkillFarm.skillInfo[def.name] then
        SkillFarm.skillInfo[def.name] = def
        table.insert(SkillFarm.skillOrder, def.name)
    end
end

for _, def in ipairs(SKILL_DEFS) do
    ensureSkillState(def)
end

local function startSkill(def, state)
    if def.handler == "Mining" then
        SkillFarm.handlers.Mining(state)
        return
    end
    local handler = SkillFarm.handlers[def.handler] or SkillFarm.handlers.Default
    local session = state.session
    task.spawn(function()
        handler(state, session, def)
    end)
end

function SkillFarm.setSkillEnabled(name, stateOn)
    local def = SkillFarm.skillInfo[name]
    if not def then
        return
    end
    local state = SkillFarm.skills[name]
    if stateOn then
        if state.enabled then
            return
        end
        state.enabled = true
        state.session = (state.session or 0) + 1
        startSkill(def, state)
    else
        if not state.enabled then
            return
        end
        state.enabled = false
        state.session = (state.session or 0) + 1
        if def.handler == "Mining" then
            SkillFarm.handlers.Mining(state)
        end
        if def.handler == "Logging" or def.handler == "Hunting" or def.handler == "Combat" or def.handler == "Fishing" or def.handler == "Panning" then
            setMouseDown(false)
        end
    end
end

function SkillFarm.setAllEnabled(stateOn)
    for _, name in ipairs(SkillFarm.skillOrder) do
        SkillFarm.setSkillEnabled(name, stateOn)
    end
end

function SkillFarm.getSkillList()
    return SkillFarm.skillOrder
end

