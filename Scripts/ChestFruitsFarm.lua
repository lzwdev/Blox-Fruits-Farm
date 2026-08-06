-- Chest & Fruit Farm Script - Premium Custom UI with Serverhop
-- Features: Chest Farm, Fruit ESP, Auto Collect Fruit, Noclip, Speed 300, Auto Serverhop

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local _UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- ==================== NOCLIP ====================
local noclipActive = true

local function EnableNoclip(character)
    if not character then return end
    pcall(function()
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function DisableNoclip(character)
    if not character then return end
    pcall(function()
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end)
end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    if noclipActive then
        EnableNoclip(char)
    end
end)

RunService.Stepped:Connect(function()
    if noclipActive and LP.Character then
        EnableNoclip(LP.Character)
    end
end)

-- ==================== SETTINGS SPEICHERN ====================
local SettingsFileName = "ChestFruitFarm_Settings.json"
local DefaultSettings = {
    ChestESP = false,
    FruitESP = false,
    Noclip = true,
    AutoServerhop = false,
    ServerhopInterval = 100
}

local function SaveSettings()
    local settings = {
        ChestESP = _G.ChestESP,
        FruitESP = _G.FruitESP,
        Noclip = noclipActive,
        AutoServerhop = _G.AutoServerhop,
        ServerhopInterval = serverhopInterval
    }
    
    if writefile and pcall then
        pcall(function()
            writefile(SettingsFileName, HttpService:JSONEncode(settings))
        end)
    end
end

local function LoadSettings()
    local settings = DefaultSettings
    
    if readfile and pcall then
        pcall(function()
            local data = readfile(SettingsFileName)
            local loaded = HttpService:JSONDecode(data)
            for k, v in pairs(loaded) do
                settings[k] = v
            end
        end)
    end
    
    return settings
end

-- ==================== VARIABLEN ====================
_G.ChestFarm = false
_G.ChestESP = false
_G.FruitESP = false
_G.AutoFruit = false
_G.AutoServerhop = false
local espObjects = {}
local fruitEspObjects = {}
local currentTween = nil
local chestHistory = {}
local collectedFruits = {}
local lastTeleportTime = 0
local TELEPORT_COOLDOWN = 0.5
local minimized = false
local isAnimating = false
local currentTab = "Main"

-- Chest Timeout System
local currentChestTarget = nil
local chestArrivedTime = 0
local CHEST_TIMEOUT = 5
local CHEST_ARRIVAL_DISTANCE = 10
local ignoredChests = {}

-- Serverhop System
local chestsCollected = 0
serverhopInterval = 100
local totalChestsEver = 0
local lastServerhopTime = 0
local SERVERHOP_COOLDOWN = 30
local isServerhopping = false
local BLOX_FRUITS_PLACE_ID = 2753915549 -- Blox Fruits Place ID

-- ==================== SETTINGS LADEN ====================
local savedSettings = LoadSettings()
_G.ChestESP = savedSettings.ChestESP
_G.FruitESP = savedSettings.FruitESP
noclipActive = savedSettings.Noclip
_G.AutoServerhop = savedSettings.AutoServerhop
serverhopInterval = savedSettings.ServerhopInterval

-- ==================== ANIMATIONS HELPER ====================
local function CreateTween(obj, props, duration, easing, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        easing or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(obj, tweenInfo, props)
    tween:Play()
    return tween
end

-- ==================== CUSTOM UI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChestFruitFarmUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Hauptfenster
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 520)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Schließen Button mit X
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -36, 0, 8)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold
CloseButton.ZIndex = 10
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

CloseButton.MouseEnter:Connect(function()
    CreateTween(CloseButton, {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}, 0.15)
end)

CloseButton.MouseLeave:Connect(function()
    CreateTween(CloseButton, {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}, 0.15)
end)

CloseButton.MouseButton1Click:Connect(function()
    if isAnimating then return end
    isAnimating = true
    
    _G.ChestFarm = false
    _G.ChestESP = false
    _G.FruitESP = false
    _G.AutoFruit = false
    _G.AutoServerhop = false
    noclipActive = false
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end
    
    SaveSettings()
    
    local shrinkTween = CreateTween(MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    
    shrinkTween.Completed:Connect(function()
        ScreenGui:Destroy()
        isAnimating = false
    end)
end)

-- Minimieren Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -70, 0, 8)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 18
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.ZIndex = 10
MinimizeButton.Parent = MainFrame

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 8)
MinimizeCorner.Parent = MinimizeButton

MinimizeButton.MouseEnter:Connect(function()
    CreateTween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(255, 190, 30)}, 0.15)
end)

MinimizeButton.MouseLeave:Connect(function()
    CreateTween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(255, 170, 0)}, 0.15)
end)

MinimizeButton.MouseButton1Click:Connect(function()
    if isAnimating then return end
    isAnimating = true
    minimized = not minimized
    
    if minimized then
        CreateTween(MainFrame, {Size = UDim2.new(0, 320, 0, 45)}, 0.3, Enum.EasingStyle.Quart)
        task.wait(0.3)
    else
        CreateTween(MainFrame, {Size = UDim2.new(0, 320, 0, 520)}, 0.3, Enum.EasingStyle.Quart)
        task.wait(0.3)
    end
    isAnimating = false
end)

-- Titel-Leiste
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 5
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "⚡ Chest & Fruit Farm"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 16
TitleText.Font = Enum.Font.GothamBlack
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 6
TitleText.Parent = TitleBar

