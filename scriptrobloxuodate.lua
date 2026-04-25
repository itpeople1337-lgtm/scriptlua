--[[
	ALLVESZ V10 PRO - Refactored & Optimized.
	Versi Indonesia + Skeleton ESP + Bypass Protection
	WARNING: Execute at your own risk!
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local V10_VERSION = "V10 PRO INDO"

-- Bypass Protection & Target GUI Setup
local TargetUI = CoreGui
pcall(function()
    if gethui then
        TargetUI = gethui()
    end
end)

-- Modules & Config
local System = {
    Connections = {},
    Drawings = {},
    Instances = {},
    CurrentFPS = 0
}

local ColorMap = {
    {Name = "Ungu Elektrik", Color = Color3.fromRGB(160, 30, 255)},
    {Name = "Merah Darah", Color = Color3.fromRGB(255, 30, 30)},
    {Name = "Biru Cyan", Color = Color3.fromRGB(30, 230, 255)},
    {Name = "Hijau Racun", Color = Color3.fromRGB(50, 255, 80)},
    {Name = "Putih Murni", Color = Color3.fromRGB(255, 255, 255)},
    {Name = "Api Jingga", Color = Color3.fromRGB(255, 140, 0)},
    {Name = "Kuning Matahari", Color = Color3.fromRGB(255, 255, 0)}
}

local DefaultConfig = {
    Aimbot = false,
    TriggerBot = false,
    SpinBot = false,
    SpinSpeed = 50,
    HitboxExpander = false,
    HitboxSize = 5,
    WallCheck = true,
    TeamCheck = false,
    AliveCheck = true,
    TargetPart = "Head",
    MinDistance = 15,
    ESP_Name = false,
    ESP_Box = false,
    ESP_Tracer = false,
    ESP_Health = false,
    ESP_Skeleton = false, -- SKELETON
    ESPColorIdx = 1,
    BoxColorIdx = 1,
    TracerColorIdx = 5,
    SkeletonColorIdx = 5,
    ShowFOV = false,
    FOVSize = 120,
    FOVColorIdx = 1,
    UIKeybind = Enum.KeyCode.RightShift,
    DiscordLink = "https://discord.gg/4fkGEpx847"
}

local Config = table.clone(DefaultConfig)
local ConfigName = "Allvesz_V10_Indo_Config.json"

-- Error Handling Wrapper untuk script yang lebih stabil
local function SafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        warn("[Allvesz V10] Error Terdeteksi & Dibypass:", err)
    end
end

-- Save / Load Config (Tersimpan Lokal)
local function SaveConfig()
    SafeCall(function()
        if writefile then
            writefile(ConfigName, HttpService:JSONEncode(Config))
        end
    end)
end

local function LoadConfig()
    SafeCall(function()
        if readfile and isfile and isfile(ConfigName) then
            local decoded = HttpService:JSONDecode(readfile(ConfigName))
            if decoded then
                for k, v in pairs(decoded) do
                    if Config[k] ~= nil then Config[k] = v end
                end
            end
        end
    end)
end

LoadConfig()

-- Fungsi Bypass: Cleanup GUI Sebelumnya agar tak bentrok
local function UnloadPrevious()
    for _, name in ipairs({"AllveszUI_V10", "AllveszUI_V9", "Allvesz_FPS"}) do
        local old = TargetUI:FindFirstChild(name) or CoreGui:FindFirstChild(name)
        if old then old:Destroy() end
    end
    if _G.AllveszUnload then
        pcall(_G.AllveszUnload)
    end
end
UnloadPrevious()

-- Advanced Anti-Cheat Bypass & Fake Hitbox System
pcall(function()
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        setreadonly(mt, false)
        local oldIndex = mt.__index
        local oldNamecall = mt.__namecall
        
        -- Bypass Lokal Anti-Cheat (Mengecoh Size Checker & Memanipulasi Info FakeHitbox)
        mt.__index = newcclosure(function(t, k)
            if not checkcaller() then
                if k == "Name" and typeof(t) == "Instance" and t.Name == "V10_FakeHitbox" then
                    return "Head" -- Jika senjata / sistem cek nama, anggap saja ini Head asli
                end
                if k == "Size" and typeof(t) == "Instance" and t.Name == "V10_FakeHitbox" then
                    return Vector3.new(1.2, 1, 1.2) -- Jika AC iseng ngecek size
                end
            end
            return oldIndex(t, k)
        end)
        
        -- Bypass Server Hit-Validation & Anti-Kick Ultimate
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if not checkcaller() then
                -- Blokir Client Kick Force
                if method == "Kick" or method == "kick" then
                    return nil
                end
                
                if method == "FireServer" or method == "InvokeServer" then
                    local remoteName = string.lower(tostring(self.Name))
                    
                    -- Blokir Remote Ban/Kick
                    if type(args[1]) == "string" then
                        local arg1 = string.lower(args[1])
                        if string.find(arg1, "kick") or string.find(arg1, "ban") or string.find(arg1, "crash") or string.find(arg1, "cheat") then
                            return nil
                        end
                    end
                    if string.find(remoteName, "kick") or string.find(remoteName, "ban") or string.find(remoteName, "punish") then return nil end

                    -- Silent Aim Mapping untuk Fake Hitbox (Mengubah sasaran ke Head Asli sebelum sampai ke server)
                    if Config.HitboxExpander then
                        local isModified = false
                        for i, arg in pairs(args) do
                            if typeof(arg) == "Instance" and arg.Name == "V10_FakeHitbox" then
                                local realHead = arg.Parent and arg.Parent:FindFirstChild("Head")
                                if realHead then
                                    args[i] = realHead
                                    isModified = true
                                end
                            elseif typeof(arg) == "Vector3" then
                                for _, p in pairs(Players:GetPlayers()) do
                                    if p ~= LocalPlayer and p.Character then
                                        local fh = p.Character:FindFirstChild("V10_FakeHitbox")
                                        if fh and (arg - fh.Position).Magnitude <= (Config.HitboxSize / 2 + 2) then
                                            local head = p.Character:FindFirstChild("Head")
                                            if head then
                                                args[i] = head.Position
                                                isModified = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if isModified then
                            return oldNamecall(self, unpack(args))
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        
        setreadonly(mt, true)
    end
end)

-- Global Unload Manager
_G.AllveszUnload = function()
    for _, conn in pairs(System.Connections) do SafeCall(function() conn:Disconnect() end) end
    for _, draw in pairs(System.Drawings) do SafeCall(function() draw:Remove() end) end
    for _, inst in pairs(System.Instances) do SafeCall(function() inst:Destroy() end) end
    System.Drawings = {}
    System.Connections = {}
    System.Instances = {}
end

local function AddDrawing(Type, Props)
    local obj = Drawing.new(Type)
    for k, v in pairs(Props) do obj[k] = v end
    table.insert(System.Drawings, obj)
    return obj
end

-- FOV Circle
local FOVCircle = AddDrawing("Circle", {
    Thickness = 2,
    Filled = false,
    NumSides = 64,
    Color = ColorMap[Config.FOVColorIdx].Color,
    Radius = Config.FOVSize,
    Visible = false,
    ZIndex = 1
})

-- FPS Counter
local FPSLabel = Instance.new("ScreenGui")
FPSLabel.Name = "Allvesz_FPS"
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(FPSLabel) end
end)
FPSLabel.Parent = TargetUI
table.insert(System.Instances, FPSLabel)

local FPSText = Instance.new("TextLabel", FPSLabel)
FPSText.Size = UDim2.new(0, 100, 0, 30)
FPSText.Position = UDim2.new(0, 5, 0, 5)
FPSText.BackgroundTransparency = 1
FPSText.TextColor3 = Color3.fromRGB(0, 255, 0)
FPSText.TextStrokeTransparency = 0.2
FPSText.Font = Enum.Font.Code
FPSText.TextSize = 18
FPSText.TextXAlignment = Enum.TextXAlignment.Left

-- Skeleton Arrays Info
local BoneLinks_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local BoneLinks_R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

-- Player Cache
local PlayerCache = {}

local function CreatePlayerVisuals(player)
    if PlayerCache[player] then return end
    local cacheObj = {
        Box = AddDrawing("Square", {Thickness = 1.5, Filled = false, ZIndex = 2}),
        Tracer = AddDrawing("Line", {Thickness = 1.5, ZIndex = 1}),
        HPOutline = AddDrawing("Square", {Thickness = 1, Filled = true, Color = Color3.new(0,0,0), ZIndex = 1}),
        HPFill = AddDrawing("Square", {Thickness = 1, Filled = true, ZIndex = 2}),
        Name = AddDrawing("Text", {Center = true, Outline = true, Size = 16, ZIndex = 3, Font = 2}),
        SkeletonLines = {}
    }
    
    -- Cache maksimal 14 garis untuk menampung R15 dan R6
    for i = 1, 14 do
        cacheObj.SkeletonLines[i] = AddDrawing("Line", {Thickness = 1.5, ZIndex = 2})
    end
    
    PlayerCache[player] = cacheObj
end

local function RemovePlayerVisuals(player)
    if PlayerCache[player] then
        for k, draw in pairs(PlayerCache[player]) do
            if k == "SkeletonLines" then
                for _, subDraw in pairs(draw) do pcall(function() subDraw:Remove() end) end
            else
                pcall(function() draw:Remove() end)
            end
        end
        PlayerCache[player] = nil
    end
end

for _, v in pairs(Players:GetPlayers()) do
    if v ~= LocalPlayer then CreatePlayerVisuals(v) end
end

table.insert(System.Connections, Players.PlayerAdded:Connect(function(v)
    if v ~= LocalPlayer then CreatePlayerVisuals(v) end
end))

table.insert(System.Connections, Players.PlayerRemoving:Connect(function(v)
    RemovePlayerVisuals(v)
end))

-- Visuals & Aimbot Logic Core
local function IsVisible(targetPart, origin)
    if not Config.WallCheck then return true end
    local direction = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = Workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetTarget()
    local closest = nil
    local minFOV = Config.FOVSize
    local origin = Camera.CFrame.Position
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for player, cache in pairs(PlayerCache) do
        if Config.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local char = player.Character
        if not char then continue end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChild("Humanoid")
        
        if not (root and head and hum) then continue end
        if Config.AliveCheck and hum.Health <= 0 then continue end
        
        if myRoot then
            local dist3D = (myRoot.Position - root.Position).Magnitude
            if dist3D < Config.MinDistance then continue end
        end
        
        local part = char:FindFirstChild(Config.TargetPart)
        if not part then continue end
        
        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local distFromCenter = (Vector2.new(pos.X, pos.Y) - viewportCenter).Magnitude
            if distFromCenter < minFOV then
                if IsVisible(part, origin) then
                    closest = part
                    minFOV = distFromCenter
                end
            end
        end
    end
    return closest
end

local function UpdateVisuals()
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local viewportY = Camera.ViewportSize.Y

    for player, pDraw in pairs(PlayerCache) do
        local show = false
        local char = player.Character
        
        local function hideDrawings()
            pDraw.Box.Visible = false
            pDraw.Tracer.Visible = false
            pDraw.HPOutline.Visible = false
            pDraw.HPFill.Visible = false
            pDraw.Name.Visible = false
            for i = 1, 14 do
                pDraw.SkeletonLines[i].Visible = false
            end
        end

        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChild("Humanoid")
            
            local isAlive = hum and hum.Health > 0
            if (not Config.AliveCheck or isAlive) and root and head and (not Config.TeamCheck or player.Team ~= LocalPlayer.Team) then
                local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                
                if onScreen or headOnScreen then
                    show = true
                    local height = math.abs(headPos.Y - rootPos.Y)
                    local width = math.clamp(height / 1.5, 2, 1000)
                    local topLeft = Vector2.new(rootPos.X - width / 2, headPos.Y)

                    -- ESP BOX
                    if Config.ESP_Box then
                        pDraw.Box.Size = Vector2.new(width, height)
                        pDraw.Box.Position = topLeft
                        pDraw.Box.Color = ColorMap[Config.BoxColorIdx].Color
                        pDraw.Box.Visible = true
                    else
                        pDraw.Box.Visible = false
                    end

                    -- TRACER
                    if Config.ESP_Tracer then
                        pDraw.Tracer.From = Vector2.new(viewportCenter.X, viewportY)
                        pDraw.Tracer.To = Vector2.new(rootPos.X, rootPos.Y + height/2)
                        pDraw.Tracer.Color = ColorMap[Config.TracerColorIdx].Color
                        pDraw.Tracer.Visible = true
                    else
                        pDraw.Tracer.Visible = false
                    end

                    -- HEALTH BAR
                    if Config.ESP_Health and isAlive then
                        local barWidth = 4
                        local offset = 6
                        local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local barHeight = height * healthPct
                        
                        pDraw.HPOutline.Position = Vector2.new(topLeft.X - offset - barWidth, topLeft.Y)
                        pDraw.HPOutline.Size = Vector2.new(barWidth, height)
                        pDraw.HPOutline.Visible = true
                        
                        pDraw.HPFill.Position = Vector2.new(topLeft.X - offset - barWidth + 1, topLeft.Y + (height - barHeight) + 1)
                        pDraw.HPFill.Size = Vector2.new(barWidth - 2, barHeight - 2)
                        pDraw.HPFill.Color = Color3.fromHSV(healthPct * 0.3, 1, 1)
                        pDraw.HPFill.Visible = true
                    else
                        pDraw.HPOutline.Visible = false
                        pDraw.HPFill.Visible = false
                    end
                    
                    -- NAME ESP
                    if Config.ESP_Name then
                        pDraw.Name.Position = Vector2.new(rootPos.X, headPos.Y - 18)
                        pDraw.Name.Text = player.Name
                        pDraw.Name.Color = ColorMap[Config.ESPColorIdx].Color
                        pDraw.Name.Visible = true
                    else
                        pDraw.Name.Visible = false
                    end
                    
                    -- SKELETON ESP
                    if Config.ESP_Skeleton then
                        local isR15 = char:FindFirstChild("UpperTorso") ~= nil
                        local links = isR15 and BoneLinks_R15 or BoneLinks_R6
                        
                        for i = 1,14 do
                            local line = pDraw.SkeletonLines[i]
                            local link = links[i]
                            if link then
                                local p1 = char:FindFirstChild(link[1])
                                local p2 = char:FindFirstChild(link[2])
                                if p1 and p2 then
                                    local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
                                    local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
                                    if on1 or on2 then
                                        line.From = Vector2.new(pos1.X, pos1.Y)
                                        line.To = Vector2.new(pos2.X, pos2.Y)
                                        line.Color = ColorMap[Config.SkeletonColorIdx].Color
                                        line.Visible = true
                                    else
                                        line.Visible = false
                                    end
                                else
                                    line.Visible = false
                                end
                            else
                                line.Visible = false
                            end
                        end
                    else
                        for i = 1, 14 do
                            pDraw.SkeletonLines[i].Visible = false
                        end
                    end
                end
            end
        end
        if not show then hideDrawings() end
    end
end

-- RenderStepped Core Tick
local lastTime = tick()
local frameCount = 0

table.insert(System.Connections, RunService.RenderStepped:Connect(function()
    SafeCall(function()
        -- FPS Calc
        frameCount = frameCount + 1
        local currentTime = tick()
        if currentTime - lastTime >= 1 then
            System.CurrentFPS = frameCount
            FPSText.Text = "FPS: " .. System.CurrentFPS
            frameCount = 0
            lastTime = currentTime
        end

        local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        -- FOV Update
        if Config.ShowFOV then
            FOVCircle.Position = viewportCenter
            FOVCircle.Radius = Config.FOVSize
            FOVCircle.Color = ColorMap[Config.FOVColorIdx].Color
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end

        -- Aimbot & TriggerBot Target Update
        local LockedTarget = GetTarget()
        if Config.Aimbot and LockedTarget then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, LockedTarget.Position)
        end
        if Config.TriggerBot and LockedTarget then
            pcall(function()
                if mouse1click then mouse1click() else mouse1press() task.wait(0.01) mouse1release() end
            end)
        end
        
        -- SpinBot & Hitbox Expander (FITUR BRUTAL)
        local myChar = LocalPlayer.Character
        if Config.SpinBot and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            myChar.HumanoidRootPart.CFrame = myChar.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0)
        end
        
        -- Fake Hitbox Expander (Mencegah kick dengan part terpisah / Proxy)
        for player, _ in pairs(PlayerCache) do
            local char = player.Character
            if char then
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChild("Humanoid")
                local isValid = head and hum and hum.Health > 0 and not (Config.TeamCheck and player.Team == LocalPlayer.Team)
                
                local fakeHitbox = char:FindFirstChild("V10_FakeHitbox")
                if Config.HitboxExpander and isValid then
                    if not fakeHitbox then
                        fakeHitbox = Instance.new("Part")
                        fakeHitbox.Name = "V10_FakeHitbox"
                        fakeHitbox.Color = ColorMap[Config.ESPColorIdx].Color
                        fakeHitbox.Transparency = 0.6
                        fakeHitbox.Material = Enum.Material.Neon
                        fakeHitbox.Shape = Enum.PartType.Block
                        fakeHitbox.CanCollide = false
                        -- PENTING: CanQuery harus true agar peluru (Raycast) game bisa mengenai kotak ini!
                        pcall(function() fakeHitbox.CanQuery = true end)
                        fakeHitbox.Massless = true
                        fakeHitbox.Anchored = false -- Diganti false, lalu dilas agar hit detection server lebih sinkron
                        fakeHitbox.Parent = char
                        
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = fakeHitbox
                        weld.Part1 = head
                        weld.Parent = fakeHitbox
                    end
                    fakeHitbox.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    fakeHitbox.CFrame = head.CFrame
                else
                    if fakeHitbox then fakeHitbox:Destroy() end
                end
            end
        end

        UpdateVisuals()
    end)
end))

