local LucideIcons = (function()
	local ok, icons = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/Icons/lucide.lua"))()
	end)
	return (ok and icons) or {}
end)()

local function Icon(name)
	if not name then return nil end
	if type(name) == "number" then return "rbxassetid://" .. name end
	local s = tostring(name)
	if s:match("^%d+$") then return "rbxassetid://" .. s end
	if s:find("rbxasset") or s:find("http") then return s end
	s = s:lower():gsub("%s+", "-")
	return LucideIcons[s] or LucideIcons[s:gsub("-", "")] or nil
end

local S = setmetatable({}, {
	__index = function(t, k)
		rawset(t, k, (cloneref or function(x) return x end)(game:GetService(k)))
		return rawget(t, k)
	end
})

local UIS, TS, CG, Players, Cam, HS =
	S.UserInputService, S.TweenService, S.CoreGui, S.Players, workspace.CurrentCamera, S.HttpService

local Themes = {
	Dark = {
		Bg = Color3.fromRGB(16, 16, 18),
		Bg2 = Color3.fromRGB(22, 22, 26),
		Card = Color3.fromRGB(30, 30, 36),
		CardHover = Color3.fromRGB(40, 40, 48),
		Stroke = Color3.fromRGB(55, 55, 65),
		Text = Color3.fromRGB(255, 255, 255),
		Text2 = Color3.fromRGB(200, 200, 210),
		Text3 = Color3.fromRGB(140, 140, 155),
		Accent = Color3.fromRGB(255, 255, 255),
		On = Color3.fromRGB(255, 255, 255),
		Off = Color3.fromRGB(50, 50, 58),
		Knob = Color3.fromRGB(20, 20, 24),
		Locked = Color3.fromRGB(255, 255, 255),
		SearchHit = Color3.fromRGB(255, 220, 80),
		Err = Color3.fromRGB(255, 90, 90),
		Ok = Color3.fromRGB(80, 200, 120),
	},
	Light = {
		Bg = Color3.fromRGB(245, 245, 248),
		Bg2 = Color3.fromRGB(255, 255, 255),
		Card = Color3.fromRGB(235, 235, 240),
		CardHover = Color3.fromRGB(220, 220, 228),
		Stroke = Color3.fromRGB(200, 200, 210),
		Text = Color3.fromRGB(20, 20, 25),
		Text2 = Color3.fromRGB(70, 70, 80),
		Text3 = Color3.fromRGB(120, 120, 130),
		Accent = Color3.fromRGB(20, 20, 25),
		On = Color3.fromRGB(20, 20, 25),
		Off = Color3.fromRGB(200, 200, 210),
		Knob = Color3.fromRGB(255, 255, 255),
		Locked = Color3.fromRGB(40, 40, 50),
		SearchHit = Color3.fromRGB(180, 120, 0),
		Err = Color3.fromRGB(200, 50, 50),
		Ok = Color3.fromRGB(40, 160, 90),
	},
}

local Lib = {
	Theme = Themes.Dark,
	ThemeName = "Dark",
	Transparency = 0.05,
	Flags = {},
	Folder = "NexxChasers",
	AutoSave = false,
	AutoSaveName = "autosave",
	Tabs = {},
	Elements = {},
	IsOpen = true,
	Device = "pc",
	Scale = 1,
}

local function Tween(o, p, d, s)
	local t = TS:Create(o, TweenInfo.new(d or 0.25, s or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p)
	t:Play()
	return t
end

local function Corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = p
	return c
end

local function Stroke(p, col, th)
	local s = Instance.new("UIStroke")
	s.Color = col or Lib.Theme.Stroke
	s.Thickness = th or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function Pad(p, t, b, l, r)
	local u = Instance.new("UIPadding")
	u.PaddingTop = UDim.new(0, t or 0)
	u.PaddingBottom = UDim.new(0, b or 0)
	u.PaddingLeft = UDim.new(0, l or 0)
	u.PaddingRight = UDim.new(0, r or 0)
	u.Parent = p
	return u
end

function Lib:SetFlag(flag, value)
	if not flag then return end
	self.Flags[flag] = value
	if self.AutoSave and writefile then
		task.defer(function() self:SaveConfig(self.AutoSaveName) end)
	end
end

function Lib:EnableAutoSave(name)
	self.AutoSave = true
	self.AutoSaveName = name or "autosave"
end

function Lib:DisableAutoSave()
	self.AutoSave = false
end

function Lib:SaveConfig(name)
	if not writefile then return end
	pcall(function()
		if not isfolder(self.Folder) then makefolder(self.Folder) end
		writefile(self.Folder .. "/" .. (name or "config") .. ".json", HS:JSONEncode(self.Flags))
	end)
end

function Lib:LoadConfig(name)
	if not readfile then return end
	pcall(function()
		local path = self.Folder .. "/" .. (name or "config") .. ".json"
		if isfile(path) then
			for k, v in pairs(HS:JSONDecode(readfile(path))) do
				self.Flags[k] = v
			end
		end
	end)
end

function Lib:SetTheme(name)
	local t = Themes[name]
	if not t then return end
	self.Theme = t
	self.ThemeName = name
	if self.Window then
		self.Window.BackgroundColor3 = t.Bg
		for _, d in ipairs(self.Window:GetDescendants()) do
			if d:IsA("UIStroke") then d.Color = t.Stroke end
		end
	end
	if self.Floating then
		self.Floating.BackgroundColor3 = t.Bg2
		local st = self.Floating:FindFirstChildOfClass("UIStroke")
		if st then st.Color = t.Accent end
		local img = self.Floating:FindFirstChildWhichIsA("ImageButton")
		if img then img.ImageColor3 = t.Text end
	end
end

function Lib:Notify(cfg)
	local gui = self.Gui
	if not gui then return end
	local T = self.Theme
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 0, 0, 0)
	f.Position = UDim2.new(1, -16, 1, -16)
	f.AnchorPoint = Vector2.new(1, 1)
	f.BackgroundColor3 = T.Bg2
	f.BackgroundTransparency = self.Transparency
	f.BorderSizePixel = 0
	f.ZIndex = 300
	f.Parent = gui
	Corner(f, 12)
	Stroke(f, T.Stroke, 1)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 22)
	title.Position = UDim2.new(0, 14, 0, 12)
	title.BackgroundTransparency = 1
	title.Text = cfg.title or "Notify"
	title.TextColor3 = T.Text
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 301
	title.Parent = f

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -24, 0, 28)
	body.Position = UDim2.new(0, 14, 0, 34)
	body.BackgroundTransparency = 1
	body.Text = cfg.content or ""
	body.TextColor3 = T.Text2
	body.TextSize = 14
	body.Font = Enum.Font.Gotham
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextWrapped = true
	body.ZIndex = 301
	body.Parent = f

	Tween(f, { Size = UDim2.new(0, 320, 0, 72) }, 0.3, Enum.EasingStyle.Back)
	task.delay(cfg.duration or 3, function()
		Tween(f, { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }, 0.25).Completed:Connect(function()
			f:Destroy()
		end)
		title.TextTransparency = 1
		body.TextTransparency = 1
	end)
end

Lib.notify = Lib.Notify

function Lib:Dialog(cfg)
	local gui = self.Gui
	if not gui then return end
	local T = self.Theme

	local ov = Instance.new("Frame")
	ov.Size = UDim2.new(1, 0, 1, 0)
	ov.BackgroundColor3 = Color3.new(0, 0, 0)
	ov.BackgroundTransparency = 1
	ov.ZIndex = 400
	ov.Parent = gui

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 0, 0, 0)
	box.Position = UDim2.new(0.5, 0, 0.5, 0)
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.BackgroundColor3 = T.Bg2
	box.BorderSizePixel = 0
	box.ZIndex = 401
	box.Parent = ov
	Corner(box, 14)
	Stroke(box, Color3.fromRGB(255, 255, 255), 1)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 28)
	title.Position = UDim2.new(0, 20, 0, 16)
	title.BackgroundTransparency = 1
	title.Text = cfg.Title or "Dialog"
	title.TextColor3 = T.Text
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 402
	title.Parent = box

	local content = Instance.new("TextLabel")
	content.Size = UDim2.new(1, -40, 0, 60)
	content.Position = UDim2.new(0, 20, 0, 50)
	content.BackgroundTransparency = 1
	content.Text = cfg.Content or ""
	content.TextColor3 = T.Text2
	content.TextSize = 15
	content.Font = Enum.Font.Gotham
	content.TextXAlignment = Enum.TextXAlignment.Left
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.TextWrapped = true
	content.ZIndex = 402
	content.Parent = box

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -40, 0, 40)
	holder.Position = UDim2.new(0, 20, 1, -56)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 402
	holder.Parent = box

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	lay.Padding = UDim.new(0, 8)
	lay.Parent = holder

	local function close()
		Tween(ov, { BackgroundTransparency = 1 }, 0.2)
		Tween(box, { Size = UDim2.new(0, 0, 0, 0) }, 0.25).Completed:Connect(function() ov:Destroy() end)
	end

	for _, b in ipairs(cfg.Buttons or { { Title = "OK" } }) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 100, 0, 36)
		btn.BackgroundColor3 = T.Card
		btn.Text = b.Title or "OK"
		btn.TextColor3 = T.Text
		btn.TextSize = 15
		btn.Font = Enum.Font.GothamMedium
		btn.ZIndex = 403
		btn.Parent = holder
		Corner(btn, 8)
		Stroke(btn, T.Stroke, 1)
		btn.MouseButton1Click:Connect(function()
			if b.Callback then b.Callback() end
			close()
		end)
	end

	Tween(ov, { BackgroundTransparency = 0.45 }, 0.25)
	Tween(box, { Size = UDim2.new(0, 380, 0, 190) }, 0.35, Enum.EasingStyle.Back)
