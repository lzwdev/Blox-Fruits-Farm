-- Chest & Fruit Farm Script - Premium Custom UI mit Serverhop v5.0
-- Features: Chest Farm, Fruit ESP, Auto Collect Fruit, Noclip, Speed 300, Auto Serverhop, Auto Marines/Pirates

if not game:IsLoaded() then
    game.Loaded:Wait()
end
repeat task.wait() until game:GetService("Players") and game:GetService("Workspace") and game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- ==================== NOCLIP ====================
local noclipActive = true

local function EnableNoclip(c)
    if not c then return end
    pcall(function() for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end)
end

local function DisableNoclip(c)
    if not c then return end
    pcall(function() for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end)
end

LP.CharacterAdded:Connect(function(c) task.wait(0.1); if noclipActive then EnableNoclip(c) end end)
RunService.Stepped:Connect(function() if noclipActive and LP.Character then EnableNoclip(LP.Character) end end)

-- ==================== SETTINGS ====================
local SettingsFile = "ChestFruitFarm_Settings.json"
local DefaultSettings = {
    ChestESP = false, FruitESP = false, Noclip = true,
    AutoServerhop = false, ServerhopInterval = 100,
    AutoChestFarm = false, AutoFruit = false,
    AutoMarines = false, AutoPirates = false,
    ChestTarget = 100
}

local function SaveSettings()
    local s = {
        ChestESP = _G.ChestESP, FruitESP = _G.FruitESP, Noclip = noclipActive,
        AutoServerhop = _G.AutoServerhop, ServerhopInterval = _G.ServerhopInterval,
        AutoChestFarm = _G.ChestFarm, AutoFruit = _G.AutoFruit,
        AutoMarines = _G.AutoMarines, AutoPirates = _G.AutoPirates,
        ChestTarget = _G.ChestTarget
    }
    if writefile then pcall(function() writefile(SettingsFile, HttpService:JSONEncode(s)) end) end
end

local function LoadSettings()
    local s = DefaultSettings
    if readfile then pcall(function() local d = readfile(SettingsFile); local l = HttpService:JSONDecode(d); for k,v in pairs(l) do s[k]=v end end) end
    return s
end

-- ==================== VARIABLEN ====================
_G.ChestFarm = false; _G.ChestESP = false; _G.FruitESP = false; _G.AutoFruit = false
_G.AutoServerhop = false; _G.AutoMarines = false; _G.AutoPirates = false
_G.ServerhopInterval = 100; _G.ChestTarget = 100

local saved = LoadSettings()
_G.ChestESP = saved.ChestESP; _G.FruitESP = saved.FruitESP; noclipActive = saved.Noclip
_G.AutoServerhop = saved.AutoServerhop; _G.ServerhopInterval = saved.ServerhopInterval
_G.ChestFarm = saved.AutoChestFarm or false; _G.AutoFruit = saved.AutoFruit or false
_G.AutoMarines = saved.AutoMarines or false; _G.AutoPirates = saved.AutoPirates or false
_G.ChestTarget = saved.ChestTarget or 100

local espObjects = {}; local fruitEspObjects = {}; local currentTween = nil
local lastTeleportTime = 0; local minimized = false; local isAnimating = false; local currentTab = "Main"
local currentChestTarget = nil; local chestArrivedTime = 0; local ignoredChests = {}
local chestsCollected = 0; local totalChestsEver = 0; local lastServerhopTime = 0
local isServerhopping = false; local BLOX_FRUITS_PLACE_ID = 2753915549

-- ==================== TEAM JOIN ====================
local function JoinTeam(team)
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", team)
        end
    end)
end

-- ==================== TWEEN HELPER ====================
local function Tween(obj, props, dur)
    local t = TweenService:Create(obj, TweenInfo.new(dur or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    t:Play(); return t
end

-- ==================== UI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChestFruitFarmUI"; ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 560); MainFrame.Position = UDim2.new(0.5, -170, 0.5, -280)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25); MainFrame.BorderSizePixel = 0
MainFrame.Active = true; MainFrame.Draggable = true; MainFrame.ClipsDescendants = true; MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Gradient Top Bar
local TopGradient = Instance.new("Frame")
TopGradient.Size = UDim2.new(1, 0, 0, 3); TopGradient.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
TopGradient.BorderSizePixel = 0; TopGradient.ZIndex = 15; TopGradient.Parent = MainFrame
Instance.new("UICorner", TopGradient).CornerRadius = UDim.new(0, 10)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28); CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60); CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"; CloseBtn.TextColor3 = Color3.fromRGB(255,255,255); CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.ZIndex = 10; CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    if isAnimating then return end; isAnimating = true
    _G.ChestFarm=false; _G.ChestESP=false; _G.FruitESP=false; _G.AutoFruit=false; _G.AutoServerhop=false; noclipActive=false
    if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end
    SaveSettings()
    for _,d in pairs(espObjects) do if d.BB then d.BB:Destroy() end end; espObjects={}
    for _,d in pairs(fruitEspObjects) do if d.BB then d.BB:Destroy() end end; fruitEspObjects={}
    Tween(MainFrame, {Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0)}, 0.25).Completed:Connect(function() ScreenGui:Destroy() end)
