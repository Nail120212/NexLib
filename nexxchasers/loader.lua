--[[
    NexxChasers UI Library
    Heavily modified from Euphoria (riq & enrithy)
    Features inspired by WindUI
]]

local LucideIcons = (function()
    local ok, icons = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/Icons/lucide.lua"))()
    end)
    return (ok and icons) or {}
end)()

local function GetLucide(name)
    if not name or name == "" then return nil end
    name = string.lower(tostring(name)):gsub("%s+", "-")
    return LucideIcons[name] or LucideIcons[name:gsub("-", "")] or nil
end

local Service = setmetatable({}, {
    __index = function(self, name)
        rawset(self, name, (cloneref or function(...) return ... end)(game:GetService(name)))
        return rawget(self, name)
    end
})

local UserInputService = Service.UserInputService
local TweenService = Service.TweenService
local CoreGui = Service.CoreGui
local RunService = Service.RunService
local Players = Service.Players
local Camera = workspace.CurrentCamera

-- Themes
local Themes = {
    Dark = {
        Name = "Dark",
        Background = Color3.fromRGB(12, 12, 14),
        BackgroundSecondary = Color3.fromRGB(18, 18, 20),
        Element = Color3.fromRGB(22, 22, 25),
        ElementHover = Color3.fromRGB(30, 30, 34),
        Stroke = Color3.fromRGB(40, 40, 45),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(160, 160, 165),
        TextMuted = Color3.fromRGB(100, 100, 110),
        Accent = Color3.fromRGB(255, 255, 255),
        AccentDark = Color3.fromRGB(0, 0, 0),
        ToggleOn = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(40, 40, 45),
        Slider = Color3.fromRGB(255, 255, 255),
        FloatingStroke = Color3.fromRGB(255, 255, 255),
    },
    Light = {
        Name = "Light",
        Background = Color3.fromRGB(245, 245, 247),
        BackgroundSecondary = Color3.fromRGB(255, 255, 255),
        Element = Color3.fromRGB(235, 235, 238),
        ElementHover = Color3.fromRGB(220, 220, 225),
        Stroke = Color3.fromRGB(200, 200, 210),
        Text = Color3.fromRGB(15, 15, 20),
        TextDim = Color3.fromRGB(80, 80, 90),
        TextMuted = Color3.fromRGB(130, 130, 140),
        Accent = Color3.fromRGB(0, 0, 0),
        AccentDark = Color3.fromRGB(255, 255, 255),
        ToggleOn = Color3.fromRGB(0, 0, 0),
        ToggleOff = Color3.fromRGB(200, 200, 210),
        Slider = Color3.fromRGB(0, 0, 0),
        FloatingStroke = Color3.fromRGB(0, 0, 0),
    }
}

local Library = {
    __current_tab = nil,
    __tabs = {},
    __all_elements = {},
    __window = {},
    __theme = Themes.Dark,
    __transparency = 0.05,
    __ui_scale = 1,
    __device = "pc",
    __minimized = false,
    __dragging = false,
    __resizing = false,
    __drag_start = nil,
    __start_pos = nil,
    __resize_start = nil,
    __size_start = nil,
    __toggle_key = Enum.KeyCode.RightShift,
    __is_open = true,
    __floating = nil,
    __flags = {},
}

Library.__index = Library

local function Tween(obj, props, duration, style)
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function Round(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color or Library.__theme.Stroke
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

function Library:get_device()
    self.__device = UserInputService.TouchEnabled and "mobile" or "pc"
end

function Library:get_screen_scale()
    self.__ui_scale = math.clamp(Camera.ViewportSize.X / 1400, 0.55, 1.15)
end

-- Notifications
local NotificationQueue = {}
local ActiveNotifications = {}

function Library:notify(index)
    local data = {
        title = index.title or "Notification",
        content = index.content or "",
        duration = index.duration or 3,
        type = index.notify_type or "normal"
    }
    table.insert(NotificationQueue, data)
    if #ActiveNotifications < 5 then
        task.spawn(function() self:__spawn_notification() end)
    end
end

function Library:__spawn_notification()
    if #NotificationQueue == 0 then return end
    local data = table.remove(NotificationQueue, 1)
    local gui = self.__window.euphoria
    if not gui then return end

    local theme = self.__theme
    local width = self.__device == "mobile" and 260 or 300
    local height = 68

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(1, -20, 1, -20)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.BackgroundColor3 = theme.BackgroundSecondary
    frame.BackgroundTransparency = self.__transparency
    frame.BorderSizePixel = 0
    frame.ZIndex = 200
    frame.ClipsDescendants = true
    frame.Parent = gui
    Round(frame, 10)
    Stroke(frame, theme.Stroke, 1)

    local iconId = GetLucide(data.type == "error" and "circle-x" or data.type == "warn" and "triangle-alert" or "info") or "rbxassetid://10734888000"
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 22, 0, 22)
    icon.Position = UDim2.new(0, 14, 0.5, -11)
    icon.BackgroundTransparency = 1
    icon.Image = iconId
    icon.ImageColor3 = theme.Text
    icon.ZIndex = 201
    icon.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 0, 20)
    title.Position = UDim2.new(0, 44, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = data.title
    title.TextColor3 = theme.Text
    title.TextSize = 14
    title.Font = Enum.Font.GothamMedium
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 201
    title.Parent = frame

    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -50, 0, 28)
    content.Position = UDim2.new(0, 44, 0, 30)
    content.BackgroundTransparency = 1
    content.Text = data.content
    content.TextColor3 = theme.TextDim
    content.TextSize = 12
    content.Font = Enum.Font.Gotham
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.TextWrapped = true
    content.ZIndex = 201
    content.Parent = frame

    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(0, 0, 0, 2)
    progress.Position = UDim2.new(0, 0, 1, -2)
    progress.BackgroundColor3 = theme.Accent
    progress.BorderSizePixel = 0
    progress.ZIndex = 202
    progress.Parent = frame

    table.insert(ActiveNotifications, frame)

    local y = -16
    for i = #ActiveNotifications - 1, 1, -1 do
        local n = ActiveNotifications[i]
        if n and n.Parent then
            y = y - n.AbsoluteSize.Y - 8
        end
    end

    frame.Position = UDim2.new(1, -20, 1, y)
    Tween(frame, { Size = UDim2.new(0, width, 0, height) }, 0.28)
    Tween(progress, { Size = UDim2.new(1, 0, 0, 2) }, data.duration)

    task.delay(data.duration, function()
        Tween(frame, { BackgroundTransparency = 1 }, 0.25)
        Tween(icon, { ImageTransparency = 1 }, 0.25)
        Tween(title, { TextTransparency = 1 }, 0.25)
        Tween(content, { TextTransparency = 1 }, 0.25)
        Tween(progress, { BackgroundTransparency = 1 }, 0.25)
        Tween(frame, { Size = UDim2.new(0, 0, 0, 0) }, 0.3).Completed:Connect(function()
            frame:Destroy()
            for i, n in ipairs(ActiveNotifications) do
                if n == frame then
                    table.remove(ActiveNotifications, i)
                    break
                end
            end
            if #NotificationQueue > 0 then
                task.spawn(function() self:__spawn_notification() end)
            end
        end)
    end)
