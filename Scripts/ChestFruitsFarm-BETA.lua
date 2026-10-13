-- Fruit Notifier + Auto Tween + Chest Farm by lzwdev (merged)
-- Features: Fruit Notifier, Auto Tween (jede Distanz), Chest Farm, Chest ESP, Tween Speed Slider (50-300)

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game:GetService("Players") and game:GetService("CoreGui") and game:GetService("CollectionService")

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService= game:GetService("CollectionService")
local LocalPlayer      = Players.LocalPlayer

-- =====================================================
--  FRUIT ERKENNUNG
-- =====================================================
local function isFruit(obj)
    if not obj or not obj:IsA("Tool") then return false end
    local n = obj.Name
    return n:find("Fruit") or n:find("fruit") or n:find("%-")
end

local function getHandle(obj)
    return obj:FindFirstChild("Handle") or obj
end

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- =====================================================
--  CHEST ERKENNUNG
-- =====================================================
local function getChests()
    local list = {}
    for _, ch in pairs(CollectionService:GetTagged("_ChestTagged")) do
        if ch and ch:IsA("BasePart") and not ch:GetAttribute("IsDisabled") then
            table.insert(list, ch)
        end
    end
    return list
end

local function findNearestChest()
    local root = getRoot()
    if not root then return nil end
    local nearest, minDist = nil, math.huge
    for _, ch in ipairs(getChests()) do
        local d = (ch:GetPivot().Position - root.Position).Magnitude
        if d < minDist then
            minDist = d
            nearest = ch
        end
    end
    return nearest, minDist
end

-- =====================================================
--  NOTIFICATION SYSTEM (Stapel)
-- =====================================================
local NotifHolder = Instance.new("Frame")
NotifHolder.Name = "FruitNotifier_Stack"
NotifHolder.Size = UDim2.new(0, 320, 1, -40)
NotifHolder.Position = UDim2.new(1, -340, 0, 20)
NotifHolder.BackgroundTransparency = 1
NotifHolder.Parent = CoreGui
NotifHolder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8)
UIList.VerticalAlignment = Enum.VerticalAlignment.Top
UIList.Parent = NotifHolder

local notifOrder = 0