-- Tabs
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1, 0, 0, 42)
TabFrame.Position = UDim2.new(0, 0, 0, 45)
TabFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
TabFrame.BorderSizePixel = 0
TabFrame.ZIndex = 5
TabFrame.Parent = MainFrame

-- Tab Slider
local TabSlider = Instance.new("Frame")
TabSlider.Size = UDim2.new(0.25, -4, 0, 3)
TabSlider.Position = UDim2.new(0, 3, 1, -3)
TabSlider.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
TabSlider.BorderSizePixel = 0
TabSlider.ZIndex = 7
TabSlider.Parent = TabFrame

local TabSliderCorner = Instance.new("UICorner")
TabSliderCorner.CornerRadius = UDim.new(0, 2)
TabSliderCorner.Parent = TabSlider

local TabSliderGlow = Instance.new("Frame")
TabSliderGlow.Size = UDim2.new(0.25, 0, 0, 8)
TabSliderGlow.Position = UDim2.new(0, 1, 1, -5)
TabSliderGlow.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
TabSliderGlow.BackgroundTransparency = 0.6
TabSliderGlow.BorderSizePixel = 0
TabSliderGlow.ZIndex = 6
TabSliderGlow.Parent = TabFrame

local TabSliderGlowCorner = Instance.new("UICorner")
TabSliderGlowCorner.CornerRadius = UDim.new(0, 4)
TabSliderGlowCorner.Parent = TabSliderGlow

-- Tab Buttons (4 Tabs jetzt)
local MainTab = Instance.new("TextButton")
MainTab.Size = UDim2.new(0.25, -4, 1, -4)
MainTab.Position = UDim2.new(0, 3, 0, 2)
MainTab.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
MainTab.BorderSizePixel = 0
MainTab.Text = "Main"
MainTab.TextColor3 = Color3.fromRGB(255, 255, 255)
MainTab.TextSize = 11
MainTab.Font = Enum.Font.GothamBold
MainTab.ZIndex = 6
MainTab.Parent = TabFrame

local MainTabCorner = Instance.new("UICorner")
MainTabCorner.CornerRadius = UDim.new(0, 6)
MainTabCorner.Parent = MainTab

local FruitTab = Instance.new("TextButton")
FruitTab.Size = UDim2.new(0.25, -4, 1, -4)
FruitTab.Position = UDim2.new(0.25, 2, 0, 2)
FruitTab.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
FruitTab.BorderSizePixel = 0
FruitTab.Text = "Fruits"
FruitTab.TextColor3 = Color3.fromRGB(150, 150, 170)
FruitTab.TextSize = 11
FruitTab.Font = Enum.Font.GothamBold
FruitTab.ZIndex = 6
FruitTab.Parent = TabFrame

local FruitTabCorner = Instance.new("UICorner")
FruitTabCorner.CornerRadius = UDim.new(0, 6)
FruitTabCorner.Parent = FruitTab

local ServerhopTab = Instance.new("TextButton")
ServerhopTab.Size = UDim2.new(0.25, -4, 1, -4)
ServerhopTab.Position = UDim2.new(0.5, 1, 0, 2)
ServerhopTab.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
ServerhopTab.BorderSizePixel = 0
ServerhopTab.Text = "Server"
ServerhopTab.TextColor3 = Color3.fromRGB(150, 150, 170)
ServerhopTab.TextSize = 11
ServerhopTab.Font = Enum.Font.GothamBold
ServerhopTab.ZIndex = 6
ServerhopTab.Parent = TabFrame

local ServerhopTabCorner = Instance.new("UICorner")
ServerhopTabCorner.CornerRadius = UDim.new(0, 6)
ServerhopTabCorner.Parent = ServerhopTab

local SettingsTab = Instance.new("TextButton")
SettingsTab.Size = UDim2.new(0.25, -4, 1, -4)
SettingsTab.Position = UDim2.new(0.75, 1, 0, 2)
SettingsTab.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
SettingsTab.BorderSizePixel = 0
SettingsTab.Text = "Set"
SettingsTab.TextColor3 = Color3.fromRGB(150, 150, 170)
SettingsTab.TextSize = 11
SettingsTab.Font = Enum.Font.GothamBold
SettingsTab.ZIndex = 6
SettingsTab.Parent = TabFrame

local SettingsTabCorner = Instance.new("UICorner")
SettingsTabCorner.CornerRadius = UDim.new(0, 6)
SettingsTabCorner.Parent = SettingsTab

-- Content Bereiche
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -92)
ContentFrame.Position = UDim2.new(0, 0, 0, 89)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ClipsDescendants = true
ContentFrame.ZIndex = 5
ContentFrame.Parent = MainFrame

local MainContent = Instance.new("ScrollingFrame")
MainContent.Size = UDim2.new(1, 0, 1, 0)
MainContent.Position = UDim2.new(0, 0, 0, 0)
MainContent.BackgroundTransparency = 1
MainContent.BorderSizePixel = 0
MainContent.ScrollBarThickness = 4
MainContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
MainContent.CanvasSize = UDim2.new(0, 0, 0, 500)
MainContent.ZIndex = 5
MainContent.Parent = ContentFrame

local FruitContent = Instance.new("ScrollingFrame")
FruitContent.Size = UDim2.new(1, 0, 1, 0)
FruitContent.Position = UDim2.new(1, 0, 0, 0)
FruitContent.BackgroundTransparency = 1
FruitContent.BorderSizePixel = 0
FruitContent.ScrollBarThickness = 4
FruitContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
FruitContent.CanvasSize = UDim2.new(0, 0, 0, 500)
FruitContent.ZIndex = 5
FruitContent.Parent = ContentFrame

