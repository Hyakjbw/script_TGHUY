-- Modern Utility Menu Script 4.5 (Final Fix Model ESP & Smart Lighting)
-- Updated by AI Assistant based on Request
-- Script optimized for Mobile Executors

-- ########################################################
-- [ANTI-CHEAT BYPASS SYSTEM]
-- Dựa trên dữ liệu scan, chặn RemoteEvent "OnPunishment"
-- ########################################################
local function secure_bypass()
    local success, err = pcall(function()
        local mt = getrawmetatable(game)
        local old_namecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            -- Kiểm tra nếu game đang cố gửi tín hiệu trừng phạt lên server
            if method == "FireServer" and self.Name == "OnPunishment" and self.Parent and self.Parent.Name == "FJsMovementAnticheat" then
                -- Chặn cuộc gọi này (Return nil)
                return nil
            end

            return old_namecall(self, ...)
        end)
        setreadonly(mt, true)
        print("✅ Anti-Cheat (FJsMovementAnticheat) Bypassed Successfully!")
    end)
    
    if not success then
        warn("⚠️ Bypass Warning: Executor might not support hookmetamethod. Anti-cheat might be active.")
    end
end
secure_bypass()
-- ########################################################

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui") 

-- Global states
local menuVisible = true
local currentTab = "ESP"

-- ESP players
local highlightEnabled = false
local highlightColor = Color3.fromRGB(0, 255, 128)
local teamFilterEnabled = false
-- === BIẾN CHO ESP NÂNG CAO ===
local espNameEnabled = false
local espHealthEnabled = false
local espDistanceEnabled = false
local espTextConnection = nil
local playerTextTags = {} 
-----------------------------------

-- Combat
local hitboxEnabled = false
local hitboxSize = 10
local headHitboxEnabled = false
local headHitboxSize = 5
local fovEnabled = false
local fovSize = 40
local aimSmooth = 0.50
local stickyTarget = nil
local fovCircle = nil
local hue = 0
local aimMaxDistance = math.huge

-- Misc
local miscInfiniteJump = false
local miscNoclip = false
local miscSpeedEnabled = false
local miscSpeedValue = 30
local originalWalkSpeed = 16

-- Fly Variables
local miscFlyEnabled = false
local miscFlySpeed = 60
local flyConn = nil
local flyControlConnection = nil 
local flyControl = {f = 0, b = 0, l = 0, r = 0, u = 0, d = 0} 
local flySpeedV3 = 50 

-- Player Interaction Variables
local currentTargetPlayer = nil
local isFollowingPlayer = false
local followSpeed = 30
local followConnection = nil 

-- Bring All Variables
local miscBringAllEnabled = false
local bringAllConnection = nil

-- Lighting Variables (Smart Restore)
local miscFullBrightEnabled = false 
local fullBrightConnection = nil 
local miscFogEnabled = false
local originalLightingState = {
    Brightness = 1,
    ClockTime = 14,
    FogEnd = 10000,
    FogStart = 0,
    Ambient = Color3.fromRGB(127, 127, 127),
    OutdoorAmbient = Color3.fromRGB(127, 127, 127),
    GlobalShadows = true
}

-- Function Tab Variables
local godModeEnabled = false
local invisibleEnabled = false
local spinBotEnabled = false
local spinBotSpeed = 20
local instantPromptEnabled = false 
local godModeConnection = nil
local invisibleConnection = nil
local spinBotConnection = nil
local instantPromptConnection = nil

-- === MODEL ESP VARIABLES (RE-FIXED) ===
local espModelEnabled = false
local modelHighlightList = {} -- Danh sách tên model cần tìm
local cachedModels = {} -- Cache danh sách model instance
local ESPTextEnabled = false -- ESP Text cho Model
local modelHitboxEnabled = false
local modelHitboxSize = 6
local showingModelList = false
local modelNotifyEnabled = false 
local modelNotifyDistance = 100 
local lastNotifyTime = 0 
local modelESPConnection = nil 

-- Helper functions
local function getHumanoid(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHead(c) return c and (c:FindFirstChild("Head") or c:FindFirstChildWhichIsA("BasePart")) end
local function sameTeam(a, b)
    if not a or not b then return false end
    return a.Team ~= nil and b.Team ~= nil and a.Team == b.Team
end
local function isAlive(p)
    if not p or p == LocalPlayer or not p.Character then return false end
    local hum = getHumanoid(p.Character)
    return hum and hum.Health > 0
end
local function tableContains(t,v) for _,x in ipairs(t) do if x==v then return true end end return false end
local function tableRemoveValue(t,v) for i=#t,1,-1 do if t[i]==v then table.remove(t,i) return true end end return false end

-- Hàm gửi thông báo
local function sendNotification(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = 3;
    })
end

-- === LIGHTING HELPER FUNCTIONS ===
local function saveOriginalLighting()
    originalLightingState.Brightness = Lighting.Brightness
    originalLightingState.ClockTime = Lighting.ClockTime
    originalLightingState.FogEnd = Lighting.FogEnd
    originalLightingState.FogStart = Lighting.FogStart
    originalLightingState.Ambient = Lighting.Ambient
    originalLightingState.OutdoorAmbient = Lighting.OutdoorAmbient
    originalLightingState.GlobalShadows = Lighting.GlobalShadows
end

local function restoreLighting()
    Lighting.Brightness = originalLightingState.Brightness
    Lighting.ClockTime = originalLightingState.ClockTime
    Lighting.Ambient = originalLightingState.Ambient
    Lighting.OutdoorAmbient = originalLightingState.OutdoorAmbient
    Lighting.GlobalShadows = originalLightingState.GlobalShadows
end

local function restoreFog()
    Lighting.FogEnd = originalLightingState.FogEnd
    Lighting.FogStart = originalLightingState.FogStart
end

-- Player ESP Highlight
local function addPlayerHighlight(p)
    if not p or p == LocalPlayer or not p.Character then 
        return 
    end

    local char = p.Character
    local hl = char:FindFirstChild("PlayerHighlight")
    
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "PlayerHighlight"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
    end

    if not highlightEnabled then
        hl.Enabled = false
        return
    end

    if teamFilterEnabled and sameTeam(p, LocalPlayer) then
        hl.Enabled = false
        return
    end

    hl.Enabled = true
    if teamFilterEnabled and not sameTeam(p, LocalPlayer) then
        hl.FillColor = Color3.fromRGB(255, 64, 64)
    else
        hl.FillColor = highlightColor
    end
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.55
    hl.OutlineTransparency = 0.05