-- ANTI LAG function (FPS Boost)
local function ActivateAntiLag()
    SafeCall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("Terrain") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                if v:IsA("MeshPart") then
                    pcall(function() v.TextureID = "" end)
                end
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
    end)
end

-- =========================================
--             UI CREATION SYSTEM
-- =========================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AllveszUI_V10"
ScreenGui.ResetOnSpawn = false
table.insert(System.Instances, ScreenGui)
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    ScreenGui.Parent = TargetUI
end)

-- ANIMASI AWAL BUKA (BY REVAL)
local SplashFrame = Instance.new("Frame", ScreenGui)
SplashFrame.Size = UDim2.new(1, 0, 1, 0)
SplashFrame.BackgroundColor3 = Color3.fromRGB(10, 5, 5)
SplashFrame.ZIndex = 99999

local SplashText = Instance.new("TextLabel", SplashFrame)
SplashText.Size = UDim2.new(1, 0, 1, 0)
SplashText.BackgroundTransparency = 1
SplashText.Text = "ALLVESZ V10 BRUTAL EDITION\n★ BY REVAL ★"
SplashText.TextColor3 = Color3.fromRGB(255, 30, 30)
SplashText.Font = Enum.Font.GothamBlack
SplashText.TextSize = 1
SplashText.ZIndex = 100000

