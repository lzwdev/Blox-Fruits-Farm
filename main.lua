-- Blox Fruits Farm Hub by lzwdev

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game:GetService("Players") and game:GetService("CoreGui")

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local function Tween(obj, props, dur)
    local t = TweenService:Create(obj, TweenInfo.new(dur or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- ==================== SCREEN GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxFruitsFarmHub"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ==================== MAIN FRAME ====================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 340)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 4)
TopBar.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 16)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 100
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Logo
local LogoFrame = Instance.new("Frame")
LogoFrame.Size = UDim2.new(0, 50, 0, 50)
LogoFrame.Position = UDim2.new(0, 20, 0, 16)
LogoFrame.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
LogoFrame.BorderSizePixel = 0
LogoFrame.Parent = MainFrame
Instance.new("UICorner", LogoFrame).CornerRadius = UDim.new(0, 14)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "⚡"
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.TextSize = 28
LogoText.Font = Enum.Font.GothamBold
LogoText.Parent = LogoFrame

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 200, 0, 28)
TitleLabel.Position = UDim2.new(0, 80, 0, 18)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "BLOX FRUITS"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Size = UDim2.new(0, 200, 0, 20)
SubtitleLabel.Position = UDim2.new(0, 80, 0, 42)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = "FARM HUB"
SubtitleLabel.TextColor3 = Color3.fromRGB(130, 160, 255)
SubtitleLabel.TextSize = 13
SubtitleLabel.Font = Enum.Font.GothamBold
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.Parent = MainFrame

local CreatorLabel = Instance.new("TextLabel")
CreatorLabel.Size = UDim2.new(0, 200, 0, 16)
CreatorLabel.Position = UDim2.new(0, 80, 0, 58)
CreatorLabel.BackgroundTransparency = 1
CreatorLabel.Text = "by lzwdev"
CreatorLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
CreatorLabel.TextSize = 10
CreatorLabel.Font = Enum.Font.Gotham
CreatorLabel.TextXAlignment = Enum.TextXAlignment.Left
CreatorLabel.Parent = MainFrame

-- Divider
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -40, 0, 1)
Divider.Position = UDim2.new(0, 20, 0, 82)
Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

-- ==================== STABLE BUTTON ====================
local StableLabel = Instance.new("TextLabel")
StableLabel.Size = UDim2.new(1, -40, 0, 20)
StableLabel.Position = UDim2.new(0, 20, 0, 95)
StableLabel.BackgroundTransparency = 1
StableLabel.Text = "STABLE VERSION"
StableLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
StableLabel.TextSize = 10
StableLabel.Font = Enum.Font.GothamBold
StableLabel.TextXAlignment = Enum.TextXAlignment.Left
StableLabel.Parent = MainFrame

local StableBtn = Instance.new("TextButton")
StableBtn.Size = UDim2.new(1, -40, 0, 70)
StableBtn.Position = UDim2.new(0, 20, 0, 117)
StableBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
StableBtn.BorderSizePixel = 0
StableBtn.Text = ""
StableBtn.AutoButtonColor = false
StableBtn.ZIndex = 10
StableBtn.Parent = MainFrame
Instance.new("UICorner", StableBtn).CornerRadius = UDim.new(0, 12)

local StableStroke = Instance.new("UIStroke")
StableStroke.Color = Color3.fromRGB(80, 200, 120)
StableStroke.Thickness = 2
StableStroke.Parent = StableBtn

local StableIcon = Instance.new("TextLabel")
StableIcon.Size = UDim2.new(0, 40, 0, 40)
StableIcon.Position = UDim2.new(0, 16, 0.5, -20)
StableIcon.BackgroundTransparency = 1
StableIcon.Text = "🛡️"
StableIcon.TextSize = 24
StableIcon.ZIndex = 11
StableIcon.Parent = StableBtn

local StableTitle = Instance.new("TextLabel")
StableTitle.Size = UDim2.new(1, -120, 0, 24)
StableTitle.Position = UDim2.new(0, 66, 0, 12)
StableTitle.BackgroundTransparency = 1
StableTitle.Text = "Stable Build"
StableTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
StableTitle.TextSize = 15
StableTitle.Font = Enum.Font.GothamBold
StableTitle.TextXAlignment = Enum.TextXAlignment.Left
StableTitle.ZIndex = 11
StableTitle.Parent = StableBtn

local StableDesc = Instance.new("TextLabel")
StableDesc.Size = UDim2.new(1, -120, 0, 18)
StableDesc.Position = UDim2.new(0, 66, 0, 38)
StableDesc.BackgroundTransparency = 1
StableDesc.Text = "Reliable • Tested • Recommended"
StableDesc.TextColor3 = Color3.fromRGB(120, 160, 140)
StableDesc.TextSize = 10
StableDesc.Font = Enum.Font.Gotham
StableDesc.TextXAlignment = Enum.TextXAlignment.Left
StableDesc.ZIndex = 11
StableDesc.Parent = StableBtn

-- STABLE CLICK - DIREKT UND EINFACH
StableBtn.MouseButton1Click:Connect(function()
    StableTitle.Text = "Loading..."
    StableIcon.Text = "⏳"
    
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/lzwdev/Blox-Fruits-Farm/refs/heads/main/Scripts/ChestFruitsFarm.lua"))()
    end)
    
    if ok then
        StableTitle.Text = "Success!"
        StableIcon.Text = "✅"
        StableStroke.Color = Color3.fromRGB(0, 255, 100)
        task.wait(1)
        ScreenGui:Destroy()
    else
        StableTitle.Text = "Error!"
        StableIcon.Text = "❌"
        StableStroke.Color = Color3.fromRGB(255, 50, 50)
        warn(err)
        task.wait(2)
        StableTitle.Text = "Stable Build"
        StableIcon.Text = "🛡️"
        StableStroke.Color = Color3.fromRGB(80, 200, 120)
    end
