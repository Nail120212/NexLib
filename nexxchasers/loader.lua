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
local Players = Service.Players
local Camera = workspace.CurrentCamera
local HttpService = Service.HttpService

local Themes = {
    Dark = {
        Name = "Dark",
        Background = Color3.fromRGB(14, 14, 16),
        BackgroundSecondary = Color3.fromRGB(20, 20, 23),
        Element = Color3.fromRGB(26, 26, 30),
        ElementHover = Color3.fromRGB(34, 34, 40),
        Stroke = Color3.fromRGB(48, 48, 55),
        Text = Color3.fromRGB(245, 245, 250),
        TextDim = Color3.fromRGB(175, 175, 185),
        TextMuted = Color3.fromRGB(115, 115, 125),
        Accent = Color3.fromRGB(255, 255, 255),
        AccentDark = Color3.fromRGB(12, 12, 14),
        ToggleOn = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(45, 45, 52),
        Slider = Color3.fromRGB(255, 255, 255),
        FloatingStroke = Color3.fromRGB(255, 255, 255),
        Locked = Color3.fromRGB(90, 90, 100),
        Success = Color3.fromRGB(80, 200, 120),
        Error = Color3.fromRGB(240, 80, 80),
        Warning = Color3.fromRGB(240, 180, 60),
    },
    Light = {
        Name = "Light",
        Background = Color3.fromRGB(248, 248, 250),
        BackgroundSecondary = Color3.fromRGB(255, 255, 255),
        Element = Color3.fromRGB(238, 238, 242),
        ElementHover = Color3.fromRGB(225, 225, 232),
        Stroke = Color3.fromRGB(210, 210, 220),
        Text = Color3.fromRGB(18, 18, 22),
        TextDim = Color3.fromRGB(70, 70, 80),
        TextMuted = Color3.fromRGB(130, 130, 140),
        Accent = Color3.fromRGB(20, 20, 25),
        AccentDark = Color3.fromRGB(255, 255, 255),
        ToggleOn = Color3.fromRGB(20, 20, 25),
        ToggleOff = Color3.fromRGB(200, 200, 210),
        Slider = Color3.fromRGB(20, 20, 25),
        FloatingStroke = Color3.fromRGB(30, 30, 35),
        Locked = Color3.fromRGB(150, 150, 160),
        Success = Color3.fromRGB(40, 160, 90),
        Error = Color3.fromRGB(200, 50, 50),
        Warning = Color3.fromRGB(200, 140, 30),
    }
}

local Library = {
    __current_tab = nil,
    __tabs = {},
    __all_elements = {},
    __window = {},
    __theme = Themes.Dark,
    __theme_name = "Dark",
    __transparency = 0.06,
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
    __config_folder = "NexxChasers",
    __themed_objects = {},
}

Library.__index = Library

local function Tween(obj, props, duration, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.28, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
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

local function TrackTheme(obj, prop, key)
    table.insert(Library.__themed_objects, { obj = obj, prop = prop, key = key })
end

function Library:ApplyTheme(name)
    local theme = Themes[name]
    if not theme then return end
    self.__theme = theme
    self.__theme_name = name
    for _, entry in ipairs(self.__themed_objects) do
        if entry.obj and entry.obj.Parent then
            local val = theme[entry.key]
            if val ~= nil then
                pcall(function()
                    entry.obj[entry.prop] = val
                end)
            end
        end
    end
    local main = self.__window.main
    if main then
        main.BackgroundColor3 = theme.Background
        for _, child in ipairs(main:GetDescendants()) do
            if child:IsA("UIStroke") then child.Color = theme.Stroke end
        end
    end
    if self.__floating then
        self.__floating.BackgroundColor3 = theme.BackgroundSecondary
        local s = self.__floating:FindFirstChildOfClass("UIStroke")
        if s then s.Color = theme.FloatingStroke end
        local img = self.__floating:FindFirstChildWhichIsA("ImageButton")
        if img then img.ImageColor3 = theme.Text end
    end
end

function Library:SetTheme(name)
    self:ApplyTheme(name)
end

function Library:get_device()
    self.__device = UserInputService.TouchEnabled and "mobile" or "pc"
end

function Library:get_screen_scale()
    self.__ui_scale = math.clamp(Camera.ViewportSize.X / 1400, 0.55, 1.15)
end

local NotificationQueue = {}
local ActiveNotifications = {}

function Library:notify(index)
    table.insert(NotificationQueue, {
        title = index.title or "Notification",
        content = index.content or "",
        duration = index.duration or 3,
        type = index.notify_type or "normal"
    })
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
    local width = self.__device == "mobile" and 270 or 310
    local height = 72

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(1, -18, 1, -18)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.BackgroundColor3 = theme.BackgroundSecondary
    frame.BackgroundTransparency = self.__transparency
    frame.BorderSizePixel = 0
    frame.ZIndex = 300
    frame.ClipsDescendants = true
    frame.Parent = gui
    Round(frame, 12)
    Stroke(frame, theme.Stroke, 1)

    local iconName = data.type == "error" and "circle-x" or data.type == "warn" and "triangle-alert" or "info"
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 22, 0, 22)
    icon.Position = UDim2.new(0, 14, 0.5, -11)
    icon.BackgroundTransparency = 1
    icon.Image = GetLucide(iconName) or "rbxassetid://10734888000"
    icon.ImageColor3 = data.type == "error" and theme.Error or data.type == "warn" and theme.Warning or theme.Text
    icon.ZIndex = 301
    icon.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -52, 0, 20)
    title.Position = UDim2.new(0, 46, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = data.title
    title.TextColor3 = theme.Text
    title.TextSize = 14
    title.Font = Enum.Font.GothamMedium
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 301
    title.Parent = frame

    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -52, 0, 28)
    content.Position = UDim2.new(0, 46, 0, 32)
    content.BackgroundTransparency = 1
    content.Text = data.content
    content.TextColor3 = theme.TextDim
    content.TextSize = 12
    content.Font = Enum.Font.Gotham
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.TextWrapped = true
    content.ZIndex = 301
    content.Parent = frame

    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(0, 0, 0, 2)
    progress.Position = UDim2.new(0, 0, 1, -2)
    progress.BackgroundColor3 = theme.Accent
    progress.BorderSizePixel = 0
    progress.ZIndex = 302
    progress.Parent = frame

    table.insert(ActiveNotifications, frame)
    local y = -14
    for i = #ActiveNotifications - 1, 1, -1 do
        local n = ActiveNotifications[i]
        if n and n.Parent then
            y = y - (n.AbsoluteSize.Y > 0 and n.AbsoluteSize.Y or height) - 8
        end
    end
    frame.Position = UDim2.new(1, -18, 1, y)
    Tween(frame, { Size = UDim2.new(0, width, 0, height) }, 0.3, Enum.EasingStyle.Back)
    Tween(progress, { Size = UDim2.new(1, 0, 0, 2) }, data.duration, Enum.EasingStyle.Linear)

    task.delay(data.duration, function()
        Tween(frame, { BackgroundTransparency = 1 }, 0.22)
        Tween(icon, { ImageTransparency = 1 }, 0.22)
        Tween(title, { TextTransparency = 1 }, 0.22)
        Tween(content, { TextTransparency = 1 }, 0.22)
        Tween(progress, { BackgroundTransparency = 1 }, 0.22)
        Tween(frame, { Size = UDim2.new(0, 0, 0, 0) }, 0.28).Completed:Connect(function()
            frame:Destroy()
            for i, n in ipairs(ActiveNotifications) do
                if n == frame then table.remove(ActiveNotifications, i) break end
            end
            if #NotificationQueue > 0 then
                task.spawn(function() self:__spawn_notification() end)
            end
        end)
    end)
