local Library = {}
Library.__index = Library

-- Services
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Helpers
local function round(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = obj
end

local function padding(parent, pixels)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, pixels)
    pad.PaddingBottom = UDim.new(0, pixels)
    pad.PaddingLeft = UDim.new(0, pixels)
    pad.PaddingRight = UDim.new(0, pixels)
    pad.Parent = parent
end

local function resolveGuiParent()
    if type(gethui) == "function" then
        local ok, value = pcall(gethui)
        if ok and value then
            return value
        end
    end
    return CoreGui
end

local function clampNumber(value, minValue, maxValue)
    return math.clamp(value, minValue, maxValue)
end

local function roundToStep(value, minValue, maxValue, step)
    step = step or 1
    if step <= 0 then
        step = 1
    end
    local snapped = minValue + math.floor(((value - minValue) / step) + 0.5) * step
    return clampNumber(snapped, minValue, maxValue)
end

function Library:CreateWindow(title, options)
    options = options or {}

    local alive = true
    local connections = {}

    local function connect(signal, handler)
        local conn = signal:Connect(handler)
        table.insert(connections, conn)
        return conn
    end

    local function disconnectAll()
        for _, conn in ipairs(connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        table.clear(connections)
    end

    local width = options.Width or 520
    local height = options.Height or 380
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
    local onClose = options.OnClose

    local function canPersist()
        return HttpService and type(readfile) == "function" and type(writefile) == "function"
    end

    local configAutoSave = options.ConfigAutoSave ~= false
    local configKey = tostring(options.ConfigKey or title or "SmugLib")
    configKey = configKey:gsub("[^%w_%-]", "_")
    local configFile = "SmugLib_" .. configKey .. ".json"
    local configData = {}
    local configBindings = {}
    local applyingConfig = false

    local function loadConfig()
        if not canPersist() then
            return
        end
        local raw = nil
        if type(isfile) == "function" then
            if isfile(configFile) then
                local ok, data = pcall(readfile, configFile)
                if ok then
                    raw = data
                end
            end
        else
            local ok, data = pcall(readfile, configFile)
            if ok then
                raw = data
            end
        end
        if raw and raw ~= "" then
            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(raw)
            end)
            if ok and type(decoded) == "table" then
                configData = decoded
            end
        end
    end

    local function saveConfig(force)
        if not canPersist() then
            return
        end
        if not force and not configAutoSave then
            return
        end
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(configData)
        end)
        if ok and encoded then
            pcall(function()
                writefile(configFile, encoded)
            end)
        end
    end

    local function applyConfigData(useDefaults)
        applyingConfig = true
        for key, binding in pairs(configBindings) do
            local value = configData[key]
            if value == nil and useDefaults then
                value = binding.default
            end
            if value ~= nil then
                binding.set(value, true)
            end
        end
        applyingConfig = false
    end

    loadConfig()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SmugLibCore"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = resolveGuiParent()

    local window = {}

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, width, 0, height)
    main.Position = UDim2.new(0.5, -math.floor(width / 2), 1, 20)
    main.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    main.BorderSizePixel = 0
    main.Parent = screenGui
    round(main, 10)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 34)
    top.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    top.BorderSizePixel = 0
    top.Parent = main
    round(top, 10)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = tostring(title or "SmugLib")
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Size = UDim2.new(1, -110, 1, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = top

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 34, 1, 0)
    closeButton.Position = UDim2.new(1, -34, 0, 0)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 15
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 46, 46)
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.BorderSizePixel = 0
    closeButton.Parent = top
    round(closeButton, 8)

    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 34, 1, 0)
    minimizeButton.Position = UDim2.new(1, -70, 0, 0)
    minimizeButton.Text = "-"
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.TextSize = 16
    minimizeButton.BackgroundColor3 = Color3.fromRGB(96, 96, 96)
    minimizeButton.TextColor3 = Color3.new(1, 1, 1)
    minimizeButton.BorderSizePixel = 0
    minimizeButton.Parent = top
    round(minimizeButton, 8)

    local restoreButton = Instance.new("TextButton")
    restoreButton.Text = "^"
    restoreButton.Size = UDim2.new(0, 46, 0, 46)
    restoreButton.Position = UDim2.new(0, 20, 1, -70)
    restoreButton.Visible = false
    restoreButton.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
    restoreButton.TextColor3 = Color3.new(1, 1, 1)
    restoreButton.Font = Enum.Font.GothamBold
    restoreButton.TextSize = 20
    restoreButton.BorderSizePixel = 0
    restoreButton.Parent = screenGui
    round(restoreButton, 8)

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 1, -34)
    body.Position = UDim2.new(0, 0, 0, 34)
    body.BackgroundTransparency = 1
    body.Parent = main
    padding(body, 8)

    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Size = UDim2.new(1, 0, 0, 28)
    tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabBar.ScrollBarThickness = 4
    tabBar.VerticalScrollBarInset = Enum.ScrollBarInset.None
    tabBar.HorizontalScrollBarInset = Enum.ScrollBarInset.Always
    tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel = 0
    tabBar.Parent = body

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -34)
    tabContent.Position = UDim2.new(0, 0, 0, 34)
    tabContent.BackgroundTransparency = 1
    tabContent.Parent = body

    local toastHost = Instance.new("Frame")
    toastHost.Size = UDim2.new(1, 0, 1, 0)
    toastHost.BackgroundTransparency = 1
    toastHost.BorderSizePixel = 0
    toastHost.ZIndex = 50
    toastHost.Parent = screenGui

    local toastLayout = Instance.new("UIListLayout")
    toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    toastLayout.Padding = UDim.new(0, 6)
    toastLayout.Parent = toastHost

    local toastPadding = Instance.new("UIPadding")
    toastPadding.PaddingTop = UDim.new(0, 14)
    toastPadding.Parent = toastHost

    local function notify(text, duration)
        if not alive then
            return
        end

        duration = duration or 3

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 280, 0, 40)
        frame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
        frame.BackgroundTransparency = 0.12
        frame.BorderSizePixel = 0
        frame.Parent = toastHost
        frame.ZIndex = 51
        round(frame, 8)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -16, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = tostring(text)
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextWrapped = true
        label.ZIndex = 52
        label.Parent = frame

        frame.Position = UDim2.new(0.5, -140, 0, -60)

        local fadeIn = TweenService:Create(
            frame,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, -140, 0, 0) }
        )
        fadeIn:Play()

        task.delay(duration, function()
            if not frame.Parent then
                return
            end
            local fadeOut = TweenService:Create(
                frame,
                TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { BackgroundTransparency = 1 }
            )
            fadeOut:Play()
            task.wait(0.26)
            if frame then
                frame:Destroy()
            end
        end)
    end

    local function makeDraggable(handle, target)
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPos = nil

        connect(handle.InputBegan, function(input)
            if not alive then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = target.Position

            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if endConn then
                        endConn:Disconnect()
                    end
                end
            end)
            table.insert(connections, endConn)
        end)

        connect(handle.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        connect(UIS.InputChanged, function(input)
            if not alive or not dragging then
                return
            end
            if input ~= dragInput or not dragStart or not startPos then
                return
            end

            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end)
    end

    local function destroyWindow()
        if not alive then
            return
        end
        alive = false
        if onClose then
            pcall(onClose)
        end
        disconnectAll()
        if screenGui then
            screenGui:Destroy()
        end
    end

    local minimized = false

    local function setMinimized(value)
        minimized = value
        main.Visible = not minimized
        restoreButton.Visible = minimized
    end

    connect(closeButton.MouseButton1Click, destroyWindow)
    connect(minimizeButton.MouseButton1Click, function()
        setMinimized(true)
    end)
    connect(restoreButton.MouseButton1Click, function()
        setMinimized(false)
    end)

    connect(UIS.InputBegan, function(input, gameProcessed)
        if gameProcessed or not alive then
            return
        end
        if input.KeyCode == toggleKey then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)

    makeDraggable(top, main)
    makeDraggable(restoreButton, restoreButton)

    connect(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        tabBar.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 8, 0, 0)
    end)

    TweenService:Create(
        main,
        TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -math.floor(width / 2), 0.5, -math.floor(height / 2)) }
    ):Play()

    local tabs = {}
    local currentTabButton = nil

    local function setActiveTab(tabButton)
        if currentTabButton == tabButton then
            return
        end

        if currentTabButton and tabs[currentTabButton] then
            tabs[currentTabButton].Frame.Visible = false
            currentTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end

        currentTabButton = tabButton

        if tabs[tabButton] then
            tabs[tabButton].Frame.Visible = true
            tabButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
        end
    end

    function window:SetTitle(newTitle)
        titleLabel.Text = tostring(newTitle or "SmugLib")
    end

    function window:SetToggleKey(keyCode)
        if typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
            toggleKey = keyCode
            return true
        end
        return false
    end

    function window:Notify(text, duration)
        notify(text, duration)
    end

    function window:Destroy()
        destroyWindow()
    end

    function window:SetOnClose(callback)
        onClose = callback
    end

    function window:GetConfig()
        return configData
    end

    function window:SetConfig(data, applyNow)
        if type(data) ~= "table" then
            return false
        end
        configData = data
        if applyNow ~= false then
            applyConfigData(false)
        end
        saveConfig(true)
        return true
    end

    function window:LoadConfig()
        loadConfig()
        applyConfigData(false)
        return true
    end

    function window:SaveConfig()
        saveConfig(true)
        return true
    end

    function window:ClearConfig()
        configData = {}
        saveConfig(true)
        applyConfigData(true)
        return true
    end

    function window:ExportConfig()
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(configData)
        end)
        if ok then
            return encoded
        end
        return nil
    end

    function window:ImportConfig(jsonString, applyNow)
        if type(jsonString) ~= "string" then
            return false
        end
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(jsonString)
        end)
        if ok and type(decoded) == "table" then
            configData = decoded
            if applyNow ~= false then
                applyConfigData(false)
            end
            saveConfig(true)
            return true
        end
        return false
    end

    function window:SetConfigKey(newKey, keepCurrent)
        if not newKey or newKey == "" then
            return false
        end
        local nextKey = tostring(newKey):gsub("[^%w_%-]", "_")
        if nextKey == configKey then
            return true
        end
        configKey = nextKey
        configFile = "SmugLib_" .. configKey .. ".json"
        if keepCurrent then
            saveConfig(true)
        else
            configData = {}
            loadConfig()
            applyConfigData(false)
        end
        return true
    end

    function window:Folder(name)
        local folderName = tostring(name or "Tab")
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(0, 110, 1, 0)
        tabButton.Text = folderName
        tabButton.Font = Enum.Font.Gotham
        tabButton.TextSize = 14
        tabButton.TextColor3 = Color3.new(1, 1, 1)
        tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        tabButton.BorderSizePixel = 0
        tabButton.Parent = tabBar
        round(tabButton, 6)

        local folderFrame = Instance.new("ScrollingFrame")
        folderFrame.Size = UDim2.new(1, 0, 1, 0)
        folderFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        folderFrame.BackgroundTransparency = 1
        folderFrame.BorderSizePixel = 0
        folderFrame.ScrollBarThickness = 6
        folderFrame.Visible = false
        folderFrame.Parent = tabContent
        padding(folderFrame, 4)

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = folderFrame

        connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            folderFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)

        tabs[tabButton] = {
            Frame = folderFrame,
        }

        connect(tabButton.MouseButton1Click, function()
            setActiveTab(tabButton)
        end)

        if not currentTabButton then
            setActiveTab(tabButton)
        end

        local elements = {}

        function elements:Label(text)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.Text = tostring(text or "")
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(205, 205, 205)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = folderFrame

            return {
                SetText = function(_, newText)
                    label.Text = tostring(newText or "")
                end,
                Destroy = function()
                    label:Destroy()
                end,
            }
        end

        function elements:Separator(text)
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 18)
            holder.BackgroundTransparency = 1
            holder.BorderSizePixel = 0
            holder.Parent = folderFrame

            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 0.5, 0)
            line.BackgroundColor3 = Color3.fromRGB(78, 78, 78)
            line.BorderSizePixel = 0
            line.Parent = holder

            if text and text ~= "" then
                local textLabel = Instance.new("TextLabel")
                textLabel.Size = UDim2.new(0, 120, 1, 0)
                textLabel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
                textLabel.Position = UDim2.new(0, 8, 0, 0)
                textLabel.Font = Enum.Font.GothamBold
                textLabel.Text = tostring(text)
                textLabel.TextSize = 11
                textLabel.TextColor3 = Color3.fromRGB(165, 165, 165)
                textLabel.Parent = holder
            end
        end

        function elements:Button(text, callback)
            local enabled = true

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 0, 32)
            button.Text = tostring(text or "Button")
            button.Font = Enum.Font.Gotham
            button.TextSize = 14
            button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            button.TextColor3 = Color3.new(1, 1, 1)
            button.BorderSizePixel = 0
            button.Parent = folderFrame
            round(button, 6)

            connect(button.MouseButton1Click, function()
                if not alive or not enabled then
                    return
                end
                if callback then
                    callback()
                end
            end)

            return {
                SetText = function(_, newText)
                    button.Text = tostring(newText or "Button")
                end,
                SetEnabled = function(_, value)
                    enabled = not not value
                    button.AutoButtonColor = enabled
                    button.BackgroundTransparency = enabled and 0 or 0.4
                end,
                Destroy = function()
                    button:Destroy()
                end,
            }
        end

        function elements:Toggle(text, callback, defaultState)
            local state = defaultState == true
            local displayText = tostring(text or "Toggle")

            local toggleButton = Instance.new("TextButton")
            toggleButton.Size = UDim2.new(1, 0, 0, 32)
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            toggleButton.TextColor3 = Color3.new(1, 1, 1)
            toggleButton.Font = Enum.Font.Gotham
            toggleButton.TextSize = 14
            toggleButton.BorderSizePixel = 0
            toggleButton.Parent = folderFrame
            round(toggleButton, 6)

            local function updateText()
                toggleButton.Text = string.format("%s : %s", displayText, state and "ON" or "OFF")
            end

            local function setState(newState, triggerCallback)
                state = not not newState
                updateText()
                if triggerCallback and callback then
                    callback(state)
                end
            end

            updateText()

            connect(toggleButton.MouseButton1Click, function()
                if not alive then
                    return
                end
                setState(not state, true)
            end)

            return {
                Set = function(_, newState)
                    setState(newState, false)
                end,
                Get = function()
                    return state
                end,
                Toggle = function()
                    setState(not state, true)
                end,
                SetText = function(_, newText)
                    displayText = tostring(newText or "Toggle")
                    updateText()
                end,
                Destroy = function()
                    toggleButton:Destroy()
                end,
            }
        end

        function elements:Checkbox(text, callback, defaultState)
            local displayText = tostring(text or "Checkbox")
            local configKeyName = string.format("checkbox:%s:%s", folderName, displayText)
            local savedState = configData[configKeyName]
            local state = savedState ~= nil and (savedState == true) or (defaultState == true)

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 28)
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0
            row.Parent = folderFrame

            local box = Instance.new("TextButton")
            box.Size = UDim2.new(0, 22, 0, 22)
            box.Position = UDim2.new(0, 0, 0, 3)
            box.BackgroundColor3 = state and Color3.fromRGB(76, 132, 76) or Color3.fromRGB(60, 60, 60)
            box.TextColor3 = Color3.new(1, 1, 1)
            box.Font = Enum.Font.GothamBold
            box.TextSize = 14
            box.BorderSizePixel = 0
            box.Parent = row
            round(box, 5)

            local labelButton = Instance.new("TextButton")
            labelButton.Size = UDim2.new(1, -30, 1, 0)
            labelButton.Position = UDim2.new(0, 30, 0, 0)
            labelButton.BackgroundTransparency = 1
            labelButton.TextXAlignment = Enum.TextXAlignment.Left
            labelButton.TextColor3 = Color3.new(1, 1, 1)
            labelButton.Font = Enum.Font.Gotham
            labelButton.TextSize = 14
            labelButton.Text = displayText
            labelButton.BorderSizePixel = 0
            labelButton.AutoButtonColor = false
            labelButton.Parent = row

            local function updateVisual()
                box.Text = state and "X" or ""
                box.BackgroundColor3 = state and Color3.fromRGB(76, 132, 76) or Color3.fromRGB(60, 60, 60)
            end

            local function setState(newState, triggerCallback)
                state = not not newState
                updateVisual()
                configData[configKeyName] = state
                if not applyingConfig then
                    saveConfig(false)
                end
                if triggerCallback and callback then
                    callback(state)
                end
            end

            updateVisual()
            configBindings[configKeyName] = {
                set = setState,
                default = defaultState == true,
            }
            if savedState ~= nil and callback then
                callback(state)
            end

            connect(box.MouseButton1Click, function()
                if not alive then
                    return
                end
                setState(not state, true)
            end)

            connect(labelButton.MouseButton1Click, function()
                if not alive then
                    return
                end
                setState(not state, true)
            end)

            return {
                Set = function(_, newState)
                    setState(newState, false)
                end,
                Get = function()
                    return state
                end,
                SetText = function(_, newText)
                    displayText = tostring(newText or "Checkbox")
                    labelButton.Text = displayText
                end,
                Destroy = function()
                    row:Destroy()
                end,
            }
        end

        function elements:Slider(text, minValue, maxValue, defaultValue, callback, step)
            minValue = tonumber(minValue) or 0
            maxValue = tonumber(maxValue) or 100
            if minValue > maxValue then
                minValue, maxValue = maxValue, minValue
            end

            step = tonumber(step) or 1
            if step <= 0 then
                step = 1
            end

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, 0, 0, 42)
            sliderFrame.BackgroundTransparency = 1
            sliderFrame.BorderSizePixel = 0
            sliderFrame.Parent = folderFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 16)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sliderFrame

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, 0, 0, 12)
            bar.Position = UDim2.new(0, 0, 0, 22)
            bar.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
            bar.BorderSizePixel = 0
            bar.Parent = sliderFrame
            round(bar, 6)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(110, 150, 255)
            fill.BorderSizePixel = 0
            fill.Parent = bar
            round(fill, 6)

            local value = clampNumber(tonumber(defaultValue) or minValue, minValue, maxValue)
            value = roundToStep(value, minValue, maxValue, step)

            local dragging = false

            local function setValue(newValue, triggerCallback)
                local range = maxValue - minValue
                value = roundToStep(newValue, minValue, maxValue, step)

                local percent = 0
                if range > 0 then
                    percent = (value - minValue) / range
                end

                fill.Size = UDim2.new(percent, 0, 1, 0)
                label.Text = string.format("%s : %s", tostring(text or "Slider"), tostring(value))

                if triggerCallback and callback then
                    callback(value)
                end
            end

            local function setFromPointer(pointerX)
                local widthPixels = math.max(bar.AbsoluteSize.X, 1)
                local percent = clampNumber((pointerX - bar.AbsolutePosition.X) / widthPixels, 0, 1)
                setValue(minValue + ((maxValue - minValue) * percent), true)
            end

            connect(bar.InputBegan, function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                dragging = true
                setFromPointer(input.Position.X)
            end)

            connect(UIS.InputChanged, function(input)
                if not dragging then
                    return
                end
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    setFromPointer(input.Position.X)
                end
            end)

            connect(UIS.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            setValue(value, false)

            return {
                Set = function(_, newValue)
                    setValue(tonumber(newValue) or value, false)
                end,
                Get = function()
                    return value
                end,
                Destroy = function()
                    sliderFrame:Destroy()
                end,
            }
        end

        function elements:Textbox(placeholder, callback, defaultText)
            local box = Instance.new("TextBox")
            box.PlaceholderText = tostring(placeholder or "Enter text")
            box.Text = tostring(defaultText or "")
            box.ClearTextOnFocus = false
            box.Size = UDim2.new(1, 0, 0, 32)
            box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            box.BorderSizePixel = 0
            box.TextColor3 = Color3.new(1, 1, 1)
            box.Font = Enum.Font.Gotham
            box.TextSize = 14
            box.Parent = folderFrame
            round(box, 6)

            connect(box.FocusLost, function(enterPressed)
                if not alive or not callback then
                    return
                end
                callback(box.Text, enterPressed)
            end)

            return {
                Set = function(_, value)
                    box.Text = tostring(value or "")
                end,
                Get = function()
                    return box.Text
                end,
                Destroy = function()
                    box:Destroy()
                end,
            }
        end

        function elements:Bind(text, key, callback)
            local current = key or Enum.KeyCode.E
            local listening = false
            local displayText = tostring(text or "Bind")

            local bindButton = Instance.new("TextButton")
            bindButton.Size = UDim2.new(1, 0, 0, 32)
            bindButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            bindButton.TextColor3 = Color3.new(1, 1, 1)
            bindButton.Font = Enum.Font.Gotham
            bindButton.TextSize = 14
            bindButton.BorderSizePixel = 0
            bindButton.Parent = folderFrame
            round(bindButton, 6)

            local function updateText()
                bindButton.Text = string.format("%s : %s", displayText, tostring(current.Name))
            end

            updateText()

            connect(bindButton.MouseButton1Click, function()
                listening = true
                bindButton.Text = string.format("%s : ...", displayText)
            end)

            connect(UIS.InputBegan, function(input, gameProcessed)
                if gameProcessed or not alive then
                    return
                end

                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        current = input.KeyCode
                        listening = false
                        updateText()
                    end
                    return
                end

                if input.KeyCode == current and callback then
                    callback()
                end
            end)

            return {
                SetKey = function(_, newKey)
                    if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
                        current = newKey
                        updateText()
                    end
                end,
                GetKey = function()
                    return current
                end,
                Destroy = function()
                    bindButton:Destroy()
                end,
            }
        end

        function elements:Dropdown(name, optionsList, callback, defaultValue)
            optionsList = optionsList or {}
            local displayName = tostring(name or "Dropdown")
            local selected = defaultValue
            local open = false

            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 32)
            holder.BackgroundTransparency = 1
            holder.BorderSizePixel = 0
            holder.Parent = folderFrame

            local dropButton = Instance.new("TextButton")
            dropButton.Size = UDim2.new(1, 0, 0, 32)
            dropButton.TextColor3 = Color3.new(1, 1, 1)
            dropButton.Font = Enum.Font.Gotham
            dropButton.TextSize = 14
            dropButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            dropButton.BorderSizePixel = 0
            dropButton.Parent = holder
            round(dropButton, 6)

            local dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(1, 0, 0, 0)
            dropFrame.Position = UDim2.new(0, 0, 0, 36)
            dropFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
            dropFrame.BorderSizePixel = 0
            dropFrame.Visible = false
            dropFrame.Parent = holder
            round(dropFrame, 6)

            local dropScroll = Instance.new("ScrollingFrame")
            dropScroll.Size = UDim2.new(1, 0, 1, 0)
            dropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            dropScroll.ScrollBarThickness = 4
            dropScroll.BackgroundTransparency = 1
            dropScroll.BorderSizePixel = 0
            dropScroll.Parent = dropFrame
            padding(dropScroll, 4)

            local dropLayout = Instance.new("UIListLayout")
            dropLayout.FillDirection = Enum.FillDirection.Vertical
            dropLayout.Padding = UDim.new(0, 4)
            dropLayout.Parent = dropScroll

            local optionButtons = {}

            local function updateButtonText()
                if selected ~= nil then
                    dropButton.Text = string.format("%s : %s v", displayName, tostring(selected))
                else
                    dropButton.Text = string.format("%s v", displayName)
                end
            end

            local function updateDropSize()
                if not open then
                    holder.Size = UDim2.new(1, 0, 0, 32)
                    dropFrame.Visible = false
                    return
                end

                local expandedHeight = math.min((#optionsList * 30) + 8, 140)
                holder.Size = UDim2.new(1, 0, 0, 36 + expandedHeight)
                dropFrame.Size = UDim2.new(1, 0, 0, expandedHeight)
                dropFrame.Visible = true
            end

            local function selectOption(value, triggerCallback)
                selected = value
                updateButtonText()
                open = false
                updateDropSize()
                if triggerCallback and callback then
                    callback(value)
                end
            end

            local function rebuildOptions()
                for _, button in ipairs(optionButtons) do
                    button:Destroy()
                end
                table.clear(optionButtons)

                for _, option in ipairs(optionsList) do
                    local optionButton = Instance.new("TextButton")
                    optionButton.Text = tostring(option)
                    optionButton.Size = UDim2.new(1, 0, 0, 26)
                    optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    optionButton.TextColor3 = Color3.new(1, 1, 1)
                    optionButton.Font = Enum.Font.Gotham
                    optionButton.TextSize = 13
                    optionButton.BorderSizePixel = 0
                    optionButton.Parent = dropScroll
                    round(optionButton, 5)

                    table.insert(optionButtons, optionButton)

                    connect(optionButton.MouseButton1Click, function()
                        if not alive then
                            return
                        end
                        selectOption(option, true)
                    end)
                end
            end

            connect(dropLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                dropScroll.CanvasSize = UDim2.new(0, 0, 0, dropLayout.AbsoluteContentSize.Y + 8)
            end)

            connect(dropButton.MouseButton1Click, function()
                if not alive then
                    return
                end
                open = not open
                updateDropSize()
            end)

            rebuildOptions()
            updateButtonText()
            updateDropSize()

            if defaultValue ~= nil then
                selectOption(defaultValue, false)
            end

            return {
                Set = function(_, value)
                    selectOption(value, false)
                end,
                Get = function()
                    return selected
                end,
                SetOptions = function(_, newOptions)
                    optionsList = newOptions or {}
                    rebuildOptions()
                    updateDropSize()
                end,
                Open = function()
                    open = true
                    updateDropSize()
                end,
                Close = function()
                    open = false
                    updateDropSize()
                end,
                Destroy = function()
                    holder:Destroy()
                end,
            }
        end

        return elements
    end

    notify(string.format("%s loaded successfully!", tostring(title or "SmugLib")), 2.8)
    return window
end

return Library
