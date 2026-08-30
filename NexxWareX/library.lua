local NexxWareX = {
	Version = "1.0 Alpha",
	Flags = {},
	Windows = {},
	Signals = {},
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
	local ok, hui = pcall(function() return gethui() end)
	if ok and hui then return hui end
	local ok2, core = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and core then return core end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function HttpGet(url)
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and type(body) == "string" and #body > 10 then return body end
	local req = (syn and syn.request) or (http and http.request) or http_request or request
	if req then
		local success, response = pcall(req, { Url = url, Method = "GET" })
		if success and response then return response.Body or response.body end
	end
	return nil
end

local function HasFS()
	return typeof(writefile) == "function" and typeof(readfile) == "function"
end

local Z = {
	Window = 10, Sidebar = 20, Header = 26, Content = 16, Row = 22, Control = 30,
	Popup = 50, Dropdown = 56, ColorPicker = 62, DialogDim = 80, Dialog = 86,
	Tooltip = 92, Notify = 96, Watermark = 40,
}

local SIZE = {
	Window = Vector2.new(800, 540),
	Mobile = Vector2.new(420, 560),
	Sidebar = 200,
	Header = 58,
	Footer = 52,
	Row = 44,
	Toggle = Vector2.new(44, 24),
	Slider = 148,
	Popup = 228,
	Dialog = Vector2.new(360, 188),
	Color = Vector2.new(214, 252),
	Notify = Vector2.new(280, 68),
}

local TWEEN = {
	Fluid = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Snap = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Pop = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	In = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
}

local Theme = {
	Name = "LiquidGlass",
	Accent = Color3.fromRGB(170, 220, 255),
	Text = Color3.fromRGB(245, 250, 255),
	Muted = Color3.fromRGB(190, 210, 230),
	Faint = Color3.fromRGB(150, 175, 200),
	Glass = Color3.fromRGB(255, 255, 255),
	GlassTop = Color3.fromRGB(255, 255, 255),
	GlassTint = Color3.fromRGB(180, 210, 240),
	Stroke = Color3.fromRGB(255, 255, 255),
	Danger = Color3.fromRGB(255, 140, 150),
	Warn = Color3.fromRGB(255, 200, 130),
	Success = Color3.fromRGB(140, 235, 190),
	Track = Color3.fromRGB(255, 255, 255),
	FillTransparency = 0.88,
	PanelTransparency = 0.92,
	StrokeTransparency = 0.72,
	SidebarTransparency = 0.90,
	RowTransparency = 0.94,
	ControlTransparency = 0.85,
}

NexxWareX.Theme = Theme
NexxWareX.Z = Z
NexxWareX.SIZE = SIZE

local function Track(signal)
	table.insert(NexxWareX.Signals, signal)
	return signal
end

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
	s.Color = color or Color3.fromRGB(255, 255, 255)
	s.Transparency = transparency or Theme.StrokeTransparency
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function GlassGradient(parent)
	local g = Instance.new("UIGradient")
	g.Rotation = 105
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(220, 235, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 190, 230)),
	})
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 0.7),
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
	Track(btn.MouseButton1Click:Connect(callback))
	return btn
end

local function Drag(handle, target)
	local dragging, start, origin
	Track(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			start = input.Position
			origin = target.Position
			Track(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end))
		end
	end))
	Track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - start
			Tween(target, TWEEN.Snap, {
				Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y),
			})
		end
	end))
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
		if out[k] == nil then out[k] = v end
	end
	for k, v in pairs(given) do
		if out[k] == nil then out[k] = v end
	end
	return out
end

local IconPacks = { lucide = {}, gravity = {} }
local IconsReady = false
local ICON_URL = {
	lucide = "https://raw.githubusercontent.com/Nail120212/NexLib/main/Icons/lucide.lua",
	gravity = "https://raw.githubusercontent.com/Nail120212/NexLib/main/Icons/gravity.lua",
}

local function LoadPack(name, url)
	local src = HttpGet(url)
	if not src then return end
	local fn = loadstring(src)
	if not fn then return end
	local ok, tbl = pcall(fn)
	if ok and type(tbl) == "table" then IconPacks[name] = tbl end
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

function NexxWareX:ResolveIcon(spec)
	if spec == nil or spec == "" then return nil, "lucide" end
	spec = tostring(spec)
	if spec:find("rbxasset", 1, true) then return spec, "asset" end
	local pack, name = spec:match("^([%w]+):(.+)$")
	if pack then
		pack = string.lower(pack)
		name = NormalizeIconName(name)
	else
		pack = "lucide"
		name = NormalizeIconName(spec)
	end
	if pack == "lucide" or pack == "lucid" then pack = "lucide" end
	local map = IconPacks[pack]
	if map and map[name] then return map[name], pack end
	if IconPacks.lucide[name] then return IconPacks.lucide[name], "lucide" end
	return nil, pack
end

function NexxWareX:SetIcon(imageLabel, spec, color)
	if not imageLabel then return end
	local function apply()
		local asset = self:ResolveIcon(spec)
		if asset then
			imageLabel.Image = asset
			imageLabel.ImageColor3 = color or Theme.Text
			imageLabel.ImageTransparency = 0
			imageLabel.ScaleType = Enum.ScaleType.Fit
		end
	end
	if IconsReady then apply() else
		task.spawn(function()
			for _ = 1, 40 do
				if IconsReady then break end
				task.wait(0.05)
			end
			apply()
		end)
	end
end

local existing = GuiParent():FindFirstChild("NexxWareXUI")
if existing then existing:Destroy() end

local Screen = New("ScreenGui", {
	Name = "NexxWareXUI",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 999999,
	Parent = GuiParent(),
})
NexxWareX.Screen = Screen

local BlurEffect = Instance.new("BlurEffect")
BlurEffect.Name = "NexxWareXBlur"
BlurEffect.Size = 0
BlurEffect.Parent = Lighting

local AcrylicFX = Instance.new("DepthOfFieldEffect")
AcrylicFX.Name = "NexxWareXAcrylic"
AcrylicFX.Enabled = false
AcrylicFX.FarIntensity = 0.35
AcrylicFX.NearIntensity = 0.55
AcrylicFX.FocusDistance = 0.05
AcrylicFX.InFocusRadius = 0.1
AcrylicFX.Parent = Lighting

local TooltipFrame = New("Frame", {
	Visible = false,
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.78,
	Size = UDim2.fromOffset(10, 28),
	ZIndex = Z.Tooltip,
	Parent = Screen,
})
Corner(TooltipFrame, 8)
Stroke(TooltipFrame, 0.72)
local TooltipLabel = New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = Theme.Text,
	ZIndex = Z.Tooltip + 1,
	Parent = TooltipFrame,
})
Pad(TooltipLabel, 0, 10, 0, 10)

local function BindTooltip(target, text)
	if not text or text == "" then return end
	Track(target.MouseEnter:Connect(function()
		TooltipLabel.Text = text
		local bounds = TooltipLabel.TextBounds
		TooltipFrame.Size = UDim2.fromOffset(math.max(bounds.X + 20, 40), 28)
		TooltipFrame.Position = UDim2.fromOffset(Mouse.X + 14, Mouse.Y + 18)
		TooltipFrame.Visible = true
	end))
	Track(target.MouseMoved:Connect(function()
		if TooltipFrame.Visible then
			TooltipFrame.Position = UDim2.fromOffset(Mouse.X + 14, Mouse.Y + 18)
		end
	end))
	Track(target.MouseLeave:Connect(function()
		TooltipFrame.Visible = false
	end))
