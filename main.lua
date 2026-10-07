local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace   = workspace
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
-- ═══════════════════════════════════════════════════════════════════════════════
--  §2. Настройки полёта
-- ═══════════════════════════════════════════════════════════════════════════════
local FLIGHT = {
	MinSpeed    = 15,      -- нижняя граница слайдера
	MaxSpeed    = 500,     -- верхняя граница слайдера
	StartSpeed  = 95,      -- с чего начинаем
	Response    = 8,       -- плавность разгона и торможения (больше — резче)
	BoostFactor = 2.2,     -- множитель ускорения на Shift
	HoverBobSpeed = 1.1,   -- мягкое всплытие/оседание при висении, studs/s
	HoverBobRate  = 1.6,   -- частота этого покачивания
	MaxAccel    = 900,     -- предохранитель: предел изменения скорости, studs/s²
	RollSpeed   = 420,     -- скорость бочки на Q/E, градусов в секунду
	RollReturn  = 260,     -- скорость возврата бочки после отпускания, град/с
	DoubleTapWindow = 0.32, -- окно двойного нажатия Space, сек
	Noclip      = false,   -- тестовый режим: персонаж проходит сквозь стены
}
-- ═══════════════════════════════════════════════════════════════════════════════
--  §3. Настройки поз (градусы)
--  Если сустав уходит не в ту сторону — поменяй знак у числа. Всё в одном месте.
-- ═══════════════════════════════════════════════════════════════════════════════
local ANIM = {
	Response      = 9,     -- скорость перетекания висение ↔ полёт
	BankMax       = 40,    -- максимальный крен вбок
	BobDegrees    = 3.5,   -- покачивание корпуса при висении
	NeckBob       = 1.4,   -- доля покачивания, уходящая в шею
	-- горизонтальный полёт («супермен»)
	ArmForward    = -96,
	ArmProneYaw   = 7,
	ElbowProne    = -9,
	HipProne      = 7,
	KneeProne     = -7,
	WaistArch     = 10,
	HeadUpProne   = -33,
	-- пикирование: руки прижаты вдоль тела
	ArmDive       = 16,
	ArmDiveYaw    = 14,
	ElbowDive     = -34,
	KneeDive      = -18,
	HeadDive      = -18,
	-- висение
	LeanHover     = -9,
	ArmHoverBack  = 17,
	ArmSpread     = -15,
	ArmHoverYaw   = 11,
	ElbowHover    = -27,
	KneeHover     = 23,
	LegSpread     = 8,
	HeadHover     = 5,
}
-- ═══════════════════════════════════════════════════════════════════════════════
--  §4. Настройки ауры
-- ═══════════════════════════════════════════════════════════════════════════════
local AURA = {
	Enabled       = true,
	FadeSpeed     = 5.5,   -- скорость розжига и затухания ауры
	HueSpeed      = 0.12,  -- скорость переливания оттенка (оборотов в секунду)
	HighlightFill = 0.62,  -- прозрачность чёрной заливки контура
	HighlightEdge = 0.12,  -- прозрачность переливающейся обводки
	TrailLifetime = 0.42,
	TrailWidth    = 1.5,   -- половина расстояния между точками крепления шлейфа
	TrailBlack    = 0.15,
	TrailAccent   = 0.28,
	OrbCount      = 8,     -- тёмные сферы по орбите
	OrbRadius     = 3.4,
	OrbRise       = 0.9,   -- разброс по высоте
	OrbSpin       = 0.8,   -- оборотов в секунду
	OrbSize       = 0.42,
	OrbTransparency = 0.25,
	LightRange    = 15,
	LightBrightness = 2.2,
	SmokeRate     = 26,
	SparkRate     = 14,
	LineRate      = 90,    -- «линии скорости» на разгоне
}
-- ═══════════════════════════════════════════════════════════════════════════════
--  §5. Настройки камеры и пост-эффектов
-- ═══════════════════════════════════════════════════════════════════════════════
local FX = {
	CameraEnabled = true,
	FovBoost      = 22,    -- на сколько расширяется обзор на максимальной скорости
	FovResponse   = 4,
	ShakeMax      = 0.16,  -- амплитуда тряски, studs
	BankRoll      = 7,     -- наклон камеры в крен, градусы
	RollResponse  = 5,
	GradeEnabled  = true,
	Contrast      = 0.12,
	Saturation    = 0.18,
	Brightness    = -0.02,
	BloomEnabled  = true,
	BloomIntensity = 0.55,
	BloomSize     = 18,
	BloomThreshold = 1.1,
}
-- ═══════════════════════════════════════════════════════════════════════════════
--  §6. Уровни качества
--  Авто-режим понижает уровень, если средний FPS просел.
-- ═══════════════════════════════════════════════════════════════════════════════
local QUALITY_LEVELS = {
	{ name = "ВЫСОКОЕ", orbScale = 1.00, particleScale = 1.00, trail = true,  highlight = true, speedLines = true,  grade = true,  bloom = true  },
	{ name = "СРЕДНЕЕ", orbScale = 0.62, particleScale = 0.55, trail = true,  highlight = true, speedLines = true,  grade = true,  bloom = false },
	{ name = "НИЗКОЕ",  orbScale = 0.38, particleScale = 0.25, trail = false, highlight = true, speedLines = false, grade = false, bloom = false },
}
local QUALITY = {
	level        = 1,        -- текущий уровень, 1..3
	auto         = true,     -- авто-понижение
	fpsFloor     = 42,       -- ниже этого среднего FPS понижаем уровень
	fpsCeil      = 58,       -- выше этого — пробуем вернуть уровень назад
	averageWindow = 1.2,     -- окно усреднения, сек
}
-- ═══════════════════════════════════════════════════════════════════════════════
--  §7. Темы оформления
--  aura — цвет заливки контура (чёрный), shimmer — палитра переливания.
-- ═══════════════════════════════════════════════════════════════════════════════
local THEMES = {
	{
		id = "VOID",
		label = "VOID · фиолет",
		backTop     = Color3.fromRGB(19, 15, 30),
		backBottom  = Color3.fromRGB(7, 6, 11),
		edge        = Color3.fromRGB(62, 52, 92),
		text        = Color3.fromRGB(238, 235, 248),
		muted       = Color3.fromRGB(139, 132, 163),
		track       = Color3.fromRGB(30, 27, 42),
		accent      = Color3.fromRGB(166, 128, 255),
		accentSoft  = Color3.fromRGB(61, 44, 108),
		aura        = Color3.fromRGB(0, 0, 0),
		shimmer     = {
			Color3.fromRGB(120, 86, 255),
			Color3.fromRGB(74, 176, 255),
			Color3.fromRGB(196, 104, 255),
			Color3.fromRGB(84, 232, 220),
			Color3.fromRGB(120, 86, 255),
		},
	},
	{
		id = "ABYSS",
		label = "ABYSS · циан",
		backTop     = Color3.fromRGB(12, 22, 30),
		backBottom  = Color3.fromRGB(5, 8, 12),
		edge        = Color3.fromRGB(44, 78, 96),
		text        = Color3.fromRGB(232, 244, 248),
		muted       = Color3.fromRGB(124, 150, 164),
		track       = Color3.fromRGB(22, 34, 42),
		accent      = Color3.fromRGB(96, 214, 255),
		accentSoft  = Color3.fromRGB(30, 70, 94),
		aura        = Color3.fromRGB(0, 0, 0),
		shimmer     = {
			Color3.fromRGB(64, 190, 255),
			Color3.fromRGB(120, 255, 230),
			Color3.fromRGB(70, 130, 255),
			Color3.fromRGB(180, 240, 255),
			Color3.fromRGB(64, 190, 255),
		},
	},
	{
		id = "EMBER",
		label = "EMBER · маджента",
		backTop     = Color3.fromRGB(28, 14, 24),
		backBottom  = Color3.fromRGB(10, 5, 9),
		edge        = Color3.fromRGB(92, 48, 74),
		text        = Color3.fromRGB(250, 236, 244),
		muted       = Color3.fromRGB(164, 126, 146),
		track       = Color3.fromRGB(40, 22, 32),
		accent      = Color3.fromRGB(255, 118, 190),
		accentSoft  = Color3.fromRGB(104, 36, 78),
		aura        = Color3.fromRGB(0, 0, 0),
		shimmer     = {
			Color3.fromRGB(255, 92, 170),
			Color3.fromRGB(255, 156, 90),
			Color3.fromRGB(214, 96, 255),
			Color3.fromRGB(255, 210, 120),
			Color3.fromRGB(255, 92, 170),
		},
	},
}
-- ═══════════════════════════════════════════════════════════════════════════════
--  §8. Мелкие утилиты
-- ═══════════════════════════════════════════════════════════════════════════════
local Util = {}
-- Создание инстанса с детьми одной строкой: удобно и читаемо.
function Util.create(className, props, children)
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end
-- FontFace — современный способ; на старых клиентах откат на Font.
function Util.setFont(object, font)
	if pcall(function()
		object.FontFace = Font.fromEnum(font)
	end) then
		return
	end
	object.Font = font
end
function Util.tween(instance, duration, props, style, direction)
	local info = TweenInfo.new(
		duration,
		style or Enum.EasingStyle.Quart,
		direction or Enum.EasingDirection.Out
	)
	local animation = TweenService:Create(instance, info, props)
	animation:Play()
	return animation
end
function Util.isTyping()
	local ok, textBox = pcall(function()
		return UserInputService:GetFocusedTextBox()
	end)
	return ok and textBox ~= nil
end
function Util.clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end
-- Экспоненциальное сглаживание: одинаковая плавность при любом FPS.
function Util.smooth(current, target, speed, delta)
	return current + (target - current) * (1 - math.exp(-speed * delta))
end
function Util.smoothVector(current, target, speed, delta)
	return current:Lerp(target, 1 - math.exp(-speed * delta))
end
function Util.colorSequence(colors)
	local keypoints = {}
	local count = #colors
	for index, color in ipairs(colors) do
		keypoints[index] = ColorSequenceKeypoint.new((index - 1) / (count - 1), color)
	end
	return ColorSequence.new(keypoints)
end
function Util.numberSequence(values)
	local keypoints = {}
	local count = #values
	for index, value in ipairs(values) do
		keypoints[index] = NumberSequenceKeypoint.new((index - 1) / (count - 1), value)
	end
	return NumberSequence.new(keypoints)
end
-- Предрасчёт колеса оттенков: вместо Color3.fromHSV каждый кадр берём готовый.
local HUE_STEPS = 48
local HUE_WHEEL = table.create(HUE_STEPS)
for index = 1, HUE_STEPS do
	HUE_WHEEL[index] = Color3.fromHSV((index - 1) / HUE_STEPS, 0.62, 1)
end
function Util.wheelColor(phase)
	local index = math.floor((phase % 1) * HUE_STEPS) + 1
	return HUE_WHEEL[index]
end
function Util.round(value)
	return math.floor(value + 0.5)
end
function Util.now()
	return os.clock()
end
-- ═══════════════════════════════════════════════════════════════════════════════
--  §9. Тема: единое место, откуда интерфейс и аура берут цвета
--  Слушатели перекрашиваются сами, поэтому смена темы ничего не ломает.
-- ═══════════════════════════════════════════════════════════════════════════════
local Theme = {
	index = 1,
	listeners = {},
	current = THEMES[1],
}
function Theme.get()
	return Theme.current
end
function Theme.onChange(callback)
	table.insert(Theme.listeners, callback)
	callback(Theme.current)