end)

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28); MinBtn.Position = UDim2.new(1, -66, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0); MinBtn.BorderSizePixel = 0
MinBtn.Text = "—"; MinBtn.TextColor3 = Color3.fromRGB(255,255,255); MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold; MinBtn.ZIndex = 10; MinBtn.Parent = MainFrame
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

MinBtn.MouseButton1Click:Connect(function()
    if isAnimating then return end; isAnimating=true; minimized=not minimized
    Tween(MainFrame, {Size=minimized and UDim2.new(0,340,0,45) or UDim2.new(0,340,0,560)}, 0.3); task.wait(0.3); isAnimating=false
end)

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,45); TitleBar.BackgroundColor3 = Color3.fromRGB(20,20,35); TitleBar.BorderSizePixel = 0; TitleBar.ZIndex = 5; TitleBar.Parent = MainFrame
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1,-80,1,0); TitleText.Position = UDim2.new(0,15,0,0); TitleText.BackgroundTransparency = 1
TitleText.Text = "⚡ Chest & Fruit Farm v5"; TitleText.TextColor3 = Color3.fromRGB(255,255,255)
TitleText.TextSize = 15; TitleText.Font = Enum.Font.GothamBlack; TitleText.TextXAlignment = Enum.TextXAlignment.Left; TitleText.ZIndex = 6; TitleText.Parent = TitleBar

-- Tabs
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1,0,0,38); TabFrame.Position = UDim2.new(0,0,0,45); TabFrame.BackgroundColor3 = Color3.fromRGB(18,18,30)
TabFrame.BorderSizePixel = 0; TabFrame.ZIndex = 5; TabFrame.Parent = MainFrame

local TabSlider = Instance.new("Frame")
TabSlider.Size = UDim2.new(0.2,-4,0,3); TabSlider.Position = UDim2.new(0,3,1,-3)
TabSlider.BackgroundColor3 = Color3.fromRGB(80,130,255); TabSlider.BorderSizePixel = 0; TabSlider.ZIndex = 7; TabSlider.Parent = TabFrame
Instance.new("UICorner", TabSlider).CornerRadius = UDim.new(0,2)

local function MakeTab(name, x)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0.2,-4,1,-4); b.Position = UDim2.new(x, 2, 0, 2)
    b.BackgroundColor3 = Color3.fromRGB(25,25,40); b.BorderSizePixel = 0; b.Text = name
    b.TextColor3 = Color3.fromRGB(150,150,170); b.TextSize = 11; b.Font = Enum.Font.GothamBold; b.ZIndex = 6; b.Parent = TabFrame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6); return b
end

local MainTab = MakeTab("Main", 0); MainTab.BackgroundColor3 = Color3.fromRGB(35,35,60); MainTab.TextColor3 = Color3.fromRGB(255,255,255)
local FruitTab = MakeTab("Fruits", 0.2); local ServerTab = MakeTab("Server", 0.4)
local TeamTab = MakeTab("Team", 0.6); local SetTab = MakeTab("Set", 0.8)

-- Content
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1,0,1,-88); ContentFrame.Position = UDim2.new(0,0,0,85); ContentFrame.BackgroundTransparency = 1
ContentFrame.ClipsDescendants = true; ContentFrame.ZIndex = 5; ContentFrame.Parent = MainFrame

local function MakePage()
    local p = Instance.new("ScrollingFrame"); p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
    p.ScrollBarThickness = 3; p.ScrollBarImageColor3 = Color3.fromRGB(80,80,100); p.CanvasSize = UDim2.new(0,0,0,600); p.ZIndex = 5; p.Parent = ContentFrame
    local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0,5); l.Parent = p
    local pad = Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10); pad.PaddingTop=UDim.new(0,6); pad.Parent = p
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() p.CanvasSize = UDim2.new(0,0,0,l.AbsoluteContentSize.Y+10) end)
    return p
end

local MainPage = MakePage(); MainPage.Position = UDim2.new(0,0,0,0)
local FruitPage = MakePage(); FruitPage.Position = UDim2.new(1,0,0,0)
local ServerPage = MakePage(); ServerPage.Position = UDim2.new(2,0,0,0)
local TeamPage = MakePage(); TeamPage.Position = UDim2.new(3,0,0,0)
local SetPage = MakePage(); SetPage.Position = UDim2.new(4,0,0,0)

