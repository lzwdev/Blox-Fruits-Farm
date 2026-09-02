-- Chest & Fruit Farm Script - Premium Custom UI mit Serverhop v5.1
-- Features: Chest Farm, Fruit ESP, Auto Collect Fruit (mit Tween), Noclip, Speed 300, Auto Serverhop

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
_G.NoclipActive = true

local function EnableNoclip(c)
    if not c then return end
    pcall(function() for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end)
end

local function DisableNoclip(c)
    if not c then return end
    pcall(function() for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end)
end

LP.CharacterAdded:Connect(function(c) task.wait(0.1); if _G.NoclipActive then EnableNoclip(c) end end)
RunService.Stepped:Connect(function() if _G.NoclipActive and LP.Character then EnableNoclip(LP.Character) end end)

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
        ChestESP = _G.ChestESP, FruitESP = _G.FruitESP, Noclip = _G.NoclipActive,
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
_G.ChestESP = saved.ChestESP; _G.FruitESP = saved.FruitESP; _G.NoclipActive = saved.Noclip
_G.AutoServerhop = saved.AutoServerhop; _G.ServerhopInterval = saved.ServerhopInterval
_G.ChestFarm = saved.AutoChestFarm or false; _G.AutoFruit = saved.AutoFruit or false
_G.AutoMarines = saved.AutoMarines or false; _G.AutoPirates = saved.AutoPirates or false
_G.ChestTarget = saved.ChestTarget or 100

local espObjects = {}; local fruitEspObjects = {}; local currentTween = nil
local lastTeleportTime = 0; local minimized = false; local isAnimating = false; local currentTab = "Main"
local currentChestTarget = nil; local chestArrivedTime = 0; local ignoredChests = {}
local chestsCollected = 0; local totalChestsEver = 0; local lastServerhopTime = 0
local isServerhopping = false; local BLOX_FRUITS_PLACE_ID = 2753915549
local isFarmingFruit = false -- NEU: Damit Chest Farm Vorrang hat

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

-- ==================== FRUIT DETECTION ====================
local function GetFruits()
    local fruits = {}
    pcall(function()
        for _, obj in pairs(workspace:GetChildren()) do
            if obj and obj:FindFirstChild("Handle") then
                local handle = obj.Handle
                if handle and handle:IsA("BasePart") then
                    if string.find(obj.Name, "Fruit") or string.find(obj.Name:lower(), "fruit") then
                        table.insert(fruits, obj)
                    end
                end
            end
        end
    end)
    return fruits
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

-- Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28); CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60); CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"; CloseBtn.TextColor3 = Color3.fromRGB(255,255,255); CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.ZIndex = 10; CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    _G.ChestFarm=false; _G.ChestESP=false; _G.FruitESP=false; _G.AutoFruit=false; _G.AutoServerhop=false; _G.NoclipActive=false
    if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end
    SaveSettings()
    for _,d in pairs(espObjects) do if d.BB then d.BB:Destroy() end end; espObjects={}
    for _,d in pairs(fruitEspObjects) do if d.BB then d.BB:Destroy() end end; fruitEspObjects={}
    ScreenGui:Destroy()
end)

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28); MinBtn.Position = UDim2.new(1, -66, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0); MinBtn.BorderSizePixel = 0
MinBtn.Text = "—"; MinBtn.TextColor3 = Color3.fromRGB(255,255,255); MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold; MinBtn.ZIndex = 10; MinBtn.Parent = MainFrame
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Tween(MainFrame, {Size = minimized and UDim2.new(0,340,0,45) or UDim2.new(0,340,0,560)}, 0.3)
end)

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,45); TitleBar.BackgroundColor3 = Color3.fromRGB(20,20,35); TitleBar.BorderSizePixel = 0; TitleBar.Parent = MainFrame
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1,-80,1,0); TitleText.Position = UDim2.new(0,15,0,0); TitleText.BackgroundTransparency = 1
TitleText.Text = "⚡ Chest & Fruit Farm"; TitleText.TextColor3 = Color3.fromRGB(255,255,255)
TitleText.TextSize = 15; TitleText.Font = Enum.Font.GothamBlack; TitleText.TextXAlignment = Enum.TextXAlignment.Left; TitleText.Parent = TitleBar

