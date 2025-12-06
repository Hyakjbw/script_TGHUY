-- Full Utility Menu Script
-- Features: ESP Player, Combat Hitbox, FOV/Aimbot, ESP Text NPC, ESP Model (on-demand list), Misc (Fly)
-- Fixes: Tab Misc opens, Fly works, Model Hitbox excludes players + resets on toggle, adjustable Model Hitbox size,
--        Model list created on demand and does not overlap other UI.

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- Global states
local menuVisible = true

-- ESP players
local highlightEnabled = false
local highlightColor = Color3.fromRGB(0, 255, 128)

-- Combat
local hitboxEnabled = false
local hitboxSize = 6

-- Aimbot/FOV
local fovEnabled = false
local fovSize = 120
local aimSmooth = 0.25
local stickyTarget = nil
local fovCircle = nil
local hue = 0

-- Misc
local miscInfiniteJump = false
local miscNoclip = false
local miscSpeedEnabled = false
local miscSpeedValue = 24
local originalWalkSpeed = 16
local miscFlyFollowEnabled = false
local miscTargetName = ""
local miscTargetPlayer = nil

-- Fly (camera-direction)
local miscFlyEnabled = false
local miscFlySpeed = 60
local flyConn = nil

-- ESP Model
local espModelEnabled = true
local modelHighlightList = {}
local modelListFrameRef = nil -- reference to on-demand list panel

-- ESP Text NPC
local ESPTextEnabled = false
local ESPTextConnection = nil

-- Model Hitbox (NPC only)
local modelHitboxEnabled = false
local modelHitboxSize = 6

-- Helpers
local function getHumanoid(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHead(c) return c and (c:FindFirstChild("Head") or c:FindFirstChildWhichIsA("BasePart")) end
local function isAlive(p) return p and p~=LocalPlayer and p.Character and getHumanoid(p.Character) and getHumanoid(p.Character).Health>0 end
local function tableContains(t,v) for _,x in ipairs(t) do if x==v then return true end end return false end
local function tableRemoveValue(t,v) for i=#t,1,-1 do if t[i]==v then table.remove(t,i) return true end end return false end

-- Player ESP
local function addPlayerHighlight(p)
    if not p or p==LocalPlayer or not p.Character then return end
    local hl = p.Character:FindFirstChild("PlayerHighlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "PlayerHighlight"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = p.Character
    end
    hl.Enabled = highlightEnabled
    hl.FillColor = highlightColor
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.55
    hl.OutlineTransparency = 0.05
end

local function setupPlayerConnections(p)
    if not p or p==LocalPlayer then return end
    p.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        addPlayerHighlight(p)
        if hitboxEnabled then
            local hrp = getHRP(char)
            if hrp then
                hrp.Size = Vector3.new(hitboxSize,hitboxSize,hitboxSize)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            end
        end
    end)
    if p.Character then
        addPlayerHighlight(p)
        if hitboxEnabled then
            local hrp = getHRP(p.Character)
            if hrp then
                hrp.Size = Vector3.new(hitboxSize,hitboxSize,hitboxSize)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            end
        end
    end
end

-- Combat Hitbox (players)
local function applyHitboxToCharacter(p,c)
    if not p or p==LocalPlayer or not c then return end
    local hrp = getHRP(c)
    if hrp then
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
end

-- Model ESP
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

-- Model Hitbox (NPC only)
local function applyHitboxToModel(model)
    if not model or not model:IsA("Model") then return end
    if Players:GetPlayerFromCharacter(model) then return end -- exclude players
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

-- ESP Text NPC
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
            local head = getHead(plr.Character)
            if head then
                local wp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(wp.X, wp.Y) - Vector2.new(center.X, center.Y)).Magnitude
                    if dist < bestDist and dist <= fovSize then bestDist = dist best = plr end
                end
            end
        end
    end
    return best
end

-- Fly toggle (camera-direction)
local miscFlyEnabled = false
local miscFlySpeed = 60
local flyConn = nil

local function toggleFly()
    miscFlyEnabled = not miscFlyEnabled
    if miscFlyEnabled then
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
end

