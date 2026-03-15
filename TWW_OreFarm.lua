local env = (getgenv and getgenv()) or _G
env.TWW = env.TWW or {}
local TWW = env.TWW

if TWW._farmLoaded then
    return
end
TWW._farmLoaded = true

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

local function getOreState()
    local esp = TWW.Esp
    return (esp and esp.oreState) or { selections = {}, oreFolders = {} }
end

local function rebuildOreFolders()
    local esp = TWW.Esp
    if esp and esp.rebuildOreFolders then
        return esp.rebuildOreFolders()
    end
    return nil
end

local function findOreRemainingValue(model, oreName)
    local esp = TWW.Esp
    if esp and esp.findOreRemainingValue then
        return esp.findOreRemainingValue(model, oreName)
    end
    return nil
end

local function getModelPart(model)
    local esp = TWW.Esp
    if esp and esp.getModelPart then
        return esp.getModelPart(model)
    end
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

local function getLocalPlayerModel()
    local esp = TWW.Esp
    if esp and esp.getLocalPlayerModel then
        return esp.getLocalPlayerModel()
    end
    local playersFolder = Services.Workspace:FindFirstChild("WORKSPACE_Entities")
    playersFolder = playersFolder and playersFolder:FindFirstChild("Players") or nil
    return playersFolder and playersFolder:FindFirstChild(LocalPlayer.Name) or nil
end

local function getLocalHumanoid()
    local esp = TWW.Esp
    if esp and esp.getLocalHumanoid then
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
    local esp = TWW.Esp
    if esp and esp.getLocalRootPart then
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

TWW.Farm = TWW.Farm or {}
local Farm = TWW.Farm

local oreFarmState = Farm.oreFarmState
if not oreFarmState then
    oreFarmState = {
        enabled = false,
        running = false,
        target = nil,
        mouseDown = false,
        mineDistance = 6,
        waypointRadius = 6,
        scanInterval = 1.0,
        waypointTimeout = 3.5,
        lastScan = 0,
        jumpEnabled = true,
        runEnabled = true,
        mineStallTime = 1.0,
        mineStallReset = 0.08,
        moveStallTime = 1.2,
        moveProgressMin = 0.45,
        pathClearance = 0.9,
        pathSampleSpacing = 4,
        pathLookahead = 3,
        pathSegmentLength = 240,
        session = 0,
        lastMoveMode = nil,
        autoRotateBackup = nil,
        autoRotateHumanoid = nil,
        facePart = nil,
        faceBound = false,
        keyState = {
            [Enum.KeyCode.W] = false,
            [Enum.KeyCode.A] = false,
            [Enum.KeyCode.S] = false,
            [Enum.KeyCode.D] = false,
            [Enum.KeyCode.LeftShift] = false,
        },
    }
    Farm.oreFarmState = oreFarmState
end

oreFarmState.keyState = oreFarmState.keyState or {
    [Enum.KeyCode.W] = false,
    [Enum.KeyCode.A] = false,
    [Enum.KeyCode.S] = false,
    [Enum.KeyCode.D] = false,
    [Enum.KeyCode.LeftShift] = false,
}

local controlModuleCache = nil

local function getControlModule()
    if controlModuleCache then
        return controlModuleCache
    end
    local playerScripts = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts")
    local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
    if playerModule then
        if playerModule:IsA("ModuleScript") then
            local ok, pm = pcall(require, playerModule)
            if ok and pm and type(pm.GetControls) == "function" then
                local okControls, controls = pcall(function()
                    return pm:GetControls()
                end)
                if okControls and controls then
                    controlModuleCache = controls
                    return controlModuleCache
                end
            end
        end
        local controlModule = playerModule:FindFirstChild("ControlModule", true)
        if controlModule and controlModule:IsA("ModuleScript") then
            local okControl, controls = pcall(require, controlModule)
            if okControl and controls then
                controlModuleCache = controls
                return controlModuleCache
            end
        end
    end
    return nil
end

local function worldToCameraMoveVector(worldDir)
    local cam = Services.Workspace.CurrentCamera
    if not cam then
        return worldDir, false
    end
    local forward = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
    local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
    if forward.Magnitude < 0.001 or right.Magnitude < 0.001 then
        return worldDir, false
    end
    forward = forward.Unit
    right = right.Unit
    local x = worldDir:Dot(right)
    local z = worldDir:Dot(forward)
    return Vector3.new(x, 0, z), true
