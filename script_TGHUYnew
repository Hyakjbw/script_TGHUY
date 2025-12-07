-- Modern Utility Menu Script 3.1 (UPDATED - ADD ESP NAME/HEALTH/DISTANCE & FIXED HIGHLIGHT)
-- script được roblox cho phép

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- Global states
local menuVisible = true
local currentTab = "ESP"

-- ESP players
local highlightEnabled = false
local highlightColor = Color3.fromRGB(0, 255, 128)
local teamFilterEnabled = false
-- === BIẾN MỚI CHO ESP NÂNG CAO ===
local espNameEnabled = false
local espHealthEnabled = false
local espDistanceEnabled = false
local espTextConnection = nil
local playerTextTags = {} -- Lưu trữ BillboardGui cho ESP
-----------------------------------

-- Combat
local hitboxEnabled = false
local hitboxSize = 6
local fovEnabled = false
local fovSize = 120
local aimSmooth = 0.25
local stickyTarget = nil
local fovCircle = nil
local hue = 0
local aimMaxDistance = math.huge

-- Misc
local miscInfiniteJump = false
local miscNoclip = false
local miscSpeedEnabled = false
local miscSpeedValue = 24
local originalWalkSpeed = 16
local miscFlyEnabled = false
local miscFlySpeed = 60
local flyConn = nil
local currentTargetPlayer = nil
local isFollowingPlayer = false
local followSpeed = 30
local followConnection = nil 

-- ESP Model
local espModelEnabled = true
local modelHighlightList = {}
local ESPTextEnabled = false
local ESPTextConnection = nil
local modelHitboxEnabled = false
local modelHitboxSize = 6
local showingModelList = false

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

-- Player ESP Highlight (FIXED LOGIC)
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

    -- Nếu bật và không cùng team (hoặc không dùng team filter) -> Bật highlight
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

-- === HÀM MỚI: XỬ LÝ TEXT ESP CHO NGƯỜI CHƠI (TÊN, MÁU, KHOẢNG CÁCH) ===
local function updatePlayerTextESP(p)
    if p == LocalPlayer then return end
    local char = p.Character
    local head = getHead(char)
    local hum = getHumanoid(char)
    
    local enabled = espNameEnabled or espHealthEnabled or espDistanceEnabled
    
    -- Xóa tag nếu không bật hoặc người chơi không hợp lệ
    if not enabled or not char or not head or not hum then 
        if playerTextTags[p] then 
            playerTextTags[p]:Destroy() 
            playerTextTags[p] = nil 
        end
        return
    end
    
    local tag = playerTextTags[p]
    if not tag then
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
    
    tag.Adornee = head
    
    local text = ""
    
    -- 1. Tên
    if espNameEnabled then
        text = text .. p.Name .. "\n"
    end
    
    -- 2. Máu (Health)
    if espHealthEnabled and hum.Health > 0 then
        local health = math.floor(hum.Health + 0.5)
        local maxHealth = hum.MaxHealth
        -- Tạo màu dựa trên % máu
        local hueValue = math.clamp(health/maxHealth * 0.35, 0, 0.35)
        local healthColor = Color3.fromHSV(hueValue, 1, 1) 
        
        text = text .. "<font color=\"rgb(" .. math.floor(healthColor.R*255) .. "," .. math.floor(healthColor.G*255) .. "," .. math.floor(healthColor.B*255) .. ")\">[" .. health .. " HP]</font>\n"
    end

    -- 3. Khoảng cách (Distance)
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
    if espTextConnection then espTextConnection:Disconnect() end
    -- Loop Heartbeat để cập nhật liên tục (máu, khoảng cách)
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
    -- Xóa tất cả tag text
    for _, tag in pairs(playerTextTags) do
        if tag and tag.Parent then tag:Destroy() end
    end
    playerTextTags = {}
end
-- KẾT THÚC HÀM XỬ LÝ TEXT ESP

-- Combat Hitbox
local function applyHitboxToCharacter(p,c)
    if not p or p==LocalPlayer or not c then return end
    local hrp = getHRP(c)
    if not hrp then return end

    if teamFilterEnabled and sameTeam(p, LocalPlayer) then
        hrp.Size = Vector3.new(2,2,1)
        hrp.Transparency = 1
        hrp.CanCollide = true
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
end