end

-- === HÀM XỬ LÝ TEXT ESP PLAYER ===
local function updatePlayerTextESP(p)
    if p == LocalPlayer then return end
    local char = p.Character
    if not char then return end
    
    local head = getHead(char)
    local hum = getHumanoid(char)
    
    local enabled = espNameEnabled or espHealthEnabled or espDistanceEnabled
    
    if not enabled or not head or not hum or hum.Health <= 0 then 
        if playerTextTags[p] then 
            playerTextTags[p]:Destroy() 
            playerTextTags[p] = nil 
        end
        return
    end
    
    local tag = playerTextTags[p]
    if not tag or not tag.Parent then
        tag = Instance.new("BillboardGui")
        tag.Name = "PlayerESPText"
        tag.Size = UDim2.new(0, 150, 0, 80) 
        tag.StudsOffset = Vector3.new(0, 3.5, 0)
        tag.AlwaysOnTop = true
        tag.ExtentsOffset = Vector3.new(0, 0, 0)
        tag.Parent = char 
        playerTextTags[p] = tag

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "ESPLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(240, 242, 250)
        textLabel.TextStrokeTransparency = 0.6
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 12 
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Top
        textLabel.Parent = tag
    end
    
    if tag.Adornee ~= head then
        tag.Adornee = head
    end
    
    local text = ""
    
    if espNameEnabled then
        text = text .. p.Name .. "\n"
    end
    
    if espHealthEnabled and hum.Health > 0 then
        local health = math.floor(hum.Health + 0.5)
        local maxHealth = hum.MaxHealth
        local hueValue = math.clamp(health/maxHealth * 0.35, 0, 0.35)
        local healthColor = Color3.fromHSV(hueValue, 1, 1) 
        text = text .. "<font color=\"rgb(" .. math.floor(healthColor.R*255) .. "," .. math.floor(healthColor.G*255) .. "," .. math.floor(healthColor.B*255) .. ")\">[" .. health .. " HP]</font>\n"
    end

    if espDistanceEnabled and getHRP(LocalPlayer.Character) and getHRP(char) then
        local localHRP = getHRP(LocalPlayer.Character)
        local targetHRP = getHRP(char)
        if localHRP and targetHRP then
            local dist = math.floor((localHRP.Position - targetHRP.Position).Magnitude + 0.5)
            text = text .. "{" .. dist .. "m}"
        end
    end
    
    local textLabel = tag:FindFirstChild("ESPLabel")
    if textLabel then
        textLabel.Text = text
        textLabel.RichText = true 
    end
end

local function startESPTextLoop()
    if espTextConnection then return end 
    espTextConnection = RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                updatePlayerTextESP(p)
            end
        end
    end)
end

local function stopESPTextLoop()
    if espTextConnection then
        espTextConnection:Disconnect()
        espTextConnection = nil
    end
    for p, tag in pairs(playerTextTags) do
        if tag and tag.Parent then tag:Destroy() end
        playerTextTags[p] = nil
    end
end

-- Combat Hitbox
local function applyHitboxToCharacter(p,c)
    if not p or p==LocalPlayer or not c then return end
    local hrp = getHRP(c)
    local head = getHead(c)
    if not hrp or not head then return end

    if teamFilterEnabled and sameTeam(p, LocalPlayer) then
        hrp.Size = Vector3.new(2,2,1)
        hrp.Transparency = 1
        hrp.CanCollide = true
        head.Size = Vector3.new(1,1,1)
        head.Transparency = 1
        return
    end

    if hitboxEnabled then
        hrp.Size = Vector3.new(hitboxSize,hitboxSize,hitboxSize)
        hrp.Transparency = 0.7
        hrp.CanCollide = false
    else
        hrp.Size = Vector3.new(2,2,1)
        hrp.Transparency = 1
        hrp.CanCollide = true
    end
    
    if headHitboxEnabled then 
        head.Size = Vector3.new(headHitboxSize, headHitboxSize, headHitboxSize)
        head.Transparency = 0.7
    else
        head.Size = Vector3.new(1, 1, 1) 
        head.Transparency = 1
    end
end

-- Setup Player Connections
local function setupPlayerConnections(p)
    if not p or p==LocalPlayer then return end
    
    local function onCharacterAdded(char)
        task.wait(0.3)
        addPlayerHighlight(p) 
        applyHitboxToCharacter(p, char)
        if espNameEnabled or espHealthEnabled or espDistanceEnabled then
            updatePlayerTextESP(p)
        end
    end
    
    p.CharacterAdded:Connect(onCharacterAdded)
    if p.Character then
        onCharacterAdded(p.Character)
    end
end

-- =========================================================
-- OPTIMIZED MODEL ESP & FUNCTIONS (FIXED REMOVAL)
-- =========================================================

-- Làm mới danh sách Cache
local function refreshModelCache()
    cachedModels = {}
    -- Quét toàn bộ workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and tableContains(modelHighlightList, obj.Name) and not Players:GetPlayerFromCharacter(obj) then
            table.insert(cachedModels, obj)
        end
    end
end

-- Xóa visual của một Model cụ thể (Dùng khi bỏ tick trong list)
local function clearSpecificModelVisuals(modelName)
    -- Quét cache hiện tại để xóa
    for i, model in ipairs(cachedModels) do
        if model and model.Name == modelName then
             local hl = model:FindFirstChild("ModelHighlight")
             if hl then hl:Destroy() end
             
             local tag = model:FindFirstChild("ModelNameTag")
             if tag then tag:Destroy() end
             
             -- Reset Hitbox
             local hrp = model:FindFirstChild("HumanoidRootPart")
             if hrp then
                 hrp.Size = Vector3.new(2, 2, 1)
                 hrp.Transparency = 1
                 hrp.CanCollide = true
             end
        end
    end
    -- Ngoài ra quét thêm workspace phòng hờ
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == modelName then
             local hl = obj:FindFirstChild("ModelHighlight")
             if hl then hl:Destroy() end
             local tag = obj:FindFirstChild("ModelNameTag")
             if tag then tag:Destroy() end
        end
    end
end

