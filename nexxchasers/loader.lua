local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local CoreGui = game:GetService("CoreGui")

local Flags = {}
local ConfigFolder = "NexxChasers"
local Themes = {
	index = {"Dark","Light"},
	Dark = {
		Background = Color3.fromRGB(15,15,15),
		Page = Color3.fromRGB(20,20,20),
		Main = Color3.fromRGB(0,122,255),
		Text = Color3.fromRGB(230,230,230),
		SubText = Color3.fromRGB(150,150,150),
		Stroke = Color3.fromRGB(40,40,40),
		Item = Color3.fromRGB(255,255,255),
		ItemTransparency = 0.935,
		Shadow = Color3.fromRGB(0,0,0)
	},
	Light = {
		Background = Color3.fromRGB(245,245,245),
		Page = Color3.fromRGB(255,255,255),
		Main = Color3.fromRGB(0,122,255),
		Text = Color3.fromRGB(20,20,20),
		SubText = Color3.fromRGB(80,80,80),
		Stroke = Color3.fromRGB(200,200,200),
		Item = Color3.fromRGB(0,0,0),
		ItemTransparency = 0.94,
		Shadow = Color3.fromRGB(180,180,180)
	}
}
local CurrentTheme = "Dark"
local IconList = {}
pcall(function()
	IconList = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/Icons/lucide.lua"))() or {}
end)

local function gl(i)
	if type(i) == "table" then return i end
	local d = IconList and IconList.Icons and IconList.Icons[i]
	if d then
		local ss = IconList.Spritesheets and IconList.Spritesheets[tostring(d.Image)]
		if ss then return {Image=ss,ImageRectSize=d.ImageRectSize,ImageRectPosition=d.ImageRectPosition} end
	end
	if type(i)=="string" and string.find(i,"rbxassetid://") then
		return {Image=i,ImageRectSize=Vector2.new(0,0),ImageRectPosition=Vector2.new(0,0)}
	elseif type(i)=="number" then
		return {Image="rbxassetid://"..i,ImageRectSize=Vector2.new(0,0),ImageRectPosition=Vector2.new(0,0)}
	elseif type(i)=="string" and tonumber(i) then
		return {Image="rbxassetid://"..i,ImageRectSize=Vector2.new(0,0),ImageRectPosition=Vector2.new(0,0)}
	end
	return {Image="rbxassetid://7733960981",ImageRectSize=Vector2.new(0,0),ImageRectPosition=Vector2.new(0,0)}
end

local function tw(obj,info,props)
	return TweenService:Create(obj,TweenInfo.new(info.t or 0.2,info.s or Enum.EasingStyle.Quad,info.d or Enum.EasingDirection.Out),props)
end

local function MakeDraggable(handle, object)
	local dragging, dragInput, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		tw(object,{t=0.15,s=Enum.EasingStyle.Quad},{Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)}):Play()
	end
	handle.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true dragStart=input.Position startPos=object.Position
			input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input==dragInput and dragging then update(input) end
	end)
end

local function CircleClick(Button, X, Y)
	task.spawn(function()
		Button.ClipsDescendants = true
		local Circle = Instance.new("ImageLabel")
		Circle.Image = "rbxassetid://266543268"
		Circle.ImageColor3 = Color3.fromRGB(80,80,80)
		Circle.ImageTransparency = 0.9
		Circle.BackgroundTransparency = 1
		Circle.ZIndex = 10
		Circle.Parent = Button
		local nx = X - Circle.AbsolutePosition.X
		local ny = Y - Circle.AbsolutePosition.Y
		Circle.Position = UDim2.new(0,nx,0,ny)
		local Size = math.max(Button.AbsoluteSize.X,Button.AbsoluteSize.Y)*1.5
		Circle:TweenSizeAndPosition(UDim2.new(0,Size,0,Size),UDim2.new(0.5,-Size/2,0.5,-Size/2),"Out","Quad",0.4,false,nil)
		for i=1,10 do Circle.ImageTransparency=Circle.ImageTransparency+0.01 task.wait(0.04) end
		Circle:Destroy()
	end)
end

local function makeLockBox(parent, text)
	local box = Instance.new("Frame")
	box.Name = "LockBox"
	box.Parent = parent
	box.BackgroundColor3 = Color3.fromRGB(28,28,28)
	box.BorderSizePixel = 0
	box.Size = UDim2.new(0,0,0,20)
	box.AutomaticSize = Enum.AutomaticSize.X
	box.Visible = false
	box.ZIndex = 15
	box.AnchorPoint = Vector2.new(1,0.5)
	box.Position = UDim2.new(1,-10,0.5,0)
	Instance.new("UICorner",box).CornerRadius = UDim.new(0,6)
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(0,122,255)
	st.Thickness = 1.2
	st.Transparency = 0.3
	st.Parent = box
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0,5)
	list.Parent = box
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0,8)
	pad.PaddingRight = UDim.new(0,8)
	pad.Parent = box
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(0,12,0,12)
	icon.Image = "rbxassetid://6031094678"
	icon.ImageColor3 = Color3.fromRGB(0,122,255)
	icon.Parent = box
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.Size = UDim2.new(0,0,1,0)
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = text or "Locked"
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.TextSize = 11
	lbl.Parent = box
	return box
end

local function addLockMethods(obj, frame)
	function obj:Lock(text)
		frame:SetAttribute("Locked", true)
		local existing = frame:FindFirstChild("LockBox")
		if existing then existing:Destroy() end
		local box = makeLockBox(frame, text or "Locked")
		box.Visible = true
	end
	function obj:Unlock()
		frame:SetAttribute("Locked", false)
		local b = frame:FindFirstChild("LockBox")
		if b then b:Destroy() end
	end
	function obj:SetLocked(bool, text)
		if bool then obj:Lock(text) else obj:Unlock() end
	end
end

local Library = {}

function Library:AddTheme(name, themeTable)
	Themes[name] = themeTable
	if not table.find(Themes.index, name) then
		table.insert(Themes.index, name)
	end
end

function Library:MakeNotify(NotifyConfig)
	NotifyConfig = NotifyConfig or {}
	NotifyConfig.Title = NotifyConfig.Title or "NexxChasers"
	NotifyConfig.Description = NotifyConfig.Description or NotifyConfig.Desc or ""
	NotifyConfig.Content = NotifyConfig.Content or NotifyConfig.Desc or ""
	NotifyConfig.Color = NotifyConfig.Color or Color3.fromRGB(0,122,255)
	NotifyConfig.Time = NotifyConfig.Time or 0.4
	NotifyConfig.Delay = NotifyConfig.Delay or NotifyConfig.Duration or 4
	local NotifyFunction = {}
	task.spawn(function()
		if not CoreGui:FindFirstChild("NexxNotifyGui") then
			local g = Instance.new("ScreenGui")
			g.Name = "NexxNotifyGui"
			g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			g.Parent = CoreGui
		end
		if not CoreGui.NexxNotifyGui:FindFirstChild("NotifyLayout") then
			local layout = Instance.new("Frame")
			layout.Name = "NotifyLayout"
			layout.AnchorPoint = Vector2.new(1,1)
			layout.BackgroundTransparency = 1
			layout.Position = UDim2.new(1,-20,1,-20)
			layout.Size = UDim2.new(0,300,1,0)
			layout.Parent = CoreGui.NexxNotifyGui
			local count = 0
			layout.ChildRemoved:Connect(function()
				count = 0
				for _,v in layout:GetChildren() do
					tw(v,{t=0.25},{Position=UDim2.new(0,0,1,-((v.Size.Y.Offset+10)*count))}):Play()
					count = count + 1
				end
			end)
		end
		local height = 0
		for _,v in CoreGui.NexxNotifyGui.NotifyLayout:GetChildren() do
			height = -(v.Position.Y.Offset) + v.Size.Y.Offset + 10
		end
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1,0,0,70)
		frame.AnchorPoint = Vector2.new(0,1)
		frame.Position = UDim2.new(0,0,1,-height)
		frame.Parent = CoreGui.NexxNotifyGui.NotifyLayout
		local real = Instance.new("Frame")
		real.BackgroundColor3 = Themes[CurrentTheme].Background
		real.BorderSizePixel = 0
		real.Position = UDim2.new(0,320,0,0)
		real.Size = UDim2.new(1,0,1,0)
		real.Parent = frame
		Instance.new("UICorner",real).CornerRadius = UDim.new(0,10)
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Position = UDim2.new(0,12,0,8)
		title.Size = UDim2.new(1,-40,0,16)
		title.Font = Enum.Font.GothamBold
		title.Text = NotifyConfig.Title
		title.TextColor3 = Themes[CurrentTheme].Text
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = real
		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.Position = UDim2.new(0,12,0,28)
		desc.Size = UDim2.new(1,-24,0,30)
		desc.Font = Enum.Font.Gotham
		desc.Text = NotifyConfig.Content ~= "" and NotifyConfig.Content or NotifyConfig.Description
		desc.TextColor3 = Themes[CurrentTheme].SubText
		desc.TextSize = 11
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = real
		local close = Instance.new("TextButton")
		close.BackgroundTransparency = 1
		close.Position = UDim2.new(1,-28,0,4)
		close.Size = UDim2.new(0,24,0,24)
		close.Text = ""
		close.Parent = real
		local closeImg = Instance.new("ImageLabel")
		closeImg.BackgroundTransparency = 1
		closeImg.Size = UDim2.new(1,-6,1,-6)
		closeImg.Position = UDim2.new(0,3,0,3)
		closeImg.Image = "rbxassetid://9886659671"
		closeImg.Parent = close
		local closed = false
		function NotifyFunction:Close()
			if closed then return end
			closed = true
			tw(real,{t=NotifyConfig.Time,s=Enum.EasingStyle.Back,d=Enum.EasingDirection.In},{Position=UDim2.new(0,320,0,0)}):Play()
			task.wait(NotifyConfig.Time)
			frame:Destroy()
		end
		close.MouseButton1Click:Connect(function() NotifyFunction:Close() end)
		tw(real,{t=NotifyConfig.Time,s=Enum.EasingStyle.Back},{Position=UDim2.new(0,0,0,0)}):Play()
		task.wait(NotifyConfig.Delay)
		NotifyFunction:Close()
	end)
	return NotifyFunction
