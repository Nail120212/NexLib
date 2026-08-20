local Library = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

groqapi = ""
groqprompt = ""

Library.GroqEndpoint = "https://api.groq.com/openai/v1/chat/completions"
Library.GroqModel = "openai/gpt-oss-120b"

local function Get(url)
    if game.HttpGet then
        return game:HttpGet(url)
    end
    return HttpService:GetAsync(url)
end

local UIIcons
do
    local ok, result = pcall(function()
        return loadstring(Get("https://raw.githubusercontent.com/DSP-V1/NextGen/refs/heads/main/UILib/icons/UIIcons.lua"))()
    end)
    if ok and type(result) == "table" then
        UIIcons = result
        if UIIcons.SetIconsType then
            pcall(UIIcons.SetIconsType, "lucide")
        end
    end
end

Library.DefaultIcons = {
    Minimize = "minus",
    Maximize = "maximize-2",
    Close = "x",
    Search = "search",
    ChevronRight = "chevron-right",
    ChevronDown = "chevron-down",
    Edit = "pencil",
    Tab = "square",
    Lock = "lock",
    Tag = "tag",
    Check = "check",
    Scan = "scan",
    Copy = "copy",
    Play = "play",
    Key = "keyboard",
    Palette = "palette",
    Reorder = "list-ordered",
    Grip = "grip-vertical",
    Bot = "bot",
    Send = "send",
    Sparkles = "sparkles",
    Trash = "trash-2",
    User = "user",
    Clock = "clock",
    Finger = "fingerprint",
    Gauge = "gauge",
    Signal = "signal",
    Cake = "cake",
    Bolt = "zap",
    Pad = "gamepad-2",
    Shield = "shield",
    Cpu = "cpu",
    Refresh = "refresh-cw"
}

Library.Themes = {
    Dark = {
        Main = Color3.fromRGB(11, 11, 14),
        Accent = Color3.fromRGB(179, 0, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDisabled = Color3.fromRGB(138, 138, 150),
        Background = Color3.fromRGB(22, 22, 27),
        Stroke = Color3.fromRGB(120, 120, 138),
        Secondary = Color3.fromRGB(28, 28, 34),
        Elevated = Color3.fromRGB(16, 16, 20),
        Surface = Color3.fromRGB(255, 255, 255),
        SurfaceAlpha = 0.95,
        SurfaceHover = 0.9
    },
    Light = {
        Main = Color3.fromRGB(243, 243, 248),
        Accent = Color3.fromRGB(179, 0, 255),
        Text = Color3.fromRGB(18, 18, 24),
        TextDisabled = Color3.fromRGB(108, 108, 122),
        Background = Color3.fromRGB(226, 226, 236),
        Stroke = Color3.fromRGB(158, 158, 176),
        Secondary = Color3.fromRGB(252, 252, 255),
        Elevated = Color3.fromRGB(255, 255, 255),
        Surface = Color3.fromRGB(0, 0, 0),
        SurfaceAlpha = 0.93,
        SurfaceHover = 0.87
    },
    Black = {
        Main = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(179, 0, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDisabled = Color3.fromRGB(150, 150, 150),
        Background = Color3.fromRGB(8, 8, 8),
        Stroke = Color3.fromRGB(90, 90, 90),
        Secondary = Color3.fromRGB(14, 14, 14),
        Elevated = Color3.fromRGB(4, 4, 4),
        Surface = Color3.fromRGB(255, 255, 255),
        SurfaceAlpha = 0.965,
        SurfaceHover = 0.92
    }
}

Library.ThemeOrder = { "Dark", "Black", "Light" }

function Library:AddTheme(Name, Colors)
    if type(Name) ~= "string" or type(Colors) ~= "table" then
        return
    end
    local Merged = {}
    for Key, Value in pairs(Library.Themes.Dark) do
        Merged[Key] = Value
    end
    for Key, Value in pairs(Colors) do
        Merged[Key] = Value
    end
    Library.Themes[Name] = Merged
    if not table.find(Library.ThemeOrder, Name) then
        table.insert(Library.ThemeOrder, Name)
    end
    return Merged
end

function Library:ApplyTheme(Name)
    if not Library.Themes[Name] then
        return false
    end
    Library.CurrentTheme = Name
    Library.Theme = Library.Themes[Name]
    Library:RefreshTheme(true)
    return true
end

Library.Theme = Library.Themes.Dark
Library.CurrentTheme = "Dark"
Library.ThemeObjects = {}

local Quart = Enum.EasingStyle.Quart
local Back = Enum.EasingStyle.Back
local Out = Enum.EasingDirection.Out
local In = Enum.EasingDirection.In

function Library:NormalizeIconName(IconName)
    if type(IconName) ~= "string" or IconName == "" then
        return Library.DefaultIcons.Tab
    end
    if IconName:find(":") then
        return IconName
    end
    return "lucide:" .. IconName
end

Library.IconAliases = {
    ["circle-check"] = "check-circle",
    ["circle-x"] = "x-circle",
    ["circle-alert"] = "alert-circle",
    ["triangle-alert"] = "alert-triangle",
    ["contact"] = "user",
    ["gauge"] = "activity",
    ["signal"] = "wifi",
    ["cake"] = "calendar",
    ["cpu"] = "terminal",
    ["hash"] = "tag",
    ["gamepad-2"] = "gamepad",
    ["list-ordered"] = "list",
    ["trash-2"] = "trash",
    ["refresh-cw"] = "refresh-ccw",
    ["maximize-2"] = "maximize",
    ["grip-vertical"] = "menu"
}

function Library:SetIcon(Object, IconName, IconColor, IconType)
    if IconColor then
        Object.ImageColor3 = IconColor
    end
    if not UIIcons or not UIIcons.Icon2 then
        return
    end

    local Requested = IconName or Library.DefaultIcons.Tab
    local Candidates = { Requested }
    local Alias = Library.IconAliases[Requested]
    if Alias then
        table.insert(Candidates, Alias)
    end
    table.insert(Candidates, Library.DefaultIcons.Tab)

    for _, Candidate in ipairs(Candidates) do
        local Normalized = self:NormalizeIconName(Candidate)
        local Ok, IconData = pcall(UIIcons.Icon2, Normalized, IconType or "lucide")
        if Ok and type(IconData) == "table" and IconData[2] then
            Object.Image = IconData[1]
            Object.ImageRectOffset = IconData[2].ImageRectPosition
            Object.ImageRectSize = IconData[2].ImageRectSize
            return
        end
    end
end

function Library:Tween(Instance, Info, Properties, Callback)
    local Tween = TweenService:Create(Instance, Info or TweenInfo.new(0.35, Quart, Out), Properties)
    if Callback then
        Tween.Completed:Connect(Callback)
    end
    Tween:Play()
    return Tween
end

function Library:TweenInstance(Instance, Time, Property, TargetValue, Callback)
    return self:Tween(Instance, TweenInfo.new(Time or 0.3, Quart, Out), { [Property] = TargetValue }, Callback)
end

function Library:MakeConfig(DefaultConfig, UserConfig)
    UserConfig = UserConfig or {}
    local Config = {}
    for Key, Value in pairs(DefaultConfig) do
        Config[Key] = UserConfig[Key] ~= nil and UserConfig[Key] or Value
    end
    for Key, Value in pairs(UserConfig) do
        if Config[Key] == nil then
            Config[Key] = Value
        end
    end
    return Config
end

function Library:Themed(Object, Property, Key)
    table.insert(Library.ThemeObjects, { Object = Object, Property = Property, Key = Key })
    Object[Property] = Library.Theme[Key]
    return Object
end

function Library:RefreshTheme(Animated)
    for Index = #Library.ThemeObjects, 1, -1 do
        local Entry = Library.ThemeObjects[Index]
        if not Entry.Object or not Entry.Object.Parent then
            table.remove(Library.ThemeObjects, Index)
        else
            local Value = Library.Theme[Entry.Key]
            if Value ~= nil then
                if Animated and (typeof(Value) == "Color3" or typeof(Value) == "number") then
                    Library:TweenInstance(Entry.Object, 0.25, Entry.Property, Value)
                else
                    Entry.Object[Entry.Property] = Value
                end
            end
        end
    end
end

Library.Rounded = true

function Library:Corner(Object, Radius)
    local Corner = Instance.new("UICorner")
    if typeof(Radius) == "UDim" then
        Corner.CornerRadius = Radius
    else
        local r = Radius or 8
        Corner.CornerRadius = UDim.new(0, r)
    end
    Corner.Parent = Object
    return Corner
end

function Library:Stroke(Object, Color, Transparency, Thickness)
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color or Library.Theme.Stroke
    Stroke.Transparency = Transparency or 0.75
    Stroke.Thickness = Thickness or 1
    Stroke.Parent = Object
    return Stroke
end

function Library:Padding(Object, Top, Bottom, Left, Right)
    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, Top or 0)
    Pad.PaddingBottom = UDim.new(0, Bottom or 0)
    Pad.PaddingLeft = UDim.new(0, Left or 0)
    Pad.PaddingRight = UDim.new(0, Right or 0)
    Pad.Parent = Object
    return Pad
end

function Library:Gradient(Object, Colors, Rotation, Transparencies)
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = Colors
    Gradient.Rotation = Rotation or 0
    if Transparencies then
        Gradient.Transparency = Transparencies
    end
    Gradient.Parent = Object
    return Gradient
end

function Library:FadeLine(Object, Color, Horizontal)
    return self:Gradient(Object, ColorSequence.new(Color or Library.Theme.Accent), Horizontal and 0 or 90, NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.15),
        NumberSequenceKeypoint.new(1, 1)
    }))
end

function Library:Flash(Object, Color)
    local Overlay = Instance.new("Frame")
    Overlay.Name = "Flash"
    Overlay.Parent = Object
    Overlay.BackgroundColor3 = Color or Library.Theme.Accent
    Overlay.BackgroundTransparency = 0.72
    Overlay.BorderSizePixel = 0
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.ZIndex = Object.ZIndex + 1

    local Source = Object:FindFirstChildOfClass("UICorner")
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = Source and Source.CornerRadius or UDim.new(0, 6)
    Corner.Parent = Overlay

    Library:Tween(Overlay, TweenInfo.new(0.4, Quart, Out), { BackgroundTransparency = 1 }, function()
        Overlay:Destroy()
    end)
end

function Library:Hover(Trigger, Target, Property, Idle, Active, Time)
    Trigger.MouseEnter:Connect(function()
        Library:TweenInstance(Target, Time or 0.18, Property, Active)
    end)
    Trigger.MouseLeave:Connect(function()
        Library:TweenInstance(Target, Time or 0.18, Property, Idle)
    end)
end

function Library:Pop(Object, Time, From)
    local Scale = Object:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    Scale.Parent = Object
    Scale.Scale = From or 0.9
    Library:Tween(Scale, TweenInfo.new(Time or 0.36, Back, Out), { Scale = 1 })
    return Scale
end

function Library:UpdateContent(Content, Title, Object)
    if Content.Text and Content.Text ~= "" then
        Title.Position = UDim2.new(0, 12, 0, 6)
        Title.Size = UDim2.new(Title.Size.X.Scale, Title.Size.X.Offset, 0, 17)
        Object.Size = UDim2.new(1, 0, 0, math.max(Content.TextBounds.Y + 31, 48))
    end
end

function Library:UpdateScrolling(Scroll, List)
    local function UpdateCanvasSize()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 16)
    end
    List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)
    coroutine.wrap(UpdateCanvasSize)()
end

function Library:StyleScroll(Scroll)
    Scroll.ScrollBarThickness = 4
    Scroll.ScrollBarImageTransparency = 0.35
    Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    Scroll.BorderSizePixel = 0
    Scroll.ElasticBehavior = Enum.ElasticBehavior.Always
    Scroll.ScrollingEnabled = true
    Library:Themed(Scroll, "ScrollBarImageColor3", "Accent")
end

function Library:MakeDraggable(DragBar, Object, OnMoved)
    DragBar.Active = true

    local Dragging = false
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil
    local LastTouchPos = nil

    DragBar.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = Input.Position
            LastTouchPos = Input.Position
            StartPosition = Object.Position
            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    DragBar.InputChanged:Connect(function(Input)
        if not Dragging then return end
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if not Dragging or Input ~= DragInput then
            return
        end
        local Delta = Input.Position - DragStart
        Object.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
        if OnMoved then
            OnMoved(Object.Position)
        end
    end)
end

local function GetRequestFunction()
    if syn and syn.request then
        return syn.request
    end
    if fluxus and fluxus.request then
        return fluxus.request
    end
    if http and http.request then
        return http.request
    end
    if http_request then
        return http_request
    end
    if request then
        return request
    end
    return nil
end

local function GetGlobal(Name)
    local Ok, Value = pcall(function()
        return rawget(getfenv(), Name)
    end)
    if Ok and type(Value) == "string" and Value ~= "" then
        return Value
    end
    if getgenv then
        local ok, Env = pcall(getgenv)
        if ok and type(Env) == "table" and type(Env[Name]) == "string" and Env[Name] ~= "" then
            return Env[Name]
        end
    end
    return ""
end

local function GetExecutorName()
    if identifyexecutor then
        local ok, Name = pcall(identifyexecutor)
        if ok and type(Name) == "string" and Name ~= "" then
            return Name
        end
    end
    if getexecutorname then
        local ok, Name = pcall(getexecutorname)
        if ok and type(Name) == "string" and Name ~= "" then
            return Name
        end
    end
    return "Unknown"
end

local function GetHardwareId()
    if gethwid then
        local ok, Id = pcall(gethwid)
        if ok and type(Id) == "string" and Id ~= "" then
            return Id
        end
    end
    local ok, Id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and type(Id) == "string" and Id ~= "" then
        return Id
    end
    local Seed = tostring(Player.UserId) .. "-" .. tostring(Player.Name)
    local Hash = 5381
    for Index = 1, #Seed do
        Hash = (Hash * 33 + string.byte(Seed, Index)) % 4294967296
    end
    return string.upper(string.format("%08X%08X", Hash, (Hash * 2654435761) % 4294967296))
end