-- Tab Switch
local function SwitchTab(tab)
    if isAnimating or currentTab==tab then return end; isAnimating=true; currentTab=tab
    local idx = ({Main=0,Fruit=1,Server=2,Team=3,Settings=4})[tab] or 0
    local cols = {Color3.fromRGB(80,130,255),Color3.fromRGB(255,150,50),Color3.fromRGB(0,200,200),Color3.fromRGB(0,180,100),Color3.fromRGB(150,80,255)}
    local x = idx*0.2
    Tween(TabSlider, {Position=UDim2.new(x,3-idx,1,-3),BackgroundColor3=cols[idx+1]}, 0.3)
    local off = -idx
    Tween(MainPage, {Position=UDim2.new(off,0,0,0)}, 0.35); Tween(FruitPage, {Position=UDim2.new(1+off,0,0,0)}, 0.35)
    Tween(ServerPage, {Position=UDim2.new(2+off,0,0,0)}, 0.35); Tween(TeamPage, {Position=UDim2.new(3+off,0,0,0)}, 0.35)
    Tween(SetPage, {Position=UDim2.new(4+off,0,0,0)}, 0.35)
    local tabs = {MainTab,FruitTab,ServerTab,TeamTab,SetTab}
    for i,t in pairs(tabs) do local a=i==idx+1; Tween(t,{BackgroundColor3=a and Color3.fromRGB(35,35,60) or Color3.fromRGB(25,25,40),TextColor3=a and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,170)},0.2) end
    task.delay(0.35, function() isAnimating=false end)
end

MainTab.MouseButton1Click:Connect(function() SwitchTab("Main") end)
FruitTab.MouseButton1Click:Connect(function() SwitchTab("Fruit") end)
ServerTab.MouseButton1Click:Connect(function() SwitchTab("Server") end)
TeamTab.MouseButton1Click:Connect(function() SwitchTab("Team") end)
SetTab.MouseButton1Click:Connect(function() SwitchTab("Settings") end)

-- ==================== UI ELEMENTS ====================
local function AddSection(p, n, col)
    local s = Instance.new("Frame"); s.Size=UDim2.new(1,0,0,28); s.BackgroundColor3=col or Color3.fromRGB(35,35,55); s.BorderSizePixel=0; s.Parent=p
    Instance.new("UICorner",s).CornerRadius=UDim.new(0,5)
    local t = Instance.new("TextLabel"); t.Size=UDim2.new(1,-10,1,0); t.Position=UDim2.new(0,10,0,0); t.BackgroundTransparency=1
    t.Text=n; t.TextColor3=Color3.fromRGB(200,200,230); t.TextSize=12; t.Font=Enum.Font.GothamBold; t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=s
    return s
end

local function AddToggle(p, n, d, cb)
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,38); f.BackgroundColor3=Color3.fromRGB(25,25,40); f.BorderSizePixel=0; f.Parent=p
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local txt = Instance.new("TextLabel"); txt.Size=UDim2.new(0.6,-10,1,0); txt.Position=UDim2.new(0,10,0,0); txt.BackgroundTransparency=1
    txt.Text=n; txt.TextColor3=Color3.fromRGB(230,230,240); txt.TextSize=12; txt.Font=Enum.Font.Gotham; txt.TextXAlignment=Enum.TextXAlignment.Left; txt.Parent=f
    local btn = Instance.new("Frame"); btn.Size=UDim2.new(0,44,0,22); btn.Position=UDim2.new(1,-52,0.5,-11)
    btn.BackgroundColor3=d and Color3.fromRGB(0,180,90) or Color3.fromRGB(60,60,80); btn.BorderSizePixel=0; btn.Parent=f
    Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0)
    local dot = Instance.new("Frame"); dot.Size=UDim2.new(0,18,0,18); dot.Position=d and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    dot.BackgroundColor3=Color3.fromRGB(255,255,255); dot.BorderSizePixel=0; dot.Parent=btn; Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local on = d
    local function up()
        Tween(btn,{BackgroundColor3=on and Color3.fromRGB(0,180,90) or Color3.fromRGB(60,60,80)},0.2)
        Tween(dot,{Position=on and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)},0.2)
    end
    f.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then on=not on; up(); pcall(cb,on) end end)
    f.MouseEnter:Connect(function() Tween(f,{BackgroundColor3=Color3.fromRGB(32,32,50)},0.15) end)
    f.MouseLeave:Connect(function() Tween(f,{BackgroundColor3=Color3.fromRGB(25,25,40)},0.15) end)
    return f
end