local SplashGlow = Instance.new("UIStroke", SplashText)
SplashGlow.Color = Color3.fromRGB(200, 0, 0)
SplashGlow.Thickness = 3
SplashGlow.Transparency = 1

local TweenSplash = TweenService:Create(SplashText, TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextSize = 50})
TweenSplash:Play()
TweenService:Create(SplashGlow, TweenInfo.new(1.5), {Transparency = 0}):Play()

task.spawn(function()
    TweenSplash.Completed:Wait()
    task.wait(1.5)
    TweenService:Create(SplashText, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {TextSize = 1}):Play()
    TweenService:Create(SplashGlow, TweenInfo.new(1), {Transparency = 1}):Play()
    local fadeOut = TweenService:Create(SplashFrame, TweenInfo.new(1, Enum.EasingStyle.Linear), {BackgroundTransparency = 1})
    fadeOut:Play()
    fadeOut.Completed:Wait()
    SplashFrame:Destroy()
end)

local ToggleButton = Instance.new("ImageButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -25)
ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleButton.Draggable = true
ToggleButton.Active = true
ToggleButton.Selectable = true
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleButton)
ToggleStroke.Color = Color3.fromRGB(255, 30, 30)
ToggleStroke.Thickness = 2
task.spawn(function()
    pcall(function()
        local uid = Players:GetUserIdFromNameAsync("17gemadin")
        ToggleButton.Image = Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
end)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 8, 8)
MainFrame.BackgroundTransparency = 0.1
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local isMenuOpen = false
local function ToggleMenu()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        MainFrame.Visible = true
        MainFrame.ClipsDescendants = false
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 600, 0, 420)}):Play()
    else
        MainFrame.ClipsDescendants = true
        local tw = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
        tw:Play()
        tw.Completed:Wait()
        if not isMenuOpen then MainFrame.Visible = false end
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleMenu)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(200, 20, 20)
MainStroke.Thickness = 2

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.ZIndex = 50
CloseBtn.MouseButton1Click:Connect(function()
    ToggleMenu()
end)
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50) end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150) end)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 170, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Sidebar)
Title.Text = "V10 BRUTAL ED."
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Font = Enum.Font.Sarpanch
Title.TextColor3 = Color3.fromRGB(255, 30, 30)
Title.TextSize = 20
Title.BackgroundTransparency = 1

