-- Utility Menu - FULL SCRIPT (Mobile-friendly, Speed Hub style)
-- Use long scrollbar: CanvasSize set super long to ensure scrolling works on mobile.
-- Tabs: ESP (players), Combat, Misc (Infinite Jump, Noclip, Speed, Teleport to player with autocomplete, Fly follow, ESP Model Highlight with list/add/remove)

-- =======================
-- Services
-- =======================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- =======================
-- States
-- =======================
local menuVisible = true

-- ESP (players)
local highlightEnabled = false
local highlightColor = Color3.fromRGB(0,255,128)

-- Combat
local hitboxEnabled = false
local hitboxSize = 6
local fovEnabled = false
local fovSize = 120
local aimSmooth = 0.25
local stickyTarget = nil
local maxTargetDistance = 500
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

-- ESP Model Highlight (separate from players)
local espModelEnabled = true
local modelHighlightList = {} -- list of model names to highlight

-- =======================
-- Helpers
-- =======================
local function getHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid") or nil
end

local function isAlive(plr)
    if not plr or plr == LocalPlayer then return false end
    local char = plr.Character
    local hum = char and getHumanoid(char)
    return hum and hum.Health and hum.Health > 0
end

local function getHead(character)
    return character and (character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")) or nil
end

local function getHRP(character)
    return character and character:FindFirstChild("HumanoidRootPart") or nil
end

local function findPlayerByPartialName(partial)
    if not partial or partial == "" then return nil end
    partial = string.lower(partial)
    local bestMatch, bestLen = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        local nameLower = string.lower(p.Name)
        if string.find(nameLower, partial, 1, true) then
            if #nameLower < bestLen then
                bestMatch, bestLen = p, #nameLower
            end
        end
    end
    return bestMatch
end

-- =======================
-- ESP players
-- =======================
local function addHighlight(plr, character)
    if not plr or plr == LocalPlayer then return end
    if not character then return end
    local hl = character:FindFirstChild("PlayerHighlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "PlayerHighlight"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = character
    end
    hl.Enabled = highlightEnabled
    hl.FillColor = highlightColor
    hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.FillTransparency = 0.55
    hl.OutlineTransparency = 0.05
end

-- =======================
-- Combat: Hitbox
-- =======================
local function applyHitbox(plr, character)
    if not plr or plr == LocalPlayer then return end
    if not character then return end
    local function setHRP(hrp)
        if not hrp then return end
        if hitboxEnabled then
            hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            hrp.Transparency = 0.7
            hrp.CanCollide = false
        else
            hrp.Size = Vector3.new(2,2,1)
            hrp.Transparency = 1
            hrp.CanCollide = true
        end
    end
    local hrp = getHRP(character)
    setHRP(hrp)
    character.ChildAdded:Connect(function(child)
        if child.Name == "HumanoidRootPart" and child:IsA("BasePart") then
            setHRP(child)
        end
    end)
end

-- =======================
-- Wire players
-- =======================
local function setupPlayer(plr)
    if not plr or plr == LocalPlayer then return end
    plr.CharacterAdded:Connect(function(char)
        addHighlight(plr, char)
        applyHitbox(plr, char)
    end)
    if plr.Character then
        addHighlight(plr, plr.Character)
        applyHitbox(plr, plr.Character)
    end
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.4)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            addHighlight(plr, plr.Character)
            applyHitbox(plr, plr.Character)
        end
    end
    local hum = getHumanoid(char)
    if hum then originalWalkSpeed = hum.WalkSpeed end
end)

task.spawn(function()
    while true do
        task.wait(0.6)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if highlightEnabled then addHighlight(plr, plr.Character) end
                if hitboxEnabled then applyHitbox(plr, plr.Character) end
            end
        end
        if stickyTarget and not isAlive(stickyTarget) then stickyTarget = nil end
    end
end)

-- =======================
-- ESP Model Highlight
-- =======================
local function applyModelHighlight()
    if not espModelEnabled then return end
    for _, name in ipairs(modelHighlightList) do
        local model = workspace:FindFirstChild(name)
        if model and model:IsA("Model") then
            local hl = model:FindFirstChild("ModelHighlight")
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "ModelHighlight"
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillColor = Color3.fromRGB(255,200,0)
                hl.OutlineColor = Color3.fromRGB(255,255,255)
                hl.FillTransparency = 0.55
                hl.OutlineTransparency = 0.05
                hl.Parent = model
            else
                hl.Enabled = true
            end
        end
    end