end

local function setMoveMode(mode)
    oreFarmState.lastMoveMode = mode
end

local function setKeyState(keyCode, state)
    if not Services.VirtualInputManager then
        return false
    end
    if oreFarmState.keyState[keyCode] == state then
        return true
    end
    oreFarmState.keyState[keyCode] = state
    pcall(function()
        Services.VirtualInputManager:SendKeyEvent(state, keyCode, false, game)
    end)
    return true
end

local function clearMovementKeys()
    setKeyState(Enum.KeyCode.W, false)
    setKeyState(Enum.KeyCode.A, false)
    setKeyState(Enum.KeyCode.S, false)
    setKeyState(Enum.KeyCode.D, false)
    setKeyState(Enum.KeyCode.LeftShift, false)
end

local function applyMoveDirection(worldDir)
    if not worldDir then
        return false
    end
    local dir = worldDir
    if dir.Magnitude < 0.001 then
        dir = Vector3.new(0, 0, 0)
    end

    local controls = getControlModule()
    if controls and type(controls.Move) == "function" then
        local camVec = worldToCameraMoveVector(dir)
        pcall(function()
            controls:Move(camVec, true)
        end)
        if oreFarmState.runEnabled then
            setKeyState(Enum.KeyCode.LeftShift, dir.Magnitude > 0.05)
        else
            setKeyState(Enum.KeyCode.LeftShift, false)
        end
        setMoveMode("ControlModule")
        return true
    end

    if Services.VirtualInputManager then
        local camVec = worldToCameraMoveVector(dir)
        local x = camVec.X
        local z = camVec.Z
        local w = z > 0.25
        local s = z < -0.25
        local d = x > 0.25
        local a = x < -0.25
        setKeyState(Enum.KeyCode.W, w)
        setKeyState(Enum.KeyCode.S, s)
        setKeyState(Enum.KeyCode.D, d)
        setKeyState(Enum.KeyCode.A, a)
        if oreFarmState.runEnabled then
            setKeyState(Enum.KeyCode.LeftShift, (w or a or s or d))
        else
            setKeyState(Enum.KeyCode.LeftShift, false)
        end
        setMoveMode("VirtualInput")
        return true
    end

    local humanoid = getLocalHumanoid()
    if humanoid then
        humanoid:Move(dir, false)
        if oreFarmState.runEnabled then
            setKeyState(Enum.KeyCode.LeftShift, dir.Magnitude > 0.05)
        else
            setKeyState(Enum.KeyCode.LeftShift, false)
        end
        setMoveMode("Humanoid")
        return true
    end
    return false
end

local function stopAutoMove()
    applyMoveDirection(Vector3.new(0, 0, 0))
    clearMovementKeys()
end

local function beginFaceTarget()
    local humanoid = getLocalHumanoid()
    if humanoid then
        if oreFarmState.autoRotateHumanoid ~= humanoid then
            oreFarmState.autoRotateHumanoid = humanoid
            oreFarmState.autoRotateBackup = humanoid.AutoRotate
        end
        humanoid.AutoRotate = false
    end
end

local function startFaceLoop(part)
    oreFarmState.facePart = part
    if oreFarmState.faceBound then
        return
    end
    oreFarmState.faceBound = true
    Services.RunService:BindToRenderStep("SmugOreFace", Enum.RenderPriority.Camera.Value + 1, function()
        local target = oreFarmState.facePart
        if not target or not target.Parent then
            return
        end
        local cam = Services.Workspace.CurrentCamera
        if cam then
            cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)
        end
        local root = getLocalRootPart()
        if root then
            local pos = root.Position
            root.CFrame = CFrame.new(pos, Vector3.new(target.Position.X, pos.Y, target.Position.Z))
        end
    end)
end

local function stopFaceLoop()
    oreFarmState.facePart = nil
    if oreFarmState.faceBound then
        oreFarmState.faceBound = false
        pcall(function()
            Services.RunService:UnbindFromRenderStep("SmugOreFace")
        end)
    end
end