local MyProfile = Instance.new("Frame", Sidebar)
MyProfile.Size = UDim2.new(0.9, 0, 0, 50)
MyProfile.Position = UDim2.new(0.05, 0, 1, -60)
MyProfile.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", MyProfile)

local MyImg = Instance.new("ImageLabel", MyProfile)
MyImg.Size = UDim2.new(0, 34, 0, 34)
MyImg.Position = UDim2.new(0, 8, 0.5, -17)
MyImg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
task.spawn(function()
    pcall(function()
        MyImg.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
end)
Instance.new("UICorner", MyImg).CornerRadius = UDim.new(1, 0)

local MyName = Instance.new("TextLabel", MyProfile)
MyName.Text = LocalPlayer.Name
MyName.Position = UDim2.new(0, 50, 0, 0)
MyName.Size = UDim2.new(0, 100, 1, 0)
MyName.BackgroundTransparency = 1
MyName.TextColor3 = Color3.fromRGB(200, 200, 200)
MyName.Font = Enum.Font.GothamBold
MyName.TextSize = 11
MyName.TextXAlignment = Enum.TextXAlignment.Left
MyName.TextTruncate = Enum.TextTruncate.AtEnd

local TabContainer = Instance.new("Frame", Sidebar)
TabContainer.Size = UDim2.new(1, 0, 1, -120)
TabContainer.Position = UDim2.new(0, 0, 0, 60)
TabContainer.BackgroundTransparency = 1

local TabList = Instance.new("UIListLayout", TabContainer)
TabList.Padding = UDim.new(0, 5)
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.SortOrder = Enum.SortOrder.LayoutOrder

local Pages = Instance.new("Frame", MainFrame)
Pages.Size = UDim2.new(1, -180, 1, -20)
Pages.Position = UDim2.new(0, 180, 0, 10)
Pages.BackgroundTransparency = 1

local function CreateTab(Name)
    local TabBtn = Instance.new("TextButton", TabContainer)
    TabBtn.Size = UDim2.new(0.9, 0, 0, 35)
    TabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TabBtn.Text = Name
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = 13
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

    local Page = Instance.new("ScrollingFrame", Pages)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 2
    Page.BorderSizePixel = 0
    
    local PList = Instance.new("UIListLayout", Page)
    PList.Padding = UDim.new(0, 8)
    PList.SortOrder = Enum.SortOrder.LayoutOrder

    PList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, PList.AbsoluteContentSize.Y + 20)
    end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, v in ipairs(Pages:GetChildren()) do
            v.Visible = (v == Page)
        end
        for _, v in ipairs(TabContainer:GetChildren()) do
            if v:IsA("TextButton") then
                v.BackgroundColor3 = (v == TabBtn) and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(25, 25, 25)
                v.TextColor3 = (v == TabBtn) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
            end
        end
    end)
    return Page
