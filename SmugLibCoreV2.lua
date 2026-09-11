local Library = {}
Library.__index = Library

-- Services
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- ---------- Theme ----------
local Theme = {
    Background     = Color3.fromRGB(16, 16, 20),
    Panel          = Color3.fromRGB(22, 22, 28),
    SectionBody    = Color3.fromRGB(20, 20, 26),
    SectionHeader  = Color3.fromRGB(56, 68, 150),
    Input          = Color3.fromRGB(30, 30, 40),
    InputHover     = Color3.fromRGB(42, 42, 55),
    Accent         = Color3.fromRGB(88, 104, 220),
    AccentLight    = Color3.fromRGB(120, 135, 240),
    Text           = Color3.fromRGB(235, 235, 245),
    TextDim        = Color3.fromRGB(150, 150, 165),
    Border         = Color3.fromRGB(45, 45, 58),
    Close          = Color3.fromRGB(190, 45, 55),
    CloseHover     = Color3.fromRGB(220, 60, 70),
}

-- ---------- Helpers ----------
local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local function resolveGuiParent()
    if type(gethui) == "function" then
        local ok, value = pcall(gethui)
        if ok and value then return value end
    end
    return CoreGui
end

local function clampNumber(v, mn, mx) return math.clamp(v, mn, mx) end

local function roundToStep(value, minValue, maxValue, step)
    step = step or 1
    if step <= 0 then step = 1 end
    local snapped = minValue + math.floor(((value - minValue) / step) + 0.5) * step
    return clampNumber(snapped, minValue, maxValue)
end

local function keyLabel(key)
    if not key then return "?" end
    if typeof(key) == "EnumItem" then
        if key == Enum.UserInputType.MouseButton1 then return "M1" end
        if key == Enum.UserInputType.MouseButton2 then return "M2" end
        if key == Enum.UserInputType.MouseButton3 then return "M3" end
        return key.Name
    end
    return tostring(key)
end

local function normalizeInput(k)
    if typeof(k) == "EnumItem" then return k end
    if type(k) == "string" then
        if Enum.KeyCode[k] then return Enum.KeyCode[k] end
        if Enum.UserInputType[k] then return Enum.UserInputType[k] end
    end
    return nil
end

