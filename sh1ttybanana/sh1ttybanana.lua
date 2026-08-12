local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

local function Get(url)
    local ok, res = pcall(function()
        if type(game.HttpGet) == "function" then
            return game:HttpGet(url)
        end
        if type(game.HttpGetAsync) == "function" then
            return game:HttpGetAsync(url)
        end
        if syn and syn.request then
            local r = syn.request({Url = url, Method = "GET"})
            return r.Body
        end
        if request then
            local r = request({Url = url, Method = "GET"})
            return r.Body
        end
        if http_request then
            local r = http_request({Url = url, Method = "GET"})
            return r.Body
        end
        return HttpService:GetAsync(url)
    end)
    if ok then return res end
    error("Get failed: " .. tostring(res))
end

local UIIcons
do
    local ok, result = pcall(function()
        local src = Get("https://raw.githubusercontent.com/DSP-V1/NextGen/refs/heads/main/UILib/icons/UIIcons.lua")
        if not src or src == "" then
            error("UIIcons empty")
        end
        local fn = loadstring(src)
        if not fn then
            error("UIIcons compile fail")
        end
        return fn()
    end)
    if ok and type(result) == "table" then
        UIIcons = result
        pcall(function()
            if UIIcons.SetIconsType then
                UIIcons.SetIconsType("lucide")
            end
        end)
    else
        UIIcons = {
            SetIconsType = function() end,
            Icon2 = function()
                return nil
            end,
            Icon = function()
                return nil
            end
        }
        warn("[sh1ttybanana] UIIcons failed to load, using fallback:", result)
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
    Palette = "palette"
}

Library.Themes = {
    Dark = {
        Main = Color3.fromRGB(9, 9, 9),
        Accent = Color3.fromRGB(179, 0, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDisabled = Color3.fromRGB(100, 100, 100),
        Background = Color3.fromRGB(20, 20, 20),
        Stroke = Color3.fromRGB(100, 100, 100),
        Secondary = Color3.fromRGB(28, 28, 28)
    },
    Light = {
        Main = Color3.fromRGB(245, 245, 245),
        Accent = Color3.fromRGB(179, 0, 255),
        Text = Color3.fromRGB(20, 20, 20),
        TextDisabled = Color3.fromRGB(120, 120, 120),
        Background = Color3.fromRGB(230, 230, 230),
        Stroke = Color3.fromRGB(180, 180, 180),
        Secondary = Color3.fromRGB(255, 255, 255)
    }
}

Library.Theme = Library.Themes.Dark
Library.CurrentTheme = "Dark"

function Library:NormalizeIconName(IconName)
    if type(IconName) ~= "string" or IconName == "" then
        return Library.DefaultIcons.Tab
    end
    if IconName:find(":") then
        return IconName
    end
    return "lucide:" .. IconName
end

function Library:SetIcon(Object, IconName, IconColor, IconType)
    if not Object then
        return
    end
    local NormalizedIconName = self:NormalizeIconName(IconName or Library.DefaultIcons.Tab)
    local ok, IconData = pcall(function()
        return UIIcons.Icon2(NormalizedIconName, IconType or "lucide")
    end)
    if not ok or not IconData then
        return
    end
    if type(IconData) == "string" then
        Object.Image = IconData
        return
    end
    if type(IconData) == "table" and IconData[1] then
        Object.Image = IconData[1]
        if IconData[2] then
            if IconData[2].ImageRectPosition then
                Object.ImageRectOffset = IconData[2].ImageRectPosition
            end
            if IconData[2].ImageRectSize then
                Object.ImageRectSize = IconData[2].ImageRectSize
            end
        end
    end
    if IconColor then
        Object.ImageColor3 = IconColor
    end
end

Library.Theme = {
    Main = Color3.fromRGB(9, 9, 9),
    Accent = Color3.fromRGB(179, 0, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDisabled = Color3.fromRGB(100, 100, 100),
    Background = Color3.fromRGB(20, 20, 20),
    Stroke = Color3.fromRGB(100, 100, 100)
}

function Library:TweenInstance(Instance, Time, Property, TargetValue, Callback)
    local Tween = TweenService:Create(
        Instance,
        TweenInfo.new(Time or 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { [Property] = TargetValue }
    )
    if Callback then
        Tween.Completed:Connect(Callback)
    end
    Tween:Play()
    return Tween
end

function Library:Tween(Instance, Info, Properties, Callback)
    local Tween = TweenService:Create(Instance, Info or TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), Properties)
    if Callback then
        Tween.Completed:Connect(Callback)
    end
    Tween:Play()
    return Tween
end

function Library:MakeConfig(DefaultConfig, UserConfig)
    UserConfig = UserConfig or {}
    local Config = {}
    for Key, Value in pairs(DefaultConfig) do
        Config[Key] = UserConfig[Key] ~= nil and UserConfig[Key] or Value
    end
    return Config
end

function Library:UpdateContent(Content, Title, Object)
    if Content.Text and Content.Text ~= "" then
        Title.Position = UDim2.new(0, 10, 0, 7)
        Title.Size = UDim2.new(1, -60, 0, 16)
        local MaxY = math.max(Content.TextBounds.Y + 15, 45)
        Object.Size = UDim2.new(1, 0, 0, MaxY)
    end
end

function Library:UpdateScrolling(Scroll, List)
    local function UpdateCanvasSize()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 15)
    end
    List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)
    coroutine.wrap(UpdateCanvasSize)()
end

function Library:MakeDraggable(DragBar, Object)
    local Dragging = false
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function UpdatePosition(Input)
        local Delta = Input.Position - DragStart
        local NewPosition = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
        Object.Position = NewPosition
    end

    DragBar.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or 
           Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = Input.Position
            StartPosition = Object.Position

            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    DragBar.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or 
           Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if Input == DragInput and Dragging then
            UpdatePosition(Input)
        end
    end)
end

