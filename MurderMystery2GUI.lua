-- Murder Mystery 2 Hub | Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local flags = { PlayerESP = false, RoleESP = false, CoinFarm = false, MurdererArrow = false }
local espObjects = {}

local function getHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function myHRP() return getHRP(LocalPlayer.Character) end

-- read role from ReplicatedStorage / player tool
local function getRole(plr)
    local char = plr.Character
    if not char then return "Unknown" end
    if char:FindFirstChild("Knife") or (char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool").Name:lower():find("knife")) then
        return "Murderer"
    end
    if char:FindFirstChild("Gun") or (plr.Backpack and plr.Backpack:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
end

local function roleColor(role)
    if role == "Murderer" then return Color3.fromRGB(255,40,40)
    elseif role == "Sheriff" then return Color3.fromRGB(40,120,255)
    else return Color3.fromRGB(60,255,120) end
end

local function findMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and getRole(p) == "Murderer" then return p end
    end
    return nil
end

local Window = Rayfield:CreateWindow({
    Name = "MM2 Hub",
    LoadingTitle = "Murder Mystery 2",
    LoadingSubtitle = "Enjoy!",
    ConfigurationSaving = { Enabled = true, FolderName = "MM2Hub", FileName = "MM2Hub" },
})

-- ===== ESP TAB =====
local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateToggle({ Name="Player ESP (through walls)", CurrentValue=false, Callback=function(v) flags.PlayerESP=v end })
ESPTab:CreateToggle({ Name="Role ESP (color by role)", CurrentValue=false, Callback=function(v) flags.RoleESP=v end })

-- ===== FARM TAB =====
local FarmTab = Window:CreateTab("Farm", 4483362458)
FarmTab:CreateToggle({ Name="Auto Coin Farm", CurrentValue=false, Callback=function(v) flags.CoinFarm=v end })

-- ===== HUNT TAB =====
local HuntTab = Window:CreateTab("Hunt", 4483362458)
HuntTab:CreateToggle({ Name="Murderer Arrow (Beam)", CurrentValue=false, Callback=function(v)
    flags.MurdererArrow=v
end })
HuntTab:CreateButton({ Name="TP to Murderer (Sheriff Win)", Callback=function()
    local m = findMurderer()
    local hrp = myHRP()
    if m and m.Character and hrp then
        local mhrp = getHRP(m.Character)
        if mhrp then
            hrp.CFrame = mhrp.CFrame * CFrame.new(0,0,4)
            Rayfield:Notify({Title="MM2", Content="TP to "..m.Name, Duration=3})
        end
    else
        Rayfield:Notify({Title="MM2", Content="No murderer found", Duration=3})
    end
end })

-- ESP builder using Highlight + BillboardGui
local function ensureESP(plr)
    local char = plr.Character
    local hrp = getHRP(char)
    if not char or not hrp then return end
    local data = espObjects[plr]
    if not data then
        local hl = Instance.new("Highlight")
        hl.Name = "MM2_ESP"
        hl.FillTransparency = 0.5
        local bg = Instance.new("BillboardGui")
        bg.Name = "MM2_TAG"
        bg.Size = UDim2.new(0,120,0,30)
        bg.StudsOffset = Vector3.new(0,3,0)
        bg.AlwaysOnTop = true
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextScaled = true
        lbl.Parent = bg
        data = { hl=hl, bg=bg, lbl=lbl }
        espObjects[plr] = data
    end
    data.hl.Adornee = char
    data.hl.Parent = char
    data.bg.Adornee = hrp
    data.bg.Parent = hrp
    local role = getRole(plr)
    local col = flags.RoleESP and roleColor(role) or Color3.fromRGB(255,255,255)
    data.hl.FillColor = col
    data.hl.OutlineColor = col
    data.lbl.TextColor3 = col
    data.lbl.Text = plr.Name .. (flags.RoleESP and (" ["..role.."]") or "")
end

local function clearESP()
    for plr, data in pairs(espObjects) do
        if data.hl then data.hl:Destroy() end
        if data.bg then data.bg:Destroy() end
        espObjects[plr] = nil
    end
end

RunService.RenderStepped:Connect(function()
    if flags.PlayerESP or flags.RoleESP then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ensureESP(p) end
        end
    elseif next(espObjects) then
        clearESP()
    end
end)

-- coin farm loop
task.spawn(function()
    while true do
        task.wait(0.4)
        if flags.CoinFarm then
            local hrp = myHRP()
            if hrp then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name == "CoinContainer" or obj.Name:lower():find("coin")) then
                        hrp.CFrame = obj.CFrame
                        task.wait(0.08)
                    end
                end
            end
        end
    end
end)

-- murderer arrow (beam from player to murderer)
local beam, att0, att1
task.spawn(function()
    while true do
        task.wait(0.2)
        if flags.MurdererArrow then
            local hrp = myHRP()
            local m = findMurderer()
            if hrp and m and m.Character then
                local mhrp = getHRP(m.Character)
                if mhrp then
                    if not beam then
                        att0 = Instance.new("Attachment", hrp)
                        att1 = Instance.new("Attachment", mhrp)
                        beam = Instance.new("Beam")
                        beam.Attachment0 = att0
                        beam.Attachment1 = att1
                        beam.Color = ColorSequence.new(Color3.fromRGB(255,0,0))
                        beam.Width0 = 0.4; beam.Width1 = 0.4
                        beam.FaceCamera = true
                        beam.Parent = hrp
                    else
                        att1.Parent = mhrp
                    end
                end
            end
        else
            if beam then beam:Destroy() beam=nil end
            if att0 then att0:Destroy() att0=nil end
            if att1 then att1:Destroy() att1=nil end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    local d = espObjects[p]
    if d then if d.hl then d.hl:Destroy() end if d.bg then d.bg:Destroy() end espObjects[p]=nil end
end)

Rayfield:Notify({Title="MM2 Hub", Content="Loaded successfully!", Duration=4})