local function endFaceTarget()
    if oreFarmState.autoRotateHumanoid and oreFarmState.autoRotateBackup ~= nil then
        oreFarmState.autoRotateHumanoid.AutoRotate = oreFarmState.autoRotateBackup
    end
    oreFarmState.autoRotateHumanoid = nil
    oreFarmState.autoRotateBackup = nil
    stopFaceLoop()
end

local function faceTarget(part)
    if not part then
        return
    end
    local cam = Services.Workspace.CurrentCamera
    if cam then
        cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
    end
    local root = getLocalRootPart()
    if root then
        local pos = root.Position
        root.CFrame = CFrame.new(pos, Vector3.new(part.Position.X, pos.Y, part.Position.Z))
    end
end

local function getMousePosition()
    local pos = Services.UserInputService:GetMouseLocation()
    local inset = Services.GuiService:GetGuiInset()
    return Vector2.new(pos.X - inset.X, pos.Y - inset.Y)
end

local function setMouseDown(state)
    if oreFarmState.mouseDown == state then
        return
    end
    oreFarmState.mouseDown = state

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

local function gatherOreCandidates()
    local candidates = {}
    local deposits = rebuildOreFolders()
    if not deposits then
        return candidates
    end
    local oreState = getOreState()
    for oreName, folder in pairs(oreState.oreFolders) do
        if oreState.selections[oreName] then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Folder") then
                    for _, sub in ipairs(child:GetChildren()) do
                        if sub:IsA("Model") or sub:IsA("BasePart") then
                            table.insert(candidates, { model = sub, oreName = oreName })
                        end
                    end
                elseif child:IsA("Model") or child:IsA("BasePart") then
                    table.insert(candidates, { model = child, oreName = oreName })
                end
            end
        end
    end
    return candidates
end

local function findClosestOreTarget()
    local root = getLocalRootPart()
    if not root then
        return nil
    end

    local best = nil
    local bestDist = nil
    for _, info in ipairs(gatherOreCandidates()) do
        local model = info.model
        if model and model.Parent then
            local remaining = findOreRemainingValue(model, info.oreName)
            local value = remaining and tonumber(remaining.Value) or 0
            if remaining and value > 0 then
                local part = getModelPart(model)
                if part then
                    local dist = (root.Position - part.Position).Magnitude
                    if not bestDist or dist < bestDist then
                        bestDist = dist
                        best = {
                            model = model,
                            oreName = info.oreName,
                            part = part,
                            remaining = remaining,
                        }
                    end
                end
            end
        end
    end
    return best, bestDist
end