local function showNotification(title, subtitle, color)
    notifOrder = notifOrder + 1

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    card.BorderSizePixel = 0
    card.BackgroundTransparency = 1
    card.LayoutOrder = notifOrder
    card.Parent = NotifHolder
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 200, 80)
    stroke.Thickness = 2
    stroke.Transparency = 1
    stroke.Parent = card

    local side = Instance.new("Frame")
    side.Size = UDim2.new(0, 4, 1, -12)
    side.Position = UDim2.new(0, 6, 0, 6)
    side.BackgroundColor3 = color or Color3.fromRGB(255, 200, 80)
    side.BorderSizePixel = 0
    side.BackgroundTransparency = 1
    side.Parent = card
    Instance.new("UICorner", side).CornerRadius = UDim.new(0, 4)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 18, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Text = "🍎"
    icon.TextSize = 22
    icon.TextTransparency = 1
    icon.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -80, 0, 22)
    titleLbl.Position = UDim2.new(0, 62, 0, 10)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextSize = 13
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTransparency = 1
    titleLbl.Parent = card

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1, -80, 0, 18)
    subLbl.Position = UDim2.new(0, 62, 0, 32)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = subtitle
    subLbl.TextColor3 = Color3.fromRGB(160, 180, 220)
    subLbl.TextSize = 10
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.TextTransparency = 1
    subLbl.Parent = card

    local info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(card, info, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(side, info, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(stroke, info, { Transparency = 0 }):Play()
    TweenService:Create(icon, info, { TextTransparency = 0 }):Play()
    TweenService:Create(titleLbl, info, { TextTransparency = 0 }):Play()
    TweenService:Create(subLbl, info, { TextTransparency = 0 }):Play()

    task.delay(7.5, function()
        local out = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        local t1 = TweenService:Create(card, out, { BackgroundTransparency = 1 })
        local t2 = TweenService:Create(side, out, { BackgroundTransparency = 1 })
        local t3 = TweenService:Create(stroke, out, { Transparency = 1 })
        local t4 = TweenService:Create(icon, out, { TextTransparency = 1 })
        local t5 = TweenService:Create(titleLbl, out, { TextTransparency = 1 })
        local t6 = TweenService:Create(subLbl, out, { TextTransparency = 1 })
        t1:Play(); t2:Play(); t3:Play(); t4:Play(); t5:Play(); t6:Play()
        t1.Completed:Connect(function() card:Destroy() end)
    end)
end

-- =====================================================
--  STATE
-- =====================================================
local State = {
    TweenEnabled = false,
    TweenSpeed   = 220,       -- 50..300
    KnownFruits  = {},
    ChestFarm    = false,
    ChestESP     = false,
    AutoFruit    = false,
}

local function autoTweenActive()
    return State.TweenEnabled and not State.ChestFarm
end

-- =====================================================
--  FRUIT TRACKER
-- =====================================================
local function trackFruit(fruit)
    if State.KnownFruits[fruit] then return end
    State.KnownFruits[fruit] = true

    local handle = getHandle(fruit)
    local root = getRoot()
    local dist = root and math.floor((handle.Position - root.Position).Magnitude) or 0

    showNotification(
        "🍎 Fruit spawned: " .. fruit.Name,
        string.format("Distance: %d studs", dist),
        Color3.fromRGB(255, 200, 80)
    )

    fruit.AncestryChanged:Connect(function(_, parent)
        if not parent then
            State.KnownFruits[fruit] = nil
        end
    end)
end

local function scanFruits()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isFruit(obj) then
            trackFruit(obj)
        end
    end
end

scanFruits()

workspace.DescendantAdded:Connect(function(obj)
    if isFruit(obj) then
        task.wait(0.05)
        trackFruit(obj)
    end
end)

-- =====================================================
--  AUTO TWEEN (jede Distanz)
-- =====================================================
local isTweening = false

local function collectFruitsSorted()
    local root = getRoot()
    if not root then return {} end

    local list = {}
    for fruit in pairs(State.KnownFruits) do
        if fruit and fruit.Parent then
            local handle = getHandle(fruit)
            local dist = (handle.Position - root.Position).Magnitude
            table.insert(list, { fruit = fruit, dist = dist, handle = handle })
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function flyTo(targetPos, speed)
    local root = getRoot()
    if not root then return end

    local startPos = root.Position
    local dist = (targetPos - startPos).Magnitude
    local duration = math.max(0.05, dist / speed)

    local goal = { CFrame = CFrame.new(targetPos) }
    local tween = TweenService:Create(
        root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        goal
    )
    tween:Play()
    tween.Completed:Wait()
end

task.spawn(function()
    while task.wait(0.2) do
        if not autoTweenActive() then continue end
        if isTweening then continue end

        local list = collectFruitsSorted()
        if #list == 0 then continue end

        isTweening = true

        for _, entry in ipairs(list) do
            if not autoTweenActive() then break end
            if not entry.fruit.Parent then continue end

            pcall(function()
                flyTo(entry.handle.Position, State.TweenSpeed)
            end)

            task.wait(0.1)
        end

        isTweening = false
    end
end)

-- =====================================================
--  CHEST ESP
-- =====================================================
local chestESPObjects = {}

local function createChestESP(ch)
    if not ch or chestESPObjects[ch] then return end
    pcall(function()
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 160, 0, 30)
        bb.Adornee = ch
        bb.AlwaysOnTop = true
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.Parent = ch

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.5
        bg.BorderSizePixel = 0
        bg.Parent = bb
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.Text = "Chest"
        l.TextColor3 = Color3.fromRGB(255, 215, 0)
        l.TextScaled = true
        l.Font = Enum.Font.GothamBold
        l.Parent = bb

        chestESPObjects[ch] = { BB = bb, Lbl = l }
    end)
end

local function updateChestESP()
    local root = getRoot()
    if not root then return end
    local p = root.Position

    for _, ch in pairs(getChests()) do
        pcall(function()
            if State.ChestESP then
                if not chestESPObjects[ch] then createChestESP(ch) end
                local e = chestESPObjects[ch]
                if e and e.Lbl then
                    local d = math.floor((p - ch:GetPivot().Position).Magnitude / 3 + 0.5)
                    e.Lbl.Text = "Chest (" .. d .. "m)"
                end
            else
                if chestESPObjects[ch] then
                    if chestESPObjects[ch].BB then chestESPObjects[ch].BB:Destroy() end
                    chestESPObjects[ch] = nil
                end
            end
        end)
    end
end

-- =====================================================
--  CHEST FARM LOOP
-- =====================================================
local ignoredChests = {}
local currentChestTarget = nil
local chestArrivedTime = 0
local chestsCollected = 0
local isFarmingChest = false

task.spawn(function()
    while task.wait(0.3) do
        if State.ChestFarm and not isTweening then
            pcall(function()
                local root = getRoot()
                if not root then return end

                if currentChestTarget then
                    local dist = (currentChestTarget:GetPivot().Position - root.Position).Magnitude
                    if dist < 10 then
                        if chestArrivedTime == 0 then
                            chestArrivedTime = tick()
                        elseif tick() - chestArrivedTime > 5 then
                            ignoredChests[currentChestTarget] = true
                            currentChestTarget = nil
                            chestArrivedTime = 0
                            task.wait(0.5)
                            return
                        end
                    else
                        chestArrivedTime = 0
                    end
                end

                local ch, dist = findNearestChest()
                -- Filter ignored
                while ch and ignoredChests[ch] do
                    ch, dist = nil, nil
                    -- fallback: find next
                    local best, bestD = nil, math.huge
                    for _, c in ipairs(getChests()) do
                        if not ignoredChests[c] then
                            local d = (c:GetPivot().Position - root.Position).Magnitude
                            if d < bestD then bestD = d; best = c end
                        end
                    end
                    ch, dist = best, bestD
                    break
                end

                if ch and dist then
                    if ch ~= currentChestTarget then
                        currentChestTarget = ch
                        chestArrivedTime = 0
                    end
                    isFarmingChest = true
                    flyTo(ch:GetPivot().Position + Vector3.new(0, 3, 0), State.TweenSpeed)
                    if dist < 15 then
                        chestsCollected = chestsCollected + 1
                    end
                    isFarmingChest = false
                else
                    currentChestTarget = nil
                    chestArrivedTime = 0
                    task.wait(1)
                end
            end)
        end
    end
end)

-- =====================================================
--  GUI
-- =====================================================
local gui = Instance.new("ScreenGui")
gui.Name = "FruitNotifier_ChestFarm_GUI"
gui.Parent = CoreGui
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 420)
frame.Position = UDim2.new(0, 20, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundTransparency = 1
title.Text = "🍎 Fruit & Chest Farm"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

-- ========== TAB BAR ==========
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 30)
tabBar.Position = UDim2.new(0, 10, 0, 38)
tabBar.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
tabBar.BorderSizePixel = 0
tabBar.Parent = frame
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 8)

