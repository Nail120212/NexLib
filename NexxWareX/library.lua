--[[
	Fluid Glass UI Library
	Theme: Liquid Glass / Fluid Glass (transparent only)
	Icons: NexLib raw (Lucide + Gravity)
	  "search"            → lucide (default)
	  "Lucide:crosshair"  → lucide
	  "gravity:gear"      → gravity
]]

local FluidGlass = {
	Version = "2.0.0",
	Flags = {},
	Windows = {},
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local function GuiParent()
	local ok, hui = pcall(function()
		return gethui()
	end)
	if ok and hui then
		return hui
	end
	local ok2, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 and core then
		return core
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function HttpGet(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and #body > 10 then
		return body
	end
	local req = (syn and syn.request) or (http and http.request) or http_request or request
	if req then
		local success, response = pcall(req, { Url = url, Method = "GET" })
		if success and response then
			return response.Body or response.body
		end
	end
	return nil
end

local function HasFS()
	return typeof(writefile) == "function" and typeof(readfile) == "function"
end

-- ZIndex / sizes (verified stacking)
local Z = {
	Window = 10,
	Sidebar = 20,
	Header = 26,
	Content = 16,
	Row = 22,
	Control = 30,
	Popup = 50,
	Dropdown = 56,
	ColorPicker = 62,
	DialogDim = 80,
	Dialog = 86,
	Tooltip = 92,
	Notify = 96,
	Watermark = 40,
}

local SIZE = {
	Window = Vector2.new(800, 540),
	Sidebar = 200,
	Header = 58,
	Footer = 52,
	Row = 44,
	Toggle = Vector2.new(44, 24),
	Slider = 148,
	Popup = 228,
	Dialog = Vector2.new(360, 188),
	Color = Vector2.new(214, 252),
	Notify = Vector2.new(280, 64),
}

local TWEEN = {
	Fluid = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Snap = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Pop = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	In = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
}

-- Liquid Glass theme only
local Theme = {
	Name = "LiquidGlass",
	Accent = Color3.fromRGB(154, 212, 255),
	AccentDeep = Color3.fromRGB(78, 163, 230),
	Text = Color3.fromRGB(238, 247, 255),
	Muted = Color3.fromRGB(159, 180, 200),
	Faint = Color3.fromRGB(109, 132, 153),
	Glass = Color3.fromRGB(16, 28, 40),
	GlassTop = Color3.fromRGB(48, 72, 96),
	Stroke = Color3.fromRGB(214, 236, 255),
	Danger = Color3.fromRGB(255, 132, 132),
	Track = Color3.fromRGB(10, 16, 24),
	FillTransparency = 0.38,
	PanelTransparency = 0.46,
	StrokeTransparency = 0.78,
	RowTransparency = 0.88,
}

FluidGlass.Theme = Theme
FluidGlass.Z = Z
FluidGlass.SIZE = SIZE

local function Tween(obj, info, props)
	local t = TweenService:Create(obj, info or TWEEN.Fluid, props)
	t:Play()
	return t
end

local function Corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 14)
	c.Parent = parent
	return c
end

local function Stroke(parent, transparency, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Stroke
	s.Transparency = transparency or Theme.StrokeTransparency
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function GlassGradient(parent)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.GlassTop),
		ColorSequenceKeypoint.new(0.42, Theme.Glass),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 16, 24)),
	})
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 0.22),
	})
	g.Parent = parent
	return g
end

local function Pad(parent, t, r, b, l)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingRight = UDim.new(0, r or t or 0)
	p.PaddingBottom = UDim.new(0, b or t or 0)
	p.PaddingLeft = UDim.new(0, l or r or t or 0)
	p.Parent = parent
	return p
end

local function New(className, props)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function Click(parent, callback)
	local btn = New("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = (parent.ZIndex or 1) + 4,
		Parent = parent,
	})
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local function Drag(handle, target)
	local dragging, start, origin
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			start = input.Position
			origin = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - start
			Tween(target, TWEEN.Snap, {
				Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y),
			})
		end
	end)
end

local function Round(n, places)
	local m = 10 ^ (places or 0)
	return math.floor(n * m + 0.5) / m
end

local function Merge(defaults, given)
	given = given or {}
	local out = {}
	for k, v in pairs(defaults) do
		out[k] = given[k]
		if out[k] == nil then
			out[k] = v
		end
	end
	for k, v in pairs(given) do
		if out[k] == nil then
			out[k] = v
		end
	end
	return out
end

-- Icons from NexLib raw
local IconPacks = { lucide = {}, gravity = {} }
local IconsReady = false

local ICON_URL = {
	lucide = "https://raw.githubusercontent.com/Nail120212/NexLib/main/Icons/lucide.lua",
	gravity = "https://raw.githubusercontent.com/Nail120212/NexLib/main/Icons/gravity.lua",
}

local function LoadPack(name, url)
	local src = HttpGet(url)
	if not src then
		return
	end
	local fn = loadstring(src)
	if not fn then
		return
	end
	local ok, tbl = pcall(fn)
	if ok and type(tbl) == "table" then
		IconPacks[name] = tbl
	end
end

task.spawn(function()
	LoadPack("lucide", ICON_URL.lucide)
	LoadPack("gravity", ICON_URL.gravity)
	IconsReady = true
end)

local function NormalizeIconName(name)
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	name = name:gsub("_", "-"):gsub("%s+", "-")
	return string.lower(name)
end

function FluidGlass:ResolveIcon(spec)
	if spec == nil or spec == "" then
		return nil, "lucide"
	end
	spec = tostring(spec)
	if spec:find("rbxasset", 1, true) then
		return spec, "asset"
	end
	local pack, name = spec:match("^([%w]+):(.+)$")
	if pack then
		pack = string.lower(pack)
		name = NormalizeIconName(name)
	else
		pack = "lucide"
		name = NormalizeIconName(spec)
	end
	if pack == "lucide" or pack == "lucid" then
		pack = "lucide"
	end
	local map = IconPacks[pack]
	if map and map[name] then
		return map[name], pack
	end
	if IconPacks.lucide[name] then
		return IconPacks.lucide[name], "lucide"
	end
	return nil, pack
