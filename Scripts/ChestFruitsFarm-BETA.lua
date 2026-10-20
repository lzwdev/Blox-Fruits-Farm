-- Fruit Notifier + Auto Tween + Chest Farm (Nebula UI Edition) - CLEAN & STABLE
-- Features: Fruit Notifier, Auto Tween, Chest Farm, Chest ESP, Tween Speed Slider

if not game:IsLoaded() then game.Loaded:Wait() end

-- =====================================================
--  NEBULA UI LADEN (mit Retry & Fehlerfang)
-- =====================================================
local Nebula
local success, err = pcall(function()
    Nebula = loadstring(game:HttpGet("https://raw.githubusercontent.com/lzwdev/Nebula/refs/heads/main/Nebula-UI/V3.lua"))()
end)
if not success or not Nebula then
    warn("Nebula UI konnte nicht geladen werden: " .. tostring(err))
    return
end

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
--  VARIABLEN & STATE (Alles ganz oben, um Linter-Warnungen zu vermeiden!)
-- =====================================================
local State = {
    TweenEnabled = false,
    TweenSpeed   = 220,
    KnownFruits  = {},
    ChestFarm    = false,
    ChestESP     = false,
}

local isTweening = false
local chestESPObjects = {}
local ignoredChests = {}
local currentChestTarget = nil
local chestArrivedTime = 0

-- =====================================================
--  HELPER: Section erstellen
-- =====================================================
local function CreateSection(tab, name)
    local ok, res = pcall(function() return tab:CreateSection(name) end)
    if ok and res then return res end
    ok, res = pcall(function() return tab:CreateSection({ Name = name }) end)
    if ok and res then return res end
    ok, res = pcall(function() return Nebula.CreateSection(tab, { Name = name }) end)
    if ok and res then return res end
    ok, res = pcall(function() return Nebula.CreateSection(tab, name) end)
    if ok and res then return res end
    warn("[Nebula] Could not create section: " .. tostring(name))
    return nil
end

-- =====================================================
--  FRUIT / CHEST LOGIK
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

local function getChests()
    local list = {}
    for _, ch in pairs(CollectionService:GetTagged("_ChestTagged")) do
        if ch and ch:IsA("BasePart") and not ch:GetAttribute("IsDisabled") then
            table.insert(list, ch)
        end
    end
    return list
end

-- =====================================================
--  NEBULA WINDOW & UI AUFBAU (Zuerst!)
-- =====================================================
local Window = Nebula.CreateWindow({
    Title = "Fruit & Chest Farm",
    ConfigName = "FruitChestFarm_Nebula",
    ShowLoading = true,
    LoadingDuration = 2,
    LoadingSteps = {
        "Initializing...",
        "Building UI...",
        "Ready!"
    }
})

local FruitTab    = Window:CreateTab("Fruits", "🍎")
local ChestTab    = Window:CreateTab("Chest Farm", "📦")
local SettingsTab = Window:CreateTab("Settings", "⚙")

-- FRUIT TAB
local FruitSection = CreateSection(FruitTab, "Auto Tween")
if FruitSection then
    FruitSection:CreateToggle({
        Name = "Auto Tween Fruits",
        Default = false,
        Callback = function(Value) State.TweenEnabled = Value end
    })
    FruitSection:CreateSlider({
        Name = "Tween Speed",
        Min = 50, Max = 300, Default = 220, Suffix = " studs/s",
        Callback = function(Value) State.TweenSpeed = Value end
    })
end
local FruitInfo = CreateSection(FruitTab, "Info")
if FruitInfo and FruitInfo.CreateLabel then
    FruitInfo:CreateLabel("Tweent zu JEDER Distanz automatisch.")
end

-- CHEST TAB
local ChestSection = CreateSection(ChestTab, "Chest Farm")
if ChestSection then
    ChestSection:CreateToggle({
        Name = "Auto Chest Farm",
        Default = false,
        Callback = function(Value) 
            State.ChestFarm = Value 
            if Value then 
                ignoredChests = {} 
                currentChestTarget = nil 
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
end
local ChestInfo = CreateSection(ChestTab, "Info")
if ChestInfo and ChestInfo.CreateLabel then
    ChestInfo:CreateLabel("Chest Farm hat Vorrang vor Fruit Tween.")
end

-- SETTINGS TAB
local SettingsSection = CreateSection(SettingsTab, "Allgemein")
if SettingsSection then
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
                LocalPlayer.CharacterAdded:Connect(function(c) task.wait(0.1); setNoclip(c, true) end)
                if LocalPlayer.Character then setNoclip(LocalPlayer.Character, true) end
            else
                if LocalPlayer.Character then setNoclip(LocalPlayer.Character, false) end
            end
        end
    })
    SettingsSection:CreateSlider({
        Name = "WalkSpeed",
        Min = 16, Max = 300, Default = 16, Suffix = " Studs",
        Callback = function(Value)
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
            end
        end
    })