end

-- Floating Button
function Library:__create_floating_button(logo)
    local theme = self.__theme
    local gui = self.__window.euphoria

    local holder = Instance.new("Frame")
    holder.Name = "FloatingButton"
    holder.Size = UDim2.new(0, 52, 0, 52)
    holder.Position = UDim2.new(1, -70, 1, -90)
    holder.BackgroundColor3 = theme.BackgroundSecondary
    holder.BackgroundTransparency = self.__transparency
    holder.BorderSizePixel = 0
    holder.ZIndex = 150
    holder.Parent = gui
    Round(holder, 14)
    local stroke = Stroke(holder, theme.FloatingStroke, 1.5)
    stroke.Transparency = 0.15

    local btn = Instance.new("ImageButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Image = logo or GetLucide("layout-dashboard") or "rbxassetid://10734943674"
    btn.ImageColor3 = theme.Text
    btn.ScaleType = Enum.ScaleType.Fit
    btn.ZIndex = 151
    btn.Parent = holder

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = btn

    -- Smooth drag
    local dragging, dragStart, startPos
    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = holder.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Tween(holder, {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }, 0.12, Enum.EasingStyle.Quad)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        if self.__is_open then
            self:Close()
        else
            self:Open()
        end
    end)

    self.__floating = holder
    return holder
end

-- Open / Close with popup animation
function Library:Open()
    if self.__is_open then return end
    self.__is_open = true
    self.__minimized = false

    local main = self.__window.main
    if not main then return end

    main.Visible = true
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1
    main.ClipsDescendants = true

    local targetSize = self.__window.__target_size or UDim2.new(0, 680, 0, 440)
    local targetPos = self.__window.__target_pos or UDim2.new(0.5, -340, 0.5, -220)

    Tween(main, {
        Size = targetSize,
        Position = targetPos,
        BackgroundTransparency = self.__transparency
    }, 0.35, Enum.EasingStyle.Back).Completed:Connect(function()
        main.ClipsDescendants = false
    end)

    if self.__floating then
        Tween(self.__floating, { BackgroundTransparency = 0.4 }, 0.2)
    end
end

function Library:Close()
    if not self.__is_open then return end
    self.__is_open = false
    self.__minimized = true

    local main = self.__window.main
    if not main then return end

    self.__window.__target_size = main.Size
    self.__window.__target_pos = main.Position

    main.ClipsDescendants = true
    Tween(main, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset + main.Size.X.Offset / 2,
                             main.Position.Y.Scale, main.Position.Y.Offset + main.Size.Y.Offset / 2),
        BackgroundTransparency = 1
    }, 0.28, Enum.EasingStyle.Quint).Completed:Connect(function()
        main.Visible = false
    end)

    if self.__floating then
        Tween(self.__floating, { BackgroundTransparency = self.__transparency }, 0.2)
    end
end

function Library:Toggle()
    if self.__is_open then
        self:Close()
    else
        self:Open()
    end
end

