local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local Player = Players.LocalPlayer
local IconModule = nil
pcall(function()
    IconModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/DSP-V1/NextGen/refs/heads/main/UILib/icons/UIIcons.lua"))()
    if IconModule and IconModule.SetIconsType then
        IconModule.SetIconsType("lucide")
    end
end)
Library.Themes = {
    Dark = {
        Main = Color3.fromRGB(11, 11, 13),
        Accent = Color3.fromRGB(158, 158, 158),
        Text = Color3.fromRGB(255, 255, 255),
        TextDisabled = Color3.fromRGB(165, 165, 165),
        Background = Color3.fromRGB(24, 24, 28),
        Stroke = Color3.fromRGB(88, 88, 96),
        Card = Color3.fromRGB(255, 255, 255),
        CardTransparency = 0.95,
        Section = Color3.fromRGB(255, 255, 255),
        SectionTransparency = 0.98,
        Notify = Color3.fromRGB(19, 19, 19),
        Overlay = Color3.fromRGB(18, 18, 18),
        Input = Color3.fromRGB(15, 15, 15),
        ImageBg = Color3.fromRGB(14, 14, 14)
    },
    Light = {
        Main = Color3.fromRGB(245, 245, 248),
        Accent = Color3.fromRGB(80, 80, 90),
        Text = Color3.fromRGB(20, 20, 25),
        TextDisabled = Color3.fromRGB(90, 90, 100),
        Background = Color3.fromRGB(230, 230, 235),
        Stroke = Color3.fromRGB(180, 180, 190),
        Card = Color3.fromRGB(255, 255, 255),
        CardTransparency = 0.15,
        Section = Color3.fromRGB(250, 250, 252),
        SectionTransparency = 0.3,
        Notify = Color3.fromRGB(255, 255, 255),
        Overlay = Color3.fromRGB(250, 250, 252),
        Input = Color3.fromRGB(235, 235, 240),
        ImageBg = Color3.fromRGB(240, 240, 245)
    }
}
Library.Theme = Library.Themes.Dark
Library.CurrentTheme = "Dark"
Library.Transparency = 0.06
function Library:SetTheme(Name)
    Name = tostring(Name or "Dark")
    if not self.Themes[Name] then
        Name = "Dark"
    end
    self.CurrentTheme = Name
    self.Theme = self.Themes[Name]
    return self.Theme
end
function Library:SetTransparency(Value)
    Value = math.clamp(tonumber(Value) or 0.06, 0, 0.9)
    self.Transparency = Value
    return Value
end
function Library:GetTheme()
    return self.CurrentTheme, self.Theme
end
Library.Flags = {}
function Library:SetFlag(Name, Value)
    self.Flags[tostring(Name)] = Value
end
function Library:GetFlag(Name, Default)
    local v = self.Flags[tostring(Name)]
    if v == nil then return Default end
    return v
end
function Library:SaveConfig(FileName)
    FileName = tostring(FileName or "kingbanana_config")
    local ok, err = pcall(function()
        if writefile then
            writefile(FileName .. ".json", game:GetService("HttpService"):JSONEncode(self.Flags))
        end
    end)
    return ok
end
function Library:LoadConfig(FileName)
    FileName = tostring(FileName or "kingbanana_config")
    local ok, data = pcall(function()
        if isfile and isfile(FileName .. ".json") and readfile then
            return game:GetService("HttpService"):JSONDecode(readfile(FileName .. ".json"))
        end
        return nil
    end)
    if ok and typeof(data) == "table" then
        for k, v in pairs(data) do
            self.Flags[k] = v
        end
        return true
    end
    return false
end

local function Create(ClassName, Properties)
    local Object = Instance.new(ClassName)
    for Property, Value in pairs(Properties or {}) do
        Object[Property] = Value
    end
    return Object
end
function Library:TweenInstance(Instance, Time, Property, TargetValue, Callback)
    local Tween = TweenService:Create(
        Instance,
        TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { [Property] = TargetValue }
    )
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
function Library:GetTitleGradient()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(176, 176, 176)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(82, 82, 82))
    })
end
function Library:GetAccentGradient()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 235, 235)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(156, 156, 156)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(68, 68, 68))
    })
end
function Library:GetLineGradient()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 35)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(155, 155, 155)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 35))
    })
end
function Library:ApplyGradient(Object, Color, Transparency, Rotation)
    local Gradient = Object:FindFirstChild("Gradient")
    if not Gradient then
        Gradient = Instance.new("UIGradient")
        Gradient.Name = "Gradient"
        Gradient.Parent = Object
    end
    Gradient.Color = Color or self:GetTitleGradient()
    Gradient.Rotation = Rotation or 0
    if Transparency then
        Gradient.Transparency = Transparency
    end
    return Gradient
end
function Library:CreateAccentBar(Parent, HeightPadding)
    local Bar = Create("Frame", {
        Name = "AccentBar",
        Parent = Parent,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 7, 0, HeightPadding or 7),
        Size = UDim2.new(0, 3, 1, -((HeightPadding or 7) * 2))
    })
    Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Bar
    })
    self:ApplyGradient(
        Bar,
        self:GetAccentGradient(),
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.05)
        }),
        90
    )
    return Bar
end
function Library:CreateHeaderDecor(Parent, TitleText, WidthOffset)
    local Header = Create("Frame", {
        Name = "HeaderDecor",
        Parent = Parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -(WidthOffset or 20), 1, 0)
    })
    local LeftGlow = Create("Frame", {
        Name = "LeftGlow",
        Parent = Header,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0.5, 0),
        Size = UDim2.new(0, 46, 0, 8)
    })
    local RightGlow = Create("Frame", {
        Name = "RightGlow",
        Parent = Header,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0, 46, 0, 8)
    })
    Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = LeftGlow
    })
    Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = RightGlow
    })
    Create("UIStroke", {
        Parent = LeftGlow,
        Color = self.Theme.Accent,
        Transparency = 0.3,
        Thickness = 1
    })
    Create("UIStroke", {
        Parent = RightGlow,
        Color = self.Theme.Accent,
        Transparency = 0.3,
        Thickness = 1
    })
    self:ApplyGradient(
        LeftGlow,
        self:GetAccentGradient(),
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.25)
        }),
        0
    )
    self:ApplyGradient(
        RightGlow,
        self:GetAccentGradient(),
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.25)
        }),
        180
    )
    local Title = Create("TextLabel", {
        Name = "Title",
        Parent = Header,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = TitleText,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    return Header, Title, LeftGlow, RightGlow
end
function Library:UpdateContent(Content, Title, Object, LeftOffset, RightOffset)
    local Text = Content.Text or ""
    local LeftPad = LeftOffset or 18
    local RightPad = RightOffset or 60
    if Text ~= "" then
        Title.Position = UDim2.new(0, LeftPad, 0, 7)
        Title.Size = UDim2.new(1, -RightPad, 0, 16)
        local Width = Object.AbsoluteSize.X > 0 and (Object.AbsoluteSize.X - (LeftPad + 12) - (RightPad - LeftPad)) or 250
        local Height = TextService:GetTextSize(
            Text,
            Content.TextSize,
            Content.Font,
            Vector2.new(Width, 1000)
        ).Y
        Object.Size = UDim2.new(1, 0, 0, math.max(45, Height + 32))
    else
        Object.Size = UDim2.new(1, 0, 0, 35)
    end
end
function Library:UpdateScrolling(Scroll, List, Horizontal)
    local function UpdateCanvasSize()
        if Horizontal then
            Scroll.CanvasSize = UDim2.new(0, List.AbsoluteContentSize.X + 10, 0, 0)
        else
            Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 10)
        end
    end
    List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)
    task.defer(UpdateCanvasSize)
end
function Library:Color3ToHex(Color)
    return string.format(
        "#%02X%02X%02X",
        math.clamp(math.floor((Color.R * 255) + 0.5), 0, 255),
        math.clamp(math.floor((Color.G * 255) + 0.5), 0, 255),
        math.clamp(math.floor((Color.B * 255) + 0.5), 0, 255)
    )
end
function Library:HexToColor3(Value)
    local Clean = tostring(Value or ""):gsub("#", ""):upper()
    if #Clean == 3 then
        Clean = Clean:sub(1, 1):rep(2) .. Clean:sub(2, 2):rep(2) .. Clean:sub(3, 3):rep(2)
    end
    if #Clean ~= 6 or not Clean:match("^%x%x%x%x%x%x$") then
        return nil
    end
    return Color3.fromRGB(
        tonumber(Clean:sub(1, 2), 16),
        tonumber(Clean:sub(3, 4), 16),
        tonumber(Clean:sub(5, 6), 16)
    )
end
function Library:MakeDraggable(DragBar, Object)
    local Dragging = false
    local DragInput
    local DragStart
    local StartPosition
    local function UpdatePosition(Input)
        local Delta = Input.Position - DragStart
        Object.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end
    DragBar.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
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
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end)
    UserInputService.InputChanged:Connect(function(Input)
        if Dragging and Input == DragInput then
            UpdatePosition(Input)
        end
    end)
end
function Library:SetIconColor(IconObject, Color, Transparency)
    if not IconObject then
        return
    end
    if IconObject:IsA("ImageLabel") or IconObject:IsA("ImageButton") then
        IconObject.ImageColor3 = Color
        if Transparency ~= nil then
            IconObject.ImageTransparency = Transparency
        end
    end
    for _, Child in ipairs(IconObject:GetDescendants()) do
        if Child:IsA("ImageLabel") or Child:IsA("ImageButton") then
            Child.ImageColor3 = Color
            if Transparency ~= nil then
                Child.ImageTransparency = Transparency
            end
        end
    end
end
function Library:CreateRemoteIcon(Parent, IconName, Size, Color)
    if not IconModule or not IconName or IconName == "" then
        return nil
    end
    local Success, IconData = pcall(function()
        return IconModule.Image({
            Icon = tostring(IconName):lower(),
            Size = Size or UDim2.new(0, 16, 0, 16),
            Colors = { Color or self.Theme.TextDisabled }
        })
    end)
    if Success and IconData and IconData.IconFrame then
        local IconFrame = IconData.IconFrame
        IconFrame.Name = "TabIcon"
        IconFrame.BackgroundTransparency = 1
        IconFrame.Parent = Parent
        self:SetIconColor(IconFrame, Color or self.Theme.TextDisabled, 0)
        return IconFrame
    end
    return nil