end
function Theme.apply(index)
	local wrapped = ((index - 1) % #THEMES) + 1
	Theme.index = wrapped
	Theme.current = THEMES[wrapped]
	for _, callback in ipairs(Theme.listeners) do
		callback(Theme.current)
	end
end
function Theme.next()
	Theme.apply(Theme.index + 1)
	return Theme.current
end
-- ═══════════════════════════════════════════════════════════════════════════════
--  §10. Кэш ввода
--  Клавиши читаются из событий, а не опросом IsKeyDown каждый кадр: это дешевле
--  и одинаково работает для клавиатуры и кнопок геймпада.
-- ═══════════════════════════════════════════════════════════════════════════════
local Input = {
	keys = {},
	gamepad = false,
	thumbstick = Vector3.zero,
	triggers = { left = 0, right = 0 },
}
function Input.isDown(keyCode)
	return Input.keys[keyCode] == true
end
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode ~= Enum.KeyCode.Unknown then
		Input.keys[input.KeyCode] = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.Unknown then
		Input.keys[input.KeyCode] = false
	end
end)
UserInputService.GamepadConnected:Connect(function()
	Input.gamepad = true
end)
UserInputService.GamepadDisconnected:Connect(function()
	Input.gamepad = false
	Input.thumbstick = Vector3.zero
	Input.triggers = { left = 0, right = 0 }
end)
-- Опрос стиков только если геймпад подключён: иначе это лишняя работа каждый кадр.
function Input.pollGamepad()
	if not Input.gamepad then
		return
	end
	local state = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
	if not state then
		return
	end
	local move = Vector3.zero
	for _, inputObject in ipairs(state) do
		if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 then
			move = Vector3.new(inputObject.Position.X, 0, inputObject.Position.Y)
		elseif inputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
			Input.thumbstick = Vector3.new(inputObject.Position.X, inputObject.Position.Y, 0)
		elseif inputObject.KeyCode == Enum.KeyCode.ButtonR2 then
			Input.triggers.right = inputObject.Position.Z
		elseif inputObject.KeyCode == Enum.KeyCode.ButtonL2 then
			Input.triggers.left = inputObject.Position.Z
		end
	end
	Input.gamepadMove = move
end
-- ═══════════════════════════════════════════════════════════════════════════════
--  §11. Эффекты камеры и пост-обработка
--  Привязывается позже стандартной камеры, иначе она перезапишет наш наклон.
-- ═══════════════════════════════════════════════════════════════════════════════
local CameraFX = {
	enabled = false,
	bound = false,
	baseFov = 70,
	roll = 0,
	shakeTime = 0,
	intensity = 0,
	humanoid = nil,
	grade = nil,
	bloom = nil,
}
CameraFX.BIND_NAME = "FlightControllerCamera"
function CameraFX:_ensureEffects()
	if FX.GradeEnabled and not self.grade then
		local existing = Lighting:FindFirstChild("FlightControllerGrade")
		if existing then
			self.grade = existing
		else
			self.grade = Util.create("ColorCorrectionEffect", {
				Name = "FlightControllerGrade",
				Enabled = false,
				Contrast = 0,
				Saturation = 0,
				Brightness = 0,
				Parent = Lighting,
			})
		end
	end
	if FX.BloomEnabled and not self.bloom then
		local existing = Lighting:FindFirstChild("FlightControllerBloom")
		if existing then
			self.bloom = existing
		else
			self.bloom = Util.create("BloomEffect", {
				Name = "FlightControllerBloom",
				Enabled = false,
				Intensity = 0,
				Size = FX.BloomSize,
				Threshold = FX.BloomThreshold,
				Parent = Lighting,
			})
		end
	end
end
function CameraFX:_updateGrade(delta, target)
	if self.grade then
		local quality = QUALITY_LEVELS[QUALITY.level]
		local on = FX.GradeEnabled and quality.grade and target > 0.01
		self.grade.Enabled = on
		if on then
			self.grade.Contrast = Util.smooth(self.grade.Contrast, FX.Contrast * target, 4, delta)
			self.grade.Saturation = Util.smooth(self.grade.Saturation, FX.Saturation * target, 4, delta)
			self.grade.Brightness = Util.smooth(self.grade.Brightness, FX.Brightness * target, 4, delta)
		end
	end
	if self.bloom then
		local quality = QUALITY_LEVELS[QUALITY.level]
		local on = FX.BloomEnabled and quality.bloom and target > 0.01
		self.bloom.Enabled = on
		if on then
			self.bloom.Intensity = Util.smooth(self.bloom.Intensity, FX.BloomIntensity * target, 4, delta)
		end
	end
end
function CameraFX:setEnabled(state)
	if state == self.enabled then
		return
	end
	self.enabled = state
	if state then
		self:_ensureEffects()
		local camera = Workspace.CurrentCamera
		if camera then
			self.baseFov = camera.FieldOfView
		end
		if not self.bound then
			self.bound = true
			RunService:BindToRenderStep(
				CameraFX.BIND_NAME,
				Enum.RenderPriority.Camera.Value + 1,
				function(delta)
					self:step(delta)
				end
			)
		end
	else
		if self.bound then
			self.bound = false
			RunService:UnbindFromRenderStep(CameraFX.BIND_NAME)
		end
		local camera = Workspace.CurrentCamera
		if camera then
			camera.FieldOfView = self.baseFov
		end
		if self.humanoid and self.humanoid.Parent then
			self.humanoid.CameraOffset = Vector3.zero
		end
		self.roll = 0
		self:_updateGrade(1, 0)
	end
end
function CameraFX:step(delta)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local target = self.intensity
	local quality = QUALITY_LEVELS[QUALITY.level]
	-- Обзор расширяется от скорости: даёт ощущение разгона.
	local fovTarget = self.baseFov + FX.FovBoost * target
	camera.FieldOfView = Util.smooth(camera.FieldOfView, fovTarget, FX.FovResponse, delta)
	-- Лёгкая тряска на большой скорости.
	self.shakeTime += delta
	local shake = FX.ShakeMax * target * target
	if self.humanoid and self.humanoid.Parent then
		local offset = Vector3.new(
			math.sin(self.shakeTime * 37.1) * shake,
			math.sin(self.shakeTime * 41.7 + 1.3) * shake,
			0
		)
		self.humanoid.CameraOffset = Util.smoothVector(self.humanoid.CameraOffset, offset, 18, delta)
	end
	-- Наклон камеры в крен: пишем после стандартной камеры, поэтому не спорим с ней.
	local rollTarget = math.rad(self.bankRoll or 0)
	self.roll = Util.smooth(self.roll, rollTarget, FX.RollResponse, delta)
	if math.abs(self.roll) > 0.0005 then
		camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, self.roll)
	end
	self:_updateGrade(delta, quality.grade and target or 0)
end
-- Обратная связь от полёта: скорость, крен, персонаж.
function CameraFX:feed(speedRatio, bankRoll, humanoid)
	self.intensity = speedRatio
	self.bankRoll = bankRoll
	self.humanoid = humanoid
end
-- ═══════════════════════════════════════════════════════════════════════════════
--  §12. Аура: чёрная подсветка, шлейфы, дым, искры, орбита тёмных сфер
--  Всё живёт в отдельной папке в Workspace и полностью выключается вне полёта,
--  поэтому в покое аура не стоит ни одного кадра симуляции частиц.
-- ═══════════════════════════════════════════════════════════════════════════════
local AURA_TEXTURES = {
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	spark = "rbxasset://textures/particles/sparkles_main.dds",
}
-- Предрасчёт на старте: ни одной новой ColorSequence за кадр.
local TRAIL_SEQUENCES = table.create(HUE_STEPS)
local SPARK_SEQUENCES = table.create(HUE_STEPS)
local ORB_TINTS = table.create(HUE_STEPS)
for index = 1, HUE_STEPS do
	TRAIL_SEQUENCES[index] = Util.colorSequence({ Color3.fromRGB(0, 0, 0), HUE_WHEEL[index] })
	SPARK_SEQUENCES[index] = ColorSequence.new(HUE_WHEEL[index])
	ORB_TINTS[index] = HUE_WHEEL[index]:Lerp(Color3.fromRGB(0, 0, 0), 0.84)
end
-- Ступени затухания шлейфа: шесть готовых последовательностей вместо сборки на кадр.
local TRAIL_FADE_STEPS = 6
local TRAIL_FADE_BLACK = table.create(TRAIL_FADE_STEPS)
local TRAIL_FADE_ACCENT = table.create(TRAIL_FADE_STEPS)
for step = 1, TRAIL_FADE_STEPS do
	local strength = (step - 1) / (TRAIL_FADE_STEPS - 1)
	TRAIL_FADE_BLACK[step] = Util.numberSequence({ 1 - (1 - AURA.TrailBlack) * strength, 1 })
	TRAIL_FADE_ACCENT[step] = Util.numberSequence({ 1 - (1 - AURA.TrailAccent) * strength, 1 })
end
local Aura = {}
Aura.__index = Aura
function Aura.new()
	return setmetatable({
		folder = nil,
		core = nil,
		root = nil,
		character = nil,
		orbs = {},
		power = 0,
		hue = 0,
		spin = 0,
		wheelIndex = 0,
		fadeStep = 0,
		activeObjects = false,
	}, Aura)
end
function Aura:setEnabled(state)
	AURA.Enabled = state and true or false
	return AURA.Enabled
end
function Aura:toggle()
	return self:setEnabled(not AURA.Enabled)
end
function Aura:isEnabled()
	return AURA.Enabled
end
function Aura:applyTheme(theme)
	if self.highlight then
		self.highlight.FillColor = theme.aura
	end
end
function Aura:attach(root, character)
	if self.folder and self.root == root then
		return
	end
	self:detach()
	self.root = root
	self.character = character
	local folder = Util.create("Folder", { Name = "FlightAura", Parent = Workspace })
	self.folder = folder
	-- Невидимое «ядро»: к нему крепим шлейфы и излучатели, и разворачиваем его
	-- по направлению движения — тогда дым всегда уходит строго назад.
	local core = Util.create("Part", {
		Name = "AuraCore",
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Anchored = true,
		Massless = true,
		Parent = folder,
	})
	self.core = core
	local leftPoint = Util.create("Attachment", {
		Name = "AuraLeft",
		Position = Vector3.new(-AURA.TrailWidth, 0, 0),
		Parent = core,
	})
	local rightPoint = Util.create("Attachment", {
		Name = "AuraRight",
		Position = Vector3.new(AURA.TrailWidth, 0, 0),
		Parent = core,
	})
	self.highlight = Util.create("Highlight", {
		Name = "AuraHighlight",
		Adornee = character,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		FillColor = Theme.get().aura,
		FillTransparency = 1,
		OutlineColor = Theme.get().accent,
		OutlineTransparency = 1,
		Enabled = false,
		Parent = folder,
	})
	self.trailBlack = Util.create("Trail", {
		Name = "AuraTrailBlack",
		Attachment0 = leftPoint,
		Attachment1 = rightPoint,
		Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
		Transparency = TRAIL_FADE_BLACK[1],
		Lifetime = AURA.TrailLifetime,
		MinLength = 0,
		LightEmission = 0,
		FaceCamera = false,
		Enabled = false,
		Parent = core,
	})
	self.trailAccent = Util.create("Trail", {
		Name = "AuraTrailAccent",
		Attachment0 = leftPoint,
		Attachment1 = rightPoint,
		Color = TRAIL_SEQUENCES[1],
		Transparency = TRAIL_FADE_ACCENT[1],
		Lifetime = AURA.TrailLifetime * 1.3,
		MinLength = 0,
		LightEmission = 0.4,
		FaceCamera = false,
		Enabled = false,
		Parent = core,
	})
	self.smoke = Util.create("ParticleEmitter", {
		Name = "AuraSmoke",
		Texture = AURA_TEXTURES.smoke,
		Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
		Size = Util.numberSequence({ 3.4, 0.7 }),
		Transparency = Util.numberSequence({ 1, 0.34, 1 }),
		Lifetime = NumberRange.new(0.85, 1.5),
		Rate = 0,
		Speed = NumberRange.new(1, 3.2),
		SpreadAngle = Vector2.new(26, 26),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-45, 45),
		LightEmission = 0,
		LightInfluence = 1,
		Acceleration = Vector3.new(0, 1.4, 0),
		Drag = 1.2,
		EmissionDirection = Enum.NormalId.Back,
		VelocityInheritance = 0.15,
		Enabled = false,
		Parent = core,
	})
	self.spark = Util.create("ParticleEmitter", {
		Name = "AuraSpark",
		Texture = AURA_TEXTURES.spark,
		Color = SPARK_SEQUENCES[1],
		Size = Util.numberSequence({ 0.34, 0.02 }),
		Transparency = Util.numberSequence({ 0.2, 1 }),
		Lifetime = NumberRange.new(0.5, 1.1),
		Rate = 0,
		Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-90, 90),
		LightEmission = 0.7,
		LightInfluence = 0,
		Drag = 0.6,
		EmissionDirection = Enum.NormalId.Back,
		VelocityInheritance = 0.1,
		Enabled = false,
		Parent = core,
	})
	self.lines = Util.create("ParticleEmitter", {
		Name = "AuraSpeedLines",
		Texture = AURA_TEXTURES.spark,
		Color = SPARK_SEQUENCES[1],
		Size = Util.numberSequence({ 0.16, 0.04 }),
		Transparency = Util.numberSequence({ 0.55, 1 }),
		Lifetime = NumberRange.new(0.22, 0.4),
		Rate = 0,
		Speed = NumberRange.new(42, 74),
		SpreadAngle = Vector2.new(7, 7),
		Rotation = NumberRange.new(0, 360),
		LightEmission = 0.8,
		LightInfluence = 0,
		EmissionDirection = Enum.NormalId.Back,
		VelocityInheritance = 0,
		Enabled = false,
		Parent = core,
	})
	for index = 1, AURA.OrbCount do
		self.orbs[index] = Util.create("Part", {
			Name = "AuraOrb" .. index,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(AURA.OrbSize, AURA.OrbSize, AURA.OrbSize),
			Color = ORB_TINTS[1],
			Material = Enum.Material.SmoothPlastic,
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Anchored = true,
			Massless = true,
			Parent = folder,
		})
	end
	self.light = Util.create("PointLight", {
		Name = "AuraLight",
		Color = Theme.get().accent,
		Brightness = 0,
		Range = AURA.LightRange,
		Shadows = false,
		Enabled = false,
		Parent = core,
	})
