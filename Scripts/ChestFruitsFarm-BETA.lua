-- Fruit Notifier + Auto Tween + Chest Farm (Nebula UI Edition)
-- Features: Fruit Notifier, Auto Tween (jede Distanz), Chest Farm, Chest ESP, Tween Speed Slider (50-300)

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game:GetService("Players") and game:GetService("CoreGui") and game:GetService("CollectionService")

-- =====================================================
--  NEBULA UI LADEN
-- =====================================================
local Nebula = loadstring(game:HttpGet("https://raw.githubusercontent.com/lzwdev/Nebula/refs/heads/main/Nebula-UI/V3.lua"))()

-- =====================================================
--  SERVICES
-- =====================================================
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
--  STATE
-- =====================================================
local State = {
    TweenEnabled = false,
    TweenSpeed   = 220,
    KnownFruits  = {},
    ChestFarm    = false,
    ChestESP     = false,
}

local function autoTweenActive()
    return State.TweenEnabled and not State.ChestFarm
end

-- =====================================================
--  NEBULA WINDOW ERSTELLEN
-- =====================================================
local Window = Nebula.CreateWindow({
    Title = "🍎 Fruit & Chest Farm",
    ConfigName = "FruitChestFarm_Nebula",
    ShowLoading = true,
    LoadingDuration = 3,
    LoadingSteps = {
        "Initializing...",
        "Loading Fruit System...",
        "Loading Chest System...",
        "Ready!"
    }
})

-- =====================================================
--  TABS ERSTELLEN
-- =====================================================
local FruitTab    = Window:CreateTab("Fruits", "🍎")
local ChestTab    = Window:CreateTab("Chest Farm", "📦")
local SettingsTab = Window:CreateTab("Settings", "⚙")

-- =====================================================
--  FRUIT TRACKER
-- =====================================================
local function trackFruit(fruit)
    if State.KnownFruits[fruit] then return end
    State.KnownFruits[fruit] = true

    local handle = getHandle(fruit)
    local root = getRoot()
    local dist = root and math.floor((handle.Position - root.Position).Magnitude) or 0

    Window:Notify({
        Title = "🍎 Fruit spawned",
        Content = fruit.Name .. "  ·  " .. dist .. " studs",
        Type = "info",
        Duration = 6,
        Icon = "🍎"
    })

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

task.spawn(function()
    while task.wait(0.3) do
        if State.ChestESP then updateChestESP() end
    end
end)

-- =====================================================
--  CHEST FARM LOOP
-- =====================================================
local ignoredChests = {}
local currentChestTarget = nil
local chestArrivedTime = 0
local chestsCollected = 0

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

                local best, bestD = nil, math.huge
                for _, c in ipairs(getChests()) do
                    if not ignoredChests[c] then
                        local d = (c:GetPivot().Position - root.Position).Magnitude
                        if d < bestD then bestD = d; best = c end
                    end
                end

                if best and bestD then
                    if best ~= currentChestTarget then
                        currentChestTarget = best
                        chestArrivedTime = 0
                    end
                    flyTo(best:GetPivot().Position + Vector3.new(0, 3, 0), State.TweenSpeed)
                    if bestD < 15 then
                        chestsCollected = chestsCollected + 1
                    end
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
--  FRUIT TAB UI
-- =====================================================
local FruitSection = Nebula.CreateSection(FruitTab, {
    Name = "Auto Tween"
})

FruitSection:CreateToggle({
    Name = "Auto Tween Fruits",
    Default = false,
    Callback = function(Value)
        State.TweenEnabled = Value
    end
})

FruitSection:CreateSlider({
    Name = "Tween Speed",
    Min = 50,
    Max = 300,
    Default = 220,
    Suffix = " studs/s",
    Callback = function(Value)
        State.TweenSpeed = Value
    end
})

local InfoSection = Nebula.CreateSection(FruitTab, {
    Name = "Info"
})

InfoSection:CreateToggle({
    Name = "Tweent zu JEDER Distanz",
    Default = true,
    Callback = function(Value)
        -- Nur Info-Toggle (immer an)
    end
})

-- =====================================================
--  CHEST TAB UI
-- =====================================================
local ChestSection = Nebula.CreateSection(ChestTab, {
    Name = "Chest Farm"
})

ChestSection:CreateToggle({
    Name = "Auto Chest Farm",
    Default = false,
    Callback = function(Value)
        State.ChestFarm = Value
        if Value then
            ignoredChests = {}
            currentChestTarget = nil
            chestArrivedTime = 0
        end
    end
})

ChestSection:CreateToggle({
    Name = "Chest ESP",
    Default = false,
    Callback = function(Value)
        State.ChestESP = Value
        if not Value then
            for ch, data in pairs(chestESPObjects) do
                if data.BB then data.BB:Destroy() end
                chestESPObjects[ch] = nil
            end
        end
    end
})

local ChestInfo = Nebula.CreateSection(ChestTab, {
    Name = "Info"
})

ChestInfo:CreateToggle({
    Name = "Chest Farm hat Vorrang",
    Default = true,
    Callback = function(Value) end
})

-- =====================================================
--  SETTINGS TAB UI
-- =====================================================
local SettingsSection = Nebula.CreateSection(SettingsTab, {
    Name = "Allgemein"
})

SettingsSection:CreateToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(Value)
        local function setNoclip(c, state)
            if not c then return end
            pcall(function()
                for _, p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = not state end
                end
            end)
        end
        if Value then
            LocalPlayer.CharacterAdded:Connect(function(c)
                task.wait(0.1)
                setNoclip(c, true)
            end)
            if LocalPlayer.Character then setNoclip(LocalPlayer.Character, true) end
        else
            if LocalPlayer.Character then setNoclip(LocalPlayer.Character, false) end
        end
    end
})

SettingsSection:CreateSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 300,
    Default = 16,
    Suffix = " Studs",
    Callback = function(Value)
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
        end
    end
})

local InfoSection2 = Nebula.CreateSection(SettingsTab, {
    Name = "Info"
})

InfoSection2:CreateTextBox({
    Placeholder = "Version",
    Default = "v1.0 · Nebula UI",
    Callback = function(Text) end
})

Window:Notify({
    Title = "✅ Geladen!",
    Content = "Fruit Notifier + Auto Tween + Chest Farm",
    Type = "success",
    Duration = 5,
    Icon = "✅"
})

print("✅ Fruit Notifier + Auto Tween + Chest Farm (Nebula UI) geladen!")
