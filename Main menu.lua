local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local API_URL = "https://aetherial-hub.netlify.app/api/verify"
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==========================================
-- CONNECTION CLEANUP (prevents memory leaks & respawn errors)
-- ==========================================
local Connections = {}
local function AddConnection(conn)
    if typeof(conn) == "RBXScriptConnection" then
        table.insert(Connections, conn)
    end
    return conn
end

-- ==========================================
-- AUTHENTICATION SCREEN (Fixed infinite yield)
-- ==========================================
local function ShowLoadingScreen()
    local authSuccess = false
    local sg = Instance.new("ScreenGui")
    sg.Name = "AetherialAuth"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    
    if gethui then
        sg.Parent = gethui()
    elseif syn and syn.protect_gui then
        pcall(syn.protect_gui, sg)
        sg.Parent = CoreGui
    else
        sg.Parent = CoreGui
    end
    
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    bg.BackgroundTransparency = 0.3
    bg.Parent = sg
    
    local window = Instance.new("Frame")
    window.Name = "Window"
    window.Size = UDim2.new(0, 350, 0, 220)
    window.Position = UDim2.new(0.5, -175, 0.5, -110)
    window.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    window.Parent = bg
    
    Instance.new("UICorner", window).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "Aetherial Hub - Authentication"
    title.TextColor3 = Color3.fromRGB(200, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = window
    
    local input = Instance.new("TextBox")
    input.Name = "KeyInput"
    input.Size = UDim2.new(0, 300, 0, 40)
    input.Position = UDim2.new(0.5, -150, 0.5, -30)
    input.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.Font = Enum.Font.Gotham
    input.TextSize = 14
    input.PlaceholderText = "Enter your key..."
    input.Text = ""
    input.ClearTextOnFocus = false
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
    input.Parent = window
    
    local submit = Instance.new("TextButton")
    submit.Name = "Submit"
    submit.Size = UDim2.new(0, 140, 0, 35)
    submit.Position = UDim2.new(0.5, -70, 0.65, 0)
    submit.BackgroundColor3 = Color3.fromRGB(80, 100, 255)
    submit.TextColor3 = Color3.fromRGB(255, 255, 255)
    submit.Font = Enum.Font.GothamBold
    submit.TextSize = 14
    submit.Text = "Check Key"
    Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 6)
    submit.Parent = window
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.Parent = window
    
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0.85, 0)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.Text = ""
    status.Parent = window
    
    submit.MouseButton1Click:Connect(function()
        local key = input.Text
        if key == "" then 
            status.Text = "Please enter a key" 
            return 
        end
        
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
        status.Text = "Checking key..."
        submit.Active = false
        
        local httpRequest = (request or http_request or (http and http.request))
        if not httpRequest then
            status.Text = "Executor does not support HTTP requests!"
            submit.Active = true
            return
        end
        
        task.spawn(function()
            local success, err = pcall(function()
                local hwid = (typeof(gethwid) == "function" and gethwid()) or (game:GetService("RbxAnalyticsService"):GetClientId()) or "unknown-hwid"
                local res = httpRequest({
                    Url = API_URL .. "?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid),
                    Method = "GET"
                })
                
                if res.StatusCode == 200 then
                    local data = HttpService:JSONDecode(res.Body)
                    if data and data.valid then
                        status.TextColor3 = Color3.fromRGB(100, 255, 100)
                        status.Text = "Authenticated! Loading..."
                        task.wait(1)
                        authSuccess = true
                        sg:Destroy()
                    else
                        status.TextColor3 = Color3.fromRGB(255, 100, 100)
                        status.Text = "Invalid or expired key."
                        submit.Active = true
                    end
                else
                    status.TextColor3 = Color3.fromRGB(255, 100, 100)
                    status.Text = "Server error. Code: " .. tostring(res.StatusCode)
                    submit.Active = true
                end
            end)
            
            if not success then
                status.TextColor3 = Color3.fromRGB(255, 100, 100)
                status.Text = "Request failed: " .. tostring(err):sub(1, 50)
                submit.Active = true
            end
        end)
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        authSuccess = true
        sg:Destroy()
    end)
    
    -- Safely wait without infinite yielding
    local startTime = tick()
    while not authSuccess do
        if tick() - startTime > 120 then -- 2 minute timeout
            sg:Destroy()
            break
        end
        task.wait(0.1)
    end
end

ShowLoadingScreen()

-- ==========================================
-- UI LIBRARY LOADING (with error handling)
-- ==========================================
local Library, ThemeManager, SaveManager
local Options, Toggles

local libSuccess, libErr = pcall(function()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
end)

if not libSuccess or not Library then
    warn("Failed to load Obsidian UI Library: " .. tostring(libErr))
    return -- Cannot continue without UI
end

Options = Library.Options
Toggles = Library.Toggles

Library.ForceCheckbox = false 
Library.ShowToggleFrameInKeybinds = true 