local function ShortHardwareId(Id)
    local Clean = string.upper((Id:gsub("[^%w]", "")))
    if #Clean <= 16 then
        return Clean
    end
    return string.sub(Clean, 1, 4) .. "-" .. string.sub(Clean, 5, 8) .. "-" .. string.sub(Clean, 9, 12) .. "-" .. string.sub(Clean, #Clean - 3)
end

local function FormatClock(Seconds)
    Seconds = math.max(0, math.floor(Seconds))
    local Hours = math.floor(Seconds / 3600)
    local Minutes = math.floor((Seconds % 3600) / 60)
    local Rest = Seconds % 60
    if Hours > 0 then
        return string.format("%02d:%02d:%02d", Hours, Minutes, Rest)
    end
    return string.format("%02d:%02d", Minutes, Rest)
end

local function Trim(Text)
    return (tostring(Text):match("^%s*(.-)%s*$"))
end

function Library:SetGroq(Key, Prompt, Model)
    if type(Key) == "string" and Key ~= "" then
        groqapi = Key
    end
    if type(Prompt) == "string" then
        groqprompt = Prompt
    end
    if type(Model) == "string" and Model ~= "" then
        Library.GroqModel = Model
    end
end

function Library:NewWindow(ConfigWindow)
    local ConfigWindow = self:MakeConfig({
        Title = "sh1ttybanana",
        Description = "sh1ttybanana ui",
        Icon = "rbxassetid://89646749075297",
        Logo = "rbxassetid://89646749075297",
        Color = Color3.fromRGB(179, 0, 255),
        Size = UDim2.new(0, 620, 0, 420),
        Transparent = 0.07,
        AutoScale = true,
        GroqApiKey = nil,
        GroqPrompt = nil,
        GroqModel = nil
    }, ConfigWindow or {})

    Library.Themes.Dark.Accent = ConfigWindow.Color
    Library.Themes.Light.Accent = ConfigWindow.Color
    Library.Themes.Black.Accent = ConfigWindow.Color
    Library.Theme.Accent = ConfigWindow.Color

    if type(ConfigWindow.GroqApiKey) == "string" and ConfigWindow.GroqApiKey ~= "" then
        groqapi = ConfigWindow.GroqApiKey
    end
    if type(ConfigWindow.GroqPrompt) == "string" then
        groqprompt = ConfigWindow.GroqPrompt
    end
    if type(ConfigWindow.GroqModel) == "string" and ConfigWindow.GroqModel ~= "" then
        Library.GroqModel = ConfigWindow.GroqModel
    end

    local WindowTags = {}
    local ConfigFlags = {}
    local ReorderMode = false
    local TabElements = {}
    local TabRegistry = {}
    local SectionRegistry = {}
    local UIIndex = {}
    local SessionStart = os.time()
    local ToggleWindow
    local ToggleAI
    local TogglePlayerCard

    local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    local WindowAPI
    -- Manual sizing only: ConfigWindow.Size is used exactly as given, with
    -- no automatic clamping to screen size and no runtime UIScale change.

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "sh1ttybanana"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")

    local TeddyUI_Premium = ScreenGui

    local DropShadowHolder = Instance.new("Frame")
    DropShadowHolder.Name = "DropShadowHolder"
    DropShadowHolder.Parent = ScreenGui
    DropShadowHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadowHolder.BackgroundTransparency = 1
    DropShadowHolder.BorderSizePixel = 0
    DropShadowHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropShadowHolder.Size = ConfigWindow.Size
    DropShadowHolder.ZIndex = 2

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = DropShadowHolder
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundTransparency = typeof(ConfigWindow.Transparent) == "number" and ConfigWindow.Transparent or 0.07
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(1, 0, 1, 0)
    Library:Themed(Main, "BackgroundColor3", "Main")
    Library:Corner(Main, 14)
    Main.ClipsDescendants = true

    local ContentScale = Instance.new("UIScale")
    ContentScale.Parent = Main
    ContentScale.Scale = 1

    local MainStroke = Library:Stroke(Main, Library.Theme.Accent, 0.55, 1.4)
    Library:Themed(MainStroke, "Color", "Accent")

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Rotation = 90
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(214, 214, 224))
    })
    MainGradient.Parent = Main

    local Top = Instance.new("Frame")
    Top.Name = "Top"
    Top.Parent = Main
    Top.BackgroundTransparency = 1
    Top.BorderSizePixel = 0
    Top.Size = UDim2.new(1, 0, 0, 54)
    Top.Active = true
    Top.ZIndex = 5
    Top.ClipsDescendants = false

    local Line = Instance.new("Frame")
    Line.Name = "Line"
    Line.Parent = Top
    Line.BorderSizePixel = 0
    Line.Position = UDim2.new(0, 0, 1, -1)
    Line.Size = UDim2.new(1, 0, 0, 1)
    Library:Themed(Line, "BackgroundColor3", "Accent")
    Library:FadeLine(Line, Library.Theme.Accent, true)

    local Left = Instance.new("Folder")
    Left.Name = "Left"
    Left.Parent = Top

    local LogoHolder = Instance.new("Frame")
    LogoHolder.Name = "LogoHolder"
    LogoHolder.Parent = Top
    LogoHolder.BackgroundTransparency = 0.86
    LogoHolder.BorderSizePixel = 0
    LogoHolder.Position = UDim2.new(0, 10, 0, 9)
    LogoHolder.Size = UDim2.new(0, 36, 0, 36)
    LogoHolder.ZIndex = 6
    LogoHolder.ClipsDescendants = true
    Library:Themed(LogoHolder, "BackgroundColor3", "Accent")
    Library:Corner(LogoHolder, 9)
    local LogoStroke = Library:Stroke(LogoHolder, Library.Theme.Accent, 0.62, 1)
    Library:Themed(LogoStroke, "Color", "Accent")

    local LogoHub = Instance.new("ImageLabel")
    LogoHub.Name = "LogoHub"
    LogoHub.Parent = LogoHolder
    LogoHub.AnchorPoint = Vector2.new(0.5, 0.5)
    LogoHub.BackgroundTransparency = 1
    LogoHub.BorderSizePixel = 0
    LogoHub.Position = UDim2.new(0.5, 0, 0.5, 0)
    LogoHub.Size = UDim2.new(1, 0, 1, 0)
    LogoHub.Image = ConfigWindow.Logo
    LogoHub.ScaleType = Enum.ScaleType.Crop

    -- Title + description + tags scroll horizontally as one centered
    -- unit if they ever overflow the space between the logo and the
    -- control icons; the control icons themselves are a sibling of this
    -- scroll frame, so they never move or get clipped by it.
    local HeaderScroll = Instance.new("ScrollingFrame")
    HeaderScroll.Name = "HeaderScroll"
    HeaderScroll.Parent = Top
    HeaderScroll.BackgroundTransparency = 1
    HeaderScroll.BorderSizePixel = 0
    HeaderScroll.Position = UDim2.new(0, 54, 0, 2)
    HeaderScroll.Size = UDim2.new(1, -212, 0, 48)
    HeaderScroll.ScrollingDirection = Enum.ScrollingDirection.X
    HeaderScroll.ScrollBarThickness = 2
    HeaderScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    HeaderScroll.ZIndex = 6
    Library:Themed(HeaderScroll, "ScrollBarImageColor3", "Accent")

    local HeaderContent = Instance.new("Frame")
    HeaderContent.Name = "HeaderContent"
    HeaderContent.Parent = HeaderScroll
    HeaderContent.BackgroundTransparency = 1
    HeaderContent.Position = UDim2.new(0, 0, 0, 0)
    HeaderContent.Size = UDim2.new(0, 0, 1, 0)
    HeaderContent.AutomaticSize = Enum.AutomaticSize.X

    local HeaderContentList = Instance.new("UIListLayout")
    HeaderContentList.Parent = HeaderContent
    HeaderContentList.SortOrder = Enum.SortOrder.LayoutOrder
    HeaderContentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    HeaderContentList.Padding = UDim.new(0, 4)

    local function RecalcHeaderScroll()
        local ContentW = HeaderContentList.AbsoluteContentSize.X
        local ViewportW = HeaderScroll.AbsoluteSize.X
        if ContentW <= ViewportW then
            HeaderContent.Position = UDim2.new(0, math.floor((ViewportW - ContentW) / 2), 0, 0)
            HeaderScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        else
            HeaderContent.Position = UDim2.new(0, 0, 0, 0)
            HeaderScroll.CanvasSize = UDim2.new(0, ContentW, 0, 0)
        end
    end
    HeaderContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RecalcHeaderScroll)
    HeaderScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(RecalcHeaderScroll)
    task.defer(RecalcHeaderScroll)

    local NameHub = Instance.new("TextLabel")
    NameHub.Name = "NameHub"
    NameHub.Parent = HeaderContent
    NameHub.LayoutOrder = 1
    NameHub.BackgroundTransparency = 1
    NameHub.BorderSizePixel = 0
    NameHub.AutomaticSize = Enum.AutomaticSize.X
    NameHub.Size = UDim2.new(0, 0, 0, 18)
    NameHub.Font = Enum.Font.GothamBold
    NameHub.Text = ConfigWindow.Title
    NameHub.TextSize = 14
    NameHub.TextXAlignment = Enum.TextXAlignment.Center
    Library:Themed(NameHub, "TextColor3", "Text")

    -- Description + Tags share one auto-flowing row so tags always sit
    -- immediately after the description text (whatever its length) and
    -- never drift into a fixed pixel gap or crowd the control icons.
    local DescRow = Instance.new("Frame")
    DescRow.Name = "DescRow"
    DescRow.Parent = HeaderContent
    DescRow.LayoutOrder = 2
    DescRow.BackgroundTransparency = 1
    DescRow.Position = UDim2.new(0, 0, 0, 0)
    DescRow.Size = UDim2.new(0, 0, 0, 20)
    DescRow.AutomaticSize = Enum.AutomaticSize.X

    local DescRowList = Instance.new("UIListLayout")
    DescRowList.Parent = DescRow
    DescRowList.FillDirection = Enum.FillDirection.Horizontal
    DescRowList.VerticalAlignment = Enum.VerticalAlignment.Center
    DescRowList.SortOrder = Enum.SortOrder.LayoutOrder
    DescRowList.Padding = UDim.new(0, 8)

    local Desc = Instance.new("TextLabel")
    Desc.Name = "Desc"
    Desc.Parent = DescRow
    Desc.LayoutOrder = 1
    Desc.BackgroundTransparency = 1
    Desc.BorderSizePixel = 0
    Desc.AutomaticSize = Enum.AutomaticSize.X
    Desc.Size = UDim2.new(0, 0, 1, 0)
    Desc.Font = Enum.Font.Gotham
    Desc.Text = ConfigWindow.Description
    Desc.TextSize = 11
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Library:Themed(Desc, "TextColor3", "TextDisabled")

    local Right = Instance.new("Folder")
    Right.Name = "Right"
    Right.Parent = Top

    local ControlBar = Instance.new("Frame")
    ControlBar.Name = "ControlBar"
    ControlBar.Parent = Top
    ControlBar.AnchorPoint = Vector2.new(1, 0.5)
    ControlBar.BackgroundTransparency = 1
    ControlBar.BorderSizePixel = 0
    ControlBar.Position = UDim2.new(1, -10, 0.5, 0)
    ControlBar.Size = UDim2.new(0, 0, 0, 32)
    ControlBar.AutomaticSize = Enum.AutomaticSize.X

    local ControlList = Instance.new("UIListLayout")
    ControlList.Parent = ControlBar
    ControlList.FillDirection = Enum.FillDirection.Horizontal
    ControlList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlList.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlList.SortOrder = Enum.SortOrder.LayoutOrder
    ControlList.Padding = UDim.new(0, 6)

    local function MakeControl(Name, IconName, Order)
        local Button = Instance.new("TextButton")
        Button.Name = Name
        Button.Parent = ControlBar
        Button.BackgroundTransparency = 0.94
        Button.BorderSizePixel = 0
        Button.Size = UDim2.new(0, 30, 0, 30)
        Button.Text = ""
        Button.AutoButtonColor = false
        Button.LayoutOrder = Order
        Library:Themed(Button, "BackgroundColor3", "Surface")
        Library:Corner(Button, 8)

        local Icon = Instance.new("ImageLabel")
        Icon.Name = "Icon"
        Icon.Parent = Button
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.BorderSizePixel = 0
        Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Library:SetIcon(Icon, IconName, Library.Theme.Accent)
        Library:Themed(Icon, "ImageColor3", "Accent")

        Library:Hover(Button, Button, "BackgroundTransparency", 0.94, 0.82)
        return Button, Icon
    end

    local ChangelogBtn = MakeControl("Changelog", "history", 1)
    ChangelogBtn.MouseButton1Click:Connect(function()
        WindowAPI:Changelog()
    end)
    local ThemeBtn = MakeControl("Theme", Library.DefaultIcons.Palette, 2)
    local Minize = MakeControl("Minize", Library.DefaultIcons.Minimize, 3)
    local Large = MakeControl("Large", Library.DefaultIcons.Maximize, 4)
    local Close = MakeControl("Close", Library.DefaultIcons.Close, 5)

    local TabFrame = Instance.new("Frame")
    TabFrame.Name = "TabFrame"
    TabFrame.Parent = Main
    TabFrame.BackgroundTransparency = 0.97
    TabFrame.BorderSizePixel = 0
    TabFrame.Position = UDim2.new(0, 0, 0, 54)
    TabFrame.Size = UDim2.new(0, 156, 1, -54)
    Library:Themed(TabFrame, "BackgroundColor3", "Surface")

    local Line_2 = Instance.new("Frame")
    Line_2.Name = "Line"
    Line_2.Parent = TabFrame
    Line_2.BorderSizePixel = 0
    Line_2.Position = UDim2.new(1, -1, 0, 0)
    Line_2.Size = UDim2.new(0, 1, 1, 0)
    Library:Themed(Line_2, "BackgroundColor3", "Accent")
    Library:FadeLine(Line_2, Library.Theme.Accent, false)

    local SearchFrame = Instance.new("Frame")
    SearchFrame.Name = "SearchFrame"
    SearchFrame.Parent = TabFrame
    SearchFrame.BackgroundTransparency = 0.93
    SearchFrame.BorderSizePixel = 0
    SearchFrame.Position = UDim2.new(0, 10, 0, 12)
    SearchFrame.Size = UDim2.new(1, -21, 0, 32)
    Library:Themed(SearchFrame, "BackgroundColor3", "Surface")
    Library:Corner(SearchFrame, 8)
    local SearchStroke = Library:Stroke(SearchFrame, Library.Theme.Stroke, 0.85, 1)

    local IconSearch = Instance.new("ImageLabel")
    IconSearch.Name = "IconSearch"
    IconSearch.Parent = SearchFrame
    IconSearch.AnchorPoint = Vector2.new(0, 0.5)
    IconSearch.BackgroundTransparency = 1
    IconSearch.BorderSizePixel = 0
    IconSearch.Position = UDim2.new(0, 10, 0.5, 0)
    IconSearch.Size = UDim2.new(0, 14, 0, 14)
    Library:SetIcon(IconSearch, Library.DefaultIcons.Search, Library.Theme.Accent)
    Library:Themed(IconSearch, "ImageColor3", "Accent")

    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "SearchBox"
    SearchBox.Parent = SearchFrame
    SearchBox.BackgroundTransparency = 1
    SearchBox.BorderSizePixel = 0
    SearchBox.ClipsDescendants = true
    SearchBox.Position = UDim2.new(0, 32, 0, 0)
    SearchBox.Size = UDim2.new(1, -40, 1, 0)
    SearchBox.Font = Enum.Font.GothamMedium
    SearchBox.PlaceholderText = "Search"
    SearchBox.Text = ""
    SearchBox.TextSize = 12
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    Library:Themed(SearchBox, "TextColor3", "Text")
    Library:Themed(SearchBox, "PlaceholderColor3", "TextDisabled")

    SearchBox.Focused:Connect(function()
        Library:TweenInstance(SearchStroke, 0.2, "Transparency", 0.35)
        Library:TweenInstance(SearchStroke, 0.2, "Color", Library.Theme.Accent)
    end)

    SearchBox.FocusLost:Connect(function()
        Library:TweenInstance(SearchStroke, 0.2, "Transparency", 0.85)
        Library:TweenInstance(SearchStroke, 0.2, "Color", Library.Theme.Stroke)
    end)

    local ScrollingTab = Instance.new("ScrollingFrame")
    ScrollingTab.Name = "ScrollingTab"
    ScrollingTab.Parent = TabFrame
    ScrollingTab.BackgroundTransparency = 1
    ScrollingTab.BorderSizePixel = 0
    ScrollingTab.Position = UDim2.new(0, 0, 0, 52)
    ScrollingTab.Selectable = false
    ScrollingTab.Size = UDim2.new(1, 0, 1, -108)
    Library:StyleScroll(ScrollingTab)

    local UIPadding_2 = Instance.new("UIPadding")
    UIPadding_2.Parent = ScrollingTab
    UIPadding_2.PaddingBottom = UDim.new(0, 4)
    UIPadding_2.PaddingLeft = UDim.new(0, 8)
    UIPadding_2.PaddingRight = UDim.new(0, 8)
    UIPadding_2.PaddingTop = UDim.new(0, 4)

    local UIListLayout_2 = Instance.new("UIListLayout")
    UIListLayout_2.Parent = ScrollingTab
    UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_2.Padding = UDim.new(0, 3)
    self:UpdateScrolling(ScrollingTab, UIListLayout_2)

    local BottomBar = Instance.new("Frame")
    BottomBar.Name = "BottomBar"
    BottomBar.Parent = TabFrame
    BottomBar.BackgroundTransparency = 1
    BottomBar.BorderSizePixel = 0
    BottomBar.Position = UDim2.new(0, 0, 1, -54)
    BottomBar.Size = UDim2.new(1, -1, 0, 54)

    local BottomLine = Instance.new("Frame")
    BottomLine.Name = "BottomLine"
    BottomLine.Parent = BottomBar
    BottomLine.BorderSizePixel = 0
    BottomLine.Position = UDim2.new(0, 8, 0, 0)
    BottomLine.Size = UDim2.new(1, -16, 0, 1)
    Library:Themed(BottomLine, "BackgroundColor3", "Accent")
    Library:FadeLine(BottomLine, Library.Theme.Accent, true)

    local BottomHolder = Instance.new("Frame")
    BottomHolder.Name = "BottomHolder"
    BottomHolder.Parent = BottomBar
    BottomHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    BottomHolder.BackgroundTransparency = 1
    BottomHolder.BorderSizePixel = 0
    BottomHolder.Position = UDim2.new(0.5, 0, 0.5, 2)
    BottomHolder.Size = UDim2.new(1, -10, 0, 34)
    BottomHolder.ZIndex = 8

    local BottomList = Instance.new("UIListLayout")
    BottomList.Parent = BottomHolder
    BottomList.FillDirection = Enum.FillDirection.Horizontal
    BottomList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    BottomList.VerticalAlignment = Enum.VerticalAlignment.Center
    BottomList.SortOrder = Enum.SortOrder.LayoutOrder
    BottomList.Padding = UDim.new(0, 5)

    local Tooltip = Instance.new("Frame")
    Tooltip.Name = "Tooltip"
    Tooltip.Parent = TabFrame
    Tooltip.AnchorPoint = Vector2.new(0.5, 1)
    Tooltip.BackgroundTransparency = 1
    Tooltip.BorderSizePixel = 0
    Tooltip.Position = UDim2.new(0.5, 0, 1, -58)
    Tooltip.Size = UDim2.new(0, 110, 0, 22)
    Tooltip.Visible = false
    Tooltip.ZIndex = 40
    Library:Themed(Tooltip, "BackgroundColor3", "Elevated")
    Library:Corner(Tooltip, 6)
    local TooltipStroke = Library:Stroke(Tooltip, Library.Theme.Stroke, 0.7, 1)

    local TooltipText = Instance.new("TextLabel")
    TooltipText.Parent = Tooltip
    TooltipText.BackgroundTransparency = 1
    TooltipText.Size = UDim2.new(1, 0, 1, 0)
    TooltipText.Font = Enum.Font.GothamMedium
    TooltipText.Text = ""
    TooltipText.TextSize = 11
    TooltipText.ZIndex = 41
    Library:Themed(TooltipText, "TextColor3", "Text")

    local function ShowTooltip(Text)
        TooltipText.Text = Text
        Tooltip.Visible = true
        Tooltip.BackgroundTransparency = 1
        TooltipText.TextTransparency = 1
        TooltipStroke.Transparency = 1
        Library:TweenInstance(Tooltip, 0.16, "BackgroundTransparency", 0.05)
        Library:TweenInstance(TooltipText, 0.16, "TextTransparency", 0)
        Library:TweenInstance(TooltipStroke, 0.16, "Transparency", 0.7)
    end

    local function HideTooltip()
        Library:TweenInstance(Tooltip, 0.14, "BackgroundTransparency", 1)
        Library:TweenInstance(TooltipText, 0.14, "TextTransparency", 1)
        Library:TweenInstance(TooltipStroke, 0.14, "Transparency", 1, function()
            Tooltip.Visible = false
        end)
    end

    local BottomButtons = {}

    local function MakeBottomBtn(Name, IconName, Order, TooltipLabel, Callback)
        local Button = Instance.new("TextButton")
        Button.Name = Name
        Button.Parent = BottomHolder
        Button.BackgroundTransparency = 0.92
        Button.BorderSizePixel = 0
        Button.Size = UDim2.new(0, 36, 0, 32)
        Button.ZIndex = 9
        Button.Text = ""
        Button.AutoButtonColor = false
        Button.LayoutOrder = Order
        Library:Themed(Button, "BackgroundColor3", "Surface")
        Library:Corner(Button, 8)
        local Stroke = Library:Stroke(Button, Library.Theme.Stroke, 0.88, 1)

        local Icon = Instance.new("ImageLabel")
        Icon.Name = "Icon"
        Icon.Parent = Button
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.BorderSizePixel = 0
        Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Library:SetIcon(Icon, IconName, Library.Theme.Text)

        local Data = { Button = Button, Icon = Icon, Stroke = Stroke, IconName = IconName, Active = false }

        function Data:SetActive(State)
            Data.Active = State
            if State then
                Library:TweenInstance(Button, 0.22, "BackgroundColor3", Library.Theme.Accent)
                Library:TweenInstance(Button, 0.22, "BackgroundTransparency", 0.1)
                Library:TweenInstance(Stroke, 0.22, "Transparency", 0.4)
                Library:TweenInstance(Stroke, 0.22, "Color", Library.Theme.Accent)
                Library:SetIcon(Icon, IconName, Color3.fromRGB(255, 255, 255))
            else
                Library:TweenInstance(Button, 0.22, "BackgroundColor3", Library.Theme.Surface)
                Library:TweenInstance(Button, 0.22, "BackgroundTransparency", 0.92)
                Library:TweenInstance(Stroke, 0.22, "Transparency", 0.88)
                Library:TweenInstance(Stroke, 0.22, "Color", Library.Theme.Stroke)
                Library:SetIcon(Icon, IconName, Library.Theme.Text)
            end
        end

        Button.MouseEnter:Connect(function()
            ShowTooltip(TooltipLabel)
            if not Data.Active then
                Library:TweenInstance(Button, 0.16, "BackgroundTransparency", 0.84)
            end
            Library:TweenInstance(Icon, 0.16, "Size", UDim2.new(0, 18, 0, 18))
        end)

        Button.MouseLeave:Connect(function()
            HideTooltip()
            if not Data.Active then
                Library:TweenInstance(Button, 0.16, "BackgroundTransparency", 0.92)
            end
            Library:TweenInstance(Icon, 0.16, "Size", UDim2.new(0, 16, 0, 16))
        end)

        Button.MouseButton1Click:Connect(function()
            Library:Flash(Button)
            Callback(Data)
        end)

        Button.TouchTap:Connect(function()
            Library:Flash(Button)
            Callback(Data)
        end)

        BottomButtons[Name] = Data
        return Data
    end

    local ReorderBtn = MakeBottomBtn("Reorder", Library.DefaultIcons.Reorder, 1, "Reorder tabs", function(Data)
        ReorderMode = not ReorderMode
        Data:SetActive(ReorderMode)
        for _, Entry in ipairs(TabElements) do
            if Entry.DragHandle then
                Entry.DragHandle.Visible = ReorderMode
                Entry.DragIcon.Visible = ReorderMode
                if ReorderMode then
                    Entry.DragIcon.ImageTransparency = 1
                    Library:TweenInstance(Entry.DragIcon, 0.2, "ImageTransparency", 0.15)
                end
            end
        end
    end)

    local AIBtn = MakeBottomBtn("AI", Library.DefaultIcons.Bot, 2, "AI assistant", function()
        if ToggleAI then
            ToggleAI()
        end
    end)
    AIBtn.Icon.Image = "rbxassetid://86390392481729"
    AIBtn.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    AIBtn.Icon.Size = UDim2.new(0, 19, 0, 19)
    Library:Corner(AIBtn.Icon, UDim.new(1, 0))
    local AIBtnOriginalSetActive = AIBtn.SetActive
    AIBtn.SetActive = function(self, State)
        AIBtnOriginalSetActive(self, State)
        AIBtn.Icon.Image = "rbxassetid://86390392481729"
        AIBtn.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end

    local CardBtn = MakeBottomBtn("PlayerCard", "contact", 3, "Player card", function()
        if TogglePlayerCard then
            TogglePlayerCard()
        end
    end)

    local LayoutFrame = Instance.new("Frame")
    LayoutFrame.Name = "LayoutFrame"
    LayoutFrame.Parent = Main
    LayoutFrame.BackgroundTransparency = 1
    LayoutFrame.BorderSizePixel = 0
    LayoutFrame.Position = UDim2.new(0, 156, 0, 54)
    LayoutFrame.Size = UDim2.new(1, -156, 1, -54)
    LayoutFrame.ClipsDescendants = true

    local RealLayout = Instance.new("Frame")
    RealLayout.Name = "RealLayout"
    RealLayout.Parent = LayoutFrame
    RealLayout.BackgroundTransparency = 1
    RealLayout.BorderSizePixel = 0
    RealLayout.Position = UDim2.new(0, 0, 0, 42)
    RealLayout.Size = UDim2.new(1, 0, 1, -42)

    local LayoutList = Instance.new("Frame")
    LayoutList.Name = "Layout List"
    LayoutList.Parent = RealLayout
    LayoutList.BackgroundTransparency = 1
    LayoutList.BorderSizePixel = 0
    LayoutList.Size = UDim2.new(1, 0, 1, 0)

    local UIPageLayout = Instance.new("UIPageLayout")
    UIPageLayout.Parent = LayoutList
    UIPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIPageLayout.EasingStyle = Enum.EasingStyle.Quint
    UIPageLayout.EasingDirection = Out
    UIPageLayout.TweenTime = 0.32

    local LayoutName = Instance.new("Frame")
    LayoutName.Name = "LayoutName"
    LayoutName.Parent = LayoutFrame
    LayoutName.BackgroundTransparency = 1
    LayoutName.BorderSizePixel = 0
    LayoutName.Size = UDim2.new(1, 0, 0, 42)

    local CrumbIcon = Instance.new("ImageLabel")
    CrumbIcon.Name = "CrumbIcon"
    CrumbIcon.Parent = LayoutName
    CrumbIcon.AnchorPoint = Vector2.new(0, 0.5)
    CrumbIcon.BackgroundTransparency = 1
    CrumbIcon.BorderSizePixel = 0
    CrumbIcon.Position = UDim2.new(0, 14, 0.5, 0)
    CrumbIcon.Size = UDim2.new(0, 15, 0, 15)
    Library:SetIcon(CrumbIcon, Library.DefaultIcons.Tab, Library.Theme.Accent)
    Library:Themed(CrumbIcon, "ImageColor3", "Accent")

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = "PageTitle"
    TextLabel.Parent = LayoutName
    TextLabel.BackgroundTransparency = 1
    TextLabel.BorderSizePixel = 0
    TextLabel.Position = UDim2.new(0, 36, 0, 0)
    TextLabel.Size = UDim2.new(1, -46, 1, 0)
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = ""
    TextLabel.TextSize = 13
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    Library:Themed(TextLabel, "TextColor3", "Text")

    local DropdownZone = Instance.new("Frame")
    DropdownZone.Name = "DropdownZone"
    DropdownZone.Parent = Main
    DropdownZone.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    DropdownZone.BackgroundTransparency = 1
    DropdownZone.BorderSizePixel = 0
    DropdownZone.Size = UDim2.new(1, 0, 1, 0)
    DropdownZone.Visible = false
    DropdownZone.ZIndex = 20
    Library:Corner(DropdownZone, 12)

    self:MakeDraggable(Top, DropShadowHolder)

    local FloatBox = Instance.new("Frame")
    FloatBox.Name = "FloatingButton"
    FloatBox.Parent = ScreenGui
    FloatBox.BackgroundTransparency = 0.25
    FloatBox.BorderSizePixel = 0
    FloatBox.Position = UDim2.new(0.04, 0, 0.36, 0)
    FloatBox.Size = UDim2.new(0, 168, 0, 44)
    FloatBox.ZIndex = 10
    FloatBox.Visible = false
    FloatBox.Active = true
    Library:Themed(FloatBox, "BackgroundColor3", "Elevated")
    Library:Corner(FloatBox, 12)
    local FloatStroke = Library:Stroke(FloatBox, Library.Theme.Accent, 0.55, 1.2)
    Library:Themed(FloatStroke, "Color", "Accent")

    local FloatLogo = Instance.new("ImageLabel")
    FloatLogo.Name = "Logo"
    FloatLogo.Parent = FloatBox
    FloatLogo.AnchorPoint = Vector2.new(0, 0.5)
    FloatLogo.BackgroundTransparency = 1
    FloatLogo.Position = UDim2.new(0, 10, 0.5, 0)
    FloatLogo.Size = UDim2.new(0, 24, 0, 24)
    FloatLogo.Image = ConfigWindow.Logo or ConfigWindow.Icon
    FloatLogo.ScaleType = Enum.ScaleType.Fit
    FloatLogo.ZIndex = 11

    local FloatTitle = Instance.new("TextLabel")
    FloatTitle.Name = "Title"
    FloatTitle.Parent = FloatBox
    FloatTitle.BackgroundTransparency = 1
    FloatTitle.Position = UDim2.new(0, 42, 0, 0)
    FloatTitle.Size = UDim2.new(1, -78, 1, 0)
    FloatTitle.Font = Enum.Font.GothamBold
    FloatTitle.Text = ConfigWindow.Title or "sh1ttybanana"
    FloatTitle.TextSize = 12
    FloatTitle.TextXAlignment = Enum.TextXAlignment.Left
    FloatTitle.TextTruncate = Enum.TextTruncate.AtEnd
    FloatTitle.ZIndex = 11
    Library:Themed(FloatTitle, "TextColor3", "Text")

    local FloatScan = Instance.new("ImageButton")
    FloatScan.Name = "Scan"
    FloatScan.Parent = FloatBox
    FloatScan.AnchorPoint = Vector2.new(1, 0.5)
    FloatScan.BackgroundTransparency = 1
    FloatScan.Position = UDim2.new(1, -12, 0.5, 0)
    FloatScan.Size = UDim2.new(0, 20, 0, 20)
    FloatScan.ZIndex = 12
    Library:SetIcon(FloatScan, Library.DefaultIcons.Scan, Library.Theme.Accent)
    Library:Themed(FloatScan, "ImageColor3", "Accent")

    self:MakeDraggable(FloatBox, FloatBox)

    ToggleWindow = function(Open)
        if Open then
            FloatBox.Visible = false
            DropShadowHolder.Visible = true
            DropShadowHolder.Size = UDim2.new(0, math.floor(ConfigWindow.Size.X.Offset * 0.86), 0, math.floor(ConfigWindow.Size.Y.Offset * 0.86))
            Main.BackgroundTransparency = 1
            Library:Tween(DropShadowHolder, TweenInfo.new(0.42, Back, Out), { Size = ConfigWindow.Size })
            Library:TweenInstance(Main, 0.35, "BackgroundTransparency", typeof(ConfigWindow.Transparent) == "number" and ConfigWindow.Transparent or 0.07)
        else
            Library:Tween(DropShadowHolder, TweenInfo.new(0.28, Quart, In), {
                Size = UDim2.new(0, math.floor(ConfigWindow.Size.X.Offset * 0.8), 0, math.floor(ConfigWindow.Size.Y.Offset * 0.8))
            }, function()
                DropShadowHolder.Visible = false
                DropShadowHolder.Size = ConfigWindow.Size
                FloatBox.Visible = true
                Library:Pop(FloatBox, 0.3, 0.85)
            end)
            Library:TweenInstance(Main, 0.25, "BackgroundTransparency", 1)
        end
    end

    FloatScan.MouseButton1Click:Connect(function()
        ToggleWindow(not DropShadowHolder.Visible)
    end)

    local function FindTab(Name)
        if type(Name) ~= "string" then
            return nil
        end
        local Target = string.lower(Trim(Name))
        if Target == "" then
            return nil
        end
        for _, Entry in ipairs(TabRegistry) do
            if string.lower(Entry.Name) == Target then
                return Entry
            end
        end
        for _, Entry in ipairs(TabRegistry) do
            if string.find(string.lower(Entry.Name), Target, 1, true) then
                return Entry
            end
        end
        return nil
    end

    local function SelectTabByName(Name)
        local Entry = FindTab(Name)
        if not Entry then
            return false
        end
        if not DropShadowHolder.Visible then
            ToggleWindow(true)
        end
        if Entry.Locked and Entry.IsUnlocked and not Entry.IsUnlocked() then
            if Entry.RequestUnlock then
                Entry.RequestUnlock()
            end
            return false
        end
        Entry.Select()
        return true
    end

    local YellowHex = "#FFD400"
    local HighlightedLabels = {}
    local HighlightedFrames = {}
    local LastJumpedTarget = nil

    local function ClearComponentHighlights()
        for _, Rec in ipairs(HighlightedLabels) do
            if Rec.Label and Rec.Label.Parent then
                Rec.Label.RichText = false
                Rec.Label.Text = Rec.Original
            end
        end
        HighlightedLabels = {}
        for _, Frm in ipairs(HighlightedFrames) do
            if Frm and Frm.Parent then
                local Glow = Frm:FindFirstChild("SearchGlow")
                if Glow then
                    Glow:Destroy()
                end
            end
        end
        HighlightedFrames = {}
    end

    local function HighlightSubstring(Label, Raw, Start, Len)
        Label.RichText = true
        Label.Text = string.sub(Raw, 1, Start - 1)
            .. '<font color="' .. YellowHex .. '">'
            .. string.sub(Raw, Start, Start + Len - 1)
            .. "</font>"
            .. string.sub(Raw, Start + Len)
        table.insert(HighlightedLabels, { Label = Label, Original = Raw })
    end

    local function GlowFrame(Frame)
        if not Frame then
            return
        end
        local Glow = Instance.new("UIStroke")
        Glow.Name = "SearchGlow"
        Glow.Parent = Frame
        Glow.Thickness = 1.5
        Glow.Transparency = 0.2
        Library:Themed(Glow, "Color", "Accent")
        table.insert(HighlightedFrames, Frame)
    end

    local function ScrollToFrame(Entry)
        task.defer(function()
            task.wait()
            if not (Entry.Frame and Entry.Frame.Parent and Entry.Page) then
                return
            end
            local PageAbsY = Entry.Page.AbsolutePosition.Y
            local FrameAbsY = Entry.Frame.AbsolutePosition.Y
            local Target = Entry.Page.CanvasPosition.Y + (FrameAbsY - PageAbsY) - 60
            Entry.Page.CanvasPosition = Vector2.new(0, math.max(0, Target))
        end)
    end

    local function ApplySearch(Query)
        Query = string.lower(Trim(Query or ""))

        ClearComponentHighlights()

        for _, Entry in ipairs(TabRegistry) do
            local Raw = Entry.Name
            local Lower = string.lower(Raw)
            local Start = Query ~= "" and string.find(Lower, Query, 1, true) or nil
            local Match = Query == "" or Start ~= nil
            Entry.Frame.Visible = Match
            if Match and Start then
                HighlightSubstring(Entry.Label, Raw, Start, #Query)
            else
                Entry.Label.RichText = false
                Entry.Label.Text = Raw
            end
        end
        for _, Entry in ipairs(SectionRegistry) do
            Entry.Refresh()
        end

        if Query == "" then
            LastJumpedTarget = nil
            return
        end

        -- Component-level search: highlight matching element titles in
        -- their own tab and jump straight to the first match, wherever
        -- it lives. Tab names already matched above take priority only
        -- for sidebar filtering -- this handles the content itself.
        local FirstMatch = nil
        for _, Item in ipairs(UIIndex) do
            if Item.Frame and Item.Frame.Parent then
                local Lower = string.lower(Item.Title)
                local Start = string.find(Lower, Query, 1, true)
                if Start then
                    if Item.Label then
                        HighlightSubstring(Item.Label, Item.Title, Start, #Query)
                    end
                    GlowFrame(Item.Frame)
                    if not FirstMatch then
                        FirstMatch = Item
                    end
                end
            end
        end

        if FirstMatch then
            local Key = FirstMatch.Tab .. ":" .. FirstMatch.Title
            if Key ~= LastJumpedTarget then
                LastJumpedTarget = Key
                SelectTabByName(FirstMatch.Tab)
                ScrollToFrame(FirstMatch)
            end
        end
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        ApplySearch(SearchBox.Text)
    end)

    local IsEnlarged = false

    Minize.MouseButton1Click:Connect(function()
        ToggleWindow(false)
    end)

    Large.MouseButton1Click:Connect(function()
        IsEnlarged = not IsEnlarged
        local Base = ConfigWindow.Size
        local Target = IsEnlarged and UDim2.new(0, math.floor(Base.X.Offset * 1.22), 0, math.floor(Base.Y.Offset * 1.22)) or Base
        Library:Tween(DropShadowHolder, TweenInfo.new(0.38, Quart, Out), { Size = Target })
    end)

    local function ShowModal(BuildFn)
        DropdownZone.Visible = true
        DropdownZone.BackgroundTransparency = 1
        Library:TweenInstance(DropdownZone, 0.22, "BackgroundTransparency", 0.42)

        local Popup = Instance.new("Frame")
        Popup.Name = "Modal"
        Popup.Parent = DropdownZone
        Popup.AnchorPoint = Vector2.new(0.5, 0.5)
        Popup.BorderSizePixel = 0
        Popup.Position = UDim2.new(0.5, 0, 0.5, 0)
        Popup.ZIndex = 25
        Library:Themed(Popup, "BackgroundColor3", "Elevated")
        Library:Corner(Popup, 12)
        Library:Stroke(Popup, Library.Theme.Accent, 0.6, 1.2)
        Library:Pop(Popup, 0.34, 0.88)

        local function ClosePopup()
            local Scale = Popup:FindFirstChildOfClass("UIScale")
            if Scale then
                Library:Tween(Scale, TweenInfo.new(0.18, Quart, In), { Scale = 0.9 })
            end
            Library:TweenInstance(DropdownZone, 0.2, "BackgroundTransparency", 1, function()
                DropdownZone.Visible = false
            end)
            task.delay(0.18, function()
                if Popup then
                    Popup:Destroy()
                end
            end)
        end

        BuildFn(Popup, ClosePopup)
        return Popup, ClosePopup
    end

    local ThemeDropdownOpen = false
    ThemeBtn.MouseButton1Click:Connect(function()
        if ThemeDropdownOpen then
            return
        end
        ThemeDropdownOpen = true

        local Catcher = Instance.new("TextButton")
        Catcher.Name = "ThemeCatcher"
        Catcher.Parent = Main
        Catcher.BackgroundTransparency = 1
        Catcher.Size = UDim2.new(1, 0, 1, 0)
        Catcher.Text = ""
        Catcher.AutoButtonColor = false
        Catcher.ZIndex = 24

        local ThemeList = Instance.new("Frame")
        ThemeList.Name = "ThemeList"
        ThemeList.Parent = Main
        ThemeList.AnchorPoint = Vector2.new(1, 0)
        ThemeList.BorderSizePixel = 0
        ThemeList.Position = UDim2.new(1, -12, 0, 44)
        ThemeList.Size = UDim2.new(0, 150, 0, 0)
        ThemeList.AutomaticSize = Enum.AutomaticSize.Y
        ThemeList.ZIndex = 25
        Library:Themed(ThemeList, "BackgroundColor3", "Elevated")
        Library:Corner(ThemeList, 10)
        Library:Stroke(ThemeList, Library.Theme.Stroke, 0.75, 1)
        Library:Pop(ThemeList, 0.22, 0.9)

        local ThemeListPad = Instance.new("UIPadding")
        ThemeListPad.Parent = ThemeList
        ThemeListPad.PaddingTop = UDim.new(0, 6)
        ThemeListPad.PaddingBottom = UDim.new(0, 6)
        ThemeListPad.PaddingLeft = UDim.new(0, 6)
        ThemeListPad.PaddingRight = UDim.new(0, 6)

        local ThemeListLayout = Instance.new("UIListLayout")
        ThemeListLayout.Parent = ThemeList
        ThemeListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ThemeListLayout.Padding = UDim.new(0, 3)

        local function CloseThemeDropdown()
            ThemeDropdownOpen = false
            Catcher:Destroy()
            ThemeList:Destroy()
        end

        Catcher.MouseButton1Click:Connect(CloseThemeDropdown)

        for i, ThemeName in ipairs(Library.ThemeOrder) do
            if Library.Themes[ThemeName] then
                local Row = Instance.new("TextButton")
                Row.Parent = ThemeList
                Row.LayoutOrder = i
                Row.BackgroundTransparency = Library.CurrentTheme == ThemeName and 0.85 or 1
                Row.BorderSizePixel = 0
                Row.Size = UDim2.new(1, 0, 0, 34)
                Row.Text = ""
                Row.AutoButtonColor = false
                Row.ZIndex = 26
                Library:Themed(Row, "BackgroundColor3", "Accent")
                Library:Corner(Row, 7)

                local Swatch = Instance.new("Frame")
                Swatch.Parent = Row
                Swatch.AnchorPoint = Vector2.new(0, 0.5)
                Swatch.BackgroundColor3 = Library.Themes[ThemeName].Main
                Swatch.BorderSizePixel = 0
                Swatch.Position = UDim2.new(0, 10, 0.5, 0)
                Swatch.Size = UDim2.new(0, 18, 0, 18)
                Swatch.ZIndex = 27
                Library:Corner(Swatch, 6)
                Library:Stroke(Swatch, Library.Theme.Stroke, 0.5, 1)

                local RowLabel = Instance.new("TextLabel")
                RowLabel.Parent = Row
                RowLabel.BackgroundTransparency = 1
                RowLabel.Position = UDim2.new(0, 38, 0, 0)
                RowLabel.Size = UDim2.new(1, -70, 1, 0)
                RowLabel.Font = Library.CurrentTheme == ThemeName and Enum.Font.GothamBold or Enum.Font.Gotham
                RowLabel.Text = ThemeName
                RowLabel.TextSize = 13
                RowLabel.TextXAlignment = Enum.TextXAlignment.Left
                RowLabel.ZIndex = 27
                Library:Themed(RowLabel, "TextColor3", "Text")

                if Library.CurrentTheme == ThemeName then
                    local Check = Instance.new("ImageLabel")
                    Check.Parent = Row
                    Check.AnchorPoint = Vector2.new(1, 0.5)
                    Check.BackgroundTransparency = 1
                    Check.Position = UDim2.new(1, -10, 0.5, 0)
                    Check.Size = UDim2.new(0, 14, 0, 14)
                    Check.ZIndex = 27
                    Library:SetIcon(Check, "check", Library.Theme.Accent)
                end

                Row.MouseEnter:Connect(function()
                    if Library.CurrentTheme ~= ThemeName then
                        Library:TweenInstance(Row, 0.12, "BackgroundTransparency", 0.92)
                    end
                end)
                Row.MouseLeave:Connect(function()
                    if Library.CurrentTheme ~= ThemeName then
                        Library:TweenInstance(Row, 0.12, "BackgroundTransparency", 1)
                    end
                end)

                Row.MouseButton1Click:Connect(function()
                    Library:ApplyTheme(ThemeName)
                    Library:Flash(Main, Library.Theme.Accent)
                    CloseThemeDropdown()
                end)
            end
        end
    end)

    Close.MouseButton1Click:Connect(function()
        ShowModal(function(Popup, ClosePopup)
            Popup.Size = UDim2.new(0, 340, 0, 176)

            local Icon = Instance.new("ImageLabel")
            Icon.Parent = Popup
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0, 20, 0, 18)
            Icon.Size = UDim2.new(0, 20, 0, 20)
            Icon.ZIndex = 26
            Library:SetIcon(Icon, "triangle-alert", Library.Theme.Accent)

            local Title = Instance.new("TextLabel")
            Title.Parent = Popup
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 50, 0, 16)
            Title.Size = UDim2.new(1, -70, 0, 24)
            Title.Font = Enum.Font.GothamBold
            Title.Text = "Unload interface"
            Title.TextSize = 15
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.ZIndex = 26
            Library:Themed(Title, "TextColor3", "Text")

            local Content = Instance.new("TextLabel")
            Content.Parent = Popup
            Content.BackgroundTransparency = 1
            Content.Position = UDim2.new(0, 20, 0, 48)
            Content.Size = UDim2.new(1, -40, 0, 46)
            Content.Font = Enum.Font.Gotham
            Content.Text = "This closes the window and removes every element. Scripts already running keep running."
            Content.TextSize = 12
            Content.TextWrapped = true
            Content.TextXAlignment = Enum.TextXAlignment.Left
            Content.TextYAlignment = Enum.TextYAlignment.Top
            Content.ZIndex = 26
            Library:Themed(Content, "TextColor3", "TextDisabled")

            local No = Instance.new("TextButton")
            No.Parent = Popup
            No.BackgroundTransparency = 0.9
            No.BorderSizePixel = 0
            No.Position = UDim2.new(0, 20, 1, -50)
            No.Size = UDim2.new(0.5, -26, 0, 34)
            No.Font = Enum.Font.GothamBold
            No.Text = "Cancel"
            No.TextSize = 13
            No.AutoButtonColor = false
            No.ZIndex = 26
            Library:Themed(No, "BackgroundColor3", "Surface")
            Library:Themed(No, "TextColor3", "Text")
            Library:Corner(No, 8)
            Library:Hover(No, No, "BackgroundTransparency", 0.9, 0.78)

            local Yes = Instance.new("TextButton")
            Yes.Parent = Popup
            Yes.AnchorPoint = Vector2.new(1, 0)
            Yes.BackgroundTransparency = 0.05
            Yes.BorderSizePixel = 0
            Yes.Position = UDim2.new(1, -20, 1, -50)
            Yes.Size = UDim2.new(0.5, -26, 0, 34)
            Yes.Font = Enum.Font.GothamBold
            Yes.Text = "Unload"
            Yes.TextColor3 = Color3.fromRGB(255, 255, 255)
            Yes.TextSize = 13
            Yes.AutoButtonColor = false
            Yes.ZIndex = 26
            Library:Themed(Yes, "BackgroundColor3", "Accent")
            Library:Corner(Yes, 8)
            Library:Hover(Yes, Yes, "BackgroundTransparency", 0.05, 0.25)

            No.MouseButton1Click:Connect(ClosePopup)

            Yes.MouseButton1Click:Connect(function()
                ClosePopup()
                Library:Tween(DropShadowHolder, TweenInfo.new(0.25, Quart, In), { Size = UDim2.new(0, 0, 0, 0) }, function()
                    ScreenGui:Destroy()
                end)
            end)
        end)
    end)

    local AIWindow = Instance.new("Frame")
    AIWindow.Name = "AIWindow"
    AIWindow.Parent = Main
    AIWindow.AnchorPoint = Vector2.new(0, 0)
    AIWindow.BackgroundTransparency = 0
    AIWindow.BorderSizePixel = 0
    AIWindow.Position = UDim2.new(0, 156, 0, 54)
    AIWindow.Size = UDim2.new(1, -156, 1, -54)
    AIWindow.Visible = false
    AIWindow.ZIndex = 200
    Library:Themed(AIWindow, "BackgroundColor3", "Main")
    local AIWindowLine = Instance.new("Frame")
    AIWindowLine.Parent = AIWindow
    AIWindowLine.BorderSizePixel = 0
    AIWindowLine.Position = UDim2.new(0, 0, 0, 0)
    AIWindowLine.Size = UDim2.new(0, 1, 1, 0)
    AIWindowLine.ZIndex = 201
    Library:Themed(AIWindowLine, "BackgroundColor3", "Stroke")

    local AIHeader = Instance.new("Frame")
    AIHeader.Name = "Header"
    AIHeader.Parent = AIWindow
    AIHeader.BackgroundTransparency = 1
    AIHeader.BorderSizePixel = 0
    AIHeader.Size = UDim2.new(1, 0, 0, 62)
    AIHeader.Active = true

    local AIBadge = Instance.new("Frame")
    AIBadge.Name = "Badge"
    AIBadge.Parent = AIHeader
    AIBadge.AnchorPoint = Vector2.new(0, 0.5)
    AIBadge.BorderSizePixel = 0
    AIBadge.Position = UDim2.new(0, 16, 0.5, 0)
    AIBadge.Size = UDim2.new(0, 36, 0, 36)
    Library:Themed(AIBadge, "BackgroundColor3", "Accent")
    Library:Corner(AIBadge, 11)
    Library:Gradient(AIBadge, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 148, 170))
    }), 55)

    local AIBadgeIcon = Instance.new("ImageLabel")
    AIBadgeIcon.Parent = AIBadge
    AIBadgeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    AIBadgeIcon.BackgroundTransparency = 1
    AIBadgeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    AIBadgeIcon.Size = UDim2.new(1, 0, 1, 0)
    AIBadgeIcon.Image = "rbxassetid://86390392481729"
    Library:Corner(AIBadgeIcon, 11)

    local AITitle = Instance.new("TextLabel")
    AITitle.Parent = AIHeader
    AITitle.BackgroundTransparency = 1
    AITitle.Position = UDim2.new(0, 62, 0, 12)
    AITitle.Size = UDim2.new(1, -160, 0, 18)
    AITitle.Font = Enum.Font.GothamBold
    AITitle.Text = "AI Assistant"
    AITitle.TextSize = 15
    AITitle.TextXAlignment = Enum.TextXAlignment.Left
    Library:Themed(AITitle, "TextColor3", "Text")

    local AIStatusDot = Instance.new("Frame")
    AIStatusDot.Parent = AIHeader
    AIStatusDot.BackgroundColor3 = Color3.fromRGB(70, 220, 130)
    AIStatusDot.BorderSizePixel = 0
    AIStatusDot.Position = UDim2.new(0, 63, 0, 36)
    AIStatusDot.Size = UDim2.new(0, 6, 0, 6)
    Library:Corner(AIStatusDot, UDim.new(1, 0))

    local AISubtitle = Instance.new("TextLabel")
    AISubtitle.Parent = AIHeader
    AISubtitle.BackgroundTransparency = 1
    AISubtitle.Position = UDim2.new(0, 75, 0, 30)
    AISubtitle.Size = UDim2.new(1, -175, 0, 16)
    AISubtitle.Font = Enum.Font.Gotham
    AISubtitle.Text = "Groq - " .. Library.GroqModel
    AISubtitle.TextSize = 11
    AISubtitle.TextXAlignment = Enum.TextXAlignment.Left
    AISubtitle.TextTruncate = Enum.TextTruncate.AtEnd
    Library:Themed(AISubtitle, "TextColor3", "TextDisabled")

    local AIActions = Instance.new("Frame")
    AIActions.Parent = AIHeader
    AIActions.AnchorPoint = Vector2.new(1, 0.5)
    AIActions.BackgroundTransparency = 1
    AIActions.Position = UDim2.new(1, -14, 0.5, 0)
    AIActions.Size = UDim2.new(0, 68, 0, 28)

    local AIActionList = Instance.new("UIListLayout")
    AIActionList.Parent = AIActions
    AIActionList.FillDirection = Enum.FillDirection.Horizontal
    AIActionList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    AIActionList.VerticalAlignment = Enum.VerticalAlignment.Center
    AIActionList.SortOrder = Enum.SortOrder.LayoutOrder
    AIActionList.Padding = UDim.new(0, 6)

    local function MakeAIAction(IconName, Order)
        local Button = Instance.new("TextButton")
        Button.Parent = AIActions
        Button.BackgroundTransparency = 0.93
        Button.BorderSizePixel = 0
        Button.Size = UDim2.new(0, 28, 0, 28)
        Button.Text = ""
        Button.AutoButtonColor = false
        Button.LayoutOrder = Order
        Library:Themed(Button, "BackgroundColor3", "Surface")
        Library:Corner(Button, 8)

        local Icon = Instance.new("ImageLabel")
        Icon.Parent = Button
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
        Icon.Size = UDim2.new(0, 15, 0, 15)
        Library:SetIcon(Icon, IconName, Library.Theme.TextDisabled)

        Library:Hover(Button, Button, "BackgroundTransparency", 0.93, 0.8)
        return Button, Icon
    end

    local AIClearBtn = MakeAIAction(Library.DefaultIcons.Trash, 1)
    local AICloseBtn = MakeAIAction(Library.DefaultIcons.Close, 2)

    local AIHeaderLine = Instance.new("Frame")
    AIHeaderLine.Parent = AIWindow
    AIHeaderLine.BorderSizePixel = 0
    AIHeaderLine.Position = UDim2.new(0, 0, 0, 62)
    AIHeaderLine.Size = UDim2.new(1, 0, 0, 1)
    Library:Themed(AIHeaderLine, "BackgroundColor3", "Accent")
    Library:FadeLine(AIHeaderLine, Library.Theme.Accent, true)

    local AIMessages = Instance.new("ScrollingFrame")
    AIMessages.Name = "Messages"
    AIMessages.Parent = AIWindow
    AIMessages.BackgroundTransparency = 1
    AIMessages.BorderSizePixel = 0
    AIMessages.Position = UDim2.new(0, 0, 0, 63)
    AIMessages.Size = UDim2.new(1, 0, 1, -175)
    AIMessages.Selectable = false
    Library:StyleScroll(AIMessages)

    local AIMessagePad = Instance.new("UIPadding")
    AIMessagePad.Parent = AIMessages
    AIMessagePad.PaddingTop = UDim.new(0, 14)
    AIMessagePad.PaddingBottom = UDim.new(0, 10)
    AIMessagePad.PaddingLeft = UDim.new(0, 14)
    AIMessagePad.PaddingRight = UDim.new(0, 14)

    local AIMessageList = Instance.new("UIListLayout")
    AIMessageList.Parent = AIMessages
    AIMessageList.SortOrder = Enum.SortOrder.LayoutOrder
    AIMessageList.Padding = UDim.new(0, 12)
    Library:UpdateScrolling(AIMessages, AIMessageList)

    local AISuggestions = Instance.new("ScrollingFrame")
    AISuggestions.Name = "Suggestions"
    AISuggestions.Parent = AIWindow
    AISuggestions.BackgroundTransparency = 1
    AISuggestions.BorderSizePixel = 0
    AISuggestions.Position = UDim2.new(0, 8, 1, -106)
    AISuggestions.Size = UDim2.new(1, -16, 0, 30)
    AISuggestions.ScrollBarThickness = 0
    AISuggestions.ScrollingDirection = Enum.ScrollingDirection.X
    AISuggestions.CanvasSize = UDim2.new(0, 0, 0, 0)
    AISuggestions.Selectable = false

    local AISuggestionList = Instance.new("UIListLayout")
    AISuggestionList.Parent = AISuggestions
    AISuggestionList.FillDirection = Enum.FillDirection.Horizontal
    AISuggestionList.VerticalAlignment = Enum.VerticalAlignment.Center
    AISuggestionList.SortOrder = Enum.SortOrder.LayoutOrder
    AISuggestionList.Padding = UDim.new(0, 6)
    AISuggestionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        AISuggestions.CanvasSize = UDim2.new(0, AISuggestionList.AbsoluteContentSize.X + 6, 0, 0)
    end)

    local AIInputFrame = Instance.new("Frame")
    AIInputFrame.Name = "InputFrame"
    AIInputFrame.Parent = AIWindow
    AIInputFrame.AnchorPoint = Vector2.new(0, 1)
    AIInputFrame.BackgroundTransparency = 0.93
    AIInputFrame.BorderSizePixel = 0
    AIInputFrame.Position = UDim2.new(0, 8, 1, -14)
    AIInputFrame.Size = UDim2.new(1, -16, 0, 54)
    Library:Themed(AIInputFrame, "BackgroundColor3", "Surface")
    Library:Corner(AIInputFrame, 12)
    local AIInputStroke = Library:Stroke(AIInputFrame, Library.Theme.Stroke, 0.8, 1)

    local AIInput = Instance.new("TextBox")
    AIInput.Name = "Input"
    AIInput.Parent = AIInputFrame
    AIInput.BackgroundTransparency = 1
    AIInput.BorderSizePixel = 0
    AIInput.ClipsDescendants = true
    AIInput.Position = UDim2.new(0, 14, 0, 0)
    AIInput.Size = UDim2.new(1, -62, 1, 0)
    AIInput.Font = Enum.Font.GothamMedium
    AIInput.PlaceholderText = "Ask about this hub..."
    AIInput.Text = ""
    AIInput.TextSize = 13
    AIInput.TextXAlignment = Enum.TextXAlignment.Left
    AIInput.ClearTextOnFocus = false
    Library:Themed(AIInput, "TextColor3", "Text")
    Library:Themed(AIInput, "PlaceholderColor3", "TextDisabled")

    local AISend = Instance.new("TextButton")
    AISend.Name = "Send"
    AISend.Parent = AIInputFrame
    AISend.AnchorPoint = Vector2.new(1, 0.5)
    AISend.BackgroundTransparency = 0.05
    AISend.BorderSizePixel = 0
    AISend.Position = UDim2.new(1, -6, 0.5, 0)
    AISend.Size = UDim2.new(0, 34, 0, 34)
    AISend.Text = ""
    AISend.AutoButtonColor = false
    Library:Themed(AISend, "BackgroundColor3", "Accent")
    Library:Corner(AISend, 10)

    local AISendIcon = Instance.new("ImageLabel")
    AISendIcon.Parent = AISend
    AISendIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    AISendIcon.BackgroundTransparency = 1
    AISendIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    AISendIcon.Size = UDim2.new(0, 16, 0, 16)
    Library:SetIcon(AISendIcon, Library.DefaultIcons.Send, Color3.fromRGB(255, 255, 255))

    Library:Hover(AISend, AISend, "BackgroundTransparency", 0.05, 0.25)

    AIInput.Focused:Connect(function()
        Library:TweenInstance(AIInputStroke, 0.2, "Transparency", 0.35)
        Library:TweenInstance(AIInputStroke, 0.2, "Color", Library.Theme.Accent)
    end)

    AIInput.FocusLost:Connect(function()
        Library:TweenInstance(AIInputStroke, 0.2, "Transparency", 0.8)
        Library:TweenInstance(AIInputStroke, 0.2, "Color", Library.Theme.Stroke)
    end)

    -- AI window moves with main window (attached)

    local ChatHistory = {}
    local Thinking = false
    local MessageOrder = 0
    local TypingHolder = nil

    local function ScrollToBottom()
        task.defer(function()
            AIMessages.CanvasPosition = Vector2.new(0, math.max(0, AIMessageList.AbsoluteContentSize.Y - AIMessages.AbsoluteSize.Y + 30))
        end)
    end

    local function MakeChip(Parent, Text, IconName, Order, Callback)
        local Chip = Instance.new("TextButton")
        Chip.Name = "Chip"
        Chip.Parent = Parent
        Chip.AutomaticSize = Enum.AutomaticSize.X
        Chip.BackgroundTransparency = 0.88
        Chip.BorderSizePixel = 0
        Chip.Size = UDim2.new(0, 0, 0, 26)
        Chip.Font = Enum.Font.GothamBold
        Chip.Text = Text
        Chip.TextSize = 11
        Chip.AutoButtonColor = false
        Chip.LayoutOrder = Order or 1
        Library:Themed(Chip, "TextColor3", "Text")
        Library:Themed(Chip, "BackgroundColor3", "Accent")
        Library:Corner(Chip, 8)
        local Stroke = Library:Stroke(Chip, Library.Theme.Accent, 0.62, 1)
        Library:Themed(Stroke, "Color", "Accent")

        local Pad = Instance.new("UIPadding")
        Pad.Parent = Chip
        Pad.PaddingLeft = UDim.new(0, IconName and 26 or 11)
        Pad.PaddingRight = UDim.new(0, 11)

        if IconName then
            local Icon = Instance.new("ImageLabel")
            Icon.Parent = Chip
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0, -17, 0.5, 0)
            Icon.Size = UDim2.new(0, 12, 0, 12)
            Library:SetIcon(Icon, IconName, Library.Theme.Accent)
            Library:Themed(Icon, "ImageColor3", "Accent")
        end

        Library:Hover(Chip, Chip, "BackgroundTransparency", 0.88, 0.66)

        Chip.MouseButton1Click:Connect(function()
            Library:Flash(Chip)
            Callback()
        end)

        return Chip
    end

    local function AddBubble(Role, Text, Refs)
        MessageOrder = MessageOrder + 1

        local IsUser = Role == "user"

        local Holder = Instance.new("Frame")
        Holder.Name = "Message"
        Holder.Parent = AIMessages
        Holder.AutomaticSize = Enum.AutomaticSize.Y
        Holder.BackgroundTransparency = 1
        Holder.BorderSizePixel = 0
        Holder.Size = UDim2.new(1, 0, 0, 0)
        Holder.LayoutOrder = MessageOrder

        -- Discord-style: avatar pinned top-left, name + message stacked
        -- in a column to its right. Same layout for both roles.
        local AvatarHolder = Instance.new("Frame")
        AvatarHolder.Parent = Holder
        AvatarHolder.BackgroundTransparency = 0
        AvatarHolder.BorderSizePixel = 0
        AvatarHolder.Position = UDim2.new(0, 0, 0, 2)
        AvatarHolder.Size = UDim2.new(0, 32, 0, 32)
        Library:Themed(AvatarHolder, "BackgroundColor3", "Accent")
        Library:Corner(AvatarHolder, UDim.new(1, 0))

        local Avatar = Instance.new("ImageLabel")
        Avatar.Parent = AvatarHolder
        Avatar.AnchorPoint = Vector2.new(0.5, 0.5)
        Avatar.BackgroundTransparency = 1
        Avatar.Position = UDim2.new(0.5, 0, 0.5, 0)
        Avatar.Size = IsUser and UDim2.new(1, -2, 1, -2) or UDim2.new(1, -8, 1, -8)
        Avatar.Image = IsUser
            and ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(Player.UserId) .. "&w=100&h=100")
            or "rbxassetid://86390392481729"
        if not IsUser then
            Avatar.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
        Library:Corner(Avatar, UDim.new(1, 0))

        local ContentCol = Instance.new("Frame")
        ContentCol.Parent = Holder
        ContentCol.BackgroundTransparency = 1
        ContentCol.Position = UDim2.new(0, 42, 0, 0)
        ContentCol.Size = UDim2.new(1, -42, 0, 0)
        ContentCol.AutomaticSize = Enum.AutomaticSize.Y

        local ContentList = Instance.new("UIListLayout")
        ContentList.Parent = ContentCol
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Padding = UDim.new(0, 3)

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Parent = ContentCol
        NameLbl.LayoutOrder = 0
        NameLbl.BackgroundTransparency = 1
        NameLbl.Size = UDim2.new(1, 0, 0, 16)
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.Text = IsUser and Player.DisplayName or "Groq AI"
        NameLbl.TextSize = 12
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        if IsUser then
            Library:Themed(NameLbl, "TextColor3", "Text")
        else
            Library:Themed(NameLbl, "TextColor3", "Accent")
        end

        local Label = Instance.new("TextLabel")
        Label.Name = "Text"
        Label.Parent = ContentCol
        Label.LayoutOrder = 1
        Label.AutomaticSize = Enum.AutomaticSize.Y
        Label.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, 0, 0, 0)
        Label.Font = Enum.Font.GothamMedium
        Label.Text = Text
        Label.TextSize = 13
        Label.TextWrapped = true
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextYAlignment = Enum.TextYAlignment.Top
        Label.LineHeight = 1.22
        Library:Themed(Label, "TextColor3", "Text")

        if Refs and #Refs > 0 then
            local ChipRow = Instance.new("Frame")
            ChipRow.Name = "Refs"
            ChipRow.Parent = ContentCol
            ChipRow.LayoutOrder = 2
            ChipRow.BackgroundTransparency = 1
            ChipRow.BorderSizePixel = 0
            ChipRow.Size = UDim2.new(1, 0, 0, 26)

            local ChipList = Instance.new("UIListLayout")
            ChipList.Parent = ChipRow
            ChipList.FillDirection = Enum.FillDirection.Horizontal
            ChipList.VerticalAlignment = Enum.VerticalAlignment.Center
            ChipList.SortOrder = Enum.SortOrder.LayoutOrder
            ChipList.Padding = UDim.new(0, 6)

            for Index, Name in ipairs(Refs) do
                MakeChip(ChipRow, Name, Library.DefaultIcons.ChevronRight, Index, function()
                    SelectTabByName(Name)
                end)
            end
        end

        local Scale = Instance.new("UIScale")
        Scale.Scale = 0.93
        Scale.Parent = Holder
        Library:Tween(Scale, TweenInfo.new(0.34, Back, Out), { Scale = 1 })

        Label.TextTransparency = 1
        Library:TweenInstance(Label, 0.3, "TextTransparency", 0)

        ScrollToBottom()
        return Holder
    end

    local function ShowTyping()
        if TypingHolder then
            return
        end
        MessageOrder = MessageOrder + 1

        local Holder = Instance.new("Frame")
        Holder.Name = "Typing"
        Holder.Parent = AIMessages
        Holder.BackgroundTransparency = 1
        Holder.BorderSizePixel = 0
        Holder.Size = UDim2.new(1, 0, 0, 32)
        Holder.LayoutOrder = MessageOrder

        local Bubble = Instance.new("Frame")
        Bubble.Parent = Holder
        Bubble.BackgroundTransparency = 0.92
        Bubble.BorderSizePixel = 0
        Bubble.Size = UDim2.new(0, 62, 0, 32)
        Library:Themed(Bubble, "BackgroundColor3", "Surface")
        Library:Corner(Bubble, 12)
        Library:Stroke(Bubble, Library.Theme.Stroke, 0.88, 1)

        for Index = 1, 3 do
            local BaseX = 12 + (Index - 1) * 14
            local Dot = Instance.new("Frame")
            Dot.Parent = Bubble
            Dot.AnchorPoint = Vector2.new(0, 0.5)
            Dot.BackgroundTransparency = 0.45
            Dot.BorderSizePixel = 0
            Dot.Position = UDim2.new(0, BaseX, 0.5, 0)
            Dot.Size = UDim2.new(0, 7, 0, 7)
            Library:Themed(Dot, "BackgroundColor3", "Accent")
            Library:Corner(Dot, UDim.new(1, 0))

            task.spawn(function()
                task.wait((Index - 1) * 0.12)
                while Dot.Parent do
                    Library:Tween(Dot, TweenInfo.new(0.3, Quart, Out), { Position = UDim2.new(0, BaseX, 0.5, -4), BackgroundTransparency = 0 })
                    task.wait(0.3)
                    Library:Tween(Dot, TweenInfo.new(0.3, Quart, Out), { Position = UDim2.new(0, BaseX, 0.5, 0), BackgroundTransparency = 0.45 })
                    task.wait(0.5)
                end
            end)
        end

        TypingHolder = Holder
        ScrollToBottom()
    end

    local function HideTyping()
        if TypingHolder then
            TypingHolder:Destroy()
            TypingHolder = nil
        end
    end

    local function BuildInterfaceMap()
        local Lines = {}
        table.insert(Lines, "Hub name: " .. tostring(ConfigWindow.Title))
        table.insert(Lines, "Hub description: " .. tostring(ConfigWindow.Description))

        local Names = {}
        for _, Entry in ipairs(TabRegistry) do
            table.insert(Names, Entry.Name)
        end
        table.insert(Lines, "Tabs: " .. (#Names > 0 and table.concat(Names, ", ") or "none yet"))

        local Count = 0
        for _, Item in ipairs(UIIndex) do
            Count = Count + 1
            if Count > 100 then
                table.insert(Lines, "more elements exist but are not listed")
                break
            end
            table.insert(Lines, string.format("%s | %s | %s | %s", Item.Tab, Item.Section, Item.Kind, Item.Title))
        end

        return table.concat(Lines, "\n")
    end

    local function BuildSystemPrompt()
        local Parts = {}
        table.insert(Parts, "You are the assistant built into the Roblox script hub named " .. tostring(ConfigWindow.Title) .. ".")
        table.insert(Parts, "You help the user find and understand the features of this interface and answer short scripting questions.")
        table.insert(Parts, "Reply in the language the user writes in. Stay under 90 words. No markdown headings, no tables, no code fences unless code was asked for.")
        table.insert(Parts, "When you point the user to a place in the interface, write the reference exactly as [[tab:Name]] where Name is copied from the tab list. Keep it inline in the sentence, use at most three references, and only names that exist.")
        table.insert(Parts, "If a feature is not in the map below, say it does not exist here instead of inventing it.")
        table.insert(Parts, "Never write or complete Lua code, function bodies, component/UI snippets, or scripts of any kind, even if asked directly or told it is for this same hub. Politely decline and redirect to the relevant tab instead.")
        table.insert(Parts, "Locked tabs still require their password even if you mention them by name -- clicking your reference only opens the password prompt, it never skips it.")
        table.insert(Parts, "Interface map:")
        table.insert(Parts, BuildInterfaceMap())

        local Extra = Trim(groqprompt)
        if Extra == "" then
            Extra = Trim(GetGlobal("groqprompt"))
        end
        if Extra ~= "" then
            table.insert(Parts, "Extra instructions from the hub owner:")
            table.insert(Parts, Extra)
        end

        return table.concat(Parts, "\n")
    end

    local function ExtractRefs(Text)
        local Refs = {}
        local Seen = {}

        for Name in string.gmatch(Text, "%[%[tab:(.-)%]%]") do
            local Entry = FindTab(Name)
            if Entry and not Seen[Entry.Name] then
                Seen[Entry.Name] = true
                table.insert(Refs, Entry.Name)
            end
        end

        local Clean = string.gsub(Text, "%[%[tab:(.-)%]%]", "%1")

        if #Refs == 0 then
            local Lower = string.lower(Clean)
            for _, Entry in ipairs(TabRegistry) do
                local Name = string.lower(Entry.Name)
                if #Name >= 3 and string.find(Lower, Name, 1, true) and not Seen[Entry.Name] then
                    Seen[Entry.Name] = true
                    table.insert(Refs, Entry.Name)
                end
                if #Refs >= 3 then
                    break
                end
            end
        end

        while #Refs > 3 do
            table.remove(Refs)
        end

        return Trim(Clean), Refs
    end

    local function GroqKey()
        if type(groqapi) == "string" and Trim(groqapi) ~= "" then
            return Trim(groqapi)
        end
        return Trim(GetGlobal("groqapi"))
    end

    local function SetBusy(State)
        Thinking = State
        Library:TweenInstance(AISend, 0.2, "BackgroundTransparency", State and 0.55 or 0.05)
        Library:TweenInstance(AISendIcon, 0.2, "ImageTransparency", State and 0.5 or 0)
        Library:TweenInstance(AIStatusDot, 0.2, "BackgroundColor3", State and Color3.fromRGB(255, 198, 88) or Color3.fromRGB(70, 220, 130))
    end

    local function AskGroq(Question)
        if Thinking then
            return
        end

        AddBubble("user", Question)
        table.insert(ChatHistory, { role = "user", content = Question })

        local Key = GroqKey()
        if Key == "" then
            AddBubble("assistant", "No Groq key loaded. Fill groqapi at the top of the library, or pass GroqApiKey to NewWindow.")
            return
        end

        local Request = GetRequestFunction()
        if not Request then
            AddBubble("assistant", "This executor exposes no HTTP request function, so Groq cannot be reached from here.")
            return
        end

        SetBusy(true)
        ShowTyping()

        task.spawn(function()
            local Messages = { { role = "system", content = BuildSystemPrompt() } }
            local StartIndex = math.max(1, #ChatHistory - 9)
            for Index = StartIndex, #ChatHistory do
                table.insert(Messages, ChatHistory[Index])
            end

            local Payload = HttpService:JSONEncode({
                model = Library.GroqModel,
                messages = Messages,
                temperature = 0.5,
                max_tokens = 600,
                stream = false
            })

            local Ok, Response = pcall(Request, {
                Url = Library.GroqEndpoint,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer " .. Key
                },
                Body = Payload
            })

            HideTyping()
            SetBusy(false)

            if not Ok or type(Response) ~= "table" then
                AddBubble("assistant", "Request failed: " .. tostring(Response))
                return
            end

            local Body = Response.Body or Response.body or ""
            local Status = Response.StatusCode or Response.Status or 0

            local Decoded
            local DecodedOk = pcall(function()
                Decoded = HttpService:JSONDecode(Body)
            end)

            if not DecodedOk or type(Decoded) ~= "table" then
                AddBubble("assistant", "Groq returned an unreadable answer (status " .. tostring(Status) .. ").")
                return
            end

            if Decoded.error then
                AddBubble("assistant", "Groq error: " .. tostring(Decoded.error.message or Decoded.error.type or "unknown"))
                return
            end

            local Choice = Decoded.choices and Decoded.choices[1]
            local Content = Choice and Choice.message and Choice.message.content
            if type(Content) ~= "string" or Trim(Content) == "" then
                AddBubble("assistant", "Groq sent an empty answer, try again.")
                return
            end

            table.insert(ChatHistory, { role = "assistant", content = Content })
            if string.find(Content, "```") or string.find(Content, "function%s*%(") or string.find(Content, "function%s+[%w_:%.]+%(") then
                Content = "I can't share code or component snippets here -- ask me which tab has what you need and I'll point you there."
                ChatHistory[#ChatHistory].content = Content
            end
            local Clean, Refs = ExtractRefs(Content)
            AddBubble("assistant", Clean, Refs)
        end)
    end

    local function SendCurrent()
        local Text = Trim(AIInput.Text)
        if Text == "" or Thinking then
            return
        end
        AIInput.Text = ""
        AskGroq(Text)
    end

    AISend.MouseButton1Click:Connect(function()
        Library:Flash(AISend, Color3.fromRGB(255, 255, 255))
        SendCurrent()
    end)

    AIInput.FocusLost:Connect(function(Enter)
        if Enter then
            SendCurrent()
        end
    end)

    local function ResetChat()
        for _, Child in ipairs(AIMessages:GetChildren()) do
            if Child:IsA("Frame") then
                Child:Destroy()
            end
        end
        TypingHolder = nil
        ChatHistory = {}
        MessageOrder = 0
        AddBubble("assistant", "Hey " .. Player.DisplayName .. ", ask me what a feature does or where it lives and I will hand you a button straight to the right tab.")
    end

    AIClearBtn.MouseButton1Click:Connect(ResetChat)

    for Index, Preset in ipairs({ "What can this hub do?", "Where do I find the visuals?", "Explain the first tab" }) do
        MakeChip(AISuggestions, Preset, Library.DefaultIcons.Sparkles, Index, function()
            if not Thinking then
                AskGroq(Preset)
            end
        end)
    end

    ResetChat()

    local AIOpen = false

    ToggleAI = function(Force)
        local Target = Force
        if Target == nil then
            Target = not AIOpen
        end
        AIOpen = Target
        BottomButtons.AI:SetActive(Target)

        if Target then
            -- Hide PlayerCard if open
            if CardOpen and TogglePlayerCard then TogglePlayerCard(false) end
            -- Hide tab content immediately (no race)
            LayoutFrame.Visible = false
            AIWindow.BackgroundTransparency = 0
            AIWindow.Visible = true
            AISubtitle.Text = "Groq - " .. Library.GroqModel
            Library:Pop(AIWindow, 0.28, 0.92)
            ScrollToBottom()
            return
        end
        LayoutFrame.Visible = true

        local Scale = AIWindow:FindFirstChildOfClass("UIScale")
        if Scale then
            Library:Tween(Scale, TweenInfo.new(0.22, Quart, In), { Scale = 0.92 })
        end
        Library:TweenInstance(AIWindow, 0.2, "BackgroundTransparency", 1, function()
            if not AIOpen then
                AIWindow.Visible = false
                LayoutFrame.Visible = true
            end
        end)
    end

    AICloseBtn.MouseButton1Click:Connect(function()
        ToggleAI(false)
    end)

    local HardwareId = GetHardwareId()
    local ExecutorName = GetExecutorName()
    local CurrentFps = 60
    local FrameCount = 0
    local FrameTimer = 0

    RunService.Heartbeat:Connect(function(Step)
        FrameCount = FrameCount + 1
        FrameTimer = FrameTimer + Step
        if FrameTimer >= 1 then
            CurrentFps = math.floor(FrameCount / FrameTimer + 0.5)
            FrameCount = 0
            FrameTimer = 0
        end
    end)

    local function GetPing()
        local Ok, Value = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if Ok and type(Value) == "number" then
            return math.floor(Value + 0.5)
        end
        return 0
    end

    local PlayerCard = Instance.new("Frame")
    PlayerCard.Name = "PlayerCard"
    PlayerCard.Parent = Main
    PlayerCard.AnchorPoint = Vector2.new(0, 0)
    PlayerCard.BackgroundTransparency = 0
    PlayerCard.BorderSizePixel = 0
    PlayerCard.Position = UDim2.new(0, 156, 0, 54)
    PlayerCard.Size = UDim2.new(1, -156, 1, -54)
    PlayerCard.ClipsDescendants = true
    PlayerCard.Visible = false
    PlayerCard.ZIndex = 200
    Library:Themed(PlayerCard, "BackgroundColor3", "Main")
    local PCWindowLine = Instance.new("Frame")
    PCWindowLine.Parent = PlayerCard
    PCWindowLine.BorderSizePixel = 0
    PCWindowLine.Position = UDim2.new(0, 0, 0, 0)
    PCWindowLine.Size = UDim2.new(0, 1, 1, 0)
    PCWindowLine.ZIndex = 201
    Library:Themed(PCWindowLine, "BackgroundColor3", "Stroke")
    Library:Corner(PlayerCard, 16)

    -- Everything scrollable lives in here. The card itself never clips
    -- content away -- if it doesn't fit the visible area, it scrolls.
    local PlayerCardScroll = Instance.new("ScrollingFrame")
    PlayerCardScroll.Name = "PlayerCardScroll"
    PlayerCardScroll.Parent = PlayerCard
    PlayerCardScroll.BackgroundTransparency = 1
    PlayerCardScroll.BorderSizePixel = 0
    PlayerCardScroll.Position = UDim2.new(0, 0, 0, 0)
    PlayerCardScroll.Size = UDim2.new(1, 0, 1, 0)
    PlayerCardScroll.ScrollBarThickness = 3
    PlayerCardScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    PlayerCardScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    local AutoCanvasOk = pcall(function()
        PlayerCardScroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    end)
    PlayerCardScroll.ZIndex = 111
    Library:Themed(PlayerCardScroll, "ScrollBarImageColor3", "Accent")

    local CardBanner = Instance.new("Frame")
    CardBanner.Name = "Banner"
    CardBanner.Parent = PlayerCardScroll
    CardBanner.BackgroundTransparency = 0
    CardBanner.BorderSizePixel = 0
    CardBanner.Size = UDim2.new(1, 0, 0, 96)
    CardBanner.Active = true
    Library:Themed(CardBanner, "BackgroundColor3", "Accent")
    Library:Corner(CardBanner, 16)
    Library:Gradient(CardBanner, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 200))
    }), 90, NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.55, 0.86),
        NumberSequenceKeypoint.new(1, 1)
    }))

    -- Close button is pinned to the card itself (outside the scrolling
    -- frame) so it always stays in the corner no matter the scroll offset.
    local CardClose = Instance.new("TextButton")
    CardClose.Name = "CardClose"
    CardClose.Parent = PlayerCard
    CardClose.AnchorPoint = Vector2.new(1, 0)
    CardClose.BackgroundTransparency = 0.9
    CardClose.BorderSizePixel = 0
    CardClose.Position = UDim2.new(1, -12, 0, 12)
    CardClose.Size = UDim2.new(0, 26, 0, 26)
    CardClose.Text = ""
    CardClose.AutoButtonColor = false
    CardClose.ZIndex = 210
    Library:Themed(CardClose, "BackgroundColor3", "Surface")
    Library:Corner(CardClose, 8)

    local CardCloseIcon = Instance.new("ImageLabel")
    CardCloseIcon.Parent = CardClose
    CardCloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CardCloseIcon.BackgroundTransparency = 1
    CardCloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    CardCloseIcon.Size = UDim2.new(0, 14, 0, 14)
    CardCloseIcon.ZIndex = 211
    Library:SetIcon(CardCloseIcon, Library.DefaultIcons.Close, Library.Theme.Text)

    Library:Hover(CardClose, CardClose, "BackgroundTransparency", 0.9, 0.72)

    local AvatarRing = Instance.new("Frame")
    AvatarRing.Name = "AvatarRing"
    AvatarRing.Parent = PlayerCardScroll
    AvatarRing.BackgroundTransparency = 0
    AvatarRing.BorderSizePixel = 0
    AvatarRing.Position = UDim2.new(0, 14, 0, 44)
    AvatarRing.Size = UDim2.new(0, 74, 0, 74)
    AvatarRing.ZIndex = 111
    Library:Themed(AvatarRing, "BackgroundColor3", "Accent")
    Library:Corner(AvatarRing, UDim.new(1, 0))

    local RingGradient = Library:Gradient(AvatarRing, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 120, 140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    }), 0)

    Library:Tween(RingGradient, TweenInfo.new(7, Enum.EasingStyle.Linear, Out, -1), { Rotation = 360 })

    local AvatarHolder = Instance.new("Frame")
    AvatarHolder.Name = "AvatarHolder"
    AvatarHolder.Parent = AvatarRing
    AvatarHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    AvatarHolder.BackgroundTransparency = 0
    AvatarHolder.BorderSizePixel = 0
    AvatarHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    AvatarHolder.Size = UDim2.new(0, 66, 0, 66)
    AvatarHolder.ZIndex = 112
    Library:Themed(AvatarHolder, "BackgroundColor3", "Elevated")
    Library:Corner(AvatarHolder, UDim.new(1, 0))

    local Avatar = Instance.new("ImageLabel")
    Avatar.Name = "Avatar"
    Avatar.Parent = AvatarHolder
    Avatar.AnchorPoint = Vector2.new(0.5, 0.5)
    Avatar.BackgroundTransparency = 1
    Avatar.BorderSizePixel = 0
    Avatar.Position = UDim2.new(0.5, 0, 0.5, 0)
    Avatar.Size = UDim2.new(0, 62, 0, 62)
    Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Player.UserId) .. "&w=150&h=150"
    Avatar.ZIndex = 113
    Library:Corner(Avatar, UDim.new(1, 0))

    local StatusDot = Instance.new("Frame")
    StatusDot.Name = "StatusDot"
    StatusDot.Parent = AvatarRing
    StatusDot.AnchorPoint = Vector2.new(1, 1)
    StatusDot.BackgroundColor3 = Color3.fromRGB(70, 220, 130)
    StatusDot.BorderSizePixel = 0
    StatusDot.Position = UDim2.new(1, -4, 1, -4)
    StatusDot.Size = UDim2.new(0, 14, 0, 14)
    StatusDot.ZIndex = 114
    Library:Corner(StatusDot, UDim.new(1, 0))
    local StatusRing = Library:Stroke(StatusDot, Library.Theme.Main, 0, 3)
    Library:Themed(StatusRing, "Color", "Main")

    task.spawn(function()
        while StatusDot.Parent do
            Library:Tween(StatusDot, TweenInfo.new(1, Quart, Out), { BackgroundTransparency = 0.45 })
            task.wait(1)
            Library:Tween(StatusDot, TweenInfo.new(1, Quart, Out), { BackgroundTransparency = 0 })
            task.wait(1)
        end
    end)

    local DisplayLabel = Instance.new("TextLabel")
    DisplayLabel.Name = "DisplayName"
    DisplayLabel.Parent = PlayerCardScroll
    DisplayLabel.BackgroundTransparency = 1
    DisplayLabel.Position = UDim2.new(0, 98, 0, 46)
    DisplayLabel.Size = UDim2.new(1, -140, 0, 22)
    DisplayLabel.Font = Enum.Font.GothamBold
    DisplayLabel.Text = Player.DisplayName
    DisplayLabel.TextSize = 17
    DisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DisplayLabel.TextTruncate = Enum.TextTruncate.AtEnd
    DisplayLabel.ZIndex = 112
    Library:Themed(DisplayLabel, "TextColor3", "Text")

    local UserLabel = Instance.new("TextLabel")
    UserLabel.Name = "Username"
    UserLabel.Parent = PlayerCardScroll
    UserLabel.BackgroundTransparency = 1
    UserLabel.Position = UDim2.new(0, 98, 0, 68)
    UserLabel.Size = UDim2.new(1, -140, 0, 16)
    UserLabel.Font = Enum.Font.GothamMedium
    UserLabel.Text = "@" .. Player.Name
    UserLabel.TextSize = 12
    UserLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserLabel.TextTruncate = Enum.TextTruncate.AtEnd
    UserLabel.ZIndex = 112
    Library:Themed(UserLabel, "TextColor3", "TextDisabled")

    local PremiumPill = Instance.new("Frame")
    PremiumPill.Name = "Pill"
    PremiumPill.Parent = PlayerCardScroll
    PremiumPill.AutomaticSize = Enum.AutomaticSize.X
    PremiumPill.BackgroundTransparency = 0.86
    PremiumPill.BorderSizePixel = 0
    PremiumPill.Position = UDim2.new(0, 98, 0, 90)
    PremiumPill.Size = UDim2.new(0, 0, 0, 20)
    PremiumPill.ZIndex = 112
    Library:Themed(PremiumPill, "BackgroundColor3", "Accent")
    Library:Corner(PremiumPill, 6)
    local PillStroke = Library:Stroke(PremiumPill, Library.Theme.Accent, 0.6, 1)
    Library:Themed(PillStroke, "Color", "Accent")
    Library:Padding(PremiumPill, 0, 0, 8, 8)

    local PremiumText = Instance.new("TextLabel")
    PremiumText.Parent = PremiumPill
    PremiumText.AutomaticSize = Enum.AutomaticSize.X
    PremiumText.BackgroundTransparency = 1
    PremiumText.Size = UDim2.new(0, 0, 1, 0)
    PremiumText.Font = Enum.Font.GothamBold
    PremiumText.Text = Player.MembershipType == Enum.MembershipType.Premium and "PREMIUM" or "STANDARD"
    PremiumText.TextSize = 10
    PremiumText.ZIndex = 113
    Library:Themed(PremiumText, "TextColor3", "Text")

    local CardDivider = Instance.new("Frame")
    CardDivider.Parent = PlayerCardScroll
    CardDivider.BorderSizePixel = 0
    CardDivider.Position = UDim2.new(0, 14, 0, 126)
    CardDivider.Size = UDim2.new(1, -32, 0, 1)
    CardDivider.ZIndex = 112
    Library:Themed(CardDivider, "BackgroundColor3", "Accent")
    Library:FadeLine(CardDivider, Library.Theme.Accent, true)

    -- Uptime / HWID / stats / footer auto-stack vertically so they can
    -- never overlap each other, however many stat rows end up rendered.
    local StatsStack = Instance.new("Frame")
    StatsStack.Name = "StatsStack"
    StatsStack.Parent = PlayerCardScroll
    StatsStack.BackgroundTransparency = 1
    StatsStack.Position = UDim2.new(0, 14, 0, 136)
    StatsStack.Size = UDim2.new(1, -28, 0, 0)
    StatsStack.AutomaticSize = Enum.AutomaticSize.Y

    local StatsStackList = Instance.new("UIListLayout")
    StatsStackList.Parent = StatsStack
    StatsStackList.SortOrder = Enum.SortOrder.LayoutOrder
    StatsStackList.Padding = UDim.new(0, 10)

    if not AutoCanvasOk then
        local function RecalcCardCanvas()
            PlayerCardScroll.CanvasSize = UDim2.new(0, 0, 0, StatsStack.Position.Y.Offset + StatsStack.AbsoluteSize.Y + 24)
        end
        StatsStack:GetPropertyChangedSignal("AbsoluteSize"):Connect(RecalcCardCanvas)
        task.defer(RecalcCardCanvas)
    end

    local UptimeTile = Instance.new("Frame")
    UptimeTile.Name = "UptimeTile"
    UptimeTile.Parent = StatsStack
    UptimeTile.LayoutOrder = 1
    UptimeTile.BackgroundTransparency = 0.94
    UptimeTile.BorderSizePixel = 0
    UptimeTile.Size = UDim2.new(1, 0, 0, 62)
    UptimeTile.ZIndex = 112
    Library:Themed(UptimeTile, "BackgroundColor3", "Surface")
    Library:Corner(UptimeTile, 12)
    Library:Stroke(UptimeTile, Library.Theme.Stroke, 0.9, 1)

    local UptimeIcon = Instance.new("ImageLabel")
    UptimeIcon.Parent = UptimeTile
    UptimeIcon.AnchorPoint = Vector2.new(0, 0.5)
    UptimeIcon.BackgroundTransparency = 1
    UptimeIcon.Position = UDim2.new(0, 14, 0.5, 0)
    UptimeIcon.Size = UDim2.new(0, 20, 0, 20)
    UptimeIcon.ZIndex = 113
    Library:SetIcon(UptimeIcon, Library.DefaultIcons.Clock, Library.Theme.Accent)
    Library:Themed(UptimeIcon, "ImageColor3", "Accent")

    local UptimeCaption = Instance.new("TextLabel")
    UptimeCaption.Parent = UptimeTile
    UptimeCaption.BackgroundTransparency = 1
    UptimeCaption.Position = UDim2.new(0, 44, 0, 12)
    UptimeCaption.Size = UDim2.new(0, 140, 0, 14)
    UptimeCaption.Font = Enum.Font.GothamBold
    UptimeCaption.Text = "TIME LIVE"
    UptimeCaption.TextSize = 10
    UptimeCaption.TextXAlignment = Enum.TextXAlignment.Left
    UptimeCaption.ZIndex = 113
    Library:Themed(UptimeCaption, "TextColor3", "TextDisabled")

    local UptimeSub = Instance.new("TextLabel")
    UptimeSub.Parent = UptimeTile
    UptimeSub.BackgroundTransparency = 1
    UptimeSub.Position = UDim2.new(0, 44, 0, 30)
    UptimeSub.Size = UDim2.new(0, 160, 0, 18)
    UptimeSub.Font = Enum.Font.GothamMedium
    UptimeSub.Text = "session running"
    UptimeSub.TextSize = 11
    UptimeSub.TextXAlignment = Enum.TextXAlignment.Left
    UptimeSub.ZIndex = 113
    Library:Themed(UptimeSub, "TextColor3", "TextDisabled")

    local UptimeValue = Instance.new("TextLabel")
    UptimeValue.Parent = UptimeTile
    UptimeValue.AnchorPoint = Vector2.new(1, 0.5)
    UptimeValue.BackgroundTransparency = 1
    UptimeValue.Position = UDim2.new(1, -14, 0.5, 0)
    UptimeValue.Size = UDim2.new(0, 120, 0, 28)
    UptimeValue.Font = Enum.Font.GothamBold
    UptimeValue.Text = "00:00"
    UptimeValue.TextSize = 22
    UptimeValue.TextXAlignment = Enum.TextXAlignment.Right
    UptimeValue.ZIndex = 113
    Library:Themed(UptimeValue, "TextColor3", "Text")

    local HwidTile = Instance.new("Frame")
    HwidTile.Name = "HwidTile"
    HwidTile.Parent = StatsStack
    HwidTile.LayoutOrder = 2
    HwidTile.BackgroundTransparency = 0.94
    HwidTile.BorderSizePixel = 0
    HwidTile.Size = UDim2.new(1, 0, 0, 48)
    HwidTile.ZIndex = 112
    Library:Themed(HwidTile, "BackgroundColor3", "Surface")
    Library:Corner(HwidTile, 12)
    Library:Stroke(HwidTile, Library.Theme.Stroke, 0.9, 1)

    local HwidIcon = Instance.new("ImageLabel")
    HwidIcon.Parent = HwidTile
    HwidIcon.AnchorPoint = Vector2.new(0, 0.5)
    HwidIcon.BackgroundTransparency = 1
    HwidIcon.Position = UDim2.new(0, 14, 0.5, 0)
    HwidIcon.Size = UDim2.new(0, 18, 0, 18)
    HwidIcon.ZIndex = 113
    Library:SetIcon(HwidIcon, Library.DefaultIcons.Finger, Library.Theme.Accent)
    Library:Themed(HwidIcon, "ImageColor3", "Accent")

    local HwidCaption = Instance.new("TextLabel")
    HwidCaption.Parent = HwidTile
    HwidCaption.BackgroundTransparency = 1
    HwidCaption.Position = UDim2.new(0, 42, 0, 8)
    HwidCaption.Size = UDim2.new(0, 120, 0, 13)
    HwidCaption.Font = Enum.Font.GothamBold
    HwidCaption.Text = "HWID"
    HwidCaption.TextSize = 10
    HwidCaption.TextXAlignment = Enum.TextXAlignment.Left
    HwidCaption.ZIndex = 113
    Library:Themed(HwidCaption, "TextColor3", "TextDisabled")

    local HwidValue = Instance.new("TextLabel")
    HwidValue.Parent = HwidTile
    HwidValue.BackgroundTransparency = 1
    HwidValue.Position = UDim2.new(0, 42, 0, 22)
    HwidValue.Size = UDim2.new(1, -90, 0, 18)
    HwidValue.Font = Enum.Font.Code
    HwidValue.Text = ShortHardwareId(HardwareId)
    HwidValue.TextSize = 12
    HwidValue.TextXAlignment = Enum.TextXAlignment.Left
    HwidValue.TextTruncate = Enum.TextTruncate.AtEnd
    HwidValue.ZIndex = 113
    Library:Themed(HwidValue, "TextColor3", "Text")

    local HwidCopy = Instance.new("TextButton")
    HwidCopy.Parent = HwidTile
    HwidCopy.AnchorPoint = Vector2.new(1, 0.5)
    HwidCopy.BackgroundTransparency = 0.88
    HwidCopy.BorderSizePixel = 0
    HwidCopy.Position = UDim2.new(1, -10, 0.5, 0)
    HwidCopy.Size = UDim2.new(0, 30, 0, 28)
    HwidCopy.Text = ""
    HwidCopy.AutoButtonColor = false
    HwidCopy.ZIndex = 113
    Library:Themed(HwidCopy, "BackgroundColor3", "Surface")
    Library:Corner(HwidCopy, 8)

    local HwidCopyIcon = Instance.new("ImageLabel")
    HwidCopyIcon.Parent = HwidCopy
    HwidCopyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    HwidCopyIcon.BackgroundTransparency = 1
    HwidCopyIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    HwidCopyIcon.Size = UDim2.new(0, 14, 0, 14)
    HwidCopyIcon.ZIndex = 114
    Library:SetIcon(HwidCopyIcon, Library.DefaultIcons.Copy, Library.Theme.TextDisabled)

    Library:Hover(HwidCopy, HwidCopy, "BackgroundTransparency", 0.88, 0.72)

    HwidCopy.MouseButton1Click:Connect(function()
        local Copied = false
        if setclipboard then
            Copied = pcall(setclipboard, HardwareId)
        elseif toclipboard then
            Copied = pcall(toclipboard, HardwareId)
        end
        Library:Flash(HwidCopy)
        Library:SetIcon(HwidCopyIcon, Copied and Library.DefaultIcons.Check or Library.DefaultIcons.Close, Copied and Color3.fromRGB(70, 220, 130) or Color3.fromRGB(255, 90, 90))
        task.delay(1.4, function()
            Library:SetIcon(HwidCopyIcon, Library.DefaultIcons.Copy, Library.Theme.TextDisabled)
        end)
    end)

    -- Auto-sized (not independently scrolling — the outer PlayerCardScroll
    -- handles scrolling for the whole card now), so it can never overlap
    -- the HWID tile above or the footer below.
    local StatGrid = Instance.new("Frame")
    StatGrid.Name = "StatGrid"
    StatGrid.Parent = StatsStack
    StatGrid.LayoutOrder = 3
    StatGrid.BackgroundTransparency = 1
    StatGrid.BorderSizePixel = 0
    StatGrid.Size = UDim2.new(1, 0, 0, 0)
    StatGrid.AutomaticSize = Enum.AutomaticSize.Y
    StatGrid.ZIndex = 112

    local StatLayout = Instance.new("UIGridLayout")
    StatLayout.Parent = StatGrid
    StatLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    StatLayout.CellSize = UDim2.new(0.5, -5, 0, 51)
    StatLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local StatTiles = {}

    local function MakeStat(Order, IconName, Caption, Value)
        local Tile = Instance.new("Frame")
        Tile.Name = Caption
        Tile.Parent = StatGrid
        Tile.BackgroundTransparency = 0.94
        Tile.BorderSizePixel = 0
        Tile.LayoutOrder = Order
        Tile.ZIndex = 112
        Library:Themed(Tile, "BackgroundColor3", "Surface")
        Library:Corner(Tile, 10)
        local Stroke = Library:Stroke(Tile, Library.Theme.Stroke, 0.9, 1)

        local Icon = Instance.new("ImageLabel")
        Icon.Parent = Tile
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0, 11, 0, 9)
        Icon.Size = UDim2.new(0, 13, 0, 13)
        Icon.ZIndex = 113
        Library:SetIcon(Icon, IconName, Library.Theme.Accent)
        Library:Themed(Icon, "ImageColor3", "Accent")

        local CaptionLabel = Instance.new("TextLabel")
        CaptionLabel.Parent = Tile
        CaptionLabel.BackgroundTransparency = 1
        CaptionLabel.Position = UDim2.new(0, 30, 0, 7)
        CaptionLabel.Size = UDim2.new(1, -40, 0, 16)
        CaptionLabel.Font = Enum.Font.GothamBold
        CaptionLabel.Text = Caption
        CaptionLabel.TextSize = 10
        CaptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        CaptionLabel.ZIndex = 113
        Library:Themed(CaptionLabel, "TextColor3", "TextDisabled")

        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Parent = Tile
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Position = UDim2.new(0, 11, 0, 26)
        ValueLabel.Size = UDim2.new(1, -22, 0, 18)
        ValueLabel.Font = Enum.Font.GothamBold
        ValueLabel.Text = Value
        ValueLabel.TextSize = 13
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
        ValueLabel.TextTruncate = Enum.TextTruncate.AtEnd
        ValueLabel.ZIndex = 113
        Library:Themed(ValueLabel, "TextColor3", "Text")

        Tile.MouseEnter:Connect(function()
            Library:TweenInstance(Tile, 0.18, "BackgroundTransparency", 0.88)
            Library:TweenInstance(Stroke, 0.18, "Transparency", 0.55)
            Library:TweenInstance(Stroke, 0.18, "Color", Library.Theme.Accent)
        end)

        Tile.MouseLeave:Connect(function()
            Library:TweenInstance(Tile, 0.18, "BackgroundTransparency", 0.94)
            Library:TweenInstance(Stroke, 0.18, "Transparency", 0.9)
            Library:TweenInstance(Stroke, 0.18, "Color", Library.Theme.Stroke)
        end)

        local TileScale = Instance.new("UIScale")
        TileScale.Parent = Tile

        local Data = { Tile = Tile, Label = ValueLabel, Scale = TileScale }

        function Data:Set(NewValue)
            if ValueLabel.Text == NewValue then
                return
            end
            ValueLabel.Text = NewValue
        end

        table.insert(StatTiles, Data)
        return Data
    end

    local UserIdStat = MakeStat(1, "hash", "USER ID", tostring(Player.UserId))
    local AgeStat = MakeStat(2, Library.DefaultIcons.Cake, "ACCOUNT AGE", tostring(Player.AccountAge) .. " days")
    local FpsStat = MakeStat(3, Library.DefaultIcons.Gauge, "FPS", "60")
    local PingStat = MakeStat(4, Library.DefaultIcons.Signal, "PING", "0 ms")
    local ExecutorStat = MakeStat(5, Library.DefaultIcons.Cpu, "EXECUTOR", ExecutorName)
    local PlaceStat = MakeStat(6, Library.DefaultIcons.Pad, "PLACE ID", tostring(game.PlaceId))

    local FooterDivider = Instance.new("Frame")
    FooterDivider.Parent = StatsStack
    FooterDivider.LayoutOrder = 3
    FooterDivider.BorderSizePixel = 0
    FooterDivider.Size = UDim2.new(1, 0, 0, 1)
    FooterDivider.ZIndex = 112
    Library:FadeLine(FooterDivider, Library.Theme.Accent, true)

    local FooterRow = Instance.new("Frame")
    FooterRow.Name = "FooterRow"
    FooterRow.Parent = StatsStack
    FooterRow.LayoutOrder = 4
    FooterRow.BackgroundTransparency = 1
    FooterRow.Size = UDim2.new(1, 0, 0, 30)
    FooterRow.ZIndex = 112

    local CardFooter = Instance.new("TextLabel")
    CardFooter.Parent = FooterRow
    CardFooter.BackgroundTransparency = 1
    CardFooter.Position = UDim2.new(0, 0, 0, 6)
    CardFooter.Size = UDim2.new(1, -40, 0, 18)
    CardFooter.Font = Enum.Font.GothamMedium
    CardFooter.Text = ConfigWindow.Title
    CardFooter.TextSize = 11
    CardFooter.TextXAlignment = Enum.TextXAlignment.Left
    CardFooter.TextTruncate = Enum.TextTruncate.AtEnd
    CardFooter.ZIndex = 112
    Library:Themed(CardFooter, "TextColor3", "TextDisabled")

    local CardRefresh = Instance.new("TextButton")
    CardRefresh.Parent = FooterRow
    CardRefresh.AnchorPoint = Vector2.new(1, 0.5)
    CardRefresh.BackgroundTransparency = 0.9
    CardRefresh.BorderSizePixel = 0
    CardRefresh.Position = UDim2.new(1, 0, 0.5, 0)
    CardRefresh.Size = UDim2.new(0, 28, 0, 26)
    CardRefresh.Text = ""
    CardRefresh.AutoButtonColor = false
    CardRefresh.ZIndex = 112
    Library:Themed(CardRefresh, "BackgroundColor3", "Surface")
    Library:Corner(CardRefresh, 8)

    local CardRefreshIcon = Instance.new("ImageLabel")
    CardRefreshIcon.Parent = CardRefresh
    CardRefreshIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CardRefreshIcon.BackgroundTransparency = 1
    CardRefreshIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    CardRefreshIcon.Size = UDim2.new(0, 13, 0, 13)
    CardRefreshIcon.ZIndex = 113
    Library:SetIcon(CardRefreshIcon, Library.DefaultIcons.Refresh, Library.Theme.TextDisabled)

    Library:Hover(CardRefresh, CardRefresh, "BackgroundTransparency", 0.9, 0.74)

    -- PlayerCard moves with main window (attached)

    local CardOpen = false

    local function UpdateLive()
        UptimeValue.Text = FormatClock(os.time() - SessionStart)
        FpsStat:Set(tostring(CurrentFps))
        PingStat:Set(tostring(GetPing()) .. " ms")
        AgeStat:Set(tostring(Player.AccountAge) .. " days")
    end

    CardRefresh.MouseButton1Click:Connect(function()
        HardwareId = GetHardwareId()
        HwidValue.Text = ShortHardwareId(HardwareId)
        ExecutorStat:Set(GetExecutorName())
        Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Player.UserId) .. "&w=150&h=150"
        UpdateLive()
        Library:Flash(CardRefresh)
        CardRefreshIcon.Rotation = 0
        Library:Tween(CardRefreshIcon, TweenInfo.new(0.6, Quart, Out), { Rotation = 360 })
    end)

    task.spawn(function()
        while ScreenGui.Parent do
            task.wait(1)
            if CardOpen then
                UpdateLive()
            end
        end
    end)

    TogglePlayerCard = function(Force)
        local Target = Force
        if Target == nil then
            Target = not CardOpen
        end
        CardOpen = Target
        BottomButtons.PlayerCard:SetActive(Target)

        if Target then
            -- Hide AI if open
            if AIOpen and ToggleAI then ToggleAI(false) end
            -- Hide tab content immediately (no race)
            LayoutFrame.Visible = false
            UpdateLive()
            PlayerCard.BackgroundTransparency = 0
            PlayerCard.Visible = true
            Library:Pop(PlayerCard, 0.28, 0.92)

            for Index, Data in ipairs(StatTiles) do
                Data.Tile.BackgroundTransparency = 1
                Data.Label.TextTransparency = 1
                Data.Scale.Scale = 0.86
                task.delay(0.06 + Index * 0.04, function()
                    Library:Tween(Data.Scale, TweenInfo.new(0.42, Back, Out), { Scale = 1 })
                    Library:TweenInstance(Data.Tile, 0.42, "BackgroundTransparency", 0.94)
                    Library:TweenInstance(Data.Label, 0.42, "TextTransparency", 0)
                end)
            end
            return
        end

        local Scale = PlayerCard:FindFirstChildOfClass("UIScale")
        if Scale then
            Library:Tween(Scale, TweenInfo.new(0.22, Quart, In), { Scale = 0.9 })
        end
        Library:TweenInstance(PlayerCard, 0.2, "BackgroundTransparency", 1, function()
            if not CardOpen then
                PlayerCard.Visible = false
                LayoutFrame.Visible = true
            end
        end)
    end

    CardClose.MouseButton1Click:Connect(function()
        TogglePlayerCard(false)
    end)

    local AllLayouts = 0
    local Tab = {}

    function Tab:T(nameOrConfig, iconName)
        local name, Locked, LockPassword, LockTitle, LockDesc, RememberKey
        if type(nameOrConfig) == "table" then
            name = nameOrConfig.Title or nameOrConfig.Name or "Tab"
            iconName = nameOrConfig.Icon or iconName or Library.DefaultIcons.Tab
            Locked = nameOrConfig.Locked or false
            LockPassword = nameOrConfig.LockPassword
            LockTitle = nameOrConfig.LockTitle or "Private Tab"
            LockDesc = nameOrConfig.LockDesc or "Enter the password to unlock"
            RememberKey = nameOrConfig.RememberKey or ("sh1ttybanana_lock_" .. name)
        else
            name = nameOrConfig or "Tab"
            iconName = iconName or Library.DefaultIcons.Tab
            Locked = false
        end

        local Unlocked = not Locked
        if Locked and LockPassword and writefile and isfile and readfile then
            pcall(function()
                if isfile(RememberKey) and readfile(RememberKey) == tostring(LockPassword) then
                    Unlocked = true
                end
            end)
        end

        local TabDisable = Instance.new("Frame")
        TabDisable.Name = "TabDisable"
        TabDisable.Parent = ScrollingTab
        TabDisable.BackgroundTransparency = 1
        TabDisable.BorderSizePixel = 0
        TabDisable.Size = UDim2.new(1, 0, 0, 36)
        TabDisable.LayoutOrder = AllLayouts + 1
        Library:Themed(TabDisable, "BackgroundColor3", "Accent")
        Library:Corner(TabDisable, 8)

        local TabScale = Instance.new("UIScale")
        TabScale.Parent = TabDisable

        local Choose_2 = Instance.new("Frame")
        Choose_2.Name = "Choose"
        Choose_2.Parent = TabDisable
        Choose_2.AnchorPoint = Vector2.new(0, 0.5)
        Choose_2.BorderSizePixel = 0
        Choose_2.Position = UDim2.new(0, 0, 0.5, 0)
        Choose_2.Size = UDim2.new(0, 3, 0, 0)
        Library:Themed(Choose_2, "BackgroundColor3", "Accent")
        Library:Corner(Choose_2, UDim.new(1, 0))

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Name = "TabIcon"
        TabIcon.Parent = TabDisable
        TabIcon.AnchorPoint = Vector2.new(0, 0.5)
        TabIcon.BackgroundTransparency = 1
        TabIcon.BorderSizePixel = 0
        TabIcon.Position = UDim2.new(0, 11, 0.5, 0)
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        TabIcon.ImageTransparency = 0.35
        Library:SetIcon(TabIcon, Locked and not Unlocked and Library.DefaultIcons.Lock or iconName, Library.Theme.Accent)
        Library:Themed(TabIcon, "ImageColor3", "Accent")

        local NameTab_2 = Instance.new("TextLabel")
        NameTab_2.Name = "NameTab"
        NameTab_2.Parent = TabDisable
        NameTab_2.BackgroundTransparency = 1
        NameTab_2.BorderSizePixel = 0
        NameTab_2.Position = UDim2.new(0, 34, 0, 0)
        NameTab_2.Size = UDim2.new(1, -56, 1, 0)
        NameTab_2.Font = Enum.Font.GothamBold
        NameTab_2.Text = name
        NameTab_2.TextSize = 12
        NameTab_2.TextTransparency = 0.4
        NameTab_2.TextXAlignment = Enum.TextXAlignment.Left
        NameTab_2.TextTruncate = Enum.TextTruncate.AtEnd
        NameTab_2:SetAttribute("RawName", name)
        Library:Themed(NameTab_2, "TextColor3", "Text")

        local Click_Tab_2 = Instance.new("TextButton")
        Click_Tab_2.Name = "Click_Tab"
        Click_Tab_2.Parent = TabDisable
        Click_Tab_2.BackgroundTransparency = 1
        Click_Tab_2.BorderSizePixel = 0
        Click_Tab_2.Size = UDim2.new(1, 0, 1, 0)
        Click_Tab_2.Text = ""
        Click_Tab_2.AutoButtonColor = false
        Click_Tab_2.ZIndex = 2

        local DragHandle = Instance.new("ImageButton")
        DragHandle.Name = "DragHandle"
        DragHandle.Parent = TabDisable
        DragHandle.AnchorPoint = Vector2.new(1, 0.5)
        DragHandle.BackgroundTransparency = 1
        DragHandle.Image = ""
        DragHandle.Position = UDim2.new(1, -4, 0.5, 0)
        DragHandle.Size = UDim2.new(0, 24, 1, -4)
        DragHandle.AutoButtonColor = false
        DragHandle.Visible = false
        DragHandle.ZIndex = 4

        local DragIcon = Instance.new("ImageLabel")
        DragIcon.Name = "DragIcon"
        DragIcon.Parent = DragHandle
        DragIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        DragIcon.BackgroundTransparency = 1
        DragIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
        DragIcon.Size = UDim2.new(0, 14, 0, 14)
        DragIcon.ImageTransparency = 0.15
        DragIcon.Visible = false
        DragIcon.ZIndex = 5
        Library:SetIcon(DragIcon, Library.DefaultIcons.Grip, Library.Theme.TextDisabled)

        local Selected = false
        local Dragging = false
        local DragAnchorY = 0

        local function BaseTransparency()
            return Selected and 0.9 or 1
        end

        local function SiblingList()
            local Parent = TabDisable.Parent
            local List = {}
            if not Parent then
                return List
            end
            for _, Child in ipairs(Parent:GetChildren()) do
                if Child:IsA("Frame") and Child.Name == "TabDisable" and Child.Visible then
                    table.insert(List, Child)
                end
            end
            table.sort(List, function(A, B)
                if A.LayoutOrder == B.LayoutOrder then
                    return A.AbsolutePosition.Y < B.AbsolutePosition.Y
                end
                return A.LayoutOrder < B.LayoutOrder
            end)
            return List
        end

        DragHandle.InputBegan:Connect(function(Input)
            if not ReorderMode then
                return
            end
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            Dragging = true
            DragAnchorY = Input.Position.Y
            TabDisable.ZIndex = 6
            Library:TweenInstance(TabDisable, 0.15, "BackgroundTransparency", 0.8)
            Library:Tween(TabScale, TweenInfo.new(0.15, Quart, Out), { Scale = 1.04 })
        end)

        UserInputService.InputEnded:Connect(function(Input)
            if not Dragging then
                return
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
                TabDisable.ZIndex = 1
                Library:TweenInstance(TabDisable, 0.2, "BackgroundTransparency", BaseTransparency())
                Library:Tween(TabScale, TweenInfo.new(0.22, Back, Out), { Scale = 1 })
            end
        end)

        UserInputService.InputChanged:Connect(function(Input)
            if not Dragging then
                return
            end
            if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local Step = TabDisable.AbsoluteSize.Y + 3
            if Step <= 1 then
                return
            end

            local Delta = Input.Position.Y - DragAnchorY
            local Shift = 0
            if Delta >= Step then
                Shift = math.floor(Delta / Step)
            elseif Delta <= -Step then
                Shift = -math.floor(-Delta / Step)
            end
            if Shift == 0 then
                return
            end

            local List = SiblingList()
            if #List < 2 then
                return
            end

            local MyIndex
            for Index, Item in ipairs(List) do
                if Item == TabDisable then
                    MyIndex = Index
                    break
                end
            end
            if not MyIndex then
                return
            end

            local Target = math.clamp(MyIndex + Shift, 1, #List)
            if Target == MyIndex then
                return
            end

            DragAnchorY = DragAnchorY + (Target - MyIndex) * Step
            table.remove(List, MyIndex)
            table.insert(List, Target, TabDisable)
            for Index, Item in ipairs(List) do
                Item.LayoutOrder = Index
            end
        end)

        Click_Tab_2.MouseEnter:Connect(function()
            if Selected or Dragging then
                return
            end
            Library:TweenInstance(TabDisable, 0.16, "BackgroundTransparency", 0.94)
            Library:TweenInstance(NameTab_2, 0.16, "TextTransparency", 0.15)
            Library:TweenInstance(TabIcon, 0.16, "ImageTransparency", 0.1)
        end)

        Click_Tab_2.MouseLeave:Connect(function()
            if Selected or Dragging then
                return
            end
            Library:TweenInstance(TabDisable, 0.16, "BackgroundTransparency", 1)
            Library:TweenInstance(NameTab_2, 0.16, "TextTransparency", 0.4)
            Library:TweenInstance(TabIcon, 0.16, "ImageTransparency", 0.35)
        end)

        local Layout = Instance.new("ScrollingFrame")
        Layout.Name = "Layout"
        Layout.Parent = LayoutList
        Layout.BackgroundTransparency = 1
        Layout.BorderSizePixel = 0
        Layout.Selectable = false
        Layout.Size = UDim2.new(1, 0, 1, 0)
        Layout.CanvasSize = UDim2.new(0, 0, 1, 0)
        Layout.LayoutOrder = AllLayouts
        Library:StyleScroll(Layout)

        local UIPadding_3 = Instance.new("UIPadding")
        UIPadding_3.Parent = Layout
        UIPadding_3.PaddingBottom = UDim.new(0, 10)
        UIPadding_3.PaddingLeft = UDim.new(0, 12)
        UIPadding_3.PaddingRight = UDim.new(0, 10)
        UIPadding_3.PaddingTop = UDim.new(0, 2)

        local UIListLayout_3 = Instance.new("UIListLayout")
        UIListLayout_3.Parent = Layout
        UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_3.Padding = UDim.new(0, 12)
        Library:UpdateScrolling(Layout, UIListLayout_3)

        local function SetSelectedVisual(State)
            Selected = State
            if State then
                Library:TweenInstance(TabDisable, 0.24, "BackgroundTransparency", 0.9)
                Library:TweenInstance(NameTab_2, 0.24, "TextTransparency", 0)
                Library:TweenInstance(TabIcon, 0.24, "ImageTransparency", 0)
                Library:Tween(Choose_2, TweenInfo.new(0.28, Back, Out), { Size = UDim2.new(0, 3, 0, 18) })
            else
                Library:TweenInstance(TabDisable, 0.24, "BackgroundTransparency", 1)
                Library:TweenInstance(NameTab_2, 0.24, "TextTransparency", 0.4)
                Library:TweenInstance(TabIcon, 0.24, "ImageTransparency", 0.35)
                Library:Tween(Choose_2, TweenInfo.new(0.2, Quart, Out), { Size = UDim2.new(0, 3, 0, 0) })
            end
        end

        local function SelectThisTab()
            for _, Entry in ipairs(TabRegistry) do
                if Entry.SetSelected then
                    Entry.SetSelected(false)
                end
            end
            SetSelectedVisual(true)
            TextLabel.Text = name
            Library:SetIcon(CrumbIcon, iconName, Library.Theme.Accent)
            TextLabel.TextTransparency = 1
            CrumbIcon.ImageTransparency = 1
            Library:TweenInstance(TextLabel, 0.3, "TextTransparency", 0)
            Library:TweenInstance(CrumbIcon, 0.3, "ImageTransparency", 0)
            UIPageLayout:JumpTo(Layout)
        end

        table.insert(TabElements, { Frame = TabDisable, DragHandle = DragHandle, DragIcon = DragIcon, Name = name })
        table.insert(TabRegistry, {
            Name = name,
            Frame = TabDisable,
            Label = NameTab_2,
            Icon = iconName,
            Page = Layout,
            Select = function()
                SelectThisTab()
            end,
            SetSelected = SetSelectedVisual
        })
        local RegEntry = TabRegistry[#TabRegistry]

        if AllLayouts == 0 and Unlocked then
            SetSelectedVisual(true)
            TextLabel.Text = name
            Library:SetIcon(CrumbIcon, iconName, Library.Theme.Accent)
            UIPageLayout:JumpTo(Layout)
        end

        local function ShowLockPopup()
            ShowModal(function(Popup, ClosePopup)
                Popup.Size = UDim2.new(0, 340, 0, 226)

                local LockIcon = Instance.new("ImageLabel")
                LockIcon.Parent = Popup
                LockIcon.BackgroundTransparency = 1
                LockIcon.Position = UDim2.new(0, 20, 0, 18)
                LockIcon.Size = UDim2.new(0, 20, 0, 20)
                LockIcon.ZIndex = 26
                Library:SetIcon(LockIcon, Library.DefaultIcons.Lock, Library.Theme.Accent)

                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Parent = Popup
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Position = UDim2.new(0, 50, 0, 16)
                TitleLbl.Size = UDim2.new(1, -70, 0, 24)
                TitleLbl.Font = Enum.Font.GothamBold
                TitleLbl.Text = LockTitle
                TitleLbl.TextSize = 15
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.ZIndex = 26
                Library:Themed(TitleLbl, "TextColor3", "Text")

                local DescLbl = Instance.new("TextLabel")
                DescLbl.Parent = Popup
                DescLbl.BackgroundTransparency = 1
                DescLbl.Position = UDim2.new(0, 20, 0, 46)
                DescLbl.Size = UDim2.new(1, -40, 0, 20)
                DescLbl.Font = Enum.Font.Gotham
                DescLbl.Text = LockDesc .. ' "' .. name .. '"'
                DescLbl.TextSize = 12
                DescLbl.TextXAlignment = Enum.TextXAlignment.Left
                DescLbl.ZIndex = 26
                Library:Themed(DescLbl, "TextColor3", "TextDisabled")

                local PassFrame = Instance.new("Frame")
                PassFrame.Parent = Popup
                PassFrame.BackgroundTransparency = 0.92
                PassFrame.BorderSizePixel = 0
                PassFrame.Position = UDim2.new(0, 20, 0, 76)
                PassFrame.Size = UDim2.new(1, -40, 0, 36)
                PassFrame.ZIndex = 26
                Library:Themed(PassFrame, "BackgroundColor3", "Surface")
                Library:Corner(PassFrame, 8)
                local PassStroke = Library:Stroke(PassFrame, Library.Theme.Stroke, 0.8, 1)

                local PassBox = Instance.new("TextBox")
                PassBox.Parent = PassFrame
                PassBox.BackgroundTransparency = 1
                PassBox.Position = UDim2.new(0, 12, 0, 0)
                PassBox.Size = UDim2.new(1, -24, 1, 0)
                PassBox.Font = Enum.Font.GothamMedium
                PassBox.PlaceholderText = "Password"
                PassBox.Text = ""
                PassBox.TextSize = 13
                PassBox.TextXAlignment = Enum.TextXAlignment.Left
                PassBox.ClearTextOnFocus = false
                PassBox.ZIndex = 27
                Library:Themed(PassBox, "TextColor3", "Text")
                Library:Themed(PassBox, "PlaceholderColor3", "TextDisabled")

                PassBox.Focused:Connect(function()
                    Library:TweenInstance(PassStroke, 0.2, "Transparency", 0.35)
                    Library:TweenInstance(PassStroke, 0.2, "Color", Library.Theme.Accent)
                end)

                PassBox.FocusLost:Connect(function()
                    Library:TweenInstance(PassStroke, 0.2, "Transparency", 0.8)
                    Library:TweenInstance(PassStroke, 0.2, "Color", Library.Theme.Stroke)
                end)

                local RememberFrame = Instance.new("Frame")
                RememberFrame.Parent = Popup
                RememberFrame.BackgroundTransparency = 1
                RememberFrame.Position = UDim2.new(0, 20, 0, 122)
                RememberFrame.Size = UDim2.new(1, -40, 0, 24)
                RememberFrame.ZIndex = 26

                local RememberToggle = Instance.new("Frame")
                RememberToggle.Parent = RememberFrame
                RememberToggle.AnchorPoint = Vector2.new(0, 0.5)
                RememberToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
                RememberToggle.BorderSizePixel = 0
                RememberToggle.Position = UDim2.new(0, 0, 0.5, 0)
                RememberToggle.Size = UDim2.new(0, 34, 0, 18)
                RememberToggle.ZIndex = 26
                Library:Corner(RememberToggle, UDim.new(1, 0))

                local RememberKnob = Instance.new("Frame")
                RememberKnob.Parent = RememberToggle
                RememberKnob.AnchorPoint = Vector2.new(0, 0.5)
                RememberKnob.BackgroundColor3 = Color3.fromRGB(210, 210, 215)
                RememberKnob.BorderSizePixel = 0
                RememberKnob.Position = UDim2.new(0, 2, 0.5, 0)
                RememberKnob.Size = UDim2.new(0, 14, 0, 14)
                RememberKnob.ZIndex = 27
                Library:Corner(RememberKnob, UDim.new(1, 0))

                local RememberText = Instance.new("TextLabel")
                RememberText.Parent = RememberFrame
                RememberText.BackgroundTransparency = 1
                RememberText.Position = UDim2.new(0, 44, 0, 0)
                RememberText.Size = UDim2.new(1, -44, 1, 0)
                RememberText.Font = Enum.Font.GothamMedium
                RememberText.Text = "Remember me"
                RememberText.TextSize = 12
                RememberText.TextXAlignment = Enum.TextXAlignment.Left
                RememberText.ZIndex = 26
                Library:Themed(RememberText, "TextColor3", "Text")

                local RememberOn = false
                local function SetRemember(State)
                    RememberOn = State
                    if State then
                        Library:TweenInstance(RememberToggle, 0.25, "BackgroundColor3", Library.Theme.Accent)
                        Library:Tween(RememberKnob, TweenInfo.new(0.3, Back, Out), { Position = UDim2.new(0, 18, 0.5, 0) })
                        Library:TweenInstance(RememberKnob, 0.25, "BackgroundColor3", Color3.fromRGB(255, 255, 255))
                    else
                        Library:TweenInstance(RememberToggle, 0.25, "BackgroundColor3", Color3.fromRGB(70, 70, 80))
                        Library:Tween(RememberKnob, TweenInfo.new(0.3, Back, Out), { Position = UDim2.new(0, 2, 0.5, 0) })
                        Library:TweenInstance(RememberKnob, 0.25, "BackgroundColor3", Color3.fromRGB(210, 210, 215))
                    end
                end

                local RememberBtn = Instance.new("TextButton")
                RememberBtn.Parent = RememberFrame
                RememberBtn.BackgroundTransparency = 1
                RememberBtn.Size = UDim2.new(1, 0, 1, 0)
                RememberBtn.Text = ""
                RememberBtn.ZIndex = 28
                RememberBtn.MouseButton1Click:Connect(function()
                    SetRemember(not RememberOn)
                end)

                local ErrorLbl = Instance.new("TextLabel")
                ErrorLbl.Parent = Popup
                ErrorLbl.BackgroundTransparency = 1
                ErrorLbl.Position = UDim2.new(0, 20, 0, 150)
                ErrorLbl.Size = UDim2.new(1, -40, 0, 16)
                ErrorLbl.Font = Enum.Font.GothamMedium
                ErrorLbl.Text = ""
                ErrorLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
                ErrorLbl.TextSize = 12
                ErrorLbl.TextXAlignment = Enum.TextXAlignment.Left
                ErrorLbl.Visible = false
                ErrorLbl.ZIndex = 26

                local CancelBtn = Instance.new("TextButton")
                CancelBtn.Parent = Popup
                CancelBtn.BackgroundTransparency = 0.9
                CancelBtn.BorderSizePixel = 0
                CancelBtn.Position = UDim2.new(0, 20, 1, -50)
                CancelBtn.Size = UDim2.new(0.5, -26, 0, 34)
                CancelBtn.Font = Enum.Font.GothamBold
                CancelBtn.Text = "Cancel"
                CancelBtn.TextSize = 13
                CancelBtn.AutoButtonColor = false
                CancelBtn.ZIndex = 26
                Library:Themed(CancelBtn, "BackgroundColor3", "Surface")
                Library:Themed(CancelBtn, "TextColor3", "Text")
                Library:Corner(CancelBtn, 8)
                Library:Hover(CancelBtn, CancelBtn, "BackgroundTransparency", 0.9, 0.78)

                local UnlockBtn = Instance.new("TextButton")
                UnlockBtn.Parent = Popup
                UnlockBtn.AnchorPoint = Vector2.new(1, 0)
                UnlockBtn.BackgroundTransparency = 0.05
                UnlockBtn.BorderSizePixel = 0
                UnlockBtn.Position = UDim2.new(1, -20, 1, -50)
                UnlockBtn.Size = UDim2.new(0.5, -26, 0, 34)
                UnlockBtn.Font = Enum.Font.GothamBold
                UnlockBtn.Text = "Unlock"
                UnlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                UnlockBtn.TextSize = 13
                UnlockBtn.AutoButtonColor = false
                UnlockBtn.ZIndex = 26
                Library:Themed(UnlockBtn, "BackgroundColor3", "Accent")
                Library:Corner(UnlockBtn, 8)
                Library:Hover(UnlockBtn, UnlockBtn, "BackgroundTransparency", 0.05, 0.25)

                CancelBtn.MouseButton1Click:Connect(ClosePopup)

                UnlockBtn.MouseButton1Click:Connect(function()
                    if PassBox.Text == tostring(LockPassword) then
                        Unlocked = true
                        if RememberOn and writefile then
                            pcall(writefile, RememberKey, tostring(LockPassword))
                        end
                        Library:SetIcon(TabIcon, iconName, Library.Theme.Accent)
                        ClosePopup()
                        SelectThisTab()
                    else
                        ErrorLbl.Text = "Incorrect password"
                        ErrorLbl.Visible = true
                        task.spawn(function()
                            for _, Offset in ipairs({ 8, -8, 5, -5, 0 }) do
                                Library:Tween(Popup, TweenInfo.new(0.05, Enum.EasingStyle.Sine, Out), { Position = UDim2.new(0.5, Offset, 0.5, 0) })
                                task.wait(0.05)
                            end
                        end)
                    end
                end)
            end)
        end

        RegEntry.Locked = Locked
        RegEntry.IsUnlocked = function() return Unlocked end
        RegEntry.RequestUnlock = ShowLockPopup

        Click_Tab_2.Activated:Connect(function()
            if Dragging or ReorderMode then
                return
            end
            if Locked and not Unlocked then
                ShowLockPopup()
                return
            end
            SelectThisTab()
        end)

        AllLayouts = AllLayouts + 1
        local TabFunc = {}

        function TabFunc:AddSection(RealNameSection, ParentOverride, Headerless)
            local SectionTitle = tostring(RealNameSection or "Section")

            local Section = Instance.new("Frame")
            Section.Name = "Section"
            Section.Parent = ParentOverride or Layout
            Section:SetAttribute("SectionTitle", SectionTitle)
            Section.BackgroundTransparency = Headerless and 1 or 0.97
            Section.BorderSizePixel = 0
            Section.Size = UDim2.new(1, 0, 0, Headerless and 20 or 34)
            Section.AutomaticSize = Enum.AutomaticSize.Y
            Library:Themed(Section, "BackgroundColor3", "Surface")
            Library:Corner(Section, 9)

            if not Headerless then
                Library:Stroke(Section, Library.Theme.Stroke, 0.92, 1)
            end

            local NameSection = Instance.new("Frame")
            NameSection.Name = "NameSection"
            NameSection.Parent = Section
            NameSection.BackgroundTransparency = 1
            NameSection.BorderSizePixel = 0
            NameSection.Size = UDim2.new(1, 0, 0, 32)
            NameSection.Visible = not Headerless

            local Title = Instance.new("TextLabel")
            Title.Name = "Title"
            Title.Parent = NameSection
            Title.BackgroundTransparency = 1
            Title.BorderSizePixel = 0
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Size = UDim2.new(1, -24, 1, 0)
            Title.Font = Enum.Font.GothamBold
            Title.Text = SectionTitle
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Library:Themed(Title, "TextColor3", "Text")

            local Line_3 = Instance.new("Frame")
            Line_3.Name = "Line"
            Line_3.Parent = NameSection
            Line_3.BorderSizePixel = 0
            Line_3.Position = UDim2.new(0, 0, 1, -1)
            Line_3.Size = UDim2.new(1, 0, 0, 1)
            Library:Themed(Line_3, "BackgroundColor3", "Accent")
            Library:FadeLine(Line_3, Library.Theme.Accent, true)

            local SectionList = Instance.new("Frame")
            SectionList.Name = "SectionList"
            SectionList.Parent = Section
            SectionList.BackgroundTransparency = 1
            SectionList.BorderSizePixel = 0
            SectionList.Position = UDim2.new(0, 0, 0, Headerless and 0 or 34)
            SectionList.ClipsDescendants = false
            SectionList.Size = UDim2.new(1, 0, 0, 0)
            SectionList.AutomaticSize = Enum.AutomaticSize.Y

            local UIPadding_4 = Instance.new("UIPadding")
            UIPadding_4.Parent = SectionList
            UIPadding_4.PaddingBottom = UDim.new(0, 12)
            UIPadding_4.PaddingLeft = UDim.new(0, 9)
            UIPadding_4.PaddingRight = UDim.new(0, 9)
            UIPadding_4.PaddingTop = UDim.new(0, 10)

            local UIListLayout_4 = Instance.new("UIListLayout")
            UIListLayout_4.Parent = SectionList
            UIListLayout_4.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_4.Padding = UDim.new(0, 10)

            local BaseHeight = Headerless and 18 or 52
            UIListLayout_4:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Section.Size = UDim2.new(1, 0, 0, UIListLayout_4.AbsoluteContentSize.Y + BaseHeight)
            end)

            local function Register(Kind, ElementTitle, Frame, Label)
                table.insert(UIIndex, { Tab = name, Section = SectionTitle, Kind = Kind, Title = tostring(ElementTitle), Frame = Frame, Label = Label, Page = Layout })
            end

            local function MakeRow(Kind, RowTitle, Description, Reserve)
                local Row = Instance.new("Frame")
                Row.Name = Kind
                Row.Parent = SectionList
                Row.BorderSizePixel = 0
                Row.ClipsDescendants = true
                Row.Size = UDim2.new(1, 0, 0, 36)
                Library:Themed(Row, "BackgroundColor3", "Surface")
                Library:Themed(Row, "BackgroundTransparency", "SurfaceAlpha")
                Library:Corner(Row, 7)
                local Stroke = Library:Stroke(Row, Library.Theme.Stroke, 0.93, 1)

                local RowTitleLabel = Instance.new("TextLabel")
                RowTitleLabel.Name = "Title"
                RowTitleLabel.Parent = Row
                RowTitleLabel.BackgroundTransparency = 1
                RowTitleLabel.BorderSizePixel = 0
                RowTitleLabel.Position = UDim2.new(0, 12, 0, 0)
                RowTitleLabel.Size = UDim2.new(1, -Reserve, 1, 0)
                RowTitleLabel.Font = Enum.Font.GothamBold
                RowTitleLabel.Text = tostring(RowTitle)
                RowTitleLabel.TextSize = 13
                RowTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                RowTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
                Library:Themed(RowTitleLabel, "TextColor3", "Text")

                local RowContent = Instance.new("TextLabel")
                RowContent.Name = "Content"
                RowContent.Parent = Row
                RowContent.BackgroundTransparency = 1
                RowContent.BorderSizePixel = 0
                RowContent.Position = UDim2.new(0, 12, 0, 23)
                RowContent.Size = UDim2.new(1, -Reserve, 1, 0)
                RowContent.Font = Enum.Font.Gotham
                RowContent.Text = tostring(Description or "")
                RowContent.TextSize = 11
                RowContent.TextWrapped = true
                RowContent.TextXAlignment = Enum.TextXAlignment.Left
                RowContent.TextYAlignment = Enum.TextYAlignment.Top
                Library:Themed(RowContent, "TextColor3", "TextDisabled")

                if RowContent.Text ~= "" then
                    local function Resize()
                        RowTitleLabel.Position = UDim2.new(0, 12, 0, 6)
                        RowTitleLabel.Size = UDim2.new(1, -Reserve, 0, 17)
                        Row.Size = UDim2.new(1, 0, 0, math.max(RowContent.TextBounds.Y + 31, 48))
                    end
                    RowContent:GetPropertyChangedSignal("TextBounds"):Connect(Resize)
                    task.defer(Resize)
                end

                Register(Kind, RowTitle, Row, RowTitleLabel)
                return Row, RowTitleLabel, RowContent, Stroke
            end

            local function RowHover(Row, Stroke, ...)
                local Triggers = { Row, ... }
                for _, Trigger in ipairs(Triggers) do
                    Trigger.MouseEnter:Connect(function()
                        Library:TweenInstance(Row, 0.16, "BackgroundTransparency", Library.Theme.SurfaceHover)
                        Library:TweenInstance(Stroke, 0.16, "Transparency", 0.72)
                    end)
                    Trigger.MouseLeave:Connect(function()
                        Library:TweenInstance(Row, 0.16, "BackgroundTransparency", Library.Theme.SurfaceAlpha)
                        Library:TweenInstance(Stroke, 0.16, "Transparency", 0.93)
                    end)
                end
            end

            local SectionFunc = {}
            SectionFunc._Frame = Section
            SectionFunc._List = SectionList

            function SectionFunc:AddToggle(cftoggle)
                local cftoggle = Library:MakeConfig({
                    Title = "Toggle < Missing Title >",
                    Description = "",
                    Default = false,
                    Flag = nil,
                    Callback = function() end
                }, cftoggle or {})

                local Toggle, Title_2, Content, Stroke = MakeRow("Toggle", cftoggle.Title, cftoggle.Description, 70)

                local ToggleCheck = Instance.new("Frame")
                ToggleCheck.Name = "ToggleCheck"
                ToggleCheck.Parent = Toggle
                ToggleCheck.AnchorPoint = Vector2.new(1, 0.5)
                ToggleCheck.BackgroundColor3 = Color3.fromRGB(72, 72, 82)
                ToggleCheck.BorderSizePixel = 0
                ToggleCheck.Position = UDim2.new(1, -12, 0.5, 0)
                ToggleCheck.Size = UDim2.new(0, 40, 0, 22)
                Library:Corner(ToggleCheck, UDim.new(1, 0))

                local Check = Instance.new("Frame")
                Check.Name = "Check"
                Check.Parent = ToggleCheck
                Check.AnchorPoint = Vector2.new(0, 0.5)
                Check.BackgroundColor3 = Color3.fromRGB(210, 210, 215)
                Check.BorderSizePixel = 0
                Check.Position = UDim2.new(0, 3, 0.5, 0)
                Check.Size = UDim2.new(0, 16, 0, 16)
                Library:Corner(Check, UDim.new(1, 0))

                local Toggle_Click = Instance.new("TextButton")
                Toggle_Click.Name = "Toggle_Click"
                Toggle_Click.Parent = Toggle
                Toggle_Click.BackgroundTransparency = 1
                Toggle_Click.BorderSizePixel = 0
                Toggle_Click.Size = UDim2.new(1, 0, 1, 0)
                Toggle_Click.Text = ""
                Toggle_Click.AutoButtonColor = false

                RowHover(Toggle, Stroke, Toggle_Click)
                Library:UpdateContent(Content, Title_2, Toggle)

                local ToggleFunc = { Value = cftoggle.Default and true or false }

                function ToggleFunc:Set(State, Silent)
                    State = State and true or false
                    ToggleFunc.Value = State
                    if State then
                        Library:TweenInstance(ToggleCheck, 0.28, "BackgroundColor3", Library.Theme.Accent)
                        Library:Tween(Check, TweenInfo.new(0.34, Back, Out), { Position = UDim2.new(0, 21, 0.5, 0), Size = UDim2.new(0, 16, 0, 16) })
                        Library:TweenInstance(Check, 0.28, "BackgroundColor3", Color3.fromRGB(255, 255, 255))
                    else
                        Library:TweenInstance(ToggleCheck, 0.28, "BackgroundColor3", Color3.fromRGB(72, 72, 82))
                        Library:Tween(Check, TweenInfo.new(0.34, Back, Out), { Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.new(0, 16, 0, 16) })
                        Library:TweenInstance(Check, 0.28, "BackgroundColor3", Color3.fromRGB(210, 210, 215))
                    end
                    if cftoggle.Flag then
                        ConfigFlags[cftoggle.Flag] = State
                    end
                    if not Silent then
                        cftoggle.Callback(State)
                    end
                end

                ToggleFunc:Set(ToggleFunc.Value)

                Toggle_Click.Activated:Connect(function()
                    ToggleFunc:Set(not ToggleFunc.Value)
                end)

                return ToggleFunc
            end

            function SectionFunc:AddButton(cfbutton)
                local cfbutton = Library:MakeConfig({
                    Title = "Button < Missing Title >",
                    Description = "",
                    Callback = function() end
                }, cfbutton or {})

                local Button, Title_3, Content_2, Stroke = MakeRow("Button", cfbutton.Title, cfbutton.Description, 54)

                local Arrow = Instance.new("ImageLabel")
                Arrow.Parent = Button
                Arrow.AnchorPoint = Vector2.new(1, 0.5)
                Arrow.BackgroundTransparency = 1
                Arrow.BorderSizePixel = 0
                Arrow.Position = UDim2.new(1, -12, 0.5, 0)
                Arrow.Size = UDim2.new(0, 18, 0, 18)
                Library:SetIcon(Arrow, Library.DefaultIcons.ChevronRight, Library.Theme.Accent)
                Library:Themed(Arrow, "ImageColor3", "Accent")

                local Button_Click = Instance.new("TextButton")
                Button_Click.Name = "Button_Click"
                Button_Click.Parent = Button
                Button_Click.BackgroundTransparency = 1
                Button_Click.BorderSizePixel = 0
                Button_Click.Size = UDim2.new(1, 0, 1, 0)
                Button_Click.Text = ""
                Button_Click.AutoButtonColor = false

                RowHover(Button, Stroke, Button_Click)
                Library:UpdateContent(Content_2, Title_3, Button)

                Button_Click.MouseEnter:Connect(function()
                    Library:Tween(Arrow, TweenInfo.new(0.18, Back, Out), { Position = UDim2.new(1, -8, 0.5, 0) })
                end)

                Button_Click.MouseLeave:Connect(function()
                    Library:Tween(Arrow, TweenInfo.new(0.18, Back, Out), { Position = UDim2.new(1, -12, 0.5, 0) })
                end)

                Button_Click.Activated:Connect(function()
                    Library:Flash(Button)
                    cfbutton.Callback()
                end)

                return { Frame = Button }
            end

            function SectionFunc:AddInput(cftextbox)
                local cftextbox = Library:MakeConfig({
                    Title = "Textbox",
                    Description = "",
                    PlaceHolder = "",
                    Default = "",
                    Numeric = false,
                    Callback = function() end
                }, cftextbox or {})

                local Input, Title_7, Content_5, Stroke = MakeRow("Input", cftextbox.Title, cftextbox.Description, 168)
                RowHover(Input, Stroke)

                local TextboxFrame = Instance.new("Frame")
                TextboxFrame.Name = "TextboxFrame"
                TextboxFrame.Parent = Input
                TextboxFrame.AnchorPoint = Vector2.new(1, 0.5)
                TextboxFrame.BackgroundTransparency = 0
                TextboxFrame.BorderSizePixel = 0
                TextboxFrame.Position = UDim2.new(1, -12, 0.5, 0)
                TextboxFrame.Size = UDim2.new(0, 140, 0, 28)
                Library:Themed(TextboxFrame, "BackgroundColor3", "Background")
                Library:Corner(TextboxFrame, 7)
                local BoxStroke = Library:Stroke(TextboxFrame, Library.Theme.Stroke, 0.82, 1)

                local WritingIcon = Instance.new("ImageLabel")
                WritingIcon.Name = "WritingIcon"
                WritingIcon.Parent = TextboxFrame
                WritingIcon.AnchorPoint = Vector2.new(0, 0.5)
                WritingIcon.BackgroundTransparency = 1
                WritingIcon.BorderSizePixel = 0
                WritingIcon.Position = UDim2.new(0, 9, 0.5, 0)
                WritingIcon.Size = UDim2.new(0, 13, 0, 13)
                Library:SetIcon(WritingIcon, Library.DefaultIcons.Edit, Library.Theme.Accent)
                Library:Themed(WritingIcon, "ImageColor3", "Accent")

                local RealTextBox = Instance.new("TextBox")
                RealTextBox.Name = "RealTextBox"
                RealTextBox.Parent = TextboxFrame
                RealTextBox.BackgroundTransparency = 1
                RealTextBox.BorderSizePixel = 0
                RealTextBox.ClipsDescendants = true
                RealTextBox.Position = UDim2.new(0, 28, 0, 0)
                RealTextBox.Size = UDim2.new(1, -38, 1, 0)
                RealTextBox.Font = Enum.Font.GothamMedium
                RealTextBox.PlaceholderText = cftextbox.PlaceHolder
                RealTextBox.Text = tostring(cftextbox.Default)
                RealTextBox.TextSize = 12
                RealTextBox.TextXAlignment = Enum.TextXAlignment.Left
                RealTextBox.ClearTextOnFocus = false
                Library:Themed(RealTextBox, "TextColor3", "Text")
                Library:Themed(RealTextBox, "PlaceholderColor3", "TextDisabled")

                Library:UpdateContent(Content_5, Title_7, Input)

                RealTextBox.Focused:Connect(function()
                    Library:TweenInstance(BoxStroke, 0.2, "Transparency", 0.35)
                    Library:TweenInstance(BoxStroke, 0.2, "Color", Library.Theme.Accent)
                end)

                local InputFunc = { Value = tostring(cftextbox.Default) }

                function InputFunc:Set(Value, Silent)
                    RealTextBox.Text = tostring(Value)
                    InputFunc.Value = RealTextBox.Text
                    if not Silent then
                        cftextbox.Callback(InputFunc.Value)
                    end
                end

                RealTextBox.FocusLost:Connect(function()
                    Library:TweenInstance(BoxStroke, 0.2, "Transparency", 0.82)
                    Library:TweenInstance(BoxStroke, 0.2, "Color", Library.Theme.Stroke)
                    if cftextbox.Numeric then
                        local Number = tonumber(RealTextBox.Text)
                        RealTextBox.Text = Number and tostring(Number) or ""
                    end
                    InputFunc.Value = RealTextBox.Text
                    cftextbox.Callback(RealTextBox.Text)
                end)

                cftextbox.Callback(RealTextBox.Text)
                return InputFunc
            end

            function SectionFunc:AddSlider(cfslider)
                local cfslider = Library:MakeConfig({
                    Title = "Slider < Missing Title >",
                    Description = "",
                    Max = 100,
                    Min = 1,
                    Increment = 1,
                    Default = 1,
                    Suffix = "",
                    Callback = function() end
                }, cfslider or {})

                local Slider, Title_4, Content_3, Stroke = MakeRow("Slider", cfslider.Title, cfslider.Description, 150)
                RowHover(Slider, Stroke)
                -- Title reserves a scale-based left portion so it can never
                -- compute a negative/near-zero width on a narrow row.
                Title_4.Size = UDim2.new(0.42, -8, 1, 0)

                local SliderValue = Instance.new("TextBox")
                SliderValue.Name = "SliderValue"
                SliderValue.Parent = Slider
                SliderValue.AnchorPoint = Vector2.new(1, 0.5)
                SliderValue.BackgroundTransparency = 0
                SliderValue.BorderSizePixel = 0
                SliderValue.Position = UDim2.new(1, -12, 0.5, 0)
                SliderValue.Size = UDim2.new(0, 48, 0, 24)
                SliderValue.Font = Enum.Font.GothamBold
                SliderValue.PlaceholderText = "..."
                SliderValue.Text = ""
                SliderValue.TextSize = 11
                SliderValue.ClearTextOnFocus = false
                Library:Themed(SliderValue, "BackgroundColor3", "Background")
                Library:Themed(SliderValue, "TextColor3", "Text")
                Library:Themed(SliderValue, "PlaceholderColor3", "TextDisabled")
                Library:Corner(SliderValue, 6)
                local ValueStroke = Library:Stroke(SliderValue, Library.Theme.Accent, 0.62, 1)
                Library:Themed(ValueStroke, "Color", "Accent")

                local SliderFrame = Instance.new("Frame")
                SliderFrame.Name = "SliderFrame"
                SliderFrame.Parent = Slider
                SliderFrame.AnchorPoint = Vector2.new(1, 0.5)
                SliderFrame.BackgroundColor3 = Color3.fromRGB(56, 56, 66)
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Position = UDim2.new(1, -68, 0.5, 0)
                SliderFrame.Size = UDim2.new(0, 112, 0, 6)
                Library:Corner(SliderFrame, UDim.new(1, 0))

                local SliderDraggable = Instance.new("Frame")
                SliderDraggable.Name = "SliderDraggable"
                SliderDraggable.Parent = SliderFrame
                SliderDraggable.BorderSizePixel = 0
                SliderDraggable.Size = UDim2.new(0, 0, 1, 0)
                Library:Themed(SliderDraggable, "BackgroundColor3", "Accent")
                Library:Corner(SliderDraggable, UDim.new(1, 0))

                local Circle = Instance.new("Frame")
                Circle.Name = "Circle"
                Circle.Parent = SliderDraggable
                Circle.AnchorPoint = Vector2.new(0.5, 0.5)
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.BorderSizePixel = 0
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.Size = UDim2.new(0, 13, 0, 13)
                Circle.ZIndex = 3
                Library:Corner(Circle, UDim.new(1, 0))
                local CircleStroke = Library:Stroke(Circle, Library.Theme.Accent, 0.1, 2)
                Library:Themed(CircleStroke, "Color", "Accent")

                local SliderHit = Instance.new("TextButton")
                SliderHit.Name = "SliderHit"
                SliderHit.Parent = Slider
                SliderHit.AnchorPoint = Vector2.new(1, 0.5)
                SliderHit.BackgroundTransparency = 1
                SliderHit.BorderSizePixel = 0
                SliderHit.Position = UDim2.new(1, -66, 0.5, 0)
                SliderHit.Size = UDim2.new(0, 122, 0, 26)
                SliderHit.Text = ""
                SliderHit.AutoButtonColor = false
                SliderHit.ZIndex = 4

                Library:UpdateContent(Content_3, Title_4, Slider)

                local SliderFunc = { Value = cfslider.Default }
                local Dragging = false

                local function Round(Number, Factor)
                    if not Factor or Factor <= 0 then
                        return Number
                    end
                    local Result = math.floor(Number / Factor + 0.5) * Factor
                    return tonumber(string.format("%.4f", Result)) or Result
                end

                function SliderFunc:Set(Value, Silent)
                    Value = tonumber(Value) or cfslider.Min
                    Value = math.clamp(Round(Value, cfslider.Increment), cfslider.Min, cfslider.Max)
                    SliderFunc.Value = Value
                    SliderValue.Text = tostring(Value) .. tostring(cfslider.Suffix)
                    local Range = cfslider.Max - cfslider.Min
                    local Scale = Range ~= 0 and (Value - cfslider.Min) / Range or 0
                    Library:Tween(SliderDraggable, TweenInfo.new(0.16, Quart, Out), { Size = UDim2.new(Scale, 0, 1, 0) })
                    if not Silent then
                        cfslider.Callback(Value)
                    end
                end

                local function UpdateFromInput(Position)
                    local Width = SliderFrame.AbsoluteSize.X
                    if Width <= 0 then
                        return
                    end
                    local Scale = math.clamp((Position.X - SliderFrame.AbsolutePosition.X) / Width, 0, 1)
                    SliderFunc:Set(cfslider.Min + ((cfslider.Max - cfslider.Min) * Scale))
                end

                SliderHit.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
                        Library:Tween(Circle, TweenInfo.new(0.15, Back, Out), { Size = UDim2.new(0, 17, 0, 17) })
                        UpdateFromInput(Input.Position)
                    end
                end)

                UserInputService.InputEnded:Connect(function(Input)
                    if not Dragging then
                        return
                    end
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = false
                        Library:Tween(Circle, TweenInfo.new(0.2, Back, Out), { Size = UDim2.new(0, 13, 0, 13) })
                    end
                end)

                UserInputService.InputChanged:Connect(function(Input)
                    if not Dragging then
                        return
                    end
                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                        UpdateFromInput(Input.Position)
                    end
                end)

                SliderValue.Focused:Connect(function()
                    SliderValue.Text = tostring(SliderFunc.Value)
                    Library:TweenInstance(ValueStroke, 0.2, "Transparency", 0.25)
                end)

                SliderValue.FocusLost:Connect(function()
                    Library:TweenInstance(ValueStroke, 0.2, "Transparency", 0.62)
                    local Number = tonumber((SliderValue.Text:gsub("[^%-%d%.]", "")))
                    if Number then
                        SliderFunc:Set(Number)
                    else
                        SliderFunc:Set(SliderFunc.Value, true)
                    end
                end)

                SliderFunc:Set(tonumber(cfslider.Default) or cfslider.Min, true)
                return SliderFunc
            end

            function SectionFunc:AddDropdown(cfdropdown)
                local cfdropdown = Library:MakeConfig({
                    Title = "Dropdown",
                    Description = "",
                    Values = {},
                    Default = "",
                    Multi = false,
                    Callback = function() end
                }, cfdropdown or {})

                local Dropdown, Title_8, Content_6, Stroke = MakeRow("Dropdown", cfdropdown.Title, cfdropdown.Description, 140)
                RowHover(Dropdown, Stroke)

                local Selects = Instance.new("Frame")
                Selects.Name = "Selects"
                Selects.Parent = Dropdown
                Selects.AnchorPoint = Vector2.new(1, 0.5)
                Selects.BorderSizePixel = 0
                Selects.Position = UDim2.new(1, -12, 0.5, 0)
                Selects.Size = UDim2.new(0, 112, 0, 26)
                Library:Themed(Selects, "BackgroundColor3", "Background")
                Library:Corner(Selects, 7)
                local SelectStroke = Library:Stroke(Selects, Library.Theme.Stroke, 0.82, 1)

                local SelectText = Instance.new("TextLabel")
                SelectText.Name = "SelectText"
                SelectText.Parent = Selects
                SelectText.BackgroundTransparency = 1
                SelectText.BorderSizePixel = 0
                SelectText.Position = UDim2.new(0, 9, 0, 0)
                SelectText.Size = UDim2.new(1, -28, 1, 0)
                SelectText.Font = Enum.Font.GothamMedium
                SelectText.Text = ""
                SelectText.TextSize = 11
                SelectText.TextXAlignment = Enum.TextXAlignment.Left
                SelectText.TextTruncate = Enum.TextTruncate.AtEnd
                Library:Themed(SelectText, "TextColor3", "Text")

                local DropIcon = Instance.new("ImageLabel")
                DropIcon.Parent = Selects
                DropIcon.AnchorPoint = Vector2.new(1, 0.5)
                DropIcon.BackgroundTransparency = 1
                DropIcon.BorderSizePixel = 0
                DropIcon.Position = UDim2.new(1, -8, 0.5, 0)
                DropIcon.Size = UDim2.new(0, 13, 0, 13)
                Library:SetIcon(DropIcon, Library.DefaultIcons.ChevronDown, Library.Theme.Accent)
                Library:Themed(DropIcon, "ImageColor3", "Accent")

                local Drop_Click = Instance.new("TextButton")
                Drop_Click.Name = "Drop_Click"
                Drop_Click.Parent = Selects
                Drop_Click.BackgroundTransparency = 1
                Drop_Click.BorderSizePixel = 0
                Drop_Click.Size = UDim2.new(1, 0, 1, 0)
                Drop_Click.Text = ""
                Drop_Click.AutoButtonColor = false

                Library:UpdateContent(Content_6, Title_8, Dropdown)

                local DropdownList = Instance.new("Frame")
                DropdownList.Name = "DropdownList"
                DropdownList.Parent = DropdownZone
                DropdownList.AnchorPoint = Vector2.new(0.5, 0.5)
                DropdownList.BorderSizePixel = 0
                DropdownList.Position = UDim2.new(0.5, 0, 0.5, 0)
                DropdownList.Size = UDim2.new(0, 380, 0, 268)
                DropdownList.Visible = false
                DropdownList.ZIndex = 25
                Library:Themed(DropdownList, "BackgroundColor3", "Elevated")
                Library:Corner(DropdownList, 12)
                local ListStroke = Library:Stroke(DropdownList, Library.Theme.Accent, 0.6, 1.2)
                Library:Themed(ListStroke, "Color", "Accent")

                local ListScale = Instance.new("UIScale")
                ListScale.Parent = DropdownList

                local Topbar = Instance.new("Frame")
                Topbar.Name = "Topbar"
                Topbar.Parent = DropdownList
                Topbar.BackgroundTransparency = 1
                Topbar.BorderSizePixel = 0
                Topbar.Size = UDim2.new(1, 0, 0, 52)
                Topbar.ZIndex = 26

                local Title_10 = Instance.new("TextLabel")
                Title_10.Name = "Title"
                Title_10.Parent = Topbar
                Title_10.BackgroundTransparency = 1
                Title_10.BorderSizePixel = 0
                Title_10.Position = UDim2.new(0, 16, 0, 0)
                Title_10.Size = UDim2.new(1, -190, 1, 0)
                Title_10.Font = Enum.Font.GothamBold
                Title_10.Text = cfdropdown.Title
                Title_10.TextSize = 14
                Title_10.TextXAlignment = Enum.TextXAlignment.Left
                Title_10.TextTruncate = Enum.TextTruncate.AtEnd
                Title_10.ZIndex = 26
                Library:Themed(Title_10, "TextColor3", "Text")

                local SearchFrame_2 = Instance.new("Frame")
                SearchFrame_2.Name = "SearchFrame"
                SearchFrame_2.Parent = Topbar
                SearchFrame_2.AnchorPoint = Vector2.new(1, 0.5)
                SearchFrame_2.BackgroundTransparency = 0.92
                SearchFrame_2.BorderSizePixel = 0
                SearchFrame_2.Position = UDim2.new(1, -52, 0.5, 0)
                SearchFrame_2.Size = UDim2.new(0, 120, 0, 30)
                SearchFrame_2.ZIndex = 26
                Library:Themed(SearchFrame_2, "BackgroundColor3", "Surface")
                Library:Corner(SearchFrame_2, 8)
                Library:Stroke(SearchFrame_2, Library.Theme.Stroke, 0.82, 1)

                local IconSearch_2 = Instance.new("ImageLabel")
                IconSearch_2.Name = "IconSearch"
                IconSearch_2.Parent = SearchFrame_2
                IconSearch_2.AnchorPoint = Vector2.new(0, 0.5)
                IconSearch_2.BackgroundTransparency = 1
                IconSearch_2.BorderSizePixel = 0
                IconSearch_2.Position = UDim2.new(0, 9, 0.5, 0)
                IconSearch_2.Size = UDim2.new(0, 13, 0, 13)
                IconSearch_2.ZIndex = 27
                Library:SetIcon(IconSearch_2, Library.DefaultIcons.Search, Library.Theme.Accent)
                Library:Themed(IconSearch_2, "ImageColor3", "Accent")

                local TextBox = Instance.new("TextBox")
                TextBox.Parent = SearchFrame_2
                TextBox.BackgroundTransparency = 1
                TextBox.BorderSizePixel = 0
                TextBox.ClipsDescendants = true
                TextBox.Position = UDim2.new(0, 28, 0, 0)
                TextBox.Size = UDim2.new(1, -36, 1, 0)
                TextBox.Font = Enum.Font.GothamMedium
                TextBox.PlaceholderText = "Search"
                TextBox.Text = ""
                TextBox.TextSize = 12
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.ClearTextOnFocus = false
                TextBox.ZIndex = 27
                Library:Themed(TextBox, "TextColor3", "Text")
                Library:Themed(TextBox, "PlaceholderColor3", "TextDisabled")

                local Click_Dropdown = Instance.new("TextButton")
                Click_Dropdown.Name = "Click_Dropdown"
                Click_Dropdown.Parent = Topbar
                Click_Dropdown.AnchorPoint = Vector2.new(1, 0.5)
                Click_Dropdown.BackgroundTransparency = 0.92
                Click_Dropdown.BorderSizePixel = 0
                Click_Dropdown.Position = UDim2.new(1, -14, 0.5, 0)
                Click_Dropdown.Size = UDim2.new(0, 30, 0, 30)
                Click_Dropdown.Text = ""
                Click_Dropdown.AutoButtonColor = false
                Click_Dropdown.ZIndex = 26
                Library:Themed(Click_Dropdown, "BackgroundColor3", "Surface")
                Library:Corner(Click_Dropdown, 8)
                Library:Hover(Click_Dropdown, Click_Dropdown, "BackgroundTransparency", 0.92, 0.78)

                local Icon_4 = Instance.new("ImageLabel")
                Icon_4.Name = "Icon"
                Icon_4.Parent = Click_Dropdown
                Icon_4.AnchorPoint = Vector2.new(0.5, 0.5)
                Icon_4.BackgroundTransparency = 1
                Icon_4.BorderSizePixel = 0
                Icon_4.Position = UDim2.new(0.5, 0, 0.5, 0)
                Icon_4.Size = UDim2.new(0, 15, 0, 15)
                Icon_4.ZIndex = 27
                Library:SetIcon(Icon_4, Library.DefaultIcons.Close, Library.Theme.Accent)
                Library:Themed(Icon_4, "ImageColor3", "Accent")

                local Real_List = Instance.new("ScrollingFrame")
                Real_List.Name = "Real_List"
                Real_List.Parent = DropdownList
                Real_List.BackgroundTransparency = 0.96
                Real_List.BorderSizePixel = 0
                Real_List.Position = UDim2.new(0, 12, 0, 54)
                Real_List.Selectable = false
                Real_List.Size = UDim2.new(1, -24, 1, -66)
                Real_List.ZIndex = 26
                Library:Themed(Real_List, "BackgroundColor3", "Surface")
                Library:StyleScroll(Real_List)
                Library:Corner(Real_List, 9)

                local UIListLayout_5 = Instance.new("UIListLayout")
                UIListLayout_5.Parent = Real_List
                UIListLayout_5.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout_5.Padding = UDim.new(0, 5)
                Library:UpdateScrolling(Real_List, UIListLayout_5)

                local UIPadding_5 = Instance.new("UIPadding")
                UIPadding_5.Parent = Real_List
                UIPadding_5.PaddingBottom = UDim.new(0, 8)
                UIPadding_5.PaddingLeft = UDim.new(0, 8)
                UIPadding_5.PaddingRight = UDim.new(0, 8)
                UIPadding_5.PaddingTop = UDim.new(0, 8)

                local function OpenList()
                    DropdownZone.Visible = true
                    DropdownList.Visible = true
                    DropdownZone.BackgroundTransparency = 1
                    ListScale.Scale = 0.9
                    Library:TweenInstance(DropdownZone, 0.24, "BackgroundTransparency", 0.4)
                    Library:Tween(ListScale, TweenInfo.new(0.34, Back, Out), { Scale = 1 })
                    Library:Tween(DropIcon, TweenInfo.new(0.24, Quart, Out), { Rotation = 180 })
                end

                local function CloseList()
                    Library:Tween(ListScale, TweenInfo.new(0.18, Quart, In), { Scale = 0.92 })
                    Library:Tween(DropIcon, TweenInfo.new(0.24, Quart, Out), { Rotation = 0 })
                    Library:TweenInstance(DropdownZone, 0.2, "BackgroundTransparency", 1, function()
                        DropdownZone.Visible = false
                    end)
                    task.delay(0.18, function()
                        DropdownList.Visible = false
                    end)
                end

                Drop_Click.Activated:Connect(OpenList)
                Click_Dropdown.Activated:Connect(CloseList)

                Drop_Click.MouseEnter:Connect(function()
                    Library:TweenInstance(SelectStroke, 0.16, "Transparency", 0.5)
                    Library:TweenInstance(SelectStroke, 0.16, "Color", Library.Theme.Accent)
                end)

                Drop_Click.MouseLeave:Connect(function()
                    Library:TweenInstance(SelectStroke, 0.16, "Transparency", 0.82)
                    Library:TweenInstance(SelectStroke, 0.16, "Color", Library.Theme.Stroke)
                end)

                TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local Query = string.lower(Trim(TextBox.Text))
                    for _, Option in ipairs(Real_List:GetChildren()) do
                        if Option:IsA("Frame") and Option:FindFirstChild("Title") then
                            Option.Visible = Query == "" or string.find(string.lower(Option.Title.Text), Query, 1, true) ~= nil
                        end
                    end
                end)

                local DropFunc = { Value = {} }

                local function Normalize(Value)
                    if typeof(Value) == "string" then
                        return Value ~= "" and { Value } or {}
                    end
                    if type(Value) == "table" then
                        local Copy = {}
                        for _, Item in ipairs(Value) do
                            table.insert(Copy, tostring(Item))
                        end
                        return Copy
                    end
                    return {}
                end

                function DropFunc:Set(Value, Silent)
                    DropFunc.Value = Normalize(Value)
                    for _, Option in ipairs(Real_List:GetChildren()) do
                        if Option:IsA("Frame") and Option:FindFirstChild("Title") then
                            local Active = table.find(DropFunc.Value, Option.Title.Text) ~= nil
                            Library:TweenInstance(Option, 0.24, "BackgroundTransparency", Active and 0.86 or 0.97)
                            Library:TweenInstance(Option.Title, 0.24, "TextTransparency", Active and 0 or 0.4)
                            local Mark = Option:FindFirstChild("Mark")
                            if Mark then
                                Library:TweenInstance(Mark, 0.24, "ImageTransparency", Active and 0 or 1)
                            end
                        end
                    end
                    SelectText.Text = table.concat(DropFunc.Value, ", ")
                    if not Silent then
                        cfdropdown.Callback(cfdropdown.Multi and DropFunc.Value or (DropFunc.Value[1] or ""))
                    end
                end

                function DropFunc:Add(Value)
                    local Option2 = Instance.new("Frame")
                    Option2.Name = "Option"
                    Option2.Parent = Real_List
                    Option2.BackgroundTransparency = 0.97
                    Option2.BorderSizePixel = 0
                    Option2.Size = UDim2.new(1, 0, 0, 34)
                    Option2.ZIndex = 26
                    Library:Themed(Option2, "BackgroundColor3", "Accent")
                    Library:Corner(Option2, 7)

                    local Title_12 = Instance.new("TextLabel")
                    Title_12.Name = "Title"
                    Title_12.Parent = Option2
                    Title_12.BackgroundTransparency = 1
                    Title_12.BorderSizePixel = 0
                    Title_12.Position = UDim2.new(0, 12, 0, 0)
                    Title_12.Size = UDim2.new(1, -44, 1, 0)
                    Title_12.Font = Enum.Font.GothamMedium
                    Title_12.Text = tostring(Value)
                    Title_12.TextSize = 12
                    Title_12.TextTransparency = 0.4
                    Title_12.TextXAlignment = Enum.TextXAlignment.Left
                    Title_12.TextTruncate = Enum.TextTruncate.AtEnd
                    Title_12.ZIndex = 27
                    Library:Themed(Title_12, "TextColor3", "Text")

                    local Mark = Instance.new("ImageLabel")
                    Mark.Name = "Mark"
                    Mark.Parent = Option2
                    Mark.AnchorPoint = Vector2.new(1, 0.5)
                    Mark.BackgroundTransparency = 1
                    Mark.BorderSizePixel = 0
                    Mark.Position = UDim2.new(1, -12, 0.5, 0)
                    Mark.Size = UDim2.new(0, 14, 0, 14)
                    Mark.ImageTransparency = 1
                    Mark.ZIndex = 27
                    Library:SetIcon(Mark, Library.DefaultIcons.Check, Library.Theme.Accent)
                    Library:Themed(Mark, "ImageColor3", "Accent")

                    local Option2_Click = Instance.new("TextButton")
                    Option2_Click.Name = "Option2_Click"
                    Option2_Click.Parent = Option2
                    Option2_Click.BackgroundTransparency = 1
                    Option2_Click.BorderSizePixel = 0
                    Option2_Click.Size = UDim2.new(1, 0, 1, 0)
                    Option2_Click.Text = ""
                    Option2_Click.AutoButtonColor = false
                    Option2_Click.ZIndex = 28

                    Option2_Click.Activated:Connect(function()
                        local Current = DropFunc.Value
                        if cfdropdown.Multi then
                            local Index = table.find(Current, Title_12.Text)
                            if Index then
                                table.remove(Current, Index)
                            else
                                table.insert(Current, Title_12.Text)
                            end
                            DropFunc:Set(Current)
                        else
                            DropFunc:Set({ Title_12.Text })
                            CloseList()
                        end
                        Library:Flash(Option2)
                    end)

                    return Option2
                end

                function DropFunc:Clear()
                    for _, Option in ipairs(Real_List:GetChildren()) do
                        if Option:IsA("Frame") then
                            Option:Destroy()
                        end
                    end
                end

                function DropFunc:Refresh(NewList, KeepValue)
                    self:Clear()
                    for _, Value in ipairs(NewList or {}) do
                        self:Add(Value)
                    end
                    if KeepValue then
                        self:Set(DropFunc.Value, true)
                    end
                end

                DropFunc:Refresh(cfdropdown.Values)
                DropFunc:Set(cfdropdown.Default, true)
                return DropFunc
            end

            function SectionFunc:AddColorpicker(cfcolor)
                local cfcolor = Library:MakeConfig({
                    Title = "Colorpicker",
                    Description = "",
                    Default = Color3.fromRGB(255, 255, 255),
                    Callback = function() end
                }, cfcolor or {})

                local Colorpicker, Title_C, Content_C, Stroke = MakeRow("Colorpicker", cfcolor.Title, cfcolor.Description, 60)
                RowHover(Colorpicker, Stroke)

                local ColorBox = Instance.new("Frame")
                ColorBox.Name = "ColorBox"
                ColorBox.Parent = Colorpicker
                ColorBox.AnchorPoint = Vector2.new(1, 0.5)
                ColorBox.BackgroundColor3 = cfcolor.Default or Color3.fromRGB(255, 255, 255)
                ColorBox.BorderSizePixel = 0
                ColorBox.Position = UDim2.new(1, -12, 0.5, 0)
                ColorBox.Size = UDim2.new(0, 30, 0, 26)
                ColorBox.ZIndex = 3
                Library:Corner(ColorBox, 7)
                Library:Stroke(ColorBox, Color3.fromRGB(255, 255, 255), 0.55, 1.2)

                local ColorBtn = Instance.new("TextButton")
                ColorBtn.Parent = ColorBox
                ColorBtn.BackgroundTransparency = 1
                ColorBtn.Size = UDim2.new(1, 0, 1, 0)
                ColorBtn.Text = ""
                ColorBtn.AutoButtonColor = false
                ColorBtn.ZIndex = 4

                Library:UpdateContent(Content_C, Title_C, Colorpicker)

                local ColorFunc = { Value = cfcolor.Default or Color3.fromRGB(255, 255, 255) }

                function ColorFunc:Set(Value, Silent)
                    if typeof(Value) ~= "Color3" then
                        return
                    end
                    ColorFunc.Value = Value
                    Library:TweenInstance(ColorBox, 0.2, "BackgroundColor3", Value)
                    if not Silent then
                        cfcolor.Callback(Value)
                    end
                end

                ColorBtn.MouseButton1Click:Connect(function()
                    ShowModal(function(Popup, ClosePopup)
                        Popup.Size = UDim2.new(0, 320, 0, 322)

                        local TitleBar = Instance.new("TextLabel")
                        TitleBar.Parent = Popup
                        TitleBar.BackgroundTransparency = 1
                        TitleBar.Position = UDim2.new(0, 16, 0, 14)
                        TitleBar.Size = UDim2.new(1, -32, 0, 20)
                        TitleBar.Font = Enum.Font.GothamBold
                        TitleBar.Text = cfcolor.Title
                        TitleBar.TextSize = 14
                        TitleBar.TextXAlignment = Enum.TextXAlignment.Left
                        TitleBar.ZIndex = 26
                        Library:Themed(TitleBar, "TextColor3", "Text")

                        local SVSquare = Instance.new("ImageLabel")
                        SVSquare.Parent = Popup
                        SVSquare.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        SVSquare.BorderSizePixel = 0
                        SVSquare.Position = UDim2.new(0, 16, 0, 44)
                        SVSquare.Size = UDim2.new(1, -32, 0, 148)
                        SVSquare.ZIndex = 26
                        SVSquare.Image = "rbxassetid://4155801252"
                        SVSquare.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        SVSquare.ScaleType = Enum.ScaleType.Stretch
                        Library:Corner(SVSquare, 8)

                        local SVHit = Instance.new("TextButton")
                        SVHit.Parent = SVSquare
                        SVHit.BackgroundTransparency = 1
                        SVHit.BorderSizePixel = 0
                        SVHit.Size = UDim2.new(1, 0, 1, 0)
                        SVHit.Text = ""
                        SVHit.AutoButtonColor = false
                        SVHit.ZIndex = 27

                        local SVCursor = Instance.new("Frame")
                        SVCursor.Parent = SVSquare
                        SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                        SVCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        SVCursor.BorderSizePixel = 0
                        SVCursor.Size = UDim2.new(0, 12, 0, 12)
                        SVCursor.ZIndex = 29
                        Library:Corner(SVCursor, 6)
                        Library:Stroke(SVCursor, Color3.fromRGB(30, 30, 30), 0.2, 2)

                        local HueBar = Instance.new("Frame")
                        HueBar.Parent = Popup
                        HueBar.BorderSizePixel = 0
                        HueBar.Position = UDim2.new(0, 16, 0, 202)
                        HueBar.Size = UDim2.new(1, -32, 0, 18)
                        HueBar.ZIndex = 26
                        Library:Corner(HueBar, UDim.new(1, 0))
                        Library:Gradient(HueBar, ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                        }), 0)

                        local HueCursor = Instance.new("Frame")
                        HueCursor.Parent = HueBar
                        HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                        HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        HueCursor.BorderSizePixel = 0
                        HueCursor.Position = UDim2.new(0, 0, 0.5, 0)
                        HueCursor.Size = UDim2.new(0, 8, 0, 24)
                        HueCursor.ZIndex = 29
                        Library:Corner(HueCursor, 4)
                        Library:Stroke(HueCursor, Color3.fromRGB(30, 30, 30), 0.3, 1.5)

                        local Preview = Instance.new("Frame")
                        Preview.Parent = Popup
                        Preview.BackgroundColor3 = ColorFunc.Value
                        Preview.BorderSizePixel = 0
                        Preview.Position = UDim2.new(0, 16, 0, 232)
                        Preview.Size = UDim2.new(0, 46, 0, 34)
                        Preview.ZIndex = 26
                        Library:Corner(Preview, 8)
                        Library:Stroke(Preview, Color3.fromRGB(255, 255, 255), 0.6, 1)

                        local HexFrame = Instance.new("Frame")
                        HexFrame.Parent = Popup
                        HexFrame.BackgroundTransparency = 0.92
                        HexFrame.BorderSizePixel = 0
                        HexFrame.Position = UDim2.new(0, 70, 0, 232)
                        HexFrame.Size = UDim2.new(1, -86, 0, 34)
                        HexFrame.ZIndex = 26
                        Library:Themed(HexFrame, "BackgroundColor3", "Surface")
                        Library:Corner(HexFrame, 8)
                        Library:Stroke(HexFrame, Library.Theme.Stroke, 0.8, 1)

                        local HexLabel = Instance.new("TextLabel")
                        HexLabel.Parent = HexFrame
                        HexLabel.BackgroundTransparency = 1
                        HexLabel.Position = UDim2.new(0, 12, 0, 0)
                        HexLabel.Size = UDim2.new(0, 14, 1, 0)
                        HexLabel.Font = Enum.Font.GothamBold
                        HexLabel.Text = "#"
                        HexLabel.TextSize = 13
                        HexLabel.ZIndex = 27
                        Library:Themed(HexLabel, "TextColor3", "TextDisabled")

                        local HexInput = Instance.new("TextBox")
                        HexInput.Parent = HexFrame
                        HexInput.BackgroundTransparency = 1
                        HexInput.Position = UDim2.new(0, 28, 0, 0)
                        HexInput.Size = UDim2.new(1, -36, 1, 0)
                        HexInput.Font = Enum.Font.Code
                        HexInput.PlaceholderText = "FFFFFF"
                        HexInput.Text = ""
                        HexInput.TextSize = 13
                        HexInput.TextXAlignment = Enum.TextXAlignment.Left
                        HexInput.ClearTextOnFocus = false
                        HexInput.ZIndex = 27
                        Library:Themed(HexInput, "TextColor3", "Text")
                        Library:Themed(HexInput, "PlaceholderColor3", "TextDisabled")

                        local Cancel = Instance.new("TextButton")
                        Cancel.Parent = Popup
                        Cancel.BackgroundTransparency = 0.9
                        Cancel.BorderSizePixel = 0
                        Cancel.Position = UDim2.new(0, 16, 1, -50)
                        Cancel.Size = UDim2.new(0.5, -22, 0, 34)
                        Cancel.Font = Enum.Font.GothamBold
                        Cancel.Text = "Cancel"
                        Cancel.TextSize = 13
                        Cancel.AutoButtonColor = false
                        Cancel.ZIndex = 26
                        Library:Themed(Cancel, "BackgroundColor3", "Surface")
                        Library:Themed(Cancel, "TextColor3", "Text")
                        Library:Corner(Cancel, 8)
                        Library:Hover(Cancel, Cancel, "BackgroundTransparency", 0.9, 0.78)

                        local Apply = Instance.new("TextButton")
                        Apply.Parent = Popup
                        Apply.AnchorPoint = Vector2.new(1, 0)
                        Apply.BackgroundTransparency = 0.05
                        Apply.BorderSizePixel = 0
                        Apply.Position = UDim2.new(1, -16, 1, -50)
                        Apply.Size = UDim2.new(0.5, -22, 0, 34)
                        Apply.Font = Enum.Font.GothamBold
                        Apply.Text = "Apply"
                        Apply.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Apply.TextSize = 13
                        Apply.AutoButtonColor = false
                        Apply.ZIndex = 26
                        Library:Themed(Apply, "BackgroundColor3", "Accent")
                        Library:Corner(Apply, 8)
                        Library:Hover(Apply, Apply, "BackgroundTransparency", 0.05, 0.25)

                        local CurrentH, CurrentS, CurrentV = Color3.toHSV(ColorFunc.Value)

                        local function ToHex(Color)
                            return string.format("%02X%02X%02X", math.floor(Color.R * 255 + 0.5), math.floor(Color.G * 255 + 0.5), math.floor(Color.B * 255 + 0.5))
                        end

                        local function FromHex(Hex)
                            Hex = Hex:gsub("#", "")
                            if #Hex == 6 then
                                local R = tonumber(Hex:sub(1, 2), 16)
                                local G = tonumber(Hex:sub(3, 4), 16)
                                local B = tonumber(Hex:sub(5, 6), 16)
                                if R and G and B then
                                    return Color3.fromRGB(R, G, B)
                                end
                            end
                            return nil
                        end

                        local function UpdateUI()
                            SVSquare.BackgroundColor3 = Color3.fromHSV(CurrentH, 1, 1)
                            HueCursor.Position = UDim2.new(CurrentH, 0, 0.5, 0)
                            SVCursor.Position = UDim2.new(CurrentS, 0, 1 - CurrentV, 0)
                            local Preview3 = Color3.fromHSV(CurrentH, CurrentS, CurrentV)
                            Preview.BackgroundColor3 = Preview3
                            HexInput.Text = ToHex(Preview3)
                        end

                        UpdateUI()

                        local HueDragging = false
                        local SVDragging = false

                        local function UpdateHue(Position)
                            if HueBar.AbsoluteSize.X <= 0 then
                                return
                            end
                            CurrentH = math.clamp((Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                            UpdateUI()
                        end

                        local function UpdateSV(Position)
                            if SVSquare.AbsoluteSize.X <= 0 or SVSquare.AbsoluteSize.Y <= 0 then
                                return
                            end
                            CurrentS = math.clamp((Position.X - SVSquare.AbsolutePosition.X) / SVSquare.AbsoluteSize.X, 0, 1)
                            CurrentV = 1 - math.clamp((Position.Y - SVSquare.AbsolutePosition.Y) / SVSquare.AbsoluteSize.Y, 0, 1)
                            UpdateUI()
                        end

                        HueBar.InputBegan:Connect(function(Input)
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                                HueDragging = true
                                UpdateHue(Input.Position)
                            end
                        end)

                        SVHit.InputBegan:Connect(function(Input)
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                                SVDragging = true
                                UpdateSV(Input.Position)
                            end
                        end)

                        local ColorConnection
                        ColorConnection = UserInputService.InputChanged:Connect(function(Input)
                            if not Popup.Parent then
                                ColorConnection:Disconnect()
                                return
                            end
                            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                                if HueDragging then
                                    UpdateHue(Input.Position)
                                end
                                if SVDragging then
                                    UpdateSV(Input.Position)
                                end
                            end
                        end)

                        UserInputService.InputEnded:Connect(function(Input)
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                                HueDragging = false
                                SVDragging = false
                            end
                        end)

                        HexInput.FocusLost:Connect(function()
                            local Parsed = FromHex(HexInput.Text)
                            if Parsed then
                                CurrentH, CurrentS, CurrentV = Color3.toHSV(Parsed)
                            end
                            UpdateUI()
                        end)

                        Cancel.MouseButton1Click:Connect(function()
                            ColorConnection:Disconnect()
                            ClosePopup()
                        end)

                        Apply.MouseButton1Click:Connect(function()
                            ColorFunc:Set(Preview.BackgroundColor3)
                            ColorConnection:Disconnect()
                            ClosePopup()
                        end)
                    end)
                end)

                task.defer(function()
                    ColorFunc:Set(ColorFunc.Value)
                end)

                return ColorFunc
            end

            function SectionFunc:AddKeybind(cfkey)
                local cfkey = Library:MakeConfig({
                    Title = "Keybind",
                    Description = "",
                    Default = Enum.KeyCode.Unknown,
                    Callback = function() end,
                    OnPress = nil
                }, cfkey or {})

                local Keybind, Title_K, Content_K, Stroke = MakeRow("Keybind", cfkey.Title, cfkey.Description, 114)
                RowHover(Keybind, Stroke)

                local KeyFrame = Instance.new("Frame")
                KeyFrame.Name = "KeyFrame"
                KeyFrame.Parent = Keybind
                KeyFrame.AnchorPoint = Vector2.new(1, 0.5)
                KeyFrame.BorderSizePixel = 0
                KeyFrame.Position = UDim2.new(1, -12, 0.5, 0)
                KeyFrame.Size = UDim2.new(0, 86, 0, 26)
                Library:Themed(KeyFrame, "BackgroundColor3", "Background")
                Library:Corner(KeyFrame, 7)
                local KeyStroke = Library:Stroke(KeyFrame, Library.Theme.Stroke, 0.82, 1)

                local KeyText = Instance.new("TextLabel")
                KeyText.Parent = KeyFrame
                KeyText.BackgroundTransparency = 1
                KeyText.Size = UDim2.new(1, -10, 1, 0)
                KeyText.Position = UDim2.new(0, 5, 0, 0)
                KeyText.Font = Enum.Font.GothamBold
                KeyText.Text = "None"
                KeyText.TextSize = 11
                KeyText.TextTruncate = Enum.TextTruncate.AtEnd
                Library:Themed(KeyText, "TextColor3", "Text")

                local KeyBtn = Instance.new("TextButton")
                KeyBtn.Parent = KeyFrame
                KeyBtn.BackgroundTransparency = 1
                KeyBtn.Size = UDim2.new(1, 0, 1, 0)
                KeyBtn.Text = ""
                KeyBtn.AutoButtonColor = false

                Library:UpdateContent(Content_K, Title_K, Keybind)

                local function ToKeyCode(Value)
                    if typeof(Value) == "EnumItem" then
                        return Value
                    end
                    if type(Value) == "string" then
                        local Ok, Key = pcall(function()
                            return Enum.KeyCode[Value]
                        end)
                        if Ok and Key then
                            return Key
                        end
                    end
                    return Enum.KeyCode.Unknown
                end

                local KeyFunc = { Value = ToKeyCode(cfkey.Default) }
                local Listening = false

                function KeyFunc:Set(Key, Silent)
                    KeyFunc.Value = ToKeyCode(Key)
                    KeyText.Text = KeyFunc.Value == Enum.KeyCode.Unknown and "None" or KeyFunc.Value.Name
                    if not Silent then
                        cfkey.Callback(KeyFunc.Value)
                    end
                end

                KeyFunc:Set(KeyFunc.Value, true)

                KeyBtn.MouseButton1Click:Connect(function()
                    if Listening then
                        return
                    end
                    Listening = true
                    KeyText.Text = "..."
                    Library:TweenInstance(KeyStroke, 0.2, "Transparency", 0.3)
                    Library:TweenInstance(KeyStroke, 0.2, "Color", Library.Theme.Accent)

                    local Connection
                    Connection = UserInputService.InputBegan:Connect(function(Input, Processed)
                        if Processed then
                            return
                        end
                        if Input.UserInputType == Enum.UserInputType.Keyboard then
                            Connection:Disconnect()
                            Listening = false
                            Library:TweenInstance(KeyStroke, 0.2, "Transparency", 0.82)
                            Library:TweenInstance(KeyStroke, 0.2, "Color", Library.Theme.Stroke)
                            if Input.KeyCode == Enum.KeyCode.Escape then
                                KeyFunc:Set(Enum.KeyCode.Unknown)
                            else
                                KeyFunc:Set(Input.KeyCode)
                            end
                        end
                    end)
                end)

                UserInputService.InputBegan:Connect(function(Input, Processed)
                    if Processed or Listening then
                        return
                    end
                    if Input.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end
                    if KeyFunc.Value ~= Enum.KeyCode.Unknown and Input.KeyCode == KeyFunc.Value then
                        Library:Flash(KeyFrame)
                        if cfkey.OnPress then
                            cfkey.OnPress(KeyFunc.Value)
                        end
                    end
                end)

                return KeyFunc
            end

            function SectionFunc:AddParagraph(cfpara)
                local cfpara = Library:MakeConfig({
                    Title = "Paragraph < Missing Title >",
                    Content = ""
                }, cfpara or {})

                local Paragraph = Instance.new("Frame")
                Paragraph.Name = "Paragraph"
                Paragraph.Parent = SectionList
                Paragraph.BorderSizePixel = 0
                Paragraph.Size = UDim2.new(1, 0, 0, 46)
                Library:Themed(Paragraph, "BackgroundColor3", "Surface")
                Library:Themed(Paragraph, "BackgroundTransparency", "SurfaceAlpha")
                Library:Corner(Paragraph, 7)
                Library:Stroke(Paragraph, Library.Theme.Stroke, 0.93, 1)

                local Bar = Instance.new("Frame")
                Bar.Parent = Paragraph
                Bar.AnchorPoint = Vector2.new(0, 0.5)
                Bar.BorderSizePixel = 0
                Bar.Position = UDim2.new(0, 0, 0.5, 0)
                Bar.Size = UDim2.new(0, 3, 1, -16)
                Library:Themed(Bar, "BackgroundColor3", "Accent")
                Library:Corner(Bar, UDim.new(1, 0))

                local Title_6 = Instance.new("TextLabel")
                Title_6.Name = "Title"
                Title_6.Parent = Paragraph
                Title_6.BackgroundTransparency = 1
                Title_6.BorderSizePixel = 0
                Title_6.Position = UDim2.new(0, 14, 0, 7)
                Title_6.Size = UDim2.new(1, -24, 0, 17)
                Title_6.Font = Enum.Font.GothamBold
                Title_6.Text = cfpara.Title
                Title_6.TextSize = 13
                Title_6.TextXAlignment = Enum.TextXAlignment.Left
                Library:Themed(Title_6, "TextColor3", "Text")

                local Content_4 = Instance.new("TextLabel")
                Content_4.Name = "Content"
                Content_4.Parent = Paragraph
                Content_4.BackgroundTransparency = 1
                Content_4.BorderSizePixel = 0
                Content_4.Position = UDim2.new(0, 14, 0, 24)
                Content_4.Size = UDim2.new(1, -24, 1, 0)
                Content_4.Font = Enum.Font.Gotham
                Content_4.Text = cfpara.Content
                Content_4.TextSize = 11
                Content_4.TextWrapped = true
                Content_4.TextXAlignment = Enum.TextXAlignment.Left
                Content_4.TextYAlignment = Enum.TextYAlignment.Top
                Library:Themed(Content_4, "TextColor3", "TextDisabled")

                local function Resize()
                    Paragraph.Size = UDim2.new(1, 0, 0, math.max(Content_4.TextBounds.Y + 34, 46))
                end

                Content_4:GetPropertyChangedSignal("TextBounds"):Connect(Resize)
                task.defer(Resize)

                Register("Paragraph", cfpara.Title, Paragraph, Title_6)

                local ParaFunc = {}

                function ParaFunc:SetTitle(Value)
                    Title_6.Text = tostring(Value)
                end

                function ParaFunc:SetDesc(Value)
                    Content_4.Text = tostring(Value)
                    task.defer(Resize)
                end

                return ParaFunc
            end

            function SectionFunc:AddSeperator(args)
                local Seperator = Instance.new("Frame")
                Seperator.Name = "Seperator"
                Seperator.Parent = SectionList
                Seperator.BackgroundTransparency = 1
                Seperator.BorderSizePixel = 0
                Seperator.Size = UDim2.new(1, 0, 0, 22)

                local Title_5 = Instance.new("TextLabel")
                Title_5.Name = "Title"
                Title_5.Parent = Seperator
                Title_5.BackgroundTransparency = 1
                Title_5.BorderSizePixel = 0
                Title_5.Position = UDim2.new(0, 2, 0, 0)
                Title_5.Size = UDim2.new(1, -4, 1, 0)
                Title_5.Font = Enum.Font.GothamBold
                Title_5.Text = tostring(args or "")
                Title_5.TextSize = 11
                Title_5.TextXAlignment = Enum.TextXAlignment.Left
                Library:Themed(Title_5, "TextColor3", "TextDisabled")

                return Seperator
            end

            function SectionFunc:AddDivider()
                local Divider = Instance.new("Frame")
                Divider.Name = "Divider"
                Divider.Parent = SectionList
                Divider.BorderSizePixel = 0
                Divider.Size = UDim2.new(1, 0, 0, 1)
                Library:Themed(Divider, "BackgroundColor3", "Accent")
                Library:FadeLine(Divider, Library.Theme.Accent, true)
                return Divider
            end

            function SectionFunc:AddSpace(amount)
                local Space = Instance.new("Frame")
                Space.Name = "Space"
                Space.Parent = SectionList
                Space.BackgroundTransparency = 1
                Space.BorderSizePixel = 0
                Space.Size = UDim2.new(1, 0, 0, amount or 10)
                return Space
            end

            function SectionFunc:AddTag(cftag)
                local cftag = Library:MakeConfig({
                    Title = "Tag",
                    Color = Library.Theme.Accent
                }, cftag or {})

                local Tag = Instance.new("Frame")
                Tag.Name = "Tag"
                Tag.Parent = SectionList
                Tag.AutomaticSize = Enum.AutomaticSize.X
                Tag.BackgroundColor3 = cftag.Color
                Tag.BackgroundTransparency = 0.12
                Tag.BorderSizePixel = 0
                Tag.Size = UDim2.new(0, 0, 0, 20)
                Library:Corner(Tag, 6)
                Library:Padding(Tag, 0, 0, 9, 9)

                local Title_T = Instance.new("TextLabel")
                Title_T.Name = "Title"
                Title_T.Parent = Tag
                Title_T.AutomaticSize = Enum.AutomaticSize.X
                Title_T.BackgroundTransparency = 1
                Title_T.Size = UDim2.new(0, 0, 1, 0)
                Title_T.Font = Enum.Font.GothamBold
                Title_T.Text = cftag.Title
                Title_T.TextColor3 = Color3.fromRGB(255, 255, 255)
                Title_T.TextSize = 10

                return Tag
            end

            function SectionFunc:AddMultiButton(cfmb)
                local cfmb = Library:MakeConfig({
                    Title = nil,
                    Buttons = {
                        { Title = "Button 1", Callback = function() end },
                        { Title = "Button 2", Callback = function() end }
                    }
                }, cfmb or {})

                local Holder = Instance.new("Frame")
                Holder.Name = "MultiButton"
                Holder.Parent = SectionList
                Holder.BackgroundTransparency = 1
                Holder.BorderSizePixel = 0
                Holder.Size = UDim2.new(1, 0, 0, 0)
                Holder.AutomaticSize = Enum.AutomaticSize.Y

                local Rows = 0
                if cfmb.Title and cfmb.Title ~= "" then
                    local Label = Instance.new("TextLabel")
                    Label.Parent = Holder
                    Label.BackgroundTransparency = 1
                    Label.Size = UDim2.new(1, 0, 0, 20)
                    Label.Font = Enum.Font.GothamBold
                    Label.Text = cfmb.Title
                    Label.TextSize = 13
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Library:Themed(Label, "TextColor3", "Text")
                    Rows = 1
                end

                local Row = Instance.new("Frame")
                Row.Parent = Holder
                Row.BackgroundTransparency = 1
                Row.BorderSizePixel = 0
                Row.Position = UDim2.new(0, 0, 0, Rows == 1 and 26 or 0)
                Row.Size = UDim2.new(1, 0, 0, 34)
                Row.ClipsDescendants = true

                local RowList = Instance.new("UIListLayout")
                RowList.Parent = Row
                RowList.FillDirection = Enum.FillDirection.Horizontal
                RowList.SortOrder = Enum.SortOrder.LayoutOrder
                RowList.Padding = UDim.new(0, 8)

                local Count = math.max(1, #cfmb.Buttons)
                for i, BtnCfg in ipairs(cfmb.Buttons) do
                    local Primary = (i == 1)
                    local Button = Instance.new("TextButton")
                    Button.Parent = Row
                    Button.LayoutOrder = i
                    Button.BackgroundTransparency = Primary and 0.05 or 0.9
                    Button.BorderSizePixel = 0
                    Button.Size = UDim2.new(1 / Count, -6, 1, 0)
                    Button.Font = Enum.Font.GothamBold
                    Button.Text = BtnCfg.Title or ("Button " .. i)
                    Button.TextSize = 12
                    Button.AutoButtonColor = false
                    Library:Corner(Button, 8)

                    if Primary then
                        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Library:Themed(Button, "BackgroundColor3", "Accent")
                        Library:Hover(Button, Button, "BackgroundTransparency", 0.05, 0.25)
                    else
                        Library:Themed(Button, "BackgroundColor3", "Surface")
                        Library:Themed(Button, "TextColor3", "Text")
                        Library:Stroke(Button, Library.Theme.Stroke, 0.9, 1)
                        Library:Hover(Button, Button, "BackgroundTransparency", 0.9, 0.78)
                    end

                    Button.MouseButton1Click:Connect(function()
                        Library:Flash(Button)
                        if BtnCfg.Callback then
                            BtnCfg.Callback()
                        end
                    end)

                    Register("Button", BtnCfg.Title or ("Button " .. i), Row, Button)
                end

                return Holder
            end

            function SectionFunc:AddCodeblock(cfcode)
                local cfcode = Library:MakeConfig({
                    Title = "Code",
                    Code = "print('hello')",
                    Callback = function() end
                }, cfcode or {})

                local Code = Instance.new("Frame")
                Code.Name = "Codeblock"
                Code.Parent = SectionList
                Code.BorderSizePixel = 0
                Code.Size = UDim2.new(1, 0, 0, 146)
                Library:Themed(Code, "BackgroundColor3", "Elevated")
                Library:Corner(Code, 9)
                Library:Stroke(Code, Library.Theme.Stroke, 0.9, 1)

                local Title_CD = Instance.new("TextLabel")
                Title_CD.Parent = Code
                Title_CD.BackgroundTransparency = 1
                Title_CD.Position = UDim2.new(0, 12, 0, 7)
                Title_CD.Size = UDim2.new(1, -24, 0, 18)
                Title_CD.Font = Enum.Font.GothamBold
                Title_CD.Text = cfcode.Title
                Title_CD.TextSize = 12
                Title_CD.TextXAlignment = Enum.TextXAlignment.Left
                Library:Themed(Title_CD, "TextColor3", "Text")

                local CodeBox = Instance.new("TextBox")
                CodeBox.Parent = Code
                CodeBox.BackgroundTransparency = 0.94
                CodeBox.BorderSizePixel = 0
                CodeBox.Position = UDim2.new(0, 10, 0, 28)
                CodeBox.Size = UDim2.new(1, -20, 0, 74)
                CodeBox.Font = Enum.Font.Code
                CodeBox.Text = cfcode.Code
                CodeBox.TextSize = 12
                CodeBox.TextXAlignment = Enum.TextXAlignment.Left
                CodeBox.TextYAlignment = Enum.TextYAlignment.Top
                CodeBox.ClearTextOnFocus = false
                CodeBox.MultiLine = true
                CodeBox.TextWrapped = true
                Library:Themed(CodeBox, "BackgroundColor3", "Surface")
                Library:Themed(CodeBox, "TextColor3", "Text")
                Library:Corner(CodeBox, 7)
                Library:Padding(CodeBox, 6, 6, 8, 8)

                local RunBtn = Instance.new("TextButton")
                RunBtn.Parent = Code
                RunBtn.BackgroundTransparency = 0.05
                RunBtn.BorderSizePixel = 0
                RunBtn.Position = UDim2.new(0, 10, 1, -36)
                RunBtn.Size = UDim2.new(0.5, -13, 0, 28)
                RunBtn.Font = Enum.Font.GothamBold
                RunBtn.Text = "Run"
                RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                RunBtn.TextSize = 12
                RunBtn.AutoButtonColor = false
                Library:Themed(RunBtn, "BackgroundColor3", "Accent")
                Library:Corner(RunBtn, 7)
                Library:Hover(RunBtn, RunBtn, "BackgroundTransparency", 0.05, 0.25)

                local CopyBtn = Instance.new("TextButton")
                CopyBtn.Parent = Code
                CopyBtn.AnchorPoint = Vector2.new(1, 0)
                CopyBtn.BackgroundTransparency = 0.9
                CopyBtn.BorderSizePixel = 0
                CopyBtn.Position = UDim2.new(1, -10, 1, -36)
                CopyBtn.Size = UDim2.new(0.5, -13, 0, 28)
                CopyBtn.Font = Enum.Font.GothamBold
                CopyBtn.Text = "Copy"
                CopyBtn.TextSize = 12
                CopyBtn.AutoButtonColor = false
                Library:Themed(CopyBtn, "BackgroundColor3", "Surface")
                Library:Themed(CopyBtn, "TextColor3", "Text")
                Library:Corner(CopyBtn, 7)
                Library:Hover(CopyBtn, CopyBtn, "BackgroundTransparency", 0.9, 0.78)

                RunBtn.MouseButton1Click:Connect(function()
                    Library:Flash(RunBtn, Color3.fromRGB(255, 255, 255))
                    local Ok, Err = pcall(function()
                        loadstring(CodeBox.Text)()
                    end)
                    if not Ok then
                        warn("[sh1ttybanana] Code error:", Err)
                    end
                    cfcode.Callback(CodeBox.Text)
                end)

                CopyBtn.MouseButton1Click:Connect(function()
                    Library:Flash(CopyBtn)
                    if setclipboard then
                        pcall(setclipboard, CodeBox.Text)
                    end
                end)

                Register("Codeblock", cfcode.Title, Code, Title_CD)
                return { Frame = Code, Box = CodeBox }
            end

              function SectionFunc:AddProgress(cfg)
                cfg = Library:MakeConfig({ Title = "Progress", Description = "", Value = 0, Max = 100 }, cfg or {})
                local RowP, TitleP, ContentP, StrokeP = MakeRow("Progress", cfg.Title, cfg.Description, 170)
                RowHover(RowP, StrokeP)
                local TrackP = Instance.new("Frame")
                TrackP.Parent = RowP
                TrackP.AnchorPoint = Vector2.new(1, 0.5)
                TrackP.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                TrackP.BorderSizePixel = 0
                TrackP.Position = UDim2.new(1, -12, 0.5, 0)
                TrackP.Size = UDim2.new(0, 130, 0, 6)
                Library:Corner(TrackP, UDim.new(1, 0))
                local FillP = Instance.new("Frame")
                FillP.Parent = TrackP
                FillP.BorderSizePixel = 0
                FillP.Size = UDim2.new(0, 0, 1, 0)
                Library:Themed(FillP, "BackgroundColor3", "Accent")
                Library:Corner(FillP, UDim.new(1, 0))
                local PctP = Instance.new("TextLabel")
                PctP.Parent = RowP
                PctP.AnchorPoint = Vector2.new(1, 0.5)
                PctP.BackgroundTransparency = 1
                PctP.Position = UDim2.new(1, -148, 0.5, 0)
                PctP.Size = UDim2.new(0, 32, 0, 18)
                PctP.Font = Enum.Font.GothamBold
                PctP.TextSize = 10
                PctP.TextXAlignment = Enum.TextXAlignment.Right
                Library:Themed(PctP, "TextColor3", "TextDisabled")
                Library:UpdateContent(ContentP, TitleP, RowP)
                local PF = { Value = cfg.Value }
                function PF:Set(v)
                    v = math.clamp(tonumber(v) or 0, 0, cfg.Max)
                    PF.Value = v
                    local pct = cfg.Max > 0 and v / cfg.Max or 0
                    Library:Tween(FillP, TweenInfo.new(0.3, Quart, Out), { Size = UDim2.new(pct, 0, 1, 0) })
                    PctP.Text = math.floor(pct * 100 + 0.5) .. "%"
                end
                PF:Set(cfg.Value)
                return PF
            end

            function SectionFunc:AddColorpickerRGB(cfg)
                cfg = Library:MakeConfig({ Title = "Color RGB", Default = Color3.fromRGB(255,255,255), Callback = function() end }, cfg or {})
                local rV = math.floor(cfg.Default.R*255+0.5)
                local gV = math.floor(cfg.Default.G*255+0.5)
                local bV = math.floor(cfg.Default.B*255+0.5)
                local SecRGB = Instance.new("Frame")
                SecRGB.Name = "ColorRGB"
                SecRGB.Parent = SectionList
                SecRGB.BackgroundTransparency = Library.Theme.SurfaceAlpha
                SecRGB.BorderSizePixel = 0
                SecRGB.Size = UDim2.new(1, 0, 0, 82)
                Library:Themed(SecRGB, "BackgroundColor3", "Surface")
                Library:Corner(SecRGB, 7)
                Library:Stroke(SecRGB, Library.Theme.Stroke, 0.93, 1)
                local TRgb = Instance.new("TextLabel")
                TRgb.Parent = SecRGB
                TRgb.BackgroundTransparency = 1
                TRgb.Position = UDim2.new(0, 12, 0, 8)
                TRgb.Size = UDim2.new(0, 140, 0, 16)
                TRgb.Font = Enum.Font.GothamBold
                TRgb.Text = cfg.Title
                TRgb.TextSize = 13
                TRgb.TextXAlignment = Enum.TextXAlignment.Left
                Library:Themed(TRgb, "TextColor3", "Text")
                local PrevRGB = Instance.new("Frame")
                PrevRGB.Parent = SecRGB
                PrevRGB.AnchorPoint = Vector2.new(1, 0)
                PrevRGB.BackgroundColor3 = cfg.Default
                PrevRGB.BorderSizePixel = 0
                PrevRGB.Position = UDim2.new(1, -12, 0, 8)
                PrevRGB.Size = UDim2.new(0, 28, 0, 28)
                Library:Corner(PrevRGB, 7)
                local CRGBFunc = { Value = cfg.Default }
                local rgbSliders = {}
                local function UpdateRGB()
                    local col = Color3.fromRGB(math.clamp(rgbSliders[1].v,0,255), math.clamp(rgbSliders[2].v,0,255), math.clamp(rgbSliders[3].v,0,255))
                    CRGBFunc.Value = col
                    PrevRGB.BackgroundColor3 = col
                    cfg.Callback(col)
                end
                local rgbLabels = {"R","G","B"}
                local rgbDefs = {rV, gV, bV}
                local rgbColors = {Color3.fromRGB(220,60,60), Color3.fromRGB(60,200,60), Color3.fromRGB(60,120,255)}
                for ri = 1, 3 do
                    local xOff = 12 + (ri-1) * 84
                    local CLbl = Instance.new("TextLabel")
                    CLbl.Parent = SecRGB
                    CLbl.BackgroundTransparency = 1
                    CLbl.Position = UDim2.new(0, xOff, 0, 30)
                    CLbl.Size = UDim2.new(0, 80, 0, 12)
                    CLbl.Font = Enum.Font.GothamBold
                    CLbl.Text = rgbLabels[ri]
                    CLbl.TextSize = 10
                    CLbl.TextColor3 = rgbColors[ri]
                    CLbl.TextXAlignment = Enum.TextXAlignment.Left
                    local TrkR = Instance.new("Frame")
                    TrkR.Parent = SecRGB
                    TrkR.BackgroundColor3 = Color3.fromRGB(50,50,60)
                    TrkR.BorderSizePixel = 0
                    TrkR.Position = UDim2.new(0, xOff, 0, 44)
                    TrkR.Size = UDim2.new(0, 74, 0, 5)
                    Library:Corner(TrkR, UDim.new(1,0))
                    local FilR = Instance.new("Frame")
                    FilR.Parent = TrkR
                    FilR.BackgroundColor3 = rgbColors[ri]
                    FilR.BorderSizePixel = 0
                    FilR.Size = UDim2.new(rgbDefs[ri]/255, 0, 1, 0)
                    Library:Corner(FilR, UDim.new(1,0))
                    local VbR = Instance.new("TextBox")
                    VbR.Parent = SecRGB
                    VbR.BackgroundTransparency = 0
                    VbR.BorderSizePixel = 0
                    VbR.Position = UDim2.new(0, xOff, 0, 52)
                    VbR.Size = UDim2.new(0, 74, 0, 20)
                    VbR.Font = Enum.Font.GothamBold
                    VbR.Text = tostring(rgbDefs[ri])
                    VbR.TextSize = 11
                    VbR.ClearTextOnFocus = false
                    Library:Themed(VbR, "BackgroundColor3", "Background")
                    Library:Themed(VbR, "TextColor3", "Text")
                    Library:Corner(VbR, 5)
                    local sd = { v = rgbDefs[ri], fil = FilR }
                    rgbSliders[ri] = sd
                    local dragR = false
                    local HitR = Instance.new("TextButton")
                    HitR.Parent = TrkR
                    HitR.BackgroundTransparency = 1
                    HitR.Size = UDim2.new(1, 0, 1, 14)
                    HitR.Position = UDim2.new(0,0,0,-4)
                    HitR.Text = ""
                    HitR.AutoButtonColor = false
                    HitR.ZIndex = 3
                    local function UpdR(pos)
                        local w = TrkR.AbsoluteSize.X
                        if w <= 0 then return end
                        local p = math.clamp((pos.X - TrkR.AbsolutePosition.X) / w, 0, 1)
                        local val = math.floor(p * 255 + 0.5)
                        sd.v = val
                        FilR.Size = UDim2.new(p, 0, 1, 0)
                        VbR.Text = tostring(val)
                        UpdateRGB()
                    end
                    HitR.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragR = true UpdR(inp.Position) end end)
                    UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragR = false end end)
                    UserInputService.InputChanged:Connect(function(inp) if dragR and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then UpdR(inp.Position) end end)
                    VbR.FocusLost:Connect(function()
                        local n = math.clamp(tonumber(VbR.Text) or sd.v, 0, 255)
                        sd.v = n VbR.Text = tostring(n) FilR.Size = UDim2.new(n/255,0,1,0) UpdateRGB()
                    end)
                end
                Register("ColorpickerRGB", cfg.Title, SecRGB, TRgb)
                function CRGBFunc:Set(col, silent)
                    CRGBFunc.Value = col
                    PrevRGB.BackgroundColor3 = col
                    rgbSliders[1].v = math.floor(col.R*255+0.5)
                    rgbSliders[2].v = math.floor(col.G*255+0.5)
                    rgbSliders[3].v = math.floor(col.B*255+0.5)
                    for _, s in ipairs(rgbSliders) do s.fil.Size = UDim2.new(s.v/255,0,1,0) end
                    if not silent then cfg.Callback(col) end
                end
                return CRGBFunc
            end

            function SectionFunc:AddGrid(cfg)
                cfg = Library:MakeConfig({ Title = "Grid", Items = {}, Columns = 4, Default = {}, Callback = function() end }, cfg or {})
                local gridRows = math.ceil(#cfg.Items / math.max(cfg.Columns, 1))
                local GHolder = Instance.new("Frame")
                GHolder.Name = "Grid"
                GHolder.Parent = SectionList
                GHolder.BackgroundTransparency = Library.Theme.SurfaceAlpha
                GHolder.BorderSizePixel = 0
                GHolder.Size = UDim2.new(1, 0, 0, 32 + gridRows * 34)
                Library:Themed(GHolder, "BackgroundColor3", "Surface")
                Library:Corner(GHolder, 7)
                Library:Stroke(GHolder, Library.Theme.Stroke, 0.93, 1)
                local GTitle = Instance.new("TextLabel")
                GTitle.Parent = GHolder
                GTitle.BackgroundTransparency = 1
                GTitle.Position = UDim2.new(0, 12, 0, 8)
                GTitle.Size = UDim2.new(1, -24, 0, 16)
                GTitle.Font = Enum.Font.GothamBold
                GTitle.Text = cfg.Title
                GTitle.TextSize = 13
                GTitle.TextXAlignment = Enum.TextXAlignment.Left
                Library:Themed(GTitle, "TextColor3", "Text")
                local GFrame = Instance.new("Frame")
                GFrame.Parent = GHolder
                GFrame.BackgroundTransparency = 1
                GFrame.BorderSizePixel = 0
                GFrame.Position = UDim2.new(0, 8, 0, 28)
                GFrame.Size = UDim2.new(1, -16, 1, -36)
                local GLayout = Instance.new("UIGridLayout")
                GLayout.Parent = GFrame
                GLayout.CellPadding = UDim2.new(0, 5, 0, 5)
                GLayout.CellSize = UDim2.new(1/cfg.Columns, -5, 0, 28)
                GLayout.SortOrder = Enum.SortOrder.LayoutOrder
                local gsel = {}
                for _, v in ipairs(cfg.Default) do gsel[v] = true end
                local GF = { Selected = gsel }
                for gi, item in ipairs(cfg.Items) do
                    local Cell = Instance.new("TextButton")
                    Cell.Parent = GFrame
                    Cell.BorderSizePixel = 0
                    Cell.LayoutOrder = gi
                    Cell.Font = Enum.Font.GothamBold
                    Cell.Text = tostring(item)
                    Cell.TextSize = 11
                    Cell.AutoButtonColor = false
                    Cell.BackgroundTransparency = gsel[item] and 0.1 or 0.88
                    if gsel[item] then Library:Themed(Cell, "BackgroundColor3", "Accent") Cell.TextColor3 = Color3.fromRGB(255,255,255)
                    else Library:Themed(Cell, "BackgroundColor3", "Surface") Library:Themed(Cell, "TextColor3", "TextDisabled") end
                    Library:Corner(Cell, 6)
                    Cell.MouseButton1Click:Connect(function()
                        gsel[item] = not gsel[item]
                        Library:TweenInstance(Cell, 0.2, "BackgroundTransparency", gsel[item] and 0.1 or 0.88)
                        if gsel[item] then Library:TweenInstance(Cell, 0.2, "BackgroundColor3", Library.Theme.Accent) Library:TweenInstance(Cell, 0.2, "TextColor3", Color3.fromRGB(255,255,255))
                        else Library:TweenInstance(Cell, 0.2, "BackgroundColor3", Library.Theme.Surface) Library:TweenInstance(Cell, 0.2, "TextColor3", Library.Theme.TextDisabled) end
                        local res = {}
                        for k, v in pairs(gsel) do if v then table.insert(res, k) end end
                        GF.Selected = gsel
                        cfg.Callback(res)
                    end)
                end
                Register("Grid", cfg.Title, GHolder, GTitle)
                return GF
            end

            function SectionFunc:AddTable(cfg)
                cfg = Library:MakeConfig({ Title = "Table", Headers = {}, Rows = {} }, cfg or {})
                local rH = 28
                local tH = 42 + (#cfg.Headers > 0 and rH or 0) + #cfg.Rows * rH
                local TH = Instance.new("Frame")
                TH.Name = "Table"
                TH.Parent = SectionList
                TH.BackgroundTransparency = Library.Theme.SurfaceAlpha
                TH.BorderSizePixel = 0
                TH.Size = UDim2.new(1, 0, 0, tH)
                Library:Themed(TH, "BackgroundColor3", "Surface")
                Library:Corner(TH, 7)
                Library:Stroke(TH, Library.Theme.Stroke, 0.93, 1)
                local TTl = Instance.new("TextLabel")
                TTl.Parent = TH
                TTl.BackgroundTransparency = 1
                TTl.Position = UDim2.new(0, 12, 0, 8)
                TTl.Size = UDim2.new(1, -24, 0, 16)
                TTl.Font = Enum.Font.GothamBold
                TTl.Text = cfg.Title
                TTl.TextSize = 13
                TTl.TextXAlignment = Enum.TextXAlignment.Left
                Library:Themed(TTl, "TextColor3", "Text")
                local function MkRow(data, isHdr, rIdx)
                    local RF = Instance.new("Frame")
                    RF.Parent = TH
                    RF.BackgroundTransparency = isHdr and 0.88 or (rIdx % 2 == 0 and 0.97 or 1)
                    RF.BorderSizePixel = 0
                    RF.Position = UDim2.new(0, 8, 0, 28 + rIdx * rH)
                    RF.Size = UDim2.new(1, -16, 0, rH)
                    if isHdr then Library:Themed(RF, "BackgroundColor3", "Accent")
                    else Library:Themed(RF, "BackgroundColor3", "Surface") end
                    Library:Corner(RF, 5)
                    for ci, cell in ipairs(data) do
                        local cw = 1 / #data
                        local CL = Instance.new("TextLabel")
                        CL.Parent = RF
                        CL.BackgroundTransparency = 1
                        CL.Position = UDim2.new((ci-1)*cw, 4, 0, 0)
                        CL.Size = UDim2.new(cw, -8, 1, 0)
                        CL.Font = isHdr and Enum.Font.GothamBold or Enum.Font.GothamMedium
                        CL.Text = tostring(cell)
                        CL.TextSize = 11
                        CL.TextXAlignment = Enum.TextXAlignment.Left
                        CL.TextTruncate = Enum.TextTruncate.AtEnd
                        if isHdr then CL.TextColor3 = Color3.fromRGB(255,255,255)
                        else Library:Themed(CL, "TextColor3", "Text") end
                    end
                end
                if #cfg.Headers > 0 then MkRow(cfg.Headers, true, 0) end
                for ri, row in ipairs(cfg.Rows) do MkRow(row, false, (#cfg.Headers > 0 and ri or ri-1)) end
                Register("Table", cfg.Title, TH, nil)
                return { Frame = TH }
            end

            function SectionFunc:AddImage(cfg)
                cfg = Library:MakeConfig({ Title = "", Asset = "rbxassetid://0", Height = 120, Rounded = true }, cfg or {})
                local IH = Instance.new("Frame")
                IH.Name = "Image"
                IH.Parent = SectionList
                IH.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
                IH.BorderSizePixel = 0
                IH.Size = UDim2.new(1, 0, 0, cfg.Height + (cfg.Title ~= "" and 30 or 0))
                Library:Corner(IH, 9)
                Library:Stroke(IH, Library.Theme.Stroke, 0.88, 1)
                if cfg.Title ~= "" then
                    local IT = Instance.new("TextLabel")
                    IT.Parent = IH
                    IT.BackgroundTransparency = 1
                    IT.Position = UDim2.new(0, 12, 0, 8)
                    IT.Size = UDim2.new(1, -24, 0, 16)
                    IT.Font = Enum.Font.GothamBold
                    IT.Text = cfg.Title
                    IT.TextSize = 13
                    IT.TextXAlignment = Enum.TextXAlignment.Left
                    Library:Themed(IT, "TextColor3", "Text")
                end
                local IL = Instance.new("ImageLabel")
                IL.Parent = IH
                IL.BackgroundTransparency = 1
                IL.BorderSizePixel = 0
                IL.Position = UDim2.new(0, 8, 0, cfg.Title ~= "" and 26 or 8)
                IL.Size = UDim2.new(1, -16, 0, cfg.Height - 16)
                IL.Image = cfg.Asset
                IL.ScaleType = Enum.ScaleType.Crop
                if cfg.Rounded then Library:Corner(IL, 7) end
                Register("Image", cfg.Title, IH, nil)
                return { Frame = IH, Image = IL }
            end

          return SectionFunc
        end

        function TabFunc:AddTabSection(cfg)
            if type(cfg) == "string" then
                cfg = { Title = cfg, Opened = true }
            end
            cfg = Library:MakeConfig({
                Title = "Section",
                Icon = nil,
                Opened = true
            }, cfg or {})

            local Opened = cfg.Opened ~= false

            local Card = Instance.new("Frame")
            Card.Name = "TabSection"
            Card.Parent = Layout
            Card.BackgroundTransparency = 0.96
            Card.BorderSizePixel = 0
            Card.Size = UDim2.new(1, 0, 0, 38)
            Library:Themed(Card, "BackgroundColor3", "Surface")
            Library:Corner(Card, 9)
            Library:Stroke(Card, Library.Theme.Stroke, 0.9, 1)

            local Header = Instance.new("TextButton")
            Header.Name = "Header"
            Header.Parent = Card
            Header.BackgroundTransparency = 1
            Header.BorderSizePixel = 0
            Header.Size = UDim2.new(1, 0, 0, 38)
            Header.Text = ""
            Header.AutoButtonColor = false

            local ArrowIcon = Instance.new("ImageLabel")
            ArrowIcon.Parent = Header
            ArrowIcon.AnchorPoint = Vector2.new(0, 0.5)
            ArrowIcon.BackgroundTransparency = 1
            ArrowIcon.BorderSizePixel = 0
            ArrowIcon.Position = UDim2.new(0, 12, 0.5, 0)
            ArrowIcon.Size = UDim2.new(0, 14, 0, 14)
            ArrowIcon.ZIndex = 2
            Library:SetIcon(ArrowIcon, Library.DefaultIcons.ChevronRight, Library.Theme.Accent)
            Library:Themed(ArrowIcon, "ImageColor3", "Accent")
            ArrowIcon.Rotation = Opened and 90 or 0

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Parent = Header
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.BorderSizePixel = 0
            TitleLbl.Position = UDim2.new(0, 34, 0, 0)
            TitleLbl.Size = UDim2.new(1, -46, 1, 0)
            TitleLbl.Font = Enum.Font.GothamBold
            TitleLbl.Text = cfg.Title
            TitleLbl.TextSize = 13
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            Library:Themed(TitleLbl, "TextColor3", "Text")

            local Body = Instance.new("Frame")
            Body.Name = "Body"
            Body.Parent = Card
            Body.BackgroundTransparency = 1
            Body.BorderSizePixel = 0
            Body.Position = UDim2.new(0, 0, 0, 38)
            Body.Size = UDim2.new(1, 0, 0, 0)
            Body.ClipsDescendants = true

            local Inner = TabFunc:AddSection(cfg.Title, Body, true)
            local InnerFrame = Inner._Frame

            local function Refresh(Animate)
                local Height = Opened and InnerFrame.AbsoluteSize.Y + 8 or 0
                if Animate then
                    Library:Tween(Body, TweenInfo.new(0.28, Quart, Out), { Size = UDim2.new(1, 0, 0, Height) })
                    Library:Tween(Card, TweenInfo.new(0.28, Quart, Out), { Size = UDim2.new(1, 0, 0, 38 + Height) })
                else
                    Body.Size = UDim2.new(1, 0, 0, Height)
                    Card.Size = UDim2.new(1, 0, 0, 38 + Height)
                end
            end

            InnerFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if Opened then
                    Refresh(false)
                end
            end)

            Header.MouseButton1Click:Connect(function()
                Opened = not Opened
                Library:Tween(ArrowIcon, TweenInfo.new(0.26, Back, Out), { Rotation = Opened and 90 or 0 })
                Refresh(true)
            end)

            Library:Hover(Header, Card, "BackgroundTransparency", 0.96, 0.9)

            task.defer(function()
                Refresh(false)
            end)
            task.delay(0.15, function()
                Refresh(false)
            end)

            return Inner
        end

        return TabFunc
    end

    WindowAPI = {}

    function WindowAPI:Section(cfg)
        if type(cfg) == "string" then
            cfg = { Title = cfg, Opened = true }
        end
        cfg = Library:MakeConfig({
            Title = "Section",
            Icon = nil,
            Opened = true
        }, cfg or {})

        local Opened = cfg.Opened ~= false
        local SectionTabs = {}

        local SecFrame = Instance.new("Frame")
        SecFrame.Name = "TabSection"
        SecFrame.Parent = ScrollingTab
        SecFrame.BackgroundTransparency = 1
        SecFrame.BorderSizePixel = 0
        SecFrame.Size = UDim2.new(1, 0, 0, 28)
        SecFrame.LayoutOrder = AllLayouts + 1

        local Header = Instance.new("TextButton")
        Header.Name = "Header"
        Header.Parent = SecFrame
        Header.BackgroundTransparency = 1
        Header.BorderSizePixel = 0
        Header.Size = UDim2.new(1, 0, 0, 28)
        Header.Text = ""
        Header.AutoButtonColor = false

        local Title = Instance.new("TextLabel")
        Title.Parent = Header
        Title.BackgroundTransparency = 1
        Title.BorderSizePixel = 0
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.Size = UDim2.new(1, -36, 1, 0)
        Title.Font = Enum.Font.GothamBold
        Title.Text = string.upper(cfg.Title)
        Title.TextSize = 10
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.TextTruncate = Enum.TextTruncate.AtEnd
        Library:Themed(Title, "TextColor3", "TextDisabled")

        local Chevron = Instance.new("ImageLabel")
        Chevron.Parent = Header
        Chevron.AnchorPoint = Vector2.new(1, 0.5)
        Chevron.BackgroundTransparency = 1
        Chevron.BorderSizePixel = 0
        Chevron.Position = UDim2.new(1, -8, 0.5, 0)
        Chevron.Size = UDim2.new(0, 12, 0, 12)
        Chevron.Visible = false
        Chevron.Rotation = Opened and 90 or 0
        Library:SetIcon(Chevron, Library.DefaultIcons.ChevronRight, Library.Theme.TextDisabled)
        Library:Themed(Chevron, "ImageColor3", "TextDisabled")

        local TabsHolder = Instance.new("Frame")
        TabsHolder.Name = "TabsHolder"
        TabsHolder.Parent = SecFrame
        TabsHolder.BackgroundTransparency = 1
        TabsHolder.BorderSizePixel = 0
        TabsHolder.Position = UDim2.new(0, 0, 0, 28)
        TabsHolder.Size = UDim2.new(1, 0, 0, 0)
        TabsHolder.Visible = Opened
        TabsHolder.ClipsDescendants = true

        local TabsLayout = Instance.new("UIListLayout")
        TabsLayout.Parent = TabsHolder
        TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabsLayout.Padding = UDim.new(0, 3)

        local function Refresh()
            local VisibleCount = 0
            for _, Item in ipairs(SectionTabs) do
                if Item.Visible then
                    VisibleCount = VisibleCount + 1
                end
            end

            local HasTabs = #SectionTabs > 0
            Chevron.Visible = HasTabs
            SecFrame.Visible = (not HasTabs) or VisibleCount > 0

            if HasTabs and Opened and VisibleCount > 0 then
                local Height = TabsLayout.AbsoluteContentSize.Y
                TabsHolder.Size = UDim2.new(1, 0, 0, Height)
                TabsHolder.Visible = true
                SecFrame.Size = UDim2.new(1, 0, 0, 28 + Height)
            else
                TabsHolder.Size = UDim2.new(1, 0, 0, 0)
                TabsHolder.Visible = false
                SecFrame.Size = UDim2.new(1, 0, 0, 28)
            end
        end

        TabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Refresh)

        Header.MouseButton1Click:Connect(function()
            if #SectionTabs == 0 then
                return
            end
            Opened = not Opened
            Library:Tween(Chevron, TweenInfo.new(0.26, Back, Out), { Rotation = Opened and 90 or 0 })
            Refresh()
        end)

        Library:Hover(Header, Title, "TextTransparency", 0, 0.4)

        table.insert(SectionRegistry, { Frame = SecFrame, Tabs = SectionTabs, Refresh = Refresh })

        local SectionAPI = {}

        function SectionAPI:Tab(nameOrConfig, iconName)
            local TabResult = Tab:T(nameOrConfig, iconName)
            local Entry = TabRegistry[#TabRegistry]
            if Entry and Entry.Frame then
                Entry.Frame.Parent = TabsHolder
                table.insert(SectionTabs, Entry.Frame)
                task.defer(Refresh)
            end
            return TabResult
        end

        function SectionAPI:T(...)
            return SectionAPI:Tab(...)
        end

        task.defer(Refresh)
        return SectionAPI
    end

    function WindowAPI:T(...)
        return Tab:T(...)
    end

    function WindowAPI:Tab(...)
        return Tab:T(...)
    end

    function WindowAPI:SelectTab(Name)
        return SelectTabByName(Name)
    end

    function WindowAPI:GetTabs()
        local Names = {}
        for _, Entry in ipairs(TabRegistry) do
            table.insert(Names, Entry.Name)
        end
        return Names
    end

    function WindowAPI:ToggleAI(State)
        ToggleAI(State)
    end

    function WindowAPI:TogglePlayerCard(State)
        TogglePlayerCard(State)
    end

    function WindowAPI:SetGroq(Key, Prompt, Model)
        Library:SetGroq(Key, Prompt, Model)
    end

    function WindowAPI:Toggle(State)
        if State == nil then
            State = not DropShadowHolder.Visible
        end
        ToggleWindow(State)
    end

    function WindowAPI:Destroy()
        ScreenGui:Destroy()
    end

    function WindowAPI:Tag(cfg)
        cfg = Library:MakeConfig({
            Title = "Tag",
            Color = Color3.fromRGB(48, 255, 106),
            Icon = nil
        }, cfg or {})

        local DescRow = Top:FindFirstChild("HeaderScroll") and Top.HeaderScroll:FindFirstChild("HeaderContent") and Top.HeaderScroll.HeaderContent:FindFirstChild("DescRow")
        local TagHolder = DescRow and DescRow:FindFirstChild("TagHolder")
        if not TagHolder then
            TagHolder = Instance.new("Frame")
            TagHolder.Name = "TagHolder"
            TagHolder.Parent = DescRow or Top
            TagHolder.LayoutOrder = 2
            TagHolder.BackgroundTransparency = 1
            TagHolder.BorderSizePixel = 0
            TagHolder.Size = UDim2.new(0, 0, 0, 22)
            TagHolder.AutomaticSize = Enum.AutomaticSize.X
            TagHolder.ZIndex = 6

            local TagList = Instance.new("UIListLayout")
            TagList.Parent = TagHolder
            TagList.FillDirection = Enum.FillDirection.Horizontal
            TagList.VerticalAlignment = Enum.VerticalAlignment.Center
            TagList.Padding = UDim.new(0, 6)
            TagList.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local Tag = Instance.new("Frame")
        Tag.Name = "Tag"
        Tag.Parent = TagHolder
        Tag.AutomaticSize = Enum.AutomaticSize.X
        Tag.BackgroundColor3 = cfg.Color
        Tag.BackgroundTransparency = 0.1
        Tag.BorderSizePixel = 0
        Tag.Size = UDim2.new(0, 0, 0, 22)
        Library:Corner(Tag, UDim.new(1, 0))
        Library:Padding(Tag, 0, 0, cfg.Icon and 7 or 11, 11)

        if cfg.Icon then
            local TagIcon = Instance.new("ImageLabel")
            TagIcon.Parent = Tag
            TagIcon.AnchorPoint = Vector2.new(0, 0.5)
            TagIcon.BackgroundTransparency = 1
            TagIcon.BorderSizePixel = 0
            TagIcon.Position = UDim2.new(0, 0, 0.5, 0)
            TagIcon.Size = UDim2.new(0, 12, 0, 12)
            Library:SetIcon(TagIcon, cfg.Icon, Color3.fromRGB(20, 20, 24))
        end

        local TagLabel = Instance.new("TextLabel")
        TagLabel.Parent = Tag
        TagLabel.AutomaticSize = Enum.AutomaticSize.X
        TagLabel.BackgroundTransparency = 1
        TagLabel.Position = UDim2.new(0, cfg.Icon and 16 or 0, 0, 0)
        TagLabel.Size = UDim2.new(0, 0, 1, 0)
        TagLabel.Font = Enum.Font.GothamBold
        TagLabel.Text = cfg.Title
        TagLabel.TextColor3 = Color3.fromRGB(20, 20, 24)
        TagLabel.TextSize = 11

        Library:Pop(Tag, 0.34, 0.7)
        table.insert(WindowTags, Tag)
        return Tag
    end

    function WindowAPI:SetTransparency(Value)
        Value = math.clamp(tonumber(Value) or 0.07, 0, 0.9)
        Library:TweenInstance(Main, 0.25, "BackgroundTransparency", Value)
        ConfigWindow.Transparent = Value
    end

    function WindowAPI:SetTitle(Value)
        NameHub.Text = tostring(Value)
        ConfigWindow.Title = tostring(Value)
    end

    function WindowAPI:SetDescription(Value)
        Desc.Text = tostring(Value)
        ConfigWindow.Description = tostring(Value)
    end

    function WindowAPI:SaveConfig(Name)
        Name = Name or "sh1ttybanana_config"
        if writefile then
            pcall(function()
                writefile(Name .. ".json", HttpService:JSONEncode(ConfigFlags))
            end)
        end
    end

    function WindowAPI:LoadConfig(Name)
        Name = Name or "sh1ttybanana_config"
        if readfile and isfile and isfile(Name .. ".json") then
            local Ok, Data = pcall(function()
                return HttpService:JSONDecode(readfile(Name .. ".json"))
            end)
            if Ok and type(Data) == "table" then
                ConfigFlags = Data
            end
        end
        return ConfigFlags
    end

    function WindowAPI:SetFlag(Flag, Value)
        ConfigFlags[Flag] = Value
    end

    function WindowAPI:GetFlag(Flag)
        return ConfigFlags[Flag]
    end

    function WindowAPI:Dialog(cfg)
        cfg = Library:MakeConfig({
            Title = "Dialog",
            Content = "",
            Buttons = {}
        }, cfg or {})

        local Result
        ShowModal(function(Popup, ClosePopup)
            Popup.Size = UDim2.new(0, 350, 0, 172)
            Result = Popup

            local Title = Instance.new("TextLabel")
            Title.Parent = Popup
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 20, 0, 16)
            Title.Size = UDim2.new(1, -40, 0, 22)
            Title.Font = Enum.Font.GothamBold
            Title.Text = cfg.Title
            Title.TextSize = 15
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.ZIndex = 26
            Library:Themed(Title, "TextColor3", "Text")

            local Content = Instance.new("TextLabel")
            Content.Parent = Popup
            Content.BackgroundTransparency = 1
            Content.Position = UDim2.new(0, 20, 0, 44)
            Content.Size = UDim2.new(1, -40, 0, 54)
            Content.Font = Enum.Font.Gotham
            Content.Text = cfg.Content
            Content.TextSize = 12
            Content.TextWrapped = true
            Content.TextXAlignment = Enum.TextXAlignment.Left
            Content.TextYAlignment = Enum.TextYAlignment.Top
            Content.ZIndex = 26
            Library:Themed(Content, "TextColor3", "TextDisabled")

            local Row = Instance.new("Frame")
            Row.Parent = Popup
            Row.AnchorPoint = Vector2.new(0.5, 1)
            Row.BackgroundTransparency = 1
            Row.BorderSizePixel = 0
            Row.Position = UDim2.new(0.5, 0, 1, -16)
            Row.Size = UDim2.new(1, -40, 0, 34)
            Row.ZIndex = 26

            local RowList = Instance.new("UIListLayout")
            RowList.Parent = Row
            RowList.FillDirection = Enum.FillDirection.Horizontal
            RowList.HorizontalAlignment = Enum.HorizontalAlignment.Right
            RowList.VerticalAlignment = Enum.VerticalAlignment.Center
            RowList.SortOrder = Enum.SortOrder.LayoutOrder
            RowList.Padding = UDim.new(0, 8)

            if #cfg.Buttons == 0 then
                cfg.Buttons = { { Title = "OK", Variant = "Primary" } }
            end

            for Index, Config in ipairs(cfg.Buttons) do
                local Primary = Config.Variant == "Primary"
                local Button = Instance.new("TextButton")
                Button.Parent = Row
                Button.BackgroundTransparency = Primary and 0.05 or 0.9
                Button.BorderSizePixel = 0
                Button.Size = UDim2.new(0, 132, 0, 34)
                Button.Font = Enum.Font.GothamBold
                Button.Text = Config.Title or "OK"
                Button.TextSize = 13
                Button.AutoButtonColor = false
                Button.LayoutOrder = Index
                Button.ZIndex = 27
                Library:Corner(Button, 8)

                if Primary then
                    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                    Library:Themed(Button, "BackgroundColor3", "Accent")
                    Library:Hover(Button, Button, "BackgroundTransparency", 0.05, 0.25)
                else
                    Library:Themed(Button, "BackgroundColor3", "Surface")
                    Library:Themed(Button, "TextColor3", "Text")
                    Library:Hover(Button, Button, "BackgroundTransparency", 0.9, 0.78)
                end

                Button.MouseButton1Click:Connect(function()
                    if Config.Callback then
                        Config.Callback()
                    end
                    ClosePopup()
                end)
            end
        end)

        return Result
    end

    function WindowAPI:Popup(cfg)
        return WindowAPI:Dialog(cfg)
    end

    function WindowAPI:Changelog(cfg)
        cfg = Library:MakeConfig({
            Title = "Changelog",
            Entries = ConfigWindow.Changelog or {
                { Version = ConfigWindow.Version or "v1.0", Notes = { "Initial release." } },
            },
        }, cfg or {})

        ShowModal(function(Popup, ClosePopup)
            Popup.Size = UDim2.new(0, 360, 0, 320)

            local Icon = Instance.new("ImageLabel")
            Icon.Parent = Popup
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0, 18, 0, 16)
            Icon.Size = UDim2.new(0, 20, 0, 20)
            Icon.ZIndex = 26
            Library:SetIcon(Icon, "history", Library.Theme.Accent)

            local Title = Instance.new("TextLabel")
            Title.Parent = Popup
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 48, 0, 15)
            Title.Size = UDim2.new(1, -100, 0, 22)
            Title.Font = Enum.Font.GothamBold
            Title.Text = cfg.Title
            Title.TextSize = 15
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.ZIndex = 26
            Library:Themed(Title, "TextColor3", "Text")

            local CloseBtn = Instance.new("TextButton")
            CloseBtn.Parent = Popup
            CloseBtn.AnchorPoint = Vector2.new(1, 0)
            CloseBtn.BackgroundTransparency = 0.9
            CloseBtn.BorderSizePixel = 0
            CloseBtn.Position = UDim2.new(1, -14, 0, 14)
            CloseBtn.Size = UDim2.new(0, 26, 0, 26)
            CloseBtn.Text = ""
            CloseBtn.AutoButtonColor = false
            CloseBtn.ZIndex = 26
            Library:Themed(CloseBtn, "BackgroundColor3", "Surface")
            Library:Corner(CloseBtn, 8)
            local CloseIcon = Instance.new("ImageLabel")
            CloseIcon.Parent = CloseBtn
            CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
            CloseIcon.BackgroundTransparency = 1
            CloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
            CloseIcon.Size = UDim2.new(0, 12, 0, 12)
            CloseIcon.ZIndex = 27
            Library:SetIcon(CloseIcon, Library.DefaultIcons.Close, Library.Theme.Text)
            CloseBtn.MouseButton1Click:Connect(ClosePopup)

            local Divider = Instance.new("Frame")
            Divider.Parent = Popup
            Divider.BorderSizePixel = 0
            Divider.Position = UDim2.new(0, 18, 0, 48)
            Divider.Size = UDim2.new(1, -36, 0, 1)
            Divider.ZIndex = 26
            Library:FadeLine(Divider, Library.Theme.Accent, true)

            local Scroll = Instance.new("ScrollingFrame")
            Scroll.Parent = Popup
            Scroll.BackgroundTransparency = 1
            Scroll.BorderSizePixel = 0
            Scroll.Position = UDim2.new(0, 18, 0, 58)
            Scroll.Size = UDim2.new(1, -36, 1, -66)
            Scroll.ScrollBarThickness = 3
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            Scroll.ZIndex = 26
            Library:Themed(Scroll, "ScrollBarImageColor3", "Accent")

            local ScrollList = Instance.new("UIListLayout")
            ScrollList.Parent = Scroll
            ScrollList.SortOrder = Enum.SortOrder.LayoutOrder
            ScrollList.Padding = UDim.new(0, 14)
            Library:UpdateScrolling(Scroll, ScrollList)

            for i, Entry in ipairs(cfg.Entries) do
                local Block = Instance.new("Frame")
                Block.Parent = Scroll
                Block.LayoutOrder = i
                Block.BackgroundTransparency = 1
                Block.Size = UDim2.new(1, 0, 0, 0)
                Block.AutomaticSize = Enum.AutomaticSize.Y
                Block.ZIndex = 26

                local VerLabel = Instance.new("TextLabel")
                VerLabel.Parent = Block
                VerLabel.BackgroundTransparency = 1
                VerLabel.Size = UDim2.new(1, 0, 0, 18)
                VerLabel.Font = Enum.Font.GothamBold
                VerLabel.Text = Entry.Version or "Update"
                VerLabel.TextSize = 13
                VerLabel.TextXAlignment = Enum.TextXAlignment.Left
                VerLabel.ZIndex = 27
                Library:Themed(VerLabel, "TextColor3", "Accent")

                local NotesHolder = Instance.new("Frame")
                NotesHolder.Parent = Block
                NotesHolder.BackgroundTransparency = 1
                NotesHolder.Position = UDim2.new(0, 0, 0, 20)
                NotesHolder.Size = UDim2.new(1, 0, 0, 0)
                NotesHolder.AutomaticSize = Enum.AutomaticSize.Y
                NotesHolder.ZIndex = 27

                local NotesList = Instance.new("UIListLayout")
                NotesList.Parent = NotesHolder
                NotesList.SortOrder = Enum.SortOrder.LayoutOrder
                NotesList.Padding = UDim.new(0, 4)

                for j, Note in ipairs(Entry.Notes or {}) do
                    local NoteLbl = Instance.new("TextLabel")
                    NoteLbl.Parent = NotesHolder
                    NoteLbl.LayoutOrder = j
                    NoteLbl.BackgroundTransparency = 1
                    NoteLbl.Size = UDim2.new(1, 0, 0, 0)
                    NoteLbl.AutomaticSize = Enum.AutomaticSize.Y
                    NoteLbl.Font = Enum.Font.Gotham
                    NoteLbl.Text = "•  " .. Note
                    NoteLbl.TextSize = 12
                    NoteLbl.TextWrapped = true
                    NoteLbl.TextXAlignment = Enum.TextXAlignment.Left
                    NoteLbl.ZIndex = 28
                    Library:Themed(NoteLbl, "TextColor3", "TextDisabled")
                end
            end
        end)
    end

    Library.ActiveNotifications = Library.ActiveNotifications or {}

    function WindowAPI:Notify(cfg)
        cfg = Library:MakeConfig({
            Title = "Notification",
            Content = "",
            Desc = "",
            Type = "Info",
            Duration = 4
        }, cfg or {})

        local TitleText = cfg.Title
        local DescText = cfg.Content ~= "" and cfg.Content or cfg.Desc
        local Duration = tonumber(cfg.Duration) or 4
        local NotifType = cfg.Type or "Info"

        local TypeColor = Color3.fromRGB(120, 180, 255)
        local TypeIcon = "info"
        if NotifType == "Error" then
            TypeColor = Color3.fromRGB(255, 88, 88)
            TypeIcon = "circle-x"
        elseif NotifType == "Success" then
            TypeColor = Color3.fromRGB(80, 225, 140)
            TypeIcon = "circle-check"
        elseif NotifType == "Warn" then
            TypeColor = Color3.fromRGB(255, 200, 90)
            TypeIcon = "triangle-alert"
        end

        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "Notify"
        MainFrame.Parent = ScreenGui
        MainFrame.AnchorPoint = Vector2.new(1, 0)
        MainFrame.BackgroundTransparency = 0.02
        MainFrame.BorderSizePixel = 0
        MainFrame.Position = UDim2.new(1, 300, 0, 100)
        MainFrame.Size = UDim2.new(0, 258, 0, 66)
        MainFrame.ZIndex = 200
        Library:Themed(MainFrame, "BackgroundColor3", "Elevated")
        Library:Corner(MainFrame, 10)
        local NotifStroke = Library:Stroke(MainFrame, TypeColor, 0.62, 1.2)

        local IconHolder = Instance.new("Frame")
        IconHolder.Parent = MainFrame
        IconHolder.AnchorPoint = Vector2.new(0, 0.5)
        IconHolder.BackgroundColor3 = TypeColor
        IconHolder.BackgroundTransparency = 0.85
        IconHolder.BorderSizePixel = 0
        IconHolder.Position = UDim2.new(0, 12, 0.5, -3)
        IconHolder.Size = UDim2.new(0, 30, 0, 30)
        IconHolder.ZIndex = 201
        Library:Corner(IconHolder, 9)

        local TypeIconLabel = Instance.new("ImageLabel")
        TypeIconLabel.Parent = IconHolder
        TypeIconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        TypeIconLabel.BackgroundTransparency = 1
        TypeIconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        TypeIconLabel.Size = UDim2.new(0, 16, 0, 16)
        TypeIconLabel.ZIndex = 202
        Library:SetIcon(TypeIconLabel, TypeIcon, TypeColor)

        local NotificationTitle = Instance.new("TextLabel")
        NotificationTitle.Parent = MainFrame
        NotificationTitle.BackgroundTransparency = 1
        NotificationTitle.BorderSizePixel = 0
        NotificationTitle.Position = UDim2.new(0, 52, 0, 11)
        NotificationTitle.Size = UDim2.new(1, -84, 0, 17)
        NotificationTitle.Font = Enum.Font.GothamBold
        NotificationTitle.Text = TitleText
        NotificationTitle.TextSize = 13
        NotificationTitle.TextXAlignment = Enum.TextXAlignment.Left
        NotificationTitle.TextTruncate = Enum.TextTruncate.AtEnd
        NotificationTitle.ZIndex = 202
        Library:Themed(NotificationTitle, "TextColor3", "Text")

        local NotificationDescription = Instance.new("TextLabel")
        NotificationDescription.Name = "NotificationDescription"
        NotificationDescription.Parent = MainFrame
        NotificationDescription.BackgroundTransparency = 1
        NotificationDescription.BorderSizePixel = 0
        NotificationDescription.Position = UDim2.new(0, 52, 0, 28)
        NotificationDescription.Size = UDim2.new(1, -68, 0, 28)
        NotificationDescription.Font = Enum.Font.Gotham
        NotificationDescription.Text = DescText
        NotificationDescription.TextSize = 11
        NotificationDescription.TextWrapped = true
        NotificationDescription.TextXAlignment = Enum.TextXAlignment.Left
        NotificationDescription.TextYAlignment = Enum.TextYAlignment.Top
        NotificationDescription.ZIndex = 202
        Library:Themed(NotificationDescription, "TextColor3", "TextDisabled")

        local DurationFrame = Instance.new("Frame")
        DurationFrame.Parent = MainFrame
        DurationFrame.BackgroundColor3 = TypeColor
        DurationFrame.BackgroundTransparency = 0.25
        DurationFrame.BorderSizePixel = 0
        DurationFrame.Position = UDim2.new(0, 10, 1, -6)
        DurationFrame.Size = UDim2.new(1, -20, 0, 3)
        DurationFrame.ZIndex = 202
        Library:Corner(DurationFrame, UDim.new(1, 0))

        local CloseButton = Instance.new("TextButton")
        CloseButton.Parent = MainFrame
        CloseButton.AnchorPoint = Vector2.new(1, 0)
        CloseButton.BackgroundTransparency = 1
        CloseButton.BorderSizePixel = 0
        CloseButton.Position = UDim2.new(1, -8, 0, 8)
        CloseButton.Size = UDim2.new(0, 20, 0, 20)
        CloseButton.Text = ""
        CloseButton.AutoButtonColor = false
        CloseButton.ZIndex = 203

        local CloseIcon = Instance.new("ImageLabel")
        CloseIcon.Parent = CloseButton
        CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        CloseIcon.BackgroundTransparency = 1
        CloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
        CloseIcon.Size = UDim2.new(0, 12, 0, 12)
        CloseIcon.ImageTransparency = 0.4
        CloseIcon.ZIndex = 204
        Library:SetIcon(CloseIcon, Library.DefaultIcons.Close, Library.Theme.Text)

        Library:Hover(CloseButton, CloseIcon, "ImageTransparency", 0.4, 0)

        local NotifData = { Frame = MainFrame }
        table.insert(Library.ActiveNotifications, NotifData)

        local function UpdatePositions()
            for Index, Notif in ipairs(Library.ActiveNotifications) do
                if Notif and Notif.Frame and Notif.Frame.Parent then
                    Library:Tween(Notif.Frame, TweenInfo.new(0.38, Quart, Out), {
                        Position = UDim2.new(1, -18, 0, 96 + ((Index - 1) * 76))
                    })
                end
            end
        end

        local IsClosing = false
        local TweenBar = TweenService:Create(DurationFrame, TweenInfo.new(Duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 3) })

        local function CloseNotification()
            if IsClosing then
                return
            end
            IsClosing = true
            TweenBar:Cancel()
            for Index, Value in ipairs(Library.ActiveNotifications) do
                if Value == NotifData then
                    table.remove(Library.ActiveNotifications, Index)
                    break
                end
            end
            UpdatePositions()
            Library:Tween(MainFrame, TweenInfo.new(0.3, Quart, In), {
                Position = UDim2.new(1, 300, 0, MainFrame.Position.Y.Offset)
            }, function()
                MainFrame:Destroy()
            end)
        end

        CloseButton.MouseButton1Click:Connect(CloseNotification)

        Library:Pop(MainFrame, 0.4, 0.92)
        UpdatePositions()
        TweenBar:Play()
        TweenBar.Completed:Connect(function()
            if not IsClosing then
                CloseNotification()
            end
        end)

        return { Close = CloseNotification, Frame = MainFrame }
    end

    ToggleWindow(true)

    return WindowAPI
end

return Library