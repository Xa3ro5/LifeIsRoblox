local Library = {}
Library.__index = Library

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Alive = true
local Connections = {}

local function Terminate()
    Alive = false
    for _,c in pairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
end

function Library:CreateWindow(title)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UILibrary"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game.CoreGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0,400,0,350)
    Main.Position = UDim2.new(0.5,-200,0.5,-175)
    Main.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui

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

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = Container
    Layout.Padding = UDim.new(0,6)

    -- drag
    local dragging = false
    local dragInput
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

    function Window:Folder(name)

        local Folder = Instance.new("Frame")
        Folder.Size = UDim2.new(1,-10,0,30)
        Folder.BackgroundColor3 = Color3.fromRGB(40,40,40)
        Folder.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Text = name
        Label.Size = UDim2.new(1,0,1,0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.new(1,1,1)
        Label.Parent = Folder

        local List = Instance.new("UIListLayout")
        List.Parent = Folder
        List.Padding = UDim.new(0,4)

        local Elements = {}

        function Elements:Label(text)
            local L = Instance.new("TextLabel")
            L.Text = text
            L.Size = UDim2.new(1,0,0,20)
            L.BackgroundTransparency = 1
            L.TextColor3 = Color3.new(1,1,1)
            L.Parent = Folder
        end

        function Elements:Button(text,callback)
            local B = Instance.new("TextButton")
            B.Text = text
            B.Size = UDim2.new(1,0,0,25)
            B.BackgroundColor3 = Color3.fromRGB(60,60,60)
            B.TextColor3 = Color3.new(1,1,1)
            B.Parent = Folder

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
            T.Parent = Folder

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

        function Elements:Slider(text,min,max,default,callback)

            local Value = default or min

            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1,0,0,40)
            Holder.BackgroundTransparency = 1
            Holder.Parent = Folder

            local Label = Instance.new("TextLabel")
            Label.Text = text.." : "..Value
            Label.Size = UDim2.new(1,0,0,20)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3.new(1,1,1)
            Label.Parent = Holder

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1,0,0,10)
            Bar.Position = UDim2.new(0,0,0,25)
            Bar.BackgroundColor3 = Color3.fromRGB(60,60,60)
            Bar.Parent = Holder

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((Value-min)/(max-min),0,1,0)
            Fill.BackgroundColor3 = Color3.fromRGB(120,120,120)
            Fill.Parent = Bar

            Bar.InputBegan:Connect(function()
                local percent = (Mouse.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X
                percent = math.clamp(percent,0,1)

                Value = math.floor(min + (max-min)*percent)

                Fill.Size = UDim2.new(percent,0,1,0)
                Label.Text = text.." : "..Value

                if Alive and callback then
                    callback(Value)
                end
            end)

        end

        function Elements:Bind(text,key,callback)

            local Current = key

            local B = Instance.new("TextButton")
            B.Text = text.." : "..tostring(key.Name)
            B.Size = UDim2.new(1,0,0,25)
            B.BackgroundColor3 = Color3.fromRGB(60,60,60)
            B.TextColor3 = Color3.new(1,1,1)
            B.Parent = Folder

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
            Box.Parent = Folder

            table.insert(Connections,
                Box.FocusLost:Connect(function()
                    if Alive and callback then
                        callback(Box.Text)
                    end
                end)
            )
        end

        return Elements
    end

    return Window
end

return Library
