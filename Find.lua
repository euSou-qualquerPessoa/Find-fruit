--[[ 
    Banana Hub | Fruit Finder
    Use por sua conta e risco
]]

-- ===== CONFIG =====
_G.SetTeam = "Pirate" -- Marine or Pirate
_G.Webhook = ""
_G.FlySpeed = 300
_G.ServerHopCooldown = 1
_G.AutoExecute = true -- colocar loadstring aqui depois
-- ==================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer

-- ===== TEAM =====
pcall(function()
    ReplicatedStorage.Remotes.CommF_:InvokeServer(
        "SetTeam",
        (_G.SetTeam or "Marine"):lower() == "pirate" and "Pirates" or "Marines"
    )
end)

-- ===== WEBHOOK =====
local function SendWebhook(t,d)
    if _G.Webhook == "" then return end
    pcall(function()
        HttpService:PostAsync(
            _G.Webhook,
            HttpService:JSONEncode({
                embeds={{
                    title = t,
                    description = d,
                    color = 16711680, -- vermelho
                    timestamp = DateTime.now():ToIsoDate()
                }}
            }),
            Enum.HttpContentType.ApplicationJson
        )
    end)
end

-- ===== NOCLIP =====
local NoClip = false
RunService.Stepped:Connect(function()
    if NoClip and plr.Character then
        for _,v in ipairs(plr.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

-- ===== FLY =====
local function FlyTo(pos)
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    NoClip = true
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    bv.Parent = hrp

    while (hrp.Position - pos).Magnitude > 8 do
        bv.Velocity = (pos - hrp.Position).Unit * _G.FlySpeed
        task.wait()
    end

    bv:Destroy()
    NoClip = false
end

-- ===== AUTO STORE =====
local OwnedFruits = {}
local function AutoStore(tool)
    if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
        if tool.Name:lower():find("fruit") then
            task.wait(0.4)
            OwnedFruits[tool.Name] = true
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer(
                    "StoreFruit",
                    tool:GetAttribute("OriginalName") or tool.Name,
                    tool
                )
            end)
        end
    end
end

plr.Backpack.ChildAdded:Connect(AutoStore)
plr.CharacterAdded:Connect(function(c)
    c.ChildAdded:Connect(AutoStore)
end)

-- ===== UI AJUSTADA =====
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 300, 0, 140)
main.Position = UDim2.new(0.5, -150, 0, 10) -- topo da tela
main.BackgroundColor3 = Color3.fromRGB(25,25,30)
main.BackgroundTransparency = 0.2
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(255,0,0) -- borda vermelha
stroke.Thickness = 1.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Título
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, -20, 0, 25)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "DesplockHub | Fruit Finder"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextStrokeColor3 = Color3.fromRGB(0,0,0)
title.TextStrokeTransparency = 0.2
title.TextXAlignment = Enum.TextXAlignment.Center
title.TextYAlignment = Enum.TextYAlignment.Center

-- Status
local Status = Instance.new("TextLabel", main)
Status.Position = UDim2.new(0, 10, 0, 35)
Status.Size = UDim2.new(1, -20, 0, 20)
Status.BackgroundTransparency = 1
Status.Text = "Status : None"
Status.Font = Enum.Font.Gotham
Status.TextSize = 14
Status.TextColor3 = Color3.fromRGB(255,255,255)
Status.TextXAlignment = Enum.TextXAlignment.Center

task.spawn(function()
    while task.wait() do
        TweenService:Create(Status,TweenInfo.new(1.2),{TextColor3=Color3.fromRGB(255,100,100)}):Play()
        task.wait(1.2)
        TweenService:Create(Status,TweenInfo.new(1.2),{TextColor3=Color3.fromRGB(255,50,50)}):Play()
        task.wait(1.2)
    end
end)

local function SetStatus(t)
    Status.Text = "Status : "..t
end

-- ===== BOTÃO HOP SERVER =====
local hopBtn = Instance.new("TextButton", main)
hopBtn.Size = UDim2.new(0, 120, 0, 25)
hopBtn.Position = UDim2.new(0.5, -60, 0, 60)
hopBtn.BackgroundColor3 = Color3.fromRGB(255,0,0)
hopBtn.Font = Enum.Font.GothamBold
hopBtn.Text = "Hop Server"
hopBtn.TextColor3 = Color3.fromRGB(255,255,255)
hopBtn.TextSize = 14
Instance.new("UICorner", hopBtn).CornerRadius = UDim.new(0,6)

hopBtn.MouseButton1Click:Connect(function()
    SetStatus("Hopping Server (Manual)...")
    task.spawn(function()
        local s = HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100")
        )
        local list = {}
        for _,sv in ipairs(s.data) do
            if sv.playing < sv.maxPlayers then
                table.insert(list,sv.id)
            end
        end
        if #list > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId,list[math.random(#list)])
        else
            SetStatus("No server available")
        end
    end)
end)

-- ===== FIND FRUIT + HOP =====
local lastHop = 0

task.spawn(function()
    while task.wait(1) do
        local found = false
        for _,v in ipairs(workspace:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("Handle") and v.Name:lower():find("fruit") then
                found = true
                ServerFruits[v.Name] = true
                SetStatus('Fruta encontrada "'..v.Name..'"')
                SendWebhook("Fruit Found",v.Name)
                FlyTo(v.Handle.Position)
                UpdateFruitList()
                break
            end
        end

        if not found then
            SetStatus("Searching")
            if tick() - lastHop > _G.ServerHopCooldown then
                lastHop = tick()
                SetStatus("Hopping Server")
                local s = HttpService:JSONDecode(
                    game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100")
                )
                local list = {}
                for _,sv in ipairs(s.data) do
                    if sv.playing < sv.maxPlayers then
                        table.insert(list,sv.id)
                    end
                end
                if #list > 0 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId,list[math.random(#list)])
                end
            end
        end
    end
end)

-- ===== AUTO EXECUTE LOADSTRING =====
if _G.AutoExecute and _G.AutoExecute ~= "loadstring(game:HttpGet("https://raw.githubusercontent.com/PlockScripts/Find/refs/heads/main/Find.lua"))()" then
    pcall(function()
        loadstring(_G.AutoExecute)()
    end)
end