local function makeTab(name, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -4, 1, -4)
    b.Position = UDim2.new(x, 2, 0, 2)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    b.BorderSizePixel = 0
    b.Text = name
    b.TextColor3 = Color3.fromRGB(180, 180, 200)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.Parent = tabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local fruitTabBtn = makeTab("Fruits", 0)
local chestTabBtn = makeTab("Chest Farm", 0.5)

-- ========== CONTENT ==========
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -160)
content.Position = UDim2.new(0, 10, 0, 76)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = frame

-- Fruit Page
local fruitPage = Instance.new("Frame")
fruitPage.Size = UDim2.new(1, 0, 1, 0)
fruitPage.Position = UDim2.new(0, 0, 0, 0)
fruitPage.BackgroundTransparency = 1
fruitPage.Parent = content

-- Chest Page
local chestPage = Instance.new("Frame")
chestPage.Size = UDim2.new(1, 0, 1, 0)
chestPage.Position = UDim2.new(1, 0, 0, 0)
chestPage.BackgroundTransparency = 1
chestPage.Parent = content

local function switchTab(tab)
    if tab == "fruit" then
        TweenService:Create(fruitPage, TweenInfo.new(0.25), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        TweenService:Create(chestPage, TweenInfo.new(0.25), { Position = UDim2.new(1, 0, 0, 0) }):Play()
        fruitTabBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
        fruitTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        chestTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        chestTabBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    else
        TweenService:Create(fruitPage, TweenInfo.new(0.25), { Position = UDim2.new(-1, 0, 0, 0) }):Play()
        TweenService:Create(chestPage, TweenInfo.new(0.25), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        chestTabBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
        chestTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        fruitTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        fruitTabBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    end
end

fruitTabBtn.MouseButton1Click:Connect(function() switchTab("fruit") end)
chestTabBtn.MouseButton1Click:Connect(function() switchTab("chest") end)
switchTab("fruit")

-- ========== FRUIT PAGE ==========
local fruitToggle = Instance.new("TextButton")
fruitToggle.Size = UDim2.new(1, 0, 0, 34)
fruitToggle.Position = UDim2.new(0, 0, 0, 0)
fruitToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
fruitToggle.BorderSizePixel = 0
fruitToggle.Text = "Auto Tween  [OFF]"
fruitToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
fruitToggle.Font = Enum.Font.GothamBold
fruitToggle.TextSize = 12
fruitToggle.Parent = fruitPage
Instance.new("UICorner", fruitToggle).CornerRadius = UDim.new(0, 8)

fruitToggle.MouseButton1Click:Connect(function()
    State.TweenEnabled = not State.TweenEnabled
    fruitToggle.BackgroundColor3 = State.TweenEnabled and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(45, 45, 60)
    fruitToggle.Text = "Auto Tween  [" .. (State.TweenEnabled and "ON" or "OFF") .. "]"
end)

-- Speed Label (Fruit)
local speedLbl = Instance.new("TextLabel")
speedLbl.Size = UDim2.new(1, 0, 0, 20)
speedLbl.Position = UDim2.new(0, 0, 0, 42)
speedLbl.BackgroundTransparency = 1
speedLbl.Text = "Tween Speed: " .. State.TweenSpeed
speedLbl.TextColor3 = Color3.fromRGB(180, 200, 255)
speedLbl.Font = Enum.Font.Gotham
speedLbl.TextSize = 11
speedLbl.TextXAlignment = Enum.TextXAlignment.Left
speedLbl.Parent = fruitPage

-- Speed Slider (Fruit)
local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, 0, 0, 10)
sliderBg.Position = UDim2.new(0, 0, 0, 66)
sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = fruitPage
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 5)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new((State.TweenSpeed - 50) / 250, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 5)

