--[[
	AURORA HUB  -  Mobile Executor UI
	- Touch only (mobile) / Obsidian-style minimize orb (draggable)
	- Animated gradients, ripple, particles, splash, glow stroke
	- Tabs: Home / Script / Explorer / Env / HTTP / Lab / Settings
]]

-- ================= SERVICES =================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

-- ================= NOTIFY (debug) =================
local function Notify(title, text, duration)
	StarterGui:SetCore("SendNotification", {
		Title = title,
		Text = text,
		Duration = duration
	})
end

-- ================= SINGLE INSTANCE =================
if getgenv().AuroraHub then
	pcall(function() getgenv().AuroraHub.Destroy() end)
end

-- ================= STATE =================
local Connections = {}
local Gradients = {}
local Settings = {
	Theme = "Aurora",
	GradSpeed = 40,
	Particles = true,
	Glow = true,
}
local Themes = {
	Aurora = {Color3.fromRGB(125, 80, 255), Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 80, 200)},
	Sunset = {Color3.fromRGB(255, 94, 58), Color3.fromRGB(255, 176, 59), Color3.fromRGB(255, 64, 129)},
	Emerald = {Color3.fromRGB(0, 230, 118), Color3.fromRGB(0, 184, 212), Color3.fromRGB(118, 255, 3)},
	Crimson = {Color3.fromRGB(255, 23, 68), Color3.fromRGB(170, 0, 255), Color3.fromRGB(255, 110, 64)},
}
local ThemeOrder = {"Aurora", "Sunset", "Emerald", "Crimson"}

local function MakeSeq(t)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, t[1]),
		ColorSequenceKeypoint.new(0.33, t[2]),
		ColorSequenceKeypoint.new(0.66, t[3]),
		ColorSequenceKeypoint.new(1, t[1]),
	})
end

local function Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Connections, c)
	return c
end

-- ================= HELPERS =================
local function New(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	for _, c in ipairs(children or {}) do
		c.Parent = o
	end
	return o
end

local function Corner(parent, r)
	return New("UICorner", {CornerRadius = UDim.new(0, r), Parent = parent})
end

local function Tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function AddGradient(parent, rot)
	local g = New("UIGradient", {
		Rotation = rot or math.random(0, 359),
		Color = MakeSeq(Themes[Settings.Theme]),
		Parent = parent
	})
	table.insert(Gradients, g)
	return g
end

local function ApplyTheme(name)
	Settings.Theme = name
	local seq = MakeSeq(Themes[name])
	for _, g in ipairs(Gradients) do
		g.Color = seq
	end
end

local function Order(page)
	local n = (page:GetAttribute("n") or 0) + 1
	page:SetAttribute("n", n)
	return n
end

-- shared touch drag handler
local DragHandler, DragEnd = nil, nil
Connect(UserInputService.InputChanged, function(i)
	if DragHandler and i.UserInputType == Enum.UserInputType.Touch then
		DragHandler(i.Position)
	end
end)
Connect(UserInputService.InputEnded, function(i)
	if i.UserInputType == Enum.UserInputType.Touch and DragEnd then
		DragEnd()
	end
end)

local function MakeDraggable(handle, target, onTap)
	Connect(handle.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then return end
		local start = input.Position
		local sp = target.Position
		local moved = false
		DragHandler = function(pos)
			local d = pos - start
			if d.Magnitude > 8 then moved = true end
			if moved then
				target.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end
		DragEnd = function()
			DragHandler = nil
			DragEnd = nil
			if not moved and onTap then onTap() end
		end
	end)
end

-- ================= SCREEN GUI =================
local Gui = New("ScreenGui", {
	Name = "AuroraHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local okParent = pcall(function() Gui.Parent = CoreGui end)
if not okParent or not Gui.Parent then
	Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Camera = workspace.CurrentCamera
local VP = Camera.ViewportSize
local BaseScale = math.clamp(math.min(VP.Y / 340, VP.X / 500), 0.6, 1)
local WIN_W, WIN_H = 460, 290

-- Holder (position control) + Window (scaled)
local Holder = New("Frame", {
	Name = "Holder",
	Size = UDim2.fromOffset(WIN_W, WIN_H),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = Gui,
})
local Scale = New("UIScale", {Scale = 0.01})
local Window = New("Frame", {
	Name = "Window",
	Size = UDim2.fromScale(1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.05,
	ClipsDescendants = true,
	Parent = Holder,
})
Scale.Parent = Window
Corner(Window, 14)
New("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(22, 18, 40), Color3.fromRGB(8, 8, 16)),
	Rotation = 60,
	Parent = Window
})
local Glow = New("UIStroke", {
	Thickness = 2,
	Color = Color3.new(1, 1, 1),
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	Parent = Window
})
AddGradient(Glow, 0)

-- Particles
local ParticleLayer = New("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 1,
	Parent = Window
})
local Particles = {}
for i = 1, 18 do
	local s = math.random(3, 7)
	local p = New("Frame", {
		Size = UDim2.fromOffset(s, s),
		Position = UDim2.fromScale(math.random(), math.random()),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = ParticleLayer
	})
	Corner(p, 8)
	AddGradient(p)
	table.insert(Particles, {f = p, speed = math.random(4, 14) / 100, drift = (math.random() - 0.5) * 0.02})
end

-- ================= TOP BAR =================
local TopBar = New("Frame", {
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = Color3.fromRGB(14, 12, 26),
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = Window
})
local TitleLbl = New("TextLabel", {
	Size = UDim2.new(0, 200, 1, 0),
	Position = UDim2.fromOffset(14, 0),
	BackgroundTransparency = 1,
	Text = "AURORA HUB",
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 6,
	Parent = TopBar
})
AddGradient(TitleLbl, 0)
local SubLbl = New("TextLabel", {
	Size = UDim2.new(0, 120, 1, 0),
	Position = UDim2.fromOffset(130, 3),
	BackgroundTransparency = 1,
	Text = "mobile edition",
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = Color3.fromRGB(150, 150, 175),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 6,
	Parent = TopBar
})

local function TopButton(text, xOff)
	local b = New("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, xOff, 0.5, -14),
		BackgroundColor3 = Color3.fromRGB(32, 30, 52),
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		ZIndex = 7,
		Parent = TopBar
	})
	Corner(b, 14)
	return b
end
local MinBtn = TopButton("-", -68)
local CloseBtn = TopButton("x", -36)

-- ================= RIPPLE / BUTTON BUILDERS =================
local function Ripple(btn, x, y)
	local sc = Scale.Scale
	local r = New("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.55,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((x - btn.AbsolutePosition.X) / sc, (y - btn.AbsolutePosition.Y) / sc),
		Size = UDim2.fromOffset(0, 0),
		ZIndex = 20,
		Parent = btn
	})
	Corner(r, 200)
	local big = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.2 / sc
	Tween(r, 0.5, {Size = UDim2.fromOffset(big, big), BackgroundTransparency = 1})
	task.delay(0.55, function() r:Destroy() end)