-- Hàm dọn dẹp TOÀN BỘ visual khi tắt nút tổng
local function clearAllModelVisuals()
    for _, model in ipairs(cachedModels) do
        if model then
            local hl = model:FindFirstChild("ModelHighlight")
            if hl then hl:Destroy() end
            
            local tag = model:FindFirstChild("ModelNameTag")
            if tag then tag:Destroy() end

            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
                hrp.CanCollide = true
            end
        end
    end
    -- Quét lại workspace một lần nữa để chắc chắn sạch sẽ
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hl = obj:FindFirstChild("ModelHighlight")
            if hl then hl:Destroy() end
            local tag = obj:FindFirstChild("ModelNameTag")
            if tag then tag:Destroy() end
        end
    end
end

-- Xử lý Logic từng Frame
local function updateModelVisuals()
    -- Nếu tắt cả nút tổng ESP Model và Text thì không chạy update visual
    if not espModelEnabled and not ESPTextEnabled and not modelHitboxEnabled and not modelNotifyEnabled then
        return 
    end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and getHRP(myChar)
    local currentTime = tick()

    -- Duyệt qua cache
    for _, model in ipairs(cachedModels) do
        if model and model.Parent then -- Kiểm tra model còn tồn tại
            
            -- Chỉ xử lý nếu model này nằm trong danh sách đang bật
            if tableContains(modelHighlightList, model.Name) then

                local adornee = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
                
                if adornee then
                    local distVal = 999999
                    if myHRP then
                        distVal = (myHRP.Position - adornee.Position).Magnitude
                    end

                    -- 1. HIGHLIGHT
                    if espModelEnabled then
                        local hl = model:FindFirstChild("ModelHighlight")
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "ModelHighlight"
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.FillColor = Color3.fromRGB(255,200,0)
                            hl.OutlineColor = Color3.new(1,1,1)
                            hl.FillTransparency = 0.55
                            hl.OutlineTransparency = 0.05
                            hl.Parent = model
                        end
                        hl.Enabled = true
                    else
                        -- Nếu nút tổng ESP tắt, phải xóa highlight đi
                        local hl = model:FindFirstChild("ModelHighlight")
                        if hl then hl:Destroy() end
                    end

                    -- 2. HITBOX
                    if modelHitboxEnabled then
                        local hrp = model:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Size = Vector3.new(modelHitboxSize, modelHitboxSize, modelHitboxSize)
                            hrp.Transparency = 0.7
                            hrp.CanCollide = false
                        end
                    end

                    -- 3. TEXT ESP
                    if ESPTextEnabled then
                        local tag = model:FindFirstChild("ModelNameTag")
                        if not tag then
                            tag = Instance.new("BillboardGui")
                            tag.Name = "ModelNameTag"
                            tag.Adornee = adornee
                            tag.Size = UDim2.new(0, 200, 0, 50)
                            tag.StudsOffset = Vector3.new(0, 3, 0)
                            tag.AlwaysOnTop = true
                            
                            local label = Instance.new("TextLabel", tag)
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.TextColor3 = Color3.fromRGB(255, 220, 100)
                            label.TextStrokeTransparency = 0.5
                            label.TextScaled = false
                            label.TextSize = 14
                            label.Font = Enum.Font.GothamBold
                            tag.Parent = model
                        end
                        
                        local lbl = tag:FindFirstChildOfClass("TextLabel")
                        if lbl then
                            lbl.Text = string.format("%s\n[%d m]", model.Name, math.floor(distVal))
                        end
                    else
                        local tag = model:FindFirstChild("ModelNameTag")
                        if tag then tag:Destroy() end
                    end

                    -- 4. NOTIFICATION
                    if modelNotifyEnabled and distVal <= modelNotifyDistance then
                        if currentTime - lastNotifyTime >= 3 then
                            sendNotification("⚠️ CẢNH BÁO", "Tìm thấy: " .. model.Name .. " (" .. math.floor(distVal) .. "m)")
                            lastNotifyTime = currentTime
                        end
                    end
                end 
            else
                -- Nếu model có trong cache nhưng tên không còn trong list (do vừa tắt) -> Xóa visual
                local hl = model:FindFirstChild("ModelHighlight")
                if hl then hl:Destroy() end
                local tag = model:FindFirstChild("ModelNameTag")
                if tag then tag:Destroy() end
            end
        end 
    end 
end

local function startModelLoop()
    if modelESPConnection then return end
    refreshModelCache() 
    
    modelESPConnection = RunService.RenderStepped:Connect(function()
        updateModelVisuals()
    end)
    
    workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") and tableContains(modelHighlightList, obj.Name) then
            table.insert(cachedModels, obj)
        end
    end)
end

local function findModelsByName(name)
    local results = {}
    if not name or name=="" then return results end
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name==name and not Players:GetPlayerFromCharacter(obj) then
            table.insert(results, obj)
        end
    end
    return results
end

-- FOV + Aimbot
local function ensureFOVCircle()
    if fovCircle then return end
    local ok, DrawingLib = pcall(function() return Drawing end)
    if ok and DrawingLib then
        fovCircle = DrawingLib.new("Circle")
        fovCircle.Filled = false
        fovCircle.NumSides = 128
        fovCircle.Thickness = 3
        fovCircle.Visible = false
    end
end

local function getClosestTargetInFOV()
    local center = Camera.ViewportSize/2
    local best, bestDist = nil, math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        if isAlive(plr) and plr~=LocalPlayer then
            if not (teamFilterEnabled and sameTeam(plr, LocalPlayer)) then
                local head = getHead(plr.Character)
                if head then
                    local wp, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local distScreen = (Vector2.new(wp.X, wp.Y) - Vector2.new(center.X, center.Y)).Magnitude
                        local dist3d = (head.Position - Camera.CFrame.Position).Magnitude
                        if dist3d <= aimMaxDistance and distScreen < bestDist and distScreen <= fovSize then
                            bestDist = distScreen
                            best = plr
                        end
                    end
                end
            end
        end
    end
    return best
end

-- UI Helper Functions
local function createCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function createStroke(parent, thickness, color)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.2
    s.Color = color or Color3.fromRGB(100, 110, 180)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function createButton(parent, text, size, color, callback)
    local button = Instance.new("TextButton")
    button.Size = size
    button.BackgroundColor3 = color
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.AutoButtonColor = false
    button.Parent = parent
    createCorner(button, 6)
    createStroke(button, 1, Color3.fromRGB(80, 85, 130))

    button.MouseButton1Click:Connect(callback)
    return button
end