local function AddLabel(p, t, col)
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,28); f.BackgroundColor3=Color3.fromRGB(25,25,40); f.BorderSizePixel=0; f.Parent=p
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local d = Instance.new("Frame"); d.Size=UDim2.new(0,7,0,7); d.Position=UDim2.new(0,8,0.5,-3); d.BackgroundColor3=col or Color3.fromRGB(0,255,100); d.BorderSizePixel=0; d.Parent=f
    Instance.new("UICorner",d).CornerRadius=UDim.new(1,0)
    local l = Instance.new("TextLabel"); l.Size=UDim2.new(1,-22,1,0); l.Position=UDim2.new(0,18,0,0); l.BackgroundTransparency=1
    l.Text=t; l.TextColor3=Color3.fromRGB(200,200,220); l.TextSize=11; l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
    return l, d
end

local function AddButton(p, t, col, cb)
    local b = Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,34); b.BackgroundColor3=col or Color3.fromRGB(50,50,80); b.BorderSizePixel=0
    b.Text=t; b.TextColor3=Color3.fromRGB(255,255,255); b.TextSize=13; b.Font=Enum.Font.GothamBold; b.Parent=p
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5); b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function() Tween(b,{BackgroundColor3=Color3.fromRGB(80,80,120)},0.15) end)
    b.MouseLeave:Connect(function() Tween(b,{BackgroundColor3=col or Color3.fromRGB(50,50,80)},0.15) end)
end

local function AddSlider(p, n, min, max, val, cb)
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,60); f.BackgroundColor3=Color3.fromRGB(25,25,40); f.BorderSizePixel=0; f.Parent=p
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local txt = Instance.new("TextLabel"); txt.Size=UDim2.new(1,-20,0,20); txt.Position=UDim2.new(0,10,0,2); txt.BackgroundTransparency=1
    txt.Text=n..": "..val; txt.TextColor3=Color3.fromRGB(230,230,240); txt.TextSize=12; txt.Font=Enum.Font.Gotham; txt.TextXAlignment=Enum.TextXAlignment.Left; txt.Parent=f
    local sliderFrame = Instance.new("Frame"); sliderFrame.Size=UDim2.new(1,-20,0,6); sliderFrame.Position=UDim2.new(0,10,0,30)
    sliderFrame.BackgroundColor3=Color3.fromRGB(60,60,80); sliderFrame.BorderSizePixel=0; sliderFrame.Parent=f
    Instance.new("UICorner",sliderFrame).CornerRadius=UDim.new(1,0)
    local fill = Instance.new("Frame"); fill.Size=UDim2.new((val-min)/(max-min),0,1,0); fill.BackgroundColor3=Color3.fromRGB(80,130,255); fill.BorderSizePixel=0; fill.Parent=sliderFrame
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob = Instance.new("TextButton"); knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new((val-min)/(max-min),-8,0.5,-8)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0; knob.Text=""; knob.Parent=sliderFrame
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    
    local dragging = false
    local function updateKnob(input)
        local relX = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        local newVal = math.floor(min + relX * (max - min))
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -8, 0.5, -8)
        txt.Text = n..": "..newVal
        pcall(cb, newVal)
    end
    
    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then updateKnob(i) end end)
    sliderFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then updateKnob(i); dragging = true end end)
    
    return f, txt
end