end

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
		BackgroundTransparency = 0.82,
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
		BackgroundTransparency = 0.35,
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
			if not pending then dim.Visible = false end
		end)
		local cb = pending
		pending = nil
		if cb then cb(result) end
	end
	Track(confirmBtn.MouseButton1Click:Connect(function() Close(true) end))
	Track(cancelBtn.MouseButton1Click:Connect(function() Close(false) end))
	Track(dim.MouseButton1Click:Connect(function() Close(false) end))
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
		card.Position = UDim2.fromScale(0.5, 0.54)
		Tween(dim, TWEEN.Fluid, { BackgroundTransparency = 0.55 })
		Tween(card, TWEEN.Pop, { BackgroundTransparency = Theme.FillTransparency, Position = UDim2.fromScale(0.5, 0.5) })
		Tween(cardStroke, TWEEN.Fluid, { Transparency = 0.72 })
		Tween(title, TWEEN.Fluid, { TextTransparency = 0 })
		Tween(body, TWEEN.Fluid, { TextTransparency = 0.12 })
	end
end

local OpenDialog = CreateDialogHost()
NexxWareX.Dialog = OpenDialog

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

NexxWareX.__NotifyCards = NexxWareX.__NotifyCards or {}
NexxWareX.NotifyLimit = 5