end

function Lib:Open()
	if self.IsOpen then return end
	self.IsOpen = true
	local m = self.Window
	if not m then return end
	m.Visible = true
	m.Size = UDim2.new(0, 0, 0, 0)
	m.BackgroundTransparency = 1
	Tween(m, {
		Size = self.TargetSize or UDim2.new(0, 800, 0, 520),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = self.Transparency,
	}, 0.4, Enum.EasingStyle.Back)
end

function Lib:Close()
	if not self.IsOpen then return end
	self.IsOpen = false
	local m = self.Window
	if not m then return end
	self.TargetSize = m.Size
	Tween(m, {
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
	}, 0.28).Completed:Connect(function()
		m.Visible = false
	end)
end

function Lib:Toggle()
	if self.IsOpen then self:Close() else self:Open() end
end

function Lib:CreateWindow(cfg)
	cfg = cfg or {}
	local title = cfg.Title or "NexxChasers"
	local author = cfg.Author or ""
	local themeName = cfg.Theme or "Dark"
	self.Transparency = cfg.Transparency or 0.05
	self.Folder = cfg.Folder or "NexxChasers"
	self.Theme = Themes[themeName] or Themes.Dark
	self.ThemeName = themeName
	local T = self.Theme

	local logo = cfg.Logo
	logo = Icon(logo) or Icon("layout-dashboard") or "rbxassetid://10734943674"

	local toggleKey = cfg.ToggleKeybind or Enum.KeyCode.RightShift
	if type(toggleKey) == "string" then toggleKey = Enum.KeyCode[toggleKey] or Enum.KeyCode.RightShift end

	self.Device = UIS.TouchEnabled and "mobile" or "pc"
	local vx, vy = Cam.ViewportSize.X, Cam.ViewportSize.Y
	self.Scale = math.clamp(math.min(vx / 1280, vy / 720), 0.55, 1.15)

	local gui = Instance.new("ScreenGui")
	gui.Name = "NexxChasers"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	pcall(function() gui.Parent = CG end)
	if not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
	self.Gui = gui

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.Size = UDim2.new(0, 0, 0, 0)
	main.BackgroundColor3 = T.Bg
	main.BackgroundTransparency = 1
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = gui
	Corner(main, 16)
	Stroke(main, T.Stroke, 1)
	self.Window = main

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = self.Device == "mobile" and self.Scale or math.clamp(self.Scale, 0.9, 1.1)
	uiScale.Parent = main
	Cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local vx, vy = Cam.ViewportSize.X, Cam.ViewportSize.Y
		self.Scale = math.clamp(math.min(vx / 1280, vy / 720), 0.55, 1.15)
		uiScale.Scale = self.Device == "mobile" and self.Scale or math.clamp(self.Scale, 0.9, 1.1)
	end)

	local tw = self.Device == "mobile" and math.floor(vx * 0.92) or 800
	local th = self.Device == "mobile" and math.floor(vy * 0.75) or 520
	self.TargetSize = UDim2.new(0, tw, 0, th)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 58)
	header.BackgroundColor3 = T.Bg2
	header.BackgroundTransparency = self.Transparency
	header.BorderSizePixel = 0
	header.ZIndex = 5
	header.Parent = main
	Corner(header, 16)

	local hLine = Instance.new("Frame")
	hLine.Size = UDim2.new(1, 0, 0, 1)
	hLine.Position = UDim2.new(0, 0, 1, -1)
	hLine.BackgroundColor3 = T.Stroke
	hLine.BorderSizePixel = 0
	hLine.ZIndex = 6
	hLine.Parent = header

	local logoImg = Instance.new("ImageLabel")
	logoImg.Size = UDim2.new(0, 28, 0, 28)
	logoImg.Position = UDim2.new(0, 16, 0.5, -14)
	logoImg.BackgroundTransparency = 1
	logoImg.Image = logo
	logoImg.ImageColor3 = T.Text
	logoImg.ZIndex = 7
	logoImg.Parent = header

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(0, 260, 0, 22)
	titleLbl.Position = UDim2.new(0, 54, 0, 10)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = title
	titleLbl.TextColor3 = T.Text
	titleLbl.TextSize = 18
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 7
	titleLbl.Parent = header

	if author ~= "" then
		local al = Instance.new("TextLabel")
		al.Size = UDim2.new(0, 260, 0, 18)
		al.Position = UDim2.new(0, 54, 0, 32)
		al.BackgroundTransparency = 1
		al.Text = author
		al.TextColor3 = T.Text3
		al.TextSize = 13
		al.Font = Enum.Font.Gotham
		al.TextXAlignment = Enum.TextXAlignment.Left
		al.ZIndex = 7
		al.Parent = header
	end

	local closeBtn = Instance.new("ImageButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -44, 0.5, -16)
	closeBtn.BackgroundColor3 = T.Card
	closeBtn.BorderSizePixel = 0
	closeBtn.Image = Icon("x") or "rbxassetid://10747384394"
	closeBtn.ImageColor3 = T.Text2
	closeBtn.ScaleType = Enum.ScaleType.Fit
	closeBtn.ZIndex = 8
	closeBtn.Parent = header
	Corner(closeBtn, 8)
	Pad(closeBtn, 7, 7, 7, 7)
	closeBtn.MouseButton1Click:Connect(function() self:Close() end)
	closeBtn.MouseEnter:Connect(function() Tween(closeBtn, { BackgroundColor3 = T.CardHover, ImageColor3 = T.Text }, 0.15) end)
	closeBtn.MouseLeave:Connect(function() Tween(closeBtn, { BackgroundColor3 = T.Card, ImageColor3 = T.Text2 }, 0.15) end)

	local searchBox = Instance.new("Frame")
	searchBox.Size = UDim2.new(0, 160, 0, 32)
	searchBox.Position = UDim2.new(1, -220, 0.5, -16)
	searchBox.BackgroundColor3 = T.Card
	searchBox.BorderSizePixel = 0
	searchBox.ZIndex = 7
	searchBox.Parent = header
	Corner(searchBox, 8)
	Stroke(searchBox, T.Stroke, 1)

	local sIcon = Instance.new("ImageLabel")
	sIcon.Size = UDim2.new(0, 15, 0, 15)
	sIcon.Position = UDim2.new(0, 10, 0.5, -7)
	sIcon.BackgroundTransparency = 1
	sIcon.Image = Icon("search") or "rbxassetid://10734943674"
	sIcon.ImageColor3 = T.Text3
	sIcon.ZIndex = 8
	sIcon.Parent = searchBox

	local sInput = Instance.new("TextBox")
	sInput.Size = UDim2.new(1, -36, 1, 0)
	sInput.Position = UDim2.new(0, 30, 0, 0)
	sInput.BackgroundTransparency = 1
	sInput.PlaceholderText = "Search..."
	sInput.PlaceholderColor3 = T.Text3
	sInput.Text = ""
	sInput.TextColor3 = T.Text
	sInput.TextSize = 14
	sInput.Font = Enum.Font.Gotham
	sInput.TextXAlignment = Enum.TextXAlignment.Left
	sInput.ClearTextOnFocus = false
	sInput.ZIndex = 8
	sInput.Parent = searchBox

	sInput:GetPropertyChangedSignal("Text"):Connect(function()
		local q = sInput.Text:lower()
		for _, el in ipairs(self.Elements) do
			local isDiv = el.Frame.Name == "Divider"
			local lbl = el.Frame:FindFirstChildWhichIsA("TextLabel")
			if q == "" then
				el.Frame.Visible = true
				if lbl then lbl.TextColor3 = T.Text end
			elseif isDiv then
				el.Frame.Visible = false
			else
				local hit = el.Name:lower():find(q, 1, true) ~= nil
				el.Frame.Visible = hit
				if lbl then lbl.TextColor3 = hit and T.SearchHit or T.Text end
			end
		end
	end)

	local tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Size = UDim2.new(0, 160, 1, -76)
	tabScroll.Position = UDim2.new(0, 10, 0, 66)
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	tabScroll.ScrollBarThickness = 3
	tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabScroll.ZIndex = 4
	tabScroll.Parent = main

	local tabList = Instance.new("UIListLayout")
	tabList.Padding = UDim.new(0, 6)
	tabList.Parent = tabScroll
	tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabList.AbsoluteContentSize.Y + 12)
	end)

	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(0, 1, 1, -76)
	sep.Position = UDim2.new(0, 178, 0, 66)
	sep.BackgroundColor3 = T.Stroke
	sep.BorderSizePixel = 0
	sep.ZIndex = 4
	sep.Parent = main

	local dragLine = Instance.new("Frame")
	dragLine.Size = UDim2.new(0, 120, 0, 6)
	dragLine.Position = UDim2.new(0.5, -60, 1, 14)
	dragLine.BackgroundColor3 = T.Text2
	dragLine.BackgroundTransparency = 0.25
	dragLine.BorderSizePixel = 0
	dragLine.ZIndex = 30
	dragLine.Parent = main
	Corner(dragLine, 3)

	local dragging, dragStart, startPos
	dragLine.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local resizeHold = Instance.new("Frame")
	resizeHold.Size = UDim2.new(0, 36, 0, 36)
	resizeHold.Position = UDim2.new(1, 8, 1, 8)
	resizeHold.BackgroundTransparency = 1
	resizeHold.ZIndex = 30
	resizeHold.Parent = main

	local rH = Instance.new("Frame")
	rH.Size = UDim2.new(0, 18, 0, 3)
	rH.Position = UDim2.new(1, -22, 1, -8)
	rH.BackgroundColor3 = T.Text2
	rH.BackgroundTransparency = 0.15
	rH.BorderSizePixel = 0
	rH.ZIndex = 31
	rH.Parent = resizeHold
	Corner(rH, 1)

	local rV = Instance.new("Frame")
	rV.Size = UDim2.new(0, 3, 0, 18)
	rV.Position = UDim2.new(1, -8, 1, -22)
	rV.BackgroundColor3 = T.Text2
	rV.BackgroundTransparency = 0.15
	rV.BorderSizePixel = 0
	rV.ZIndex = 31
	rV.Parent = resizeHold
	Corner(rV, 1)

	local resizing, rStart, sStart
	resizeHold.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			rStart = Vector2.new(input.Position.X, input.Position.Y)
			sStart = main.Size
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if not resizing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = Vector2.new(input.Position.X, input.Position.Y) - rStart
		main.Size = UDim2.new(0, math.max(500, sStart.X.Offset + d.X), 0, math.max(380, sStart.Y.Offset + d.Y))
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
		end
	end)

	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then self:Toggle() end
	end)

	local float = Instance.new("Frame")
	float.Size = UDim2.new(0, 58, 0, 58)
	float.Position = UDim2.new(1, -82, 1, -100)
	float.BackgroundColor3 = T.Bg2
	float.BackgroundTransparency = self.Transparency
	float.BorderSizePixel = 0
	float.ZIndex = 150
	float.Active = true
	float.Parent = gui
	Corner(float, 29)
	Stroke(float, T.Accent, 1.5).Transparency = 0.2

	local fBtn = Instance.new("ImageButton")
	fBtn.Size = UDim2.new(1, 0, 1, 0)
	fBtn.BackgroundTransparency = 1
	fBtn.Image = logo
	fBtn.ImageColor3 = T.Text
	fBtn.ScaleType = Enum.ScaleType.Fit
	fBtn.ZIndex = 151
	fBtn.Active = true
	fBtn.Parent = float
	Pad(fBtn, 14, 14, 14, 14)

	local fDrag, fStart, fPos, fMoved
	local function beginF(input)
		fDrag = true
		fMoved = false
		fStart = input.Position
		fPos = float.Position
	end
	float.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginF(input) end
	end)
	fBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginF(input) end
	end)
	UIS.InputChanged:Connect(function(input)
		if fDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - fStart
			if math.abs(d.X) > 3 or math.abs(d.Y) > 3 then fMoved = true end
			float.Position = UDim2.new(fPos.X.Scale, fPos.X.Offset + d.X, fPos.Y.Scale, fPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if fDrag and not fMoved then self:Toggle() end
			fDrag = false
		end
	end)
	self.Floating = float

	task.defer(function()
		Tween(main, {
			Size = self.TargetSize,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = self.Transparency,
		}, 0.45, Enum.EasingStyle.Back)
		self.IsOpen = true
	end)

	function Lib:create_tab(name, iconName)
		local tab = {}
		local T = self.Theme

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -8, 0, 42)
		btn.BackgroundColor3 = T.Card
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.ZIndex = 5
		btn.Parent = tabScroll
		Corner(btn, 10)

		local hi = Instance.new("Frame")
		hi.Size = UDim2.new(0, 3, 0.5, 0)
		hi.Position = UDim2.new(0, 6, 0.25, 0)
		hi.BackgroundColor3 = T.Accent
		hi.BackgroundTransparency = 1
		hi.BorderSizePixel = 0
		hi.ZIndex = 6
		hi.Parent = btn
		Corner(hi, 2)

		local ic
		local xOff = 14
		local iid = Icon(iconName)
		if iid then
			ic = Instance.new("ImageLabel")
			ic.Size = UDim2.new(0, 18, 0, 18)
			ic.Position = UDim2.new(0, 16, 0.5, -9)
			ic.BackgroundTransparency = 1
			ic.Image = iid
			ic.ImageColor3 = T.Text3
			ic.ZIndex = 6
			ic.Parent = btn
			xOff = 42
		end

		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1, -xOff - 8, 1, 0)
		tl.Position = UDim2.new(0, xOff, 0, 0)
		tl.BackgroundTransparency = 1
		tl.Text = name
		tl.TextColor3 = T.Text3
		tl.TextSize = 15
		tl.Font = Enum.Font.GothamMedium
		tl.TextXAlignment = Enum.TextXAlignment.Left
		tl.ZIndex = 6
		tl.Parent = btn

		local content = Instance.new("ScrollingFrame")
		content.Size = UDim2.new(1, -200, 1, -76)
		content.Position = UDim2.new(0, 190, 0, 66)
		content.BackgroundTransparency = 1
		content.BorderSizePixel = 0
		content.ScrollBarThickness = 4
		content.CanvasSize = UDim2.new(0, 0, 0, 0)
		content.Visible = false
		content.ZIndex = 3
		content.Parent = main

		local cl = Instance.new("UIListLayout")
		cl.Padding = UDim.new(0, 8)
		cl.Parent = content
		Pad(content, 6, 16, 4, 10)
		cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			content.CanvasSize = UDim2.new(0, 0, 0, cl.AbsoluteContentSize.Y + 24)
		end)

		local function activate()
			for _, t in ipairs(self.Tabs) do
				t.Content.Visible = false
				t.Btn.BackgroundTransparency = 1
				t.Label.TextColor3 = T.Text3
				t.Hi.BackgroundTransparency = 1
				if t.Icon then t.Icon.ImageColor3 = T.Text3 end
			end
			content.Visible = true
			btn.BackgroundTransparency = 0.3
			tl.TextColor3 = T.Text
			hi.BackgroundTransparency = 0
			if ic then ic.ImageColor3 = T.Text end
			local i = 0
			for _, ch in ipairs(content:GetChildren()) do
				if ch:IsA("Frame") then
					i += 1
					ch.Position = UDim2.new(0, 0, 0, 18)
					local tt = ch.Name == "Divider" and 1 or 0.1
					ch.BackgroundTransparency = 1
					task.delay(i * 0.03, function()
						Tween(ch, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = tt }, 0.28)
					end)
				end
			end
		end

		btn.MouseButton1Click:Connect(activate)
		tab.Btn, tab.Content, tab.Label, tab.Hi, tab.Icon = btn, content, tl, hi, ic
		table.insert(self.Tabs, tab)
		if #self.Tabs == 1 then activate() end

		local function LockBadge(parent, text)
			local b = Instance.new("Frame")
			b.Name = "LockedBadge"
			b.AutomaticSize = Enum.AutomaticSize.X
			b.Size = UDim2.new(0, 0, 0, 24)
			b.Position = UDim2.new(0, 150, 0.5, -12)
			b.BackgroundColor3 = T.Bg
			b.BackgroundTransparency = 0.1
			b.Visible = false
			b.ZIndex = 20
			b.Parent = parent
			Corner(b, 6)
			Stroke(b, Color3.fromRGB(255, 255, 255), 1).Transparency = 0.3
			Pad(b, 0, 0, 8, 10)
			local lay = Instance.new("UIListLayout")
			lay.FillDirection = Enum.FillDirection.Horizontal
			lay.VerticalAlignment = Enum.VerticalAlignment.Center
			lay.Padding = UDim.new(0, 5)
			lay.Parent = b
			local li = Instance.new("ImageLabel")
			li.Size = UDim2.new(0, 13, 0, 13)
			li.BackgroundTransparency = 1
			li.Image = Icon("lock") or "rbxassetid://10734943674"
			li.ImageColor3 = Color3.fromRGB(255, 255, 255)
			li.ZIndex = 21
			li.Parent = b
			local lt = Instance.new("TextLabel")
			lt.AutomaticSize = Enum.AutomaticSize.X
			lt.Size = UDim2.new(0, 0, 0, 16)
			lt.BackgroundTransparency = 1
			lt.Text = text or "Locked"
			lt.TextColor3 = Color3.fromRGB(255, 255, 255)
			lt.TextSize = 13
			lt.Font = Enum.Font.GothamMedium
			lt.ZIndex = 21
			lt.Parent = b
			return b, lt
		end

		local function Card()
			local f = Instance.new("Frame")
			f.Size = UDim2.new(1, 0, 0, 48)
			f.BackgroundColor3 = T.Card
			f.BackgroundTransparency = 0.1
			f.BorderSizePixel = 0
			f.ZIndex = 4
			f.Parent = content
			Corner(f, 10)
			Stroke(f, T.Stroke, 1)
			return f
		end

		function tab:create_button(index)
			local locked = index.Locked or false
			local f = Card()
			f.Name = "Button"
			local accent = Instance.new("Frame")
			accent.Size = UDim2.new(0, 3, 0.5, 0)
			accent.Position = UDim2.new(0, 10, 0.25, 0)
			accent.BackgroundColor3 = T.Accent
			accent.BackgroundTransparency = 0.4
			accent.BorderSizePixel = 0
			accent.ZIndex = 5
			accent.Parent = f
			Corner(accent, 2)
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -60, 1, 0)
			lbl.Position = UDim2.new(0, 22, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = index.Title or index.title or "Button"
			lbl.TextColor3 = T.Text
			lbl.TextSize = 16
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 5
			lbl.Parent = f
			local arrow = Instance.new("ImageLabel")
			arrow.Size = UDim2.new(0, 16, 0, 16)
			arrow.Position = UDim2.new(1, -32, 0.5, -8)
			arrow.BackgroundTransparency = 1
			arrow.Image = Icon("chevron-right") or "rbxassetid://10709791437"
			arrow.ImageColor3 = T.Text2
			arrow.ZIndex = 5
			arrow.Parent = f
			local badge = LockBadge(f, index.LockedText or "Locked")
			badge.Visible = locked
			local hit = Instance.new("TextButton")
			hit.Size = UDim2.new(1, 0, 1, 0)
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.ZIndex = 6
			hit.Parent = f
			hit.MouseEnter:Connect(function()
				if not locked then Tween(f, { BackgroundColor3 = T.CardHover }, 0.15) end
			end)
			hit.MouseLeave:Connect(function()
				Tween(f, { BackgroundColor3 = T.Card }, 0.15)
			end)
			hit.MouseButton1Click:Connect(function()
				if locked then return end
				Tween(f, { BackgroundColor3 = T.CardHover }, 0.08)
				task.delay(0.1, function() Tween(f, { BackgroundColor3 = T.Card }, 0.18) end)
				local cb = index.callback or index.Callback
				if cb then cb() end
			end)
			local api = {}
			function api:SetLocked(v, text)
				locked = v
				badge.Visible = v
				if text then local l = badge:FindFirstChildOfClass("TextLabel") if l then l.Text = text end end
			end
			function api:Lock(t) api:SetLocked(true, t) end
			function api:Unlock() api:SetLocked(false) end
			table.insert(Lib.Elements, { Name = index.Title or index.title or "Button", Frame = f })
			return api
		end

		function tab:create_toggle(index)
			local locked = index.Locked or false
			local on = index.default or index.Value or false
			local flag = index.Flag
			if flag and Lib.Flags[flag] ~= nil then on = Lib.Flags[flag] end
			local cb = index.callback or index.Callback or function() end
			local f = Card()
			f.Name = "Toggle"
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -80, 1, 0)
			lbl.Position = UDim2.new(0, 16, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = index.Title or index.title or "Toggle"
			lbl.TextColor3 = T.Text
			lbl.TextSize = 16
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 5
			lbl.Parent = f
			local track = Instance.new("Frame")
			track.Size = UDim2.new(0, 50, 0, 28)
			track.Position = UDim2.new(1, -64, 0.5, -14)
			track.BackgroundColor3 = on and T.On or T.Off
			track.BorderSizePixel = 0
			track.ZIndex = 5
			track.Parent = f
			Corner(track, 14)
			Stroke(track, T.Stroke, 1)
			local knob = Instance.new("Frame")
			knob.Size = UDim2.new(0, 22, 0, 22)
			knob.Position = on and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
			knob.BackgroundColor3 = on and T.Knob or T.Text
			knob.BorderSizePixel = 0
			knob.ZIndex = 6
			knob.Parent = track
			Corner(knob, 11)
			local badge = LockBadge(f, index.LockedText or "Locked")
			badge.Visible = locked
			local function set(v, fire)
				if locked then return end
				on = v
				Tween(track, { BackgroundColor3 = on and T.On or T.Off }, 0.22)
				Tween(knob, {
					Position = on and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11),
					BackgroundColor3 = on and T.Knob or T.Text,
				}, 0.22)
				Lib:SetFlag(flag, on)
				if fire ~= false then cb(on) end
			end
			local hit = Instance.new("TextButton")
			hit.Size = UDim2.new(1, 0, 1, 0)
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.ZIndex = 7
			hit.Parent = f
			hit.MouseButton1Click:Connect(function() set(not on) end)
			local api = {}
			function api:Set(v) set(v) end
			function api:Get() return on end
			function api:SetLocked(v, text)
				locked = v
				badge.Visible = v
				if text then local l = badge:FindFirstChildOfClass("TextLabel") if l then l.Text = text end end
			end
			function api:Lock(t) api:SetLocked(true, t) end
			function api:Unlock() api:SetLocked(false) end
			if flag then Lib:SetFlag(flag, on) end
			table.insert(Lib.Elements, { Name = index.Title or index.title or "Toggle", Frame = f })
			return api
		end

		function tab:create_checkbox(index)
			return self:create_toggle(index)
		end

		function tab:create_divider(text)
			local f = Instance.new("Frame")
			f.Name = "Divider"
			f.Size = UDim2.new(1, 0, 0, 28)
			f.BackgroundTransparency = 1
			f.ZIndex = 4
			f.Parent = content
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -8, 1, 0)
			lbl.Position = UDim2.new(0, 4, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text or ""
			lbl.TextColor3 = T.Text3
			lbl.TextSize = 14
			lbl.Font = Enum.Font.GothamBold
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 5
			lbl.Parent = f
			table.insert(Lib.Elements, { Name = text or "", Frame = f })
		end

		function tab:create_slider(index)
			local locked = index.Locked or false
			local min = index.Min or index.minimum or 0
			local max = index.Max or index.maximum or 100
			local value = index.default or index.Value or min
			local step = index.Step or index.rounding or 0
			local flag = index.Flag
			if flag and Lib.Flags[flag] ~= nil then value = Lib.Flags[flag] end
			local cb = index.callback or index.Callback or function() end
			local f = Card()
			f.Name = "Slider"
			f.Size = UDim2.new(1, 0, 0, 60)
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0.6, 0, 0, 22)
			lbl.Position = UDim2.new(0, 16, 0, 8)
			lbl.BackgroundTransparency = 1
			lbl.Text = index.Title or index.title or "Slider"
			lbl.TextColor3 = T.Text
			lbl.TextSize = 16
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 5
			lbl.Parent = f
			local val = Instance.new("TextLabel")
			val.Size = UDim2.new(0.3, 0, 0, 22)
			val.Position = UDim2.new(0.68, 0, 0, 8)
			val.BackgroundTransparency = 1
			val.Text = tostring(value)
			val.TextColor3 = T.Text2
			val.TextSize = 15
			val.Font = Enum.Font.GothamMedium
			val.TextXAlignment = Enum.TextXAlignment.Right
			val.ZIndex = 5
			val.Parent = f
			local bg = Instance.new("Frame")
			bg.Size = UDim2.new(1, -32, 0, 6)
			bg.Position = UDim2.new(0, 16, 1, -18)
			bg.BackgroundColor3 = T.Off
			bg.BorderSizePixel = 0
			bg.ZIndex = 5
			bg.Parent = f
			Corner(bg, 3)
			local fill = Instance.new("Frame")
			fill.Size = UDim2.new(math.clamp((value - min) / math.max(max - min, 1), 0, 1), 0, 1, 0)
			fill.BackgroundColor3 = T.Accent
			fill.BorderSizePixel = 0
			fill.ZIndex = 6
			fill.Parent = bg
			Corner(fill, 3)
			local ball = Instance.new("Frame")
			ball.Size = UDim2.new(0, 16, 0, 16)
			ball.Position = UDim2.new(1, -8, 0.5, -8)
			ball.BackgroundColor3 = T.Accent
			ball.BorderSizePixel = 0
			ball.ZIndex = 7
			ball.Parent = fill
			Corner(ball, 8)
			Stroke(ball, T.Stroke, 1)
			local hit = Instance.new("Frame")
			hit.Size = UDim2.new(1, 0, 0, 24)
			hit.Position = UDim2.new(0, 0, 0.5, -12)
			hit.BackgroundTransparency = 1
			hit.ZIndex = 8
			hit.Parent = bg
			local badge = LockBadge(f, index.LockedText or "Locked")
			badge.Visible = locked
			local drag = false
			local function apply(input)
				if locked then return end
				local p = math.clamp((input.Position.X - bg.AbsolutePosition.X) / math.max(bg.AbsoluteSize.X, 1), 0, 1)
				value = min + (max - min) * p
				if step > 0 then value = math.floor(value / step + 0.5) * step else value = math.floor(value) end
				value = math.clamp(value, min, max)
				val.Text = tostring(value)
				Tween(fill, { Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0) }, 0.08)
				Lib:SetFlag(flag, value)
				cb(value)
			end
			hit.InputBegan:Connect(function(input)
				if locked then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					drag = true
					apply(input)
				end
			end)
			UIS.InputChanged:Connect(function(input)
				if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					apply(input)
				end
			end)
			UIS.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					drag = false
				end
			end)
			local api = {}
			function api:Set(v)
				value = math.clamp(v, min, max)
				val.Text = tostring(value)
				fill.Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0)
				Lib:SetFlag(flag, value)
				cb(value)
			end
			function api:SetLocked(v) locked = v badge.Visible = v end
			function api:Lock() api:SetLocked(true) end
			function api:Unlock() api:SetLocked(false) end
			if flag then Lib:SetFlag(flag, value) end
			table.insert(Lib.Elements, { Name = index.Title or index.title or "Slider", Frame = f })
			return api
		end

		function tab:create_textbox(index)
			local locked = index.Locked or false
			local f = Card()
			f.Name = "Textbox"
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0, 120, 1, 0)
			lbl.Position = UDim2.new(0, 16, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = index.Title or index.title or "Input"
			lbl.TextColor3 = T.Text
			lbl.TextSize = 16
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 5
			lbl.Parent = f
			local boxF = Instance.new("Frame")
			boxF.Size = UDim2.new(0, 200, 0, 32)
			boxF.Position = UDim2.new(1, -216, 0.5, -16)
			boxF.BackgroundColor3 = T.Bg
			boxF.BorderSizePixel = 0
			boxF.ZIndex = 5
			boxF.Parent = f
			Corner(boxF, 8)
			Stroke(boxF, T.Stroke, 1)
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(1, -14, 1, 0)
			box.Position = UDim2.new(0, 8, 0, 0)
			box.BackgroundTransparency = 1
			box.PlaceholderText = index.Placeholder or index.placeholder or ""
			box.PlaceholderColor3 = T.Text3
			box.Text = ""
			box.TextColor3 = T.Text
			box.TextSize = 14
			box.Font = Enum.Font.Gotham
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.ClearTextOnFocus = false
			box.ZIndex = 6
			box.Parent = boxF
			local badge = LockBadge(f, index.LockedText or "Locked")
			badge.Visible = locked
			box.FocusLost:Connect(function(enter)
				if locked then return end
				if enter then
					local cb = index.callback or index.Callback
					if cb then cb(box.Text) end
				end
			end)
			local api = {}
			function api:Set(t) box.Text = t end
			function api:SetLocked(v) locked = v badge.Visible = v end
			function api:Lock() api:SetLocked(true) end
			function api:Unlock() api:SetLocked(false) end
			table.insert(Lib.Elements, { Name = index.Title or index.title or "Input", Frame = f })
			return api
		end

		function tab:create_dropdown(index)
			local opts = index.options or index.Values or {}
			local multi = index.multi_selection or index.Multi or false
			local selected = multi and (type(index.default or index.Value) == "table" and (index.default or index.Value) or {}) or (index.default or index.Value or opts[1] or "--")
			local cb = index.callback or index.Callback or function() end
			local locked = index.Locked or false
			local open = false
			local f = Card()
			f.Name = "Dropdown"
			f.ZIndex = 10
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0, 150, 1, 0)
			lbl.Position = UDim2.new(0, 16, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = index.Title or index.title or "Dropdown"
			lbl.TextColor3 = T.Text
			lbl.TextSize = 16
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 11
			lbl.Parent = f
			local drop = Instance.new("Frame")
			drop.Size = UDim2.new(0, 160, 0, 32)
			drop.Position = UDim2.new(1, -176, 0.5, -16)
			drop.BackgroundColor3 = T.Bg
			drop.BorderSizePixel = 0
			drop.ClipsDescendants = true
			drop.ZIndex = 12
			drop.Parent = f
			Corner(drop, 8)
			Stroke(drop, T.Stroke, 1)
			local function disp()
				if multi then return #selected == 0 and "--" or table.concat(selected, ", ") end
				return selected
			end
			local sel = Instance.new("TextLabel")
			sel.Size = UDim2.new(1, -34, 1, 0)
			sel.Position = UDim2.new(0, 10, 0, 0)
			sel.BackgroundTransparency = 1
			sel.Text = disp()
			sel.TextColor3 = T.Text
			sel.TextSize = 14
			sel.Font = Enum.Font.Gotham
			sel.TextXAlignment = Enum.TextXAlignment.Left
			sel.TextTruncate = Enum.TextTruncate.AtEnd
			sel.ZIndex = 13
			sel.Parent = drop
			local arr = Instance.new("ImageLabel")
			arr.Size = UDim2.new(0, 14, 0, 14)
			arr.Position = UDim2.new(1, -24, 0.5, -7)
			arr.BackgroundTransparency = 1
			arr.Image = Icon("chevron-down") or "rbxassetid://10709790948"
			arr.ImageColor3 = T.Text3
			arr.ZIndex = 13
			arr.Parent = drop
			local list = Instance.new("ScrollingFrame")
			list.Size = UDim2.new(1, 0, 0, 0)
			list.Position = UDim2.new(0, 0, 0, 34)
			list.BackgroundTransparency = 1
			list.BorderSizePixel = 0
			list.ScrollBarThickness = 3
			list.CanvasSize = UDim2.new(0, 0, 0, 0)
			list.ZIndex = 14
			list.Parent = drop
			local ll = Instance.new("UIListLayout")
			ll.Padding = UDim.new(0, 2)
			ll.Parent = list
			for _, opt in ipairs(opts) do
				local ob = Instance.new("TextButton")
				ob.Size = UDim2.new(1, -8, 0, 30)
				ob.BackgroundColor3 = T.Card
				ob.BackgroundTransparency = 0.2
				ob.Text = "  " .. opt
				ob.TextColor3 = T.Text2
				ob.TextSize = 14
				ob.Font = Enum.Font.Gotham
				ob.TextXAlignment = Enum.TextXAlignment.Left
				ob.ZIndex = 15
				ob.Parent = list
				Corner(ob, 6)
				ob.MouseButton1Click:Connect(function()
					if locked then return end
					if multi then
						local i = table.find(selected, opt)
						if i then table.remove(selected, i) ob.TextColor3 = T.Text2
						else table.insert(selected, opt) ob.TextColor3 = T.Text end
						sel.Text = disp()
						cb(selected)
					else
						selected = opt
						sel.Text = opt
						cb(opt)
						open = false
						Tween(drop, { Size = UDim2.new(0, 160, 0, 32) }, 0.2)
						Tween(arr, { Rotation = 0 }, 0.2)
						list.Size = UDim2.new(1, 0, 0, 0)
					end
				end)
			end
			ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				list.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y)
			end)
			local badge = LockBadge(f, index.LockedText or "Locked")
			badge.Visible = locked
			local openBtn = Instance.new("TextButton")
			openBtn.Size = UDim2.new(1, 0, 0, 32)
			openBtn.BackgroundTransparency = 1
			openBtn.Text = ""
			openBtn.ZIndex = 14
			openBtn.Parent = drop
			openBtn.MouseButton1Click:Connect(function()
				if locked then return end
				open = not open
				local h = math.min(#opts * 32, 160)
				if open then
					list.Size = UDim2.new(1, 0, 0, h)
					Tween(drop, { Size = UDim2.new(0, 160, 0, 36 + h) }, 0.25)
					Tween(arr, { Rotation = 180 }, 0.25)
				else
					Tween(drop, { Size = UDim2.new(0, 160, 0, 32) }, 0.2)
					Tween(arr, { Rotation = 0 }, 0.2)
					list.Size = UDim2.new(1, 0, 0, 0)
				end
			end)
			local api = {}
			function api:Set(v) selected = v sel.Text = disp() cb(selected) end
			function api:SetLocked(v) locked = v badge.Visible = v end
			function api:Lock() api:SetLocked(true) end
			function api:Unlock() api:SetLocked(false) end
			table.insert(Lib.Elements, { Name = index.Title or index.title or "Dropdown", Frame = f })
			return api
		end

		function tab:create_keybind(index)
			local cur = index.default or index.Value or Enum.KeyCode.E
			if type(cur) == "string" then cur = Enum.KeyCode[cur] or Enum.KeyCode.E end
			local cb = index.callback or index.Callback or function() end
			local flag = index.Flag
			local f = Card()
			f.Name = "Keybind"
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -110, 1, 0)
			lbl.Position = UDim2.new(0, 16, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = index.Title or index.title or "Keybind"
			lbl.TextColor3 = T.Text
			lbl.TextSize = 16
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 5
			lbl.Parent = f
			local kb = Instance.new("TextButton")
			kb.Size = UDim2.new(0, 88, 0, 30)
			kb.Position = UDim2.new(1, -104, 0.5, -15)
			kb.BackgroundColor3 = T.Bg
			kb.Text = cur.Name
			kb.TextColor3 = T.Text
			kb.TextSize = 14
			kb.Font = Enum.Font.GothamMedium
			kb.ZIndex = 6
			kb.Parent = f
			Corner(kb, 8)
			Stroke(kb, T.Stroke, 1)
			kb.MouseButton1Click:Connect(function()
				kb.Text = "..."
				local c
				c = UIS.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if input.UserInputType == Enum.UserInputType.Keyboard then
						cur = input.KeyCode
						kb.Text = cur.Name
						Lib:SetFlag(flag, cur.Name)
						cb(cur)
						c:Disconnect()
					end
				end)
			end)
			local api = {}
			function api:Set(k)
				if type(k) == "string" then k = Enum.KeyCode[k] end
				cur = k
				kb.Text = cur.Name
			end
			function api:Get() return cur end
			table.insert(Lib.Elements, { Name = index.Title or index.title or "Keybind", Frame = f })
			return api
		end

		function tab:create_paragraph(index)
			local f = Instance.new("Frame")
			f.Name = "Paragraph"
			f.Size = UDim2.new(1, 0, 0, 0)
			f.AutomaticSize = Enum.AutomaticSize.Y
			f.BackgroundColor3 = T.Card
			f.BackgroundTransparency = 0.1
			f.BorderSizePixel = 0
			f.ZIndex = 4
			f.Parent = content
			Corner(f, 10)
			Stroke(f, T.Stroke, 1)
			Pad(f, 14, 14, 16, 16)
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, 0, 0, 20)
			title.BackgroundTransparency = 1
			title.Text = index.Title or index.title or ""
			title.TextColor3 = T.Text
			title.TextSize = 16
			title.Font = Enum.Font.GothamMedium
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.ZIndex = 5
			title.Parent = f
			local body = Instance.new("TextLabel")
			body.Size = UDim2.new(1, 0, 0, 0)
			body.Position = UDim2.new(0, 0, 0, 24)
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.BackgroundTransparency = 1
			body.Text = index.Content or index.content or index.Desc or ""
			body.TextColor3 = T.Text2
			body.TextSize = 14
			body.Font = Enum.Font.Gotham
			body.TextXAlignment = Enum.TextXAlignment.Left
			body.TextYAlignment = Enum.TextYAlignment.Top
			body.TextWrapped = true
			body.ZIndex = 5
			body.Parent = f
			table.insert(Lib.Elements, { Name = index.Title or index.title or "Paragraph", Frame = f })
		end

		function tab:create_imageparagraph(index)
			local f = Instance.new("Frame")
			f.Name = "ImageParagraph"
			f.Size = UDim2.new(1, 0, 0, 0)
			f.AutomaticSize = Enum.AutomaticSize.Y
			f.BackgroundColor3 = T.Card
			f.BackgroundTransparency = 0.1
			f.BorderSizePixel = 0
			f.ZIndex = 4
			f.Parent = content
			Corner(f, 10)
			Stroke(f, T.Stroke, 1)
			Pad(f, 14, 14, 16, 16)
			local img = Instance.new("ImageLabel")
			img.Size = UDim2.new(0, 42, 0, 42)
			img.BackgroundTransparency = 1
			img.Image = Icon(index.Image) or Icon("image") or "rbxassetid://10734943674"
			img.ImageColor3 = T.Text
			img.ZIndex = 5
			img.Parent = f
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -56, 0, 20)
			title.Position = UDim2.new(0, 52, 0, 2)
			title.BackgroundTransparency = 1
			title.Text = index.Title or index.title or ""
			title.TextColor3 = T.Text
			title.TextSize = 16
			title.Font = Enum.Font.GothamMedium
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.ZIndex = 5
			title.Parent = f
			local body = Instance.new("TextLabel")
			body.Size = UDim2.new(1, -56, 0, 0)
			body.Position = UDim2.new(0, 52, 0, 24)
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.BackgroundTransparency = 1
			body.Text = index.Content or index.content or index.Desc or ""
			body.TextColor3 = T.Text2
			body.TextSize = 14
			body.Font = Enum.Font.Gotham
			body.TextXAlignment = Enum.TextXAlignment.Left
			body.TextWrapped = true
			body.ZIndex = 5
			body.Parent = f
			table.insert(Lib.Elements, { Name = index.Title or index.title or "ImageParagraph", Frame = f })
		end

		function tab:create_colorpicker(index)
			local locked = index.Locked or false
			local color = index.default or index.Value or Color3.fromRGB(255, 255, 255)
			local cb = index.callback or index.Callback or function() end
			local flag = index.Flag
			local open = false
			local f = Card()
			f.Name = "Colorpicker"
			f.ClipsDescendants = false
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -70, 1, 0)
			lbl.Position = UDim2.new(0, 16, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = index.Title or index.title or "Color"
			lbl.TextColor3 = T.Text
			lbl.TextSize = 16
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 5
			lbl.Parent = f
			local prev = Instance.new("TextButton")
			prev.Size = UDim2.new(0, 30, 0, 30)
			prev.Position = UDim2.new(1, -46, 0.5, -15)
			prev.BackgroundColor3 = color
			prev.Text = ""
			prev.ZIndex = 5
			prev.Parent = f
			Corner(prev, 8)
			Stroke(prev, Color3.fromRGB(255, 255, 255), 1)
			local picker = Instance.new("Frame")
			picker.Size = UDim2.new(0, 190, 0, 0)
			picker.Position = UDim2.new(1, -200, 0, 52)
			picker.BackgroundColor3 = T.Bg2
			picker.Visible = false
			picker.ClipsDescendants = true
			picker.ZIndex = 25
			picker.Parent = f
			Corner(picker, 10)
			Stroke(picker, Color3.fromRGB(255, 255, 255), 1)
			local sat = Instance.new("ImageLabel")
			sat.Size = UDim2.new(0, 150, 0, 100)
			sat.Position = UDim2.new(0, 10, 0, 10)
			sat.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			sat.Image = "rbxassetid://4155801252"
			sat.ZIndex = 26
			sat.Parent = picker
			Corner(sat, 6)
			local hue = Instance.new("ImageLabel")
			hue.Size = UDim2.new(0, 14, 0, 100)
			hue.Position = UDim2.new(0, 166, 0, 10)
			hue.Image = "rbxassetid://6523285904"
			hue.ZIndex = 26
			hue.Parent = picker
			Corner(hue, 4)
			local h, s, v = Color3.toHSV(color)
			local function apply()
				color = Color3.fromHSV(h, s, v)
				prev.BackgroundColor3 = color
				sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				Lib:SetFlag(flag, { math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255) })
				cb(color)
			end
			local dS, dH = false, false
			sat.InputBegan:Connect(function(input)
				if locked then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dS = true
					local r = Vector2.new(input.Position.X - sat.AbsolutePosition.X, input.Position.Y - sat.AbsolutePosition.Y)
					s = math.clamp(r.X / math.max(sat.AbsoluteSize.X, 1), 0, 1)
					v = 1 - math.clamp(r.Y / math.max(sat.AbsoluteSize.Y, 1), 0, 1)
					apply()
				end
			end)
			hue.InputBegan:Connect(function(input)
				if locked then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dH = true
					h = math.clamp((input.Position.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
					apply()
				end
			end)
			UIS.InputChanged:Connect(function(input)
				if dS and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local r = Vector2.new(input.Position.X - sat.AbsolutePosition.X, input.Position.Y - sat.AbsolutePosition.Y)
					s = math.clamp(r.X / math.max(sat.AbsoluteSize.X, 1), 0, 1)
					v = 1 - math.clamp(r.Y / math.max(sat.AbsoluteSize.Y, 1), 0, 1)
					apply()
				end
				if dH and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					h = math.clamp((input.Position.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
					apply()
				end
			end)
			UIS.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dS, dH = false, false
				end
			end)
			local badge = LockBadge(f, index.LockedText or "Locked")
			badge.Visible = locked
			prev.MouseButton1Click:Connect(function()
				if locked then return end
				open = not open
				picker.Visible = open
				if open then
					Tween(picker, { Size = UDim2.new(0, 190, 0, 120) }, 0.25)
					Tween(f, { Size = UDim2.new(1, 0, 0, 180) }, 0.25)
				else
					Tween(picker, { Size = UDim2.new(0, 190, 0, 0) }, 0.2)
					Tween(f, { Size = UDim2.new(1, 0, 0, 48) }, 0.2)
					task.delay(0.2, function() picker.Visible = false end)
				end
			end)
			local api = {}
			function api:Set(c) color = c h, s, v = Color3.toHSV(c) apply() end
			function api:Get() return color end
			function api:SetLocked(v) locked = v badge.Visible = v end
			function api:Lock() api:SetLocked(true) end
			function api:Unlock() api:SetLocked(false) end
			table.insert(Lib.Elements, { Name = index.Title or index.title or "Color", Frame = f })
			return api
		end

		function tab:create_codebox(index)
			local code = index.Code or index.code or "-- code"
			local title = index.Title or index.title or "Code"
			local f = Instance.new("Frame")
			f.Name = "Codebox"
			f.Size = UDim2.new(1, 0, 0, 170)
			f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
			f.BorderSizePixel = 0
			f.ZIndex = 4
			f.Parent = content
			Corner(f, 10)
			Stroke(f, T.Stroke, 1)
			local top = Instance.new("Frame")
			top.Size = UDim2.new(1, 0, 0, 34)
			top.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
			top.BorderSizePixel = 0
			top.ZIndex = 5
			top.Parent = f
			Corner(top, 10)
			for i, col in ipairs({ Color3.fromRGB(255, 95, 87), Color3.fromRGB(255, 189, 46), Color3.fromRGB(39, 201, 63) }) do
				local c = Instance.new("Frame")
				c.Size = UDim2.new(0, 11, 0, 11)
				c.Position = UDim2.new(0, 10 + (i - 1) * 18, 0.5, -5)
				c.BackgroundColor3 = col
				c.BorderSizePixel = 0
				c.ZIndex = 6
				c.Parent = top
				Corner(c, 6)
			end
			local tl = Instance.new("TextLabel")
			tl.Size = UDim2.new(1, -170, 1, 0)
			tl.Position = UDim2.new(0, 68, 0, 0)
			tl.BackgroundTransparency = 1
			tl.Text = title
			tl.TextColor3 = T.Text2
			tl.TextSize = 13
			tl.Font = Enum.Font.GothamMedium
			tl.TextXAlignment = Enum.TextXAlignment.Left
			tl.ZIndex = 6
			tl.Parent = top
			if index.Copyable ~= false then
				local copy = Instance.new("TextButton")
				copy.Size = UDim2.new(0, 56, 0, 24)
				copy.Position = UDim2.new(1, -128, 0.5, -12)
				copy.BackgroundColor3 = T.Card
				copy.Text = "Copy"
				copy.TextColor3 = T.Text
				copy.TextSize = 13
				copy.Font = Enum.Font.GothamMedium
				copy.ZIndex = 7
				copy.Parent = top
				Corner(copy, 6)
				Stroke(copy, T.Stroke, 1)
				copy.MouseButton1Click:Connect(function()
					pcall(function()
						if setclipboard then setclipboard(code) elseif toclipboard then toclipboard(code) end
					end)
					copy.Text = "Copied"
					task.delay(1.2, function() if copy.Parent then copy.Text = "Copy" end end)
				end)
			end
			if index.Runnable ~= false then
				local run = Instance.new("TextButton")
				run.Size = UDim2.new(0, 56, 0, 24)
				run.Position = UDim2.new(1, -64, 0.5, -12)
				run.BackgroundColor3 = T.Card
				run.Text = "Run"
				run.TextColor3 = T.Text
				run.TextSize = 13
				run.Font = Enum.Font.GothamMedium
				run.ZIndex = 7
				run.Parent = top
				Corner(run, 6)
				Stroke(run, T.Stroke, 1)
				run.MouseButton1Click:Connect(function()
					local fn, err = loadstring(code)
					if fn then task.spawn(fn) if index.OnRun then index.OnRun() end
					else Lib:Notify({ title = "Code Error", content = tostring(err), duration = 4 }) end
				end)
			end
			local sc = Instance.new("ScrollingFrame")
			sc.Size = UDim2.new(1, -16, 1, -42)
			sc.Position = UDim2.new(0, 8, 0, 38)
			sc.BackgroundTransparency = 1
			sc.BorderSizePixel = 0
			sc.ScrollBarThickness = 3
			sc.CanvasSize = UDim2.new(0, 0, 0, 0)
			sc.ZIndex = 5
			sc.Parent = f
			local codeLbl = Instance.new("TextLabel")
			codeLbl.Size = UDim2.new(1, -8, 0, 0)
			codeLbl.AutomaticSize = Enum.AutomaticSize.Y
			codeLbl.BackgroundTransparency = 1
			codeLbl.Text = code
			codeLbl.TextColor3 = Color3.fromRGB(210, 220, 230)
			codeLbl.TextSize = 14
			codeLbl.Font = Enum.Font.Code
			codeLbl.TextXAlignment = Enum.TextXAlignment.Left
			codeLbl.TextYAlignment = Enum.TextYAlignment.Top
			codeLbl.TextWrapped = true
			codeLbl.ZIndex = 6
			codeLbl.Parent = sc
			codeLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				sc.CanvasSize = UDim2.new(0, 0, 0, codeLbl.AbsoluteSize.Y + 8)
			end)
			local api = {}
			function api:Set(c) code = c codeLbl.Text = c end
			function api:Get() return code end
			table.insert(Lib.Elements, { Name = title, Frame = f })
			return api
		end

		function tab:create_module(index)
			local on = index.default or false
			local cb = index.callback or function() end
			local mod = { Elements = {} }
			local f = Card()
			f.Name = "Module"
			f.ClipsDescendants = false
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -80, 0, 48)
			lbl.Position = UDim2.new(0, 16, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = index.Title or index.title or "Module"
			lbl.TextColor3 = T.Text
			lbl.TextSize = 16
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 5
			lbl.Parent = f
			local track = Instance.new("Frame")
			track.Size = UDim2.new(0, 50, 0, 28)
			track.Position = UDim2.new(1, -64, 0, 10)
			track.BackgroundColor3 = on and T.On or T.Off
			track.BorderSizePixel = 0
			track.ZIndex = 5
			track.Parent = f
			Corner(track, 14)
			Stroke(track, T.Stroke, 1)
			local knob = Instance.new("Frame")
			knob.Size = UDim2.new(0, 22, 0, 22)
			knob.Position = on and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
			knob.BackgroundColor3 = on and T.Knob or T.Text
			knob.BorderSizePixel = 0
			knob.ZIndex = 6
			knob.Parent = track
			Corner(knob, 11)
			local kids = Instance.new("Frame")
			kids.Size = UDim2.new(1, 0, 0, 0)
			kids.Position = UDim2.new(0, 0, 0, 52)
			kids.BackgroundTransparency = 1
			kids.Visible = false
			kids.ZIndex = 5
			kids.Parent = f
			local kl = Instance.new("UIListLayout")
			kl.Padding = UDim.new(0, 6)
			kl.Parent = kids
			local function height()
				local h = 48
				if on and #mod.Elements > 0 then
					for _, e in ipairs(mod.Elements) do h = h + e.Size.Y.Offset + 6 end
					h = h + 12
				end
				Tween(f, { Size = UDim2.new(1, 0, 0, h) }, 0.25)
			end
			local function set(v)
				on = v
				Tween(track, { BackgroundColor3 = on and T.On or T.Off }, 0.22)
				Tween(knob, {
					Position = on and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11),
					BackgroundColor3 = on and T.Knob or T.Text,
				}, 0.22)
				kids.Visible = on and #mod.Elements > 0
				height()
				cb(on)
			end
			local hit = Instance.new("TextButton")
			hit.Size = UDim2.new(1, -70, 0, 48)
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.ZIndex = 7
			hit.Parent = f
			hit.MouseButton1Click:Connect(function() set(not on) end)
			local th = Instance.new("TextButton")
			th.Size = UDim2.new(0, 50, 0, 28)
			th.Position = UDim2.new(1, -64, 0, 10)
			th.BackgroundTransparency = 1
			th.Text = ""
			th.ZIndex = 8
			th.Parent = f
			th.MouseButton1Click:Connect(function() set(not on) end)
			function mod:create_button(idx)
				local cf = Instance.new("Frame")
				cf.Size = UDim2.new(1, -16, 0, 36)
				cf.BackgroundColor3 = T.Bg
				cf.BackgroundTransparency = 0.2
				cf.BorderSizePixel = 0
				cf.Parent = kids
				Corner(cf, 8)
				local l = Instance.new("TextLabel")
				l.Size = UDim2.new(1, -12, 1, 0)
				l.Position = UDim2.new(0, 10, 0, 0)
				l.BackgroundTransparency = 1
				l.Text = idx.Title or idx.title or ""
				l.TextColor3 = T.Text2
				l.TextSize = 14
				l.Font = Enum.Font.Gotham
				l.TextXAlignment = Enum.TextXAlignment.Left
				l.Parent = cf
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, 0, 1, 0)
				b.BackgroundTransparency = 1
				b.Text = ""
				b.Parent = cf
				b.MouseButton1Click:Connect(function()
					local c = idx.callback or idx.Callback
					if c then c() end
				end)
				table.insert(mod.Elements, cf)
				if on then height() end
			end
			function mod:create_checkbox(idx)
				local cf = Instance.new("Frame")
				cf.Size = UDim2.new(1, -16, 0, 36)
				cf.BackgroundColor3 = T.Bg
				cf.BackgroundTransparency = 0.2
				cf.BorderSizePixel = 0
				cf.Parent = kids
				Corner(cf, 8)
				local l = Instance.new("TextLabel")
				l.Size = UDim2.new(1, -12, 1, 0)
				l.Position = UDim2.new(0, 10, 0, 0)
				l.BackgroundTransparency = 1
				l.Text = idx.Title or idx.title or ""
				l.TextColor3 = T.Text2
				l.TextSize = 14
				l.Font = Enum.Font.Gotham
				l.TextXAlignment = Enum.TextXAlignment.Left
				l.Parent = cf
				table.insert(mod.Elements, cf)
				if on then height() end
			end
			function mod:create_slider() end
			function mod:create_textbox() end
			function mod:create_dropdown() end
			function mod:create_divider() end
			table.insert(Lib.Elements, { Name = index.Title or index.title or "Module", Frame = f })
			return mod
		end

		return tab
	end

	return self