-- UI Helpers
local function createUICorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeSidebarButton(parent, text, order)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.Position = UDim2.new(0, 8, 0, (order - 1) * 36)
    btn.BackgroundColor3 = Color3.fromRGB(50, 54, 78)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(230, 230, 235)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    createUICorner(btn, 10)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(70, 74, 105)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(50, 54, 78)}):Play()
    end)
    return btn
end

local function makeButton(parent, text)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -12, 0, 32)
    btn.Position = UDim2.new(0, 6, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(60, 62, 90)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.AutoButtonColor = false
    createUICorner(btn, 10)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(82, 85, 120)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 62, 90)}):Play()
    end)
    return btn
end

local function makeSmallButton(parent, text, color)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 148, 0, 30)
    btn.BackgroundColor3 = color or Color3.fromRGB(80, 82, 110)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.AutoButtonColor = false
    createUICorner(btn, 8)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = (color or Color3.fromRGB(95, 97, 130))}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = (color or Color3.fromRGB(80, 82, 110))}):Play()
    end)
    return btn
end

local function makeGroup(parent, titleText, height)
    local group = Instance.new("Frame", parent)
    group.Size = UDim2.new(1, -12, 0, height or 110)
    group.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", group)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = titleText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left

    local gridContainer = Instance.new("Frame", group)
    gridContainer.Size = UDim2.new(1, 0, 1, -24)
    gridContainer.Position = UDim2.new(0, 0, 0, 24)
    gridContainer.BackgroundTransparency = 1

    local grid = Instance.new("UIGridLayout", gridContainer)
    grid.CellSize = UDim2.new(0, 148, 0, 30)
    grid.CellPadding = UDim2.new(0, 6, 0, 6)
    grid.FillDirectionMaxCells = 2

    return group, gridContainer
end

