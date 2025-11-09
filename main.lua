local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

------------------------------------------------------------
-- ⚙️ НАСТРОЙКИ
------------------------------------------------------------

-- ESP
local Can_Player_Esp = false
local Show_Player_Names = true
local Show_Player_HP = true
local Show_Player_Distance = true
local Show_Tracers = true
local Team_Check = false
local Player_Esp_Color = Color3.fromRGB(0, 255, 0)
local Player_Esp_Thickness = 1
local PlayerDrawings = {}

-- AIMBOT
local Aimbot_Enabled = false
local Aimbot_TeamCheck = true
local Aimbot_Smoothness = 0.25
local Aimbot_FOV = 150
local Aimbot_Key = Enum.KeyCode.E
local Aimbot_TargetPart = "Head"
local Holding = false

-- FOV Circle
local Show_FOV_Circle = true
local FOV_Color = Color3.fromRGB(255, 255, 255)
local FOV_Thickness = 1.5
local FOV_Transparency = 0.4
local FOV_Circle = Drawing.new("Circle")

------------------------------------------------------------
-- 🪟 UI
------------------------------------------------------------
local Window = Rayfield:CreateWindow({
	Name = "Xera Hub",
	LoadingTitle = "Xera Hub",
	LoadingSubtitle = "by Nobody",
	Theme = "Dark Blue",
	ToggleUIKeybind = "U",
})

------------------------------------------------------------
-- 🟩 Вкладка ESP
------------------------------------------------------------
local ESP_Tab = Window:CreateTab("ESP")
ESP_Tab:CreateSection("Player ESP")

ESP_Tab:CreateToggle({ Name = "Player ESP", CurrentValue = false, Callback = function(v) Can_Player_Esp = v end })
ESP_Tab:CreateToggle({ Name = "Show Player Name", CurrentValue = true, Callback = function(v) Show_Player_Names = v end })
ESP_Tab:CreateToggle({ Name = "Show Player HP Bar", CurrentValue = true, Callback = function(v) Show_Player_HP = v end })
ESP_Tab:CreateToggle({ Name = "Show Distance", CurrentValue = true, Callback = function(v) Show_Player_Distance = v end })
ESP_Tab:CreateToggle({ Name = "Show Tracers", CurrentValue = true, Callback = function(v) Show_Tracers = v end })
ESP_Tab:CreateToggle({ Name = "Ignore Same Team", CurrentValue = false, Callback = function(v) Team_Check = v end })

ESP_Tab:CreateColorPicker({
	Name = "ESP Player Color",
	Color = Color3.fromRGB(0,255,0),
	Callback = function(v) Player_Esp_Color = v end,
})

ESP_Tab:CreateSlider({
	Name = "ESP Player Thickness",
	Range = {1,10},
	Increment = 1,
	CurrentValue = 1,
	Callback = function(v) Player_Esp_Thickness = v end,
})

------------------------------------------------------------
-- 🔴 Вкладка AIMBOT
------------------------------------------------------------
local AIM_Tab = Window:CreateTab("Aimbot")
AIM_Tab:CreateSection("Aimbot Settings")

AIM_Tab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = false, Callback = function(v) Aimbot_Enabled = v end })
AIM_Tab:CreateToggle({ Name = "Ignore Same Team", CurrentValue = true, Callback = function(v) Aimbot_TeamCheck = v end })

AIM_Tab:CreateSlider({
	Name = "Smoothness",
	Range = {0.01,1},
	Increment = 0.01,
	CurrentValue = 0.25,
	Callback = function(v) Aimbot_Smoothness = v end,
})

AIM_Tab:CreateSlider({
	Name = "Aimbot FOV",
	Range = {50,400},
	Increment = 10,
	CurrentValue = 150,
	Callback = function(v) Aimbot_FOV = v end,
})

AIM_Tab:CreateDropdown({
	Name = "Target Part",
	Options = {"Head","Torso","Random"},
	CurrentOption = "Head",
	Callback = function(opt)
		if typeof(opt) == "table" then Aimbot_TargetPart = opt[1] else Aimbot_TargetPart = opt end
	end,
})