end

function FluidGlass:SetIcon(imageLabel, spec, color)
	if not imageLabel then
		return
	end
	local function apply()
		local asset = self:ResolveIcon(spec)
		if asset then
			imageLabel.Image = asset
			imageLabel.ImageColor3 = color or Theme.Text
			imageLabel.ImageTransparency = 0
			imageLabel.ScaleType = Enum.ScaleType.Fit
		end
	end
	if IconsReady then
		apply()
	else
		task.spawn(function()
			for _ = 1, 40 do
				if IconsReady then
					break
				end
				task.wait(0.05)
			end
			apply()
		end)
	end
end

-- Screen
local existing = GuiParent():FindFirstChild("FluidGlassUI")
if existing then
	existing:Destroy()
end

local Screen = New("ScreenGui", {
	Name = "FluidGlassUI",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 999999,
	Parent = GuiParent(),
})
FluidGlass.Screen = Screen

local BlurEffect = Instance.new("BlurEffect")
BlurEffect.Name = "FluidGlassBlur"
BlurEffect.Size = 0
BlurEffect.Parent = Lighting

-- Dialog host
local function CreateDialogHost()
	local dim = New("TextButton", {
		Name = "DialogDim",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Color3.fromRGB(4, 8, 12),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = Z.DialogDim,
		Visible = false,
		Parent = Screen,
	})
	local card = New("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(SIZE.Dialog.X, SIZE.Dialog.Y),
		BackgroundColor3 = Theme.Glass,
		BackgroundTransparency = 1,
		ZIndex = Z.Dialog,
		Parent = dim,
	})
	Corner(card, 18)
	local cardStroke = Stroke(card, 1, Theme.Stroke, 1.2)
	GlassGradient(card)
	local title = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 18),
		Size = UDim2.new(1, -44, 0, 24),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
		TextTransparency = 1,
		ZIndex = Z.Dialog + 1,
		Parent = card,
	})
	local body = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 48),
		Size = UDim2.new(1, -44, 0, 56),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Theme.Muted,
		TextTransparency = 1,
		ZIndex = Z.Dialog + 1,
		Parent = card,
	})
	local cancelBtn = New("TextButton", {
		Name = "Cancel",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -128, 1, -16),
		Size = UDim2.fromOffset(100, 34),
		BackgroundTransparency = 0.55,
		BackgroundColor3 = Theme.Glass,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Theme.Muted,
		AutoButtonColor = false,
		ZIndex = Z.Dialog + 2,
		Parent = card,
	})
	Corner(cancelBtn, 10)
	Stroke(cancelBtn, 0.82)
	local confirmBtn = New("TextButton", {
		Name = "Confirm",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(104, 34),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.15,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(8, 16, 24),
		AutoButtonColor = false,
		ZIndex = Z.Dialog + 2,
		Parent = card,
	})
	Corner(confirmBtn, 10)

	local pending
	local function Close(result)
		Tween(dim, TWEEN.In, { BackgroundTransparency = 1 })
		Tween(card, TWEEN.In, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.54) })
		Tween(cardStroke, TWEEN.In, { Transparency = 1 })
		Tween(title, TWEEN.In, { TextTransparency = 1 })
		Tween(body, TWEEN.In, { TextTransparency = 1 })
		task.delay(0.2, function()
			if not pending then
				dim.Visible = false
			end
		end)
		local cb = pending
		pending = nil
		if cb then
			cb(result)
		end
	end

	confirmBtn.MouseButton1Click:Connect(function()
		Close(true)
	end)
	cancelBtn.MouseButton1Click:Connect(function()
		Close(false)
	end)
	dim.MouseButton1Click:Connect(function()
		Close(false)
	end)

	return function(opts)
		opts = Merge({
			Title = "Confirm",
			Content = "Are you sure?",
			Confirm = "Confirm",
			Cancel = "Cancel",
		}, opts)
		pending = opts.Callback
		title.Text = opts.Title
		body.Text = opts.Content
		confirmBtn.Text = opts.Confirm
		cancelBtn.Text = opts.Cancel
		dim.Visible = true
		dim.ZIndex = Z.DialogDim
		card.Position = UDim2.fromScale(0.5, 0.54)
		Tween(dim, TWEEN.Fluid, { BackgroundTransparency = 0.42 })
		Tween(card, TWEEN.Pop, { BackgroundTransparency = Theme.FillTransparency, Position = UDim2.fromScale(0.5, 0.5) })
		Tween(cardStroke, TWEEN.Fluid, { Transparency = 0.72 })
		Tween(title, TWEEN.Fluid, { TextTransparency = 0 })
		Tween(body, TWEEN.Fluid, { TextTransparency = 0.12 })
	end
end

local OpenDialog = CreateDialogHost()
FluidGlass.Dialog = OpenDialog

-- Notifications
local NotifyHolder = New("Frame", {
	Name = "Notifies",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 18),
	Size = UDim2.fromOffset(SIZE.Notify.X, 400),
	BackgroundTransparency = 1,
	ZIndex = Z.Notify,
	Parent = Screen,
})
New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
	Parent = NotifyHolder,
})

