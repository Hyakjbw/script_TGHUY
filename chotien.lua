

-- con cho tien
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-------------------------------------------------------------------------------
-- 0. HỆ THỐNG LƯU VÀ TẢI CONFIG TỰ ĐỘNG
-------------------------------------------------------------------------------
local ConfigName = "MobileFruitSniperConfig.json"

-- Cấu hình mặc định nếu chưa có file
_G.Config = {
    AutoFruit = true,
    ServerHopIfNoFruit = true,
    AutoStoreFruit = true,
    ScriptURL = "ĐIỀN_LINK_RAW_SCRIPT_CỦA_BẠN_VÀO_ĐÂY", 
    FlySpeed = 250
}

local function SaveConfig()
    pcall(function()
        if writefile then
            writefile(ConfigName, HttpService:JSONEncode(_G.Config))
        end
    end)
end

local function LoadConfig()
    pcall(function()
        if isfile and isfile(ConfigName) then
            local savedData = HttpService:JSONDecode(readfile(ConfigName))
            if savedData then
                for k, v in pairs(savedData) do
                    _G.Config[k] = v
                end
            end
        else
            SaveConfig()
        end
    end)
end

LoadConfig() 

-------------------------------------------------------------------------------
-- 1. HỆ THỐNG TỰ ĐỘNG CHẠY LẠI SCRIPT KHI ĐỔI SERVER (QUEUE ON TELEPORT)
-------------------------------------------------------------------------------
pcall(function()
    local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if queue and _G.Config.ScriptURL ~= "ĐIỀN_LINK_RAW_SCRIPT_CỦA_BẠN_VÀO_ĐÂY" and _G.Config.ScriptURL ~= "" then
        queue('loadstring(game:HttpGet("' .. _G.Config.ScriptURL .. '"))()')
    end
end)

-------------------------------------------------------------------------------
-- 2. MOBILE OPTIMIZED GUI (Sử dụng tỷ lệ Scale & Kéo thả độc lập)
-------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileFruitSniperV6"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = CoreGui
end)

local ToggleMenuBtn = Instance.new("TextButton")
ToggleMenuBtn.Size = UDim2.new(0.18, 0, 0.06, 0)
ToggleMenuBtn.Position = UDim2.new(0.05, 0, 0.05, 0)
ToggleMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleMenuBtn.Text = "Ẩn/Hiện Menu"
ToggleMenuBtn.TextColor3 = Color3.fromRGB(0, 255, 127)
ToggleMenuBtn.Font = Enum.Font.GothamBold
ToggleMenuBtn.TextSize = 12
ToggleMenuBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleMenuBtn

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.45, 0, 0.65, 0)
MainFrame.Position = UDim2.new(0.27, 0, 0.22, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0.15, 0)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "   ANIME FRUIT SNIPER (MOBILE)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
ContentFrame.Position = UDim2.new(0.05, 0, 0.18, 0)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0.15, 0)
StatusLabel.Position = UDim2.new(0, 0, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Trạng thái: Đã kết nối, đang khởi động..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 235, 165)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = ContentFrame

local AutoBtn = Instance.new("TextButton")
AutoBtn.Size = UDim2.new(1, 0, 0.2, 0)
AutoBtn.Position = UDim2.new(0, 0, 0.2, 0)
AutoBtn.BackgroundColor3 = _G.Config.AutoFruit and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(150, 50, 50)
AutoBtn.Text = _G.Config.AutoFruit and "Auto Nhặt: BẬT" or "Auto Nhặt: TẮT"
AutoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBtn.Font = Enum.Font.GothamBold
AutoBtn.TextSize = 14
AutoBtn.Parent = ContentFrame

local AutoBtnCorner = Instance.new("UICorner")
AutoBtnCorner.CornerRadius = UDim.new(0, 6)
AutoBtnCorner.Parent = AutoBtn

local HopBtn = Instance.new("TextButton")
HopBtn.Size = UDim2.new(1, 0, 0.2, 0)
HopBtn.Position = UDim2.new(0, 0, 0.45, 0)
HopBtn.BackgroundColor3 = _G.Config.ServerHopIfNoFruit and Color3.fromRGB(170, 85, 255) or Color3.fromRGB(150, 50, 50)
HopBtn.Text = _G.Config.ServerHopIfNoFruit and "Auto Server Hop: BẬT" or "Auto Server Hop: TẮT"
HopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HopBtn.Font = Enum.Font.GothamBold
HopBtn.TextSize = 14
HopBtn.Parent = ContentFrame

local HopBtnCorner = Instance.new("UICorner")
HopBtnCorner.CornerRadius = UDim.new(0, 6)
HopBtnCorner.Parent = HopBtn

local ManualHopBtn = Instance.new("TextButton")
ManualHopBtn.Size = UDim2.new(1, 0, 0.2, 0)
ManualHopBtn.Position = UDim2.new(0, 0, 0.7, 0)
ManualHopBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
ManualHopBtn.Text = "Đổi Server Ngay Lập Tức"
ManualHopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ManualHopBtn.Font = Enum.Font.GothamBold
ManualHopBtn.TextSize = 14
ManualHopBtn.Parent = ContentFrame