-- Tabs
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1,0,0,38); TabFrame.Position = UDim2.new(0,0,0,45); TabFrame.BackgroundColor3 = Color3.fromRGB(18,18,30)
TabFrame.BorderSizePixel = 0; TabFrame.Parent = MainFrame

local TabSlider = Instance.new("Frame")
TabSlider.Size = UDim2.new(0.2,-4,0,3); TabSlider.Position = UDim2.new(0,3,1,-3)
TabSlider.BackgroundColor3 = Color3.fromRGB(80,130,255); TabSlider.BorderSizePixel = 0; TabSlider.Parent = TabFrame
Instance.new("UICorner", TabSlider).CornerRadius = UDim.new(0,2)

local function MakeTab(name, x)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0.2,-4,1,-4); b.Position = UDim2.new(x, 2, 0, 2)
    b.BackgroundColor3 = Color3.fromRGB(25,25,40); b.BorderSizePixel = 0; b.Text = name
    b.TextColor3 = Color3.fromRGB(150,150,170); b.TextSize = 11; b.Font = Enum.Font.GothamBold; b.Parent = TabFrame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6); return b
end

local MainTab = MakeTab("Main", 0); MainTab.BackgroundColor3 = Color3.fromRGB(35,35,60); MainTab.TextColor3 = Color3.fromRGB(255,255,255)
local FruitTab = MakeTab("Fruits", 0.2); local ServerTab = MakeTab("Server", 0.4)
local TeamTab = MakeTab("Team", 0.6); local SetTab = MakeTab("Set", 0.8)

-- Content
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1,0,1,-88); ContentFrame.Position = UDim2.new(0,0,0,85); ContentFrame.BackgroundTransparency = 1
ContentFrame.ClipsDescendants = true; ContentFrame.Parent = MainFrame

local function MakePage()
    local p = Instance.new("ScrollingFrame"); p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
    p.ScrollBarThickness = 3; p.ScrollBarImageColor3 = Color3.fromRGB(80,80,100); p.CanvasSize = UDim2.new(0,0,0,600); p.Parent = ContentFrame
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

local function SwitchTab(tab)
    if currentTab==tab then return end; currentTab=tab
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
end

MainTab.MouseButton1Click:Connect(function() SwitchTab("Main") end)
FruitTab.MouseButton1Click:Connect(function() SwitchTab("Fruit") end)
ServerTab.MouseButton1Click:Connect(function() SwitchTab("Server") end)
TeamTab.MouseButton1Click:Connect(function() SwitchTab("Team") end)
SetTab.MouseButton1Click:Connect(function() SwitchTab("Settings") end)

-- ==================== UI ELEMENTS ====================
local function AddSection(p, n)
    local s = Instance.new("Frame"); s.Size=UDim2.new(1,0,0,28); s.BackgroundColor3=Color3.fromRGB(35,35,55); s.BorderSizePixel=0; s.Parent=p
    Instance.new("UICorner",s).CornerRadius=UDim.new(0,5)
    local t = Instance.new("TextLabel"); t.Size=UDim2.new(1,-10,1,0); t.Position=UDim2.new(0,10,0,0); t.BackgroundTransparency=1
    t.Text=n; t.TextColor3=Color3.fromRGB(200,200,230); t.TextSize=12; t.Font=Enum.Font.GothamBold; t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=s
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
end

local function AddLabel(p, t)
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,28); f.BackgroundColor3=Color3.fromRGB(25,25,40); f.BorderSizePixel=0; f.Parent=p
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local d = Instance.new("Frame"); d.Size=UDim2.new(0,7,0,7); d.Position=UDim2.new(0,8,0.5,-3); d.BackgroundColor3=Color3.fromRGB(0,255,100); d.BorderSizePixel=0; d.Parent=f
    Instance.new("UICorner",d).CornerRadius=UDim.new(1,0)
    local l = Instance.new("TextLabel"); l.Size=UDim2.new(1,-22,1,0); l.Position=UDim2.new(0,18,0,0); l.BackgroundTransparency=1
    l.Text=t; l.TextColor3=Color3.fromRGB(200,200,220); l.TextSize=11; l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
    return l
end