function FluidGlass:Notify(opts)
	opts = Merge({ Title = "Fluid Glass", Content = "", Duration = 3.4, Icon = "bell" }, opts)
	local card = New("Frame", {
		Size = UDim2.fromOffset(SIZE.Notify.X, SIZE.Notify.Y),
		BackgroundColor3 = Theme.Glass,
		BackgroundTransparency = 0.28,
		ZIndex = Z.Notify,
		Parent = NotifyHolder,
	})
	Corner(card, 14)
	Stroke(card, 0.74)
	GlassGradient(card)
	local icon = New("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 16),
		Size = UDim2.fromOffset(28, 28),
		ZIndex = Z.Notify + 1,
		Parent = card,
	})
	self:SetIcon(icon, opts.Icon, Theme.Accent)
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(48, 10),
		Size = UDim2.new(1, -60, 0, 20),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
		Text = opts.Title,
		ZIndex = Z.Notify + 1,
		Parent = card,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(48, 30),
		Size = UDim2.new(1, -60, 0, 22),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Muted,
		Text = opts.Content,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = Z.Notify + 1,
		Parent = card,
	})
	task.delay(opts.Duration, function()
		Tween(card, TWEEN.In, { BackgroundTransparency = 1 })
		task.wait(0.2)
		card:Destroy()
	end)
	return card
end