-- Modern UI Components
local function createToggleButton(parent, text, state, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -16, 0, 36)
    container.BackgroundColor3 = Color3.fromRGB(40, 43, 62)
    container.BorderSizePixel = 0
    container.Parent = parent
    createCorner(container, 6)
    createStroke(container, 1, Color3.fromRGB(80, 85, 130))
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(240, 242, 250)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 40, 0, 22)
    toggle.Position = UDim2.new(1, -46, 0.5, -11)
    toggle.BackgroundColor3 = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 65, 90)
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.Parent = container
    createCorner(toggle, 11)
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 18, 0, 18)
    indicator.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BorderSizePixel = 0
    indicator.Parent = toggle
    createCorner(indicator, 9)
    
    toggle.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        
        local targetColor = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 65, 90)
        local targetPos = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        
        TweenService:Create(toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
    end)
    
    return container
end

-- Slider
local function createSlider(parent, text, value, min, max, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -12, 0, 48)
    container.BackgroundColor3 = Color3.fromRGB(40, 43, 62)
    container.BorderSizePixel = 0
    container.Parent = parent
    createCorner(container, 6)
    createStroke(container, 1, Color3.fromRGB(80, 85, 130))
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 16)
    label.Position = UDim2.new(0, 8, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(math.floor(value))
    label.TextColor3 = Color3.fromRGB(240, 242, 250)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "SliderBg"
    sliderBg.Size = UDim2.new(1, -16, 0, 6)
    sliderBg.Position = UDim2.new(0, 8, 1, -20)
    sliderBg.BackgroundColor3 = Color3.fromRGB(30, 33, 48)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    createCorner(sliderBg, 3)
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg
    createCorner(fill, 3)
    
    local handle = Instance.new("Frame")
    handle.Name = "Handle"
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.ZIndex = 2
    handle.Parent = container
    createCorner(handle, 8)
    createStroke(handle, 2, Color3.fromRGB(100, 150, 255))
    
    local interactionFrame = Instance.new("TextButton")
    interactionFrame.Name = "InteractionFrame"
    interactionFrame.Size = UDim2.new(1, 0, 1, 0) 
    interactionFrame.BackgroundTransparency = 1
    interactionFrame.Text = ""
    interactionFrame.AutoButtonColor = false
    interactionFrame.ZIndex = 3 
    interactionFrame.Parent = container
    
    local currentValue = value
    local isDragging = false
    local inputConnection = nil
    
    local function updateSlider(newValue)
        newValue = math.clamp(newValue, min, max)
        
        local displayValue = math.floor(newValue + 0.5) 
        
        if displayValue ~= math.floor(currentValue + 0.5) then
            currentValue = displayValue
            
            local normalized = (currentValue - min) / (max - min)
            fill.Size = UDim2.new(normalized, 0, 1, 0)
            handle.Position = UDim2.new(normalized, -8, 0.5, -8)
            label.Text = text .. ": " .. tostring(currentValue)
            
            callback(currentValue)
        end
    end
    
    local function calculateValueFromPosition(position)
        local sliderWidth = sliderBg.AbsoluteSize.X
        local sliderXPos = sliderBg.AbsolutePosition.X
        
        if sliderWidth == 0 then return currentValue end 
        
        local mouseX = position.X
        
        local relativeX = (mouseX - sliderXPos) / sliderWidth
        relativeX = math.clamp(relativeX, 0, 1)
        
        return min + (max - min) * relativeX
    end
    
    local function startDrag(input)
        isDragging = true
        updateSlider(calculateValueFromPosition(input.Position))
        
        inputConnection = UserInputService.InputChanged:Connect(function(moveInput)
            if isDragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                local pos = moveInput.Position
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                    pos = UserInputService:GetMouseLocation()
                end
                updateSlider(calculateValueFromPosition(pos))
            end
        end)
        
        UserInputService.InputEnded:Connect(function(endInput)
            if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                isDragging = false
                if inputConnection then inputConnection:Disconnect() end
            end
        end)
    end
    
    interactionFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            startDrag(input)
        end
    end)
    
    return container
end

local function createColorPicker(parent)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -16, 0, 60)
    container.BackgroundColor3 = Color3.fromRGB(40, 43, 62)
    container.BorderSizePixel = 0
    container.Parent = parent
    createCorner(container, 6)
    createStroke(container, 1, Color3.fromRGB(80, 85, 130))
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 16)
    label.Position = UDim2.new(0, 10, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = "ESP Color"
    label.TextColor3 = Color3.fromRGB(240, 242, 250)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, -20, 0, 26)
    grid.Position = UDim2.new(0, 10, 0, 26)
    grid.BackgroundTransparency = 1
    grid.Parent = container
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 4)
    layout.Parent = grid
    
    local colors = {
        {name = "Green", color = Color3.fromRGB(0, 255, 128)},
        {name = "Red", color = Color3.fromRGB(255, 64, 64)},
        {name = "Blue", color = Color3.fromRGB(64, 128, 255)},
        {name = "Yellow", color = Color3.fromRGB(255, 225, 64)},
        {name = "White", color = Color3.fromRGB(255, 255, 255)},
        {name = "Gray", color = Color3.fromRGB(200, 200, 200)}
    }
    
    for _, colorData in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 26, 0, 26)
        btn.BackgroundColor3 = colorData.color
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = grid
        createCorner(btn, 6)
        createStroke(btn, 2, Color3.fromRGB(255, 255, 255))
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 28, 0, 28)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 26, 0, 26)}):Play()
        end)
        
        btn.MouseButton1Click:Connect(function()
            highlightColor = colorData.color
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    addPlayerHighlight(p)
                end
            end
        end)
    end
    
    return container
end

local function createActionButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(70, 100, 200)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = parent
    createCorner(btn, 6)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 120, 220)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 100, 200)}):Play()
    end)
    
    btn.MouseButton1Click:Connect(callback)
    
    return btn
end

