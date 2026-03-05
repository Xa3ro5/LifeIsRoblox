local Library = {}
Library.__index = Library

-- Roblox services
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Global flags
local Alive = true
local Connections = {}

-- Global terminate function
local function Terminate()
    Alive = false
    for _, c in pairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
end

-- Helper function for notifications
local function Notify(text, parent)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 250, 0, 50)
    notif.Position = UDim2.new(0.5, -125, 0, 50)
    notif.BackgroundColor3 = Color3.fromRGB(50,50,50)
    notif.BorderSizePixel = 0
    notif.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.Parent = notif

    local tween = TweenService:Create(notif, TweenInfo.new(0.5), {Position = UDim2.new(0.5,-125,0,80)})
    tween:Play()

    delay(3, function()
        if notif and notif.Parent then
            notif:Destroy()
        end
    end)
end

function Library:CreateWindow(title)

    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UILibrary"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game.CoreGui

    -- Main frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 400, 0, 350)
    Main.Position = UDim2.new(0.5, -200, 1.2, 0) -- start off-screen bottom
    Main.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui

    -- Tween window from bottom to center
    TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -200, 0.5, -175)}):Play()

    -- Top bar
    local Top = Instance.new("Frame")
    Top.Size = UDim2.new(1,0,0,30)
    Top.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Top.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Text = title
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.TextColor3 = Color3.new(1,1,1)
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1,-60,1,0)
    Title.Parent = Top

    -- Minimize
    local Min = Instance.new("TextButton")
    Min.Text = "-"
    Min.Size = UDim2.new(0,30,1,0)
    Min.Position = UDim2.new(1,-60,0,0)
    Min.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Min.TextColor3 = Color3.new(1,1,1)
    Min.Parent = Top

    local Close = Instance.new("TextButton")
    Close.Text = "X"
    Close.Size = UDim2.new(0,30,1,0)
    Close.Position = UDim2.new(1,-30,0,0)
    Close.BackgroundColor3 = Color3.fromRGB(60,30,30)
    Close.TextColor3 = Color3.new(1,1,1)
    Close.Parent = Top

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1,0,1,-30)
    Container.Position = UDim2.new(0,0,0,30)
    Container.BackgroundTransparency = 1
    Container.Parent = Main

    -- Tab bar
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1,0,0,25)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Container

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0,5)
    TabLayout.Parent = TabBar

    local TabContents = Instance.new("Frame")
    TabContents.Size = UDim2.new(1,0,1,-25)
    TabContents.Position = UDim2.new(0,0,0,25)
    TabContents.BackgroundTransparency = 1
    TabContents.Parent = Container

    local Tabs = {}
    local CurrentTab = nil

    -- drag
    local dragging = false
    local start
    local startPos

    Top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            start = input.Position
            startPos = Main.Position
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging then
            local delta = input.Position - start
            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- minimize
    local Minimized = false
    local Restore = Instance.new("TextButton")
    Restore.Text = "▲"
    Restore.Size = UDim2.new(0,40,0,40)
    Restore.Position = UDim2.new(0,20,1,-60)
    Restore.Visible = false
    Restore.Parent = ScreenGui

    Min.MouseButton1Click:Connect(function()
        Minimized = true
        Main.Visible = false
        Restore.Visible = true
    end)

    Restore.MouseButton1Click:Connect(function()
        Minimized = false
        Main.Visible = true
        Restore.Visible = false
    end)

    Close.MouseButton1Click:Connect(function()
        Terminate()
        ScreenGui:Destroy()
    end)

    local Window = {}

    -- Folder / Tab
    function Window:Folder(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Text = name
        TabButton.Size = UDim2.new(0,80,1,0)
        TabButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
        TabButton.TextColor3 = Color3.new(1,1,1)
        TabButton.Parent = TabBar

        local FolderFrame = Instance.new("Frame")
        FolderFrame.Size = UDim2.new(1,0,1,0)
        FolderFrame.BackgroundTransparency = 1
        FolderFrame.Visible = false
        FolderFrame.Parent = TabContents

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0,6)
        Layout.Parent = FolderFrame

        Tabs[TabButton] = FolderFrame

        TabButton.MouseButton1Click:Connect(function()
            if CurrentTab then
                Tabs[CurrentTab].Visible = false
            end
            FolderFrame.Visible = true
            CurrentTab = TabButton
        end)

        if not CurrentTab then
            CurrentTab = TabButton
            FolderFrame.Visible = true
        end

        local Elements = {}

        -- Existing elements
        function Elements:Label(text)
            local L = Instance.new("TextLabel")
            L.Text = text
            L.Size = UDim2.new(1,0,0,20)
            L.BackgroundTransparency = 1
            L.TextColor3 = Color3.new(1,1,1)
            L.Parent = FolderFrame
        end

        function Elements:Button(text,callback)
            local B = Instance.new("TextButton")
            B.Text = text
            B.Size = UDim2.new(1,0,0,25)
            B.BackgroundColor3 = Color3.fromRGB(60,60,60)
            B.TextColor3 = Color3.new(1,1,1)
            B.Parent = FolderFrame

            table.insert(Connections,
                B.MouseButton1Click:Connect(function()
                    if Alive and callback then
                        callback()
                    end
                end)
            )
        end

        function Elements:Toggle(text,callback)
            local state = false
            local T = Instance.new("TextButton")
            T.Text = text.." : OFF"
            T.Size = UDim2.new(1,0,0,25)
            T.BackgroundColor3 = Color3.fromRGB(60,60,60)
            T.TextColor3 = Color3.new(1,1,1)
            T.Parent = FolderFrame

            table.insert(Connections,
                T.MouseButton1Click:Connect(function()
                    state = not state
                    T.Text = text.." : "..(state and "ON" or "OFF")
                    if Alive and callback then
                        callback(state)
                    end
                end)
            )
        end

        function Elements:Bind(text,key,callback)
            local Current = key
            local B = Instance.new("TextButton")
            B.Text = text.." : "..tostring(key.Name)
            B.Size = UDim2.new(1,0,0,25)
            B.BackgroundColor3 = Color3.fromRGB(60,60,60)
            B.TextColor3 = Color3.new(1,1,1)
            B.Parent = FolderFrame

            table.insert(Connections,
                UIS.InputBegan:Connect(function(input,gp)
                    if gp then return end
                    if input.KeyCode == Current then
                        if Alive and callback then
                            callback()
                        end
                    end
                end)
            )
        end

        function Elements:Textbox(text,callback)
            local Box = Instance.new("TextBox")
            Box.PlaceholderText = text
            Box.Size = UDim2.new(1,0,0,25)
            Box.BackgroundColor3 = Color3.fromRGB(60,60,60)
            Box.TextColor3 = Color3.new(1,1,1)
            Box.Parent = FolderFrame

            table.insert(Connections,
                Box.FocusLost:Connect(function()
                    if Alive and callback then
                        callback(Box.Text)
                    end
                end)
            )
        end

        -- DROPDOWN
        function Elements:Dropdown(name,options,callback)
            local DropButton = Instance.new("TextButton")
            DropButton.Text = name.." ▼"
            DropButton.Size = UDim2.new(1,0,0,25)
            DropButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            DropButton.TextColor3 = Color3.new(1,1,1)
            DropButton.Parent = FolderFrame

            local DropFrame = Instance.new("Frame")
            DropFrame.Size = UDim2.new(1,0,0,#options*25)
            DropFrame.Position = UDim2.new(0,0,0,25)
            DropFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
            DropFrame.Visible = false
            DropFrame.Parent = DropButton

            for i,opt in pairs(options) do
                local Btn = Instance.new("TextButton")
                Btn.Text = opt
                Btn.Size = UDim2.new(1,0,0,25)
                Btn.Position = UDim2.new(0,0,0,(i-1)*25)
                Btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
                Btn.TextColor3 = Color3.new(1,1,1)
                Btn.Parent = DropFrame

                table.insert(Connections,
                    Btn.MouseButton1Click:Connect(function()
                        DropButton.Text = name.." : "..opt.." ▼"
                        DropFrame.Visible = false
                        if Alive and callback then
                            callback(opt)
                        end
                    end)
                )
            end

            DropButton.MouseButton1Click:Connect(function()
                DropFrame.Visible = not DropFrame.Visible
            end)
        end

        return Elements
    end

    -- Notify user UI loaded successfully
    Notify(title.." loaded successfully!", ScreenGui)

    return Window
end

return Library
