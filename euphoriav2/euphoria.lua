--> euphoria! rewritten & fixed
--> improved animations, smoother interactions, bug fixes, better centering

export type Library = {
    __current_tab: Tab?,
    __tabs: { Tab },
    __all_elements: { { name: string, frame: Frame } },
    __window: { main: Frame, euphoria: ScreenGui, overlay: Frame },
    __resize_start: Vector2?,
    __size_start: UDim2?,
    __resizing: boolean,
    __ui_scale: number,
    __device: string?,
    __drag_input: InputObject?,
    __drag_start: Vector2?,
    __start_pos: UDim2?,
    __dragging: boolean?,
    __minimized: boolean,
    __closed: boolean,
    __floating_icon: ImageButton?,
    __size_presets: { UDim2 },
    __size_index: number,
    __connections: { RBXScriptConnection },
    get_device: (self: Library) -> (),
    notify: (self: Library, index: { title: string, content: string, duration: number?, notify_type: string }) -> (),
    get_screen_scale: (self: Library) -> (),
    mobile_ui_scale: (self: Library) -> (),
    mobile_controls: (self: Library) -> (),
    init: (self: Library, config: ({ title: string?, logo: string?, size: UDim2? } | string)?) -> Library,
    create_tab: (self: Library, name: string, icon: string?) -> Tab,
    toggle_window: (self: Library, force_minimized: boolean?) -> (),
    destroy: (self: Library) -> (),
}

export type Tab = {
    __library: Library,
    button: TextButton,
    container: ScrollingFrame,
    label: TextLabel,
    highlight: Frame,
    outline: UIStroke,
    highlight_effect: Frame,
    icon: ImageLabel?,
    create_button: (self: Tab, index: { title: string, callback: () -> () }) -> (),
    create_divider: (self: Tab, text: string?) -> (),
    create_slider: (self: Tab, index: { title: string, minimum: number?, maximum: number?, default: number?, rounding: number?, callback: (value: number) -> () }) -> { Set: (self: any, value: number) -> () },
    create_textbox: (self: Tab, index: { title: string, placeholder: string?, callback: (text: string) -> () }) -> { Set: (self: any, text: string) -> () },
    create_module: (self: Tab, index: { title: string, default: boolean?, callback: (state: boolean) -> () }) -> Module,
    create_checkbox: (self: Tab, index: { title: string, default: boolean?, callback: (state: boolean) -> () }) -> { Set: (self: any, state: boolean) -> () },
    create_dropdown: (self: Tab, index: { title: string, options: { string }, default: string | { string }?, multi_selection: boolean?, callback: (value: string | { string }) -> () }) -> { Set: (self: any, value: string | { string }) -> () }
}

export type Module = {
    __elements: { Instance },
    __library: Library,
    create_checkbox: (self: Module, index: { title: string, default: boolean?, callback: (state: boolean) -> () }) -> { Set: (self: any, state: boolean) -> () },
    create_divider: (self: Module, text: string?) -> (),
    create_textbox: (self: Module, index: { title: string, placeholder: string?, callback: (text: string) -> () }) -> { Set: (self: any, text: string) -> () },
    create_slider: (self: Module, index: { title: string, minimum: number?, maximum: number?, default: number?, rounding: number?, callback: (value: number) -> () }) -> { Set: (self: any, value: number) -> () },
    create_button: (self: Module, index: { title: string, callback: () -> () }) -> (),
    create_dropdown: (self: Module, index: { title: string, options: { string }, default: string | { string }?, multi_selection: boolean?, callback: (value: string | { string }) -> () }) -> { Set: (self: any, value: string | { string }) -> () }
}

local Service = setmetatable({} :: any, {
    __index = function(self: any, name: string): Instance
        local service = (cloneref or function(...) return ... end)(game:GetService(name))
        rawset(self, name, service)
        return service
    end
})

local UserInputService = Service.UserInputService
local CoreGui = Service.CoreGui
local TweenService = Service.TweenService
local RunService = Service.RunService
local Camera = workspace.CurrentCamera

--> lucide icons
local __Lucide: { [string]: string } = {}
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/Icons/lucide.lua"))()
    end)
    if ok and type(result) == "table" then
        __Lucide = result
    end
end

local function __get_lucide(name: string?): string
    if not name then return "" end
    if name:sub(1, 7) == "rbxasse" or name:sub(1, 4) == "http" then
        return name
    end
    return __Lucide[name] or __Lucide[name:lower()] or ""
end

--> theme
local Theme = {
    Background = Color3.fromRGB(0, 0, 0),
    Foreground = Color3.fromRGB(8, 8, 8),
    Surface = Color3.fromRGB(12, 12, 12),
    SurfaceHighlight = Color3.fromRGB(20, 20, 20),
    Border = Color3.fromRGB(35, 35, 35),
    Accent = Color3.fromRGB(255, 255, 255),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    TextMuted = Color3.fromRGB(120, 120, 120),
    Error = Color3.fromRGB(220, 100, 100),
    Warning = Color3.fromRGB(220, 180, 80),
    Success = Color3.fromRGB(120, 220, 120),
    Font = Enum.Font.Gotham,
    FontMedium = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    CornerRadius = 8,
    Speed = 0.3,
}