-- #############################################
-- HÀM FLY MODE V3 (ĐÃ FIX CHO MOBILE & PC)
-- #############################################
local function startFlyModeV3()
    local chr = LocalPlayer.Character
    local hum = getHumanoid(chr)
    -- Nếu không tìm thấy nhân vật, thử tìm lại một lần nữa
    if not chr or not hum then 
        chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        hum = getHumanoid(chr)
        if not chr or not hum then return end -- Vẫn không có thì thoát
    end
    
    -- Reset trạng thái để tránh lỗi chồng chéo
    if flyConn then flyConn:Disconnect() end
    if flyControlConnection then flyControlConnection:Disconnect() end
    
    -- Set trạng thái vật lý
    for i, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        if state ~= Enum.HumanoidStateType.None then
            hum:SetStateEnabled(state, false)
        end
    end
    hum:ChangeState(Enum.HumanoidStateType.Swimming)
    
    local targetPart = (chr.ClassName == "Model" and chr:FindFirstChild("UpperTorso")) or (chr.ClassName == "Model" and chr:FindFirstChild("Torso")) or getHRP(chr)
    if not targetPart then return end
    
    if targetPart:FindFirstChild("BodyGyro") then targetPart.BodyGyro:Destroy() end
    if targetPart:FindFirstChild("BodyVelocity") then targetPart.BodyVelocity:Destroy() end
    
    local bg = Instance.new("BodyGyro", targetPart)
    bg.P = 9e4
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = targetPart.CFrame
    
    local bv = Instance.new("BodyVelocity", targetPart)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    hum.PlatformStand = true

    -- Control cho PC (Keyboard)
    flyControlConnection = UserInputService.InputChanged:Connect(function(input)
        if not miscFlyEnabled then return end
        local key = input.KeyCode
        local isDown = input.UserInputState == Enum.UserInputState.Begin
        
        if key == Enum.KeyCode.W then flyControl.f = isDown and 1 or 0
        elseif key == Enum.KeyCode.S then flyControl.b = isDown and -1 or 0
        elseif key == Enum.KeyCode.A then flyControl.l = isDown and -1 or 0
        elseif key == Enum.KeyCode.D then flyControl.r = isDown and 1 or 0
        elseif key == Enum.KeyCode.Space then flyControl.u = isDown and 1 or 0
        elseif key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.RightShift then flyControl.d = isDown and -1 or 0
        end
    end)
    
    flyConn = RunService.RenderStepped:Connect(function()
        -- Kiểm tra an toàn
        if not miscFlyEnabled or not targetPart.Parent or not targetPart:FindFirstChild("BodyGyro") then
            stopFlyModeV3()
            return
        end
        
        local currentSpeed = flySpeedV3
        
        -- Vector di chuyển từ bàn phím (PC)
        local keyVector = Vector3.new(
            flyControl.l + flyControl.r, 
            flyControl.u + flyControl.d, 
            flyControl.f + flyControl.b  
        )
        
        local cameraCF = Camera.CFrame
        
        if keyVector.Magnitude > 0 then
            -- Logic PC: Di chuyển theo hướng camera + phím bấm
            local direction = (cameraCF.LookVector * keyVector.Z) + (cameraCF.RightVector * keyVector.X) + (cameraCF.UpVector * keyVector.Y)
            bv.Velocity = direction.Unit * currentSpeed
            bg.CFrame = cameraCF * CFrame.Angles(-math.rad((flyControl.f + flyControl.b) * 10), 0, 0)
        elseif hum.MoveDirection.Magnitude > 0 then
            -- Logic Mobile: Di chuyển theo Joystick (MoveDirection)
            bv.Velocity = hum.MoveDirection * currentSpeed
            -- Xoay người theo hướng camera nhìn
            bg.CFrame = Camera.CFrame
        else
            -- Đứng yên
            bv.Velocity = Vector3.new(0, 0, 0)
            bg.CFrame = Camera.CFrame 
        end
    end)
end

local function stopFlyModeV3()
    if flyConn then 
        flyConn:Disconnect() 
        flyConn = nil 
    end
    if flyControlConnection then 
        flyControlConnection:Disconnect() 
        flyControlConnection = nil 
    end
    
    local chr = LocalPlayer.Character
    if chr then
        local hum = getHumanoid(chr)
        local targetPart = (chr.ClassName == "Model" and chr:FindFirstChild("UpperTorso")) or (chr.ClassName == "Model" and chr:FindFirstChild("Torso")) or getHRP(chr)
        
        if targetPart then
            if targetPart:FindFirstChild("BodyGyro") then targetPart.BodyGyro:Destroy() end
            if targetPart:FindFirstChild("BodyVelocity") then targetPart.BodyVelocity:Destroy() end
        end

        if hum then
            hum.PlatformStand = false
            for i, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                hum:SetStateEnabled(state, true)
            end
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
    flyControl = {f = 0, b = 0, l = 0, r = 0, u = 0, d = 0} 
end
-- #############################################
-- KẾT THÚC HÀM FLY MODE V3