end
function Aura:detach()
	if self.folder then
		self.folder:Destroy()
	end
	self.folder = nil
	self.core = nil
	self.highlight = nil
	self.trailBlack = nil
	self.trailAccent = nil
	self.smoke = nil
	self.spark = nil
	self.lines = nil
	self.light = nil
	self.orbs = {}
	self.activeObjects = false
	self.fadeStep = 0
	self.power = 0
end
function Aura:_setObjectsEnabled(state)
	local quality = QUALITY_LEVELS[QUALITY.level]
	if self.highlight then
		self.highlight.Enabled = state and quality.highlight or false
	end
	if self.trailBlack then
		self.trailBlack.Enabled = state and quality.trail or false
		self.trailAccent.Enabled = state and quality.trail or false
	end
	if self.smoke then
		self.smoke.Enabled = state
		self.spark.Enabled = state
		self.lines.Enabled = state and quality.speedLines or false
	end
	if self.light then
		self.light.Enabled = state
		if not state then
			self.light.Brightness = 0
		end
	end
end
-- delta — время кадра, active — идёт ли полёт, root — HumanoidRootPart,
-- velocity — текущая скорость персонажа, speedRatio — 0..1 от максимума.
function Aura:update(delta, active, root, velocity, speedRatio)
	if not self.folder or not self.core then
		return
	end
	if root then
		self.root = root
	end
	if not self.root or not self.root.Parent then
		return
	end
	local target = (AURA.Enabled and active) and 1 or 0
	self.power = Util.smooth(self.power, target, AURA.FadeSpeed, delta)
	self.hue = (self.hue + delta * AURA.HueSpeed) % 1
	if self.power <= 0.02 then
		if self.activeObjects then
			self:_setObjectsEnabled(false)
			self.activeObjects = false
		end
		return
	end
	if not self.activeObjects then
		self:_setObjectsEnabled(true)
		self.activeObjects = true
	end
	local quality = QUALITY_LEVELS[QUALITY.level]
	local power = self.power
	-- Переливание: перекрашиваем только когда сменилась ступень колеса оттенков,
	-- а не каждый кадр — это позволяет вообще не создавать объекты в цикле.
	local wheelIndex = math.floor(self.hue * HUE_STEPS) + 1
	if wheelIndex ~= self.wheelIndex then
		self.wheelIndex = wheelIndex
		if self.highlight then
			self.highlight.OutlineColor = HUE_WHEEL[wheelIndex]
		end
		if self.trailAccent then
			self.trailAccent.Color = TRAIL_SEQUENCES[wheelIndex]
		end
		if self.spark then
			self.spark.Color = SPARK_SEQUENCES[wheelIndex]
		end
		if self.lines then
			self.lines.Color = SPARK_SEQUENCES[wheelIndex]
		end
		if self.light then
			self.light.Color = HUE_WHEEL[wheelIndex]
		end
	end
	-- Ядро ауры: позиция персонажа, разворот по вектору движения.
	local position = self.root.Position
	local direction = self.root.CFrame.LookVector
	if velocity and velocity.Magnitude > 0.6 then
		direction = velocity.Unit
	end
	self.core.CFrame = CFrame.lookAt(position, position + direction)
	if self.highlight then
		self.highlight.FillTransparency = 1 - (1 - AURA.HighlightFill) * power
		self.highlight.OutlineTransparency = 1 - (1 - AURA.HighlightEdge) * power
	end
	local fadeStep = Util.clamp(math.ceil(power * TRAIL_FADE_STEPS), 1, TRAIL_FADE_STEPS)
	if fadeStep ~= self.fadeStep then
		self.fadeStep = fadeStep
		if self.trailBlack then
			self.trailBlack.Transparency = TRAIL_FADE_BLACK[fadeStep]
			self.trailAccent.Transparency = TRAIL_FADE_ACCENT[fadeStep]
		end
	end
	local particleScale = quality.particleScale
	self.smoke.Rate = AURA.SmokeRate * particleScale * power
	self.spark.Rate = AURA.SparkRate * particleScale * power * (0.45 + 0.55 * speedRatio)
	self.lines.Rate = quality.speedLines and (AURA.LineRate * particleScale * power * math.max(speedRatio - 0.4, 0) * 1.6) or 0
	if self.light then
		self.light.Brightness = AURA.LightBrightness * power * (0.7 + 0.3 * speedRatio)
	end
	-- Орбита тёмных сфер: мировая горизонтальная окружность вокруг персонажа.
	self.spin = (self.spin + delta * AURA.OrbSpin * math.pi * 2) % (math.pi * 2)
	local visible = math.max(1, math.floor(AURA.OrbCount * quality.orbScale))
	local radius = AURA.OrbRadius * (0.8 + 0.35 * speedRatio)
	local orbTransparency = 1 - (1 - AURA.OrbTransparency) * power
	local tint = ORB_TINTS[self.wheelIndex > 0 and self.wheelIndex or 1]
	for index, orb in ipairs(self.orbs) do
		if index <= visible then
			local angle = self.spin + (index - 1) * (math.pi * 2 / visible)
			local offset = Vector3.new(
				math.cos(angle) * radius,
				math.sin(angle * 1.7) * AURA.OrbRise,
				math.sin(angle) * radius
			)
			orb.CFrame = CFrame.new(position + offset)
			orb.Transparency = orbTransparency
			orb.Color = tint
		elseif orb.Transparency ~= 1 then
			orb.Transparency = 1
		end
	end
end
local AuraInstance = Aura.new()
Theme.onChange(function(theme)
	AuraInstance:applyTheme(theme)
end)
-- ═══════════════════════════════════════════════════════════════════════════════
--  §13. Суставы: поиск, позы, ориентация корпуса
--  Имена подходят и для R15, и для R6: чего в риге нет — то просто пропускается.
-- ═══════════════════════════════════════════════════════════════════════════════
local JOINT_ALIASES = {
	root          = { "Root", "RootJoint" },
	waist         = { "Waist" },
	neck          = { "Neck" },
	leftShoulder  = { "LeftShoulder", "Left Shoulder" },
	rightShoulder = { "RightShoulder", "Right Shoulder" },
	leftElbow     = { "LeftElbow" },
	rightElbow    = { "RightElbow" },
	leftHip       = { "LeftHip", "Left Hip" },
	rightHip      = { "RightHip", "Right Hip" },
	leftKnee      = { "LeftKnee" },
	rightKnee     = { "RightKnee" },
}
local function captureJoints(character)
	local found = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			for key, names in pairs(JOINT_ALIASES) do
				if not found[key] then
					for _, name in ipairs(names) do
						if descendant.Name == name then
							found[key] = descendant
							break
						end
					end
				end
			end
		end
	end
	return found
end
-- Ориентация корпуса в мировом пространстве для горизонтального полёта:
-- «вверх» тела смотрит по направлению движения, лицо — вниз.
local function proneRotation(moveDirection)
	local spine = moveDirection.Unit
	local front = Vector3.yAxis * -1
	front = front - spine * front:Dot(spine)
	if front.Magnitude < 0.01 then
		front = spine:Cross(Vector3.xAxis)
		if front.Magnitude < 0.01 then
			front = spine:Cross(Vector3.zAxis)
		end
	end
	front = front.Unit
	return CFrame.fromMatrix(Vector3.zero, front:Cross(spine), spine, -front)
end
-- ═══════════════════════════════════════════════════════════════════════════════
--  §14. Ядро полёта
-- ═══════════════════════════════════════════════════════════════════════════════
local Flight = {}
Flight.__index = Flight
function Flight.new()
	return setmetatable({
		active = false,
		restoring = false,
		rolling = false,
		speed = FLIGHT.StartSpeed,
		speedRatio = 0,
		velocity = Vector3.zero,
		root = nil,
		humanoid = nil,
		character = nil,
		mover = nil,
		stepConnection = nil,
		animatorConnection = nil,
		joints = {},
		original = {},
		pose = {},
		body = CFrame.new(),
		blend = 0,
		dive = 0,
		lateral = 0,
		rollExtra = 0,
		noclipSaved = nil,
	}, Flight)
end
function Flight:isActive()
	return self.active
end
function Flight:getSpeedRatio()
	return self.speedRatio
end
function Flight:setSpeed(value)
	self.speed = Util.clamp(value, FLIGHT.MinSpeed, FLIGHT.MaxSpeed)
	return self.speed
end
function Flight:getStateLabel()
	if not self.active then
		return "ОЖИДАНИЕ"
	end
	if self.rolling then
		return "БОЧКА"
	end
	if self.blend < 0.25 then
		return "ВИСЕНИЕ"
	end
	if self.dive > 0.5 then
		return "ПИКИРОВАНИЕ"
	end
	return "ПОЛЁТ"
end
function Flight:_clearMover()
	if not self.mover then
		return
	end
	if self.mover.constraint then
		self.mover.constraint:Destroy()
	end
	if self.mover.attachment then
		self.mover.attachment:Destroy()
	end
	self.mover = nil
end
function Flight:_makeMover(root)
	local ok, mover = pcall(function()
		local attachment = Instance.new("Attachment")
		attachment.Name = "FlightAttachment"
		local constraint = Instance.new("LinearVelocity")
		constraint.Name = "FlightVelocity"
		constraint.Attachment0 = attachment
		constraint.RelativeTo = Enum.ActuatorRelativeTo.World
		constraint.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		constraint.VectorVelocity = Vector3.zero
		constraint.Enabled = false
		attachment.Parent = root
		constraint.Parent = root
		return { kind = "constraint", attachment = attachment, constraint = constraint }
	end)
	if ok and mover then
		return mover
	end
	-- Старый клиент: подчищаем возможные остатки и двигаем напрямую через скорость.
	for _, name in ipairs({ "FlightAttachment", "FlightVelocity" }) do
		local leftover = root:FindFirstChild(name)
		if leftover then
			leftover:Destroy()
		end
	end
	return { kind = "velocity" }
end
function Flight:_capturePose(character)
	self.joints = captureJoints(character)
	self.original = {}
	self.pose = {}
	for key, motor in pairs(self.joints) do
		self.original[key] = motor.C0
		self.pose[key] = { x = 0, y = 0, z = 0 }
	end
	self.body = CFrame.new()
	self.blend = 0
	self.dive = 0
	self.lateral = 0
	self.rollExtra = 0
	self.restoring = false