end

local function MakeBtn(parent, text, cb, size, order)
	local b = New("TextButton", {
		Size = size,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		LayoutOrder = order or 0,
		Parent = parent
	})
	Corner(b, 8)
	AddGradient(b)
	New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = b
	})
	Connect(b.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			Ripple(b, i.Position.X, i.Position.Y)
		end
	end)
	Connect(b.Activated, function()
		if cb then cb() end
	end)
	return b
end

-- Sidebar + content
local Sidebar = New("ScrollingFrame", {
	Size = UDim2.new(0, 96, 1, -46),
	Position = UDim2.fromOffset(6, 42),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 4,
	Parent = Window
})
New("UIListLayout", {Padding = UDim.new(0, 3), Parent = Sidebar})
local Content = New("Frame", {
	Size = UDim2.new(1, -112, 1, -50),
	Position = UDim2.fromOffset(106, 44),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 4,
	Parent = Window
})

local Pages, TabBtns = {}, {}
local CurrentTab = nil

local function SelectTab(name)
	if CurrentTab == name then return end
	CurrentTab = name
	for n, pg in pairs(Pages) do
		local active = (n == name)
		local tb = TabBtns[n]
		tb.Grad.Enabled = active
		Tween(tb.Btn, 0.25, {BackgroundColor3 = active and Color3.new(1, 1, 1) or Color3.fromRGB(26, 24, 44)})
		Tween(tb.Lbl, 0.25, {TextColor3 = active and Color3.new(1, 1, 1) or Color3.fromRGB(160, 160, 185)})
		pg.Visible = active
		if active then
			pg.Position = UDim2.fromOffset(18, 0)
			Tween(pg, 0.3, {Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Quint)
		end
	end
end

local function CreateTab(name)
	local btn = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(26, 24, 44),
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		Parent = Sidebar
	})
	Corner(btn, 8)
	local g = AddGradient(btn)
	g.Enabled = false
	local lbl = New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(160, 160, 185),
		ZIndex = 3,
		Parent = btn
	})
	local page = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = Content
	})
	New("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})
	New("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8), Parent = page})
	Pages[name] = page
	TabBtns[name] = {Btn = btn, Lbl = lbl, Grad = g}
	Connect(btn.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			Ripple(btn, i.Position.X, i.Position.Y)
		end
	end)
	Connect(btn.Activated, function() SelectTab(name) end)
	return page
end

-- ================= COMPONENTS =================
local function Section(page, text)
	local l = New("TextLabel", {
		Size = UDim2.new(1, -4, 0, 20),
		BackgroundTransparency = 1,
		Text = string.upper(text),
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = Order(page),
		Parent = page
	})
	AddGradient(l, 0)
	return l
end

local function Label(page, text, height)
	local holder = New("Frame", {
		Size = UDim2.new(1, -4, 0, height or 24),
		BackgroundColor3 = Color3.fromRGB(24, 24, 38),
		LayoutOrder = Order(page),
		Parent = page
	})
	Corner(holder, 8)
	local l = New("TextLabel", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(215, 215, 235),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = holder
	})
	return l
end

local function Button(page, text, cb)
	return MakeBtn(page, text, cb, UDim2.new(1, -4, 0, 34), Order(page))
end

local function BtnRow(page, defs)
	local row = New("Frame", {
		Size = UDim2.new(1, -4, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = Order(page),
		Parent = page
	})
	New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = row})
	local n = #defs
	for _, d in ipairs(defs) do
		MakeBtn(row, d[1], d[2], UDim2.new(1 / n, -(4 * (n - 1)) / n, 1, 0), 0)
	end
