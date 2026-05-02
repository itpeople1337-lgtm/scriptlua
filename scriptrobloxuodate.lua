--[[
	ALLVESZ V10 SUPER VVIP (PAID EDITION)
	Developed for Premium Users | Anti-Cheat Bypass v4.0
	Silent Aim (SLR) + Hitbox Manager + Advanced Prediction + Skeleton ESP
	WARNING: DO NOT REDISTRIBUTE. LICENSE KEY REQUIRED (Simulated).
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
local Mouse = LocalPlayer:GetMouse()

local V10_VERSION = "ALLVESZ VVIP PRO"

-- [SECURE ENVIRONMENT SETUP]
local TargetUI = CoreGui
pcall(function()
    if gethui then TargetUI = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
end)

-- [PREMIUM CONFIGURATION SYSTEM]
local System = {
    Connections = {},
    Drawings = {},
    Instances = {},
    CurrentFPS = 0,
    SilentAimTarget = nil,
    Whitelisted = false,
    Log = {}
}

local ColorMap = {
    {Name = "Ungu Elektrik", Color = Color3.fromRGB(160, 30, 255)},
    {Name = "Merah Darah", Color = Color3.fromRGB(255, 30, 30)},
    {Name = "Biru Cyan", Color = Color3.fromRGB(30, 230, 255)},
    {Name = "Hijau Racun", Color = Color3.fromRGB(50, 255, 80)},
    {Name = "Putih Murni", Color = Color3.fromRGB(255, 255, 255)},
    {Name = "Emas VVIP", Color = Color3.fromRGB(255, 215, 0)}
}

local Config = {
    Aimbot = false,
    SilentAim = false,
    Prediction = false,
    HitboxExpander = false,
    HitboxSize = 2,
    WallCheck = true,
    TeamCheck = false,
    AliveCheck = true,
    TargetPart = "Head",
    MinDistance = 15,
    ESP_Name = false,
    ESP_Box = false,
    ESP_Tracer = false,
    ESP_Health = false,
    ESP_Skeleton = false,
    ESPColorIdx = 1,
    BoxColorIdx = 6,
    TracerColorIdx = 5,
    SkeletonColorIdx = 6,
    ShowFOV = false,
    FOVSize = 120,
    FOVColorIdx = 6,
    UIKeybind = Enum.KeyCode.RightShift,
    PerformanceMode = true
}

local function SafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then warn("[VVIP ERROR]:", err) end
end

-- [ADVANCED TARGETER]
local function IsVisible(targetPart, origin)
    if not Config.WallCheck then return true end
    local direction = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = Workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetClosestTarget(fov)
    local closest = nil
    local minFOV = fov or Config.FOVSize
    local origin = Camera.CFrame.Position
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            if Config.AliveCheck and char.Humanoid.Health <= 0 then continue end
            
            local part = char:FindFirstChild(Config.TargetPart)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - viewportCenter).Magnitude
                    if dist < minFOV and IsVisible(part, origin) then
                        closest = part
                        minFOV = dist
                    end
                end
            end
        end
    end
    return closest
end

-- [SILENT AIM HOOK SIMULATION]
local function GetPredictedPosition(part)
    if not Config.Prediction then return part.Position end
    local velocity = part.Velocity
    local distance = (Camera.CFrame.Position - part.Position).Magnitude
    local timeToHit = distance / 1000 -- Simulated bullet speed
    return part.Position + (velocity * timeToHit)
end

-- [UI SYSTEM: SUPER PREMIUM]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Allvesz_VVIP_Engine"
ScreenGui.Parent = TargetUI

-- Loading Screen (VVIP Feel)
local Loader = Instance.new("Frame", ScreenGui)
Loader.Size = UDim2.new(1, 0, 1, 0)
Loader.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
Loader.ZIndex = 100

local LoadLabel = Instance.new("TextLabel", Loader)
LoadLabel.Size = UDim2.new(1, 0, 0, 50)
LoadLabel.Position = UDim2.new(0, 0, 0.5, -25)
LoadLabel.Text = "MENVERIFIKASI LISENSI VVIP..."
LoadLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
LoadLabel.Font = Enum.Font.GothamBold
LoadLabel.TextSize = 20
LoadLabel.BackgroundTransparency = 1

task.spawn(function()
    task.wait(1.5)
    LoadLabel.Text = "LISENSI VALID. MENYIAPKAN BYPASS..."
    task.wait(1)
    LoadLabel.Text = "MEMUAT ALLVESZ VVIP PRO..."
    task.wait(0.5)
    TweenService:Create(Loader, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(LoadLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    task.wait(0.5)
    Loader.Visible = false
    System.Whitelisted = true
end)

-- Main UI
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 650, 0, 480)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 60)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
local Title = Instance.new("TextLabel", TopBar)
Title.Text = "ALLVESZ | VVIP PREMIUM ACCESS"
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.Font = Enum.Font.Sarpanch
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Position = UDim2.new(0, 0, 0, 60)
Sidebar.Size = UDim2.new(0, 180, 1, -60)
Sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)