end
-- Поворот сустава: исходный CFrame сохраняет смещение, добавляется только вращение.
function Flight:_applyJoint(key, angles)
	local motor = self.joints[key]
	local original = self.original[key]
	if not motor or not original then
		return
	end
	local rotation = CFrame.Angles(angles.x, angles.y, angles.z)
	motor.C0 = CFrame.new(original.Position) * (rotation * original.Rotation)
end
-- Наклон всего корпуса: крен добавляется здесь, чтобы не накапливался в self.body.
function Flight:_applyBody(extraRoll)
	local root = self.root
	local original = self.original.root
	local motor = self.joints.root
	if not root or not original or not motor then
		return
	end
	local body = self.body
	if extraRoll and math.abs(extraRoll) > 0.0001 then
		body = body * CFrame.Angles(0, extraRoll, 0)
	end
	local hrp = root.CFrame.Rotation
	local localDelta = hrp:Inverse() * body * hrp
	motor.C0 = CFrame.new(original.Position) * (localDelta * original.Rotation)
end
function Flight:_poseTargets()
	local blend = self.blend
	local hover = 1 - blend
	local dive = self.dive
	local bob = math.sin(Util.now() * 2.2) * math.rad(ANIM.BobDegrees) * hover
	local armForward = math.rad(ANIM.ArmForward) * blend * (1 - dive)
	local armDive = math.rad(ANIM.ArmDive) * blend * dive
	local armBack = math.rad(ANIM.ArmHoverBack) * hover
	local armSpread = math.rad(ANIM.ArmSpread) * hover
	local armYaw = math.rad(ANIM.ArmHoverYaw) * hover
	local armYawDive = math.rad(ANIM.ArmDiveYaw) * blend * dive
	local elbow = math.rad(ANIM.ElbowHover) * hover
		+ math.rad(ANIM.ElbowProne) * blend * (1 - dive)
		+ math.rad(ANIM.ElbowDive) * blend * dive
	local knee = math.rad(ANIM.KneeHover) * hover
		+ math.rad(ANIM.KneeProne) * blend * (1 - dive)
		+ math.rad(ANIM.KneeDive) * blend * dive
	local head = math.rad(ANIM.HeadHover) * hover
		+ math.rad(ANIM.HeadUpProne) * blend * (1 - dive)
		+ math.rad(ANIM.HeadDive) * blend * dive
	local hip = math.rad(ANIM.HipProne) * blend
	local legSpread = math.rad(ANIM.LegSpread) * hover
	local shoulderX = armForward + armDive + armBack
	local shoulderY = armYaw + armYawDive
	return {
		waist = { x = math.rad(ANIM.LeanHover) * hover + math.rad(ANIM.WaistArch) * blend + bob * 0.4 },
		neck = { x = head + bob * ANIM.NeckBob },
		leftShoulder = { x = shoulderX, y = shoulderY, z = -armSpread },
		rightShoulder = { x = shoulderX, y = -shoulderY, z = armSpread },
		leftElbow = { x = elbow },
		rightElbow = { x = elbow },
		leftHip = { x = hip, z = legSpread },
		rightHip = { x = hip, z = -legSpread },
		leftKnee = { x = knee },
		rightKnee = { x = knee },
	}
end
function Flight:_applyPose(delta)
	local targets = self.restoring and {} or self:_poseTargets()
	local alpha = 1 - math.exp(-ANIM.Response * delta)
	for key, current in pairs(self.pose) do
		local target = targets[key]
		current.x += ((target and target.x or 0) - current.x) * alpha
		current.y += ((target and target.y or 0) - current.y) * alpha
		current.z += ((target and target.z or 0) - current.z) * alpha
		self:_applyJoint(key, current)
	end
end
function Flight:_poseSettled()
	if self.blend > 0.02 or math.abs(self.rollExtra) > 1 then
		return false
	end
	for _, angles in pairs(self.pose) do
		if math.abs(angles.x) > 0.01 or math.abs(angles.y) > 0.01 or math.abs(angles.z) > 0.01 then
			return false
		end
	end
	return true
end
function Flight:_restoreOriginalPose()
	for key, motor in pairs(self.joints) do
		local original = self.original[key]
		if original and motor.Parent then
			motor.C0 = original
		end
	end
	self.restoring = false
	self.blend = 0
	self.dive = 0
	self.lateral = 0
	self.rollExtra = 0
	self.body = CFrame.new()
end
-- Тестовый режим: персонаж перестаёт сталкиваться со стенами.
function Flight:_setNoclip(state)
	local character = self.character
	if not character then
		return
	end
	if state then
		if self.noclipSaved then
			return
		end
		local saved = {}
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				saved[part] = true
				part.CanCollide = false
			end
		end
		self.noclipSaved = saved
	else
		if not self.noclipSaved then
			return
		end
		for part in pairs(self.noclipSaved) do
			if part.Parent then
				part.CanCollide = true
			end
		end
		self.noclipSaved = nil
	end
end
function Flight:_readDirection(camera)
	local direction = Vector3.zero
	if Util.isTyping() then
		return direction
	end
	if camera then
		local look = camera.CFrame.LookVector
		local right = camera.CFrame.RightVector
		if Input.isDown(Enum.KeyCode.W) then direction += look end
		if Input.isDown(Enum.KeyCode.S) then direction -= look end
		if Input.isDown(Enum.KeyCode.D) then direction += right end
		if Input.isDown(Enum.KeyCode.A) then direction -= right end
		-- Геймпад: стик. Если движение окажется инвертированным — поменяй знак у stick.Z.
		local stick = Input.gamepadMove
		if stick and stick.Magnitude > 0.08 then
			direction += look * -stick.Z + right * stick.X
		end
	end
	if Input.isDown(FLIGHT.UpKey) or Input.isDown(Enum.KeyCode.ButtonA) then
		direction += Vector3.yAxis
	end
	if Input.isDown(FLIGHT.DownKey) or Input.isDown(Enum.KeyCode.ButtonB) then
		direction -= Vector3.yAxis
	end
	if Input.triggers and Input.triggers.left > 0.4 then
		direction -= Vector3.yAxis
	end
	return direction
end
-- Крен вбок: нажатие A/D плюс боковая составляющая фактического движения.
function Flight:_lateralInput(camera)
	local lateral = 0
	if Input.isDown(Enum.KeyCode.D) then lateral += 1 end
	if Input.isDown(Enum.KeyCode.A) then lateral -= 1 end
	local speed = self.velocity.Magnitude
	if camera and speed > 1 then
		local right = camera.CFrame.RightVector
		local flatRight = Vector3.new(right.X, 0, right.Z)
		if flatRight.Magnitude > 0.01 then
			local flatVelocity = Vector3.new(self.velocity.X, 0, self.velocity.Z)
			if flatVelocity.Magnitude > 0.01 then
				lateral += flatRight.Unit:Dot(flatVelocity.Unit) * 0.6
			end
		end
	end
	return Util.clamp(lateral, -1, 1)
end
function Flight:_stepRoll(delta)
	local rollInput = 0
	-- Во время возврата позы ввод бочки игнорируем, иначе угол не дойдёт до нуля
	-- и поза останется недоведённой до исходной.
	if self.active then
		if Input.isDown(Enum.KeyCode.E) or Input.isDown(Enum.KeyCode.ButtonR1) then rollInput += 1 end
		if Input.isDown(Enum.KeyCode.Q) or Input.isDown(Enum.KeyCode.ButtonL1) then rollInput -= 1 end
	end
	if rollInput ~= 0 then
		self.rollExtra += rollInput * FLIGHT.RollSpeed * delta
		self.rolling = true
		return
	end
	self.rolling = false
	if self.rollExtra == 0 then
		return
	end
	-- Приводим угол к диапазону (-180, 180] и плавно возвращаемся к нулю.
	self.rollExtra = self.rollExtra % 360
	if self.rollExtra > 180 then
		self.rollExtra -= 360
	end
	local step = FLIGHT.RollReturn * delta
	if math.abs(self.rollExtra) <= step then
		self.rollExtra = 0
	else
		self.rollExtra -= (self.rollExtra > 0 and step or -step)
	end
end
function Flight:bind(character)
	self:deactivate()
	self:_restoreOriginalPose()
	self:_clearMover()
	self.velocity = Vector3.zero
	self.speedRatio = 0
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then
		return
	end
	self.character = character
	self.humanoid = humanoid
	self.root = root
	self.mover = self:_makeMover(root)
	self:_capturePose(character)
	if self.animatorConnection then
		self.animatorConnection:Disconnect()
		self.animatorConnection = nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		-- Во время полёта глушим штатные анимации: иначе они спорят с нашей позой.
		self.animatorConnection = animator.AnimationPlayed:Connect(function(track)
			if self.active then
				track:Stop(0)
			end
		end)
	end
	-- Отдельный цикл кадров здесь не создаём: шаг полёта вызывает главный цикл
	-- в §18, поэтому на весь скрипт приходится ровно один RenderStepped.
end
function Flight:activate()
	if self.active or not self.root or not self.humanoid then
		return false
	end
	local humanoid = self.humanoid
	if humanoid.Health <= 0 then
		return false
	end
	self.active = true
	self.restoring = false
	local root = self.root
	self.velocity = root.AssemblyLinearVelocity
	local limit = self.speed * FLIGHT.BoostFactor
	if self.velocity.Magnitude > limit then
		self.velocity = self.velocity.Unit * limit
	end
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.PlatformStand = true
	if self.mover and self.mover.constraint then
		self.mover.constraint.Enabled = true
	end
	if FLIGHT.Noclip then
		self:_setNoclip(true)
	end
	return true
end
function Flight:deactivate()
	if not self.active then
		return
	end
	self.active = false
	self.restoring = true
	self.velocity = Vector3.zero
	self.speedRatio = 0
	self.rolling = false
	if self.mover and self.mover.constraint then
		self.mover.constraint.VectorVelocity = Vector3.zero
		self.mover.constraint.Enabled = false
	end
	self:_setNoclip(false)
	local humanoid = self.humanoid
	if humanoid and humanoid.Parent and humanoid.Health > 0 then
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end
function Flight:step(delta)
	local root = self.root
	if not root or not root.Parent then
		return
	end
	local camera = Workspace.CurrentCamera
	local flying = self.active
	if flying then
		Input.pollGamepad()
		local direction = self:_readDirection(camera)
		local boosting = Input.isDown(Enum.KeyCode.LeftShift)
			or Input.isDown(Enum.KeyCode.RightShift)
			or (Input.triggers and Input.triggers.right > 0.4)
		local target
		if direction.Magnitude > 0 then
			target = direction.Unit * self.speed * (boosting and FLIGHT.BoostFactor or 1)
		else
			-- Пока висим — еле заметно всплываем и оседаем.
			target = Vector3.yAxis * math.sin(Util.now() * FLIGHT.HoverBobRate) * FLIGHT.HoverBobSpeed
		end
		-- Плавное приближение к цели плюс предохранитель по ускорению:
		-- так резкий рывок не превращается в телепорт через полкарты.
		local desired = self.velocity:Lerp(target, 1 - math.exp(-FLIGHT.Response * delta))
		local change = desired - self.velocity
		local maxChange = FLIGHT.MaxAccel * delta
		if change.Magnitude > maxChange then
			change = change.Unit * maxChange
		end
		self.velocity += change
		if self.mover and self.mover.kind == "constraint" then
			self.mover.constraint.VectorVelocity = self.velocity
		else
			root.AssemblyLinearVelocity = self.velocity
		end
		-- В PlatformStand персонаж не держит равновесие сам — гасим вращение.
		root.AssemblyAngularVelocity = Vector3.zero
	end
	if not flying and not self.restoring then
		return
	end
	local speed = self.velocity.Magnitude
	self.speedRatio = Util.clamp(speed / math.max(self.speed, 1), 0, 1)
	local moveDirection = speed > 1 and self.velocity.Unit or Vector3.zero
	local poseAlpha = 1 - math.exp(-ANIM.Response * delta)
	local blendTarget = 0
	local diveTarget = 0
	local lateralTarget = 0
	if flying then
		blendTarget = Util.clamp((speed - 6) / math.max(self.speed - 6, 1), 0, 1)
		if moveDirection.Magnitude > 0 then
			diveTarget = blendTarget * Util.clamp(-moveDirection.Y, 0, 1)
		end
		lateralTarget = self:_lateralInput(camera)
	end
	-- Бочку считаем и во время возврата позы, чтобы угол гарантированно обнулился.
	self:_stepRoll(delta)
	self.blend = Util.smooth(self.blend, blendTarget, ANIM.Response, delta)
	self.dive = Util.smooth(self.dive, diveTarget, ANIM.Response * 0.8, delta)
	self.lateral = Util.smooth(self.lateral, lateralTarget, ANIM.Response, delta)
	local proneTarget = CFrame.new()
	if moveDirection.Magnitude > 0.001 then
		proneTarget = proneRotation(moveDirection)
	end
	self.body = self.body:Lerp(proneTarget, poseAlpha)
	local bank = -self.lateral * math.rad(ANIM.BankMax) * self.blend
	self:_applyBody(bank + math.rad(self.rollExtra))
	self:_applyPose(delta)
	if FX.CameraEnabled then
		CameraFX:feed(self.speedRatio, math.deg(bank), self.humanoid)
	end
	if self.restoring and self:_poseSettled() then
		self:_restoreOriginalPose()
	end