end

function Library:Dialog(index)
    local theme = self.__theme
    local gui = self.__window.euphoria
    if not gui then return end

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 400
    overlay.Parent = gui

    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0, 0, 0, 0)
    dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
    dialog.AnchorPoint = Vector2.new(0.5, 0.5)
    dialog.BackgroundColor3 = theme.BackgroundSecondary
    dialog.BackgroundTransparency = self.__transparency
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 401
    dialog.ClipsDescendants = true
    dialog.Parent = overlay
    Round(dialog, 14)
    Stroke(dialog, theme.Stroke, 1)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 28)
    title.Position = UDim2.new(0, 20, 0, 16)
    title.BackgroundTransparency = 1
    title.Text = index.Title or "Dialog"
    title.TextColor3 = theme.Text
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 402
    title.Parent = dialog

    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -40, 0, 60)
    content.Position = UDim2.new(0, 20, 0, 48)
    content.BackgroundTransparency = 1
    content.Text = index.Content or ""
    content.TextColor3 = theme.TextDim
    content.TextSize = 13
    content.Font = Enum.Font.Gotham
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.TextWrapped = true
    content.ZIndex = 402
    content.Parent = dialog

    local btnHolder = Instance.new("Frame")
    btnHolder.Size = UDim2.new(1, -40, 0, 36)
    btnHolder.Position = UDim2.new(0, 20, 1, -52)
    btnHolder.BackgroundTransparency = 1
    btnHolder.ZIndex = 402
    btnHolder.Parent = dialog

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    btnLayout.Padding = UDim.new(0, 8)
    btnLayout.Parent = btnHolder

    local function close()
        Tween(overlay, { BackgroundTransparency = 1 }, 0.2)
        Tween(dialog, { Size = UDim2.new(0, 0, 0, 0) }, 0.25).Completed:Connect(function()
            overlay:Destroy()
        end)
    end

    for _, b in ipairs(index.Buttons or { { Title = "OK" } }) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 90, 0, 34)
        btn.BackgroundColor3 = theme.Element
        btn.BorderSizePixel = 0
        btn.Text = b.Title or "OK"
        btn.TextColor3 = theme.Text
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamMedium
        btn.ZIndex = 403
        btn.Parent = btnHolder
        Round(btn, 8)
        Stroke(btn, theme.Stroke, 1)
        btn.MouseButton1Click:Connect(function()
            if b.Callback then b.Callback() end
            close()
        end)
    end

    Tween(overlay, { BackgroundTransparency = 0.45 }, 0.25)
    Tween(dialog, { Size = UDim2.new(0, 360, 0, 180) }, 0.32, Enum.EasingStyle.Back)
end

function Library:__create_floating_button(logo)
    local theme = self.__theme
    local gui = self.__window.euphoria

    local holder = Instance.new("Frame")
    holder.Name = "FloatingButton"
    holder.Size = UDim2.new(0, 56, 0, 56)
    holder.Position = UDim2.new(1, -80, 1, -100)
    holder.BackgroundColor3 = theme.BackgroundSecondary
    holder.BackgroundTransparency = self.__transparency
    holder.BorderSizePixel = 0
    holder.ZIndex = 150
    holder.Parent = gui
    Round(holder, 28)
    local stroke = Stroke(holder, theme.FloatingStroke, 1.5)
    stroke.Transparency = 0.2

    local btn = Instance.new("ImageButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Image = logo or GetLucide("layout-dashboard") or "rbxassetid://10734943674"
    btn.ImageColor3 = theme.Text
    btn.ScaleType = Enum.ScaleType.Fit
    btn.ZIndex = 151
    btn.Parent = holder

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 14)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = btn

    local dragging, dragStart, startPos, moved
    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = holder.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved then
                        if self.__is_open then self:Close() else self:Open() end
                    end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then moved = true end
            Tween(holder, {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }, 0.1, Enum.EasingStyle.Quad)
        end
    end)

    self.__floating = holder
    return holder
end

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
    local ts = self.__window.__target_size or UDim2.new(0, 700, 0, 460)
    local tp = self.__window.__target_pos or UDim2.new(0.5, 0, 0.5, 0)
    Tween(main, { Size = ts, Position = tp, BackgroundTransparency = self.__transparency }, 0.38, Enum.EasingStyle.Back).Completed:Connect(function()
        main.ClipsDescendants = false
    end)
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
        Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset),
        BackgroundTransparency = 1
    }, 0.28).Completed:Connect(function()
        main.Visible = false
    end)
end

function Library:Toggle()
    if self.__is_open then self:Close() else self:Open() end
end

function Library:SaveConfig(name)
    if not writefile then return end
    pcall(function()
        if not isfolder(self.__config_folder) then makefolder(self.__config_folder) end
        writefile(self.__config_folder .. "/" .. (name or "config") .. ".json", HttpService:JSONEncode(self.__flags))
    end)
end

function Library:LoadConfig(name)
    if not readfile then return end
    pcall(function()
        local path = self.__config_folder .. "/" .. (name or "config") .. ".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for k, v in pairs(data) do
                self.__flags[k] = v
            end
        end
    end)
end