-- Main Init
function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "NexxChasers"
    local author = config.Author or ""
    local themeName = config.Theme or "Dark"
    local transparency = config.Transparency or 0.05
    local logo = config.Logo or GetLucide("layout-dashboard") or "rbxassetid://10734943674"
    local toggleKey = config.ToggleKeybind or Enum.KeyCode.RightShift

    self.__theme = Themes[themeName] or Themes.Dark
    self.__transparency = transparency
    self.__toggle_key = typeof(toggleKey) == "EnumItem" and toggleKey or Enum.KeyCode[tostring(toggleKey)] or Enum.KeyCode.RightShift
    self:get_device()

    local theme = self.__theme

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "NexxChasers"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    self.__window.euphoria = gui

    -- Main Window
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.BackgroundColor3 = theme.Background
    main.BackgroundTransparency = 1
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui
    Round(main, 14)
    Stroke(main, theme.Stroke, 1)

    self.__window.main = main

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = main
    if self.__device == "mobile" then
        self:get_screen_scale()
        uiScale.Scale = math.min(self.__ui_scale * 1.1, 1)
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            self:get_screen_scale()
            uiScale.Scale = math.min(self.__ui_scale * 1.1, 1)
        end)
    end

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 52)
    header.BackgroundColor3 = theme.BackgroundSecondary
    header.BackgroundTransparency = transparency
    header.BorderSizePixel = 0
    header.ZIndex = 5
    header.Parent = main
    Round(header, 14)

    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 1)
    headerBottom.Position = UDim2.new(0, 0, 1, -1)
    headerBottom.BackgroundColor3 = theme.Stroke
    headerBottom.BorderSizePixel = 0
    headerBottom.ZIndex = 6
    headerBottom.Parent = header

    -- Logo
    local logoImg = Instance.new("ImageLabel")
    logoImg.Size = UDim2.new(0, 24, 0, 24)
    logoImg.Position = UDim2.new(0, 16, 0.5, -12)
    logoImg.BackgroundTransparency = 1
    logoImg.Image = logo
    logoImg.ImageColor3 = theme.Text
    logoImg.ZIndex = 7
    logoImg.Parent = header

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 200, 0, 20)
    titleLabel.Position = UDim2.new(0, 50, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.Text
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 7
    titleLabel.Parent = header

    -- Author
    if author and author ~= "" then
        local authorLabel = Instance.new("TextLabel")
        authorLabel.Size = UDim2.new(0, 200, 0, 16)
        authorLabel.Position = UDim2.new(0, 50, 0, 28)
        authorLabel.BackgroundTransparency = 1
        authorLabel.Text = author
        authorLabel.TextColor3 = theme.TextMuted
        authorLabel.TextSize = 11
        authorLabel.Font = Enum.Font.Gotham
        authorLabel.TextXAlignment = Enum.TextXAlignment.Left
        authorLabel.ZIndex = 7
        authorLabel.Parent = header
    end

    -- Close (X) button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -14)
    closeBtn.BackgroundColor3 = theme.Element
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.BorderSizePixel = 0
    closeBtn.Image = GetLucide("x") or "rbxassetid://10747384394"
    closeBtn.ImageColor3 = theme.TextDim
    closeBtn.ScaleType = Enum.ScaleType.Fit
    closeBtn.ZIndex = 8
    closeBtn.Parent = header
    Round(closeBtn, 7)

    local closePad = Instance.new("UIPadding")
    closePad.PaddingTop = UDim.new(0, 6)
    closePad.PaddingBottom = UDim.new(0, 6)
    closePad.PaddingLeft = UDim.new(0, 6)
    closePad.PaddingRight = UDim.new(0, 6)
    closePad.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)

    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = theme.ElementHover, ImageColor3 = theme.Text }, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = theme.Element, ImageColor3 = theme.TextDim }, 0.15)
    end)

    -- Search
    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(0, 160, 0, 30)
    searchContainer.Position = UDim2.new(1, -220, 0.5, -15)
    searchContainer.BackgroundColor3 = theme.Element
    searchContainer.BackgroundTransparency = 0.2
    searchContainer.BorderSizePixel = 0
    searchContainer.ZIndex = 7
    searchContainer.Parent = header
    Round(searchContainer, 8)
    Stroke(searchContainer, theme.Stroke, 1)

    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Size = UDim2.new(0, 14, 0, 14)
    searchIcon.Position = UDim2.new(0, 10, 0.5, -7)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = GetLucide("search") or "rbxassetid://10734943674"
    searchIcon.ImageColor3 = theme.TextMuted
    searchIcon.ZIndex = 8
    searchIcon.Parent = searchContainer

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -36, 1, 0)
    searchBox.Position = UDim2.new(0, 30, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search..."
    searchBox.TextColor3 = theme.Text
    searchBox.PlaceholderColor3 = theme.TextMuted
    searchBox.TextSize = 12
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 8
    searchBox.Parent = searchContainer

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower()
        for _, el in pairs(self.__all_elements) do
            local isDiv = el.frame.Name == "Divider" or el.frame.Name == "DividerItem"
            if q == "" then
                el.frame.Visible = true
            else
                if isDiv then
                    el.frame.Visible = false
                else
                    el.frame.Visible = el.name:lower():find(q, 1, true) ~= nil
                end
            end
        end
    end)

    -- Tab Container (left side)
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 150, 1, -70)
    tabContainer.Position = UDim2.new(0, 8, 0, 58)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 3
    tabContainer.ScrollBarImageColor3 = theme.Stroke
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContainer.ZIndex = 4
    tabContainer.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabContainer

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingTop = UDim.new(0, 4)
    tabPad.Parent = tabContainer

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 12)
    end)

    local tabSeparator = Instance.new("Frame")
    tabSeparator.Size = UDim2.new(0, 1, 1, -70)
    tabSeparator.Position = UDim2.new(0, 162, 0, 58)
    tabSeparator.BackgroundColor3 = theme.Stroke
    tabSeparator.BorderSizePixel = 0
    tabSeparator.ZIndex = 4
    tabSeparator.Parent = main

    -- ========== DRAG LINE (bottom center, outside) ==========
    local dragLine = Instance.new("Frame")
    dragLine.Name = "DragLine"
    dragLine.Size = UDim2.new(0, 80, 0, 5)
    dragLine.Position = UDim2.new(0.5, -40, 1, 10)
    dragLine.BackgroundColor3 = theme.TextMuted
    dragLine.BackgroundTransparency = 0.4
    dragLine.BorderSizePixel = 0
    dragLine.ZIndex = 20
    dragLine.Parent = main
    Round(dragLine, 3)

    -- Only drag via the drag line
    local dragInput
    dragLine.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.__dragging = true
            self.__drag_start = input.Position
            self.__start_pos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    self.__dragging = false
                end
            end)
        end
    end)

    dragLine.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and self.__dragging then
            local delta = input.Position - self.__drag_start
            Tween(main, {
                Position = UDim2.new(
                    self.__start_pos.X.Scale,
                    self.__start_pos.X.Offset + delta.X,
                    self.__start_pos.Y.Scale,
                    self.__start_pos.Y.Offset + delta.Y
                )
            }, 0.08, Enum.EasingStyle.Quad)
        end
    end)

    -- Hover effect on drag line
    dragLine.MouseEnter:Connect(function()
        Tween(dragLine, { BackgroundTransparency = 0.1, Size = UDim2.new(0, 100, 0, 5) }, 0.2)
    end)
    dragLine.MouseLeave:Connect(function()
        Tween(dragLine, { BackgroundTransparency = 0.4, Size = UDim2.new(0, 80, 0, 5) }, 0.2)
    end)

    -- ========== RESIZE HANDLE (L-shape bottom-right) ==========
    local resizeHolder = Instance.new("Frame")
    resizeHolder.Name = "ResizeHandle"
    resizeHolder.Size = UDim2.new(0, 28, 0, 28)
    resizeHolder.Position = UDim2.new(1, -28, 1, -28)
    resizeHolder.BackgroundTransparency = 1
    resizeHolder.ZIndex = 25
    resizeHolder.Parent = main

    -- Horizontal part of L
    local resizeH = Instance.new("Frame")
    resizeH.Size = UDim2.new(0, 14, 0, 2)
    resizeH.Position = UDim2.new(1, -18, 1, -6)
    resizeH.BackgroundColor3 = theme.TextMuted
    resizeH.BackgroundTransparency = 0.35
    resizeH.BorderSizePixel = 0
    resizeH.ZIndex = 26
    resizeH.Parent = resizeHolder
    Round(resizeH, 1)

    -- Vertical part of L
    local resizeV = Instance.new("Frame")
    resizeV.Size = UDim2.new(0, 2, 0, 14)
    resizeV.Position = UDim2.new(1, -6, 1, -18)
    resizeV.BackgroundColor3 = theme.TextMuted
    resizeV.BackgroundTransparency = 0.35
    resizeV.BorderSizePixel = 0
    resizeV.ZIndex = 26
    resizeV.Parent = resizeHolder
    Round(resizeV, 1)

    local function startResize(input)
        self.__resizing = true
        self.__resize_start = Vector2.new(input.Position.X, input.Position.Y)
        self.__size_start = main.Size
    end

    resizeHolder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            startResize(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not self.__resizing then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = Vector2.new(input.Position.X, input.Position.Y) - self.__resize_start
        local newW = math.max(420, self.__size_start.X.Offset + delta.X)
        local newH = math.max(300, self.__size_start.Y.Offset + delta.Y)
        main.Size = UDim2.new(0, newW, 0, newH)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.__resizing = false
        end
    end)

    -- Toggle Keybind
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.__toggle_key then
            self:Toggle()
        end
    end)

    -- Floating button
    self:__create_floating_button(logo)

    -- Initial open animation
    task.spawn(function()
        task.wait(0.05)
        local tw = self.__device == "mobile" and math.floor(Camera.ViewportSize.X * 0.9) or 680
        local th = self.__device == "mobile" and math.floor(Camera.ViewportSize.Y * 0.75) or 440
        self.__window.__target_size = UDim2.new(0, tw, 0, th)
        self.__window.__target_pos = UDim2.new(0.5, -tw / 2, 0.5, -th / 2)

        Tween(main, {
            Size = self.__window.__target_size,
            Position = self.__window.__target_pos,
            BackgroundTransparency = transparency
        }, 0.4, Enum.EasingStyle.Back).Completed:Connect(function()
            main.ClipsDescendants = false
        end)
        self.__is_open = true
    end)

    -- Create Tab method
    function Library:create_tab(name, icon)
        local tab = { __library = self }
        local theme = self.__theme

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -8, 0, 36)
        tabBtn.BackgroundColor3 = theme.Element
        tabBtn.BackgroundTransparency = 1
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 5
        tabBtn.Parent = tabContainer
        Round(tabBtn, 8)

        local highlight = Instance.new("Frame")
        highlight.Size = UDim2.new(0, 3, 0.55, 0)
        highlight.Position = UDim2.new(0, 4, 0.225, 0)
        highlight.BackgroundColor3 = theme.Accent
        highlight.BackgroundTransparency = 1
        highlight.BorderSizePixel = 0
        highlight.ZIndex = 6
        highlight.Parent = tabBtn
        Round(highlight, 2)

        local iconImg
        local labelOffset = 12
        local iconId = GetLucide(icon)
        if iconId then
            iconImg = Instance.new("ImageLabel")
            iconImg.Size = UDim2.new(0, 16, 0, 16)
            iconImg.Position = UDim2.new(0, 14, 0.5, -8)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = iconId
            iconImg.ImageColor3 = theme.TextMuted
            iconImg.ZIndex = 6
            iconImg.Parent = tabBtn
            labelOffset = 36
        end

        local tabLabel = Instance.new("TextLabel")
        tabLabel.Size = UDim2.new(1, -labelOffset - 8, 1, 0)
        tabLabel.Position = UDim2.new(0, labelOffset, 0, 0)
        tabLabel.BackgroundTransparency = 1
        tabLabel.Text = name
        tabLabel.TextColor3 = theme.TextMuted
        tabLabel.TextSize = 13
        tabLabel.Font = Enum.Font.GothamMedium
        tabLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabLabel.ZIndex = 6
        tabLabel.Parent = tabBtn

        -- Content container
        local container = Instance.new("ScrollingFrame")
        container.Name = name .. "Container"
        container.Size = UDim2.new(1, -180, 1, -70)
        container.Position = UDim2.new(0, 172, 0, 58)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = theme.Stroke
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.Visible = false
        container.ZIndex = 3
        container.Parent = main

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container

        local cPad = Instance.new("UIPadding")
        cPad.PaddingTop = UDim.new(0, 6)
        cPad.PaddingLeft = UDim.new(0, 4)
        cPad.PaddingRight = UDim.new(0, 10)
        cPad.PaddingBottom = UDim.new(0, 16)
        cPad.Parent = container

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
        end)

        local function activate()
            for _, t in pairs(self.__tabs) do
                t.container.Visible = false
                t.button.BackgroundTransparency = 1
                t.label.TextColor3 = theme.TextMuted
                t.highlight.BackgroundTransparency = 1
                if t.icon then t.icon.ImageColor3 = theme.TextMuted end
            end

            container.Visible = true
            tabBtn.BackgroundTransparency = 0.4
            tabLabel.TextColor3 = theme.Text
            highlight.BackgroundTransparency = 0
            if iconImg then iconImg.ImageColor3 = theme.Text end
            self.__current_tab = tab

            -- Slide-up animation for children
            local order = 0
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Frame") then
                    child.LayoutOrder = order
                    order += 1
                    local orig = child.Position
                    child.Position = UDim2.new(0, 0, 0, 24)
                    child.BackgroundTransparency = 1
                    task.delay(order * 0.035, function()
                        Tween(child, {
                            Position = UDim2.new(0, 0, 0, 0),
                            BackgroundTransparency = child.Name == "Divider" and 1 or 0.25
                        }, 0.28)
                    end)
                end
            end
        end

        tabBtn.MouseButton1Click:Connect(activate)

        tab.button = tabBtn
        tab.container = container
        tab.label = tabLabel
        tab.highlight = highlight
        tab.icon = iconImg

        table.insert(self.__tabs, tab)
        if #self.__tabs == 1 then activate() end

        -- ========== COMPONENTS ==========

        function tab:create_button(index)
            local frame = Instance.new("Frame")
            frame.Name = "Button"
            frame.Size = UDim2.new(1, 0, 0, 40)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 9)
            Stroke(frame, theme.Stroke, 1)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -50, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame

            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.new(0, 16, 0, 16)
            arrow.Position = UDim2.new(1, -30, 0.5, -8)
            arrow.BackgroundTransparency = 1
            arrow.Image = GetLucide("chevron-right") or "rbxassetid://10709791437"
            arrow.ImageColor3 = theme.TextDim
            arrow.ZIndex = 5
            arrow.Parent = frame

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 6
            btn.Parent = frame

            btn.MouseButton1Click:Connect(function()
                Tween(frame, { BackgroundColor3 = theme.ElementHover }, 0.1)
                task.delay(0.12, function()
                    Tween(frame, { BackgroundColor3 = theme.Element }, 0.2)
                end)
                if index.callback then index.callback() end
            end)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })
        end

        function tab:create_divider(text)
            local frame = Instance.new("Frame")
            frame.Name = "Divider"
            frame.Size = UDim2.new(1, 0, 0, 22)
            frame.BackgroundTransparency = 1
            frame.ZIndex = 4
            frame.Parent = container

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 1, 0)
            lbl.Position = UDim2.new(0, 4, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text or ""
            lbl.TextColor3 = theme.TextMuted
            lbl.TextSize = 12
            lbl.Font = Enum.Font.GothamBold
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame

            table.insert(self.__library.__all_elements, { name = text or "", frame = frame })
        end

        function tab:create_checkbox(index)
            local toggled = index.default or false
            local frame = Instance.new("Frame")
            frame.Name = "Checkbox"
            frame.Size = UDim2.new(1, 0, 0, 40)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 9)
            Stroke(frame, theme.Stroke, 1)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -55, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame

            local box = Instance.new("Frame")
            box.Size = UDim2.new(0, 22, 0, 22)
            box.Position = UDim2.new(1, -36, 0.5, -11)
            box.BackgroundColor3 = toggled and theme.ToggleOn or theme.ToggleOff
            box.BorderSizePixel = 0
            box.ZIndex = 5
            box.Parent = frame
            Round(box, 6)
            Stroke(box, theme.Stroke, 1)

            local check = Instance.new("ImageLabel")
            check.Size = UDim2.new(0, 14, 0, 14)
            check.Position = UDim2.new(0.5, -7, 0.5, -7)
            check.BackgroundTransparency = 1
            check.Image = GetLucide("check") or "rbxassetid://10709790644"
            check.ImageColor3 = theme.AccentDark
            check.ImageTransparency = toggled and 0 or 1
            check.ZIndex = 6
            check.Parent = box

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 7
            btn.Parent = frame

            btn.MouseButton1Click:Connect(function()
                toggled = not toggled
                Tween(box, { BackgroundColor3 = toggled and theme.ToggleOn or theme.ToggleOff }, 0.25)
                Tween(check, { ImageTransparency = toggled and 0 or 1 }, 0.25)
                if index.callback then index.callback(toggled) end
            end)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })
        end

        function tab:create_slider(index)
            local min = index.minimum or 0
            local max = index.maximum or 100
            local value = index.default or min
            local rounding = index.rounding or 0
            local callback = index.callback or function() end

            local frame = Instance.new("Frame")
            frame.Name = "Slider"
            frame.Size = UDim2.new(1, 0, 0, 52)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 9)
            Stroke(frame, theme.Stroke, 1)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.6, 0, 0, 20)
            lbl.Position = UDim2.new(0, 14, 0, 8)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame

            local valLbl = Instance.new("TextLabel")
            valLbl.Size = UDim2.new(0.3, 0, 0, 20)
            valLbl.Position = UDim2.new(0.7, -14, 0, 8)
            valLbl.BackgroundTransparency = 1
            valLbl.Text = tostring(value)
            valLbl.TextColor3 = theme.TextDim
            valLbl.TextSize = 13
            valLbl.Font = Enum.Font.GothamMedium
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.ZIndex = 5
            valLbl.Parent = frame

            local trackBg = Instance.new("Frame")
            trackBg.Size = UDim2.new(1, -28, 0, 4)
            trackBg.Position = UDim2.new(0, 14, 1, -16)
            trackBg.BackgroundColor3 = theme.ToggleOff
            trackBg.BorderSizePixel = 0
            trackBg.ZIndex = 5
            trackBg.Parent = frame
            Round(trackBg, 2)

            local track = Instance.new("Frame")
            track.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            track.BackgroundColor3 = theme.Slider
            track.BorderSizePixel = 0
            track.ZIndex = 6
            track.Parent = trackBg
            Round(track, 2)

            local ball = Instance.new("Frame")
            ball.Size = UDim2.new(0, 12, 0, 12)
            ball.Position = UDim2.new(1, -6, 0.5, -6)
            ball.BackgroundColor3 = theme.Slider
            ball.BorderSizePixel = 0
            ball.ZIndex = 7
            ball.Parent = track
            Round(ball, 6)
            Stroke(ball, theme.Stroke, 1)

            local hitbox = Instance.new("Frame")
            hitbox.Size = UDim2.new(1, 0, 0, 20)
            hitbox.Position = UDim2.new(0, 0, 0.5, -10)
            hitbox.BackgroundTransparency = 1
            hitbox.ZIndex = 8
            hitbox.Parent = trackBg

            local dragging = false

            local function update(input)
                local pos = math.clamp((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                value = min + (max - min) * pos
                if rounding > 0 then
                    value = math.floor(value / rounding + 0.5) * rounding
                else
                    value = math.floor(value)
                end
                value = math.clamp(value, min, max)
                valLbl.Text = tostring(value)
                Tween(track, { Size = UDim2.new((value - min) / (max - min), 0, 1, 0) }, 0.08)
                callback(value)
            end

            hitbox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Tween(ball, { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7) }, 0.15)
                    update(input)
                end
            end)

            hitbox.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    Tween(ball, { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6) }, 0.15)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })

            return {
                Set = function(_, v)
                    value = math.clamp(v, min, max)
                    valLbl.Text = tostring(value)
                    track.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    callback(value)
                end
            }
        end

        function tab:create_textbox(index)
            local frame = Instance.new("Frame")
            frame.Name = "Textbox"
            frame.Size = UDim2.new(1, 0, 0, 40)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 9)
            Stroke(frame, theme.Stroke, 1)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, 110, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame

            local inputFrame = Instance.new("Frame")
            inputFrame.Size = UDim2.new(0, 180, 0, 28)
            inputFrame.Position = UDim2.new(1, -194, 0.5, -14)
            inputFrame.BackgroundColor3 = theme.Background
            inputFrame.BackgroundTransparency = 0.3
            inputFrame.BorderSizePixel = 0
            inputFrame.ZIndex = 5
            inputFrame.Parent = frame
            Round(inputFrame, 7)
            Stroke(inputFrame, theme.Stroke, 1)

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -12, 1, 0)
            box.Position = UDim2.new(0, 8, 0, 0)
            box.BackgroundTransparency = 1
            box.Text = ""
            box.PlaceholderText = index.placeholder or ""
            box.TextColor3 = theme.Text
            box.PlaceholderColor3 = theme.TextMuted
            box.TextSize = 12
            box.Font = Enum.Font.Gotham
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.ZIndex = 6
            box.Parent = inputFrame

            box.FocusLost:Connect(function(enter)
                if enter and index.callback then
                    index.callback(box.Text)
                end
            end)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })

            return {
                Set = function(_, text)
                    box.Text = text
                end
            }
        end

        function tab:create_dropdown(index)
            local options = index.options or {}
            local multi = index.multi_selection or false
            local selected = multi and (type(index.default) == "table" and index.default or {}) or (index.default or options[1] or "--")
            local callback = index.callback or function() end
            local opened = false

            local frame = Instance.new("Frame")
            frame.Name = "Dropdown"
            frame.Size = UDim2.new(1, 0, 0, 40)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 10
            frame.ClipsDescendants = false
            frame.Parent = container
            Round(frame, 9)
            Stroke(frame, theme.Stroke, 1)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, 140, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 11
            lbl.Parent = frame

            local drop = Instance.new("Frame")
            drop.Size = UDim2.new(0, 140, 0, 28)
            drop.Position = UDim2.new(1, -154, 0.5, -14)
            drop.BackgroundColor3 = theme.Background
            drop.BackgroundTransparency = 0.2
            drop.BorderSizePixel = 0
            drop.ClipsDescendants = true
            drop.ZIndex = 12
            drop.Parent = frame
            Round(drop, 7)
            Stroke(drop, theme.Stroke, 1)

            local function display()
                if multi then
                    return #selected == 0 and "--" or table.concat(selected, ", ")
                end
                return selected
            end

            local selLbl = Instance.new("TextLabel")
            selLbl.Size = UDim2.new(1, -30, 1, 0)
            selLbl.Position = UDim2.new(0, 8, 0, 0)
            selLbl.BackgroundTransparency = 1
            selLbl.Text = display()
            selLbl.TextColor3 = theme.Text
            selLbl.TextSize = 12
            selLbl.Font = Enum.Font.Gotham
            selLbl.TextXAlignment = Enum.TextXAlignment.Left
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 13
            selLbl.Parent = drop

            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.new(0, 12, 0, 12)
            arrow.Position = UDim2.new(1, -20, 0.5, -6)
            arrow.BackgroundTransparency = 1
            arrow.Image = GetLucide("chevron-down") or "rbxassetid://10709790948"
            arrow.ImageColor3 = theme.TextMuted
            arrow.ZIndex = 13
            arrow.Parent = drop

            local list = Instance.new("ScrollingFrame")
            list.Size = UDim2.new(1, 0, 0, 0)
            list.Position = UDim2.new(0, 0, 0, 30)
            list.BackgroundTransparency = 1
            list.BorderSizePixel = 0
            list.ScrollBarThickness = 2
            list.CanvasSize = UDim2.new(0, 0, 0, 0)
            list.ZIndex = 14
            list.Parent = drop

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 2)
            listLayout.Parent = list

            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, -6, 0, 28)
                optBtn.BackgroundColor3 = theme.Element
                optBtn.BackgroundTransparency = 0.3
                optBtn.BorderSizePixel = 0
                optBtn.Text = opt
                optBtn.TextColor3 = theme.TextDim
                optBtn.TextSize = 12
                optBtn.Font = Enum.Font.Gotham
                optBtn.ZIndex = 15
                optBtn.Parent = list
                Round(optBtn, 5)

                optBtn.MouseButton1Click:Connect(function()
                    if multi then
                        local idx = table.find(selected, opt)
                        if idx then
                            table.remove(selected, idx)
                            optBtn.TextColor3 = theme.TextDim
                        else
                            table.insert(selected, opt)
                            optBtn.TextColor3 = theme.Text
                        end
                        selLbl.Text = display()
                        callback(selected)
                    else
                        selected = opt
                        selLbl.Text = opt
                        callback(opt)
                        -- close
                        opened = false
                        Tween(drop, { Size = UDim2.new(0, 140, 0, 28) }, 0.2)
                        Tween(arrow, { Rotation = 0 }, 0.2)
                        list.Size = UDim2.new(1, 0, 0, 0)
                    end
                end)
            end

            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
            end)

            local openBtn = Instance.new("TextButton")
            openBtn.Size = UDim2.new(1, 0, 0, 28)
            openBtn.BackgroundTransparency = 1
            openBtn.Text = ""
            openBtn.ZIndex = 14
            openBtn.Parent = drop

            openBtn.MouseButton1Click:Connect(function()
                opened = not opened
                local h = math.min(#options * 30, 140)
                if opened then
                    list.Size = UDim2.new(1, 0, 0, h)
                    Tween(drop, { Size = UDim2.new(0, 140, 0, 32 + h) }, 0.25)
                    Tween(arrow, { Rotation = 180 }, 0.25)
                else
                    Tween(drop, { Size = UDim2.new(0, 140, 0, 28) }, 0.2)
                    Tween(arrow, { Rotation = 0 }, 0.2)
                    list.Size = UDim2.new(1, 0, 0, 0)
                end
            end)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })

            return {
                Set = function(_, v)
                    selected = v
                    selLbl.Text = display()
                    callback(selected)
                end
            }
        end

        function tab:create_module(index)
            -- Simplified module (toggle + expandable children)
            local toggled = index.default or false
            local callback = index.callback or function() end
            local module = { __elements = {}, __library = self.__library }

            local frame = Instance.new("Frame")
            frame.Name = "Module"
            frame.Size = UDim2.new(1, 0, 0, 40)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ClipsDescendants = false
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 9)
            Stroke(frame, theme.Stroke, 1)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -70, 0, 40)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame

            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(0, 42, 0, 22)
            toggleFrame.Position = UDim2.new(1, -52, 0, 9)
            toggleFrame.BackgroundColor3 = toggled and theme.ToggleOn or theme.ToggleOff
            toggleFrame.BorderSizePixel = 0
            toggleFrame.ZIndex = 5
            toggleFrame.Parent = frame
            Round(toggleFrame, 11)
            Stroke(toggleFrame, theme.Stroke, 1)

            local circle = Instance.new("Frame")
            circle.Size = UDim2.new(0, 16, 0, 16)
            circle.Position = toggled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            circle.BackgroundColor3 = toggled and theme.AccentDark or theme.Text
            circle.BorderSizePixel = 0
            circle.ZIndex = 6
            circle.Parent = toggleFrame
            Round(circle, 8)

            local childrenHolder = Instance.new("Frame")
            childrenHolder.Size = UDim2.new(1, 0, 0, 0)
            childrenHolder.Position = UDim2.new(0, 0, 0, 42)
            childrenHolder.BackgroundTransparency = 1
            childrenHolder.Visible = false
            childrenHolder.ZIndex = 5
            childrenHolder.Parent = frame

            local childLayout = Instance.new("UIListLayout")
            childLayout.Padding = UDim.new(0, 4)
            childLayout.Parent = childrenHolder

            local function updateHeight()
                local h = 40
                if toggled and #module.__elements > 0 then
                    for _, e in pairs(module.__elements) do
                        h = h + e.Size.Y.Offset + 4
                    end
                    h = h + 8
                end
                Tween(frame, { Size = UDim2.new(1, 0, 0, h) }, 0.25)
            end

            local function setToggle(state)
                toggled = state
                Tween(toggleFrame, { BackgroundColor3 = toggled and theme.ToggleOn or theme.ToggleOff }, 0.25)
                Tween(circle, {
                    Position = toggled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                    BackgroundColor3 = toggled and theme.AccentDark or theme.Text
                }, 0.25)
                childrenHolder.Visible = toggled and #module.__elements > 0
                updateHeight()
                callback(toggled)
            end

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -60, 0, 40)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 7
            btn.Parent = frame
            btn.MouseButton1Click:Connect(function() setToggle(not toggled) end)

            local tBtn = Instance.new("TextButton")
            tBtn.Size = UDim2.new(0, 42, 0, 22)
            tBtn.Position = UDim2.new(1, -52, 0, 9)
            tBtn.BackgroundTransparency = 1
            tBtn.Text = ""
            tBtn.ZIndex = 8
            tBtn.Parent = frame
            tBtn.MouseButton1Click:Connect(function() setToggle(not toggled) end)

            -- Module children helpers (simplified)
            function module:create_checkbox(idx)
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, -12, 0, 32)
                f.BackgroundColor3 = theme.Background
                f.BackgroundTransparency = 0.3
                f.BorderSizePixel = 0
                f.Parent = childrenHolder
                Round(f, 6)
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, -40, 1, 0)
                l.Position = UDim2.new(0, 10, 0, 0)
                l.BackgroundTransparency = 1
                l.Text = idx.title
                l.TextColor3 = theme.TextDim
                l.TextSize = 12
                l.Font = Enum.Font.Gotham
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.Parent = f
                table.insert(module.__elements, f)
                if toggled then updateHeight() end
            end

            function module:create_button(idx)
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, -12, 0, 32)
                f.BackgroundColor3 = theme.Background
                f.BackgroundTransparency = 0.3
                f.BorderSizePixel = 0
                f.Parent = childrenHolder
                Round(f, 6)
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, -10, 1, 0)
                l.Position = UDim2.new(0, 10, 0, 0)
                l.BackgroundTransparency = 1
                l.Text = idx.title
                l.TextColor3 = theme.TextDim
                l.TextSize = 12
                l.Font = Enum.Font.Gotham
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.Parent = f
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, 0, 1, 0)
                b.BackgroundTransparency = 1
                b.Text = ""
                b.Parent = f
                b.MouseButton1Click:Connect(function()
                    if idx.callback then idx.callback() end
                end)
                table.insert(module.__elements, f)
                if toggled then updateHeight() end
            end

            function module:create_slider(idx) end
            function module:create_textbox(idx) end
            function module:create_dropdown(idx) end
            function module:create_divider(t) end

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })
            return module
        end

        return tab
    end

    return self
end

-- Compatibility alias
Library.init = Library.CreateWindow

return Library