local ServerhopContent = Instance.new("ScrollingFrame")
ServerhopContent.Size = UDim2.new(1, 0, 1, 0)
ServerhopContent.Position = UDim2.new(2, 0, 0, 0)
ServerhopContent.BackgroundTransparency = 1
ServerhopContent.BorderSizePixel = 0
ServerhopContent.ScrollBarThickness = 4
ServerhopContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
ServerhopContent.CanvasSize = UDim2.new(0, 0, 0, 500)
ServerhopContent.ZIndex = 5
ServerhopContent.Parent = ContentFrame

local SettingsContent = Instance.new("ScrollingFrame")
SettingsContent.Size = UDim2.new(1, 0, 1, 0)
SettingsContent.Position = UDim2.new(3, 0, 0, 0)
SettingsContent.BackgroundTransparency = 1
SettingsContent.BorderSizePixel = 0
SettingsContent.ScrollBarThickness = 4
SettingsContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
SettingsContent.CanvasSize = UDim2.new(0, 0, 0, 500)
SettingsContent.ZIndex = 5
SettingsContent.Parent = ContentFrame

-- UIList Layouts
local MainList = Instance.new("UIListLayout")
MainList.Padding = UDim.new(0, 6)
MainList.Parent = MainContent

local FruitList = Instance.new("UIListLayout")
FruitList.Padding = UDim.new(0, 6)
FruitList.Parent = FruitContent

local ServerhopList = Instance.new("UIListLayout")
ServerhopList.Padding = UDim.new(0, 6)
ServerhopList.Parent = ServerhopContent

local SettingsList = Instance.new("UIListLayout")
SettingsList.Padding = UDim.new(0, 6)
SettingsList.Parent = SettingsContent

-- Padding
local MainPadding = Instance.new("UIPadding")
MainPadding.PaddingLeft = UDim.new(0, 12)
MainPadding.PaddingRight = UDim.new(0, 12)
MainPadding.PaddingTop = UDim.new(0, 8)
MainPadding.Parent = MainContent

local FruitPadding = Instance.new("UIPadding")
FruitPadding.PaddingLeft = UDim.new(0, 12)
FruitPadding.PaddingRight = UDim.new(0, 12)
FruitPadding.PaddingTop = UDim.new(0, 8)
FruitPadding.Parent = FruitContent

local ServerhopPadding = Instance.new("UIPadding")
ServerhopPadding.PaddingLeft = UDim.new(0, 12)
ServerhopPadding.PaddingRight = UDim.new(0, 12)
ServerhopPadding.PaddingTop = UDim.new(0, 8)
ServerhopPadding.Parent = ServerhopContent

local SettingsPadding = Instance.new("UIPadding")
SettingsPadding.PaddingLeft = UDim.new(0, 12)
SettingsPadding.PaddingRight = UDim.new(0, 12)
SettingsPadding.PaddingTop = UDim.new(0, 8)
SettingsPadding.Parent = SettingsContent

-- ==================== TAB SWITCHING (4 TABS) ====================
local function SwitchTab(tab)
    if isAnimating or currentTab == tab then return end
    isAnimating = true
    currentTab = tab
    
    local sliderTargetPos, glowTargetPos, sliderColor
    local tabIndex = 0
    
    if tab == "Main" then
        tabIndex = 0
        sliderTargetPos = UDim2.new(0, 3, 1, -3)
        glowTargetPos = UDim2.new(0, 1, 1, -5)
        sliderColor = Color3.fromRGB(80, 130, 255)
    elseif tab == "Fruit" then
        tabIndex = 1
        sliderTargetPos = UDim2.new(0.25, 2, 1, -3)
        glowTargetPos = UDim2.new(0.25, 0, 1, -5)
        sliderColor = Color3.fromRGB(255, 150, 50)
    elseif tab == "Server" then
        tabIndex = 2
        sliderTargetPos = UDim2.new(0.5, 1, 1, -3)
        glowTargetPos = UDim2.new(0.5, -1, 1, -5)
        sliderColor = Color3.fromRGB(0, 200, 200)
    else
        tabIndex = 3
        sliderTargetPos = UDim2.new(0.75, 1, 1, -3)
        glowTargetPos = UDim2.new(0.75, -1, 1, -5)
        sliderColor = Color3.fromRGB(150, 80, 255)
    end
    
    CreateTween(TabSlider, {Position = sliderTargetPos, BackgroundColor3 = sliderColor}, 0.3, Enum.EasingStyle.Quart)
    CreateTween(TabSliderGlow, {Position = glowTargetPos, BackgroundColor3 = sliderColor}, 0.3, Enum.EasingStyle.Quart)
    
    local offset = -tabIndex
    CreateTween(MainContent, {Position = UDim2.new(offset, 0, 0, 0)}, 0.35, Enum.EasingStyle.Quart)
    CreateTween(FruitContent, {Position = UDim2.new(1 + offset, 0, 0, 0)}, 0.35, Enum.EasingStyle.Quart)
    CreateTween(ServerhopContent, {Position = UDim2.new(2 + offset, 0, 0, 0)}, 0.35, Enum.EasingStyle.Quart)
    CreateTween(SettingsContent, {Position = UDim2.new(3 + offset, 0, 0, 0)}, 0.35, Enum.EasingStyle.Quart)
    
    CreateTween(MainTab, {BackgroundColor3 = tab == "Main" and Color3.fromRGB(35, 35, 60) or Color3.fromRGB(25, 25, 40), TextColor3 = tab == "Main" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)}, 0.2)
    CreateTween(FruitTab, {BackgroundColor3 = tab == "Fruit" and Color3.fromRGB(35, 35, 60) or Color3.fromRGB(25, 25, 40), TextColor3 = tab == "Fruit" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)}, 0.2)
    CreateTween(ServerhopTab, {BackgroundColor3 = tab == "Server" and Color3.fromRGB(35, 35, 60) or Color3.fromRGB(25, 25, 40), TextColor3 = tab == "Server" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)}, 0.2)
    CreateTween(SettingsTab, {BackgroundColor3 = tab == "Settings" and Color3.fromRGB(35, 35, 60) or Color3.fromRGB(25, 25, 40), TextColor3 = tab == "Settings" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)}, 0.2)
    
    task.delay(0.35, function()
        isAnimating = false
    end)