end
local FlightInstance = Flight.new()
-- ═══════════════════════════════════════════════════════════════════════════════
--  §15. Виджеты интерфейса
--  Перетаскивание и слайдер обслуживаются общими обработчиками: на три панели
--  и один слайдер приходится по одному событию, а не по одному на элемент.
-- ═══════════════════════════════════════════════════════════════════════════════
local Ui = {}
Ui.__index = Ui
-- Объявляем слот заранее: на него ссылается подписка на смену темы ниже,
-- а сама UiInstance создаётся в §17. Иначе замыкание увидело бы не local,
-- а пустую глобальную переменную, и смена темы не перекрашивала бы интерфейс.
local UiInstance
local Drag = { frame = nil, start = nil, origin = nil }
local ActiveSlider = { handler = nil }
UserInputService.InputChanged:Connect(function(input)
	local isPointer = input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	if not isPointer then
		return
	end
	if ActiveSlider.handler then
		ActiveSlider.handler(input.Position.X)
	end
	local frame = Drag.frame
	if frame then
		local delta = input.Position - Drag.start
		frame.Position = UDim2.new(
			Drag.origin.X.Scale, Drag.origin.X.Offset + delta.X,
			Drag.origin.Y.Scale, Drag.origin.Y.Offset + delta.Y
		)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		Drag.frame = nil
		ActiveSlider.handler = nil
	end
end)
local function makeDraggable(frame, handle)
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			Drag.frame = frame
			Drag.start = input.Position
			Drag.origin = frame.Position
		end
	end)
end
local function makeRipple(button, tint)
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local origin = Vector2.new(input.Position.X, input.Position.Y) - button.AbsolutePosition
		local diameter = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
		local ripple = Util.create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(origin.X, origin.Y),
			Size = UDim2.fromOffset(2, 2),
			BackgroundColor3 = tint or Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			ZIndex = (button.ZIndex or 1) + 1,
			Parent = button,
		}, {
			Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
		local animation = Util.tween(ripple, 0.5, {
			Size = UDim2.fromOffset(diameter, diameter),
			BackgroundTransparency = 1,
		}, Enum.EasingStyle.Quad)
		animation.Completed:Once(function()
			ripple:Destroy()
		end)
	end)
end
-- Регистрация цвета в теме: сразу присваиваем и запоминаем для смены темы.
function Ui:_color(instance, property, picker)
	table.insert(self.colorTargets, { instance = instance, property = property, picker = picker })
	instance[property] = picker(Theme.get())
	return instance
end
-- Переливание идёт на текст, тонкие полосы и мелкие детали. Тёмные панели
-- получают мягкий тёмный градиент: радуга на чёрном читалась бы как заливка,
-- а не как переливание, и мешала бы тексту.
local function gradientIsBright(parent)
	if parent:IsA("TextLabel") then
		return true
	end
	return parent.AbsoluteSize.Y <= 14
end
function Ui:_gradient(parent, rotation)
	local palette = gradientIsBright(parent)
		and Theme.get().shimmer
		or { Theme.get().backTop, Theme.get().backBottom }
	local gradient = Util.create("UIGradient", {
		Rotation = rotation or 0,
		Color = Util.colorSequence(palette),
		Parent = parent,
	})
	table.insert(self.gradients, gradient)
	return gradient
end
function Ui:_button(parent, text, size, position, textSize)
	local button = Util.create("TextButton", {
		Size = size,
		Position = position,
		BackgroundTransparency = 0.12,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		Parent = parent,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(0, 9) }),
		Util.create("UIStroke", { Thickness = 1, Transparency = 0.4 }),
	})
	self:_color(button, "BackgroundColor3", function(theme) return theme.track end)
	self:_color(button:FindFirstChildOfClass("UIStroke"), "Color", function(theme) return theme.edge end)
	local label = Util.create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = textSize or 11,
		Parent = button,
	})
	Util.setFont(label, Enum.Font.GothamBold)
	self:_color(label, "TextColor3", function(theme) return theme.text end)
	makeRipple(button)
	button.MouseEnter:Connect(function()
		Util.tween(button, 0.15, { BackgroundTransparency = 0 })
	end)
	button.MouseLeave:Connect(function()
		Util.tween(button, 0.2, { BackgroundTransparency = 0.12 })
	end)
	return button, label
end
function Ui:_switch(parent, y, text, initial, onChange)
	local row = Util.create("TextButton", {
		Position = UDim2.fromOffset(12, y),
		Size = UDim2.new(1, -24, 0, 26),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	})
	local label = Util.create("TextLabel", {
		Size = UDim2.new(1, -58, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	Util.setFont(label, Enum.Font.GothamMedium)
	self:_color(label, "TextColor3", function(theme) return theme.text end)
	local pill = Util.create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(38, 18),
		BorderSizePixel = 0,
		Parent = row,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Util.create("UIStroke", { Thickness = 1, Transparency = 0.45 }),
	})
	self:_color(pill:FindFirstChildOfClass("UIStroke"), "Color", function(theme) return theme.edge end)
	local knob = Util.create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BorderSizePixel = 0,
		Parent = pill,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local controller = { state = initial and true or false }
	function controller:render(animate)
		local theme = Theme.get()
		local duration = animate and 0.18 or 0
		Util.tween(pill, duration, {
			BackgroundColor3 = controller.state and theme.accentSoft or theme.track,
		})
		Util.tween(knob, duration, {
			Position = controller.state and UDim2.new(0, 22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = controller.state and theme.accent or theme.muted,
		})
	end
	function controller:set(value, silent)
		controller.state = value and true or false
		controller:render(true)
		if not silent and onChange then
			onChange(controller.state)
		end
	end
	row.Activated:Connect(function()
		controller:set(not controller.state)
	end)
	controller:render(false)
	return controller
end
function Ui:_actionRow(parent, y, text, onClick)
	local row = Util.create("TextButton", {
		Position = UDim2.fromOffset(12, y),
		Size = UDim2.new(1, -24, 0, 26),
		BackgroundTransparency = 0.12,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		Parent = parent,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Util.create("UIStroke", { Thickness = 1, Transparency = 0.45 }),
	})
	self:_color(row, "BackgroundColor3", function(theme) return theme.track end)
	self:_color(row:FindFirstChildOfClass("UIStroke"), "Color", function(theme) return theme.edge end)
	local label = Util.create("TextLabel", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -112, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	Util.setFont(label, Enum.Font.GothamMedium)
	self:_color(label, "TextColor3", function(theme) return theme.text end)
	local value = Util.create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 92, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	Util.setFont(value, Enum.Font.GothamBold)
	self:_color(value, "TextColor3", function(theme) return theme.accent end)
	makeRipple(row)
	row.Activated:Connect(onClick)
	return row, value
end
function Ui:_slider(parent, position, initial, onChange)
	local slider = Util.create("TextButton", {
		Position = position,
		Size = UDim2.new(1, -32, 0, 22),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	})
	local track = Util.create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 6),
		BorderSizePixel = 0,
		Parent = slider,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	self:_color(track, "BackgroundColor3", function(theme) return theme.track end)
	local fill = Util.create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	self:_color(fill, "BackgroundColor3", function(theme) return theme.accent end)
	self:_gradient(fill, 0)
	local knob = Util.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 2,
		BorderSizePixel = 0,
		Parent = slider,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Util.create("UIStroke", { Thickness = 2 }),
	})
	self:_color(knob, "BackgroundColor3", function(theme) return theme.text end)
	self:_color(knob:FindFirstChildOfClass("UIStroke"), "Color", function(theme) return theme.accent end)
	local controller = { value = initial, min = FLIGHT.MinSpeed, max = FLIGHT.MaxSpeed }
	function controller:render()
		local span = math.max(controller.max - controller.min, 0.001)
		local alpha = Util.clamp((controller.value - controller.min) / span, 0, 1)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
	end
	local function fromX(x)
		local width = slider.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local alpha = Util.clamp((x - slider.AbsolutePosition.X) / width, 0, 1)
		controller.value = controller.min + alpha * (controller.max - controller.min)
		controller:render()
		if onChange then
			onChange(controller.value)
		end
	end
	function controller:set(value, silent)
		controller.value = Util.clamp(value, controller.min, controller.max)
		controller:render()
		if not silent and onChange then
			onChange(controller.value)
		end
	end
	slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			ActiveSlider.handler = fromX
			fromX(input.Position.X)
		end
	end)
	controller:render()
	return controller
