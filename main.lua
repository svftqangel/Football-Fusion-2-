local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create main window
local Window = Rayfield:CreateWindow({
    Name = "Football Fusion 🏈",
    LoadingTitle = "Rayfield Interface Suite",
    LoadingSubtitle = "by Svderr2", -- updated
    ShowText = "Rayfield",
    Theme = "Default",
    ToggleUIKeybind = Enum.KeyCode.K,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FootballFusionHub",
        FileName = "BigHub"
    },
    Discord = {
        Enabled = false,
        Invite = "ABCD",
        RememberJoins = true
    },
    KeySystem = true,
    KeySettings = {
        Title = "Verdin",
        Subtitle = "Key System",
        Note = "Key = Hello",
        FileName = "KeyFile",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

-- ✅ Tab
local CatchingTab = Window:CreateTab("Catching", 4483362458)

-- ===== MAGNET BACKEND =====
getgenv().g = getgenv().g or {}
g.magnetEnabled = false
g.magnetRange = 13
g.currentMode = "Regular"
g.hitboxEnabled = false
g.hitboxType = "Forcefield"
g.rainbowHitboxEnabled = false
g.rainbowSpeed = 0.5
g.ping = 0.12

-- Long Arm settings
g.longArmEnabled = false
g.longArmDistance = 10

local hitboxes, velocities, lastPositions = {}, {}, {}
local rainbowHue = 0
local modeRanges = {Regular = 13, League = 6, Legit = 10, Rage = 25, Custom = 0}

local function getRange()
    if g.currentMode == "Custom" then return g.magnetRange end
    return modeRanges[g.currentMode] or 13
end

local function findFootballs()
    local balls = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name == "Football" and not obj.Anchored then
            balls[#balls+1] = obj
        end
    end
    return balls
end

local function nearestPart(ref, parts)
    local closest, dist = nil, math.huge
    if not ref or not ref.Position then return nil end
    for _, p in ipairs(parts) do
        local d = (ref.Position - p.Position).Magnitude
        if d < dist then dist, closest = d, p end
    end
    return closest
end

local function rainbowUpdate()
    rainbowHue = (rainbowHue + (g.rainbowSpeed / 255)) % 1
    return Color3.fromHSV(rainbowHue, 1, 1)
end

local function createOrUpdateHitbox(ball)
    local size = getRange()
    local hb = hitboxes[ball]
    if not hb or not hb.Parent then
        hb = Instance.new("Part")
        hb.Name = "Croom_Hitbox"
        hb.Anchored = true
        hb.CanCollide = false
        hb.Size = Vector3.new(size, size, size)
        hb.CFrame = ball.CFrame
        hb.Parent = Workspace
        hitboxes[ball] = hb
    end
    hb.Size = Vector3.new(size, size, size)
    hb.CFrame = ball.CFrame
    for _,child in ipairs(hb:GetChildren()) do
        if child:IsA("SelectionBox") or child:IsA("SelectionSphere") then child:Destroy() end
    end
    if g.rainbowHitboxEnabled then
        hb.Shape = Enum.PartType.Ball
        hb.Material = Enum.Material.ForceField
        hb.Color = rainbowUpdate()
        hb.Transparency = 0.3
    elseif g.hitboxType == "Forcefield" then
        hb.Shape = Enum.PartType.Ball
        hb.Material = Enum.Material.ForceField
        hb.Color = Color3.fromRGB(50,205,50)
        hb.Transparency = 0.3
    elseif g.hitboxType == "Sphere" then
        hb.Shape = Enum.PartType.Ball
        hb.Material = Enum.Material.SmoothPlastic
        hb.Color = Color3.fromRGB(255,105,180)
        hb.Transparency = 0.4
        local outline = Instance.new("SelectionSphere", hb)
        outline.Adornee = hb
        outline.SurfaceColor3 = Color3.fromRGB(137,207,240)
        outline.SurfaceTransparency = 0.3
    else
        hb.Shape = Enum.PartType.Block
        hb.Material = Enum.Material.SmoothPlastic
        hb.Color = Color3.fromRGB(120,120,120)
        hb.Transparency = 0.65
        local outline = Instance.new("SelectionBox", hb)
        outline.Adornee = hb
        outline.LineThickness = 0.05
        outline.Color3 = Color3.fromRGB(120,120,120)
        outline.Transparency = 0.6
    end
end

local function clearHitbox(ball)
    if hitboxes[ball] then
        hitboxes[ball]:Destroy()
        hitboxes[ball] = nil
    end
    velocities[ball], lastPositions[ball] = nil, nil
end

Workspace.ChildRemoved:Connect(function(obj)
    if hitboxes[obj] then clearHitbox(obj) end
end)

RunService.Heartbeat:Connect(function(dt)
    local balls = findFootballs()
    if #balls == 0 then return end
    local char = LocalPlayer.Character
    local leftCatch = char and (char:FindFirstChild("LeftCatch") or char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm"))
    local rightCatch = char and (char:FindFirstChild("RightCatch") or char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
    for _, ball in ipairs(balls) do
        local last = lastPositions[ball] or ball.Position
        velocities[ball] = (ball.Position - last) / (dt > 0 and dt or 0.016)
        lastPositions[ball] = ball.Position
        if g.hitboxEnabled or g.rainbowHitboxEnabled then
            createOrUpdateHitbox(ball)
        else
            clearHitbox(ball)
        end

        if g.magnetEnabled and leftCatch and rightCatch then
            local predictedPos = ball.Position + (velocities[ball] or Vector3.new()) * g.ping

            -- Long Arm extension
            local leftPos = leftCatch.Position
            local rightPos = rightCatch.Position
            if g.longArmEnabled then
                local dirToBallL = (predictedPos - leftPos).Unit
                leftPos = leftPos + dirToBallL * g.longArmDistance

                local dirToBallR = (predictedPos - rightPos).Unit
                rightPos = rightPos + dirToBallR * g.longArmDistance
            end

            local nearest = nearestPart(ball, {leftPos, rightPos})
            if nearest and (nearest.Position - predictedPos).Magnitude <= getRange() + (g.longArmEnabled and g.longArmDistance or 0) then
                pcall(function()
                    firetouchinterest(leftCatch, ball, 0)
                    firetouchinterest(leftCatch, ball, 1)
                    firetouchinterest(rightCatch, ball, 0)
                    firetouchinterest(rightCatch, ball, 1)
                end)
            end
        end
    end
end)

-- ===== RAYFIELD UI =====
CatchingTab:CreateSection("Magnet Settings")

CatchingTab:CreateToggle({
    Name = "Magnets",
    CurrentValue = false,
    Flag = "Magnets",
    Callback = function(Value) g.magnetEnabled = Value end,
})

CatchingTab:CreateSlider({
    Name = "Magnet Range",
    Range = {0, 40},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 13,
    Flag = "MagnetRange",
    Callback = function(Value) g.magnetRange = Value end,
})

CatchingTab:CreateDropdown({
    Name = "Magnet Type",
    Options = {"Regular","League","Legit","Rage","Custom"},
    CurrentOption = {"Regular"},
    MultipleOptions = false,
    Flag = "MagnetType",
    Callback = function(Options) g.currentMode = Options[1] end,
})

CatchingTab:CreateDivider()

CatchingTab:CreateToggle({
    Name = "Magnet Hitbox",
    CurrentValue = false,
    Flag = "MagnetHitbox",
    Callback = function(Value) g.hitboxEnabled = Value end,
})

CatchingTab:CreateDropdown({
    Name = "Hitbox Type",
    Options = {"Forcefield","Sphere","Box"},
    CurrentOption = {"Forcefield"},
    MultipleOptions = false,
    Flag = "HitboxType",
    Callback = function(Options) g.hitboxType = Options[1] end,
})

CatchingTab:CreateToggle({
    Name = "Rainbow Hitbox",
    CurrentValue = false,
    Flag = "RainbowHitbox",
    Callback = function(Value) g.rainbowHitboxEnabled = Value end,
})

CatchingTab:CreateSlider({
    Name = "Rainbow Speed",
    Range = {0.01, 2},
    Increment = 0.01,
    CurrentValue = 0.5,
    Flag = "RainbowSpeed",
    Callback = function(Value) g.rainbowSpeed = Value end,
})

-- ===== LONG ARM UI =====
CatchingTab:CreateToggle({
    Name = "Long Arm",
    CurrentValue = false,
    Flag = "LongArm",
    Callback = function(Value) g.longArmEnabled = Value end,
})

CatchingTab:CreateSlider({
    Name = "Arm Distance",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 10,
    Flag = "LongArmDistance",
    Callback = function(Value) g.longArmDistance = Value end,
})

Rayfield:Notify({
    Title = "Magnet Hub Loaded",
    Content = "Magnet + Hitbox settings are ready.",
    Duration = 5,
    Image = "rewind",
})

-- ===== CREDITS TAB =====
local CreditsTab = Window:CreateTab("Credits", 4483362458)

CreditsTab:CreateSection("Script Creator")
CreditsTab:CreateLabel("Made by Svderr2")

Rayfield:Notify({
    Title = "Credits",
    Content = "Made by Svderr2",
    Duration = 5,
    Image = "star"
})
