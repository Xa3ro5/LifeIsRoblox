local Library = {}
Library.__index = Library

-- Services
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local Alive = true
local Connections = {}

-- Terminate
local function Terminate()
    Alive = false
    for _, c in pairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
end

-- Helpers
local function Round(obj,r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,r)
    c.Parent = obj
end

local function Padding(parent,p)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0,p)
    pad.PaddingBottom = UDim.new(0,p)
    pad.PaddingLeft = UDim.new(0,p)
    pad.PaddingRight = UDim.new(0,p)
    pad.Parent = parent
end

local function Notify(text,parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,260,0,50)
    frame.Position = UDim2.new(.5,-130,0,-60)
    frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
    frame.Parent = parent
    Round(frame,8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.Parent = frame

    TweenService:Create(frame,TweenInfo.new(.35),{
        Position = UDim2.new(.5,-130,0,40)
    }):Play()

    task.delay(3,function()
        if frame then frame:Destroy() end
    end)
end

-- Main window creation
function Library:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ModernUILib"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Main frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0,520,0,380)
    Main.Position = UDim2.new(.5,-260,1,0)
    Main.BackgroundColor3 = Color3.fromRGB(25,25,25)
    Main.Parent = ScreenGui
    Round(Main,10)

    TweenService:Create(Main,TweenInfo.new(.6,Enum.EasingStyle.Quad),{
        Position = UDim2.new(.5,-260,.5,-190)
    }):Play()

    -- Top bar
    local Top = Instance.new("Frame")
    Top.Size = UDim2.new(1,0,0,34)
    Top.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Top.Parent = Main
    Round(Top,10)

    local Title = Instance.new("TextLabel")
    Title.Text = title
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextColor3 = Color3.new(1,1,1)
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0,10,0,0)
    Title.Size = UDim2.new(1,-100,1,0)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Top

    -- Close
    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0,34,1,0)
    Close.Position = UDim2.new(1,-34,0,0)
    Close.Text = "✕"
    Close.Font = Enum.Font.GothamBold
    Close.TextSize = 14
    Close.BackgroundColor3 = Color3.fromRGB(60,40,40)
    Close.TextColor3 = Color3.new(1,1,1)
    Close.Parent = Top
    Round(Close,8)

    Close.MouseButton1Click:Connect(function()
        Terminate()
        ScreenGui:Destroy()
    end)

    -- Body
    local Body = Instance.new("Frame")
    Body.Size = UDim2.new(1,0,1,-34)
    Body.Position = UDim2.new(0,0,0,34)
    Body.BackgroundTransparency = 1
    Body.Parent = Main
    Padding(Body,8)

    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1,0,0,28)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Body

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0,6)
    TabLayout.Parent = TabBar

    local TabContent = Instance.new("Frame")
    TabContent.Size = UDim2.new(1,0,1,-30)
    TabContent.Position = UDim2.new(0,0,0,30)
    TabContent.BackgroundTransparency = 1
    TabContent.Parent = Body
    Padding(TabContent,6)

    -- Resizable
    local Resize = Instance.new("Frame")
    Resize.Size = UDim2.new(0,16,0,16)
    Resize.Position = UDim2.new(1,-16,1,-16)
    Resize.BackgroundColor3 = Color3.fromRGB(80,80,80)
    Resize.Parent = Main
    Round(Resize,4)

    local resizing=false
    local startSize
    local startPos

    Resize.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            resizing=true
            startPos=input.Position
            startSize=Main.Size
        end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            resizing=false
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if resizing then
            local delta=i.Position-startPos
            Main.Size=UDim2.new(
                startSize.X.Scale,
                startSize.X.Offset+delta.X,
                startSize.Y.Scale,
                startSize.Y.Offset+delta.Y
            )
        end
    end)

    -- Dragging
    local dragging=false
    local dragStart
    local startPos2
    Top.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            dragStart=input.Position
            startPos2=Main.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging then
            local delta=input.Position-dragStart
            Main.Position=UDim2.new(
                startPos2.X.Scale,
                startPos2.X.Offset+delta.X,
                startPos2.Y.Scale,
                startPos2.Y.Offset+delta.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false
        end
    end)

    -- Tabs
    local Tabs={}
    local CurrentTab=nil
    local Window={}

    function Window:Folder(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0,90,1,0)
        TabButton.Text = name
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 13
        TabButton.TextColor3 = Color3.new(1,1,1)
        TabButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
        TabButton.Parent = TabBar
        Round(TabButton,6)

        local FolderFrame = Instance.new("Frame")
        FolderFrame.Size = UDim2.new(1,0,1,0)
        FolderFrame.BackgroundTransparency = 1
        FolderFrame.Visible = false
        FolderFrame.Parent = TabContent
        Padding(FolderFrame,4)

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0,8)
        Layout.Parent = FolderFrame

        Tabs[TabButton]=FolderFrame
        TabButton.MouseButton1Click:Connect(function()
            if CurrentTab then
                Tabs[CurrentTab].Visible=false
            end
            FolderFrame.Visible=true
            CurrentTab=TabButton
        end)
        if not CurrentTab then
            FolderFrame.Visible=true
            CurrentTab=TabButton
        end

        local Elements={}

        -- Button
        function Elements:Button(text,callback)
            local B=Instance.new("TextButton")
            B.Size=UDim2.new(1,0,0,32)
            B.Text=text
            B.Font=Enum.Font.Gotham
            B.TextSize=14
            B.BackgroundColor3=Color3.fromRGB(50,50,50)
            B.TextColor3=Color3.new(1,1,1)
            B.Parent=FolderFrame
            Round(B,6)
            B.MouseButton1Click:Connect(function()
                if Alive and callback then callback() end
            end)
        end

        -- Toggle
        function Elements:Toggle(text,callback)
            local state=false
            local T=Instance.new("TextButton")
            T.Size=UDim2.new(1,0,0,32)
            T.BackgroundColor3=Color3.fromRGB(50,50,50)
            T.Text=text.." : OFF"
            T.TextColor3=Color3.new(1,1,1)
            T.Font=Enum.Font.Gotham
            T.Parent=FolderFrame
            Round(T,6)
            T.MouseButton1Click:Connect(function()
                state=not state
                T.Text=text.." : "..(state and "ON" or "OFF")
                if callback then callback(state) end
            end)
        end

        -- Slider
        function Elements:Slider(text,min,max,default,callback)
            min=min or 0
            max=max or 100
            default=default or min
            local Slider=Instance.new("Frame")
            Slider.Size=UDim2.new(1,0,0,40)
            Slider.BackgroundTransparency=1
            Slider.Parent=FolderFrame

            local Label=Instance.new("TextLabel")
            Label.Size=UDim2.new(1,0,0,16)
            Label.Text=text.." : "..default
            Label.TextColor3=Color3.new(1,1,1)
            Label.Font=Enum.Font.Gotham
            Label.TextSize=13
            Label.BackgroundTransparency=1
            Label.Parent=Slider

            local Bar=Instance.new("Frame")
            Bar.Size=UDim2.new(1,0,0,10)
            Bar.Position = UDim2.new(0,0,0,22)
            Bar.BackgroundColor3=Color3.fromRGB(55,55,55)
            Bar.Parent=Slider
            Round(Bar,6)

            local Fill=Instance.new("Frame")
            Fill.Size=UDim2.new((default-min)/(max-min),0,1,0)
            Fill.BackgroundColor3=Color3.fromRGB(120,120,255)
            Fill.Parent=Bar
            Round(Fill,6)

            local dragging=false
            local function SetValue(x)
                local percent = math.clamp((x-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1)
                local value=math.floor(min+(max-min)*percent)
                Fill.Size=UDim2.new(percent,0,1,0)
                Label.Text=text.." : "..value
                if callback then callback(value) end
            end
            Bar.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=true
                    SetValue(i.Position.X)
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                    SetValue(i.Position.X)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=false
                end
            end)
        end

        -- Textbox
        function Elements:Textbox(text,callback)
            local Box=Instance.new("TextBox")
            Box.PlaceholderText=text
            Box.Size=UDim2.new(1,0,0,32)
            Box.BackgroundColor3=Color3.fromRGB(50,50,50)
            Box.TextColor3=Color3.new(1,1,1)
            Box.Font=Enum.Font.Gotham
            Box.Parent=FolderFrame
            Round(Box,6)
            Box.FocusLost:Connect(function()
                if Alive and callback then callback(Box.Text) end
            end)
        end

        -- Bind
        function Elements:Bind(text,key,callback)
            local Current=key
            local B=Instance.new("TextButton")
            B.Text=text.." : "..tostring(key.Name)
            B.Size=UDim2.new(1,0,0,32)
            B.BackgroundColor3=Color3.fromRGB(50,50,50)
            B.TextColor3=Color3.new(1,1,1)
            B.Font=Enum.Font.Gotham
            B.Parent=FolderFrame
            Round(B,6)

            local Listening=false
            B.MouseButton1Click:Connect(function()
                Listening=true
                B.Text=text.." : ... (press key)"
            end)

            table.insert(Connections,UIS.InputBegan:Connect(function(input,gp)
                if gp then return end
                if Listening and input.UserInputType==Enum.UserInputType.Keyboard then
                    Current=input.KeyCode
                    B.Text=text.." : "..tostring(Current.Name)
                    Listening=false
                elseif input.KeyCode==Current then
                    if Alive and callback then callback() end
                end
            end))
        end

        -- Dropdown (scrollable, opens to the right)
        function Elements:Dropdown(name,options,callback)
            local DropButton = Instance.new("TextButton")
            DropButton.Text=name.." ▼"
            DropButton.Size=UDim2.new(1,0,0,32)
            DropButton.BackgroundColor3=Color3.fromRGB(50,50,50)
            DropButton.TextColor3=Color3.new(1,1,1)
            DropButton.Font=Enum.Font.Gotham
            DropButton.Parent=FolderFrame
            Round(DropButton,6)

            local DropFrame = Instance.new("Frame")
            DropFrame.Size=UDim2.new(0,160,0,math.min(#options*30,150))
            DropFrame.Position=UDim2.new(1,5,0,0)
            DropFrame.BackgroundColor3=Color3.fromRGB(35,35,35)
            DropFrame.Visible=false
            DropFrame.Parent=FolderFrame
            Round(DropFrame,6)

            local DropScroll = Instance.new("ScrollingFrame")
            DropScroll.Size = UDim2.new(1,0,1,0)
            DropScroll.CanvasSize = UDim2.new(0,0,0,#options*30)
            DropScroll.ScrollBarThickness = 6
            DropScroll.BackgroundTransparency = 1
            DropScroll.Parent = DropFrame

            local DropLayout = Instance.new("UIListLayout")
            DropLayout.FillDirection = Enum.FillDirection.Vertical
            DropLayout.Padding = UDim.new(0,4)
            DropLayout.Parent = DropScroll

            for i,opt in pairs(options) do
                local Btn=Instance.new("TextButton")
                Btn.Text=opt
                Btn.Size=UDim2.new(1,0,0,30)
                Btn.BackgroundColor3=Color3.fromRGB(60,60,60)
                Btn.TextColor3=Color3.new(1,1,1)
                Btn.Font=Enum.Font.Gotham
                Btn.Parent=DropScroll
                Round(Btn,6)

                Btn.MouseButton1Click:Connect(function()
                    DropButton.Text=name.." : "..opt.." ▼"
                    DropFrame.Visible=false
                    if Alive and callback then callback(opt) end
                end)
            end

            DropButton.MouseButton1Click:Connect(function()
                DropFrame.Visible = not DropFrame.Visible
            end)
        end

        return Elements
    end

    Notify(title.." loaded successfully!",ScreenGui)
    return Window
end

return Library