local function AddDropdown(p, n, items, default, cb)
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,38); f.BackgroundColor3=Color3.fromRGB(25,25,40); f.BorderSizePixel=0; f.Parent=p
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local txt = Instance.new("TextLabel"); txt.Size=UDim2.new(0.5,-10,1,0); txt.Position=UDim2.new(0,10,0,0); txt.BackgroundTransparency=1
    txt.Text=n; txt.TextColor3=Color3.fromRGB(230,230,240); txt.TextSize=12; txt.Font=Enum.Font.Gotham; txt.TextXAlignment=Enum.TextXAlignment.Left; txt.Parent=f
    local selected = default or items[1]
    local btn = Instance.new("TextButton"); btn.Size=UDim2.new(0.45,-10,0,28); btn.Position=UDim2.new(0.55,0,0.5,-14)
    btn.BackgroundColor3=Color3.fromRGB(50,50,80); btn.BorderSizePixel=0; btn.Text=selected; btn.TextColor3=Color3.fromRGB(255,255,255); btn.TextSize=11; btn.Font=Enum.Font.Gotham; btn.Parent=f
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    
    local open = false
    local dropFrame = Instance.new("Frame"); dropFrame.Size=UDim2.new(0.45,-10,0,#items*28); dropFrame.Position=UDim2.new(0.55,0,1,2)
    dropFrame.BackgroundColor3=Color3.fromRGB(40,40,60); dropFrame.BorderSizePixel=0; dropFrame.Visible=false; dropFrame.ZIndex=20; dropFrame.Parent=f
    Instance.new("UICorner",dropFrame).CornerRadius=UDim.new(0,5)
    local dropList = Instance.new("UIListLayout"); dropList.Parent=dropFrame
    
    for _, item in pairs(items) do
        local ibtn = Instance.new("TextButton"); ibtn.Size=UDim2.new(1,0,0,28); ibtn.BackgroundTransparency=1; ibtn.Text=item
        ibtn.TextColor3=Color3.fromRGB(200,200,220); ibtn.TextSize=11; ibtn.Font=Enum.Font.Gotham; ibtn.ZIndex=21; ibtn.Parent=dropFrame
        ibtn.MouseButton1Click:Connect(function() selected=item; btn.Text=item; dropFrame.Visible=false; open=false; pcall(cb, item) end)
        ibtn.MouseEnter:Connect(function() Tween(ibtn,{BackgroundColor3=Color3.fromRGB(60,60,90)},0.1) end)
        ibtn.MouseLeave:Connect(function() Tween(ibtn,{BackgroundTransparency=1},0.1) end)
    end
    
    btn.MouseButton1Click:Connect(function() open=not open; dropFrame.Visible=open end)
    return f
end

-- Status labels
local statusLabel, statusDot, chestLabel, fruitLabel, timeoutLabel, hopLabel, totalLabel, teamLabel

local function SetStatus(t,a) if statusLabel then statusLabel.Text=t; Tween(statusDot,{BackgroundColor3=a and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,80,80)},0.3) end end
local function SetChest(t) if chestLabel then chestLabel.Text=t end end
local function SetFruit(t) if fruitLabel then fruitLabel.Text=t end end
local function SetTimeout(t) if timeoutLabel then timeoutLabel.Text=t end end
local function SetHop(t) if hopLabel then hopLabel.Text=t end end
local function SetTotal(t) if totalLabel then totalLabel.Text=t end end
local function SetTeam(t) if teamLabel then teamLabel.Text=t end end

-- ==================== SERVERHOP ====================
local function Serverhop()
    if isServerhopping then return end; isServerhopping=true; SaveSettings(); task.wait(1)
    pcall(function() TeleportService:Teleport(BLOX_FRUITS_PLACE_ID, LP) end); task.wait(5); isServerhopping=false
end

-- ==================== UI AUFBAUEN ====================
-- Main Tab
AddSection(MainPage, "🎯 Chest Farm", Color3.fromRGB(40, 40, 60))
AddToggle(MainPage, "Auto Farm Chest", _G.ChestFarm, function(v)
    _G.ChestFarm=v; SaveSettings()
    if v then SetStatus("Running",true); ignoredChests={}; currentChestTarget=nil; chestArrivedTime=0; chestsCollected=0; SetTimeout("Ready")
    else SetStatus("Idle",false); if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end; ignoredChests={}; currentChestTarget=nil; chestArrivedTime=0; SetTimeout("-") end
end)
AddToggle(MainPage, "Chest ESP", _G.ChestESP, function(v) _G.ChestESP=v; SaveSettings(); if not v then for _,d in pairs(espObjects) do if d.BB then d.BB:Destroy() end end; espObjects={} end end)
AddToggle(MainPage, "Noclip", noclipActive, function(v) noclipActive=v; SaveSettings(); if not v and LP.Character then DisableNoclip(LP.Character) elseif v and LP.Character then EnableNoclip(LP.Character) end end)

AddSection(MainPage, "📊 Status", Color3.fromRGB(40, 40, 60))
statusLabel, statusDot = AddLabel(MainPage, "Status: "..(_G.ChestFarm and "Running" or "Idle"), Color3.fromRGB(0,255,100))
chestLabel, _ = AddLabel(MainPage, "Chests this session: 0", Color3.fromRGB(255,200,0))
timeoutLabel, _ = AddLabel(MainPage, "Timeout: -", Color3.fromRGB(255,150,0))
totalLabel, _ = AddLabel(MainPage, "Total collected: "..totalChestsEver, Color3.fromRGB(100,200,255))

-- Fruit Tab
AddSection(FruitPage, "🍎 Fruit Farm", Color3.fromRGB(40, 40, 60))
AddToggle(FruitPage, "Fruit ESP", _G.FruitESP, function(v) _G.FruitESP=v; SaveSettings(); if not v then for _,d in pairs(fruitEspObjects) do if d.BB then d.BB:Destroy() end end; fruitEspObjects={} end end)
AddToggle(FruitPage, "Auto Collect Fruit", _G.AutoFruit, function(v) _G.AutoFruit=v; SaveSettings() end)
AddSection(FruitPage, "📊 Fruit Stats", Color3.fromRGB(40, 40, 60))
fruitLabel, _ = AddLabel(FruitPage, "Fruits found: 0", Color3.fromRGB(255,100,100))