end

local function listAllModels()
    print("=== Danh sách Model trong game ===")
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") then
            print(obj.Name)
        end
    end
end

RunService.Stepped:Connect(function()
    applyModelHighlight()
end)

-- =======================
-- UI (mobile-friendly)
-- =======================
local function createMenu()
    if CoreGui:FindFirstChild("CustomMenu") then CoreGui.CustomMenu:Destroy() end

    local screenGui = Instance.new("ScreenGui", CoreGui)
    screenGui.Name = "CustomMenu"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    -- Toggle button (floating)
    local toggleBtn = Instance.new("TextButton", screenGui)
    toggleBtn.Size = UDim2.new(0,36,0,36)
    toggleBtn.Position = UDim2.new(0.02,0,0.06,0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(30,32,45)
    toggleBtn.Text = "☰"
    toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 18
    toggleBtn.Draggable = true
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,12)

    -- Main frame (compact for mobile)
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0,360,0,260)
    mainFrame.Position = UDim2.new(0.06,0,0.14,0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(22,24,34)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)
    local strokeMain = Instance.new("UIStroke", mainFrame)
    strokeMain.Thickness = 1.6
    strokeMain.Color = Color3.fromRGB(85,90,140)

    toggleBtn.MouseButton1Click:Connect(function()
        menuVisible = not menuVisible
        mainFrame.Visible = menuVisible
    end)

    -- Header
    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1,0,0,36)
    header.BackgroundColor3 = Color3.fromRGB(34,37,54)
    header.BorderSizePixel = 0
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,12)

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1,-16,1,0)
    title.Position = UDim2.new(0,8,0,0)
    title.BackgroundTransparency = 1
    title.Text = "Utility Menu"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Sidebar (narrow)
    local sidebar = Instance.new("Frame", mainFrame)
    sidebar.Size = UDim2.new(0,110,1,-44)
    sidebar.Position = UDim2.new(0,0,0,44)
    sidebar.BackgroundColor3 = Color3.fromRGB(28,30,44)
    sidebar.BorderSizePixel = 0
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,12)
    local strokeSidebar = Instance.new("UIStroke", sidebar)
    strokeSidebar.Thickness = 1.2
    strokeSidebar.Color = Color3.fromRGB(70,75,120)

    -- Content (ScrollingFrame, long CanvasSize to force scrollbar)
    local content = Instance.new("ScrollingFrame", mainFrame)
    content.Size = UDim2.new(1,-126,1,-44)
    content.Position = UDim2.new(0,118,0,44)
    content.BackgroundColor3 = Color3.fromRGB(24,26,38)
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 6
    content.ScrollingEnabled = true
    content.ScrollBarImageTransparency = 0
    content.ScrollBarImageColor3 = Color3.fromRGB(120,120,140)
    content.AutomaticCanvasSize = Enum.AutomaticSize.None
    content.CanvasSize = UDim2.new(0,0,0,2400) -- super long for reliable scrollbar on mobile
    Instance.new("UICorner", content).CornerRadius = UDim.new(0,12)

    local padContent = Instance.new("UIPadding", content)
    padContent.PaddingTop = UDim.new(0,8)
    padContent.PaddingLeft = UDim.new(0,8)
    padContent.PaddingRight = UDim.new(0,8)
    padContent.PaddingBottom = UDim.new(0,8)

    local listContent = Instance.new("UIListLayout", content)
    listContent.Padding = UDim.new(0,8)
    listContent.FillDirection = Enum.FillDirection.Vertical
    listContent.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listContent.SortOrder = Enum.SortOrder.LayoutOrder

    local function makeSidebarButton(text, order)
        local btn = Instance.new("TextButton", sidebar)
        btn.Size = UDim2.new(1,-16,0,32)
        btn.Position = UDim2.new(0,8,0,(order-1)*36)
        btn.BackgroundColor3 = Color3.fromRGB(50,54,78)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(230,230,235)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(70,74,105)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(50,54,78)}):Play()
        end)
        return btn
    end

    local function clearContent()
        for _, c in ipairs(content:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
    end

    local function makePane(titleText)
        local pane = Instance.new("Frame", content)
        pane.Size = UDim2.new(1,-12,0,0)
        pane.BackgroundColor3 = Color3.fromRGB(32,34,48)
        pane.BorderSizePixel = 0
        pane.LayoutOrder = #content:GetChildren()+1
        Instance.new("UICorner", pane).CornerRadius = UDim.new(0,10)
        local stroke = Instance.new("UIStroke", pane)
        stroke.Thickness = 1
        stroke.Color = Color3.fromRGB(80,85,130)

        local list = Instance.new("UIListLayout", pane)
        list.Padding = UDim.new(0,8)
        list.FillDirection = Enum.FillDirection.Vertical
        list.SortOrder = Enum.SortOrder.LayoutOrder

        local headerPane = Instance.new("TextLabel", pane)
        headerPane.Size = UDim2.new(1,-12,0,24)
        headerPane.Position = UDim2.new(0,6,0,6)
        headerPane.BackgroundTransparency = 1
        headerPane.Text = titleText
        headerPane.TextColor3 = Color3.fromRGB(235,235,245)
        headerPane.Font = Enum.Font.GothamBold
        headerPane.TextSize = 14
        headerPane.TextXAlignment = Enum.TextXAlignment.Left

        return pane
    end

    local function makeButton(parent, text)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1,-12,0,32)
        btn.Position = UDim2.new(0,6,0,0)
        btn.BackgroundColor3 = Color3.fromRGB(60,62,90)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(82,85,120)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60,62,90)}):Play()
        end)
        return btn
    end

    local function makeSmallButton(parent, text, color)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(0,148,0,30)
        btn.BackgroundColor3 = color or Color3.fromRGB(80,82,110)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = (color or Color3.fromRGB(95,97,130))}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = (color or Color3.fromRGB(80,82,110))}):Play()
        end)
        return btn
    end

    local function makeGroup(parent, titleText, height)
        local group = Instance.new("Frame", parent)
        group.Size = UDim2.new(1,-12,0,height or 110)
        group.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", group)
        label.Size = UDim2.new(1,0,0,20)
        label.Text = titleText
        label.TextColor3 = Color3.fromRGB(220,220,230)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left

        local gridContainer = Instance.new("Frame", group)
        gridContainer.Size = UDim2.new(1,0,1,-24)
        gridContainer.Position = UDim2.new(0,0,0,24)
        gridContainer.BackgroundTransparency = 1

        local grid = Instance.new("UIGridLayout", gridContainer)
        grid.CellSize = UDim2.new(0,148,0,30)
        grid.CellPadding = UDim2.new(0,6,0,6)
        grid.FillDirectionMaxCells = 2

        return group, gridContainer
    end

    -- =======================
    -- ESP Tab
    -- =======================
    local function showESP()
        clearContent()
        local pane = makePane("ESP")

        local hlBtn = makeButton(pane, "Highlight players: "..(highlightEnabled and "ON" or "OFF"))
        hlBtn.MouseButton1Click:Connect(function()
            highlightEnabled = not highlightEnabled
            hlBtn.Text = "Highlight players: "..(highlightEnabled and "ON" or "OFF")
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then addHighlight(plr, plr.Character) end
            end
        end)

        local colorGroup, colorGrid = makeGroup(pane, "ESP color", 110)
        local c1 = makeSmallButton(colorGrid,"Green",Color3.fromRGB(0,255,128))
        local c2 = makeSmallButton(colorGrid,"Red",Color3.fromRGB(255,64,64))
        local c3 = makeSmallButton(colorGrid,"Blue",Color3.fromRGB(64,128,255))
        local c4 = makeSmallButton(colorGrid,"Yellow",Color3.fromRGB(255,225,64))

        c1.MouseButton1Click:Connect(function() highlightColor = Color3.fromRGB(0,255,128) for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then addHighlight(p, p.Character) end end end)
        c2.MouseButton1Click:Connect(function() highlightColor = Color3.fromRGB(255,64,64) for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then addHighlight(p, p.Character) end end end)
        c3.MouseButton1Click:Connect(function() highlightColor = Color3.fromRGB(64,128,255) for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then addHighlight(p, p.Character) end end end)
        c4.MouseButton1Click:Connect(function() highlightColor = Color3.fromRGB(255,225,64) for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then addHighlight(p, p.Character) end end end)
    end

    -- =======================
    -- Combat Tab
    -- =======================
    local function showCombat()
        clearContent()
        local pane = makePane("Combat")

        local hitboxBtn = makeButton(pane, "Hitbox: "..(hitboxEnabled and "ON" or "OFF"))
        hitboxBtn.MouseButton1Click:Connect(function()
            hitboxEnabled = not hitboxEnabled
            hitboxBtn.Text = "Hitbox: "..(hitboxEnabled and "ON" or "OFF")
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then applyHitbox(plr, plr.Character) end
            end
        end)

        local hitboxGroup, hitboxGrid = makeGroup(pane, "Hitbox size: "..tostring(hitboxSize), 110)
        local sizePlus = makeSmallButton(hitboxGrid, "Size +")
        local sizeMinus = makeSmallButton(hitboxGrid, "Size -")
        sizePlus.MouseButton1Click:Connect(function()
            hitboxSize = hitboxSize + 2
            hitboxGroup:FindFirstChildOfClass("TextLabel").Text = "Hitbox size: "..tostring(hitboxSize)
            if hitboxEnabled then for _, plr in ipairs(Players:GetPlayers()) do if plr~=LocalPlayer and plr.Character then applyHitbox(plr, plr.Character) end end end
        end)
        sizeMinus.MouseButton1Click:Connect(function()
            hitboxSize = math.max(2, hitboxSize - 2)
            hitboxGroup:FindFirstChildOfClass("TextLabel").Text = "Hitbox size: "..tostring(hitboxSize)
            if hitboxEnabled then for _, plr in ipairs(Players:GetPlayers()) do if plr~=LocalPlayer and plr.Character then applyHitbox(plr, plr.Character) end end end
        end)

        local fovBtn = makeButton(pane, "FOV + Aimbot: "..(fovEnabled and "ON" or "OFF"))
        fovBtn.MouseButton1Click:Connect(function()
            fovEnabled = not fovEnabled
            if not fovEnabled then stickyTarget = nil end
            fovBtn.Text = "FOV + Aimbot: "..(fovEnabled and "ON" or "OFF")
        end)

        local fovGroup, fovGrid = makeGroup(pane, "FOV size: "..tostring(fovSize), 110)
        local fovPlus = makeSmallButton(fovGrid, "FOV +")
        local fovMinus = makeSmallButton(fovGrid, "FOV -")
        fovPlus.MouseButton1Click:Connect(function()
            fovSize = fovSize + 10
            fovGroup:FindFirstChildOfClass("TextLabel").Text = "FOV size: "..tostring(fovSize)
        end)
        fovMinus.MouseButton1Click:Connect(function()
            fovSize = math.max(10, fovSize - 10)
            fovGroup:FindFirstChildOfClass("TextLabel").Text = "FOV size: "..tostring(fovSize)
        end)

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

    -- =======================
    -- Misc Tab
    -- =======================
    local function showMisc()
        clearContent()
        local pane = makePane("Misc")

        -- Infinite Jump
        local ijBtn = makeButton(pane, "Infinite Jump: "..(miscInfiniteJump and "ON" or "OFF"))
        ijBtn.MouseButton1Click:Connect(function()
            miscInfiniteJump = not miscInfiniteJump
            ijBtn.Text = "Infinite Jump: "..(miscInfiniteJump and "ON" or "OFF")
        end)

        -- Noclip
        local noclipBtn = makeButton(pane, "Noclip: "..(miscNoclip and "ON" or "OFF"))
        noclipBtn.MouseButton1Click:Connect(function()
            miscNoclip = not miscNoclip
            noclipBtn.Text = "Noclip: "..(miscNoclip and "ON" or "OFF")
        end)

        -- Speed
        local speedGroup, speedGrid = makeGroup(pane, "Run speed: "..tostring(miscSpeedValue), 110)
        local speedToggle = makeSmallButton(speedGrid, "Speed: "..(miscSpeedEnabled and "ON" or "OFF"))
        local speedPlus = makeSmallButton(speedGrid, "Speed +")
        local speedMinus = makeSmallButton(speedGrid, "Speed -")
        speedToggle.MouseButton1Click:Connect(function()
            miscSpeedEnabled = not miscSpeedEnabled
            speedToggle.Text = "Speed: "..(miscSpeedEnabled and "ON" or "OFF")
            local hum = getHumanoid(LocalPlayer.Character)
            if hum then
                if miscSpeedEnabled then
                    originalWalkSpeed = hum.WalkSpeed
                    hum.WalkSpeed = miscSpeedValue
                else
                    hum.WalkSpeed = originalWalkSpeed
                end
            end
        end)
        speedPlus.MouseButton1Click:Connect(function()
            miscSpeedValue = miscSpeedValue + 2
            speedGroup:FindFirstChildOfClass("TextLabel").Text = "Run speed: "..tostring(miscSpeedValue)
            local hum = getHumanoid(LocalPlayer.Character)
            if hum and miscSpeedEnabled then hum.WalkSpeed = miscSpeedValue end
        end)
        speedMinus.MouseButton1Click:Connect(function()
            miscSpeedValue = math.max(8, miscSpeedValue - 2)
            speedGroup:FindFirstChildOfClass("TextLabel").Text = "Run speed: "..tostring(miscSpeedValue)
            local hum = getHumanoid(LocalPlayer.Character)
            if hum and miscSpeedEnabled then hum.WalkSpeed = miscSpeedValue end
        end)

        -- Target player actions (autocomplete)
        local targetGroup, targetGrid = makeGroup(pane, "Target player", 160)
        local targetBox = Instance.new("TextBox", targetGrid)
        targetBox.Size = UDim2.new(0,302,0,30)
        targetBox.PlaceholderText = "Nhập một phần tên (vd: bab)"
        targetBox.Text = miscTargetName
        targetBox.TextColor3 = Color3.fromRGB(255,255,255)
        targetBox.PlaceholderColor3 = Color3.fromRGB(180,180,190)
        targetBox.BackgroundColor3 = Color3.fromRGB(60,62,90)
        targetBox.Font = Enum.Font.Gotham
        targetBox.TextSize = 12
        Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0,8)

        local setTargetBtn = makeSmallButton(targetGrid, "Set target")
        local tpToBtn = makeSmallButton(targetGrid, "Teleport to")
        local flyFollowToggle = makeSmallButton(targetGrid, "Fly follow: "..(miscFlyFollowEnabled and "ON" or "OFF"))

        setTargetBtn.MouseButton1Click:Connect(function()
            miscTargetName = targetBox.Text
            miscTargetPlayer = findPlayerByPartialName(miscTargetName)
            local label = targetGroup:FindFirstChildOfClass("TextLabel")
            if miscTargetPlayer then
                label.Text = "Target player: "..miscTargetPlayer.Name
            else
                label.Text = "Target player: (không tìm thấy)"
            end
        end)

        tpToBtn.MouseButton1Click:Connect(function()
            local target = miscTargetPlayer or findPlayerByPartialName(targetBox.Text)
            if target and target.Character then
                local myHRP = getHRP(LocalPlayer.Character)
                local targetHRP = getHRP(target.Character)
                if myHRP and targetHRP then
                    myHRP.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0,3,0))
                end
            end
        end)

        flyFollowToggle.MouseButton1Click:Connect(function()
            miscFlyFollowEnabled = not miscFlyFollowEnabled
            flyFollowToggle.Text = "Fly follow: "..(miscFlyFollowEnabled and "ON" or "OFF")
        end)

        -- ESP Model Highlight
        local modelGroup, modelGrid = makeGroup(pane, "ESP Model Highlight", 200)
        local modelBox = Instance.new("TextBox", modelGrid)
        modelBox.Size = UDim2.new(0,302,0,30)
        modelBox.PlaceholderText = "Nhập tên model (vd: Tree, Chest...)"
        modelBox.Text = ""
        modelBox.TextColor3 = Color3.fromRGB(255,255,255)
        modelBox.PlaceholderColor3 = Color3.fromRGB(180,180,190)
        modelBox.BackgroundColor3 = Color3.fromRGB(60,62,90)
        modelBox.Font = Enum.Font.Gotham
        modelBox.TextSize = 12
        Instance.new("UICorner", modelBox).CornerRadius = UDim.new(0,8)

        local addBtn = makeSmallButton(modelGrid, "Add")
        local removeBtn = makeSmallButton(modelGrid, "Remove")
        local listBtn = makeSmallButton(modelGrid, "List Models")
        local toggleModelESP = makeSmallButton(modelGrid, "ESP Model: "..(espModelEnabled and "ON" or "OFF"))

        addBtn.MouseButton1Click:Connect(function()
            local name = modelBox.Text
            if name ~= "" then
                table.insert(modelHighlightList, name)
                applyModelHighlight()
            end
        end)

        removeBtn.MouseButton1Click:Connect(function()
            local name = modelBox.Text
            if name ~= "" then
                for i, v in ipairs(modelHighlightList) do
                    if v == name then
                        table.remove(modelHighlightList, i)
                        break
                    end
                end
            end
        end)

        listBtn.MouseButton1Click:Connect(function()
            listAllModels()
        end)

        toggleModelESP.MouseButton1Click:Connect(function()
            espModelEnabled = not espModelEnabled
            toggleModelESP.Text = "ESP Model: "..(espModelEnabled and "ON" or "OFF")
            if not espModelEnabled then
                for _, name in ipairs(modelHighlightList) do
                    local model = workspace:FindFirstChild(name)
                    if model then
                        local hl = model:FindFirstChild("ModelHighlight")
                        if hl then hl.Enabled = false end
                    end
                end
            end
        end)
    end

    local espBtn = makeSidebarButton("ESP", 1)
    local combatBtn = makeSidebarButton("Combat", 2)
    local miscBtn = makeSidebarButton("Misc", 3)
    espBtn.MouseButton1Click:Connect(showESP)
    combatBtn.MouseButton1Click:Connect(showCombat)
    miscBtn.MouseButton1Click:Connect(showMisc)

    showESP()