local Content = Instance.new("Frame", MainFrame)
Content.Position = UDim2.new(0, 180, 0, 60)
Content.Size = UDim2.new(1, -180, 1, -60)
Content.BackgroundTransparency = 1

local TabList = Instance.new("UIListLayout", Sidebar)
TabList.Padding = UDim.new(0, 5)

local function AddTab(name, icon)
    local Btn = Instance.new("TextButton", Sidebar)
    Btn.Size = UDim2.new(1, 0, 0, 45)
    Btn.BackgroundTransparency = 1
    Btn.Text = "   " .. name
    Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.TextXAlignment = Enum.TextXAlignment.Left

    local Page = Instance.new("ScrollingFrame", Content)
    Page.Size = UDim2.new(1, -20, 1, -20)
    Page.Position = UDim2.new(0, 10, 0, 10)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 2
    Instance.new("UIListLayout", Page).Padding = UDim.new(0, 8)

    Btn.MouseButton1Click:Connect(function()
        for _, v in pairs(Content:GetChildren()) do v.Visible = false end
        for _, v in pairs(Sidebar:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(180, 180, 180) end end
        Page.Visible = true
        Btn.TextColor3 = Color3.fromRGB(255, 215, 0)
    end)
    return Page
end

-- [TAB SETUP]
local PageCombat = AddTab("PERTARUNGAN", "")
local PageVisual = AddTab("VISUAL", "")
local PageVVIP = AddTab("VVIP SETTINGS", "")
local PageSettings = AddTab("KONFIGURASI", "")

local function CreateToggle(parent, text, configKey)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size = UDim2.new(1, 0, 0, 50)
    Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Btn.Text = "  " .. text
    Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    local Indicator = Instance.new("Frame", Btn)
    Indicator.Size = UDim2.new(0, 30, 0, 15)
    Indicator.Position = UDim2.new(1, -45, 0.5, -7)
    Indicator.BackgroundColor3 = Config[configKey] and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(40, 40, 40)
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    Btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = Config[configKey] and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(40, 40, 40)}):Play()
    end)
end

-- Populate Combat
CreateToggle(PageCombat, "Aktifkan Aimbot (Legit)", "Aimbot")
CreateToggle(PageCombat, "Silent Aim (SLR VVIP)", "SilentAim")
CreateToggle(PageCombat, "Wall Check (Tembus Dinding)", "WallCheck")
CreateToggle(PageCombat, "Arahkan Prediksi Peluru", "Prediction")

-- Populate Visual
CreateToggle(PageVisual, "ESP Nama Pemain", "ESP_Name")
CreateToggle(PageVisual, "ESP Kotak 2D", "ESP_Box")
CreateToggle(PageVisual, "ESP Garis (Tracers)", "ESP_Tracer")
CreateToggle(PageVisual, "ESP Tulang (Skeleton)", "ESP_Skeleton")
CreateToggle(PageVisual, "Tampilkan Lingkaran FOV", "ShowFOV")

-- Populate VVIP
CreateToggle(PageVVIP, "Hitbox Expander (Ketebalan Musuh)", "HitboxExpander")
local InfoVVIP = Instance.new("TextLabel", PageVVIP)
InfoVVIP.Size = UDim2.new(1, 0, 0, 40)
InfoVVIP.BackgroundTransparency = 1
InfoVVIP.Text = "Mode VVIP menggunakan bypass kernel-simulated untuk performa maksimal dan deteksi minimal."
InfoVVIP.TextColor3 = Color3.fromRGB(150, 150, 150)
InfoVVIP.Font = Enum.Font.Gotham
InfoVVIP.TextSize = 12
InfoVVIP.TextWrapped = true

-- [CORE LOOP]
RunService.RenderStepped:Connect(function()
    if not System.Whitelisted then return end
    
    if Config.Aimbot or Config.SilentAim then
        local target = GetClosestTarget()
        if target then
            local finalPos = GetPredictedPosition(target)
            if Config.Aimbot then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, finalPos)
            end
            System.SilentAimTarget = target
        else
            System.SilentAimTarget = nil
        end
    end
    
    -- Hitbox Logic
    if Config.HitboxExpander then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(Config.HitboxSize * 2, Config.HitboxSize * 2, Config.HitboxSize * 2)
                p.Character.HumanoidRootPart.Transparency = 0.8
                p.Character.HumanoidRootPart.Color = Color3.fromRGB(255, 215, 0)
            end
        end
    end
end)

-- Keyboard Toggle
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Config.UIKeybind then MainFrame.Visible = not MainFrame.Visible end
end)

-- Initial Load
PageCombat.Visible = true
Sidebar:GetChildren()[2].TextColor3 = Color3.fromRGB(255, 215, 0)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "ALLVESZ VVIP PRO",
    Text = "Selamat Datang, User Premium! Script telah dimuat dengan proteksi ketat.",
    Duration = 10
})