end

function Lib:CreateMultiButton(parent, index)
	local T = self.Theme
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 92)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 5
	frame.Parent = parent
	local buttons = index.Buttons or {}
	local function style(btn, text)
		btn.BackgroundColor3 = T.Card
		btn.BorderSizePixel = 0
		btn.Text = text or ""
		btn.TextColor3 = T.Text
		btn.TextSize = 15
		btn.Font = Enum.Font.GothamMedium
		btn.AutoButtonColor = false
		Corner(btn, 9)
		Stroke(btn, T.Stroke, 1)
		btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = T.CardHover }, 0.15) end)
		btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = T.Card }, 0.15) end)
	end
	if buttons[1] then
		local b1 = Instance.new("TextButton")
		b1.Size = UDim2.new(1, 0, 0, 40)
		b1.ZIndex = 6
		b1.Parent = frame
		style(b1, buttons[1].Title or "Button")
		b1.MouseButton1Click:Connect(function() if buttons[1].Callback then buttons[1].Callback() end end)
	end
	if buttons[2] then
		local b2 = Instance.new("TextButton")
		b2.Size = UDim2.new(0.5, -4, 0, 40)
		b2.Position = UDim2.new(0, 0, 0, 48)
		b2.ZIndex = 6
		b2.Parent = frame
		style(b2, buttons[2].Title or "Button")
		b2.MouseButton1Click:Connect(function() if buttons[2].Callback then buttons[2].Callback() end end)
	end
	if buttons[3] then
		local b3 = Instance.new("TextButton")
		b3.Size = UDim2.new(0.5, -4, 0, 40)
		b3.Position = UDim2.new(0.5, 4, 0, 48)
		b3.ZIndex = 6
		b3.Parent = frame
		style(b3, buttons[3].Title or "Button")
		b3.MouseButton1Click:Connect(function() if buttons[3].Callback then buttons[3].Callback() end end)
	end
	return frame