end

-- =====================================================
--  BACKGROUND LOOPS (Mit pcall geschützt!)
-- =====================================================

-- 1. Fruit Tracker Loop
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if isFruit(obj) and not State.KnownFruits[obj] then
                    State.KnownFruits[obj] = true
                    local handle = getHandle(obj)
                    local root = getRoot()
                    local dist = root and math.floor((handle.Position - root.Position).Magnitude) or 0
                    
                    Window:Notify({
                        Title = "🍎 Fruit spawned",
                        Content = obj.Name .. " - " .. dist .. " studs",
                        Type = "info", Duration = 5, Icon = "🍎"
                    })

                    obj.AncestryChanged:Connect(function(_, parent)
                        if not parent then State.KnownFruits[obj] = nil end
                    end)
                end
            end
        end)
    end
end)

-- 2. Auto Tween Loop
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if not (State.TweenEnabled and not State.ChestFarm) then return end
            if isTweening then return end

            local root = getRoot()
            if not root then return end

            local list = {}
            for fruit in pairs(State.KnownFruits) do
                if fruit and fruit.Parent then
                    local handle = getHandle(fruit)
                    table.insert(list, { fruit = fruit, dist = (handle.Position - root.Position).Magnitude, handle = handle })
                end
            end
            table.sort(list, function(a, b) return a.dist < b.dist end)
            if #list == 0 then return end

            isTweening = true
            for _, entry in ipairs(list) do
                if not (State.TweenEnabled and not State.ChestFarm) then break end
                if not entry.fruit.Parent then continue end

                local dist = (entry.handle.Position - root.Position).Magnitude
                local duration = math.max(0.05, dist / State.TweenSpeed)
                local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = CFrame.new(entry.handle.Position) })
                tween:Play()
                tween.Completed:Wait()
                task.wait(0.1)
            end
            isTweening = false
        end)
    end
end)

-- 3. Chest ESP Loop
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if not State.ChestESP then return end
            local root = getRoot()
            if not root then return end
            local p = root.Position

            for _, ch in pairs(getChests()) do
                if not chestESPObjects[ch] then
                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 160, 0, 30)
                    bb.Adornee = ch; bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 2, 0); bb.Parent = ch
                    
                    local bg = Instance.new("Frame")
                    bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    bg.BackgroundTransparency = 0.5; bg.BorderSizePixel = 0; bg.Parent = bb
                    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)

                    local l = Instance.new("TextLabel")
                    l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 1; l.Text = "Chest"
                    l.TextColor3 = Color3.fromRGB(255, 215, 0); l.TextScaled = true; l.Font = Enum.Font.GothamBold; l.Parent = bb

                    chestESPObjects[ch] = { BB = bb, Lbl = l }
                end
                local e = chestESPObjects[ch]
                if e and e.Lbl then
                    e.Lbl.Text = "Chest (" .. math.floor((p - ch:GetPivot().Position).Magnitude / 3 + 0.5) .. "m)"
                end
            end
        end)
    end
end)

-- 4. Chest Farm Loop
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if not (State.ChestFarm and not isTweening) then return end
            local root = getRoot()
            if not root then return end

            if currentChestTarget then
                if (currentChestTarget:GetPivot().Position - root.Position).Magnitude < 10 then
                    if chestArrivedTime == 0 then chestArrivedTime = tick()
                    elseif tick() - chestArrivedTime > 5 then
                        ignoredChests[currentChestTarget] = true
                        currentChestTarget = nil; chestArrivedTime = 0
                    end
                else chestArrivedTime = 0 end
            end

            local best, bestD = nil, math.huge
            for _, c in ipairs(getChests()) do
                if not ignoredChests[c] then
                    local d = (c:GetPivot().Position - root.Position).Magnitude
                    if d < bestD then bestD = d; best = c end
                end
            end

            if best and bestD then
                if best ~= currentChestTarget then currentChestTarget = best; chestArrivedTime = 0 end
                local duration = math.max(0.05, (best:GetPivot().Position - root.Position).Magnitude / State.TweenSpeed)
                local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = best:GetPivot().Position + Vector3.new(0, 3, 0) })
                tween:Play(); tween.Completed:Wait()
            else
                currentChestTarget = nil; chestArrivedTime = 0; task.wait(1)
            end
        end)
    end
end)

-- =====================================================
--  READY NOTIFICATION
-- =====================================================
Window:Notify({
    Title = "Geladen!",
    Content = "Fruit Notifier + Auto Tween + Chest Farm",
    Type = "success", Duration = 5, Icon = "✅"
})

print("✅ Script erfolgreich geladen!")
