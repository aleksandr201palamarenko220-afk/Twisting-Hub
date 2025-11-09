local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Can_Player_Esp = false
local Show_Player_Names = true
local Show_Player_HP = true
local Team_Check = false
local Player_Esp_Color = Color3.fromRGB(0, 255, 0)
local Player_Esp_Thickness = 1

local Aimbot_Enabled = false
local Aimbot_TeamCheck = true
local Aimbot_Smoothness = 0.25
local Aimbot_FOV = 150
local Aimbot_Key = Enum.KeyCode.E
local Aimbot_TargetPart = "Head" -- "Head", "Torso", "Random"

local Holding = false
local AimTarget = nil

------------------------------------------------------------
-- 🪟 UI
------------------------------------------------------------
local Window = Rayfield:CreateWindow({
	Name = "Twisting Hub",
	LoadingTitle = "Twisting Hub",
	LoadingSubtitle = "by Nobody",
	Theme = "Serenity",
	ToggleUIKeybind = "U",
})

------------------------------------------------------------
-- 🟩 Вкладка AIMBOT
------------------------------------------------------------
local AIM_Tab = Window:CreateTab("Aimbot")
AIM_Tab:CreateSection("Aimbot Settings")

AIM_Tab:CreateToggle({
	Name = "Enable Aimbot",
	CurrentValue = false,
	Flag = "Aimbot_Enabled",
	Callback = function(Value)
		Aimbot_Enabled = Value
	end,
})

AIM_Tab:CreateToggle({
	Name = "Ignore Same Team",
	CurrentValue = true,
	Flag = "Aimbot_TeamCheck",
	Callback = function(Value)
		Aimbot_TeamCheck = Value
	end,
})

AIM_Tab:CreateSlider({
	Name = "Smoothness",
	Range = {0.01, 1},
	Increment = 0.01,
	Suffix = "Speed",
	CurrentValue = 0.25,
	Flag = "Aimbot_Smoothness",
	Callback = function(Value)
		Aimbot_Smoothness = Value
	end,
})

AIM_Tab:CreateSlider({
	Name = "Aimbot FOV",
	Range = {50, 400},
	Increment = 10,
	Suffix = "px",
	CurrentValue = 150,
	Flag = "Aimbot_FOV",
	Callback = function(Value)
		Aimbot_FOV = Value
	end,
})

-- 🎯 Выбор части тела
AIM_Tab:CreateDropdown({
	Name = "Target Part",
	Options = {"Head", "Torso", "Random"},
	CurrentOption = "Head",
	Flag = "Aimbot_TargetPart",
	Callback = function(Option)
		Aimbot_TargetPart = Option
	end,
})

-- ⌨️ Настройка клавиши активации
AIM_Tab:CreateKeybind({
	Name = "Aimbot Key",
	CurrentKeybind = "E",
	Flag = "Aimbot_Keybind",
	Callback = function(Key)
		Aimbot_Key = Key
	end,
})

------------------------------------------------------------
-- 🎯 AIMBOT ЛОГИКА
------------------------------------------------------------

-- Возвращает ближайшего противника
local function GetClosestTarget()
	local closest = nil
	local shortestDist = Aimbot_FOV
	local mousePos = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player == Players.LocalPlayer then continue end

		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not (char and humanoid and humanoid.Health > 0) then continue end

		-- Проверка команды
		if Aimbot_TeamCheck and player.Team == Players.LocalPlayer.Team then
			continue
		end

		local targetPart
		if Aimbot_TargetPart == "Random" then
			targetPart = math.random(1, 2) == 1 and char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
		else
			targetPart = char:FindFirstChild(Aimbot_TargetPart)
		end

		if not targetPart then continue end

		local screenPos, visible = Camera:WorldToViewportPoint(targetPart.Position)
		if not visible then continue end

		local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if distance < shortestDist then
			shortestDist = distance
			closest = targetPart
		end
	end

	return closest
end

-- Плавное наведение камеры
local function SmoothAim(targetPos)
	local camPos = Camera.CFrame.Position
	local direction = (targetPos - camPos).Unit
	local newCF = CFrame.new(camPos, camPos + direction)
	Camera.CFrame = Camera.CFrame:Lerp(newCF, Aimbot_Smoothness)
end

-- Слежение за клавишей
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Aimbot_Key or input.UserInputType == Aimbot_Key then
		Holding = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Aimbot_Key or input.UserInputType == Aimbot_Key then
		Holding = false
	end
end)

-- Цикл работы аимбота
RunService.RenderStepped:Connect(function()
	if not (Aimbot_Enabled and Holding) then
		AimTarget = nil
		return
	end

	local target = GetClosestTarget()
	if not target then return end
	SmoothAim(target.Position)
end)