end

function Lib:OpenThemeEditor()
	local T = self.Theme
	local gui = self.Gui
	if not gui then return end
	local ov = Instance.new("Frame")
	ov.Size = UDim2.new(1, 0, 1, 0)
	ov.BackgroundColor3 = Color3.new(0, 0, 0)
	ov.BackgroundTransparency = 1
	ov.ZIndex = 450
	ov.Parent = gui
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 0, 0, 0)
	box.Position = UDim2.new(0.5, 0, 0.5, 0)
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.BackgroundColor3 = T.Bg2
	box.ZIndex = 451
	box.Parent = ov
	Corner(box, 14)
	Stroke(box, Color3.fromRGB(255, 255, 255), 1)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 28)
	title.Position = UDim2.new(0, 20, 0, 14)
	title.BackgroundTransparency = 1
	title.Text = "Theme Editor"
	title.TextColor3 = T.Text
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 452
	title.Parent = box
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -40, 0, 280)
	scroll.Position = UDim2.new(0, 20, 0, 50)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = 452
	scroll.Parent = box
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.Parent = scroll
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
	end)
	local tokens = { "Bg", "Bg2", "Card", "CardHover", "Stroke", "Text", "Text2", "Accent", "On", "Off" }
	local edits = {}
	for _, key in ipairs(tokens) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 38)
		row.BackgroundColor3 = T.Card
		row.BorderSizePixel = 0
		row.ZIndex = 453
		row.Parent = scroll
		Corner(row, 8)
		Stroke(row, T.Stroke, 1)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.5, 0, 1, 0)
		lbl.Position = UDim2.new(0, 12, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = key
		lbl.TextColor3 = T.Text
		lbl.TextSize = 15
		lbl.Font = Enum.Font.Gotham
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 454
		lbl.Parent = row
		local sw = Instance.new("TextButton")
		sw.Size = UDim2.new(0, 28, 0, 28)
		sw.Position = UDim2.new(1, -40, 0.5, -14)
		sw.BackgroundColor3 = T[key] or Color3.fromRGB(255, 255, 255)
		sw.Text = ""
		sw.ZIndex = 454
		sw.Parent = row
		Corner(sw, 6)
		Stroke(sw, Color3.fromRGB(255, 255, 255), 1)
		edits[key] = sw
		sw.MouseButton1Click:Connect(function()
			local hh, ss, vv = Color3.toHSV(sw.BackgroundColor3)
			sw.BackgroundColor3 = Color3.fromHSV((hh + 0.08) % 1, math.max(ss, 0.4), math.max(vv, 0.5))
		end)
	end
	local btnArea = Instance.new("Frame")
	btnArea.Size = UDim2.new(1, -40, 0, 92)
	btnArea.Position = UDim2.new(0, 20, 1, -104)
	btnArea.BackgroundTransparency = 1
	btnArea.ZIndex = 452
	btnArea.Parent = box
	local function close()
		Tween(ov, { BackgroundTransparency = 1 }, 0.2)
		Tween(box, { Size = UDim2.new(0, 0, 0, 0) }, 0.25).Completed:Connect(function() ov:Destroy() end)
	end
	self:CreateMultiButton(btnArea, {
		Buttons = {
			{
				Title = "Apply Theme",
				Callback = function()
					local custom = {}
					for k, v in pairs(T) do custom[k] = v end
					for k, sw in pairs(edits) do custom[k] = sw.BackgroundColor3 end
					Themes.Custom = custom
					self:SetTheme("Custom")
					self:Notify({ title = "Theme", content = "Custom applied", duration = 2 })
					close()
				end,
			},
			{ Title = "Reset Dark", Callback = function() self:SetTheme("Dark") close() end },
			{ Title = "Reset Light", Callback = function() self:SetTheme("Light") close() end },
		},
	})
	Tween(ov, { BackgroundTransparency = 0.5 }, 0.25)
	Tween(box, { Size = UDim2.new(0, 420, 0, 480) }, 0.35, Enum.EasingStyle.Back)
end

Lib.init = Lib.CreateWindow
return Lib