end

function Library:MakeGui(GuiConfig)
	GuiConfig = GuiConfig or {}
	local NameHub = GuiConfig.NameHub or GuiConfig.Title or "NexxChasers"
	local Description = GuiConfig.Description or GuiConfig.Author or GuiConfig.Desc or ""
	local AccentColor = GuiConfig.Color or GuiConfig.Main or Color3.fromRGB(0,122,255)
	local Logo = GuiConfig.Logo or GuiConfig.Icon or "house"
	local TabWidth = GuiConfig["Tab Width"] or 120
	local ThemeName = GuiConfig.Theme or "Dark"
	local Transparency = (GuiConfig.Config and GuiConfig.Config.Transparency) or GuiConfig.Transparency or 0.1
	local Keybind = (GuiConfig.Config and (GuiConfig.Config.ToggleKeybind or GuiConfig.Config.Keybind)) or GuiConfig.Keybind or Enum.KeyCode.LeftControl
	local Size = (GuiConfig.Config and GuiConfig.Config.Size) or GuiConfig.Size or UDim2.new(0,500,0,380)
	local AutoScale = GuiConfig.Config and GuiConfig.Config.AutoScale
	local Tags = (GuiConfig.Config and GuiConfig.Config.Tags) or GuiConfig.Tags or {}
	local Anonymous = (GuiConfig.Config and GuiConfig.Config.Anonymous) or GuiConfig.Anonymous or false

	if AutoScale then
		local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
		local sc = math.clamp(math.min(vs.X/1920,vs.Y/1080),0.55,1)
		Size = UDim2.new(0,math.floor(Size.X.Offset*sc),0,math.floor(Size.Y.Offset*sc))
	end

	CurrentTheme = ThemeName
	if Themes[ThemeName] then
		AccentColor = Themes[ThemeName].Main
	end

	local GuiFunc = {}
	local isOpen = true

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "NexxChasers"
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = not RunService:IsStudio() and CoreGui or LocalPlayer:WaitForChild("PlayerGui")

	local DropShadowHolder = Instance.new("Frame")
	DropShadowHolder.BackgroundTransparency = 1
	DropShadowHolder.BorderSizePixel = 0
	DropShadowHolder.AnchorPoint = Vector2.new(0.5,0.5)
	DropShadowHolder.Position = UDim2.new(0.5,0,0.5,0)
	DropShadowHolder.Size = Size
	DropShadowHolder.ZIndex = 0
	DropShadowHolder.Name = "DropShadowHolder"
	DropShadowHolder.Parent = ScreenGui
	DropShadowHolder.Visible = false

	local DropShadow = Instance.new("ImageLabel")
	DropShadow.Image = "rbxassetid://6015897843"
	DropShadow.ImageColor3 = Color3.fromRGB(0,0,0)
	DropShadow.ImageTransparency = 0.5
	DropShadow.ScaleType = Enum.ScaleType.Slice
	DropShadow.SliceCenter = Rect.new(49,49,450,450)
	DropShadow.AnchorPoint = Vector2.new(0.5,0.5)
	DropShadow.BackgroundTransparency = 1
	DropShadow.BorderSizePixel = 0
	DropShadow.Position = UDim2.new(0.5,0,0.5,0)
	DropShadow.Size = UDim2.new(1,47,1,47)
	DropShadow.ZIndex = 0
	DropShadow.Parent = DropShadowHolder

	local Main = Instance.new("Frame")
	Main.AnchorPoint = Vector2.new(0.5,0.5)
	Main.BackgroundColor3 = Themes[CurrentTheme].Background
	Main.BackgroundTransparency = Transparency
	Main.BorderSizePixel = 0
	Main.Position = UDim2.new(0.5,0,0.5,0)
	Main.Size = UDim2.new(1,0,1,0)
	Main.ClipsDescendants = true
	Main.Parent = DropShadowHolder
	Instance.new("UICorner",Main).CornerRadius = UDim.new(0,12)

	local UIStrokeMain = Instance.new("UIStroke")
	UIStrokeMain.Color = Themes[CurrentTheme].Stroke
	UIStrokeMain.Thickness = 1
	UIStrokeMain.Parent = Main

	local Top = Instance.new("Frame")
	Top.BackgroundTransparency = 1
	Top.Size = UDim2.new(1,0,0,42)
	Top.Parent = Main

	local TopLine = Instance.new("Frame")
	TopLine.BackgroundColor3 = Themes[CurrentTheme].Stroke
	TopLine.BorderSizePixel = 0
	TopLine.Position = UDim2.new(0,0,1,0)
	TopLine.Size = UDim2.new(1,0,0,1)
	TopLine.Parent = Top

	local LogoImg = Instance.new("ImageLabel")
	LogoImg.BackgroundTransparency = 1
	LogoImg.Position = UDim2.new(0,10,0.5,-12)
	LogoImg.Size = UDim2.new(0,24,0,24)
	local gLogo = gl(Logo)
	LogoImg.Image = gLogo.Image
	LogoImg.ImageRectSize = gLogo.ImageRectSize
	LogoImg.ImageRectOffset = gLogo.ImageRectPosition
	LogoImg.Parent = Top

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.new(0,42,0,4)
	TitleLabel.Size = UDim2.new(0,160,0,18)
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.Text = NameHub
	TitleLabel.TextColor3 = Themes[CurrentTheme].Text
	TitleLabel.TextSize = 14
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = Top

	local DescLabel = Instance.new("TextLabel")
	DescLabel.BackgroundTransparency = 1
	DescLabel.Position = UDim2.new(0,42,0,22)
	DescLabel.Size = UDim2.new(0,160,0,14)
	DescLabel.Font = Enum.Font.Gotham
	DescLabel.Text = Description
	DescLabel.TextColor3 = Themes[CurrentTheme].SubText
	DescLabel.TextSize = 11
	DescLabel.TextXAlignment = Enum.TextXAlignment.Left
	DescLabel.Visible = Description ~= ""
	DescLabel.Parent = Top

	local TagHolder = Instance.new("Frame")
	TagHolder.BackgroundTransparency = 1
	TagHolder.Position = UDim2.new(0,42,0,4)
	TagHolder.Size = UDim2.new(0,0,0,18)
	TagHolder.AutomaticSize = Enum.AutomaticSize.X
	TagHolder.Parent = Top
	local TagList = Instance.new("UIListLayout")
	TagList.FillDirection = Enum.FillDirection.Horizontal
	TagList.VerticalAlignment = Enum.VerticalAlignment.Center
	TagList.Padding = UDim.new(0,6)
	TagList.Parent = TagHolder
	local TitleInTag = Instance.new("TextLabel")
	TitleInTag.BackgroundTransparency = 1
	TitleInTag.AutomaticSize = Enum.AutomaticSize.X
	TitleInTag.Size = UDim2.new(0,0,0,18)
	TitleInTag.Font = Enum.Font.GothamBold
	TitleInTag.Text = NameHub
	TitleInTag.TextColor3 = Themes[CurrentTheme].Text
	TitleInTag.TextSize = 14
	TitleInTag.LayoutOrder = 0
	TitleInTag.Parent = TagHolder
	TitleLabel.Visible = false
	for i,tag in ipairs(Tags) do
		local tf = Instance.new("Frame")
		tf.BackgroundColor3 = tag.Color or Color3.fromRGB(255,180,0)
		tf.BorderSizePixel = 0
		tf.Size = UDim2.new(0,0,0,16)
		tf.AutomaticSize = Enum.AutomaticSize.X
		tf.LayoutOrder = i
		tf.Parent = TagHolder
		Instance.new("UICorner",tf).CornerRadius = UDim.new(0,5)
		local tp = Instance.new("UIPadding")
		tp.PaddingLeft = UDim.new(0,7)
		tp.PaddingRight = UDim.new(0,7)
		tp.Parent = tf
		local tt = Instance.new("TextLabel")
		tt.BackgroundTransparency = 1
		tt.AutomaticSize = Enum.AutomaticSize.X
		tt.Size = UDim2.new(0,0,1,0)
		tt.Font = Enum.Font.GothamBold
		tt.Text = tag.Text or "TAG"
		tt.TextColor3 = Color3.fromRGB(0,0,0)
		tt.TextSize = 10
		tt.Parent = tf
	end

	local FPSLabel = Instance.new("TextLabel")
	FPSLabel.BackgroundTransparency = 1
	FPSLabel.AnchorPoint = Vector2.new(1,0.5)
	FPSLabel.Position = UDim2.new(1,-145,0.5,0)
	FPSLabel.Size = UDim2.new(0,60,0,18)
	FPSLabel.Font = Enum.Font.GothamBold
	FPSLabel.Text = "60 FPS"
	FPSLabel.TextColor3 = Color3.fromRGB(255,220,50)
	FPSLabel.TextSize = 11
	FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
	FPSLabel.Parent = Top
	task.spawn(function()
		local last,frames = tick(),0
		RunService.RenderStepped:Connect(function()
			frames = frames + 1
			if tick()-last >= 1 then
				FPSLabel.Text = frames.." FPS"
				frames = 0
				last = tick()
			end
		end)
	end)

	local ThemeBtn = Instance.new("TextButton")
	ThemeBtn.BackgroundColor3 = Themes[CurrentTheme].Page
	ThemeBtn.BorderSizePixel = 0
	ThemeBtn.AnchorPoint = Vector2.new(1,0.5)
	ThemeBtn.Position = UDim2.new(1,-78,0.5,0)
	ThemeBtn.Size = UDim2.new(0,55,0,22)
	ThemeBtn.Font = Enum.Font.Gotham
	ThemeBtn.Text = CurrentTheme
	ThemeBtn.TextColor3 = Themes[CurrentTheme].Text
	ThemeBtn.TextSize = 11
	ThemeBtn.AutoButtonColor = false
	ThemeBtn.Parent = Top
	Instance.new("UICorner",ThemeBtn).CornerRadius = UDim.new(0,6)

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.AnchorPoint = Vector2.new(1,0.5)
	CloseBtn.Position = UDim2.new(1,-8,0.5,0)
	CloseBtn.Size = UDim2.new(0,22,0,22)
	CloseBtn.Text = ""
	CloseBtn.Parent = Top
	local CloseImg = Instance.new("ImageLabel")
	CloseImg.BackgroundTransparency = 1
	CloseImg.Size = UDim2.new(1,-4,1,-4)
	CloseImg.Position = UDim2.new(0,2,0,2)
	CloseImg.Image = "rbxassetid://9886659671"
	CloseImg.Parent = CloseBtn

	local LayersTab = Instance.new("Frame")
	LayersTab.BackgroundTransparency = 1
	LayersTab.Position = UDim2.new(0,0,0,42)
	LayersTab.Size = UDim2.new(0,TabWidth,1,-42)
	LayersTab.Parent = Main

	local TabScroll = Instance.new("ScrollingFrame")
	TabScroll.BackgroundTransparency = 1
	TabScroll.BorderSizePixel = 0
	TabScroll.Size = UDim2.new(1,0,1,-60)
	TabScroll.Position = UDim2.new(0,0,0,4)
	TabScroll.ScrollBarThickness = 2
	TabScroll.ScrollBarImageColor3 = Themes[CurrentTheme].Main
	TabScroll.CanvasSize = UDim2.new(0,0,0,0)
	TabScroll.Parent = LayersTab

	local TabList = Instance.new("Frame")
	TabList.BackgroundTransparency = 1
	TabList.Size = UDim2.new(1,0,1,0)
	TabList.Parent = TabScroll
	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.Padding = UDim.new(0,4)
	TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	TabListLayout.Parent = TabList
	local TabPad = Instance.new("UIPadding")
	TabPad.PaddingTop = UDim.new(0,4)
	TabPad.Parent = TabList

	TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabScroll.CanvasSize = UDim2.new(0,0,0,TabListLayout.AbsoluteContentSize.Y+8)
	end)

	local SelectBar = Instance.new("Frame")
	SelectBar.BackgroundColor3 = Themes[CurrentTheme].Main
	SelectBar.BorderSizePixel = 0
	SelectBar.Position = UDim2.new(0,2,0,8)
	SelectBar.Size = UDim2.new(0,3,0,22)
	SelectBar.Parent = TabScroll
	Instance.new("UICorner",SelectBar).CornerRadius = UDim.new(1,0)

	local Profile = Instance.new("Frame")
	Profile.BackgroundColor3 = Themes[CurrentTheme].Page
	Profile.BorderSizePixel = 0
	Profile.AnchorPoint = Vector2.new(0,1)
	Profile.Position = UDim2.new(0,6,1,-6)
	Profile.Size = UDim2.new(0,TabWidth-12,0,48)
	Profile.Parent = LayersTab
	Instance.new("UICorner",Profile).CornerRadius = UDim.new(0,8)

	local Avatar = Instance.new("ImageLabel")
	Avatar.BackgroundTransparency = 1
	Avatar.Position = UDim2.new(0,6,0.5,-14)
	Avatar.Size = UDim2.new(0,28,0,28)
	if Anonymous then
		Avatar.Image = "rbxassetid://6031075938"
	else
		Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..LocalPlayer.UserId.."&width=60&height=60&format=png"
	end
	Avatar.Parent = Profile
	Instance.new("UICorner",Avatar).CornerRadius = UDim.new(1,0)

	local DN = Instance.new("TextLabel")
	DN.BackgroundTransparency = 1
	DN.Position = UDim2.new(0,38,0,4)
	DN.Size = UDim2.new(1,-44,0,14)
	DN.Font = Enum.Font.GothamBold
	DN.Text = Anonymous and "*****" or LocalPlayer.DisplayName
	DN.TextColor3 = Themes[CurrentTheme].Text
	DN.TextSize = 11
	DN.TextXAlignment = Enum.TextXAlignment.Left
	DN.TextTruncate = Enum.TextTruncate.AtEnd
	DN.Parent = Profile

	local UN = Instance.new("TextLabel")
	UN.BackgroundTransparency = 1
	UN.Position = UDim2.new(0,38,0,18)
	UN.Size = UDim2.new(1,-44,0,12)
	UN.Font = Enum.Font.Gotham
	UN.Text = Anonymous and "@*****" or ("@"..LocalPlayer.Name)
	UN.TextColor3 = Themes[CurrentTheme].SubText
	UN.TextSize = 10
	UN.TextXAlignment = Enum.TextXAlignment.Left
	UN.Parent = Profile

	local Clock = Instance.new("TextLabel")
	Clock.BackgroundTransparency = 1
	Clock.Position = UDim2.new(0,38,0,32)
	Clock.Size = UDim2.new(1,-44,0,12)
	Clock.Font = Enum.Font.Gotham
	Clock.TextColor3 = Themes[CurrentTheme].SubText
	Clock.TextSize = 9
	Clock.TextXAlignment = Enum.TextXAlignment.Left
	Clock.Parent = Profile
	task.spawn(function()
		while Profile.Parent do
			local t = os.date("*t")
			Clock.Text = string.format("%02d/%02d/%04d %02d:%02d",t.day,t.month,t.year,t.hour,t.min)
			task.wait(1)
		end
	end)

	local Layers = Instance.new("Frame")
	Layers.BackgroundColor3 = Themes[CurrentTheme].Page
	Layers.BorderSizePixel = 0
	Layers.Position = UDim2.new(0,TabWidth+4,0,48)
	Layers.Size = UDim2.new(1,-(TabWidth+10),1,-54)
	Layers.Parent = Main
	Instance.new("UICorner",Layers).CornerRadius = UDim.new(0,10)

	local NameTab = Instance.new("TextLabel")
	NameTab.BackgroundTransparency = 1
	NameTab.Position = UDim2.new(0,12,0,6)
	NameTab.Size = UDim2.new(1,-80,0,20)
	NameTab.Font = Enum.Font.GothamBold
	NameTab.Text = ""
	NameTab.TextColor3 = Themes[CurrentTheme].Text
	NameTab.TextSize = 13
	NameTab.TextXAlignment = Enum.TextXAlignment.Left
	NameTab.Parent = Layers

	local SearchBox = Instance.new("TextBox")
	SearchBox.BackgroundColor3 = Themes[CurrentTheme].Background
	SearchBox.BorderSizePixel = 0
	SearchBox.AnchorPoint = Vector2.new(1,0)
	SearchBox.Position = UDim2.new(1,-10,0,6)
	SearchBox.Size = UDim2.new(0,100,0,22)
	SearchBox.Font = Enum.Font.Gotham
	SearchBox.PlaceholderText = "Search..."
	SearchBox.Text = ""
	SearchBox.TextColor3 = Themes[CurrentTheme].Text
	SearchBox.TextSize = 11
	SearchBox.ClearTextOnFocus = false
	SearchBox.Parent = Layers
	Instance.new("UICorner",SearchBox).CornerRadius = UDim.new(0,6)

	local LayersReal = Instance.new("Frame")
	LayersReal.BackgroundTransparency = 1
	LayersReal.Position = UDim2.new(0,0,0,32)
	LayersReal.Size = UDim2.new(1,0,1,-32)
	LayersReal.ClipsDescendants = true
	LayersReal.Parent = Layers

	local LayersFolder = Instance.new("Folder")
	LayersFolder.Parent = LayersReal
	local LayersPageLayout = Instance.new("UIPageLayout")
	LayersPageLayout.FillDirection = Enum.FillDirection.Vertical
	LayersPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	LayersPageLayout.EasingStyle = Enum.EasingStyle.Exponential
	LayersPageLayout.TweenTime = 0.3
	LayersPageLayout.Parent = LayersFolder

	local DragLine = Instance.new("Frame")
	DragLine.Name = "DragLine"
	DragLine.Parent = DropShadowHolder
	DragLine.AnchorPoint = Vector2.new(0.5,0)
	DragLine.BackgroundColor3 = Color3.fromRGB(100,100,100)
	DragLine.BackgroundTransparency = 0.2
	DragLine.BorderSizePixel = 0
	DragLine.Position = UDim2.new(0.5,0,1,6)
	DragLine.Size = UDim2.new(0,90,0,5)
	Instance.new("UICorner",DragLine).CornerRadius = UDim.new(1,0)
	MakeDraggable(DragLine, DropShadowHolder)

	local ResizeHandle = Instance.new("Frame")
	ResizeHandle.Name = "ResizeHandle"
	ResizeHandle.Parent = DropShadowHolder
	ResizeHandle.AnchorPoint = Vector2.new(1,1)
	ResizeHandle.BackgroundTransparency = 1
	ResizeHandle.Position = UDim2.new(1,14,1,14)
	ResizeHandle.Size = UDim2.new(0,26,0,26)
	ResizeHandle.ZIndex = 20
	local RL = Instance.new("Frame")
	RL.Parent = ResizeHandle
	RL.BackgroundColor3 = Color3.fromRGB(160,160,160)
	RL.BorderSizePixel = 0
	RL.AnchorPoint = Vector2.new(1,0)
	RL.Position = UDim2.new(1,-3,0.25,0)
	RL.Size = UDim2.new(0,3,0.5,0)
	Instance.new("UICorner",RL).CornerRadius = UDim.new(1,0)
	local RB = Instance.new("Frame")
	RB.Parent = ResizeHandle
	RB.BackgroundColor3 = Color3.fromRGB(160,160,160)
	RB.BorderSizePixel = 0
	RB.AnchorPoint = Vector2.new(0,1)
	RB.Position = UDim2.new(0.25,0,1,-3)
	RB.Size = UDim2.new(0.5,0,0,3)
	Instance.new("UICorner",RB).CornerRadius = UDim.new(1,0)
	local resizing, rStart, rSize
	ResizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			resizing=true rStart=input.Position rSize=DropShadowHolder.Size
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then resizing=false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local d = input.Position - rStart
			local nw = math.max(400, rSize.X.Offset + d.X)
			local nh = math.max(280, rSize.Y.Offset + d.Y)
			tw(DropShadowHolder,{t=0.08,s=Enum.EasingStyle.Quad},{Size=UDim2.new(0,nw,0,nh)}):Play()
		end
	end)

	local FloatBtn = Instance.new("Frame")
	FloatBtn.Name = "FloatBtn"
	FloatBtn.Parent = ScreenGui
	FloatBtn.AnchorPoint = Vector2.new(0,0.5)
	FloatBtn.BackgroundColor3 = Themes[CurrentTheme].Background
	FloatBtn.Position = UDim2.new(0,16,0.5,0)
	FloatBtn.Size = UDim2.new(0,46,0,46)
	FloatBtn.ZIndex = 30
	Instance.new("UICorner",FloatBtn).CornerRadius = UDim.new(1,0)
	local fStroke = Instance.new("UIStroke")
	fStroke.Color = Color3.fromRGB(255,255,255)
	fStroke.Thickness = 1.5
	fStroke.Transparency = 0.25
	fStroke.Parent = FloatBtn
	local FImg = Instance.new("ImageButton")
	FImg.BackgroundTransparency = 1
	FImg.Size = UDim2.new(1,0,1,0)
	FImg.Image = gLogo.Image
	FImg.ImageRectSize = gLogo.ImageRectSize
	FImg.ImageRectOffset = gLogo.ImageRectPosition
	FImg.ZIndex = 31
	FImg.Parent = FloatBtn
	MakeDraggable(FloatBtn, FloatBtn)

	local function openUI()
		DropShadowHolder.Visible = true
		Main.Size = UDim2.new(1,0,1,0) - UDim2.fromOffset(8,8)
		Main.BackgroundTransparency = 1
		tw(Main,{t=0.28,s=Enum.EasingStyle.Back},{Size=UDim2.new(1,0,1,0),BackgroundTransparency=Transparency}):Play()
		isOpen = true
	end
	local function closeUI()
		local t = tw(Main,{t=0.2,s=Enum.EasingStyle.Quad,d=Enum.EasingDirection.In},{Size=UDim2.new(1,0,1,0)-UDim2.fromOffset(8,8),BackgroundTransparency=1})
		t:Play()
		t.Completed:Wait()
		DropShadowHolder.Visible = false
		isOpen = false
	end
	FImg.MouseButton1Click:Connect(function()
		if isOpen then closeUI() else openUI() end
	end)

	DropShadowHolder.Visible = true
	Main.Size = UDim2.new(1,0,1,0) - UDim2.fromOffset(8,8)
	tw(Main,{t=0.28,s=Enum.EasingStyle.Back},{Size=UDim2.new(1,0,1,0),BackgroundTransparency=Transparency}):Play()

	UserInputService.InputBegan:Connect(function(i,gp)
		if i.KeyCode == Keybind and not UserInputService:GetFocusedTextBox() then
			if isOpen then closeUI() else openUI() end
		end
	end)

	ThemeBtn.MouseButton1Click:Connect(function()
		local idx = table.find(Themes.index, CurrentTheme) or 1
		idx = idx % #Themes.index + 1
		CurrentTheme = Themes.index[idx]
		ThemeBtn.Text = CurrentTheme
		local th = Themes[CurrentTheme]
		Main.BackgroundColor3 = th.Background
		Layers.BackgroundColor3 = th.Page
		Profile.BackgroundColor3 = th.Page
		TitleLabel.TextColor3 = th.Text
		DescLabel.TextColor3 = th.SubText
		NameTab.TextColor3 = th.Text
		DN.TextColor3 = th.Text
		UN.TextColor3 = th.SubText
		Clock.TextColor3 = th.SubText
		ThemeBtn.BackgroundColor3 = th.Page
		ThemeBtn.TextColor3 = th.Text
		SelectBar.BackgroundColor3 = th.Main
		SearchBox.BackgroundColor3 = th.Background
		SearchBox.TextColor3 = th.Text
		FloatBtn.BackgroundColor3 = th.Background
		UIStrokeMain.Color = th.Stroke
	end)

	CloseBtn.MouseButton1Click:Connect(function()
		GuiFunc:Dialog({
			Title = "Close NexxChasers?",
			Buttons = {
				{Title="Yes",Color=Color3.fromRGB(0,180,0),Callback=function() ScreenGui:Destroy() end},
				{Title="No",Color=Color3.fromRGB(200,50,50)}
			}
		})
	end)

	local Tabs = {}
	local TabCount = 0
	local CurrentPage = nil

	function GuiFunc:Dialog(p)
		p = p or {}
		local Buttons = p.Buttons or {
			{Title="OK",Color=Color3.fromRGB(0,122,255),Callback=function() end}
		}
		local Ov = Instance.new("Frame")
		Ov.BackgroundColor3 = Color3.fromRGB(0,0,0)
		Ov.BackgroundTransparency = 0.45
		Ov.Size = UDim2.new(1,0,1,0)
		Ov.ZIndex = 50
		Ov.Parent = Main
		Instance.new("UICorner",Ov).CornerRadius = UDim.new(0,12)
		local DF = Instance.new("Frame")
		DF.AnchorPoint = Vector2.new(0.5,0.5)
		DF.BackgroundColor3 = Themes[CurrentTheme].Background
		DF.Position = UDim2.new(0.5,0,0.5,0)
		DF.Size = UDim2.new(0,260,0,110)
		DF.ZIndex = 51
		DF.Parent = Ov
		Instance.new("UICorner",DF).CornerRadius = UDim.new(0,12)
		local TL = Instance.new("TextLabel")
		TL.BackgroundTransparency = 1
		TL.Position = UDim2.new(0,14,0,12)
		TL.Size = UDim2.new(1,-28,0,36)
		TL.Font = Enum.Font.GothamBold
		TL.Text = p.Title or "Dialog"
		TL.TextColor3 = Themes[CurrentTheme].Text
		TL.TextSize = 14
		TL.TextWrapped = true
		TL.Parent = DF
		local BH = Instance.new("Frame")
		BH.BackgroundTransparency = 1
		BH.Position = UDim2.new(0,14,1,-44)
		BH.Size = UDim2.new(1,-28,0,32)
		BH.Parent = DF
		local bl = Instance.new("UIListLayout")
		bl.FillDirection = Enum.FillDirection.Horizontal
		bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
		bl.Padding = UDim.new(0,8)
		bl.Parent = BH
		for _,btn in ipairs(Buttons) do
			local B = Instance.new("TextButton")
			B.BackgroundColor3 = btn.Color or Color3.fromRGB(60,60,60)
			B.Size = UDim2.new(0,90,0,30)
			B.Font = Enum.Font.GothamBold
			B.Text = btn.Title or "OK"
			B.TextColor3 = Color3.fromRGB(255,255,255)
			B.TextSize = 12
			B.AutoButtonColor = false
			B.ZIndex = 52
			B.Parent = BH
			Instance.new("UICorner",B).CornerRadius = UDim.new(0,8)
			B.MouseButton1Click:Connect(function()
				if btn.Callback then pcall(btn.Callback) end
				Ov:Destroy()
			end)
		end
	end

	function GuiFunc:Notify(p)
		return Library:MakeNotify(p)
	end

	function GuiFunc:SaveConfig(name)
		name = name or "config"
		local data = HttpService:JSONEncode(Flags)
		pcall(function()
			if writefile then
				pcall(makefolder, ConfigFolder)
				writefile(ConfigFolder.."/"..name..".json", data)
			end
		end)
		pcall(setclipboard, data)
		return data
	end
	function GuiFunc:LoadConfig(name)
		name = name or "config"
		local data
		pcall(function()
			if isfile and isfile(ConfigFolder.."/"..name..".json") then
				data = readfile(ConfigFolder.."/"..name..".json")
			end
		end)
		if data then
			local ok,dec = pcall(HttpService.JSONDecode, HttpService, data)
			if ok and type(dec)=="table" then for k,v in pairs(dec) do Flags[k]=v end end
		end
	end
	function GuiFunc:ExportConfig()
		local data = HttpService:JSONEncode(Flags)
		pcall(setclipboard, data)
		return data
	end
	function GuiFunc:ImportConfig(str)
		local ok,dec = pcall(HttpService.JSONDecode, HttpService, str)
		if ok and type(dec)=="table" then for k,v in pairs(dec) do Flags[k]=v end end
	end

	function GuiFunc:CreateTab(TabConfig)
		TabConfig = TabConfig or {}
		local TabTitle = TabConfig.Title or TabConfig.Name or "Tab"
		local TabIcon = TabConfig.Icon or "house"
		local TabLocked = TabConfig.Locked or false
		TabCount = TabCount + 1
		local thisIndex = TabCount

		local TabBtn = Instance.new("Frame")
		TabBtn.BackgroundTransparency = 1
		TabBtn.Size = UDim2.new(1,-8,0,30)
		TabBtn.Parent = TabList

		local TabClick = Instance.new("TextButton")
		TabClick.BackgroundTransparency = 1
		TabClick.Size = UDim2.new(1,0,1,0)
		TabClick.Text = ""
		TabClick.Parent = TabBtn

		local TIcon = Instance.new("ImageLabel")
		TIcon.BackgroundTransparency = 1
		TIcon.Position = UDim2.new(0,10,0.5,-9)
		TIcon.Size = UDim2.new(0,18,0,18)
		local gi = gl(TabIcon)
		TIcon.Image = gi.Image
		TIcon.ImageRectSize = gi.ImageRectSize
		TIcon.ImageRectOffset = gi.ImageRectPosition
		TIcon.ImageTransparency = 0.45
		TIcon.Parent = TabBtn

		local TTitle = Instance.new("TextLabel")
		TTitle.BackgroundTransparency = 1
		TTitle.Position = UDim2.new(0,34,0,0)
		TTitle.Size = UDim2.new(1,-40,1,0)
		TTitle.Font = Enum.Font.GothamBold
		TTitle.Text = TabLocked and "Locked" or TabTitle
		TTitle.TextColor3 = Themes[CurrentTheme].Text
		TTitle.TextSize = 12
		TTitle.TextTransparency = 0.45
		TTitle.TextXAlignment = Enum.TextXAlignment.Left
		TTitle.Parent = TabBtn

		local Page = Instance.new("ScrollingFrame")
		Page.BackgroundTransparency = 1
		Page.BorderSizePixel = 0
		Page.Size = UDim2.new(1,0,1,0)
		Page.ScrollBarThickness = 3
		Page.ScrollBarImageColor3 = Themes[CurrentTheme].Main
		Page.CanvasSize = UDim2.new(0,0,0,0)
		Page.LayoutOrder = thisIndex
		Page.Visible = false
		Page.Parent = LayersFolder

		local PageList = Instance.new("UIListLayout")
		PageList.Padding = UDim.new(0,6)
		PageList.SortOrder = Enum.SortOrder.LayoutOrder
		PageList.Parent = Page
		local PagePad = Instance.new("UIPadding")
		PagePad.PaddingLeft = UDim.new(0,8)
		PagePad.PaddingRight = UDim.new(0,8)
		PagePad.PaddingTop = UDim.new(0,6)
		PagePad.PaddingBottom = UDim.new(0,8)
		PagePad.Parent = Page
		PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0,0,0,PageList.AbsoluteContentSize.Y+16)
		end)

		local ItemCount = 0
		local allItems = {}

		SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local q = string.lower(SearchBox.Text)
			for _,item in ipairs(allItems) do
				if item.Frame and item.Frame.Parent then
					local titleObj = item.Frame:FindFirstChild("ItemTitle") or item.Frame:FindFirstChildWhichIsA("TextLabel")
					if titleObj then
						local match = q=="" or string.find(string.lower(titleObj.Text),q,1,true)
						item.Frame.Visible = match
						if match and q~="" then
							titleObj.TextColor3 = Color3.fromRGB(255,220,50)
						else
							titleObj.TextColor3 = Themes[CurrentTheme].Text
						end
					end
				end
			end
		end)

		local function selectThis()
			if TabLocked then return end
			for _,t in pairs(Tabs) do
				t.Page.Visible = false
				t.TTitle.TextTransparency = 0.45
				t.TIcon.ImageTransparency = 0.45
			end
			Page.Visible = true
			Page.CanvasPosition = Vector2.new(0,0)
			TTitle.TextTransparency = 0
			TIcon.ImageTransparency = 0
			NameTab.Text = TabTitle
			local cy = TabBtn.AbsolutePosition.Y + TabBtn.AbsoluteSize.Y/2
			local ty = cy - TabScroll.AbsolutePosition.Y - SelectBar.AbsoluteSize.Y/2 + TabScroll.CanvasPosition.Y
			tw(SelectBar,{t=0.3,s=Enum.EasingStyle.Exponential},{Position=UDim2.new(0,2,0,ty)}):Play()
			for _,child in pairs(Page:GetChildren()) do
				if child:IsA("Frame") then
					child.Position = UDim2.new(0,0,0,12)
					child.BackgroundTransparency = 1
					tw(child,{t=0.25,s=Enum.EasingStyle.Exponential},{Position=UDim2.new(0,0,0,0),BackgroundTransparency=child:GetAttribute("OrigTrans") or 0.935}):Play()
				end
			end
			CurrentPage = Page
		end

		TabClick.MouseButton1Click:Connect(selectThis)
		if thisIndex == 1 then task.defer(selectThis) end

		table.insert(Tabs, {Page=Page,TTitle=TTitle,TIcon=TIcon,Btn=TabBtn})

		local Items = {}

		local function makeItem(title, content)
			ItemCount = ItemCount + 1
			local Item = Instance.new("Frame")
			Item.BackgroundColor3 = Color3.fromRGB(255,255,255)
			Item.BackgroundTransparency = Themes[CurrentTheme].ItemTransparency
			Item:SetAttribute("OrigTrans", Themes[CurrentTheme].ItemTransparency)
			Item.BorderSizePixel = 0
			Item.LayoutOrder = ItemCount
			Item.Size = UDim2.new(1,0,0,46)
			Item.Parent = Page
			Instance.new("UICorner",Item).CornerRadius = UDim.new(0,6)
			local ItemTitle = Instance.new("TextLabel")
			ItemTitle.Name = "ItemTitle"
			ItemTitle.BackgroundTransparency = 1
			ItemTitle.Position = UDim2.new(0,10,0,8)
			ItemTitle.Size = UDim2.new(1,-160,0,14)
			ItemTitle.Font = Enum.Font.GothamBold
			ItemTitle.Text = title or ""
			ItemTitle.TextColor3 = Themes[CurrentTheme].Text
			ItemTitle.TextSize = 13
			ItemTitle.TextXAlignment = Enum.TextXAlignment.Left
			ItemTitle.Parent = Item
			local ItemContent = Instance.new("TextLabel")
			ItemContent.BackgroundTransparency = 1
			ItemContent.Position = UDim2.new(0,10,0,24)
			ItemContent.Size = UDim2.new(1,-160,0,14)
			ItemContent.Font = Enum.Font.Gotham
			ItemContent.Text = content or ""
			ItemContent.TextColor3 = Themes[CurrentTheme].SubText
			ItemContent.TextSize = 11
			ItemContent.TextXAlignment = Enum.TextXAlignment.Left
			ItemContent.TextTransparency = 0.3
			ItemContent.Visible = content and content ~= ""
			ItemContent.Parent = Item
			if content and content ~= "" then
				Item.Size = UDim2.new(1,0,0,52)
			end
			table.insert(allItems, {Frame=Item})
			return Item, ItemTitle, ItemContent
		end

		function Items:AddSection(cfg)
			cfg = cfg or {}
			local Title = cfg.Title or cfg.Name or "Section"
			local Opened = true
			if cfg.Opened ~= nil then Opened = cfg.Opened end
			ItemCount = ItemCount + 1
			local SectionFrame = Instance.new("Frame")
			SectionFrame.Name = "Section"
			SectionFrame.BackgroundTransparency = 1
			SectionFrame.BorderSizePixel = 0
			SectionFrame.LayoutOrder = ItemCount
			SectionFrame.Size = UDim2.new(1,0,0,0)
			SectionFrame.AutomaticSize = Enum.AutomaticSize.Y
			SectionFrame.Parent = Page
			local Header = Instance.new("TextButton")
			Header.BackgroundTransparency = 1
			Header.Size = UDim2.new(1,0,0,28)
			Header.Text = ""
			Header.AutoButtonColor = false
			Header.Parent = SectionFrame
			local Arrow = Instance.new("TextLabel")
			Arrow.BackgroundTransparency = 1
			Arrow.Size = UDim2.new(0,16,0,28)
			Arrow.Font = Enum.Font.GothamBold
			Arrow.Text = Opened and "v" or ">"
			Arrow.TextColor3 = Themes[CurrentTheme].Main
			Arrow.TextSize = 11
			Arrow.Parent = Header
			local SecTitle = Instance.new("TextLabel")
			SecTitle.BackgroundTransparency = 1
			SecTitle.Position = UDim2.new(0,18,0,0)
			SecTitle.Size = UDim2.new(1,-20,1,0)
			SecTitle.Font = Enum.Font.GothamBold
			SecTitle.Text = Title
			SecTitle.TextColor3 = Themes[CurrentTheme].Main
			SecTitle.TextSize = 14
			SecTitle.TextXAlignment = Enum.TextXAlignment.Left
			SecTitle.Parent = Header
			local Content = Instance.new("Frame")
			Content.Name = "Content"
			Content.BackgroundTransparency = 1
			Content.Position = UDim2.new(0,0,0,30)
			Content.Size = UDim2.new(1,0,0,0)
			Content.AutomaticSize = Enum.AutomaticSize.Y
			Content.Visible = Opened
			Content.Parent = SectionFrame
			local ContentList = Instance.new("UIListLayout")
			ContentList.Padding = UDim.new(0,6)
			ContentList.SortOrder = Enum.SortOrder.LayoutOrder
			ContentList.Parent = Content
			local isOpen = Opened
			Header.MouseButton1Click:Connect(function()
				isOpen = not isOpen
				Content.Visible = isOpen
				Arrow.Text = isOpen and "v" or ">"
			end)
			local SecItems = {}
			local secCount = 0
			local oldParent = Page
			local function withContent(fn)
				return function(c)
					local prev = Page
					Page = Content
					local r = fn(c)
					Page = prev
					return r
				end
			end
			SecItems.Button = withContent(function(c) return Items:AddButton(c) end)
			SecItems.Toggle = withContent(function(c) return Items:AddToggle(c) end)
			SecItems.Slider = withContent(function(c) return Items:AddSlider(c) end)
			SecItems.Stepper = withContent(function(c) return Items:AddStepper(c) end)
			SecItems.Textbox = withContent(function(c) return Items:AddInput(c) end)
			SecItems.Dropdown = withContent(function(c) return Items:AddDropdown(c) end)
			SecItems.Segmented = withContent(function(c) return Items:AddSegmented(c) end)
			SecItems.Keybind = withContent(function(c) return Items:AddKeybind(c) end)
			SecItems.ColorPicker = withContent(function(c) return Items:AddColorPicker(c) end)
			SecItems.Paragraph = withContent(function(c) return Items:AddParagraph(c) end)
			SecItems.Label = withContent(function(c) return Items:Label(c) end)
			SecItems.MultiButton = withContent(function(c) return Items:MultiButton(c) end)
			SecItems.RangeSlider = withContent(function(c) return Items:RangeSlider(c) end)
			SecItems.Code = withContent(function(c) return Items:Code(c) end)
			function SecItems:Open() isOpen=true Content.Visible=true Arrow.Text="v" end
			function SecItems:Close() isOpen=false Content.Visible=false Arrow.Text=">" end
			function SecItems:SetTitle(t) SecTitle.Text = t end
			return SecItems
		end

		function Items:AddButton(cfg)
			cfg = cfg or {}
			local Item = makeItem(cfg.Title or "Button", cfg.Content or cfg.Desc or "")
			local Btn = Instance.new("TextButton")
			Btn.BackgroundColor3 = Themes[CurrentTheme].Main
			Btn.BorderSizePixel = 0
			Btn.AnchorPoint = Vector2.new(1,0.5)
			Btn.Position = UDim2.new(1,-10,0.5,0)
			Btn.Size = UDim2.new(0,70,0,26)
			Btn.Font = Enum.Font.GothamBold
			Btn.Text = cfg.ButtonName or "Click"
			Btn.TextColor3 = Color3.fromRGB(255,255,255)
			Btn.TextSize = 12
			Btn.AutoButtonColor = false
			Btn.Parent = Item
			Instance.new("UICorner",Btn).CornerRadius = UDim.new(0,6)
			Btn.MouseButton1Click:Connect(function()
				if Item:GetAttribute("Locked") then return end
				CircleClick(Btn, Mouse.X, Mouse.Y)
				if cfg.Callback then pcall(cfg.Callback) end
			end)
			local New = {}
			addLockMethods(New, Item)
			if cfg.Locked then New:Lock(cfg.LockText) end
			return New
		end

		function Items:AddToggle(cfg)
			cfg = cfg or {}
			local Value = cfg.Default or cfg.Value or false
			local Item = makeItem(cfg.Title or "Toggle", cfg.Content or cfg.Desc or "")
			local TBg = Instance.new("Frame")
			TBg.BackgroundColor3 = Value and Themes[CurrentTheme].Main or Color3.fromRGB(50,50,50)
			TBg.BorderSizePixel = 0
			TBg.AnchorPoint = Vector2.new(1,0.5)
			TBg.Position = UDim2.new(1,-10,0.5,0)
			TBg.Size = UDim2.new(0,40,0,22)
			TBg.Parent = Item
			Instance.new("UICorner",TBg).CornerRadius = UDim.new(1,0)
			local Knob = Instance.new("Frame")
			Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
			Knob.BorderSizePixel = 0
			Knob.AnchorPoint = Vector2.new(0,0.5)
			Knob.Position = Value and UDim2.new(1,-19,0.5,0) or UDim2.new(0,3,0.5,0)
			Knob.Size = UDim2.new(0,16,0,16)
			Knob.Parent = TBg
			Instance.new("UICorner",Knob).CornerRadius = UDim.new(1,0)
			local function set(v)
				Value = v
				if Value then
					tw(TBg,{t=0.15},{BackgroundColor3=cfg.Color or Themes[CurrentTheme].Main}):Play()
					tw(Knob,{t=0.15},{Position=UDim2.new(1,-19,0.5,0)}):Play()
				else
					tw(TBg,{t=0.15},{BackgroundColor3=Color3.fromRGB(50,50,50)}):Play()
					tw(Knob,{t=0.15},{Position=UDim2.new(0,3,0.5,0)}):Play()
				end
				if cfg.Flag then Flags[cfg.Flag] = Value end
				if cfg.Callback then pcall(cfg.Callback, Value) end
			end
			local click = Instance.new("TextButton")
			click.BackgroundTransparency = 1
			click.Size = UDim2.new(1,0,1,0)
			click.Text = ""
			click.Parent = Item
			click.MouseButton1Click:Connect(function()
				if Item:GetAttribute("Locked") then return end
				set(not Value)
			end)
			task.defer(function() set(Value) end)
			local New = {Value=Value}
			function New:Set(v) set(v) end
			addLockMethods(New, Item)
			if cfg.Locked then New:Lock(cfg.LockText) end
			return New
		end

		function Items:AddSlider(cfg)
			cfg = cfg or {}
			local Min,Max,Value = cfg.Min or 0, cfg.Max or 100, cfg.Default or cfg.Value or 0
			local Item = makeItem(cfg.Title or "Slider", cfg.Content or cfg.Desc or "")
			Item.Size = UDim2.new(1,0,0,56)
			local VL = Instance.new("TextLabel")
			VL.BackgroundTransparency = 1
			VL.AnchorPoint = Vector2.new(1,0)
			VL.Position = UDim2.new(1,-10,0,8)
			VL.Size = UDim2.new(0,40,0,14)
			VL.Font = Enum.Font.GothamBold
			VL.Text = tostring(Value)
			VL.TextColor3 = Themes[CurrentTheme].Text
			VL.TextSize = 12
			VL.TextXAlignment = Enum.TextXAlignment.Right
			VL.Parent = Item
			local Bar = Instance.new("Frame")
			Bar.BackgroundColor3 = Color3.fromRGB(50,50,50)
			Bar.BorderSizePixel = 0
			Bar.Position = UDim2.new(0,10,1,-16)
			Bar.Size = UDim2.new(1,-20,0,6)
			Bar.Parent = Item
			Instance.new("UICorner",Bar).CornerRadius = UDim.new(1,0)
			local Fill = Instance.new("Frame")
			Fill.BackgroundColor3 = Themes[CurrentTheme].Main
			Fill.BorderSizePixel = 0
			Fill.Size = UDim2.new(0,0,1,0)
			Fill.Parent = Bar
			Instance.new("UICorner",Fill).CornerRadius = UDim.new(1,0)
			local Circle = Instance.new("Frame")
			Circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
			Circle.BorderSizePixel = 0
			Circle.AnchorPoint = Vector2.new(0.5,0.5)
			Circle.Position = UDim2.new(1,0,0.5,0)
			Circle.Size = UDim2.new(0,12,0,12)
			Circle.Parent = Fill
			Instance.new("UICorner",Circle).CornerRadius = UDim.new(1,0)
			local sliding = false
			local function upd(v)
				v = math.clamp(math.floor(v),Min,Max)
				Value = v
				VL.Text = tostring(v)
				local pct = (Max==Min) and 0 or (v-Min)/(Max-Min)
				Fill.Size = UDim2.new(pct,0,1,0)
				if cfg.Flag then Flags[cfg.Flag] = v end
				if cfg.Callback then pcall(cfg.Callback, v) end
			end
			Bar.InputBegan:Connect(function(input)
				if Item:GetAttribute("Locked") then return end
				if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then sliding=true end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then sliding=false end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
					local rel = math.clamp((input.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1)
					upd(Min+rel*(Max-Min))
				end
			end)
			task.defer(function() upd(Value) end)
			local New = {}
			function New:Set(v) upd(v) end
			addLockMethods(New, Item)
			if cfg.Locked then New:Lock(cfg.LockText) end
			return New
		end

		function Items:AddStepper(cfg)
			cfg = cfg or {}
			local Min,Max,Value = cfg.Min or 0, cfg.Max or 10, cfg.Default or cfg.Value or 0
			local Item = makeItem(cfg.Title or "Stepper", cfg.Content or "")
			local H = Instance.new("Frame")
			H.BackgroundTransparency = 1
			H.AnchorPoint = Vector2.new(1,0.5)
			H.Position = UDim2.new(1,-8,0.5,0)
			H.Size = UDim2.new(0,90,0,26)
			H.Parent = Item
			local Minus = Instance.new("TextButton")
			Minus.BackgroundColor3 = Color3.fromRGB(45,45,45)
			Minus.Size = UDim2.new(0,26,0,26)
			Minus.Font = Enum.Font.GothamBold
			Minus.Text = "−"
			Minus.TextColor3 = Color3.fromRGB(255,255,255)
			Minus.TextSize = 16
			Minus.AutoButtonColor = false
			Minus.Parent = H
			Instance.new("UICorner",Minus).CornerRadius = UDim.new(0,6)
			local VL = Instance.new("TextLabel")
			VL.BackgroundTransparency = 1
			VL.Position = UDim2.new(0,28,0,0)
			VL.Size = UDim2.new(0,34,1,0)
			VL.Font = Enum.Font.GothamBold
			VL.Text = tostring(Value)
			VL.TextColor3 = Themes[CurrentTheme].Text
			VL.TextSize = 13
			VL.Parent = H
			local Plus = Instance.new("TextButton")
			Plus.BackgroundColor3 = Color3.fromRGB(45,45,45)
			Plus.Position = UDim2.new(1,-26,0,0)
			Plus.Size = UDim2.new(0,26,0,26)
			Plus.Font = Enum.Font.GothamBold
			Plus.Text = "+"
			Plus.TextColor3 = Color3.fromRGB(255,255,255)
			Plus.TextSize = 16
			Plus.AutoButtonColor = false
			Plus.Parent = H
			Instance.new("UICorner",Plus).CornerRadius = UDim.new(0,6)
			local function set(v)
				Value = math.clamp(v,Min,Max)
				VL.Text = tostring(Value)
				if cfg.Flag then Flags[cfg.Flag] = Value end
				if cfg.Callback then pcall(cfg.Callback, Value) end
			end
			Minus.MouseButton1Click:Connect(function() if not Item:GetAttribute("Locked") then set(Value-1) end end)
			Plus.MouseButton1Click:Connect(function() if not Item:GetAttribute("Locked") then set(Value+1) end end)
			task.defer(function() set(Value) end)
			local New = {}
			function New:Set(v) set(v) end
			addLockMethods(New, Item)
			return New
		end

		function Items:AddInput(cfg)
			cfg = cfg or {}
			local Item = makeItem(cfg.Title or "Input", cfg.Content or cfg.Desc or "")
			local Box = Instance.new("TextBox")
			Box.BackgroundColor3 = Themes[CurrentTheme].Background
			Box.BorderSizePixel = 0
			Box.AnchorPoint = Vector2.new(1,0.5)
			Box.Position = UDim2.new(1,-10,0.5,0)
			Box.Size = UDim2.new(0,120,0,26)
			Box.Font = Enum.Font.Gotham
			Box.PlaceholderText = cfg.Placeholder or "Type..."
			Box.Text = cfg.Default or cfg.Value or ""
			Box.TextColor3 = Themes[CurrentTheme].Text
			Box.TextSize = 12
			Box.ClearTextOnFocus = false
			Box.Parent = Item
			Instance.new("UICorner",Box).CornerRadius = UDim.new(0,6)
			Box.FocusLost:Connect(function()
				if Item:GetAttribute("Locked") then return end
				if cfg.Flag then Flags[cfg.Flag] = Box.Text end
				if cfg.Callback then pcall(cfg.Callback, Box.Text) end
			end)
			local New = {}
			function New:Set(v) Box.Text = v end
			addLockMethods(New, Item)
			return New
		end

		function Items:AddDropdown(cfg)
			cfg = cfg or {}
			local Options = cfg.Options or cfg.List or {}
			local Value = cfg.Default or cfg.Value or Options[1]
			local Multi = cfg.Multi or false
			local Item = makeItem(cfg.Title or "Dropdown", cfg.Content or cfg.Desc or "")
			local Btn = Instance.new("TextButton")
			Btn.BackgroundColor3 = Themes[CurrentTheme].Background
			Btn.BorderSizePixel = 0
			Btn.AnchorPoint = Vector2.new(1,0.5)
			Btn.Position = UDim2.new(1,-10,0.5,0)
			Btn.Size = UDim2.new(0,120,0,26)
			Btn.Font = Enum.Font.Gotham
			Btn.Text = type(Value)=="table" and table.concat(Value,", ") or tostring(Value or "Select")
			Btn.TextColor3 = Themes[CurrentTheme].Text
			Btn.TextSize = 11
			Btn.TextTruncate = Enum.TextTruncate.AtEnd
			Btn.AutoButtonColor = false
			Btn.Parent = Item
			Instance.new("UICorner",Btn).CornerRadius = UDim.new(0,6)
			local New = {Value=Value,Options=Options}
			function New:Set(v)
				Value = v
				New.Value = v
				Btn.Text = type(v)=="table" and table.concat(v,", ") or tostring(v)
				if cfg.Flag then Flags[cfg.Flag] = v end
				if cfg.Callback then pcall(cfg.Callback, v) end
			end
			function New:Refresh(list, sel)
				Options = list or Options
				New.Options = Options
				if sel then New:Set(sel) end
			end
			addLockMethods(New, Item)
			task.defer(function() New:Set(Value) end)
			return New
		end

		function Items:AddSegmented(cfg)
			cfg = cfg or {}
			local Options = cfg.Options or {"A","B"}
			local Value = cfg.Default or cfg.Value or Options[1]
			local Item = makeItem(cfg.Title or "Segmented", "")
			local H = Instance.new("Frame")
			H.BackgroundColor3 = Themes[CurrentTheme].Background
			H.BorderSizePixel = 0
			H.AnchorPoint = Vector2.new(1,0.5)
			H.Position = UDim2.new(1,-10,0.5,0)
			H.Size = UDim2.new(0,math.max(100,#Options*48),0,26)
			H.Parent = Item
			Instance.new("UICorner",H).CornerRadius = UDim.new(0,6)
			local hl = Instance.new("UIListLayout")
			hl.FillDirection = Enum.FillDirection.Horizontal
			hl.Parent = H
			local btns = {}
			for i,opt in ipairs(Options) do
				local B = Instance.new("TextButton")
				B.BackgroundColor3 = opt==Value and Themes[CurrentTheme].Main or Themes[CurrentTheme].Background
				B.Size = UDim2.new(1/#Options,0,1,0)
				B.Font = Enum.Font.GothamBold
				B.Text = opt
				B.TextColor3 = Color3.fromRGB(255,255,255)
				B.TextSize = 11
				B.AutoButtonColor = false
				B.Parent = H
				Instance.new("UICorner",B).CornerRadius = UDim.new(0,6)
				btns[i] = B
				B.MouseButton1Click:Connect(function()
					if Item:GetAttribute("Locked") then return end
					Value = opt
					for j,bb in ipairs(btns) do
						bb.BackgroundColor3 = Options[j]==Value and Themes[CurrentTheme].Main or Themes[CurrentTheme].Background
					end
					if cfg.Callback then pcall(cfg.Callback, Value) end
				end)
			end
			local New = {}
			addLockMethods(New, Item)
			return New
		end

		function Items:AddKeybind(cfg)
			cfg = cfg or {}
			local Key = cfg.Default or cfg.Key or Enum.KeyCode.E
			local Item = makeItem(cfg.Title or "Keybind", cfg.Content or "")
			local Btn = Instance.new("TextButton")
			Btn.BackgroundColor3 = Themes[CurrentTheme].Background
			Btn.BorderSizePixel = 0
			Btn.AnchorPoint = Vector2.new(1,0.5)
			Btn.Position = UDim2.new(1,-10,0.5,0)
			Btn.Size = UDim2.new(0,70,0,26)
			Btn.Font = Enum.Font.GothamBold
			Btn.Text = tostring(Key):gsub("Enum.KeyCode.","")
			Btn.TextColor3 = Themes[CurrentTheme].Text
			Btn.TextSize = 12
			Btn.AutoButtonColor = false
			Btn.Parent = Item
			Instance.new("UICorner",Btn).CornerRadius = UDim.new(0,6)
			local changing = false
			Btn.MouseButton1Click:Connect(function()
				if Item:GetAttribute("Locked") then return end
				changing = true
				Btn.Text = "..."
				local conn
				conn = UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Keyboard then
						Key = input.KeyCode
						Btn.Text = tostring(Key):gsub("Enum.KeyCode.","")
						changing = false
						conn:Disconnect()
						if cfg.Flag then Flags[cfg.Flag] = Key end
						if cfg.Callback then pcall(cfg.Callback, Key) end
					end
				end)
			end)
			local New = {}
			function New:Set(k) Key=k Btn.Text=tostring(k):gsub("Enum.KeyCode.","") end
			addLockMethods(New, Item)
			return New
		end

		function Items:AddColorPicker(cfg)
			cfg = cfg or {}
			local Value = cfg.Default or cfg.Value or Color3.fromRGB(255,255,255)
			local Item = makeItem(cfg.Title or "Color", cfg.Content or "")
			local Prev = Instance.new("Frame")
			Prev.BackgroundColor3 = Value
			Prev.BorderSizePixel = 0
			Prev.AnchorPoint = Vector2.new(1,0.5)
			Prev.Position = UDim2.new(1,-12,0.5,0)
			Prev.Size = UDim2.new(0,24,0,24)
			Prev.Parent = Item
			Instance.new("UICorner",Prev).CornerRadius = UDim.new(1,0)
			local st = Instance.new("UIStroke")
			st.Color = Color3.fromRGB(255,255,255)
			st.Thickness = 1
			st.Transparency = 0.4
			st.Parent = Prev
			local New = {}
			function New:Set(c)
				Value = c
				Prev.BackgroundColor3 = c
				if cfg.Flag then Flags[cfg.Flag] = c end
				if cfg.Callback then pcall(cfg.Callback, math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)) end
			end
			addLockMethods(New, Item)
			return New
		end

		function Items:AddParagraph(cfg)
			cfg = cfg or {}
			local Item = makeItem(cfg.Title or "", cfg.Content or cfg.Desc or "")
			local New = {}
			addLockMethods(New, Item)
			return New
		end

		function Items:Button(cfg) return Items:AddButton(cfg) end
		function Items:Toggle(cfg) return Items:AddToggle(cfg) end
		function Items:Slider(cfg) return Items:AddSlider(cfg) end
		function Items:Stepper(cfg) return Items:AddStepper(cfg) end
		function Items:Textbox(cfg) return Items:AddInput(cfg) end
		function Items:Dropdown(cfg) return Items:AddDropdown(cfg) end
		function Items:Segmented(cfg) return Items:AddSegmented(cfg) end
		function Items:Keybind(cfg) return Items:AddKeybind(cfg) end
		function Items:ColorPicker(cfg) return Items:AddColorPicker(cfg) end
		function Items:Paragraph(cfg) return Items:AddParagraph(cfg) end
		function Items:Section(cfg) return Items:AddSection(cfg) end
		function Items:Label(cfg)
			cfg = cfg or {}
			return Items:AddParagraph({Title=cfg.Title or cfg.Text or "Label"})
		end

		function Items:MultiButton(cfg)
			cfg = cfg or {}
			local Buttons = cfg.Buttons or {}
			ItemCount = ItemCount + 1
			local Item = Instance.new("Frame")
			Item.BackgroundColor3 = Color3.fromRGB(255,255,255)
			Item.BackgroundTransparency = Themes[CurrentTheme].ItemTransparency
			Item:SetAttribute("OrigTrans", Themes[CurrentTheme].ItemTransparency)
			Item.BorderSizePixel = 0
			Item.LayoutOrder = ItemCount
			Item.Size = UDim2.new(1,0,0,70)
			Item.Parent = Page
			Instance.new("UICorner",Item).CornerRadius = UDim.new(0,6)
			local IT = Instance.new("TextLabel")
			IT.Name = "ItemTitle"
			IT.BackgroundTransparency = 1
			IT.Position = UDim2.new(0,10,0,4)
			IT.Size = UDim2.new(1,-20,0,14)
			IT.Font = Enum.Font.GothamBold
			IT.Text = cfg.Title or "Multi"
			IT.TextColor3 = Themes[CurrentTheme].Text
			IT.TextSize = 13
			IT.TextXAlignment = Enum.TextXAlignment.Left
			IT.Parent = Item
			local B1 = Instance.new("TextButton")
			B1.BackgroundColor3 = Themes[CurrentTheme].Main
			B1.Size = UDim2.new(1,-20,0,24)
			B1.Position = UDim2.new(0,10,0,22)
			B1.Font = Enum.Font.GothamBold
			B1.Text = Buttons[1] and Buttons[1].Title or "Button 1"
			B1.TextColor3 = Color3.fromRGB(255,255,255)
			B1.TextSize = 11
			B1.AutoButtonColor = false
			B1.Parent = Item
			Instance.new("UICorner",B1).CornerRadius = UDim.new(0,5)
			B1.MouseButton1Click:Connect(function()
				if not Item:GetAttribute("Locked") and Buttons[1] and Buttons[1].Callback then pcall(Buttons[1].Callback) end
			end)
			local B2 = Instance.new("TextButton")
			B2.BackgroundColor3 = Color3.fromRGB(45,45,45)
			B2.Size = UDim2.new(0.48,-12,0,20)
			B2.Position = UDim2.new(0,10,0,48)
			B2.Font = Enum.Font.GothamBold
			B2.Text = Buttons[2] and Buttons[2].Title or "A"
			B2.TextColor3 = Color3.fromRGB(255,255,255)
			B2.TextSize = 11
			B2.AutoButtonColor = false
			B2.Parent = Item
			Instance.new("UICorner",B2).CornerRadius = UDim.new(0,5)
			B2.MouseButton1Click:Connect(function()
				if not Item:GetAttribute("Locked") and Buttons[2] and Buttons[2].Callback then pcall(Buttons[2].Callback) end
			end)
			local B3 = Instance.new("TextButton")
			B3.BackgroundColor3 = Color3.fromRGB(45,45,45)
			B3.Size = UDim2.new(0.48,-12,0,20)
			B3.Position = UDim2.new(0.52,2,0,48)
			B3.Font = Enum.Font.GothamBold
			B3.Text = Buttons[3] and Buttons[3].Title or "B"
			B3.TextColor3 = Color3.fromRGB(255,255,255)
			B3.TextSize = 11
			B3.AutoButtonColor = false
			B3.Parent = Item
			Instance.new("UICorner",B3).CornerRadius = UDim.new(0,5)
			B3.MouseButton1Click:Connect(function()
				if not Item:GetAttribute("Locked") and Buttons[3] and Buttons[3].Callback then pcall(Buttons[3].Callback) end
			end)
			table.insert(allItems,{Frame=Item})
			local New = {}
			addLockMethods(New, Item)
			return New
		end

		function Items:RangeSlider(cfg)
			cfg = cfg or {}
			local Min,Max = cfg.Min or 0, cfg.Max or 100
			local Value = cfg.Default or cfg.Value or {Min,Max}
			local Item = makeItem(cfg.Title or "Range", "")
			local VL = Instance.new("TextLabel")
			VL.BackgroundTransparency = 1
			VL.AnchorPoint = Vector2.new(1,0.5)
			VL.Position = UDim2.new(1,-10,0.5,0)
			VL.Size = UDim2.new(0,55,0,16)
			VL.Font = Enum.Font.GothamBold
			VL.Text = Value[1].." - "..Value[2]
			VL.TextColor3 = Themes[CurrentTheme].Text
			VL.TextSize = 11
			VL.TextXAlignment = Enum.TextXAlignment.Right
			VL.Parent = Item
			local New = {}
			function New:Set(v) Value=v VL.Text=v[1].." - "..v[2] if cfg.Callback then pcall(cfg.Callback,v) end end
			addLockMethods(New, Item)
			return New
		end

		function Items:Code(cfg)
			cfg = cfg or {}
			ItemCount = ItemCount + 1
			local Item = Instance.new("Frame")
			Item.BackgroundColor3 = Color3.fromRGB(20,20,20)
			Item.BorderSizePixel = 0
			Item.LayoutOrder = ItemCount
			Item.Size = UDim2.new(1,0,0,140)
			Item.Parent = Page
			Instance.new("UICorner",Item).CornerRadius = UDim.new(0,8)
			local colors = {Color3.fromRGB(255,95,86),Color3.fromRGB(255,189,46),Color3.fromRGB(39,201,63)}
			for i=1,3 do
				local c = Instance.new("Frame")
				c.BackgroundColor3 = colors[i]
				c.Position = UDim2.new(0,8+(i-1)*16,0,8)
				c.Size = UDim2.new(0,10,0,10)
				c.Parent = Item
				Instance.new("UICorner",c).CornerRadius = UDim.new(1,0)
			end
			local Box = Instance.new("TextBox")
			Box.BackgroundTransparency = 1
			Box.Position = UDim2.new(0,8,0,24)
			Box.Size = UDim2.new(1,-16,1,-56)
			Box.Font = Enum.Font.Code
			Box.Text = cfg.Code or cfg.Default or "-- code"
			Box.TextColor3 = Color3.fromRGB(200,200,200)
			Box.TextSize = 12
			Box.TextXAlignment = Enum.TextXAlignment.Left
			Box.TextYAlignment = Enum.TextYAlignment.Top
			Box.MultiLine = true
			Box.ClearTextOnFocus = false
			Box.TextWrapped = true
			Box.Parent = Item
			local Copy = Instance.new("TextButton")
			Copy.BackgroundColor3 = Color3.fromRGB(40,40,40)
			Copy.Position = UDim2.new(1,-90,1,-28)
			Copy.Size = UDim2.new(0,40,0,22)
			Copy.Font = Enum.Font.GothamBold
			Copy.Text = "Copy"
			Copy.TextColor3 = Color3.fromRGB(255,255,255)
			Copy.TextSize = 11
			Copy.Parent = Item
			Instance.new("UICorner",Copy).CornerRadius = UDim.new(0,4)
			Copy.MouseButton1Click:Connect(function()
				pcall(setclipboard, Box.Text)
				Copy.Text = "OK"
				task.wait(0.8)
				Copy.Text = "Copy"
			end)
			local Run = Instance.new("TextButton")
			Run.BackgroundColor3 = Themes[CurrentTheme].Main
			Run.Position = UDim2.new(1,-45,1,-28)
			Run.Size = UDim2.new(0,38,0,22)
			Run.Font = Enum.Font.GothamBold
			Run.Text = "Run"
			Run.TextColor3 = Color3.fromRGB(255,255,255)
			Run.TextSize = 11
			Run.Parent = Item
			Instance.new("UICorner",Run).CornerRadius = UDim.new(0,4)
			Run.MouseButton1Click:Connect(function() pcall(loadstring, Box.Text) end)
			table.insert(allItems,{Frame=Item})
			local New = {}
			function New:SetCode(c) Box.Text = c end
			addLockMethods(New, Item)
			return New
		end

		return Items
	end

	function GuiFunc:Tab(cfg) return GuiFunc:CreateTab(cfg) end

	return GuiFunc
end

function Library:Window(p)
	return Library:MakeGui(p)
end

return Library