function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "NexxChasers"
    local author = config.Author or ""
    local themeName = config.Theme or "Dark"
    local transparency = config.Transparency or 0.06
    local logo = config.Logo
    if type(logo) == "string" and not tostring(logo):find("rbxasset") then
        logo = GetLucide(logo) or logo
    end
    logo = logo or GetLucide("layout-dashboard") or "rbxassetid://10734943674"
    local toggleKey = config.ToggleKeybind or Enum.KeyCode.RightShift
    self.__config_folder = config.Folder or "NexxChasers"
    self.__theme = Themes[themeName] or Themes.Dark
    self.__theme_name = themeName
    self.__transparency = transparency
    self.__toggle_key = typeof(toggleKey) == "EnumItem" and toggleKey or Enum.KeyCode[tostring(toggleKey)] or Enum.KeyCode.RightShift
    self:get_device()
    local theme = self.__theme

    local gui = Instance.new("ScreenGui")
    gui.Name = "NexxChasers"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
    self.__window.euphoria = gui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = theme.Background
    main.BackgroundTransparency = 1
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui
    Round(main, 14)
    Stroke(main, theme.Stroke, 1)
    TrackTheme(main, "BackgroundColor3", "Background")
    self.__window.main = main

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = main
    if self.__device == "mobile" then
        self:get_screen_scale()
        uiScale.Scale = math.min(self.__ui_scale * 1.05, 1)
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            self:get_screen_scale()
            uiScale.Scale = math.min(self.__ui_scale * 1.05, 1)
        end)
    end

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 54)
    header.BackgroundColor3 = theme.BackgroundSecondary
    header.BackgroundTransparency = transparency
    header.BorderSizePixel = 0
    header.ZIndex = 5
    header.Parent = main
    Round(header, 14)
    TrackTheme(header, "BackgroundColor3", "BackgroundSecondary")

    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 1, -1)
    headerLine.BackgroundColor3 = theme.Stroke
    headerLine.BorderSizePixel = 0
    headerLine.ZIndex = 6
    headerLine.Parent = header
    TrackTheme(headerLine, "BackgroundColor3", "Stroke")

    local logoImg = Instance.new("ImageLabel")
    logoImg.Size = UDim2.new(0, 26, 0, 26)
    logoImg.Position = UDim2.new(0, 16, 0.5, -13)
    logoImg.BackgroundTransparency = 1
    logoImg.Image = logo
    logoImg.ImageColor3 = theme.Text
    logoImg.ZIndex = 7
    logoImg.Parent = header
    TrackTheme(logoImg, "ImageColor3", "Text")

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 220, 0, 20)
    titleLabel.Position = UDim2.new(0, 52, 0, 9)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.Text
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 7
    titleLabel.Parent = header
    TrackTheme(titleLabel, "TextColor3", "Text")

    if author and author ~= "" then
        local authorLabel = Instance.new("TextLabel")
        authorLabel.Size = UDim2.new(0, 220, 0, 16)
        authorLabel.Position = UDim2.new(0, 52, 0, 29)
        authorLabel.BackgroundTransparency = 1
        authorLabel.Text = author
        authorLabel.TextColor3 = theme.TextMuted
        authorLabel.TextSize = 11
        authorLabel.Font = Enum.Font.Gotham
        authorLabel.TextXAlignment = Enum.TextXAlignment.Left
        authorLabel.ZIndex = 7
        authorLabel.Parent = header
        TrackTheme(authorLabel, "TextColor3", "TextMuted")
    end

    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -42, 0.5, -15)
    closeBtn.BackgroundColor3 = theme.Element
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.BorderSizePixel = 0
    closeBtn.Image = GetLucide("x") or "rbxassetid://10747384394"
    closeBtn.ImageColor3 = theme.TextDim
    closeBtn.ScaleType = Enum.ScaleType.Fit
    closeBtn.ZIndex = 8
    closeBtn.Parent = header
    Round(closeBtn, 8)
    TrackTheme(closeBtn, "BackgroundColor3", "Element")
    TrackTheme(closeBtn, "ImageColor3", "TextDim")
    local closePad = Instance.new("UIPadding")
    closePad.PaddingTop = UDim.new(0, 7)
    closePad.PaddingBottom = UDim.new(0, 7)
    closePad.PaddingLeft = UDim.new(0, 7)
    closePad.PaddingRight = UDim.new(0, 7)
    closePad.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function() self:Close() end)
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = theme.ElementHover, ImageColor3 = theme.Text }, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = theme.Element, ImageColor3 = theme.TextDim }, 0.15)
    end)

    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(0, 150, 0, 30)
    searchContainer.Position = UDim2.new(1, -210, 0.5, -15)
    searchContainer.BackgroundColor3 = theme.Element
    searchContainer.BackgroundTransparency = 0.15
    searchContainer.BorderSizePixel = 0
    searchContainer.ZIndex = 7
    searchContainer.Parent = header
    Round(searchContainer, 8)
    Stroke(searchContainer, theme.Stroke, 1)
    TrackTheme(searchContainer, "BackgroundColor3", "Element")

    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Size = UDim2.new(0, 14, 0, 14)
    searchIcon.Position = UDim2.new(0, 10, 0.5, -7)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = GetLucide("search") or "rbxassetid://10734943674"
    searchIcon.ImageColor3 = theme.TextMuted
    searchIcon.ZIndex = 8
    searchIcon.Parent = searchContainer

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -34, 1, 0)
    searchBox.Position = UDim2.new(0, 28, 0, 0)
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
    TrackTheme(searchBox, "TextColor3", "Text")

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower()
        for _, el in pairs(self.__all_elements) do
            local isDiv = el.frame.Name == "Divider" or el.frame.Name == "DividerItem"
            if q == "" then
                el.frame.Visible = true
            else
                if isDiv then el.frame.Visible = false
                else el.frame.Visible = el.name:lower():find(q, 1, true) ~= nil end
            end
        end
    end)

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 152, 1, -72)
    tabContainer.Position = UDim2.new(0, 8, 0, 60)
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
    tabSeparator.Size = UDim2.new(0, 1, 1, -72)
    tabSeparator.Position = UDim2.new(0, 164, 0, 60)
    tabSeparator.BackgroundColor3 = theme.Stroke
    tabSeparator.BorderSizePixel = 0
    tabSeparator.ZIndex = 4
    tabSeparator.Parent = main
    TrackTheme(tabSeparator, "BackgroundColor3", "Stroke")

    local dragLine = Instance.new("Frame")
    dragLine.Name = "DragLine"
    dragLine.Size = UDim2.new(0, 120, 0, 6)
    dragLine.Position = UDim2.new(0.5, -60, 1, 14)
    dragLine.BackgroundColor3 = theme.TextDim
    dragLine.BackgroundTransparency = 0.2
    dragLine.BorderSizePixel = 0
    dragLine.ZIndex = 30
    dragLine.Parent = main
    Round(dragLine, 3)
    TrackTheme(dragLine, "BackgroundColor3", "TextDim")

    local dragInput
    dragLine.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.__dragging = true
            self.__drag_start = input.Position
            self.__start_pos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then self.__dragging = false end
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
                Position = UDim2.new(self.__start_pos.X.Scale, self.__start_pos.X.Offset + delta.X, self.__start_pos.Y.Scale, self.__start_pos.Y.Offset + delta.Y)
            }, 0.08, Enum.EasingStyle.Quad)
        end
    end)
    dragLine.MouseEnter:Connect(function()
        Tween(dragLine, { BackgroundTransparency = 0.05, Size = UDim2.new(0, 140, 0, 6) }, 0.18)
    end)
    dragLine.MouseLeave:Connect(function()
        Tween(dragLine, { BackgroundTransparency = 0.2, Size = UDim2.new(0, 120, 0, 6) }, 0.18)
    end)

    local resizeHolder = Instance.new("Frame")
    resizeHolder.Name = "ResizeHandle"
    resizeHolder.Size = UDim2.new(0, 36, 0, 36)
    resizeHolder.Position = UDim2.new(1, 6, 1, 6)
    resizeHolder.BackgroundTransparency = 1
    resizeHolder.ZIndex = 30
    resizeHolder.Parent = main

    local resizeH = Instance.new("Frame")
    resizeH.Size = UDim2.new(0, 18, 0, 3)
    resizeH.Position = UDim2.new(1, -22, 1, -8)
    resizeH.BackgroundColor3 = theme.TextDim
    resizeH.BackgroundTransparency = 0.15
    resizeH.BorderSizePixel = 0
    resizeH.ZIndex = 31
    resizeH.Parent = resizeHolder
    Round(resizeH, 1)
    TrackTheme(resizeH, "BackgroundColor3", "TextDim")

    local resizeV = Instance.new("Frame")
    resizeV.Size = UDim2.new(0, 3, 0, 18)
    resizeV.Position = UDim2.new(1, -8, 1, -22)
    resizeV.BackgroundColor3 = theme.TextDim
    resizeV.BackgroundTransparency = 0.15
    resizeV.BorderSizePixel = 0
    resizeV.ZIndex = 31
    resizeV.Parent = resizeHolder
    Round(resizeV, 1)
    TrackTheme(resizeV, "BackgroundColor3", "TextDim")

    resizeHolder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.__resizing = true
            self.__resize_start = Vector2.new(input.Position.X, input.Position.Y)
            self.__size_start = main.Size
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not self.__resizing then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = Vector2.new(input.Position.X, input.Position.Y) - self.__resize_start
        local newW = math.max(440, self.__size_start.X.Offset + delta.X)
        local newH = math.max(320, self.__size_start.Y.Offset + delta.Y)
        main.Size = UDim2.new(0, newW, 0, newH)
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.__resizing = false
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.__toggle_key then self:Toggle() end
    end)

    self:__create_floating_button(logo)

    task.spawn(function()
        task.wait(0.04)
        local tw = self.__device == "mobile" and math.floor(Camera.ViewportSize.X * 0.9) or 700
        local th = self.__device == "mobile" and math.floor(Camera.ViewportSize.Y * 0.72) or 460
        self.__window.__target_size = UDim2.new(0, tw, 0, th)
        self.__window.__target_pos = UDim2.new(0.5, 0, 0.5, 0)
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        Tween(main, {
            Size = self.__window.__target_size,
            Position = self.__window.__target_pos,
            BackgroundTransparency = transparency
        }, 0.42, Enum.EasingStyle.Back).Completed:Connect(function()
            main.ClipsDescendants = false
        end)
        self.__is_open = true
    end)

    function Library:create_tab(name, icon)
        local tab = { __library = self }
        local theme = self.__theme

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -8, 0, 38)
        tabBtn.BackgroundColor3 = theme.Element
        tabBtn.BackgroundTransparency = 1
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 5
        tabBtn.Parent = tabContainer
        Round(tabBtn, 9)
        TrackTheme(tabBtn, "BackgroundColor3", "Element")

        local highlight = Instance.new("Frame")
        highlight.Size = UDim2.new(0, 3, 0.55, 0)
        highlight.Position = UDim2.new(0, 4, 0.225, 0)
        highlight.BackgroundColor3 = theme.Accent
        highlight.BackgroundTransparency = 1
        highlight.BorderSizePixel = 0
        highlight.ZIndex = 6
        highlight.Parent = tabBtn
        Round(highlight, 2)
        TrackTheme(highlight, "BackgroundColor3", "Accent")

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
            TrackTheme(iconImg, "ImageColor3", "TextMuted")
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
        TrackTheme(tabLabel, "TextColor3", "TextMuted")

        local container = Instance.new("ScrollingFrame")
        container.Name = name .. "Container"
        container.Size = UDim2.new(1, -182, 1, -72)
        container.Position = UDim2.new(0, 174, 0, 60)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = theme.Stroke
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.Visible = false
        container.ZIndex = 3
        container.Parent = main

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 7)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container
        local cPad = Instance.new("UIPadding")
        cPad.PaddingTop = UDim.new(0, 6)
        cPad.PaddingLeft = UDim.new(0, 4)
        cPad.PaddingRight = UDim.new(0, 10)
        cPad.PaddingBottom = UDim.new(0, 18)
        cPad.Parent = container
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 26)
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
            tabBtn.BackgroundTransparency = 0.35
            tabLabel.TextColor3 = theme.Text
            highlight.BackgroundTransparency = 0
            if iconImg then iconImg.ImageColor3 = theme.Text end
            self.__current_tab = tab
            local order = 0
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Frame") then
                    child.LayoutOrder = order
                    order += 1
                    child.Position = UDim2.new(0, 0, 0, 22)
                    local targetTrans = child.Name == "Divider" and 1 or 0.2
                    child.BackgroundTransparency = 1
                    task.delay(order * 0.032, function()
                        Tween(child, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = targetTrans }, 0.3)
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

        local function makeLockedOverlay(parent, lockedText)
            local overlay = Instance.new("Frame")
            overlay.Name = "LockedOverlay"
            overlay.Size = UDim2.new(1, 0, 1, 0)
            overlay.BackgroundColor3 = theme.Background
            overlay.BackgroundTransparency = 0.4
            overlay.BorderSizePixel = 0
            overlay.Visible = false
            overlay.ZIndex = 20
            overlay.Parent = parent
            Round(overlay, 9)
            local lockIcon = Instance.new("ImageLabel")
            lockIcon.Size = UDim2.new(0, 14, 0, 14)
            lockIcon.Position = UDim2.new(0.5, -42, 0.5, -7)
            lockIcon.BackgroundTransparency = 1
            lockIcon.Image = GetLucide("lock") or "rbxassetid://10734943674"
            lockIcon.ImageColor3 = theme.Locked
            lockIcon.ZIndex = 21
            lockIcon.Parent = overlay
            local lockLbl = Instance.new("TextLabel")
            lockLbl.Size = UDim2.new(0, 90, 0, 16)
            lockLbl.Position = UDim2.new(0.5, -22, 0.5, -8)
            lockLbl.BackgroundTransparency = 1
            lockLbl.Text = lockedText or "Locked"
            lockLbl.TextColor3 = theme.Locked
            lockLbl.TextSize = 12
            lockLbl.Font = Enum.Font.GothamMedium
            lockLbl.ZIndex = 21
            lockLbl.Parent = overlay
            return overlay, lockLbl
        end

        function tab:create_button(index)
            local locked = index.Locked or false
            local lockedText = index.LockedText or "Locked"
            local frame = Instance.new("Frame")
            frame.Name = "Button"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 10)
            Stroke(frame, theme.Stroke, 1)
            TrackTheme(frame, "BackgroundColor3", "Element")
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -48, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title or index.Title or "Button"
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame
            TrackTheme(lbl, "TextColor3", "Text")
            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.new(0, 16, 0, 16)
            arrow.Position = UDim2.new(1, -30, 0.5, -8)
            arrow.BackgroundTransparency = 1
            arrow.Image = GetLucide("chevron-right") or "rbxassetid://10709791437"
            arrow.ImageColor3 = theme.TextDim
            arrow.ZIndex = 5
            arrow.Parent = frame
            local overlay = makeLockedOverlay(frame, lockedText)
            overlay.Visible = locked
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 6
            btn.Parent = frame
            local api = {}
            function api:SetLocked(v, text) locked = v overlay.Visible = v end
            function api:Lock(text) api:SetLocked(true, text) end
            function api:Unlock() api:SetLocked(false) end
            btn.MouseButton1Click:Connect(function()
                if locked then return end
                Tween(frame, { BackgroundColor3 = theme.ElementHover }, 0.1)
                task.delay(0.12, function() Tween(frame, { BackgroundColor3 = theme.Element }, 0.2) end)
                if index.callback or index.Callback then (index.callback or index.Callback)() end
            end)
            table.insert(self.__library.__all_elements, { name = index.title or index.Title or "Button", frame = frame })
            return api
        end

        function tab:create_toggle(index)
            local locked = index.Locked or false
            local lockedText = index.LockedText or "Locked"
            local toggled = index.default or index.Value or false
            local flag = index.Flag
            if flag and self.__library.__flags[flag] ~= nil then toggled = self.__library.__flags[flag] end
            local callback = index.callback or index.Callback or function() end
            local frame = Instance.new("Frame")
            frame.Name = "Toggle"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 10)
            Stroke(frame, theme.Stroke, 1)
            TrackTheme(frame, "BackgroundColor3", "Element")
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -70, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title or index.Title or "Toggle"
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame
            TrackTheme(lbl, "TextColor3", "Text")
            local track = Instance.new("Frame")
            track.Size = UDim2.new(0, 46, 0, 26)
            track.Position = UDim2.new(1, -58, 0.5, -13)
            track.BackgroundColor3 = toggled and theme.ToggleOn or theme.ToggleOff
            track.BorderSizePixel = 0
            track.ZIndex = 5
            track.Parent = frame
            Round(track, 13)
            Stroke(track, theme.Stroke, 1)
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = toggled and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
            knob.BackgroundColor3 = toggled and theme.AccentDark or theme.Text
            knob.BorderSizePixel = 0
            knob.ZIndex = 6
            knob.Parent = track
            Round(knob, 10)
            local overlay = makeLockedOverlay(frame, lockedText)
            overlay.Visible = locked
            local function setState(state, fire)
                if locked then return end
                toggled = state
                Tween(track, { BackgroundColor3 = toggled and theme.ToggleOn or theme.ToggleOff }, 0.25)
                Tween(knob, {
                    Position = toggled and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
                    BackgroundColor3 = toggled and theme.AccentDark or theme.Text
                }, 0.25)
                if flag then self.__library.__flags[flag] = toggled end
                if fire ~= false then callback(toggled) end
            end
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 7
            btn.Parent = frame
            btn.MouseButton1Click:Connect(function() setState(not toggled) end)
            local api = {}
            function api:Set(v) setState(v) end
            function api:Get() return toggled end
            function api:SetLocked(v) locked = v overlay.Visible = v end
            function api:Lock() api:SetLocked(true) end
            function api:Unlock() api:SetLocked(false) end
            if flag then self.__library.__flags[flag] = toggled end
            table.insert(self.__library.__all_elements, { name = index.title or index.Title or "Toggle", frame = frame })
            return api
        end

        function tab:create_checkbox(index)
            return self:create_toggle(index)
        end

        function tab:create_divider(text)
            local frame = Instance.new("Frame")
            frame.Name = "Divider"
            frame.Size = UDim2.new(1, 0, 0, 24)
            frame.BackgroundTransparency = 1
            frame.ZIndex = 4
            frame.Parent = container
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -8, 1, 0)
            lbl.Position = UDim2.new(0, 4, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text or ""
            lbl.TextColor3 = theme.TextMuted
            lbl.TextSize = 12
            lbl.Font = Enum.Font.GothamBold
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame
            TrackTheme(lbl, "TextColor3", "TextMuted")
            table.insert(self.__library.__all_elements, { name = text or "", frame = frame })
        end

        function tab:create_paragraph(index)
            local frame = Instance.new("Frame")
            frame.Name = "Paragraph"
            frame.Size = UDim2.new(1, 0, 0, 0)
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 10)
            Stroke(frame, theme.Stroke, 1)
            TrackTheme(frame, "BackgroundColor3", "Element")
            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 12)
            pad.PaddingBottom = UDim.new(0, 12)
            pad.PaddingLeft = UDim.new(0, 14)
            pad.PaddingRight = UDim.new(0, 14)
            pad.Parent = frame
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 18)
            title.BackgroundTransparency = 1
            title.Text = index.title or index.Title or ""
            title.TextColor3 = theme.Text
            title.TextSize = 14
            title.Font = Enum.Font.GothamMedium
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.ZIndex = 5
            title.Parent = frame
            TrackTheme(title, "TextColor3", "Text")
            local content = Instance.new("TextLabel")
            content.Size = UDim2.new(1, 0, 0, 0)
            content.Position = UDim2.new(0, 0, 0, 22)
            content.AutomaticSize = Enum.AutomaticSize.Y
            content.BackgroundTransparency = 1
            content.Text = index.content or index.Content or index.Desc or ""
            content.TextColor3 = theme.TextDim
            content.TextSize = 12
            content.Font = Enum.Font.Gotham
            content.TextXAlignment = Enum.TextXAlignment.Left
            content.TextYAlignment = Enum.TextYAlignment.Top
            content.TextWrapped = true
            content.ZIndex = 5
            content.Parent = frame
            TrackTheme(content, "TextColor3", "TextDim")
            table.insert(self.__library.__all_elements, { name = index.title or index.Title or "Paragraph", frame = frame })
        end

        function tab:create_imageparagraph(index)
            local frame = Instance.new("Frame")
            frame.Name = "ImageParagraph"
            frame.Size = UDim2.new(1, 0, 0, 0)
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 10)
            Stroke(frame, theme.Stroke, 1)
            TrackTheme(frame, "BackgroundColor3", "Element")
            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 12)
            pad.PaddingBottom = UDim.new(0, 12)
            pad.PaddingLeft = UDim.new(0, 14)
            pad.PaddingRight = UDim.new(0, 14)
            pad.Parent = frame
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(0, 40, 0, 40)
            img.BackgroundTransparency = 1
            img.Image = (type(index.Image) == "string" and (GetLucide(index.Image) or index.Image)) or GetLucide("image") or "rbxassetid://10734943674"
            img.ImageColor3 = theme.Text
            img.ScaleType = Enum.ScaleType.Fit
            img.ZIndex = 5
            img.Parent = frame
            TrackTheme(img, "ImageColor3", "Text")
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -52, 0, 18)
            title.Position = UDim2.new(0, 50, 0, 2)
            title.BackgroundTransparency = 1
            title.Text = index.title or index.Title or ""
            title.TextColor3 = theme.Text
            title.TextSize = 14
            title.Font = Enum.Font.GothamMedium
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.ZIndex = 5
            title.Parent = frame
            TrackTheme(title, "TextColor3", "Text")
            local content = Instance.new("TextLabel")
            content.Size = UDim2.new(1, -52, 0, 0)
            content.Position = UDim2.new(0, 50, 0, 22)
            content.AutomaticSize = Enum.AutomaticSize.Y
            content.BackgroundTransparency = 1
            content.Text = index.content or index.Content or index.Desc or ""
            content.TextColor3 = theme.TextDim
            content.TextSize = 12
            content.Font = Enum.Font.Gotham
            content.TextXAlignment = Enum.TextXAlignment.Left
            content.TextYAlignment = Enum.TextYAlignment.Top
            content.TextWrapped = true
            content.ZIndex = 5
            content.Parent = frame
            TrackTheme(content, "TextColor3", "TextDim")
            table.insert(self.__library.__all_elements, { name = index.title or index.Title or "ImageParagraph", frame = frame })
        end

        function tab:create_slider(index)
            local locked = index.Locked or false
            local lockedText = index.LockedText or "Locked"
            local min = index.minimum or index.Min or 0
            local max = index.maximum or index.Max or 100
            local value = index.default or index.Value or min
            local rounding = index.rounding or index.Step or 0
            local flag = index.Flag
            if flag and self.__library.__flags[flag] ~= nil then value = self.__library.__flags[flag] end
            local callback = index.callback or index.Callback or function() end
            local frame = Instance.new("Frame")
            frame.Name = "Slider"
            frame.Size = UDim2.new(1, 0, 0, 54)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 10)
            Stroke(frame, theme.Stroke, 1)
            TrackTheme(frame, "BackgroundColor3", "Element")
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.6, 0, 0, 20)
            lbl.Position = UDim2.new(0, 14, 0, 8)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title or index.Title or "Slider"
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame
            TrackTheme(lbl, "TextColor3", "Text")
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
            TrackTheme(valLbl, "TextColor3", "TextDim")
            local trackBg = Instance.new("Frame")
            trackBg.Size = UDim2.new(1, -28, 0, 5)
            trackBg.Position = UDim2.new(0, 14, 1, -16)
            trackBg.BackgroundColor3 = theme.ToggleOff
            trackBg.BorderSizePixel = 0
            trackBg.ZIndex = 5
            trackBg.Parent = frame
            Round(trackBg, 3)
            TrackTheme(trackBg, "BackgroundColor3", "ToggleOff")
            local track = Instance.new("Frame")
            track.Size = UDim2.new(math.clamp((value - min) / math.max(max - min, 1), 0, 1), 0, 1, 0)
            track.BackgroundColor3 = theme.Slider
            track.BorderSizePixel = 0
            track.ZIndex = 6
            track.Parent = trackBg
            Round(track, 3)
            TrackTheme(track, "BackgroundColor3", "Slider")
            local ball = Instance.new("Frame")
            ball.Size = UDim2.new(0, 14, 0, 14)
            ball.Position = UDim2.new(1, -7, 0.5, -7)
            ball.BackgroundColor3 = theme.Slider
            ball.BorderSizePixel = 0
            ball.ZIndex = 7
            ball.Parent = track
            Round(ball, 7)
            Stroke(ball, theme.Stroke, 1)
            local hitbox = Instance.new("Frame")
            hitbox.Size = UDim2.new(1, 0, 0, 22)
            hitbox.Position = UDim2.new(0, 0, 0.5, -11)
            hitbox.BackgroundTransparency = 1
            hitbox.ZIndex = 8
            hitbox.Parent = trackBg
            local overlay = makeLockedOverlay(frame, lockedText)
            overlay.Visible = locked
            local dragging = false
            local function update(input)
                if locked then return end
                local pos = math.clamp((input.Position.X - trackBg.AbsolutePosition.X) / math.max(trackBg.AbsoluteSize.X, 1), 0, 1)
                value = min + (max - min) * pos
                if rounding > 0 then value = math.floor(value / rounding + 0.5) * rounding else value = math.floor(value) end
                value = math.clamp(value, min, max)
                valLbl.Text = tostring(value)
                Tween(track, { Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0) }, 0.08)
                if flag then self.__library.__flags[flag] = value end
                callback(value)
            end
            hitbox.InputBegan:Connect(function(input)
                if locked then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Tween(ball, { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -8, 0.5, -8) }, 0.12)
                    update(input)
                end
            end)
            hitbox.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    Tween(ball, { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7) }, 0.12)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)
            local api = {}
            function api:Set(v)
                value = math.clamp(v, min, max)
                valLbl.Text = tostring(value)
                track.Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0)
                if flag then self.__library.__flags[flag] = value end
                callback(value)
            end
            function api:SetLocked(v) locked = v overlay.Visible = v end
            function api:Lock() api:SetLocked(true) end
            function api:Unlock() api:SetLocked(false) end
            if flag then self.__library.__flags[flag] = value end
            table.insert(self.__library.__all_elements, { name = index.title or index.Title or "Slider", frame = frame })
            return api
        end

        function tab:create_textbox(index)
            local locked = index.Locked or false
            local frame = Instance.new("Frame")
            frame.Name = "Textbox"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 10)
            Stroke(frame, theme.Stroke, 1)
            TrackTheme(frame, "BackgroundColor3", "Element")
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, 110, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title or index.Title or "Input"
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame
            TrackTheme(lbl, "TextColor3", "Text")
            local inputFrame = Instance.new("Frame")
            inputFrame.Size = UDim2.new(0, 190, 0, 30)
            inputFrame.Position = UDim2.new(1, -204, 0.5, -15)
            inputFrame.BackgroundColor3 = theme.Background
            inputFrame.BackgroundTransparency = 0.25
            inputFrame.BorderSizePixel = 0
            inputFrame.ZIndex = 5
            inputFrame.Parent = frame
            Round(inputFrame, 8)
            Stroke(inputFrame, theme.Stroke, 1)
            TrackTheme(inputFrame, "BackgroundColor3", "Background")
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -14, 1, 0)
            box.Position = UDim2.new(0, 8, 0, 0)
            box.BackgroundTransparency = 1
            box.Text = ""
            box.PlaceholderText = index.placeholder or index.Placeholder or ""
            box.TextColor3 = theme.Text
            box.PlaceholderColor3 = theme.TextMuted
            box.TextSize = 12
            box.Font = Enum.Font.Gotham
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.ZIndex = 6
            box.Parent = inputFrame
            TrackTheme(box, "TextColor3", "Text")
            local overlay = makeLockedOverlay(frame, index.LockedText or "Locked")
            overlay.Visible = locked
            box.FocusLost:Connect(function(enter)
                if locked then return end
                if enter and (index.callback or index.Callback) then
                    (index.callback or index.Callback)(box.Text)
                end
            end)
            local api = {}
            function api:Set(text) box.Text = text end
            function api:SetLocked(v) locked = v overlay.Visible = v end
            function api:Lock() api:SetLocked(true) end
            function api:Unlock() api:SetLocked(false) end
            table.insert(self.__library.__all_elements, { name = index.title or index.Title or "Input", frame = frame })
            return api
        end

        function tab:create_dropdown(index)
            local options = index.options or index.Values or {}
            local multi = index.multi_selection or index.Multi or false
            local selected = multi and (type(index.default or index.Value) == "table" and (index.default or index.Value) or {}) or (index.default or index.Value or options[1] or "--")
            local callback = index.callback or index.Callback or function() end
            local locked = index.Locked or false
            local opened = false
            local frame = Instance.new("Frame")
            frame.Name = "Dropdown"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.ZIndex = 10
            frame.ClipsDescendants = false
            frame.Parent = container
            Round(frame, 10)
            Stroke(frame, theme.Stroke, 1)
            TrackTheme(frame, "BackgroundColor3", "Element")
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, 140, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title or index.Title or "Dropdown"
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 11
            lbl.Parent = frame
            TrackTheme(lbl, "TextColor3", "Text")
            local drop = Instance.new("Frame")
            drop.Size = UDim2.new(0, 148, 0, 30)
            drop.Position = UDim2.new(1, -162, 0.5, -15)
            drop.BackgroundColor3 = theme.Background
            drop.BackgroundTransparency = 0.15
            drop.BorderSizePixel = 0
            drop.ClipsDescendants = true
            drop.ZIndex = 12
            drop.Parent = frame
            Round(drop, 8)
            Stroke(drop, theme.Stroke, 1)
            TrackTheme(drop, "BackgroundColor3", "Background")
            local function display()
                if multi then return #selected == 0 and "--" or table.concat(selected, ", ") end
                return selected
            end
            local selLbl = Instance.new("TextLabel")
            selLbl.Size = UDim2.new(1, -32, 1, 0)
            selLbl.Position = UDim2.new(0, 10, 0, 0)
            selLbl.BackgroundTransparency = 1
            selLbl.Text = display()
            selLbl.TextColor3 = theme.Text
            selLbl.TextSize = 12
            selLbl.Font = Enum.Font.Gotham
            selLbl.TextXAlignment = Enum.TextXAlignment.Left
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 13
            selLbl.Parent = drop
            TrackTheme(selLbl, "TextColor3", "Text")
            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.new(0, 12, 0, 12)
            arrow.Position = UDim2.new(1, -22, 0.5, -6)
            arrow.BackgroundTransparency = 1
            arrow.Image = GetLucide("chevron-down") or "rbxassetid://10709790948"
            arrow.ImageColor3 = theme.TextMuted
            arrow.ZIndex = 13
            arrow.Parent = drop
            local list = Instance.new("ScrollingFrame")
            list.Size = UDim2.new(1, 0, 0, 0)
            list.Position = UDim2.new(0, 0, 0, 32)
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
                optBtn.Size = UDim2.new(1, -8, 0, 28)
                optBtn.BackgroundColor3 = theme.Element
                optBtn.BackgroundTransparency = 0.25
                optBtn.BorderSizePixel = 0
                optBtn.Text = "  " .. opt
                optBtn.TextColor3 = theme.TextDim
                optBtn.TextSize = 12
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.ZIndex = 15
                optBtn.Parent = list
                Round(optBtn, 6)
                optBtn.MouseButton1Click:Connect(function()
                    if locked then return end
                    if multi then
                        local idx = table.find(selected, opt)
                        if idx then table.remove(selected, idx) optBtn.TextColor3 = theme.TextDim
                        else table.insert(selected, opt) optBtn.TextColor3 = theme.Text end
                        selLbl.Text = display()
                        callback(selected)
                    else
                        selected = opt
                        selLbl.Text = opt
                        callback(opt)
                        opened = false
                        Tween(drop, { Size = UDim2.new(0, 148, 0, 30) }, 0.2)
                        Tween(arrow, { Rotation = 0 }, 0.2)
                        list.Size = UDim2.new(1, 0, 0, 0)
                    end
                end)
            end
            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
            end)
            local overlay = makeLockedOverlay(frame, index.LockedText or "Locked")
            overlay.Visible = locked
            local openBtn = Instance.new("TextButton")
            openBtn.Size = UDim2.new(1, 0, 0, 30)
            openBtn.BackgroundTransparency = 1
            openBtn.Text = ""
            openBtn.ZIndex = 14
            openBtn.Parent = drop
            openBtn.MouseButton1Click:Connect(function()
                if locked then return end
                opened = not opened
                local h = math.min(#options * 30, 150)
                if opened then
                    list.Size = UDim2.new(1, 0, 0, h)
                    Tween(drop, { Size = UDim2.new(0, 148, 0, 34 + h) }, 0.25)
                    Tween(arrow, { Rotation = 180 }, 0.25)
                else
                    Tween(drop, { Size = UDim2.new(0, 148, 0, 30) }, 0.2)
                    Tween(arrow, { Rotation = 0 }, 0.2)
                    list.Size = UDim2.new(1, 0, 0, 0)
                end
            end)
            local api = {}
            function api:Set(v) selected = v selLbl.Text = display() callback(selected) end
            function api:SetLocked(v) locked = v overlay.Visible = v end
            function api:Lock() api:SetLocked(true) end
            function api:Unlock() api:SetLocked(false) end
            table.insert(self.__library.__all_elements, { name = index.title or index.Title or "Dropdown", frame = frame })
            return api
        end

        function tab:create_keybind(index)
            local current = index.default or index.Value or Enum.KeyCode.E
            if type(current) == "string" then current = Enum.KeyCode[current] or Enum.KeyCode.E end
            local callback = index.callback or index.Callback or function() end
            local flag = index.Flag
            local frame = Instance.new("Frame")
            frame.Name = "Keybind"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 10)
            Stroke(frame, theme.Stroke, 1)
            TrackTheme(frame, "BackgroundColor3", "Element")
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -100, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title or index.Title or "Keybind"
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame
            TrackTheme(lbl, "TextColor3", "Text")
            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0, 80, 0, 28)
            keyBtn.Position = UDim2.new(1, -94, 0.5, -14)
            keyBtn.BackgroundColor3 = theme.Background
            keyBtn.BorderSizePixel = 0
            keyBtn.Text = current.Name
            keyBtn.TextColor3 = theme.Text
            keyBtn.TextSize = 12
            keyBtn.Font = Enum.Font.GothamMedium
            keyBtn.ZIndex = 6
            keyBtn.Parent = frame
            Round(keyBtn, 7)
            Stroke(keyBtn, theme.Stroke, 1)
            TrackTheme(keyBtn, "BackgroundColor3", "Background")
            TrackTheme(keyBtn, "TextColor3", "Text")
            keyBtn.MouseButton1Click:Connect(function()
                keyBtn.Text = "..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        current = input.KeyCode
                        keyBtn.Text = current.Name
                        if flag then self.__library.__flags[flag] = current.Name end
                        callback(current)
                        conn:Disconnect()
                    end
                end)
            end)
            local api = {}
            function api:Set(k)
                if type(k) == "string" then k = Enum.KeyCode[k] end
                current = k
                keyBtn.Text = current.Name
            end
            function api:Get() return current end
            table.insert(self.__library.__all_elements, { name = index.title or index.Title or "Keybind", frame = frame })
            return api
        end

        function tab:create_module(index)
            local toggled = index.default or false
            local callback = index.callback or function() end
            local module = { __elements = {}, __library = self.__library }
            local frame = Instance.new("Frame")
            frame.Name = "Module"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = theme.Element
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.ClipsDescendants = false
            frame.ZIndex = 4
            frame.Parent = container
            Round(frame, 10)
            Stroke(frame, theme.Stroke, 1)
            TrackTheme(frame, "BackgroundColor3", "Element")
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -70, 0, 42)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = index.title or "Module"
            lbl.TextColor3 = theme.Text
            lbl.TextSize = 14
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 5
            lbl.Parent = frame
            TrackTheme(lbl, "TextColor3", "Text")
            local track = Instance.new("Frame")
            track.Size = UDim2.new(0, 46, 0, 26)
            track.Position = UDim2.new(1, -58, 0, 8)
            track.BackgroundColor3 = toggled and theme.ToggleOn or theme.ToggleOff
            track.BorderSizePixel = 0
            track.ZIndex = 5
            track.Parent = frame
            Round(track, 13)
            Stroke(track, theme.Stroke, 1)
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = toggled and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
            knob.BackgroundColor3 = toggled and theme.AccentDark or theme.Text
            knob.BorderSizePixel = 0
            knob.ZIndex = 6
            knob.Parent = track
            Round(knob, 10)
            local childrenHolder = Instance.new("Frame")
            childrenHolder.Size = UDim2.new(1, 0, 0, 0)
            childrenHolder.Position = UDim2.new(0, 0, 0, 46)
            childrenHolder.BackgroundTransparency = 1
            childrenHolder.Visible = false
            childrenHolder.ZIndex = 5
            childrenHolder.Parent = frame
            local childLayout = Instance.new("UIListLayout")
            childLayout.Padding = UDim.new(0, 5)
            childLayout.Parent = childrenHolder
            local function updateHeight()
                local h = 42
                if toggled and #module.__elements > 0 then
                    for _, e in pairs(module.__elements) do h = h + e.Size.Y.Offset + 5 end
                    h = h + 10
                end
                Tween(frame, { Size = UDim2.new(1, 0, 0, h) }, 0.25)
            end
            local function setToggle(state)
                toggled = state
                Tween(track, { BackgroundColor3 = toggled and theme.ToggleOn or theme.ToggleOff }, 0.25)
                Tween(knob, {
                    Position = toggled and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
                    BackgroundColor3 = toggled and theme.AccentDark or theme.Text
                }, 0.25)
                childrenHolder.Visible = toggled and #module.__elements > 0
                updateHeight()
                callback(toggled)
            end
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -65, 0, 42)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 7
            btn.Parent = frame
            btn.MouseButton1Click:Connect(function() setToggle(not toggled) end)
            local tBtn = Instance.new("TextButton")
            tBtn.Size = UDim2.new(0, 46, 0, 26)
            tBtn.Position = UDim2.new(1, -58, 0, 8)
            tBtn.BackgroundTransparency = 1
            tBtn.Text = ""
            tBtn.ZIndex = 8
            tBtn.Parent = frame
            tBtn.MouseButton1Click:Connect(function() setToggle(not toggled) end)
            function module:create_checkbox(idx)
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, -14, 0, 34)
                f.BackgroundColor3 = theme.Background
                f.BackgroundTransparency = 0.25
                f.BorderSizePixel = 0
                f.Parent = childrenHolder
                Round(f, 7)
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, -14, 1, 0)
                l.Position = UDim2.new(0, 10, 0, 0)
                l.BackgroundTransparency = 1
                l.Text = idx.title or ""
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
                f.Size = UDim2.new(1, -14, 0, 34)
                f.BackgroundColor3 = theme.Background
                f.BackgroundTransparency = 0.25
                f.BorderSizePixel = 0
                f.Parent = childrenHolder
                Round(f, 7)
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, -10, 1, 0)
                l.Position = UDim2.new(0, 10, 0, 0)
                l.BackgroundTransparency = 1
                l.Text = idx.title or ""
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
                b.MouseButton1Click:Connect(function() if idx.callback then idx.callback() end end)
                table.insert(module.__elements, f)
                if toggled then updateHeight() end
            end
            function module:create_slider() end
            function module:create_textbox() end
            function module:create_dropdown() end
            function module:create_divider() end
            table.insert(self.__library.__all_elements, { name = index.title or "Module", frame = frame })
            return module
        end

        return tab
    end

    return self
end

Library.init = Library.CreateWindow
return Library