local function AddButton(p, t, col, cb)
    local b = Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,34); b.BackgroundColor3=col or Color3.fromRGB(50,50,80); b.BorderSizePixel=0
    b.Text=t; b.TextColor3=Color3.fromRGB(255,255,255); b.TextSize=13; b.Font=Enum.Font.GothamBold; b.Parent=p
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5); b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function() Tween(b,{BackgroundColor3=Color3.fromRGB(80,80,120)},0.15) end)
    b.MouseLeave:Connect(function() Tween(b,{BackgroundColor3=col or Color3.fromRGB(50,50,80)},0.15) end)
end

-- Status Labels
local statusLabel, chestLabel, fruitLabel, timeoutLabel, hopLabel, totalLabel, teamLabel

local function SetStatus(t,a) if statusLabel then statusLabel.Text=t; end end
local function SetChest(t) if chestLabel then chestLabel.Text=t end end
local function SetFruit(t) if fruitLabel then fruitLabel.Text=t end end
local function SetTimeout(t) if timeoutLabel then timeoutLabel.Text=t end end
local function SetHop(t) if hopLabel then hopLabel.Text=t end end
local function SetTotal(t) if totalLabel then totalLabel.Text=t end end
local function SetTeam(t) if teamLabel then teamLabel.Text=t end end

-- ==================== UI AUFBAUEN ====================
AddSection(MainPage, "🎯 Chest Farm")
AddToggle(MainPage, "Auto Farm Chest", _G.ChestFarm, function(v)
    _G.ChestFarm=v; SaveSettings()
    if v then SetStatus("Running"); ignoredChests={}; currentChestTarget=nil; chestArrivedTime=0; chestsCollected=0; SetTimeout("Ready")
    else SetStatus("Idle"); if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end; ignoredChests={}; currentChestTarget=nil; chestArrivedTime=0; SetTimeout("-") end
end)
AddToggle(MainPage, "Chest ESP", _G.ChestESP, function(v) _G.ChestESP=v; SaveSettings(); if not v then for _,d in pairs(espObjects) do if d.BB then d.BB:Destroy() end end; espObjects={} end end)
AddToggle(MainPage, "Noclip", _G.NoclipActive, function(v) _G.NoclipActive=v; SaveSettings(); if not v and LP.Character then DisableNoclip(LP.Character) elseif v and LP.Character then EnableNoclip(LP.Character) end end)
AddSection(MainPage, "📊 Status")
statusLabel = AddLabel(MainPage, "Status: Idle")
chestLabel = AddLabel(MainPage, "Chests: 0")
timeoutLabel = AddLabel(MainPage, "Timeout: -")

AddSection(FruitPage, "🍎 Fruit Farm")
AddToggle(FruitPage, "Fruit ESP", _G.FruitESP, function(v) _G.FruitESP=v; SaveSettings(); if not v then for _,d in pairs(fruitEspObjects) do if d.BB then d.BB:Destroy() end end; fruitEspObjects={} end end)
AddToggle(FruitPage, "Auto Collect Fruit", _G.AutoFruit, function(v) _G.AutoFruit=v; SaveSettings() end)
AddSection(FruitPage, "📊 Fruit Stats")
fruitLabel = AddLabel(FruitPage, "Fruits: 0")

AddSection(ServerPage, "🔄 Serverhop")
AddToggle(ServerPage, "Auto Serverhop", _G.AutoServerhop, function(v) _G.AutoServerhop=v; SaveSettings(); if v then chestsCollected=0; SetHop("Hop at: ".._G.ChestTarget) end end)
AddButton(ServerPage, "Serverhop NOW", Color3.fromRGB(200, 50, 50), function()
    if isServerhopping then return end; isServerhopping=true; task.wait(1)
    pcall(function() TeleportService:Teleport(BLOX_FRUITS_PLACE_ID, LP) end); task.wait(5); isServerhopping=false
end)
AddSection(ServerPage, "📊 Hop Stats")
hopLabel = AddLabel(ServerPage, "Hop at: ".._G.ChestTarget)