-- Setup Player Connections (FIXED - ĐẢM BẢO HIGHLIGHT/ESP/HITBOX ÁP DỤNG KHI VÀO GAME VÀ HỒI SINH)
local function setupPlayerConnections(p)
    if not p or p==LocalPlayer then return end
    
    local function onCharacterAdded(char)
        task.wait(0.1) -- Đợi nhân vật load hoàn chỉnh

        -- 1. Apply Highlight (Luôn gọi để đảm bảo tính năng hoạt động)
        addPlayerHighlight(p) 
        
        -- 2. Apply Hitbox
        applyHitboxToCharacter(p, char)
        
        -- 3. Cập nhật ESP Text Tag (Nếu tính năng bật, nó sẽ được cập nhật trong loop)
        if espNameEnabled or espHealthEnabled or espDistanceEnabled then
            updatePlayerTextESP(p)
        end
    end
    
    p.CharacterAdded:Connect(onCharacterAdded)
    
    -- Nếu người chơi đã có nhân vật (khi vào game)
    if p.Character then
        onCharacterAdded(p.Character)
    end
end
-- KẾT THÚC HÀM XỬ LÝ PLAYER CONNECTION

-- Model functions (Unchanged)
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

local function applyModelHighlight()
    if not espModelEnabled then
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local hl=obj:FindFirstChild("ModelHighlight")
                if hl then hl.Enabled=false end
            end
        end
        return
    end
    for _,name in ipairs(modelHighlightList) do
        for _,model in ipairs(findModelsByName(name)) do
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
        end
    end
end

local function applyHitboxToModel(model)
    if not model or not model:IsA("Model") then return end
    if Players:GetPlayerFromCharacter(model) then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hum and hrp then
        if modelHitboxEnabled then
            hrp.Size = Vector3.new(modelHitboxSize,modelHitboxSize,modelHitboxSize)
            hrp.Transparency = 0.7
            hrp.CanCollide = false
        else
            hrp.Size = Vector3.new(2,2,1)
            hrp.Transparency = 1
            hrp.CanCollide = true
        end
    end
end

local function createTextESPForModel(model)
    if not model or not model:IsA("Model") then return end
    if model:FindFirstChild("NameTag") then return end
    local adornee = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
    if not adornee then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Adornee = adornee
    billboard.Size = UDim2.new(0, 140, 0, 28)
    billboard.StudsOffset = Vector3.new(0, 2.2, 0)
    billboard.AlwaysOnTop = true
    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = model.Name
    label.TextColor3 = Color3.fromRGB(255, 200, 80)
    label.TextStrokeTransparency = 0.6
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    billboard.Parent = model
end

local function scanNPCModelsForText()
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            if obj:FindFirstChildOfClass("Humanoid") and not obj:FindFirstChild("NameTag") then
                createTextESPForModel(obj)
            end
        end
    end
end

-- FOV + Aimbot (Unchanged)
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

-- UI Helper Functions (Unchanged)
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

-- Modern UI Components (Unchanged Toggle Button)
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

-- SLIDER ĐÃ SỬA LẦN 5 - CẢI THIỆN XỬ LÝ KÉO TRÊN MOBILE VÀ DESKTOP
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
    
    -- KHUNG TƯƠNG TÁC
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