end

-- Keybind Toggle implementation
table.insert(System.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Config.UIKeybind then
        ToggleMenu()
    end
end))

-- UI Components Module
local function AddToggle(Parent, Text, ConfigKey, Callback)
    local Frame = Instance.new("TextButton", Parent)
    Frame.Size = UDim2.new(1, -10, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.Text = ""
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.Text = Text
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextSize = 13
    
    local Checkbox = Instance.new("Frame", Frame)
    Checkbox.Size = UDim2.new(0, 20, 0, 20)
    Checkbox.Position = UDim2.new(1, -30, 0.5, -10)
    Checkbox.BackgroundColor3 = Config[ConfigKey] and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(40, 40, 40)
    Instance.new("UICorner", Checkbox).CornerRadius = UDim.new(0, 4)
    
    local debounce = false
    Frame.MouseButton1Click:Connect(function()
        if debounce then return end debounce = true
        Config[ConfigKey] = not Config[ConfigKey]
        TweenService:Create(Checkbox, TweenInfo.new(0.2), {
            BackgroundColor3 = Config[ConfigKey] and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(40, 40, 40)
        }):Play()
        SaveConfig()
        if Callback then Callback(Config[ConfigKey]) end
        task.wait(0.1)
        debounce = false
    end)
end

local function AddInput(Parent, Text, ConfigKey, Callback)
    local Frame = Instance.new("Frame", Parent)
    Frame.Size = UDim2.new(1, -10, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.Text = Text
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextSize = 13
    
    local Box = Instance.new("TextBox", Frame)
    Box.Size = UDim2.new(0, 60, 0, 24)
    Box.Position = UDim2.new(1, -70, 0.5, -12)
    Box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Box.TextColor3 = Color3.fromRGB(255, 30, 30)
    Box.Font = Enum.Font.GothamBold
    Box.Text = tostring(Config[ConfigKey])
    Box.TextSize = 13
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    
    Box.FocusLost:Connect(function()
        local n = tonumber(Box.Text)
        if n then
            Config[ConfigKey] = n
            SaveConfig()
            if Callback then Callback(n) end
        else
            Box.Text = tostring(Config[ConfigKey])
        end
    end)
end

local function AddColorPicker(Parent, Text, ConfigKey, Callback)
    local Btn = Instance.new("TextButton", Parent)
    Btn.Size = UDim2.new(1, -10, 0, 40)
    Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Btn.Text = ""
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", Btn)
    Label.Text = Text
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextSize = 13
    
    local Preview = Instance.new("Frame", Btn)
    Preview.Size = UDim2.new(0, 100, 0, 24)
    Preview.Position = UDim2.new(1, -110, 0.5, -12)
    Preview.BackgroundColor3 = ColorMap[Config[ConfigKey]].Color
    Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 4)
    
    local NameLbl = Instance.new("TextLabel", Preview)
    NameLbl.Size = UDim2.new(1, 0, 1, 0)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Text = ColorMap[Config[ConfigKey]].Name
    NameLbl.Font = Enum.Font.GothamBold
    NameLbl.TextSize = 10
    NameLbl.TextColor3 = Color3.new(0, 0, 0)
    
    local debounce = false
    Btn.MouseButton1Click:Connect(function()
        if debounce then return end debounce = true
        Config[ConfigKey] = Config[ConfigKey] + 1
        if Config[ConfigKey] > #ColorMap then
            Config[ConfigKey] = 1
        end
        local info = ColorMap[Config[ConfigKey]]
        Preview.BackgroundColor3 = info.Color
        NameLbl.Text = info.Name
        SaveConfig()
        if Callback then Callback(info.Color) end
        task.wait(0.1)
        debounce = false
    end)
end

local function AddButton(Parent, Text, Color, Callback)
    local Btn = Instance.new("TextButton", Parent)
    Btn.Size = UDim2.new(1, -10, 0, 40)
    Btn.BackgroundColor3 = Color
    Btn.Text = Text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBlack
    Btn.TextSize = 13
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    local debounce = false
    Btn.MouseButton1Click:Connect(function()
        if debounce then return end debounce = true
        Callback()
        task.wait(0.2)
        debounce = false
    end)
end

local function AddLabel(Parent, Text)
    local Lbl = Instance.new("TextLabel", Parent)
    Lbl.Size = UDim2.new(1, -10, 0, 25)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = Text
    Lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 12
    Lbl.TextWrapped = true
end

-- Setup Tabs Content
local TabCombat = CreateTab("PERTARUNGAN")
local TabVisual = CreateTab("VISUAL")
local TabMisc = CreateTab("LAINNYA")
local TabCredits = CreateTab("KREDIT")

-- Combat Tab (Pertarungan)
AddToggle(TabCombat, "[BRUTAL] Aktifkan Aimbot", "Aimbot")
AddToggle(TabCombat, "[BRUTAL] Autoclicker / TriggerBot", "TriggerBot")
AddToggle(TabCombat, "[BRUTAL] SpinBot 360", "SpinBot")
AddInput(TabCombat, "Kecepatan SpinBot", "SpinSpeed")
AddToggle(TabCombat, "[BRUTAL] Perbesar Kepala (Hitbox)", "HitboxExpander")
AddInput(TabCombat, "Ukuran Kepala Hitbox", "HitboxSize")
AddToggle(TabCombat, "Cek Dinding (Wall Check)", "WallCheck")
AddToggle(TabCombat, "Cek Tim Terpisah", "TeamCheck")
AddToggle(TabCombat, "Verifikasi Hidup (Alive)", "AliveCheck")
AddInput(TabCombat, "Jarak Minimum (Aimbot)", "MinDistance")
AddLabel(TabCombat, " * Akan mengabaikan musuh dalam radius ini (Anti deteksi instan)")
AddInput(TabCombat, "Ukuran Lingkaran FOV", "FOVSize")

-- Visual Tab
AddLabel(TabVisual, "--- ESP NAMA & DARAH ---")
AddToggle(TabVisual, "Tampilkan Nama ESP", "ESP_Name")
AddColorPicker(TabVisual, "Warna Nama", "ESPColorIdx")
AddToggle(TabVisual, "Tampilkan Bar Darah (Health)", "ESP_Health")

AddLabel(TabVisual, "--- ESP BENTUK (VISUAL) ---")
AddToggle(TabVisual, "Kotak 2D (Box)", "ESP_Box")
AddColorPicker(TabVisual, "Warna Kotak (Box)", "BoxColorIdx")

AddToggle(TabVisual, "Garis Arah (Tracers)", "ESP_Tracer")
AddColorPicker(TabVisual, "Warna Garis Target", "TracerColorIdx")

AddToggle(TabVisual, "Tampilkan Tulang (Skeleton)", "ESP_Skeleton")
AddColorPicker(TabVisual, "Warna Tulang", "SkeletonColorIdx")

AddLabel(TabVisual, "--- LAINNYA ---")
AddToggle(TabVisual, "Tampilkan Cincin FOV", "ShowFOV")
AddColorPicker(TabVisual, "Warna Cincin FOV", "FOVColorIdx")

-- Misc Tab (Lainnya)
AddLabel(TabMisc, "Atkifkan/Matikan Menu: Tombol Shift Kanan (RightShift)")
AddButton(TabMisc, "HAPUS LAG (FPS BOOST MAX)", Color3.fromRGB(180, 0, 0), ActivateAntiLag)
AddButton(TabMisc, "TUTUP & UNLOAD SCRIPT", Color3.fromRGB(200, 50, 50), function()
    UnloadPrevious()
end)

-- Credits Tab
local CreditCard = Instance.new("Frame", TabCredits)
CreditCard.Size = UDim2.new(1, -10, 0, 160)
CreditCard.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", CreditCard).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", CreditCard).Color = Color3.fromRGB(255, 30, 30)
Instance.new("UIStroke", CreditCard).Thickness = 1