local ManualHopBtnCorner = Instance.new("UICorner")
ManualHopBtnCorner.CornerRadius = UDim.new(0, 6)
ManualHopBtnCorner.Parent = ManualHopBtn

-------------------------------------------------------------------------------
-- LOGIC GUI: Tương tác & Kéo thả
-------------------------------------------------------------------------------
ToggleMenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

AutoBtn.MouseButton1Click:Connect(function()
    _G.Config.AutoFruit = not _G.Config.AutoFruit
    SaveConfig()
    if _G.Config.AutoFruit then
        AutoBtn.Text = "Auto Nhặt: BẬT"
        AutoBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
    else
        AutoBtn.Text = "Auto Nhặt: TẮT"
        AutoBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    end
end)

HopBtn.MouseButton1Click:Connect(function()
    _G.Config.ServerHopIfNoFruit = not _G.Config.ServerHopIfNoFruit
    SaveConfig()
    if _G.Config.ServerHopIfNoFruit then
        HopBtn.Text = "Auto Server Hop: BẬT"
        HopBtn.BackgroundColor3 = Color3.fromRGB(170, 85, 255)
    else
        HopBtn.Text = "Auto Server Hop: TẮT"
        HopBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    end
end)

local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale, 
        startPos.X.Offset + delta.X, 
        startPos.Y.Scale, 
        startPos.Y.Offset + delta.Y
    )
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-------------------------------------------------------------------------------
-- 3. HỆ THỐNG SERVER HOP (Thuật toán Chọn Server Tối Ưu Mới)
-------------------------------------------------------------------------------
local function ServerHop()
    StatusLabel.Text = "Trạng thái: Đang tìm Server hợp lệ..."
    pcall(function()
        local cursor = ""
        local validServers = {}
        
        -- Mở rộng vòng lặp quét 10 trang, dùng 'Desc' (đông xuống ít) để vượt qua nhanh mớ server 1 người
        for i = 1, 10 do
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            if cursor ~= "" then
                url = url .. "&cursor=" .. cursor
            end
            
            local response = HttpService:JSONDecode(game:HttpGet(url))
            if response and response.data then
                for _, server in pairs(response.data) do
                    -- Tìm server có từ 3 người trở lên và chưa bị full người (Max Players - 1)
                    if server.playing >= 3 and server.playing <= (server.maxPlayers - 1) and server.id ~= game.JobId then
                        table.insert(validServers, server.id)
                    end
                end
                
                -- Nếu đã tìm đủ ít nhất 5 server thì cắt vòng lặp ngay để nhảy luôn, tránh tốn thời gian
                if #validServers >= 5 then
                    break
                end
                
                if response.nextPageCursor and response.nextPageCursor ~= "null" then
                    cursor = response.nextPageCursor
                    task.wait(0.1) -- Tạo delay cực nhỏ chống Roblox Ratelimit API
                else
                    break
                end
            end
        end
        
        if #validServers > 0 then
            local randomServerId = validServers[math.random(1, #validServers)]
            StatusLabel.Text = "Trạng thái: Đang nhảy Server: " .. tostring(randomServerId)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServerId, Player)
            task.wait(5)
        else
            StatusLabel.Text = "Trạng thái: Không tìm thấy Server, thử lại sau..."
        end
    end)
end

ManualHopBtn.MouseButton1Click:Connect(ServerHop)

-------------------------------------------------------------------------------
-- 4. HỆ THỐNG AUTO LƯU TRÁI (Lưu ý: Auto Team đã được chuyển xuống Main Loop)
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if _G.Config.AutoStoreFruit then
            local function TryStoreTool(tool)
                if tool:IsA("Tool") and string.find(string.lower(tool.Name), "fruit") then
                    task.spawn(function()
                        pcall(function()
                            local fruitId = tool:GetAttribute("OriginalName") or tool.Name
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitId, tool)
                        end)
                    end)
                end
            end
            
            pcall(function()
                if Player:FindFirstChild("Backpack") then
                    for _, tool in pairs(Player.Backpack:GetChildren()) do TryStoreTool(tool) end
                end
                if Player.Character then
                    for _, tool in pairs(Player.Character:GetChildren()) do TryStoreTool(tool) end
                end
            end)
        end
    end
end)

-------------------------------------------------------------------------------
-- 5. HỆ THỐNG ESP TRÁI ÁC QUỶ
-------------------------------------------------------------------------------
local function CreateESP(object, fullName)
    pcall(function()
        if not object:FindFirstChild("FruitESP") then
            local handle = object:FindFirstChild("Handle") or object:IsA("BasePart") and object or object:FindFirstChildWhichIsA("BasePart")
            if not handle then return end

            local bill = Instance.new("BillboardGui")
            bill.Name = "FruitESP"
            bill.AlwaysOnTop = true
            bill.Size = UDim2.new(0, 150, 0, 50)
            bill.Adornee = handle
            bill.Parent = handle
            
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Text = "🍓 " .. fullName 
            txt.TextColor3 = Color3.fromRGB(255, 48, 48)
            txt.TextStrokeTransparency = 0
            txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 13
            txt.Parent = bill
        end
    end)