end

local function ChipRow(page, options, default, cb)
	local row = New("Frame", {
		Size = UDim2.new(1, -4, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = Order(page),
		Parent = page
	})
	New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = row})
	local n = #options
	local chips = {}
	local function select(idx)
		for i, c in ipairs(chips) do
			local on = (i == idx)
			c.g.Enabled = on
			Tween(c.b, 0.2, {BackgroundColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(30, 30, 46)})
		end
	end
	for i, name in ipairs(options) do
		local b = New("TextButton", {
			Size = UDim2.new(1 / n, -(4 * (n - 1)) / n, 1, 0),
			BackgroundColor3 = Color3.fromRGB(30, 30, 46),
			Text = name,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = Color3.new(1, 1, 1),
			AutoButtonColor = false,
			ClipsDescendants = true,
			Parent = row
		})
		Corner(b, 8)
		local g = AddGradient(b)
		g.Enabled = false
		table.insert(chips, {b = b, g = g})
		Connect(b.InputBegan, function(inp)
			if inp.UserInputType == Enum.UserInputType.Touch then
				Ripple(b, inp.Position.X, inp.Position.Y)
			end
		end)
		Connect(b.Activated, function()
			select(i)
			if cb then cb(i, name) end
		end)
	end
	select(default or 1)
end

local function Toggle(page, text, default, cb)
	local holder = New("TextButton", {
		Size = UDim2.new(1, -4, 0, 34),
		BackgroundColor3 = Color3.fromRGB(24, 24, 38),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = Order(page),
		Parent = page
	})
	Corner(holder, 8)
	New("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(225, 225, 240),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder
	})
	local track = New("Frame", {
		Size = UDim2.fromOffset(42, 20),
		Position = UDim2.new(1, -52, 0.5, -10),
		BackgroundColor3 = Color3.fromRGB(50, 50, 70),
		Parent = holder
	})
	Corner(track, 10)
	local tg = AddGradient(track)
	tg.Enabled = false
	local knob = New("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track
	})
	Corner(knob, 8)
	local state = default and true or false
	local function render(animate)
		tg.Enabled = state
		local goalPos = state and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)
		local goalCol = state and Color3.new(1, 1, 1) or Color3.fromRGB(50, 50, 70)
		if animate then
			Tween(knob, 0.25, {Position = goalPos}, Enum.EasingStyle.Back)
			Tween(track, 0.25, {BackgroundColor3 = goalCol})
		else
			knob.Position = goalPos
			track.BackgroundColor3 = goalCol
		end
	end
	render(false)
	Connect(holder.Activated, function()
		state = not state
		render(true)
		if cb then cb(state) end
	end)
	return {Set = function(v) state = v render(true) end, Get = function() return state end}
end