-- Server Tab
AddSection(ServerPage, "🔄 Serverhop", Color3.fromRGB(40, 40, 60))
AddToggle(ServerPage, "Auto Serverhop", _G.AutoServerhop, function(v) _G.AutoServerhop=v; SaveSettings(); if v then chestsCollected=0; SetHop("Hop at: ".._G.ChestTarget) end end)

local sliderFrame, sliderText = AddSlider(ServerPage, "Chests until hop", 20, 250, _G.ChestTarget, function(v)
    _G.ChestTarget=v; SaveSettings(); SetHop("Hop at: "..v)
end)

AddButton(ServerPage, "Serverhop NOW", Color3.fromRGB(200, 50, 50), Serverhop)
AddSection(ServerPage, "📊 Hop Stats", Color3.fromRGB(40, 40, 60))
hopLabel, _ = AddLabel(ServerPage, "Hop at: ".._G.ChestTarget, Color3.fromRGB(0,200,200))

-- Team Tab
AddSection(TeamPage, "👥 Team Join", Color3.fromRGB(40, 40, 60))
AddButton(TeamPage, "🔵 Join Marines", Color3.fromRGB(30, 80, 180), function() JoinTeam("Marines"); SetTeam("Team: Marines") end)
AddButton(TeamPage, "🔴 Join Pirates", Color3.fromRGB(180, 30, 30), function() JoinTeam("Pirates"); SetTeam("Team: Pirates") end)

AddSection(TeamPage, "🤖 Auto Join", Color3.fromRGB(40, 40, 60))
AddDropdown(TeamPage, "Auto Join", {"None", "Marines", "Pirates"}, _G.AutoMarines and "Marines" or _G.AutoPirates and "Pirates" or "None", function(v)
    _G.AutoMarines = (v == "Marines")
    _G.AutoPirates = (v == "Pirates")
    SaveSettings()
    if v == "Marines" then JoinTeam("Marines"); SetTeam("Team: Marines")
    elseif v == "Pirates" then JoinTeam("Pirates"); SetTeam("Team: Pirates")
    else SetTeam("Team: None") end
end)

AddSection(TeamPage, "📊 Team Status", Color3.fromRGB(40, 40, 60))
teamLabel, _ = AddLabel(TeamPage, "Team: "..(_G.AutoMarines and "Marines" or _G.AutoPirates and "Pirates" or "None"), Color3.fromRGB(0,200,200))

-- Settings Tab
AddSection(SetPage, "ℹ️ Info", Color3.fromRGB(40, 40, 60))
AddLabel(SetPage, "Chest & Fruit Farm v5.0", Color3.fromRGB(255,255,100))
AddLabel(SetPage, "Speed: 300 | Timeout: 5s", Color3.fromRGB(150,150,200))
AddButton(SetPage, "💾 Save Settings", Color3.fromRGB(50, 180, 50), function() SaveSettings(); SetStatus("Saved!", true) end)
AddButton(SetPage, "🗑️ Unload Script", Color3.fromRGB(255, 60, 60), function()
    if isAnimating then return end; isAnimating=true
    _G.ChestFarm=false; _G.ChestESP=false; _G.FruitESP=false; _G.AutoFruit=false; _G.AutoServerhop=false; _G.AutoMarines=false; _G.AutoPirates=false; noclipActive=false
    if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end; SaveSettings()
    for _,d in pairs(espObjects) do if d.BB then d.BB:Destroy() end end; espObjects={}
    for _,d in pairs(fruitEspObjects) do if d.BB then d.BB:Destroy() end end; fruitEspObjects={}
    Tween(MainFrame,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)},0.25).Completed:Connect(function() ScreenGui:Destroy() end)
end)

-- ==================== FUNCTIONS ====================
local function round(n) return math.floor(n+0.5) end

local function GetChestCount()
    local c=0
    pcall(function() for _,ch in pairs(CollectionService:GetTagged("_ChestTagged")) do if ch and ch:IsA("BasePart") and not ch:GetAttribute("IsDisabled") then c=c+1 end end end)
    return c
end

local function GetFruitCount()
    local c=0
    pcall(function() for _,o in pairs(workspace:GetChildren()) do if o and o:IsA("BasePart") and string.find(o.Name,"Fruit") and o:FindFirstChild("Handle") then c=c+1 end end end)
    return c
end

-- ESP Functions
local function CreateFruitESP(f)
    if not f or fruitEspObjects[f] then return end; local h=f:FindFirstChild("Handle"); if not h or not h:IsA("BasePart") then return end
    pcall(function()
        local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,160,0,30); bb.Adornee=h; bb.AlwaysOnTop=true; bb.StudsOffset=Vector3.new(0,2,0); bb.Parent=h
        local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(0,0,0); bg.BackgroundTransparency=0.5; bg.BorderSizePixel=0; bg.Parent=bb; Instance.new("UICorner",bg).CornerRadius=UDim.new(0,4)
        local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Text="Fruit"; l.TextColor3=Color3.fromRGB(255,100,100); l.TextScaled=true; l.Font=Enum.Font.GothamBold; l.Parent=bb
        fruitEspObjects[f]={BB=bb,Lbl=l}
    end)