local function simplifyWaypoints(waypoints)
    if not waypoints or #waypoints <= 2 then
        return waypoints
    end
    local simplified = { waypoints[1] }
    for i = 2, #waypoints - 1 do
        local prev = simplified[#simplified]
        local curr = waypoints[i]
        local next = waypoints[i + 1]
        if curr.Action ~= Enum.PathWaypointAction.Walk or next.Action ~= Enum.PathWaypointAction.Walk then
            table.insert(simplified, curr)
        else
            local dir1 = curr.Position - prev.Position
            local dir2 = next.Position - curr.Position
            if dir1.Magnitude < 0.05 or dir2.Magnitude < 0.05 then
                -- skip tiny segments
            else
                local dot = dir1.Unit:Dot(dir2.Unit)
                if dot < 0.98 then
                    table.insert(simplified, curr)
                end
            end
        end
    end
    table.insert(simplified, waypoints[#waypoints])
    return simplified
end

local function computePathDetailed(startPos, goalPos, agentRadius, agentHeight)
    local path = Services.PathfindingService:CreatePath({
        AgentRadius = agentRadius or 2,
        AgentHeight = agentHeight or 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 4,
    })
    local ok = pcall(function()
        path:ComputeAsync(startPos, goalPos)
    end)
    if ok and path.Status == Enum.PathStatus.Success then
        return simplifyWaypoints(path:GetWaypoints()), path
    end
    return nil, path
end

local function getAgentDimensions()
    local root = getLocalRootPart()
    local humanoid = getLocalHumanoid()
    local radius = 2
    local height = 5
    if root and root:IsA("BasePart") then
        radius = math.max(root.Size.X, root.Size.Z) * 0.5
        height = math.max(height, root.Size.Y + 2)
    end
    if humanoid then
        height = math.max(height, (humanoid.HipHeight * 2) + 2)
    end
    return radius, height
end

local function buildIgnoreList(extra)
    local ignore = {}
    local localModel = getLocalPlayerModel() or LocalPlayer.Character
    if localModel then
        table.insert(ignore, localModel)
    end
    if extra then
        table.insert(ignore, extra)
    end
    local wsIgnore = Services.Workspace:FindFirstChild("Ignore")
    if wsIgnore then
        table.insert(ignore, wsIgnore)
    end
    return ignore
end

local function buildRaycastParams(ignoreInstance)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = buildIgnoreList(ignoreInstance)
    params.IgnoreWater = true
    return params
end

local function buildOverlapParams(ignoreInstance)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = buildIgnoreList(ignoreInstance)
    params.MaxParts = 50
    pcall(function()
        params.RespectCanCollide = true
    end)
    return params
end

local function getPathClearanceRadius()
    local radius, height = getAgentDimensions()
    local clearance = oreFarmState.pathClearance or 0
    radius = math.max(radius + clearance, 0.5)
    height = math.max(height, 4)
    return radius, height
end

local function projectToGround(pos, ignoreInstance)
    if not pos then
        return nil
    end
    local rayParams = buildRaycastParams(ignoreInstance)
    local origin = pos + Vector3.new(0, 80, 0)
    local result = Services.Workspace:Raycast(origin, Vector3.new(0, -160, 0), rayParams)
    if result then
        return result.Position
    end
    return nil
end

local function buildGoalCandidates(goalPos, desiredRadius)
    local candidates = {}
    if not goalPos then
        return candidates
    end
    table.insert(candidates, goalPos)
    local radius = desiredRadius or 8
    local step = 45
    for angle = 0, 360 - step, step do
        local rad = math.rad(angle)
        local offset = Vector3.new(math.cos(rad) * radius, 0, math.sin(rad) * radius)
        table.insert(candidates, goalPos + offset)
    end
    return candidates
end

local function isWaypointClear(pos, ignoreInstance, radius, height)
    local params = buildOverlapParams(ignoreInstance)

    local center = pos + Vector3.new(0, height * 0.5, 0)
    local parts = Services.Workspace:GetPartBoundsInBox(CFrame.new(center), Vector3.new(radius * 2, height, radius * 2), params)
    for _, part in ipairs(parts) do
        if part and part.CanCollide then
            local top = part.Position.Y + (part.Size.Y * 0.5)
            if top > pos.Y + 0.4 then
                return false
            end
        end
    end

    local rayParams = buildRaycastParams(ignoreInstance)
    local origin = pos + Vector3.new(0, math.max(2, height * 0.5), 0)
    local pad = math.max(0.15, radius * 0.2)
    local dirs = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1),
    }
    for _, dir in ipairs(dirs) do
        local hit = Services.Workspace:Raycast(origin, dir * (radius + pad), rayParams)
        if hit then
            return false
        end
    end

    local ground = Services.Workspace:Raycast(pos + Vector3.new(0, height, 0), Vector3.new(0, -(height + 6), 0), rayParams)
    if not ground then
        return false
    end
    return true
end

local function isSegmentClear(startPos, endPos, ignoreInstance, radius, height)
    local dir = endPos - startPos
    if dir.Magnitude < 0.25 then
        return true
    end
    local rayParams = buildRaycastParams(ignoreInstance)
    local origin = startPos + Vector3.new(0, math.max(1.5, height * 0.5), 0)
    local function isBlockingHit(hit)
        if not hit then
            return false
        end
        local normal = hit.Normal
        return not normal or normal.Y < 0.6
    end
    if isBlockingHit(Services.Workspace:Raycast(origin, dir, rayParams)) then
        return false
    end
    local flat = Vector3.new(dir.X, 0, dir.Z)
    if flat.Magnitude > 0.1 then
        local right = Vector3.new(-flat.Z, 0, flat.X).Unit
        local offset = right * radius
        if isBlockingHit(Services.Workspace:Raycast(origin + offset, dir, rayParams)) then
            return false
        end
        if isBlockingHit(Services.Workspace:Raycast(origin - offset, dir, rayParams)) then
            return false
        end
    end
    return true
end

local function validatePathSegments(waypoints, ignoreInstance, radius, height)
    if not waypoints or #waypoints < 2 then
        return true
    end
    local spacing = math.clamp(oreFarmState.pathSampleSpacing or 4, 2, 8)
    for i = 1, #waypoints - 1 do
        local a = waypoints[i]
        local b = waypoints[i + 1]
        if a and b then
            if a.Action ~= Enum.PathWaypointAction.Jump and b.Action ~= Enum.PathWaypointAction.Jump then
                if not isSegmentClear(a.Position, b.Position, ignoreInstance, radius, height) then
                    return false
                end
                local delta = b.Position - a.Position
                local length = delta.Magnitude
                if length > spacing then
                    local steps = math.clamp(math.floor(length / spacing), 1, 25)
                    for s = 1, steps do
                        local pos = a.Position + delta * (s / steps)
                        if not isWaypointClear(pos, ignoreInstance, radius, height) then
                            return false
                        end
                    end
                end
            elseif not isWaypointClear(b.Position, ignoreInstance, radius, height) then
                return false
            end
        end
    end
    return true
end

local function smoothWaypoints(waypoints, ignoreInstance, radius, height)
    if not waypoints or #waypoints <= 2 then
        return waypoints
    end
    local smoothed = {}
    local i = 1
    while i <= #waypoints do
        table.insert(smoothed, waypoints[i])
        if i >= #waypoints then
            break
        end
        local best = i + 1
        local maxIndex = math.min(#waypoints, i + (oreFarmState.pathLookahead or 3))
        for j = maxIndex, i + 1, -1 do
            local canSkip = true
            for k = i + 1, j do
                if waypoints[k].Action ~= Enum.PathWaypointAction.Walk then
                    canSkip = false
                    break
                end
            end
            if canSkip and isSegmentClear(waypoints[i].Position, waypoints[j].Position, ignoreInstance, radius, height) then
                best = j
                break
            end
        end
        i = best
    end
    return smoothed
end

local function validatePath(waypoints, ignoreInstance, radius, height)
    if not waypoints or #waypoints == 0 then
        return false
    end
    if not radius or not height then
        local defaultRadius, defaultHeight = getPathClearanceRadius()
        radius = radius or defaultRadius
        height = height or defaultHeight
    end
    for i = 1, #waypoints do
        local wp = waypoints[i]
        if wp and wp.Action ~= Enum.PathWaypointAction.Jump then
            if not isWaypointClear(wp.Position, ignoreInstance, radius, height) then
                return false
            end
        end
    end
    return validatePathSegments(waypoints, ignoreInstance, radius, height)
end

local function isPathBlocked(targetPos, ignoreInstance)
    if not targetPos then
        return false
    end
    local root = getLocalRootPart()
    if not root then
        return false
    end
    local origin = root.Position
    local direction = targetPos - origin
    if direction.Magnitude < 1 then
        return false
    end
    local radius, height = getPathClearanceRadius()
    return not isSegmentClear(origin, targetPos, ignoreInstance, radius, height)
end

local function walkToPosition(targetPos, timeout, ignoreInstance)
    if not targetPos then
        return false
    end
    local humanoid = getLocalHumanoid()
    local radius, height = getPathClearanceRadius()
    local reachDist = math.max(oreFarmState.waypointRadius or 4, oreFarmState.mineDistance or 6, radius + 1)
    local rootAtStart = getLocalRootPart()
    local speed = humanoid and humanoid.WalkSpeed or 16
    local distEstimate = rootAtStart and (targetPos - rootAtStart.Position).Magnitude or 0
    local timeBudget = math.max(timeout or 3.5, (distEstimate / math.max(speed, 8)) + 1.5)
    local start = os.clock()
    local lastDist = nil
    local lastProgress = os.clock()
    while oreFarmState.enabled and os.clock() - start < timeBudget do
        local root = getLocalRootPart()
        if not root then
            stopAutoMove()
            return false
        end
        local delta = targetPos - root.Position
        local horiz = Vector3.new(delta.X, 0, delta.Z)
        if horiz.Magnitude <= reachDist then
            stopAutoMove()
            return true
        end
        if not isWaypointClear(targetPos, ignoreInstance, radius, height) then
            stopAutoMove()
            return false
        end
        if isPathBlocked(targetPos, ignoreInstance) then
            stopAutoMove()
            return false
        end
        if lastDist then
            local progress = lastDist - horiz.Magnitude
            if progress >= (oreFarmState.moveProgressMin or 0.45) then
                lastProgress = os.clock()
            elseif os.clock() - lastProgress >= (oreFarmState.moveStallTime or 1.2) then
                stopAutoMove()
                return false
            end
        else
            lastProgress = os.clock()
        end
        lastDist = horiz.Magnitude
        if horiz.Magnitude > 0.05 then
            applyMoveDirection(horiz.Unit)
        end
        if oreFarmState.jumpEnabled and humanoid and delta.Y > 1.5 then
            humanoid.Jump = true
        end
        task.wait(0.03)
    end
    stopAutoMove()
    return false
end

local function buildOreGoalPositions(target)
    local part = target and (target.part or getModelPart(target.model))
    if not part then
        return {}
    end
    local base = part.Position
    local desiredRadius = math.max((oreFarmState.mineDistance or 6) + 2, 4)
    local candidates = buildGoalCandidates(base, desiredRadius)
    local radius, height = getPathClearanceRadius()
    local results = {}
    for _, pos in ipairs(candidates) do
        local ground = projectToGround(pos, target.model) or pos
        if isWaypointClear(ground, target.model, radius, height) then
            table.insert(results, ground)
        end
    end
    if #results == 0 then
        table.insert(results, base)
    end
    return results
end

local function getSegmentGoal(startPos, goalPos, ignoreInstance)
    if not startPos or not goalPos then
        return nil
    end
    local segmentLength = math.max(oreFarmState.pathSegmentLength or 240, 60)
    local dir = goalPos - startPos
    local dist = dir.Magnitude
    if dist <= segmentLength then
        return goalPos
    end
    local segPos = startPos + dir.Unit * segmentLength
    return projectToGround(segPos, ignoreInstance) or segPos
end

local function computeSafePath(startPos, goalPos, ignoreInstance)
    local baseRadius, baseHeight = getAgentDimensions()
    local clearance = oreFarmState.pathClearance or 0
    local options = {
        math.max(clearance, 0),
        math.max(clearance * 0.5, 0),
        0,
    }
    for _, extra in ipairs(options) do
        local radius = math.max(baseRadius + extra, 0.5)
        local height = math.max(baseHeight, 4)
        local waypoints, path = computePathDetailed(startPos, goalPos, radius, height)
        if waypoints and #waypoints > 0 then
            local smoothed = smoothWaypoints(waypoints, ignoreInstance, radius, height)
            if validatePath(smoothed, ignoreInstance, radius, height) then
                return smoothed, path, radius, height
            end
        end
    end
    return nil, nil, nil, nil
end

local function getLookaheadIndex(waypoints, startIndex, ignoreInstance, radius, height)
    if not waypoints or startIndex >= #waypoints then
        return startIndex
    end
    local maxIndex = math.min(#waypoints, startIndex + (oreFarmState.pathLookahead or 3))
    for j = maxIndex, startIndex + 1, -1 do
        local canSkip = true
        for k = startIndex + 1, j do
            if waypoints[k].Action ~= Enum.PathWaypointAction.Walk then
                canSkip = false
                break
            end
        end
        if canSkip and isSegmentClear(waypoints[startIndex].Position, waypoints[j].Position, ignoreInstance, radius, height) then
            return j
        end
    end
    return startIndex
end

local function moveToOreTarget(target)
    if not target or not target.part then
        return false
    end
    local humanoid = getLocalHumanoid()
    local root = getLocalRootPart()
    if not humanoid or not root then
        return false
    end
    if humanoid.WalkSpeed and humanoid.WalkSpeed <= 0 then
        return false
    end

    local maxFailures = 12
    local failures = 0
    while oreFarmState.enabled do
        root = getLocalRootPart()
        if not root then
            return false
        end
        target.part = getModelPart(target.model) or target.part
        if not target.part then
            return false
        end

        local startDist = (root.Position - target.part.Position).Magnitude
        if startDist <= oreFarmState.mineDistance then
            return true
        end

        local goalCandidates = buildOreGoalPositions(target)
        local waypoints, path, radius, height, goalPos = nil, nil, nil, nil, nil
        for _, candidate in ipairs(goalCandidates) do
            waypoints, path, radius, height = computeSafePath(root.Position, candidate, target.model)
            if waypoints then
                goalPos = candidate
                break
            end
        end

        if not waypoints then
            local fallbackGoal = goalCandidates[1] or target.part.Position
            local segmentGoal = getSegmentGoal(root.Position, fallbackGoal, target.model)
            if segmentGoal then
                waypoints, path, radius, height = computeSafePath(root.Position, segmentGoal, target.model)
                goalPos = segmentGoal
            end
        end

        if not waypoints or not goalPos then
            local fallbackGoal = (goalCandidates and goalCandidates[1]) or target.part.Position
            local directGoal = getSegmentGoal(root.Position, fallbackGoal, target.model)
            if directGoal and walkToPosition(directGoal, (oreFarmState.waypointTimeout or 3.5) * 2, target.model) then
                failures = 0
                task.wait(0.05)
                continue
            end
            return false
        end

        local blocked = false
        local blockedConn = nil
        if path and path.Blocked then
            blockedConn = path.Blocked:Connect(function()
                blocked = true
            end)
        end

        local idx = 1
        local reachedGoal = false
        while idx <= #waypoints and oreFarmState.enabled do
            local remaining = findOreRemainingValue(target.model, target.oreName)
            local value = remaining and tonumber(remaining.Value) or 0
            if not remaining or value <= 0 then
                stopAutoMove()
                break
            end
            if blocked then
                break
            end

            local lookIdx = getLookaheadIndex(waypoints, idx, target.model, radius, height)
            local wp = waypoints[lookIdx]
            if wp and wp.Action == Enum.PathWaypointAction.Jump and oreFarmState.jumpEnabled then
                humanoid.Jump = true
            end
            local reached = walkToPosition(wp.Position, oreFarmState.waypointTimeout, target.model)
            if not reached then
                break
            end
            idx = math.max(idx + 1, lookIdx + 1)
            root = getLocalRootPart()
            if not root then
                stopAutoMove()
                break
            end
            if (root.Position - target.part.Position).Magnitude <= oreFarmState.mineDistance then
                reachedGoal = true
                break
            end
        end

        if blockedConn then
            blockedConn:Disconnect()
        end

        stopAutoMove()

        if reachedGoal then
            return true
        end

        root = getLocalRootPart()
        if not root then
            return false
        end
        local endDist = (root.Position - target.part.Position).Magnitude
        if endDist + 1 < startDist then
            failures = 0
        else
            failures += 1
        end
        if failures > maxFailures then
            return false
        end
        task.wait(0.05)
    end

    return false
end

local function mineOreTarget(target)
    if not target or not target.part then
        return
    end
    local remaining = target.remaining
    if not remaining or not remaining.Parent then
        remaining = findOreRemainingValue(target.model, target.oreName)
    end
    if not remaining then
        local deadline = os.clock() + 1.0
        while oreFarmState.enabled and os.clock() < deadline and not remaining do
            remaining = findOreRemainingValue(target.model, target.oreName)
            task.wait(0.1)
        end
    end
    if not remaining then
        return
    end

    stopAutoMove()
    beginFaceTarget()
    startFaceLoop(target.part)
    setMouseDown(true)
    local lastValue = tonumber(remaining.Value) or 0
    local lastChange = os.clock()
    while oreFarmState.enabled do
        local root = getLocalRootPart()
        if not root then
            break
        end
        if (root.Position - target.part.Position).Magnitude > (oreFarmState.mineDistance + 3) then
            break
        end
        if not remaining.Parent then
            remaining = findOreRemainingValue(target.model, target.oreName)
            if not remaining then
                break
            end
        end
        local value = tonumber(remaining.Value) or 0
        if value <= 0 then
            break
        end
        if value ~= lastValue then
            lastValue = value
            lastChange = os.clock()
        elseif os.clock() - lastChange >= (oreFarmState.mineStallTime or 1.0) then
            setMouseDown(false)
            task.wait(oreFarmState.mineStallReset or 0.08)
            setMouseDown(true)
            lastChange = os.clock()
        end
        task.wait(0.1)
    end
    setMouseDown(false)
    endFaceTarget()
end

local function oreFarmLoop(sessionId)
    if oreFarmState.running then
        if sessionId ~= oreFarmState.session then
            return
        end
    end
    oreFarmState.running = true
    oreFarmState.target = nil
    while oreFarmState.enabled and sessionId == oreFarmState.session do
        local root = getLocalRootPart()
        if not root then
            setMouseDown(false)
            stopAutoMove()
            endFaceTarget()
            task.wait(0.5)
            continue
        end

        if not oreFarmState.target or not oreFarmState.target.model or not oreFarmState.target.model.Parent then
            if os.clock() - oreFarmState.lastScan >= oreFarmState.scanInterval then
                oreFarmState.lastScan = os.clock()
                oreFarmState.target = findClosestOreTarget()
            end
        else
            local remaining = oreFarmState.target.remaining
            if not remaining or not remaining.Parent then
                remaining = findOreRemainingValue(oreFarmState.target.model, oreFarmState.target.oreName)
                oreFarmState.target.remaining = remaining
            end
            local value = remaining and tonumber(remaining.Value) or nil
            if value ~= nil and value <= 0 then
                oreFarmState.target = nil
                oreFarmState.lastScan = 0
            end
        end

        local target = oreFarmState.target
        if not target then
            setMouseDown(false)
            stopAutoMove()
            endFaceTarget()
            task.wait(0.4)
            continue
        end

        target.part = getModelPart(target.model)
        if not target.part then
            stopAutoMove()
            endFaceTarget()
            oreFarmState.target = nil
            task.wait(0.2)
            continue
        end

        local remaining = target.remaining
        if not remaining or not remaining.Parent then
            remaining = findOreRemainingValue(target.model, target.oreName)
            target.remaining = remaining
        end
        local value = remaining and tonumber(remaining.Value) or nil
        if value ~= nil and value <= 0 then
            stopAutoMove()
            endFaceTarget()
            oreFarmState.target = nil
            oreFarmState.lastScan = 0
            task.wait(0.2)
            continue
        end

        local dist = (root.Position - target.part.Position).Magnitude
        if dist > oreFarmState.mineDistance then
            setMouseDown(false)
            local moved = moveToOreTarget(target)
            if not moved then
                oreFarmState.target = nil
                oreFarmState.lastScan = 0
                task.wait(0.1)
                continue
            end
        end

        root = getLocalRootPart()
        if root and (root.Position - target.part.Position).Magnitude <= oreFarmState.mineDistance then
            mineOreTarget(target)
            oreFarmState.target = nil
            oreFarmState.lastScan = 0
        else
            task.wait(0.1)
        end
    end

    setMouseDown(false)
    stopAutoMove()
    endFaceTarget()
    oreFarmState.running = false
end

local function setOreFarmEnabled(state)
    oreFarmState.enabled = state == true
    if not oreFarmState.enabled then
        oreFarmState.session = (oreFarmState.session or 0) + 1
        oreFarmState.target = nil
        setMouseDown(false)
        stopAutoMove()
        endFaceTarget()
        oreFarmState.running = false
        return
    end
    oreFarmState.session = (oreFarmState.session or 0) + 1
    local sessionId = oreFarmState.session
    task.spawn(function()
        oreFarmLoop(sessionId)
    end)
end

local function setOreFarmMineDistance(value)
    local num = tonumber(value)
    if not num then
        return
    end
    oreFarmState.mineDistance = math.clamp(num, 2, 20)
end

local function setOreFarmScanInterval(value)
    local num = tonumber(value)
    if not num then
        return
    end
    oreFarmState.scanInterval = math.clamp(num, 0.2, 5)
end

Farm.oreFarmState = oreFarmState
Farm.setOreFarmEnabled = setOreFarmEnabled
Farm.setOreFarmMineDistance = setOreFarmMineDistance
Farm.setOreFarmScanInterval = setOreFarmScanInterval
Farm.setKeyState = setKeyState