end

MainTab.MouseButton1Click:Connect(function() SwitchTab("Main") end)
FruitTab.MouseButton1Click:Connect(function() SwitchTab("Fruit") end)
ServerhopTab.MouseButton1Click:Connect(function() SwitchTab("Server") end)
SettingsTab.MouseButton1Click:Connect(function() SwitchTab("Settings") end)

-- ==================== UI ELEMENTE ERSTELLEN ====================
local function CreateSection(parent, name)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 30)
    section.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    section.BorderSizePixel = 0
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 5)
    sectionCorner.Parent = section
    
    local sectionText = Instance.new("TextLabel")
    sectionText.Size = UDim2.new(1, -10, 1, 0)
    sectionText.Position = UDim2.new(0, 10, 0, 0)
    sectionText.BackgroundTransparency = 1
    sectionText.Text = name
    sectionText.TextColor3 = Color3.fromRGB(200, 200, 230)
    sectionText.TextSize = 13
    sectionText.Font = Enum.Font.GothamBold
    sectionText.TextXAlignment = Enum.TextXAlignment.Left
    sectionText.Parent = section
    
    return section
end

local function CreateToggle(parent, name, default, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 40)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = parent
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 5)
    toggleCorner.Parent = toggleFrame
    
    local toggleText = Instance.new("TextLabel")
    toggleText.Size = UDim2.new(0.65, -10, 1, 0)
    toggleText.Position = UDim2.new(0, 10, 0, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.Text = name
    toggleText.TextColor3 = Color3.fromRGB(230, 230, 240)
    toggleText.TextSize = 13
    toggleText.Font = Enum.Font.Gotham
    toggleText.TextXAlignment = Enum.TextXAlignment.Left
    toggleText.Parent = toggleFrame
    
    local toggleButton = Instance.new("Frame")
    toggleButton.Size = UDim2.new(0, 46, 0, 24)
    toggleButton.Position = UDim2.new(1, -56, 0.5, -12)
    toggleButton.BackgroundColor3 = default and Color3.fromRGB(0, 180, 90) or Color3.fromRGB(60, 60, 80)
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = toggleFrame
    
    local toggleButtonCorner = Instance.new("UICorner")
    toggleButtonCorner.CornerRadius = UDim.new(1, 0)
    toggleButtonCorner.Parent = toggleButton
    
    local toggleDot = Instance.new("Frame")
    toggleDot.Size = UDim2.new(0, 20, 0, 20)
    toggleDot.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    toggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleDot.BorderSizePixel = 0
    toggleDot.Parent = toggleButton
    
    local toggleDotCorner = Instance.new("UICorner")
    toggleDotCorner.CornerRadius = UDim.new(1, 0)
    toggleDotCorner.Parent = toggleDot
    
    local enabled = default
    
    local function updateVisual()
        if enabled then
            CreateTween(toggleButton, {BackgroundColor3 = Color3.fromRGB(0, 180, 90)}, 0.2)
            CreateTween(toggleDot, {Position = UDim2.new(1, -22, 0.5, -10)}, 0.2, Enum.EasingStyle.Quart)
        else
            CreateTween(toggleButton, {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}, 0.2)
            CreateTween(toggleDot, {Position = UDim2.new(0, 2, 0.5, -10)}, 0.2, Enum.EasingStyle.Quart)
        end
    end
    
    toggleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            enabled = not enabled
            updateVisual()
            pcall(callback, enabled)
        end
    end)
    
    toggleFrame.MouseEnter:Connect(function()
        CreateTween(toggleFrame, {BackgroundColor3 = Color3.fromRGB(32, 32, 50)}, 0.15)
    end)
    
    toggleFrame.MouseLeave:Connect(function()
        CreateTween(toggleFrame, {BackgroundColor3 = Color3.fromRGB(25, 25, 40)}, 0.15)
    end)
    
    return toggleFrame
end