end
-- ═══════════════════════════════════════════════════════════════════════════════
--  §16. Интерфейс целиком
-- ═══════════════════════════════════════════════════════════════════════════════
function Ui.new()
	local self = setmetatable({
		colorTargets = {},
		gradients = {},
		toasts = {},
		time = 0,
		shimmerAccumulator = 0,
		shimmerSpeed = 0.12,
		textAccumulator = 0,
		groundAccumulator = 0,
		altitude = nil,
		flightActive = false,
		settingsOpen = false,
		hotkeysOpen = false,
		flight = nil,
		character = nil,
	}, Ui)
	self.screenGui = Util.create("ScreenGui", {
		Name = "FlightControllerUi",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 60,
		Parent = PlayerGui,
	})
	-- ── Кнопка-переключатель ────────────────────────────────────────────────
	self.toggle = Util.create("TextButton", {
		Name = "Toggle",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 24),
		Size = UDim2.fromOffset(112, 40),
		BackgroundTransparency = 0.05,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		Parent = self.screenGui,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Util.create("UIStroke", { Thickness = 1, Transparency = 0.3 }),
		Util.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	self:_gradient(self.toggle, 0)
	self:_color(self.toggle:FindFirstChildOfClass("UIStroke"), "Color", function(theme) return theme.edge end)
	self.toggleDot = Util.create("Frame", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(9, 9),
		BorderSizePixel = 0,
		Parent = self.toggle,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	self:_color(self.toggleDot, "BackgroundColor3", function(theme) return theme.muted end)
	self.toggleLabel = Util.create("TextLabel", {
		LayoutOrder = 2,
		Size = UDim2.fromOffset(66, 20),
		BackgroundTransparency = 1,
		Text = "ПОЛЁТ",
		TextSize = 12,
		Parent = self.toggle,
	})
	Util.setFont(self.toggleLabel, Enum.Font.GothamBold)
	self:_color(self.toggleLabel, "TextColor3", function(theme) return theme.text end)
	-- ── Основная панель ─────────────────────────────────────────────────────
	self.panel = Util.create("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 74),
		Size = UDim2.fromOffset(288, 236),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.screenGui,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Util.create("UIStroke", { Thickness = 1, Transparency = 1 }),
	})
	self:_color(self.panel, "BackgroundColor3", function(theme) return theme.backBottom end)
	self:_color(self.panel:FindFirstChildOfClass("UIStroke"), "Color", function(theme) return theme.edge end)
	self.panelGradient = self:_gradient(self.panel, 90)
	self.panelStroke = self.panel:FindFirstChildOfClass("UIStroke")
	local header = Util.create("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = self.panel,
	})
	makeDraggable(self.panel, header)
	self.title = Util.create("TextLabel", {
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -86, 1, 0),
		BackgroundTransparency = 1,
		Text = "FLIGHT CONTROLLER",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	Util.setFont(self.title, Enum.Font.GothamBold)
	self:_gradient(self.title, 0)
	self.statusDot = Util.create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -44, 0.5, 0),
		Size = UDim2.fromOffset(9, 9),
		BorderSizePixel = 0,
		Parent = header,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	self:_color(self.statusDot, "BackgroundColor3", function(theme) return theme.muted end)
	self.collapse = Util.create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Text = "–",
		TextSize = 16,
		AutoButtonColor = false,
		Parent = header,
	})
	Util.setFont(self.collapse, Enum.Font.GothamBold)
	self:_color(self.collapse, "TextColor3", function(theme) return theme.muted end)
	local function divider(y)
		local line = Util.create("Frame", {
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Parent = self.panel,
		})
		self:_color(line, "BackgroundColor3", function(theme) return theme.edge end)
		return line
	end
	divider(38)
	divider(200)
	self.stateLabel = Util.create("TextLabel", {
		Position = UDim2.fromOffset(16, 44),
		Size = UDim2.new(1, -110, 0, 18),
		BackgroundTransparency = 1,
		Text = "ОЖИДАНИЕ",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.panel,
	})
	Util.setFont(self.stateLabel, Enum.Font.GothamBold)
	self:_color(self.stateLabel, "TextColor3", function(theme) return theme.accent end)
	self.keyHint = Util.create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 46),
		Size = UDim2.new(0, 90, 0, 16),
		BackgroundTransparency = 1,
		Text = "F · Space ×2",
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = self.panel,
	})
	Util.setFont(self.keyHint, Enum.Font.GothamMedium)
	self:_color(self.keyHint, "TextColor3", function(theme) return theme.muted end)
	self.speedCaption = Util.create("TextLabel", {
		Position = UDim2.fromOffset(16, 70),
		Size = UDim2.new(0, 120, 0, 16),
		BackgroundTransparency = 1,
		Text = "СКОРОСТЬ",
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.panel,
	})
	Util.setFont(self.speedCaption, Enum.Font.GothamMedium)
	self:_color(self.speedCaption, "TextColor3", function(theme) return theme.muted end)
	self.speedValue = Util.create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 66),
		Size = UDim2.new(0, 120, 0, 22),
		BackgroundTransparency = 1,
		Text = "95",
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = self.panel,
	})
	Util.setFont(self.speedValue, Enum.Font.GothamBold)
	self:_gradient(self.speedValue, 0)
	self.slider = self:_slider(self.panel, UDim2.fromOffset(16, 92), FLIGHT.StartSpeed, function(value)
		FlightInstance:setSpeed(value)
	end)
	local settingsButton = self:_button(self.panel, "НАСТРОЙКИ", UDim2.fromOffset(124, 30), UDim2.fromOffset(16, 122), 10)
	settingsButton.Activated:Connect(function()
		self:toggleSettings()
	end)
	local hotkeysButton = self:_button(self.panel, "КЛАВИШИ", UDim2.fromOffset(124, 30), UDim2.fromOffset(148, 122), 10)
	hotkeysButton.Activated:Connect(function()
		self:toggleHotkeys()
	end)
	for index, text in ipairs({
		"W A S D · Space / Ctrl · Shift",
		"Q / E — бочка · T — аура · G — тема",
	}) do
		local hint = Util.create("TextLabel", {
			Position = UDim2.fromOffset(16, 158 + (index - 1) * 16),
			Size = UDim2.new(1, -32, 0, 14),
			BackgroundTransparency = 1,
			Text = text,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = self.panel,
		})
		Util.setFont(hint, Enum.Font.GothamMedium)
		self:_color(hint, "TextColor3", function(theme) return theme.muted end)
	end
	local footer = Util.create("TextLabel", {
		Position = UDim2.fromOffset(0, 204),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "ЛОКАЛЬНЫЙ ТЕСТОВЫЙ ИНСТРУМЕНТ",
		TextSize = 9,
		TextTransparency = 0.35,
		Parent = self.panel,
	})
	Util.setFont(footer, Enum.Font.GothamMedium)
	self:_color(footer, "TextColor3", function(theme) return theme.muted end)
	-- ── HUD со спидометром ──────────────────────────────────────────────────
	self.hud = Util.create("Frame", {
		Name = "Hud",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		Size = UDim2.fromOffset(340, 66),
		BackgroundTransparency = 1,
		Parent = self.screenGui,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Util.create("UIStroke", { Thickness = 1, Transparency = 0.35 }),
	})
	self:_color(self.hud, "BackgroundColor3", function(theme) return theme.backBottom end)
	self:_color(self.hud:FindFirstChildOfClass("UIStroke"), "Color", function(theme) return theme.edge end)
	self.hudGradient = self:_gradient(self.hud, 90)
	self.hudSpeed = Util.create("TextLabel", {
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(0, 110, 0, 28),
		BackgroundTransparency = 1,
		Text = "0",
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.hud,
	})
	Util.setFont(self.hudSpeed, Enum.Font.GothamBold)
	self:_gradient(self.hudSpeed, 0)
	self.hudSpeedCaption = Util.create("TextLabel", {
		Position = UDim2.fromOffset(16, 36),
		Size = UDim2.new(0, 110, 0, 14),
		BackgroundTransparency = 1,
		Text = "STUDS / S",
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.hud,
	})
	Util.setFont(self.hudSpeedCaption, Enum.Font.GothamMedium)
	self:_color(self.hudSpeedCaption, "TextColor3", function(theme) return theme.muted end)
	self.statePill = Util.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(132, 24),
		BackgroundTransparency = 0.25,
		Parent = self.hud,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Util.create("UIStroke", { Thickness = 1, Transparency = 0.4 }),
	})
	self:_color(self.statePill, "BackgroundColor3", function(theme) return theme.accentSoft end)
	self:_color(self.statePill:FindFirstChildOfClass("UIStroke"), "Color", function(theme) return theme.accent end)
	self.statePillLabel = Util.create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "ОЖИДАНИЕ",
		TextSize = 11,
		Parent = self.statePill,
	})
	Util.setFont(self.statePillLabel, Enum.Font.GothamBold)
	self:_color(self.statePillLabel, "TextColor3", function(theme) return theme.text end)
	self.hudAltitude = Util.create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 8),
		Size = UDim2.new(0, 110, 0, 28),
		BackgroundTransparency = 1,
		Text = "—",
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = self.hud,
	})
	Util.setFont(self.hudAltitude, Enum.Font.GothamBold)
	self:_color(self.hudAltitude, "TextColor3", function(theme) return theme.text end)
	self.hudAltitudeCaption = Util.create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 36),
		Size = UDim2.new(0, 110, 0, 14),
		BackgroundTransparency = 1,
		Text = "ВЫСОТА",
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = self.hud,
	})
	Util.setFont(self.hudAltitudeCaption, Enum.Font.GothamMedium)
	self:_color(self.hudAltitudeCaption, "TextColor3", function(theme) return theme.muted end)
	self.hudTrack = Util.create("Frame", {
		Position = UDim2.fromOffset(16, 52),
		Size = UDim2.new(1, -32, 0, 5),
		BorderSizePixel = 0,
		Parent = self.hud,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	self:_color(self.hudTrack, "BackgroundColor3", function(theme) return theme.track end)
	self.hudFill = Util.create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BorderSizePixel = 0,
		Parent = self.hudTrack,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	self:_color(self.hudFill, "BackgroundColor3", function(theme) return theme.accent end)
	self:_gradient(self.hudFill, 0)
	-- Группа плавного появления HUD: только во время полёта.
	self.hudGroup = {
		{ instance = self.hud, property = "BackgroundTransparency", shown = 0.15, hidden = 1 },
		{ instance = self.hud:FindFirstChildOfClass("UIStroke"), property = "Transparency", shown = 0.35, hidden = 1 },
		{ instance = self.hudSpeed, property = "TextTransparency", shown = 0, hidden = 1 },
		{ instance = self.hudSpeedCaption, property = "TextTransparency", shown = 0, hidden = 1 },
		{ instance = self.statePill, property = "BackgroundTransparency", shown = 0.25, hidden = 1 },
		{ instance = self.statePillLabel, property = "TextTransparency", shown = 0, hidden = 1 },
		{ instance = self.hudAltitude, property = "TextTransparency", shown = 0, hidden = 1 },
		{ instance = self.hudAltitudeCaption, property = "TextTransparency", shown = 0, hidden = 1 },
		{ instance = self.hudTrack, property = "BackgroundTransparency", shown = 0, hidden = 1 },
		{ instance = self.hudFill, property = "BackgroundTransparency", shown = 0, hidden = 1 },
	}
	-- ── Панель настроек ─────────────────────────────────────────────────────
	self.settingsPanel = Util.create("Frame", {
		Name = "Settings",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -324, 0, 74),
		Size = UDim2.fromOffset(288, 406),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.screenGui,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Util.create("UIStroke", { Thickness = 1, Transparency = 1 }),
	})
	self:_color(self.settingsPanel, "BackgroundColor3", function(theme) return theme.backBottom end)
	self.settingsStroke = self.settingsPanel:FindFirstChildOfClass("UIStroke")
	self:_color(self.settingsStroke, "Color", function(theme) return theme.edge end)
	self.settingsGradient = self:_gradient(self.settingsPanel, 90)
	local settingsHeader = Util.create("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = self.settingsPanel,
	})
	makeDraggable(self.settingsPanel, settingsHeader)
	local settingsTitle = Util.create("TextLabel", {
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Text = "НАСТРОЙКИ",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = settingsHeader,
	})
	Util.setFont(settingsTitle, Enum.Font.GothamBold)
	self:_gradient(settingsTitle, 0)
	local closeSettings = Util.create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Text = "×",
		TextSize = 16,
		AutoButtonColor = false,
		Parent = settingsHeader,
	})
	Util.setFont(closeSettings, Enum.Font.GothamBold)
	self:_color(closeSettings, "TextColor3", function(theme) return theme.muted end)
	closeSettings.Activated:Connect(function()
		self:toggleSettings(false)
	end)
	local settingsDivider = Util.create("Frame", {
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = self.settingsPanel,
	})
	self:_color(settingsDivider, "BackgroundColor3", function(theme) return theme.edge end)
	local rowY = 48
	local rowStep = 30
	self.switches = {}
	local themeRow, themeValue = self:_actionRow(self.settingsPanel, rowY, "Тема оформления", function()
		local theme = Theme.next()
		themeValue.Text = theme.label
		self:toast("тема: " .. theme.label)
	end)
	themeValue.Text = Theme.get().label
	self.themeValue = themeValue
	rowY += rowStep
	self.switches.aura = self:_switch(self.settingsPanel, rowY, "Аура", AURA.Enabled, function(state)
		AURA.Enabled = state
	end)
	rowY += rowStep
	self.switches.camera = self:_switch(self.settingsPanel, rowY, "Эффекты камеры", FX.CameraEnabled, function(state)
		FX.CameraEnabled = state
		if not state then
			CameraFX:setEnabled(false)
		end
	end)
	rowY += rowStep
	self.switches.grade = self:_switch(self.settingsPanel, rowY, "Цветокоррекция", FX.GradeEnabled, function(state)
		FX.GradeEnabled = state
	end)
	rowY += rowStep
	self.switches.bloom = self:_switch(self.settingsPanel, rowY, "Свечение (Bloom)", FX.BloomEnabled, function(state)
		FX.BloomEnabled = state
	end)
	rowY += rowStep
	self.switches.bob = self:_switch(self.settingsPanel, rowY, "Покачивание при висении", true, function(state)
		FLIGHT.HoverBobSpeed = state and 1.1 or 0
	end)
	rowY += rowStep
	local bankRow, bankValue = self:_actionRow(self.settingsPanel, rowY, "Крен в повороте", function()
		local steps = { 0, 20, 40, 60 }
		local current = ANIM.BankMax
		local nextValue = steps[1]
		for index, value in ipairs(steps) do
			if value > current + 1 then
				nextValue = value
				break
			end
			if index == #steps then
				nextValue = steps[1]
			end
		end
		ANIM.BankMax = nextValue
		bankValue.Text = nextValue .. "°"
	end)
	bankValue.Text = ANIM.BankMax .. "°"
	rowY += rowStep
	local fovRow, fovValue = self:_actionRow(self.settingsPanel, rowY, "Обзор камеры", function()
		local steps = { 0, 12, 22, 35 }
		local nextValue = steps[1]
		for index, value in ipairs(steps) do
			if value > FX.FovBoost + 1 then
				nextValue = value
				break
			end
			if index == #steps then
				nextValue = steps[1]
			end
		end
		FX.FovBoost = nextValue
		fovValue.Text = "+" .. nextValue
	end)
	fovValue.Text = "+" .. FX.FovBoost
	rowY += rowStep
	self.switches.noclip = self:_switch(self.settingsPanel, rowY, "Сквозь стены (тест)", FLIGHT.Noclip, function(state)
		FLIGHT.Noclip = state
		if not state and FlightInstance then
			FlightInstance:_setNoclip(false)
		elseif state and FlightInstance and FlightInstance:isActive() then
			FlightInstance:_setNoclip(true)
		end
	end)
	rowY += rowStep
	self.switches.autoquality = self:_switch(self.settingsPanel, rowY, "Авто-качество", QUALITY.auto, function(state)
		QUALITY.auto = state
	end)
	rowY += rowStep
	local qualityRow, qualityValue = self:_actionRow(self.settingsPanel, rowY, "Качество эффектов", function()
		QUALITY.level = (QUALITY.level % #QUALITY_LEVELS) + 1
		qualityValue.Text = QUALITY_LEVELS[QUALITY.level].name
	end)
	qualityValue.Text = QUALITY_LEVELS[QUALITY.level].name
	rowY += rowStep
	local settingsFooter = Util.create("TextLabel", {
		Position = UDim2.fromOffset(0, 382),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "P — закрыть · H — скрыть интерфейс",
		TextSize = 9,
		TextTransparency = 0.35,
		Parent = self.settingsPanel,
	})
	Util.setFont(settingsFooter, Enum.Font.GothamMedium)
	self:_color(settingsFooter, "TextColor3", function(theme) return theme.muted end)
	-- ── Панель горячих клавиш ───────────────────────────────────────────────
	self.hotkeysPanel = Util.create("Frame", {
		Name = "Hotkeys",
		Position = UDim2.fromOffset(24, 74),
		Size = UDim2.fromOffset(268, 268),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.screenGui,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Util.create("UIStroke", { Thickness = 1, Transparency = 1 }),
	})
	self:_color(self.hotkeysPanel, "BackgroundColor3", function(theme) return theme.backBottom end)
	self:_color(self.hotkeysPanel:FindFirstChildOfClass("UIStroke"), "Color", function(theme) return theme.edge end)
	self.hotkeysStroke = self.hotkeysPanel:FindFirstChildOfClass("UIStroke")
	self.hotkeysGradient = self:_gradient(self.hotkeysPanel, 90)
	local hotkeysHeader = Util.create("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = self.hotkeysPanel,
	})
	makeDraggable(self.hotkeysPanel, hotkeysHeader)
	local hotkeysTitle = Util.create("TextLabel", {
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Text = "ГОРЯЧИЕ КЛАВИШИ",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = hotkeysHeader,
	})
	Util.setFont(hotkeysTitle, Enum.Font.GothamBold)
	self:_gradient(hotkeysTitle, 0)
	local closeHotkeys = Util.create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Text = "×",
		TextSize = 16,
		AutoButtonColor = false,
		Parent = hotkeysHeader,
	})
	Util.setFont(closeHotkeys, Enum.Font.GothamBold)
	self:_color(closeHotkeys, "TextColor3", function(theme) return theme.muted end)
	closeHotkeys.Activated:Connect(function()
		self:toggleHotkeys(false)
	end)
	self.hotkeysBody = Util.create("TextLabel", {
		Position = UDim2.fromOffset(16, 48),
		Size = UDim2.new(1, -32, 1, -60),
		BackgroundTransparency = 1,
		RichText = true,
		TextWrapped = true,
		LineHeight = 1.35,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = table.concat({
			"<b>F</b>  полёт вкл / выкл",
			"<b>Space × 2</b>  то же двойным нажатием",
			"<b>W A S D</b>  движение по камере",
			"<b>Space / Ctrl</b>  вверх / вниз",
			"<b>Shift</b>  ускорение",
			"<b>Q / E</b>  бочка",
			"<b>R</b>  сбросить скорость",
			"<b>T</b>  аура",
			"<b>G</b>  сменить тему",
			"<b>V</b>  эффекты камеры",
			"<b>P</b>  настройки",
			"<b>K</b>  эта панель",
			"<b>H</b>  скрыть интерфейс",
			"",
			"Геймпад: A / B — вверх и вниз,",
			"стик — движение, R1 / L1 — бочка.",
		}, "\n"),
		Parent = self.hotkeysPanel,
	})
	Util.setFont(self.hotkeysBody, Enum.Font.GothamMedium)
	self:_color(self.hotkeysBody, "TextColor3", function(theme) return theme.text end)
	-- ── Контейнер уведомлений ───────────────────────────────────────────────
	self.toastHolder = Util.create("Frame", {
		Name = "Toasts",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = self.screenGui,
	})
	-- ── Луч вниз для высоты ─────────────────────────────────────────────────
	self.rayParams = RaycastParams.new()
	self.rayParams.FilterType = Enum.RaycastFilterType.Exclude
		or Enum.RaycastFilterType.Blacklist
	self.rayParams.IgnoreWater = true
	self.rayParams.FilterDescendantsInstances = {}
	-- ── Переливание: тонкие полосы и обводки ────────────────────────────────
	-- Полосы по верхнему краю панелей и обводки, цвет которых берётся из
	-- предрасчитанного колеса оттенков. Ни одной новой ColorSequence в кадре.
	local function shimmerLine(parent)
		local line = Util.create("Frame", {
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -28, 0, 2),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = parent,
		}, {
			Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
		self:_gradient(line, 0)
		return line
	end
	self.shimmerLines = {
		shimmerLine(self.panel),
		shimmerLine(self.settingsPanel),
		shimmerLine(self.hotkeysPanel),
		shimmerLine(self.hud),
	}
	-- Полоса HUD должна гаснуть вместе с самим HUD.
	table.insert(self.hudGroup, {
		instance = self.shimmerLines[4],
		property = "BackgroundTransparency",
		shown = 0.2,
		hidden = 1,
	})
	self.shimmerStrokes = {
		self.panelStroke,
		self.settingsStroke,
		self.hotkeysStroke,
		self.toggle:FindFirstChildOfClass("UIStroke"),
		self.statePill:FindFirstChildOfClass("UIStroke"),
		self.hud:FindFirstChildOfClass("UIStroke"),
	}
	return self
end
function Ui:bind(flight)
	self.flight = flight
end
function Ui:setCharacter(character)
	self.character = character
end
function Ui:setSpeed(value)
	self.slider:set(value, true)
	self.speedValue.Text = tostring(Util.round(value))
end
function Ui:toast(text)
	local frame = Util.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(320, 34),
		BackgroundColor3 = Theme.get().backBottom,
		BackgroundTransparency = 1,
		Parent = self.toastHolder,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Util.create("UIStroke", { Color = Theme.get().accent, Thickness = 1, Transparency = 0.25 }),
	})
	self:_gradient(frame, 0)
	local label = Util.create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 11,
		TextTransparency = 1,
		Parent = frame,
	})
	Util.setFont(label, Enum.Font.GothamBold)
	label.TextColor3 = Theme.get().text
	local entry = { frame = frame, alive = true }
	table.insert(self.toasts, entry)
	self:_layoutToasts()
	Util.tween(frame, 0.25, { BackgroundTransparency = 0.1 })
	Util.tween(label, 0.25, { TextTransparency = 0 })
	Util.tween(frame, 0.3, { Position = UDim2.new(0.5, 0, 1, -122) })
	task.delay(2, function()
		if not entry.alive then
			return
		end
		entry.alive = false
		Util.tween(frame, 0.3, {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 1, -100),
		})
		Util.tween(label, 0.3, { TextTransparency = 1 })
		task.delay(0.32, function()
			frame:Destroy()
			for index = #self.toasts, 1, -1 do
				if self.toasts[index] == entry then
					table.remove(self.toasts, index)
				end
			end
			self:_layoutToasts()
		end)
	end)