end
function Library:ResolveLockConfig(Config)
    Config = Config or {}
    local Locked = Config.Locked == true
    local LockText = tostring(Config.Locktext or Config.LockText or "premium")
    local LockIcon = tostring(Config.Lockicon or Config.LockIcon or "lock")
    return {
        Locked = Locked,
        Text = LockText,
        Icon = LockIcon
    }
end
function Library:PulseLockBadge(Badge)
    if not Badge then
        return
    end
    local Stroke = Badge:FindFirstChildOfClass("UIStroke")
    local CurrentTransparency = Badge.BackgroundTransparency
    self:TweenInstance(Badge, 0.12, "BackgroundTransparency", math.max(0.02, CurrentTransparency - 0.18), function()
        self:TweenInstance(Badge, 0.16, "BackgroundTransparency", CurrentTransparency)
    end)
    if Stroke then
        local StrokeTransparency = Stroke.Transparency
        self:TweenInstance(Stroke, 0.12, "Transparency", math.max(0, StrokeTransparency - 0.25), function()
            self:TweenInstance(Stroke, 0.16, "Transparency", StrokeTransparency)
        end)
    end
end
function Library:CreateLockBadge(Parent, LockData, Options)
    LockData = LockData or { Locked = false, Text = "premium", Icon = "lock" }
    Options = Options or {}
    local TextSize = Options.TextSize or 10
    local BadgeHeight = Options.Height or 18
    local HorizontalPadding = Options.Padding or 9
    local Gap = Options.Gap or 5
    local IconSize = Options.IconSize or 12
    local TextWidth = TextService:GetTextSize(
        LockData.Text,
        TextSize,
        Enum.Font.GothamBold,
        Vector2.new(1000, BadgeHeight)
    ).X
    local BadgeWidth = math.max(54, TextWidth + (HorizontalPadding * 2) + IconSize + Gap)
    local Badge = Create("Frame", {
        Name = "LockBadge",
        Parent = Parent,
        BackgroundColor3 = Color3.fromRGB(33, 33, 38),
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Size = UDim2.new(0, BadgeWidth, 0, BadgeHeight),
        Visible = LockData.Locked
    })
    if Options.Position then
        Badge.Position = Options.Position
    end
    if Options.AnchorPoint then
        Badge.AnchorPoint = Options.AnchorPoint
    end
    if Options.LayoutOrder ~= nil then
        Badge.LayoutOrder = Options.LayoutOrder
    end
    Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Badge
    })
    Create("UIStroke", {
        Parent = Badge,
        Color = Color3.fromRGB(112, 112, 120),
        Transparency = 0.28,
        Thickness = 1
    })
    self:ApplyGradient(
        Badge,
        self:GetAccentGradient(),
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.14),
            NumberSequenceKeypoint.new(0.5, 0.02),
            NumberSequenceKeypoint.new(1, 0.14)
        }),
        0
    )
    local Inline = Create("Frame", {
        Name = "Inline",
        Parent = Badge,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, HorizontalPadding, 0, 0),
        Size = UDim2.new(1, -(HorizontalPadding * 2), 1, 0)
    })
    Create("UIListLayout", {
        Parent = Inline,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, Gap),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local Icon = self:CreateRemoteIcon(
        Inline,
        LockData.Icon,
        UDim2.new(0, IconSize, 0, IconSize),
        Color3.fromRGB(245, 245, 245)
    )
    if Icon then
        Icon.LayoutOrder = 1
    end
    Create("TextLabel", {
        Name = "LockText",
        Parent = Inline,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = LockData.Text,
        TextColor3 = Color3.fromRGB(245, 245, 245),
        TextSize = TextSize,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 2
    })
    return Badge
end
function Library:NewWindow(ConfigWindow)
    ConfigWindow = self:MakeConfig({
        Title = "Quantum Hub",
        Description = "By Ho Van Hai",
        Icon = "rbxassetid://89646749075297",
        Logo = "rbxassetid://89646749075297",
        Color = Color3.fromRGB(158, 158, 158),
        Size = UDim2.new(0, 555, 0, 350),
        Theme = "Dark",
        Transparency = 0.06,
        ToggleKey = "RightControl",
    }, ConfigWindow or {})
    self:SetTheme(ConfigWindow.Theme)
    self:SetTransparency(ConfigWindow.Transparency)
    if ConfigWindow.Color then
        self.Theme.Accent = ConfigWindow.Color
    end

    local ScreenGui = Create("ScreenGui", {
        Name = "QuantumUI_V5",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = Player:WaitForChild("PlayerGui")
    })
    local DropShadowHolder = Create("Frame", {
        Name = "DropShadowHolder",
        Parent = ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.585, 0),
        Size = ConfigWindow.Size,
        ZIndex = 1
    })
    Create("ImageLabel", {
        Name = "DropShadow",
        Parent = DropShadowHolder,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 47, 1, 47),
        ZIndex = 0,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450)
    })
    local Main = Create("Frame", {
        Name = "Main",
        Parent = DropShadowHolder,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Main,
        BackgroundTransparency = self.Transparency,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true
    })
    Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Main
    })
    Create("UIStroke", {
        Color = self.Theme.Accent,
        Transparency = 0.45,
        Parent = Main
    })
    local Top = Create("Frame", {
        Name = "Top",
        Parent = Main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 41)
    })
    local Left = Create("Frame", {
        Name = "Left",
        Parent = Top,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -80, 1, 0)
    })
    local NameHub = Create("TextLabel", {
        Name = "NameHub",
        Parent = Left,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 0, 8),
        Size = UDim2.new(1, -28, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = ConfigWindow.Title,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    self:ApplyGradient(NameHub)
    Create("TextLabel", {
        Name = "Desc",
        Parent = Left,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 0, 26),
        Size = UDim2.new(1, -28, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = ConfigWindow.Description,
        TextColor3 = self.Theme.TextDisabled,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    local Right = Create("Frame", {
        Name = "Right",
        Parent = Top,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -74, 0, 0),
        Size = UDim2.new(0, 74, 1, 0)
    })
    Create("UIListLayout", {
        Parent = Right,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })
    Create("UIPadding", {
        Parent = Right,
        PaddingTop = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })
    local function MakeIconButton(Parent, IconId, Size, RectOffset, RectSize)
        local Button = Create("TextButton", {
            Parent = Parent,
            Active = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Selectable = false,
            Size = UDim2.new(0, 24, 0, 24),
            Text = ""
        })
        Create("ImageLabel", {
            Name = "Icon",
            Parent = Button,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = Size,
            Image = IconId,
            ImageRectOffset = RectOffset,
            ImageRectSize = RectSize,
            ImageColor3 = self.Theme.Accent
        })
        return Button
    end
    local Large = MakeIconButton(Right, "rbxassetid://136452605242985", UDim2.new(0, 18, 0, 18), Vector2.new(580, 194), Vector2.new(96, 96))
    local Close = MakeIconButton(Right, "rbxassetid://105957381820378", UDim2.new(0, 20, 0, 20), Vector2.new(480, 0), Vector2.new(96, 96))
    local TabFrame = Create("Frame", {
        Name = "TabFrame",
        Parent = Main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 41),
        Size = UDim2.new(1, 0, 0, 40)
    })
    local SearchFrame = Create("Frame", {
        Name = "SearchFrame",
        Parent = TabFrame,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.95,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 5),
        Size = UDim2.new(0, 120, 0, 30)
    })
    Create("UICorner", {
        CornerRadius = UDim.new(0, 3),
        Parent = SearchFrame
    })
    self:CreateAccentBar(SearchFrame, 6)
    Create("ImageLabel", {
        Name = "IconSearch",
        Parent = SearchFrame,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        Image = "rbxassetid://71309835376233",
        ImageColor3 = self.Theme.Accent
    })
    local SearchBox = Create("TextBox", {
        Name = "SearchBox",
        Parent = SearchFrame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.new(0, 36, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.GothamBold,
        PlaceholderText = "Search.",
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local ScrollingTab = Create("ScrollingFrame", {
        Name = "ScrollingTab",
        Parent = TabFrame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 136, 0, 5),
        Selectable = false,
        Size = UDim2.new(1, -144, 0, 30),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X
    })
    Create("UIPadding", {
        Parent = ScrollingTab,
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })
    local TabList = Create("UIListLayout", {
        Parent = ScrollingTab,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10)
    })
    self:UpdateScrolling(ScrollingTab, TabList, true)
    local LayoutFrame = Create("Frame", {
        Name = "LayoutFrame",
        Parent = Main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 81),
        Size = UDim2.new(1, 0, 1, -81),
        ClipsDescendants = true
    })
    local PagesFolder = Create("Frame", {
        Name = "PagesFolder",
        Parent = LayoutFrame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true
    })
    local DropdownZone = Create("Frame", {
        Name = "DropdownZone",
        Parent = Main,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 20
    })
    local NotifyHolder = Create("Frame", {
        Name = "NotifyHolder",
        Parent = ScreenGui,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -15, 1, -15),
        Size = UDim2.new(0, 320, 1, -30),
        ZIndex = 30
    })
    Create("UIListLayout", {
        Parent = NotifyHolder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom
    })
    Create("UIPadding", {
        Parent = NotifyHolder,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    })
    local FloatingButton = Create("ImageButton", {
        Parent = ScreenGui,
        BackgroundColor3 = self.Theme.Main,
        BackgroundTransparency = self.Transparency,
        BorderSizePixel = 0,
        Position = UDim2.new(0.18, 0, 0.47, 0),
        Size = UDim2.new(0, 56, 0, 56),
        Image = ConfigWindow.Icon,
        ImageColor3 = Color3.new(1, 1, 1),
        Name = "FloatingButton",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10,
        Visible = true
    })
    Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = FloatingButton
    })
    Create("UIStroke", {
        Thickness = 2,
        Color = self.Theme.Accent,
        Parent = FloatingButton
    })
    self:MakeDraggable(Top, DropShadowHolder)
    self:MakeDraggable(FloatingButton, FloatingButton)
    local Window = {
        ScreenGui = ScreenGui,
        Main = Main,
        DropShadowHolder = DropShadowHolder,
        DropdownZone = DropdownZone,
        NotifyHolder = NotifyHolder,
        FloatingButton = FloatingButton,
        Tabs = {},
        CurrentTab = nil
    }
    function Window:OpenOverlay(ContentFrame)
        for _, Child in ipairs(DropdownZone:GetChildren()) do
            if Child ~= ContentFrame and Child:IsA("GuiObject") then
                Child.Visible = false
            end
        end
        DropdownZone.Visible = true
        DropdownZone.BackgroundTransparency = 1
        ContentFrame.Visible = true
        Library:TweenInstance(DropdownZone, 0.2, "BackgroundTransparency", 0.25)
    end
    function Window:CloseOverlay(ContentFrame)
        if ContentFrame then
            ContentFrame.Visible = false
        end
        Library:TweenInstance(DropdownZone, 0.2, "BackgroundTransparency", 1, function()
            local AnyVisible = false
            for _, Child in ipairs(DropdownZone:GetChildren()) do
                if Child:IsA("GuiObject") and Child.Visible then
                    AnyVisible = true
                    break
                end
            end
            if not AnyVisible then
                DropdownZone.Visible = false
            end
        end)
    end
    function Window:Notify(cfnotify)
        cfnotify = Library:MakeConfig({
            Title = "Notification",
            Content = "",
            Duration = 5
        }, cfnotify or {})
        local Width = 300
        local ContentHeight = TextService:GetTextSize(
            cfnotify.Content,
            12,
            Enum.Font.GothamBold,
            Vector2.new(Width - 42, 1000)
        ).Y
        local Height = math.max(74, 50 + ContentHeight)
        local Notification = Create("Frame", {
            Name = "Notification",
            Parent = NotifyHolder,
            BackgroundColor3 = Color3.fromRGB(19, 19, 19),
            BorderSizePixel = 0,
            Size = UDim2.new(0, Width, 0, 0),
            BackgroundTransparency = 0,
            ZIndex = 31,
            LayoutOrder = math.floor(os.clock() * 1000)
        })
        Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = Notification
        })
        local NotifyStroke = Create("UIStroke", {
            Color = Library.Theme.Stroke,
            Transparency = 0.5,
            Parent = Notification
        })
        Library:CreateAccentBar(Notification, 10)
        local TitleNotify = Create("TextLabel", {
            Name = "Title",
            Parent = Notification,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 18, 0, 10),
            Size = UDim2.new(1, -50, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = cfnotify.Title,
            TextColor3 = Library.Theme.Text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 32
        })
        Library:ApplyGradient(TitleNotify)
        local ContentNotify = Create("TextLabel", {
            Name = "Content",
            Parent = Notification,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 18, 0, 34),
            Size = UDim2.new(1, -32, 0, ContentHeight),
            Font = Enum.Font.GothamBold,
            Text = cfnotify.Content,
            TextColor3 = Library.Theme.Text,
            TextTransparency = 0.15,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 32
        })
        local BarBack = Create("Frame", {
            Name = "BarBack",
            Parent = Notification,
            BackgroundColor3 = Library.Theme.Background,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 18, 1, -10),
            Size = UDim2.new(1, -32, 0, 4),
            ZIndex = 32
        })
        Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = BarBack
        })
        local BarFill = Create("Frame", {
            Name = "BarFill",
            Parent = BarBack,
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 33
        })
        Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = BarFill
        })
        Library:ApplyGradient(
            BarFill,
            Library:GetAccentGradient(),
            NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 0.05)
            }),
            0
        )
        local CloseNotify = Create("TextButton", {
            Name = "Close",
            Parent = Notification,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -34, 0, 8),
            Size = UDim2.new(0, 24, 0, 24),
            Text = "",
            ZIndex = 33
        })
        local CloseIcon = Create("ImageLabel", {
            Parent = CloseNotify,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 16, 0, 16),
            Image = "rbxassetid://105957381820378",
            ImageRectOffset = Vector2.new(480, 0),
            ImageRectSize = Vector2.new(96, 96),
            ImageColor3 = Library.Theme.Accent,
            ZIndex = 34
        })
        local Closed = false
        local ProgressTween
        local function CloseNotification()
            if Closed then
                return
            end
            Closed = true
            if ProgressTween then
                ProgressTween:Cancel()
            end
            Library:TweenInstance(Notification, 0.2, "BackgroundTransparency", 1)
            Library:TweenInstance(NotifyStroke, 0.2, "Transparency", 1)
            Library:TweenInstance(TitleNotify, 0.2, "TextTransparency", 1)
            Library:TweenInstance(ContentNotify, 0.2, "TextTransparency", 1)
            Library:TweenInstance(BarBack, 0.2, "BackgroundTransparency", 1)
            Library:TweenInstance(BarFill, 0.2, "BackgroundTransparency", 1)
            Library:TweenInstance(CloseIcon, 0.2, "ImageTransparency", 1)
            Library:TweenInstance(Notification, 0.25, "Size", UDim2.new(0, Width, 0, 0), function()
                Notification:Destroy()
            end)
        end
        CloseNotify.Activated:Connect(CloseNotification)
        Library:TweenInstance(Notification, 0.25, "Size", UDim2.new(0, Width, 0, Height))
        ProgressTween = TweenService:Create(
            BarFill,
            TweenInfo.new(cfnotify.Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 0, 1, 0) }
        )
        ProgressTween:Play()
        task.delay(cfnotify.Duration, CloseNotification)
    end
    local function ToggleWindow()
        DropShadowHolder.Visible = not DropShadowHolder.Visible
        if not DropShadowHolder.Visible then
            DropdownZone.Visible = false
        end
    end
    FloatingButton.MouseButton1Click:Connect(ToggleWindow)
    if ConfigWindow.ToggleKey and ConfigWindow.ToggleKey ~= "" then
        UserInputService.InputBegan:Connect(function(Input, Gpe)
            if Gpe then return end
            if UserInputService:GetFocusedTextBox() then return end
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == tostring(ConfigWindow.ToggleKey) then
                ToggleWindow()
            end
        end)
    end
    Large.MouseButton1Click:Connect(function()
        if DropShadowHolder.Size == ConfigWindow.Size then
            DropShadowHolder.Size = UDim2.new(0, 700, 0, 430)
        else
            DropShadowHolder.Size = ConfigWindow.Size
        end
    end)

    local CloseDialog = Create("Frame", {
        Parent = DropdownZone,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(19, 19, 19),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 400, 0, 150),
        Visible = false,
        ZIndex = 21
    })
    Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = CloseDialog
    })
    Create("UIStroke", {
        Color = self.Theme.Stroke,
        Transparency = 0.5,
        Parent = CloseDialog
    })
    self:CreateAccentBar(CloseDialog, 10)
    local CloseTitle = Create("TextLabel", {
        Parent = CloseDialog,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 0, 12),
        Size = UDim2.new(1, -18, 0, 30),
        Text = "Are you sure",
        TextColor3 = self.Theme.Text,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 22
    })
    self:ApplyGradient(CloseTitle)
    local YesButton = Create("TextButton", {
        Parent = CloseDialog,
        BorderSizePixel = 0,
        TextSize = 25,
        TextColor3 = self.Theme.Text,
        BackgroundColor3 = self.Theme.Accent,
        Font = Enum.Font.GothamBold,
        AnchorPoint = Vector2.new(0, 1),
        Size = UDim2.new(0, 150, 0, 50),
        Position = UDim2.new(0, 40, 1, -40),
        Text = "Yes",
        ZIndex = 22
    })
    Create("UICorner", {
        Parent = YesButton
    })
    Create("UIStroke", {
        Parent = YesButton,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = self.Theme.Stroke
    })
    self:ApplyGradient(
        YesButton,
        self:GetAccentGradient(),
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.1)
        }),
        0
    )
    local NoButton = Create("TextButton", {
        Parent = CloseDialog,
        BorderSizePixel = 0,
        TextSize = 25,
        TextColor3 = self.Theme.Text,
        BackgroundColor3 = self.Theme.Background,
        Font = Enum.Font.GothamBold,
        AnchorPoint = Vector2.new(1, 1),
        Size = UDim2.new(0, 150, 0, 50),
        Position = UDim2.new(1, -40, 1, -40),
        Text = "No",
        ZIndex = 22
    })
    Create("UICorner", {
        Parent = NoButton
    })
    Create("UIStroke", {
        Parent = NoButton,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = self.Theme.Stroke
    })
    Close.MouseButton1Click:Connect(function()
        Window:OpenOverlay(CloseDialog)
    end)
    YesButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    NoButton.MouseButton1Click:Connect(function()
        Window:CloseOverlay(CloseDialog)
    end)
    local AllLayouts = 0
    function Window:T(name, icon)
        local HasIcon = IconModule and icon and icon ~= ""
        local TabWidth = math.max(
            TextService:GetTextSize(name, 13, Enum.Font.GothamBold, Vector2.new(1000, 30)).X + (HasIcon and 42 or 20),
            60
        )
        local TabDisable = Create("Frame", {
            Name = "TabDisable",
            Parent = ScrollingTab,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, TabWidth, 0, 30)
        })
        local Choose = Create("Frame", {
            Name = "Choose",
            Parent = TabDisable,
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -2),
            Size = UDim2.new(0.6, 0, 0, 2),
            Visible = false
        })
        Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Choose
        })
        Library:ApplyGradient(
            Choose,
            Library:GetAccentGradient(),
            NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.08),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 0.08)
            }),
            0
        )
        local TabInline = Create("Frame", {
            Name = "TabInline",
            Parent = TabDisable,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0)
        })
        Create("UIListLayout", {
            Parent = TabInline,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local TabIcon = nil
        if HasIcon then
            TabIcon = Library:CreateRemoteIcon(
                TabInline,
                icon,
                UDim2.new(0, 16, 0, 16),
                Library.Theme.TextDisabled
            )
        end
        local NameTab = Create("TextLabel", {
            Name = "NameTab",
            Parent = TabInline,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = name,
            TextColor3 = Library.Theme.Text,
            TextSize = 13,
            TextTransparency = 0.5,
            TextXAlignment = Enum.TextXAlignment.Center
        })
        local ClickTab = Create("TextButton", {
            Name = "ClickTab",
            Parent = TabDisable,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
            ZIndex = 5
        })
        local Layout = Create("Frame", {
            Name = "Layout",
            Parent = PagesFolder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            LayoutOrder = AllLayouts,
            Visible = false
        })
        Create("UIListLayout", {
            Parent = Layout,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0)
        })
        local function MakeColumn(Name, Order, LeftPadding, RightPadding)
            local Column = Create("ScrollingFrame", {
                Name = Name,
                Parent = Layout,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0.5, 0, 1, 0),
                ScrollBarThickness = 0,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                LayoutOrder = Order
            })
            local List = Create("UIListLayout", {
                Parent = Column,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10)
            })
            List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Column.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 15)
            end)
            Create("UIPadding", {
                Parent = Column,
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, LeftPadding),
                PaddingRight = UDim.new(0, RightPadding)
            })
            return Column
        end
        local LeftColumn = MakeColumn("LeftColumn", 0, 10, 5)
        local RightColumn = MakeColumn("RightColumn", 1, 5, 10)
        local TabData
        local function SelectTab()
            for _, Data in ipairs(Window.Tabs) do
                Data.Layout.Visible = false
                Data.Choose.Visible = false
                Library:TweenInstance(Data.NameTab, 0.2, "TextTransparency", 0.5)
                if Data.Icon then
                    Library:SetIconColor(Data.Icon, Library.Theme.TextDisabled, 0.15)
                end
            end
            Layout.Visible = true
            Choose.Visible = true
            Window.CurrentTab = TabData
            Library:TweenInstance(NameTab, 0.2, "TextTransparency", 0)
            if TabIcon then
                Library:SetIconColor(TabIcon, Library.Theme.Accent, 0)
            end
        end
        ClickTab.Activated:Connect(SelectTab)
        TabData = {
            Name = name,
            Button = TabDisable,
            NameTab = NameTab,
            Choose = Choose,
            Layout = Layout,
            Icon = TabIcon
        }
        table.insert(Window.Tabs, TabData)
        if #Window.Tabs == 1 then
            for _, Data in ipairs(Window.Tabs) do
                Data.Layout.Visible = false
                Data.Choose.Visible = false
                Data.NameTab.TextTransparency = 0.5
                if Data.Icon then
                    Library:SetIconColor(Data.Icon, Library.Theme.TextDisabled, 0.15)
                end
            end
            Layout.Visible = true
            Choose.Visible = true
            NameTab.TextTransparency = 0
            if TabIcon then
                Library:SetIconColor(TabIcon, Library.Theme.Accent, 0)
            end
            Window.CurrentTab = TabData
        end
        AllLayouts = AllLayouts + 1
        local TabFunc = {}
        local function MakeCardBase(Parent, BaseHeight)
            local Card = Create("Frame", {
                Parent = Parent,
                BackgroundColor3 = Library.Theme.Card or Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = Library.Theme.CardTransparency or 0.95,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, BaseHeight)
            })
            Create("UICorner", {
                CornerRadius = UDim.new(0, 3),
                Parent = Card
            })
            Library:CreateAccentBar(Card, 7)
            return Card
        end
        local function MakeGroupbox(RealNameSection, ParentColumn)
            local NoHeader = (RealNameSection == nil or RealNameSection == "")
            local Section = Create("Frame", {
                Name = "Section",
                Parent = ParentColumn,
                BackgroundColor3 = Library.Theme.Section or Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = Library.Theme.SectionTransparency or 0.98,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, NoHeader and 20 or 55)
            })
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = Section
            })
            Create("UIStroke", {
                Color = Library.Theme.Stroke,
                Thickness = 2,
                Transparency = 0.92,
                Parent = Section
            })
            local HeaderH = 0
            if not NoHeader then
                local NameSection = Create("Frame", {
                    Name = "NameSection",
                    Parent = Section,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 34)
                })
                Library:CreateHeaderDecor(NameSection, RealNameSection, 20)
                HeaderH = 36
            end
            local SectionList = Create("Frame", {
                Name = "SectionList",
                Parent = Section,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, HeaderH),
                Size = UDim2.new(1, 0, 1, -HeaderH)
            })
            Create("UIPadding", {
                Parent = SectionList,
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7)
            })
            local SectionListLayout = Create("UIListLayout", {
                Parent = SectionList,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6)
            })
            SectionListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Section.Size = UDim2.new(1, 0, 0, SectionListLayout.AbsoluteContentSize.Y + (NoHeader and 20 or 56))
            end)

            local SectionFunc = {}
            function SectionFunc:AddToggle(cftoggle)
                cftoggle = Library:MakeConfig({
                    Title = "Toggle < Missing Title >",
                    Description = "",
                    Default = false,
                    Locked = false,
                    Lockicon = "lock",
                    Locktext = "premium",
                    Callback = function() end
                }, cftoggle or {})
                local ToggleLock = Library:ResolveLockConfig(cftoggle)
                local Toggle = MakeCardBase(SectionList, 35)
                Toggle.Name = "Toggle"
                local RightOffset = ToggleLock.Locked and 150 or 70
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = Toggle,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -RightOffset, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cftoggle.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local ToggleCheck = Create("Frame", {
                    Name = "ToggleCheck",
                    Parent = Toggle,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -50, 0.5, 0),
                    Size = UDim2.new(0, 40, 0, 22)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = ToggleCheck
                })
                local TrackGradient = Library:ApplyGradient(
                    ToggleCheck,
                    Library:GetAccentGradient(),
                    NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.12),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 0.12)
                    }),
                    0
                )
                TrackGradient.Enabled = false
                local Check = Create("Frame", {
                    Name = "Check",
                    Parent = ToggleCheck,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 3, 0.5, 0),
                    Size = UDim2.new(0, 16, 0, 16)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = Check
                })
                local ToggleClick = Create("TextButton", {
                    Name = "ToggleClick",
                    Parent = Toggle,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })
                local Content = Create("TextLabel", {
                    Name = "Content",
                    Parent = Toggle,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 22),
                    Size = UDim2.new(1, -RightOffset, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cftoggle.Description,
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                })
                local LockBadge = Library:CreateLockBadge(Toggle, ToggleLock, {
                    Position = UDim2.new(1, -58, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Height = 18,
                    TextSize = 10,
                    IconSize = 12
                })
                if ToggleLock.Locked then
                    ToggleCheck.BackgroundColor3 = Color3.fromRGB(44, 44, 48)
                    Check.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
                end
                task.defer(function()
                    Library:UpdateContent(Content, Title, Toggle, 18, RightOffset)
                end)
                local ToggleFunc = { Value = cftoggle.Default, Locked = ToggleLock.Locked }
                function ToggleFunc:Set(Boolean)
                    self.Value = Boolean
                    if Boolean then
                        TrackGradient.Enabled = true
                        Library:TweenInstance(ToggleCheck, 0.25, "BackgroundColor3", Library.Theme.Accent)
                        Library:TweenInstance(Check, 0.25, "Position", UDim2.new(0, 22, 0.5, 0))
                        Library:TweenInstance(Check, 0.25, "BackgroundColor3", Library.Theme.Text)
                    else
                        TrackGradient.Enabled = false
                        Library:TweenInstance(ToggleCheck, 0.25, "BackgroundColor3", ToggleLock.Locked and Color3.fromRGB(44, 44, 48) or Color3.fromRGB(60, 60, 60))
                        Library:TweenInstance(Check, 0.25, "Position", UDim2.new(0, 3, 0.5, 0))
                        Library:TweenInstance(Check, 0.25, "BackgroundColor3", ToggleLock.Locked and Color3.fromRGB(140, 140, 140) or Color3.fromRGB(200, 200, 200))
                    end
                    cftoggle.Callback(Boolean)
                end
                ToggleFunc:Set(ToggleFunc.Value)
                ToggleClick.Activated:Connect(function()
                    if ToggleLock.Locked then
                        Library:PulseLockBadge(LockBadge)
                        return
                    end
                    ToggleFunc:Set(not ToggleFunc.Value)
                end)
                return ToggleFunc
            end
            function SectionFunc:AddButton(cfbutton)
                cfbutton = Library:MakeConfig({
                    Title = "Button < Missing Title >",
                    Description = "",
                    Callback = function() end
                }, cfbutton or {})
                local Button = MakeCardBase(SectionList, 35)
                Button.Name = "Button"
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = Button,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -70, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfbutton.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local ButtonClick = Create("TextButton", {
                    Name = "ButtonClick",
                    Parent = Button,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })
                local Content = Create("TextLabel", {
                    Name = "Content",
                    Parent = Button,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 22),
                    Size = UDim2.new(1, -70, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfbutton.Description,
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                })
                local Arrow = Create("ImageLabel", {
                    Parent = Button,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -35, 0.5, 0),
                    Size = UDim2.new(0, 24, 0, 24),
                    Image = "rbxassetid://85905776508942"
                })
                local ArrowLine = Create("Frame", {
                    Parent = Button,
                    BackgroundColor3 = Library.Theme.Accent,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -48, 0.5, -8),
                    Size = UDim2.new(0, 2, 0, 16)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = ArrowLine
                })
                Library:ApplyGradient(
                    ArrowLine,
                    Library:GetAccentGradient(),
                    NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.12),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 0.12)
                    }),
                    90
                )
                task.defer(function()
                    Library:UpdateContent(Content, Title, Button, 18, 70)
                end)
                ButtonClick.Activated:Connect(function()
                    Button.BackgroundTransparency = 0.92
                    Library:TweenInstance(Arrow, 0.15, "ImageColor3", Library.Theme.Accent)
                    cfbutton.Callback()
                    Library:TweenInstance(Button, 0.2, "BackgroundTransparency", 0.95)
                    task.delay(0.05, function()
                        Library:TweenInstance(Arrow, 0.15, "ImageColor3", Color3.new(1, 1, 1))
                    end)
                end)
            end
            function SectionFunc:AddDropdown(cfdropdown)
                cfdropdown = Library:MakeConfig({
                    Title = "Dropdown",
                    Description = "",
                    Values = {},
                    Default = {},
                    Multi = false,
                    Callback = function() end
                }, cfdropdown or {})
                local Dropdown = MakeCardBase(SectionList, 35)
                Dropdown.Name = "Dropdown"
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = Dropdown,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -100, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfdropdown.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Content = Create("TextLabel", {
                    Name = "Content",
                    Parent = Dropdown,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 22),
                    Size = UDim2.new(1, -100, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfdropdown.Description,
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                })
                local Selects = Create("Frame", {
                    Name = "Selects",
                    Parent = Dropdown,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Library.Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -90, 0.5, 0),
                    Size = UDim2.new(0, 80, 0, 25)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = Selects
                })
                Create("UIStroke", {
                    Parent = Selects,
                    Color = Library.Theme.Stroke,
                    Transparency = 0.6
                })
                local SelectText = Create("TextLabel", {
                    Name = "SelectText",
                    Parent = Selects,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 3, 0, 0),
                    Size = UDim2.new(1, -25, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = "",
                    TextColor3 = Library.Theme.Text,
                    TextScaled = true,
                    TextSize = 1,
                    TextWrapped = true
                })
                Create("UITextSizeConstraint", {
                    Parent = SelectText,
                    MaxTextSize = 12
                })
                local DropClick = Create("TextButton", {
                    Name = "DropClick",
                    Parent = Selects,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })
                Create("ImageLabel", {
                    Parent = Selects,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -20, 0.5, 0),
                    Size = UDim2.new(0, 15, 0, 15),
                    Image = "rbxassetid://80845745785361",
                    ImageColor3 = Library.Theme.Accent
                })
                task.defer(function()
                    Library:UpdateContent(Content, Title, Dropdown, 18, 100)
                end)
                local DropdownList = Create("Frame", {
                    Name = "DropdownList",
                    Parent = DropdownZone,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 400, 0, 250),
                    Visible = false,
                    ZIndex = 21
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = DropdownList
                })
                Create("UIStroke", {
                    Color = Library.Theme.Stroke,
                    Transparency = 0.5,
                    Parent = DropdownList
                })
                Library:CreateAccentBar(DropdownList, 10)
                local Topbar = Create("Frame", {
                    Name = "Topbar",
                    Parent = DropdownList,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 50),
                    ZIndex = 22
                })
                local TopTitle = Create("TextLabel", {
                    Name = "Title",
                    Parent = Topbar,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -210, 1, -5),
                    Font = Enum.Font.GothamBold,
                    Text = cfdropdown.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 14,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 22
                })
                local SearchFrame2 = Create("Frame", {
                    Name = "SearchFrame",
                    Parent = Topbar,
                    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -150, 0, 8),
                    Size = UDim2.new(0, 100, 0, 30),
                    ZIndex = 22
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = SearchFrame2
                })
                Create("UIStroke", {
                    Color = Library.Theme.Stroke,
                    Transparency = 0.74,
                    Parent = SearchFrame2
                })
                Library:CreateAccentBar(SearchFrame2, 6)
                Create("ImageLabel", {
                    Name = "IconSearch",
                    Parent = SearchFrame2,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 16, 0.5, 0),
                    Size = UDim2.new(0, 15, 0, 15),
                    Image = "rbxassetid://71309835376233",
                    ZIndex = 22
                })
                local SearchTextBox = Create("TextBox", {
                    Parent = SearchFrame2,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 35, 0, 0),
                    Size = UDim2.new(1, -35, 1, 0),
                    Font = Enum.Font.GothamBold,
                    PlaceholderText = "Search...",
                    Text = "",
                    TextColor3 = Library.Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 22
                })
                local ClickDropdown = Create("TextButton", {
                    Name = "ClickDropdown",
                    Parent = Topbar,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -40, 0, 8),
                    Size = UDim2.new(0, 30, 0, 30),
                    Text = "",
                    ZIndex = 22
                })
                Create("ImageLabel", {
                    Name = "Icon",
                    Parent = ClickDropdown,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 20, 0, 20),
                    Image = "rbxassetid://105957381820378",
                    ImageRectOffset = Vector2.new(480, 0),
                    ImageRectSize = Vector2.new(96, 96),
                    ZIndex = 23
                })
                local RealList = Create("ScrollingFrame", {
                    Name = "RealList",
                    Parent = DropdownList,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 10, 0, 50),
                    Selectable = false,
                    ScrollBarThickness = 0,
                    Size = UDim2.new(1, -20, 1, -60),
                    ZIndex = 22
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = RealList
                })
                local RealListLayout = Create("UIListLayout", {
                    Parent = RealList,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5)
                })
                Create("UIPadding", {
                    Parent = RealList,
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7)
                })
                Library:UpdateScrolling(RealList, RealListLayout, false)
                local DropFunc = { Value = {} }
                local function NormalizeDefault(Value)
                    if typeof(Value) == "string" then
                        return Value == "" and {} or { Value }
                    elseif typeof(Value) == "table" then
                        return Value
                    end
                    return {}
                end
                function DropFunc:Set(Value)
                    self.Value = NormalizeDefault(Value)
                    for _, Item in ipairs(RealList:GetChildren()) do
                        if Item:IsA("Frame") and Item:FindFirstChild("Title") then
                            local Selected = table.find(self.Value, Item.Title.Text) ~= nil
                            Library:TweenInstance(Item, 0.2, "BackgroundTransparency", Selected and 0.9 or 0.98)
                            Library:TweenInstance(Item.Title, 0.2, "TextTransparency", Selected and 0 or 0.5)
                        end
                    end
                    local Joined = table.concat(self.Value, ", ")
                    SelectText.Text = Joined
                    if cfdropdown.Multi then
                        cfdropdown.Callback(self.Value)
                    else
                        cfdropdown.Callback(self.Value[1] or "")
                    end
                end
                function DropFunc:Add(Value)
                    local Option = Create("Frame", {
                        Name = "Option",
                        Parent = RealList,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0.98,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 35),
                        ZIndex = 22
                    })
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = Option
                    })
                    Library:CreateAccentBar(Option, 7)
                    local OptionClick = Create("TextButton", {
                        Name = "OptionClick",
                        Parent = Option,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        ZIndex = 23
                    })
                    local OptionTitle = Create("TextLabel", {
                        Name = "Title",
                        Parent = Option,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 18, 0, 0),
                        Size = UDim2.new(1, -18, 1, 0),
                        Font = Enum.Font.GothamBold,
                        Text = tostring(Value),
                        TextColor3 = Library.Theme.Text,
                        TextSize = 13,
                        TextTransparency = 0.5,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 23
                    })
                    OptionClick.Activated:Connect(function()
                        if cfdropdown.Multi then
                            local Exists = table.find(DropFunc.Value, OptionTitle.Text)
                            if Exists then
                                table.remove(DropFunc.Value, Exists)
                            else
                                table.insert(DropFunc.Value, OptionTitle.Text)
                            end
                            DropFunc:Set(DropFunc.Value)
                        else
                            DropFunc:Set({ OptionTitle.Text })
                            Window:CloseOverlay(DropdownList)
                        end
                    end)
                end
                function DropFunc:Clear()
                    for _, Item in ipairs(RealList:GetChildren()) do
                        if Item:IsA("Frame") then
                            Item:Destroy()
                        end
                    end
                end
                function DropFunc:Refresh(NewList)
                    self:Clear()
                    for _, Value in ipairs(NewList) do
                        self:Add(Value)
                    end
                    self:Set(self.Value)
                end
                SearchTextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local Query = SearchTextBox.Text:lower()
                    for _, Item in ipairs(RealList:GetChildren()) do
                        if Item:IsA("Frame") and Item:FindFirstChild("Title") then
                            Item.Visible = Query == "" or string.find(Item.Title.Text:lower(), Query, 1, true) ~= nil
                        end
                    end
                end)
                DropClick.Activated:Connect(function()
                    Window:OpenOverlay(DropdownList)
                end)
                ClickDropdown.Activated:Connect(function()
                    Window:CloseOverlay(DropdownList)
                end)
                DropFunc.Value = NormalizeDefault(cfdropdown.Default)
                DropFunc:Refresh(cfdropdown.Values)
                DropFunc:Set(DropFunc.Value)
                return DropFunc
            end
            function SectionFunc:AddInput(cftextbox)
                cftextbox = Library:MakeConfig({
                    Title = "Textbox",
                    Description = "",
                    PlaceHolder = "",
                    Default = "",
                    Callback = function() end
                }, cftextbox or {})
                local Input = MakeCardBase(SectionList, 35)
                Input.Name = "Input"
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = Input,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -150, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cftextbox.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Content = Create("TextLabel", {
                    Name = "Content",
                    Parent = Input,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 22),
                    Size = UDim2.new(1, -160, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cftextbox.Description,
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                })
                local TextboxFrame = Create("Frame", {
                    Name = "TextboxFrame",
                    Parent = Input,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Library.Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -140, 0.5, 0),
                    Size = UDim2.new(0, 130, 0, 28)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 3),
                    Parent = TextboxFrame
                })
                Create("UIStroke", {
                    Parent = TextboxFrame,
                    Color = Library.Theme.Stroke,
                    Transparency = 0.55
                })
                Library:CreateAccentBar(TextboxFrame, 6)
                local RealTextBox = Create("TextBox", {
                    Name = "RealTextBox",
                    Parent = TextboxFrame,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 35, 0, 0),
                    Size = UDim2.new(1, -35, 1, 0),
                    Font = Enum.Font.GothamBold,
                    PlaceholderText = cftextbox.PlaceHolder,
                    Text = cftextbox.Default,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                Create("ImageLabel", {
                    Name = "WritingIcon",
                    Parent = TextboxFrame,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 14, 0.5, 0),
                    Size = UDim2.new(0, 15, 0, 15),
                    Image = "rbxassetid://126409600467363"
                })
                task.defer(function()
                    Library:UpdateContent(Content, Title, Input, 18, 150)
                end)
                RealTextBox.FocusLost:Connect(function()
                    cftextbox.Callback(RealTextBox.Text)
                end)
                cftextbox.Callback(RealTextBox.Text)
                return {
                    Set = function(_, Value)
                        RealTextBox.Text = tostring(Value)
                        cftextbox.Callback(RealTextBox.Text)
                    end
                }
            end
            function SectionFunc:AddSlider(cfslider)
                cfslider = Library:MakeConfig({
                    Title = "Slider < Missing Title >",
                    Description = "",
                    Max = 100,
                    Min = 1,
                    Increment = 1,
                    Default = 1,
                    Locked = false,
                    Lockicon = "lock",
                    Locktext = "premium",
                    Callback = function() end
                }, cfslider or {})
                local SliderLock = Library:ResolveLockConfig(cfslider)
                local Slider = MakeCardBase(SectionList, 56)
                Slider.Name = "Slider"
                local TitleRight = SliderLock.Locked and 170 or 70
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = Slider,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 5),
                    Size = UDim2.new(1, -TitleRight, 0, 18),
                    Font = Enum.Font.GothamBold,
                    Text = cfslider.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Content = Create("TextLabel", {
                    Name = "Content",
                    Parent = Slider,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 22),
                    Size = UDim2.new(1, -TitleRight, 0, 14),
                    Font = Enum.Font.GothamBold,
                    Text = cfslider.Description,
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                })
                local SliderValue = Create("TextBox", {
                    Name = "SliderValue",
                    Parent = Slider,
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = Library.Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -8, 0, 5),
                    Size = UDim2.new(0, 42, 0, 20),
                    Font = Enum.Font.GothamBold,
                    PlaceholderColor3 = Color3.fromRGB(178, 178, 178),
                    PlaceholderText = "...",
                    Text = "",
                    TextColor3 = Library.Theme.Text,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Center
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = SliderValue
                })
                Create("UIStroke", {
                    Parent = SliderValue,
                    Color = Library.Theme.Accent,
                    Transparency = 0.45
                })
                local SliderFrame = Create("Frame", {
                    Name = "SliderFrame",
                    Parent = Slider,
                    BackgroundColor3 = Library.Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 38),
                    Size = UDim2.new(1, -26, 0, 8)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = SliderFrame
                })
                local SliderDraggable = Create("Frame", {
                    Name = "SliderDraggable",
                    Parent = SliderFrame,
                    BackgroundColor3 = Library.Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 20, 1, 0)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = SliderDraggable
                })
                Library:ApplyGradient(
                    SliderDraggable,
                    Library:GetAccentGradient(),
                    NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.05),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 0.05)
                    }),
                    0
                )
                local Circle = Create("Frame", {
                    Name = "Circle",
                    Parent = SliderDraggable,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Library.Theme.Text,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 12, 0, 12)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = Circle
                })
                Create("UIStroke", {
                    Parent = Circle,
                    Color = Library.Theme.Accent,
                    Transparency = 0.2,
                    Thickness = 1.5
                })
                local LockBadge = Library:CreateLockBadge(Slider, SliderLock, {
                    Position = UDim2.new(1, -58, 0, 6),
                    AnchorPoint = Vector2.new(1, 0),
                    Height = 18,
                    TextSize = 10,
                    IconSize = 12
                })
                if SliderLock.Locked then
                    SliderFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
                    SliderValue.TextColor3 = Color3.fromRGB(170, 170, 170)
                end
                local SliderFunc = { Value = cfslider.Default, Locked = SliderLock.Locked }
                local Dragging = false
                local function Round(Number, Factor)
                    return math.floor(Number / Factor + 0.5) * Factor
                end
                function SliderFunc:Set(Value)
                    Value = math.clamp(Round(Value, cfslider.Increment), cfslider.Min, cfslider.Max)
                    SliderFunc.Value = Value
                    SliderValue.Text = tostring(Value)
                    local Range = cfslider.Max - cfslider.Min
                    local Scale = Range == 0 and 0 or ((Value - cfslider.Min) / Range)
                    TweenService:Create(
                        SliderDraggable,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Size = UDim2.fromScale(Scale, 1) }
                    ):Play()
                    cfslider.Callback(Value)
                end
                local function UpdateSliderFromInput(InputPosition)
                    local Scale = math.clamp((InputPosition.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
                    SliderFunc:Set(cfslider.Min + ((cfslider.Max - cfslider.Min) * Scale))
                end
                SliderFrame.InputBegan:Connect(function(Input)
                    if SliderLock.Locked then
                        Library:PulseLockBadge(LockBadge)
                        return
                    end
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
                        UpdateSliderFromInput(Input.Position)
                    end
                end)
                SliderFrame.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(Input)
                    if SliderLock.Locked then
                        return
                    end
                    if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSliderFromInput(Input.Position)
                    end
                end)
                UserInputService.TouchMoved:Connect(function(Input)
                    if SliderLock.Locked then
                        return
                    end
                    if Dragging then
                        UpdateSliderFromInput(Input.Position)
                    end
                end)
                SliderValue:GetPropertyChangedSignal("Text"):Connect(function()
                    if SliderLock.Locked then
                        return
                    end
                    local Digits = SliderValue.Text:gsub("[^%d]", "")
                    if SliderValue.Text ~= Digits then
                        SliderValue.Text = Digits
                    end
                end)
                SliderValue.Focused:Connect(function()
                    if SliderLock.Locked then
                        Library:PulseLockBadge(LockBadge)
                        task.defer(function()
                            SliderValue:ReleaseFocus()
                        end)
                    end
                end)
                SliderValue.FocusLost:Connect(function()
                    if SliderLock.Locked then
                        SliderValue.Text = tostring(SliderFunc.Value)
                        return
                    end
                    local Number = tonumber(SliderValue.Text)
                    SliderFunc:Set(Number or cfslider.Min)
                end)
                SliderFunc:Set(tonumber(cfslider.Default) or cfslider.Min)
                return SliderFunc
            end
            function SectionFunc:AddColorPicker(cfcolorpicker)
                cfcolorpicker = Library:MakeConfig({
                    Title = "Color Picker",
                    Description = "",
                    Default = Color3.fromRGB(255, 255, 255),
                    Presets = {
                        Color3.fromRGB(255, 60, 60),
                        Color3.fromRGB(255, 170, 60),
                        Color3.fromRGB(255, 230, 60),
                        Color3.fromRGB(75, 255, 120),
                        Color3.fromRGB(60, 180, 255),
                        Color3.fromRGB(150, 95, 255),
                        Color3.fromRGB(255, 95, 200),
                        Color3.fromRGB(255, 255, 255)
                    },
                    Callback = function() end
                }, cfcolorpicker or {})
                local ColorPicker = MakeCardBase(SectionList, 45)
                ColorPicker.Name = "ColorPicker"
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = ColorPicker,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -90, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfcolorpicker.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Content = Create("TextLabel", {
                    Name = "Content",
                    Parent = ColorPicker,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 22),
                    Size = UDim2.new(1, -90, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfcolorpicker.Description,
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                })
                local ColorPreview = Create("Frame", {
                    Name = "ColorPreview",
                    Parent = ColorPicker,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -54, 0.5, 0),
                    Size = UDim2.new(0, 34, 0, 34)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 10),
                    Parent = ColorPreview
                })
                Create("UIStroke", {
                    Parent = ColorPreview,
                    Color = Color3.fromRGB(255, 255, 255),
                    Transparency = 0.65,
                    Thickness = 1.2
                })
                local ColorClick = Create("TextButton", {
                    Name = "ColorClick",
                    Parent = ColorPicker,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })
                task.defer(function()
                    Library:UpdateContent(Content, Title, ColorPicker, 18, 90)
                end)
                local PickerOverlay = Create("Frame", {
                    Name = "ColorPickerOverlay",
                    Parent = DropdownZone,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 430, 0, 292),
                    Visible = false,
                    ZIndex = 21
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = PickerOverlay
                })
                Create("UIStroke", {
                    Parent = PickerOverlay,
                    Color = Library.Theme.Stroke,
                    Transparency = 0.45,
                    Thickness = 1.2
                })
                Library:CreateAccentBar(PickerOverlay, 10)
                local PickerTitle = Create("TextLabel", {
                    Name = "PickerTitle",
                    Parent = PickerOverlay,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 10),
                    Size = UDim2.new(1, -60, 0, 22),
                    Font = Enum.Font.GothamBold,
                    Text = cfcolorpicker.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 22
                })
                local PickerDescription = Create("TextLabel", {
                    Name = "PickerDescription",
                    Parent = PickerOverlay,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 32),
                    Size = UDim2.new(1, -60, 0, 18),
                    Font = Enum.Font.GothamBold,
                    Text = cfcolorpicker.Description ~= "" and cfcolorpicker.Description or "Choose a custom color",
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 22
                })
                local ClosePicker = Create("TextButton", {
                    Name = "ClosePicker",
                    Parent = PickerOverlay,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -38, 0, 10),
                    Size = UDim2.new(0, 24, 0, 24),
                    Font = Enum.Font.GothamBold,
                    Text = "Ã—",
                    TextColor3 = Library.Theme.Text,
                    TextSize = 20,
                    ZIndex = 23
                })
                local SatValFrame = Create("Frame", {
                    Name = "SatValFrame",
                    Parent = PickerOverlay,
                    BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 62),
                    Size = UDim2.new(0, 228, 0, 152),
                    ZIndex = 22
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = SatValFrame
                })
                local WhiteFade = Create("Frame", {
                    Name = "WhiteFade",
                    Parent = SatValFrame,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 22
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = WhiteFade
                })
                Create("UIGradient", {
                    Parent = WhiteFade,
                    Rotation = 0,
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                })
                local BlackFade = Create("Frame", {
                    Name = "BlackFade",
                    Parent = SatValFrame,
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 22
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = BlackFade
                })
                Create("UIGradient", {
                    Parent = BlackFade,
                    Rotation = 90,
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0)
                    })
                })
                Create("UIStroke", {
                    Parent = SatValFrame,
                    Color = Color3.fromRGB(255, 255, 255),
                    Transparency = 0.82,
                    Thickness = 1
                })
                local SatValKnob = Create("Frame", {
                    Name = "SatValKnob",
                    Parent = SatValFrame,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    ZIndex = 23
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = SatValKnob
                })
                Create("UIStroke", {
                    Parent = SatValKnob,
                    Color = Color3.fromRGB(0, 0, 0),
                    Transparency = 0.3,
                    Thickness = 1.4
                })
                local HueFrame = Create("Frame", {
                    Name = "HueFrame",
                    Parent = PickerOverlay,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 258, 0, 62),
                    Size = UDim2.new(0, 18, 0, 152),
                    ZIndex = 22
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = HueFrame
                })
                Create("UIGradient", {
                    Parent = HueFrame,
                    Rotation = 90,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.82, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                    })
                })
                Create("UIStroke", {
                    Parent = HueFrame,
                    Color = Color3.fromRGB(255, 255, 255),
                    Transparency = 0.82,
                    Thickness = 1
                })
                local HueKnob = Create("Frame", {
                    Name = "HueKnob",
                    Parent = HueFrame,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(1, 6, 0, 4),
                    ZIndex = 23
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = HueKnob
                })
                local PreviewFrame = Create("Frame", {
                    Name = "PreviewFrame",
                    Parent = PickerOverlay,
                    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 292, 0, 62),
                    Size = UDim2.new(0, 120, 0, 68),
                    ZIndex = 22
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = PreviewFrame
                })
                Create("UIStroke", {
                    Parent = PreviewFrame,
                    Color = Library.Theme.Stroke,
                    Transparency = 0.45
                })
                local PreviewFill = Create("Frame", {
                    Name = "PreviewFill",
                    Parent = PreviewFrame,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 8, 0, 8),
                    Size = UDim2.new(1, -16, 0, 32),
                    ZIndex = 22
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = PreviewFill
                })
                local PreviewHex = Create("TextLabel", {
                    Name = "PreviewHex",
                    Parent = PreviewFrame,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 8, 0, 45),
                    Size = UDim2.new(1, -16, 0, 16),
                    Font = Enum.Font.GothamBold,
                    Text = "",
                    TextColor3 = Library.Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 22
                })
                local HexFrame = Create("Frame", {
                    Name = "HexFrame",
                    Parent = PickerOverlay,
                    BackgroundColor3 = Library.Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 292, 0, 140),
                    Size = UDim2.new(0, 120, 0, 30),
                    ZIndex = 22
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = HexFrame
                })
                Create("UIStroke", {
                    Parent = HexFrame,
                    Color = Library.Theme.Stroke,
                    Transparency = 0.45
                })
                local HexInput = Create("TextBox", {
                    Name = "HexInput",
                    Parent = HexFrame,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    Font = Enum.Font.GothamBold,
                    PlaceholderText = "#FFFFFF",
                    Text = "",
                    TextColor3 = Library.Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 23
                })
                local PresetLabel = Create("TextLabel", {
                    Name = "PresetLabel",
                    Parent = PickerOverlay,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 226),
                    Size = UDim2.new(1, -36, 0, 16),
                    Font = Enum.Font.GothamBold,
                    Text = "Presets",
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 22
                })
                local PresetScroll = Create("ScrollingFrame", {
                    Name = "PresetScroll",
                    Parent = PickerOverlay,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 248),
                    Size = UDim2.new(1, -36, 0, 28),
                    ScrollBarThickness = 0,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ZIndex = 22
                })
                local PresetLayout = Create("UIListLayout", {
                    Parent = PresetScroll,
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 8)
                })
                Library:UpdateScrolling(PresetScroll, PresetLayout, true)
                local PickerFunc = {}
                local DragMode = nil
                local function ResolveColor(Value)
                    if typeof(Value) == "Color3" then
                        return Value
                    end
                    if typeof(Value) == "string" then
                        return Library:HexToColor3(Value)
                    end
                    return nil
                end
                local InitialColor = ResolveColor(cfcolorpicker.Default) or Color3.fromRGB(255, 255, 255)
                local Hue, Sat, Val = InitialColor:ToHSV()
                PickerFunc.Value = InitialColor
                local function ApplyFromPosition(Frame, Position)
                    local X = math.clamp((Position.X - Frame.AbsolutePosition.X) / Frame.AbsoluteSize.X, 0, 1)
                    local Y = math.clamp((Position.Y - Frame.AbsolutePosition.Y) / Frame.AbsoluteSize.Y, 0, 1)
                    return X, Y
                end
                local function UpdateColor()
                    local CurrentColor = Color3.fromHSV(Hue, Sat, Val)
                    PickerFunc.Value = CurrentColor
                    ColorPreview.BackgroundColor3 = CurrentColor
                    PreviewFill.BackgroundColor3 = CurrentColor
                    PreviewHex.Text = Library:Color3ToHex(CurrentColor)
                    HexInput.Text = PreviewHex.Text
                    SatValFrame.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
                    SatValKnob.Position = UDim2.new(Sat, 0, 1 - Val, 0)
                    HueKnob.Position = UDim2.new(0.5, 0, 1 - Hue, 0)
                    cfcolorpicker.Callback(CurrentColor)
                end
                function PickerFunc:Set(Value)
                    local CurrentColor = ResolveColor(Value)
                    if not CurrentColor then
                        return
                    end
                    Hue, Sat, Val = CurrentColor:ToHSV()
                    UpdateColor()
                end
                function PickerFunc:Get()
                    return self.Value
                end
                function PickerFunc:GetHex()
                    return Library:Color3ToHex(self.Value)
                end
                function PickerFunc:SetTitle(Value)
                    local Text = tostring(Value)
                    Title.Text = Text
                    PickerTitle.Text = Text
                end
                function PickerFunc:SetDescription(Value)
                    local Text = tostring(Value)
                    Content.Text = Text
                    PickerDescription.Text = Text ~= "" and Text or "Choose a custom color"
                    task.defer(function()
                        Library:UpdateContent(Content, Title, ColorPicker, 18, 90)
                    end)
                end
                for _, PresetColor in ipairs(cfcolorpicker.Presets) do
                    local Swatch = Create("TextButton", {
                        Name = "Swatch",
                        Parent = PresetScroll,
                        BackgroundColor3 = PresetColor,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, 28, 0, 28),
                        Text = "",
                        ZIndex = 23
                    })
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 8),
                        Parent = Swatch
                    })
                    Create("UIStroke", {
                        Parent = Swatch,
                        Color = Color3.fromRGB(255, 255, 255),
                        Transparency = 0.62,
                        Thickness = 1
                    })
                    Swatch.Activated:Connect(function()
                        PickerFunc:Set(PresetColor)
                    end)
                end
                SatValFrame.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DragMode = "SV"
                        local X, Y = ApplyFromPosition(SatValFrame, Input.Position)
                        Sat = X
                        Val = 1 - Y
                        UpdateColor()
                    end
                end)
                HueFrame.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DragMode = "H"
                        local _, Y = ApplyFromPosition(HueFrame, Input.Position)
                        Hue = 1 - Y
                        UpdateColor()
                    end
                end)
                UserInputService.InputChanged:Connect(function(Input)
                    if DragMode == "SV" and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                        local X, Y = ApplyFromPosition(SatValFrame, Input.Position)
                        Sat = X
                        Val = 1 - Y
                        UpdateColor()
                    elseif DragMode == "H" and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                        local _, Y = ApplyFromPosition(HueFrame, Input.Position)
                        Hue = 1 - Y
                        UpdateColor()
                    end
                end)
                UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DragMode = nil
                    end
                end)
                HexInput:GetPropertyChangedSignal("Text"):Connect(function()
                    local Filtered = HexInput.Text:upper():gsub("[^#%x]", "")
                    if #Filtered > 7 then
                        Filtered = Filtered:sub(1, 7)
                    end
                    if HexInput.Text ~= Filtered then
                        HexInput.Text = Filtered
                    end
                end)
                HexInput.FocusLost:Connect(function()
                    local Converted = ResolveColor(HexInput.Text)
                    if Converted then
                        PickerFunc:Set(Converted)
                    else
                        HexInput.Text = PickerFunc:GetHex()
                    end
                end)
                ColorClick.Activated:Connect(function()
                    Window:OpenOverlay(PickerOverlay)
                end)
                ClosePicker.Activated:Connect(function()
                    Window:CloseOverlay(PickerOverlay)
                end)
                PickerFunc:Set(InitialColor)
                return PickerFunc
            end
            function SectionFunc:AddImage(Name, cfimage)
                if typeof(Name) == "table" then
                    cfimage = Name
                    Name = cfimage.Title or cfimage.Name or "Image"
                end
                cfimage = Library:MakeConfig({
                    Image = "",
                    Height = 200
                }, cfimage or {})
                local ImageTitle = tostring(Name or "Image")
                local ImageHeight = math.max(40, tonumber(cfimage.Height) or 200)
                local ImageCard = MakeCardBase(SectionList, ImageHeight + 42)
                ImageCard.Name = "Image"
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = ImageCard,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 8),
                    Size = UDim2.new(1, -36, 0, 16),
                    Font = Enum.Font.GothamBold,
                    Text = ImageTitle,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local ImageFrame = Create("Frame", {
                    Name = "ImageFrame",
                    Parent = ImageCard,
                    BackgroundColor3 = Color3.fromRGB(14, 14, 14),
                    BackgroundTransparency = 0.04,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 30),
                    Size = UDim2.new(1, -36, 0, ImageHeight)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ImageFrame
                })
                Create("UIStroke", {
                    Parent = ImageFrame,
                    Color = Color3.fromRGB(55, 55, 55),
                    Transparency = 0.2,
                    Thickness = 1
                })
                local ImageLabel = Create("ImageLabel", {
                    Name = "ImageLabel",
                    Parent = ImageFrame,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Image = tostring(cfimage.Image or ""),
                    ScaleType = Enum.ScaleType.Fit
                })
                local ImageFunc = {}
                function ImageFunc:SetImage(Value)
                    ImageLabel.Image = tostring(Value or "")
                end
                function ImageFunc:SetHeight(Value)
                    local NewHeight = math.max(40, tonumber(Value) or ImageHeight)
                    ImageHeight = NewHeight
                    ImageFrame.Size = UDim2.new(1, -36, 0, NewHeight)
                    ImageCard.Size = UDim2.new(1, 0, 0, NewHeight + 42)
                end
                function ImageFunc:SetTitle(Value)
                    Title.Text = tostring(Value or "")
                end
                function ImageFunc:Destroy()
                    ImageCard:Destroy()
                end
                return ImageFunc
            end
            function SectionFunc:AddSeperator(args)
                local Seperator = Create("Frame", {
                    Name = "Seperator",
                    Parent = SectionList,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 24)
                })
                local _, Title = Library:CreateHeaderDecor(Seperator, tostring(args or ""), 20)
                local DividerFunc = {}
                function DividerFunc:SetTitle(Value)
                    Title.Text = tostring(Value or "")
                end
                function DividerFunc:Destroy()
                    Seperator:Destroy()
                end
                return DividerFunc
            end
            function SectionFunc:AddDivider(args)
                return self:AddSeperator(args)
            end
            function SectionFunc:AddParagraph(cfpara)
                cfpara = Library:MakeConfig({
                    Title = "Paragraph < Missing Title >",
                    Content = ""
                }, cfpara or {})
                local Paragraph = MakeCardBase(SectionList, 72)
                Paragraph.Name = "Paragraph"
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = Paragraph,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 7),
                    Size = UDim2.new(1, -18, 0, 16),
                    Font = Enum.Font.GothamBold,
                    Text = cfpara.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local ContentFrame = Create("Frame", {
                    Name = "ContentFrame",
                    Parent = Paragraph,
                    BackgroundColor3 = Color3.fromRGB(14, 14, 14),
                    BackgroundTransparency = 0.08,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 28),
                    Size = UDim2.new(1, -36, 0, 34)
                })
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ContentFrame
                })
                Create("UIStroke", {
                    Parent = ContentFrame,
                    Color = Color3.fromRGB(55, 55, 55),
                    Transparency = 0.25,
                    Thickness = 1
                })
                local Content = Create("TextLabel", {
                    Name = "Content",
                    Parent = ContentFrame,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 10, 0, 8),
                    Size = UDim2.new(1, -20, 1, -16),
                    Font = Enum.Font.GothamBold,
                    Text = cfpara.Content,
                    TextColor3 = Color3.fromRGB(185, 185, 185),
                    TextSize = 12,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                })
                local function UpdateParagraph()
                    local Text = Content.Text or ""
                    local Width = ContentFrame.AbsoluteSize.X > 0 and (ContentFrame.AbsoluteSize.X - 20) or 220
                    local Height = TextService:GetTextSize(
                        Text,
                        Content.TextSize,
                        Content.Font,
                        Vector2.new(Width, 1000)
                    ).Y
                    local BoxHeight = math.max(34, Height + 16)
                    ContentFrame.Size = UDim2.new(1, -36, 0, BoxHeight)
                    Content.Size = UDim2.new(1, -20, 0, Height)
                    Paragraph.Size = UDim2.new(1, 0, 0, BoxHeight + 38)
                end
                task.defer(UpdateParagraph)
                local ParaFunc = {}
                function ParaFunc:SetTitle(args)
                    Title.Text = args
                end
                function ParaFunc:SetDesc(args)
                    Content.Text = args
                    task.defer(UpdateParagraph)
                end
                return ParaFunc
            end
            function SectionFunc:AddKeybind(cfkey)
                cfkey = Library:MakeConfig({
                    Title = "Keybind",
                    Description = "",
                    Default = "F",
                    Locked = false,
                    Locktext = "premium",
                    Lockicon = "lock",
                    Callback = function() end
                }, cfkey or {})
                local KeyLock = Library:ResolveLockConfig(cfkey)
                local Keybind = MakeCardBase(SectionList, 35)
                Keybind.Name = "Keybind"
                local RightOffset = KeyLock.Locked and 150 or 90
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = Keybind,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -RightOffset, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfkey.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Content = Create("TextLabel", {
                    Name = "Content",
                    Parent = Keybind,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 22),
                    Size = UDim2.new(1, -RightOffset, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfkey.Description,
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                })
                local KeyBox = Create("TextButton", {
                    Name = "KeyBox",
                    Parent = Keybind,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Library.Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.new(0, 70, 0, 24),
                    Text = "",
                    AutoButtonColor = false
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = KeyBox})
                Create("UIStroke", {Parent = KeyBox, Color = Library.Theme.Stroke, Transparency = 0.5})
                local KeyText = Create("TextLabel", {
                    Parent = KeyBox,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = tostring(cfkey.Default),
                    TextColor3 = Library.Theme.Text,
                    TextSize = 12
                })
                local LockBadge = Library:CreateLockBadge(Keybind, KeyLock, {
                    Position = UDim2.new(1, -90, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Height = 18,
                    TextSize = 10,
                    IconSize = 12
                })
                task.defer(function()
                    Library:UpdateContent(Content, Title, Keybind, 18, RightOffset)
                end)
                local KeyFunc = {Value = tostring(cfkey.Default), Picking = false, Locked = KeyLock.Locked}
                function KeyFunc:Set(Value)
                    self.Value = tostring(Value)
                    KeyText.Text = self.Value
                end
                KeyBox.Activated:Connect(function()
                    if KeyLock.Locked then
                        Library:PulseLockBadge(LockBadge)
                        return
                    end
                    if KeyFunc.Picking then return end
                    KeyFunc.Picking = true
                    KeyText.Text = "..."
                    local Conn
                    Conn = UserInputService.InputBegan:Connect(function(Input, Gpe)
                        if Gpe then return end
                        if Input.UserInputType == Enum.UserInputType.Keyboard then
                            if Input.KeyCode == Enum.KeyCode.Escape then
                                KeyText.Text = KeyFunc.Value
                                KeyFunc.Picking = false
                                Conn:Disconnect()
                                return
                            end
                            KeyFunc:Set(Input.KeyCode.Name)
                            KeyFunc.Picking = false
                            Conn:Disconnect()
                            cfkey.Callback(KeyFunc.Value)
                        end
                    end)
                end)
                UserInputService.InputBegan:Connect(function(Input, Gpe)
                    if Gpe or KeyFunc.Picking or KeyLock.Locked then return end
                    if UserInputService:GetFocusedTextBox() then return end
                    if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KeyFunc.Value then
                        cfkey.Callback(KeyFunc.Value)
                    end
                end)
                return KeyFunc
            end
            function SectionFunc:AddTag(cftag)
                cftag = Library:MakeConfig({
                    Title = "Tag",
                    Color = Color3.fromRGB(80, 200, 120),
                    TextColor = Color3.fromRGB(20, 20, 25)
                }, cftag or {})
                local TagHolder = Create("Frame", {
                    Name = "TagHolder",
                    Parent = SectionList,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 28)
                })
                local TagText = tostring(cftag.Title or "Tag")
                local TextWidth = TextService:GetTextSize(TagText, 12, Enum.Font.GothamBold, Vector2.new(1000, 28)).X
                local Tag = Create("Frame", {
                    Name = "Tag",
                    Parent = TagHolder,
                    BackgroundColor3 = cftag.Color,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, math.max(48, TextWidth + 22), 0, 24),
                    Position = UDim2.new(0, 10, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5)
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Tag})
                Create("TextLabel", {
                    Parent = Tag,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = TagText,
                    TextColor3 = cftag.TextColor,
                    TextSize = 12
                })
                local TagFunc = {}
                function TagFunc:SetTitle(v)
                    local t = tostring(v or "")
                    Tag:FindFirstChildOfClass("TextLabel").Text = t
                    local w = TextService:GetTextSize(t, 12, Enum.Font.GothamBold, Vector2.new(1000, 28)).X
                    Tag.Size = UDim2.new(0, math.max(48, w + 22), 0, 24)
                end
                function TagFunc:SetColor(c)
                    if typeof(c) == "Color3" then
                        Tag.BackgroundColor3 = c
                    end
                end
                function TagFunc:Destroy()
                    TagHolder:Destroy()
                end
                return TagFunc
            end
            return SectionFunc
        end
        function TabFunc:AddLeftGroupbox(SectionName)
            return MakeGroupbox(SectionName, LeftColumn)
        end
        function TabFunc:AddRightGroupbox(SectionName)
            return MakeGroupbox(SectionName, RightColumn)
        end
        function TabFunc:AddSection(SectionName)
            return MakeGroupbox(SectionName, LeftColumn)
        end
        local DefaultSection = MakeGroupbox("", LeftColumn)
        function TabFunc:AddToggle(cfg) return DefaultSection:AddToggle(cfg) end
        function TabFunc:AddButton(cfg) return DefaultSection:AddButton(cfg) end
        function TabFunc:AddDropdown(cfg) return DefaultSection:AddDropdown(cfg) end
        function TabFunc:AddInput(cfg) return DefaultSection:AddInput(cfg) end
        function TabFunc:AddSlider(cfg) return DefaultSection:AddSlider(cfg) end
        function TabFunc:AddColorPicker(cfg) return DefaultSection:AddColorPicker(cfg) end
        function TabFunc:AddImage(name, cfg) return DefaultSection:AddImage(name, cfg) end
        function TabFunc:AddSeperator(args) return DefaultSection:AddSeperator(args) end
        function TabFunc:AddDivider(args) return DefaultSection:AddDivider(args) end
        function TabFunc:AddParagraph(cfg) return DefaultSection:AddParagraph(cfg) end
        function TabFunc:AddKeybind(cfg) return DefaultSection:AddKeybind(cfg) end
        function TabFunc:AddTag(cfg) return DefaultSection:AddTag(cfg) end
        return TabFunc
    end


    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local Query = SearchBox.Text:lower()
        for _, TabData in ipairs(Window.Tabs) do
            TabData.Button.Visible = Query == "" or string.find(TabData.Name:lower(), Query, 1, true) ~= nil
        end
    end)
    return Window
end
return Library