-- Build Menu
local function createMenu()
    saveOriginalLighting() -- Save lighting state on load

    if CoreGui:FindFirstChild("ModernUtilityMenu") then 
        CoreGui.ModernUtilityMenu:Destroy() 
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernUtilityMenu"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = CoreGui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 40, 0, 40)
    toggleBtn.Position = UDim2.new(0.02, 0, 0.08, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 70)
    toggleBtn.Text = "☰"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 18
    toggleBtn.Draggable = true
    toggleBtn.Parent = screenGui
    createCorner(toggleBtn, 10)
    createStroke(toggleBtn, 2, Color3.fromRGB(100, 110, 180))

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 420, 0, 360) 
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -180)
    mainFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 45)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    createCorner(mainFrame, 12)
    createStroke(mainFrame, 2, Color3.fromRGB(100, 110, 180))

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(35, 38, 55)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    createCorner(header, 12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🛠️ Menu 4.5 (Final Fix Model/Light)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 100, 1, -50)
    sidebar.Position = UDim2.new(0, 8, 0, 50)
    sidebar.BackgroundColor3 = Color3.fromRGB(32, 35, 50)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame
    createCorner(sidebar, 8)
    createStroke(sidebar, 1, Color3.fromRGB(80, 85, 130))

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 5)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.Parent = sidebar

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 6)
    sidebarPadding.Parent = sidebar

    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -120, 1, -60)
    contentFrame.Position = UDim2.new(0, 110, 0, 50)
    contentFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 38)
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 4
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 110, 180)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Parent = mainFrame
    createCorner(contentFrame, 8)

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 6)
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.Parent = contentFrame

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 6)
    contentPadding.PaddingBottom = UDim.new(0, 6)
    contentPadding.PaddingLeft = UDim.new(0, 4)
    contentPadding.PaddingRight = UDim.new(0, 4)
    contentPadding.Parent = contentFrame

    toggleBtn.MouseButton1Click:Connect(function()
        menuVisible = not menuVisible
        mainFrame.Visible = menuVisible
    end)

    local tabButtons = {}
    local function createTabButton(text, icon)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(45, 50, 70)
        btn.Text = icon .. " " .. text
        btn.TextColor3 = Color3.fromRGB(200, 205, 220)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.AutoButtonColor = false
        btn.Parent = sidebar
        createCorner(btn, 6)
        
        tabButtons[text] = btn
        
        btn.MouseEnter:Connect(function()
            if currentTab ~= text then
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(60, 65, 90),
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end
        end)
        
        btn.MouseLeave:Connect(function()
            if currentTab ~= text then
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(45, 50, 70),
                    TextColor3 = Color3.fromRGB(200, 205, 220)
                }):Play()
            end
        end)
        
        return btn
    end

    local function clearContent()
        for _, child in ipairs(contentFrame:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("ScrollingFrame") then
                child:Destroy()
            end
        end
    end

    local function setActiveTab(tabName)
        currentTab = tabName
        for name, btn in pairs(tabButtons) do
            if name == tabName then
                btn.BackgroundColor3 = Color3.fromRGB(70, 100, 200)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(45, 50, 70)
                btn.TextColor3 = Color3.fromRGB(200, 205, 220)
            end
        end
    end

    -- ESP Tab
    local function showESP()
        clearContent()
        setActiveTab("ESP")
        showingModelList = false
        
        createToggleButton(contentFrame, "Highlight Players", highlightEnabled, function(state)
            highlightEnabled = state
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    addPlayerHighlight(p)
                end
            end
        end)
        
        createToggleButton(contentFrame, "Team Filter (Highlight/Hitbox)", teamFilterEnabled, function(state)
            teamFilterEnabled = state
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    addPlayerHighlight(p)
                    applyHitboxToCharacter(p, p.Character)
                end
            end
        end)
        
        createColorPicker(contentFrame)

        --- === ESP TEXT FEATURES ===
        local function toggleESPTextLoop()
            local enabled = espNameEnabled or espHealthEnabled or espDistanceEnabled
            if enabled then
                startESPTextLoop()
            else
                stopESPTextLoop()
            end
        end

        createToggleButton(contentFrame, "ESP Name", espNameEnabled, function(state)
            espNameEnabled = state
            toggleESPTextLoop()
        end)

        createToggleButton(contentFrame, "ESP Health (HP)", espHealthEnabled, function(state)
            espHealthEnabled = state
            toggleESPTextLoop()
        end)

        createToggleButton(contentFrame, "ESP Distance (m)", espDistanceEnabled, function(state)
            espDistanceEnabled = state
            toggleESPTextLoop()
        end)
    end

    -- Combat Tab
    local function showCombat()
        clearContent()
        setActiveTab("Combat")
        showingModelList = false
        
        createToggleButton(contentFrame, "Body Hitbox Expander", hitboxEnabled, function(state)
            hitboxEnabled = state
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    applyHitboxToCharacter(p, p.Character)
                end
            end
        end)
        
        createSlider(contentFrame, "Body Hitbox Size", hitboxSize, 2, 100, function(val)
            hitboxSize = val
            if hitboxEnabled then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        applyHitboxToCharacter(p, p.Character)
                    end
                end
            end
        end)
        
        createToggleButton(contentFrame, "Head Hitbox Expander", headHitboxEnabled, function(state)
            headHitboxEnabled = state
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    applyHitboxToCharacter(p, p.Character)
                end
            end
        end)
        
        createSlider(contentFrame, "Head Hitbox Size", headHitboxSize, 1, 30, function(val)
            headHitboxSize = val
            if headHitboxEnabled then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        applyHitboxToCharacter(p, p.Character)
                    end
                end
            end
        end)
        
        createToggleButton(contentFrame, "FOV + Aimbot", fovEnabled, function(state)
            fovEnabled = state
            stickyTarget = nil
        end)
        
        createSlider(contentFrame, "FOV Size", fovSize, 10, 120, function(val)
            fovSize = val
        end)
        
        createSlider(contentFrame, "Aim Smooth", math.floor(aimSmooth * 100), 1, 100, function(val)
            aimSmooth = val / 100
        end)
        
        createSlider(contentFrame, "Max Distance", math.min(aimMaxDistance, 10000), 50, 10000, function(val)
            aimMaxDistance = val
        end)
    end

    -- Function Tab
    local function showFunction()
        clearContent()
        setActiveTab("Function")
        showingModelList = false

        createToggleButton(contentFrame, "God Mode (Bất Tử)", godModeEnabled, function(state)
            godModeEnabled = state
            if state then
                if godModeConnection then godModeConnection:Disconnect() end
                
                local hum = getHumanoid(LocalPlayer.Character)
                if hum then
                    hum.BreakJointsOnDeath = false 
                    hum.HealthChanged:Connect(function()
                        if godModeEnabled and hum.Health < hum.MaxHealth then
                            hum.Health = hum.MaxHealth
                        end
                    end)
                end

                godModeConnection = RunService.Stepped:Connect(function()
                    if godModeEnabled and LocalPlayer.Character then
                        local h = getHumanoid(LocalPlayer.Character)
                        if h then
                            h.Health = h.MaxHealth
                            h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                        end
                    else
                         if godModeConnection then godModeConnection:Disconnect() end
                    end
                end)
            else
                if godModeConnection then 
                    godModeConnection:Disconnect() 
                    godModeConnection = nil
                end
            end
        end)

        createToggleButton(contentFrame, "Invisible (Ghost Mode)", invisibleEnabled, function(state)
            invisibleEnabled = state
            if state then
                if invisibleConnection then invisibleConnection:Disconnect() end
                invisibleConnection = RunService.Stepped:Connect(function()
                    if invisibleEnabled and LocalPlayer.Character then
                        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Transparency = 1
                                part.CanCollide = false
                            elseif part:IsA("Decal") or part:IsA("Texture") then
                                part.Transparency = 1
                            end
                        end
                    else
                         if invisibleConnection then invisibleConnection:Disconnect() end
                    end
                end)
            else
                if invisibleConnection then 
                    invisibleConnection:Disconnect() 
                    invisibleConnection = nil
                end
                if LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if part.Name == "HumanoidRootPart" then
                                part.Transparency = 1
                            else
                                part.Transparency = 0
                                part.CanCollide = true
                            end
                        elseif part:IsA("Decal") or part:IsA("Texture") then
                            part.Transparency = 0
                        end
                    end
                end
            end
        end)
        
        createToggleButton(contentFrame, "Instant Interact (Giữ E)", instantPromptEnabled, function(state)
            instantPromptEnabled = state
            if state then
                if instantPromptConnection then instantPromptConnection:Disconnect() end
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") then v.HoldDuration = 0 end
                end
                instantPromptConnection = workspace.DescendantAdded:Connect(function(v)
                    if instantPromptEnabled and v:IsA("ProximityPrompt") then
                        v.HoldDuration = 0
                    end
                end)
            else
                if instantPromptConnection then 
                    instantPromptConnection:Disconnect() 
                    instantPromptConnection = nil
                end
            end
        end)

        createToggleButton(contentFrame, "Spinbot", spinBotEnabled, function(state)
            spinBotEnabled = state
            if state then
                if spinBotConnection then spinBotConnection:Disconnect() end
                spinBotConnection = RunService.RenderStepped:Connect(function()
                    if spinBotEnabled and LocalPlayer.Character then
                        local hrp = getHRP(LocalPlayer.Character)
                        if hrp then
                            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinBotSpeed), 0)
                        end
                    else
                        if spinBotConnection then spinBotConnection:Disconnect() end
                    end
                end)
            else
                if spinBotConnection then
                    spinBotConnection:Disconnect()
                    spinBotConnection = nil
                end
            end
        end)

        createSlider(contentFrame, "Spin Speed", spinBotSpeed, 1, 100, function(val)
            spinBotSpeed = val
        end)
    end

    -- Misc Tab
    local function showMisc()
        clearContent()
        setActiveTab("Misc")
        showingModelList = false
        
        createToggleButton(contentFrame, "Full Bright (Sáng)", miscFullBrightEnabled, function(state)
            miscFullBrightEnabled = state
            if state then
                saveOriginalLighting() -- Save before change
                if fullBrightConnection then fullBrightConnection:Disconnect() end
                fullBrightConnection = RunService.RenderStepped:Connect(function()
                    Lighting.Brightness = 2
                    Lighting.ClockTime = 14
                    Lighting.GlobalShadows = false
                    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                end)
            else
                if fullBrightConnection then 
                    fullBrightConnection:Disconnect() 
                    fullBrightConnection = nil
                end
                restoreLighting() -- Restore original
            end
        end)

        createToggleButton(contentFrame, "No Fog (Xóa Mù)", miscFogEnabled, function(state)
            miscFogEnabled = state
            if state then
                saveOriginalLighting()
                Lighting.FogEnd = 1000000
                Lighting.FogStart = 0
            else
                restoreFog()
            end
        end)

        createToggleButton(contentFrame, "Infinite Jump", miscInfiniteJump, function(state)
            miscInfiniteJump = state
        end)
        
        createToggleButton(contentFrame, "Noclip", miscNoclip, function(state)
            miscNoclip = state
        end)
        
        createToggleButton(contentFrame, "Speed Boost", miscSpeedEnabled, function(state)
            miscSpeedEnabled = state
            local hum = getHumanoid(LocalPlayer.Character)
            if hum then
                if state then
                    originalWalkSpeed = hum.WalkSpeed
                    hum.WalkSpeed = miscSpeedValue
                else
                    hum.WalkSpeed = originalWalkSpeed
                end
            end
        end)
        
        createSlider(contentFrame, "Speed Value", miscSpeedValue, 16, 150, function(val)
            miscSpeedValue = val
            if miscSpeedEnabled then
                local hum = getHumanoid(LocalPlayer.Character)
                if hum then
                    hum.WalkSpeed = val
                end
            end
        end)

        createToggleButton(contentFrame, "Bring All (Client/Hit)", miscBringAllEnabled, function(state)
            miscBringAllEnabled = state
            if state then
                if bringAllConnection then bringAllConnection:Disconnect() end
                bringAllConnection = RunService.Stepped:Connect(function()
                    if not miscBringAllEnabled then 
                        if bringAllConnection then bringAllConnection:Disconnect() end
                        return 
                    end
                    
                    local myRoot = getHRP(LocalPlayer.Character)
                    if not myRoot then return end
                    
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and isAlive(p) then
                            if not (teamFilterEnabled and sameTeam(p, LocalPlayer)) then
                                local targetRoot = getHRP(p.Character)
                                if targetRoot then
                                    targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -6)
                                    targetRoot.Velocity = Vector3.new(0,0,0) 
                                    targetRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                                end
                            end
                        end
                    end
                end)
            else
                if bringAllConnection then 
                    bringAllConnection:Disconnect()
                    bringAllConnection = nil
                end
            end
        end)
        
        createToggleButton(contentFrame, "Fly Mode V3 (Mobile Fix)", miscFlyEnabled, function(state)
            miscFlyEnabled = state
            if state then
                startFlyModeV3()
            else
                stopFlyModeV3()
            end
        end)
        
        createSlider(contentFrame, "Fly Speed V3", flySpeedV3, 10, 200, function(val)
            flySpeedV3 = val
        end)
    end

    -- ESP Model Tab (FIXED)
    local function showModel()
        clearContent()
        setActiveTab("Model")
        
        startModelLoop() -- Đảm bảo Loop chạy

        if showingModelList then
            createActionButton(contentFrame, "← Back", function()
                showingModelList = false
                showModel()
            end)
            
            local listLabel = Instance.new("TextLabel")
            listLabel.Size = UDim2.new(1, -16, 0, 24)
            listLabel.BackgroundTransparency = 1
            listLabel.Text = "Click model name to toggle ESP"
            listLabel.TextColor3 = Color3.fromRGB(240, 242, 250)
            listLabel.Font = Enum.Font.GothamBold
            listLabel.TextSize = 11
            listLabel.Parent = contentFrame
            
            local seen = {}
            local modelCount = 0
            
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                    if not seen[obj.Name] then
                        seen[obj.Name] = true
                        modelCount = modelCount + 1
                        local isActive = tableContains(modelHighlightList, obj.Name)
                        
                        local btn = Instance.new("TextButton")
                        btn.Size = UDim2.new(1, -16, 0, 32)
                        btn.BackgroundColor3 = isActive and Color3.fromRGB(70, 150, 70) or Color3.fromRGB(40, 43, 62)
                        btn.Text = (isActive and "✓ " or "   ") .. obj.Name
                        btn.TextColor3 = Color3.fromRGB(240, 242, 250)
                        btn.Font = Enum.Font.Gotham
                        btn.TextSize = 11
                        btn.TextXAlignment = Enum.TextXAlignment.Left
                        btn.AutoButtonColor = false
                        btn.Parent = contentFrame
                        createCorner(btn, 5)
                        createStroke(btn, 1, Color3.fromRGB(80, 85, 130))
                        
                        local padding = Instance.new("UIPadding")
                        padding.PaddingLeft = UDim.new(0, 8)
                        padding.Parent = btn
                        
                        btn.MouseButton1Click:Connect(function()
                            if not tableContains(modelHighlightList, obj.Name) then
                                table.insert(modelHighlightList, obj.Name)
                                refreshModelCache() 
                                btn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
                                btn.Text = "✓ " .. obj.Name
                            else
                                tableRemoveValue(modelHighlightList, obj.Name)
                                clearSpecificModelVisuals(obj.Name) -- FIX: Xóa ngay lập tức
                                refreshModelCache() 
                                btn.BackgroundColor3 = Color3.fromRGB(40, 43, 62)
                                btn.Text = "   " .. obj.Name
                            end
                        end)
                    end
                end
            end
            
            if modelCount == 0 then
                local noModelsLabel = Instance.new("TextLabel")
                noModelsLabel.Size = UDim2.new(1, -16, 0, 32)
                noModelsLabel.BackgroundTransparency = 1
                noModelsLabel.Text = "No models found in workspace"
                noModelsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                noModelsLabel.Font = Enum.Font.Gotham
                noModelsLabel.TextSize = 11
                noModelsLabel.Parent = contentFrame
            end
        else
            createToggleButton(contentFrame, "Enable Model ESP (Highlight)", espModelEnabled, function(state)
                espModelEnabled = state
                if not state then clearAllModelVisuals() end -- FIX: Xóa sạch khi tắt
            end)
            
            createToggleButton(contentFrame, "Model Hitbox (NPC)", modelHitboxEnabled, function(state)
                modelHitboxEnabled = state
                if not state then clearAllModelVisuals() end
            end)
            
            createSlider(contentFrame, "Model Hitbox Size", modelHitboxSize, 2, 20, function(val)
                modelHitboxSize = val
            end)
            
            createToggleButton(contentFrame, "ESP Text & Distance", ESPTextEnabled, function(state)
                ESPTextEnabled = state
                if not state then clearAllModelVisuals() end
            end)

            createToggleButton(contentFrame, "Proximity Alert (Báo Gần)", modelNotifyEnabled, function(state)
                modelNotifyEnabled = state
            end)

            createSlider(contentFrame, "Alert Distance", modelNotifyDistance, 10, 500, function(val)
                modelNotifyDistance = val
            end)
            
            createActionButton(contentFrame, "Select Models List", function()
                showingModelList = true
                showModel()
            end)
        end
    end

    local espBtn = createTabButton("ESP", "👁️")
    local combatBtn = createTabButton("Combat", "⚔️")
    local functionBtn = createTabButton("Function", "⚙️")
    local miscBtn = createTabButton("Misc", "🔧")
    local modelBtn = createTabButton("Model", "📦")

    espBtn.MouseButton1Click:Connect(showESP)
    combatBtn.MouseButton1Click:Connect(showCombat)
    functionBtn.MouseButton1Click:Connect(showFunction)
    miscBtn.MouseButton1Click:Connect(showMisc)
    modelBtn.MouseButton1Click:Connect(showModel)

    showMisc()
