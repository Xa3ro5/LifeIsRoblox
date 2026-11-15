-- ================= GLOBAL REGISTRY (survives reload) =================
local env = (typeof(getgenv) == "function" and getgenv()) or _G

if env.GameOfChoice then
    local old = env.GameOfChoice
    for name in pairs(old.flags) do
        old.flags[name] = false
    end
    pcall(function()
        if old.win and old.win.Kill then old.win:Kill() end
    end)
    pcall(function()
        if old.gui and old.gui.Parent then old.gui:Destroy() end
    end)
    task.wait(0.15)
    env.GameOfChoice = nil
end

local state = { flags = {}, gui = nil, win = nil }
env.GameOfChoice = state

local SMUGLIB_URLS = {
    "https://raw.githubusercontent.com/Xa3ro5/LifeIsRoblox/refs/heads/main/SmugLibCoreV2.lua",
    "https://pastebin.com/raw/CkVW0eJZ"
}
local Library
do
    for _, url in ipairs(SMUGLIB_URLS) do
        -- Executors can retain an old raw-GitHub response across executions.
        local freshUrl = url .. "?smuglib=" .. game:GetService("HttpService"):GenerateGUID(false)
        local ok, source = pcall(game.HttpGet, game, freshUrl, true)
        if ok and type(source) == "string" and source ~= "" then
            if not source:find("-- Keyforge gate:", 1, true)
                or not source:find("SmugLibKeyforgeKeys", 1, true) then
                warn("[KeyForge] Make sure you use the latest SmugLibCoreV2 to the remote source.")
                return
            end
            local compile = loadstring(source)
            if compile then
                local ran, lib = pcall(compile)
                if not ran then warn(tostring(lib)) return end
                if ran and type(lib) == "table" then Library = lib break end
            end
        end
    end
    if not Library then warn("[SmugLib] Failed to load SmugLibV2") return end
end

local win = Library:CreateWindow("My UI", {
    Width = 620,
    Height = 460,
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigKey = "main",
    ConfigAutoSave = true,
})
state.win = win
state.gui = type(win.GetGui) == "function" and win:GetGui() or nil

local tab = win:Folder("main")
local sec = tab:Section("legit")

sec:Label("utility")
sec:Separator("bindings")

sec:Toggle("Aimbot", function(on)
    print("[aimbot]", on)
end, false, Enum.KeyCode.E)

sec:Slider("FOV", 0, 360, 90, function(v)
    print("[fov]", v)
end, 5)

sec:Slider("Smoothing", 0, 20, 0, function(v)
    print("[smoothing]", v)
end, 1)

sec:Dropdown("Mode", {"Camera", "Mouse", "Silent"}, function(v)
    print("[mode]", v)
end, "Camera")

sec:Textbox("Webhook URL...", function(text, enterPressed)
    print("[webhook]", text, enterPressed)
end, "")

sec:Checklist("ESP elements", {"Box", "Name", "Health", "Tracer"}, function(list)
    print("[esp]", table.concat(list, ", "))
end, {"Box", "Name"})

-- TableWindow: combine as many independent rows as needed in one floating panel.
local tableExample = tab:Section("Universal table example")
if type(win.TableWindow) == "function" then
    local dashboard = win:TableWindow("Session", {Width = 300, Height = 280})
    local statusLine = dashboard:AddLabel("Ready")
    local counter = dashboard:AddValue("Items", 0)
    local progress = dashboard:AddProgress("Storage", 0)
    dashboard:AddSeparator("Controls")
    local count = 0
    dashboard:AddButton("Add item", function()
        count = count + 1
        counter:SetValue(count)
        progress:SetProgress(math.min(count / 10, 1))
        statusLine:SetText("Last action: added an item")
    end)
    local toggle = dashboard:AddToggle("Notifications", true, function(enabled)
        statusLine:SetText(enabled and "Notifications on" or "Notifications off")
    end)
    tableExample:Toggle("Show universal table", function(on) dashboard:SetVisible(on) end, true)
    tableExample:Button("Reset example", function()
        count = 0
        counter:SetValue(0)
        progress:SetProgress(0)
        toggle:SetValue(true, false) -- false suppresses the change callback.
        statusLine:SetText("Ready")
    end)
    -- dashboard:AddPreview(modelOrPart, 120) makes a rotating clone.
    -- row:SetVisible(false), row:SetOrder(2), row:Destroy(), dashboard:Clear().
    -- dashboard:SetTitle("New title"), dashboard:SetMinimized(true), dashboard:Destroy().
else
    tableExample:Label("Update SmugLibCoreV2 to use TableWindow.")
end

sec:Bind("Panic", Enum.KeyCode.P, function()
    win:Kill()
end)

win:Notify("Loaded successfully. Press RShift to toggle.", 3)