local sliderKnob = Instance.new("TextButton")
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.Position = UDim2.new((State.TweenSpeed - 50) / 250, -7, 0.5, -7)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.BorderSizePixel = 0
sliderKnob.Text = ""
sliderKnob.Parent = sliderBg
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

local draggingFruit = false

local function setSliderFromX(x)
    local relX = math.clamp((x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
    local speed = math.floor(50 + relX * 250) -- 50..300
    State.TweenSpeed = speed
    sliderFill.Size = UDim2.new(relX, 0, 1, 0)
    sliderKnob.Position = UDim2.new(relX, -7, 0.5, -7)
    speedLbl.Text = "Tween Speed: " .. speed
end

sliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        draggingFruit = true
    end
end)

sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        draggingFruit = true
        setSliderFromX(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingFruit and (input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch) then
        setSliderFromX(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        draggingFruit = false
    end
end)

-- Info Label
local infoLbl = Instance.new("TextLabel")
infoLbl.Size = UDim2.new(1, 0, 0, 20)
infoLbl.Position = UDim2.new(0, 0, 0, 90)
infoLbl.BackgroundTransparency = 1
infoLbl.Text = "Tweent zu JEDER Distanz automatisch."
infoLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 10
infoLbl.TextXAlignment = Enum.TextXAlignment.Left
infoLbl.Parent = fruitPage

-- ========== CHEST PAGE ==========
local chestFarmToggle = Instance.new("TextButton")
chestFarmToggle.Size = UDim2.new(1, 0, 0, 34)
chestFarmToggle.Position = UDim2.new(0, 0, 0, 0)
chestFarmToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
chestFarmToggle.BorderSizePixel = 0
chestFarmToggle.Text = "Auto Chest Farm  [OFF]"
chestFarmToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
chestFarmToggle.Font = Enum.Font.GothamBold
chestFarmToggle.TextSize = 12
chestFarmToggle.Parent = chestPage
Instance.new("UICorner", chestFarmToggle).CornerRadius = UDim.new(0, 8)

chestFarmToggle.MouseButton1Click:Connect(function()
    State.ChestFarm = not State.ChestFarm
    chestFarmToggle.BackgroundColor3 = State.ChestFarm and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(45, 45, 60)
    chestFarmToggle.Text = "Auto Chest Farm  [" .. (State.ChestFarm and "ON" or "OFF") .. "]"
    if State.ChestFarm then
        ignoredChests = {}
        currentChestTarget = nil
        chestArrivedTime = 0
    end
end)

local chestESPToggle = Instance.new("TextButton")
chestESPToggle.Size = UDim2.new(1, 0, 0, 34)
chestESPToggle.Position = UDim2.new(0, 0, 0, 42)
chestESPToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
chestESPToggle.BorderSizePixel = 0
chestESPToggle.Text = "Chest ESP  [OFF]"
chestESPToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
chestESPToggle.Font = Enum.Font.GothamBold
chestESPToggle.TextSize = 12
chestESPToggle.Parent = chestPage
Instance.new("UICorner", chestESPToggle).CornerRadius = UDim.new(0, 8)

chestESPToggle.MouseButton1Click:Connect(function()
    State.ChestESP = not State.ChestESP
    chestESPToggle.BackgroundColor3 = State.ChestESP and Color3.fromRGB(0, 180, 90) or Color3.fromRGB(45, 45, 60)
    chestESPToggle.Text = "Chest ESP  [" .. (State.ChestESP and "ON" or "OFF") .. "]"
    if not State.ChestESP then
        for ch, data in pairs(chestESPObjects) do
            if data.BB then data.BB:Destroy() end
            chestESPObjects[ch] = nil
        end
    end
end)

-- Chest Info
local chestInfo = Instance.new("TextLabel")
chestInfo.Size = UDim2.new(1, 0, 0, 20)
chestInfo.Position = UDim2.new(0, 0, 0, 86)
chestInfo.BackgroundTransparency = 1
chestInfo.Text = "Chest Farm hat Vorrang vor Fruit Tween."
chestInfo.TextColor3 = Color3.fromRGB(140, 140, 160)
chestInfo.Font = Enum.Font.Gotham
chestInfo.TextSize = 10
chestInfo.TextXAlignment = Enum.TextXAlignment.Left
chestInfo.Parent = chestPage

-- ========== ESP LOOP ==========
task.spawn(function()
    while task.wait(0.3) do
        if State.ChestESP then
            updateChestESP()
        end
    end
end)

print("✅ Fruit Notifier + Auto Tween + Chest Farm geladen!")
print("Tween Speed: 50-300 (Slider im Fruits Tab)")
print("Chest Farm hat Vorrang wenn aktiviert.")