local Window = Library:CreateWindow({
    Title = "Aetherial",
    Footer = "version: beta | discord.gg/aetherial",
    Icon = 95953584838667,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "swords"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Movement = Window:AddTab("Movement", "person-standing"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- ==========================================
-- SHARED TARGETING UTILS
-- ==========================================
local function IsVisible(targetPart)
    if not targetPart then return false end
    local targetChar = targetPart:FindFirstAncestorOfClass("Model")
    local ignoreList = {LocalPlayer.Character, Camera}
    if targetChar then
        table.insert(ignoreList, targetChar)
    end
    local castPoints = {targetPart.Position}
    local parts = Camera:GetPartsObscuringTarget(castPoints, ignoreList)
    return #parts == 0
end

local function GetClosestTarget(targetPartName, fovRadius, teamCheck, visCheck, wallBang, excludeFriends, forceTargetPlayer)
    if forceTargetPlayer and forceTargetPlayer ~= "None" then
        local p = Players:FindFirstChild(forceTargetPlayer)
        if p and p.Character and p.Character:FindFirstChild(targetPartName) and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if visCheck and not wallBang and not IsVisible(p.Character[targetPartName]) then
                return nil
            end
            return p.Character
        end
    end

    local closestPlayer = nil
    local shortestDistance = fovRadius
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(targetPartName) then
            if teamCheck and player.Team == LocalPlayer.Team then continue end
            if excludeFriends and player:IsFriendsWith(LocalPlayer.UserId) then continue end
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health <= 0 then continue end
            
            local targetPart = player.Character[targetPartName]
            local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            
            if onScreen then
                if visCheck and not wallBang and not IsVisible(targetPart) then continue end
                
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < shortestDistance then
                    closestPlayer = player.Character
                    shortestDistance = dist
                end
            end
        end
    end
    return closestPlayer
end

-- ==========================================
-- WEAPON STATS & GUN MODS
-- ==========================================
local WeaponStatsModule = ReplicatedStorage:WaitForChild("WeaponStats", 5)
local WeaponStats = WeaponStatsModule and require(WeaponStatsModule) or {}

local OriginalWeaponStats = {}
if WeaponStats then
    for name, stats in pairs(WeaponStats) do
        if type(stats) == "table" and stats.Behavior then
            OriginalWeaponStats[name] = {}
            for k, v in pairs(stats) do
                OriginalWeaponStats[name][k] = v
            end
        end
    end
end

local function ApplyGunMods()
    if not WeaponStats then return end
    for name, stats in pairs(WeaponStats) do
        if type(stats) == "table" and stats.Behavior then
            local og = OriginalWeaponStats[name]
            if og then
                for k, v in pairs(og) do
                    stats[k] = v
                end
            end
            
            if Toggles.AntiRecoil and Toggles.AntiRecoil.Value then
                stats.IKRecoil = 0
                stats.CamRecoil = 0
                stats.CamRecoilRecovery = 999
                stats.CamRecoilLateralRatio = 0
                stats.CamRecoilSpeed = 0
                stats.CamRecoilDamper = 0
                stats.RecoilForce = 0
                if stats.ADSRecoilForce then stats.ADSRecoilForce = 0 end
                if stats.ADSRecoilRatio then stats.ADSRecoilRatio = 0 end
            end
            if Toggles.ZeroSpread and Toggles.ZeroSpread.Value then
                stats.MinSpread = 0
                stats.MaxSpread = 0
                stats.SpreadStep = 0
                stats.SpreadRecovery = 999
                stats.AimSpreadMulti = 0
            end
            if Toggles.BottomlessClip and Toggles.BottomlessClip.Value then
                stats.AmmoMax = 9999999 
            end
            if Toggles.InstantReload and Toggles.InstantReload.Value then
                stats.ReloadTime = 0
                stats.EquipTime = 0 
                stats.UnequipTime = 0
            end
            if Toggles.FastFireRate and Toggles.FastFireRate.Value then
                stats.FireRate = 0.01 
            end
            if Toggles.FullAutoEveryGun and Toggles.FullAutoEveryGun.Value then
                if stats.Behavior == "StandardSingleProjectileWeapon" then
                    stats.Behavior = "AutomaticProjectileWeapon"
                end
            end
            if Toggles.InstantKill and Toggles.InstantKill.Value then
                if stats.ProjectileParams then
                    stats.ProjectileParams.Damage = 999999
                    stats.ProjectileParams.HeadshotDamage = 999999
                end
            end
            if Toggles.NoBulletDrop and Toggles.NoBulletDrop.Value then
                if stats.ProjectileParams then stats.ProjectileParams.Gravity = 0 end
                stats.BulletDrop = 0
            end
            if Toggles.MaxRange and Toggles.MaxRange.Value then
                stats.Range = 99999
            end
            if Toggles.MaxBulletSpeed and Toggles.MaxBulletSpeed.Value then
                if stats.ProjectileParams then stats.ProjectileParams.Velocity = 999999 end
                stats.BulletSpeed = 999999
            end
            if Toggles.NoSway and Toggles.NoSway.Value then
                stats.SwayAmp = 0
                stats.SwaySpeed = 0
                stats.BobSpeed = 0
                stats.BobAmp = 0
            end
            if Toggles.NoEquipAnim and Toggles.NoEquipAnim.Value then
                stats.EquipAnimation = nil
                stats.UnequipAnimation = nil
            end
        end
    end
end

local GunModsGroup = Tabs.Combat:AddLeftGroupbox("Gun Mods")

local function OnGunModToggle()
    ApplyGunMods()
end

GunModsGroup:AddToggle("AntiRecoil", { Text = "No Recoil", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("ZeroSpread", { Text = "No Spread", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("BottomlessClip", { Text = "Infinite Ammo", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("InstantReload", { Text = "Instant Reload", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("FastFireRate", { Text = "Fast Fire Rate", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("FullAutoEveryGun", { Text = "Full Auto Every Gun", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("InstantKill", { Text = "Instant Kill (One Shot)", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("NoBulletDrop", { Text = "No Bullet Drop", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("MaxRange", { Text = "Max Range", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("MaxBulletSpeed", { Text = "Max Bullet Speed", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("NoSway", { Text = "No Sway / No Bob", Default = false, Callback = OnGunModToggle })
GunModsGroup:AddToggle("NoEquipAnim", { Text = "No Equip Animation", Default = false, Callback = OnGunModToggle })

GunModsGroup:AddButton("Force Apply Mods", function()
    ApplyGunMods()
    Library:Notify({Title = "Gun Mods", Description = "Mods force-applied to all weapons.", Time = 3})
end)

-- Re-apply mods periodically in case new weapons are equipped
AddConnection(RunService.Heartbeat:Connect(function()
    if Toggles.AntiRecoil and Toggles.AntiRecoil.Value then
        ApplyGunMods()
    end
end))

-- ==========================================
-- SILENT AIM
-- ==========================================
local SilentAimGroup = Tabs.Combat:AddRightGroupbox("Silent Aim")

local PlayerList = {"None"}
for _, p in pairs(Players:GetPlayers()) do 
    if p ~= LocalPlayer then table.insert(PlayerList, p.Name) end 
end

SilentAimGroup:AddToggle("SilentAim", { Text = "Enable Silent Aim", Default = false })
SilentAimGroup:AddDropdown("SilentAimTargetPlayer", { Values = PlayerList, Default = 1, Multi = false, Text = "Target Player" })
SilentAimGroup:AddDropdown("SilentAimPart", { Values = { "Head", "HumanoidRootPart" }, Default = 1, Multi = false, Text = "Target Part" })
SilentAimGroup:AddSlider("SilentAimHitChance", { Text = "Hit Chance", Default = 100, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
SilentAimGroup:AddToggle("SilentAimForceBullet", { Text = "Force Bullet (Teleport)", Default = false, Tooltip = "Teleports bullet straight to target." })
SilentAimGroup:AddToggle("SilentAimWallbang", { Text = "Wallbang", Default = false })
SilentAimGroup:AddToggle("SilentAimVisCheck", { Text = "Visibility Check", Default = false })
SilentAimGroup:AddToggle("SilentAimTeamCheck", { Text = "Team Check", Default = false })
SilentAimGroup:AddToggle("SilentAimExcludeFriends", { Text = "Exclude Friends", Default = false })
SilentAimGroup:AddToggle("SilentAimShowFOV", { Text = "Show FOV", Default = false })
SilentAimGroup:AddSlider("SilentAimFOV", { Text = "FOV Radius", Default = 200, Min = 10, Max = 1000, Rounding = 0 })
SilentAimGroup:AddLabel("FOV Color"):AddColorPicker("SilentAimFOVColor", { Default = Color3.fromRGB(255, 0, 0), Title = "FOV Color" })

local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Thickness = 1

-- ==========================================
-- AIMBOT
-- ==========================================
local AimbotGroup = Tabs.Combat:AddRightGroupbox("Aimbot")
AimbotGroup:AddToggle("Aimbot", { Text = "Enable Aimbot", Default = false })
AimbotGroup:AddLabel("Aimbot Key"):AddKeyPicker("AimbotKey", { Default = "MB2", SyncToggleState = false, Mode = "Hold", Text = "Aimbot Key", NoUI = false })
AimbotGroup:AddDropdown("AimbotTargetPlayer", { Values = PlayerList, Default = 1, Multi = false, Text = "Target Player" })
AimbotGroup:AddDropdown("AimbotPart", { Values = { "Head", "HumanoidRootPart" }, Default = 1, Multi = false, Text = "Target Part" })
AimbotGroup:AddToggle("AimbotWallbang", { Text = "Wallbang", Default = false })
AimbotGroup:AddToggle("AimbotVisCheck", { Text = "Visibility Check", Default = false })
AimbotGroup:AddToggle("AimbotTeamCheck", { Text = "Team Check", Default = false })
AimbotGroup:AddToggle("AimbotExcludeFriends", { Text = "Exclude Friends", Default = false })
AimbotGroup:AddSlider("AimbotSmoothness", { Text = "Smoothness", Default = 1, Min = 1, Max = 10, Rounding = 1 })
AimbotGroup:AddToggle("AimbotShowFOV", { Text = "Show FOV", Default = false })
AimbotGroup:AddSlider("AimbotFOV", { Text = "Aimbot FOV", Default = 100, Min = 10, Max = 1000, Rounding = 0 })
AimbotGroup:AddLabel("FOV Color"):AddColorPicker("AimbotFOVColor", { Default = Color3.fromRGB(0, 255, 0), Title = "FOV Color" })

local AimbotFOVCircle = Drawing.new("Circle")
AimbotFOVCircle.Filled = false
AimbotFOVCircle.Thickness = 1

-- ==========================================
-- HITBOX EXPANDER & MISC COMBAT
-- ==========================================
local HitboxGroup = Tabs.Combat:AddLeftGroupbox("Hitbox Expander")
HitboxGroup:AddToggle("HitboxEnabled", { Text = "Enable Hitbox Expander", Default = false })
HitboxGroup:AddDropdown("HitboxPart", { Values = { "Head", "HumanoidRootPart" }, Default = 1, Multi = false, Text = "Target Part" })
HitboxGroup:AddSlider("HitboxSize", { Text = "Size", Default = 2, Min = 1, Max = 50, Rounding = 1 })
HitboxGroup:AddSlider("HitboxTrans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })
HitboxGroup:AddToggle("HitboxExcludeFriends", { Text = "Exclude Friends", Default = false })

local CombatMiscGroup = Tabs.Combat:AddLeftGroupbox("Misc Combat")
CombatMiscGroup:AddToggle("AutoFire", { Text = "Auto Fire", Default = false })
CombatMiscGroup:AddToggle("BulletTrails", { Text = "Bullet Trails", Default = false })
CombatMiscGroup:AddLabel("Trail Color"):AddColorPicker("BulletTrailColor", { Default = Color3.fromRGB(255, 255, 255) })

CombatMiscGroup:AddToggle("HitSound", { Text = "Enable Hit Sound", Default = false })
CombatMiscGroup:AddDropdown("HitSoundType", { Values = {"Rust", "Bells", "Skeet", "Neverlose", "Dog", "RustHeadshot", "Ding"}, Default = 1, Multi = false, Text = "Sound" })

-- Hitsound Logic
local function PlayHitSound()
    local sound = Instance.new("Sound")
    local soundType = Options.HitSoundType and Options.HitSoundType.Value or "Rust"
    if soundType == "Rust" then sound.SoundId = "rbxassetid://160432334"
    elseif soundType == "Bells" then sound.SoundId = "rbxassetid://12066699318"
    elseif soundType == "Skeet" then sound.SoundId = "rbxassetid://5641855627"
    elseif soundType == "Neverlose" then sound.SoundId = "rbxassetid://6534224075"
    elseif soundType == "Dog" then sound.SoundId = "rbxassetid://5902468562"
    elseif soundType == "RustHeadshot" then sound.SoundId = "rbxassetid://138750331387064"
    elseif soundType == "Ding" then sound.SoundId = "rbxassetid://78096406204798" end
    sound.Parent = Workspace
    sound.Volume = 2
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

local EnemyHealths = {}
local OriginalHitboxSizes = {}

local function UpdatePlayerLists()
    local list = {"None"}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    if Options.SilentAimTargetPlayer and typeof(Options.SilentAimTargetPlayer.SetValues) == "function" then 
        Options.SilentAimTargetPlayer:SetValues(list) 
    end
    if Options.AimbotTargetPlayer and typeof(Options.AimbotTargetPlayer.SetValues) == "function" then 
        Options.AimbotTargetPlayer:SetValues(list) 
    end
end

AddConnection(Players.PlayerAdded:Connect(UpdatePlayerLists))
AddConnection(Players.PlayerRemoving:Connect(UpdatePlayerLists))

AddConnection(RunService.RenderStepped:Connect(function()
    local midScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if FOVCircle then
        FOVCircle.Position = midScreen
        if Options.SilentAimFOV then FOVCircle.Radius = Options.SilentAimFOV.Value end
        if Toggles.SilentAim then FOVCircle.Visible = Toggles.SilentAim.Value and Toggles.SilentAimShowFOV.Value end
        if Options.SilentAimFOVColor then FOVCircle.Color = Options.SilentAimFOVColor.Value end
    end

    if AimbotFOVCircle then
        AimbotFOVCircle.Position = midScreen
        if Options.AimbotFOV then AimbotFOVCircle.Radius = Options.AimbotFOV.Value end
        if Toggles.Aimbot then AimbotFOVCircle.Visible = Toggles.Aimbot.Value and Toggles.AimbotShowFOV.Value end
        if Options.AimbotFOVColor then AimbotFOVCircle.Color = Options.AimbotFOVColor.Value end
    end

    -- Camera Aimbot Logic
    if Toggles.Aimbot and Toggles.Aimbot.Value then
        local keyPicker = Options.AimbotKey
        local isHolding = false
        if keyPicker then
            if typeof(keyPicker.GetState) == "function" then
                isHolding = keyPicker:GetState()
            elseif keyPicker.Active ~= nil then
                isHolding = keyPicker.Active
            end
        end
        
        if isHolding then
            local targetPartName = Options.AimbotPart and Options.AimbotPart.Value or "Head"
            local fov = Options.AimbotFOV and Options.AimbotFOV.Value or 100
            local teamCheck = Toggles.AimbotTeamCheck and Toggles.AimbotTeamCheck.Value
            local visCheck = Toggles.AimbotVisCheck and Toggles.AimbotVisCheck.Value
            local wallBang = Toggles.AimbotWallbang and Toggles.AimbotWallbang.Value
            local excludeFriends = Toggles.AimbotExcludeFriends and Toggles.AimbotExcludeFriends.Value
            local forceTargetPlayer = Options.AimbotTargetPlayer and Options.AimbotTargetPlayer.Value
            
            local target = GetClosestTarget(targetPartName, fov, teamCheck, visCheck, wallBang, excludeFriends, forceTargetPlayer)
            if target and target:FindFirstChild(targetPartName) then
                local pos = target[targetPartName].Position
                local smooth = Options.AimbotSmoothness and Options.AimbotSmoothness.Value or 1
                if smooth <= 1.1 then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, pos)
                else
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pos), 1 / smooth)
                end
            end
        end
    end
    
    -- Autofire
    if Toggles.AutoFire and Toggles.AutoFire.Value then
        local targetPartName = Options.SilentAimPart and Options.SilentAimPart.Value or "Head"
        local fov = Options.SilentAimFOV and Options.SilentAimFOV.Value or 200
        local teamCheck = Toggles.SilentAimTeamCheck and Toggles.SilentAimTeamCheck.Value
        local visCheck = true 
        local wallBang = Toggles.SilentAimWallbang and Toggles.SilentAimWallbang.Value
        local excludeFriends = Toggles.SilentAimExcludeFriends and Toggles.SilentAimExcludeFriends.Value
        
        local target = GetClosestTarget(targetPartName, fov, teamCheck, visCheck, wallBang, excludeFriends, "None")
        if target and typeof(mouse1click) == "function" then
            mouse1click()
        end
    end
    
    -- Hitbox Expander (Fixed respawn handling)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Toggles.HitboxExcludeFriends and Toggles.HitboxExcludeFriends.Value and player:IsFriendsWith(LocalPlayer.UserId) then continue end
            
            local partName = Options.HitboxPart and Options.HitboxPart.Value or "Head"
            local part = player.Character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                local charId = player.Character
                if not OriginalHitboxSizes[charId] then OriginalHitboxSizes[charId] = {} end
                if not OriginalHitboxSizes[charId][partName] then
                    OriginalHitboxSizes[charId][partName] = {Size = part.Size, Trans = part.Transparency, Material = part.Material}
                end
                
                if Toggles.HitboxEnabled and Toggles.HitboxEnabled.Value then
                    local size = Options.HitboxSize and Options.HitboxSize.Value or 2
                    part.Size = Vector3.new(size, size, size)
                    part.Transparency = Options.HitboxTrans and Options.HitboxTrans.Value or 0.5
                    part.CanCollide = false
                    part.Material = Enum.Material.Neon
                else
                    local og = OriginalHitboxSizes[charId][partName]
                    if og then
                        part.Size = og.Size
                        part.Transparency = og.Trans
                        part.Material = og.Material
                    end
                end
            end
        end
    end
end))

-- Health monitor for hitsounds (Note: Cannot accurately detect local hits without remote hooks)
AddConnection(RunService.Heartbeat:Connect(function()
    if Toggles.HitSound and Toggles.HitSound.Value then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                local humanoid = player.Character.Humanoid
                local currentHealth = humanoid.Health
                if EnemyHealths[player] and currentHealth < EnemyHealths[player] and currentHealth > 0 then
                    PlayHitSound() 
                end
                EnemyHealths[player] = currentHealth
            end
        end
    end
end))

AddConnection(Players.PlayerRemoving:Connect(function(player) 
    EnemyHealths[player] = nil 
end))

AddConnection(Players.PlayerAdded:Connect(function(player)
    EnemyHealths[player] = nil
end))

-- Cleanup hitbox data on character removal
AddConnection(Players.PlayerRemoving:Connect(function(player)
    if player.Character and OriginalHitboxSizes[player.Character] then
        OriginalHitboxSizes[player.Character] = nil
    end
end))

-- Create Beam for Trails
local function CreateBulletTrail(startPos, endPos)
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Position = startPos
    part.Parent = Workspace
    
    local a0 = Instance.new("Attachment", part)
    local a1 = Instance.new("Attachment", part)
    a1.Position = Vector3.new(0, 0, (endPos - startPos).Magnitude)
    
    local beam = Instance.new("Beam", part)
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.FaceCamera = true
    beam.Color = ColorSequence.new(Options.BulletTrailColor.Value)
    beam.Width0 = 0.1
    beam.Width1 = 0.1
    beam.LightEmission = 1
    beam.LightInfluence = 0
    
    part.CFrame = CFrame.new(startPos, endPos)
    
    game.Debris:AddItem(part, 1)
    
    task.spawn(function()
        for i = 1, 0, -0.05 do
            if beam and beam.Parent then
                beam.Transparency = NumberSequence.new(1 - i)
            end
            task.wait(0.01)
        end
    end)
end

-- Remote Hook for Silent Aim (Fixed argument packing)
local OldNameCall
OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = table.pack(...)
    
    if Toggles.SilentAim and Toggles.SilentAim.Value and method == "FireServer" and tostring(self) == "CastProjectileRequest" then
        if math.random(1, 100) <= (Options.SilentAimHitChance and Options.SilentAimHitChance.Value or 100) then
            local targetPartName = Options.SilentAimPart and Options.SilentAimPart.Value or "Head"
            local fov = Options.SilentAimFOV and Options.SilentAimFOV.Value or 200
            local teamCheck = Toggles.SilentAimTeamCheck and Toggles.SilentAimTeamCheck.Value
            local visCheck = Toggles.SilentAimVisCheck and Toggles.SilentAimVisCheck.Value
            local wallBang = Toggles.SilentAimWallbang and Toggles.SilentAimWallbang.Value
            local excludeFriends = Toggles.SilentAimExcludeFriends and Toggles.SilentAimExcludeFriends.Value
            local forceTargetPlayer = Options.SilentAimTargetPlayer and Options.SilentAimTargetPlayer.Value
            
            local targetCharacter = GetClosestTarget(targetPartName, fov, teamCheck, visCheck, wallBang, excludeFriends, forceTargetPlayer)
            
            if targetCharacter and targetCharacter:FindFirstChild(targetPartName) then
                local targetPos = targetCharacter[targetPartName].Position
                local projData = args[1]
                local forceBullet = Toggles.SilentAimForceBullet and Toggles.SilentAimForceBullet.Value
                
                if type(projData) == "table" then
                    if #projData > 0 then
                        for i, bullet in pairs(projData) do
                            if bullet and type(bullet) == "table" and bullet.StartCF and bullet.Caster then
                                if Toggles.BulletTrails and Toggles.BulletTrails.Value then
                                    CreateBulletTrail(bullet.StartCF.Position, targetPos)
                                end
                                if forceBullet then
                                    bullet.StartCF = CFrame.new(targetPos, targetPos + Camera.CFrame.LookVector)
                                else
                                    bullet.StartCF = CFrame.new(bullet.StartCF.Position, targetPos)
                                end
                            end
                        end
                    elseif projData.StartCF and projData.Caster then
                        if Toggles.BulletTrails and Toggles.BulletTrails.Value then
                            CreateBulletTrail(projData.StartCF.Position, targetPos)
                        end
                        if forceBullet then
                            projData.StartCF = CFrame.new(targetPos, targetPos + Camera.CFrame.LookVector)
                        else
                            projData.StartCF = CFrame.new(projData.StartCF.Position, targetPos)
                        end
                    end
                end
            end
        end
        return OldNameCall(self, table.unpack(args, 1, args.n))
    end
    return OldNameCall(self, table.unpack(args, 1, args.n))
end)

-- ==========================================
-- VISUALS (ESP) LOGIC
-- ==========================================
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("Player ESP")

ESPGroup:AddToggle("ESPEnabled", { Text = "Enable ESP", Default = false })
ESPGroup:AddToggle("ESPBoxes", { Text = "Boxes", Default = false })
ESPGroup:AddToggle("ESPNames", { Text = "Names", Default = false })
ESPGroup:AddToggle("ESPDist", { Text = "Distance", Default = false })
ESPGroup:AddToggle("ESPHealth", { Text = "Health (Bar)", Default = false })
ESPGroup:AddToggle("ESPWeapon", { Text = "Weapon/Tool ESP", Default = false })
ESPGroup:AddToggle("ESPSnaplines", { Text = "Snaplines", Default = false })
ESPGroup:AddToggle("ESPChams", { Text = "Chams (Highlight)", Default = false })
ESPGroup:AddToggle("ESPChamsVisCheck", { Text = "Chams Visibility Check", Default = false })
ESPGroup:AddToggle("ESPTeamCheck", { Text = "Team Check", Default = false })
ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", { Default = Color3.fromRGB(255, 255, 255) })

local ESPObjects = {}
local ChamsHighlights = {}
local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name = "AetherialChams"
ChamsFolder.Parent = CoreGui

local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local esp = {
        BoxOutline = Drawing.new("Square"),
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthOutline = Drawing.new("Line"),
        Health = Drawing.new("Line"),
        Distance = Drawing.new("Text"),
        Weapon = Drawing.new("Text"),
        Snapline = Drawing.new("Line")
    }
    
    esp.BoxOutline.Thickness = 3
    esp.BoxOutline.Filled = false
    esp.BoxOutline.Color = Color3.new(0,0,0)
    
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    esp.Box.Color = Color3.new(1,1,1)
    
    esp.Name.Size = 16
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Color = Color3.new(1,1,1)
    
    esp.Distance.Size = 14
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Color = Color3.new(1,1,1)
    
    esp.Weapon.Size = 13
    esp.Weapon.Center = true
    esp.Weapon.Outline = true
    esp.Weapon.Color = Color3.fromRGB(200, 200, 200)

    esp.Snapline.Thickness = 1
    esp.Snapline.Color = Color3.new(1,1,1)
    
    esp.HealthOutline.Thickness = 3
    esp.HealthOutline.Color = Color3.new(0,0,0)
    
    esp.Health.Thickness = 1
    esp.Health.Color = Color3.new(0,1,0)
    
    ESPObjects[player] = esp

    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.1
    highlight.Parent = ChamsFolder
    ChamsHighlights[player] = highlight
end

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, drawing in pairs(ESPObjects[player]) do
            if drawing and typeof(drawing.Remove) == "function" then
                drawing:Remove()
            end
        end
        ESPObjects[player] = nil
    end
    if ChamsHighlights[player] then
        ChamsHighlights[player]:Destroy()
        ChamsHighlights[player] = nil
    end
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

AddConnection(Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then CreateESP(player) end
end))

AddConnection(Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end))

AddConnection(RunService.RenderStepped:Connect(function()
    for player, esp in pairs(ESPObjects) do
        local success, err = pcall(function()
            local isEnabled = Toggles.ESPEnabled and Toggles.ESPEnabled.Value
            local char = player.Character
            local humanoid = char and char:FindFirstChild("Humanoid")
            local isAlive = char and char:FindFirstChild("HumanoidRootPart") and humanoid and humanoid.Health > 0
            local passTeam = not (Toggles.ESPTeamCheck and Toggles.ESPTeamCheck.Value and player.Team == LocalPlayer.Team)
            
            local highlight = ChamsHighlights[player]

            if isEnabled and isAlive and passTeam then
                local hrp = char.HumanoidRootPart
                local head = char:FindFirstChild("Head") or hrp
                
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                
                local color = Options.ESPColor and Options.ESPColor.Value or Color3.new(1,1,1)

                -- Chams
                if highlight then
                    if Toggles.ESPChams and Toggles.ESPChams.Value then
                        highlight.Adornee = char
                        highlight.FillColor = color
                        highlight.OutlineColor = color
                        highlight.DepthMode = (Toggles.ESPChamsVisCheck and Toggles.ESPChamsVisCheck.Value) and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Enabled = true
                    else
                        highlight.Enabled = false
                        highlight.Adornee = nil
                    end
                end

                if onScreen then
                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height * 0.6
                    
                    if Toggles.ESPBoxes and Toggles.ESPBoxes.Value then
                        esp.BoxOutline.Size = Vector2.new(width, height)
                        esp.BoxOutline.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
                        esp.BoxOutline.Visible = true
                        
                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
                        esp.Box.Color = color
                        esp.Box.Visible = true
                    else
                        esp.BoxOutline.Visible = false
                        esp.Box.Visible = false
                    end
                    
                    if Toggles.ESPNames and Toggles.ESPNames.Value then
                        esp.Name.Text = player.Name
                        esp.Name.Position = Vector2.new(pos.X, pos.Y - height / 2 - 18)
                        esp.Name.Color = color
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    if Toggles.ESPDist and Toggles.ESPDist.Value then
                        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                        esp.Distance.Text = string.format("[%d m]", math.floor(dist))
                        esp.Distance.Position = Vector2.new(pos.X, pos.Y + height / 2 + 2)
                        esp.Distance.Color = color
                        esp.Distance.Visible = true
                    else
                        esp.Distance.Visible = false
                    end

                    if Toggles.ESPWeapon and Toggles.ESPWeapon.Value then
                        local tool = char:FindFirstChildOfClass("Tool")
                        esp.Weapon.Text = tool and tool.Name or "None"
                        local yAdd = Toggles.ESPDist and Toggles.ESPDist.Value and 16 or 0
                        esp.Weapon.Position = Vector2.new(pos.X, pos.Y + height / 2 + 2 + yAdd)
                        esp.Weapon.Visible = true
                    else
                        esp.Weapon.Visible = false
                    end

                    if Toggles.ESPSnaplines and Toggles.ESPSnaplines.Value then
                        esp.Snapline.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.Snapline.To = Vector2.new(pos.X, pos.Y + height / 2)
                        esp.Snapline.Color = color
                        esp.Snapline.Visible = true
                    else
                        esp.Snapline.Visible = false
                    end
                    
                    if Toggles.ESPHealth and Toggles.ESPHealth.Value then
                        local health = humanoid.Health
                        local maxHealth = humanoid.MaxHealth
                        if maxHealth == 0 then maxHealth = 100 end
                        local factor = math.clamp(health / maxHealth, 0, 1)
                        
                        local barHeight = height
                        local bottomY = pos.Y + height / 2
                        local leftX = pos.X - width / 2 - 5
                        
                        esp.HealthOutline.From = Vector2.new(leftX, bottomY + 1)
                        esp.HealthOutline.To = Vector2.new(leftX, bottomY - barHeight - 1)
                        esp.HealthOutline.Visible = true
                        
                        esp.Health.From = Vector2.new(leftX, bottomY)
                        esp.Health.To = Vector2.new(leftX, bottomY - (barHeight * factor))
                        esp.Health.Color = Color3.fromHSV(factor * 0.3, 1, 1)
                        esp.Health.Visible = true
                    else
                        esp.HealthOutline.Visible = false
                        esp.Health.Visible = false
                    end
                else
                    for k, drawing in pairs(esp) do 
                        if typeof(drawing.Visible) ~= "nil" then drawing.Visible = false end 
                    end
                end
            else
                for k, drawing in pairs(esp) do 
                    if typeof(drawing.Visible) ~= "nil" then drawing.Visible = false end 
                end
                if highlight then 
                    highlight.Enabled = false 
                    highlight.Adornee = nil
                end
            end
        end)
        
        if not success then
            -- Silently handle ESP errors for individual players
        end
    end
end))

-- ==========================================
-- MOVEMENT / PLAYER LOGIC
-- ==========================================
local PlayerModGroup = Tabs.Movement:AddLeftGroupbox("Player Modifications")

PlayerModGroup:AddToggle("InfiniteSprint", { Text = "Infinite Sprint / Stamina", Default = false })
PlayerModGroup:AddToggle("CharacterForcefield", { Text = "Fake Forcefield", Default = false })
PlayerModGroup:AddToggle("Speedhack", { Text = "Speedhack", Default = false })
PlayerModGroup:AddSlider("SpeedhackWalkSpeed", { Text = "WalkSpeed", Default = 50, Min = 16, Max = 300, Rounding = 0 })

local FakeForceField = nil

AddConnection(RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    if Toggles.InfiniteSprint and Toggles.InfiniteSprint.Value then
        local st = char:FindFirstChild("Stamina") or LocalPlayer:FindFirstChild("Stamina")
        if st and st:IsA("NumberValue") then st.Value = 100 end
        -- Also check attributes
        if char:GetAttribute("Stamina") then
            char:SetAttribute("Stamina", 100)
        end
        if LocalPlayer:GetAttribute("Stamina") then
            LocalPlayer:SetAttribute("Stamina", 100)
        end
    end

    if Toggles.Speedhack and Toggles.Speedhack.Value then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Options.SpeedhackWalkSpeed.Value
        end
    end

    if Toggles.CharacterForcefield and Toggles.CharacterForcefield.Value then
        if not FakeForceField or FakeForceField.Parent == nil then
            FakeForceField = Instance.new("ForceField")
            FakeForceField.Visible = true
        end
        if FakeForceField.Parent ~= char then
            FakeForceField.Parent = char
        end
    else
        if FakeForceField then
            FakeForceField:Destroy()
            FakeForceField = nil
        end
    end
end))

local GhostFlyGroup = Tabs.Movement:AddRightGroupbox("Ghost Fly (Spoofed)")

GhostFlyGroup:AddToggle("GhostFlyEnabled", { Text = "Enable Ghost Fly", Default = false })
    :AddKeyPicker("GhostFlyKeybind", { Default = "F", SyncToggleState = true, Mode = "Toggle", Text = "Ghost Fly Key", NoUI = false })
GhostFlyGroup:AddSlider("GhostFlySpeed", { Text = "Fly Speed", Default = 200, Min = 50, Max = 600, Rounding = 0 })

local Flying = false
local FlyConnection, NoclipConnection
local KeysDown = {W = false, A = false, S = false, D = false, Space = false, LeftControl = false}

local function StopFly()
    Flying = false
    if FlyConnection then FlyConnection:Disconnect() end
    if NoclipConnection then NoclipConnection:Disconnect() end
    FlyConnection = nil
    NoclipConnection = nil
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = false
            hrp.Velocity = Vector3.zero 
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end
end

local function StartFly()
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    
    StopFly()
    Flying = true
    
    humanoid.PlatformStand = true
    hrp.Anchored = true 
    
    NoclipConnection = RunService.Stepped:Connect(function()
        if not Flying then return end
        local char = LocalPlayer.Character
        if not char then StopFly() return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
    
    FlyConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not Flying then return end
        local char = LocalPlayer.Character
        if not char then StopFly() return end
        local currentHrp = char:FindFirstChild("HumanoidRootPart")
        if not currentHrp then StopFly() return end
        
        local moveDir = Vector3.zero
        local camCF = Camera.CFrame
        
        if KeysDown.W then moveDir += camCF.LookVector end
        if KeysDown.S then moveDir -= camCF.LookVector end
        if KeysDown.D then moveDir += camCF.RightVector end
        if KeysDown.A then moveDir -= camCF.RightVector end
        if KeysDown.Space then moveDir += Vector3.new(0, 1, 0) end
        if KeysDown.LeftControl then moveDir += Vector3.new(0, -1, 0) end
        
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
        
        local speed = Options.GhostFlySpeed and Options.GhostFlySpeed.Value or 200
        local newPos = currentHrp.Position + (moveDir * speed * deltaTime)
        currentHrp.CFrame = CFrame.new(newPos, newPos + camCF.LookVector)
        
        currentHrp.Velocity = Vector3.zero
        currentHrp.AssemblyLinearVelocity = Vector3.zero
    end)
end

if Toggles.GhostFlyEnabled then
    Toggles.GhostFlyEnabled:OnChanged(function()
        if Toggles.GhostFlyEnabled.Value then
            StartFly()
        else
            StopFly()
        end
    end)
end

AddConnection(UserInputService.InputBegan:Connect(function(input, isTyping)
    if isTyping then return end
    if input.KeyCode == Enum.KeyCode.W then KeysDown.W = true
    elseif input.KeyCode == Enum.KeyCode.S then KeysDown.S = true
    elseif input.KeyCode == Enum.KeyCode.A then KeysDown.A = true
    elseif input.KeyCode == Enum.KeyCode.D then KeysDown.D = true
    elseif input.KeyCode == Enum.KeyCode.Space then KeysDown.Space = true
    elseif input.KeyCode == Enum.KeyCode.LeftControl then KeysDown.LeftControl = true
    end
end))

AddConnection(UserInputService.InputEnded:Connect(function(input, isTyping)
    if input.KeyCode == Enum.KeyCode.W then KeysDown.W = false
    elseif input.KeyCode == Enum.KeyCode.S then KeysDown.S = false
    elseif input.KeyCode == Enum.KeyCode.A then KeysDown.A = false
    elseif input.KeyCode == Enum.KeyCode.D then KeysDown.D = false
    elseif input.KeyCode == Enum.KeyCode.Space then KeysDown.Space = false
    elseif input.KeyCode == Enum.KeyCode.LeftControl then KeysDown.LeftControl = false
    end
end))

-- ==========================================
-- UI SETTINGS LOGIC
-- ==========================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value) Library.KeybindFrame.Visible = value end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value) Library.ShowCustomCursor = Value end,
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value) Library:SetNotifySide(Value) end,
})
MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        if DPI then Library:SetDPIScale(DPI) end
    end,
})
MenuGroup:AddSlider("UICornerSlider", {
    Text = "Corner Radius",
    Default = Library.CornerRadius,
    Min = 0, Max = 20, Rounding = 0,
    Callback = function(value) Window:SetCornerRadius(value) end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload Menu", function() 
    -- Cleanup all connections
    for _, conn in pairs(Connections) do
        if conn and typeof(conn.Disconnect) == "function" then
            pcall(function() conn:Disconnect() end)
        end
    end
    -- Cleanup ESP
    for player, _ in pairs(ESPObjects) do
        RemoveESP(player)
    end
    if ChamsFolder then ChamsFolder:Destroy() end
    -- Cleanup drawings
    if FOVCircle then FOVCircle:Remove() end
    if AimbotFOVCircle then AimbotFOVCircle:Remove() end
    -- Stop fly
    StopFly()
    Library:Unload() 
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("AetherialHub")
SaveManager:SetFolder("AetherialHub/game")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()