function Library:NewWindow(ConfigWindow)
    local ConfigWindow = self:MakeConfig({
        Title = "sh1ttybanana",
        Description = "sh1ttybanana ui",
        Icon = "rbxassetid://89646749075297",
        Logo = "rbxassetid://89646749075297",
        Color = Color3.fromRGB(179, 0, 255),
        Size = UDim2.new(0, 580, 0, 380),
        Transparent = 0.07,
        AutoScale = true,
    }, ConfigWindow or {})

    Library.Theme.Accent = ConfigWindow.Color
    local WindowTags = {}
    local ConfigFlags = {}
    local ReorderMode = false
    local TabElements = {}

    if ConfigWindow.AutoScale ~= false then
        local cam = workspace.CurrentCamera
        local scale = math.clamp(math.min(cam.ViewportSize.X / 1920, cam.ViewportSize.Y / 1080), 0.65, 1.2)
        ConfigWindow.Size = UDim2.new(0, math.floor(ConfigWindow.Size.X.Offset * scale), 0, math.floor(ConfigWindow.Size.Y.Offset * scale))
    end

    local TeddyUI_Premium = Instance.new("ScreenGui")
    local DropShadowHolder = Instance.new("Frame")
    local DropShadow = Instance.new("ImageLabel")
    local Main = Instance.new("Frame")
    local UICorner = Instance.new("UICorner")
    local Top = Instance.new("Frame")
    local Line = Instance.new("Frame")
    local Left = Instance.new("Folder")
    local NameHub = Instance.new("TextLabel")
    local LogoHub = Instance.new("ImageLabel")
    local Desc = Instance.new("TextLabel")
    local Right = Instance.new("Folder")
    local Frame = Instance.new("Frame")
    local UIListLayout = Instance.new("UIListLayout")
    local UIPadding = Instance.new("UIPadding")
    local Minize = Instance.new("TextButton")
    local Icon = Instance.new("ImageLabel")
    local Large = Instance.new("TextButton")
    local Icon_2 = Instance.new("ImageLabel")
    local Close = Instance.new("TextButton")
    local Icon_3 = Instance.new("ImageLabel")
    local UIStroke = Instance.new("UIStroke")
    local TabFrame = Instance.new("Frame")
    local Line_2 = Instance.new("Frame")
    local SearchFrame = Instance.new("Frame")
    local UICorner_2 = Instance.new("UICorner")
    local IconSearch = Instance.new("ImageLabel")
    local SearchBox = Instance.new("TextBox")
    local ScrollingTab = Instance.new("ScrollingFrame")
    local UIPadding_2 = Instance.new("UIPadding")
    local UIListLayout_2 = Instance.new("UIListLayout")
    local LayoutFrame = Instance.new("Frame")
    local RealLayout = Instance.new("Frame")
    local LayoutList = Instance.new("Folder")
    local UIPageLayout = Instance.new("UIPageLayout")
    local LayoutName = Instance.new("Frame")
    local TextLabel = Instance.new("TextLabel")
    local DropdownZone = Instance.new("Frame")

    TeddyUI_Premium.Name = "sh1ttybanana"
    TeddyUI_Premium.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    TeddyUI_Premium.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    TeddyUI_Premium.ResetOnSpawn = false

    DropShadowHolder.Name = "DropShadowHolder"
    DropShadowHolder.Parent = TeddyUI_Premium
    DropShadowHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadowHolder.BackgroundTransparency = 1.000
    DropShadowHolder.BorderSizePixel = 0
    DropShadowHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropShadowHolder.Size = ConfigWindow.Size
    DropShadowHolder.ZIndex = 0

    DropShadow.Name = "DropShadow"
    DropShadow.Parent = DropShadowHolder
    DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadow.BackgroundTransparency = 1.000
    DropShadow.BorderSizePixel = 0
    DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropShadow.Size = UDim2.new(1, 47, 1, 47)
    DropShadow.ZIndex = 0
    DropShadow.Image = "rbxassetid://6015897843"
    DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    DropShadow.ImageTransparency = 0.500
    DropShadow.ScaleType = Enum.ScaleType.Slice
    DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

    Main.Name = "Main"
    Main.Parent = DropShadowHolder
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Library.Theme.Main
    Main.BackgroundTransparency = typeof(ConfigWindow.Transparent) == "number" and ConfigWindow.Transparent or 0.07
    Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(1, 0, 1, 0)

    UICorner.Parent = Main

    Top.Name = "Top"
    Top.Parent = Main
    Top.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Top.BackgroundTransparency = 1.000
    Top.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Top.BorderSizePixel = 0
    Top.Size = UDim2.new(1, 0, 0, 50)
    Top.Active = true
    Top.ZIndex = 5

    Line.Name = "Line"
    Line.Parent = Top
    Line.BackgroundColor3 = Library.Theme.Accent
    Line.BackgroundTransparency = 0.500
    Line.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Line.BorderSizePixel = 0
    Line.Position = UDim2.new(0, 0, 1, -1)
    Line.Size = UDim2.new(1, 0, 0, 1)

    Left.Name = "Left"
    Left.Parent = Top

    LogoHub.Name = "LogoHub"
    LogoHub.Parent = Left
    LogoHub.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LogoHub.BackgroundTransparency = 1.000
    LogoHub.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LogoHub.BorderSizePixel = 0
    LogoHub.Position = UDim2.new(0, 10, 0, 5)
    LogoHub.Size = UDim2.new(0, 40, 0, 35)
    LogoHub.Image = ConfigWindow.Logo
    LogoHub.ImageColor3 = Color3.new(1,1,1)

    NameHub.Name = "NameHub"
    NameHub.Parent = Left
    NameHub.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NameHub.BackgroundTransparency = 1.000
    NameHub.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NameHub.BorderSizePixel = 0
    NameHub.Position = UDim2.new(0, 60, 0, 10)
    NameHub.Size = UDim2.new(0, 470, 0, 20)
    NameHub.Font = Enum.Font.GothamBold
    NameHub.Text = ConfigWindow.Title
    NameHub.TextColor3 = Library.Theme.Text
    NameHub.TextSize = 14.000
    NameHub.TextXAlignment = Enum.TextXAlignment.Left

    Desc.Name = "Desc"
    Desc.Parent = Left
    Desc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Desc.BackgroundTransparency = 1.000
    Desc.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Desc.BorderSizePixel = 0
    Desc.Position = UDim2.new(0, 60, 0, 27)
    Desc.Size = UDim2.new(0, 470, 1, -30)
    Desc.Font = Enum.Font.GothamBold
    Desc.Text = ConfigWindow.Description
    Desc.TextColor3 = Library.Theme.TextDisabled
    Desc.TextSize = 12.000
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.TextYAlignment = Enum.TextYAlignment.Top

    Right.Name = "Right"
    Right.Parent = Top

    Frame.Parent = Right
    Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Frame.BackgroundTransparency = 1.000
    Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BorderSizePixel = 0
    Frame.Position = UDim2.new(1, -150, 0, 0)
    Frame.Size = UDim2.new(0, 150, 1, 0)

    UIListLayout.Parent = Frame
    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 6)

    UIPadding.Parent = Frame
    UIPadding.PaddingTop = UDim.new(0, 10)

    local ThemeBtn = Instance.new("TextButton")
    ThemeBtn.Name = "Theme"
    ThemeBtn.Parent = Frame
    ThemeBtn.BackgroundTransparency = 1
    ThemeBtn.Size = UDim2.new(0, 30, 0, 30)
    ThemeBtn.Text = ""
    ThemeBtn.LayoutOrder = 0

    local ThemeIcon = Instance.new("ImageLabel")
    ThemeIcon.Parent = ThemeBtn
    ThemeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ThemeIcon.BackgroundTransparency = 1
    ThemeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ThemeIcon.Size = UDim2.new(0, 18, 0, 18)
    Library:SetIcon(ThemeIcon, Library.DefaultIcons.Palette, Library.Theme.Accent)

    ThemeBtn.MouseButton1Click:Connect(function()
        local nextTheme = Library.CurrentTheme == "Dark" and "Light" or "Dark"
        Library.CurrentTheme = nextTheme
        Library.Theme = Library.Themes[nextTheme]
        Library.Theme.Accent = ConfigWindow.Color
        Main.BackgroundColor3 = Library.Theme.Main
        Main.BackgroundTransparency = typeof(ConfigWindow.Transparent) == "number" and ConfigWindow.Transparent or 0.07
        NameHub.TextColor3 = Library.Theme.Text
        Desc.TextColor3 = Library.Theme.TextDisabled
        SearchBox.TextColor3 = Library.Theme.Text
        TextLabel.TextColor3 = Library.Theme.Text
        local function ApplyTheme(obj)
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    if child.Name == "Content" or child.Name == "Desc" or child.Name == "NotificationDescription" then
                        child.TextColor3 = Library.Theme.TextDisabled
                    elseif child.TextColor3 == Color3.fromRGB(255, 255, 255) or child.TextColor3 == Color3.fromRGB(20, 20, 20) or child.TextColor3 == Library.Themes.Dark.Text or child.TextColor3 == Library.Themes.Light.Text then
                        child.TextColor3 = Library.Theme.Text
                    end
                elseif child:IsA("Frame") and (child.Name == "Section" or child.Name == "Toggle" or child.Name == "Button" or child.Name == "Slider" or child.Name == "Dropdown" or child.Name == "Input" or child.Name == "Colorpicker" or child.Name == "Keybind" or child.Name == "Paragraph") then
                    if nextTheme == "Light" then
                        child.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        child.BackgroundTransparency = 0.92
                    else
                        child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        child.BackgroundTransparency = 0.95
                    end
                end
            end
        end
        ApplyTheme(Main)
        ApplyTheme(ScrollingTab)
        for _, t in ipairs(TabElements) do
            if t.Frame and t.Frame:FindFirstChild("NameTab") then
                t.Frame.NameTab.TextColor3 = Library.Theme.Text
            end
        end
    end)

    Minize.Name = "Minize"
    Minize.Parent = Frame
    Minize.Active = false
    Minize.AnchorPoint = Vector2.new(0, 0.5)
    Minize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minize.BackgroundTransparency = 1.000
    Minize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minize.BorderSizePixel = 0
    Minize.Selectable = false
    Minize.Size = UDim2.new(0, 30, 0, 30)
    Minize.Text = ""
    Minize.LayoutOrder = 1

    Icon.Name = "Icon"
    Icon.Parent = Minize
    Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon.BackgroundTransparency = 1.000
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.BorderSizePixel = 0
    Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    Icon.Size = UDim2.new(0, 20, 0, 20)
    Library:SetIcon(Icon, Library.DefaultIcons.Minimize, Library.Theme.Accent)

    Large.Name = "Large"
    Large.Parent = Frame
    Large.Active = false
    Large.AnchorPoint = Vector2.new(0, 0.5)
    Large.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Large.BackgroundTransparency = 1.000
    Large.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Large.BorderSizePixel = 0
    Large.Selectable = false
    Large.Size = UDim2.new(0, 30, 0, 30)
    Large.Text = ""
    Large.LayoutOrder = 2

    Icon_2.Name = "Icon"
    Icon_2.Parent = Large
    Icon_2.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon_2.BackgroundTransparency = 1.000
    Icon_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon_2.BorderSizePixel = 0
    Icon_2.Position = UDim2.new(0.5, 0, 0.5, 0)
    Icon_2.Size = UDim2.new(0, 18, 0, 18)
    Library:SetIcon(Icon_2, Library.DefaultIcons.Maximize, Library.Theme.Accent)

    Close.Name = "Close"
    Close.Parent = Frame
    Close.Active = false
    Close.AnchorPoint = Vector2.new(0, 0.5)
    Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Close.BackgroundTransparency = 1.000
    Close.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Close.BorderSizePixel = 0
    Close.Selectable = false
    Close.Size = UDim2.new(0, 30, 0, 30)
    Close.Text = ""
    Close.LayoutOrder = 3

    Icon_3.Name = "Icon"
    Icon_3.Parent = Close
    Icon_3.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon_3.BackgroundTransparency = 1.000
    Icon_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon_3.BorderSizePixel = 0
    Icon_3.Position = UDim2.new(0.5, 0, 0.5, 0)
    Icon_3.Size = UDim2.new(0, 20, 0, 20)
    Library:SetIcon(Icon_3, Library.DefaultIcons.Close, Library.Theme.Accent)

    UIStroke.Color = Library.Theme.Accent
    UIStroke.Transparency = 0.5
    UIStroke.Parent = Main

    TabFrame.Name = "TabFrame"
    TabFrame.Parent = Main
    TabFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TabFrame.BackgroundTransparency = 1.000
    TabFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TabFrame.BorderSizePixel = 0
    TabFrame.Position = UDim2.new(0, 0, 0, 50)
    TabFrame.Size = UDim2.new(0, 144, 1, -50)

    Line_2.Name = "Line"
    Line_2.Parent = TabFrame
    Line_2.BackgroundColor3 = Library.Theme.Accent
    Line_2.BackgroundTransparency = 0.500
    Line_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Line_2.BorderSizePixel = 0
    Line_2.Position = UDim2.new(1, -1, 0, 0)
    Line_2.Size = UDim2.new(0, 1, 1, 0)

    SearchFrame.Name = "SearchFrame"
    SearchFrame.Parent = TabFrame
    SearchFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SearchFrame.BackgroundTransparency = 0.950
    SearchFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SearchFrame.BorderSizePixel = 0
    SearchFrame.Position = UDim2.new(0, 7, 0, 10)
    SearchFrame.Size = UDim2.new(1, -14, 0, 30)

    UICorner_2.CornerRadius = UDim.new(0, 3)
    UICorner_2.Parent = SearchFrame

    IconSearch.Name = "IconSearch"
    IconSearch.Parent = SearchFrame
    IconSearch.AnchorPoint = Vector2.new(0, 0.5)
    IconSearch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    IconSearch.BackgroundTransparency = 1.000
    IconSearch.BorderColor3 = Color3.fromRGB(0, 0, 0)
    IconSearch.BorderSizePixel = 0
    IconSearch.Position = UDim2.new(0, 10, 0.5, 0)
    IconSearch.Size = UDim2.new(0, 15, 0, 15)
    Library:SetIcon(IconSearch, Library.DefaultIcons.Search, Library.Theme.Accent)

    SearchBox.Name = "SearchBox"
    SearchBox.Parent = SearchFrame
    SearchBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SearchBox.BackgroundTransparency = 1.000
    SearchBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SearchBox.BorderSizePixel = 0
    SearchBox.ClipsDescendants = true
    SearchBox.Position = UDim2.new(0, 35, 0, 0)
    SearchBox.Size = UDim2.new(1, -35, 1, 0)
    SearchBox.Font = Enum.Font.GothamBold
    SearchBox.PlaceholderText = "Search."
    SearchBox.Text = ""
    SearchBox.TextColor3 = Library.Theme.Text
    SearchBox.TextSize = 13.000
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left

    ScrollingTab.Name = "ScrollingTab"
    ScrollingTab.Parent = TabFrame
    ScrollingTab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ScrollingTab.BackgroundTransparency = 1.000
    ScrollingTab.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ScrollingTab.BorderSizePixel = 0
    ScrollingTab.Position = UDim2.new(0, 0, 0, 50)
    ScrollingTab.Selectable = false
    ScrollingTab.Size = UDim2.new(1, 0, 1, -100)
    ScrollingTab.ScrollBarThickness = 0
    self:UpdateScrolling(ScrollingTab, UIListLayout_2)

    UIPadding_2.Parent = ScrollingTab
    UIPadding_2.PaddingBottom = UDim.new(0, 3)
    UIPadding_2.PaddingLeft = UDim.new(0, 7)
    UIPadding_2.PaddingRight = UDim.new(0, 7)
    UIPadding_2.PaddingTop = UDim.new(0, 3)

    UIListLayout_2.Parent = ScrollingTab
    UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder

    local BottomBar = Instance.new("Frame")
    BottomBar.Name = "BottomBar"
    BottomBar.Parent = TabFrame
    BottomBar.BackgroundTransparency = 1
    BottomBar.Position = UDim2.new(0, 0, 1, -48)
    BottomBar.Size = UDim2.new(1, 0, 0, 48)

    local function MakeBottomBtn(name, icon, order, callback)
        local B = Instance.new("TextButton")
        B.Name = name
        B.Parent = BottomBar
        B.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        B.BackgroundTransparency = 0.3
        B.BorderSizePixel = 0
        B.Position = UDim2.new(0, 8 + (order - 1) * 44, 0, 8)
        B.Size = UDim2.new(0, 38, 0, 32)
        B.Text = ""
        B.AutoButtonColor = false

        local BC = Instance.new("UICorner")
        BC.CornerRadius = UDim.new(0, 6)
        BC.Parent = B

        local BI = Instance.new("ImageLabel")
        BI.Parent = B
        BI.BackgroundTransparency = 1
        BI.AnchorPoint = Vector2.new(0.5, 0.5)
        BI.Position = UDim2.new(0.5, 0, 0.5, 0)
        BI.Size = UDim2.new(0, 16, 0, 16)
        Library:SetIcon(BI, icon, Library.Theme.Text)

        B.MouseButton1Click:Connect(function()
            callback(B, BI)
        end)
        return B, BI
    end

    local ReorderBtn, ReorderIcon = MakeBottomBtn("Reorder", "list-ordered", 1, function(btn, icon)
        ReorderMode = not ReorderMode
        if ReorderMode then
            Library:TweenInstance(btn, 0.2, "BackgroundColor3", Color3.fromRGB(0, 120, 255))
            Library:SetIcon(icon, "list-ordered", Color3.fromRGB(255, 255, 255))
            for _, t in ipairs(TabElements) do
                if t.DragIcon then t.DragIcon.Visible = true end
                if t.DragBtn then t.DragBtn.Visible = true end
            end
        else
            Library:TweenInstance(btn, 0.2, "BackgroundColor3", Color3.fromRGB(30, 30, 30))
            Library:SetIcon(icon, "list-ordered", Library.Theme.Text)
            for _, t in ipairs(TabElements) do
                if t.DragIcon then t.DragIcon.Visible = false end
                if t.DragBtn then t.DragBtn.Visible = false end
            end
        end
    end)

    -- AI Window state
    local AIWindow = nil
    local AIOpen = false
    local AIMessages = {} -- {role, text}[]

    local function HideMainContent()
        TabFrame.Visible = false
        LayoutFrame.Visible = false
    end

    local function ShowMainContent()
        TabFrame.Visible = true
        LayoutFrame.Visible = true
    end

    local function CloseAI()
        if AIWindow then
            Library:Tween(AIWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 0)
            }, function()
                if AIWindow then AIWindow:Destroy() AIWindow = nil end
            end)
        end
        AIOpen = false
        ShowMainContent()
    end

    -- Parse AI response: detects [tab:TabName] clickable links
    local function ParseAndRenderAIResponse(parent, text, selectTabCallback)
        -- Split text on [tab:...] tokens
        local segments = {}
        local pos = 1
        while pos <= #text do
            local s, e, tabName = text:find("%[tab:([^%]]+)%]", pos)
            if s then
                if s > pos then
                    table.insert(segments, { type = "text", content = text:sub(pos, s - 1) })
                end
                table.insert(segments, { type = "tab", content = tabName })
                pos = e + 1
            else
                table.insert(segments, { type = "text", content = text:sub(pos) })
                break
            end
        end

        local container = Instance.new("Frame")
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(1, 0, 0, 0)
        container.AutomaticSize = Enum.AutomaticSize.Y
        container.Parent = parent

        local list = Instance.new("UIListLayout")
        list.Parent = container
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 2)

        local order = 0
        for _, seg in ipairs(segments) do
            if seg.type == "text" and seg.content ~= "" then
                local lbl = Instance.new("TextLabel")
                lbl.Parent = container
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 0, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.Y
                lbl.Font = Enum.Font.Gotham
                lbl.Text = seg.content
                lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
                lbl.TextSize = 12
                lbl.TextWrapped = true
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.LayoutOrder = order
                order = order + 1
            elseif seg.type == "tab" then
                local btn = Instance.new("TextButton")
                btn.Parent = container
                btn.BackgroundColor3 = Library.Theme.Accent
                btn.BackgroundTransparency = 0.75
                btn.BorderSizePixel = 0
                btn.Size = UDim2.new(0, 0, 0, 22)
                btn.AutomaticSize = Enum.AutomaticSize.X
                btn.Font = Enum.Font.GothamBold
                btn.Text = "  → " .. seg.content .. "  "
                btn.TextColor3 = Library.Theme.Accent
                btn.TextSize = 12
                btn.LayoutOrder = order
                order = order + 1
                local bc = Instance.new("UICorner")
                bc.CornerRadius = UDim.new(0, 4)
                bc.Parent = btn
                btn.MouseButton1Click:Connect(function()
                    CloseAI()
                    task.wait(0.3)
                    if selectTabCallback then selectTabCallback(seg.content) end
                end)
                btn.MouseEnter:Connect(function()
                    Library:TweenInstance(btn, 0.15, "BackgroundTransparency", 0.5)
                end)
                btn.MouseLeave:Connect(function()
                    Library:TweenInstance(btn, 0.15, "BackgroundTransparency", 0.75)
                end)
            end
        end
        return container
    end

    MakeBottomBtn("AI", "bot", 2, function()
        if AIOpen then CloseAI() return end
        AIOpen = true
        HideMainContent()

        AIWindow = Instance.new("Frame")
        AIWindow.Name = "AIWindow"
        AIWindow.Parent = Main
        AIWindow.BackgroundColor3 = Color3.fromRGB(11, 11, 13)
        AIWindow.BackgroundTransparency = 0
        AIWindow.BorderSizePixel = 0
        AIWindow.Position = UDim2.new(0, 0, 1, 0)
        AIWindow.Size = UDim2.new(1, 0, 0, 0)
        AIWindow.ZIndex = 20
        AIWindow.ClipsDescendants = true

        local AWC = Instance.new("UICorner")
        AWC.CornerRadius = UDim.new(0, 8)
        AWC.Parent = AIWindow

        -- Animate in
        Library:Tween(AIWindow, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 50),
            Size = UDim2.new(1, 0, 1, -50)
        })

        -- Header
        local AIHeader = Instance.new("Frame")
        AIHeader.Name = "Header"
        AIHeader.Parent = AIWindow
        AIHeader.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
        AIHeader.BorderSizePixel = 0
        AIHeader.Size = UDim2.new(1, 0, 0, 44)
        AIHeader.ZIndex = 21

        local AHC = Instance.new("UICorner")
        AHC.CornerRadius = UDim.new(0, 8)
        AHC.Parent = AIHeader

        local AHFix = Instance.new("Frame")
        AHFix.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
        AHFix.BorderSizePixel = 0
        AHFix.Position = UDim2.new(0, 0, 0.5, 0)
        AHFix.Size = UDim2.new(1, 0, 0.5, 0)
        AHFix.Parent = AIHeader

        local AIBotIcon = Instance.new("ImageLabel")
        AIBotIcon.Parent = AIHeader
        AIBotIcon.BackgroundTransparency = 1
        AIBotIcon.Position = UDim2.new(0, 12, 0.5, -9)
        AIBotIcon.Size = UDim2.new(0, 18, 0, 18)
        AIBotIcon.ZIndex = 22
        Library:SetIcon(AIBotIcon, "bot", Library.Theme.Accent)

        local AITitle = Instance.new("TextLabel")
        AITitle.Parent = AIHeader
        AITitle.BackgroundTransparency = 1
        AITitle.Position = UDim2.new(0, 36, 0, 0)
        AITitle.Size = UDim2.new(1, -80, 1, 0)
        AITitle.Font = Enum.Font.GothamBold
        AITitle.Text = "Assistant"
        AITitle.TextColor3 = Library.Theme.Text
        AITitle.TextSize = 13
        AITitle.TextXAlignment = Enum.TextXAlignment.Left
        AITitle.ZIndex = 22

        local AIClearBtn = Instance.new("TextButton")
        AIClearBtn.Parent = AIHeader
        AIClearBtn.BackgroundTransparency = 1
        AIClearBtn.Position = UDim2.new(1, -76, 0.5, -12)
        AIClearBtn.Size = UDim2.new(0, 24, 0, 24)
        AIClearBtn.Text = ""
        AIClearBtn.ZIndex = 22
        local AIClearI = Instance.new("ImageLabel")
        AIClearI.Parent = AIClearBtn
        AIClearI.BackgroundTransparency = 1
        AIClearI.AnchorPoint = Vector2.new(0.5, 0.5)
        AIClearI.Position = UDim2.new(0.5, 0, 0.5, 0)
        AIClearI.Size = UDim2.new(0, 16, 0, 16)
        AIClearI.ZIndex = 23
        Library:SetIcon(AIClearI, "trash-2", Library.Theme.TextDisabled)

        local AICloseBtn = Instance.new("TextButton")
        AICloseBtn.Parent = AIHeader
        AICloseBtn.BackgroundTransparency = 1
        AICloseBtn.Position = UDim2.new(1, -44, 0.5, -12)
        AICloseBtn.Size = UDim2.new(0, 24, 0, 24)
        AICloseBtn.Text = ""
        AICloseBtn.ZIndex = 22
        local AICloseI = Instance.new("ImageLabel")
        AICloseI.Parent = AICloseBtn
        AICloseI.BackgroundTransparency = 1
        AICloseI.AnchorPoint = Vector2.new(0.5, 0.5)
        AICloseI.Position = UDim2.new(0.5, 0, 0.5, 0)
        AICloseI.Size = UDim2.new(0, 16, 0, 16)
        AICloseI.ZIndex = 23
        Library:SetIcon(AICloseI, "x", Library.Theme.Accent)

        AICloseBtn.MouseButton1Click:Connect(CloseAI)

        AIClearBtn.MouseButton1Click:Connect(function()
            AIMessages = {}
            for _, ch in ipairs(AIScroll:GetChildren()) do
                if ch:IsA("Frame") or ch:IsA("TextLabel") then
                    ch:Destroy()
                end
            end
        end)

        -- Scroll area for messages
        local AIScroll = Instance.new("ScrollingFrame")
        AIScroll.Name = "AIScroll"
        AIScroll.Parent = AIWindow
        AIScroll.BackgroundTransparency = 1
        AIScroll.BorderSizePixel = 0
        AIScroll.Position = UDim2.new(0, 0, 0, 44)
        AIScroll.Size = UDim2.new(1, 0, 1, -100)
        AIScroll.ScrollBarThickness = 2
        AIScroll.ScrollBarImageColor3 = Library.Theme.Accent
        AIScroll.ScrollBarImageTransparency = 0.5
        AIScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        AIScroll.ZIndex = 21
        AIScroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y

        local AIList = Instance.new("UIListLayout")
        AIList.Parent = AIScroll
        AIList.SortOrder = Enum.SortOrder.LayoutOrder
        AIList.Padding = UDim.new(0, 8)

        local AIPad = Instance.new("UIPadding")
        AIPad.Parent = AIScroll
        AIPad.PaddingLeft = UDim.new(0, 10)
        AIPad.PaddingRight = UDim.new(0, 10)
        AIPad.PaddingTop = UDim.new(0, 10)
        AIPad.PaddingBottom = UDim.new(0, 10)

        -- Tab select callback (wired up after WindowAPI is built - stored for AI to use)
        local function SelectTabByName(tabName)
            for _, child in ipairs(ScrollingTab:GetChildren()) do
                if child:IsA("Frame") and child:FindFirstChild("NameTab") then
                    local raw = child.NameTab:GetAttribute("RawName") or child.NameTab.Text or ""
                    if string.lower(raw) == string.lower(tabName) then
                        local clickBtn = child:FindFirstChild("Click_Tab")
                        if clickBtn then clickBtn.Activated:Connect(function() end) end
                        -- fire via LayoutOrder
                        local lo = child.LayoutOrder
                        if lo then
                            TextLabel.Text = raw
                            for _, c2 in ipairs(ScrollingTab:GetChildren()) do
                                if c2:IsA("Frame") and c2:FindFirstChild("NameTab") then
                                    Library:TweenInstance(c2.NameTab, 0.28, "TextTransparency", 0.35)
                                    if c2:FindFirstChild("Choose") then c2.Choose.Visible = false end
                                end
                            end
                            Library:TweenInstance(child.NameTab, 0.22, "TextTransparency", 0)
                            UIPageLayout:JumpToIndex(lo)
                            if child:FindFirstChild("Choose") then child.Choose.Visible = true end
                        end
                        return
                    end
                end
            end
        end

        local function AddMessage(role, text)
            table.insert(AIMessages, { role = role, text = text })

            local isUser = (role == "user")
            local bubble = Instance.new("Frame")
            bubble.Name = role .. "Bubble"
            bubble.Parent = AIScroll
            bubble.BackgroundTransparency = 1
            bubble.Size = UDim2.new(1, 0, 0, 0)
            bubble.AutomaticSize = Enum.AutomaticSize.Y
            bubble.LayoutOrder = #AIMessages

            if isUser then
                -- User: right-aligned pill
                local pill = Instance.new("Frame")
                pill.Parent = bubble
                pill.AnchorPoint = Vector2.new(1, 0)
                pill.BackgroundColor3 = Library.Theme.Accent
                pill.BackgroundTransparency = 0.65
                pill.BorderSizePixel = 0
                pill.Position = UDim2.new(1, 0, 0, 0)
                pill.Size = UDim2.new(0.8, 0, 0, 0)
                pill.AutomaticSize = Enum.AutomaticSize.Y

                local pc = Instance.new("UICorner")
                pc.CornerRadius = UDim.new(0, 8)
                pc.Parent = pill

                local pp = Instance.new("UIPadding")
                pp.Parent = pill
                pp.PaddingLeft = UDim.new(0, 10)
                pp.PaddingRight = UDim.new(0, 10)
                pp.PaddingTop = UDim.new(0, 6)
                pp.PaddingBottom = UDim.new(0, 6)

                local lbl = Instance.new("TextLabel")
                lbl.Parent = pill
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 0, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.Y
                lbl.Font = Enum.Font.Gotham
                lbl.Text = text
                lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
                lbl.TextSize = 12
                lbl.TextWrapped = true
                lbl.TextXAlignment = Enum.TextXAlignment.Left
            else
                -- AI: left-aligned with icon
                local row = Instance.new("Frame")
                row.Parent = bubble
                row.BackgroundTransparency = 1
                row.Size = UDim2.new(1, 0, 0, 0)
                row.AutomaticSize = Enum.AutomaticSize.Y

                local iconF = Instance.new("Frame")
                iconF.Parent = row
                iconF.BackgroundColor3 = Library.Theme.Accent
                iconF.BackgroundTransparency = 0.8
                iconF.BorderSizePixel = 0
                iconF.Position = UDim2.new(0, 0, 0, 2)
                iconF.Size = UDim2.new(0, 22, 0, 22)
                local iconFC = Instance.new("UICorner")
                iconFC.CornerRadius = UDim.new(1, 0)
                iconFC.Parent = iconF
                local iconImg = Instance.new("ImageLabel")
                iconImg.Parent = iconF
                iconImg.BackgroundTransparency = 1
                iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
                iconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
                iconImg.Size = UDim2.new(0, 14, 0, 14)
                Library:SetIcon(iconImg, "bot", Library.Theme.Accent)

                local msgFrame = Instance.new("Frame")
                msgFrame.Parent = row
                msgFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
                msgFrame.BackgroundTransparency = 0
                msgFrame.BorderSizePixel = 0
                msgFrame.Position = UDim2.new(0, 28, 0, 0)
                msgFrame.Size = UDim2.new(1, -28, 0, 0)
                msgFrame.AutomaticSize = Enum.AutomaticSize.Y

                local mfc = Instance.new("UICorner")
                mfc.CornerRadius = UDim.new(0, 8)
                mfc.Parent = msgFrame

                local mfp = Instance.new("UIPadding")
                mfp.Parent = msgFrame
                mfp.PaddingLeft = UDim.new(0, 10)
                mfp.PaddingRight = UDim.new(0, 10)
                mfp.PaddingTop = UDim.new(0, 6)
                mfp.PaddingBottom = UDim.new(0, 6)

                ParseAndRenderAIResponse(msgFrame, text, SelectTabByName)
            end

            -- Auto scroll to bottom
            task.defer(function()
                AIScroll.CanvasPosition = Vector2.new(0, math.huge)
            end)
        end

        -- Thinking indicator
        local thinkFrame = nil
        local function ShowThinking()
            thinkFrame = Instance.new("Frame")
            thinkFrame.Name = "Thinking"
            thinkFrame.Parent = AIScroll
            thinkFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            thinkFrame.BackgroundTransparency = 0
            thinkFrame.BorderSizePixel = 0
            thinkFrame.Size = UDim2.new(0, 70, 0, 30)
            thinkFrame.LayoutOrder = 9999
            local tfc = Instance.new("UICorner")
            tfc.CornerRadius = UDim.new(0, 8)
            tfc.Parent = thinkFrame
            local dots = Instance.new("TextLabel")
            dots.Parent = thinkFrame
            dots.BackgroundTransparency = 1
            dots.Size = UDim2.new(1, 0, 1, 0)
            dots.Font = Enum.Font.GothamBold
            dots.Text = "..."
            dots.TextColor3 = Library.Theme.Accent
            dots.TextSize = 18
            local dotCount = 0
            local dotConn
            dotConn = game:GetService("RunService").Heartbeat:Connect(function()
                dotCount = (dotCount + 1) % 60
                local n = math.floor(dotCount / 20) + 1
                dots.Text = string.rep("•", n) .. string.rep(" ", 3 - n)
            end)
            thinkFrame:GetPropertyChangedSignal("Parent"):Connect(function()
                if not thinkFrame.Parent then dotConn:Disconnect() end
            end)
            task.defer(function()
                AIScroll.CanvasPosition = Vector2.new(0, math.huge)
            end)
        end

        local function HideThinking()
            if thinkFrame then thinkFrame:Destroy() thinkFrame = nil end
        end

        -- Groq API call
        local groqApiKey = ""
        local groqSystemPrompt = ""

        local function CallGroq(userMsg)
            if groqApiKey == "" then
                AddMessage("assistant", "⚠ No API key set. Pass groqapi and groqprompt to Window:SetGroqConfig().")
                return
            end

            local msgs = {}
            for _, m in ipairs(AIMessages) do
                if m.role ~= "assistant" or m.text:sub(1, 1) ~= "⚠" then
                    table.insert(msgs, { role = m.role, content = m.text })
                end
            end

            ShowThinking()

            task.spawn(function()
                local ok, result = pcall(function()
                    local body = HttpService:JSONEncode({
                        model = "llama-3.3-70b-versatile",
                        messages = msgs,
                        max_tokens = 1024,
                        temperature = 0.7
                    })
                    local resp = game:HttpGet("https://api.groq.com/openai/v1/chat/completions", {
                        Method = "POST",
                        Headers = {
                            ["Authorization"] = "Bearer " .. groqApiKey,
                            ["Content-Type"] = "application/json"
                        },
                        Body = body
                    })
                    local data = HttpService:JSONDecode(resp)
                    return data.choices[1].message.content
                end)

                HideThinking()

                if ok and result then
                    AddMessage("assistant", result)
                else
                    AddMessage("assistant", "⚠ Error: " .. tostring(result))
                end
            end)
        end

        -- Input bar
        local AIInputBar = Instance.new("Frame")
        AIInputBar.Name = "InputBar"
        AIInputBar.Parent = AIWindow
        AIInputBar.AnchorPoint = Vector2.new(0, 1)
        AIInputBar.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
        AIInputBar.BorderSizePixel = 0
        AIInputBar.Position = UDim2.new(0, 0, 1, 0)
        AIInputBar.Size = UDim2.new(1, 0, 0, 52)
        AIInputBar.ZIndex = 21

        local AIBC = Instance.new("UICorner")
        AIBC.CornerRadius = UDim.new(0, 8)
        AIBC.Parent = AIInputBar

        local AIBFix = Instance.new("Frame")
        AIBFix.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
        AIBFix.BorderSizePixel = 0
        AIBFix.Position = UDim2.new(0, 0, 0, 0)
        AIBFix.Size = UDim2.new(1, 0, 0.5, 0)
        AIBFix.Parent = AIInputBar

        local AITextFrame = Instance.new("Frame")
        AITextFrame.Parent = AIInputBar
        AITextFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        AITextFrame.BackgroundTransparency = 0
        AITextFrame.BorderSizePixel = 0
        AITextFrame.Position = UDim2.new(0, 8, 0, 8)
        AITextFrame.Size = UDim2.new(1, -50, 0, 36)
        AITextFrame.ZIndex = 22

        local AITFC = Instance.new("UICorner")
        AITFC.CornerRadius = UDim.new(0, 8)
        AITFC.Parent = AITextFrame

        local AITextBox = Instance.new("TextBox")
        AITextBox.Parent = AITextFrame
        AITextBox.BackgroundTransparency = 1
        AITextBox.Position = UDim2.new(0, 12, 0, 0)
        AITextBox.Size = UDim2.new(1, -12, 1, 0)
        AITextBox.Font = Enum.Font.Gotham
        AITextBox.PlaceholderText = "Ask me anything..."
        AITextBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 85)
        AITextBox.Text = ""
        AITextBox.TextColor3 = Library.Theme.Text
        AITextBox.TextSize = 13
        AITextBox.TextXAlignment = Enum.TextXAlignment.Left
        AITextBox.ClearTextOnFocus = false
        AITextBox.ZIndex = 23

        local AISendBtn = Instance.new("TextButton")
        AISendBtn.Parent = AIInputBar
        AISendBtn.AnchorPoint = Vector2.new(1, 0.5)
        AISendBtn.BackgroundColor3 = Library.Theme.Accent
        AISendBtn.BackgroundTransparency = 0
        AISendBtn.BorderSizePixel = 0
        AISendBtn.Position = UDim2.new(1, -8, 0.5, 0)
        AISendBtn.Size = UDim2.new(0, 36, 0, 36)
        AISendBtn.Text = ""
        AISendBtn.ZIndex = 22

        local ASBC = Instance.new("UICorner")
        ASBC.CornerRadius = UDim.new(0, 8)
        ASBC.Parent = AISendBtn

        local ASSendI = Instance.new("ImageLabel")
        ASSendI.Parent = AISendBtn
        ASSendI.BackgroundTransparency = 1
        ASSendI.AnchorPoint = Vector2.new(0.5, 0.5)
        ASSendI.Position = UDim2.new(0.5, 0, 0.5, 0)
        ASSendI.Size = UDim2.new(0, 18, 0, 18)
        ASSendI.ZIndex = 23
        Library:SetIcon(ASSendI, "send", Color3.fromRGB(255, 255, 255))

        local function SendMessage()
            local txt = AITextBox.Text
            if txt == "" or txt:match("^%s*$") then return end
            AITextBox.Text = ""
            AddMessage("user", txt)
            CallGroq(txt)
        end

        AISendBtn.MouseButton1Click:Connect(SendMessage)
        AISendBtn.MouseEnter:Connect(function()
            Library:TweenInstance(AISendBtn, 0.15, "BackgroundTransparency", 0.3)
        end)
        AISendBtn.MouseLeave:Connect(function()
            Library:TweenInstance(AISendBtn, 0.15, "BackgroundTransparency", 0)
        end)

        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.Return and AITextBox:IsFocused() then
                SendMessage()
            end
        end)

        -- Wire config from pending or future calls
        if WindowAPI._pendingGroqKey then
            groqApiKey = WindowAPI._pendingGroqKey
            groqSystemPrompt = WindowAPI._pendingGroqPrompt or ""
            if groqSystemPrompt ~= "" and #AIMessages == 0 then
                AIMessages = { { role = "system", content = groqSystemPrompt } }
            end
        end

        WindowAPI._activeSetGroqConfig = function(apiKey, systemPrompt)
            groqApiKey = apiKey or ""
            groqSystemPrompt = systemPrompt or ""
            if groqSystemPrompt ~= "" then
                if #AIMessages == 0 then
                    AIMessages = { { role = "system", content = groqSystemPrompt } }
                else
                    AIMessages[1] = { role = "system", content = groqSystemPrompt }
                end
            end
        end
        WindowAPI_SetGroqConfig = WindowAPI._activeSetGroqConfig
    end)

    local PCWindow = nil
    local PCOpen = false

    local function ClosePlayerCard()
        if PCWindow then
            Library:Tween(PCWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 0)
            }, function()
                if PCWindow then PCWindow:Destroy() PCWindow = nil end
            end)
        end
        PCOpen = false
        ShowMainContent()
    end

    MakeBottomBtn("PlayerCard", "contact", 3, function()
        if PCOpen then ClosePlayerCard() return end
        PCOpen = true
        HideMainContent()

        PCWindow = Instance.new("Frame")
        PCWindow.Name = "PlayerCard"
        PCWindow.Parent = Main
        PCWindow.BackgroundColor3 = Color3.fromRGB(11, 11, 13)
        PCWindow.BackgroundTransparency = 0
        PCWindow.BorderSizePixel = 0
        PCWindow.Position = UDim2.new(0, 0, 1, 0)
        PCWindow.Size = UDim2.new(1, 0, 0, 0)
        PCWindow.ZIndex = 20
        PCWindow.ClipsDescendants = true

        local PWC = Instance.new("UICorner")
        PWC.CornerRadius = UDim.new(0, 8)
        PWC.Parent = PCWindow

        Library:Tween(PCWindow, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 50),
            Size = UDim2.new(1, 0, 1, -50)
        })

        -- Header
        local PCHeader = Instance.new("Frame")
        PCHeader.Parent = PCWindow
        PCHeader.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
        PCHeader.BorderSizePixel = 0
        PCHeader.Size = UDim2.new(1, 0, 0, 44)
        PCHeader.ZIndex = 21
        local PCHC = Instance.new("UICorner") PCHC.CornerRadius = UDim.new(0, 8) PCHC.Parent = PCHeader
        local PCHFix = Instance.new("Frame")
        PCHFix.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
        PCHFix.BorderSizePixel = 0
        PCHFix.Position = UDim2.new(0, 0, 0.5, 0)
        PCHFix.Size = UDim2.new(1, 0, 0.5, 0)
        PCHFix.Parent = PCHeader

        local PCHIcon = Instance.new("ImageLabel")
        PCHIcon.Parent = PCHeader
        PCHIcon.BackgroundTransparency = 1
        PCHIcon.Position = UDim2.new(0, 12, 0.5, -9)
        PCHIcon.Size = UDim2.new(0, 18, 0, 18)
        PCHIcon.ZIndex = 22
        Library:SetIcon(PCHIcon, "contact", Library.Theme.Accent)

        local PCHTit = Instance.new("TextLabel")
        PCHTit.Parent = PCHeader
        PCHTit.BackgroundTransparency = 1
        PCHTit.Position = UDim2.new(0, 36, 0, 0)
        PCHTit.Size = UDim2.new(1, -70, 1, 0)
        PCHTit.Font = Enum.Font.GothamBold
        PCHTit.Text = "Player Card"
        PCHTit.TextColor3 = Library.Theme.Text
        PCHTit.TextSize = 13
        PCHTit.TextXAlignment = Enum.TextXAlignment.Left
        PCHTit.ZIndex = 22

        local PCCloseBtn = Instance.new("TextButton")
        PCCloseBtn.Parent = PCHeader
        PCCloseBtn.BackgroundTransparency = 1
        PCCloseBtn.Position = UDim2.new(1, -38, 0.5, -12)
        PCCloseBtn.Size = UDim2.new(0, 24, 0, 24)
        PCCloseBtn.Text = ""
        PCCloseBtn.ZIndex = 22
        local PCCloseI = Instance.new("ImageLabel")
        PCCloseI.Parent = PCCloseBtn
        PCCloseI.BackgroundTransparency = 1
        PCCloseI.AnchorPoint = Vector2.new(0.5, 0.5)
        PCCloseI.Position = UDim2.new(0.5, 0, 0.5, 0)
        PCCloseI.Size = UDim2.new(0, 16, 0, 16)
        PCCloseI.ZIndex = 23
        Library:SetIcon(PCCloseI, "x", Library.Theme.Accent)
        PCCloseBtn.MouseButton1Click:Connect(ClosePlayerCard)

        -- Content scroll
        local PCScroll = Instance.new("ScrollingFrame")
        PCScroll.Parent = PCWindow
        PCScroll.BackgroundTransparency = 1
        PCScroll.BorderSizePixel = 0
        PCScroll.Position = UDim2.new(0, 0, 0, 44)
        PCScroll.Size = UDim2.new(1, 0, 1, -44)
        PCScroll.ScrollBarThickness = 2
        PCScroll.ScrollBarImageColor3 = Library.Theme.Accent
        PCScroll.ScrollBarImageTransparency = 0.5
        PCScroll.ZIndex = 21
        PCScroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        PCScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

        local PCList = Instance.new("UIListLayout")
        PCList.Parent = PCScroll
        PCList.SortOrder = Enum.SortOrder.LayoutOrder
        PCList.Padding = UDim.new(0, 10)
        PCList.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local PCPad = Instance.new("UIPadding")
        PCPad.Parent = PCScroll
        PCPad.PaddingLeft = UDim.new(0, 12)
        PCPad.PaddingRight = UDim.new(0, 12)
        PCPad.PaddingTop = UDim.new(0, 12)
        PCPad.PaddingBottom = UDim.new(0, 12)

        -- Avatar + name hero card
        local HeroCard = Instance.new("Frame")
        HeroCard.Name = "HeroCard"
        HeroCard.Parent = PCScroll
        HeroCard.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        HeroCard.BackgroundTransparency = 0
        HeroCard.BorderSizePixel = 0
        HeroCard.Size = UDim2.new(1, 0, 0, 110)
        HeroCard.ZIndex = 22
        HeroCard.LayoutOrder = 1
        local HCC = Instance.new("UICorner") HCC.CornerRadius = UDim.new(0, 10) HCC.Parent = HeroCard

        -- Gradient banner top
        local Banner = Instance.new("Frame")
        Banner.Parent = HeroCard
        Banner.BackgroundColor3 = Library.Theme.Accent
        Banner.BackgroundTransparency = 0
        Banner.BorderSizePixel = 0
        Banner.Size = UDim2.new(1, 0, 0, 38)
        Banner.ZIndex = 22
        local BanC = Instance.new("UICorner") BanC.CornerRadius = UDim.new(0, 10) BanC.Parent = Banner
        local BanFix = Instance.new("Frame")
        BanFix.BackgroundColor3 = Library.Theme.Accent
        BanFix.BorderSizePixel = 0
        BanFix.Position = UDim2.new(0, 0, 0.5, 0)
        BanFix.Size = UDim2.new(1, 0, 0.5, 0)
        BanFix.Parent = Banner
        local BanGrad = Instance.new("UIGradient")
        BanGrad.Color = ColorSequence.new(Library.Theme.Accent, Color3.fromRGB(60, 0, 90))
        BanGrad.Rotation = 90
        BanGrad.Parent = Banner

        -- Avatar image
        local AvatarFrame = Instance.new("Frame")
        AvatarFrame.Parent = HeroCard
        AvatarFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 13)
        AvatarFrame.BorderSizePixel = 0
        AvatarFrame.Position = UDim2.new(0, 12, 0, 18)
        AvatarFrame.Size = UDim2.new(0, 58, 0, 58)
        AvatarFrame.ZIndex = 24
        local AFC = Instance.new("UICorner") AFC.CornerRadius = UDim.new(1, 0) AFC.Parent = AvatarFrame
        local AFStroke = Instance.new("UIStroke")
        AFStroke.Color = Library.Theme.Accent
        AFStroke.Thickness = 2
        AFStroke.Parent = AvatarFrame

        local AvatarImg = Instance.new("ImageLabel")
        AvatarImg.Parent = AvatarFrame
        AvatarImg.BackgroundTransparency = 1
        AvatarImg.Size = UDim2.new(1, 0, 1, 0)
        AvatarImg.ZIndex = 25
        local AIMC = Instance.new("UICorner") AIMC.CornerRadius = UDim.new(1, 0) AIMC.Parent = AvatarImg

        -- Load avatar async
        task.spawn(function()
            local ok, tid = pcall(function()
                return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
            end)
            if ok then AvatarImg.Image = tid end
        end)

        -- Username
        local DispName = Instance.new("TextLabel")
        DispName.Parent = HeroCard
        DispName.BackgroundTransparency = 1
        DispName.Position = UDim2.new(0, 78, 0, 42)
        DispName.Size = UDim2.new(1, -90, 0, 20)
        DispName.Font = Enum.Font.GothamBold
        DispName.Text = Player.DisplayName
        DispName.TextColor3 = Color3.fromRGB(255, 255, 255)
        DispName.TextSize = 16
        DispName.TextXAlignment = Enum.TextXAlignment.Left
        DispName.ZIndex = 24

        local UserName = Instance.new("TextLabel")
        UserName.Parent = HeroCard
        UserName.BackgroundTransparency = 1
        UserName.Position = UDim2.new(0, 78, 0, 62)
        UserName.Size = UDim2.new(1, -90, 0, 16)
        UserName.Font = Enum.Font.Gotham
        UserName.Text = "@" .. Player.Name
        UserName.TextColor3 = Library.Theme.TextDisabled
        UserName.TextSize = 12
        UserName.TextXAlignment = Enum.TextXAlignment.Left
        UserName.ZIndex = 24

        -- Copy username button
        local CopyBtn = Instance.new("TextButton")
        CopyBtn.Parent = HeroCard
        CopyBtn.BackgroundColor3 = Library.Theme.Accent
        CopyBtn.BackgroundTransparency = 0.7
        CopyBtn.BorderSizePixel = 0
        CopyBtn.Position = UDim2.new(1, -70, 0, 75)
        CopyBtn.Size = UDim2.new(0, 58, 0, 22)
        CopyBtn.Font = Enum.Font.GothamBold
        CopyBtn.Text = "Copy"
        CopyBtn.TextColor3 = Library.Theme.Accent
        CopyBtn.TextSize = 11
        CopyBtn.ZIndex = 24
        local CBC = Instance.new("UICorner") CBC.CornerRadius = UDim.new(0, 5) CBC.Parent = CopyBtn
        CopyBtn.MouseButton1Click:Connect(function()
            if setclipboard then pcall(setclipboard, Player.Name) end
            CopyBtn.Text = "✓"
            task.delay(1.5, function() if CopyBtn and CopyBtn.Parent then CopyBtn.Text = "Copy" end end)
        end)

        -- Info rows helper
        local function MakeInfoCard(order, icon, label, value, accent)
            local card = Instance.new("Frame")
            card.Parent = PCScroll
            card.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
            card.BorderSizePixel = 0
            card.Size = UDim2.new(1, 0, 0, 44)
            card.ZIndex = 22
            card.LayoutOrder = order
            local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 8) cc.Parent = card

            local ic = Instance.new("Frame")
            ic.Parent = card
            ic.BackgroundColor3 = accent or Library.Theme.Accent
            ic.BackgroundTransparency = 0.8
            ic.BorderSizePixel = 0
            ic.Position = UDim2.new(0, 10, 0.5, -12)
            ic.Size = UDim2.new(0, 24, 0, 24)
            ic.ZIndex = 23
            local icc = Instance.new("UICorner") icc.CornerRadius = UDim.new(0, 6) icc.Parent = ic
            local ii = Instance.new("ImageLabel")
            ii.Parent = ic
            ii.BackgroundTransparency = 1
            ii.AnchorPoint = Vector2.new(0.5, 0.5)
            ii.Position = UDim2.new(0.5, 0, 0.5, 0)
            ii.Size = UDim2.new(0, 14, 0, 14)
            ii.ZIndex = 24
            Library:SetIcon(ii, icon, accent or Library.Theme.Accent)

            local lbl = Instance.new("TextLabel")
            lbl.Parent = card
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0, 42, 0, 7)
            lbl.Size = UDim2.new(1, -52, 0, 14)
            lbl.Font = Enum.Font.Gotham
            lbl.Text = label
            lbl.TextColor3 = Library.Theme.TextDisabled
            lbl.TextSize = 10
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 23

            local val = Instance.new("TextLabel")
            val.Parent = card
            val.BackgroundTransparency = 1
            val.Position = UDim2.new(0, 42, 0, 22)
            val.Size = UDim2.new(1, -52, 0, 16)
            val.Font = Enum.Font.GothamBold
            val.Text = tostring(value)
            val.TextColor3 = Color3.fromRGB(230, 230, 230)
            val.TextSize = 12
            val.TextXAlignment = Enum.TextXAlignment.Left
            val.TextTruncate = Enum.TextTruncate.AtEnd
            val.ZIndex = 23
            return val
        end

        -- Generate HWID-like string from UserId + machine hash
        local function GetHWID()
            local uid = tostring(Player.UserId)
            local hash = 0
            for i = 1, #uid do
                hash = (hash * 31 + uid:byte(i)) % 0xFFFFFFFF
            end
            local h1 = string.format("%08X", hash)
            local h2 = string.format("%08X", (hash * 0x9E3779B9) % 0xFFFFFFFF)
            local h3 = string.format("%08X", (hash * 0x6C62272E) % 0xFFFFFFFF)
            return h1:sub(1,8) .. "-" .. h2:sub(1,4) .. "-" .. h2:sub(5,8) .. "-" .. h3:sub(1,4) .. "-" .. h3:sub(5,8) .. "00" .. h1:sub(1,4)
        end

        -- Account age
        local function GetAccountAge()
            local age = Player.AccountAge
            if age < 30 then return age .. " days"
            elseif age < 365 then return math.floor(age/30) .. " months"
            else return math.floor(age/365) .. " years, " .. math.floor((age%365)/30) .. " mo"
            end
        end

        MakeInfoCard(2, "hash", "User ID", tostring(Player.UserId))
        MakeInfoCard(3, "fingerprint", "HWID", GetHWID(), Color3.fromRGB(255, 160, 50))
        MakeInfoCard(4, "calendar", "Account Age", GetAccountAge(), Color3.fromRGB(100, 200, 100))
        MakeInfoCard(5, "users", "Team", Player.Team and Player.Team.Name or "None")

        -- Session timer card
        local sessionStart = tick()
        local timeVal = MakeInfoCard(6, "timer", "Session Time", "00:00", Color3.fromRGB(130, 130, 255))

        -- Membership card
        local memStr = "None"
        if Player.MembershipType == Enum.MembershipType.BuildersClub then memStr = "Builders Club"
        elseif Player.MembershipType == Enum.MembershipType.TurboBuildersClub then memStr = "Turbo BC"
        elseif Player.MembershipType == Enum.MembershipType.OutrageousBuildersClub then memStr = "Outrageous BC"
        end
        MakeInfoCard(7, "star", "Membership", memStr, Color3.fromRGB(255, 220, 80))

        -- Ping/server info
        local pingVal = MakeInfoCard(8, "wifi", "Ping", "measuring...", Color3.fromRGB(80, 200, 180))
        task.spawn(function()
            local stats = game:GetService("Stats")
            while PCWindow and PCWindow.Parent do
                local elapsed = math.floor(tick() - sessionStart)
                local m = math.floor(elapsed / 60)
                local s = elapsed % 60
                if timeVal and timeVal.Parent then
                    timeVal.Text = string.format("%02d:%02d", m, s)
                end
                local ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                if pingVal and pingVal.Parent then
                    pingVal.Text = tostring(ping) .. " ms"
                    pingVal.TextColor3 = ping < 80 and Color3.fromRGB(100, 240, 120)
                        or ping < 150 and Color3.fromRGB(255, 220, 80)
                        or Color3.fromRGB(255, 80, 80)
                end
                task.wait(1)
            end
        end)
    end)

    LayoutFrame.Name = "LayoutFrame"
    LayoutFrame.Parent = Main
    LayoutFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LayoutFrame.BackgroundTransparency = 1.000
    LayoutFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LayoutFrame.BorderSizePixel = 0
    LayoutFrame.Position = UDim2.new(0, 144, 0, 50)
    LayoutFrame.Size = UDim2.new(1, -144, 1, -50)
    LayoutFrame.ClipsDescendants = true

    RealLayout.Name = "RealLayout"
    RealLayout.Parent = LayoutFrame
    RealLayout.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    RealLayout.BackgroundTransparency = 1.000
    RealLayout.BorderColor3 = Color3.fromRGB(0, 0, 0)
    RealLayout.BorderSizePixel = 0
    RealLayout.Position = UDim2.new(0, 0, 0, 40)
    RealLayout.Size = UDim2.new(1, 0, 1, -40)

    LayoutList.Name = "Layout List"
    LayoutList.Parent = RealLayout

    UIPageLayout.Parent = LayoutList
    UIPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIPageLayout.EasingStyle = Enum.EasingStyle.Quad
    UIPageLayout.TweenTime = 0.300

    LayoutName.Name = "LayoutName"
    LayoutName.Parent = LayoutFrame
    LayoutName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LayoutName.BackgroundTransparency = 1.000
    LayoutName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LayoutName.BorderSizePixel = 0
    LayoutName.Size = UDim2.new(1, 0, 0, 40)

    TextLabel.Parent = LayoutName
    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.BackgroundTransparency = 1.000
    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.BorderSizePixel = 0
    TextLabel.Position = UDim2.new(0, 10, 0, 0)
    TextLabel.Size = UDim2.new(1, -10, 1, 0)
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = ""
    TextLabel.TextColor3 = Library.Theme.Text
    TextLabel.TextSize = 13.000
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left

    DropdownZone.Name = "DropdownZone"
    DropdownZone.Parent = Main
    DropdownZone.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    DropdownZone.BackgroundTransparency = 1
    DropdownZone.BorderColor3 = Color3.fromRGB(0, 0, 0)
    DropdownZone.BorderSizePixel = 0
    DropdownZone.Size = UDim2.new(1, 0, 1, 0)
    DropdownZone.Visible = false

    self:MakeDraggable(Top, DropShadowHolder)

    local ResizeHandle = Instance.new("Frame")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Parent = DropShadowHolder
    ResizeHandle.AnchorPoint = Vector2.new(1, 1)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.BorderSizePixel = 0
    ResizeHandle.Position = UDim2.new(1, 8, 1, 8)
    ResizeHandle.Size = UDim2.new(0, 22, 0, 22)
    ResizeHandle.ZIndex = 60

    local ResizeH = Instance.new("Frame")
    ResizeH.Parent = ResizeHandle
    ResizeH.AnchorPoint = Vector2.new(1, 1)
    ResizeH.BackgroundColor3 = Color3.fromRGB(170, 170, 178)
    ResizeH.BackgroundTransparency = 0.15
    ResizeH.BorderSizePixel = 0
    ResizeH.Position = UDim2.new(1, 0, 1, 0)
    ResizeH.Size = UDim2.new(0, 20, 0, 4)
    ResizeH.ZIndex = 61
    local RHC = Instance.new("UICorner")
    RHC.CornerRadius = UDim.new(1, 0)
    RHC.Parent = ResizeH

    local ResizeV = Instance.new("Frame")
    ResizeV.Parent = ResizeHandle
    ResizeV.AnchorPoint = Vector2.new(1, 1)
    ResizeV.BackgroundColor3 = Color3.fromRGB(170, 170, 178)
    ResizeV.BackgroundTransparency = 0.15
    ResizeV.BorderSizePixel = 0
    ResizeV.Position = UDim2.new(1, 0, 1, 0)
    ResizeV.Size = UDim2.new(0, 4, 0, 20)
    ResizeV.ZIndex = 61
    local RVC = Instance.new("UICorner")
    RVC.CornerRadius = UDim.new(1, 0)
    RVC.Parent = ResizeV

    do
        local Resizing = false
        local StartPos, StartSize
        local MinW, MinH = 420, 280
        local function BeginResize(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Resizing = true
                StartPos = Input.Position
                StartSize = DropShadowHolder.AbsoluteSize
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Resizing = false
                        ConfigWindow.Size = UDim2.new(0, DropShadowHolder.AbsoluteSize.X, 0, DropShadowHolder.AbsoluteSize.Y)
                    end
                end)
            end
        end
        ResizeHandle.InputBegan:Connect(BeginResize)
        ResizeH.InputBegan:Connect(BeginResize)
        ResizeV.InputBegan:Connect(BeginResize)
        UserInputService.InputChanged:Connect(function(Input)
            if not Resizing then return end
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                local dx = Input.Position.X - StartPos.X
                local dy = Input.Position.Y - StartPos.Y
                local nw = math.max(MinW, StartSize.X + dx)
                local nh = math.max(MinH, StartSize.Y + dy)
                DropShadowHolder.Size = UDim2.new(0, nw, 0, nh)
            end
        end)
    end

    local FloatBox = Instance.new("Frame")
    FloatBox.Name = "FloatingButton"
    FloatBox.Parent = TeddyUI_Premium
    FloatBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    FloatBox.BackgroundTransparency = 0.5
    FloatBox.BorderSizePixel = 0
    FloatBox.Position = UDim2.new(0.05, 0, 0.4, 0)
    FloatBox.Size = UDim2.new(0, 160, 0, 42)
    FloatBox.ZIndex = 10
    FloatBox.Visible = true

    local FloatCorner = Instance.new("UICorner")
    FloatCorner.CornerRadius = UDim.new(0, 8)
    FloatCorner.Parent = FloatBox

    local FloatStroke = Instance.new("UIStroke")
    FloatStroke.Thickness = 1
    FloatStroke.Color = Color3.fromRGB(255, 255, 255)
    FloatStroke.Transparency = 0.7
    FloatStroke.Parent = FloatBox

    local FloatLogo = Instance.new("ImageLabel")
    FloatLogo.Name = "Logo"
    FloatLogo.Parent = FloatBox
    FloatLogo.BackgroundTransparency = 1
    FloatLogo.Position = UDim2.new(0, 8, 0.5, -12)
    FloatLogo.Size = UDim2.new(0, 24, 0, 24)
    FloatLogo.Image = ConfigWindow.Logo or ConfigWindow.Icon
    FloatLogo.ZIndex = 11

    local FloatTitle = Instance.new("TextLabel")
    FloatTitle.Name = "Title"
    FloatTitle.Parent = FloatBox
    FloatTitle.BackgroundTransparency = 1
    FloatTitle.Position = UDim2.new(0, 38, 0, 0)
    FloatTitle.Size = UDim2.new(1, -70, 1, 0)
    FloatTitle.Font = Enum.Font.GothamBold
    FloatTitle.Text = ConfigWindow.Title or "sh1ttybanana"
    FloatTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    FloatTitle.TextSize = 12
    FloatTitle.TextXAlignment = Enum.TextXAlignment.Left
    FloatTitle.TextTruncate = Enum.TextTruncate.AtEnd
    FloatTitle.ZIndex = 11

    local FloatScan = Instance.new("ImageButton")
    FloatScan.Name = "Scan"
    FloatScan.Parent = FloatBox
    FloatScan.BackgroundTransparency = 1
    FloatScan.Position = UDim2.new(1, -32, 0.5, -10)
    FloatScan.Size = UDim2.new(0, 20, 0, 20)
    FloatScan.ZIndex = 12
    Library:SetIcon(FloatScan, Library.DefaultIcons.Scan, Color3.fromRGB(255, 255, 255))

    self:MakeDraggable(FloatBox, FloatBox)

    local function ToggleWindow(open)
        if open then
            FloatBox.Visible = false
            DropShadowHolder.Visible = true
            DropShadowHolder.Size = UDim2.new(0, 40, 0, 40)
            Library:Tween(DropShadowHolder, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = ConfigWindow.Size
            })
        else
            Library:Tween(DropShadowHolder, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 40, 0, 40)
            }, function()
                DropShadowHolder.Visible = false
                DropShadowHolder.Size = ConfigWindow.Size
                FloatBox.Visible = true
            end)
        end
    end

    FloatScan.MouseButton1Click:Connect(function()
        local isOpen = DropShadowHolder.Visible
        ToggleWindow(not isOpen)
    end)

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(SearchBox.Text)
        for _, child in ipairs(ScrollingTab:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChild("NameTab") then
                local label = child.NameTab
                local raw = label:GetAttribute("RawName") or label.Text or ""
                local name = string.lower(raw)
                local match = q == "" or string.find(name, q, 1, true) ~= nil
                child.Visible = match
                if q ~= "" and match then
                    local start = string.find(name, q, 1, true)
                    if start then
                        label.Text = string.sub(raw, 1, start - 1) .. "【" .. string.sub(raw, start, start + #q - 1) .. "】" .. string.sub(raw, start + #q)
                        label.TextColor3 = Color3.fromRGB(255, 220, 50)
                    end
                else
                    label.Text = raw
                    label.TextColor3 = Library.Theme.Text
                end
            end
        end
    end)

    local IsEnlarged = false
    local NormalSize = ConfigWindow.Size
    local LargeSize = UDim2.new(0, NormalSize.X.Offset * 1.25, 0, NormalSize.Y.Offset * 1.25)

    Minize.MouseButton1Click:Connect(function()
        ToggleWindow(false)
    end)

    Large.MouseButton1Click:Connect(function()
        IsEnlarged = not IsEnlarged
        local target = IsEnlarged and LargeSize or NormalSize
        Library:Tween(DropShadowHolder, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = target
        })
    end)

    Close.MouseButton1Down:Connect(function()
        DropdownZone.Visible = true
        local tat_ = Instance.new("Frame", DropdownZone)
        tat_["BorderSizePixel"] = 0
        tat_["BackgroundColor3"] = Color3.fromRGB(19, 19, 19)
        tat_["AnchorPoint"] = Vector2.new(0.5, 0.5)
        tat_["Size"] = UDim2.new(0, 400, 0, 150)
        tat_["Position"] = UDim2.new(0.5, 0, 0.5, 0)
        tat_["BorderColor3"] = Color3.fromRGB(0, 0, 0)
        tat_["Name"] = "Tat"

        local suacc = Instance.new("UIStroke", tat_)
        suacc["Transparency"] = 0.5
        suacc["Color"] = Library.Theme.Stroke

        local suacc = Instance.new("UICorner", tat_)
        suacc["CornerRadius"] = UDim.new(0, 5)

        local suacc2 = Instance.new("TextLabel", tat_)
        suacc2["BorderSizePixel"] = 0
        suacc2["TextSize"] = 20
        suacc2["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
        suacc2["BackgroundTransparency"] = 1
        suacc2["FontFace"] = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        suacc2["TextColor3"] = Library.Theme.Text
        suacc2["Size"] = UDim2.new(0, 400, 0, 50)
        suacc2["BorderColor3"] = Color3.fromRGB(0, 0, 0)
        suacc2["Text"] = "Are you sure"

        local btnyes = Instance.new("TextButton", tat_)
        btnyes["BorderSizePixel"] = 0
        btnyes["TextSize"] = 25
        btnyes["TextColor3"] = Library.Theme.Text
        btnyes["BackgroundColor3"] = Library.Theme.Accent
        btnyes["FontFace"] = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        btnyes["AnchorPoint"] = Vector2.new(0, 1)
        btnyes["Size"] = UDim2.new(0, 150, 0, 50)
        btnyes["BorderColor3"] = Color3.fromRGB(0, 0, 0)
        btnyes["Text"] = "Yes"
        btnyes["Position"] = UDim2.new(0, 40, 1, -40)
        
        btnyes.MouseButton1Down:Connect(function()
            FloatBox:Destroy()
            DropShadowHolder:Destroy()
            DropdownZone.Visible = false
            tat_:Destroy()
            TeddyUI_Premium:Destroy()
        end)

        local thuaaa = Instance.new("UICorner", btnyes)
        local thuaaa = Instance.new("UIStroke", btnyes)
        thuaaa["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
        thuaaa["Color"] = Library.Theme.Stroke

        local btnno = Instance.new("TextButton", tat_)
        btnno["BorderSizePixel"] = 0
        btnno["TextSize"] = 25
        btnno["TextColor3"] = Library.Theme.Text
        btnno["BackgroundColor3"] = Library.Theme.Background
        btnno["FontFace"] = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        btnno["AnchorPoint"] = Vector2.new(1, 1)
        btnno["Size"] = UDim2.new(0, 150, 0, 50)
        btnno["BorderColor3"] = Color3.fromRGB(0, 0, 0)
        btnno["Text"] = "No"
        btnno["Position"] = UDim2.new(1, -40, 1, -40)

        btnno.MouseButton1Down:Connect(function()
            tat_:Destroy()
            DropdownZone.Visible = false
        end)

        local thuaa = Instance.new("UICorner", btnno)
        local thuaa = Instance.new("UIStroke", btnno)
        thuaa["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
        thuaa["Color"] = Library.Theme.Stroke
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
        local Choose_2 = Instance.new("Frame")
        local UICorner_4 = Instance.new("UICorner")
        local TabIcon = Instance.new("ImageLabel")
        local NameTab_2 = Instance.new("TextLabel")
        local Click_Tab_2 = Instance.new("TextButton")
        local Layout = Instance.new("ScrollingFrame")
        local UIPadding_3 = Instance.new("UIPadding")
        local UIListLayout_3 = Instance.new("UIListLayout")
        local Divider = Instance.new("Frame")

        TabDisable.Name = "TabDisable"
        TabDisable.Parent = ScrollingTab
        TabDisable.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabDisable.BackgroundTransparency = 1.000
        TabDisable.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabDisable.BorderSizePixel = 0
        TabDisable.Size = UDim2.new(1, 0, 0, 36)

        Choose_2.Name = "Choose"
        Choose_2.Parent = TabDisable
        Choose_2.BackgroundColor3 = Library.Theme.Accent
        Choose_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Choose_2.BorderSizePixel = 0
        Choose_2.Position = UDim2.new(0, 0, 0.5, -9)
        Choose_2.Size = UDim2.new(0, 3, 0, 18)
        Choose_2.Visible = false

        UICorner_4.CornerRadius = UDim.new(1, 0)
        UICorner_4.Parent = Choose_2

        TabIcon.Name = "TabIcon"
        TabIcon.Parent = TabDisable
        TabIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabIcon.BackgroundTransparency = 1.000
        TabIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabIcon.BorderSizePixel = 0
        TabIcon.Position = UDim2.new(0, 10, 0, 8)
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        Library:SetIcon(TabIcon, Locked and not Unlocked and Library.DefaultIcons.Lock or iconName, Library.Theme.Accent)

        NameTab_2.Name = "NameTab"
        NameTab_2.Parent = TabDisable
        NameTab_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        NameTab_2.BackgroundTransparency = 1.000
        NameTab_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NameTab_2.BorderSizePixel = 0
        NameTab_2.Position = UDim2.new(0, 32, 0, 0)
        NameTab_2.Size = UDim2.new(1, -50, 1, 0)
        NameTab_2.Font = Enum.Font.GothamBold
        NameTab_2.Text = name
        NameTab_2.TextColor3 = Library.Theme.Text
        NameTab_2.TextSize = 12.000
        NameTab_2.TextTransparency = 0.35
        NameTab_2.TextXAlignment = Enum.TextXAlignment.Left
        NameTab_2:SetAttribute("RawName", name)

        local DragIcon = Instance.new("ImageLabel")
        DragIcon.Name = "DragIcon"
        DragIcon.Parent = TabDisable
        DragIcon.BackgroundTransparency = 1
        DragIcon.Position = UDim2.new(1, -22, 0.5, -7)
        DragIcon.Size = UDim2.new(0, 14, 0, 14)
        DragIcon.Visible = false
        DragIcon.ZIndex = 3
        Library:SetIcon(DragIcon, "grip-vertical", Library.Theme.TextDisabled)

        -- Invisible button overlay so DragIcon actually receives input
        local DragBtn = Instance.new("TextButton")
        DragBtn.Name = "DragBtn"
        DragBtn.Parent = TabDisable
        DragBtn.BackgroundTransparency = 1
        DragBtn.Position = UDim2.new(1, -26, 0, 0)
        DragBtn.Size = UDim2.new(0, 26, 1, 0)
        DragBtn.Text = ""
        DragBtn.ZIndex = 4
        DragBtn.Visible = false

        Click_Tab_2.Name = "Click_Tab"
        Click_Tab_2.Parent = TabDisable
        Click_Tab_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Click_Tab_2.BackgroundTransparency = 1.000
        Click_Tab_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Click_Tab_2.BorderSizePixel = 0
        Click_Tab_2.Size = UDim2.new(1, 0, 1, 0)
        Click_Tab_2.Font = Enum.Font.SourceSans
        Click_Tab_2.Text = ""
        Click_Tab_2.TextColor3 = Color3.fromRGB(0, 0, 0)
        Click_Tab_2.TextSize = 14.000

        -- Tab drag reorder logic
        local tabDragging = false
        local tabDragStartY = 0

        DragBtn.InputBegan:Connect(function(input)
            if not ReorderMode then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            tabDragging = true
            tabDragStartY = input.Position.Y
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not tabDragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local dy = input.Position.Y - tabDragStartY
            tabDragStartY = input.Position.Y
            -- Find sorted tab list
            local tabs = {}
            for _, child in ipairs(ScrollingTab:GetChildren()) do
                if child:IsA("Frame") and child.Name == "TabDisable" then
                    table.insert(tabs, child)
                end
            end
            table.sort(tabs, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
            -- Find our index
            local myIdx = nil
            for i, t in ipairs(tabs) do
                if t == TabDisable then myIdx = i break end
            end
            if not myIdx then return end
            if dy < -18 and myIdx > 1 then
                -- Swap with previous
                local prev = tabs[myIdx - 1]
                local tempOrder = TabDisable.LayoutOrder
                TabDisable.LayoutOrder = prev.LayoutOrder
                prev.LayoutOrder = tempOrder
                -- Also swap in TabElements
                for i, e in ipairs(TabElements) do
                    if e.Frame == TabDisable then
                        for j, f in ipairs(TabElements) do
                            if f.Frame == prev then
                                TabElements[i], TabElements[j] = TabElements[j], TabElements[i]
                                break
                            end
                        end
                        break
                    end
                end
            elseif dy > 18 and myIdx < #tabs then
                -- Swap with next
                local next = tabs[myIdx + 1]
                local tempOrder = TabDisable.LayoutOrder
                TabDisable.LayoutOrder = next.LayoutOrder
                next.LayoutOrder = tempOrder
                for i, e in ipairs(TabElements) do
                    if e.Frame == TabDisable then
                        for j, f in ipairs(TabElements) do
                            if f.Frame == next then
                                TabElements[i], TabElements[j] = TabElements[j], TabElements[i]
                                break
                            end
                        end
                        break
                    end
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                tabDragging = false
            end
        end)

        Divider.Name = "TabDivider"
        Divider.Parent = TabDisable
        Divider.BackgroundColor3 = Library.Theme.Accent
        Divider.BackgroundTransparency = 0.85
        Divider.BorderSizePixel = 0
        Divider.Position = UDim2.new(0, 8, 1, -1)
        Divider.Size = UDim2.new(1, -16, 0, 1)

        table.insert(TabElements, { Frame = TabDisable, DragIcon = DragIcon, DragBtn = DragBtn, Name = name })

        Layout.Name = "Layout"
        Layout.Parent = LayoutList
        Layout.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Layout.BackgroundTransparency = 1.000
        Layout.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Layout.BorderSizePixel = 0
        Layout.Selectable = false
        Layout.Size = UDim2.new(1, 0, 1, 0)
        Layout.CanvasSize = UDim2.new(0, 0, 1, 0)
        Layout.ScrollBarThickness = 0
        Layout.LayoutOrder = AllLayouts
        Library:UpdateScrolling(Layout, UIListLayout_3)

        UIPadding_3.Parent = Layout
        UIPadding_3.PaddingBottom = UDim.new(0, 7)
        UIPadding_3.PaddingLeft = UDim.new(0, 10)
        UIPadding_3.PaddingRight = UDim.new(0, 7)

        UIListLayout_3.Parent = Layout
        UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_3.Padding = UDim.new(0, 8)

        local function SelectThisTab()
            TextLabel.Text = name
            for i, v in next, ScrollingTab:GetChildren() do
                if v:IsA("Frame") and v:FindFirstChild("NameTab") then
                    Library:TweenInstance(v.NameTab, 0.28, "TextTransparency", 0.35)
                    if v:FindFirstChild("Choose") then
                        v.Choose.Visible = false
                    end
                end
            end
            Library:TweenInstance(NameTab_2, 0.22, "TextTransparency", 0)
            UIPageLayout:JumpToIndex(Layout.LayoutOrder)
            Choose_2.Visible = true
        end

        if AllLayouts == 0 and Unlocked then
            NameTab_2.TextTransparency = 0
            Choose_2.Visible = true
            UIPageLayout:JumpToIndex(0)
            TextLabel.Text = name
        end

        local function ShowLockPopup()
            DropdownZone.Visible = true
            Library:TweenInstance(DropdownZone, 0.25, "BackgroundTransparency", 0.45)

            local Popup = Instance.new("Frame")
            Popup.Name = "LockPopup"
            Popup.Parent = DropdownZone
            Popup.AnchorPoint = Vector2.new(0.5, 0.5)
            Popup.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            Popup.BorderSizePixel = 0
            Popup.Position = UDim2.new(0.5, 0, 0.5, 0)
            Popup.Size = UDim2.new(0, 340, 0, 210)

            local PopupCorner = Instance.new("UICorner")
            PopupCorner.CornerRadius = UDim.new(0, 10)
            PopupCorner.Parent = Popup

            local PopupStroke = Instance.new("UIStroke")
            PopupStroke.Color = Library.Theme.Stroke
            PopupStroke.Transparency = 0.55
            PopupStroke.Parent = Popup

            local LockIcon = Instance.new("ImageLabel")
            LockIcon.Parent = Popup
            LockIcon.BackgroundTransparency = 1
            LockIcon.Position = UDim2.new(0, 18, 0, 16)
            LockIcon.Size = UDim2.new(0, 20, 0, 20)
            Library:SetIcon(LockIcon, Library.DefaultIcons.Lock, Library.Theme.Accent)

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Parent = Popup
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Position = UDim2.new(0, 46, 0, 14)
            TitleLbl.Size = UDim2.new(1, -60, 0, 24)
            TitleLbl.Font = Enum.Font.GothamBold
            TitleLbl.Text = LockTitle
            TitleLbl.TextColor3 = Library.Theme.Text
            TitleLbl.TextSize = 15
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

            local DescLbl = Instance.new("TextLabel")
            DescLbl.Parent = Popup
            DescLbl.BackgroundTransparency = 1
            DescLbl.Position = UDim2.new(0, 18, 0, 44)
            DescLbl.Size = UDim2.new(1, -36, 0, 20)
            DescLbl.Font = Enum.Font.Gotham
            DescLbl.Text = LockDesc .. ' "' .. name .. '"'
            DescLbl.TextColor3 = Library.Theme.TextDisabled
            DescLbl.TextSize = 12
            DescLbl.TextXAlignment = Enum.TextXAlignment.Left

            local PassFrame = Instance.new("Frame")
            PassFrame.Parent = Popup
            PassFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
            PassFrame.BorderSizePixel = 0
            PassFrame.Position = UDim2.new(0, 18, 0, 74)
            PassFrame.Size = UDim2.new(1, -36, 0, 34)

            local PassCorner = Instance.new("UICorner")
            PassCorner.CornerRadius = UDim.new(0, 6)
            PassCorner.Parent = PassFrame

            local PassBox = Instance.new("TextBox")
            PassBox.Parent = PassFrame
            PassBox.BackgroundTransparency = 1
            PassBox.Position = UDim2.new(0, 12, 0, 0)
            PassBox.Size = UDim2.new(1, -24, 1, 0)
            PassBox.Font = Enum.Font.Gotham
            PassBox.PlaceholderText = "Password"
            PassBox.Text = ""
            PassBox.TextColor3 = Library.Theme.Text
            PassBox.TextSize = 13
            PassBox.TextXAlignment = Enum.TextXAlignment.Left
            PassBox.ClearTextOnFocus = false

            local RememberFrame = Instance.new("Frame")
            RememberFrame.Parent = Popup
            RememberFrame.BackgroundTransparency = 1
            RememberFrame.Position = UDim2.new(0, 18, 0, 118)
            RememberFrame.Size = UDim2.new(1, -36, 0, 22)

            local RememberToggle = Instance.new("Frame")
            RememberToggle.Parent = RememberFrame
            RememberToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            RememberToggle.BorderSizePixel = 0
            RememberToggle.Size = UDim2.new(0, 34, 0, 18)
            RememberToggle.Position = UDim2.new(0, 0, 0.5, -9)

            local RememberCorner = Instance.new("UICorner")
            RememberCorner.CornerRadius = UDim.new(1, 0)
            RememberCorner.Parent = RememberToggle

            local RememberKnob = Instance.new("Frame")
            RememberKnob.Parent = RememberToggle
            RememberKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            RememberKnob.BorderSizePixel = 0
            RememberKnob.Position = UDim2.new(0, 2, 0.5, -7)
            RememberKnob.Size = UDim2.new(0, 14, 0, 14)

            local KnobCorner = Instance.new("UICorner")
            KnobCorner.CornerRadius = UDim.new(1, 0)
            KnobCorner.Parent = RememberKnob

            local RememberText = Instance.new("TextLabel")
            RememberText.Parent = RememberFrame
            RememberText.BackgroundTransparency = 1
            RememberText.Position = UDim2.new(0, 42, 0, 0)
            RememberText.Size = UDim2.new(1, -42, 1, 0)
            RememberText.Font = Enum.Font.Gotham
            RememberText.Text = "Remember me"
            RememberText.TextColor3 = Library.Theme.Text
            RememberText.TextSize = 12
            RememberText.TextXAlignment = Enum.TextXAlignment.Left

            local RememberOn = false
            local function SetRemember(state)
                RememberOn = state
                if state then
                    Library:TweenInstance(RememberToggle, 0.25, "BackgroundColor3", Library.Theme.Accent)
                    Library:TweenInstance(RememberKnob, 0.25, "Position", UDim2.new(0, 18, 0.5, -7))
                    Library:TweenInstance(RememberKnob, 0.25, "BackgroundColor3", Library.Theme.Text)
                else
                    Library:TweenInstance(RememberToggle, 0.25, "BackgroundColor3", Color3.fromRGB(50, 50, 50))
                    Library:TweenInstance(RememberKnob, 0.25, "Position", UDim2.new(0, 2, 0.5, -7))
                    Library:TweenInstance(RememberKnob, 0.25, "BackgroundColor3", Color3.fromRGB(200, 200, 200))
                end
            end

            local RememberBtn = Instance.new("TextButton")
            RememberBtn.Parent = RememberFrame
            RememberBtn.BackgroundTransparency = 1
            RememberBtn.Size = UDim2.new(1, 0, 1, 0)
            RememberBtn.Text = ""
            RememberBtn.MouseButton1Click:Connect(function()
                SetRemember(not RememberOn)
            end)

            local ErrorLbl = Instance.new("TextLabel")
            ErrorLbl.Parent = Popup
            ErrorLbl.BackgroundTransparency = 1
            ErrorLbl.Position = UDim2.new(0, 18, 0, 144)
            ErrorLbl.Size = UDim2.new(1, -36, 0, 16)
            ErrorLbl.Font = Enum.Font.Gotham
            ErrorLbl.Text = ""
            ErrorLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
            ErrorLbl.TextSize = 12
            ErrorLbl.TextXAlignment = Enum.TextXAlignment.Left
            ErrorLbl.Visible = false

            local CancelBtn = Instance.new("TextButton")
            CancelBtn.Parent = Popup
            CancelBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            CancelBtn.BorderSizePixel = 0
            CancelBtn.Position = UDim2.new(0, 18, 1, -48)
            CancelBtn.Size = UDim2.new(0, 140, 0, 34)
            CancelBtn.Font = Enum.Font.GothamBold
            CancelBtn.Text = "Cancel"
            CancelBtn.TextColor3 = Library.Theme.Text
            CancelBtn.TextSize = 13

            local CancelCorner = Instance.new("UICorner")
            CancelCorner.CornerRadius = UDim.new(0, 6)
            CancelCorner.Parent = CancelBtn

            local UnlockBtn = Instance.new("TextButton")
            UnlockBtn.Parent = Popup
            UnlockBtn.BackgroundColor3 = Library.Theme.Accent
            UnlockBtn.BorderSizePixel = 0
            UnlockBtn.Position = UDim2.new(1, -158, 1, -48)
            UnlockBtn.Size = UDim2.new(0, 140, 0, 34)
            UnlockBtn.Font = Enum.Font.GothamBold
            UnlockBtn.Text = "Unlock"
            UnlockBtn.TextColor3 = Library.Theme.Text
            UnlockBtn.TextSize = 13

            local UnlockCorner = Instance.new("UICorner")
            UnlockCorner.CornerRadius = UDim.new(0, 6)
            UnlockCorner.Parent = UnlockBtn

            local function ClosePopup()
                Popup:Destroy()
                Library:TweenInstance(DropdownZone, 0.25, "BackgroundTransparency", 1, function()
                    DropdownZone.Visible = false
                end)
            end

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
                    Library:TweenInstance(Popup, 0.08, "Position", UDim2.new(0.5, 6, 0.5, 0))
                    task.wait(0.08)
                    Library:TweenInstance(Popup, 0.08, "Position", UDim2.new(0.5, -6, 0.5, 0))
                    task.wait(0.08)
                    Library:TweenInstance(Popup, 0.08, "Position", UDim2.new(0.5, 0, 0.5, 0))
                end
            end)
        end

        Click_Tab_2.Activated:Connect(function()
            if Locked and not Unlocked then
                ShowLockPopup()
                return
            end
            SelectThisTab()
        end)

        AllLayouts = AllLayouts + 1
        local TabFunc = {}

        function TabFunc:AddTabSection(cfg)
            if type(cfg) == "string" then
                cfg = { Title = cfg, Opened = true }
            end
            cfg = Library:MakeConfig({
                Title = "Section",
                Opened = true
            }, cfg or {})

            local Opened = cfg.Opened ~= false

            local Card = Instance.new("Frame")
            Card.Name = "TabSection"
            Card.Parent = Layout
            Card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Card.BackgroundTransparency = 0.96
            Card.BorderSizePixel = 0
            Card.Size = UDim2.new(1, 0, 0, 36)

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 7)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Library.Theme.Stroke
            CardStroke.Transparency = 0.88
            CardStroke.Thickness = 1
            CardStroke.Parent = Card

            local Header = Instance.new("TextButton")
            Header.Name = "Header"
            Header.Parent = Card
            Header.BackgroundTransparency = 1
            Header.Size = UDim2.new(1, 0, 0, 34)
            Header.Text = ""
            Header.AutoButtonColor = false

            local ArrowIcon = Instance.new("ImageLabel")
            ArrowIcon.Parent = Header
            ArrowIcon.BackgroundTransparency = 1
            ArrowIcon.Position = UDim2.new(0, 10, 0.5, -7)
            ArrowIcon.Size = UDim2.new(0, 14, 0, 14)
            ArrowIcon.ZIndex = 2
            Library:SetIcon(ArrowIcon, Opened and Library.DefaultIcons.ChevronDown or Library.DefaultIcons.ChevronRight, Library.Theme.Accent)

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Parent = Header
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Position = UDim2.new(0, 30, 0, 0)
            TitleLbl.Size = UDim2.new(1, -40, 1, 0)
            TitleLbl.Font = Enum.Font.GothamBold
            TitleLbl.Text = cfg.Title
            TitleLbl.TextColor3 = Library.Theme.Text
            TitleLbl.TextSize = 13
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

            local Body = Instance.new("Frame")
            Body.Name = "Body"
            Body.Parent = Card
            Body.BackgroundTransparency = 1
            Body.Position = UDim2.new(0, 0, 0, 34)
            Body.Size = UDim2.new(1, 0, 0, 0)
            Body.Visible = Opened
            Body.ClipsDescendants = true

            local BodyList = Instance.new("UIListLayout")
            BodyList.Parent = Body
            BodyList.SortOrder = Enum.SortOrder.LayoutOrder
            BodyList.Padding = UDim.new(0, 6)

            local BodyPad = Instance.new("UIPadding")
            BodyPad.Parent = Body
            BodyPad.PaddingLeft = UDim.new(0, 8)
            BodyPad.PaddingRight = UDim.new(0, 8)
            BodyPad.PaddingBottom = UDim.new(0, 8)
            BodyPad.PaddingTop = UDim.new(0, 2)

            local function RefreshSize()
                if Opened then
                    local h = math.max(0, BodyList.AbsoluteContentSize.Y) + 10
                    Body.Size = UDim2.new(1, 0, 0, h)
                    Card.Size = UDim2.new(1, 0, 0, 34 + h)
                    Body.Visible = true
                else
                    Body.Size = UDim2.new(1, 0, 0, 0)
                    Card.Size = UDim2.new(1, 0, 0, 34)
                    Body.Visible = false
                end
            end

            BodyList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshSize)

            Header.MouseButton1Click:Connect(function()
                Opened = not Opened
                Library:SetIcon(ArrowIcon, Opened and Library.DefaultIcons.ChevronDown or Library.DefaultIcons.ChevronRight, Library.Theme.Accent)
                RefreshSize()
            end)

            local Inner = TabFunc:AddSection(cfg.Title)
            if Inner and Inner._GetSectionFrame then
                local sf = Inner._GetSectionFrame()
                if sf then
                    sf.Parent = Body
                    sf.BackgroundTransparency = 1
                end
            else
                for _, child in ipairs(Layout:GetChildren()) do
                    if child.Name == "Section" and child:FindFirstChild("NameSection") then
                        local t = child.NameSection:FindFirstChild("Title")
                        if t and t.Text == cfg.Title then
                            child.Parent = Body
                            child.BackgroundTransparency = 1
                            if child:FindFirstChild("NameSection") then
                                child.NameSection.Visible = false
                            end
                            break
                        end
                    end
                end
            end

            task.defer(RefreshSize)
            task.delay(0.1, RefreshSize)

            return Inner
        end

        function TabFunc:AddSection(RealNameSection)
            local Section = Instance.new("Frame")
            local UICorner_5 = Instance.new("UICorner")
            local UIStroke_2 = Instance.new("UIStroke")
            local NameSection = Instance.new("Frame")
            local Title = Instance.new("TextLabel")
            local Line_3 = Instance.new("Frame")
            local UIGradient = Instance.new("UIGradient")
            local SectionList = Instance.new("Frame")
            local UIPadding_4 = Instance.new("UIPadding")
            local UIListLayout_4 = Instance.new("UIListLayout")

            Section.Name = "Section"
            Section.Parent = Layout
            Section:SetAttribute("SectionTitle", tostring(RealNameSection or ""))
            Section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Section.BackgroundTransparency = 0.980
            Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Section.BorderSizePixel = 0
            Section.Position = UDim2.new(1.36775815, 0, 0.545454562, 0)
            Section.Size = UDim2.new(1, 0, 0, 55)

            UICorner_5.CornerRadius = UDim.new(0, 4)
            UICorner_5.Parent = Section

            UIStroke_2.Color = Library.Theme.Stroke
            UIStroke_2.Thickness = 2
            UIStroke_2.Transparency = 0.9200000166893005
            UIStroke_2.Parent = Section

            NameSection.Name = "NameSection"
            NameSection.Parent = Section
            NameSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            NameSection.BackgroundTransparency = 1.000
            NameSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
            NameSection.BorderSizePixel = 0
            NameSection.Size = UDim2.new(1, 0, 0, 30)

            Title.Name = "Title"
            Title.Parent = NameSection
            Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Title.BackgroundTransparency = 1.000
            Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Title.BorderSizePixel = 0
            Title.Position = UDim2.new(0, 10, 0, 0)
            Title.Size = UDim2.new(1, -10, 1, 0)
            Title.Font = Enum.Font.GothamBold
            Title.Text = RealNameSection
            Title.TextColor3 = Library.Theme.Text
            Title.TextSize = 13.000
            Title.TextXAlignment = Enum.TextXAlignment.Left

            Line_3.Name = "Line"
            Line_3.Parent = NameSection
            Line_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Line_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Line_3.BorderSizePixel = 0
            Line_3.Position = UDim2.new(0, 0, 1, -2)
            Line_3.Size = UDim2.new(1, 0, 0, 2)

            UIGradient.Color = ColorSequence.new { ColorSequenceKeypoint.new(0.00, Color3.fromRGB(24, 24, 25)), ColorSequenceKeypoint.new(0.52, Library.Theme.Accent), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(24, 24, 25)) }
            UIGradient.Transparency = NumberSequence.new { NumberSequenceKeypoint.new(0.00, 0.53), NumberSequenceKeypoint.new(0.51, 0.00), NumberSequenceKeypoint.new(1.00, 0.51) }
            UIGradient.Parent = Line_3

            SectionList.Name = "SectionList"
            SectionList.Parent = Section
            SectionList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SectionList.BackgroundTransparency = 1.000
            SectionList.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SectionList.BorderSizePixel = 0
            SectionList.Position = UDim2.new(0, 0, 0, 35)
            SectionList.Size = UDim2.new(1, 0, 1, -35)

            UIPadding_4.Parent = SectionList
            UIPadding_4.PaddingBottom = UDim.new(0, 10)
            UIPadding_4.PaddingLeft = UDim.new(0, 8)
            UIPadding_4.PaddingRight = UDim.new(0, 8)
            UIPadding_4.PaddingTop = UDim.new(0, 6)

            UIListLayout_4.Parent = SectionList
            UIListLayout_4.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_4.Padding = UDim.new(0, 8)
            UIListLayout_4:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Section.Size = UDim2.new(1, 0, 0, UIListLayout_4.AbsoluteContentSize.Y + 55)
            end)

            local SectionFunc = {}

            function SectionFunc:AddToggle(cftoggle)
                local cftoggle = Library:MakeConfig({
                    Title = "Toggle < Missing Title >",
                    Description = "",
                    Default = false,
                    Callback = function()
                    end
                }, cftoggle or {})

                local Toggle = Instance.new("Frame")
                local UICorner_6 = Instance.new("UICorner")
                local Title_2 = Instance.new("TextLabel")
                local ToggleCheck = Instance.new("Frame")
                local UICorner_7 = Instance.new("UICorner")
                local Check = Instance.new("Frame")
                local UICorner_8 = Instance.new("UICorner")
                local Toggle_Click = Instance.new("TextButton")
                local Content = Instance.new("TextLabel")

                Toggle.Name = "Toggle"
                Toggle.Parent = SectionList
                Toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Toggle.BackgroundTransparency = 0.950
                Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Toggle.BorderSizePixel = 0
                Toggle.Size = UDim2.new(1, 0, 0, 35)

                UICorner_6.CornerRadius = UDim.new(0, 3)
                UICorner_6.Parent = Toggle

                Title_2.Name = "Title"
                Title_2.Parent = Toggle
                Title_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Title_2.BackgroundTransparency = 1.000
                Title_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Title_2.BorderSizePixel = 0
                Title_2.Position = UDim2.new(0, 10, 0, 0)
                Title_2.Size = UDim2.new(1, -60, 1, 0)
                Title_2.Font = Enum.Font.GothamBold
                Title_2.Text = cftoggle.Title
                Title_2.TextColor3 = Library.Theme.Text
                Title_2.TextSize = 13.000
                Title_2.TextXAlignment = Enum.TextXAlignment.Left

                ToggleCheck.Name = "ToggleCheck"
                ToggleCheck.Parent = Toggle
                ToggleCheck.AnchorPoint = Vector2.new(0, 0.5)
                ToggleCheck.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                ToggleCheck.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ToggleCheck.BorderSizePixel = 0
                ToggleCheck.Position = UDim2.new(1, -50, 0.5, 0)
                ToggleCheck.Size = UDim2.new(0, 40, 0, 22)

                UICorner_7.CornerRadius = UDim.new(1, 0)
                UICorner_7.Parent = ToggleCheck

                Check.Name = "Check"
                Check.Parent = ToggleCheck
                Check.AnchorPoint = Vector2.new(0, 0.5)
                Check.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                Check.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Check.BorderSizePixel = 0
                Check.Position = UDim2.new(0, 3, 0.5, 0)
                Check.Size = UDim2.new(0, 16, 0, 16)

                UICorner_8.CornerRadius = UDim.new(1, 0)
                UICorner_8.Parent = Check

                Toggle_Click.Name = "Toggle_Click"
                Toggle_Click.Parent = Toggle
                Toggle_Click.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Toggle_Click.BackgroundTransparency = 1.000
                Toggle_Click.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Toggle_Click.BorderSizePixel = 0
                Toggle_Click.Size = UDim2.new(1, 0, 1, 0)
                Toggle_Click.Font = Enum.Font.SourceSans
                Toggle_Click.Text = ""
                Toggle_Click.TextColor3 = Color3.fromRGB(0, 0, 0)
                Toggle_Click.TextSize = 14.000

                Content.Name = "Content"
                Content.Parent = Toggle
                Content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Content.BackgroundTransparency = 1.000
                Content.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Content.BorderSizePixel = 0
                Content.Position = UDim2.new(0, 10, 0, 22)
                Content.Size = UDim2.new(1, -60, 1, 0)
                Content.Font = Enum.Font.GothamBold
                Content.Text = cftoggle.Description
                Content.TextColor3 = Library.Theme.TextDisabled
                Content.TextSize = 12.000
                Content.TextXAlignment = Enum.TextXAlignment.Left
                Content.TextYAlignment = Enum.TextYAlignment.Top
                Library:UpdateContent(Content, Title_2, Toggle)

                local ToggleFunc = { Value = cftoggle.Default }
                function ToggleFunc:Set(Boolean)
                    if Boolean then
                        Library:TweenInstance(ToggleCheck, 0.3, "BackgroundColor3", Library.Theme.Accent)
                        Library:TweenInstance(Check, 0.3, "Position", UDim2.new(0, 22, 0.5, 0))
                        Library:TweenInstance(Check, 0.3, "BackgroundColor3", Library.Theme.Text)
                    else
                        Library:TweenInstance(ToggleCheck, 0.3, "BackgroundColor3", Color3.fromRGB(60, 60, 60))
                        Library:TweenInstance(Check, 0.3, "BackgroundColor3", Color3.fromRGB(200, 200, 200))
                        Library:TweenInstance(Check, 0.3, "Position", UDim2.new(0, 3, 0.5, 0))
                    end
                    self.Value = Boolean
                    cftoggle.Callback(Boolean)
                end

                ToggleFunc:Set(ToggleFunc.Value)
                
                Toggle_Click.Activated:Connect(function()
                    ToggleFunc:Set(not ToggleFunc.Value)
                end)
            end

            function SectionFunc:AddButton(cfbutton)
                local cfbutton = Library:MakeConfig({
                    Title = "Button < Missing Title >",
                    Description = "",
                    Callback = function()
                    end
                }, cfbutton or {})

                local Button = Instance.new("Frame")
                local UICorner_9 = Instance.new("UICorner")
                local Title_3 = Instance.new("TextLabel")
                local Button_Click = Instance.new("TextButton")
                local Content_2 = Instance.new("TextLabel")
                local ImageLabel = Instance.new("ImageLabel")

                Button.Name = "Button"
                Button.Parent = SectionList
                Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Button.BackgroundTransparency = 0.950
                Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Button.BorderSizePixel = 0
                Button.Size = UDim2.new(1, 0, 0, 35)

                UICorner_9.CornerRadius = UDim.new(0, 3)
                UICorner_9.Parent = Button

                Title_3.Name = "Title"
                Title_3.Parent = Button
                Title_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Title_3.BackgroundTransparency = 1.000
                Title_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Title_3.BorderSizePixel = 0
                Title_3.Position = UDim2.new(0, 10, 0, 0)
                Title_3.Size = UDim2.new(1, -60, 1, 0)
                Title_3.Font = Enum.Font.GothamBold
                Title_3.Text = cfbutton.Title
                Title_3.TextColor3 = Library.Theme.Text
                Title_3.TextSize = 13.000
                Title_3.TextXAlignment = Enum.TextXAlignment.Left

                Button_Click.Name = "Button_Click"
                Button_Click.Parent = Button
                Button_Click.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Button_Click.BackgroundTransparency = 1.000
                Button_Click.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Button_Click.BorderSizePixel = 0
                Button_Click.Size = UDim2.new(1, 0, 1, 0)
                Button_Click.Font = Enum.Font.SourceSans
                Button_Click.Text = ""
                Button_Click.TextColor3 = Color3.fromRGB(0, 0, 0)
                Button_Click.TextSize = 14.000

                Content_2.Name = "Content"
                Content_2.Parent = Button
                Content_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Content_2.BackgroundTransparency = 1.000
                Content_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Content_2.BorderSizePixel = 0
                Content_2.Position = UDim2.new(0, 10, 0, 22)
                Content_2.Size = UDim2.new(1, -60, 1, 0)
                Content_2.Font = Enum.Font.GothamBold
                Content_2.Text = cfbutton.Description
                Content_2.TextColor3 = Library.Theme.TextDisabled
                Content_2.TextSize = 12.000
                Content_2.TextXAlignment = Enum.TextXAlignment.Left
                Content_2.TextYAlignment = Enum.TextYAlignment.Top

                ImageLabel.Parent = Button
                ImageLabel.AnchorPoint = Vector2.new(0, 0.5)
                ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel.BorderSizePixel = 0
                ImageLabel.Position = UDim2.new(1, -35, 0.5, 0)
                ImageLabel.Size = UDim2.new(0, 24, 0, 24)
                Library:SetIcon(ImageLabel, Library.DefaultIcons.ChevronRight, Library.Theme.Accent)
                Library:UpdateContent(Content_2, Title_3, Button)

                Button_Click.Activated:Connect(function()
                    Button.BackgroundTransparency = 0.970
                    cfbutton.Callback()
                    Library:TweenInstance(Button, 0.2, "BackgroundTransparency", 0.950)
                end)
            end

            function SectionFunc:AddDropdown(cfdropdown)
                local cfdropdown = Library:MakeConfig({
                    Title = "Dropdown",
                    Description = "",
                    Values = {},
                    Default = "",
                    Callback = function()
                    end
                }, cfdropdown or {})

                local Dropdown = Instance.new("Frame")
                local UICorner_19 = Instance.new("UICorner")
                local Title_8 = Instance.new("TextLabel")
                local Content_6 = Instance.new("TextLabel")
                local Selects = Instance.new("Frame")
                local UICorner_20 = Instance.new("UICorner")
                local SelectText = Instance.new("TextLabel")
                local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
                local Drop_Click = Instance.new("TextButton")
                local ImageLabel_2 = Instance.new("ImageLabel")
                local DropdownList = Instance.new("Frame")
                local UIStroke_3 = Instance.new("UIStroke")
                local UICorner_24 = Instance.new("UICorner")
                local Topbar = Instance.new("Frame")
                local Title_10 = Instance.new("TextLabel")
                local SearchFrame_2 = Instance.new("Frame")
                local UICorner_25 = Instance.new("UICorner")
                local UIStroke_4 = Instance.new("UIStroke")
                local IconSearch_2 = Instance.new("ImageLabel")
                local TextBox = Instance.new("TextBox")
                local Click_Dropdown = Instance.new("TextButton")
                local Icon_4 = Instance.new("ImageLabel")
                local Real_List = Instance.new("ScrollingFrame")
                local UICorner_26 = Instance.new("UICorner")
                local UIListLayout_5 = Instance.new("UIListLayout")
                local UIPadding_5 = Instance.new("UIPadding")

                Dropdown.Name = "Dropdown"
                Dropdown.Parent = SectionList
                Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Dropdown.BackgroundTransparency = 0.950
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderSizePixel = 0
                Dropdown.Size = UDim2.new(1, 0, 0, 35)

                UICorner_19.CornerRadius = UDim.new(0, 3)
                UICorner_19.Parent = Dropdown

                Title_8.Name = "Title"
                Title_8.Parent = Dropdown
                Title_8.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Title_8.BackgroundTransparency = 1.000
                Title_8.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Title_8.BorderSizePixel = 0
                Title_8.Position = UDim2.new(0, 10, 0, 0)
                Title_8.Size = UDim2.new(1, -60, 1, 0)
                Title_8.Font = Enum.Font.GothamBold
                Title_8.Text = cfdropdown.Title
                Title_8.TextColor3 = Library.Theme.Text
                Title_8.TextSize = 13.000
                Title_8.TextXAlignment = Enum.TextXAlignment.Left

                Content_6.Name = "Content"
                Content_6.Parent = Dropdown
                Content_6.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Content_6.BackgroundTransparency = 1.000
                Content_6.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Content_6.BorderSizePixel = 0
                Content_6.Position = UDim2.new(0, 10, 0, 22)
                Content_6.Size = UDim2.new(1, -60, 1, 0)
                Content_6.Font = Enum.Font.GothamBold
                Content_6.Text = cfdropdown.Description
                Content_6.TextColor3 = Library.Theme.TextDisabled
                Content_6.TextSize = 12.000
                Content_6.TextXAlignment = Enum.TextXAlignment.Left
                Content_6.TextYAlignment = Enum.TextYAlignment.Top

                Selects.Name = "Selects"
                Selects.Parent = Dropdown
                Selects.AnchorPoint = Vector2.new(0, 0.5)
                Selects.BackgroundColor3 = Library.Theme.Background
                Selects.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Selects.BorderSizePixel = 0
                Selects.Position = UDim2.new(1, -90, 0.5, 0)
                Selects.Size = UDim2.new(0, 80, 0, 25)

                UICorner_20.CornerRadius = UDim.new(0, 5)
                UICorner_20.Parent = Selects

                SelectText.Name = "SelectText"
                SelectText.Parent = Selects
                SelectText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SelectText.BackgroundTransparency = 1.000
                SelectText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SelectText.BorderSizePixel = 0
                SelectText.Position = UDim2.new(0, 3, 0, 0)
                SelectText.Size = UDim2.new(1, -25, 1, 0)
                SelectText.Font = Enum.Font.GothamBold
                SelectText.Text = ""
                SelectText.TextColor3 = Library.Theme.Text
                SelectText.TextScaled = true
                SelectText.TextSize = 1.000
                SelectText.TextWrapped = true

                UITextSizeConstraint.Parent = SelectText
                UITextSizeConstraint.MaxTextSize = 12

                Drop_Click.Name = "Drop_Click"
                Drop_Click.Parent = Selects
                Drop_Click.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Drop_Click.BackgroundTransparency = 1.000
                Drop_Click.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drop_Click.BorderSizePixel = 0
                Drop_Click.Size = UDim2.new(1, 0, 1, 0)
                Drop_Click.Font = Enum.Font.SourceSans
                Drop_Click.Text = ""
                Drop_Click.TextColor3 = Color3.fromRGB(0, 0, 0)
                Drop_Click.TextSize = 14.000

                ImageLabel_2.Parent = Selects
                ImageLabel_2.AnchorPoint = Vector2.new(0, 0.5)
                ImageLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel_2.BackgroundTransparency = 1.000
                ImageLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel_2.BorderSizePixel = 0
                ImageLabel_2.Position = UDim2.new(1, -20, 0.5, 0)
                ImageLabel_2.Size = UDim2.new(0, 15, 0, 15)
                Library:SetIcon(ImageLabel_2, Library.DefaultIcons.ChevronDown, Library.Theme.Accent)
                Library:UpdateContent(Content_6, Title_8, Dropdown)

                DropdownList.Name = "DropdownList"
                DropdownList.Parent = DropdownZone
                DropdownList.AnchorPoint = Vector2.new(0.5, 0.5)
                DropdownList.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                DropdownList.BorderColor3 = Color3.fromRGB(0, 0, 0)
                DropdownList.BorderSizePixel = 0
                DropdownList.Position = UDim2.new(0.5, 0, 0.5, 0)
                DropdownList.Size = UDim2.new(0, 400, 0, 250)
                DropdownList.Visible = false

                UIStroke_3.Color = Library.Theme.Stroke
                UIStroke_3.Transparency = 0.5
                UIStroke_3.Parent = DropdownList

                UICorner_24.CornerRadius = UDim.new(0, 5)
                UICorner_24.Parent = DropdownList

                Topbar.Name = "Topbar"
                Topbar.Parent = DropdownList
                Topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Topbar.BackgroundTransparency = 1.000
                Topbar.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Topbar.BorderSizePixel = 0
                Topbar.Size = UDim2.new(1, 0, 0, 50)

                Title_10.Name = "Title"
                Title_10.Parent = Topbar
                Title_10.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Title_10.BackgroundTransparency = 1.000
                Title_10.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Title_10.BorderSizePixel = 0
                Title_10.Position = UDim2.new(0, 15, 0, 0)
                Title_10.Size = UDim2.new(1, -200, 1, -5)
                Title_10.Font = Enum.Font.GothamBold
                Title_10.Text = cfdropdown.Title
                Title_10.TextColor3 = Library.Theme.Text
                Title_10.TextSize = 14.000
                Title_10.TextWrapped = true
                Title_10.TextXAlignment = Enum.TextXAlignment.Left

                SearchFrame_2.Name = "SearchFrame"
                SearchFrame_2.Parent = Topbar
                SearchFrame_2.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                SearchFrame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SearchFrame_2.BorderSizePixel = 0
                SearchFrame_2.Position = UDim2.new(1, -150, 0, 8)
                SearchFrame_2.Size = UDim2.new(0, 100, 0, 30)

                UICorner_25.CornerRadius = UDim.new(0, 5)
                UICorner_25.Parent = SearchFrame_2

                UIStroke_4.Color = Library.Theme.Stroke
                UIStroke_4.Transparency = 0.7400000095367432
                UIStroke_4.Parent = SearchFrame_2

                IconSearch_2.Name = "IconSearch"
                IconSearch_2.Parent = SearchFrame_2
                IconSearch_2.AnchorPoint = Vector2.new(0, 0.5)
                IconSearch_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                IconSearch_2.BackgroundTransparency = 1.000
                IconSearch_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                IconSearch_2.BorderSizePixel = 0
                IconSearch_2.Position = UDim2.new(0, 10, 0.5, 0)
                IconSearch_2.Size = UDim2.new(0, 15, 0, 15)
                Library:SetIcon(IconSearch_2, Library.DefaultIcons.Search, Library.Theme.Accent)

                TextBox.Parent = SearchFrame_2
                TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextBox.BackgroundTransparency = 1.000
                TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextBox.BorderSizePixel = 0
                TextBox.Position = UDim2.new(0, 35, 0, 0)
                TextBox.Size = UDim2.new(1, -35, 1, 0)
                TextBox.Font = Enum.Font.GothamBold
                TextBox.PlaceholderText = "Search..."
                TextBox.Text = ""
                TextBox.TextColor3 = Library.Theme.Text
                TextBox.TextSize = 12.000
                TextBox.TextXAlignment = Enum.TextXAlignment.Left

                Click_Dropdown.Name = "Click_Dropdown"
                Click_Dropdown.Parent = Topbar
                Click_Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Click_Dropdown.BackgroundTransparency = 1.000
                Click_Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Click_Dropdown.BorderSizePixel = 0
                Click_Dropdown.Position = UDim2.new(1, -40, 0, 8)
                Click_Dropdown.Size = UDim2.new(0, 30, 0, 30)
                Click_Dropdown.Text = ""

                Icon_4.Name = "Icon"
                Icon_4.Parent = Click_Dropdown
                Icon_4.AnchorPoint = Vector2.new(0.5, 0.5)
                Icon_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Icon_4.BackgroundTransparency = 1.000
                Icon_4.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Icon_4.BorderSizePixel = 0
                Icon_4.Position = UDim2.new(0.5, 0, 0.5, 0)
                Icon_4.Size = UDim2.new(0, 20, 0, 20)
                Library:SetIcon(Icon_4, Library.DefaultIcons.Close, Library.Theme.Accent)

                Real_List.Name = "Real_List"
                Real_List.Parent = DropdownList
                Real_List.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
                Real_List.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Real_List.BorderSizePixel = 0
                Real_List.Position = UDim2.new(0, 10, 0, 50)
                Real_List.Selectable = false
                Real_List.ScrollBarThickness = 0
                Real_List.Size = UDim2.new(1, -20, 1, -60)
                Library:UpdateScrolling(Real_List, UIListLayout_5)

                UICorner_26.CornerRadius = UDim.new(0, 5)
                UICorner_26.Parent = Real_List

                UIListLayout_5.Parent = Real_List
                UIListLayout_5.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout_5.Padding = UDim.new(0, 5)

                UIPadding_5.Parent = Real_List
                UIPadding_5.PaddingBottom = UDim.new(0, 7)
                UIPadding_5.PaddingLeft = UDim.new(0, 7)
                UIPadding_5.PaddingRight = UDim.new(0, 7)
                UIPadding_5.PaddingTop = UDim.new(0, 7)

                local UICorner_29 = Instance.new("UICorner")
                UICorner_29.Parent = DropdownZone

                Drop_Click.Activated:Connect(function()
                    DropdownZone.Visible = true
                    DropdownList.Visible = true
                    Library:TweenInstance(DropdownZone, 0.3, "BackgroundTransparency", 0.3)
                end)

                Click_Dropdown.Activated:Connect(function()
                    DropdownList.Visible = false
                    Library:TweenInstance(DropdownZone, 0.3, "BackgroundTransparency", 1)
                    wait(0.3)
                    DropdownZone.Visible = false
                end)

                local DropFunc = { Value = cfdropdown.Default }
                function DropFunc:Set(cc)
                    DropFunc.Value = cc or DropFunc.Value
                    for i, v in next, Real_List:GetChildren() do
                        if v:IsA("Frame") then
                            if table.find(DropFunc.Value, v.Title.Text) then
                                Library:TweenInstance(v, 0.3, "BackgroundTransparency", 0)
                                Library:TweenInstance(v.Title, 0.3, "TextTransparency", 0)
                            else
                                Library:TweenInstance(v, 0.3, "BackgroundTransparency", 0.98)
                                Library:TweenInstance(v.Title, 0.3, "TextTransparency", 0.5)
                            end
                        end
                    end
                    local DropValue = table.concat(DropFunc.Value, ",")
                    if DropValue == "" then
                        SelectText.Text = ""
                    else
                        SelectText.Text = DropValue
                    end
                    cfdropdown.Callback(cfdropdown.Multi and DropFunc.Value or table.concat(DropFunc.Value, ""))
                end

                function DropFunc:Add(v)
                    local Option2 = Instance.new("Frame")
                    local UICorner_28 = Instance.new("UICorner")
                    local Option2_Click = Instance.new("TextButton")
                    local Title_12 = Instance.new("TextLabel")
                    local UIGradient_3 = Instance.new("UIGradient")

                    Option2.Name = "Option 2"
                    Option2.Parent = Real_List
                    Option2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Option2.BackgroundTransparency = 0.980
                    Option2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Option2.BorderSizePixel = 0
                    Option2.Size = UDim2.new(1, 0, 0, 35)

                    UICorner_28.CornerRadius = UDim.new(0, 4)
                    UICorner_28.Parent = Option2

                    Option2_Click.Name = "Option2_Click"
                    Option2_Click.Parent = Option2
                    Option2_Click.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Option2_Click.BackgroundTransparency = 1.000
                    Option2_Click.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Option2_Click.BorderSizePixel = 0
                    Option2_Click.Size = UDim2.new(1, 0, 1, 0)
                    Option2_Click.Font = Enum.Font.SourceSans
                    Option2_Click.Text = ""
                    Option2_Click.TextColor3 = Color3.fromRGB(0, 0, 0)
                    Option2_Click.TextSize = 14.000

                    Title_12.Name = "Title"
                    Title_12.Parent = Option2
                    Title_12.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Title_12.BackgroundTransparency = 1.000
                    Title_12.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Title_12.BorderSizePixel = 0
                    Title_12.Size = UDim2.new(1, 0, 1, 0)
                    Title_12.Font = Enum.Font.GothamBold
                    Title_12.Text = v
                    Title_12.TextColor3 = Library.Theme.Text
                    Title_12.TextSize = 13.000
                    Title_12.TextTransparency = 0.500

                    UIGradient_3.Color = ColorSequence.new { ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(0.51, Library.Theme.Accent), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0)) }
                    UIGradient_3.Rotation = 0.9900000095367432
                    UIGradient_3.Transparency = NumberSequence.new { NumberSequenceKeypoint.new(0.00, 0.50), NumberSequenceKeypoint.new(0.50, 0.49), NumberSequenceKeypoint.new(1.00, 0.44) }
                    UIGradient_3.Parent = Option2

                    Option2_Click.Activated:Connect(function()
                        if cfdropdown.Multi then
                            if Option2.BackgroundTransparency < 0.950 then
                                for i, v in next, DropFunc.Value do
                                    if v == Title_12.Text then
                                        table.remove(DropFunc.Value, i)
                                    end
                                end
                                DropFunc:Set(DropFunc.Value)
                            else
                                table.insert(DropFunc.Value, Title_12.Text)
                                DropFunc:Set(DropFunc.Value)
                            end
                        else
                            DropFunc.Value = { Title_12.Text }
                            DropFunc:Set(DropFunc.Value)
                        end
                    end)
                end

                function DropFunc:Clear()
                    for i, v in next, Real_List:GetChildren() do
                        if v:IsA("Frame") then
                            v:Destroy()
                        end
                    end
                end

                function DropFunc:Refresh(NewList)
                    self:Clear()
                    for i, v in next, NewList do
                        self:Add(v)
                    end
                end

                DropFunc:Refresh(cfdropdown.Values)
                DropFunc:Set(typeof(cfdropdown.Default) == "string" and { cfdropdown.Default } or cfdropdown.Default)
                return DropFunc
            end

            function SectionFunc:AddInput(cftextbox)
                local cftextbox = Library:MakeConfig({
                    Title = "Textbox",
                    Description = "",
                    PlaceHolder = "",
                    Default = "",
                    Callback = function() end
                }, cftextbox or {})

                local Input = Instance.new("Frame")
                local UICorner_17 = Instance.new("UICorner")
                local Title_7 = Instance.new("TextLabel")
                local Content_5 = Instance.new("TextLabel")
                local TextboxFrame = Instance.new("Frame")
                local UICorner_18 = Instance.new("UICorner")
                local RealTextBox = Instance.new("TextBox")
                local WritingIcon = Instance.new("ImageLabel")

                Input.Name = "Input"
                Input.Parent = SectionList
                Input.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Input.BackgroundTransparency = 0.950
                Input.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Input.BorderSizePixel = 0
                Input.Size = UDim2.new(1, 0, 0, 35)

                UICorner_17.CornerRadius = UDim.new(0, 3)
                UICorner_17.Parent = Input

                Title_7.Name = "Title"
                Title_7.Parent = Input
                Title_7.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Title_7.BackgroundTransparency = 1.000
                Title_7.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Title_7.BorderSizePixel = 0
                Title_7.Position = UDim2.new(0, 10, 0, 0)
                Title_7.Size = UDim2.new(1, -140, 1, 0)
                Title_7.Font = Enum.Font.GothamBold
                Title_7.Text = cftextbox.Title
                Title_7.TextColor3 = Library.Theme.Text
                Title_7.TextSize = 13.000
                Title_7.TextXAlignment = Enum.TextXAlignment.Left
                Title_7.TextTruncate = Enum.TextTruncate.AtEnd

                Content_5.Name = "Content"
                Content_5.Parent = Input
                Content_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Content_5.BackgroundTransparency = 1.000
                Content_5.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Content_5.BorderSizePixel = 0
                Content_5.Position = UDim2.new(0, 10, 0, 22)
                Content_5.Size = UDim2.new(1, -160, 1, 0)
                Content_5.Font = Enum.Font.GothamBold
                Content_5.Text = cftextbox.Description
                Content_5.TextColor3 = Library.Theme.TextDisabled
                Content_5.TextSize = 12.000
                Content_5.TextXAlignment = Enum.TextXAlignment.Left
                Content_5.TextYAlignment = Enum.TextYAlignment.Top
                Library:UpdateContent(Content_5, Title_7, Input)

                TextboxFrame.Name = "TextboxFrame"
                TextboxFrame.Parent = Input
                TextboxFrame.AnchorPoint = Vector2.new(1, 0.5)
                TextboxFrame.BackgroundColor3 = Library.Theme.Background
                TextboxFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextboxFrame.BorderSizePixel = 0
                TextboxFrame.Position = UDim2.new(1, -8, 0.5, 0)
                TextboxFrame.Size = UDim2.new(0, 120, 0, 26)

                UICorner_18.CornerRadius = UDim.new(0, 3)
                UICorner_18.Parent = TextboxFrame

                RealTextBox.Name = "RealTextBox"
                RealTextBox.Parent = TextboxFrame
                RealTextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                RealTextBox.BackgroundTransparency = 1.000
                RealTextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                RealTextBox.BorderSizePixel = 0
                RealTextBox.Position = UDim2.new(0, 35, 0, 0)
                RealTextBox.Size = UDim2.new(1, -35, 1, 0)
                RealTextBox.Font = Enum.Font.GothamBold
                RealTextBox.PlaceholderText = cftextbox.PlaceHolder
                RealTextBox.Text = cftextbox.Default
                RealTextBox.TextColor3 = Library.Theme.Text
                RealTextBox.TextSize = 12.000
                RealTextBox.TextXAlignment = Enum.TextXAlignment.Left

                WritingIcon.Name = "WritingIcon"
                WritingIcon.Parent = TextboxFrame
                WritingIcon.AnchorPoint = Vector2.new(0, 0.5)
                WritingIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                WritingIcon.BackgroundTransparency = 1.000
                WritingIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
                WritingIcon.BorderSizePixel = 0
                WritingIcon.Position = UDim2.new(0, 10, 0.5, 0)
                WritingIcon.Size = UDim2.new(0, 15, 0, 15)
                Library:SetIcon(WritingIcon, Library.DefaultIcons.Edit, Library.Theme.Accent)

                RealTextBox.FocusLost:Connect(function()
                    cftextbox.Callback(RealTextBox.Text)
                end)

                cftextbox.Callback(RealTextBox.Text)
            end

            function SectionFunc:AddSlider(cfslider)
                local cfslider = Library:MakeConfig({
                    Title = "Slider < Missing Title >",
                    Description = "",
                    Max = 100,
                    Min = 1,
                    Increment = 1,
                    Default = 1,
                    Callback = function()
                    end
                }, cfslider or {})

                local Slider = Instance.new("Frame")
                local UICorner_10 = Instance.new("UICorner")
                local Title_4 = Instance.new("TextLabel")
                local Content_3 = Instance.new("TextLabel")
                local SliderFrame = Instance.new("Frame")
                local UICorner_11 = Instance.new("UICorner")
                local SliderDraggable = Instance.new("Frame")
                local UICorner_12 = Instance.new("UICorner")
                local Circle = Instance.new("Frame")
                local UICorner_13 = Instance.new("UICorner")
                local SliderValue = Instance.new("TextBox")
                local UICorner_14 = Instance.new("UICorner")

                Slider.Name = "Slider"
                Slider.Parent = SectionList
                Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Slider.BackgroundTransparency = 0.950
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderSizePixel = 0
                Slider.Size = UDim2.new(1, 0, 0, 35)

                UICorner_10.CornerRadius = UDim.new(0, 3)
                UICorner_10.Parent = Slider

                Title_4.Name = "Title"
                Title_4.Parent = Slider
                Title_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Title_4.BackgroundTransparency = 1.000
                Title_4.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Title_4.BorderSizePixel = 0
                Title_4.Position = UDim2.new(0, 10, 0, 0)
                Title_4.Size = UDim2.new(1, -60, 1, 0)
                Title_4.Font = Enum.Font.GothamBold
                Title_4.Text = cfslider.Title
                Title_4.TextColor3 = Library.Theme.Text
                Title_4.TextSize = 13.000
                Title_4.TextXAlignment = Enum.TextXAlignment.Left

                Content_3.Name = "Content"
                Content_3.Parent = Slider
                Content_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Content_3.BackgroundTransparency = 1.000
                Content_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Content_3.BorderSizePixel = 0
                Content_3.Position = UDim2.new(0, 10, 0, 22)
                Content_3.Size = UDim2.new(1, -160, 1, 0)
                Content_3.Font = Enum.Font.GothamBold
                Content_3.Text = cfslider.Description
                Content_3.TextColor3 = Library.Theme.TextDisabled
                Content_3.TextSize = 12.000
                Content_3.TextXAlignment = Enum.TextXAlignment.Left
                Content_3.TextYAlignment = Enum.TextYAlignment.Top
                Library:UpdateContent(Content_3, Title_4, Slider)

                SliderFrame.Name = "SliderFrame"
                SliderFrame.Parent = Slider
                SliderFrame.AnchorPoint = Vector2.new(0, 0.5)
                SliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                SliderFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Position = UDim2.new(1, -140, 0.5, 0)
                SliderFrame.Size = UDim2.new(0, 100, 0, 6)

                UICorner_11.CornerRadius = UDim.new(1, 0)
                UICorner_11.Parent = SliderFrame

                SliderDraggable.Name = "SliderDraggable"
                SliderDraggable.Parent = SliderFrame
                SliderDraggable.BackgroundColor3 = Library.Theme.Accent
                SliderDraggable.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderDraggable.BorderSizePixel = 0
                SliderDraggable.Size = UDim2.new(0, 20, 1, 0)

                UICorner_12.CornerRadius = UDim.new(1, 0)
                UICorner_12.Parent = SliderDraggable

                Circle.Name = "Circle"
                Circle.Parent = SliderDraggable
                Circle.AnchorPoint = Vector2.new(0.5, 0.5)
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.BorderSizePixel = 0
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.Size = UDim2.new(0, 14, 0, 14)
                Circle.ZIndex = 2

                UICorner_13.CornerRadius = UDim.new(1, 0)
                UICorner_13.Parent = Circle

                local CircleStroke = Instance.new("UIStroke")
                CircleStroke.Parent = Circle
                CircleStroke.Color = Library.Theme.Accent
                CircleStroke.Thickness = 2
                CircleStroke.Transparency = 0.2

                SliderValue.Name = "SliderValue"
                SliderValue.Parent = Slider
                SliderValue.AnchorPoint = Vector2.new(0, 0.5)
                SliderValue.BackgroundColor3 = Library.Theme.Accent
                SliderValue.BackgroundTransparency = 0.15
                SliderValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderValue.BorderSizePixel = 0
                SliderValue.Position = UDim2.new(1, -178, 0.5, 0)
                SliderValue.Size = UDim2.new(0, 30, 0, 20)
                SliderValue.Font = Enum.Font.GothamBold
                SliderValue.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
                SliderValue.PlaceholderText = "..."
                SliderValue.Text = ""
                SliderValue.TextColor3 = Library.Theme.Text
                SliderValue.TextSize = 11.000

                UICorner_14.CornerRadius = UDim.new(0, 2)
                UICorner_14.Parent = SliderValue

                local SliderFunc = {Value = cfslider.Default}
                local Dragging = false

                local function Round(Number, Factor)
                    local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
                    if Result < 0 then
                        Result = Result + Factor
                    end
                    return Result
                end

                function SliderFunc:Set(Value)
                    Value = math.clamp(Round(Value, cfslider.Increment), cfslider.Min, cfslider.Max)
                    SliderFunc.Value = Value
                    SliderValue.Text = tostring(Value)
                    TweenService:Create(
                        SliderDraggable,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Size = UDim2.fromScale((Value - cfslider.Min) / (cfslider.Max - cfslider.Min), 1) }
                    ):Play()
                end

                local function updateSliderFromInput(inputPosition)
                    local SizeScale = math.clamp(
                        (inputPosition.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
                    SliderFunc:Set(cfslider.Min + ((cfslider.Max - cfslider.Min) * SizeScale))
                end

                SliderFrame.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
                        updateSliderFromInput(Input.Position)
                    end
                end)

                SliderFrame.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = false
                        cfslider.Callback(SliderFunc.Value)
                    end
                end)

                UserInputService.InputChanged:Connect(function(Input)
                    if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSliderFromInput(Input.Position)
                    end
                end)

                UserInputService.TouchMoved:Connect(function(Input, processed)
                    if Dragging then
                        updateSliderFromInput(Input.Position)
                    end
                end)

                SliderValue:GetPropertyChangedSignal("Text"):Connect(function()
                    local Valid = SliderValue.Text:gsub("[^%d]", "")
                    if Valid ~= "" then
                        local ValidNumber = math.min(tonumber(Valid), cfslider.Max)
                        SliderValue.Text = tostring(ValidNumber)
                    else
                        SliderValue.Text = tostring(Valid)
                    end
                end)

                SliderValue.FocusLost:Connect(function()
                    if SliderValue.Text ~= "" then
                        SliderFunc:Set(tonumber(SliderValue.Text))
                    else
                        SliderFunc:Set(0)
                    end
                end)

                SliderFunc:Set(tonumber(cfslider.Default))
                return SliderFunc
            end

            function SectionFunc:AddSeperator(args)
                local Seperator = Instance.new("Frame")
                local Title_5 = Instance.new("TextLabel")

                Seperator.Name = "Seperator"
                Seperator.Parent = SectionList
                Seperator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Seperator.BackgroundTransparency = 1.000
                Seperator.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Seperator.BorderSizePixel = 0
                Seperator.Size = UDim2.new(1, 0, 0, 20)

                Title_5.Name = "Title"
                Title_5.Parent = Seperator
                Title_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Title_5.BackgroundTransparency = 1.000
                Title_5.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Title_5.BorderSizePixel = 0
                Title_5.Position = UDim2.new(0, 10, 0, 0)
                Title_5.Size = UDim2.new(1, -10, 1, 0)
                Title_5.Font = Enum.Font.GothamBold
                Title_5.Text = args
                Title_5.TextColor3 = Library.Theme.Text
                Title_5.TextSize = 13.000
                Title_5.TextXAlignment = Enum.TextXAlignment.Left
            end

            function SectionFunc:AddParagraph(cfpara)
                local cfpara = Library:MakeConfig({
                    Title = "Paragraph < Missing Title >",
                    Content = ""
                }, cfpara or {})

                local Paragraph = Instance.new("Frame")
                local UICorner_16 = Instance.new("UICorner")
                local Title_6 = Instance.new("TextLabel")
                local Content_4 = Instance.new("TextLabel")
                local ParaFunc = {}

                Paragraph.Name = "Paragraph"
                Paragraph.Parent = SectionList
                Paragraph.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Paragraph.BackgroundTransparency = 0.950
                Paragraph.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Paragraph.BorderSizePixel = 0
                Paragraph.Size = UDim2.new(1, 0, 0, 45)

                UICorner_16.CornerRadius = UDim.new(0, 3)
                UICorner_16.Parent = Paragraph

                Title_6.Name = "Title"
                Title_6.Parent = Paragraph
                Title_6.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Title_6.BackgroundTransparency = 1.000
                Title_6.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Title_6.BorderSizePixel = 0
                Title_6.Position = UDim2.new(0, 10, 0, 7)
                Title_6.Size = UDim2.new(1, -60, 0, 16)
                Title_6.Font = Enum.Font.GothamBold
                Title_6.Text = cfpara.Title
                Title_6.TextColor3 = Library.Theme.Text
                Title_6.TextSize = 13.000
                Title_6.TextXAlignment = Enum.TextXAlignment.Left

                Content_4.Name = "Content"
                Content_4.Parent = Paragraph
                Content_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Content_4.BackgroundTransparency = 1.000
                Content_4.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Content_4.BorderSizePixel = 0
                Content_4.Position = UDim2.new(0, 10, 0, 22)
                Content_4.Size = UDim2.new(1, -10, 1, 0)
                Content_4.Font = Enum.Font.GothamBold
                Content_4.Text = cfpara.Content
                Content_4.TextColor3 = Library.Theme.TextDisabled
                Content_4.TextSize = 12.000
                Content_4.TextXAlignment = Enum.TextXAlignment.Left
                Content_4.TextYAlignment = Enum.TextYAlignment.Top
                Library:UpdateContent(Content_4, Title_6, Paragraph)

                function ParaFunc:SetTitle(args)
                    Title_6.Text = args
                end

                function ParaFunc:SetDesc(args)
                    Content_4.Text = args
                end

                return ParaFunc
            end

            function SectionFunc:AddDivider()
                local Divider = Instance.new("Frame")
                Divider.Name = "Divider"
                Divider.Parent = SectionList
                Divider.BackgroundColor3 = Library.Theme.Accent
                Divider.BackgroundTransparency = 0.75
                Divider.BorderSizePixel = 0
                Divider.Size = UDim2.new(1, 0, 0, 1)
            end

            function SectionFunc:AddTag(cftag)
                local cftag = Library:MakeConfig({
                    Title = "Tag",
                    Color = Library.Theme.Accent
                }, cftag or {})

                local Tag = Instance.new("Frame")
                local UICorner_T = Instance.new("UICorner")
                local Title_T = Instance.new("TextLabel")

                Tag.Name = "Tag"
                Tag.Parent = SectionList
                Tag.BackgroundColor3 = cftag.Color
                Tag.BackgroundTransparency = 0.1
                Tag.BorderSizePixel = 0
                Tag.Size = UDim2.new(0, 0, 0, 18)
                Tag.AutomaticSize = Enum.AutomaticSize.X

                UICorner_T.CornerRadius = UDim.new(0, 4)
                UICorner_T.Parent = Tag

                Title_T.Name = "Title"
                Title_T.Parent = Tag
                Title_T.BackgroundTransparency = 1
                Title_T.Size = UDim2.new(0, 0, 1, 0)
                Title_T.AutomaticSize = Enum.AutomaticSize.X
                Title_T.Font = Enum.Font.GothamBold
                Title_T.Text = cftag.Title
                Title_T.TextColor3 = Color3.fromRGB(255, 255, 255)
                Title_T.TextSize = 10

                local Pad = Instance.new("UIPadding")
                Pad.Parent = Tag
                Pad.PaddingLeft = UDim.new(0, 8)
                Pad.PaddingRight = UDim.new(0, 8)
            end

            function SectionFunc:AddColorpicker(cfcolor)
                local cfcolor = Library:MakeConfig({
                    Title = "Colorpicker",
                    Description = "",
                    Default = Color3.fromRGB(255, 255, 255),
                    Callback = function() end
                }, cfcolor or {})

                local Colorpicker = Instance.new("Frame")
                local UICorner_C = Instance.new("UICorner")
                local Title_C = Instance.new("TextLabel")
                local Content_C = Instance.new("TextLabel")
                local ColorBox = Instance.new("Frame")
                local UICorner_CB = Instance.new("UICorner")
                local ColorBtn = Instance.new("TextButton")

                Colorpicker.Name = "Colorpicker"
                Colorpicker.Parent = SectionList
                Colorpicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Colorpicker.BackgroundTransparency = 0.950
                Colorpicker.BorderSizePixel = 0
                Colorpicker.Size = UDim2.new(1, 0, 0, 35)

                UICorner_C.CornerRadius = UDim.new(0, 3)
                UICorner_C.Parent = Colorpicker

                Title_C.Name = "Title"
                Title_C.Parent = Colorpicker
                Title_C.BackgroundTransparency = 1
                Title_C.Position = UDim2.new(0, 10, 0, 0)
                Title_C.Size = UDim2.new(1, -60, 1, 0)
                Title_C.Font = Enum.Font.GothamBold
                Title_C.Text = cfcolor.Title
                Title_C.TextColor3 = Library.Theme.Text
                Title_C.TextSize = 13
                Title_C.TextXAlignment = Enum.TextXAlignment.Left

                Content_C.Name = "Content"
                Content_C.Parent = Colorpicker
                Content_C.BackgroundTransparency = 1
                Content_C.Position = UDim2.new(0, 10, 0, 22)
                Content_C.Size = UDim2.new(1, -60, 1, 0)
                Content_C.Font = Enum.Font.GothamBold
                Content_C.Text = cfcolor.Description
                Content_C.TextColor3 = Library.Theme.TextDisabled
                Content_C.TextSize = 12
                Content_C.TextXAlignment = Enum.TextXAlignment.Left
                Content_C.TextYAlignment = Enum.TextYAlignment.Top
                Library:UpdateContent(Content_C, Title_C, Colorpicker)

                ColorBox.Name = "ColorBox"
                ColorBox.Parent = Colorpicker
                ColorBox.AnchorPoint = Vector2.new(0, 0.5)
                ColorBox.BackgroundColor3 = cfcolor.Default or Color3.fromRGB(255, 255, 255)
                ColorBox.BackgroundTransparency = 0
                ColorBox.BorderSizePixel = 0
                ColorBox.Position = UDim2.new(1, -42, 0.5, 0)
                ColorBox.Size = UDim2.new(0, 28, 0, 28)
                ColorBox.ZIndex = 3

                UICorner_CB.CornerRadius = UDim.new(0, 6)
                UICorner_CB.Parent = ColorBox

                local ColorStroke = Instance.new("UIStroke")
                ColorStroke.Parent = ColorBox
                ColorStroke.Color = Color3.fromRGB(255, 255, 255)
                ColorStroke.Transparency = 0.55
                ColorStroke.Thickness = 1.2

                ColorBtn.Parent = ColorBox
                ColorBtn.BackgroundTransparency = 1
                ColorBtn.Size = UDim2.new(1, 0, 1, 0)
                ColorBtn.Text = ""
                ColorBtn.ZIndex = 4

                local ColorFunc = { Value = cfcolor.Default or Color3.fromRGB(255, 255, 255) }

                function ColorFunc:Set(c)
                    if typeof(c) ~= "Color3" then return end
                    ColorFunc.Value = c
                    ColorBox.BackgroundColor3 = c
                    ColorBox.BackgroundTransparency = 0
                    cfcolor.Callback(c)
                end

                task.defer(function()
                    ColorFunc:Set(ColorFunc.Value)
                end)

                ColorBtn.MouseButton1Click:Connect(function()
                    DropdownZone.Visible = true
                    Library:TweenInstance(DropdownZone, 0.25, "BackgroundTransparency", 0.45)

                    -- Full HSV color picker popup
                    local Popup = Instance.new("Frame")
                    Popup.Parent = DropdownZone
                    Popup.AnchorPoint = Vector2.new(0.5, 0.5)
                    Popup.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
                    Popup.BorderSizePixel = 0
                    Popup.Position = UDim2.new(0.5, 0, 0.5, 0)
                    Popup.Size = UDim2.new(0, 320, 0, 310)
                    Popup.ZIndex = 20

                    local PC = Instance.new("UICorner")
                    PC.CornerRadius = UDim.new(0, 12)
                    PC.Parent = Popup

                    local PS = Instance.new("UIStroke")
                    PS.Color = Library.Theme.Stroke
                    PS.Transparency = 0.45
                    PS.Parent = Popup

                    -- Title bar
                    local TitleBar = Instance.new("TextLabel")
                    TitleBar.Parent = Popup
                    TitleBar.BackgroundTransparency = 1
                    TitleBar.Position = UDim2.new(0, 16, 0, 14)
                    TitleBar.Size = UDim2.new(1, -32, 0, 20)
                    TitleBar.Font = Enum.Font.GothamBold
                    TitleBar.Text = cfcolor.Title
                    TitleBar.TextColor3 = Library.Theme.Text
                    TitleBar.TextSize = 14
                    TitleBar.TextXAlignment = Enum.TextXAlignment.Left
                    TitleBar.ZIndex = 21

                    -- SV (saturation/value) 2D picker square
                    local SVSquare = Instance.new("Frame")
                    SVSquare.Parent = Popup
                    SVSquare.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    SVSquare.BorderSizePixel = 0
                    SVSquare.Position = UDim2.new(0, 16, 0, 42)
                    SVSquare.Size = UDim2.new(1, -32, 0, 140)
                    SVSquare.ZIndex = 21
                    local SVC = Instance.new("UICorner")
                    SVC.CornerRadius = UDim.new(0, 7)
                    SVC.Parent = SVSquare

                    -- White gradient (left=white, right=transparent)
                    local SVGradW = Instance.new("UIGradient")
                    SVGradW.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
                    SVGradW.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    SVGradW.Parent = SVSquare

                    -- Black overlay frame (top=transparent, bottom=black)
                    local SVDark = Instance.new("Frame")
                    SVDark.Parent = SVSquare
                    SVDark.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    SVDark.BackgroundTransparency = 0
                    SVDark.BorderSizePixel = 0
                    SVDark.Size = UDim2.new(1, 0, 1, 0)
                    SVDark.ZIndex = 22
                    local SVDC = Instance.new("UICorner")
                    SVDC.CornerRadius = UDim.new(0, 7)
                    SVDC.Parent = SVDark
                    local SVGradD = Instance.new("UIGradient")
                    SVGradD.Color = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0))
                    SVGradD.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0)
                    })
                    SVGradD.Rotation = 270
                    SVGradD.Parent = SVDark

                    -- SV cursor dot
                    local SVCursor = Instance.new("Frame")
                    SVCursor.Parent = SVSquare
                    SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                    SVCursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    SVCursor.BorderSizePixel = 0
                    SVCursor.Size = UDim2.new(0, 12, 0, 12)
                    SVCursor.ZIndex = 25
                    local SVCC = Instance.new("UICorner")
                    SVCC.CornerRadius = UDim.new(1, 0)
                    SVCC.Parent = SVCursor
                    local SVCursorStroke = Instance.new("UIStroke")
                    SVCursorStroke.Color = Color3.fromRGB(255,255,255)
                    SVCursorStroke.Thickness = 2
                    SVCursorStroke.Parent = SVCursor

                    -- Hue slider bar
                    local HueBar = Instance.new("Frame")
                    HueBar.Parent = Popup
                    HueBar.BorderSizePixel = 0
                    HueBar.Position = UDim2.new(0, 16, 0, 194)
                    HueBar.Size = UDim2.new(1, -32, 0, 18)
                    HueBar.ZIndex = 21
                    local HBC = Instance.new("UICorner")
                    HBC.CornerRadius = UDim.new(1, 0)
                    HBC.Parent = HueBar
                    local HueGrad = Instance.new("UIGradient")
                    HueGrad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 0, 0))
                    })
                    HueGrad.Parent = HueBar

                    -- Hue cursor
                    local HueCursor = Instance.new("Frame")
                    HueCursor.Parent = HueBar
                    HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                    HueCursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    HueCursor.BorderSizePixel = 0
                    HueCursor.Position = UDim2.new(0, 0, 0.5, 0)
                    HueCursor.Size = UDim2.new(0, 16, 0, 22)
                    HueCursor.ZIndex = 25
                    local HCC = Instance.new("UICorner")
                    HCC.CornerRadius = UDim.new(0, 4)
                    HCC.Parent = HueCursor
                    local HCSt = Instance.new("UIStroke")
                    HCSt.Color = Color3.fromRGB(100,100,100)
                    HCSt.Thickness = 1
                    HCSt.Parent = HueCursor

                    -- Bottom row: Preview box + Hex input
                    local Preview = Instance.new("Frame")
                    Preview.Parent = Popup
                    Preview.BackgroundColor3 = ColorFunc.Value
                    Preview.BorderSizePixel = 0
                    Preview.Position = UDim2.new(0, 16, 0, 226)
                    Preview.Size = UDim2.new(0, 44, 0, 32)
                    Preview.ZIndex = 21
                    local PrC = Instance.new("UICorner")
                    PrC.CornerRadius = UDim.new(0, 7)
                    PrC.Parent = Preview
                    local PrSt = Instance.new("UIStroke")
                    PrSt.Color = Color3.fromRGB(255,255,255)
                    PrSt.Transparency = 0.6
                    PrSt.Parent = Preview

                    local HexFrame = Instance.new("Frame")
                    HexFrame.Parent = Popup
                    HexFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 28)
                    HexFrame.BorderSizePixel = 0
                    HexFrame.Position = UDim2.new(0, 68, 0, 226)
                    HexFrame.Size = UDim2.new(1, -84, 0, 32)
                    HexFrame.ZIndex = 21
                    local HFC = Instance.new("UICorner")
                    HFC.CornerRadius = UDim.new(0, 7)
                    HFC.Parent = HexFrame
                    local HFSt = Instance.new("UIStroke")
                    HFSt.Color = Library.Theme.Stroke
                    HFSt.Transparency = 0.6
                    HFSt.Parent = HexFrame

                    local HexLabel = Instance.new("TextLabel")
                    HexLabel.Parent = HexFrame
                    HexLabel.BackgroundTransparency = 1
                    HexLabel.Position = UDim2.new(0, 10, 0, 0)
                    HexLabel.Size = UDim2.new(0, 18, 1, 0)
                    HexLabel.Font = Enum.Font.GothamBold
                    HexLabel.Text = "#"
                    HexLabel.TextColor3 = Library.Theme.TextDisabled
                    HexLabel.TextSize = 13
                    HexLabel.ZIndex = 22

                    local HexInput = Instance.new("TextBox")
                    HexInput.Parent = HexFrame
                    HexInput.BackgroundTransparency = 1
                    HexInput.Position = UDim2.new(0, 28, 0, 0)
                    HexInput.Size = UDim2.new(1, -32, 1, 0)
                    HexInput.Font = Enum.Font.Code
                    HexInput.PlaceholderText = "FFFFFF"
                    HexInput.Text = ""
                    HexInput.TextColor3 = Library.Theme.Text
                    HexInput.TextSize = 13
                    HexInput.TextXAlignment = Enum.TextXAlignment.Left
                    HexInput.ZIndex = 22
                    HexInput.ClearTextOnFocus = false

                    -- Buttons row
                    local Cancel = Instance.new("TextButton")
                    Cancel.Parent = Popup
                    Cancel.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
                    Cancel.BorderSizePixel = 0
                    Cancel.Position = UDim2.new(0, 16, 1, -50)
                    Cancel.Size = UDim2.new(0.46, -8, 0, 32)
                    Cancel.Font = Enum.Font.GothamBold
                    Cancel.Text = "Cancel"
                    Cancel.TextColor3 = Library.Theme.Text
                    Cancel.TextSize = 13
                    Cancel.ZIndex = 21
                    local CC = Instance.new("UICorner")
                    CC.CornerRadius = UDim.new(0, 7)
                    CC.Parent = Cancel

                    local Apply = Instance.new("TextButton")
                    Apply.Parent = Popup
                    Apply.BackgroundColor3 = Library.Theme.Accent
                    Apply.BorderSizePixel = 0
                    Apply.Position = UDim2.new(0.54, 0, 1, -50)
                    Apply.Size = UDim2.new(0.46, -16, 0, 32)
                    Apply.Font = Enum.Font.GothamBold
                    Apply.Text = "Apply"
                    Apply.TextColor3 = Library.Theme.Text
                    Apply.TextSize = 13
                    Apply.ZIndex = 21
                    local AC = Instance.new("UICorner")
                    AC.CornerRadius = UDim.new(0, 7)
                    AC.Parent = Apply

                    -- State
                    local currentH, currentS, currentV = Color3.toHSV(ColorFunc.Value)

                    local function ColorFromHSV(h, s, v)
                        return Color3.fromHSV(math.clamp(h,0,1), math.clamp(s,0,1), math.clamp(v,0,1))
                    end

                    local function ToHex(c)
                        return string.format("%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
                    end

                    local function FromHex(hex)
                        hex = hex:gsub("#", "")
                        if #hex == 6 then
                            local r = tonumber(hex:sub(1,2), 16)
                            local g = tonumber(hex:sub(3,4), 16)
                            local b = tonumber(hex:sub(5,6), 16)
                            if r and g and b then
                                return Color3.fromRGB(r, g, b)
                            end
                        end
                        return nil
                    end

                    local function UpdateUI()
                        local hueColor = ColorFromHSV(currentH, 1, 1)
                        SVSquare.BackgroundColor3 = hueColor
                        HueCursor.Position = UDim2.new(currentH, 0, 0.5, 0)
                        SVCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
                        local previewColor = ColorFromHSV(currentH, currentS, currentV)
                        Preview.BackgroundColor3 = previewColor
                        HexInput.Text = ToHex(previewColor)
                    end

                    UpdateUI()

                    -- Hue bar drag
                    local hueDragging = false
                    local function UpdateHue(inputPos)
                        currentH = math.clamp((inputPos.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                        UpdateUI()
                    end
                    HueBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            hueDragging = true
                            UpdateHue(input.Position)
                        end
                    end)
                    HueBar.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            hueDragging = false
                        end
                    end)

                    -- SV square drag
                    local svDragging = false
                    local function UpdateSV(inputPos)
                        currentS = math.clamp((inputPos.X - SVSquare.AbsolutePosition.X) / SVSquare.AbsoluteSize.X, 0, 1)
                        currentV = 1 - math.clamp((inputPos.Y - SVSquare.AbsolutePosition.Y) / SVSquare.AbsoluteSize.Y, 0, 1)
                        UpdateUI()
                    end
                    SVSquare.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            svDragging = true
                            UpdateSV(input.Position)
                        end
                    end)
                    SVSquare.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            svDragging = false
                        end
                    end)
                    SVDark.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            svDragging = true
                            UpdateSV(input.Position)
                        end
                    end)
                    SVDark.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            svDragging = false
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            if hueDragging then UpdateHue(input.Position) end
                            if svDragging then UpdateSV(input.Position) end
                        end
                    end)

                    -- Hex input
                    HexInput.FocusLost:Connect(function()
                        local c = FromHex(HexInput.Text)
                        if c then
                            currentH, currentS, currentV = Color3.toHSV(c)
                            UpdateUI()
                        else
                            HexInput.Text = ToHex(Preview.BackgroundColor3)
                        end
                    end)

                    local function Close()
                        Popup:Destroy()
                        Library:TweenInstance(DropdownZone, 0.25, "BackgroundTransparency", 1, function()
                            DropdownZone.Visible = false
                        end)
                    end

                    Cancel.MouseButton1Click:Connect(Close)

                    Apply.MouseButton1Click:Connect(function()
                        ColorFunc:Set(Preview.BackgroundColor3)
                        Close()
                    end)
                end)

                return ColorFunc
            end

            function SectionFunc:AddKeybind(cfkey)
                local cfkey = Library:MakeConfig({
                    Title = "Keybind",
                    Description = "",
                    Default = Enum.KeyCode.Unknown,
                    Callback = function() end
                }, cfkey or {})

                local Keybind = Instance.new("Frame")
                local UICorner_K = Instance.new("UICorner")
                local Title_K = Instance.new("TextLabel")
                local Content_K = Instance.new("TextLabel")
                local KeyFrame = Instance.new("Frame")
                local UICorner_KF = Instance.new("UICorner")
                local KeyText = Instance.new("TextLabel")
                local KeyBtn = Instance.new("TextButton")

                Keybind.Name = "Keybind"
                Keybind.Parent = SectionList
                Keybind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Keybind.BackgroundTransparency = 0.950
                Keybind.BorderSizePixel = 0
                Keybind.Size = UDim2.new(1, 0, 0, 35)

                UICorner_K.CornerRadius = UDim.new(0, 3)
                UICorner_K.Parent = Keybind

                Title_K.Name = "Title"
                Title_K.Parent = Keybind
                Title_K.BackgroundTransparency = 1
                Title_K.Position = UDim2.new(0, 10, 0, 0)
                Title_K.Size = UDim2.new(1, -100, 1, 0)
                Title_K.Font = Enum.Font.GothamBold
                Title_K.Text = cfkey.Title
                Title_K.TextColor3 = Library.Theme.Text
                Title_K.TextSize = 13
                Title_K.TextXAlignment = Enum.TextXAlignment.Left

                Content_K.Name = "Content"
                Content_K.Parent = Keybind
                Content_K.BackgroundTransparency = 1
                Content_K.Position = UDim2.new(0, 10, 0, 22)
                Content_K.Size = UDim2.new(1, -100, 1, 0)
                Content_K.Font = Enum.Font.GothamBold
                Content_K.Text = cfkey.Description
                Content_K.TextColor3 = Library.Theme.TextDisabled
                Content_K.TextSize = 12
                Content_K.TextXAlignment = Enum.TextXAlignment.Left
                Content_K.TextYAlignment = Enum.TextYAlignment.Top
                Library:UpdateContent(Content_K, Title_K, Keybind)

                KeyFrame.Name = "KeyFrame"
                KeyFrame.Parent = Keybind
                KeyFrame.AnchorPoint = Vector2.new(0, 0.5)
                KeyFrame.BackgroundColor3 = Library.Theme.Background
                KeyFrame.BorderSizePixel = 0
                KeyFrame.Position = UDim2.new(1, -90, 0.5, 0)
                KeyFrame.Size = UDim2.new(0, 80, 0, 26)

                UICorner_KF.CornerRadius = UDim.new(0, 5)
                UICorner_KF.Parent = KeyFrame

                KeyText.Parent = KeyFrame
                KeyText.BackgroundTransparency = 1
                KeyText.Size = UDim2.new(1, 0, 1, 0)
                KeyText.Font = Enum.Font.GothamBold
                KeyText.Text = cfkey.Default.Name or "None"
                KeyText.TextColor3 = Library.Theme.Text
                KeyText.TextSize = 11

                KeyBtn.Parent = KeyFrame
                KeyBtn.BackgroundTransparency = 1
                KeyBtn.Size = UDim2.new(1, 0, 1, 0)
                KeyBtn.Text = ""

                local KeyFunc = { Value = cfkey.Default }
                local Listening = false

                function KeyFunc:Set(k)
                    KeyFunc.Value = k
                    KeyText.Text = k.Name or "None"
                    cfkey.Callback(k)
                end

                KeyBtn.MouseButton1Click:Connect(function()
                    if Listening then return end
                    Listening = true
                    KeyText.Text = "..."
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input, gp)
                        if gp then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            KeyFunc:Set(input.KeyCode)
                            Listening = false
                            conn:Disconnect()
                        end
                    end)
                end)

                return KeyFunc
            end

            function SectionFunc:AddMultiButton(cfmb)
                local cfmb = Library:MakeConfig({
                    Full = { Title = "Full", Callback = function() end },
                    Left = { Title = "Left", Callback = function() end },
                    Right = { Title = "Right", Callback = function() end }
                }, cfmb or {})

                local Holder = Instance.new("Frame")
                Holder.Name = "MultiButton"
                Holder.Parent = SectionList
                Holder.BackgroundTransparency = 1
                Holder.Size = UDim2.new(1, 0, 0, 78)

                local FullBtn = Instance.new("TextButton")
                FullBtn.Parent = Holder
                FullBtn.BackgroundColor3 = Library.Theme.Accent
                FullBtn.BorderSizePixel = 0
                FullBtn.Size = UDim2.new(1, 0, 0, 32)
                FullBtn.Font = Enum.Font.GothamBold
                FullBtn.Text = cfmb.Full.Title
                FullBtn.TextColor3 = Library.Theme.Text
                FullBtn.TextSize = 13

                local FC = Instance.new("UICorner")
                FC.CornerRadius = UDim.new(0, 5)
                FC.Parent = FullBtn

                FullBtn.MouseButton1Click:Connect(function()
                    cfmb.Full.Callback()
                end)

                local LeftBtn = Instance.new("TextButton")
                LeftBtn.Parent = Holder
                LeftBtn.BackgroundColor3 = Library.Theme.Background
                LeftBtn.BorderSizePixel = 0
                LeftBtn.Position = UDim2.new(0, 0, 0, 40)
                LeftBtn.Size = UDim2.new(0.48, 0, 0, 32)
                LeftBtn.Font = Enum.Font.GothamBold
                LeftBtn.Text = cfmb.Left.Title
                LeftBtn.TextColor3 = Library.Theme.Text
                LeftBtn.TextSize = 12

                local LC = Instance.new("UICorner")
                LC.CornerRadius = UDim.new(0, 5)
                LC.Parent = LeftBtn

                LeftBtn.MouseButton1Click:Connect(function()
                    cfmb.Left.Callback()
                end)

                local RightBtn = Instance.new("TextButton")
                RightBtn.Parent = Holder
                RightBtn.BackgroundColor3 = Library.Theme.Background
                RightBtn.BorderSizePixel = 0
                RightBtn.Position = UDim2.new(0.52, 0, 0, 40)
                RightBtn.Size = UDim2.new(0.48, 0, 0, 32)
                RightBtn.Font = Enum.Font.GothamBold
                RightBtn.Text = cfmb.Right.Title
                RightBtn.TextColor3 = Library.Theme.Text
                RightBtn.TextSize = 12

                local RC = Instance.new("UICorner")
                RC.CornerRadius = UDim.new(0, 5)
                RC.Parent = RightBtn

                RightBtn.MouseButton1Click:Connect(function()
                    cfmb.Right.Callback()
                end)
            end

            function SectionFunc:AddCodeblock(cfcode)
                local cfcode = Library:MakeConfig({
                    Title = "Code",
                    Code = "print('hello')",
                    Callback = function() end
                }, cfcode or {})

                local Code = Instance.new("Frame")
                local UICorner_CD = Instance.new("UICorner")
                local Title_CD = Instance.new("TextLabel")
                local CodeBox = Instance.new("TextBox")
                local RunBtn = Instance.new("TextButton")
                local CopyBtn = Instance.new("TextButton")

                Code.Name = "Codeblock"
                Code.Parent = SectionList
                Code.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                Code.BorderSizePixel = 0
                Code.Size = UDim2.new(1, 0, 0, 140)

                UICorner_CD.CornerRadius = UDim.new(0, 6)
                UICorner_CD.Parent = Code

                Title_CD.Parent = Code
                Title_CD.BackgroundTransparency = 1
                Title_CD.Position = UDim2.new(0, 10, 0, 6)
                Title_CD.Size = UDim2.new(1, -20, 0, 18)
                Title_CD.Font = Enum.Font.GothamBold
                Title_CD.Text = cfcode.Title
                Title_CD.TextColor3 = Library.Theme.Text
                Title_CD.TextSize = 12
                Title_CD.TextXAlignment = Enum.TextXAlignment.Left

                CodeBox.Parent = Code
                CodeBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
                CodeBox.BorderSizePixel = 0
                CodeBox.Position = UDim2.new(0, 8, 0, 28)
                CodeBox.Size = UDim2.new(1, -16, 0, 70)
                CodeBox.Font = Enum.Font.Code
                CodeBox.Text = cfcode.Code
                CodeBox.TextColor3 = Color3.fromRGB(200, 200, 200)
                CodeBox.TextSize = 12
                CodeBox.TextXAlignment = Enum.TextXAlignment.Left
                CodeBox.TextYAlignment = Enum.TextYAlignment.Top
                CodeBox.ClearTextOnFocus = false
                CodeBox.MultiLine = true
                CodeBox.TextWrapped = true

                local CBC = Instance.new("UICorner")
                CBC.CornerRadius = UDim.new(0, 4)
                CBC.Parent = CodeBox

                RunBtn.Parent = Code
                RunBtn.BackgroundColor3 = Library.Theme.Accent
                RunBtn.BorderSizePixel = 0
                RunBtn.Position = UDim2.new(0, 8, 1, -34)
                RunBtn.Size = UDim2.new(0.48, -6, 0, 26)
                RunBtn.Font = Enum.Font.GothamBold
                RunBtn.Text = "Run"
                RunBtn.TextColor3 = Library.Theme.Text
                RunBtn.TextSize = 12

                local RBC = Instance.new("UICorner")
                RBC.CornerRadius = UDim.new(0, 5)
                RBC.Parent = RunBtn

                CopyBtn.Parent = Code
                CopyBtn.BackgroundColor3 = Library.Theme.Background
                CopyBtn.BorderSizePixel = 0
                CopyBtn.Position = UDim2.new(0.52, 2, 1, -34)
                CopyBtn.Size = UDim2.new(0.48, -10, 0, 26)
                CopyBtn.Font = Enum.Font.GothamBold
                CopyBtn.Text = "Copy"
                CopyBtn.TextColor3 = Library.Theme.Text
                CopyBtn.TextSize = 12

                local CBC2 = Instance.new("UICorner")
                CBC2.CornerRadius = UDim.new(0, 5)
                CBC2.Parent = CopyBtn

                RunBtn.MouseButton1Click:Connect(function()
                    local ok, err = pcall(function()
                        loadstring(CodeBox.Text)()
                    end)
                    if not ok then
                        warn("[sh1ttybanana] Code error:", err)
                    end
                    cfcode.Callback(CodeBox.Text)
                end)

                CopyBtn.MouseButton1Click:Connect(function()
                    if setclipboard then
                        setclipboard(CodeBox.Text)
                    end
                end)
            end

            function SectionFunc:AddSpace(amount)
                local Space = Instance.new("Frame")
                Space.Name = "Space"
                Space.Parent = SectionList
                Space.BackgroundTransparency = 1
                Space.Size = UDim2.new(1, 0, 0, amount or 10)
            end

            return SectionFunc
        end

        return TabFunc
    end

    local WindowAPI = {}

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
        SecFrame.ClipsDescendants = true

        local Header = Instance.new("TextButton")
        Header.Name = "Header"
        Header.Parent = SecFrame
        Header.BackgroundTransparency = 1
        Header.Size = UDim2.new(1, 0, 0, 28)
        Header.Text = ""
        Header.AutoButtonColor = false

        local Title = Instance.new("TextLabel")
        Title.Parent = Header
        Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 8, 0, 0)
        Title.Size = UDim2.new(1, -36, 1, 0)
        Title.Font = Enum.Font.GothamBold
        Title.Text = cfg.Title
        Title.TextColor3 = Library.Theme.TextDisabled
        Title.TextSize = 12
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.TextTransparency = 0.15

        local Chevron = Instance.new("ImageLabel")
        Chevron.Parent = Header
        Chevron.BackgroundTransparency = 1
        Chevron.Position = UDim2.new(1, -22, 0.5, -7)
        Chevron.Size = UDim2.new(0, 14, 0, 14)
        Chevron.Visible = false

        local TabsHolder = Instance.new("Frame")
        TabsHolder.Name = "TabsHolder"
        TabsHolder.Parent = SecFrame
        TabsHolder.BackgroundTransparency = 1
        TabsHolder.Position = UDim2.new(0, 0, 0, 28)
        TabsHolder.Size = UDim2.new(1, 0, 0, 0)
        TabsHolder.Visible = Opened
        TabsHolder.ClipsDescendants = true

        local TabsLayout = Instance.new("UIListLayout")
        TabsLayout.Parent = TabsHolder
        TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabsLayout.Padding = UDim.new(0, 2)

        local function Refresh()
            local hasTabs = #SectionTabs > 0
            Chevron.Visible = hasTabs
            if hasTabs then
                Library:SetIcon(Chevron, Opened and Library.DefaultIcons.ChevronDown or Library.DefaultIcons.ChevronRight, Library.Theme.Accent)
                if Opened then
                    local h = TabsLayout.AbsoluteContentSize.Y
                    TabsHolder.Size = UDim2.new(1, 0, 0, h)
                    TabsHolder.Visible = true
                    SecFrame.Size = UDim2.new(1, 0, 0, 28 + h)
                else
                    TabsHolder.Size = UDim2.new(1, 0, 0, 0)
                    TabsHolder.Visible = false
                    SecFrame.Size = UDim2.new(1, 0, 0, 28)
                end
            else
                TabsHolder.Visible = false
                SecFrame.Size = UDim2.new(1, 0, 0, 28)
            end
        end

        TabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Refresh)

        Header.MouseButton1Click:Connect(function()
            if #SectionTabs == 0 then return end
            Opened = not Opened
            Refresh()
        end)

        local SectionAPI = {}

        function SectionAPI:Tab(nameOrConfig, iconName)
            local tabResult = Tab:T(nameOrConfig, iconName)
            local lastTab = nil
            for _, child in ipairs(ScrollingTab:GetChildren()) do
                if child:IsA("Frame") and child.Name == "TabDisable" then
                    lastTab = child
                end
            end
            if lastTab then
                lastTab.Parent = TabsHolder
                table.insert(SectionTabs, lastTab)
                task.defer(Refresh)
            end
            return tabResult
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

    function WindowAPI:Tag(cfg)
        cfg = Library:MakeConfig({
            Title = "Tag",
            Color = Color3.fromRGB(48, 255, 106),
            Icon = nil
        }, cfg or {})

        local TagHolder = Top:FindFirstChild("TagHolder")
        if not TagHolder then
            TagHolder = Instance.new("Frame")
            TagHolder.Name = "TagHolder"
            TagHolder.Parent = Top
            TagHolder.BackgroundTransparency = 1
            TagHolder.Position = UDim2.new(0, 200, 0, 12)
            TagHolder.Size = UDim2.new(0, 300, 0, 26)

            local TagList = Instance.new("UIListLayout")
            TagList.Parent = TagHolder
            TagList.FillDirection = Enum.FillDirection.Horizontal
            TagList.Padding = UDim.new(0, 6)
            TagList.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local Tag = Instance.new("Frame")
        Tag.Name = "Tag"
        Tag.Parent = TagHolder
        Tag.BackgroundColor3 = cfg.Color
        Tag.BorderSizePixel = 0
        Tag.Size = UDim2.new(0, 0, 0, 22)
        Tag.AutomaticSize = Enum.AutomaticSize.X

        local TC = Instance.new("UICorner")
        TC.CornerRadius = UDim.new(1, 0)
        TC.Parent = Tag

        if cfg.Icon then
            local TI = Instance.new("ImageLabel")
            TI.Parent = Tag
            TI.BackgroundTransparency = 1
            TI.Position = UDim2.new(0, 6, 0.5, -6)
            TI.Size = UDim2.new(0, 12, 0, 12)
            Library:SetIcon(TI, cfg.Icon, Color3.fromRGB(20, 20, 20))
        end

        local TL = Instance.new("TextLabel")
        TL.Parent = Tag
        TL.BackgroundTransparency = 1
        TL.Position = UDim2.new(0, cfg.Icon and 22 or 0, 0, 0)
        TL.Size = UDim2.new(0, 0, 1, 0)
        TL.AutomaticSize = Enum.AutomaticSize.X
        TL.Font = Enum.Font.GothamBold
        TL.Text = cfg.Title
        TL.TextColor3 = Color3.fromRGB(20, 20, 20)
        TL.TextSize = 11

        local Pad = Instance.new("UIPadding")
        Pad.Parent = Tag
        Pad.PaddingLeft = UDim.new(0, cfg.Icon and 6 or 10)
        Pad.PaddingRight = UDim.new(0, 10)

        table.insert(WindowTags, Tag)
        return Tag
    end

    function WindowAPI:SetTransparency(value)
        value = math.clamp(tonumber(value) or 0.07, 0, 0.8)
        Main.BackgroundTransparency = value
        ConfigWindow.Transparent = value
    end

    function WindowAPI:SaveConfig(name)
        name = name or "sh1ttybanana_config"
        if writefile then
            pcall(function()
                writefile(name .. ".json", HttpService:JSONEncode(ConfigFlags))
            end)
        end
    end

    function WindowAPI:LoadConfig(name)
        name = name or "sh1ttybanana_config"
        if readfile and isfile and isfile(name .. ".json") then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(readfile(name .. ".json"))
            end)
            if ok and type(data) == "table" then
                ConfigFlags = data
            end
        end
    end

    function WindowAPI:SetFlag(flag, value)
        ConfigFlags[flag] = value
    end

    function WindowAPI:GetFlag(flag)
        return ConfigFlags[flag]
    end

    function WindowAPI:SetGroqConfig(apiKey, systemPrompt)
        if self._activeSetGroqConfig then
            self._activeSetGroqConfig(apiKey, systemPrompt)
        else
            -- store for when AI window opens next time
            self._pendingGroqKey = apiKey
            self._pendingGroqPrompt = systemPrompt
        end
    end

    function WindowAPI:SelectTab(tabName)
        for _, child in ipairs(ScrollingTab:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChild("NameTab") then
                local raw = child.NameTab:GetAttribute("RawName") or child.NameTab.Text or ""
                if string.lower(raw) == string.lower(tostring(tabName)) then
                    TextLabel.Text = raw
                    for _, c2 in ipairs(ScrollingTab:GetChildren()) do
                        if c2:IsA("Frame") and c2:FindFirstChild("NameTab") then
                            Library:TweenInstance(c2.NameTab, 0.28, "TextTransparency", 0.35)
                            if c2:FindFirstChild("Choose") then c2.Choose.Visible = false end
                        end
                    end
                    Library:TweenInstance(child.NameTab, 0.22, "TextTransparency", 0)
                    UIPageLayout:JumpToIndex(child.LayoutOrder)
                    if child:FindFirstChild("Choose") then child.Choose.Visible = true end
                    return true
                end
            end
        end
        return false
    end

    function WindowAPI:Dialog(cfg)
        cfg = Library:MakeConfig({
            Title = "Dialog",
            Content = "",
            Buttons = {}
        }, cfg or {})

        DropdownZone.Visible = true
        Library:TweenInstance(DropdownZone, 0.25, "BackgroundTransparency", 0.4)

        local Popup = Instance.new("Frame")
        Popup.Parent = DropdownZone
        Popup.AnchorPoint = Vector2.new(0.5, 0.5)
        Popup.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        Popup.BorderSizePixel = 0
        Popup.Position = UDim2.new(0.5, 0, 0.5, 0)
        Popup.Size = UDim2.new(0, 340, 0, 160)

        local PC = Instance.new("UICorner")
        PC.CornerRadius = UDim.new(0, 10)
        PC.Parent = Popup

        local Title = Instance.new("TextLabel")
        Title.Parent = Popup
        Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 18, 0, 14)
        Title.Size = UDim2.new(1, -36, 0, 22)
        Title.Font = Enum.Font.GothamBold
        Title.Text = cfg.Title
        Title.TextColor3 = Library.Theme.Text
        Title.TextSize = 15
        Title.TextXAlignment = Enum.TextXAlignment.Left

        local Content = Instance.new("TextLabel")
        Content.Parent = Popup
        Content.BackgroundTransparency = 1
        Content.Position = UDim2.new(0, 18, 0, 42)
        Content.Size = UDim2.new(1, -36, 0, 40)
        Content.Font = Enum.Font.Gotham
        Content.Text = cfg.Content
        Content.TextColor3 = Library.Theme.TextDisabled
        Content.TextSize = 13
        Content.TextXAlignment = Enum.TextXAlignment.Left
        Content.TextWrapped = true

        local function Close()
            Popup:Destroy()
            Library:TweenInstance(DropdownZone, 0.25, "BackgroundTransparency", 1, function()
                DropdownZone.Visible = false
            end)
        end

        local btnCount = #cfg.Buttons
        for i, btn in ipairs(cfg.Buttons) do
            local B = Instance.new("TextButton")
            B.Parent = Popup
            B.BackgroundColor3 = (btn.Variant == "Primary") and Library.Theme.Accent or Color3.fromRGB(40, 40, 40)
            B.BorderSizePixel = 0
            B.Size = UDim2.new(0, 140, 0, 32)
            B.Position = UDim2.new(1, -18 - (btnCount - i + 1) * 150 + 10, 1, -48)
            B.Font = Enum.Font.GothamBold
            B.Text = btn.Title or "OK"
            B.TextColor3 = Library.Theme.Text
            B.TextSize = 13

            local BC = Instance.new("UICorner")
            BC.CornerRadius = UDim.new(0, 6)
            BC.Parent = B

            B.MouseButton1Click:Connect(function()
                if btn.Callback then btn.Callback() end
                Close()
            end)
        end

        return Popup
    end

    function WindowAPI:Popup(cfg)
        return WindowAPI:Dialog(cfg)
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

        local titleText = cfg.Title
        local descText = cfg.Content ~= "" and cfg.Content or cfg.Desc
        local duration = cfg.Duration or 4
        local notifType = cfg.Type or "Info"

        local typeColor = Color3.fromRGB(158, 198, 255)
        if notifType == "Error" then
            typeColor = Color3.fromRGB(255, 82, 82)
        elseif notifType == "Success" then
            typeColor = Color3.fromRGB(145, 255, 128)
        elseif notifType == "Warn" then
            typeColor = Color3.fromRGB(255, 225, 117)
        end

        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "Notify"
        MainFrame.Parent = TeddyUI_Premium
        MainFrame.BorderSizePixel = 0
        MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
        MainFrame.Size = UDim2.new(0, 220, 0, 58)
        MainFrame.Position = UDim2.new(1, 40, 0, 120)
        MainFrame.ZIndex = 80

        local UICorner_Main = Instance.new("UICorner")
        UICorner_Main.CornerRadius = UDim.new(0, 8)
        UICorner_Main.Parent = MainFrame

        local TypeEffect = Instance.new("Frame")
        TypeEffect.Parent = MainFrame
        TypeEffect.BorderSizePixel = 0
        TypeEffect.BackgroundColor3 = typeColor
        TypeEffect.Size = UDim2.new(0, 4, 1, 0)
        TypeEffect.Position = UDim2.new(0, 0, 0, 0)
        TypeEffect.ZIndex = 81
        local TEC = Instance.new("UICorner")
        TEC.CornerRadius = UDim.new(0, 8)
        TEC.Parent = TypeEffect

        local NotificationTitle = Instance.new("TextLabel")
        NotificationTitle.Parent = MainFrame
        NotificationTitle.BorderSizePixel = 0
        NotificationTitle.TextSize = 13
        NotificationTitle.TextXAlignment = Enum.TextXAlignment.Left
        NotificationTitle.BackgroundTransparency = 1
        NotificationTitle.Font = Enum.Font.GothamBold
        NotificationTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        NotificationTitle.Size = UDim2.new(1, -30, 0, 20)
        NotificationTitle.Text = titleText
        NotificationTitle.Position = UDim2.new(0, 14, 0, 6)
        NotificationTitle.ZIndex = 82

        local NotificationDescription = Instance.new("TextLabel")
        NotificationDescription.Parent = MainFrame
        NotificationDescription.TextWrapped = true
        NotificationDescription.BorderSizePixel = 0
        NotificationDescription.TextSize = 11
        NotificationDescription.TextXAlignment = Enum.TextXAlignment.Left
        NotificationDescription.TextTransparency = 0.35
        NotificationDescription.BackgroundTransparency = 1
        NotificationDescription.Font = Enum.Font.Gotham
        NotificationDescription.TextColor3 = Color3.fromRGB(220, 220, 220)
        NotificationDescription.Size = UDim2.new(1, -24, 0, 28)
        NotificationDescription.Text = descText
        NotificationDescription.Position = UDim2.new(0, 14, 0, 26)
        NotificationDescription.ZIndex = 82

        local DurationFrame = Instance.new("Frame")
        DurationFrame.Parent = MainFrame
        DurationFrame.BorderSizePixel = 0
        DurationFrame.BackgroundColor3 = typeColor
        DurationFrame.Size = UDim2.new(1, -16, 0, 3)
        DurationFrame.Position = UDim2.new(0, 8, 1, -6)
        DurationFrame.BackgroundTransparency = 0.3
        DurationFrame.ZIndex = 82
        local DFC = Instance.new("UICorner")
        DFC.CornerRadius = UDim.new(1, 0)
        DFC.Parent = DurationFrame

        local CloseButton = Instance.new("TextButton")
        CloseButton.Parent = MainFrame
        CloseButton.BorderSizePixel = 0
        CloseButton.TextSize = 14
        CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        CloseButton.BackgroundTransparency = 1
        CloseButton.Size = UDim2.new(0, 20, 0, 20)
        CloseButton.Position = UDim2.new(1, -24, 0, 4)
        CloseButton.Text = "×"
        CloseButton.ZIndex = 83

        local notifData = {Frame = MainFrame}
        table.insert(Library.ActiveNotifications, notifData)

        local function updatePositions()
            for i, notif in ipairs(Library.ActiveNotifications) do
                if notif and notif.Frame and notif.Frame.Parent then
                    local targetY = 100 + ((i - 1) * 68)
                    Library:Tween(notif.Frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Position = UDim2.new(1, -240, 0, targetY)
                    })
                end
            end
        end

        local isClosing = false
        local tweenBar = TweenService:Create(DurationFrame, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)})

        local function closeUI()
            if isClosing then return end
            isClosing = true
            if tweenBar then tweenBar:Cancel() end
            for i, v in ipairs(Library.ActiveNotifications) do
                if v == notifData then
                    table.remove(Library.ActiveNotifications, i)
                    break
                end
            end
            updatePositions()
            Library:Tween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 40, 0, MainFrame.Position.Y.Offset)
            }, function()
                MainFrame:Destroy()
            end)
        end

        CloseButton.MouseButton1Click:Connect(closeUI)

        updatePositions()
        tweenBar:Play()
        tweenBar.Completed:Connect(function()
            if not isClosing then closeUI() end
        end)
    end

    return WindowAPI
end

return Library