end
function Ui:_layoutToasts()
	for index, entry in ipairs(self.toasts) do
		local offset = -110 - (index - 1) * 42
		if entry.alive then
			entry.frame.Position = UDim2.new(0.5, 0, 1, offset)
		end
	end
end
function Ui:_fadeGroup(group, visible, duration)
	for _, entry in ipairs(group) do
		Util.tween(entry.instance, duration, {
			[entry.property] = visible and entry.shown or entry.hidden,
		})
	end
end
function Ui:setFlightActive(state)
	if self.flightActive == state then
		return
	end
	self.flightActive = state
	local theme = Theme.get()
	Util.tween(self.toggle, 0.2, {
		BackgroundColor3 = state and theme.accentSoft or theme.track,
	})
	Util.tween(self.toggleDot, 0.2, {
		BackgroundColor3 = state and theme.accent or theme.muted,
	})
	Util.tween(self.statusDot, 0.2, {
		BackgroundColor3 = state and theme.accent or theme.muted,
	})
	self.toggleLabel.Text = state and "СТОП" or "ПОЛЁТ"
	self:_fadeGroup(self.hudGroup, state, 0.3)
end
function Ui:toggleVisible(state)
	if state == nil then
		state = not self.screenGui.Enabled
	end
	self.screenGui.Enabled = state
end
function Ui:_setPanelOpen(panel, stroke, gradient, open, offsetX)
	if open then
		panel.Visible = true
		panel.Position = UDim2.new(1, offsetX, 0, 64)
		Util.tween(panel, 0.25, {
			BackgroundTransparency = 0,
			Position = UDim2.new(1, offsetX, 0, 74),
		})
		Util.tween(stroke, 0.25, { Transparency = 0.2 })
	else
		local animation = Util.tween(panel, 0.2, {
			BackgroundTransparency = 1,
			Position = UDim2.new(1, offsetX, 0, 64),
		})
		Util.tween(stroke, 0.2, { Transparency = 1 })
		animation.Completed:Once(function()
			if not panel.Visible then
				return
			end
			if panel == self.panel and not self.panelOpen then
				panel.Visible = false
			elseif panel == self.settingsPanel and not self.settingsOpen then
				panel.Visible = false
			end
		end)
	end
end
function Ui:openPanel(state)
	if self.panelOpen == state then
		return
	end
	self.panelOpen = state
	self:_setPanelOpen(self.panel, self.panelStroke, self.panelGradient, state, -24)
end
function Ui:toggleSettings(state)
	if state == nil then
		state = not self.settingsOpen
	end
	if self.settingsOpen == state then
		return
	end
	self.settingsOpen = state
	self:_setPanelOpen(self.settingsPanel, self.settingsStroke, self.settingsGradient, state, -324)
end
function Ui:toggleHotkeys(state)
	if state == nil then
		state = not self.hotkeysOpen
	end
	if self.hotkeysOpen == state then
		return
	end
	self.hotkeysOpen = state
	-- Панель клавиш стоит слева, поэтому движение по X ей не нужно.
	if state then
		self.hotkeysPanel.Visible = true
		self.hotkeysPanel.BackgroundTransparency = 1
		Util.tween(self.hotkeysPanel, 0.25, { BackgroundTransparency = 0 })
		Util.tween(self.hotkeysStroke, 0.25, { Transparency = 0.2 })
	else
		local animation = Util.tween(self.hotkeysPanel, 0.2, { BackgroundTransparency = 1 })
		Util.tween(self.hotkeysStroke, 0.2, { Transparency = 1 })
		animation.Completed:Once(function()
			if not self.hotkeysOpen then
				self.hotkeysPanel.Visible = false
			end
		end)
	end