local function Slider(page, text, min, max, def, cb, decimals)
	decimals = decimals or 0
	local holder = New("Frame", {
		Size = UDim2.new(1, -4, 0, 46),
		BackgroundColor3 = Color3.fromRGB(24, 24, 38),
		LayoutOrder = Order(page),
		Parent = page
	})
	Corner(holder, 8)
	New("TextLabel", {
		Size = UDim2.new(1, -70, 0, 20),
		Position = UDim2.fromOffset(10, 4),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(225, 225, 240),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder
	})
	local val = New("TextLabel", {
		Size = UDim2.fromOffset(56, 20),
		Position = UDim2.new(1, -64, 0, 4),
		BackgroundTransparency = 1,
		Text = tostring(def),
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(190, 190, 215),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = holder
	})
	local bar = New("Frame", {
		Size = UDim2.new(1, -20, 0, 8),
		Position = UDim2.new(0, 10, 0, 30),
		BackgroundColor3 = Color3.fromRGB(42, 42, 60),
		Parent = holder
	})
	Corner(bar, 4)
	local fill = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = bar
	})
	Corner(fill, 4)
	AddGradient(fill)
	local knob = New("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = bar
	})
	Corner(knob, 7)
	local function set(v)
		local m = 10 ^ decimals
		v = math.clamp(math.floor(v * m + 0.5) / m, min, max)
		local a = (v - min) / (max - min)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		val.Text = tostring(v)
		if cb then cb(v) end
	end
	set(def)
	local function fromX(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		set(min + (max - min) * a)
	end
	Connect(holder.InputBegan, function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch then return end
		page.ScrollingEnabled = false
		Tween(knob, 0.15, {Size = UDim2.fromOffset(20, 20)})
		fromX(i.Position.X)
		DragHandler = function(pos) fromX(pos.X) end
		DragEnd = function()
			DragHandler = nil
			DragEnd = nil
			page.ScrollingEnabled = true
			Tween(knob, 0.15, {Size = UDim2.fromOffset(14, 14)})
		end
	end)
	return {Set = set}
end

local function Input(page, placeholder, multi, height, default)
	local tb = New("TextBox", {
		Size = UDim2.new(1, -4, 0, height or 32),
		BackgroundColor3 = Color3.fromRGB(20, 20, 32),
		Text = default or "",
		PlaceholderText = placeholder or "",
		PlaceholderColor3 = Color3.fromRGB(110, 110, 135),
		TextColor3 = Color3.fromRGB(235, 235, 250),
		Font = multi and Enum.Font.Code or Enum.Font.Gotham,
		TextSize = 12,
		ClearTextOnFocus = false,
		MultiLine = multi and true or false,
		TextWrapped = multi and true or false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		ClipsDescendants = true,
		LayoutOrder = Order(page),
		Parent = page
	})
	Corner(tb, 8)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
		Parent = tb
	})
	local st = New("UIStroke", {Thickness = 1.2, Color = Color3.fromRGB(50, 50, 75), Parent = tb})
	Connect(tb.Focused, function() Tween(st, 0.2, {Color = Color3.fromRGB(130, 110, 255)}) end)
	Connect(tb.FocusLost, function() Tween(st, 0.2, {Color = Color3.fromRGB(50, 50, 75)}) end)
	return tb
end

local function ListBox(page, height)
	local sf = New("ScrollingFrame", {
		Size = UDim2.new(1, -4, 0, height),
		BackgroundColor3 = Color3.fromRGB(18, 18, 28),
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		LayoutOrder = Order(page),
		Parent = page
	})
	Corner(sf, 8)
	New("UIListLayout", {Padding = UDim.new(0, 3), Parent = sf})
	New("UIPadding", {
		PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 4),
		Parent = sf
	})
	local obj = {Frame = sf}
	function obj.Clear()
		for _, c in ipairs(sf:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
	end
	function obj.Add(text, cb)
		local row = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = Color3.fromRGB(32, 32, 48),
			Text = text,
			TextColor3 = Color3.fromRGB(220, 220, 238),
			Font = Enum.Font.Code,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
			Parent = sf
		})
		Corner(row, 5)
		New("UIPadding", {PaddingLeft = UDim.new(0, 6), Parent = row})
		Connect(row.Activated, function()
			row.BackgroundColor3 = Color3.fromRGB(80, 70, 140)
			Tween(row, 0.35, {BackgroundColor3 = Color3.fromRGB(32, 32, 48)})
			if cb then cb() end
		end)
	end
	return obj
end

local function OutBox(page, height)
	local sf = New("ScrollingFrame", {
		Size = UDim2.new(1, -4, 0, height),
		BackgroundColor3 = Color3.fromRGB(18, 18, 28),
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		LayoutOrder = Order(page),
		Parent = page
	})
	Corner(sf, 8)
	New("UIPadding", {
		PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6),
		Parent = sf
	})
	local lbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "",
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(200, 230, 210),
		Parent = sf
	})
	return {
		Set = function(t)
			t = tostring(t)
			if #t > 3000 then t = string.sub(t, 1, 3000) .. "\n...(truncated)" end
			lbl.Text = t
		end
	}
end