function NexxWareX:Notify(opts)
	opts = Merge({
		Title = "NexxWareX",
		Content = "",
		Duration = 3.4,
		Icon = "bell",
		Type = "Info",
	}, opts)
	while #NexxWareX.__NotifyCards >= (NexxWareX.NotifyLimit or 5) do
		local old = table.remove(NexxWareX.__NotifyCards, 1)
		if old and old.Parent then old:Destroy() end
	end
	local accent = Theme.Accent
	local t = string.lower(opts.Type or "info")
	if t == "success" then accent = Theme.Success; opts.Icon = opts.Icon or "check"
	elseif t == "warn" or t == "warning" then accent = Theme.Warn; opts.Icon = opts.Icon or "triangle-alert"
	elseif t == "error" or t == "danger" then accent = Theme.Danger; opts.Icon = opts.Icon or "x"
	end
	local card = New("Frame", {
		Size = UDim2.fromOffset(SIZE.Notify.X, SIZE.Notify.Y),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.82,
		ZIndex = Z.Notify,
		Parent = NotifyHolder,
	})
	Corner(card, 14)
	Stroke(card, 0.7)
	GlassGradient(card)
	local bar = New("Frame", {
		BackgroundColor3 = accent,
		Size = UDim2.new(0, 3, 1, -12),
		Position = UDim2.fromOffset(6, 6),
		ZIndex = Z.Notify + 1,
		Parent = card,
	})
	Corner(bar, 2)
	local icon = New("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 18),
		Size = UDim2.fromOffset(26, 26),
		ZIndex = Z.Notify + 1,
		Parent = card,
	})
	self:SetIcon(icon, opts.Icon, accent)
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(52, 12),
		Size = UDim2.new(1, -64, 0, 18),
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
		Position = UDim2.fromOffset(52, 32),
		Size = UDim2.new(1, -64, 0, 22),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Muted,
		Text = opts.Content,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = Z.Notify + 1,
		Parent = card,
	})
	local progress = New("Frame", {
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.35,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = Z.Notify + 2,
		Parent = card,
	})
	Tween(progress, TweenInfo.new(opts.Duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
	table.insert(NexxWareX.__NotifyCards, card)
	task.delay(opts.Duration, function()
		for i, c in ipairs(NexxWareX.__NotifyCards) do
			if c == card then table.remove(NexxWareX.__NotifyCards, i) break end
		end
		if card and card.Parent then
			Tween(card, TWEEN.In, { BackgroundTransparency = 1 })
			task.wait(0.12)
			card:Destroy()
		end
	end)
	return card
end

function NexxWareX:CreateWindow(config)
	config = Merge({
		Title = "NexxWareX",
		Subtitle = "Liquid Glass",
		Icon = "layers",
		Size = UDim2.fromOffset(SIZE.Window.X, SIZE.Window.Y),
		Keybind = Enum.KeyCode.RightShift,
		ConfigFolder = "NexxWareX",
		Blur = true,
		Acrylic = true,
		Mobile = true,
		AutoLoad = "Default",
	}, config)

	local Window = {
		Tabs = {},
		Current = 1,
		Visible = true,
		Keybind = config.Keybind,
		ConfigFolder = config.ConfigFolder,
		Flags = NexxWareX.Flags,
		Tags = {},
	}

	if HasFS() and not isfolder(config.ConfigFolder) then
		pcall(makefolder, config.ConfigFolder)
	end

	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if config.Mobile and isMobile then
		config.Size = UDim2.fromOffset(SIZE.Mobile.X, SIZE.Mobile.Y)
	end
	local sidebarW = (config.Mobile and isMobile) and 72 or SIZE.Sidebar

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
	Stroke(Root, 0.65, Color3.fromRGB(255, 255, 255), 1.25)
	GlassGradient(Root)
	Window.Root = Root
	NexxWareX.MainWindow = Root

	local specular = New("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.55,
		Size = UDim2.new(1, 0, 0, 90),
		ZIndex = Z.Window + 1,
		Parent = Root,
	})
	local specGrad = Instance.new("UIGradient")
	specGrad.Rotation = 90
	specGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.55, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	specGrad.Parent = specular
	Corner(specular, 20)

	local Sidebar = New("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Glass,
		BackgroundTransparency = Theme.SidebarTransparency or 0.90,
		Size = UDim2.new(0, sidebarW, 1, 0),
		ZIndex = Z.Sidebar,
		Parent = Root,
	})
	Corner(Sidebar, 20)
	New("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.85,
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
	local titleLabel = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(sidebarW > 100 and 48 or 0, 12),
		Size = UDim2.new(1, sidebarW > 100 and -58 or 0, 0, 18),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
		Text = sidebarW > 100 and config.Title or "",
		ZIndex = Z.Sidebar + 3,
		Parent = Brand,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(sidebarW > 100 and 48 or 0, 30),
		Size = UDim2.new(1, -58, 0, 16),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Faint,
		Text = sidebarW > 100 and config.Subtitle or "",
		ZIndex = Z.Sidebar + 3,
		Parent = Brand,
	})

	local TagHolder = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(sidebarW > 100 and 48 or 8, 0),
		Size = UDim2.new(1, -56, 0, 18),
		ZIndex = Z.Sidebar + 4,
		Parent = Brand,
	})
	local tagLayout = New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = TagHolder,
	})

	function Window:Tag(opts)
		opts = Merge({
			Title = "Tag",
			Icon = nil,
			Color = Color3.fromHex("#315dff"),
			Radius = 13,
		}, opts)
		local chip = New("Frame", {
			BackgroundColor3 = opts.Color,
			BackgroundTransparency = 0.35,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = Z.Sidebar + 5,
			Parent = TagHolder,
		})
		Corner(chip, math.clamp(opts.Radius or 13, 0, 13))
		Pad(chip, 0, 8, 0, 8)
		local row = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = Z.Sidebar + 6,
			Parent = chip,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = row,
		})
		if opts.Icon then
			local ic = New("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(12, 12),
				ZIndex = Z.Sidebar + 7,
				Parent = row,
			})
			NexxWareX:SetIcon(ic, opts.Icon, Color3.new(1, 1, 1))
		end
		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = Color3.new(1, 1, 1),
			Text = opts.Title,
			ZIndex = Z.Sidebar + 7,
			Parent = row,
		})
		table.insert(Window.Tags, chip)
		return chip
	end

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
	Track(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabList.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 8)
	end))

	local Header = New("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(sidebarW, 0),
		Size = UDim2.new(1, -sidebarW, 0, SIZE.Header),
		ZIndex = Z.Header,
		Parent = Root,
	})
	Drag(Header, Root)
	Drag(Brand, Root)

	local SearchBox = New("TextBox", {
		BackgroundColor3 = Theme.Glass,
		BackgroundTransparency = 0.82,
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
		Position = UDim2.fromOffset(sidebarW, SIZE.Header),
		Size = UDim2.new(1, -sidebarW, 1, -SIZE.Header),
		ZIndex = Z.Content,
		ClipsDescendants = true,
		Parent = Root,
	})

	local Registry = {}
	Track(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(SearchBox.Text)
		for _, item in ipairs(Registry) do
			if q == "" then
				item.Root.Visible = true
			else
				local hit = string.find(string.lower(item.Name), q, 1, true) ~= nil
				if item.Section then
					hit = hit or string.find(string.lower(item.Section), q, 1, true) ~= nil
				end
				item.Root.Visible = hit
			end
		end
		for _, tab in ipairs(Window.Tabs) do
			if q == "" then
				tab.Button.Visible = true
				if tab.SubHolder then tab.SubHolder.Visible = (tab.SubCount or 0) > 0 end
			else
				local nameHit = string.find(string.lower(tab.Name), q, 1, true) ~= nil
				local childHit = false
				for _, item in ipairs(Registry) do
					if item.Tab == tab.Name and item.Root.Visible then childHit = true break end
				end
				tab.Button.Visible = nameHit or childHit
			end
		end
	end))

	local function SetBlur(on)
		if config.Blur and on then
			Tween(BlurEffect, TWEEN.Fluid, { Size = config.Acrylic and 28 or 18 })
			AcrylicFX.Enabled = config.Acrylic and true or false
		else
			Tween(BlurEffect, TWEEN.Fluid, { Size = 0 })
			AcrylicFX.Enabled = false
		end
	end
	SetBlur(true)

	function Window:Toggle(state)
		if state == nil then state = not Window.Visible end
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
				if not Window.Visible then Root.Visible = false end
			end)
		end
	end

	Track(Close.MouseButton1Click:Connect(function() Window:Toggle(false) end))
	Track(UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Window.Keybind then Window:Toggle() end
	end))

	local function SelectTab(index)
		Window.Current = index
		for i, tab in ipairs(Window.Tabs) do
			local on = i == index
			tab.Page.Visible = on
			Tween(tab.Button, TWEEN.Fluid, { BackgroundTransparency = on and 0.82 or 1 })
			Tween(tab.Label, TWEEN.Fluid, { TextColor3 = on and Theme.Text or Theme.Muted })
			if tab.IconImg then
				Tween(tab.IconImg, TWEEN.Fluid, { ImageColor3 = on and Theme.Accent or Theme.Faint })
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
		tabConfig = Merge({ Name = "Tab", Icon = "circle", Parent = nil }, tabConfig)
		local tab = { Name = tabConfig.Name, SubTabs = {} }
		local parentList = TabList
		local indent = 0
		if tabConfig.Parent then
			parentList = tabConfig.Parent.SubHolder or TabList
			indent = 8
			tabConfig.Parent.SubCount = (tabConfig.Parent.SubCount or 0) + 1
			if tabConfig.Parent.SubHolder then
				tabConfig.Parent.SubHolder.Visible = true
				tabConfig.Parent.SubHolder.Size = UDim2.new(1, -4, 0, tabConfig.Parent.SubCount * 36 + 4)
			end
		end

		local btn = New("Frame", {
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6 - indent, 0, indent > 0 and 34 or 40),
			ZIndex = Z.Sidebar + 3,
			Parent = parentList,
		})
		Corner(btn, 12)
		local icon = New("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, indent > 0 and 7 or 10),
			Size = UDim2.fromOffset(indent > 0 and 18 or 20, indent > 0 and 18 or 20),
			ZIndex = Z.Sidebar + 4,
			Parent = btn,
		})
		NexxWareX:SetIcon(icon, tabConfig.Icon, Theme.Faint)
		local label = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(indent > 0 and 34 or 38, 0),
			Size = UDim2.new(1, -44, 1, 0),
			Font = Enum.Font.GothamMedium,
			TextSize = indent > 0 and 12 or 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Muted,
			Text = tabConfig.Name,
			ZIndex = Z.Sidebar + 4,
			Parent = btn,
		})
		Click(btn, function()
			for i, t in ipairs(Window.Tabs) do
				if t == tab then SelectTab(i) end
			end
		end)

		local SubHolder = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 0),
			Visible = false,
			ClipsDescendants = true,
			ZIndex = Z.Sidebar + 2,
			Parent = TabList,
		})
		New("UIListLayout", { Padding = UDim.new(0, 4), Parent = SubHolder })
		tab.SubHolder = SubHolder
		tab.SubCount = 0

		local page = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			ZIndex = Z.Content,
			Parent = Content,
		})
		local singleCol = config.Mobile and isMobile
		local left = New("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 8),
			Size = singleCol and UDim2.new(1, -28, 1, -16) or UDim2.new(0.5, -18, 1, -16),
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 2,
			BorderSizePixel = 0,
			ZIndex = Z.Content + 1,
			Parent = page,
		})
		local right = left
		if not singleCol then
			right = New("ScrollingFrame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 4, 0, 8),
				Size = UDim2.new(0.5, -18, 1, -16),
				CanvasSize = UDim2.new(),
				ScrollBarThickness = 2,
				BorderSizePixel = 0,
				ZIndex = Z.Content + 1,
				Parent = page,
			})
		end
		local lLay = New("UIListLayout", { Padding = UDim.new(0, 10), Parent = left })
		Track(lLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			left.CanvasSize = UDim2.fromOffset(0, lLay.AbsoluteContentSize.Y + 12)
		end))
		if right ~= left then
			local rLay = New("UIListLayout", { Padding = UDim.new(0, 10), Parent = right })
			Track(rLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				right.CanvasSize = UDim2.fromOffset(0, rLay.AbsoluteContentSize.Y + 12)
			end))
		end

		tab.Button = btn
		tab.Label = label
		tab.IconImg = icon
		tab.Page = page

		local function MakeSection(secConfig)
			secConfig = Merge({ Name = "Section", Side = "Left" }, secConfig)
			local parent = (string.lower(secConfig.Side) == "right" and not singleCol) and right or left
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
			Track(list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				local h = math.max(list.AbsoluteContentSize.Y, 8)
				body.Size = UDim2.new(1, 0, 0, h)
				wrap.Size = UDim2.new(1, 0, 0, h + 24)
			end))

			local Section = {}

			local function Row(name)
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, SIZE.Row),
					ZIndex = Z.Row + 1,
					Parent = body,
				})
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
				local lockOverlay = New("Frame", {
					Name = "Lock",
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Visible = false,
					ZIndex = Z.Control + 20,
					Parent = row,
				})
				local entry = { Name = name, Root = row, Title = title, Section = secConfig.Name, Tab = tab.Name, Locked = false }
				table.insert(Registry, entry)
				local api = {}
				function api:Lock(msg)
					entry.Locked = true
					lockOverlay.Visible = true
					lockOverlay.BackgroundTransparency = 0.55
					row.Active = false
				end
				function api:Unlock()
					entry.Locked = false
					lockOverlay.Visible = false
					row.Active = true
				end
				function api:SetTitle(t)
					title.Text = t
					entry.Name = t
				end
				function api:Destroy()
					for i, e in ipairs(Registry) do
						if e == entry then table.remove(Registry, i) break end
					end
					row:Destroy()
				end
				return row, title, api, entry
			end

			function Section:AddParagraph(opts)
				opts = Merge({ Name = "Note", Content = "", ToolTip = nil, Buttons = nil }, opts)
				local btnCount = opts.Buttons and #opts.Buttons or 0
				local h = 58 + (btnCount > 0 and 34 or 0)
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, h),
					ZIndex = Z.Row + 1,
					Parent = body,
				})
				local titleLbl = New("TextLabel", {
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
				local bodyLbl = New("TextLabel", {
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
				if btnCount > 0 then
					local holder = New("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(10, 52),
						Size = UDim2.new(1, -20, 0, 26),
						ZIndex = Z.Control,
						Parent = row,
					})
					local lay = New("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 6),
						Parent = holder,
					})
					for _, bcfg in ipairs(opts.Buttons) do
						local b = New("TextButton", {
							AutoButtonColor = false,
							BackgroundColor3 = Theme.Glass,
							BackgroundTransparency = 0.82,
							Size = UDim2.fromOffset(0, 26),
							AutomaticSize = Enum.AutomaticSize.X,
							Font = Enum.Font.GothamMedium,
							TextSize = 11,
							TextColor3 = Theme.Text,
							Text = "  " .. (bcfg.Title or bcfg.Name or "Action") .. "  ",
							ZIndex = Z.Control + 1,
							Parent = holder,
						})
						Corner(b, 8)
						Stroke(b, 0.8)
						Track(b.MouseButton1Click:Connect(function()
							if bcfg.Callback then bcfg.Callback() end
						end))
					end
				end
				local entry = { Name = opts.Name, Root = row, Section = secConfig.Name, Tab = tab.Name }
				table.insert(Registry, entry)
				if opts.ToolTip then BindTooltip(row, opts.ToolTip) end
				local lib = {}
				function lib:SetTitle(t) titleLbl.Text = t; entry.Name = t end
				function lib:SetDesc(d) bodyLbl.Text = d end
				function lib:Destroy()
					for i, e in ipairs(Registry) do if e == entry then table.remove(Registry, i) break end end
					row:Destroy()
				end
				function lib:Lock() row.Visible = true; for _, d in ipairs(row:GetDescendants()) do if d:IsA("GuiButton") then d.Active = false end end end
				function lib:Unlock() for _, d in ipairs(row:GetDescendants()) do if d:IsA("GuiButton") then d.Active = true end end end
				return lib
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
					Name = "Toggle", Default = false, Flag = nil, Callback = function() end, Dialog = nil, ToolTip = nil,
				}, opts)
				local row = Row(opts.Name)
				if opts.ToolTip then BindTooltip(row, opts.ToolTip) end
				local track = New("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.fromOffset(SIZE.Toggle.X, SIZE.Toggle.Y),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.78,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(track, 12)
				Stroke(track, 0.7)
				local knob = New("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 3, 0.5, 0),
					Size = UDim2.fromOffset(18, 18),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					ZIndex = Z.Control + 1,
					Parent = track,
				})
				Corner(knob, 9)
				local lib = { Value = opts.Default }
				local function Paint(v)
					Tween(track, TWEEN.Fluid, {
						BackgroundColor3 = v and Theme.Accent or Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = v and 0.25 or 0.78,
					})
					Tween(knob, TWEEN.Fluid, {
						Position = v and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
						BackgroundColor3 = Color3.new(1, 1, 1),
					})
				end
				Paint(lib.Value)
				local function Apply(v)
					lib.Value = v
					Paint(v)
					opts.Callback(v)
				end
				Click(track, function()
					if lib.__locked then return end
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
								Callback = function(ok) if ok then Apply(nextv) end end,
							})
							return
						end
					end
					Apply(nextv)
				end)
				function lib:GetValue() return lib.Value end
				function lib:SetValue(v) Apply(v and true or false) end
				function lib:SetTitle(t)
					local titleLbl = row:FindFirstChildWhichIsA("TextLabel")
					if titleLbl then titleLbl.Text = t end
				end
				function lib:Lock()
					lib.__locked = true
					for _, d in ipairs(row:GetDescendants()) do
						if d:IsA("GuiButton") then d.Active = false end
					end
					row.BackgroundTransparency = 0.9
				end
				function lib:Unlock()
					lib.__locked = false
					for _, d in ipairs(row:GetDescendants()) do
						if d:IsA("GuiButton") then d.Active = true end
					end
				end
				function lib:Destroy()
					if opts.Flag then NexxWareX.Flags[opts.Flag] = nil end
					row:Destroy()
				end
				if opts.Flag then NexxWareX.Flags[opts.Flag] = lib end
				return lib
			end

			function Section:AddSlider(opts)
				opts = Merge({
					Name = "Slider", Min = 0, Max = 100, Default = 50, Rounding = 0, Suffix = "", Flag = nil, Callback = function() end, ToolTip = nil,
				}, opts)
				local row, title = Row(opts.Name)
				if opts.ToolTip then BindTooltip(row, opts.ToolTip) end
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
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.8,
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
					if fire ~= false then opts.Callback(v) end
				end
				Set(opts.Default, false)
				local holding = false
				Track(bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						holding = true
					end
				end))
				Track(UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						holding = false
					end
				end))
				Track(RunService.RenderStepped:Connect(function()
					if holding then
						local x = math.clamp((Mouse.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
						Set(opts.Min + (opts.Max - opts.Min) * x)
					end
				end))
				function lib:GetValue() return lib.Value end
				function lib:SetValue(v) Set(tonumber(v) or lib.Value) end
				function lib:SetTitle(t) if title then title.Text = t end end
				function lib:Lock() lib.__locked = true; holding = false; for _, d in ipairs(row:GetDescendants()) do if d:IsA("GuiObject") then end end end
				function lib:Unlock() lib.__locked = false end
				function lib:Destroy() if opts.Flag then NexxWareX.Flags[opts.Flag] = nil end; row:Destroy() end
				if opts.Flag then NexxWareX.Flags[opts.Flag] = lib end
				return lib
			end

			function Section:AddDropdown(opts)
				opts = Merge({
					Name = "Dropdown", Values = { "One", "Two" }, Default = nil, Multi = false, Flag = nil, Callback = function() end, ToolTip = nil,
				}, opts)
				local row, title = Row(opts.Name)
				if opts.ToolTip then BindTooltip(row, opts.ToolTip) end
				title.Size = UDim2.new(0.42, 0, 1, 0)
				local chip = New("TextButton", {
					AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(132, 26),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.82,
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
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.78,
					Size = UDim2.fromOffset(SIZE.Popup, 8),
					ZIndex = Z.Dropdown,
					Parent = Screen,
				})
				Corner(popup, 12)
				Stroke(popup, 0.65)
				local popList = New("UIListLayout", { Padding = UDim.new(0, 2), Parent = popup })
				Pad(popup, 6, 6, 6, 6)
				local selected = opts.Multi and {} or (opts.Default or opts.Values[1])
				if opts.Multi and opts.Default then
					if type(opts.Default) == "table" then
						for _, v in ipairs(opts.Default) do selected[v] = true end
					else
						selected[opts.Default] = true
					end
				end
				local lib = {}
				local function Label()
					if opts.Multi then
						local n = 0
						for _ in pairs(selected) do n = n + 1 end
						chip.Text = n == 0 and "None" or (n .. " selected")
					else
						chip.Text = tostring(selected)
					end
				end
				Label()
				local function Rebuild()
					for _, ch in ipairs(popup:GetChildren()) do
						if ch:IsA("TextButton") then ch:Destroy() end
					end
					for _, value in ipairs(opts.Values) do
						local on = opts.Multi and selected[value] or selected == value
						local item = New("TextButton", {
							AutoButtonColor = false,
							BackgroundTransparency = on and 0.85 or 1,
							BackgroundColor3 = Theme.Accent,
							Size = UDim2.new(1, 0, 0, 26),
							Font = Enum.Font.Gotham,
							TextSize = 12,
							TextColor3 = Theme.Text,
							Text = (on and "✓ " or "  ") .. tostring(value),
							TextXAlignment = Enum.TextXAlignment.Left,
							ZIndex = Z.Dropdown + 1,
							Parent = popup,
						})
						Pad(item, 0, 8, 0, 8)
						Track(item.MouseButton1Click:Connect(function()
							if opts.Multi then
								selected[value] = not selected[value]
								if not selected[value] then selected[value] = nil end
								Label()
								Rebuild()
								opts.Callback(selected)
							else
								selected = value
								Label()
								popup.Visible = false
								opts.Callback(selected)
							end
						end))
					end
					popup.Size = UDim2.fromOffset(SIZE.Popup, popList.AbsoluteContentSize.Y + 16)
				end
				Rebuild()
				Track(chip.MouseButton1Click:Connect(function()
					Rebuild()
					local pos = chip.AbsolutePosition
					local sz = chip.AbsoluteSize
					popup.Position = UDim2.fromOffset(pos.X + sz.X - SIZE.Popup, pos.Y + sz.Y + 6)
					popup.Visible = not popup.Visible
				end))
				Track(UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and popup.Visible then
						local p = popup.AbsolutePosition
						local s = popup.AbsoluteSize
						local mx, my = Mouse.X, Mouse.Y
						if mx < p.X or mx > p.X + s.X or my < p.Y or my > p.Y + s.Y then
							local cp = chip.AbsolutePosition
							local cs = chip.AbsoluteSize
							if mx < cp.X or mx > cp.X + cs.X or my < cp.Y or my > cp.Y + cs.Y then
								popup.Visible = false
							end
						end
					end
				end))
				function lib:GetValue() return selected end
				function lib:SetValue(v) selected = v; Label(); opts.Callback(selected) end
				function lib:Refresh(values) opts.Values = values; Rebuild() end
				function lib:SetTitle(t) if title then title.Text = t end end
				function lib:Lock() lib.__locked = true; chip.Active = false end
				function lib:Unlock() lib.__locked = false; chip.Active = true end
				function lib:Destroy() if opts.Flag then NexxWareX.Flags[opts.Flag] = nil end; popup:Destroy(); row:Destroy() end
				if opts.Flag then NexxWareX.Flags[opts.Flag] = lib end
				return lib
			end

			function Section:AddKeybind(opts)
				opts = Merge({
					Name = "Keybind", Default = Enum.KeyCode.E, Flag = nil, Callback = function() end,
					Mode = "Toggle", ToolTip = nil,
				}, opts)
				local row, title = Row(opts.Name)
				if opts.ToolTip then BindTooltip(row, opts.ToolTip) end
				title.Size = UDim2.new(1, -150, 1, 0)
				local modeChip = New("TextButton", {
					AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -100, 0.5, 0),
					Size = UDim2.fromOffset(52, 22),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.82,
					Font = Enum.Font.GothamBold,
					TextSize = 10,
					TextColor3 = Theme.Muted,
					Text = opts.Mode,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(modeChip, 6)
				Stroke(modeChip, 0.85)
				local chip = New("TextButton", {
					AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(80, 26),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.82,
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					TextColor3 = Theme.Text,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(chip, 8)
				Stroke(chip, 0.75)
				local modes = { "Toggle", "Hold", "Always" }
				local modeIdx = 1
				for i, m in ipairs(modes) do
					if string.lower(m) == string.lower(opts.Mode) then modeIdx = i end
				end
				local lib = { Value = opts.Default, Mode = modes[modeIdx], Listening = false, Active = false }
				local function NameOf(k)
					if typeof(k) == "EnumItem" then return k.Name end
					return tostring(k)
				end
				chip.Text = NameOf(lib.Value)
				Track(modeChip.MouseButton1Click:Connect(function()
					modeIdx = modeIdx % #modes + 1
					lib.Mode = modes[modeIdx]
					modeChip.Text = lib.Mode
					opts.Callback(lib.Value, false, lib.Mode)
				end))
				Track(chip.MouseButton1Click:Connect(function()
					lib.Listening = true
					chip.Text = "..."
				end))
				Track(UserInputService.InputBegan:Connect(function(input, gp)
					if lib.Listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							lib.Value = input.KeyCode
							lib.Listening = false
							chip.Text = NameOf(lib.Value)
							opts.Callback(lib.Value, false, lib.Mode)
						end
					elseif not gp and input.KeyCode == lib.Value then
						if lib.Mode == "Toggle" then
							lib.Active = not lib.Active
							opts.Callback(lib.Value, lib.Active, lib.Mode)
						elseif lib.Mode == "Hold" then
							lib.Active = true
							opts.Callback(lib.Value, true, lib.Mode)
						elseif lib.Mode == "Always" then
							opts.Callback(lib.Value, true, lib.Mode)
						end
					end
				end))
				Track(UserInputService.InputEnded:Connect(function(input)
					if lib.Mode == "Hold" and input.KeyCode == lib.Value then
						lib.Active = false
						opts.Callback(lib.Value, false, lib.Mode)
					end
				end))
				function lib:GetValue()
					return {
						Key = typeof(lib.Value) == "EnumItem" and lib.Value.Name or lib.Value,
						Mode = lib.Mode,
					}
				end
				function lib:SetValue(v)
					if type(v) == "table" then
						if v.Key then
							if type(v.Key) == "string" then pcall(function() lib.Value = Enum.KeyCode[v.Key] end)
							else lib.Value = v.Key end
						end
						if v.Mode then lib.Mode = v.Mode; modeChip.Text = v.Mode end
					elseif type(v) == "string" then
						pcall(function() lib.Value = Enum.KeyCode[v] end)
					else
						lib.Value = v
					end
					chip.Text = NameOf(lib.Value)
				end
				function lib:SetTitle(t) if title then title.Text = t end end
				function lib:Lock() lib.__locked = true; chip.Active = false; modeChip.Active = false end
				function lib:Unlock() lib.__locked = false; chip.Active = true; modeChip.Active = true end
				function lib:Destroy() if opts.Flag then NexxWareX.Flags[opts.Flag] = nil end; row:Destroy() end
				if opts.Flag then NexxWareX.Flags[opts.Flag] = lib end
				return lib
			end

			function Section:AddColorPicker(opts)
				opts = Merge({ Name = "Color", Default = Theme.Accent, Flag = nil, Callback = function() end, ToolTip = nil }, opts)
				local row, title = Row(opts.Name)
				if opts.ToolTip then BindTooltip(row, opts.ToolTip) end
				title.Size = UDim2.new(1, -52, 1, 0)
				local swatch = New("TextButton", {
					AutoButtonColor = false, Text = "",
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
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.78,
					Size = UDim2.fromOffset(SIZE.Color.X, SIZE.Color.Y),
					ZIndex = Z.ColorPicker,
					Parent = Screen,
				})
				Corner(picker, 14)
				Stroke(picker, 0.65)
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
				local white = New("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), ZIndex = Z.ColorPicker + 2, Parent = sv })
				Corner(white, 8)
				local wg = Instance.new("UIGradient")
				wg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
				wg.Parent = white
				local black = New("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 1), ZIndex = Z.ColorPicker + 3, Parent = sv })
				Corner(black, 8)
				local bg = Instance.new("UIGradient")
				bg.Rotation = 90
				bg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
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
					Size = UDim2.fromOffset(70, 28),
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextColor3 = Theme.Faint,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = "Hex",
					ZIndex = Z.ColorPicker + 1,
					Parent = picker,
				})
				local hexBox = New("TextBox", {
					Position = UDim2.fromOffset(48, 206),
					Size = UDim2.fromOffset(154, 24),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.82,
					Font = Enum.Font.Code,
					TextSize = 12,
					TextColor3 = Theme.Text,
					ClearTextOnFocus = false,
					ZIndex = Z.ColorPicker + 2,
					Parent = picker,
				})
				Corner(hexBox, 6)
				Stroke(hexBox, 0.8)
				Pad(hexBox, 0, 6, 0, 6)
				local h, s, v = opts.Default:ToHSV()
				local lib = { Value = opts.Default }
				local function Apply()
					lib.Value = Color3.fromHSV(h, s, v)
					sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					swatch.BackgroundColor3 = lib.Value
					hexBox.Text = "#" .. lib.Value:ToHex()
					opts.Callback(lib.Value)
				end
				Apply()
				Track(hexBox.FocusLost:Connect(function()
					local raw = hexBox.Text:gsub("#", ""):gsub("%s", "")
					if #raw == 6 then
						local ok, col = pcall(function() return Color3.fromHex(raw) end)
						if ok and typeof(col) == "Color3" then
							h, s, v = col:ToHSV()
							Apply()
						else
							hexBox.Text = "#" .. lib.Value:ToHex()
						end
					else
						hexBox.Text = "#" .. lib.Value:ToHex()
					end
				end))
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
				Track(sv.MouseButton1Down:Connect(function()
					local conn
					SampleSV()
					conn = RunService.RenderStepped:Connect(function()
						if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then SampleSV()
						else conn:Disconnect() end
					end)
				end))
				Track(hueBar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local conn
						SampleHue()
						conn = RunService.RenderStepped:Connect(function()
							if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then SampleHue()
							else conn:Disconnect() end
						end)
					end
				end))
				Track(swatch.MouseButton1Click:Connect(function()
					local pos = swatch.AbsolutePosition
					picker.Position = UDim2.fromOffset(pos.X - SIZE.Color.X + 28, pos.Y + 28)
					picker.Visible = not picker.Visible
				end))
				function lib:GetValue() return lib.Value:ToHex() end
				function lib:SetValue(c)
					if type(c) == "string" then c = Color3.fromHex((c:gsub("#", ""))) end
					h, s, v = c:ToHSV()
					Apply()
				end
				function lib:SetTitle(t) if title then title.Text = t end end
				function lib:Lock() lib.__locked = true end
				function lib:Unlock() lib.__locked = false end
				function lib:Destroy() if opts.Flag then NexxWareX.Flags[opts.Flag] = nil end; row:Destroy(); picker:Destroy() end
				if opts.Flag then NexxWareX.Flags[opts.Flag] = lib end
				return lib
			end

			function Section:AddTextInput(opts)
				opts = Merge({ Name = "Input", Default = "", Placeholder = "", Flag = nil, Callback = function() end, ToolTip = nil }, opts)
				local row, title = Row(opts.Name)
				if opts.ToolTip then BindTooltip(row, opts.ToolTip) end
				title.Size = UDim2.new(0.4, 0, 1, 0)
				local box = New("TextBox", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(128, 26),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.82,
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
				Track(box.FocusLost:Connect(function()
					lib.Value = box.Text
					opts.Callback(lib.Value)
				end))
				function lib:GetValue() return lib.Value end
				function lib:SetValue(v)
					lib.Value = tostring(v)
					box.Text = lib.Value
					opts.Callback(lib.Value)
				end
				function lib:SetTitle(t) if title then title.Text = t end end
				function lib:Lock() lib.__locked = true; box.TextEditable = false end
				function lib:Unlock() lib.__locked = false; box.TextEditable = true end
				function lib:Destroy() if opts.Flag then NexxWareX.Flags[opts.Flag] = nil end; row:Destroy() end
				if opts.Flag then NexxWareX.Flags[opts.Flag] = lib end
				return lib
			end

			function Section:AddButton(opts)
				opts = Merge({ Name = "Button", Icon = "chevron-right", Callback = function() end, Dialog = nil, ToolTip = nil }, opts)
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
					BackgroundTransparency = 0.82,
					Text = "",
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(btn, 10)
				Stroke(btn, 0.72)
				local ic = New("ImageLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 6),
					Size = UDim2.fromOffset(18, 18),
					ZIndex = Z.Control + 1,
					Parent = btn,
				})
				NexxWareX:SetIcon(ic, opts.Icon, Theme.Accent)
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
				if opts.ToolTip then BindTooltip(btn, opts.ToolTip) end
				Track(btn.MouseButton1Click:Connect(function()
					if lib.__locked then return end
					if opts.Dialog then
						OpenDialog({
							Title = opts.Dialog.Title or opts.Name,
							Content = opts.Dialog.Content or "Confirm this action.",
							Confirm = opts.Dialog.Confirm or "Confirm",
							Cancel = opts.Dialog.Cancel or "Cancel",
							Callback = function(ok) if ok then opts.Callback() end end,
						})
					else
						opts.Callback()
					end
				end))
				local lib = {}
				function lib:SetTitle(t)
					opts.Name = t
					for _, c in ipairs(btn:GetChildren()) do
						if c:IsA("TextLabel") then c.Text = t end
					end
				end
				function lib:Lock() lib.__locked = true; btn.Active = false end
				function lib:Unlock() lib.__locked = false; btn.Active = true end
				function lib:Destroy() row:Destroy() end
				return lib
			end

			function Section:AddMultiButton(opts)
				opts = Merge({
					Buttons = {
						{ Title = "A", Callback = function() end },
						{ Title = "B", Callback = function() end },
						{ Title = "C", Callback = function() end },
					},
				}, opts)
				local buttons = opts.Buttons
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 78),
					ZIndex = Z.Row + 1,
					Parent = body,
				})
				table.insert(Registry, { Name = "MultiButton", Root = row })
				local function makeBtn(cfg, pos, size)
					local b = New("TextButton", {
						AutoButtonColor = false,
						Position = pos,
						Size = size,
						BackgroundColor3 = Theme.Glass,
						BackgroundTransparency = 0.82,
						Font = Enum.Font.GothamMedium,
						TextSize = 12,
						TextColor3 = Theme.Text,
						Text = cfg.Title or cfg.Name or "Button",
						ZIndex = Z.Control,
						Parent = row,
					})
					Corner(b, 10)
					Stroke(b, 0.78)
					Track(b.MouseButton1Click:Connect(function()
						if cfg.Dialog then
							OpenDialog({
								Title = cfg.Dialog.Title or (cfg.Title or "Confirm"),
								Content = cfg.Dialog.Content or "Confirm this action.",
								Confirm = cfg.Dialog.Confirm or "Confirm",
								Cancel = cfg.Dialog.Cancel or "Cancel",
								Callback = function(ok) if ok and cfg.Callback then cfg.Callback() end end,
							})
						elseif cfg.Callback then
							cfg.Callback()
						end
					end))
					return b
				end
				if buttons[1] then makeBtn(buttons[1], UDim2.fromOffset(10, 6), UDim2.new(0.5, -14, 0, 30)) end
				if buttons[2] then makeBtn(buttons[2], UDim2.new(0.5, 2, 0, 6), UDim2.new(0.5, -12, 0, 30)) end
				if buttons[3] then makeBtn(buttons[3], UDim2.fromOffset(10, 42), UDim2.new(1, -20, 0, 30)) end
				return row
			end

			function Section:AddCode(opts)
				return self:AddCodeBox(opts)
			end

			function Section:AddCodeBox(opts)
				opts = Merge({
					Title = "Code",
					Code = 'print("Hello")',
					OnCopy = nil,
				}, opts)
				local lines = 1
				for _ in string.gmatch(opts.Code, "\n") do lines = lines + 1 end
				local h = math.clamp(28 + lines * 14, 72, 180)
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, h + 8),
					ZIndex = Z.Row + 1,
					Parent = body,
				})
				table.insert(Registry, { Name = opts.Title, Root = row })
				local card = New("Frame", {
					Position = UDim2.fromOffset(10, 4),
					Size = UDim2.new(1, -20, 0, h),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.88,
					ZIndex = Z.Control,
					Parent = row,
				})
				Corner(card, 10)
				Stroke(card, 0.75)
				New("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 6),
					Size = UDim2.new(1, -70, 0, 16),
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Theme.Faint,
					Text = opts.Title,
					ZIndex = Z.Control + 1,
					Parent = card,
				})
				local copyBtn = New("TextButton", {
					AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -8, 0, 4),
					Size = UDim2.fromOffset(52, 20),
					BackgroundColor3 = Theme.Glass,
					BackgroundTransparency = 0.82,
					Font = Enum.Font.GothamBold,
					TextSize = 10,
					TextColor3 = Theme.Accent,
					Text = "Copy",
					ZIndex = Z.Control + 2,
					Parent = card,
				})
				Corner(copyBtn, 6)
				local codeLbl = New("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 26),
					Size = UDim2.new(1, -20, 1, -32),
					Font = Enum.Font.Code,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextColor3 = Theme.Text,
					Text = opts.Code,
					TextWrapped = true,
					ZIndex = Z.Control + 1,
					Parent = card,
				})
				local lib = { Title = opts.Title, Code = opts.Code }
				Track(copyBtn.MouseButton1Click:Connect(function()
					if setclipboard then setclipboard(lib.Code) end
					NexxWareX:Notify({ Title = "Copied", Content = lib.Title, Type = "Success", Icon = "check" })
					if opts.OnCopy then opts.OnCopy() end
				end))
				function lib:SetCode(c)
					lib.Code = c
					codeLbl.Text = c
				end
				function lib:OnCopy(fn)
					opts.OnCopy = fn
				end
				function lib:Destroy()
					row:Destroy()
				end
				return lib
			end

			return Section
		end

		function tab:AddSection(sec)
			return MakeSection(sec)
		end

		function tab:AddSubTab(cfg)
			cfg = Merge({ Name = "Sub", Icon = "circle" }, cfg)
			cfg.Parent = tab
			return Window:AddTab(cfg)
		end

		table.insert(Window.Tabs, tab)
		if #Window.Tabs == 1 then SelectTab(1) end
		return tab
	end

	local function Collect()
		local data = {}
		for flag, obj in pairs(NexxWareX.Flags) do
			if obj and obj.GetValue then data[flag] = obj:GetValue() end
		end
		return data
	end

	local function ApplyFlags(data)
		if type(data) ~= "table" then return end
		for flag, value in pairs(data) do
			local obj = NexxWareX.Flags[flag]
			if obj and obj.SetValue then pcall(obj.SetValue, obj, value) end
		end
	end

	local function Encode(tbl)
		return HttpService:Base64Encode(HttpService:JSONEncode({
			v = 2, lib = "NexxWareX", flags = tbl,
		}))
	end

	local function Decode(str)
		str = tostring(str or ""):gsub("%s+", "")
		local ok, json = pcall(function()
			return HttpService:JSONDecode(HttpService:Base64Decode(str))
		end)
		if ok and type(json) == "table" then return json.flags or json end
		local ok2, raw = pcall(HttpService.JSONDecode, HttpService, str)
		if ok2 and type(raw) == "table" then return raw.flags or raw end
		return nil
	end

	function Window:ListConfigs()
		local list = {}
		if not HasFS() then return list end
		if not isfolder(config.ConfigFolder) then return list end
		for _, path in ipairs(listfiles(config.ConfigFolder)) do
			local name = string.match(path, "([^/\\]+)%.fg$") or string.match(path, "([^/\\]+)$")
			if name then table.insert(list, name) end
		end
		return list
	end

	function Window:SaveConfig(name)
		name = name ~= "" and name or "Default"
		if not HasFS() then
			NexxWareX:Notify({ Title = "Config", Content = "Filesystem unavailable", Type = "Error" })
			return
		end
		writefile(config.ConfigFolder .. "/" .. name .. ".fg", Encode(Collect()))
		NexxWareX:Notify({ Title = "Saved", Content = name, Type = "Success", Icon = "check" })
	end

	function Window:LoadConfig(name)
		name = name ~= "" and name or "Default"
		local path = config.ConfigFolder .. "/" .. name .. ".fg"
		if not HasFS() or not isfile(path) then
			NexxWareX:Notify({ Title = "Config", Content = "Not found: " .. name, Type = "Warn" })
			return
		end
		ApplyFlags(Decode(readfile(path)))
		NexxWareX:Notify({ Title = "Loaded", Content = name, Type = "Success", Icon = "folder" })
	end

	function Window:DeleteConfig(name)
		local path = config.ConfigFolder .. "/" .. name .. ".fg"
		if HasFS() and isfile(path) then
			delfile(path)
			NexxWareX:Notify({ Title = "Deleted", Content = name, Type = "Warn", Icon = "trash-2" })
		end
	end

	function Window:ExportConfig()
		local payload = Encode(Collect())
		if setclipboard then
			setclipboard(payload)
			NexxWareX:Notify({ Title = "Exported", Content = "Config copied", Type = "Success", Icon = "upload" })
		end
		return payload
	end

	function Window:ImportConfig(payload)
		if not payload or payload == "" then
			if getclipboard then payload = getclipboard() end
		end
		local flags = Decode(payload)
		if not flags then
			NexxWareX:Notify({ Title = "Import failed", Content = "Invalid payload", Type = "Error" })
			return
		end
		ApplyFlags(flags)
		NexxWareX:Notify({ Title = "Imported", Content = "Flags applied", Type = "Success", Icon = "download" })
	end

	function Window:Watermark()
		if NexxWareX.__Watermark then return NexxWareX.__Watermark end
		local wm = {}
		local frame = New("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 12),
			Size = UDim2.fromOffset(160, 28),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.82,
			ZIndex = Z.Watermark,
			Parent = Screen,
		})
		Corner(frame, 14)
		Stroke(frame, 0.7)
		local layout = New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 6),
			Parent = frame,
		})
		Pad(frame, 0, 10, 0, 10)
		Track(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			frame.Size = UDim2.fromOffset(layout.AbsoluteContentSize.X + 20, 28)
		end))
		function wm:SetRender(v)
			frame.Visible = v and true or false
		end
		function wm:AddBlock(icon, text)
			local block = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(40, 28),
				ZIndex = Z.Watermark + 1,
				Parent = frame,
			})
			local ic = New("ImageLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 6),
				Size = UDim2.fromOffset(16, 16),
				ZIndex = Z.Watermark + 2,
				Parent = block,
			})
			NexxWareX:SetIcon(ic, icon, Theme.Accent)
			local lbl = New("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(20, 0),
				Size = UDim2.fromOffset(20, 28),
				AutomaticSize = Enum.AutomaticSize.X,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Theme.Muted,
				Text = text,
				ZIndex = Z.Watermark + 2,
				Parent = block,
			})
			local api = {}
			function api:SetText(t)
				lbl.Text = t
				block.Size = UDim2.fromOffset(lbl.TextBounds.X + 24, 28)
			end
			function api:SetVisible(v) block.Visible = v end
			api:SetText(text)
			return api
		end
		NexxWareX.__Watermark = wm
		return wm
	end

	function Window:AddLibrarySettings()
		self:AddTabLabel("System")
		local tab = self:AddTab({ Name = "Settings", Icon = "settings" })
		local ui = tab:AddSection({ Name = "Interface", Side = "Left" })
		local look = tab:AddSection({ Name = "Appearance", Side = "Right" })
		local cfg = tab:AddSection({ Name = "Configs", Side = "Right" })
		ui:AddKeybind({
			Name = "Menu Key",
			Flag = "nx.menuKey",
			Default = Window.Keybind,
			Mode = "Toggle",
			Callback = function(k) Window.Keybind = k end,
		})
		ui:AddToggle({
			Name = "Menu Blur",
			Flag = "nx.blur",
			Default = true,
			Callback = function(v)
				config.Blur = v
				SetBlur(Window.Visible and v)
			end,
		})
		ui:AddToggle({
			Name = "Acrylic",
			Flag = "nx.acrylic",
			Default = true,
			Callback = function(v)
				config.Acrylic = v
				SetBlur(Window.Visible and config.Blur)
			end,
		})
		ui:AddSlider({
			Name = "Opacity",
			Flag = "nx.opacity",
			Min = 50, Max = 95, Default = 88, Suffix = "%",
			Callback = function(v)
				Theme.FillTransparency = v / 100
				if Window.Visible then Root.BackgroundTransparency = Theme.FillTransparency end
			end,
		})
		ui:AddToggle({
			Name = "Watermark",
			Flag = "nx.wm",
			Default = false,
			Callback = function(v)
				Window:Watermark():SetRender(v)
			end,
		})
		look:AddColorPicker({
			Name = "Accent",
			Flag = "nx.accent",
			Default = Theme.Accent,
			Callback = function(c) Theme.Accent = c end,
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
			Flag = "nx.cfgName",
			Default = "Default",
			Placeholder = "Default",
		})
		cfg:AddDropdown({
			Name = "Saved",
			Flag = "nx.cfgList",
			Values = Window:ListConfigs(),
			Default = "Default",
			Callback = function(v)
				if type(v) == "string" then nameBox:SetValue(v) end
			end,
		})
		cfg:AddMultiButton({
			Buttons = {
				{ Title = "Save", Callback = function() Window:SaveConfig(nameBox:GetValue()) end },
				{ Title = "Load", Callback = function() Window:LoadConfig(nameBox:GetValue()) end },
				{ Title = "Refresh list", Callback = function()
					local drop = NexxWareX.Flags["nx.cfgList"]
					if drop and drop.Refresh then drop:Refresh(Window:ListConfigs()) end
					NexxWareX:Notify({ Title = "Configs", Content = "List refreshed", Type = "Info" })
				end },
			},
		})
		cfg:AddButton({
			Name = "Export Config",
			Icon = "upload",
			Callback = function() Window:ExportConfig() end,
		})
		cfg:AddButton({
			Name = "Import Config",
			Icon = "download",
			Dialog = {
				Title = "Import config?",
				Content = "Clipboard payload will overwrite current flags.",
				Confirm = "Import",
			},
			Callback = function() Window:ImportConfig() end,
		})
		cfg:AddButton({
			Name = "Delete Config",
			Icon = "trash-2",
			Dialog = {
				Title = "Delete config?",
				Content = "This file will be removed from disk.",
				Confirm = "Delete",
			},
			Callback = function() Window:DeleteConfig(nameBox:GetValue()) end,
		})
		return tab
	end

	if config.AutoLoad and config.AutoLoad ~= false then
		local name = type(config.AutoLoad) == "string" and config.AutoLoad or "Default"
		task.defer(function()
			local path = config.ConfigFolder .. "/" .. name .. ".fg"
			if HasFS() and isfile(path) then
				pcall(function()
					ApplyFlags(Decode(readfile(path)))
				end)
			end
		end)
	end

	table.insert(self.Windows, Window)
	return Window
end

function NexxWareX:Unload()
	for _, s in ipairs(self.Signals) do
		pcall(function() s:Disconnect() end)
	end
	table.clear(self.Signals)
	pcall(function() BlurEffect:Destroy() end)
	pcall(function() AcrylicFX:Destroy() end)
	if NexxWareX.__NotifyCards then
		for _, c in ipairs(NexxWareX.__NotifyCards) do pcall(function() c:Destroy() end) end
		table.clear(NexxWareX.__NotifyCards)
	end
	Screen:Destroy()
end

return NexxWareX