-- Window
function FluidGlass:CreateWindow(config)
	config = Merge({
		Title = "Fluid Glass",
		Subtitle = "Liquid Glass",
		Icon = "layers",
		Size = UDim2.fromOffset(SIZE.Window.X, SIZE.Window.Y),
		Keybind = Enum.KeyCode.RightShift,
		ConfigFolder = "FluidGlass",
		Website = "",
		Blur = true,
	}, config)

	local Window = {
		Tabs = {},
		Current = 1,
		Visible = true,
		Keybind = config.Keybind,
		ConfigFolder = config.ConfigFolder,
		Flags = FluidGlass.Flags,
	}

	if HasFS() and not isfolder(config.ConfigFolder) then
		pcall(makefolder, config.ConfigFolder)
	end

	local Root = New("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = config.Size,
		BackgroundColor3 = Theme.Glass,
		BackgroundTransparency = Theme.FillTransparency,
		ZIndex = Z.Window,
		Parent = Screen,
	})
	Corner(Root, 20)
	Stroke(Root, Theme.StrokeTransparency, Theme.Stroke, 1.15)
	GlassGradient(Root)
	Window.Root = Root
	FluidGlass.MainWindow = Root

	local specular = New("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		Size = UDim2.new(1, 0, 0, 70),
		ZIndex = Z.Window + 1,
		Parent = Root,
	})
	local specGrad = Instance.new("UIGradient")
	specGrad.Rotation = 90
	specGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	specGrad.Parent = specular
	Corner(specular, 20)

	local Sidebar = New("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Glass,
		BackgroundTransparency = 0.55,
		Size = UDim2.new(0, SIZE.Sidebar, 1, 0),
		ZIndex = Z.Sidebar,
		Parent = Root,
	})
	Corner(Sidebar, 20)
	New("Frame", {
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.88,
		Position = UDim2.new(1, -1, 0, 16),
		Size = UDim2.new(0, 1, 1, -32),
		BorderSizePixel = 0,
		ZIndex = Z.Sidebar + 1,
		Parent = Sidebar,
	})

	local Brand = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, SIZE.Header),
		ZIndex = Z.Sidebar + 2,
		Parent = Sidebar,
	})
	local brandIcon = New("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(26, 26),
		ZIndex = Z.Sidebar + 3,
		Parent = Brand,
	})
	self:SetIcon(brandIcon, config.Icon, Theme.Accent)
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(48, 12),
		Size = UDim2.new(1, -58, 0, 18),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
		Text = config.Title,
		ZIndex = Z.Sidebar + 3,
		Parent = Brand,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(48, 30),
		Size = UDim2.new(1, -58, 0, 16),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Faint,
		Text = config.Subtitle,
		ZIndex = Z.Sidebar + 3,
		Parent = Brand,
	})

	local TabList = New("ScrollingFrame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, SIZE.Header),
		Size = UDim2.new(1, -14, 1, -(SIZE.Header + SIZE.Footer)),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = Z.Sidebar + 2,
		Parent = Sidebar,
	})
	local tabLayout = New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TabList,
	})
	tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabList.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 8)
	end)

	local Header = New("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(SIZE.Sidebar, 0),
		Size = UDim2.new(1, -SIZE.Sidebar, 0, SIZE.Header),
		ZIndex = Z.Header,
		Parent = Root,
	})
	Drag(Header, Root)
	Drag(Brand, Root)

	local SearchBox = New("TextBox", {
		BackgroundColor3 = Theme.Glass,
		BackgroundTransparency = 0.35,
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -80, 0, 34),
		Font = Enum.Font.Gotham,
		PlaceholderText = "Search",
		PlaceholderColor3 = Theme.Faint,
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = Z.Header + 1,
		Parent = Header,
	})
	Corner(SearchBox, 11)
	Stroke(SearchBox, 0.84)
	Pad(SearchBox, 0, 12, 0, 36)
	local searchIcon = New("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = Z.Header + 2,
		Parent = SearchBox,
	})
	self:SetIcon(searchIcon, "search", Theme.Faint)

	local Close = New("ImageButton", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		ZIndex = Z.Header + 2,
		Parent = Header,
	})
	self:SetIcon(Close, "x", Theme.Muted)

	local Content = New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(SIZE.Sidebar, SIZE.Header),
		Size = UDim2.new(1, -SIZE.Sidebar, 1, -SIZE.Header),
		ZIndex = Z.Content,
		ClipsDescendants = true,
		Parent = Root,
	})

	local Registry = {}

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(SearchBox.Text)
		for _, item in ipairs(Registry) do
			if q == "" then
				item.Root.Visible = true
			else
				item.Root.Visible = string.find(string.lower(item.Name), q, 1, true) ~= nil
			end
		end
	end)

	local function SetBlur(on)
		if config.Blur and on then
			Tween(BlurEffect, TWEEN.Fluid, { Size = 18 })
		else
			Tween(BlurEffect, TWEEN.Fluid, { Size = 0 })
		end
	end
	SetBlur(true)

	function Window:Toggle(state)
		if state == nil then
			state = not Window.Visible
		end
		Window.Visible = state
		if state then
			Root.Visible = true
			Tween(Root, TWEEN.Pop, { BackgroundTransparency = Theme.FillTransparency, Size = config.Size })
			SetBlur(true)
		else
			Tween(Root, TWEEN.In, {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(config.Size.X.Offset - 12, config.Size.Y.Offset - 12),
			})
			SetBlur(false)
			task.delay(0.2, function()
				if not Window.Visible then
					Root.Visible = false
				end
			end)
		end
	end

	Close.MouseButton1Click:Connect(function()
		Window:Toggle(false)
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Window.Keybind then
			Window:Toggle()
		end
	end)

	local function SelectTab(index)
		Window.Current = index
		for i, tab in ipairs(Window.Tabs) do
			local on = i == index
			tab.Page.Visible = on
			Tween(tab.Button, TWEEN.Fluid, {
				BackgroundTransparency = on and 0.55 or 1,
			})
			Tween(tab.Label, TWEEN.Fluid, {
				TextColor3 = on and Theme.Text or Theme.Muted,
			})
			if tab.IconImg then
				Tween(tab.IconImg, TWEEN.Fluid, {
					ImageColor3 = on and Theme.Accent or Theme.Faint,
				})
			end
		end
	end

	function Window:AddTabLabel(name)
		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 0, 22),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			Text = string.upper(name),
			TextColor3 = Theme.Faint,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = Z.Sidebar + 3,
			Parent = TabList,
		})
	end

	function Window:AddTab(tabConfig)
		tabConfig = Merge({ Name = "Tab", Icon = "circle" }, tabConfig)
		local tab = { Name = tabConfig.Name }

		local btn = New("Frame", {
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 40),
			ZIndex = Z.Sidebar + 3,
			Parent = TabList,
		})
		Corner(btn, 12)
		local icon = New("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(20, 20),
			ZIndex = Z.Sidebar + 4,
			Parent = btn,
		})
		FluidGlass:SetIcon(icon, tabConfig.Icon, Theme.Faint)
		local label = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(38, 0),
			Size = UDim2.new(1, -44, 1, 0),
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Muted,
			Text = tabConfig.Name,
			ZIndex = Z.Sidebar + 4,
			Parent = btn,
		})
		Click(btn, function()
			for i, t in ipairs(Window.Tabs) do
				if t == tab then
					SelectTab(i)
				end
			end
		end)

		local page = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			ZIndex = Z.Content,
			Parent = Content,
		})
		local left = New("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 8),
			Size = UDim2.new(0.5, -18, 1, -16),
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 2,
			BorderSizePixel = 0,
			ZIndex = Z.Content + 1,
			Parent = page,
		})
		local right = New("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 4, 0, 8),
			Size = UDim2.new(0.5, -18, 1, -16),
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 2,
			BorderSizePixel = 0,
			ZIndex = Z.Content + 1,
			Parent = page,
		})
		local lLay = New("UIListLayout", { Padding = UDim.new(0, 10), Parent = left })
		local rLay = New("UIListLayout", { Padding = UDim.new(0, 10), Parent = right })
		lLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			left.CanvasSize = UDim2.fromOffset(0, lLay.AbsoluteContentSize.Y + 12)
		end)
		rLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			right.CanvasSize = UDim2.fromOffset(0, rLay.AbsoluteContentSize.Y + 12)
		end)

		tab.Button = btn
		tab.Label = label
		tab.IconImg = icon
		tab.Page = page

		local function MakeSection(secConfig)
			secConfig = Merge({ Name = "Section", Side = "Left" }, secConfig)
			local parent = (string.lower(secConfig.Side) == "right") and right or left
			local wrap = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				ZIndex = Z.Row,
				Parent = parent,
			})
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Faint,
				Text = string.upper(secConfig.Name),
				ZIndex = Z.Row + 1,
				Parent = wrap,
			})
			local body = New("Frame", {
				BackgroundColor3 = Theme.Glass,
				BackgroundTransparency = Theme.PanelTransparency,
				Position = UDim2.fromOffset(0, 20),
				Size = UDim2.new(1, 0, 0, 20),
				ZIndex = Z.Row,
				Parent = wrap,
			})
			Corner(body, 14)
			Stroke(body, 0.84)
			local list = New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
			list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				local h = math.max(list.AbsoluteContentSize.Y, 8)
				body.Size = UDim2.new(1, 0, 0, h)
				wrap.Size = UDim2.new(1, 0, 0, h + 24)
			end)

			local Section = {}

			local function Row(name)
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, SIZE.Row),
					ZIndex = Z.Row + 1,
					Parent = body,
				})
				table.insert(Registry, { Name = name, Root = row })
				local title = New("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 0),
					Size = UDim2.new(1, -24, 1, 0),
					Font = Enum.Font.GothamMedium,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Theme.Text,
					Text = name,
					ZIndex = Z.Row + 2,
					Parent = row,
				})
				return row, title
			end

			function Section:AddParagraph(opts)
				opts = Merge({ Name = "Note", Content = "" }, opts)
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 58),
					ZIndex = Z.Row + 1,
					Parent = body,
				})
				table.insert(Registry, { Name = opts.Name, Root = row })
				New("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 8),
					Size = UDim2.new(1, -24, 0, 16),
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Theme.Text,
					Text = opts.Name,
					ZIndex = Z.Row + 2,
					Parent = row,
				})
				New("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 26),
					Size = UDim2.new(1, -24, 0, 26),
					Font = Enum.Font.Gotham,
					TextSize = 12,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Theme.Muted,
					Text = opts.Content,
					ZIndex = Z.Row + 2,
					Parent = row,
				})
				return row
			end

			function Section:AddDivider()
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 10),
					Parent = body,
				})
				New("Frame", {
					BackgroundColor3 = Theme.Stroke,
					BackgroundTransparency = 0.9,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, -24, 0, 1),
					BorderSizePixel = 0,
					Parent = row,
				})
			end

			function Section:AddToggle(opts)
				opts = Merge({
					Name = "Toggle",
					Default = false,
					Flag = nil,
					Callback = function() end,
					Dialog = nil,
				}, opts)
				local row = Row(opts.Name)
				local track = New("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.fromOffset(SIZE.Toggle.X, SIZE.Toggle.Y),
					BackgroundColor3 = Theme.Track,
					BackgroundTransparency = 0.2,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(track, 12)
				Stroke(track, 0.8)
				local knob = New("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 3, 0.5, 0),
					Size = UDim2.fromOffset(18, 18),
					BackgroundColor3 = Theme.Muted,
					ZIndex = Z.Control + 1,
					Parent = track,
				})
				Corner(knob, 9)

				local lib = { Value = opts.Default }
				local function Paint(v)
					Tween(track, TWEEN.Fluid, {
						BackgroundColor3 = v and Theme.Accent or Theme.Track,
						BackgroundTransparency = v and 0.12 or 0.2,
					})
					Tween(knob, TWEEN.Fluid, {
						Position = v and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
						BackgroundColor3 = v and Color3.new(1, 1, 1) or Theme.Muted,
					})
				end
				Paint(lib.Value)

				local function Apply(v)
					lib.Value = v
					Paint(v)
					opts.Callback(v)
				end

				Click(track, function()
					local nextv = not lib.Value
					if opts.Dialog then
						local when = string.lower(opts.Dialog.When or "on")
						local need = (when == "both") or (when == "on" and nextv) or (when == "off" and not nextv)
						if need then
							OpenDialog({
								Title = opts.Dialog.Title or opts.Name,
								Content = opts.Dialog.Content or "Confirm this change.",
								Confirm = opts.Dialog.Confirm or "Continue",
								Cancel = opts.Dialog.Cancel or "Cancel",
								Callback = function(ok)
									if ok then
										Apply(nextv)
									end
								end,
							})
							return
						end
					end
					Apply(nextv)
				end)

				function lib:GetValue()
					return lib.Value
				end
				function lib:SetValue(v)
					Apply(v and true or false)
				end
				if opts.Flag then
					FluidGlass.Flags[opts.Flag] = lib
				end
				return lib
			end

			function Section:AddSlider(opts)
				opts = Merge({
					Name = "Slider",
					Min = 0,
					Max = 100,
					Default = 50,
					Rounding = 0,
					Suffix = "",
					Flag = nil,
					Callback = function() end,
				}, opts)
				local row, title = Row(opts.Name)
				title.Size = UDim2.new(1, -170, 1, 0)
				local valueLbl = New("TextLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, -8),
					Size = UDim2.fromOffset(48, 14),
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextColor3 = Theme.Accent,
					ZIndex = Z.Control,
					Parent = row,
				})
				local bar = New("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 8),
					Size = UDim2.fromOffset(SIZE.Slider, 6),
					BackgroundColor3 = Theme.Track,
					BackgroundTransparency = 0.15,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(bar, 3)
				local fill = New("Frame", {
					BackgroundColor3 = Theme.Accent,
					Size = UDim2.fromScale(0, 1),
					ZIndex = Z.Control + 1,
					Parent = bar,
				})
				Corner(fill, 3)
				local lib = { Value = opts.Default }
				local function Set(v, fire)
					v = math.clamp(v, opts.Min, opts.Max)
					v = Round(v, opts.Rounding)
					lib.Value = v
					local a = (opts.Max == opts.Min) and 0 or (v - opts.Min) / (opts.Max - opts.Min)
					fill.Size = UDim2.fromScale(a, 1)
					valueLbl.Text = tostring(v) .. (opts.Suffix or "")
					if fire ~= false then
						opts.Callback(v)
					end
				end
				Set(opts.Default, false)
				local holding = false
				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						holding = true
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						holding = false
					end
				end)
				RunService.RenderStepped:Connect(function()
					if holding then
						local x = math.clamp((Mouse.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
						Set(opts.Min + (opts.Max - opts.Min) * x)
					end
				end)
				function lib:GetValue()
					return lib.Value
				end
				function lib:SetValue(v)
					Set(tonumber(v) or lib.Value)
				end
				if opts.Flag then
					FluidGlass.Flags[opts.Flag] = lib
				end
				return lib
			end

			function Section:AddDropdown(opts)
				opts = Merge({
					Name = "Dropdown",
					Values = { "One", "Two" },
					Default = nil,
					Multi = false,
					Flag = nil,
					Callback = function() end,
				}, opts)
				local row, title = Row(opts.Name)
				title.Size = UDim2.new(0.42, 0, 1, 0)
				local chip = New("TextButton", {
					AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(132, 26),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.25,
					Font = Enum.Font.Gotham,
					TextSize = 12,
					TextColor3 = Theme.Text,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(chip, 8)
				Stroke(chip, 0.8)

				local popup = New("Frame", {
					Visible = false,
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.12,
					Size = UDim2.fromOffset(SIZE.Popup, 8),
					ZIndex = Z.Dropdown,
					Parent = Screen,
				})
				Corner(popup, 12)
				Stroke(popup, 0.72)
				local popList = New("UIListLayout", { Padding = UDim.new(0, 2), Parent = popup })
				Pad(popup, 6, 6, 6, 6)

				local selected = opts.Multi and {} or (opts.Default or opts.Values[1])
				if opts.Multi and opts.Default then
					if type(opts.Default) == "table" then
						for _, v in ipairs(opts.Default) do
							selected[v] = true
						end
					else
						selected[opts.Default] = true
					end
				end

				local lib = {}
				local function Label()
					if opts.Multi then
						local n = 0
						for _ in pairs(selected) do
							n = n + 1
						end
						chip.Text = n == 0 and "None" or (n .. " selected")
					else
						chip.Text = tostring(selected)
					end
				end
				Label()

				local function Rebuild()
					for _, ch in ipairs(popup:GetChildren()) do
						if ch:IsA("TextButton") then
							ch:Destroy()
						end
					end
					for _, value in ipairs(opts.Values) do
						local item = New("TextButton", {
							AutoButtonColor = false,
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 26),
							Font = Enum.Font.Gotham,
							TextSize = 12,
							TextColor3 = Theme.Text,
							Text = tostring(value),
							ZIndex = Z.Dropdown + 1,
							Parent = popup,
						})
						item.MouseButton1Click:Connect(function()
							if opts.Multi then
								selected[value] = not selected[value]
								if not selected[value] then
									selected[value] = nil
								end
								Label()
								opts.Callback(selected)
							else
								selected = value
								Label()
								popup.Visible = false
								opts.Callback(selected)
							end
						end)
					end
					popup.Size = UDim2.fromOffset(SIZE.Popup, popList.AbsoluteContentSize.Y + 16)
				end
				Rebuild()

				chip.MouseButton1Click:Connect(function()
					Rebuild()
					local pos = chip.AbsolutePosition
					local sz = chip.AbsoluteSize
					popup.Position = UDim2.fromOffset(pos.X + sz.X - SIZE.Popup, pos.Y + sz.Y + 6)
					popup.Visible = not popup.Visible
				end)

				function lib:GetValue()
					return selected
				end
				function lib:SetValue(v)
					selected = v
					Label()
					opts.Callback(selected)
				end
				function lib:Refresh(values)
					opts.Values = values
					Rebuild()
				end
				if opts.Flag then
					FluidGlass.Flags[opts.Flag] = lib
				end
				return lib
			end

			function Section:AddKeybind(opts)
				opts = Merge({
					Name = "Keybind",
					Default = Enum.KeyCode.E,
					Flag = nil,
					Callback = function() end,
				}, opts)
				local row, title = Row(opts.Name)
				title.Size = UDim2.new(1, -110, 1, 0)
				local chip = New("TextButton", {
					AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(86, 26),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.25,
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					TextColor3 = Theme.Text,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(chip, 8)
				Stroke(chip, 0.8)
				local lib = { Value = opts.Default, Listening = false }
				local function NameOf(k)
					if typeof(k) == "EnumItem" then
						return k.Name
					end
					return tostring(k)
				end
				chip.Text = NameOf(lib.Value)
				chip.MouseButton1Click:Connect(function()
					lib.Listening = true
					chip.Text = "..."
				end)
				UserInputService.InputBegan:Connect(function(input, gp)
					if lib.Listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							lib.Value = input.KeyCode
							lib.Listening = false
							chip.Text = NameOf(lib.Value)
							opts.Callback(lib.Value)
						end
					elseif not gp and input.KeyCode == lib.Value then
						opts.Callback(lib.Value, true)
					end
				end)
				function lib:GetValue()
					return typeof(lib.Value) == "EnumItem" and lib.Value.Name or lib.Value
				end
				function lib:SetValue(v)
					if type(v) == "string" then
						pcall(function()
							lib.Value = Enum.KeyCode[v]
						end)
					else
						lib.Value = v
					end
					chip.Text = NameOf(lib.Value)
				end
				if opts.Flag then
					FluidGlass.Flags[opts.Flag] = lib
				end
				return lib
			end

			function Section:AddColorPicker(opts)
				opts = Merge({
					Name = "Color",
					Default = Theme.Accent,
					Flag = nil,
					Callback = function() end,
				}, opts)
				local row, title = Row(opts.Name)
				title.Size = UDim2.new(1, -52, 1, 0)
				local swatch = New("TextButton", {
					AutoButtonColor = false,
					Text = "",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.fromOffset(28, 20),
					BackgroundColor3 = opts.Default,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(swatch, 6)
				Stroke(swatch, 0.7)

				local picker = New("Frame", {
					Visible = false,
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.1,
					Size = UDim2.fromOffset(SIZE.Color.X, SIZE.Color.Y),
					ZIndex = Z.ColorPicker,
					Parent = Screen,
				})
				Corner(picker, 14)
				Stroke(picker, 0.7)
				GlassGradient(picker)

				local sv = New("ImageButton", {
					AutoButtonColor = false,
					Position = UDim2.fromOffset(12, 12),
					Size = UDim2.fromOffset(190, 160),
					BackgroundColor3 = Color3.fromHSV(0, 1, 1),
					ZIndex = Z.ColorPicker + 1,
					Parent = picker,
				})
				Corner(sv, 8)
				local white = New("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					Size = UDim2.fromScale(1, 1),
					ZIndex = Z.ColorPicker + 2,
					Parent = sv,
				})
				Corner(white, 8)
				local wg = Instance.new("UIGradient")
				wg.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				})
				wg.Parent = white
				local black = New("Frame", {
					BackgroundColor3 = Color3.new(0, 0, 0),
					Size = UDim2.fromScale(1, 1),
					ZIndex = Z.ColorPicker + 3,
					Parent = sv,
				})
				Corner(black, 8)
				local bg = Instance.new("UIGradient")
				bg.Rotation = 90
				bg.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				})
				bg.Parent = black

				local hueBar = New("Frame", {
					Position = UDim2.fromOffset(12, 180),
					Size = UDim2.fromOffset(190, 12),
					BackgroundColor3 = Color3.new(1, 1, 1),
					ZIndex = Z.ColorPicker + 1,
					Parent = picker,
				})
				Corner(hueBar, 4)
				local hg = Instance.new("UIGradient")
				hg.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
				})
				hg.Parent = hueBar

				local hex = New("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 204),
					Size = UDim2.new(1, -24, 0, 28),
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = Z.ColorPicker + 1,
					Parent = picker,
				})

				local h, s, v = opts.Default:ToHSV()
				local lib = { Value = opts.Default }
				local function Apply()
					lib.Value = Color3.fromHSV(h, s, v)
					sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					swatch.BackgroundColor3 = lib.Value
					hex.Text = "#" .. lib.Value:ToHex()
					opts.Callback(lib.Value)
				end
				Apply()

				local function SampleSV()
					local p = sv.AbsolutePosition
					local z = sv.AbsoluteSize
					s = math.clamp((Mouse.X - p.X) / math.max(z.X, 1), 0, 1)
					v = 1 - math.clamp((Mouse.Y - p.Y) / math.max(z.Y, 1), 0, 1)
					Apply()
				end
				local function SampleHue()
					local p = hueBar.AbsolutePosition
					local z = hueBar.AbsoluteSize
					h = math.clamp((Mouse.X - p.X) / math.max(z.X, 1), 0, 1)
					Apply()
				end
				sv.MouseButton1Down:Connect(function()
					local conn
					SampleSV()
					conn = RunService.RenderStepped:Connect(function()
						if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
							SampleSV()
						else
							conn:Disconnect()
						end
					end)
				end)
				hueBar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local conn
						SampleHue()
						conn = RunService.RenderStepped:Connect(function()
							if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
								SampleHue()
							else
								conn:Disconnect()
							end
						end)
					end
				end)

				swatch.MouseButton1Click:Connect(function()
					local pos = swatch.AbsolutePosition
					picker.Position = UDim2.fromOffset(pos.X - SIZE.Color.X + 28, pos.Y + 28)
					picker.Visible = not picker.Visible
				end)

				function lib:GetValue()
					return lib.Value:ToHex()
				end
				function lib:SetValue(c)
					if type(c) == "string" then
						c = Color3.fromHex((c:gsub("#", "")))
					end
					h, s, v = c:ToHSV()
					Apply()
				end
				if opts.Flag then
					FluidGlass.Flags[opts.Flag] = lib
				end
				return lib
			end

			function Section:AddTextInput(opts)
				opts = Merge({
					Name = "Input",
					Default = "",
					Placeholder = "",
					Flag = nil,
					Callback = function() end,
				}, opts)
				local row, title = Row(opts.Name)
				title.Size = UDim2.new(0.4, 0, 1, 0)
				local box = New("TextBox", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(128, 26),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.25,
					Font = Enum.Font.Gotham,
					TextSize = 12,
					TextColor3 = Theme.Text,
					PlaceholderText = opts.Placeholder,
					PlaceholderColor3 = Theme.Faint,
					Text = opts.Default,
					ClearTextOnFocus = false,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(box, 8)
				Stroke(box, 0.8)
				Pad(box, 0, 8, 0, 8)
				local lib = { Value = opts.Default }
				box.FocusLost:Connect(function()
					lib.Value = box.Text
					opts.Callback(lib.Value)
				end)
				function lib:GetValue()
					return lib.Value
				end
				function lib:SetValue(v)
					lib.Value = tostring(v)
					box.Text = lib.Value
					opts.Callback(lib.Value)
				end
				if opts.Flag then
					FluidGlass.Flags[opts.Flag] = lib
				end
				return lib
			end

			function Section:AddButton(opts)
				opts = Merge({
					Name = "Button",
					Icon = "chevron-right",
					Callback = function() end,
					Dialog = nil,
				}, opts)
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 42),
					ZIndex = Z.Row + 1,
					Parent = body,
				})
				table.insert(Registry, { Name = opts.Name, Root = row })
				local btn = New("TextButton", {
					AutoButtonColor = false,
					Position = UDim2.fromOffset(10, 6),
					Size = UDim2.new(1, -20, 0, 30),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.2,
					Text = "",
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(btn, 10)
				Stroke(btn, 0.78)
				local ic = New("ImageLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 6),
					Size = UDim2.fromOffset(18, 18),
					ZIndex = Z.Control + 1,
					Parent = btn,
				})
				FluidGlass:SetIcon(ic, opts.Icon, Theme.Accent)
				New("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(34, 0),
					Size = UDim2.new(1, -42, 1, 0),
					Font = Enum.Font.GothamMedium,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Theme.Text,
					Text = opts.Name,
					ZIndex = Z.Control + 1,
					Parent = btn,
				})
				btn.MouseButton1Click:Connect(function()
					if opts.Dialog then
						OpenDialog({
							Title = opts.Dialog.Title or opts.Name,
							Content = opts.Dialog.Content or "Confirm this action.",
							Confirm = opts.Dialog.Confirm or "Confirm",
							Cancel = opts.Dialog.Cancel or "Cancel",
							Callback = function(ok)
								if ok then
									opts.Callback()
								end
							end,
						})
					else
						opts.Callback()
					end
				end)
				return btn
			end

			return Section
		end

		function tab:AddSection(sec)
			return MakeSection(sec)
		end

		table.insert(Window.Tabs, tab)
		if #Window.Tabs == 1 then
			SelectTab(1)
		end
		return tab
	end

	-- Config: save / load / delete / export / import
	local function Collect()
		local data = {}
		for flag, obj in pairs(FluidGlass.Flags) do
			if obj and obj.GetValue then
				data[flag] = obj:GetValue()
			end
		end
		return data
	end

	local function ApplyFlags(data)
		if type(data) ~= "table" then
			return
		end
		for flag, value in pairs(data) do
			local obj = FluidGlass.Flags[flag]
			if obj and obj.SetValue then
				pcall(obj.SetValue, obj, value)
			end
		end
	end

	local function Encode(tbl)
		return HttpService:Base64Encode(HttpService:JSONEncode({
			v = 2,
			lib = "FluidGlass",
			flags = tbl,
		}))
	end

	local function Decode(str)
		str = tostring(str or ""):gsub("%s+", "")
		local ok, json = pcall(function()
			return HttpService:JSONDecode(HttpService:Base64Decode(str))
		end)
		if ok and type(json) == "table" then
			return json.flags or json
		end
		local ok2, raw = pcall(HttpService.JSONDecode, HttpService, str)
		if ok2 and type(raw) == "table" then
			return raw.flags or raw
		end
		return nil
	end

	function Window:SaveConfig(name)
		name = name ~= "" and name or "Default"
		if not HasFS() then
			FluidGlass:Notify({ Title = "Config", Content = "Filesystem unavailable", Icon = "folder" })
			return
		end
		writefile(config.ConfigFolder .. "/" .. name .. ".fg", Encode(Collect()))
		FluidGlass:Notify({ Title = "Saved", Content = name, Icon = "check" })
	end

	function Window:LoadConfig(name)
		name = name ~= "" and name or "Default"
		local path = config.ConfigFolder .. "/" .. name .. ".fg"
		if not HasFS() or not isfile(path) then
			FluidGlass:Notify({ Title = "Config", Content = "Not found: " .. name, Icon = "x" })
			return
		end
		ApplyFlags(Decode(readfile(path)))
		FluidGlass:Notify({ Title = "Loaded", Content = name, Icon = "folder" })
	end

	function Window:DeleteConfig(name)
		local path = config.ConfigFolder .. "/" .. name .. ".fg"
		if HasFS() and isfile(path) then
			delfile(path)
			FluidGlass:Notify({ Title = "Deleted", Content = name, Icon = "trash-2" })
		end
	end

	function Window:ExportConfig()
		local payload = Encode(Collect())
		if setclipboard then
			setclipboard(payload)
			FluidGlass:Notify({ Title = "Exported", Content = "Config copied to clipboard", Icon = "upload" })
		else
			FluidGlass:Notify({ Title = "Export", Content = payload:sub(1, 48) .. "...", Icon = "upload" })
		end
		return payload
	end

	function Window:ImportConfig(payload)
		if not payload or payload == "" then
			if getclipboard then
				payload = getclipboard()
			end
		end
		local flags = Decode(payload)
		if not flags then
			FluidGlass:Notify({ Title = "Import failed", Content = "Invalid payload", Icon = "x" })
			return
		end
		ApplyFlags(flags)
		FluidGlass:Notify({ Title = "Imported", Content = "Flags applied", Icon = "download" })
	end

	function Window:AddLibrarySettings()
		self:AddTabLabel("System")
		local tab = self:AddTab({ Name = "Settings", Icon = "settings" })
		local ui = tab:AddSection({ Name = "Interface", Side = "Left" })
		local look = tab:AddSection({ Name = "Appearance", Side = "Right" })
		local cfg = tab:AddSection({ Name = "Configs", Side = "Right" })

		ui:AddKeybind({
			Name = "Menu Key",
			Flag = "fg.menuKey",
			Default = Window.Keybind,
			Callback = function(k)
				Window.Keybind = k
			end,
		})
		ui:AddToggle({
			Name = "Menu Blur",
			Flag = "fg.blur",
			Default = true,
			Callback = function(v)
				config.Blur = v
				SetBlur(Window.Visible and v)
			end,
		})
		ui:AddSlider({
			Name = "Opacity",
			Flag = "fg.opacity",
			Min = 20,
			Max = 80,
			Default = 38,
			Suffix = "%",
			Callback = function(v)
				Theme.FillTransparency = v / 100
				if Window.Visible then
					Root.BackgroundTransparency = Theme.FillTransparency
				end
			end,
		})
		look:AddColorPicker({
			Name = "Accent",
			Flag = "fg.accent",
			Default = Theme.Accent,
			Callback = function(c)
				Theme.Accent = c
			end,
		})
		look:AddButton({
			Name = "Reset Position",
			Icon = "rotate-ccw",
			Callback = function()
				Tween(Root, TWEEN.Pop, { Position = UDim2.fromScale(0.5, 0.5) })
			end,
		})

		local nameBox = cfg:AddTextInput({
			Name = "Config Name",
			Flag = "fg.cfgName",
			Default = "Default",
			Placeholder = "Default",
		})
		cfg:AddButton({
			Name = "Save Config",
			Icon = "save",
			Callback = function()
				Window:SaveConfig(nameBox:GetValue())
			end,
		})
		cfg:AddButton({
			Name = "Load Config",
			Icon = "folder",
			Callback = function()
				Window:LoadConfig(nameBox:GetValue())
			end,
		})
		cfg:AddButton({
			Name = "Export Config",
			Icon = "upload",
			Callback = function()
				Window:ExportConfig()
			end,
		})
		cfg:AddButton({
			Name = "Import Config",
			Icon = "download",
			Dialog = {
				Title = "Import config?",
				Content = "Clipboard payload will overwrite current flags.",
				Confirm = "Import",
			},
			Callback = function()
				Window:ImportConfig()
			end,
		})
		cfg:AddButton({
			Name = "Delete Config",
			Icon = "trash-2",
			Dialog = {
				Title = "Delete config?",
				Content = "This file will be removed from disk.",
				Confirm = "Delete",
			},
			Callback = function()
				Window:DeleteConfig(nameBox:GetValue())
			end,
		})
		return tab
	end

	table.insert(self.Windows, Window)
	return Window
end

function FluidGlass:Unload()
	pcall(function()
		BlurEffect:Destroy()
	end)
	Screen:Destroy()
end

return FluidGlass