end

Players.PlayerAdded:Connect(setupPlayerConnections)
for _,p in ipairs(Players:GetPlayers()) do setupPlayerConnections(p) end

Players.PlayerRemoving:Connect(function(p)
    if playerTextTags[p] then 
        playerTextTags[p]:Destroy() 
        playerTextTags[p] = nil 
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    local hum = getHumanoid(char)
    if hum then
        if miscSpeedEnabled then hum.WalkSpeed = miscSpeedValue else hum.WalkSpeed = originalWalkSpeed end
        
        hum.Died:Connect(function()
            if miscFlyEnabled then stopFlyModeV3(); miscFlyEnabled = false end
            if isFollowingPlayer then isFollowingPlayer = false; if followConnection then followConnection:Disconnect() end end
            if miscBringAllEnabled then miscBringAllEnabled = false; if bringAllConnection then bringAllConnection:Disconnect() end end
            if godModeEnabled then godModeEnabled = false; if godModeConnection then godModeConnection:Disconnect() end end
            if spinBotEnabled then spinBotEnabled = false; if spinBotConnection then spinBotConnection:Disconnect() end end
            if invisibleEnabled then invisibleEnabled = false; if invisibleConnection then invisibleConnection:Disconnect() end end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(1.5)
        local esp_enabled = espNameEnabled or espHealthEnabled or espDistanceEnabled
        for _,p in ipairs(Players:GetPlayers()) do 
            if p.Character then
                addPlayerHighlight(p) 
                applyHitboxToCharacter(p, p.Character)
                if esp_enabled then updatePlayerTextESP(p) end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if miscInfiniteJump then
        local hum = getHumanoid(LocalPlayer.Character)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if miscNoclip then
        local char = LocalPlayer.Character
        if char then
            for _,part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if fovEnabled then
        ensureFOVCircle()
        if fovCircle then
            fovCircle.Radius = fovSize
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            hue = (hue + 0.005) % 1
            fovCircle.Color = Color3.fromHSV(hue, 1, 1)
            fovCircle.Visible = true
        end
    else
        if fovCircle then fovCircle.Visible = false end
    end

    if fovEnabled then
        if not (stickyTarget and isAlive(stickyTarget)) then
            stickyTarget = getClosestTargetInFOV()
        else
            local head = getHead(stickyTarget.Character)
            if head then
                local wp, onScreen = Camera:WorldToViewportPoint(head.Position)
                local center = Camera.ViewportSize/2
                local distScreen = (Vector2.new(wp.X, wp.Y) - Vector2.new(center.X, center.Y)).Magnitude
                local dist3d = (head.Position - Camera.CFrame.Position).Magnitude
                if (not onScreen) or distScreen > fovSize or dist3d > aimMaxDistance then
                    stickyTarget = getClosestTargetInFOV()
                end
            else
                stickyTarget = getClosestTargetInFOV()
            end
        end

        if stickyTarget and isAlive(stickyTarget) then
            local head = getHead(stickyTarget.Character)
            if head then
                local current = Camera.CFrame
                local target = CFrame.new(current.Position, head.Position)
                Camera.CFrame = current:Lerp(target, math.clamp(aimSmooth, 0.01, 1.00))
            end
        end
    else
        stickyTarget = nil
    end
end)

createMenu()
print("✅ Script Loaded: Model ESP Fix + Lighting Restore")