local function CreateLabel(parent, text)
    local labelFrame = Instance.new("Frame")
    labelFrame.Size = UDim2.new(1, 0, 0, 30)
    labelFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    labelFrame.BorderSizePixel = 0
    labelFrame.Parent = parent
    
    local labelCorner = Instance.new("UICorner")
    labelCorner.CornerRadius = UDim.new(0, 5)
    labelCorner.Parent = labelFrame
    
    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, 10, 0.5, -4)
    statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = labelFrame
    
    local statusDotCorner = Instance.new("UICorner")
    statusDotCorner.CornerRadius = UDim.new(1, 0)
    statusDotCorner.Parent = statusDot
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, -25, 1, 0)
    labelText.Position = UDim2.new(0, 22, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = text
    labelText.TextColor3 = Color3.fromRGB(200, 200, 220)
    labelText.TextSize = 12
    labelText.Font = Enum.Font.Gotham
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = labelFrame
    
    return labelText, statusDot
end

local function CreateButton(parent, text, callback)
    local buttonFrame = Instance.new("TextButton")
    buttonFrame.Size = UDim2.new(1, 0, 0, 36)
    buttonFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Text = text
    buttonFrame.TextColor3 = Color3.fromRGB(255, 255, 255)
    buttonFrame.TextSize = 14
    buttonFrame.Font = Enum.Font.GothamBold
    buttonFrame.Parent = parent
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = buttonFrame
    
    buttonFrame.MouseButton1Click:Connect(callback)
    
    buttonFrame.MouseEnter:Connect(function()
        CreateTween(buttonFrame, {BackgroundColor3 = Color3.fromRGB(70, 70, 110)}, 0.15)
    end)
    
    buttonFrame.MouseLeave:Connect(function()
        CreateTween(buttonFrame, {BackgroundColor3 = Color3.fromRGB(50, 50, 80)}, 0.15)
    end)
    
    return buttonFrame
end

-- ==================== STATUS VARIABLEN ====================
local statusLabel = nil
local statusDot = nil
local chestCountLabel = nil
local fruitCountLabel = nil
local timeoutLabel = nil
local serverhopCountLabel = nil
local totalChestsLabel = nil

local function SetStatus(text, active)
    if statusLabel then
        statusLabel.Text = text
    end
    if statusDot then
        if active then
            CreateTween(statusDot, {BackgroundColor3 = Color3.fromRGB(0, 255, 100)}, 0.3)
        else
            CreateTween(statusDot, {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}, 0.3)
        end
    end
end

local function SetChestCount(text)
    if chestCountLabel then
        chestCountLabel.Text = text
    end
end

local function SetFruitCount(text)
    if fruitCountLabel then
        fruitCountLabel.Text = text
    end
end

local function SetTimeoutLabel(text)
    if timeoutLabel then
        timeoutLabel.Text = text
    end
end

local function SetServerhopCount(text)
    if serverhopCountLabel then
        serverhopCountLabel.Text = text
    end
end

local function SetTotalChests(text)
    if totalChestsLabel then
        totalChestsLabel.Text = text
    end
end

-- ==================== SERVERHOP FUNKTION ====================
local function Serverhop()
    if isServerhopping then return end
    isServerhopping = true
    
    SetStatus("Serverhopping...", true)
    SaveSettings()
    
    -- Kurze Verzögerung für UI-Update
    task.wait(1)
    
    -- Teleport zu Blox Fruits (neuer Server)
    pcall(function()
        TeleportService:Teleport(BLOX_FRUITS_PLACE_ID, LP)
    end)
    
    -- Falls Teleport fehlschlägt
    task.wait(5)
    isServerhopping = false
    SetStatus("Serverhop failed!", false)
end

-- ==================== UI AUFBAUEN ====================
-- Main Tab
CreateSection(MainContent, "Chest Farm")
CreateToggle(MainContent, "Auto Farm Chest", false, function(Value)
    _G.ChestFarm = Value
    if Value then
        SetStatus("Status: Running", true)
        ignoredChests = {}
        currentChestTarget = nil
        chestArrivedTime = 0
        chestsCollected = 0
        SetTimeoutLabel("Timeout: Ready")
    else
        SetStatus("Status: Idle", false)
        if currentTween then
            pcall(function() currentTween:Cancel() end)
            currentTween = nil
        end
        ignoredChests = {}
        currentChestTarget = nil
        chestArrivedTime = 0
        SetTimeoutLabel("Timeout: -")
    end
end)

CreateToggle(MainContent, "Chest ESP", _G.ChestESP, function(Value)
    _G.ChestESP = Value
    SaveSettings()
    if not Value then
        for chest, data in pairs(espObjects) do
            if data and data.Billboard then
                pcall(function() data.Billboard:Destroy() end)
            end
        end
        espObjects = {}
    end
end)

CreateToggle(MainContent, "Noclip", noclipActive, function(Value)
    noclipActive = Value
    SaveSettings()
    if not Value and LP.Character then
        DisableNoclip(LP.Character)
    elseif Value and LP.Character then
        EnableNoclip(LP.Character)
    end
end)

CreateSection(MainContent, "Status")
statusLabel, statusDot = CreateLabel(MainContent, "Status: Idle")
chestCountLabel, _ = CreateLabel(MainContent, "Chests found: 0")
timeoutLabel, _ = CreateLabel(MainContent, "Timeout: -")

-- Fruit Tab
CreateSection(FruitContent, "Fruit Settings")
CreateToggle(FruitContent, "Fruit ESP", _G.FruitESP, function(Value)
    _G.FruitESP = Value
    SaveSettings()
    if not Value then
        for fruit, data in pairs(fruitEspObjects) do
            if data and data.Billboard then
                pcall(function() data.Billboard:Destroy() end)
            end
        end
        fruitEspObjects = {}
    end
end)

CreateToggle(FruitContent, "Auto Collect Fruit", false, function(Value)
    _G.AutoFruit = Value
    if Value then
        SetStatus("Status: Looking for fruits...", true)
    end
end)

CreateSection(FruitContent, "Fruit Status")
fruitCountLabel, _ = CreateLabel(FruitContent, "Fruits found: 0")

-- Serverhop Tab
CreateSection(ServerhopContent, "Auto Serverhop")
CreateToggle(ServerhopContent, "Auto Serverhop", _G.AutoServerhop, function(Value)
    _G.AutoServerhop = Value
    SaveSettings()
    if Value then
        chestsCollected = 0
        SetServerhopCount("Chests until hop: " .. serverhopInterval)
    end
end)

CreateSection(ServerhopContent, "Serverhop Settings")
CreateLabel(ServerhopContent, "Hops every " .. serverhopInterval .. " chests")

CreateButton(ServerhopContent, "Serverhop NOW", function()
    Serverhop()
end)

CreateSection(ServerhopContent, "Stats")
serverhopCountLabel, _ = CreateLabel(ServerhopContent, "Chests until hop: -")
totalChestsLabel, _ = CreateLabel(ServerhopContent, "Total chests: 0")

-- Settings Tab
CreateSection(SettingsContent, "Information")
CreateLabel(SettingsContent, "Chest & Fruit Farm v4.0")
CreateLabel(SettingsContent, "Speed: 300 (Fixed Tween)")
CreateLabel(SettingsContent, "Chest Timeout: 5s")
CreateLabel(SettingsContent, "Serverhop: Every " .. serverhopInterval .. " chests")

CreateSection(SettingsContent, "Controls")
CreateButton(SettingsContent, "Save Settings", function()
    SaveSettings()
    SetStatus("Settings saved!", true)
end)

CreateButton(SettingsContent, "Unload Script", function()
    if isAnimating then return end
    isAnimating = true
    
    _G.ChestFarm = false
    _G.ChestESP = false
    _G.FruitESP = false
    _G.AutoFruit = false
    _G.AutoServerhop = false
    noclipActive = false
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end
    
    SaveSettings()
    
    local shrinkTween = CreateTween(MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    
    shrinkTween.Completed:Connect(function()
        ScreenGui:Destroy()
        isAnimating = false
    end)
    
    for _, data in pairs(espObjects) do
        if data and data.Billboard then
            pcall(function() data.Billboard:Destroy() end)
        end
    end
    espObjects = {}
    for _, data in pairs(fruitEspObjects) do
        if data and data.Billboard then
            pcall(function() data.Billboard:Destroy() end)
        end
    end
    fruitEspObjects = {}
end)

-- Canvas Size updaten
MainList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MainContent.CanvasSize = UDim2.new(0, 0, 0, MainList.AbsoluteContentSize.Y + 10)
end)
FruitList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    FruitContent.CanvasSize = UDim2.new(0, 0, 0, FruitList.AbsoluteContentSize.Y + 10)
end)
ServerhopList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ServerhopContent.CanvasSize = UDim2.new(0, 0, 0, ServerhopList.AbsoluteContentSize.Y + 10)
end)
SettingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SettingsContent.CanvasSize = UDim2.new(0, 0, 0, SettingsList.AbsoluteContentSize.Y + 10)
end)