end

local function UpdateFruitESP()
    local h=LP.Character and LP.Character:FindFirstChild("Head"); if not h then return end; local p=h.Position
    for _,o in pairs(workspace:GetChildren()) do pcall(function() if o and string.find(o.Name,"Fruit") and o:FindFirstChild("Handle") then if _G.FruitESP then if not fruitEspObjects[o] then CreateFruitESP(o) end; local e=fruitEspObjects[o]; if e and e.Lbl and o.Handle then local d=round((p-o.Handle.Position).Magnitude/3); e.Lbl.Text=o.Name.." ("..d.."m)"; e.Lbl.TextColor3=d<50 and Color3.fromRGB(0,255,100) or d<150 and Color3.fromRGB(255,215,0) or Color3.fromRGB(255,100,100) end else if fruitEspObjects[o] then if fruitEspObjects[o].BB then fruitEspObjects[o].BB:Destroy() end; fruitEspObjects[o]=nil end end end end) end
end

local function CreateChestESP(ch)
    if not ch or espObjects[ch] then return end
    pcall(function()
        local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,160,0,30); bb.Adornee=ch; bb.AlwaysOnTop=true; bb.StudsOffset=Vector3.new(0,2,0); bb.Parent=ch
        local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(0,0,0); bg.BackgroundTransparency=0.5; bg.BorderSizePixel=0; bg.Parent=bb; Instance.new("UICorner",bg).CornerRadius=UDim.new(0,4)
        local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Text="Chest"; l.TextColor3=Color3.fromRGB(255,215,0); l.TextScaled=true; l.Font=Enum.Font.GothamBold; l.Parent=bb
        espObjects[ch]={BB=bb,Lbl=l}
    end)
end

local function UpdateChestESP()
    local h=LP.Character and LP.Character:FindFirstChild("Head"); if not h then return end; local p=h.Position
    for _,ch in pairs(CollectionService:GetTagged("_ChestTagged")) do pcall(function() if ch and ch:IsA("BasePart") and not ch:GetAttribute("IsDisabled") then if _G.ChestESP then if not espObjects[ch] then CreateChestESP(ch) end; local e=espObjects[ch]; if e and e.Lbl then local d=round((p-ch:GetPivot().Position).Magnitude/3); if ignoredChests[ch] then e.Lbl.Text="🚫 ("..d.."m)"; e.Lbl.TextColor3=Color3.fromRGB(255,50,50) else e.Lbl.Text="Chest ("..d.."m)"; e.Lbl.TextColor3=d<50 and Color3.fromRGB(0,255,100) or d<150 and Color3.fromRGB(255,215,0) or Color3.fromRGB(255,100,100) end end else if espObjects[ch] then if espObjects[ch].BB then espObjects[ch].BB:Destroy() end; espObjects[ch]=nil end end end end) end
end

-- ESP Loops
task.spawn(function() while task.wait(0.3) do if _G.ChestESP then UpdateChestESP(); SetChest("Chests: "..GetChestCount()) end end end)
task.spawn(function() while task.wait(0.3) do if _G.FruitESP then UpdateFruitESP(); SetFruit("Fruits: "..GetFruitCount()) end end end)

-- Find Nearest Chest
local function FindNearestChest()
    local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not r then return nil,nil end; local p=r.Position; local n=nil; local m=math.huge
    for _,ch in pairs(CollectionService:GetTagged("_ChestTagged")) do pcall(function() if ch and ch:IsA("BasePart") and not ch:GetAttribute("IsDisabled") and not ignoredChests[ch] then local d=(ch:GetPivot().Position-p).Magnitude; if d<m then m=d; n=ch end end end) end
    return n,m
end

-- Tween
local function TweenTo(pos)
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return false end
    if tick()-lastTeleportTime<0.5 then return false end
    local r=LP.Character.HumanoidRootPart; local d=(pos.Position-r.Position).Magnitude; local dur=math.max(d/300,0.1)
    if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end
    currentTween=TweenService:Create(r,TweenInfo.new(dur,Enum.EasingStyle.Linear),{CFrame=pos}); currentTween:Play(); lastTeleportTime=tick()
    task.delay(dur,function() if currentTween then currentTween=nil end end); return true
end