local Banner = Instance.new("Frame", CreditCard)
Banner.Size = UDim2.new(1, 0, 0, 60)
Banner.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
Instance.new("UICorner", Banner).CornerRadius = UDim.new(0, 8)

local Cover = Instance.new("Frame", Banner)
Cover.Size = UDim2.new(1, 0, 0, 10)
Cover.Position = UDim2.new(0, 0, 1, -10)
Cover.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
Cover.BorderSizePixel = 0

local DevImg = Instance.new("ImageLabel", CreditCard)
DevImg.Size = UDim2.new(0, 80, 0, 80)
DevImg.Position = UDim2.new(0, 20, 0, 20)
DevImg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", DevImg).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", DevImg).Color = Color3.fromRGB(25, 25, 25)
Instance.new("UIStroke", DevImg).Thickness = 4
task.spawn(function()
    pcall(function()
        local uid = Players:GetUserIdFromNameAsync("17gemadin")
        DevImg.Image = Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
end)

local DevName = Instance.new("TextLabel", CreditCard)
DevName.Text = "Reval"
DevName.Position = UDim2.new(0, 110, 0, 65)
DevName.Size = UDim2.new(0, 200, 0, 25)
DevName.Font = Enum.Font.GothamBlack
DevName.TextSize = 22
DevName.TextColor3 = Color3.fromRGB(255, 255, 255)
DevName.TextXAlignment = Enum.TextXAlignment.Left
DevName.BackgroundTransparency = 1

local Role = Instance.new("TextLabel", CreditCard)
Role.Text = "Pemilik / Developer"
Role.Position = UDim2.new(0, 110, 0, 90)
Role.Size = UDim2.new(0, 200, 0, 20)
Role.Font = Enum.Font.Gotham
Role.TextSize = 14
Role.TextColor3 = Color3.fromRGB(150, 150, 150)
Role.TextXAlignment = Enum.TextXAlignment.Left
Role.BackgroundTransparency = 1

local CopyDisc = Instance.new("TextButton", CreditCard)
CopyDisc.Text = "Salin Discord"
CopyDisc.Size = UDim2.new(0, 120, 0, 30)
CopyDisc.Position = UDim2.new(1, -135, 1, -40)
CopyDisc.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
CopyDisc.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyDisc.Font = Enum.Font.GothamBold
Instance.new("UICorner", CopyDisc)
local cDebounce = false
CopyDisc.MouseButton1Click:Connect(function()
    if cDebounce then return end cDebounce = true
    pcall(function() setclipboard(Config.DiscordLink) end)
    CopyDisc.Text = "Tersalin!"
    task.wait(2)
    CopyDisc.Text = "Salin Discord"
    cDebounce = false
end)

-- Initialize Default Tab View
for _, btn in pairs(TabContainer:GetChildren()) do
    if btn:IsA("TextButton") and btn.Text == "PERTARUNGAN" then
        btn.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        break
    end
end
TabCombat.Visible = true

if game:GetService("StarterGui") then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = V10_VERSION,
            Text = "Script berhasil diperbarui & dibypass via GUI",
            Duration = 5
        })
    end)
end