task.wait(0.1)
MainContent.CanvasSize = UDim2.new(0, 0, 0, MainList.AbsoluteContentSize.Y + 10)
FruitContent.CanvasSize = UDim2.new(0, 0, 0, FruitList.AbsoluteContentSize.Y + 10)
ServerhopContent.CanvasSize = UDim2.new(0, 0, 0, ServerhopList.AbsoluteContentSize.Y + 10)
SettingsContent.CanvasSize = UDim2.new(0, 0, 0, SettingsList.AbsoluteContentSize.Y + 10)

-- ==================== HILFSFUNKTIONEN ====================
local function round(num)
    return math.floor(num + 0.5)
end

local function GetChestCount()
    local count = 0
    pcall(function()
        for _, chest in pairs(CollectionService:GetTagged("_ChestTagged")) do
            if chest and chest:IsA("BasePart") and not chest:GetAttribute("IsDisabled") then
                count = count + 1
            end
        end
    end)
    return count
end

local function GetFruitCount()
    local count = 0
    pcall(function()
        for _, obj in pairs(workspace:GetChildren()) do
            if obj and obj:IsA("BasePart") and string.find(obj.Name, "Fruit") and obj:FindFirstChild("Handle") then
                count = count + 1
            end
        end
    end)
    return count
end

-- ==================== FRUIT ESP ====================
local function CreateFruitESP(fruit)
    if not fruit or fruitEspObjects[fruit] then return end
    local handle = fruit:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return end
    
    pcall(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "FruitEsp"
        billboard.Size = UDim2.new(0, 160, 0, 30)
        billboard.Adornee = handle
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Parent = handle
        
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.5
        bg.BorderSizePixel = 0
        bg.Parent = billboard
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "Fruit"
        label.TextColor3 = Color3.fromRGB(255, 100, 100)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard
        
        fruitEspObjects[fruit] = {Billboard = billboard, Label = label}
    end)
end