AIM_Tab:CreateKeybind({
	Name = "Aimbot Key",
	CurrentKeybind = "E",
	Callback = function(key)
		if typeof(key) == "string" and Enum.KeyCode[key] then
			Aimbot_Key = Enum.KeyCode[key]
		elseif typeof(key) == "EnumItem" then
			Aimbot_Key = key
		end
	end,
})

-- ⚪ FOV Circle Settings
AIM_Tab:CreateSection("FOV Circle")
AIM_Tab:CreateToggle({
	Name = "Show FOV Circle",
	CurrentValue = true,
	Callback = function(v) Show_FOV_Circle = v end,
})

AIM_Tab:CreateColorPicker({
	Name = "FOV Circle Color",
	Color = Color3.fromRGB(255,255,255),
	Callback = function(v) FOV_Color = v end,
})

AIM_Tab:CreateSlider({
	Name = "FOV Circle Thickness",
	Range = {1,5},
	Increment = 0.5,
	CurrentValue = 1.5,
	Callback = function(v) FOV_Thickness = v end,
})

AIM_Tab:CreateSlider({
	Name = "FOV Transparency",
	Range = {0,1},
	Increment = 0.05,
	CurrentValue = 0.4,
	Callback = function(v) FOV_Transparency = v end,
})

------------------------------------------------------------
-- ⚙️ Настройка FOV круга
------------------------------------------------------------
FOV_Circle.Visible = true
FOV_Circle.Radius = Aimbot_FOV
FOV_Circle.Thickness = FOV_Thickness
FOV_Circle.Color = FOV_Color
FOV_Circle.Transparency = FOV_Transparency
FOV_Circle.Filled = false
FOV_Circle.ZIndex = 10

RunService.RenderStepped:Connect(function()
	local mousePos = UserInputService:GetMouseLocation()
	FOV_Circle.Position = Vector2.new(mousePos.X, mousePos.Y)
	FOV_Circle.Radius = Aimbot_FOV
	FOV_Circle.Color = FOV_Color
	FOV_Circle.Thickness = FOV_Thickness
	FOV_Circle.Transparency = FOV_Transparency
	FOV_Circle.Visible = Show_FOV_Circle
end)

------------------------------------------------------------
-- 🎯 AIMBOT
------------------------------------------------------------
local function GetClosestTarget()
	local closest, shortest = nil, Aimbot_FOV
	local mousePos = UserInputService:GetMouseLocation()

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == LocalPlayer then continue end
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (char and hum and hum.Health > 0) then continue end
		if Aimbot_TeamCheck and plr.Team == LocalPlayer.Team then continue end

		local part
		if Aimbot_TargetPart == "Random" then
			part = math.random(1,2) == 1 and char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
		elseif Aimbot_TargetPart == "Torso" then
			part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
		else
			part = char:FindFirstChild("Head")
		end
		if not part then continue end

		local screen, vis = Camera:WorldToViewportPoint(part.Position)
		if not vis then continue end
		local dist = (Vector2.new(screen.X, screen.Y) - mousePos).Magnitude
		if dist < shortest then
			shortest = dist
			closest = part
		end
	end
	return closest
end

local function SmoothAim(target)
	local camPos = Camera.CFrame.Position
	local dir = (target - camPos).Unit
	local cf = CFrame.new(camPos, camPos + dir)
	Camera.CFrame = Camera.CFrame:Lerp(cf, Aimbot_Smoothness)
end

UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.KeyCode == Aimbot_Key then Holding = true end
end)
UserInputService.InputEnded:Connect(function(inp)
	if inp.KeyCode == Aimbot_Key then Holding = false end
end)

RunService.RenderStepped:Connect(function()
	if not (Aimbot_Enabled and Holding) then return end
	local target = GetClosestTarget()
	if target then SmoothAim(target.Position) end
end)