-- Build Menu (Unchanged)
local function createMenu()
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
    title.Text = "🛠️ Utility Menu"
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

    -- ESP Tab (UPDATED)
    local function showESP()
        clearContent()
        setActiveTab("ESP")
        showingModelList = false
        
        -- Player ESP (Highlight + Team Filter)
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

        --- === NEW ESP TEXT FEATURES ===
        local function toggleESPText(state)
            local enabled = espNameEnabled or espHealthEnabled or espDistanceEnabled
            if enabled then
                startESPTextLoop()
            else
                stopESPTextLoop()
            end
        end

        createToggleButton(contentFrame, "ESP Name", espNameEnabled, function(state)
            espNameEnabled = state
            toggleESPText(state)
        end)

        createToggleButton(contentFrame, "ESP Health (HP)", espHealthEnabled, function(state)
            espHealthEnabled = state
            toggleESPText(state)
        end)

        createToggleButton(contentFrame, "ESP Distance (m)", espDistanceEnabled, function(state)
            espDistanceEnabled = state
            toggleESPText(state)
        end)
        -- =============================
    end

    -- Combat Tab (Unchanged)
    local function showCombat()
        clearContent()
        setActiveTab("Combat")
        showingModelList = false
        
        createToggleButton(contentFrame, "Hitbox Expander", hitboxEnabled, function(state)
            hitboxEnabled = state
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    applyHitboxToCharacter(p, p.Character)
                end
            end
        end)
        
        createSlider(contentFrame, "Hitbox Size", hitboxSize, 2, 1000, function(val)
            hitboxSize = val
            if hitboxEnabled then
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
        
        createSlider(contentFrame, "FOV Size", fovSize, 10, 300, function(val)
            fovSize = val
        end)
        
        createSlider(contentFrame, "Aim Smooth", math.floor(aimSmooth * 100), 1, 100, function(val)
            aimSmooth = val / 100
        end)
        
        createSlider(contentFrame, "Max Distance", math.min(aimMaxDistance, 1000000), 50, 1000000, function(val)
            aimMaxDistance = val
        end)
    end

    -- Misc Tab (Unchanged)
    local function showMisc()
        clearContent()
        setActiveTab("Misc")
        showingModelList = false
        
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
        
        createToggleButton(contentFrame, "Fly Mode", miscFlyEnabled, function(state)
            miscFlyEnabled = state
            if state then
                if flyConn then flyConn:Disconnect() end
                flyConn = RunService.RenderStepped:Connect(function()
                    local hrp = getHRP(LocalPlayer.Character)
                    if not hrp then return end
                    local cam = Camera
                    local move = Vector3.new()
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += cam.CFrame.UpVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= cam.CFrame.UpVector end
                    if move.Magnitude > 0 then
                        hrp.CFrame = hrp.CFrame + move.Unit * (miscFlySpeed/10)
                    end
                end)
            else
                if flyConn then flyConn:Disconnect() flyConn = nil end
            end
        end)
        
        createSlider(contentFrame, "Fly Speed", miscFlySpeed, 10, 200, function(val)
            miscFlySpeed = val
        end)
        
        createActionButton(contentFrame, "FPS Booster", function()
            local lighting = game:GetService("Lighting")
            lighting.GlobalShadows = false
            lighting.FogEnd = 1e9
            lighting.Brightness = 1
            for _,v in ipairs(lighting:GetChildren()) do
                if v:IsA("PostEffect") then v.Enabled = false end
            end
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 1
            end
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                    v.Enabled = false
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 1
                elseif v:IsA("MeshPart") then
                    v.RenderFidelity = Enum.RenderFidelity.Performance
                end
            end
        end)

        --------------------------------------------------------
        -- PLAYER INTERACTION SECTION (Teleport & Follow)
        --------------------------------------------------------
        
        local playerInteractionFrame = Instance.new("Frame")
        playerInteractionFrame.Size = UDim2.new(1, -16, 0, 190)
        playerInteractionFrame.BackgroundColor3 = Color3.fromRGB(50, 53, 72)
        playerInteractionFrame.BorderSizePixel = 0
        playerInteractionFrame.Parent = contentFrame
        createCorner(playerInteractionFrame, 6)
        createStroke(playerInteractionFrame, 1, Color3.fromRGB(80, 85, 130))
        
        local headerLabel = Instance.new("TextLabel")
        headerLabel.Size = UDim2.new(1, -16, 0, 16)
        headerLabel.Position = UDim2.new(0, 8, 0, 6)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text = "Target: " .. (currentTargetPlayer and currentTargetPlayer.Name or "None")
        headerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        headerLabel.Font = Enum.Font.GothamBold
        headerLabel.TextSize = 14
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.Parent = playerInteractionFrame

        -- ******* LIST PLAYER *******
        
        local playerList = Instance.new("ScrollingFrame")
        playerList.Size = UDim2.new(1, -16, 0, 100)
        playerList.Position = UDim2.new(0, 8, 0, 24)
        playerList.BackgroundTransparency = 0.8
        playerList.BackgroundColor3 = Color3.fromRGB(30, 33, 48)
        playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
        playerList.ScrollBarThickness = 4
        playerList.ScrollBarImageColor3 = Color3.fromRGB(100, 110, 180)
        playerList.Parent = playerInteractionFrame
        createCorner(playerList, 4)
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = playerList
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local function updatePlayerList()
            for _, child in ipairs(playerList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            local players = Players:GetPlayers()
            local listHeight = 0
            
            for _, player in ipairs(players) do
                if player ~= LocalPlayer and player.Character then
                    local button = Instance.new("TextButton")
                    button.Size = UDim2.new(1, 0, 0, 18)
                    button.BackgroundColor3 = (currentTargetPlayer == player) and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(50, 53, 72)
                    button.Text = player.Name .. ((currentTargetPlayer == player) and " (Selected)" or "")
                    button.TextColor3 = Color3.fromRGB(240, 242, 250)
                    button.Font = Enum.Font.GothamMedium
                    button.TextSize = 11
                    button.TextXAlignment = Enum.TextXAlignment.Left
                    button.AutoButtonColor = false
                    button.Parent = playerList
                    
                    local padding = Instance.new("UIPadding")
                    padding.PaddingLeft = UDim.new(0, 5)
                    padding.Parent = button

                    button.MouseButton1Click:Connect(function()
                        currentTargetPlayer = player
                        headerLabel.Text = "Target: " .. player.Name
                        updatePlayerList() 
                    end)
                    
                    listHeight = listHeight + 18 + 2
                end
            end
            
            playerList.CanvasSize = UDim2.new(0, 0, 0, listHeight)
        end
        
        updatePlayerList()
        Players.PlayerAdded:Connect(updatePlayerList)
        Players.PlayerRemoving:Connect(updatePlayerList)

        local tpButton = createButton(playerInteractionFrame, "Teleport to Target", 
        UDim2.new(0.48, 0, 0, 32), Color3.fromRGB(100, 150, 255), function()
            if currentTargetPlayer and currentTargetPlayer.Character and LocalPlayer.Character then
                local targetHRP = getHRP(currentTargetPlayer.Character)
                local localHRP = getHRP(LocalPlayer.Character)
                if targetHRP and localHRP then
                    local targetCFrame = targetHRP.CFrame * CFrame.new(0, 0, -5)
                    localHRP.CFrame = targetCFrame
                end
            else
                headerLabel.Text = "Target: (Select Target First!)"
            end
        end)
        tpButton.Position = UDim2.new(0, 8, 0, 134)
        
        local followButton = createButton(playerInteractionFrame, "Toggle Follow", 
        UDim2.new(0.48, 0, 0, 32), isFollowingPlayer and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(200, 100, 255), function()
            
            if not currentTargetPlayer then
                headerLabel.Text = "Target: (Select Target First!)"
                return
            end
            
            isFollowingPlayer = not isFollowingPlayer
            
            if isFollowingPlayer then
                followButton.BackgroundColor3 = Color3.fromRGB(150, 200, 255)
                followButton.Text = "Following: " .. currentTargetPlayer.Name
            else
                followButton.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
                followButton.Text = "Toggle Follow"
            end
            
            if isFollowingPlayer and currentTargetPlayer then
                local function startFollowLoop()
                    if followConnection then followConnection:Disconnect() end
                    
                    followConnection = RunService.Heartbeat:Connect(function(dt)
                        if not isFollowingPlayer or not currentTargetPlayer or not currentTargetPlayer.Character or not LocalPlayer.Character then
                            if followConnection then followConnection:Disconnect() end
                            isFollowingPlayer = false
                            followButton.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
                            followButton.Text = "Toggle Follow"
                            return
                        end

                        local targetHRP = getHRP(currentTargetPlayer.Character)
                        local localHRP = getHRP(LocalPlayer.Character)
                        
                        if not targetHRP or not localHRP then return end

                        local targetPos = targetHRP.Position
                        local currentPos = localHRP.Position
                        local direction = (targetPos - currentPos)
                        
                        if direction.Magnitude < 8 then
                            localHRP.Velocity = Vector3.new(0,0,0)
                        else
                            local normalizedDirection = direction.Unit
                            localHRP.CFrame = localHRP.CFrame + normalizedDirection * followSpeed * dt
                        end
                    end)
                end
                startFollowLoop()
            else
                if followConnection then 
                    followConnection:Disconnect() 
                    followConnection = nil
                end
            end
        end)
        followButton.Position = UDim2.new(0.52, 4, 0, 134)
        
        --------------------------------------------------------
    end

    -- ESP Model Tab (Unchanged)
    local function showModel()
        clearContent()
        setActiveTab("Model")
        
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
                                applyModelHighlight()
                                btn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
                                btn.Text = "✓ " .. obj.Name
                            else
                                tableRemoveValue(modelHighlightList, obj.Name)
                                for _,m in ipairs(findModelsByName(obj.Name)) do
                                    local hl = m:FindFirstChild("ModelHighlight")
                                    if hl then hl:Destroy() end
                                end
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
            createToggleButton(contentFrame, "ESP Model", espModelEnabled, function(state)
                espModelEnabled = state
                if state then
                    applyModelHighlight()
                else
                    for _,m in ipairs(workspace:GetDescendants()) do
                        if m:IsA("Model") then
                            local hl = m:FindFirstChild("ModelHighlight")
                            if hl then hl.Enabled = false end
                        end
                    end
                end
            end)
            
            createToggleButton(contentFrame, "Model Hitbox (NPC)", modelHitboxEnabled, function(state)
                modelHitboxEnabled = state
                for _,obj in ipairs(workspace:GetDescendants()) do
                    applyHitboxToModel(obj)
                end
            end)
            
            createSlider(contentFrame, "Model Hitbox Size", modelHitboxSize, 2, 20, function(val)
                modelHitboxSize = val
                if modelHitboxEnabled then
                    for _,obj in ipairs(workspace:GetDescendants()) do
                        applyHitboxToModel(obj)
                    end
                end
            end)
            
            createToggleButton(contentFrame, "ESP Text NPC", ESPTextEnabled, function(state)
                ESPTextEnabled = state
                if state then
                    if ESPTextConnection then ESPTextConnection:Disconnect() end
                    ESPTextConnection = RunService.Heartbeat:Connect(scanNPCModelsForText)
                else
                    if ESPTextConnection then ESPTextConnection:Disconnect() ESPTextConnection = nil end
                    for _, v in ipairs(workspace:GetDescendants()) do
                        if v:IsA("Model") and v:FindFirstChild("NameTag") then
                            v.NameTag:Destroy()
                        end
                    end
                end
            end)
            
            createActionButton(contentFrame, "List Models", function()
                showingModelList = true
                showModel()
            end)
        end
    end

    -- Create Tab Buttons
    local espBtn = createTabButton("ESP", "👁️")
    local combatBtn = createTabButton("Combat", "⚔️")
    local miscBtn = createTabButton("Misc", "🔧")
    local modelBtn = createTabButton("Model", "📦")

    espBtn.MouseButton1Click:Connect(showESP)
    combatBtn.MouseButton1Click:Connect(showCombat)
    miscBtn.MouseButton1Click:Connect(showMisc)
    modelBtn.MouseButton1Click:Connect(showModel)

    -- Show default tab
    showESP()
end

-- Init
for _,p in ipairs(Players:GetPlayers()) do setupPlayerConnections(p) end
Players.PlayerAdded:Connect(setupPlayerConnections)
Players.PlayerRemoving:Connect(function(p)
    -- Xóa tag text khi người chơi rời đi
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
    end
end)

-- Maintenance loop (Cập nhật Highlight/Hitbox/ESP Text nếu cần)
task.spawn(function()
    while true do
        task.wait(1.5)
        local esp_enabled = espNameEnabled or espHealthEnabled or espDistanceEnabled
        for _,p in ipairs(Players:GetPlayers()) do 
            if p.Character then
                -- Đảm bảo Highlight luôn được áp dụng nếu bật
                addPlayerHighlight(p) 
                applyHitboxToCharacter(p, p.Character)
                
                -- Đảm bảo ESP Text được tạo lại nếu vừa hồi sinh
                if esp_enabled and not playerTextTags[p] then
                    updatePlayerTextESP(p)
                end
            end
        end
        
        if espModelEnabled and #modelHighlightList > 0 then applyModelHighlight() end
        for _,obj in ipairs(workspace:GetDescendants()) do applyHitboxToModel(obj) end
    end
end)

-- Infinite jump (Unchanged)
UserInputService.JumpRequest:Connect(function()
    if miscInfiniteJump then
        local hum = getHumanoid(LocalPlayer.Character)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip (Unchanged)
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

-- FOV + Aimbot loop (Unchanged)
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

-- Create UI
createMenu()
print("✅ Modern Utility Menu loaded successfully! (ESP Name/Health/Distance and Highlight Fixes Applied)")