local function UpdateFruitESP()
    local playerPos = LP.Character and LP.Character:FindFirstChild("Head")
    if not playerPos then return end
    local pos = playerPos.Position
    
    for _, obj in pairs(workspace:GetChildren()) do
        pcall(function()
            if obj and string.find(obj.Name, "Fruit") and obj:FindFirstChild("Handle") then
                if _G.FruitESP then
                    if not fruitEspObjects[obj] then CreateFruitESP(obj) end
                    local esp = fruitEspObjects[obj]
                    if esp and esp.Label and obj.Handle then
                        local dist = round((pos - obj.Handle.Position).Magnitude / 3)
                        esp.Label.Text = obj.Name .. " (" .. dist .. "m)"
                        if dist < 50 then
                            esp.Label.TextColor3 = Color3.fromRGB(0, 255, 100)
                        elseif dist < 150 then
                            esp.Label.TextColor3 = Color3.fromRGB(255, 215, 0)
                        else
                            esp.Label.TextColor3 = Color3.fromRGB(255, 100, 100)
                        end
                    end
                else
                    if fruitEspObjects[obj] then
                        local data = fruitEspObjects[obj]
                        if data and data.Billboard then
                            pcall(function() data.Billboard:Destroy() end)
                        end
                        fruitEspObjects[obj] = nil
                    end
                end
            end
        end)
    end
end

-- ==================== CHEST ESP ====================
local function CreateChestESP(chest)
    if not chest or espObjects[chest] then return end
    
    pcall(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ChestEsp"
        billboard.Size = UDim2.new(0, 160, 0, 30)
        billboard.Adornee = chest
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Parent = chest
        
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.5
        bg.BorderSizePixel = 0
        bg.Parent = billboard
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "Chest"
        label.TextColor3 = Color3.fromRGB(255, 215, 0)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard
        
        espObjects[chest] = {Billboard = billboard, Label = label}
    end)
end

local function UpdateChestESP()
    local playerPos = LP.Character and LP.Character:FindFirstChild("Head")
    if not playerPos then return end
    local pos = playerPos.Position
    
    for _, chest in pairs(CollectionService:GetTagged("_ChestTagged")) do
        pcall(function()
            if chest and chest:IsA("BasePart") and not chest:GetAttribute("IsDisabled") then
                if _G.ChestESP then
                    if not espObjects[chest] then CreateChestESP(chest) end
                    local esp = espObjects[chest]
                    if esp and esp.Label then
                        local dist = round((pos - chest:GetPivot().Position).Magnitude / 3)
                        if ignoredChests[chest] then
                            esp.Label.Text = "🚫 IGNORED (" .. dist .. "m)"
                            esp.Label.TextColor3 = Color3.fromRGB(255, 50, 50)
                        else
                            esp.Label.Text = "Chest (" .. dist .. "m)"
                            if dist < 50 then
                                esp.Label.TextColor3 = Color3.fromRGB(0, 255, 100)
                            elseif dist < 150 then
                                esp.Label.TextColor3 = Color3.fromRGB(255, 215, 0)
                            else
                                esp.Label.TextColor3 = Color3.fromRGB(255, 100, 100)
                            end
                        end
                    end
                else
                    if espObjects[chest] then
                        local data = espObjects[chest]
                        if data and data.Billboard then
                            pcall(function() data.Billboard:Destroy() end)
                        end
                        espObjects[chest] = nil
                    end
                end
            end
        end)
    end
end

-- ==================== ESP LOOPS ====================
task.spawn(function()
    while task.wait(0.3) do
        if _G.ChestESP then
            UpdateChestESP()
            SetChestCount("Chests found: " .. GetChestCount())
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.FruitESP then
            UpdateFruitESP()
            SetFruitCount("Fruits found: " .. GetFruitCount())
        end
    end
end)