end
function Ui:refreshActive()
	self:setFlightActive(FlightInstance:isActive())
end
function Ui:_measureAltitude()
	local character = self.character
	local root = FlightInstance.root
	if not character or not root then
		return nil
	end
	local filter = { character }
	if AuraInstance.folder then
		table.insert(filter, AuraInstance.folder)
	end
	self.rayParams.FilterDescendantsInstances = filter
	local result = Workspace:Raycast(root.Position, Vector3.new(0, -800, 0), self.rayParams)
	if result then
		return (root.Position - result.Position).Magnitude
	end
	return nil
end
function Ui:playSplash()
	Util.tween(self.toggle, 0.4, { BackgroundTransparency = 0.05 })
	local overlay = Util.create("Frame", {
		Name = "Splash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 40,
		Parent = self.screenGui,
	})
	local card = Util.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(360, 128),
		BackgroundColor3 = Theme.get().backBottom,
		BackgroundTransparency = 1,
		ZIndex = 41,
		Parent = overlay,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(0, 16) }),
		Util.create("UIStroke", { Color = Theme.get().accent, Thickness = 1, Transparency = 1 }),
	})
	self:_gradient(card, 90)
	local cardStroke = card:FindFirstChildOfClass("UIStroke")
	local splashTitle = Util.create("TextLabel", {
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "FLIGHT CONTROLLER",
		TextSize = 20,
		TextTransparency = 1,
		ZIndex = 42,
		Parent = card,
	})
	Util.setFont(splashTitle, Enum.Font.GothamBold)
	self:_gradient(splashTitle, 0)
	local splashCaption = Util.create("TextLabel", {
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = "VOID EDITION · ЗАГРУЗКА",
		TextSize = 10,
		TextTransparency = 1,
		ZIndex = 42,
		Parent = card,
	})
	Util.setFont(splashCaption, Enum.Font.GothamMedium)
	self:_color(splashCaption, "TextColor3", function(theme) return theme.muted end)
	local barTrack = Util.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, -26),
		Size = UDim2.new(1, -60, 0, 4),
		BackgroundTransparency = 0.45,
		ZIndex = 42,
		Parent = card,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	self:_color(barTrack, "BackgroundColor3", function(theme) return theme.track end)
	local barFill = Util.create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 43,
		Parent = barTrack,
	}, {
		Util.create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	self:_gradient(barFill, 0)
	Util.tween(overlay, 0.3, { BackgroundTransparency = 0.35 })
	Util.tween(card, 0.3, { BackgroundTransparency = 0 })
	Util.tween(cardStroke, 0.3, { Transparency = 0.2 })
	Util.tween(splashTitle, 0.3, { TextTransparency = 0 })
	Util.tween(splashCaption, 0.3, { TextTransparency = 0 })
	Util.tween(barFill, 1, { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Quad)
	task.delay(1.15, function()
		Util.tween(overlay, 0.35, { BackgroundTransparency = 1 })
		Util.tween(card, 0.35, { BackgroundTransparency = 1 })
		Util.tween(cardStroke, 0.35, { Transparency = 1 })
		Util.tween(splashTitle, 0.3, { TextTransparency = 1 })
		Util.tween(splashCaption, 0.3, { TextTransparency = 1 })
		task.delay(0.4, function()
			overlay:Destroy()
			self:openPanel(true)
		end)
	end)
end
function Ui:update(delta)
	self.time += delta
	-- Переливание: двигаем готовый градиент, а не собираем цвета заново.
	self.shimmerAccumulator += delta
	if self.shimmerAccumulator >= 0.033 then
		self.shimmerAccumulator = 0
		local offset = Vector2.new(-((self.time * self.shimmerSpeed) % 1), 0)
		for _, gradient in ipairs(self.gradients) do
			gradient.Offset = offset
		end
		-- Обводки и полосы ведём по колесу оттенков со сдвигом фазы:
		-- так переливание идёт волной, а не одной вспышкой.
		local phase = self.time * 0.14
		for index, stroke in ipairs(self.shimmerStrokes) do
			if stroke then
				stroke.Color = Util.wheelColor(phase + index * 0.08)
			end
		end
		for index, line in ipairs(self.shimmerLines) do
			if line then
				line.BackgroundTransparency = 0.16 + 0.14 * math.sin(self.time * 1.8 + index)
			end
		end
	end
	local flight = self.flight
	-- HUD: полоса каждый кадр (одна дешёвая запись), тексты — десять раз в секунду.
	if flight then
		local speed = flight.velocity.Magnitude
		local fillRatio = Util.clamp(speed / math.max(flight.speed, 1), 0, 1)
		self.hudFill.Size = UDim2.new(fillRatio, 0, 1, 0)
		self.textAccumulator += delta
		if self.textAccumulator >= 0.1 then
			self.textAccumulator = 0
			local active = flight:isActive()
			local state = flight:getStateLabel()
			self.stateLabel.Text = state
			self.statePillLabel.Text = state
			self.hudSpeed.Text = tostring(Util.round(speed))
			self.speedValue.Text = tostring(Util.round(flight.speed))
			self.statusDot.BackgroundColor3 = active and Theme.get().accent or Theme.get().muted
		end
		self.groundAccumulator += delta
		if self.groundAccumulator >= 0.25 then
			self.groundAccumulator = 0
			local altitude = self:_measureAltitude()
			self.hudAltitude.Text = altitude and tostring(Util.round(altitude)) or "—"
		end
	end
end
function Ui:applyTheme(theme)
	for _, target in ipairs(self.colorTargets) do
		target.instance[target.property] = target.picker(theme)
	end
	local bright = Util.colorSequence(theme.shimmer)
	local dark = Util.colorSequence({ theme.backTop, theme.backBottom })
	for _, gradient in ipairs(self.gradients) do
		local parent = gradient.Parent
		gradient.Color = (parent and gradientIsBright(parent)) and bright or dark
	end
	if self.themeValue then
		self.themeValue.Text = theme.label
	end
end
Theme.onChange(function(theme)
	if UiInstance then
		UiInstance:applyTheme(theme)
	end
end)
-- ═══════════════════════════════════════════════════════════════════════════════
--  §17. Связывание: клавиши и жизненный цикл персонажа
-- ═══════════════════════════════════════════════════════════════════════════════
UiInstance = Ui.new()
UiInstance:bind(FlightInstance)
local lastSpaceTap = 0
local function toggleFlight(force)
	if Util.isTyping() then
		return
	end
	local want = force
	if want == nil then
		want = not FlightInstance:isActive()
	end
	if want then
		if FlightInstance:activate() then
			UiInstance:setFlightActive(true)
			UiInstance:toast("полёт включён · " .. FlightInstance:getStateLabel())
		end
	else
		FlightInstance:deactivate()
		UiInstance:setFlightActive(false)
		UiInstance:toast("полёт выключен")
	end
end
-- Кнопки интерфейса подключаем здесь: toggleFlight уже существует.
UiInstance.toggle.Activated:Connect(function()
	toggleFlight()
end)
-- Правый клик по кнопке открывает и закрывает панель.
UiInstance.toggle.MouseButton2Click:Connect(function()
	UiInstance:openPanel(not UiInstance.panelOpen)
end)
UiInstance.collapse.Activated:Connect(function()
	UiInstance:openPanel(false)
end)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local key = input.KeyCode
	if key == FLIGHT.ToggleKey or key == Enum.KeyCode.ButtonY then
		toggleFlight()
	elseif key == Enum.KeyCode.Space then
		local now = Util.now()
		if now - lastSpaceTap <= FLIGHT.DoubleTapWindow then
			lastSpaceTap = 0
			toggleFlight()
		else
			lastSpaceTap = now
		end
	elseif key == Enum.KeyCode.R then
		FlightInstance:setSpeed(FLIGHT.StartSpeed)
		UiInstance:setSpeed(FLIGHT.StartSpeed)
		UiInstance:toast("скорость: " .. Util.round(FLIGHT.StartSpeed))
	elseif key == Enum.KeyCode.T then
		local state = AuraInstance:toggle()
		UiInstance:toast("аура: " .. (state and "включена" or "выключена"))
		if UiInstance.switches and UiInstance.switches.aura then
			UiInstance.switches.aura:set(state, true)
		end
	elseif key == Enum.KeyCode.G then
		local theme = Theme.next()
		UiInstance:toast("тема: " .. theme.label)
	elseif key == Enum.KeyCode.V then
		FX.CameraEnabled = not FX.CameraEnabled
		if not FX.CameraEnabled then
			CameraFX:setEnabled(false)
		end
		UiInstance:toast("эффекты камеры: " .. (FX.CameraEnabled and "вкл" or "выкл"))
		if UiInstance.switches and UiInstance.switches.camera then
			UiInstance.switches.camera:set(FX.CameraEnabled, true)
		end
	elseif key == Enum.KeyCode.P then
		UiInstance:toggleSettings()
	elseif key == Enum.KeyCode.K then
		UiInstance:toggleHotkeys()
	elseif key == Enum.KeyCode.H then
		UiInstance:toggleVisible()
	end
end)
local function onCharacter(character)
	FlightInstance:deactivate()
	UiInstance:setFlightActive(false)
	FlightInstance:bind(character)
	UiInstance:setCharacter(character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		AuraInstance:attach(root, character)
	end
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Connect(function()
			FlightInstance:deactivate()
			UiInstance:setFlightActive(false)
		end)
	end
end
-- ═══════════════════════════════════════════════════════════════════════════════
--  §18. Главный цикл и авто-качество
--  Один RenderStepped на весь скрипт: полёт, аура, камера и интерфейс идут
--  строго по порядку и из одного места, поэтому их ничто не разъезжает.
-- ═══════════════════════════════════════════════════════════════════════════════
local fps = { accumulator = 0, frames = 0, value = 60, cooldown = 0 }
RunService.RenderStepped:Connect(function(delta)
	local active = FlightInstance:isActive()
	local root = FlightInstance.root
	local velocity = FlightInstance.velocity
	local ratio = FlightInstance:getSpeedRatio()
	FlightInstance:step(delta)
	AuraInstance:update(delta, active, root, velocity, ratio)
	-- Камера включается только на время полёта: вне его не тратим кадры.
	local wantCamera = FX.CameraEnabled and FlightInstance:isActive()
	if wantCamera ~= CameraFX.enabled then
		CameraFX:setEnabled(wantCamera)
	end
	UiInstance:update(delta)
	fps.accumulator += delta
	fps.frames += 1
	if fps.cooldown > 0 then
		fps.cooldown -= delta
	end
	if fps.accumulator >= QUALITY.averageWindow then
		fps.value = fps.frames / fps.accumulator
		fps.accumulator = 0
		fps.frames = 0
		if QUALITY.auto and fps.cooldown <= 0 then
			if fps.value < QUALITY.fpsFloor and QUALITY.level < #QUALITY_LEVELS then
				QUALITY.level += 1
				fps.cooldown = 6
				UiInstance:toast("качество снижено: " .. QUALITY_LEVELS[QUALITY.level].name)
			elseif fps.value > QUALITY.fpsCeil and QUALITY.level > 1 then
				QUALITY.level -= 1
				fps.cooldown = 6
				UiInstance:toast("качество повышено: " .. QUALITY_LEVELS[QUALITY.level].name)
			end
		end
	end
end)
-- ═══════════════════════════════════════════════════════════════════════════════
--  §19. Старт
-- ═══════════════════════════════════════════════════════════════════════════════
FlightInstance:setSpeed(FLIGHT.StartSpeed)
UiInstance:setSpeed(FLIGHT.StartSpeed)
UiInstance:setFlightActive(false)
UiInstance:playSplash()
if LocalPlayer.Character then
	onCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacter)