-- ==========================================================================
--  Element factory
-- ==========================================================================
local function buildElements(ctx, parent)
    local elements = {}
    local order = 0
    local function nextOrder() order = order + 1; return order end

    local function scopeKey(name)
        local scope = ctx.scope or ""
        return string.format("%s%s:%s", scope, ctx.folderName, tostring(name))
    end

    -- ------------------------------------------------------------------
    -- Section
    -- ------------------------------------------------------------------
    function elements:Section(title)
        local section = Instance.new("Frame")
        section.BackgroundColor3 = Theme.SectionBody
        section.BorderSizePixel = 0
        section.Size = UDim2.new(1, 0, 0, 0)
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.LayoutOrder = nextOrder()
        section.Parent = parent
        round(section, 4)

        local outline = Instance.new("UIStroke")
        outline.Color = Theme.Border
        outline.Thickness = 1
        outline.Transparency = 0.35
        outline.Parent = section

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 20)
        header.BackgroundColor3 = Theme.SectionHeader
        header.BorderSizePixel = 0
        header.Parent = section
        round(header, 4)

        local headerCover = Instance.new("Frame")
        headerCover.Size = UDim2.new(1, 0, 0, 8)
        headerCover.Position = UDim2.new(0, 0, 1, -8)
        headerCover.BackgroundColor3 = Theme.SectionHeader
        headerCover.BorderSizePixel = 0
        headerCover.Parent = header

        local headerTitle = Instance.new("TextLabel")
        headerTitle.Text = string.upper(tostring(title or "SECTION"))
        headerTitle.Font = Enum.Font.GothamBold
        headerTitle.TextSize = 11
        headerTitle.TextColor3 = Color3.new(1, 1, 1)
        headerTitle.BackgroundTransparency = 1
        headerTitle.Size = UDim2.new(1, -12, 1, 0)
        headerTitle.Position = UDim2.new(0, 8, 0, 0)
        headerTitle.TextXAlignment = Enum.TextXAlignment.Left
        headerTitle.Parent = header

        local content = Instance.new("Frame")
        content.BackgroundTransparency = 1
        content.Size = UDim2.new(1, 0, 0, 0)
        content.Position = UDim2.new(0, 0, 0, 20)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.Parent = section

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingRight = UDim.new(0, 6)
        pad.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = content

        local subCtx = {}
        for k, v in pairs(ctx) do subCtx[k] = v end
        subCtx.scope = (ctx.scope or "") .. tostring(title or "sec") .. ":"
        return buildElements(subCtx, content)
    end

    -- ------------------------------------------------------------------
    -- Label
    -- ------------------------------------------------------------------
    function elements:Label(text)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 18)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.Text = tostring(text or "")
        label.TextSize = 12
        label.TextColor3 = Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.LayoutOrder = nextOrder()
        label.Parent = parent
        return {
            SetText = function(_, v) label.Text = tostring(v or "") end,
            Destroy = function() label:Destroy() end,
        }
    end

    -- ------------------------------------------------------------------
    -- Separator
    -- ------------------------------------------------------------------
    function elements:Separator(text)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 14)
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = nextOrder()
        holder.Parent = parent

        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3 = Theme.Border
        line.BorderSizePixel = 0
        line.Parent = holder

        if text and text ~= "" then
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, 0, 1, 0)
            lbl.AutomaticSize = Enum.AutomaticSize.X
            lbl.BackgroundColor3 = Theme.SectionBody
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.Font = Enum.Font.GothamBold
            lbl.Text = " " .. tostring(text) .. " "
            lbl.TextSize = 10
            lbl.TextColor3 = Theme.TextDim
            lbl.Parent = holder
        end

        return { Destroy = function() holder:Destroy() end }
    end

    -- ------------------------------------------------------------------
    -- Button
    -- ------------------------------------------------------------------
    function elements:Button(text, callback)
        local enabled = true
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 26)
        button.Text = tostring(text or "Button")
        button.Font = Enum.Font.Gotham
        button.TextSize = 12
        button.BackgroundColor3 = Theme.Input
        button.TextColor3 = Theme.Text
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.LayoutOrder = nextOrder()
        button.Parent = parent
        round(button, 3)

        local outline = Instance.new("UIStroke")
        outline.Color = Theme.Border
        outline.Thickness = 1
        outline.Parent = button

        ctx.connect(button.MouseEnter, function()
            if enabled then button.BackgroundColor3 = Theme.InputHover end
        end)
        ctx.connect(button.MouseLeave, function()
            button.BackgroundColor3 = Theme.Input
        end)
        ctx.connect(button.MouseButton1Click, function()
            if not ctx.alive() or not enabled then return end
            if callback then callback() end
        end)

        return {
            SetText = function(_, v) button.Text = tostring(v or "Button") end,
            SetEnabled = function(_, v)
                enabled = not not v
                button.BackgroundTransparency = enabled and 0 or 0.4
            end,
            Destroy = function() button:Destroy() end,
        }
    end

    -- ------------------------------------------------------------------
    -- Checkbox / Toggle
    -- ------------------------------------------------------------------
    local function makeCheckboxRow(text, callback, defaultState, bindKey, configKeyName)
        local displayText = tostring(text or "Checkbox")
        local savedState = ctx.configData[configKeyName]
        local state = (savedState ~= nil) and (savedState == true) or (defaultState == true)

        -- Bind (podpora KeyCode i Mouse)
        local currentBind = normalizeInput(bindKey) or nil
        local listening = false

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextOrder()
        row.Parent = parent

        local box = Instance.new("TextButton")
        box.Size = UDim2.new(0, 16, 0, 16)
        box.Position = UDim2.new(0, 0, 0, 3)
        box.BackgroundColor3 = Theme.Input
        box.TextColor3 = Color3.new(1, 1, 1)
        box.Font = Enum.Font.GothamBold
        box.TextSize = 11
        box.BorderSizePixel = 0
        box.AutoButtonColor = false
        box.Parent = row
        round(box, 3)

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Theme.Border
        boxStroke.Thickness = 1
        boxStroke.Parent = box

        local label = Instance.new("TextButton")
        label.Size = UDim2.new(1, -26, 1, 0)
        label.Position = UDim2.new(0, 24, 0, 0)
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.Text = displayText
        label.BorderSizePixel = 0
        label.AutoButtonColor = false
        label.Parent = row

        local bindBadge
        if currentBind then
            bindBadge = Instance.new("TextButton")
            bindBadge.Size = UDim2.new(0, 34, 0, 16)
            bindBadge.Position = UDim2.new(1, -34, 0, 3)
            bindBadge.BackgroundColor3 = Theme.Input
            bindBadge.TextColor3 = Theme.TextDim
            bindBadge.Font = Enum.Font.GothamBold
            bindBadge.TextSize = 10
            bindBadge.Text = keyLabel(currentBind)
            bindBadge.BorderSizePixel = 0
            bindBadge.AutoButtonColor = false
            bindBadge.Parent = row
            round(bindBadge, 3)
            label.Size = UDim2.new(1, -64, 1, 0)
        end

        local function updateVisual()
            if state then
                box.Text = "✕"
                box.BackgroundColor3 = Theme.Accent
                boxStroke.Color = Theme.AccentLight
            else
                box.Text = ""
                box.BackgroundColor3 = Theme.Input
                boxStroke.Color = Theme.Border
            end
        end

        local function setState(v, trigger)
            state = not not v
            updateVisual()
            ctx.configData[configKeyName] = state
            if not ctx.isApplying() then ctx.saveConfig(false) end
            if trigger and callback then callback(state) end
        end

        updateVisual()
        ctx.configBindings[configKeyName] = { set = setState, default = defaultState == true }
        if savedState ~= nil and callback then callback(state) end

        ctx.connect(box.MouseButton1Click, function()
            if not ctx.alive() then return end
            setState(not state, true)
        end)
        ctx.connect(label.MouseButton1Click, function()
            if not ctx.alive() then return end
            setState(not state, true)
        end)

        -- Bind badge interakce
        if bindBadge then
            ctx.connect(bindBadge.MouseButton1Click, function()
                if not ctx.alive() then return end
                listening = true
                bindBadge.Text = "..."
                bindBadge.BackgroundColor3 = Theme.Accent
            end)
        end

        -- Globální handler pro bind (i spouštění)
        ctx.connect(UIS.InputBegan, function(input, gameProcessed)
            if not ctx.alive() then return end
            if listening then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    currentBind = input.KeyCode
                elseif input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.MouseButton2
                    or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    currentBind = input.UserInputType
                else
                    return
                end
                listening = false
                if bindBadge then
                    bindBadge.BackgroundColor3 = Theme.Input
                    bindBadge.Text = keyLabel(currentBind)
                end
                ctx.configData[configKeyName .. ":bind"] = currentBind.Name
                if not ctx.isApplying() then ctx.saveConfig(false) end
                return
            end
            if gameProcessed then return end
            if not currentBind then return end

            local matches = false
            if typeof(currentBind) == "EnumItem" and currentBind.EnumType == Enum.KeyCode then
                matches = (input.KeyCode == currentBind)
            elseif typeof(currentBind) == "EnumItem" and currentBind.EnumType == Enum.UserInputType then
                matches = (input.UserInputType == currentBind)
            end
            if matches then
                setState(not state, true)
            end
        end)

        return {
            Set = function(_, v) setState(v, false) end,
            Get = function() return state end,
            Toggle = function() setState(not state, true) end,
            SetText = function(_, v) displayText = tostring(v or "Checkbox"); label.Text = displayText end,
            SetKey = function(_, k)
                local n = normalizeInput(k)
                if n then
                    currentBind = n
                    if bindBadge then bindBadge.Text = keyLabel(n) end
                end
            end,
            GetKey = function() return currentBind end,
            Destroy = function() row:Destroy() end,
        }
    end

    function elements:Checkbox(text, callback, defaultState, bindKey)
        return makeCheckboxRow(text, callback, defaultState, bindKey, scopeKey("cb:" .. tostring(text)))
    end

    function elements:Toggle(text, callback, defaultState, bindKey)
        return makeCheckboxRow(text, callback, defaultState, bindKey, scopeKey("tg:" .. tostring(text)))
    end

    -- ------------------------------------------------------------------
    -- Slider
    -- ------------------------------------------------------------------
    function elements:Slider(text, minValue, maxValue, defaultValue, callback, step)
        minValue = tonumber(minValue) or 0
        maxValue = tonumber(maxValue) or 100
        if minValue > maxValue then minValue, maxValue = maxValue, minValue end
        step = tonumber(step) or 1
        if step <= 0 then step = 1 end

        local configKeyName = scopeKey("sl:" .. tostring(text))
        local saved = tonumber(ctx.configData[configKeyName])
        defaultValue = tonumber(defaultValue) or minValue

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 36)
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = nextOrder()
        holder.Parent = parent

        local topRow = Instance.new("Frame")
        topRow.Size = UDim2.new(1, 0, 0, 14)
        topRow.BackgroundTransparency = 1
        topRow.Parent = holder

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -80, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = tostring(text or "Slider")
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextColor3 = Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = topRow

        local valueText = Instance.new("TextLabel")
        valueText.Size = UDim2.new(0, 80, 1, 0)
        valueText.Position = UDim2.new(1, -80, 0, 0)
        valueText.BackgroundTransparency = 1
        valueText.Text = ""
        valueText.Font = Enum.Font.Gotham
        valueText.TextSize = 12
        valueText.TextColor3 = Theme.TextDim
        valueText.TextXAlignment = Enum.TextXAlignment.Right
        valueText.Parent = topRow

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 16)
        bar.Position = UDim2.new(0, 0, 0, 18)
        bar.BackgroundColor3 = Theme.Input
        bar.BorderSizePixel = 0
        bar.Parent = holder
        round(bar, 3)

        local barStroke = Instance.new("UIStroke")
        barStroke.Color = Theme.Border
        barStroke.Thickness = 1
        barStroke.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        round(fill, 3)

        local fillText = Instance.new("TextLabel")
        fillText.Size = UDim2.new(1, 0, 1, 0)
        fillText.BackgroundTransparency = 1
        fillText.Text = ""
        fillText.Font = Enum.Font.GothamBold
        fillText.TextSize = 10
        fillText.TextColor3 = Color3.new(1, 1, 1)
        fillText.TextXAlignment = Enum.TextXAlignment.Center
        fillText.ZIndex = 2
        fillText.Parent = bar

        local value = clampNumber(defaultValue, minValue, maxValue)
        value = roundToStep(value, minValue, maxValue, step)
        if saved then
            value = roundToStep(clampNumber(saved, minValue, maxValue), minValue, maxValue, step)
        end

        local dragging = false

        local function setValue(v, trigger)
            value = roundToStep(clampNumber(v, minValue, maxValue), minValue, maxValue, step)
            local range = maxValue - minValue
            local percent = range > 0 and (value - minValue) / range or 0
            fill.Size = UDim2.new(percent, 0, 1, 0)
            local txt = string.format("%s/%s", tostring(value), tostring(maxValue))
            fillText.Text = txt
            valueText.Text = txt
            ctx.configData[configKeyName] = value
            if not ctx.isApplying() then ctx.saveConfig(false) end
            if trigger and callback then callback(value) end
        end

        local function setFromPointer(x)
            local w = math.max(bar.AbsoluteSize.X, 1)
            local pct = clampNumber((x - bar.AbsolutePosition.X) / w, 0, 1)
            setValue(minValue + (maxValue - minValue) * pct, true)
        end

        ctx.connect(bar.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            setFromPointer(input.Position.X)
        end)
        ctx.connect(UIS.InputChanged, function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                setFromPointer(input.Position.X)
            end
        end)
        ctx.connect(UIS.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        setValue(value, false)
        ctx.configBindings[configKeyName] = { set = setValue, default = defaultValue }

        return {
            Set = function(_, v) setValue(tonumber(v) or value, false) end,
            Get = function() return value end,
            SetText = function(_, v) label.Text = tostring(v or "") end,
            Destroy = function() holder:Destroy() end,
        }
    end

    -- ------------------------------------------------------------------
    -- Textbox
    -- ------------------------------------------------------------------
    function elements:Textbox(placeholder, callback, defaultText)
        local configKeyName = scopeKey("tb:" .. tostring(placeholder))
        local saved = ctx.configData[configKeyName]
        local box = Instance.new("TextBox")
        box.PlaceholderText = tostring(placeholder or "Enter text")
        box.Text = tostring(saved or defaultText or "")
        box.ClearTextOnFocus = false
        box.Size = UDim2.new(1, 0, 0, 26)
        box.BackgroundColor3 = Theme.Input
        box.BorderSizePixel = 0
        box.TextColor3 = Theme.Text
        box.PlaceholderColor3 = Theme.TextDim
        box.Font = Enum.Font.Gotham
        box.TextSize = 12
        box.LayoutOrder = nextOrder()
        box.Parent = parent
        round(box, 3)

        local outline = Instance.new("UIStroke")
        outline.Color = Theme.Border
        outline.Thickness = 1
        outline.Parent = box

        ctx.connect(box.FocusLost, function(enterPressed)
            if not ctx.alive() then return end
            ctx.configData[configKeyName] = box.Text
            if not ctx.isApplying() then ctx.saveConfig(false) end
            if callback then callback(box.Text, enterPressed) end
        end)

        return {
            Set = function(_, v) box.Text = tostring(v or "") end,
            Get = function() return box.Text end,
            Destroy = function() box:Destroy() end,
        }
    end

    -- ------------------------------------------------------------------
    -- Bind
    -- ------------------------------------------------------------------
    function elements:Bind(text, key, callback)
        local configKeyName = scopeKey("bind:" .. tostring(text))
        local saved = ctx.configData[configKeyName]
        local current = normalizeInput(key) or normalizeInput(saved) or Enum.KeyCode.E
        local listening = false
        local displayText = tostring(text or "Bind")

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextOrder()
        row.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -70, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = displayText
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextColor3 = Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row

        local badge = Instance.new("TextButton")
        badge.Size = UDim2.new(0, 60, 0, 18)
        badge.Position = UDim2.new(1, -60, 0, 2)
        badge.BackgroundColor3 = Theme.Input
        badge.TextColor3 = Theme.TextDim
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 10
        badge.Text = keyLabel(current)
        badge.BorderSizePixel = 0
        badge.AutoButtonColor = false
        badge.Parent = row
        round(badge, 3)

        local function updateText() badge.Text = keyLabel(current) end

        ctx.connect(badge.MouseButton1Click, function()
            if not ctx.alive() then return end
            listening = true
            badge.Text = "..."
            badge.BackgroundColor3 = Theme.Accent
        end)

        ctx.connect(UIS.InputBegan, function(input, gameProcessed)
            if not ctx.alive() then return end
            if listening then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    current = input.KeyCode
                elseif input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.MouseButton2
                    or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    current = input.UserInputType
                else
                    return
                end
                listening = false
                badge.BackgroundColor3 = Theme.Input
                updateText()
                ctx.configData[configKeyName] = current.Name
                if not ctx.isApplying() then ctx.saveConfig(false) end
                return
            end
            if gameProcessed then return end

            local matches = false
            if typeof(current) == "EnumItem" and current.EnumType == Enum.KeyCode then
                matches = (input.KeyCode == current)
            elseif typeof(current) == "EnumItem" and current.EnumType == Enum.UserInputType then
                matches = (input.UserInputType == current)
            end
            if matches and callback then callback() end
        end)

        updateText()

        return {
            SetKey = function(_, k)
                local n = normalizeInput(k)
                if n then current = n; updateText() end
            end,
            GetKey = function() return current end,
            Destroy = function() row:Destroy() end,
        }
    end

    -- ------------------------------------------------------------------
    -- Dropdown (single select)
    -- ------------------------------------------------------------------
    function elements:Dropdown(name, optionsList, callback, defaultValue)
        optionsList = optionsList or {}
        local configKeyName = scopeKey("dd:" .. tostring(name))
        local saved = ctx.configData[configKeyName]
        local displayName = tostring(name or "Dropdown")
        local selected = saved or defaultValue
        local open = false

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 22)
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = nextOrder()
        holder.Parent = parent

        local dropButton = Instance.new("TextButton")
        dropButton.Size = UDim2.new(1, 0, 1, 0)
        dropButton.BackgroundColor3 = Theme.Input
        dropButton.BorderSizePixel = 0
        dropButton.AutoButtonColor = false
        dropButton.Text = ""
        dropButton.Parent = holder
        round(dropButton, 3)

        local outline = Instance.new("UIStroke")
        outline.Color = Theme.Border
        outline.Thickness = 1
        outline.Parent = dropButton

        local btnLabel = Instance.new("TextLabel")
        btnLabel.Size = UDim2.new(1, -140, 1, 0)
        btnLabel.Position = UDim2.new(0, 8, 0, 0)
        btnLabel.BackgroundTransparency = 1
        btnLabel.Text = displayName
        btnLabel.Font = Enum.Font.Gotham
        btnLabel.TextSize = 12
        btnLabel.TextColor3 = Theme.Text
        btnLabel.TextXAlignment = Enum.TextXAlignment.Left
        btnLabel.Parent = dropButton

        local btnValue = Instance.new("TextLabel")
        btnValue.Size = UDim2.new(0, 120, 1, 0)
        btnValue.Position = UDim2.new(1, -142, 0, 0)
        btnValue.BackgroundTransparency = 1
        btnValue.Text = ""
        btnValue.Font = Enum.Font.Gotham
        btnValue.TextSize = 12
        btnValue.TextColor3 = Theme.TextDim
        btnValue.TextXAlignment = Enum.TextXAlignment.Right
        btnValue.Parent = dropButton

        local plus = Instance.new("TextLabel")
        plus.Size = UDim2.new(0, 16, 1, 0)
        plus.Position = UDim2.new(1, -20, 0, 0)
        plus.BackgroundTransparency = 1
        plus.Text = "+"
        plus.Font = Enum.Font.GothamBold
        plus.TextSize = 14
        plus.TextColor3 = Theme.TextDim
        plus.Parent = dropButton

        local dropFrame = Instance.new("Frame")
        dropFrame.Size = UDim2.new(1, 0, 0, 0)
        dropFrame.Position = UDim2.new(0, 0, 0, 24)
        dropFrame.BackgroundColor3 = Theme.Panel
        dropFrame.BorderSizePixel = 0
        dropFrame.Visible = false
        dropFrame.Parent = holder
        round(dropFrame, 3)

        local dropStroke = Instance.new("UIStroke")
        dropStroke.Color = Theme.Border
        dropStroke.Thickness = 1
        dropStroke.Parent = dropFrame

        local dropScroll = Instance.new("ScrollingFrame")
        dropScroll.Size = UDim2.new(1, 0, 1, 0)
        dropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        dropScroll.ScrollBarThickness = 4
        dropScroll.BackgroundTransparency = 1
        dropScroll.BorderSizePixel = 0
        dropScroll.Parent = dropFrame

        local dropPad = Instance.new("UIPadding")
        dropPad.PaddingTop = UDim.new(0, 4)
        dropPad.PaddingBottom = UDim.new(0, 4)
        dropPad.PaddingLeft = UDim.new(0, 4)
        dropPad.PaddingRight = UDim.new(0, 4)
        dropPad.Parent = dropScroll

        local dropLayout = Instance.new("UIListLayout")
        dropLayout.Padding = UDim.new(0, 3)
        dropLayout.Parent = dropScroll

        local optionButtons = {}

        local function updateButton()
            btnLabel.Text = displayName
            btnValue.Text = (selected ~= nil) and tostring(selected) or ""
        end

        local function updateSize()
            if not open then
                holder.Size = UDim2.new(1, 0, 0, 22)
                dropFrame.Visible = false
                return
            end
            local itemH = 22
            local total = (#optionsList) * (itemH + 3) + 10
            local h = math.min(total, 150)
            holder.Size = UDim2.new(1, 0, 0, 24 + h + 2)
            dropFrame.Size = UDim2.new(1, 0, 0, h)
            dropFrame.Visible = true
            dropScroll.CanvasSize = UDim2.new(0, 0, 0, dropLayout.AbsoluteContentSize.Y + 8)
        end

        local function selectOption(v, trigger)
            selected = v
            updateButton()
            open = false
            updateSize()
            ctx.configData[configKeyName] = v
            if not ctx.isApplying() then ctx.saveConfig(false) end
            if trigger and callback then callback(v) end
        end

        local function rebuild()
            for _, b in ipairs(optionButtons) do b:Destroy() end
            table.clear(optionButtons)
            for _, opt in ipairs(optionsList) do
                local btn = Instance.new("TextButton")
                btn.Text = tostring(opt)
                btn.Size = UDim2.new(1, 0, 0, 22)
                btn.BackgroundColor3 = Theme.Input
                btn.TextColor3 = Theme.Text
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 12
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Parent = dropScroll
                round(btn, 3)
                table.insert(optionButtons, btn)
                ctx.connect(btn.MouseEnter, function() btn.BackgroundColor3 = Theme.InputHover end)
                ctx.connect(btn.MouseLeave, function() btn.BackgroundColor3 = Theme.Input end)
                ctx.connect(btn.MouseButton1Click, function()
                    if not ctx.alive() then return end
                    selectOption(opt, true)
                end)
            end
        end

        ctx.connect(dropButton.MouseButton1Click, function()
            if not ctx.alive() then return end
            open = not open
            updateSize()
        end)

        rebuild()
        updateButton()
        updateSize()

        ctx.configBindings[configKeyName] = {
            set = function(v) selectOption(v, false) end,
            default = defaultValue,
        }

        return {
            Set = function(_, v) selectOption(v, false) end,
            Get = function() return selected end,
            SetOptions = function(_, newOpts)
                optionsList = newOpts or {}
                rebuild(); updateSize()
            end,
            Open = function() open = true; updateSize() end,
            Close = function() open = false; updateSize() end,
            Destroy = function() holder:Destroy() end,
        }
    end

    -- ------------------------------------------------------------------
    -- Checklist
    -- ------------------------------------------------------------------
    function elements:Checklist(name, options, callback, defaultSelected)
        options = options or {}
        local configKeyName = scopeKey("cl:" .. tostring(name))
        local displayName = tostring(name or "Checklist")
        local selected = {}
        if type(defaultSelected) == "table" then
            for _, v in ipairs(defaultSelected) do selected[v] = true end
        end
        local saved = ctx.configData[configKeyName]
        if type(saved) == "table" then
            selected = {}
            for _, v in ipairs(saved) do selected[v] = true end
        end
        local open = false

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 22)
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = nextOrder()
        holder.Parent = parent

        local dropButton = Instance.new("TextButton")
        dropButton.Size = UDim2.new(1, 0, 1, 0)
        dropButton.BackgroundColor3 = Theme.Input
        dropButton.BorderSizePixel = 0
        dropButton.AutoButtonColor = false
        dropButton.Text = ""
        dropButton.Parent = holder
        round(dropButton, 3)

        local outline = Instance.new("UIStroke")
        outline.Color = Theme.Border
        outline.Thickness = 1
        outline.Parent = dropButton

        local btnLabel = Instance.new("TextLabel")
        btnLabel.Size = UDim2.new(1, -160, 1, 0)
        btnLabel.Position = UDim2.new(0, 8, 0, 0)
        btnLabel.BackgroundTransparency = 1
        btnLabel.Text = displayName
        btnLabel.Font = Enum.Font.Gotham
        btnLabel.TextSize = 12
        btnLabel.TextColor3 = Theme.Text
        btnLabel.TextXAlignment = Enum.TextXAlignment.Left
        btnLabel.Parent = dropButton

        local btnValue = Instance.new("TextLabel")
        btnValue.Size = UDim2.new(0, 130, 1, 0)
        btnValue.Position = UDim2.new(1, -152, 0, 0)
        btnValue.BackgroundTransparency = 1
        btnValue.Text = ""
        btnValue.Font = Enum.Font.Gotham
        btnValue.TextSize = 12
        btnValue.TextColor3 = Theme.TextDim
        btnValue.TextXAlignment = Enum.TextXAlignment.Right
        btnValue.Parent = dropButton

        local plus = Instance.new("TextLabel")
        plus.Size = UDim2.new(0, 16, 1, 0)
        plus.Position = UDim2.new(1, -20, 0, 0)
        plus.BackgroundTransparency = 1
        plus.Text = "+"
        plus.Font = Enum.Font.GothamBold
        plus.TextSize = 14
        plus.TextColor3 = Theme.TextDim
        plus.Parent = dropButton

        local dropFrame = Instance.new("Frame")
        dropFrame.Size = UDim2.new(1, 0, 0, 0)
        dropFrame.Position = UDim2.new(0, 0, 0, 24)
        dropFrame.BackgroundColor3 = Theme.Panel
        dropFrame.BorderSizePixel = 0
        dropFrame.Visible = false
        dropFrame.Parent = holder
        round(dropFrame, 3)

        local dropStroke = Instance.new("UIStroke")
        dropStroke.Color = Theme.Border
        dropStroke.Thickness = 1
        dropStroke.Parent = dropFrame

        local dropScroll = Instance.new("ScrollingFrame")
        dropScroll.Size = UDim2.new(1, 0, 1, 0)
        dropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        dropScroll.ScrollBarThickness = 4
        dropScroll.BackgroundTransparency = 1
        dropScroll.BorderSizePixel = 0
        dropScroll.Parent = dropFrame

        local dropPad = Instance.new("UIPadding")
        dropPad.PaddingTop = UDim.new(0, 4)
        dropPad.PaddingBottom = UDim.new(0, 4)
        dropPad.PaddingLeft = UDim.new(0, 4)
        dropPad.PaddingRight = UDim.new(0, 4)
        dropPad.Parent = dropScroll

        local dropLayout = Instance.new("UIListLayout")
        dropLayout.Padding = UDim.new(0, 3)
        dropLayout.Parent = dropScroll

        local searchBar = Instance.new("TextBox")
        searchBar.Size = UDim2.new(1, 0, 0, 22)
        searchBar.PlaceholderText = "Search..."
        searchBar.Text = ""
        searchBar.ClearTextOnFocus = false
        searchBar.BackgroundColor3 = Theme.Input
        searchBar.TextColor3 = Theme.Text
        searchBar.PlaceholderColor3 = Theme.TextDim
        searchBar.Font = Enum.Font.Gotham
        searchBar.TextSize = 12
        searchBar.BorderSizePixel = 0
        searchBar.Parent = dropScroll
        round(searchBar, 3)

        local checkboxRows = {}

        local function getSelectedList()
            local list = {}
            for opt, v in pairs(selected) do if v then table.insert(list, opt) end end
            return list
        end

        local function updateButton()
            local count = 0
            for _, v in pairs(selected) do if v then count = count + 1 end end
            btnValue.Text = count > 0 and string.format("%d selected", count) or ""
        end

        local function saveSelected()
            ctx.configData[configKeyName] = getSelectedList()
            if not ctx.isApplying() then ctx.saveConfig(false) end
        end

        local function setSelected(opt, v, trigger)
            selected[opt] = v
            updateButton()
            saveSelected()
            if trigger and callback then callback(getSelectedList()) end
        end

        local function updateSize()
            if not open then
                holder.Size = UDim2.new(1, 0, 0, 22)
                dropFrame.Visible = false
                return
            end
            local visibleCount = 0
            for _, row in pairs(checkboxRows) do
                if row.Visible then visibleCount = visibleCount + 1 end
            end
            local itemH = 22
            local total = 22 + 4 + (visibleCount * (itemH + 3)) + 10
            local h = math.min(total, 170)
            holder.Size = UDim2.new(1, 0, 0, 24 + h + 2)
            dropFrame.Size = UDim2.new(1, 0, 0, h)
            dropFrame.Visible = true
            dropScroll.CanvasSize = UDim2.new(0, 0, 0, dropLayout.AbsoluteContentSize.Y + 8)
        end

        local function rebuild(filter)
            filter = filter and filter:lower() or ""
            for _, row in pairs(checkboxRows) do row:Destroy() end
            checkboxRows = {}
            for _, opt in ipairs(options) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 22)
                row.BackgroundTransparency = 1
                row.Parent = dropScroll

                local box = Instance.new("TextButton")
                box.Size = UDim2.new(0, 16, 0, 16)
                box.Position = UDim2.new(0, 0, 0, 3)
                box.BackgroundColor3 = selected[opt] and Theme.Accent or Theme.Input
                box.TextColor3 = Color3.new(1, 1, 1)
                box.Font = Enum.Font.GothamBold
                box.TextSize = 10
                box.Text = selected[opt] and "✕" or ""
                box.BorderSizePixel = 0
                box.AutoButtonColor = false
                box.Parent = row
                round(box, 3)

                local boxStroke = Instance.new("UIStroke")
                boxStroke.Color = selected[opt] and Theme.AccentLight or Theme.Border
                boxStroke.Thickness = 1
                boxStroke.Parent = box

                local lbl = Instance.new("TextButton")
                lbl.Size = UDim2.new(1, -22, 1, 0)
                lbl.Position = UDim2.new(0, 22, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.AutoButtonColor = false
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextColor3 = Theme.Text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 12
                lbl.Text = tostring(opt)
                lbl.BorderSizePixel = 0
                lbl.Parent = row

                local function updateBox()
                    box.Text = selected[opt] and "✕" or ""
                    box.BackgroundColor3 = selected[opt] and Theme.Accent or Theme.Input
                    boxStroke.Color = selected[opt] and Theme.AccentLight or Theme.Border
                end

                local show = (filter == "" or tostring(opt):lower():find(filter, 1, true) ~= nil)
                row.Visible = show

                ctx.connect(box.MouseButton1Click, function()
                    if not ctx.alive() then return end
                    setSelected(opt, not selected[opt], true)
                    updateBox()
                    updateSize()
                end)
                ctx.connect(lbl.MouseButton1Click, function()
                    if not ctx.alive() then return end
                    setSelected(opt, not selected[opt], true)
                    updateBox()
                    updateSize()
                end)

                checkboxRows[opt] = row
            end
            updateSize()
        end

        ctx.connect(searchBar:GetPropertyChangedSignal("Text"), function()
            local filter = searchBar.Text:lower()
            for opt, row in pairs(checkboxRows) do
                local show = (filter == "" or tostring(opt):lower():find(filter, 1, true) ~= nil)
                row.Visible = show
            end
            updateSize()
        end)

        ctx.connect(dropButton.MouseButton1Click, function()
            if not ctx.alive() then return end
            open = not open
            updateSize()
        end)

        rebuild("")
        updateButton()
        updateSize()

        ctx.configBindings[configKeyName] = {
            set = function(list)
                if type(list) ~= "table" then return end
                for k in pairs(selected) do selected[k] = nil end
                for _, v in ipairs(list) do selected[v] = true end
                for opt, row in pairs(checkboxRows) do
                    local box = row:FindFirstChildOfClass("TextButton")
                    if box then
                        box.Text = selected[opt] and "✕" or ""
                        box.BackgroundColor3 = selected[opt] and Theme.Accent or Theme.Input
                    end
                end
                updateButton()
            end,
            default = defaultSelected,
        }

        return {
            SetSelected = function(_, list)
                if type(list) ~= "table" then return end
                for k in pairs(selected) do selected[k] = nil end
                for _, v in ipairs(list) do selected[v] = true end
                for opt, row in pairs(checkboxRows) do
                    local box = row:FindFirstChildOfClass("TextButton")
                    if box then
                        box.Text = selected[opt] and "✕" or ""
                        box.BackgroundColor3 = selected[opt] and Theme.Accent or Theme.Input
                    end
                end
                updateButton()
                saveSelected()
            end,
            GetSelected = getSelectedList,
            SetOptions = function(_, newOpts)
                options = newOpts or {}
                rebuild(searchBar.Text)
                updateSize()
            end,
            Open = function() open = true; updateSize() end,
            Close = function() open = false; updateSize() end,
            Destroy = function() holder:Destroy() end,
        }
    end

    return elements
end

-- ==========================================================================
--  CreateWindow
-- ==========================================================================
function Library:CreateWindow(title, options)
    options = options or {}

    local alive = true
    local destroyed = false
    local generation = 0
    local connections = {}
    local tweens = {}

    local function connect(sig, fn)
        local c = sig:Connect(fn)
        table.insert(connections, c)
        return c
    end

    local function trackTween(t)
        table.insert(tweens, t)
        return t
    end

    local function disconnectAll()
        for _, c in ipairs(connections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(connections)
    end

    local function killTweens()
        for _, t in ipairs(tweens) do
            pcall(function() t:Cancel() end)
        end
        table.clear(tweens)
    end

    local function isAlive() return alive end

    local width         = options.Width or 540
    local height        = options.Height or 380
    local toggleKey     = options.ToggleKey or Enum.KeyCode.RightShift
    local onClose       = options.OnClose

    if options.AccentColor then Theme.Accent = options.AccentColor end
    if options.AccentLightColor then Theme.AccentLight = options.AccentLightColor end
    if options.SectionHeaderColor then Theme.SectionHeader = options.SectionHeaderColor end

    -- ------------------ Persistence ------------------
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
        if not canPersist() then return end
        local raw = nil
        if type(isfile) == "function" then
            if isfile(configFile) then
                local ok, data = pcall(readfile, configFile)
                if ok then raw = data end
            end
        else
            local ok, data = pcall(readfile, configFile)
            if ok then raw = data end
        end
        if raw and raw ~= "" then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(decoded) == "table" then
                for k in pairs(configData) do configData[k] = nil end
                for k, v in pairs(decoded) do configData[k] = v end
            end
        end
    end

    local function saveConfig(force)
        if not canPersist() then return end
        if not force and not configAutoSave then return end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(configData) end)
        if ok and encoded then
            pcall(function() writefile(configFile, encoded) end)
        end
    end

    local function applyConfigData(useDefaults)
        applyingConfig = true
        for key, binding in pairs(configBindings) do
            local value = configData[key]
            if value == nil and useDefaults then value = binding.default end
            if value ~= nil then binding.set(value) end
        end
        applyingConfig = false
    end

    loadConfig()

    -- ------------------ ScreenGui & Window ------------------
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SmugLibCore"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = resolveGuiParent()

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, width, 0, height)
    main.Position = UDim2.new(0.5, -math.floor(width / 2), 1, 30)
    main.BackgroundColor3 = Theme.Background
    main.BorderSizePixel = 0
    main.Parent = screenGui
    round(main, 6)

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Theme.Border
    mainStroke.Thickness = 1
    mainStroke.Parent = main

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Theme.Panel
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    round(titleBar, 6)

    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 10)
    titleCover.Position = UDim2.new(0, 0, 1, -10)
    titleCover.BackgroundColor3 = Theme.Panel
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = tostring(title or "SmugLib")
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextColor3 = Theme.Text
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Terminate (X) top right
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "TerminateButton"
    closeButton.Size = UDim2.new(0, 22, 0, 22)
    closeButton.Position = UDim2.new(1, -28, 0, 4)
    closeButton.Text = "✕"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 13
    closeButton.BackgroundColor3 = Theme.Close
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.BorderSizePixel = 0
    closeButton.AutoButtonColor = false
    closeButton.Parent = titleBar
    round(closeButton, 3)

    local closeStroke = Instance.new("UIStroke")
    closeStroke.Color = Color3.fromRGB(120, 30, 40)
    closeStroke.Thickness = 1
    closeStroke.Parent = closeButton

    connect(closeButton.MouseEnter, function()
        closeButton.BackgroundColor3 = Theme.CloseHover
    end)
    connect(closeButton.MouseLeave, function()
        closeButton.BackgroundColor3 = Theme.Close
    end)

    -- Body
    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 1, -30)
    body.Position = UDim2.new(0, 0, 0, 30)
    body.BackgroundTransparency = 1
    body.Parent = main

    local bodyPad = Instance.new("UIPadding")
    bodyPad.PaddingTop = UDim.new(0, 8)
    bodyPad.PaddingLeft = UDim.new(0, 8)
    bodyPad.PaddingRight = UDim.new(0, 8)
    bodyPad.PaddingBottom = UDim.new(0, 8)
    bodyPad.Parent = body

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 22)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = body

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    -- Content
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -26)
    tabContent.Position = UDim2.new(0, 0, 0, 26)
    tabContent.BackgroundTransparency = 1
    tabContent.Parent = body

    -- ------------------ Toast ------------------
    local toastHost = Instance.new("Frame")
    toastHost.Size = UDim2.new(1, 0, 1, 0)
    toastHost.BackgroundTransparency = 1
    toastHost.ZIndex = 50
    toastHost.Parent = screenGui

    local toastLayout = Instance.new("UIListLayout")
    toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    toastLayout.Padding = UDim.new(0, 6)
    toastLayout.Parent = toastHost

    local toastPad = Instance.new("UIPadding")
    toastPad.PaddingTop = UDim.new(0, 14)
    toastPad.Parent = toastHost

    local function notify(text, duration)
        if not alive then return end
        duration = duration or 3
        local myGen = generation

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 260, 0, 34)
        frame.BackgroundColor3 = Theme.Panel
        frame.BackgroundTransparency = 0
        frame.BorderSizePixel = 0
        frame.Parent = toastHost
        frame.ZIndex = 51
        round(frame, 4)

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Accent
        stroke.Thickness = 1
        stroke.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -16, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = tostring(text)
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextWrapped = true
        label.ZIndex = 52
        label.Parent = frame

        frame.Position = UDim2.new(0.5, -130, 0, -50)
        local fadeIn = trackTween(TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, -130, 0, 0) }
        ))
        fadeIn:Play()

        task.delay(duration, function()
            if myGen ~= generation then return end
            if not frame.Parent then return end
            local fadeOut = trackTween(TweenService:Create(
                frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { BackgroundTransparency = 1 }
            ))
            fadeOut:Play()
            local fadeOut2 = trackTween(TweenService:Create(
                stroke,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Transparency = 1 }
            ))
            fadeOut2:Play()
            task.wait(0.31)
            if myGen ~= generation then return end
            if frame then frame:Destroy() end
        end)
    end

    -- ------------------ Draggable ------------------
    local function makeDraggable(handle, target)
        local dragging, dragInput, dragStart, startPos
        connect(handle.InputBegan, function(input)
            if not alive then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = target.Position

            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if endConn then endConn:Disconnect() end
                end
            end)
            table.insert(connections, endConn)
        end)
        connect(handle.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        connect(UIS.InputChanged, function(input)
            if not alive or not dragging or input ~= dragInput then return end
            if not dragStart or not startPos then return end
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end)
    end

    makeDraggable(titleBar, main)

    -- ------------------ Destroy (nuke everything) ------------------
    local function destroyWindow()
        if destroyed then return end
        destroyed = true
        alive = false
        generation = generation + 1

        -- 1) onClose callback
        if onClose then pcall(onClose) end

        -- 2) Cancel all tweens
        killTweens()

        -- 3) Disconnect all connections (incl. dynamic drag handlers)
        disconnectAll()

        -- 4) Clear config bindings (release GUI refs)
        for k in pairs(configBindings) do
            configBindings[k] = nil
        end

        -- 5) Destroy toast host
        if toastHost then pcall(function() toastHost:Destroy() end) end

        -- 6) Destroy whole ScreenGui
        if screenGui then pcall(function() screenGui:Destroy() end) end
    end

    connect(closeButton.MouseButton1Click, destroyWindow)

    connect(UIS.InputBegan, function(input, gameProcessed)
        if gameProcessed or not alive then return end
        if input.KeyCode == toggleKey then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)

    trackTween(TweenService:Create(
        main,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -math.floor(width / 2), 0.5, -math.floor(height / 2)) }
    )):Play()

    -- ------------------ Tabs ------------------
    local tabs = {}
    local currentTabButton = nil
    local currentTabFrame = nil

    local function setActiveTab(btn, frame)
        if currentTabButton == btn then return end
        if currentTabButton then
            currentTabButton.BackgroundColor3 = Theme.Input
            currentTabButton.TextColor3 = Theme.TextDim
        end
        if currentTabFrame then currentTabFrame.Visible = false end
        currentTabButton = btn
        currentTabFrame = frame
        btn.BackgroundColor3 = Theme.Accent
        btn.TextColor3 = Color3.new(1, 1, 1)
        frame.Visible = true
    end

    -- ------------------ Window object ------------------
    local window = {}

    function window:Folder(name)
        local folderName = tostring(name or "Tab")

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.Text = folderName
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextColor3 = Theme.TextDim
        btn.BackgroundColor3 = Theme.Input
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Parent = tabBar
        round(btn, 3)

        local btnPad = Instance.new("UIPadding")
        btnPad.PaddingLeft = UDim.new(0, 12)
        btnPad.PaddingRight = UDim.new(0, 12)
        btnPad.Parent = btn

        local folderFrame = Instance.new("ScrollingFrame")
        folderFrame.Size = UDim2.new(1, 0, 1, 0)
        folderFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        folderFrame.BackgroundTransparency = 1
        folderFrame.BorderSizePixel = 0
        folderFrame.ScrollBarThickness = 4
        folderFrame.Visible = false
        folderFrame.Parent = tabContent

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = folderFrame

        connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            folderFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)

        tabs[btn] = folderFrame

        connect(btn.MouseButton1Click, function()
            setActiveTab(btn, folderFrame)
        end)

        if not currentTabButton then
            setActiveTab(btn, folderFrame)
        end

        local ctx = {
            alive = isAlive,
            connect = connect,
            folderName = folderName,
            scope = "",
            configData = configData,
            configBindings = configBindings,
            saveConfig = saveConfig,
            isApplying = function() return applyingConfig end,
            notify = notify,
        }

        return buildElements(ctx, folderFrame)
    end

    function window:SetTitle(newTitle)
        titleLabel.Text = tostring(newTitle or "SmugLib")
    end

    function window:SetToggleKey(k)
        if typeof(k) == "EnumItem" and k.EnumType == Enum.KeyCode then
            toggleKey = k
            return true
        end
        return false
    end

    function window:Notify(text, duration) notify(text, duration) end
    function window:Destroy() destroyWindow() end
    function window:SetOnClose(cb) onClose = cb end
    function window:Kill() destroyWindow() end

    function window:GetConfig() return configData end
    function window:GetConfigInfo()
        return { File = configFile, Key = configKey, AutoSave = configAutoSave }
    end

    function window:SetConfig(data, applyNow)
        if type(data) ~= "table" then return false end
        for k in pairs(configData) do configData[k] = nil end
        for k, v in pairs(data) do configData[k] = v end
        if applyNow ~= false then applyConfigData(false) end
        saveConfig(true)
        return true
    end

    function window:LoadConfig()
        loadConfig()
        applyConfigData(false)
        return true
    end

    function window:SaveConfig() saveConfig(true); return true end

    function window:ClearConfig()
        for k in pairs(configData) do configData[k] = nil end
        saveConfig(true)
        applyConfigData(true)
        return true
    end

    function window:ExportConfig()
        local ok, encoded = pcall(function() return HttpService:JSONEncode(configData) end)
        if ok then return encoded end
        return nil
    end

    function window:ImportConfig(jsonString, applyNow)
        if type(jsonString) ~= "string" then return false end
        local ok, decoded = pcall(function() return HttpService:JSONDecode(jsonString) end)
        if ok and type(decoded) == "table" then
            for k in pairs(configData) do configData[k] = nil end
            for k, v in pairs(decoded) do configData[k] = v end
            if applyNow ~= false then applyConfigData(false) end
            saveConfig(true)
            return true
        end
        return false
    end

    function window:SetConfigKey(newKey, keepCurrent)
        if not newKey or newKey == "" then return false end
        local nextKey = tostring(newKey):gsub("[^%w_%-]", "_")
        if nextKey == configKey then return true end
        configKey = nextKey
        configFile = "SmugLib_" .. configKey .. ".json"
        if keepCurrent then
            saveConfig(true)
        else
            for k in pairs(configData) do configData[k] = nil end
            loadConfig()
            applyConfigData(false)
        end
        return true
    end

    notify(string.format("%s loaded successfully!", tostring(title or "SmugLib")), 2.5)
    return window
end

-- Global fallback: kill all SmugLibCore GUIs
function Library:DestroyAll()
    local function tryKill(container)
        if not container then return end
        for _, gui in ipairs(container:GetChildren()) do
            if gui.Name == "SmugLibCore" then
                pcall(function() gui:Destroy() end)
            end
        end
    end
    tryKill(CoreGui)
    local plr = game:GetService("Players").LocalPlayer
    if plr then
        local pg = plr:FindFirstChildOfClass("PlayerGui")
        if pg then tryKill(pg) end
    end
end

return Library