AddSection(TeamPage, "👥 Team Join")
AddButton(TeamPage, "🔵 Join Marines", Color3.fromRGB(30, 80, 180), function() JoinTeam("Marines"); SetTeam("Team: Marines") end)
AddButton(TeamPage, "🔴 Join Pirates", Color3.fromRGB(180, 30, 30), function() JoinTeam("Pirates"); SetTeam("Team: Pirates") end)
AddSection(TeamPage, "📊 Team Status")
teamLabel = AddLabel(TeamPage, "Team: None")

AddSection(SetPage, "ℹ️ Info")
AddLabel(SetPage, "Chest & Fruit Farm v5.1")
AddButton(SetPage, "💾 Save Settings", Color3.fromRGB(50, 180, 50), function() SaveSettings() end)
AddButton(SetPage, "🗑️ Unload", Color3.fromRGB(255, 60, 60), function()
    _G.ChestFarm=false; _G.ChestESP=false; _G.FruitESP=false; _G.AutoFruit=false; _G.AutoServerhop=false; _G.NoclipActive=false
    if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end; SaveSettings()
    for _,d in pairs(espObjects) do if d.BB then d.BB:Destroy() end end; espObjects={}
    for _,d in pairs(fruitEspObjects) do if d.BB then d.BB:Destroy() end end; fruitEspObjects={}
    ScreenGui:Destroy()
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

-- ESP Functions (vereinfacht)
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
    for _,o in pairs(workspace:GetChildren()) do pcall(function() if o and string.find(o.Name,"Fruit") and o:FindFirstChild("Handle") then if _G.FruitESP then if not fruitEspObjects[o] then CreateFruitESP(o) end; local e=fruitEspObjects[o]; if e and e.Lbl and o.Handle then local d=round((p-o.Handle.Position).Magnitude/3); e.Lbl.Text=o.Name.." ("..d.."m)" end else if fruitEspObjects[o] then if fruitEspObjects[o].BB then fruitEspObjects[o].BB:Destroy() end; fruitEspObjects[o]=nil end end end end) end
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
    for _,ch in pairs(CollectionService:GetTagged("_ChestTagged")) do pcall(function() if ch and ch:IsA("BasePart") and not ch:GetAttribute("IsDisabled") then if _G.ChestESP then if not espObjects[ch] then CreateChestESP(ch) end; local e=espObjects[ch]; if e and e.Lbl then local d=round((p-ch:GetPivot().Position).Magnitude/3); e.Lbl.Text="Chest ("..d.."m)" end else if espObjects[ch] then if espObjects[ch].BB then espObjects[ch].BB:Destroy() end; espObjects[ch]=nil end end end end) end
end

task.spawn(function() while task.wait(0.3) do if _G.ChestESP then UpdateChestESP() end if _G.FruitESP then UpdateFruitESP(); SetFruit("Fruits: "..GetFruitCount()) end end end)

-- Find Nearest Chest
local function FindNearestChest()
    local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not r then return nil,nil end; local p=r.Position; local n=nil; local m=math.huge
    for _,ch in pairs(CollectionService:GetTagged("_ChestTagged")) do pcall(function() if ch and ch:IsA("BasePart") and not ch:GetAttribute("IsDisabled") and not ignoredChests[ch] then local d=(ch:GetPivot().Position-p).Magnitude; if d<m then m=d; n=ch end end end) end
    return n,m
end

-- Tween to position
local function TweenTo(pos)
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return false end
    if tick()-lastTeleportTime<0.5 then return false end
    local r=LP.Character.HumanoidRootPart; local d=(pos.Position-r.Position).Magnitude; local dur=math.max(d/300,0.1)
    if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end
    currentTween=TweenService:Create(r,TweenInfo.new(dur,Enum.EasingStyle.Linear),{CFrame=pos}); currentTween:Play(); lastTeleportTime=tick()
    task.delay(dur,function() if currentTween then currentTween=nil end end); return true
end

-- ==================== AUTO FARM CHEST (PRIORITÄT) ====================
task.spawn(function()
    while task.wait(0.3) do
        if _G.ChestFarm and not isFarmingFruit then -- Chest Farm hat VORRANG
            pcall(function()
                if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
                local r=LP.Character.HumanoidRootPart; local pp=r.Position
                
                if _G.AutoServerhop and chestsCollected >= _G.ChestTarget and tick()-lastServerhopTime>30 then
                    lastServerhopTime=tick(); isServerhopping=true; task.wait(1); pcall(function() TeleportService:Teleport(BLOX_FRUITS_PLACE_ID,LP) end); task.wait(5); isServerhopping=false; return
                end
                
                if currentChestTarget then
                    local dist=(currentChestTarget:GetPivot().Position-pp).Magnitude
                    if dist<10 then
                        if chestArrivedTime==0 then chestArrivedTime=tick(); SetTimeout("Timeout: 5s")
                        else local rem=math.max(0,5-(tick()-chestArrivedTime)); SetTimeout("Timeout: "..round(rem).."s")
                            if tick()-chestArrivedTime>5 then ignoredChests[currentChestTarget]=true; currentChestTarget=nil; chestArrivedTime=0; if currentTween then pcall(function() currentTween:Cancel() end); currentTween=nil end; task.wait(0.5); return end
                        end
                    else if chestArrivedTime>0 then SetTimeout("Moving...") end; chestArrivedTime=0 end
                end
                
                local ch,dist=FindNearestChest()
                if ch and dist then
                    if ch~=currentChestTarget then currentChestTarget=ch; chestArrivedTime=0; SetTimeout("Moving..."); SetStatus("Moving to Chest ("..round(dist).."m)") end
                    TweenTo(CFrame.new(ch:GetPivot().Position+Vector3.new(0,3,0)))
                    if dist<15 then chestsCollected=chestsCollected+1; totalChestsEver=totalChestsEver+1; SetChest("Chests: "..chestsCollected); SetTotal("Total: "..totalChestsEver) end
                else SetStatus("No chests"); SetTimeout("-"); currentChestTarget=nil; chestArrivedTime=0; task.wait(1) end
            end)
        end
    end
end)

-- ==================== AUTO COLLECT FRUIT (MIT TWEEN, NACHRANGIG) ====================
task.spawn(function()
    while task.wait(0.5) do
        if _G.AutoFruit and not _G.ChestFarm then -- Nur wenn Chest Farm AUS ist
            pcall(function()
                if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
                local r=LP.Character.HumanoidRootPart; local pp=r.Position
                local fruits = GetFruits()
                
                for _, fruit in pairs(fruits) do
                    if fruit and fruit:FindFirstChild("Handle") then
                        local h = fruit.Handle
                        if h and h:IsA("BasePart") then
                            local dist = (h.Position - pp).Magnitude
                            if dist < 200 then
                                isFarmingFruit = true
                                SetStatus("Tweening to Fruit ("..round(dist).."m)")
                                TweenTo(CFrame.new(h.Position - Vector3.new(0, 5, 0)))
                                
                                -- Warten bis nah genug
                                local waited = 0
                                repeat
                                    task.wait(0.2)
                                    waited = waited + 0.2
                                    if returnHRP() then
                                        local currentDist = (returnHRP().Position - h.Position).Magnitude
                                        if currentDist < 10 then break end
                                    end
                                until waited > 5 or not fruit.Parent
                                
                                task.wait(0.3)
                                
                                -- Fruit einsammeln
                                if fruit and fruit.Parent then
                                    local fruitName = string.gsub(fruit.Name, " Fruit", "")
                                    fruitName = fruitName .. "-" .. fruitName
                                    pcall(function()
                                        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitName, tool)
                                    end)
                                    SetStatus("Collected: "..fruit.Name)
                                    task.wait(0.3)
                                end
                                
                                isFarmingFruit = false
                                break
                            end
                        end
                    end
                end
                
                isFarmingFruit = false
            end)
        end
    end
end)

local function returnHRP()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return nil end
    return LP.Character.HumanoidRootPart
end

-- ==================== INIT ====================
task.wait(1)
SetChest("Chests: 0")
SetFruit("Fruits: "..GetFruitCount())
SetTimeout("-")
SetHop("Hop at: ".._G.ChestTarget)
SetTotal("Total: "..totalChestsEver)
SetTeam("Team: None")
if _G.ChestFarm then SetStatus("Running") end

print("✅ Chest & Fruit Farm BETA v5.1 loaded!")
print("Fruit Farm: Tween to Fruit (not teleport)")
print("Chest Farm has priority if both are turned on")