-- ==================== FIND NEAREST FUNCTIONS ====================
local function FindNearestChest()
    local rootPart = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil, nil end
    
    local pos = rootPart.Position
    local nearest = nil
    local minDist = math.huge
    
    for _, chest in pairs(CollectionService:GetTagged("_ChestTagged")) do
        pcall(function()
            if chest and chest:IsA("BasePart") and not chest:GetAttribute("IsDisabled") then
                if not ignoredChests[chest] then
                    local dist = (chest:GetPivot().Position - pos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = chest
                    end
                end
            end
        end)
    end
    
    return nearest, minDist
end

-- ==================== TWEEN FUNKTION ====================
local function TweenToPosition(targetCFrame)
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local currentTime = tick()
    if currentTime - lastTeleportTime < TELEPORT_COOLDOWN then
        return false
    end
    
    local rootPart = LP.Character.HumanoidRootPart
    local distance = (targetCFrame.Position - rootPart.Position).Magnitude
    
    local tweenSpeed = 300
    local duration = distance / tweenSpeed
    duration = math.max(duration, 0.1)
    
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    currentTween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    currentTween:Play()
    lastTeleportTime = currentTime
    
    task.delay(duration, function()
        if currentTween then currentTween = nil end
    end)
    
    return true
end

-- ==================== AUTO FARM CHEST (MIT SERVERHOP) ====================
task.spawn(function()
    while task.wait(0.3) do
        if _G.ChestFarm then
            pcall(function()
                if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then
                    SetStatus("Status: Waiting...", false)
                    task.wait(0.5)
                    return
                end
                
                local rootPart = LP.Character.HumanoidRootPart
                local playerPos = rootPart.Position
                
                -- Serverhop Check
                if _G.AutoServerhop and chestsCollected >= serverhopInterval then
                    local currentTime = tick()
                    if currentTime - lastServerhopTime > SERVERHOP_COOLDOWN then
                        lastServerhopTime = currentTime
                        SetStatus("Serverhopping! (" .. chestsCollected .. " chests)", true)
                        Serverhop()
                        return
                    end
                end
                
                -- Timeout-Check
                if currentChestTarget then
                    local chestPos = currentChestTarget:GetPivot().Position
                    local distToChest = (chestPos - playerPos).Magnitude
                    
                    if distToChest < CHEST_ARRIVAL_DISTANCE then
                        if chestArrivedTime == 0 then
                            chestArrivedTime = tick()
                            SetTimeoutLabel("Timeout: 5s")
                        else
                            local elapsed = tick() - chestArrivedTime
                            local remaining = math.max(0, CHEST_TIMEOUT - elapsed)
                            SetTimeoutLabel("Timeout: " .. round(remaining) .. "s")
                            
                            if elapsed > CHEST_TIMEOUT then
                                SetStatus("Chest bugged! Ignoring...", false)
                                SetTimeoutLabel("Timeout: IGNORED")
                                ignoredChests[currentChestTarget] = true
                                currentChestTarget = nil
                                chestArrivedTime = 0
                                
                                if currentTween then
                                    pcall(function() currentTween:Cancel() end)
                                    currentTween = nil
                                end
                                task.wait(0.5)
                                return
                            end
                        end
                    else
                        if chestArrivedTime > 0 then
                            SetTimeoutLabel("Timeout: Moving...")
                        end
                        chestArrivedTime = 0
                    end
                end
                
                local chest, dist = FindNearestChest()
                
                if chest and dist then
                    if chest ~= currentChestTarget then
                        currentChestTarget = chest
                        chestArrivedTime = 0
                        SetTimeoutLabel("Timeout: Moving...")
                        SetStatus("Moving to Chest (" .. round(dist) .. "m)", true)
                    end
                    
                    local pos = chest:GetPivot().Position
                    local targetPos = pos + Vector3.new(0, 3, 0)
                    
                    local success = TweenToPosition(CFrame.new(targetPos))
                    
                    if success then
                        table.insert(chestHistory, chest)
                        if #chestHistory > 5 then
                            table.remove(chestHistory, 1)
                        end
                        
                        -- Chest sammeln zählen (wenn wir nah genug sind)
                        if dist < 15 then
                            chestsCollected = chestsCollected + 1
                            totalChestsEver = totalChestsEver + 1
                            
                            if _G.AutoServerhop then
                                local remaining = serverhopInterval - chestsCollected
                                SetServerhopCount("Chests until hop: " .. math.max(0, remaining))
                            end
                            SetTotalChests("Total chests: " .. totalChestsEver)
                        end
                    end
                else
                    SetStatus("No chests available", false)
                    SetTimeoutLabel("Timeout: -")
                    currentChestTarget = nil
                    chestArrivedTime = 0
                    task.wait(1)
                end
            end)
        end
    end
end)

-- ==================== AUTO COLLECT FRUIT ====================
task.spawn(function()
    while task.wait(0.2) do
        if _G.AutoFruit then
            pcall(function()
                if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then
                    return
                end
                
                local rootPart = LP.Character.HumanoidRootPart
                local playerPos = rootPart.Position
                local foundFruit = false
                
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj and obj:FindFirstChild("Handle") then
                        local handle = obj.Handle
                        if handle and handle:IsA("BasePart") then
                            if string.find(obj.Name, "Fruit") or string.find(obj.Name:lower(), "fruit") then
                                local dist = (handle.Position - playerPos).Magnitude
                                
                                if dist < 100 then
                                    rootPart.CFrame = CFrame.new(handle.Position - Vector3.new(0, 5, 0))
                                    SetStatus("Fruit collected: " .. obj.Name, true)
                                    foundFruit = true
                                    task.wait(0.1)
                                    break
                                end
                            end
                        end
                    end
                end
                
                if not foundFruit then
                    SetStatus("No fruits nearby", false)
                end
            end)
        end
    end
end)

-- ==================== CHARACTER EVENTS ====================
LP.CharacterAdded:Connect(function(char)
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end
    
    chestHistory = {}
    collectedFruits = {}
    lastTeleportTime = 0
    ignoredChests = {}
    currentChestTarget = nil
    chestArrivedTime = 0
    
    task.wait(0.2)
    if noclipActive then
        EnableNoclip(char)
    end
end)

-- ==================== INITIAL COUNTS ====================
task.wait(1)
SetChestCount("Chests found: " .. GetChestCount())
SetFruitCount("Fruits found: " .. GetFruitCount())
SetTimeoutLabel("Timeout: -")
if _G.AutoServerhop then
    SetServerhopCount("Chests until hop: " .. serverhopInterval)
else
    SetServerhopCount("Chests until hop: OFF")
end
SetTotalChests("Total chests: " .. totalChestsEver)

-- ==================== OPEN ANIMATION ====================
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
CreateTween(MainFrame, {
    Size = UDim2.new(0, 320, 0, 520),
    Position = UDim2.new(0.5, -160, 0.5, -260)
}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Auto Serverhop aktivieren wenn gespeichert
if _G.AutoServerhop then
    chestsCollected = 0
    SetServerhopCount("Chests until hop: " .. serverhopInterval)
end

print("Chest & Fruit Farm Script loaded! (v4.0 - Auto Serverhop)")
print("Features: Chest Farm | Fruit ESP | Auto Collect Fruit | Noclip | Auto Serverhop")
print("Serverhop: Every " .. serverhopInterval .. " chests (toggleable, settings saved)")
print("Blox Fruits Place ID: " .. BLOX_FRUITS_PLACE_ID)