end)

-- ==================== BETA BUTTON ====================
local BetaLabel = Instance.new("TextLabel")
BetaLabel.Size = UDim2.new(1, -40, 0, 20)
BetaLabel.Position = UDim2.new(0, 20, 0, 200)
BetaLabel.BackgroundTransparency = 1
BetaLabel.Text = "BETA VERSION"
BetaLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
BetaLabel.TextSize = 10
BetaLabel.Font = Enum.Font.GothamBold
BetaLabel.TextXAlignment = Enum.TextXAlignment.Left
BetaLabel.Parent = MainFrame

local BetaBtn = Instance.new("TextButton")
BetaBtn.Size = UDim2.new(1, -40, 0, 70)
BetaBtn.Position = UDim2.new(0, 20, 0, 222)
BetaBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
BetaBtn.BorderSizePixel = 0
BetaBtn.Text = ""
BetaBtn.AutoButtonColor = false
BetaBtn.ZIndex = 10
BetaBtn.Parent = MainFrame
Instance.new("UICorner", BetaBtn).CornerRadius = UDim.new(0, 12)

local BetaStroke = Instance.new("UIStroke")
BetaStroke.Color = Color3.fromRGB(255, 180, 50)
BetaStroke.Thickness = 2
BetaStroke.Parent = BetaBtn

local BetaIcon = Instance.new("TextLabel")
BetaIcon.Size = UDim2.new(0, 40, 0, 40)
BetaIcon.Position = UDim2.new(0, 16, 0.5, -20)
BetaIcon.BackgroundTransparency = 1
BetaIcon.Text = "🧪"
BetaIcon.TextSize = 24
BetaIcon.ZIndex = 11
BetaIcon.Parent = BetaBtn

local BetaTitle = Instance.new("TextLabel")
BetaTitle.Size = UDim2.new(1, -120, 0, 24)
BetaTitle.Position = UDim2.new(0, 66, 0, 12)
BetaTitle.BackgroundTransparency = 1
BetaTitle.Text = "Beta Build"
BetaTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
BetaTitle.TextSize = 15
BetaTitle.Font = Enum.Font.GothamBold
BetaTitle.TextXAlignment = Enum.TextXAlignment.Left
BetaTitle.ZIndex = 11
BetaTitle.Parent = BetaBtn

local BetaDesc = Instance.new("TextLabel")
BetaDesc.Size = UDim2.new(1, -120, 0, 18)
BetaDesc.Position = UDim2.new(0, 66, 0, 38)
BetaDesc.BackgroundTransparency = 1
BetaDesc.Text = "Experimental • New Features • Unstable"
BetaDesc.TextColor3 = Color3.fromRGB(200, 160, 80)
BetaDesc.TextSize = 10
BetaDesc.Font = Enum.Font.Gotham
BetaDesc.TextXAlignment = Enum.TextXAlignment.Left
BetaDesc.ZIndex = 11
BetaDesc.Parent = BetaBtn

-- BETA CLICK - DIREKT UND EINFACH
BetaBtn.MouseButton1Click:Connect(function()
    BetaTitle.Text = "Loading..."
    BetaIcon.Text = "⏳"
    
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/lzwdev/Blox-Fruits-Farm/refs/heads/main/Scripts/ChestFruitsFarm-BETA.lua"))()
    end)
    
    if ok then
        BetaTitle.Text = "Success!"
        BetaIcon.Text = "✅"
        BetaStroke.Color = Color3.fromRGB(0, 255, 100)
        task.wait(1)
        ScreenGui:Destroy()
    else
        BetaTitle.Text = "Error!"
        BetaIcon.Text = "❌"
        BetaStroke.Color = Color3.fromRGB(255, 50, 50)
        warn(err)
        task.wait(2)
        BetaTitle.Text = "Beta Build"
        BetaIcon.Text = "🧪"
        BetaStroke.Color = Color3.fromRGB(255, 180, 50)
    end
end)

-- Warning
local WarnFrame = Instance.new("Frame")
WarnFrame.Size = UDim2.new(1, -40, 0, 24)
WarnFrame.Position = UDim2.new(0, 20, 0, 300)
WarnFrame.BackgroundColor3 = Color3.fromRGB(35, 28, 15)
WarnFrame.BorderSizePixel = 0
WarnFrame.Parent = MainFrame
Instance.new("UICorner", WarnFrame).CornerRadius = UDim.new(0, 8)

local WarnText = Instance.new("TextLabel")
WarnText.Size = UDim2.new(1, -10, 1, 0)
WarnText.Position = UDim2.new(0, 10, 0, 0)
WarnText.BackgroundTransparency = 1
WarnText.Text = "⚠️ Beta may contain bugs. Use at your own risk."
WarnText.TextColor3 = Color3.fromRGB(180, 140, 70)
WarnText.TextSize = 9
WarnText.Font = Enum.Font.Gotham
WarnText.TextXAlignment = Enum.TextXAlignment.Left
WarnText.Parent = WarnFrame

print("🌟 Blox Fruits Farm Hub loaded!")
print("by lzwdev")