-- ================= TAB: HOME =================
local Home = CreateTab("Home")
local hero = New("Frame", {
	Size = UDim2.new(1, -4, 0, 70),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ClipsDescendants = true,
	LayoutOrder = Order(Home),
	Parent = Home
})
Corner(hero, 12)
AddGradient(hero)
New("TextLabel", {
	Size = UDim2.new(1, -20, 0, 36),
	Position = UDim2.fromOffset(12, 8),
	BackgroundTransparency = 1,
	Text = "Welcome, " .. LocalPlayer.DisplayName,
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
	TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = hero
})
New("TextLabel", {
	Size = UDim2.new(1, -20, 0, 20),
	Position = UDim2.fromOffset(12, 40),
	BackgroundTransparency = 1,
	Text = "Aurora Hub - everything in one place",
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = Color3.fromRGB(240, 240, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = hero
})

local execName, execVer = identifyexecutor()
Section(Home, "Executor")
Label(Home, "Name: " .. tostring(execName))
Label(Home, "Version: " .. tostring(execVer))
Section(Home, "Session")
Label(Home, "User: " .. LocalPlayer.Name .. " (" .. LocalPlayer.UserId .. ")")
Label(Home, "PlaceId: " .. game.PlaceId .. "  /  JobId: " .. string.sub(game.JobId, 1, 8))
local StatLbl = Label(Home, "FPS: --   Ping: --")
Section(Home, "Quick Copy")
BtnRow(Home, {
	{"Copy Info", function()
		local info = ("Executor: %s %s\nUser: %s\nPlaceId: %s\nJobId: %s"):format(
			tostring(execName), tostring(execVer), LocalPlayer.Name, game.PlaceId, game.JobId)
		setclipboard(info)
		Notify("Copied", "Session info copied", 3)
	end},
	{"Copy PlaceId", function()
		setclipboard(tostring(game.PlaceId))
		Notify("Copied", "PlaceId: " .. game.PlaceId, 3)
	end},
})

-- ================= TAB: SCRIPT =================
local ScriptTab = CreateTab("Script")
Section(ScriptTab, "Editor")
local Editor = Input(ScriptTab, "-- paste your Lua / Luau code here", true, 120)
BtnRow(ScriptTab, {
	{"Execute", function()
		local src = Editor.Text
		if src == "" then
			Notify("Script", "Editor is empty", 3)
			return
		end
		local fn, err = loadstring(src)
		if not fn then
			Notify("Compile Error", string.sub(tostring(err), 1, 120), 6)
			return
		end
		local ok, e = pcall(fn)
		if ok then
			Notify("Script", "Executed successfully", 3)
		else
			Notify("Runtime Error", string.sub(tostring(e), 1, 120), 6)
		end
	end},
	{"Clear", function()
		Editor.Text = ""
		Notify("Script", "Editor cleared", 2)
	end},
	{"Copy", function()
		setclipboard(Editor.Text)
		Notify("Script", "Copied to clipboard", 2)
	end},
})
Section(ScriptTab, "Load from URL")
local UrlBox = Input(ScriptTab, "https://...", false, 32)
Button(ScriptTab, "Load URL into Editor", function()
	local url = UrlBox.Text
	if url == "" then
		Notify("Script", "Enter a URL first", 3)
		return
	end
	task.spawn(function()
		local ok, res = pcall(function()
			return request({Url = url, Method = "GET"})
		end)
		if ok and res and res.Body then
			Editor.Text = res.Body
			Notify("Script", "Loaded (" .. #res.Body .. " chars)", 3)
		else
			Notify("Script", "Request failed: " .. tostring(res), 5)
		end
	end)
end)

-- ================= TAB: EXPLORER =================
local Explorer = CreateTab("Explorer")
Section(Explorer, "Instance Scanner")
local ExpSearch = Input(Explorer, "Search by name...", false, 32)
local ExpMode = "Copy path"
ChipRow(Explorer, {"Copy path", "Inspect env"}, 1, function(_, name) ExpMode = name end)
local ExpList = ListBox(Explorer, 130)
local ExpOut = OutBox(Explorer, 80)

local function OnInstanceTap(inst)
	if ExpMode == "Copy path" then
		local ok, path = pcall(function() return inst:GetFullName() end)
		setclipboard(ok and path or inst.Name)
		Notify("Explorer", "Path copied", 2)
	else
		if inst:IsA("LuaSourceContainer") then
			local ok, env = pcall(getsenv, inst)
			if ok and type(env) == "table" then
				local keys = {}
				for k, v in pairs(env) do
					table.insert(keys, tostring(k) .. " : " .. typeof(v))
				end
				table.sort(keys)
				ExpOut.Set(inst.Name .. " env (" .. #keys .. " keys)\n" .. table.concat(keys, "\n"))
			else
				ExpOut.Set("getsenv error: " .. tostring(env))
			end
		else
			Notify("Explorer", "Select a Script / ModuleScript", 3)
		end
	end
end

local function Scan(getter, label)
	ExpList.Clear()
	local ok, data = pcall(getter)
	if not ok or type(data) ~= "table" then
		Notify("Explorer", label .. " error: " .. tostring(data), 4)
		return
	end
	local q = string.lower(ExpSearch.Text)
	local shown = 0
	for _, inst in ipairs(data) do
		if shown >= 200 then break end
		local ok2, name = pcall(function() return inst.Name end)
		if ok2 and (q == "" or string.find(string.lower(name), q, 1, true)) then
			shown += 1
			ExpList.Add(inst.ClassName .. " | " .. name, function() OnInstanceTap(inst) end)
		end
	end
	Notify(label, shown .. " results (max 200)", 3)
end

BtnRow(Explorer, {
	{"Instances", function() Scan(getinstances, "getinstances") end},
	{"Nil", function() Scan(getnilinstances, "getnilinstances") end},
	{"Modules", function() Scan(getloadedmodules, "getloadedmodules") end},
})

-- ================= TAB: ENV =================
local EnvTab = CreateTab("Env")
Section(EnvTab, "Environment Viewer")
local EnvSearch = Input(EnvTab, "Filter keys...", false, 32)
local EnvList = ListBox(EnvTab, 150)

local function EnvShow(tbl, label)
	EnvList.Clear()
	local q = string.lower(EnvSearch.Text)
	local keys = {}
	for k, v in pairs(tbl) do
		local ks = tostring(k)
		if q == "" or string.find(string.lower(ks), q, 1, true) then
			table.insert(keys, {ks, typeof(v)})
		end
	end
	table.sort(keys, function(a, b) return a[1] < b[1] end)
	local shown = 0
	for _, kv in ipairs(keys) do
		if shown >= 300 then break end
		shown += 1
		EnvList.Add(kv[1] .. " : " .. kv[2], function()
			setclipboard(kv[1])
			Notify("Env", "Copied key: " .. kv[1], 2)
		end)
	end
	Notify(label, shown .. " keys shown / " .. #keys .. " matched", 3)
end

BtnRow(EnvTab, {
	{"getgenv", function() EnvShow(getgenv(), "getgenv") end},
	{"getrenv", function() EnvShow(getrenv(), "getrenv") end},
	{"getreg", function()
		EnvList.Clear()
		local tally, total = {}, 0
		for _, v in pairs(getreg()) do
			local t = typeof(v)
			tally[t] = (tally[t] or 0) + 1
			total += 1
		end
		local names = {}
		for t, c in pairs(tally) do table.insert(names, {t, c}) end
		table.sort(names, function(a, b) return a[2] > b[2] end)
		for _, nc in ipairs(names) do
			EnvList.Add(nc[1] .. " : " .. nc[2], nil)
		end
		Notify("getreg", total .. " entries", 3)
	end},
})

-- ================= TAB: HTTP =================
local HttpTab = CreateTab("HTTP")
Section(HttpTab, "Request Tester")
local HttpUrl = Input(HttpTab, "https://...", false, 32)
local HttpMethod = "GET"
ChipRow(HttpTab, {"GET", "POST"}, 1, function(_, name) HttpMethod = name end)
local HttpBody = Input(HttpTab, "Body (POST only)", true, 60)
local HttpOut = OutBox(HttpTab, 120)
local LastResponse = ""
BtnRow(HttpTab, {
	{"Send", function()
		local url = HttpUrl.Text
		if url == "" then
			Notify("HTTP", "Enter a URL first", 3)
			return
		end
		HttpOut.Set("Sending...")
		task.spawn(function()
			local ok, res = pcall(function()
				return request({
					Url = url,
					Method = HttpMethod,
					Headers = {["Content-Type"] = "application/json"},
					Body = (HttpMethod == "POST") and HttpBody.Text or nil,
				})
			end)
			if ok and res then
				LastResponse = tostring(res.Body)
				HttpOut.Set(("Status: %s (%s)\n\n%s"):format(tostring(res.StatusCode), tostring(res.StatusMessage), LastResponse))
				Notify("HTTP", "Status " .. tostring(res.StatusCode), 3)
			else
				HttpOut.Set("Error: " .. tostring(res))
				Notify("HTTP", "Request failed", 4)
			end
		end)
	end},
	{"Copy Response", function()
		setclipboard(LastResponse)
		Notify("HTTP", "Response copied", 2)
	end},
})

-- ================= TAB: LAB =================
local Lab = CreateTab("Lab")
Section(Lab, "hookfunction / newcclosure")
local function TestFunc()
	return "original"
end
local originalTest = nil
local hooked = false
local LabOut = OutBox(Lab, 90)
Toggle(Lab, "Hook TestFunc", false, function(state)
	if state and not hooked then
		originalTest = hookfunction(TestFunc, newcclosure(function(...)
			if checkcaller() then
				return "hooked (called by executor)"
			end
			return "hooked"
		end))
		hooked = true
		Notify("Lab", "TestFunc hooked", 3)
	elseif not state and hooked then
		hookfunction(TestFunc, originalTest)
		hooked = false
		Notify("Lab", "TestFunc restored", 3)
	end
end)
Button(Lab, "Call TestFunc()", function()
	LabOut.Set(("TestFunc() -> %s\ncheckcaller() -> %s"):format(tostring(TestFunc()), tostring(checkcaller())))
end)
Section(Lab, "setreadonly / isreadonly")
local DemoTable = {value = 1}
Toggle(Lab, "Readonly DemoTable", false, function(state)
	setreadonly(DemoTable, state)
	Notify("Lab", "readonly = " .. tostring(isreadonly(DemoTable)), 3)
end)
Button(Lab, "Write test (value + 1)", function()
	local ok, err = pcall(function()
		DemoTable.value = DemoTable.value + 1
	end)
	LabOut.Set(("write ok: %s\nvalue: %s\nisreadonly: %s\n%s"):format(
		tostring(ok), tostring(DemoTable.value), tostring(isreadonly(DemoTable)), ok and "" or tostring(err)))
end)

-- ================= TAB: SETTINGS =================
local SettingsTab = CreateTab("Settings")
Section(SettingsTab, "Theme")
ChipRow(SettingsTab, ThemeOrder, 1, function(_, name)
	ApplyTheme(name)
	Notify("Theme", name .. " applied", 2)
end)
Section(SettingsTab, "Look & Feel")
local ScaleSlider
local Minimized = false
Slider(SettingsTab, "UI Scale", 0.5, 1.4, BaseScale, function(v)
	BaseScale = v
	if not Minimized and Holder.Visible then
		Scale.Scale = v
	end
end, 2)
Slider(SettingsTab, "Window Transparency", 0, 0.6, 0.05, function(v)
	Window.BackgroundTransparency = v
end, 2)
Slider(SettingsTab, "Gradient Speed", 0, 180, Settings.GradSpeed, function(v)
	Settings.GradSpeed = v
end, 0)
Toggle(SettingsTab, "Particles", true, function(s)
	Settings.Particles = s
	ParticleLayer.Visible = s
end)
Toggle(SettingsTab, "Glow Border", true, function(s)
	Settings.Glow = s
	Glow.Enabled = s
end)
Section(SettingsTab, "Danger Zone")

-- ================= ORB (minimized) =================
local Orb = New("TextButton", {
	Name = "Orb",
	Size = UDim2.fromOffset(0, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.1, 0.3),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 10,
	Parent = Gui
})
Corner(Orb, 30)
AddGradient(Orb)
New("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "A",
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 12,
	Parent = Orb
})
local OrbStroke = New("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.2, Parent = Orb})
AddGradient(OrbStroke)
local Ring = New("Frame", {
	Size = UDim2.fromOffset(52, 52),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1,
	ZIndex = 9,
	Parent = Orb
})
Corner(Ring, 100)
local RingStroke = New("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Parent = Ring})
AddGradient(RingStroke)

local Busy = false
local function SetMinimized(state)
	if Busy or Minimized == state then return end
	Busy = true
	Minimized = state
	if state then
		-- window -> orb
		local center = Holder.AbsolutePosition + Holder.AbsoluteSize / 2
		Orb.Position = UDim2.fromOffset(center.X, center.Y)
		Tween(Scale, 0.35, {Scale = 0.01}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.35, function()
			Holder.Visible = false
			Orb.Visible = true
			Orb.Size = UDim2.fromOffset(0, 0)
			Tween(Orb, 0.4, {Size = UDim2.fromOffset(52, 52)}, Enum.EasingStyle.Back)
			task.delay(0.4, function() Busy = false end)
		end)
	else
		-- orb -> window
		local vp = Camera.ViewportSize
		local hw, hh = WIN_W * BaseScale / 2, WIN_H * BaseScale / 2
		local c = Orb.AbsolutePosition + Orb.AbsoluteSize / 2
		local cx = math.clamp(c.X, hw, math.max(hw, vp.X - hw))
		local cy = math.clamp(c.Y, hh, math.max(hh, vp.Y - hh))
		Tween(Orb, 0.25, {Size = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.25, function()
			Orb.Visible = false
			Holder.Position = UDim2.fromOffset(cx, cy)
			Holder.Visible = true
			Scale.Scale = 0.01
			Tween(Scale, 0.45, {Scale = BaseScale}, Enum.EasingStyle.Back)
			task.delay(0.45, function() Busy = false end)
		end)
	end
end

MakeDraggable(TopBar, Holder, nil)
MakeDraggable(Orb, Orb, function() SetMinimized(false) end)
Connect(MinBtn.Activated, function() SetMinimized(true) end)

-- ================= DESTROY =================
local function Destroy()
	for _, c in ipairs(Connections) do
		pcall(function() c:Disconnect() end)
	end
	Connections = {}
	if Gui then Gui:Destroy() end
	getgenv().AuroraHub = nil
end
getgenv().AuroraHub = {Destroy = Destroy}

Button(SettingsTab, "Destroy UI", function()
	Notify("Aurora Hub", "Closing...", 2)
	Tween(Scale, 0.3, {Scale = 0.01}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.delay(0.35, Destroy)
end)
Connect(CloseBtn.Activated, function()
	Tween(Scale, 0.3, {Scale = 0.01}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.delay(0.35, Destroy)
end)

-- ================= MAIN LOOP =================
local frames, acc = 0, 0
Connect(RunService.Heartbeat, function(dt)
	-- animated gradients
	for i = #Gradients, 1, -1 do
		local g = Gradients[i]
		if g.Parent then
			if g.Enabled then
				g.Rotation = (g.Rotation + dt * Settings.GradSpeed) % 360
			end
		else
			table.remove(Gradients, i)
		end
	end
	-- particles
	if Settings.Particles and Holder.Visible then
		for _, p in ipairs(Particles) do
			local pos = p.f.Position
			local y = pos.Y.Scale - p.speed * dt
			local x = pos.X.Scale + p.drift * dt
			if y < -0.05 then
				y = 1.05
				x = math.random()
			end
			p.f.Position = UDim2.fromScale(x, y)
		end
	end
	-- orb pulse ring
	if Orb.Visible then
		local a = (tick() % 1.6) / 1.6
		local s = 52 + a * 26
		Ring.Size = UDim2.fromOffset(s, s)
		RingStroke.Transparency = a
	end
	-- fps / ping
	frames += 1
	acc += dt
	if acc >= 0.5 then
		local fps = math.floor(frames / acc + 0.5)
		frames, acc = 0, 0
		local ok, ping = pcall(function()
			return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		StatLbl.Text = ("FPS: %d   Ping: %s ms"):format(fps, ok and tostring(ping) or "--")
	end
end)

-- ================= SPLASH =================
local Splash = New("Frame", {
	Size = UDim2.fromOffset(280, 96),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(14, 12, 26),
	ZIndex = 50,
	Parent = Gui
})
Corner(Splash, 14)
local SplashStroke = New("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Parent = Splash})
AddGradient(SplashStroke)
local SplashTitle = New("TextLabel", {
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.fromOffset(0, 12),
	BackgroundTransparency = 1,
	Text = "AURORA HUB",
	Font = Enum.Font.GothamBlack,
	TextSize = 28,
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 51,
	Parent = Splash
})
AddGradient(SplashTitle)
local SplashBar = New("Frame", {
	Size = UDim2.new(1, -40, 0, 8),
	Position = UDim2.new(0, 20, 1, -26),
	BackgroundColor3 = Color3.fromRGB(36, 34, 56),
	ZIndex = 51,
	Parent = Splash
})
Corner(SplashBar, 4)
local SplashFill = New("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 52,
	Parent = SplashBar
})
Corner(SplashFill, 4)
AddGradient(SplashFill)
Splash.Size = UDim2.fromOffset(0, 0)
Tween(Splash, 0.4, {Size = UDim2.fromOffset(280, 96)}, Enum.EasingStyle.Back)
task.delay(0.3, function()
	Tween(SplashFill, 1.4, {Size = UDim2.fromScale(1, 1)}, Enum.EasingStyle.Quad)
end)
task.delay(1.9, function()
	Tween(Splash, 0.3, {Size = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.delay(0.3, function()
		Splash:Destroy()
		Holder.Visible = true
		Scale.Scale = 0.01
		Tween(Scale, 0.55, {Scale = BaseScale}, Enum.EasingStyle.Back)
		SelectTab("Home")
		Notify("Aurora Hub", "Loaded on " .. tostring(execName), 4)
	end)
end)