end

-------------------------------------------------------------------------------
-- 6. THUẬT TOÁN BAY MƯỢT (FIX CƠ CHẾ TIMEOUT CHỐNG KẸT TWEEN)
-------------------------------------------------------------------------------
local function SmoothFlyTo(targetCFrame)
    local character = Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    
    local timeToTravel = distance / _G.Config.FlySpeed
    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    local noclipConnection
    
    pcall(function()
        noclipConnection = RunService.Stepped:Connect(function()
            for _, v in pairs(character:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
            if hrp:FindFirstChildWhichIsA("BodyVelocity") then
                hrp:FindFirstChildWhichIsA("BodyVelocity"):Destroy()
            end
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end)
    end)
    
    tween:Play()
    
    local safeTimeout = timeToTravel + 1
    local startTime = tick()
    while tween and tween.PlaybackState == Enum.PlaybackState.Playing and (tick() - startTime) < safeTimeout do
        task.wait(0.1)
    end
    pcall(function() tween:Cancel() end)
    
    if noclipConnection then noclipConnection:Disconnect() end
end

-------------------------------------------------------------------------------
-- 7. VÒNG LẶP QUÉT VÀ THỰC THI AUTO NHẶT TỐI ƯU HOÁ (FIX NPC & LOGIC TEAM)
-------------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(1)
        if _G.Config.AutoFruit then
            local fruitsFound = {}
            
            pcall(function()
                for _, object in pairs(Workspace:GetChildren()) do
                    local lowerName = string.lower(object.Name)
                    if (object:IsA("Tool") or object:IsA("Model")) and string.find(lowerName, "fruit") then
                        
                        -- LỌC NPC TRỰC TIẾP: Loại bỏ nếu có Humanoid hoặc tên chứa Dealer/Gacha
                        if not object:FindFirstChild("Humanoid") and not string.find(lowerName, "dealer") and not string.find(lowerName, "gacha") and not string.find(lowerName, "remover") then
                            
                            -- Đảm bảo chỉ quét trái nằm trực tiếp ngoài Workspace (Không phải trên tay người chơi)
                            if object.Parent == Workspace then
                                table.insert(fruitsFound, object)
                                CreateESP(object, object.Name)
                            end
                        end
                    end
                end
            end)
            
            -- NẾU CÓ TRÁI ÁC QUỶ
            if #fruitsFound > 0 then
                
                -- KIỂM TRA & CHỌN TEAM TRƯỚC KHI BAY
                if Player.Team == nil or (Player.Team and Player.Team.Name == "Loading") then
                    StatusLabel.Text = "Trạng thái: Phát hiện trái! Đang chọn Team..."
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Marines")
                    end)
                    task.wait(2.5) -- Đợi 2.5s cho nhân vật rớt xuống và load thân hình
                end

                for _, fruit in pairs(fruitsFound) do
                    if fruit and fruit.Parent == Workspace then
                        local targetPart = fruit:FindFirstChild("Handle") or fruit:IsA("BasePart") and fruit or fruit:FindFirstChildWhichIsA("BasePart")
                        
                        if targetPart then
                            StatusLabel.Text = "Trạng thái: Đang bay tới " .. fruit.Name .. "..."
                            SmoothFlyTo(targetPart.CFrame)
                            task.wait(0.2)
                        end
                    end
                end
            
            -- NẾU KHÔNG CÓ TRÁI ÁC QUỶ
            else
                StatusLabel.Text = "Trạng thái: Đang quét tìm trái ác quỷ..."
                
                if _G.Config.ServerHopIfNoFruit then
                    task.wait(1)
                    local doubleCheck = false
                    pcall(function()
                        for _, obj in pairs(Workspace:GetChildren()) do
                            local lowerName = string.lower(obj.Name)
                            if (obj:IsA("Tool") or obj:IsA("Model")) and string.find(lowerName, "fruit") then
                                if not obj:FindFirstChild("Humanoid") and not string.find(lowerName, "dealer") and obj.Parent == Workspace then
                                    doubleCheck = true
                                end
                            end
                        end
                    end)
                    
                    if not doubleCheck then
                        -- KHÔNG CHỌN TEAM, ĐỔI SERVER LUÔN NGAY TẠI MÀN HÌNH CHỜ
                        StatusLabel.Text = "Trạng thái: Không có trái, Đổi Server (Bỏ qua chọn Team)..."
                        task.wait(1)
                        ServerHop()
                        task.wait(10) 
                    end
                end
            end
        else
            StatusLabel.Text = "Trạng thái: Tạm dừng Auto."
        end
    end
end)
