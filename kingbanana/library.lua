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
Library.ThemeObjects = {}
Library.ActiveWindows = {}
function Library:RegisterThemeObject(Object, Property, ThemeKey)
    if not Object or not Property or not ThemeKey then return end
    table.insert(self.ThemeObjects, {Object = Object, Property = Property, ThemeKey = ThemeKey})
end
function Library:ApplyThemeToObject(Entry)
    if not Entry or not Entry.Object or not Entry.Object.Parent then return end
    local Value = self.Theme[Entry.ThemeKey]
    if Value == nil then return end
    pcall(function()
        Entry.Object[Entry.Property] = Value
    end)
end
function Library:SetTheme(Name)
    Name = tostring(Name or "Dark")
    if not self.Themes[Name] then
        Name = "Dark"
    end
    self.CurrentTheme = Name
    self.Theme = self.Themes[Name]
    for i = #self.ThemeObjects, 1, -1 do
        local Entry = self.ThemeObjects[i]
        if not Entry.Object or not Entry.Object.Parent then
            table.remove(self.ThemeObjects, i)
        else
            self:ApplyThemeToObject(Entry)
        end
    end
    for _, Win in ipairs(self.ActiveWindows) do
        if Win and Win.Main and Win.Main.Parent then
            pcall(function()
                Win.Main.BackgroundColor3 = self.Theme.Main
                Win.Main.BackgroundTransparency = self.Transparency
            end)
            if Win.FloatingButton and Win.FloatingButton.Parent then
                pcall(function()
                    Win.FloatingButton.BackgroundColor3 = self.Theme.Main
                    Win.FloatingButton.BackgroundTransparency = self.Transparency
                end)
            end
        end
    end
    return self.Theme
end
function Library:SetTransparency(Value)
    Value = math.clamp(tonumber(Value) or 0.06, 0, 0.9)
    self.Transparency = Value
    for _, Win in ipairs(self.ActiveWindows) do
        if Win and Win.Main and Win.Main.Parent then
            pcall(function()
                Win.Main.BackgroundTransparency = Value
            end)
            if Win.FloatingButton and Win.FloatingButton.Parent then
                pcall(function()
                    Win.FloatingButton.BackgroundTransparency = Value
                end)
            end
        end
    end
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
Library.ConfigBinds = {}
function Library:BindConfig(Flag, Element)
    if not Flag or Flag == "" or not Element then return end
    self.ConfigBinds[tostring(Flag)] = Element
end
function Library:SaveConfig(FileName)
    FileName = tostring(FileName or "kingbanana_config")
    local ok = pcall(function()
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
            local el = self.ConfigBinds[tostring(k)]
            if el then
                pcall(function()
                    if el.Set then
                        el:Set(v)
                    elseif el.SetValue then
                        el:SetValue(v)
                    end
                end)
            end
        end
        return true
    end
    return false
end
function Library:ApplyConfigFlags()
    for k, v in pairs(self.Flags) do
        local el = self.ConfigBinds[tostring(k)]
        if el and el.Set then
            pcall(function() el:Set(v) end)
        end
    end
end

function Library:CreateCustomTheme(Name, Colors)
    if type(Name) ~= "string" or type(Colors) ~= "table" then return end
    local Base = {}
    for k, v in pairs(self.Themes.Dark) do
        Base[k] = v
    end
    for k, v in pairs(Colors) do
        Base[k] = v
    end
    self.Themes[Name] = Base
    return Base
end
function Library:ExportTheme(Name)
    Name = Name or self.CurrentTheme
    local t = self.Themes[Name] or self.Theme
    local out = {}
    for k, v in pairs(t) do
        if typeof(v) == "Color3" then
            out[k] = {math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5)}
        else
            out[k] = v
        end
    end
    local json = game:GetService("HttpService"):JSONEncode(out)
    pcall(function()
        if setclipboard then setclipboard(json) elseif toclipboard then toclipboard(json) end
    end)
    return json
end
function Library:ImportTheme(Name, Data)
    if type(Data) == "string" then
        local ok, decoded = pcall(function()
            return game:GetService("HttpService"):JSONDecode(Data)
        end)
        if ok then Data = decoded end
    end
    if type(Data) ~= "table" then return end
    local colors = {}
    for k, v in pairs(Data) do
        if type(v) == "table" and #v >= 3 then
            colors[k] = Color3.fromRGB(v[1], v[2], v[3])
        else
            colors[k] = v
        end
    end
    return self:CreateCustomTheme(Name or "Imported", colors)
end
Library.Keybinds = {}
function Library:RegisterKeybind(Key, Callback)
    Key = tostring(Key)
    self.Keybinds[Key] = Callback
end
function Library:UnregisterKeybind(Key)
    self.Keybinds[tostring(Key)] = nil
