local Library = loadstring(game:HttpGet("https://pastebin.com/raw/CkVW0eJZ"))()

local window = Library:CreateWindow("Gangsta | TWW", {
    Width = 620,
    Height = 460,
    ToggleKey = Enum.KeyCode.RightShift,
})

local main = window:Folder("main")

-- Sekce "legit" jako v obrázku
local legit = main:Section("legit")
legit:Toggle("aimbot", function(on) print("aimbot", on) end, false, Enum.KeyCode.M2)
legit:Checkbox("visible check", function(on) end, true)
legit:Checkbox("apply prediction", function(on) end, false)
legit:Slider("smoothing [mouse]", 0, 20, 0, function(v) end)
legit:Dropdown("hitbox priority", {"Head", "Torso", "Random"}, function(v) end, "Head")
legit:Dropdown("mode", {"Camera", "Mouse"}, function(v) end, "Camera")

local br = main:Section("bullet redirection")
br:Checkbox("silent aim", function(on) end, false)
br:Checkbox("apply prediction", function(on) end, false)
br:Checkbox("custom prediction", function(on) end, false)
br:Slider("value", 0, 100, 75, function(v) end)
br:Dropdown("hitbox priority", {"Head", "Torso"}, function(v) end, "Head")

local tb = main:Section("trigger bot")
tb:Checkbox("enabled", function(on) end, false, Enum.KeyCode.M)
tb:Slider("delay", 0, 5, 0, function(v) end)

local rage = window:Folder("rage")
local draws = rage:Section("drawing field of view")
draws:Checkbox("aimbot fov", function(on) end, false)
draws:Slider("size", 0, 250, 100, function(v) end)
draws:Checkbox("silent aim fov", function(on) end, false)
draws:Slider("size", 0, 250, 100, function(v) end)
draws:Dropdown("style", {"Outline", "Fill"}, function(v) end, "Outline")
draws:Dropdown("position", {"Mouse", "Center"}, function(v) end, "Mouse")

-- Multi-select dropdown
main:Section("misc"):Checklist("features", {"A", "B", "C", "D"}, function(list)
    print(table.concat(list, ", "))
end, {"A"})