-- Build menu
local function createMenu()
    if CoreGui:FindFirstChild("UtilityMenu") then CoreGui.UtilityMenu:Destroy() end

    local screenGui = Instance.new("ScreenGui", CoreGui)
    screenGui.Name = "UtilityMenu"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local toggleBtn = Instance.new("TextButton", screenGui)
    toggleBtn.Size = UDim2.new(0, 36, 0, 36)
    toggleBtn.Position = UDim2.new(0.02, 0, 0.06, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 45)
    toggleBtn.Text = "☰"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 18
    toggleBtn.Draggable = true
    createUICorner(toggleBtn, 12)

    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 390, 0, 300)
    mainFrame.Position = UDim2.new(0.06, 0, 0.14, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    createUICorner(mainFrame, 12)
    local strokeMain = Instance.new("UIStroke", mainFrame)
    strokeMain.Thickness = 1.6
    strokeMain.Color = Color3.fromRGB(85, 90, 140)

    toggleBtn.MouseButton1Click:Connect(function()
        menuVisible = not menuVisible
        mainFrame.Visible = menuVisible
    end)

    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(34, 37, 54)
    header.BorderSizePixel = 0
    createUICorner(header, 12)

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -16, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Utility Menu"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    local sidebar = Instance.new("Frame", mainFrame)
    sidebar.Size = UDim2.new(0, 120, 1, -44)
    sidebar.Position = UDim2.new(0, 0, 0, 44)
    sidebar.BackgroundColor3 = Color3.fromRGB(28, 30, 44)
    sidebar.BorderSizePixel = 0
    createUICorner(sidebar, 12)
    local strokeSidebar = Instance.new("UIStroke", sidebar)
    strokeSidebar.Thickness = 1.2
    strokeSidebar.Color = Color3.fromRGB(70, 75, 120)

    local content = Instance.new("ScrollingFrame", mainFrame)
    content.Size = UDim2.new(1, -136, 1, -44)
    content.Position = UDim2.new(0, 128, 0, 44)
    content.BackgroundColor3 = Color3.fromRGB(24, 26, 38)
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 6
    content.AutomaticCanvasSize = Enum.AutomaticSize.None
    content.CanvasSize = UDim2.new(0, 0, 0, 2400)
    createUICorner(content, 12)

    local padContent = Instance.new("UIPadding", content)
    padContent.PaddingTop = UDim.new(0, 8)
    padContent.PaddingLeft = UDim.new(0, 8)
    padContent.PaddingRight = UDim.new(0, 8)
    padContent.PaddingBottom = UDim.new(0, 8)

    local listContent = Instance.new("UIListLayout", content)
    listContent.Padding = UDim.new(0, 8)
    listContent.FillDirection = Enum.FillDirection.Vertical
    listContent.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listContent.SortOrder = Enum.SortOrder.LayoutOrder

    local function clearContent()
        for _,c in ipairs(content:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        modelListFrameRef = nil
    end

    local function makePane(titleText)
        local pane = Instance.new("Frame", content)
        pane.Size = UDim2.new(1, -12, 0, 0)
        pane.BackgroundColor3 = Color3.fromRGB(32, 34, 48)
        pane.BorderSizePixel = 0
        pane.LayoutOrder = #content:GetChildren() + 1
        createUICorner(pane, 10)
        local stroke = Instance.new("UIStroke", pane); stroke.Thickness = 1; stroke.Color = Color3.fromRGB(80, 85, 130)
        local list = Instance.new("UIListLayout", pane); list.Padding = UDim.new(0, 8); list.FillDirection = Enum.FillDirection.Vertical; list.SortOrder = Enum.SortOrder.LayoutOrder
        local headerPane = Instance.new("TextLabel", pane)
        headerPane.Size = UDim2.new(1, -12, 0, 24); headerPane.Position = UDim2.new(0, 6, 0, 6)
        headerPane.BackgroundTransparency = 1; headerPane.Text = titleText; headerPane.TextColor3 = Color3.fromRGB(235, 235, 245)
        headerPane.Font = Enum.Font.GothamBold; headerPane.TextSize = 14; headerPane.TextXAlignment = Enum.TextXAlignment.Left
        return pane
    end

    -- ESP Tab
    local function showESP()
        clearContent()
        local pane = makePane("ESP")

        local hlBtn = makeButton(pane, "Highlight players: " .. (highlightEnabled and "ON" or "OFF"))
        hlBtn.MouseButton1Click:Connect(function()
            highlightEnabled = not highlightEnabled
            hlBtn.Text = "Highlight players: " .. (highlightEnabled and "ON" or "OFF")
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then addPlayerHighlight(p) end
            end
        end)

        local colorGroup, colorGrid = makeGroup(pane, "ESP color", 110)
        local c1 = makeSmallButton(colorGrid, "Green", Color3.fromRGB(0, 255, 128))
        local c2 = makeSmallButton(colorGrid, "Red", Color3.fromRGB(255, 64, 64))
        local c3 = makeSmallButton(colorGrid, "Blue", Color3.fromRGB(64, 128, 255))
        local c4 = makeSmallButton(colorGrid, "Yellow", Color3.fromRGB(255, 225, 64))
        c1.MouseButton1Click:Connect(function() highlightColor = Color3.fromRGB(0, 255, 128); for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then addPlayerHighlight(p) end end end)
        c2.MouseButton1Click:Connect(function() highlightColor = Color3.fromRGB(255, 64, 64); for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then addPlayerHighlight(p) end end end)
        c3.MouseButton1Click:Connect(function() highlightColor = Color3.fromRGB(64, 128, 255); for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then addPlayerHighlight(p) end end end)
        c4.MouseButton1Click:Connect(function() highlightColor = Color3.fromRGB(255, 225, 64); for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then addPlayerHighlight(p) end end end)
    end

    -- Combat Tab
    local function showCombat()
        clearContent()
        local pane = makePane("Combat")

        local hitboxBtn = makeButton(pane, "Hitbox: " .. (hitboxEnabled and "ON" or "OFF"))
        hitboxBtn.MouseButton1Click:Connect(function()
            hitboxEnabled = not hitboxEnabled
            hitboxBtn.Text = "Hitbox: " .. (hitboxEnabled and "ON" or "OFF")
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then applyHitboxToCharacter(p, p.Character) end
            end
        end)

        local hitboxGroup, hitboxGrid = makeGroup(pane, "Hitbox size: " .. tostring(hitboxSize), 110)
        local sizePlus = makeSmallButton(hitboxGrid, "Size +")
        local sizeMinus = makeSmallButton(hitboxGrid, "Size -")
        sizePlus.MouseButton1Click:Connect(function()
            hitboxSize = hitboxSize + 2
            hitboxGroup:FindFirstChildOfClass("TextLabel").Text = "Hitbox size: " .. tostring(hitboxSize)
            if hitboxEnabled then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then applyHitboxToCharacter(p, p.Character) end end end
        end)
        sizeMinus.MouseButton1Click:Connect(function()
            hitboxSize = math.max(2, hitboxSize - 2)
            hitboxGroup:FindFirstChildOfClass("TextLabel").Text = "Hitbox size: " .. tostring(hitboxSize)
            if hitboxEnabled then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then applyHitboxToCharacter(p, p.Character) end end end
        end)

        -- FOV + Aimbot toggle
        local fovBtn = makeButton(pane, "FOV + Aimbot: " .. (fovEnabled and "ON" or "OFF"))
        fovBtn.MouseButton1Click:Connect(function()
            fovEnabled = not fovEnabled
            stickyTarget = nil
            fovBtn.Text = "FOV + Aimbot: " .. (fovEnabled and "ON" or "OFF")
        end)

        -- FOV size adjust
        local fovGroup, fovGrid = makeGroup(pane, "FOV size: " .. tostring(fovSize), 110)
        local fovPlus = makeSmallButton(fovGrid, "FOV +")
        local fovMinus = makeSmallButton(fovGrid, "FOV -")
        fovPlus.MouseButton1Click:Connect(function()
            fovSize = fovSize + 10
            fovGroup:FindFirstChildOfClass("TextLabel").Text = "FOV size: " .. tostring(fovSize)
        end)
        fovMinus.MouseButton1Click:Connect(function()
            fovSize = math.max(10, fovSize - 10)
            fovGroup:FindFirstChildOfClass("TextLabel").Text = "FOV size: " .. tostring(fovSize)
        end)

        -- Aim smooth adjust
        local smoothGroup, smoothGrid = makeGroup(pane, ("Aim smooth: %.2f"):format(aimSmooth), 110)
        local smoothPlus = makeSmallButton(smoothGrid, "Smooth +")
        local smoothMinus = makeSmallButton(smoothGrid, "Smooth -")
        smoothPlus.MouseButton1Click:Connect(function()
            aimSmooth = math.min(0.6, aimSmooth + 0.05)
            smoothGroup:FindFirstChildOfClass("TextLabel").Text = ("Aim smooth: %.2f"):format(aimSmooth)
        end)
        smoothMinus.MouseButton1Click:Connect(function()
            aimSmooth = math.max(0.05, aimSmooth - 0.05)
            smoothGroup:FindFirstChildOfClass("TextLabel").Text = ("Aim smooth: %.2f"):format(aimSmooth)
        end)
    end

    -- Misc Tab (fixed)
    local function showMisc()
        clearContent()
        local pane = makePane("Misc")

        -- Infinite Jump
        local ijBtn = makeButton(pane, "Infinite Jump: " .. (miscInfiniteJump and "ON" or "OFF"))
        ijBtn.MouseButton1Click:Connect(function()
            miscInfiniteJump = not miscInfiniteJump
            ijBtn.Text = "Infinite Jump: " .. (miscInfiniteJump and "ON" or "OFF")
        end)

        -- Noclip
        local noclipBtn = makeButton(pane, "Noclip: " .. (miscNoclip and "ON" or "OFF"))
        noclipBtn.MouseButton1Click:Connect(function()
            miscNoclip = not miscNoclip
            noclipBtn.Text = "Noclip: " .. (miscNoclip and "ON" or "OFF")
        end)

        -- Speed
        local speedGroup, speedGrid = makeGroup(pane, "Run speed: " .. tostring(miscSpeedValue), 110)
        local speedToggle = makeSmallButton(speedGrid, "Speed: " .. (miscSpeedEnabled and "ON" or "OFF"))
        local speedPlus = makeSmallButton(speedGrid, "Speed +")
        local speedMinus = makeSmallButton(speedGrid, "Speed -")
        speedToggle.MouseButton1Click:Connect(function()
            miscSpeedEnabled = not miscSpeedEnabled
            speedToggle.Text = "Speed: " .. (miscSpeedEnabled and "ON" or "OFF")
            local hum = getHumanoid(LocalPlayer.Character)
            if hum then
                if miscSpeedEnabled then
                    originalWalkSpeed = hum.WalkSpeed or originalWalkSpeed
                    hum.WalkSpeed = miscSpeedValue
                else
                    hum.WalkSpeed = originalWalkSpeed
                end
            end
        end)
        speedPlus.MouseButton1Click:Connect(function()
            miscSpeedValue = miscSpeedValue + 2
            speedGroup:FindFirstChildOfClass("TextLabel").Text = "Run speed: " .. tostring(miscSpeedValue)
            local hum = getHumanoid(LocalPlayer.Character)
            if hum and miscSpeedEnabled then hum.WalkSpeed = miscSpeedValue end
        end)
        speedMinus.MouseButton1Click:Connect(function()
            miscSpeedValue = math.max(8, miscSpeedValue - 2)
            speedGroup:FindFirstChildOfClass("TextLabel").Text = "Run speed: " .. tostring(miscSpeedValue)
            local hum = getHumanoid(LocalPlayer.Character)
            if hum and miscSpeedEnabled then hum.WalkSpeed = miscSpeedValue end
        end)

        -- Fly toggle (fixed)
        local flyBtn = makeButton(pane, "Fly: " .. (miscFlyEnabled and "ON" or "OFF"))
        flyBtn.MouseButton1Click:Connect(function()
            toggleFly()
            flyBtn.Text = "Fly: " .. (miscFlyEnabled and "ON" or "OFF")
        end)

        -- Fly speed
        local flyGroup, flyGrid = makeGroup(pane, "Fly speed: " .. tostring(miscFlySpeed), 110)
        local flyPlus = makeSmallButton(flyGrid, "Speed +")
        local flyMinus = makeSmallButton(flyGrid, "Speed -")
        flyPlus.MouseButton1Click:Connect(function()
            miscFlySpeed = miscFlySpeed + 10
            flyGroup:FindFirstChildOfClass("TextLabel").Text = "Fly speed: " .. tostring(miscFlySpeed)
        end)
        flyMinus.MouseButton1Click:Connect(function()
            miscFlySpeed = math.max(10, miscFlySpeed - 10)
            flyGroup:FindFirstChildOfClass("TextLabel").Text = "Fly speed: " .. tostring(miscFlySpeed)
        end)
    end

    -- ESP Model Tab (toggles + on-demand list)
    local function showModelESP()
        clearContent()
        local pane = makePane("ESP Model")

        local toggleModelESP = makeButton(pane, "ESP Model: " .. (espModelEnabled and "ON" or "OFF"))
        toggleModelESP.MouseButton1Click:Connect(function()
            espModelEnabled = not espModelEnabled
            toggleModelESP.Text = "ESP Model: " .. (espModelEnabled and "ON" or "OFF")
            if espModelEnabled then applyModelHighlight() else
                for _,m in ipairs(workspace:GetDescendants()) do
                    if m:IsA("Model") then
                        local hl=m:FindFirstChild("ModelHighlight")
                        if hl then hl.Enabled=false end
                    end
                end
            end
        end)

        local mhBtn = makeButton(pane, "Model Hitbox (NPC): " .. (modelHitboxEnabled and "ON" or "OFF"))
        mhBtn.MouseButton1Click:Connect(function()
            modelHitboxEnabled = not modelHitboxEnabled
            mhBtn.Text = "Model Hitbox (NPC): " .. (modelHitboxEnabled and "ON" or "OFF")
            for _,obj in ipairs(workspace:GetDescendants()) do applyHitboxToModel(obj) end
        end)

        local mhGroup, mhGrid = makeGroup(pane, "Model Hitbox size: " .. tostring(modelHitboxSize), 110)
        local mhPlus = makeSmallButton(mhGrid, "Size +")
        local mhMinus = makeSmallButton(mhGrid, "Size -")
        mhPlus.MouseButton1Click:Connect(function()
            modelHitboxSize = modelHitboxSize + 2
            mhGroup:FindFirstChildOfClass("TextLabel").Text = "Model Hitbox size: " .. tostring(modelHitboxSize)
            if modelHitboxEnabled then for _,obj in ipairs(workspace:GetDescendants()) do applyHitboxToModel(obj) end end
        end)
        mhMinus.MouseButton1Click:Connect(function()
            modelHitboxSize = math.max(2, modelHitboxSize - 2)
            mhGroup:FindFirstChildOfClass("TextLabel").Text = "Model Hitbox size: " .. tostring(modelHitboxSize)
            if modelHitboxEnabled then for _,obj in ipairs(workspace:GetDescendants()) do applyHitboxToModel(obj) end end
        end)

        local espTextBtn = makeButton(pane, "ESP Text NPC: " .. (ESPTextEnabled and "ON" or "OFF"))
        espTextBtn.MouseButton1Click:Connect(function()
            ESPTextEnabled = not ESPTextEnabled
            espTextBtn.Text = "ESP Text NPC: " .. (ESPTextEnabled and "ON" or "OFF")
            if ESPTextEnabled then
                if ESPTextConnection then ESPTextConnection:Disconnect() end
                ESPTextConnection = RunService.Heartbeat:Connect(scanNPCModelsForText)
            else
                if ESPTextConnection then ESPTextConnection:Disconnect() ESPTextConnection = nil end
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("Model") and v:FindFirstChild("NameTag") then v.NameTag:Destroy() end
                end
            end
        end)

        local listBtn = makeButton(pane, "List Models")
        listBtn.MouseButton1Click:Connect(function()
            if modelListFrameRef and modelListFrameRef.Parent == pane then
                modelListFrameRef:Destroy()
                modelListFrameRef = nil
            end

            local listLabel = Instance.new("TextLabel", pane)
            listLabel.Size = UDim2.new(1, -12, 0, 22)
            listLabel.BackgroundTransparency = 1
            listLabel.Text = "Danh sách model (bấm dòng để Add/Remove ESP)"
            listLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
            listLabel.Font = Enum.Font.Gotham
            listLabel.TextSize = 12
            listLabel.TextXAlignment = Enum.TextXAlignment.Left

            local listFrame = Instance.new("Frame", pane)
            listFrame.Size = UDim2.new(1, -12, 0, 180)
            listFrame.BackgroundColor3 = Color3.fromRGB(26, 28, 40)
            listFrame.BorderSizePixel = 0
            createUICorner(listFrame, 10)
            local listStroke = Instance.new("UIStroke", listFrame)
            listStroke.Thickness = 1
            listStroke.Color = Color3.fromRGB(70, 75, 120)
            modelListFrameRef = listFrame

            local listScroll = Instance.new("ScrollingFrame", listFrame)
            listScroll.Size = UDim2.new(1, -10, 1, -10)
            listScroll.Position = UDim2.new(0, 5, 0, 5)
            listScroll.BackgroundTransparency = 1
            listScroll.ScrollBarThickness = 6
            listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            local listLayout = Instance.new("UIListLayout", listScroll)
            listLayout.Padding = UDim.new(0, 4)
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local seen = {}
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                    if not seen[obj.Name] then
                        seen[obj.Name] = true
                        local row = Instance.new("TextButton", listScroll)
                        row.Size = UDim2.new(1, -8, 0, 28)
                        row.BackgroundColor3 = Color3.fromRGB(34, 36, 52)
                        row.Text = tableContains(modelHighlightList, obj.Name) and ("Remove ESP: "..obj.Name) or ("Add ESP: "..obj.Name)
                        row.TextColor3 = Color3.fromRGB(230, 230, 240)
                        row.Font = Enum.Font.Gotham
                        row.TextSize = 12
                        row.AutoButtonColor = false
                        createUICorner(row, 8)
                        row.MouseButton1Click:Connect(function()
                            if not tableContains(modelHighlightList, obj.Name) then
                                table.insert(modelHighlightList, obj.Name)
                                applyModelHighlight()
                                row.Text = "Remove ESP: "..obj.Name
                            else
                                tableRemoveValue(modelHighlightList, obj.Name)
                                for _,m in ipairs(findModelsByName(obj.Name)) do
                                    local hl=m:FindFirstChild("ModelHighlight")
                                    if hl then hl:Destroy() end
                                end
                                row.Text = "Add ESP: "..obj.Name
                            end
                        end)
                    end
                end
            end
        end)
    end

    -- Sidebar buttons
    local espBtn = makeSidebarButton(sidebar, "ESP", 1)
    local combatBtn = makeSidebarButton(sidebar, "Combat", 2)
    local miscBtn = makeSidebarButton(sidebar, "Misc", 3)
    local modelBtn = makeSidebarButton(sidebar, "ESP Model", 4)

    espBtn.MouseButton1Click:Connect(showESP)
    combatBtn.MouseButton1Click:Connect(showCombat)
    miscBtn.MouseButton1Click:Connect(showMisc)
    modelBtn.MouseButton1Click:Connect(showModelESP)

    -- default
    showESP()
end

-- Init
for _,p in ipairs(Players:GetPlayers()) do setupPlayerConnections(p) end
Players.PlayerAdded:Connect(setupPlayerConnections)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    local hum = getHumanoid(char)
    if hum then
        if miscSpeedEnabled then hum.WalkSpeed = miscSpeedValue else hum.WalkSpeed = originalWalkSpeed end
    end
end)

-- Optimized maintenance every 2s
task.spawn(function()
    while true do
        task.wait(2)
        if highlightEnabled then for _,p in ipairs(Players:GetPlayers()) do addPlayerHighlight(p) end end
        if hitboxEnabled then for _,p in ipairs(Players:GetPlayers()) do applyHitboxToCharacter(p, p.Character) end end
        if espModelEnabled and #modelHighlightList > 0 then applyModelHighlight() end
        for _,obj in ipairs(workspace:GetDescendants()) do applyHitboxToModel(obj) end -- respects modelHitboxEnabled internally
    end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if miscInfiniteJump then local hum=getHumanoid(LocalPlayer.Character) if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if miscNoclip then
        local char = LocalPlayer.Character
        if char then for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end end
    end
end)

-- Fly follow
RunService.RenderStepped:Connect(function()
    if miscFlyFollowEnabled and miscTargetPlayer and miscTargetPlayer.Character then
        local myHRP = getHRP(LocalPlayer.Character)
        local targetHRP = getHRP(miscTargetPlayer.Character)
        if myHRP and targetHRP then
            local targetPos = targetHRP.Position + Vector3.new(0, 4, 0)
            myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.new(targetPos, targetPos + Camera.CFrame.LookVector), 0.18)
        end
    end
end)

-- FOV + Aimbot loop
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
                local dist = (Vector2.new(wp.X, wp.Y) - Vector2.new(center.X, center.Y)).Magnitude
                if (not onScreen) or dist > fovSize then stickyTarget = getClosestTargetInFOV() end
            else
                stickyTarget = getClosestTargetInFOV()
            end
        end

        if stickyTarget and isAlive(stickyTarget) then
            local head = getHead(stickyTarget.Character)
            if head then
                local current = Camera.CFrame
                local target = CFrame.new(current.Position, head.Position)
                Camera.CFrame = current:Lerp(target, math.clamp(aimSmooth, 0.05, 0.6))
            end
        end
    else
        stickyTarget = nil
    end
end)

-- Create UI
createMenu()