end

createMenu()

-- =======================
-- Infinite Jump
-- =======================
UserInputService.JumpRequest:Connect(function()
    if miscInfiniteJump then
        local hum = getHumanoid(LocalPlayer.Character)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- =======================
-- Noclip
-- =======================
RunService.Stepped:Connect(function()
    if miscNoclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- =======================
-- Speed safety (restore on respawn)
-- =======================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    local hum = getHumanoid(char)
    if hum then
        if miscSpeedEnabled then
            hum.WalkSpeed = miscSpeedValue
        else
            hum.WalkSpeed = originalWalkSpeed
        end
    end
end)

-- =======================
-- Fly follow (lerp toward target)
-- =======================
RunService.RenderStepped:Connect(function()
    if miscFlyFollowEnabled and miscTargetPlayer and miscTargetPlayer.Character then
        local myHRP = getHRP(LocalPlayer.Character)
        local targetHRP = getHRP(miscTargetPlayer.Character)
        if myHRP and targetHRP then
            local targetPos = targetHRP.Position + Vector3.new(0,4,0)
            myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.new(targetPos, targetPos + Camera.CFrame.LookVector), 0.18)
        end
    end
end)

-- =======================
-- FOV circle + Aimbot
-- =======================
local function ensureFOVCircle()
    if not fovCircle then
        local ok, DrawingLib = pcall(function() return Drawing end)
        if ok and DrawingLib then
            fovCircle = DrawingLib.new("Circle")
            fovCircle.Filled = false
            fovCircle.NumSides = 128
            fovCircle.Thickness = 3
            fovCircle.Visible = false
        end
    end
end

local function getClosestTargetInFOV()
    local center = Camera.ViewportSize / 2
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isAlive(plr) then
            local head = getHead(plr.Character)
            if head then
                local wp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(wp.X, wp.Y) - Vector2.new(center.X, center.Y)).Magnitude
                    local camDist = (head.Position - Camera.CFrame.Position).Magnitude
                    if dist <= fovSize and dist < bestDist and camDist <= maxTargetDistance then
                        best, bestDist = plr, dist
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if fovEnabled then
        ensureFOVCircle()
        if fovCircle then
            fovCircle.Radius = fovSize
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
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
                local center = Camera.ViewportSize / 2
                local dist = (Vector2.new(wp.X, wp.Y) - Vector2.new(center.X, center.Y)).Magnitude
                if (not onScreen) or dist > fovSize then
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
                Camera.CFrame = current:Lerp(target, math.clamp(aimSmooth, 0.05, 0.6))
            end
        end
    else
        stickyTarget = nil
    end
end)