end
UserInputService.InputBegan:Connect(function(Input, Gpe)
    if Gpe or UserInputService:GetFocusedTextBox() then return end
    if Input.UserInputType == Enum.UserInputType.Keyboard then
        local cb = Library.Keybinds[Input.KeyCode.Name]
        if cb then pcall(cb, Input.KeyCode.Name) end
    end
end)
function Library:KeySystem(Config)
    Config = self:MakeConfig({
        Title = "KingBanana",
        Subtitle = "Key System",
        Note = "Enter your key to continue",
        Placeholder = "Banana",
        GetKeyText = "Get Key",
        VerifyText = "Verify Key",
        GetKeyLink = "",
        Key = "Banana",
        Keys = {"Banana"},
        SaveKey = true,
        FileName = "kb_key",
        Callback = function() end,
        OnFail = function() end
    }, Config or {})

    local Gui = Create("ScreenGui", {
        Name = "KB_KeySystem",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = Player:WaitForChild("PlayerGui")
    })
    local Holder = Create("Frame", {
        Parent = Gui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.Theme.Main,
        BorderSizePixel = 0
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Holder})
    Create("UIStroke", {Parent = Holder, Color = self.Theme.Accent, Transparency = 0.4})
    Create("TextLabel", {
        Parent = Holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 14),
        Size = UDim2.new(1, -36, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = Config.Title,
        TextColor3 = self.Theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Create("TextLabel", {
        Parent = Holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 38),
        Size = UDim2.new(1, -36, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = Config.Subtitle,
        TextColor3 = self.Theme.TextDisabled,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Create("TextLabel", {
        Parent = Holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 64),
        Size = UDim2.new(1, -36, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = Config.Note,
        TextColor3 = self.Theme.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local BoxFrame = Create("Frame", {
        Parent = Holder,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 0, 92),
        Size = UDim2.new(1, -36, 0, 36)
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = BoxFrame})
    Create("UIStroke", {Parent = BoxFrame, Color = self.Theme.Stroke, Transparency = 0.45})
    local KeyBox = Create("TextBox", {
        Parent = BoxFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Font = Enum.Font.GothamBold,
        PlaceholderText = Config.Placeholder,
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    local GetBtn = Create("TextButton", {
        Parent = Holder,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 0, 140),
        Size = UDim2.new(1, -36, 0, 34),
        Font = Enum.Font.GothamBold,
        Text = Config.GetKeyText,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        AutoButtonColor = false
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = GetBtn})
    Create("UIStroke", {Parent = GetBtn, Color = self.Theme.Stroke, Transparency = 0.45})
    local VerifyBtn = Create("TextButton", {
        Parent = Holder,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 0, 182),
        Size = UDim2.new(1, -36, 0, 36),
        Font = Enum.Font.GothamBold,
        Text = Config.VerifyText,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 14,
        AutoButtonColor = false
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = VerifyBtn})
    local Status = Create("TextLabel", {
        Parent = Holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 224),
        Size = UDim2.new(1, -36, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = self.Theme.TextDisabled,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local function ValidKey(k)
        k = tostring(k or ""):gsub("%s+", "")
        if k == "" then return false end
        if Config.Key ~= "" and k == tostring(Config.Key) then return true end
        for _, v in ipairs(Config.Keys or {}) do
            if k == tostring(v) then return true end
        end
        return false
    end
    local function Finish()
        Library:TweenInstance(Holder, 0.2, "Size", UDim2.new(0, 0, 0, 0), function()
            Gui:Destroy()
        end)
        Config.Callback(KeyBox.Text)
    end
    if Config.SaveKey and isfile and readfile then
        pcall(function()
            if isfile(Config.FileName .. ".txt") then
                local saved = readfile(Config.FileName .. ".txt")
                if ValidKey(saved) then
                    KeyBox.Text = saved
                    Finish()
                    return
                end
            end
        end)
    end
    GetBtn.Activated:Connect(function()
        if Config.GetKeyLink and Config.GetKeyLink ~= "" then
            pcall(function()
                if setclipboard then setclipboard(Config.GetKeyLink)
                elseif toclipboard then toclipboard(Config.GetKeyLink) end
            end)
            Status.Text = "Link copied"
            Status.TextColor3 = Color3.fromRGB(80, 200, 120)
        else
            Status.Text = "No get-key link set"
            Status.TextColor3 = Color3.fromRGB(255, 190, 60)
        end
    end)
    VerifyBtn.Activated:Connect(function()
        if ValidKey(KeyBox.Text) then
            if Config.SaveKey and writefile then
                pcall(function() writefile(Config.FileName .. ".txt", KeyBox.Text) end)
            end
            Status.Text = "Verified"
            Status.TextColor3 = Color3.fromRGB(80, 200, 120)
            task.delay(0.35, Finish)
        else
            Status.Text = "Invalid key"
            Status.TextColor3 = Color3.fromRGB(255, 80, 80)
            Config.OnFail(KeyBox.Text)
        end
    end)
    Library:TweenInstance(Holder, 0.28, "Size", UDim2.new(0, 340, 0, 260))
    return Gui
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
    local MainStroke = Create("UIStroke", {
        Color = self.Theme.Accent,
        Transparency = 0.45,
        Parent = Main
    })
    self:RegisterThemeObject(Main, "BackgroundColor3", "Main")
    self:RegisterThemeObject(MainStroke, "Color", "Accent")

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
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.GothamBold,
        Text = ConfigWindow.Title,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    self:ApplyGradient(NameHub)
    local TitleTags = Create("Frame", {
        Name = "TitleTags",
        Parent = Left,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 0, 6),
        Size = UDim2.new(1, -40, 0, 22)
    })
    Create("UIListLayout", {
        Parent = TitleTags,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {
        Parent = TitleTags,
        PaddingLeft = UDim.new(0, 0)
    })
    task.defer(function()
        local titleW = NameHub.TextBounds.X
        TitleTags.Position = UDim2.new(0, 18 + titleW + 18, 0, 7)
    end)
    NameHub:GetPropertyChangedSignal("TextBounds"):Connect(function()
        TitleTags.Position = UDim2.new(0, 18 + NameHub.TextBounds.X + 18, 0, 7)
    end)

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
    local DragGrip = Create("Frame", {
        Name = "DragGrip",
        Parent = Main,
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = Color3.fromRGB(120, 120, 128),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 1, -6),
        Size = UDim2.new(0, 48, 0, 4),
        ZIndex = 50
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = DragGrip})
    self:MakeDraggable(DragGrip, DropShadowHolder)
    self:MakeDraggable(FloatingButton, FloatingButton)
    local ResizeHandle = Create("Frame", {
        Name = "ResizeHandle",
        Parent = Main,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(140, 140, 150),
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -4, 1, -4),
        Size = UDim2.new(0, 14, 0, 14),
        ZIndex = 50
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = ResizeHandle})
    do
        local Resizing = false
        local StartPos, StartSize
        local MinW, MinH = 420, 280
        ResizeHandle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Resizing = true
                StartPos = Input.Position
                StartSize = DropShadowHolder.AbsoluteSize
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Resizing = false
                    end
                end)
            end
        end)
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
    local Window = {

        ScreenGui = ScreenGui,
        Main = Main,
        DropShadowHolder = DropShadowHolder,
        DropdownZone = DropdownZone,
        NotifyHolder = NotifyHolder,
        FloatingButton = FloatingButton,
        Tabs = {},
        CurrentTab = nil,
        TitleTags = TitleTags
    }
    table.insert(self.ActiveWindows, Window)
    self:RegisterThemeObject(NameHub, "TextColor3", "Text")

    function Window:AddTag(cftag)
        cftag = Library:MakeConfig({
            Title = "Tag",
            Color = Color3.fromRGB(80, 200, 120),
            TextColor = Color3.fromRGB(20, 20, 25)
        }, cftag or {})
        local TagText = tostring(cftag.Title or "Tag")
        local TextWidth = TextService:GetTextSize(TagText, 11, Enum.Font.GothamBold, Vector2.new(1000, 22)).X
        local Tag = Create("Frame", {
            Name = "Tag",
            Parent = TitleTags,
            BackgroundColor3 = cftag.Color,
            BorderSizePixel = 0,
            Size = UDim2.new(0, math.max(40, TextWidth + 16), 0, 18),
            LayoutOrder = #TitleTags:GetChildren()
        })
        Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Tag})
        Create("TextLabel", {
            Parent = Tag,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = TagText,
            TextColor3 = cftag.TextColor,
            TextSize = 11
        })
        local TagFunc = {}
        function TagFunc:SetTitle(v)
            local t = tostring(v or "")
            Tag:FindFirstChildOfClass("TextLabel").Text = t
            local w = TextService:GetTextSize(t, 11, Enum.Font.GothamBold, Vector2.new(1000, 22)).X
            Tag.Size = UDim2.new(0, math.max(40, w + 16), 0, 18)
        end
        function TagFunc:SetColor(c)
            if typeof(c) == "Color3" then Tag.BackgroundColor3 = c end
        end
        function TagFunc:Destroy()
            Tag:Destroy()
        end
        return TagFunc
    end
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
            Duration = 5,
            Type = "Info"
        }, cfnotify or {})
        local TypeColors = {
            Info = Library.Theme.Accent,
            Success = Color3.fromRGB(80, 200, 120),
            Warning = Color3.fromRGB(255, 190, 60),
            Error = Color3.fromRGB(255, 80, 80)
        }
        local AccentCol = TypeColors[cfnotify.Type] or TypeColors.Info
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
            Color = AccentCol,
            Transparency = 0.35,
            Parent = Notification
        })
        local AccentBarN = Library:CreateAccentBar(Notification, 10)
        if AccentBarN then
            AccentBarN.BackgroundColor3 = AccentCol
        end

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
        if DropShadowHolder.Visible then
            Library:TweenInstance(DropShadowHolder, 0.2, "Size", UDim2.new(0, 0, 0, 0), function()
                DropShadowHolder.Visible = false
                DropdownZone.Visible = false
            end)
        else
            DropShadowHolder.Visible = true
            DropShadowHolder.Size = UDim2.new(0, 0, 0, 0)
            Library:TweenInstance(DropShadowHolder, 0.28, "Size", ConfigWindow.Size)
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
            if Window.CurrentTab == TabData then return end
            for _, Data in ipairs(Window.Tabs) do
                Data.Choose.Visible = false
                Library:TweenInstance(Data.NameTab, 0.15, "TextTransparency", 0.5)
                if Data.Icon then
                    Library:SetIconColor(Data.Icon, Library.Theme.TextDisabled, 0.15)
                end
                if Data.Layout and Data.Layout ~= Layout then
                    Data.Layout.Visible = false
                    Data.Layout.Position = UDim2.new(0, 0, 0, 0)
                end
            end
            Layout.Visible = true
            Layout.Position = UDim2.new(0, 0, 0, 24)
            Library:TweenInstance(Layout, 0.22, "Position", UDim2.new(0, 0, 0, 0))
            Choose.Visible = true
            Window.CurrentTab = TabData
            Library:TweenInstance(NameTab, 0.15, "TextTransparency", 0)
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
            Library:RegisterThemeObject(Card, "BackgroundColor3", "Card")
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
            Library:RegisterThemeObject(Section, "BackgroundColor3", "Section")

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
                    Flag = "",
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
                        Library:TweenInstance(ToggleCheck, 0.2, "BackgroundColor3", Library.Theme.Accent)
                        Library:TweenInstance(Check, 0.2, "Position", UDim2.new(0, 22, 0.5, 0))
                        Library:TweenInstance(Check, 0.2, "BackgroundColor3", Library.Theme.Text)
                    else
                        TrackGradient.Enabled = false
                        Library:TweenInstance(ToggleCheck, 0.2, "BackgroundColor3", ToggleLock.Locked and Color3.fromRGB(44, 44, 48) or Color3.fromRGB(60, 60, 60))
                        Library:TweenInstance(Check, 0.2, "Position", UDim2.new(0, 3, 0.5, 0))
                        Library:TweenInstance(Check, 0.2, "BackgroundColor3", ToggleLock.Locked and Color3.fromRGB(140, 140, 140) or Color3.fromRGB(200, 200, 200))
                    end
                    if cftoggle.Flag and cftoggle.Flag ~= "" then
                        Library:SetFlag(cftoggle.Flag, Boolean)
                    end
                    cftoggle.Callback(Boolean)
                end
                if cftoggle.Flag and cftoggle.Flag ~= "" then
                    Library:BindConfig(cftoggle.Flag, ToggleFunc)
                    if Library.Flags[cftoggle.Flag] ~= nil then
                        ToggleFunc.Value = Library.Flags[cftoggle.Flag]
                    end
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
                    Flag = "",
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
                    if cfdropdown.Multi then
                        local n = #self.Value
                        SelectText.Text = n == 0 and "None" or (n == 1 and self.Value[1] or (n .. " selected"))
                    else
                        SelectText.Text = table.concat(self.Value, ", ")
                    end

                    if cfdropdown.Flag and cfdropdown.Flag ~= "" then
                        Library:SetFlag(cfdropdown.Flag, cfdropdown.Multi and self.Value or (self.Value[1] or ""))
                    end
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
                if cfdropdown.Flag and cfdropdown.Flag ~= "" then
                    Library:BindConfig(cfdropdown.Flag, DropFunc)
                    if Library.Flags[cfdropdown.Flag] ~= nil then
                        DropFunc.Value = NormalizeDefault(Library.Flags[cfdropdown.Flag])
                    end
                end
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
                    HueKnob.Position = UDim2.new(0.5, 0, Hue, 0)

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
                        Hue = Y
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
                        Hue = Y
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
                    Height = 200,
                    Button = nil,
                    ButtonText = "Open",
                    Callback = function() end
                }, cfimage or {})
                local ImageTitle = tostring(Name or "Image")
                local ImageHeight = math.max(40, tonumber(cfimage.Height) or 200)
                local HasBtn = cfimage.Button ~= nil or (cfimage.ButtonText and cfimage.Callback)
                local Extra = HasBtn and 40 or 0
                local ImageCard = MakeCardBase(SectionList, ImageHeight + 42 + Extra)
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
                if HasBtn then
                    local Btn = Create("TextButton", {
                        Parent = ImageCard,
                        BackgroundColor3 = Library.Theme.Background,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 18, 0, 36 + ImageHeight),
                        Size = UDim2.new(1, -36, 0, 30),
                        Font = Enum.Font.GothamBold,
                        Text = tostring(cfimage.Button or cfimage.ButtonText or "Open"),
                        TextColor3 = Library.Theme.Text,
                        TextSize = 12,
                        AutoButtonColor = false
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Btn})
                    Create("UIStroke", {Parent = Btn, Color = Library.Theme.Stroke, Transparency = 0.5})
                    Btn.Activated:Connect(function()
                        if cfimage.Callback then cfimage.Callback() end
                    end)
                end
                local ImageFunc = {}
                function ImageFunc:SetImage(Value)
                    ImageLabel.Image = tostring(Value or "")
                end
                function ImageFunc:SetHeight(Value)
                    local NewHeight = math.max(40, tonumber(Value) or ImageHeight)
                    ImageHeight = NewHeight
                    ImageFrame.Size = UDim2.new(1, -36, 0, NewHeight)
                    ImageCard.Size = UDim2.new(1, 0, 0, NewHeight + 42 + Extra)
                end
                function ImageFunc:SetTitle(Value)
                    Title.Text = tostring(Value or "")
                end
                function ImageFunc:Destroy()
                    ImageCard:Destroy()
                end
                return ImageFunc
            end
            function SectionFunc:AddColorToggle(cfct)
                cfct = Library:MakeConfig({
                    Title = "Color Toggle",
                    Description = "",
                    Default = false,
                    Color = Color3.fromRGB(80, 180, 255),
                    Flag = "",
                    Callback = function() end
                }, cfct or {})
                local Card = MakeCardBase(SectionList, 35)
                Card.Name = "ColorToggle"
                Create("TextLabel", {
                    Name = "Title",
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -100, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfct.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Presets = cfct.Presets or {
                    Color3.fromRGB(255, 60, 60),
                    Color3.fromRGB(255, 170, 60),
                    Color3.fromRGB(80, 220, 120),
                    Color3.fromRGB(80, 180, 255),
                    Color3.fromRGB(160, 100, 255),
                    Color3.fromRGB(255, 95, 200),
                    Color3.fromRGB(255, 255, 255)
                }
                local Swatch = Create("TextButton", {
                    Parent = Card,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = cfct.Color,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -58, 0.5, 0),
                    Size = UDim2.new(0, 18, 0, 18),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 6
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Swatch})
                Create("UIStroke", {Parent = Swatch, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.6, Thickness = 1})
                local Track = Create("TextButton", {
                    Parent = Card,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.new(0, 40, 0, 22),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 6
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Track})
                local Knob = Create("Frame", {
                    Parent = Track,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 3, 0.5, 0),
                    Size = UDim2.new(0, 16, 0, 16),
                    ZIndex = 7
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Knob})
                local Click = Create("TextButton", {
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -90, 1, 0),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 5
                })
                local CTFunc = { Value = cfct.Default, Color = cfct.Color, PresetIndex = 1 }
                function CTFunc:Set(Boolean)
                    self.Value = Boolean and true or false
                    if self.Value then
                        Library:TweenInstance(Track, 0.2, "BackgroundColor3", self.Color)
                        Library:TweenInstance(Knob, 0.2, "Position", UDim2.new(0, 22, 0.5, 0))
                        Library:TweenInstance(Knob, 0.2, "BackgroundColor3", Color3.new(1, 1, 1))
                    else
                        Library:TweenInstance(Track, 0.2, "BackgroundColor3", Color3.fromRGB(60, 60, 60))
                        Library:TweenInstance(Knob, 0.2, "Position", UDim2.new(0, 3, 0.5, 0))
                        Library:TweenInstance(Knob, 0.2, "BackgroundColor3", Color3.fromRGB(200, 200, 200))
                    end
                    if cfct.Flag and cfct.Flag ~= "" then
                        Library:SetFlag(cfct.Flag, self.Value)
                    end
                    cfct.Callback(self.Value, self.Color)
                end
                function CTFunc:SetColor(c)
                    if typeof(c) == "Color3" then
                        self.Color = c
                        Swatch.BackgroundColor3 = c
                        if self.Value then
                            Track.BackgroundColor3 = c
                        end
                        cfct.Callback(self.Value, self.Color)
                    end
                end
                if cfct.Flag and cfct.Flag ~= "" then
                    Library:BindConfig(cfct.Flag, CTFunc)
                    if Library.Flags[cfct.Flag] ~= nil then
                        CTFunc.Value = Library.Flags[cfct.Flag]
                    end
                end
                CTFunc:Set(CTFunc.Value)
                local function ToggleOnly()
                    CTFunc:Set(not CTFunc.Value)
                end
                Click.Activated:Connect(ToggleOnly)
                Track.Activated:Connect(ToggleOnly)
                Swatch.Activated:Connect(function()
                    CTFunc.PresetIndex = (CTFunc.PresetIndex % #Presets) + 1
                    CTFunc:SetColor(Presets[CTFunc.PresetIndex])
                end)
                return CTFunc
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
            function SectionFunc:AddMultiButton(cfmb)
                cfmb = Library:MakeConfig({
                    Title = "Button Section",
                    Opened = true,
                    Buttons = {}
                }, cfmb or {})
                local Opened = cfmb.Opened ~= false
                local Card = MakeCardBase(SectionList, 35)
                Card.Name = "MultiButton"
                local Header = Create("TextButton", {
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    Text = "",
                    AutoButtonColor = false
                })
                Create("TextLabel", {
                    Name = "Title",
                    Parent = Header,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -50, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cfmb.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Arrow = Create("TextLabel", {
                    Parent = Header,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -28, 0, 0),
                    Size = UDim2.new(0, 20, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = Opened and "v" or ">",
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12
                })
                local Body = Create("Frame", {
                    Name = "Body",
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 34),
                    Size = UDim2.new(1, -20, 0, 0),
                    Visible = Opened
                })
                local BtnList = {}
                local function MakeBtn(parent, title, full, callback)
                    local Btn = Create("TextButton", {
                        Parent = parent,
                        BackgroundColor3 = Library.Theme.Background,
                        BorderSizePixel = 0,
                        Size = full and UDim2.new(1, 0, 0, 30) or UDim2.new(0.5, -4, 0, 30),
                        Font = Enum.Font.GothamBold,
                        Text = tostring(title or "Button"),
                        TextColor3 = Library.Theme.Text,
                        TextSize = 12,
                        AutoButtonColor = false
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Btn})
                    Create("UIStroke", {Parent = Btn, Color = Library.Theme.Stroke, Transparency = 0.55})
                    Btn.Activated:Connect(function()
                        if callback then callback() end
                    end)
                    table.insert(BtnList, Btn)
                    return Btn
                end
                local function RefreshSize()
                    if not Opened then
                        Body.Size = UDim2.new(1, -20, 0, 0)
                        Card.Size = UDim2.new(1, 0, 0, 35)
                        Arrow.Text = ">"
                        return
                    end
                    local count = #BtnList
                    local h = 0
                    if count >= 1 then h = h + 36 end
                    if count > 1 then
                        local rows = math.ceil((count - 1) / 2)
                        h = h + rows * 36
                    end
                    Body.Size = UDim2.new(1, -20, 0, h)
                    Card.Size = UDim2.new(1, 0, 0, 38 + h)
                    Arrow.Text = "v"
                    for i, Btn in ipairs(BtnList) do
                        if i == 1 then
                            Btn.Size = UDim2.new(1, 0, 0, 30)
                            Btn.Position = UDim2.new(0, 0, 0, 0)
                        else
                            local idx = i - 2
                            local row = math.floor(idx / 2)
                            local col = idx % 2
                            Btn.Size = UDim2.new(0.5, -4, 0, 30)
                            Btn.Position = UDim2.new(col * 0.5, col > 0 and 4 or 0, 0, 36 + row * 36)
                        end
                    end
                end
                for _, B in ipairs(cfmb.Buttons) do
                    MakeBtn(Body, B.Title, false, B.Callback)
                end
                Header.Activated:Connect(function()
                    Opened = not Opened
                    Body.Visible = Opened
                    RefreshSize()
                end)
                task.defer(RefreshSize)
                local MBFunc = {}
                function MBFunc:AddButton(title, callback)
                    MakeBtn(Body, title, false, callback)
                    RefreshSize()
                end
                return MBFunc
            end
            function SectionFunc:AddCodeBox(cfcode)
                cfcode = Library:MakeConfig({
                    Title = "Code",
                    Code = "-- code",
                    Height = 120
                }, cfcode or {})
                local Height = math.max(60, tonumber(cfcode.Height) or 120)
                local Card = MakeCardBase(SectionList, Height + 42)
                Card.Name = "CodeBox"
                Create("TextLabel", {
                    Name = "Title",
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 18, 0, 6),
                    Size = UDim2.new(1, -90, 0, 18),
                    Font = Enum.Font.GothamBold,
                    Text = cfcode.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local CopyBtn = Create("TextButton", {
                    Parent = Card,
                    BackgroundColor3 = Library.Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -70, 0, 6),
                    Size = UDim2.new(0, 58, 0, 20),
                    Font = Enum.Font.GothamBold,
                    Text = "Copy",
                    TextColor3 = Library.Theme.Text,
                    TextSize = 11,
                    AutoButtonColor = false
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = CopyBtn})
                local Box = Create("Frame", {
                    Parent = Card,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 14),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 30),
                    Size = UDim2.new(1, -24, 0, Height)
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Box})
                Create("UIStroke", {Parent = Box, Color = Library.Theme.Stroke, Transparency = 0.5})
                local CodeLabel = Create("TextBox", {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 8, 0, 6),
                    Size = UDim2.new(1, -16, 1, -12),
                    Font = Enum.Font.Code,
                    Text = tostring(cfcode.Code or ""),
                    TextColor3 = Color3.fromRGB(200, 200, 210),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    ClearTextOnFocus = false,
                    MultiLine = true,
                    TextEditable = false
                })
                CopyBtn.Activated:Connect(function()
                    local text = CodeLabel.Text
                    pcall(function()
                        if setclipboard then setclipboard(text)
                        elseif toclipboard then toclipboard(text) end
                    end)
                    CopyBtn.Text = "Copied"
                    task.delay(1.2, function()
                        if CopyBtn and CopyBtn.Parent then CopyBtn.Text = "Copy" end
                    end)
                end)
                local CodeFunc = {}
                function CodeFunc:SetCode(v)
                    CodeLabel.Text = tostring(v or "")
                end
                function CodeFunc:GetCode()
                    return CodeLabel.Text
                end
                return CodeFunc
            end
            function SectionFunc:AddProgressBar(cfprog)
                cfprog = Library:MakeConfig({
                    Title = "Progress",
                    Value = 0,
                    Min = 0,
                    Max = 100
                }, cfprog or {})
                local Card = MakeCardBase(SectionList, 48)
                Card.Name = "ProgressBar"
                Create("TextLabel", {
                    Name = "Title",
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 18, 0, 4),
                    Size = UDim2.new(1, -70, 0, 16),
                    Font = Enum.Font.GothamBold,
                    Text = cfprog.Title,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local ValueLabel = Create("TextLabel", {
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -55, 0, 4),
                    Size = UDim2.new(0, 45, 0, 16),
                    Font = Enum.Font.GothamBold,
                    Text = "0%",
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right
                })
                local Track = Create("Frame", {
                    Parent = Card,
                    BackgroundColor3 = Library.Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 18, 0, 28),
                    Size = UDim2.new(1, -36, 0, 10)
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Track})
                local Fill = Create("Frame", {
                    Parent = Track,
                    BackgroundColor3 = Library.Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0)
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Fill})
                Library:ApplyGradient(Fill, Library:GetAccentGradient(), nil, 0)
                local ProgFunc = {Value = cfprog.Value or 0}
                function ProgFunc:Set(v)
                    local min, max = cfprog.Min or 0, cfprog.Max or 100
                    v = math.clamp(tonumber(v) or 0, min, max)
                    self.Value = v
                    local scale = (max == min) and 0 or ((v - min) / (max - min))
                    Library:TweenInstance(Fill, 0.2, "Size", UDim2.new(scale, 0, 1, 0))
                    ValueLabel.Text = math.floor(scale * 100 + 0.5) .. "%"
                end
                ProgFunc:Set(cfprog.Value or 0)
                return ProgFunc
            end
            function SectionFunc:AddLabel(cflabel)
                cflabel = Library:MakeConfig({
                    Title = "Label",
                    Content = ""
                }, cflabel or {})
                local Card = MakeCardBase(SectionList, 28)
                Card.Name = "Label"
                local Title = Create("TextLabel", {
                    Name = "Title",
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 18, 0, 0),
                    Size = UDim2.new(1, -24, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = cflabel.Content ~= "" and (cflabel.Title .. ": " .. cflabel.Content) or cflabel.Title,
                    TextColor3 = Library.Theme.TextDisabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local LabelFunc = {}
                function LabelFunc:Set(text)
                    Title.Text = tostring(text or "")
                end
                function LabelFunc:SetTitle(t)
                    Title.Text = tostring(t or "")
                end
                return LabelFunc
            end
            function SectionFunc:AddPlayerDropdown(cfplay)
                local players = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    table.insert(players, p.Name)
                end
                cfplay = Library:MakeConfig({
                    Title = "Player",
                    Description = "",
                    Values = players,
                    Default = {},
                    Multi = false,
                    Callback = function() end
                }, cfplay or {})
                if not cfplay.Values or #cfplay.Values == 0 then
                    cfplay.Values = players
                end
                local Drop = SectionFunc:AddDropdown(cfplay)
                local function RefreshPlayers()
                    local list = {}
                    for _, p in ipairs(Players:GetPlayers()) do
                        table.insert(list, p.Name)
                    end
                    if Drop and Drop.Refresh then
                        Drop:Refresh(list)
                    end
                end
                Players.PlayerAdded:Connect(RefreshPlayers)
                Players.PlayerRemoving:Connect(RefreshPlayers)
                return Drop
            end
            return SectionFunc
        end


        local LeftSection = MakeGroupbox("", LeftColumn)

        local RightSection = MakeGroupbox("", RightColumn)
        local function ResolveSection(cfg)
            cfg = cfg or {}
            local pos = string.lower(tostring(cfg.Position or "left"))
            if pos == "right" then return RightSection end
            return LeftSection
        end
        function TabFunc:AddToggle(cfg) return ResolveSection(cfg):AddToggle(cfg) end
        function TabFunc:AddButton(cfg) return ResolveSection(cfg):AddButton(cfg) end
        function TabFunc:AddDropdown(cfg) return ResolveSection(cfg):AddDropdown(cfg) end
        function TabFunc:AddInput(cfg) return ResolveSection(cfg):AddInput(cfg) end
        function TabFunc:AddSlider(cfg) return ResolveSection(cfg):AddSlider(cfg) end
        function TabFunc:AddColorPicker(cfg) return ResolveSection(cfg):AddColorPicker(cfg) end
        function TabFunc:AddImage(name, cfg)
            if typeof(name) == "table" then cfg = name end
            return ResolveSection(cfg):AddImage(name, cfg)
        end
        function TabFunc:AddSeperator(args)
            if typeof(args) == "table" then return ResolveSection(args):AddSeperator(args.Title or args.Text or "") end
            return LeftSection:AddSeperator(args)
        end
        function TabFunc:AddDivider(args) return TabFunc:AddSeperator(args) end
        function TabFunc:AddParagraph(cfg) return ResolveSection(cfg):AddParagraph(cfg) end
        function TabFunc:AddKeybind(cfg) return ResolveSection(cfg):AddKeybind(cfg) end
        function TabFunc:AddTag(cfg) return ResolveSection(cfg):AddTag(cfg) end
        function TabFunc:AddMultiButton(cfg) return ResolveSection(cfg):AddMultiButton(cfg) end
        function TabFunc:AddCodeBox(cfg) return ResolveSection(cfg):AddCodeBox(cfg) end
        function TabFunc:AddProgressBar(cfg) return ResolveSection(cfg):AddProgressBar(cfg) end
        function TabFunc:AddLabel(cfg) return ResolveSection(cfg):AddLabel(cfg) end
        function TabFunc:AddPlayerDropdown(cfg) return ResolveSection(cfg):AddPlayerDropdown(cfg) end
        function TabFunc:AddColorToggle(cfg) return ResolveSection(cfg):AddColorToggle(cfg) end
        function TabFunc:AddLeftGroupbox(SectionName) return MakeGroupbox(SectionName, LeftColumn) end

        function TabFunc:AddRightGroupbox(SectionName) return MakeGroupbox(SectionName, RightColumn) end
        function TabFunc:AddSection(SectionName) return MakeGroupbox(SectionName, LeftColumn) end
        return TabFunc
    end





    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local Query = SearchBox.Text:lower()
        for _, TabData in ipairs(Window.Tabs) do
            local TabMatch = Query == "" or string.find(TabData.Name:lower(), Query, 1, true) ~= nil
            TabData.Button.Visible = TabMatch
            if TabData.Layout then
                for _, Col in ipairs(TabData.Layout:GetChildren()) do
                    if Col:IsA("ScrollingFrame") then
                        for _, Sec in ipairs(Col:GetChildren()) do
                            if Sec.Name == "Section" then
                                local List = Sec:FindFirstChild("SectionList")
                                if List then
                                    for _, Item in ipairs(List:GetChildren()) do
                                        if Item:IsA("Frame") then
                                            local TitleLabel = Item:FindFirstChild("Title")
                                            if TitleLabel and TitleLabel:IsA("TextLabel") then
                                                local text = TitleLabel.Text:lower()
                                                Item.Visible = Query == "" or string.find(text, Query, 1, true) ~= nil or TabMatch and Query == ""
                                                if Query ~= "" then
                                                    Item.Visible = string.find(text, Query, 1, true) ~= nil
                                                else
                                                    Item.Visible = true
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    function Window:Dialog(cfg)
        cfg = Library:MakeConfig({
            Title = "Dialog",
            Content = "",
            Buttons = {
                {Title = "OK", Callback = function() end}
            }
        }, cfg or {})
        local DialogFrame = Create("Frame", {
            Name = "Dialog",
            Parent = DropdownZone,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 0),
            Visible = true,
            ZIndex = 25
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = DialogFrame})
        Create("UIStroke", {Color = Library.Theme.Stroke, Transparency = 0.4, Parent = DialogFrame})
        Library:CreateAccentBar(DialogFrame, 10)
        local DTitle = Create("TextLabel", {
            Parent = DialogFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 14),
            Size = UDim2.new(1, -36, 0, 22),
            Font = Enum.Font.GothamBold,
            Text = cfg.Title,
            TextColor3 = Library.Theme.Text,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 26
        })
        Library:ApplyGradient(DTitle)
        local ContentH = TextService:GetTextSize(cfg.Content, 13, Enum.Font.GothamBold, Vector2.new(340, 1000)).Y
        Create("TextLabel", {
            Parent = DialogFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 42),
            Size = UDim2.new(1, -36, 0, ContentH),
            Font = Enum.Font.GothamBold,
            Text = cfg.Content,
            TextColor3 = Library.Theme.TextDisabled,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 26
        })
        local BtnRow = Create("Frame", {
            Parent = DialogFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 1, -52),
            Size = UDim2.new(1, -36, 0, 36),
            ZIndex = 26
        })
        Create("UIListLayout", {
            Parent = BtnRow,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8)
        })
        local function CloseDialog()
            Library:TweenInstance(DialogFrame, 0.18, "Size", UDim2.new(0, 0, 0, 0), function()
                Window:CloseOverlay(DialogFrame)
                DialogFrame:Destroy()
            end)
        end
        for _, B in ipairs(cfg.Buttons) do
            local Btn = Create("TextButton", {
                Parent = BtnRow,
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 90, 0, 32),
                Font = Enum.Font.GothamBold,
                Text = tostring(B.Title or "OK"),
                TextColor3 = Library.Theme.Text,
                TextSize = 13,
                ZIndex = 27,
                AutoButtonColor = false
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = Btn})
            Btn.Activated:Connect(function()
                if B.Callback then B.Callback() end
                CloseDialog()
            end)
        end
        local TotalH = 70 + ContentH + 50
        Window:OpenOverlay(DialogFrame)
        DialogFrame.Size = UDim2.new(0, 0, 0, 0)
        Library:TweenInstance(DialogFrame, 0.22, "Size", UDim2.new(0, 380, 0, TotalH))
    end
    function Window:Popup(cfg)
        return Window:Dialog(cfg)
    end
    function Window:Destroy()
        for i = #Library.ActiveWindows, 1, -1 do
            if Library.ActiveWindows[i] == Window then
                table.remove(Library.ActiveWindows, i)
                break
            end
        end
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end
    DropShadowHolder.Size = UDim2.new(0, 0, 0, 0)
    DropShadowHolder.Visible = true
    Library:TweenInstance(DropShadowHolder, 0.28, "Size", ConfigWindow.Size)
    return Window
end
return Library