-- Auto Farm Chest
task.spawn(function()
    while task.wait(0.3) do
        if _G.ChestFarm then pcall(function()
            if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
            local r=LP.Character.HumanoidRootPart; local pp=r.Position
            
            -- Serverhop Check mit ChestTarget
            if _G.AutoServerhop and chestsCollected >= _G.ChestTarget and tick()-lastServerhopTime>30 then
                lastServerhopTime=tick(); SetStatus("Serverhopping! ("..chestsCollected.." chests)",true); Serverhop(); return
            end
            
            if currentChestTarget then
                local dist=(currentChestTarget:GetPivot().Position-pp).Magnitude
                if dist<10 then
                    if chestArrivedTime==0 then chestArrivedTime=tick(); SetTimeout("Timeout: 5s")
                    else local rem=math.max(0,5-(tick()-chestArrivedTime)); SetTimeout("Timeout: "..round(rem).."s")
                        if tick()-chestArrivedTime>5 then SetStatus("Bugged!",false); SetTimeout("IGNORED"); ignoredChests[currentChestTarget]=true; currentChestTarget=nil; chestArrivedTime=0; if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end; task.wait(0.5); return end
                    end
                else if chestArrivedTime>0 then SetTimeout("Moving...") end; chestArrivedTime=0 end
            end
            
            local ch,dist=FindNearestChest()
            if ch and dist then
                if ch~=currentChestTarget then currentChestTarget=ch; chestArrivedTime=0; SetTimeout("Moving..."); SetStatus("Moving ("..round(dist).."m)",true) end
                TweenTo(CFrame.new(ch:GetPivot().Position+Vector3.new(0,3,0)))
                if dist<15 then
                    chestsCollected=chestsCollected+1; totalChestsEver=totalChestsEver+1
                    SetChest("Chests this session: "..chestsCollected)
                    SetTotal("Total collected: "..totalChestsEver)
                    if _G.AutoServerhop then SetHop("Hop at: ".._G.ChestTarget.." ("..chestsCollected.."/".._G.ChestTarget..")") end
                end
            else SetStatus("No chests",false); SetTimeout("-"); currentChestTarget=nil; chestArrivedTime=0; task.wait(1) end
        end) end
    end
end)

-- Auto Collect Fruit
task.spawn(function()
    while task.wait(0.2) do
        if _G.AutoFruit and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then pcall(function()
            local r=LP.Character.HumanoidRootPart; local pp=r.Position
            for _,o in pairs(workspace:GetChildren()) do if o and o:FindFirstChild("Handle") then local h=o.Handle; if h and h:IsA("BasePart") and string.find(o.Name,"Fruit") and (h.Position-pp).Magnitude<100 then r.CFrame=CFrame.new(h.Position-Vector3.new(0,5,0)); SetStatus("Fruit: "..o.Name,true); task.wait(0.1); break end end end
        end) end
    end
end)

-- Character Events
LP.CharacterAdded:Connect(function(c)
    if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end
    lastTeleportTime=0; ignoredChests={}; currentChestTarget=nil; chestArrivedTime=0
    task.wait(0.2); if noclipActive then EnableNoclip(c) end
    if isServerhopping then isServerhopping=false; if not game:IsLoaded() then game.Loaded:Wait() end; task.wait(2)
        if _G.AutoMarines then JoinTeam("Marines"); SetTeam("Team: Marines")
        elseif _G.AutoPirates then JoinTeam("Pirates"); SetTeam("Team: Pirates") end
    end
end)

-- ==================== INIT ====================
task.wait(0.5)
SetChest("Chests this session: 0")
SetFruit("Fruits: "..GetFruitCount())
SetTimeout("-")
if _G.AutoServerhop then SetHop("Hop at: ".._G.ChestTarget) else SetHop("Hop: OFF") end
SetTotal("Total collected: "..totalChestsEver)
SetTeam("Team: "..(_G.AutoMarines and "Marines" or _G.AutoPirates and "Pirates" or "None"))
if _G.ChestFarm then SetStatus("Running",true); SetTimeout("Ready"); chestsCollected=0 end

-- Open Animation
MainFrame.Size = UDim2.new(0,0,0,0); MainFrame.Position = UDim2.new(0.5,0,0.5,0)
Tween(MainFrame, {Size=UDim2.new(0,340,0,560), Position=UDim2.new(0.5,-170,0.5,-280)}, 0.35)

-- Auto-Init
task.spawn(function()
    task.wait(1)
    if _G.AutoMarines then JoinTeam("Marines"); SetTeam("Team: Marines")
    elseif _G.AutoPirates then JoinTeam("Pirates"); SetTeam("Team: Pirates") end
    if _G.AutoServerhop then chestsCollected=0; SetHop("Hop at: ".._G.ChestTarget) end
end)

print("✅ Chest & Fruit Farm v5.0 loaded!")
print("Features: Slider 20-250 | Auto Marines/Pirates Dropdown | Better UI | Accurate Counter")