--> helpers
local function __tween(object: Instance, props: { [any]: any }, duration: number?, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
    local t = TweenService:Create(object, TweenInfo.new(duration or Theme.Speed, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function __corner(parent: Instance, radius: number?): UICorner
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or Theme.CornerRadius)
    c.Parent = parent
    return c
end

local function __stroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function __shadow(parent: Instance, transparency: number?): ImageLabel
    local sh = Instance.new("ImageLabel")
    sh.Name = "Shadow"
    sh.AnchorPoint = Vector2.new(0.5, 0.5)
    sh.BackgroundTransparency = 1
    sh.Position = UDim2.new(0.5, 0, 0.5, 0)
    sh.Size = UDim2.new(1, 44, 1, 44)
    sh.ZIndex = 0
    sh.Image = "rbxassetid://5554236805"
    sh.ImageColor3 = Color3.new(0, 0, 0)
    sh.ImageTransparency = transparency or 0.55
    sh.ScaleType = Enum.ScaleType.Slice
    sh.SliceCenter = Rect.new(23, 23, 277, 277)
    sh.Parent = parent
    return sh
end

local function __disconnect_all(connections: { RBXScriptConnection })
    for _, c in ipairs(connections) do
        if c and c.Connected then c:Disconnect() end
    end
    table.clear(connections)
end

--> notifications
local __NotifyQueue: { { title: string, content: string, duration: number, type: string } } = {}
local __ActiveNotifs: { Frame } = {}
local __NotifyIcons: { [string]: string } = {
    normal = "rbxassetid://10734888000",
    error = "rbxassetid://10747384394",
    warn = "rbxassetid://10709753149",
    success = "rbxassetid://10709761889",
}

local function __update_notif_positions()
    local y = -20
    for i = #__ActiveNotifs, 1, -1 do
        local n = __ActiveNotifs[i]
        if not n or not n.Parent then continue end
        __tween(n, { Position = UDim2.new(1, -20, 1, y) }, 0.35, Enum.EasingStyle.Quart)
        y -= n.AbsoluteSize.Y + 12
    end
end

local function __spawn_notif()
    if #__NotifyQueue == 0 then return end
    if #__ActiveNotifs >= 5 then return end

    local data = table.remove(__NotifyQueue, 1)
    local gui = CoreGui:FindFirstChild("Euphoria")
    if not gui then return end

    local isMobile = (Library.__device == "mobile" or Library.__device == "unknown")
    local w = isMobile and 260 or 320
    local h = isMobile and 65 or 75

    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, w, 0, 0)
    f.Position = UDim2.new(1, -20, 1, -20)
    f.AnchorPoint = Vector2.new(1, 1)
    f.BackgroundColor3 = Theme.Foreground
    f.BorderSizePixel = 0
    f.ZIndex = 100
    f.ClipsDescendants = true
    f.Parent = gui
    __corner(f, 6)
    __stroke(f, Theme.Border)

    local iconC = Instance.new("Frame")
    iconC.Size = UDim2.new(0, 44, 1, 0)
    iconC.BackgroundTransparency = 1
    iconC.ZIndex = 101
    iconC.Parent = f

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 22, 0, 22)
    icon.Position = UDim2.new(0.5, -11, 0.5, -11)
    icon.BackgroundTransparency = 1
    icon.Image = __NotifyIcons[data.type] or __NotifyIcons["normal"]
    icon.ImageColor3 = data.type == "error" and Theme.Error or (data.type == "warn" and Theme.Warning or (data.type == "success" and Theme.Success or Theme.Accent))
    icon.ZIndex = 102
    icon.Parent = iconC

    local div = Instance.new("Frame")
    div.Size = UDim2.new(0, 1, 0.7, 0)
    div.Position = UDim2.new(0, 44, 0.15, 0)
    div.BackgroundColor3 = Theme.Border
    div.BorderSizePixel = 0
    div.ZIndex = 101
    div.Parent = f

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -55, 1, -10)
    content.Position = UDim2.new(0, 50, 0, 5)
    content.BackgroundTransparency = 1
    content.ZIndex = 101
    content.Parent = f

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 18)
    title.Position = UDim2.new(0, 5, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = data.title
    title.TextColor3 = Theme.TextPrimary
    title.TextSize = 14
    title.Font = Theme.FontMedium
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Top
    title.ZIndex = 102
    title.Parent = content

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -10, 1, -26)
    body.Position = UDim2.new(0, 5, 0, 22)
    body.BackgroundTransparency = 1
    body.Text = data.content
    body.TextColor3 = Theme.TextSecondary
    body.TextSize = 13
    body.Font = Theme.Font
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.ZIndex = 102
    body.Parent = content

    local prog = Instance.new("Frame")
    prog.Size = UDim2.new(0, 0, 0, 2)
    prog.Position = UDim2.new(0, 0, 1, -2)
    prog.BackgroundColor3 = icon.ImageColor3
    prog.BorderSizePixel = 0
    prog.ZIndex = 103
    prog.Parent = f

    table.insert(__ActiveNotifs, 1, f)
    __update_notif_positions()

    __tween(f, { Size = UDim2.new(0, w, 0, h) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    __tween(prog, { Size = UDim2.new(1, 0, 0, 2) }, data.duration, Enum.EasingStyle.Linear)

    task.delay(data.duration, function()
        if not f or not f.Parent then return end
        __tween(f, { BackgroundTransparency = 1 }, 0.25)
        __tween(icon, { ImageTransparency = 1 }, 0.25)
        __tween(div, { BackgroundTransparency = 1 }, 0.25)
        __tween(title, { TextTransparency = 1 }, 0.25)
        __tween(body, { TextTransparency = 1 }, 0.25)
        __tween(prog, { BackgroundTransparency = 1 }, 0.25)
        for _, c in pairs(f:GetChildren()) do
            if c:IsA("UIStroke") then __tween(c, { Transparency = 1 }, 0.25) end
        end
        task.delay(0.3, function()
            if f and f.Parent then
                f:Destroy()
                for i, n in ipairs(__ActiveNotifs) do
                    if n == f then table.remove(__ActiveNotifs, i) break end
                end
                __update_notif_positions()
                task.spawn(__spawn_notif)
            end
        end)
    end)
end

--> library
local Library: Library = {
    __current_tab = nil,
    __tabs = {},
    __all_elements = {},
    __window = {},
    __resize_start = nil,
    __size_start = nil,
    __resizing = false,
    __ui_scale = 1,
    __device = nil,
    __drag_input = nil,
    __drag_start = nil,
    __start_pos = nil,
    __dragging = nil,
    __minimized = false,
    __closed = false,
    __floating_icon = nil,
    __size_presets = {
        UDim2.new(0, 550, 0, 380),
        UDim2.new(0, 700, 0, 450),
        UDim2.new(0, 900, 0, 560),
    },
    __size_index = 2,
    __connections = {},
}
Library.__index = Library
Library.get_icon = function(_, name) return __get_lucide(name) end

function Library:get_device()
    self.__device = UserInputService.TouchEnabled and "mobile" or "pc"
end

function Library:get_screen_scale()
    self.__ui_scale = math.clamp(Camera.ViewportSize.X / 1920, 0.5, 1.2)
end

function Library:notify(index: { title: string, content: string, duration: number?, notify_type: string })
    local ntype = index.notify_type or "normal"
    if not __NotifyIcons[ntype] then ntype = "normal" end
    table.insert(__NotifyQueue, {
        title = index.title,
        content = index.content,
        duration = index.duration or 3,
        type = ntype,
    })
    task.spawn(__spawn_notif)
end

function Library:mobile_ui_scale()
    if self.__device ~= "mobile" and self.__device ~= "unknown" then return end
    if not self.__window.main then return end
    for _, obj in pairs(self.__window.main:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if obj.TextSize then
                obj.TextSize = math.max(12, math.floor(obj.TextSize * 1.08))
            end
        elseif (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.Name ~= "Shadow" then
            if obj.Size.X.Offset > 0 and obj.Size.X.Offset < 30 then
                obj.Size = UDim2.new(0, math.floor(obj.Size.X.Offset * 0.92), 0, math.floor(obj.Size.Y.Offset * 0.92))
            end
        end
    end
end

function Library:mobile_controls()
    if self.__device ~= "mobile" then return end
    if not self.__window.main then return end
    for _, obj in pairs(self.__window.main:GetDescendants()) do
        if not ((obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Size.Y.Offset < 45) then continue end
        local hitbox = Instance.new("Frame")
        hitbox.Name = "TouchHitbox"
        hitbox.Size = UDim2.new(1, 16, 1, 16)
        hitbox.Position = UDim2.new(0.5, 0, 0.5, 0)
        hitbox.AnchorPoint = Vector2.new(0.5, 0.5)
        hitbox.BackgroundTransparency = 1
        hitbox.ZIndex = obj.ZIndex
        hitbox.Parent = obj
        if obj:IsA("TextButton") then
            local conn = hitbox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    obj.MouseButton1Click:Fire()
                end
            end)
            table.insert(self.__connections, conn)
        end
    end
end

function Library:init(config: ({ title: string?, logo: string?, size: UDim2? } | string)?): Library
    local title: string? = nil
    local logo: string? = nil
    local initial_size: UDim2? = nil

    if type(config) == "string" then
        title = config
    elseif type(config) == "table" then
        title = config.title
        logo = config.logo
        initial_size = config.size
    end

    self:get_device()

    local euphoria = Instance.new("ScreenGui")
    euphoria.Name = "Euphoria"
    euphoria.ResetOnSpawn = false
    euphoria.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    euphoria.Parent = CoreGui

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 50
    overlay.Parent = euphoria

    self.__window = { main = nil :: any, euphoria = euphoria, overlay = overlay }
    self.__tabs = {}
    self.__all_elements = {}
    self.__connections = {}
    self.__minimized = false
    self.__closed = false

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.BackgroundColor3 = Theme.Background
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = euphoria
    main.ZIndex = 2
    __corner(main, 12)
    __stroke(main, Theme.Border)
    __shadow(main, 0.5)

    self.__window.main = main

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = main

    if self.__device == "mobile" or self.__device == "unknown" then
        self:get_screen_scale()
        uiScale.Scale = math.min(self.__ui_scale * 1.15, 1)
        local conn = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            self:get_screen_scale()
            uiScale.Scale = math.min(self.__ui_scale * 1.15, 1)
        end)
        table.insert(self.__connections, conn)
    end

    --> background panel
    local blurFrame = Instance.new("Frame")
    blurFrame.Size = UDim2.new(1, 0, 1, 0)
    blurFrame.BackgroundColor3 = Theme.Foreground
    blurFrame.BackgroundTransparency = 0.1
    blurFrame.BorderSizePixel = 0
    blurFrame.ZIndex = 0
    blurFrame.Parent = main
    __corner(blurFrame, 12)

    --> header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 52)
    header.BackgroundColor3 = Theme.Foreground
    header.BackgroundTransparency = 0.3
    header.BorderSizePixel = 0
    header.ZIndex = 3
    header.Parent = main
    __corner(header, 6)

    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 1)
    headerBottom.Position = UDim2.new(0, 0, 1, -1)
    headerBottom.BackgroundColor3 = Theme.Border
    headerBottom.BorderSizePixel = 0
    headerBottom.ZIndex = 4
    headerBottom.Parent = header

    local logoIcon = Instance.new("ImageLabel")
    logoIcon.Name = "Logo"
    logoIcon.Size = UDim2.new(0, 22, 0, 22)
    logoIcon.Position = UDim2.new(0, 16, 0.5, -11)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Image = __get_lucide(logo) ~= "" and __get_lucide(logo) or (logo or "")
    logoIcon.ImageColor3 = Theme.TextPrimary
    logoIcon.ZIndex = 4
    logoIcon.Visible = logo ~= nil and logo ~= ""
    logoIcon.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Position = UDim2.new(0, logoIcon.Visible and 46 or 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "euphoria"
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 15
    titleLabel.Font = Theme.FontMedium
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = header

    --> search
    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(0, 190, 0, 32)
    searchContainer.Position = UDim2.new(1, -310, 0.5, -16)
    searchContainer.BackgroundColor3 = Theme.Foreground
    searchContainer.BackgroundTransparency = 0.4
    searchContainer.BorderSizePixel = 0
    searchContainer.ZIndex = 4
    searchContainer.Parent = header
    __corner(searchContainer, 6)
    __stroke(searchContainer, Theme.Border)

    local searchIconContainer = Instance.new("Frame")
    searchIconContainer.Size = UDim2.new(0, 32, 1, 0)
    searchIconContainer.BackgroundColor3 = Theme.Foreground
    searchIconContainer.BackgroundTransparency = 0.6
    searchIconContainer.BorderSizePixel = 0
    searchIconContainer.ZIndex = 4
    searchIconContainer.Parent = searchContainer
    __corner(searchIconContainer, 6)

    local searchDivider = Instance.new("Frame")
    searchDivider.Size = UDim2.new(0, 1, 0.6, 0)
    searchDivider.Position = UDim2.new(0, 32, 0.2, 0)
    searchDivider.BackgroundColor3 = Theme.Border
    searchDivider.BorderSizePixel = 0
    searchDivider.ZIndex = 5
    searchDivider.Parent = searchContainer

    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Size = UDim2.new(0, 16, 0, 16)
    searchIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = "rbxassetid://10734943674"
    searchIcon.ImageColor3 = Theme.TextMuted
    searchIcon.ZIndex = 5
    searchIcon.Parent = searchIconContainer

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -42, 1, 0)
    searchBox.Position = UDim2.new(0, 37, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search..."
    searchBox.TextColor3 = Theme.TextPrimary
    searchBox.PlaceholderColor3 = Theme.TextMuted
    searchBox.TextSize = 13
    searchBox.Font = Theme.Font
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 5
    searchBox.Parent = searchContainer

    local function recursive_search(parent: Instance, query: string, show: boolean)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                local searchName = child:GetAttribute("SearchName") or child.Name
                local isDivider = child.Name == "Divider" or child.Name == "DividerItem"
                local isContainer = child.Name:find("Container") ~= nil or child.Name:find("ModuleContainer") ~= nil

                if isContainer then
                    recursive_search(child, query, show)
                    continue
                end

                if isDivider then
                    child.Visible = query == "" and show
                elseif searchName:lower():find(query) ~= nil then
                    child.Visible = show
                    if child:IsA("Frame") and not isDivider then
                        __tween(child, { BackgroundTransparency = 0.25 }, 0.2)
                    end
                else
                    if child:IsA("Frame") and not isDivider then
                        __tween(child, { BackgroundTransparency = 1 }, 0.2)
                        task.delay(0.22, function()
                            if child and child.Parent then
                                local sn = child:GetAttribute("SearchName") or child.Name
                                if sn:lower():find(query) == nil then
                                    child.Visible = false
                                end
                            end
                        end)
                    else
                        child.Visible = false
                    end
                end
            end
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        for _, tab in pairs(self.__tabs) do
            recursive_search(tab.container, query, true)
        end
    end)

    --> header buttons
    local headerButtons = Instance.new("Frame")
    headerButtons.Name = "HeaderButtons"
    headerButtons.Size = UDim2.new(0, 100, 0, 28)
    headerButtons.Position = UDim2.new(1, -114, 0.5, -14)
    headerButtons.BackgroundTransparency = 1
    headerButtons.ZIndex = 4
    headerButtons.Parent = header

    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonsLayout.Padding = UDim.new(0, 8)
    buttonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonsLayout.Parent = headerButtons

    local function makeHeaderButton(iconName: string): ImageButton
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(0, 28, 0, 28)
        holder.BackgroundColor3 = Theme.SurfaceHighlight
        holder.BackgroundTransparency = 0.3
        holder.BorderSizePixel = 0
        holder.ZIndex = 4
        holder.Parent = headerButtons
        __corner(holder, 6)

        local btn = Instance.new("ImageButton")
        btn.Size = UDim2.new(0, 14, 0, 14)
        btn.Position = UDim2.new(0.5, -7, 0.5, -7)
        btn.BackgroundTransparency = 1
        btn.Image = __get_lucide(iconName)
        btn.ImageColor3 = Theme.TextSecondary
        btn.ZIndex = 5
        btn.Parent = holder

        btn.MouseEnter:Connect(function()
            __tween(holder, { BackgroundTransparency = 0 }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            __tween(holder, { BackgroundTransparency = 0.3 }, 0.15)
        end)

        return btn
    end

    local sizeBtn = makeHeaderButton("maximize-2")
    local minimizeBtn = makeHeaderButton("minus")
    local exitBtn = makeHeaderButton("x")

    sizeBtn.MouseButton1Click:Connect(function()
        self.__size_index = (self.__size_index % #self.__size_presets) + 1
        local newSize = self.__size_presets[self.__size_index]
        local center = Vector2.new(main.AbsolutePosition.X + main.AbsoluteSize.X / 2, main.AbsolutePosition.Y + main.AbsoluteSize.Y / 2)
        __tween(main, {
            Size = newSize,
            Position = UDim2.new(0, center.X - newSize.X.Offset / 2, 0, center.Y - newSize.Y.Offset / 2)
        }, 0.35, Enum.EasingStyle.Quart)
    end)

    --> floating icon
    local function createFloatingIcon(): ImageButton
        local btn = Instance.new("ImageButton")
        btn.Name = "FloatingIcon"
        btn.Size = UDim2.new(0, 52, 0, 52)
        btn.Position = UDim2.new(0, 24, 0, 24)
        btn.BackgroundColor3 = Theme.Foreground
        btn.BackgroundTransparency = 0.05
        btn.BorderSizePixel = 0
        btn.Image = (__get_lucide(logo) ~= "" and __get_lucide(logo)) or (logo and logo) or __get_lucide("layout-grid")
        btn.ImageColor3 = Theme.TextPrimary
        btn.ScaleType = Enum.ScaleType.Fit
        btn.ZIndex = 50
        btn.Visible = false
        btn.Parent = euphoria
        __corner(btn, 0.12)
        __stroke(btn, Theme.Border)
        __shadow(btn, 0.5)

        local dragging = false
        local dragStart: Vector2?
        local startPos: UDim2?
        local moved = false

        local conn1 = btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                moved = false
                dragStart = input.Position
                startPos = btn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        table.insert(self.__connections, conn1)

        local conn2 = btn.InputChanged:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging and dragStart and startPos then
                local delta = input.Position - dragStart
                if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then moved = true end
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        table.insert(self.__connections, conn2)

        btn.MouseButton1Click:Connect(function()
            if not moved then self:toggle_window(false) end
        end)

        return btn
    end

    self.__floating_icon = createFloatingIcon()

    function self:toggle_window(force_minimized: boolean?)
        self.__minimized = (force_minimized ~= nil) and force_minimized or (not self.__minimized)
        self:__handle_minimize_toggle()
    end

    minimizeBtn.MouseButton1Click:Connect(function()
        self.__minimized = not self.__minimized
        self:__handle_minimize_toggle()
    end)

    exitBtn.MouseButton1Click:Connect(function()
        self.__closed = true
        if self.__floating_icon then
            self.__floating_icon:Destroy()
            self.__floating_icon = nil
        end
        __tween(main, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Quint).Completed:Connect(function()
            euphoria:Destroy()
            __disconnect_all(self.__connections)
        end)
    end)

    --> resize handle
    local resizeBtn = Instance.new("ImageButton")
    resizeBtn.Size = UDim2.new(0, 20, 0, 20)
    resizeBtn.Position = UDim2.new(1, -24, 1, -24)
    resizeBtn.BackgroundTransparency = 1
    resizeBtn.Image = "rbxassetid://10734961133"
    resizeBtn.ImageColor3 = Theme.TextMuted
    resizeBtn.ZIndex = 10
    resizeBtn.Parent = main

    self.__resizing = false

    if self.__device == "mobile" or self.__device == "unknown" then
        local hitbox = Instance.new("Frame")
        hitbox.Size = UDim2.new(0, 55, 0, 55)
        hitbox.Position = UDim2.new(1, -55, 1, -55)
        hitbox.BackgroundTransparency = 1
        hitbox.ZIndex = 9
        hitbox.Parent = main

        hitbox.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            self.__resizing = true
            self.__resize_start = Vector2.new(input.Position.X, input.Position.Y)
            self.__size_start = main.Size
        end)

        hitbox.InputChanged:Connect(function(input)
            if not self.__resizing or input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = Vector2.new(input.Position.X, input.Position.Y) - self.__resize_start
            main.Size = UDim2.new(0, math.max(320, self.__size_start.X.Offset + delta.X), 0, math.max(260, self.__size_start.Y.Offset + delta.Y))
        end)

        hitbox.InputEnded:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            self.__resizing = false
        end)
    end

    resizeBtn.MouseButton1Down:Connect(function()
        if self.__device ~= "pc" then return end
        self.__resizing = true
        self.__resize_start = UserInputService:GetMouseLocation()
        self.__size_start = main.Size
    end)

    local connIE = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.__resizing = false
        end
    end)
    table.insert(self.__connections, connIE)

    local connIC = UserInputService.InputChanged:Connect(function(input)
        if not self.__resizing then return end
        if self.__device == "pc" and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = UserInputService:GetMouseLocation() - self.__resize_start
            main.Size = UDim2.new(0, math.max(400, self.__size_start.X.Offset + delta.X), 0, math.max(300, self.__size_start.Y.Offset + delta.Y))
        end
    end)
    table.insert(self.__connections, connIC)

    --> smooth drag
    local dragConn: RBXScriptConnection?

    header.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        self.__dragging = true
        self.__drag_start = input.Position
        self.__start_pos = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                self.__dragging = false
                if dragConn then dragConn:Disconnect() dragConn = nil end
            end
        end)

        if not dragConn then
            dragConn = RunService.RenderStepped:Connect(function()
                if not self.__dragging or not self.__drag_input then return end
                local delta = self.__drag_input.Position - self.__drag_start
                main.Position = UDim2.new(self.__start_pos.X.Scale, self.__start_pos.X.Offset + delta.X, self.__start_pos.Y.Scale, self.__start_pos.Y.Offset + delta.Y)
            end)
        end
    end)

    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            self.__drag_input = input
        end
    end)

    --> minimize / restore
    local originalSize = UDim2.new(0, 700, 0, 450)
    local originalPos = UDim2.new(0.5, -350, 0.5, -225)
    local isAnimating = false

    function self:__handle_minimize_toggle()
        if isAnimating then return end
        isAnimating = true

        if self.__minimized then
            originalSize = main.Size
            originalPos = main.Position
            main.ClipsDescendants = true

            __tween(main, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + originalSize.X.Offset / 2, originalPos.Y.Scale, originalPos.Y.Offset + originalSize.Y.Offset / 2),
                BackgroundTransparency = 1,
            }, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function()
                main.Visible = false
                if self.__floating_icon then
                    self.__floating_icon.Visible = true
                    self.__floating_icon.Position = UDim2.new(0, 24, 0, 24)
                end
                isAnimating = false
            end)
        else
            if self.__floating_icon then self.__floating_icon.Visible = false end
            main.Visible = true
            main.Size = UDim2.new(0, 0, 0, 0)
            main.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + originalSize.X.Offset / 2, originalPos.Y.Scale, originalPos.Y.Offset + originalSize.Y.Offset / 2)
            main.BackgroundTransparency = 0.05
            main.ClipsDescendants = true

            __tween(main, {
                Size = originalSize,
                Position = originalPos,
                BackgroundTransparency = 0.05,
            }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out).Completed:Connect(function()
                main.ClipsDescendants = false
                isAnimating = false
            end)
        end
    end

    local connInsert = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Insert then
            self.__minimized = not self.__minimized
            self:__handle_minimize_toggle()
        end
    end)
    table.insert(self.__connections, connInsert)

    --> tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 145, 1, -53)
    tabContainer.Position = UDim2.new(0, 6, 0, 53)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ZIndex = 2
    tabContainer.Parent = main

    local tabSeparator = Instance.new("Frame")
    tabSeparator.Size = UDim2.new(0, 1, 1, -51)
    tabSeparator.Position = UDim2.new(0, 155, 0, 51)
    tabSeparator.BackgroundColor3 = Theme.Border
    tabSeparator.BorderSizePixel = 0
    tabSeparator.ZIndex = 2
    tabSeparator.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Parent = tabContainer

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.Parent = tabContainer

    --> content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -170, 1, -63)
    contentArea.Position = UDim2.new(0, 165, 0, 55)
    contentArea.BackgroundTransparency = 1
    contentArea.ZIndex = 2
    contentArea.Parent = main

    --> grow-in
    local targetSize = initial_size or UDim2.new(0, 700, 0, 450)
    if self.__device == "mobile" or self.__device == "unknown" then
        self:get_screen_scale()
        targetSize = UDim2.new(0, math.floor(Camera.ViewportSize.X * 0.88), 0, math.floor(Camera.ViewportSize.Y * 0.78))
    end

    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)

    task.delay(0.05, function()
        originalSize = targetSize
        originalPos = UDim2.new(0.5, -targetSize.X.Offset / 2, 0.5, -targetSize.Y.Offset / 2)
        __tween(main, { Size = targetSize, Position = originalPos }, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out).Completed:Connect(function()
            main.ClipsDescendants = false
            if self.__device == "mobile" or self.__device == "unknown" then
                self:mobile_ui_scale()
                self:mobile_controls()
            end
        end)
    end)

    --> create tab
    function Library:create_tab(name: string, icon: string?): Tab
        local tab: Tab = {}
        tab.__library = self

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -10, 0, 36)
        tabBtn.BackgroundColor3 = Theme.Surface
        tabBtn.BackgroundTransparency = 1
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.ClipsDescendants = true
        tabBtn.ZIndex = 3
        tabBtn.Parent = tabContainer
        __corner(tabBtn, 6)

        local tabStroke = __stroke(tabBtn, Theme.Border)
        tabStroke.Transparency = 1

        local tabHighlight = Instance.new("Frame")
        tabHighlight.Size = UDim2.new(0, 3, 0.55, 0)
        tabHighlight.Position = UDim2.new(0, -10, 0.225, 0)
        tabHighlight.BackgroundColor3 = Theme.Accent
        tabHighlight.BackgroundTransparency = 1
        tabHighlight.BorderSizePixel = 0
        tabHighlight.ZIndex = 4
        tabHighlight.Parent = tabBtn
        __corner(tabHighlight, 1)

        local tabHighlightEffect = Instance.new("Frame")
        tabHighlightEffect.Size = UDim2.new(1, 0, 1, 0)
        tabHighlightEffect.BackgroundColor3 = Theme.Accent
        tabHighlightEffect.BackgroundTransparency = 1
        tabHighlightEffect.BorderSizePixel = 0
        tabHighlightEffect.ZIndex = 3
        tabHighlightEffect.Parent = tabBtn
        __corner(tabHighlightEffect, 6)

        local tabIcon: ImageLabel?
        local labelOffset = 12

        if icon then
            tabIcon = Instance.new("ImageLabel")
            tabIcon.Size = UDim2.new(0, 16, 0, 16)
            tabIcon.Position = UDim2.new(0, 10, 0.5, -8)
            tabIcon.BackgroundTransparency = 1
            tabIcon.Image = __get_lucide(icon)
            tabIcon.ImageColor3 = Theme.TextMuted
            tabIcon.ZIndex = 4
            tabIcon.Parent = tabBtn
            labelOffset = 32
        end

        local tabLabel = Instance.new("TextLabel")
        tabLabel.Size = UDim2.new(1, -labelOffset - 10, 1, 0)
        tabLabel.Position = UDim2.new(0, labelOffset, 0, 0)
        tabLabel.BackgroundTransparency = 1
        tabLabel.Text = name
        tabLabel.TextColor3 = Theme.TextMuted
        tabLabel.TextSize = 14
        tabLabel.Font = Theme.FontMedium
        tabLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabLabel.ZIndex = 4
        tabLabel.Parent = tabBtn

        local container = Instance.new("ScrollingFrame")
        container.Name = name .. "Container"
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = Theme.TextMuted
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.Visible = false
        container.ZIndex = 2
        container.Parent = contentArea
        container:SetAttribute("SearchName", name)

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 7)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container

        local containerPadding = Instance.new("UIPadding")
        containerPadding.PaddingTop = UDim.new(0, 10)
        containerPadding.PaddingLeft = UDim.new(0, 2)
        containerPadding.PaddingRight = UDim.new(0, 12)
        containerPadding.PaddingBottom = UDim.new(0, 20)
        containerPadding.Parent = container

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + containerPadding.PaddingTop.Offset + containerPadding.PaddingBottom.Offset + 10)
        end)

        local function activateTab()
            for _, t in pairs(self.__tabs) do
                t.container.Visible = false
                t.button.BackgroundColor3 = Theme.Surface
                t.button.BackgroundTransparency = 1
                t.label.TextColor3 = Theme.TextMuted
                t.highlight.BackgroundTransparency = 1
                t.outline.Transparency = 1
                t.highlight_effect.BackgroundTransparency = 1
                if t.icon then t.icon.ImageColor3 = Theme.TextMuted end
            end

            container.Visible = true

            local order = 0
            for _, child in ipairs(container:GetChildren()) do
                if not child:IsA("Frame") then continue end
                child.LayoutOrder = order
                order += 1

                local original = child:GetAttribute("OriginalPosition")
                if original then
                    local xScale, xOffset, yScale, yOffset = original:match("([%d%.%-]+), ([%d%.%-]+), ([%d%.%-]+), ([%d%.%-]+)")
                    child.Position = UDim2.new(tonumber(xScale), tonumber(xOffset), tonumber(yScale), tonumber(yOffset) - 15)
                else
                    child:SetAttribute("OriginalPosition", tostring(child.Position))
                    child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, child.Position.Y.Scale, child.Position.Y.Offset - 15)
                end

                child.BackgroundTransparency = 1
                local stroke = child:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Transparency = 1 end

                task.delay(child.LayoutOrder * 0.035, function()
                    if not child or not child.Parent then return end
                    local orig = child:GetAttribute("OriginalPosition")
                    if orig then
                        local xs, xo, ys, yo = orig:match("([%d%.%-]+), ([%d%.%-]+), ([%d%.%-]+), ([%d%.%-]+)")
                        child.Position = UDim2.new(tonumber(xs), tonumber(xo), tonumber(ys), tonumber(yo))
                    end
                    local targetTrans = child.Name == "Divider" and 1 or 0.25
                    __tween(child, { BackgroundTransparency = targetTrans }, 0.3, Enum.EasingStyle.Quart)
                    if stroke then __tween(stroke, { Transparency = 0 }, 0.3) end
                end)
            end

            tabBtn.BackgroundColor3 = Theme.SurfaceHighlight
            tabBtn.BackgroundTransparency = 0.2
            tabLabel.TextColor3 = Theme.TextPrimary
            tabStroke.Transparency = 0
            tabHighlight.Position = UDim2.new(0, -10, 0.225, 0)
            tabHighlight.BackgroundTransparency = 0

            __tween(tabBtn, { BackgroundTransparency = 0.2 }, 0.3)
            __tween(tabHighlight, { Position = UDim2.new(0, 4, 0.225, 0) }, 0.4, Enum.EasingStyle.Quart)
            __tween(tabHighlightEffect, { BackgroundTransparency = 0.95 }, 0.3)

            if tabIcon then tabIcon.ImageColor3 = Theme.TextPrimary end

            self.__current_tab = tab
        end

        tabBtn.MouseButton1Click:Connect(activateTab)

        tab.button = tabBtn
        tab.container = container
        tab.label = tabLabel
        tab.highlight = tabHighlight
        tab.outline = tabStroke
        tab.highlight_effect = tabHighlightEffect
        tab.icon = tabIcon

        table.insert(self.__tabs, tab)
        if #self.__tabs == 1 then activateTab() end

        --> button
        function tab:create_button(index: { title: string, callback: () -> () })
            local frame = Instance.new("Frame")
            frame.Name = "Button"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = Theme.Surface
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 3
            frame.Parent = container
            frame:SetAttribute("SearchName", index.title)
            __corner(frame, 8)
            __stroke(frame, Theme.Border)

            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0, 18, 0, 18)
            icon.Position = UDim2.new(1, -36, 0.5, -9)
            icon.BackgroundTransparency = 1
            icon.Image = "rbxassetid://10709791437"
            icon.ImageColor3 = Theme.TextPrimary
            icon.ZIndex = 4
            icon.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = index.title
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 15
            label.Font = Theme.Font
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 4
            label.Parent = frame

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 5
            btn.Parent = frame

            btn.MouseButton1Click:Connect(function()
                __tween(frame, { BackgroundColor3 = Theme.SurfaceHighlight }, 0.1)
                task.delay(0.12, function()
                    __tween(frame, { BackgroundColor3 = Theme.Surface }, 0.25)
                end)
                if index.callback then index.callback() end
            end)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })
        end

        --> divider
        function tab:create_divider(text: string?)
            local frame = Instance.new("Frame")
            frame.Name = "Divider"
            frame.Size = UDim2.new(1, 0, 0, 24)
            frame.BackgroundTransparency = 1
            frame.BorderSizePixel = 0
            frame.ZIndex = 3
            frame.Parent = container
            frame:SetAttribute("SearchName", text or "")

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 1, 0)
            label.Position = UDim2.new(0, 5, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text or ""
            label.TextColor3 = Theme.TextMuted
            label.TextSize = 13
            label.Font = Theme.FontBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 4
            label.Parent = frame

            table.insert(self.__library.__all_elements, { name = text or "", frame = frame })
        end

        --> slider
        function tab:create_slider(index: { title: string, minimum: number?, maximum: number?, default: number?, rounding: number?, callback: (value: number) -> () }): { Set: (self: any, value: number) -> () }
            local min = index.minimum or 0
            local max = index.maximum or 100
            local default = index.default or min
            local rounding = index.rounding or 0
            local callback = index.callback or function() end
            local value = default
            local dragging = false

            local frame = Instance.new("Frame")
            frame.Name = "Slider"
            frame.Size = UDim2.new(1, 0, 0, 52)
            frame.BackgroundColor3 = Theme.Surface
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 3
            frame.Parent = container
            frame:SetAttribute("SearchName", index.title)
            __corner(frame, 8)
            __stroke(frame, Theme.Border)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 0, 20)
            label.Position = UDim2.new(0, 15, 0, 8)
            label.BackgroundTransparency = 1
            label.Text = index.title
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 15
            label.Font = Theme.Font
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 4
            label.Parent = frame

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0.3, 0, 0, 20)
            valueLabel.Position = UDim2.new(0.7, -15, 0, 8)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(value)
            valueLabel.TextColor3 = Theme.TextSecondary
            valueLabel.TextSize = 13
            valueLabel.Font = Theme.FontMedium
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.ZIndex = 4
            valueLabel.Parent = frame

            local trackBg = Instance.new("Frame")
            trackBg.Size = UDim2.new(1, -30, 0, 5)
            trackBg.Position = UDim2.new(0, 15, 1, -20)
            trackBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            trackBg.BorderSizePixel = 0
            trackBg.ZIndex = 4
            trackBg.Parent = frame
            __corner(trackBg, 3)

            local hitbox = Instance.new("Frame")
            hitbox.Size = UDim2.new(1, 0, 0, 24)
            hitbox.Position = UDim2.new(0, 0, 0.5, -12)
            hitbox.BackgroundTransparency = 1
            hitbox.ZIndex = 7
            hitbox.Parent = trackBg

            local track = Instance.new("Frame")
            track.Size = UDim2.new(0, 0, 1, 0)
            track.BackgroundColor3 = Theme.Accent
            track.BorderSizePixel = 0
            track.ZIndex = 5
            track.Parent = trackBg
            __corner(track, 3)

            local ball = Instance.new("Frame")
            ball.Size = UDim2.new(0, 12, 0, 12)
            ball.Position = UDim2.new(1, -6, 0.5, -6)
            ball.BackgroundColor3 = Theme.Accent
            ball.BorderSizePixel = 0
            ball.ZIndex = 6
            ball.Parent = track
            __corner(ball, 6)
            __stroke(ball, Color3.fromRGB(60, 60, 60), 1)

            local function updateSlider(input: InputObject)
                local pos = math.clamp((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * pos)
                if rounding > 0 then value = math.floor(value / rounding) * rounding end
                value = math.clamp(value, min, max)
                valueLabel.Text = tostring(value)
                __tween(track, { Size = UDim2.new(pos, 0, 1, 0) }, 0.1)
                callback(value)
            end

            local function setValue(newValue: number)
                value = math.clamp(newValue, min, max)
                if rounding > 0 then value = math.floor(value / rounding) * rounding end
                valueLabel.Text = tostring(value)
                track.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                callback(value)
            end

            setValue(default)

            hitbox.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                dragging = true
                __tween(ball, { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7) }, 0.15)
                updateSlider(input)
            end)

            hitbox.InputEnded:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                dragging = false
                __tween(ball, { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6) }, 0.15)
            end)

            local conn = UserInputService.InputChanged:Connect(function(input)
                if not dragging or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
                updateSlider(input)
            end)
            table.insert(self.__library.__connections, conn)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })

            return { Set = function(_, v: number) setValue(v) end }
        end

        --> textbox
        function tab:create_textbox(index: { title: string, placeholder: string?, callback: (text: string) -> () }): { Set: (self: any, text: string) -> () }
            local callback = index.callback or function() end

            local frame = Instance.new("Frame")
            frame.Name = "Textbox"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = Theme.Surface
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 3
            frame.Parent = container
            frame:SetAttribute("SearchName", index.title)
            __corner(frame, 8)
            __stroke(frame, Theme.Border)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 100, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = index.title
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 15
            label.Font = Theme.Font
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 4
            label.Parent = frame

            local inputContainer = Instance.new("Frame")
            inputContainer.Size = UDim2.new(0, 200, 0, 28)
            inputContainer.Position = UDim2.new(1, -210, 0.5, -14)
            inputContainer.BackgroundColor3 = Theme.Foreground
            inputContainer.BackgroundTransparency = 0.4
            inputContainer.BorderSizePixel = 0
            inputContainer.ZIndex = 4
            inputContainer.Parent = frame
            __corner(inputContainer, 6)
            __stroke(inputContainer, Theme.Border)

            local iconContainer = Instance.new("Frame")
            iconContainer.Size = UDim2.new(0, 28, 1, 0)
            iconContainer.BackgroundColor3 = Theme.Foreground
            iconContainer.BackgroundTransparency = 0.6
            iconContainer.BorderSizePixel = 0
            iconContainer.ZIndex = 4
            iconContainer.Parent = inputContainer
            __corner(iconContainer, 6)

            local inputDivider = Instance.new("Frame")
            inputDivider.Size = UDim2.new(0, 1, 0.6, 0)
            inputDivider.Position = UDim2.new(0, 28, 0.2, 0)
            inputDivider.BackgroundColor3 = Theme.Border
            inputDivider.BorderSizePixel = 0
            inputDivider.ZIndex = 5
            inputDivider.Parent = inputContainer

            local textIcon = Instance.new("ImageLabel")
            textIcon.Size = UDim2.new(0, 16, 0, 16)
            textIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
            textIcon.BackgroundTransparency = 1
            textIcon.Image = "rbxassetid://10723433811"
            textIcon.ImageColor3 = Theme.TextMuted
            textIcon.ZIndex = 5
            textIcon.Parent = iconContainer

            local textbox = Instance.new("TextBox")
            textbox.Size = UDim2.new(1, -35, 1, 0)
            textbox.Position = UDim2.new(0, 32, 0, 0)
            textbox.BackgroundTransparency = 1
            textbox.Text = ""
            textbox.PlaceholderText = index.placeholder or ""
            textbox.TextColor3 = Theme.TextPrimary
            textbox.PlaceholderColor3 = Theme.TextMuted
            textbox.TextSize = 13
            textbox.Font = Theme.Font
            textbox.TextXAlignment = Enum.TextXAlignment.Left
            textbox.ClearTextOnFocus = false
            textbox.ZIndex = 5
            textbox.Parent = inputContainer

            textbox.FocusLost:Connect(function(enterPressed)
                if enterPressed then callback(textbox.Text) end
            end)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })

            return { Set = function(_, t: string) textbox.Text = t end }
        end

        --> checkbox
        function tab:create_checkbox(index: { title: string, default: boolean?, callback: (state: boolean) -> () }): { Set: (self: any, state: boolean) -> () }
            local default = index.default or false
            local callback = index.callback or function() end
            local toggled = default

            local frame = Instance.new("Frame")
            frame.Name = "Checkbox"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = Theme.Surface
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 3
            frame.Parent = container
            frame:SetAttribute("SearchName", index.title)
            __corner(frame, 8)
            __stroke(frame, Theme.Border)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = index.title
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 15
            label.Font = Theme.Font
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 4
            label.Parent = frame

            local checkFrame = Instance.new("Frame")
            checkFrame.Size = UDim2.new(0, 24, 0, 24)
            checkFrame.Position = UDim2.new(1, -40, 0.5, -12)
            checkFrame.BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(25, 25, 25)
            checkFrame.BorderSizePixel = 0
            checkFrame.ZIndex = 4
            checkFrame.Parent = frame
            __corner(checkFrame, 6)
            __stroke(checkFrame, Theme.Border)

            local checkIcon = Instance.new("ImageLabel")
            checkIcon.Size = UDim2.new(0, 16, 0, 16)
            checkIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
            checkIcon.BackgroundTransparency = 1
            checkIcon.Image = "rbxassetid://10709790644"
            checkIcon.ImageColor3 = Color3.fromRGB(0, 0, 0)
            checkIcon.ImageTransparency = toggled and 0.2 or 1
            checkIcon.ZIndex = 5
            checkIcon.Parent = checkFrame

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 5
            btn.Parent = frame

            local function setState(state: boolean)
                toggled = state
                __tween(checkFrame, { BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(25, 25, 25) }, 0.3)
                __tween(checkIcon, { ImageTransparency = toggled and 0.2 or 1 }, 0.3)
                callback(toggled)
            end

            btn.MouseButton1Click:Connect(function() setState(not toggled) end)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })

            return { Set = function(_, s: boolean) setState(s) end }
        end

        --> dropdown
        function tab:create_dropdown(index: { title: string, options: { string }, default: string | { string }?, multi_selection: boolean?, callback: (value: string | { string }) -> () }): { Set: (self: any, value: string | { string }) -> () }
            local options = index.options or {}
            local defaultValue = index.default or "--"
            local multi = index.multi_selection or false
            local callback = index.callback or function() end
            local selected: string | { string } = multi and (type(defaultValue) == "table" and defaultValue :: { string } or {}) or (defaultValue ~= "--" and defaultValue :: string or options[1] or "--")
            local opened = false
            local animating = false

            local frame = Instance.new("Frame")
            frame.Name = "Dropdown"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = Theme.Surface
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ZIndex = 10
            frame.ClipsDescendants = false
            frame.Parent = container
            frame:SetAttribute("SearchName", index.title)
            __corner(frame, 8)
            __stroke(frame, Theme.Border)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 150, 0, 42)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = index.title
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 15
            label.Font = Theme.Font
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 11
            label.Parent = frame

            local ddContainer = Instance.new("Frame")
            ddContainer.Size = UDim2.new(0, 145, 0, 28)
            ddContainer.Position = UDim2.new(1, -155, 0.5, -14)
            ddContainer.BackgroundColor3 = Theme.Foreground
            ddContainer.BackgroundTransparency = 0
            ddContainer.BorderSizePixel = 0
            ddContainer.ClipsDescendants = true
            ddContainer.ZIndex = 15
            ddContainer.Parent = frame
            __corner(ddContainer, 6)
            __stroke(ddContainer, Theme.Border)

            local function getDisplay(): string
                if multi then
                    local sel = selected :: { string }
                    if #sel == 0 then return "--" end
                    return table.concat(sel, ", ")
                else
                    return selected :: string
                end
            end

            local iconContainer = Instance.new("Frame")
            iconContainer.Size = UDim2.new(0, 28, 0, 28)
            iconContainer.Position = UDim2.new(1, -28, 0, 0)
            iconContainer.BackgroundColor3 = Theme.Foreground
            iconContainer.BackgroundTransparency = 0.6
            iconContainer.BorderSizePixel = 0
            iconContainer.ZIndex = 16
            iconContainer.Parent = ddContainer
            __corner(iconContainer, 6)

            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.new(0, 12, 0, 12)
            arrow.Position = UDim2.new(0.5, -6, 0.5, -6)
            arrow.BackgroundTransparency = 1
            arrow.Image = "rbxassetid://10709790948"
            arrow.ImageColor3 = Theme.TextMuted
            arrow.Rotation = 0
            arrow.ZIndex = 17
            arrow.Parent = iconContainer

            local inputDivider = Instance.new("Frame")
            inputDivider.Size = UDim2.new(0, 1, 0, 17)
            inputDivider.Position = UDim2.new(1, -29, 0, 6)
            inputDivider.BackgroundColor3 = Theme.Border
            inputDivider.BorderSizePixel = 0
            inputDivider.ZIndex = 17
            inputDivider.Parent = ddContainer

            local selLabel = Instance.new("TextLabel")
            selLabel.Size = UDim2.new(1, -35, 0, 28)
            selLabel.Position = UDim2.new(0, 8, 0, 0)
            selLabel.BackgroundTransparency = 1
            selLabel.Text = getDisplay()
            selLabel.TextColor3 = Theme.TextPrimary
            selLabel.TextSize = 12
            selLabel.Font = Theme.Font
            selLabel.TextXAlignment = Enum.TextXAlignment.Left
            selLabel.TextTruncate = Enum.TextTruncate.None
            selLabel.ClipsDescendants = true
            selLabel.ZIndex = 16
            selLabel.Parent = ddContainer

            local fade = Instance.new("UIGradient")
            fade.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
            }
            fade.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(0.75, 0.4),
                NumberSequenceKeypoint.new(0.85, 0.7),
                NumberSequenceKeypoint.new(0.95, 0.9),
                NumberSequenceKeypoint.new(1, 1),
            }
            fade.Parent = selLabel

            local searchContainer = Instance.new("Frame")
            searchContainer.Size = UDim2.new(1, -10, 0, 26)
            searchContainer.Position = UDim2.new(0, 5, 0, 30)
            searchContainer.BackgroundColor3 = Theme.SurfaceHighlight
            searchContainer.BorderSizePixel = 0
            searchContainer.Visible = false
            searchContainer.ZIndex = 17
            searchContainer.Parent = ddContainer
            __corner(searchContainer, 5)

            local searchIconContainer = Instance.new("Frame")
            searchIconContainer.Size = UDim2.new(0, 26, 1, 0)
            searchIconContainer.BackgroundColor3 = Theme.Foreground
            searchIconContainer.BackgroundTransparency = 0.5
            searchIconContainer.BorderSizePixel = 0
            searchIconContainer.ZIndex = 17
            searchIconContainer.Parent = searchContainer
            __corner(searchIconContainer, 5)

            local searchDivider = Instance.new("Frame")
            searchDivider.Size = UDim2.new(0, 1, 0.6, 0)
            searchDivider.Position = UDim2.new(0, 26, 0.2, 0)
            searchDivider.BackgroundColor3 = Theme.Border
            searchDivider.BorderSizePixel = 0
            searchDivider.ZIndex = 18
            searchDivider.Parent = searchContainer

            local searchIcon = Instance.new("ImageLabel")
            searchIcon.Size = UDim2.new(0, 12, 0, 12)
            searchIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
            searchIcon.BackgroundTransparency = 1
            searchIcon.Image = "rbxassetid://10734943674"
            searchIcon.ImageColor3 = Theme.TextMuted
            searchIcon.ZIndex = 18
            searchIcon.Parent = searchIconContainer

            local searchBox = Instance.new("TextBox")
            searchBox.Size = UDim2.new(1, -30, 1, 0)
            searchBox.Position = UDim2.new(0, 29, 0, 0)
            searchBox.BackgroundTransparency = 1
            searchBox.Text = ""
            searchBox.PlaceholderText = "Search..."
            searchBox.TextColor3 = Theme.TextPrimary
            searchBox.PlaceholderColor3 = Theme.TextMuted
            searchBox.TextSize = 10
            searchBox.Font = Theme.Font
            searchBox.TextXAlignment = Enum.TextXAlignment.Left
            searchBox.ClearTextOnFocus = false
            searchBox.ZIndex = 18
            searchBox.Parent = searchContainer

            local optionsContainer = Instance.new("ScrollingFrame")
            optionsContainer.Size = UDim2.new(1, 0, 0, 0)
            optionsContainer.Position = UDim2.new(0, 0, 0, 58)
            optionsContainer.BackgroundTransparency = 1
            optionsContainer.BorderSizePixel = 0
            optionsContainer.ScrollBarThickness = 2
            optionsContainer.ScrollBarImageColor3 = Theme.TextMuted
            optionsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
            optionsContainer.ZIndex = 17
            optionsContainer.Parent = ddContainer

            local optionsPadding = Instance.new("UIPadding")
            optionsPadding.PaddingLeft = UDim.new(0, 5)
            optionsPadding.PaddingRight = UDim.new(0, 5)
            optionsPadding.Parent = optionsContainer

            local optionsLayout = Instance.new("UIListLayout")
            optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optionsLayout.Padding = UDim.new(0, 2)
            optionsLayout.Parent = optionsContainer

            optionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                optionsContainer.CanvasSize = UDim2.new(0, 0, 0, optionsLayout.AbsoluteContentSize.Y)
            end)

            local function closeDropdown(instant: boolean)
                if not opened then return end
                opened = false
                animating = false
                searchContainer.Visible = false
                optionsContainer.Size = UDim2.new(1, 0, 0, 0)
                searchBox.Text = ""

                if instant then
                    ddContainer.Size = UDim2.new(0, 145, 0, 28)
                    arrow.Rotation = 0
                    frame.ZIndex = 10
                    ddContainer.ZIndex = 15
                    ddContainer.ClipsDescendants = true
                    label.ZIndex = 11
                    selLabel.ZIndex = 16
                    iconContainer.ZIndex = 16
                    arrow.ZIndex = 17
                    inputDivider.ZIndex = 17
                    ddContainer.Parent = frame
                    ddContainer.Position = UDim2.new(1, -155, 0.5, -14)
                else
                    animating = true
                    __tween(ddContainer, { Size = UDim2.new(0, 145, 0, 28) }, 0.3)
                    __tween(arrow, { Rotation = 0 }, 0.3)
                    task.wait(0.3)
                    frame.ZIndex = 10
                    ddContainer.ZIndex = 15
                    ddContainer.ClipsDescendants = true
                    label.ZIndex = 11
                    selLabel.ZIndex = 16
                    iconContainer.ZIndex = 16
                    arrow.ZIndex = 17
                    inputDivider.ZIndex = 17
                    ddContainer.Parent = frame
                    ddContainer.Position = UDim2.new(1, -155, 0.5, -14)
                    animating = false
                end
            end

            container:GetPropertyChangedSignal("Visible"):Connect(function()
                if not container.Visible and opened then closeDropdown(true) end
            end)
            container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                if opened then closeDropdown(true) end
            end)

            local function createOption(option: string)
                local isSelected = false
                if multi then
                    isSelected = table.find(selected :: { string }, option) ~= nil
                else
                    isSelected = selected == option
                end

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 35)
                btn.BackgroundColor3 = isSelected and Theme.SurfaceHighlight or Theme.Surface
                btn.BackgroundTransparency = 0.2
                btn.BorderSizePixel = 0
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.ZIndex = 18
                btn.Parent = optionsContainer
                __corner(btn, 5)

                local highlight = Instance.new("Frame")
                highlight.Size = UDim2.new(0, 2, 0.6, 0)
                highlight.Position = UDim2.new(0, 1, 0.2, 0)
                highlight.BackgroundColor3 = Theme.Accent
                highlight.BackgroundTransparency = isSelected and 0.1 or 1
                highlight.BorderSizePixel = 0
                highlight.ZIndex = 19
                highlight.Parent = btn
                __corner(highlight, 1)

                local optLabel = Instance.new("TextLabel")
                optLabel.Size = UDim2.new(1, -10, 1, 0)
                optLabel.Position = UDim2.new(0, 8, 0, 0)
                optLabel.BackgroundTransparency = 1
                optLabel.Text = option
                optLabel.TextColor3 = isSelected and Theme.TextPrimary or Theme.TextMuted
                optLabel.TextSize = 13
                optLabel.Font = Theme.FontMedium
                optLabel.TextXAlignment = Enum.TextXAlignment.Left
                optLabel.ZIndex = 19
                optLabel.Parent = btn

                local effect = Instance.new("Frame")
                effect.Size = UDim2.new(1, 0, 1, 0)
                effect.BackgroundColor3 = Theme.Accent
                effect.BackgroundTransparency = 1
                effect.BorderSizePixel = 0
                effect.ZIndex = 17
                effect.Parent = btn
                __corner(effect, 5)

                btn.MouseButton1Click:Connect(function()
                    effect.BackgroundTransparency = 1
                    __tween(effect, { BackgroundTransparency = 0.92 }, 0.3)
                    task.delay(0.3, function() __tween(effect, { BackgroundTransparency = 1 }, 0.3) end)

                    if multi then
                        local sel = selected :: { string }
                        local idx = table.find(sel, option)
                        if idx then
                            table.remove(sel, idx)
                            isSelected = false
                            __tween(btn, { BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.2 }, 0.2)
                            __tween(optLabel, { TextColor3 = Theme.TextMuted }, 0.2)
                            __tween(highlight, { BackgroundTransparency = 1 }, 0.3)
                        else
                            table.insert(sel, option)
                            isSelected = true
                            __tween(btn, { BackgroundColor3 = Theme.SurfaceHighlight, BackgroundTransparency = 0.2 }, 0.2)
                            __tween(optLabel, { TextColor3 = Theme.TextPrimary }, 0.2)
                            __tween(highlight, { BackgroundTransparency = 0.1 }, 0.3)
                        end
                        selLabel.Text = getDisplay()
                        callback(sel)
                    else
                        for _, child in pairs(optionsContainer:GetChildren()) do
                            if not child:IsA("TextButton") then continue end
                            local hl = child:FindFirstChildOfClass("Frame")
                            local lbl = child:FindFirstChildOfClass("TextLabel")
                            if child ~= btn then
                                __tween(child, { BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.2 }, 0.2)
                                if lbl then __tween(lbl, { TextColor3 = Theme.TextMuted }, 0.2) end
                                if hl then __tween(hl, { BackgroundTransparency = 1 }, 0.3) end
                            end
                        end
                        selected = option
                        isSelected = true
                        selLabel.Text = option
                        __tween(btn, { BackgroundColor3 = Theme.SurfaceHighlight, BackgroundTransparency = 0.2 }, 0.2)
                        __tween(optLabel, { TextColor3 = Theme.TextPrimary }, 0.2)
                        __tween(highlight, { BackgroundTransparency = 0.1 }, 0.3)
                        callback(option)
                    end
                end)

                return btn
            end

            for _, opt in ipairs(options) do createOption(opt) end

            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local q = searchBox.Text:lower()
                for _, child in pairs(optionsContainer:GetChildren()) do
                    if not child:IsA("TextButton") then continue end
                    local lbl = child:FindFirstChildOfClass("TextLabel")
                    if lbl then
                        child.Visible = q == "" or lbl.Text:lower():find(q) ~= nil
                    end
                end
            end)

            local ddBtn = Instance.new("TextButton")
            ddBtn.Size = UDim2.new(1, 0, 1, 0)
            ddBtn.BackgroundTransparency = 1
            ddBtn.Text = ""
            ddBtn.ZIndex = 16
            ddBtn.Parent = ddContainer

            ddBtn.MouseButton1Click:Connect(function()
                if animating then return end
                if opened then
                    closeDropdown(false)
                    return
                end
                animating = true
                opened = true

                local absPos = ddContainer.AbsolutePosition
                local mainAbs = main.AbsolutePosition

                ddContainer.Parent = overlay
                ddContainer.Position = UDim2.new(0, absPos.X - mainAbs.X, 0, absPos.Y - mainAbs.Y)
                ddContainer.Size = UDim2.new(0, 145, 0, 28)

                frame.ZIndex = 20
                ddContainer.ZIndex = 21
                ddContainer.ClipsDescendants = false
                label.ZIndex = 22
                selLabel.ZIndex = 23
                iconContainer.ZIndex = 23
                arrow.ZIndex = 24
                inputDivider.ZIndex = 24

                local actualHeight = math.min(optionsLayout.AbsoluteContentSize.Y, math.min(#options * 37, 148))
                searchContainer.Visible = true
                optionsContainer.Size = UDim2.new(1, 0, 0, actualHeight)

                for i, child in pairs(optionsContainer:GetChildren()) do
                    if not child:IsA("TextButton") then continue end
                    child.BackgroundTransparency = 1
                    local lbl = child:FindFirstChildOfClass("TextLabel")
                    if lbl then lbl.TextTransparency = 1 end
                    task.delay(0.1 + (i * 0.001), function()
                        __tween(child, { BackgroundTransparency = 0.2 }, 0.2)
                        if lbl then __tween(lbl, { TextTransparency = 0 }, 0.2) end
                    end)
                end

                __tween(ddContainer, { Size = UDim2.new(0, 145, 0, 58 + actualHeight + 6) }, 0.3)
                __tween(arrow, { Rotation = 180 }, 0.3)
                task.wait(0.3)
                animating = false
            end)

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })

            task.spawn(function()
                while frame and frame.Parent do
                    task.wait(0.2)
                    if self.__library.__minimized and opened then
                        closeDropdown(true)
                    end
                end
            end)

            return {
                Set = function(_, val: string | { string })
                    if multi then
                        selected = (type(val) == "table" and val :: { string }) or {}
                    else
                        selected = val :: string
                    end
                    selLabel.Text = getDisplay()
                    callback(selected)
                end
            }
        end

        --> module
        function tab:create_module(index: { title: string, default: boolean?, callback: (state: boolean) -> () }): Module
            local module: Module = {}
            module.__elements = {}
            module.__library = self.__library

            local default = index.default or false
            local callback = index.callback or function() end
            local toggled = default
            local currentKeybind: Enum.KeyCode? = nil
            local waitingForKey = false

            local frame = Instance.new("Frame")
            frame.Name = "Module"
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundColor3 = Theme.Surface
            frame.BackgroundTransparency = 0.25
            frame.BorderSizePixel = 0
            frame.ClipsDescendants = false
            frame.ZIndex = 3
            frame.Parent = container
            frame:SetAttribute("SearchName", index.title)
            __corner(frame, 8)
            __stroke(frame, Theme.Border)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -110, 0, 42)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = index.title
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 15
            label.Font = Theme.Font
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 4
            label.Parent = frame

            local keybindBtn = Instance.new("TextButton")
            keybindBtn.Size = UDim2.new(0, 32, 0, 24)
            keybindBtn.Position = UDim2.new(1, -92, 0, 9)
            keybindBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            keybindBtn.BorderSizePixel = 0
            keybindBtn.Text = ""
            keybindBtn.ZIndex = 5
            keybindBtn.Parent = frame
            __corner(keybindBtn, 6)
            __stroke(keybindBtn, Theme.Border)

            local keybindIcon = Instance.new("ImageLabel")
            keybindIcon.Size = UDim2.new(0, 16, 0, 16)
            keybindIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
            keybindIcon.BackgroundTransparency = 1
            keybindIcon.Image = "rbxassetid://10709818996"
            keybindIcon.ImageColor3 = Theme.TextMuted
            keybindIcon.ZIndex = 6
            keybindIcon.Parent = keybindBtn

            local keybindLabel = Instance.new("TextLabel")
            keybindLabel.Size = UDim2.new(1, 0, 1, 0)
            keybindLabel.BackgroundTransparency = 1
            keybindLabel.Text = ""
            keybindLabel.TextColor3 = Theme.TextPrimary
            keybindLabel.TextSize = 10
            keybindLabel.Font = Theme.FontBold
            keybindLabel.ZIndex = 7
            keybindLabel.Parent = keybindBtn

            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(0, 46, 0, 24)
            toggleFrame.Position = UDim2.new(1, -58, 0, 9)
            toggleFrame.BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(25, 25, 25)
            toggleFrame.BorderSizePixel = 0
            toggleFrame.ZIndex = 4
            toggleFrame.Parent = frame
            __corner(toggleFrame, 12)
            __stroke(toggleFrame, Theme.Border)

            local toggleCircle = Instance.new("Frame")
            toggleCircle.Size = UDim2.new(0, 18, 0, 18)
            toggleCircle.Position = toggled and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            toggleCircle.BackgroundColor3 = toggled and Color3.fromRGB(0, 0, 0) or Theme.TextPrimary
            toggleCircle.BorderSizePixel = 0
            toggleCircle.ZIndex = 5
            toggleCircle.Parent = toggleFrame
            __corner(toggleCircle, 9)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -100, 0, 42)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 5
            btn.Parent = frame

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0, 46, 0, 24)
            toggleBtn.Position = UDim2.new(1, -58, 0, 9)
            toggleBtn.BackgroundTransparency = 1
            toggleBtn.Text = ""
            toggleBtn.ZIndex = 6
            toggleBtn.Parent = frame

            local separator = Instance.new("Frame")
            separator.Size = UDim2.new(1, -20, 0, 1)
            separator.Position = UDim2.new(0, 10, 0, 42)
            separator.BackgroundColor3 = Theme.Border
            separator.BorderSizePixel = 0
            separator.ZIndex = 4
            separator.Visible = false
            separator.Parent = frame

            local moduleContainer = Instance.new("Frame")
            moduleContainer.Name = "ModuleContainer"
            moduleContainer.Size = UDim2.new(1, 0, 0, 0)
            moduleContainer.Position = UDim2.new(0, 0, 0, 46)
            moduleContainer.BackgroundTransparency = 1
            moduleContainer.Visible = false
            moduleContainer.ZIndex = 4
            moduleContainer.Parent = frame

            local modulePadding = Instance.new("UIPadding")
            modulePadding.PaddingLeft = UDim.new(0, 10)
            modulePadding.PaddingRight = UDim.new(0, 10)
            modulePadding.PaddingTop = UDim.new(0, 2)
            modulePadding.Parent = moduleContainer

            local moduleLayout = Instance.new("UIListLayout")
            moduleLayout.Padding = UDim.new(0, 5)
            moduleLayout.SortOrder = Enum.SortOrder.LayoutOrder
            moduleLayout.Parent = moduleContainer

            local function updateModuleHeight()
                local total = 42
                for _, elem in pairs(module.__elements) do
                    total += elem.Size.Y.Offset + 5
                end
                __tween(frame, { Size = UDim2.new(1, 0, 0, total + 10) }, 0.3, Enum.EasingStyle.Quart)
            end

            local function toggleModule(state: boolean)
                if toggled == state then return end
                toggled = state
                __tween(toggleFrame, { BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(25, 25, 25) }, 0.3)
                __tween(toggleCircle, {
                    Position = toggled and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
                    BackgroundColor3 = toggled and Color3.fromRGB(0, 0, 0) or Theme.TextPrimary,
                }, 0.3)

                if toggled and #module.__elements > 0 then
                    separator.Visible = true
                    moduleContainer.Visible = true
                    updateModuleHeight()
                elseif not toggled then
                    __tween(frame, { Size = UDim2.new(1, 0, 0, 42) }, 0.3)
                    separator.Visible = false
                    moduleContainer.Visible = false
                end
                callback(toggled)
            end

            keybindBtn.MouseButton1Click:Connect(function()
                if waitingForKey then
                    waitingForKey = false
                    keybindLabel.Text = currentKeybind and currentKeybind.Name or ""
                    __tween(keybindIcon, { ImageTransparency = currentKeybind and 1 or 0 }, 0.2)
                    return
                end
                waitingForKey = true
                keybindLabel.Text = "..."
                __tween(keybindIcon, { ImageTransparency = 1 }, 0.2)

                local conn
                conn = UserInputService.InputBegan:Connect(function(input, process)
                    if process then return end
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    waitingForKey = false
                    currentKeybind = input.KeyCode
                    keybindLabel.Text = input.KeyCode.Name
                    keybindIcon.ImageTransparency = 1
                    conn:Disconnect()
                end)
            end)

            local connKB = UserInputService.InputBegan:Connect(function(input, process)
                if process or waitingForKey then return end
                if currentKeybind and input.KeyCode == currentKeybind then
                    toggleModule(not toggled)
                end
            end)
            table.insert(self.__library.__connections, connKB)

            btn.MouseButton1Click:Connect(function() toggleModule(not toggled) end)
            toggleBtn.MouseButton1Click:Connect(function() toggleModule(not toggled) end)

            --> module elements
            function module:create_checkbox(index: { title: string, default: boolean?, callback: (state: boolean) -> () }): { Set: (self: any, state: boolean) -> () }
                local itemDefault = index.default or false
                local itemCallback = index.callback or function() end
                local itemToggled = itemDefault

                local itemFrame = Instance.new("Frame")
                itemFrame.Size = UDim2.new(1, 0, 0, 35)
                itemFrame.BackgroundColor3 = Theme.Surface
                itemFrame.BackgroundTransparency = 0.2
                itemFrame.BorderSizePixel = 0
                itemFrame.ZIndex = 4
                itemFrame.Parent = moduleContainer
                itemFrame:SetAttribute("SearchName", index.title)
                __corner(itemFrame, 6)
                __stroke(itemFrame, Theme.Border)

                local itemLabel = Instance.new("TextLabel")
                itemLabel.Size = UDim2.new(1, -60, 1, 0)
                itemLabel.Position = UDim2.new(0, 15, 0, 0)
                itemLabel.BackgroundTransparency = 1
                itemLabel.Text = index.title
                itemLabel.TextColor3 = Theme.TextSecondary
                itemLabel.TextSize = 13
                itemLabel.Font = Theme.Font
                itemLabel.TextXAlignment = Enum.TextXAlignment.Left
                itemLabel.ZIndex = 5
                itemLabel.Parent = itemFrame

                local itemCheck = Instance.new("Frame")
                itemCheck.Size = UDim2.new(0, 20, 0, 20)
                itemCheck.Position = UDim2.new(1, -35, 0.5, -10)
                itemCheck.BackgroundColor3 = itemToggled and Theme.Accent or Color3.fromRGB(25, 25, 25)
                itemCheck.BorderSizePixel = 0
                itemCheck.ZIndex = 5
                itemCheck.Parent = itemFrame
                __corner(itemCheck, 5)
                __stroke(itemCheck, Theme.Border)

                local itemCheckIcon = Instance.new("ImageLabel")
                itemCheckIcon.Size = UDim2.new(0, 14, 0, 14)
                itemCheckIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
                itemCheckIcon.BackgroundTransparency = 1
                itemCheckIcon.Image = "rbxassetid://10709790644"
                itemCheckIcon.ImageColor3 = Color3.fromRGB(0, 0, 0)
                itemCheckIcon.ImageTransparency = itemToggled and 0.2 or 1
                itemCheckIcon.ZIndex = 6
                itemCheckIcon.Parent = itemCheck

                local itemBtn = Instance.new("TextButton")
                itemBtn.Size = UDim2.new(1, 0, 1, 0)
                itemBtn.BackgroundTransparency = 1
                itemBtn.Text = ""
                itemBtn.ZIndex = 6
                itemBtn.Parent = itemFrame

                local function setItemState(state: boolean)
                    itemToggled = state
                    __tween(itemCheck, { BackgroundColor3 = itemToggled and Theme.Accent or Color3.fromRGB(25, 25, 25) }, 0.3)
                    __tween(itemCheckIcon, { ImageTransparency = itemToggled and 0.2 or 1 }, 0.3)
                    itemCallback(itemToggled)
                end

                itemBtn.MouseButton1Click:Connect(function() setItemState(not itemToggled) end)

                table.insert(module.__elements, itemFrame)
                if toggled then updateModuleHeight() end

                return { Set = function(_, s: boolean) setItemState(s) end }
            end

            function module:create_divider(text: string?)
                local itemFrame = Instance.new("Frame")
                itemFrame.Name = "DividerItem"
                itemFrame.Size = UDim2.new(1, 0, 0, 22)
                itemFrame.BackgroundTransparency = 1
                itemFrame.BorderSizePixel = 0
                itemFrame.ZIndex = 4
                itemFrame.Parent = moduleContainer
                itemFrame:SetAttribute("SearchName", text or "")

                local divLabel = Instance.new("TextLabel")
                divLabel.Size = UDim2.new(1, -20, 1, 0)
                divLabel.Position = UDim2.new(0, 5, 0, 0)
                divLabel.BackgroundTransparency = 1
                divLabel.Text = text or ""
                divLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
                divLabel.TextSize = 13
                divLabel.Font = Theme.FontBold
                divLabel.TextXAlignment = Enum.TextXAlignment.Left
                divLabel.ZIndex = 5
                divLabel.Parent = itemFrame

                table.insert(module.__elements, itemFrame)
                if toggled then updateModuleHeight() end
            end

            function module:create_textbox(index: { title: string, placeholder: string?, callback: (text: string) -> () }): { Set: (self: any, text: string) -> () }
                local itemCallback = index.callback or function() end

                local itemFrame = Instance.new("Frame")
                itemFrame.Name = "TextboxItem"
                itemFrame.Size = UDim2.new(1, 0, 0, 40)
                itemFrame.BackgroundColor3 = Theme.Surface
                itemFrame.BackgroundTransparency = 0.2
                itemFrame.BorderSizePixel = 0
                itemFrame.ZIndex = 4
                itemFrame.Parent = moduleContainer
                itemFrame:SetAttribute("SearchName", index.title)
                __corner(itemFrame, 6)
                __stroke(itemFrame, Theme.Border)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0, 100, 1, 0)
                lbl.Position = UDim2.new(0, 15, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = index.title
                lbl.TextColor3 = Theme.TextSecondary
                lbl.TextSize = 14
                lbl.Font = Theme.Font
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 5
                lbl.Parent = itemFrame

                local inputContainer = Instance.new("Frame")
                inputContainer.Size = UDim2.new(0, 200, 0, 28)
                inputContainer.Position = UDim2.new(1, -210, 0.5, -14)
                inputContainer.BackgroundColor3 = Theme.Foreground
                inputContainer.BackgroundTransparency = 0.4
                inputContainer.BorderSizePixel = 0
                inputContainer.ZIndex = 4
                inputContainer.Parent = itemFrame
                __corner(inputContainer, 6)
                __stroke(inputContainer, Theme.Border)

                local iconContainer = Instance.new("Frame")
                iconContainer.Size = UDim2.new(0, 28, 1, 0)
                iconContainer.BackgroundColor3 = Theme.Foreground
                iconContainer.BackgroundTransparency = 0.6
                iconContainer.BorderSizePixel = 0
                iconContainer.ZIndex = 4
                iconContainer.Parent = inputContainer
                __corner(iconContainer, 6)

                local inputDivider = Instance.new("Frame")
                inputDivider.Size = UDim2.new(0, 1, 0.6, 0)
                inputDivider.Position = UDim2.new(0, 28, 0.2, 0)
                inputDivider.BackgroundColor3 = Theme.Border
                inputDivider.BorderSizePixel = 0
                inputDivider.ZIndex = 5
                inputDivider.Parent = inputContainer

                local textIcon = Instance.new("ImageLabel")
                textIcon.Size = UDim2.new(0, 16, 0, 16)
                textIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
                textIcon.BackgroundTransparency = 1
                textIcon.Image = "rbxassetid://10723433811"
                textIcon.ImageColor3 = Theme.TextMuted
                textIcon.ZIndex = 5
                textIcon.Parent = iconContainer

                local textbox = Instance.new("TextBox")
                textbox.Size = UDim2.new(1, -35, 1, 0)
                textbox.Position = UDim2.new(0, 32, 0, 0)
                textbox.BackgroundTransparency = 1
                textbox.Text = ""
                textbox.PlaceholderText = index.placeholder or ""
                textbox.TextColor3 = Theme.TextPrimary
                textbox.PlaceholderColor3 = Theme.TextMuted
                textbox.TextSize = 13
                textbox.Font = Theme.Font
                textbox.TextXAlignment = Enum.TextXAlignment.Left
                textbox.ClearTextOnFocus = false
                textbox.ZIndex = 5
                textbox.Parent = inputContainer

                textbox.FocusLost:Connect(function(enterPressed)
                    if enterPressed then itemCallback(textbox.Text) end
                end)

                table.insert(module.__elements, itemFrame)
                if toggled then updateModuleHeight() end

                return { Set = function(_, t: string) textbox.Text = t end }
            end

            function module:create_slider(index: { title: string, minimum: number?, maximum: number?, default: number?, rounding: number?, callback: (value: number) -> () }): { Set: (self: any, value: number) -> () }
                local min = index.minimum or 0
                local max = index.maximum or 100
                local default = index.default or min
                local rounding = index.rounding or 0
                local itemCallback = index.callback or function() end
                local value = default
                local dragging = false

                local itemFrame = Instance.new("Frame")
                itemFrame.Name = "SliderItem"
                itemFrame.Size = UDim2.new(1, 0, 0, 50)
                itemFrame.BackgroundColor3 = Theme.Surface
                itemFrame.BackgroundTransparency = 0.2
                itemFrame.BorderSizePixel = 0
                itemFrame.ZIndex = 4
                itemFrame.Parent = moduleContainer
                itemFrame:SetAttribute("SearchName", index.title)
                __corner(itemFrame, 8)
                __stroke(itemFrame, Theme.Border)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.6, 0, 0, 20)
                lbl.Position = UDim2.new(0, 15, 0, 8)
                lbl.BackgroundTransparency = 1
                lbl.Text = index.title
                lbl.TextColor3 = Theme.TextSecondary
                lbl.TextSize = 14
                lbl.Font = Theme.Font
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 5
                lbl.Parent = itemFrame

                local valLbl = Instance.new("TextLabel")
                valLbl.Size = UDim2.new(0.3, 0, 0, 20)
                valLbl.Position = UDim2.new(0.7, -15, 0, 8)
                valLbl.BackgroundTransparency = 1
                valLbl.Text = tostring(value)
                valLbl.TextColor3 = Theme.TextSecondary
                valLbl.TextSize = 11
                valLbl.Font = Theme.FontMedium
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.ZIndex = 5
                valLbl.Parent = itemFrame

                local trackBg = Instance.new("Frame")
                trackBg.Size = UDim2.new(1, -30, 0, 4)
                trackBg.Position = UDim2.new(0, 15, 1, -18)
                trackBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                trackBg.BorderSizePixel = 0
                trackBg.ZIndex = 4
                trackBg.Parent = itemFrame
                __corner(trackBg, 2)

                local hitbox = Instance.new("Frame")
                hitbox.Size = UDim2.new(1, 0, 0, 20)
                hitbox.Position = UDim2.new(0, 0, 0.5, -10)
                hitbox.BackgroundTransparency = 1
                hitbox.ZIndex = 7
                hitbox.Parent = trackBg

                local track = Instance.new("Frame")
                track.Size = UDim2.new(0, 0, 1, 0)
                track.BackgroundColor3 = Theme.Accent
                track.BorderSizePixel = 0
                track.ZIndex = 5
                track.Parent = trackBg
                __corner(track, 2)

                local ball = Instance.new("Frame")
                ball.Size = UDim2.new(0, 10, 0, 10)
                ball.Position = UDim2.new(1, -5, 0.5, -5)
                ball.BackgroundColor3 = Theme.Accent
                ball.BorderSizePixel = 0
                ball.ZIndex = 6
                ball.Parent = track
                __corner(ball, 5)
                __stroke(ball, Color3.fromRGB(60, 60, 60), 1)

                local function updateSlider(input: InputObject)
                    local pos = math.clamp((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (max - min) * pos)
                    if rounding > 0 then value = math.floor(value / rounding) * rounding end
                    value = math.clamp(value, min, max)
                    valLbl.Text = tostring(value)
                    __tween(track, { Size = UDim2.new(pos, 0, 1, 0) }, 0.1)
                    itemCallback(value)
                end

                local function setValue(newValue: number)
                    value = math.clamp(newValue, min, max)
                    if rounding > 0 then value = math.floor(value / rounding) * rounding end
                    valLbl.Text = tostring(value)
                    track.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    itemCallback(value)
                end

                setValue(default)

                hitbox.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    dragging = true
                    __tween(ball, { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6) }, 0.15)
                    updateSlider(input)
                end)

                hitbox.InputEnded:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    dragging = false
                    __tween(ball, { Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -5, 0.5, -5) }, 0.15)
                end)

                local conn = UserInputService.InputChanged:Connect(function(input)
                    if not dragging or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
                    updateSlider(input)
                end)
                table.insert(self.__library.__connections, conn)

                table.insert(module.__elements, itemFrame)
                if toggled then updateModuleHeight() end

                return { Set = function(_, v: number) setValue(v) end }
            end

            function module:create_button(index: { title: string, callback: () -> () })
                local itemCallback = index.callback or function() end

                local itemFrame = Instance.new("Frame")
                itemFrame.Name = "ButtonItem"
                itemFrame.Size = UDim2.new(1, 0, 0, 35)
                itemFrame.BackgroundColor3 = Theme.Surface
                itemFrame.BackgroundTransparency = 0.2
                itemFrame.BorderSizePixel = 0
                itemFrame.ZIndex = 4
                itemFrame.Parent = moduleContainer
                itemFrame:SetAttribute("SearchName", index.title)
                __corner(itemFrame, 6)
                __stroke(itemFrame, Theme.Border)

                local icon = Instance.new("ImageLabel")
                icon.Size = UDim2.new(0, 18, 0, 18)
                icon.Position = UDim2.new(1, -35, 0.5, -9)
                icon.BackgroundTransparency = 1
                icon.Image = "rbxassetid://10709791437"
                icon.ImageColor3 = Theme.TextPrimary
                icon.ZIndex = 5
                icon.Parent = itemFrame

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -60, 1, 0)
                lbl.Position = UDim2.new(0, 15, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = index.title
                lbl.TextColor3 = Theme.TextSecondary
                lbl.TextSize = 13
                lbl.Font = Theme.Font
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 5
                lbl.Parent = itemFrame

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 1, 0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.ZIndex = 6
                btn.Parent = itemFrame

                btn.MouseButton1Click:Connect(function()
                    __tween(itemFrame, { BackgroundColor3 = Theme.SurfaceHighlight }, 0.1)
                    task.delay(0.12, function()
                        __tween(itemFrame, { BackgroundColor3 = Theme.Surface }, 0.2)
                    end)
                    itemCallback()
                end)

                table.insert(module.__elements, itemFrame)
                if toggled then updateModuleHeight() end
            end

            function module:create_dropdown(index: { title: string, options: { string }, default: string | { string }?, multi_selection: boolean?, callback: (value: string | { string }) -> () }): { Set: (self: any, value: string | { string }) -> () }
                local options = index.options or {}
                local defaultValue = index.default or "--"
                local multi = index.multi_selection or false
                local itemCallback = index.callback or function() end
                local selected: string | { string } = multi and (type(defaultValue) == "table" and defaultValue :: { string } or {}) or (defaultValue ~= "--" and defaultValue :: string or options[1] or "--")
                local opened = false
                local animating = false

                local itemFrame = Instance.new("Frame")
                itemFrame.Name = "DropdownItem"
                itemFrame.Size = UDim2.new(1, 0, 0, 35)
                itemFrame.BackgroundColor3 = Theme.Surface
                itemFrame.BackgroundTransparency = 0.2
                itemFrame.BorderSizePixel = 0
                itemFrame.ClipsDescendants = false
                itemFrame.ZIndex = 4
                itemFrame.Parent = moduleContainer
                itemFrame:SetAttribute("SearchName", index.title)
                __corner(itemFrame, 6)
                __stroke(itemFrame, Theme.Border)

                local itemLabel = Instance.new("TextLabel")
                itemLabel.Size = UDim2.new(0.5, 0, 1, 0)
                itemLabel.Position = UDim2.new(0, 15, 0, 0)
                itemLabel.BackgroundTransparency = 1
                itemLabel.Text = index.title
                itemLabel.TextColor3 = Theme.TextSecondary
                itemLabel.TextSize = 13
                itemLabel.Font = Theme.Font
                itemLabel.TextXAlignment = Enum.TextXAlignment.Left
                itemLabel.ZIndex = 5
                itemLabel.Parent = itemFrame

                local ddContainer = Instance.new("Frame")
                ddContainer.Size = UDim2.new(0, 135, 0, 24)
                ddContainer.Position = UDim2.new(1, -145, 0.5, -12)
                ddContainer.BackgroundColor3 = Theme.Foreground
                ddContainer.BackgroundTransparency = 0
                ddContainer.BorderSizePixel = 0
                ddContainer.ClipsDescendants = true
                ddContainer.ZIndex = 15
                ddContainer.Parent = itemFrame
                __corner(ddContainer, 6)
                __stroke(ddContainer, Theme.Border)

                local function getDisplay(): string
                    if multi then
                        local sel = selected :: { string }
                        if #sel == 0 then return "--" end
                        return table.concat(sel, ", ")
                    else
                        return selected :: string
                    end
                end

                local iconContainer = Instance.new("Frame")
                iconContainer.Size = UDim2.new(0, 24, 0, 24)
                iconContainer.Position = UDim2.new(1, -24, 0, 0)
                iconContainer.BackgroundColor3 = Theme.Foreground
                iconContainer.BackgroundTransparency = 0.6
                iconContainer.BorderSizePixel = 0
                iconContainer.ZIndex = 16
                iconContainer.Parent = ddContainer
                __corner(iconContainer, 6)

                local arrow = Instance.new("ImageLabel")
                arrow.Size = UDim2.new(0, 12, 0, 12)
                arrow.Position = UDim2.new(0.5, -6, 0.5, -6)
                arrow.BackgroundTransparency = 1
                arrow.Image = "rbxassetid://10709790948"
                arrow.ImageColor3 = Theme.TextMuted
                arrow.Rotation = 0
                arrow.ZIndex = 17
                arrow.Parent = iconContainer

                local inputDivider = Instance.new("Frame")
                inputDivider.Size = UDim2.new(0, 1, 0, 14)
                inputDivider.Position = UDim2.new(1, -25, 0, 5)
                inputDivider.BackgroundColor3 = Theme.Border
                inputDivider.BorderSizePixel = 0
                inputDivider.ZIndex = 17
                inputDivider.Parent = ddContainer

                local selLabel = Instance.new("TextLabel")
                selLabel.Size = UDim2.new(1, -30, 0, 24)
                selLabel.Position = UDim2.new(0, 8, 0, 0)
                selLabel.BackgroundTransparency = 1
                selLabel.Text = getDisplay()
                selLabel.TextColor3 = Theme.TextPrimary
                selLabel.TextSize = 11
                selLabel.Font = Theme.Font
                selLabel.TextXAlignment = Enum.TextXAlignment.Left
                selLabel.TextTruncate = Enum.TextTruncate.None
                selLabel.ClipsDescendants = true
                selLabel.ZIndex = 16
                selLabel.Parent = ddContainer

                local fade = Instance.new("UIGradient")
                fade.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
                }
                fade.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.5, 0),
                    NumberSequenceKeypoint.new(0.75, 0.4),
                    NumberSequenceKeypoint.new(0.85, 0.7),
                    NumberSequenceKeypoint.new(0.95, 0.9),
                    NumberSequenceKeypoint.new(1, 1),
                }
                fade.Parent = selLabel

                local searchContainer = Instance.new("Frame")
                searchContainer.Size = UDim2.new(1, -10, 0, 26)
                searchContainer.Position = UDim2.new(0, 5, 0, 26)
                searchContainer.BackgroundColor3 = Theme.SurfaceHighlight
                searchContainer.BorderSizePixel = 0
                searchContainer.Visible = false
                searchContainer.ZIndex = 17
                searchContainer.Parent = ddContainer
                __corner(searchContainer, 5)

                local searchIconContainer = Instance.new("Frame")
                searchIconContainer.Size = UDim2.new(0, 26, 1, 0)
                searchIconContainer.BackgroundColor3 = Theme.Foreground
                searchIconContainer.BackgroundTransparency = 0.5
                searchIconContainer.BorderSizePixel = 0
                searchIconContainer.ZIndex = 17
                searchIconContainer.Parent = searchContainer
                __corner(searchIconContainer, 5)

                local searchDivider = Instance.new("Frame")
                searchDivider.Size = UDim2.new(0, 1, 0.6, 0)
                searchDivider.Position = UDim2.new(0, 26, 0.2, 0)
                searchDivider.BackgroundColor3 = Theme.Border
                searchDivider.BorderSizePixel = 0
                searchDivider.ZIndex = 18
                searchDivider.Parent = searchContainer

                local searchIcon = Instance.new("ImageLabel")
                searchIcon.Size = UDim2.new(0, 12, 0, 12)
                searchIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
                searchIcon.BackgroundTransparency = 1
                searchIcon.Image = "rbxassetid://10734943674"
                searchIcon.ImageColor3 = Theme.TextMuted
                searchIcon.ZIndex = 18
                searchIcon.Parent = searchIconContainer

                local searchBox = Instance.new("TextBox")
                searchBox.Size = UDim2.new(1, -30, 1, 0)
                searchBox.Position = UDim2.new(0, 29, 0, 0)
                searchBox.BackgroundTransparency = 1
                searchBox.Text = ""
                searchBox.PlaceholderText = "Search..."
                searchBox.TextColor3 = Theme.TextPrimary
                searchBox.PlaceholderColor3 = Theme.TextMuted
                searchBox.TextSize = 10
                searchBox.Font = Theme.Font
                searchBox.TextXAlignment = Enum.TextXAlignment.Left
                searchBox.ClearTextOnFocus = false
                searchBox.ZIndex = 18
                searchBox.Parent = searchContainer

                local optionsContainer = Instance.new("ScrollingFrame")
                optionsContainer.Size = UDim2.new(1, 0, 0, 0)
                optionsContainer.Position = UDim2.new(0, 0, 0, 54)
                optionsContainer.BackgroundTransparency = 1
                optionsContainer.BorderSizePixel = 0
                optionsContainer.ScrollBarThickness = 2
                optionsContainer.ScrollBarImageColor3 = Theme.TextMuted
                optionsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
                optionsContainer.ZIndex = 17
                optionsContainer.Parent = ddContainer

                local optionsPadding = Instance.new("UIPadding")
                optionsPadding.PaddingLeft = UDim.new(0, 5)
                optionsPadding.PaddingRight = UDim.new(0, 5)
                optionsPadding.Parent = optionsContainer

                local optionsLayout = Instance.new("UIListLayout")
                optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                optionsLayout.Padding = UDim.new(0, 2)
                optionsLayout.Parent = optionsContainer

                optionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    optionsContainer.CanvasSize = UDim2.new(0, 0, 0, optionsLayout.AbsoluteContentSize.Y)
                end)

                local function closeDropdown(instant: boolean)
                    if not opened then return end
                    opened = false
                    animating = false
                    searchContainer.Visible = false
                    optionsContainer.Size = UDim2.new(1, 0, 0, 0)
                    searchBox.Text = ""

                    if instant then
                        ddContainer.Size = UDim2.new(0, 135, 0, 24)
                        arrow.Rotation = 0
                        itemFrame.ZIndex = 4
                        ddContainer.ZIndex = 15
                        ddContainer.ClipsDescendants = true
                        itemLabel.ZIndex = 5
                        selLabel.ZIndex = 16
                        iconContainer.ZIndex = 16
                        arrow.ZIndex = 17
                        inputDivider.ZIndex = 17
                        ddContainer.Parent = itemFrame
                        ddContainer.Position = UDim2.new(1, -145, 0.5, -12)
                    else
                        animating = true
                        __tween(ddContainer, { Size = UDim2.new(0, 135, 0, 24) }, 0.3)
                        __tween(arrow, { Rotation = 0 }, 0.3)
                        task.wait(0.3)
                        itemFrame.ZIndex = 4
                        ddContainer.ZIndex = 15
                        ddContainer.ClipsDescendants = true
                        itemLabel.ZIndex = 5
                        selLabel.ZIndex = 16
                        iconContainer.ZIndex = 16
                        arrow.ZIndex = 17
                        inputDivider.ZIndex = 17
                        ddContainer.Parent = itemFrame
                        ddContainer.Position = UDim2.new(1, -145, 0.5, -12)
                        animating = false
                    end
                end

                container:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not container.Visible and opened then closeDropdown(true) end
                end)
                container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                    if opened then closeDropdown(true) end
                end)
                moduleContainer:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not moduleContainer.Visible and opened then closeDropdown(true) end
                end)

                local function createOption(option: string)
                    local isSelected = false
                    if multi then
                        isSelected = table.find(selected :: { string }, option) ~= nil
                    else
                        isSelected = selected == option
                    end

                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, 35)
                    btn.BackgroundColor3 = isSelected and Theme.SurfaceHighlight or Theme.Surface
                    btn.BackgroundTransparency = 0.2
                    btn.BorderSizePixel = 0
                    btn.Text = ""
                    btn.AutoButtonColor = false
                    btn.ZIndex = 18
                    btn.Parent = optionsContainer
                    __corner(btn, 5)

                    local highlight = Instance.new("Frame")
                    highlight.Size = UDim2.new(0, 2, 0.6, 0)
                    highlight.Position = UDim2.new(0, 1, 0.2, 0)
                    highlight.BackgroundColor3 = Theme.Accent
                    highlight.BackgroundTransparency = isSelected and 0.1 or 1
                    highlight.BorderSizePixel = 0
                    highlight.ZIndex = 19
                    highlight.Parent = btn
                    __corner(highlight, 1)

                    local optLabel = Instance.new("TextLabel")
                    optLabel.Size = UDim2.new(1, -10, 1, 0)
                    optLabel.Position = UDim2.new(0, 8, 0, 0)
                    optLabel.BackgroundTransparency = 1
                    optLabel.Text = option
                    optLabel.TextColor3 = isSelected and Theme.TextPrimary or Theme.TextMuted
                    optLabel.TextSize = 13
                    optLabel.Font = Theme.FontMedium
                    optLabel.TextXAlignment = Enum.TextXAlignment.Left
                    optLabel.ZIndex = 19
                    optLabel.Parent = btn

                    local effect = Instance.new("Frame")
                    effect.Size = UDim2.new(1, 0, 1, 0)
                    effect.BackgroundColor3 = Theme.Accent
                    effect.BackgroundTransparency = 1
                    effect.BorderSizePixel = 0
                    effect.ZIndex = 17
                    effect.Parent = btn
                    __corner(effect, 5)

                    btn.MouseButton1Click:Connect(function()
                        effect.BackgroundTransparency = 1
                        __tween(effect, { BackgroundTransparency = 0.92 }, 0.3)
                        task.delay(0.3, function() __tween(effect, { BackgroundTransparency = 1 }, 0.3) end)

                        if multi then
                            local sel = selected :: { string }
                            local idx = table.find(sel, option)
                            if idx then
                                table.remove(sel, idx)
                                isSelected = false
                                __tween(btn, { BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.2 }, 0.2)
                                __tween(optLabel, { TextColor3 = Theme.TextMuted }, 0.2)
                                __tween(highlight, { BackgroundTransparency = 1 }, 0.3)
                            else
                                table.insert(sel, option)
                                isSelected = true
                                __tween(btn, { BackgroundColor3 = Theme.SurfaceHighlight, BackgroundTransparency = 0.2 }, 0.2)
                                __tween(optLabel, { TextColor3 = Theme.TextPrimary }, 0.2)
                                __tween(highlight, { BackgroundTransparency = 0.1 }, 0.3)
                            end
                            selLabel.Text = getDisplay()
                            itemCallback(sel)
                        else
                            for _, child in pairs(optionsContainer:GetChildren()) do
                                if not child:IsA("TextButton") then continue end
                                local hl = child:FindFirstChildOfClass("Frame")
                                local lbl = child:FindFirstChildOfClass("TextLabel")
                                if child ~= btn then
                                    __tween(child, { BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.2 }, 0.2)
                                    if lbl then __tween(lbl, { TextColor3 = Theme.TextMuted }, 0.2) end
                                    if hl then __tween(hl, { BackgroundTransparency = 1 }, 0.3) end
                                end
                            end
                            selected = option
                            isSelected = true
                            selLabel.Text = option
                            __tween(btn, { BackgroundColor3 = Theme.SurfaceHighlight, BackgroundTransparency = 0.2 }, 0.2)
                            __tween(optLabel, { TextColor3 = Theme.TextPrimary }, 0.2)
                            __tween(highlight, { BackgroundTransparency = 0.1 }, 0.3)
                            itemCallback(option)
                        end
                    end)

                    return btn
                end

                for _, opt in ipairs(options) do createOption(opt) end

                searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local q = searchBox.Text:lower()
                    for _, child in pairs(optionsContainer:GetChildren()) do
                        if not child:IsA("TextButton") then continue end
                        local lbl = child:FindFirstChildOfClass("TextLabel")
                        if lbl then
                            child.Visible = q == "" or lbl.Text:lower():find(q) ~= nil
                        end
                    end
                end)

                local ddBtn = Instance.new("TextButton")
                ddBtn.Size = UDim2.new(1, 0, 1, 0)
                ddBtn.BackgroundTransparency = 1
                ddBtn.Text = ""
                ddBtn.ZIndex = 16
                ddBtn.Parent = ddContainer

                ddBtn.MouseButton1Click:Connect(function()
                    if animating then return end
                    if opened then
                        closeDropdown(false)
                        return
                    end
                    animating = true
                    opened = true

                    local absPos = ddContainer.AbsolutePosition
                    local mainAbs = main.AbsolutePosition

                    ddContainer.Parent = overlay
                    ddContainer.Position = UDim2.new(0, absPos.X - mainAbs.X, 0, absPos.Y - mainAbs.Y)
                    ddContainer.Size = UDim2.new(0, 135, 0, 24)

                    itemFrame.ZIndex = 20
                    ddContainer.ZIndex = 21
                    ddContainer.ClipsDescendants = false
                    itemLabel.ZIndex = 22
                    selLabel.ZIndex = 23
                    iconContainer.ZIndex = 23
                    arrow.ZIndex = 24
                    inputDivider.ZIndex = 24

                    local actualHeight = math.min(optionsLayout.AbsoluteContentSize.Y, math.min(#options * 37, 148))
                    searchContainer.Visible = true
                    optionsContainer.Size = UDim2.new(1, 0, 0, actualHeight)

                    for i, child in pairs(optionsContainer:GetChildren()) do
                        if not child:IsA("TextButton") then continue end
                        child.BackgroundTransparency = 1
                        local lbl = child:FindFirstChildOfClass("TextLabel")
                        if lbl then lbl.TextTransparency = 1 end
                        task.delay(0.1 + (i * 0.001), function()
                            __tween(child, { BackgroundTransparency = 0.2 }, 0.2)
                            if lbl then __tween(lbl, { TextTransparency = 0 }, 0.2) end
                        end)
                    end

                    __tween(ddContainer, { Size = UDim2.new(0, 135, 0, 54 + actualHeight + 6) }, 0.3)
                    __tween(arrow, { Rotation = 180 }, 0.3)
                    task.wait(0.3)
                    animating = false
                end)

                table.insert(module.__elements, itemFrame)
                if toggled then updateModuleHeight() end

                task.spawn(function()
                    while itemFrame and itemFrame.Parent do
                        task.wait(0.2)
                        if self.__library.__minimized and opened then
                            closeDropdown(true)
                        end
                    end
                end)

                return {
                    Set = function(_, val: string | { string })
                        if multi then
                            selected = (type(val) == "table" and val :: { string }) or {}
                        else
                            selected = val :: string
                        end
                        selLabel.Text = getDisplay()
                        itemCallback(selected)
                    end
                }
            end

            table.insert(self.__library.__all_elements, { name = index.title, frame = frame })
            return module
        end

        return tab
    end

    return self
end

function Library:destroy()
    if self.__window.euphoria then
        self.__window.euphoria:Destroy()
    end
    __disconnect_all(self.__connections)
    table.clear(self.__tabs)
    table.clear(self.__all_elements)
end

return Library
