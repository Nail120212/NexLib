--[[
    sh1ttybanana v2.0.0  -  "liquid"
    Roblox executor UI library.

    Library:NewWindow(config) -> Window
    Window:Section(config)    -> sidebar group
    Window:Tab(config)        -> tab
    Tab:AddSection(name)      -> section
    Section:AddToggle{...} / AddSlider{...} / AddDropdown{...} / ...

    Every interactive element returns an object with
    :Set(v) :Get() :SetVisible(b) :SetLocked(b) :Destroy() :OnChanged(fn)
]]

local Library = {}
Library.Version = "2.0.0"
Library.Codename = "liquid"

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer
local StatsService = nil
pcall(function() StatsService = game:GetService("Stats") end)

local Quart = Enum.EasingStyle.Quart
local Quint = Enum.EasingStyle.Quint
local Back = Enum.EasingStyle.Back
local Out = Enum.EasingDirection.Out
local In = Enum.EasingDirection.In

local FAST = TweenInfo.new(0.16, Quart, Out)
local NORMAL = TweenInfo.new(0.26, Quart, Out)
local SLOW = TweenInfo.new(0.42, Quint, Out)
local SPRING = TweenInfo.new(0.34, Back, Out)

-- ============================================================ helpers

local function New(ClassName, Props, Children)
    local Obj = Instance.new(ClassName)
    local Parent
    for Key, Value in pairs(Props or {}) do
        if Key == "Parent" then
            Parent = Value
        else
            Obj[Key] = Value
        end
    end
    for _, Child in ipairs(Children or {}) do
        Child.Parent = Obj
    end
    if Parent then
        Obj.Parent = Parent
    end
    return Obj
end

Library.New = New

local function Clamp(Value, Min, Max)
    return Value < Min and Min or (Value > Max and Max or Value)
end

local function Round(Value, Increment)
    if not Increment or Increment <= 0 then
        return Value
    end
    local Snapped = math.floor(Value / Increment + 0.5) * Increment
    local Decimals = tostring(Increment):match("%.(%d+)")
    if Decimals then
        local Factor = 10 ^ #Decimals
        Snapped = math.floor(Snapped * Factor + 0.5) / Factor
    end
    return Snapped
end

local function Trim(Text)
    return (tostring(Text):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function Merge(Defaults, User)
    local Result = {}
    for Key, Value in pairs(Defaults) do
        Result[Key] = Value
    end
    for Key, Value in pairs(User or {}) do
        if Value ~= nil then
            Result[Key] = Value
        end
    end
    return Result
end

Library.MakeConfig = function(_, Defaults, User)
    return Merge(Defaults, User)
end

local function HttpGet(Url)
    if game.HttpGet then
        return game:HttpGet(Url)
    end
    return HttpService:GetAsync(Url)
end

-- exploit globals are unreliable, every one of them is probed once and cached
local Env = {}
do
    local function Grab(Name)
        local Value = rawget(getfenv(), Name)
        if Value == nil and type(getgenv) == "function" then
            local Ok, Global = pcall(getgenv)
            if Ok and type(Global) == "table" then
                Value = rawget(Global, Name)
            end
        end
        return type(Value) == "function" and Value or nil
    end
    Env.writefile = Grab("writefile")
    Env.readfile = Grab("readfile")
    Env.isfile = Grab("isfile")
    Env.delfile = Grab("delfile")
    Env.listfiles = Grab("listfiles")
    Env.makefolder = Grab("makefolder")
    Env.isfolder = Grab("isfolder")
    Env.setclipboard = Grab("setclipboard") or Grab("toclipboard")
    Env.request = Grab("request") or Grab("http_request")
        or (syn and syn.request) or (http and http.request)
    Env.identifyexecutor = Grab("identifyexecutor") or Grab("getexecutorname")
    Env.gethwid = Grab("gethwid")
end
Library.Env = Env

local FS = {}

function FS.Folder(Path)
    if not Env.makefolder or not Env.isfolder then
        return false
    end
    local Built = ""
    for Part in Path:gmatch("[^/]+") do
        Built = Built == "" and Part or (Built .. "/" .. Part)
        if not Env.isfolder(Built) then
            local Ok = pcall(Env.makefolder, Built)
            if not Ok then
                return false
            end
        end
    end
    return true
end

function FS.Write(Path, Text)
    if not Env.writefile then
        return false
    end
    return (pcall(Env.writefile, Path, Text))
end

function FS.Read(Path)
    if not Env.readfile or not Env.isfile then
        return nil
    end
    local Ok, Exists = pcall(Env.isfile, Path)
    if not Ok or not Exists then
        return nil
    end
    local Read, Data = pcall(Env.readfile, Path)
    return Read and Data or nil
end

function FS.Delete(Path)
    if not Env.delfile then
        return false
    end
    return (pcall(Env.delfile, Path))
end

function FS.List(Path)
    if not Env.listfiles or not Env.isfolder then
        return {}
    end
    local Ok, Exists = pcall(Env.isfolder, Path)
    if not Ok or not Exists then
        return {}
    end
    local Listed, Files = pcall(Env.listfiles, Path)
    return Listed and Files or {}
end

function FS.WriteJSON(Path, Value)
    local Ok, Encoded = pcall(HttpService.JSONEncode, HttpService, Value)
    if not Ok then
        return false
    end
    return FS.Write(Path, Encoded)
end

function FS.ReadJSON(Path)
    local Raw = FS.Read(Path)
    if not Raw then
        return nil
    end
    local Ok, Decoded = pcall(HttpService.JSONDecode, HttpService, Raw)
    return Ok and Decoded or nil
end

Library.FS = FS

-- ============================================================ signal

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ Handlers = {} }, Signal)
end

function Signal:Connect(Handler)
    table.insert(self.Handlers, Handler)
    local Connection = {}
    function Connection:Disconnect()
        for Index, Value in ipairs(self.Owner.Handlers) do
            if Value == Handler then
                table.remove(self.Owner.Handlers, Index)
                break
            end
        end
    end
    Connection.Owner = self
    return Connection
end

function Signal:Fire(...)
    for _, Handler in ipairs(table.clone(self.Handlers)) do
        task.spawn(Handler, ...)
    end
end

function Signal:Destroy()
    table.clear(self.Handlers)
end

Library.Signal = Signal

-- ============================================================ themes

Library.Themes = {
    Dark = {
        Main = Color3.fromRGB(11, 11, 14),
        Sidebar = Color3.fromRGB(255, 255, 255),
        Card = Color3.fromRGB(255, 255, 255),
        Row = Color3.fromRGB(255, 255, 255),
        Inset = Color3.fromRGB(22, 22, 27),
        Elevated = Color3.fromRGB(16, 16, 20),
        Accent = Color3.fromRGB(179, 0, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(138, 138, 150),
        TextDisabled = Color3.fromRGB(138, 138, 150),
        Stroke = Color3.fromRGB(120, 120, 138),
        StrokeSoft = Color3.fromRGB(120, 120, 138),
        Sheen = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        Success = Color3.fromRGB(80, 225, 140),
        Warn = Color3.fromRGB(255, 200, 90),
        Error = Color3.fromRGB(255, 88, 88),
        Info = Color3.fromRGB(120, 180, 255),
        WindowAlpha = 0.07,
        SidebarAlpha = 0.97,
        CardAlpha = 0.97,
        RowAlpha = 0.95,
        RowHoverAlpha = 0.9,
        InsetAlpha = 0,
        ElevatedAlpha = 0,
        StrokeAlpha = 0.92,
        StrokeSoftAlpha = 0.93,
        SheenAlpha = 1,
        Radius = 14,
        Blur = 0,
        Glass = false
    },
    Black = {
        Main = Color3.fromRGB(0, 0, 0),
        Sidebar = Color3.fromRGB(255, 255, 255),
        Card = Color3.fromRGB(255, 255, 255),
        Row = Color3.fromRGB(255, 255, 255),
        Inset = Color3.fromRGB(8, 8, 8),
        Elevated = Color3.fromRGB(4, 4, 4),
        Accent = Color3.fromRGB(179, 0, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(150, 150, 150),
        TextDisabled = Color3.fromRGB(150, 150, 150),
        Stroke = Color3.fromRGB(90, 90, 90),
        StrokeSoft = Color3.fromRGB(90, 90, 90),
        Sheen = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        Success = Color3.fromRGB(80, 225, 140),
        Warn = Color3.fromRGB(255, 200, 90),
        Error = Color3.fromRGB(255, 88, 88),
        Info = Color3.fromRGB(120, 180, 255),
        WindowAlpha = 0.07,
        SidebarAlpha = 0.975,
        CardAlpha = 0.975,
        RowAlpha = 0.965,
        RowHoverAlpha = 0.92,
        InsetAlpha = 0,
        ElevatedAlpha = 0,
        StrokeAlpha = 0.92,
        StrokeSoftAlpha = 0.93,
        SheenAlpha = 1,
        Radius = 14,
        Blur = 0,
        Glass = false
    },
    Light = {
        Main = Color3.fromRGB(243, 243, 248),
        Sidebar = Color3.fromRGB(0, 0, 0),
        Card = Color3.fromRGB(0, 0, 0),
        Row = Color3.fromRGB(0, 0, 0),
        Inset = Color3.fromRGB(226, 226, 236),
        Elevated = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(179, 0, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(18, 18, 24),
        TextDim = Color3.fromRGB(108, 108, 122),
        TextDisabled = Color3.fromRGB(108, 108, 122),
        Stroke = Color3.fromRGB(158, 158, 176),
        StrokeSoft = Color3.fromRGB(158, 158, 176),
        Sheen = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(38, 38, 60),
        Success = Color3.fromRGB(22, 163, 74),
        Warn = Color3.fromRGB(202, 138, 4),
        Error = Color3.fromRGB(220, 38, 38),
        Info = Color3.fromRGB(37, 99, 235),
        WindowAlpha = 0.07,
        SidebarAlpha = 0.95,
        CardAlpha = 0.95,
        RowAlpha = 0.93,
        RowHoverAlpha = 0.87,
        InsetAlpha = 0,
        ElevatedAlpha = 0,
        StrokeAlpha = 0.88,
        StrokeSoftAlpha = 0.9,
        SheenAlpha = 1,
        Radius = 14,
        Blur = 0,
        Glass = false
    },
    ["Liquid Glass"] = {
        Main = Color3.fromRGB(14, 14, 22),
        Sidebar = Color3.fromRGB(255, 255, 255),
        Card = Color3.fromRGB(255, 255, 255),
        Row = Color3.fromRGB(255, 255, 255),
        Inset = Color3.fromRGB(10, 10, 18),
        Elevated = Color3.fromRGB(16, 16, 26),
        Accent = Color3.fromRGB(198, 108, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(190, 192, 210),
        TextDisabled = Color3.fromRGB(160, 162, 184),
        Stroke = Color3.fromRGB(190, 190, 220),
        StrokeSoft = Color3.fromRGB(190, 190, 220),
        Sheen = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 10),
        Success = Color3.fromRGB(126, 245, 172),
        Warn = Color3.fromRGB(255, 224, 130),
        Error = Color3.fromRGB(255, 138, 138),
        Info = Color3.fromRGB(150, 200, 255),
        WindowAlpha = 0.3,
        SidebarAlpha = 0.94,
        CardAlpha = 0.94,
        RowAlpha = 0.92,
        RowHoverAlpha = 0.86,
        InsetAlpha = 0.35,
        ElevatedAlpha = 0.15,
        StrokeAlpha = 0.8,
        StrokeSoftAlpha = 0.86,
        SheenAlpha = 0.88,
        Radius = 14,
        Blur = 14,
        Glass = true
    }
}

Library.ThemeOrder = { "Dark", "Black", "Light", "Liquid Glass" }
Library.CurrentTheme = "Dark"
Library.Theme = Library.Themes.Dark
Library.ThemeObjects = {}
Library.OnThemeChanged = Signal.new()

function Library:Themed(Object, Property, Key)
    table.insert(Library.ThemeObjects, { Object = Object, Property = Property, Key = Key })
    local Value = Library.Theme[Key]
    if Value ~= nil then
        pcall(function()
            Object[Property] = Value
        end)
    end
    return Object
end

function Library:RefreshTheme(Animated)
    local Alive = {}
    for _, Entry in ipairs(Library.ThemeObjects) do
        local Object = Entry.Object
        local Value = Library.Theme[Entry.Key]
        local Ok = Object ~= nil and pcall(function()
            return Object.Parent
        end)
        if Ok and Value ~= nil then
            if Animated and (typeof(Value) == "Color3" or typeof(Value) == "number") then
                pcall(function()
                    TweenService:Create(Object, NORMAL, { [Entry.Property] = Value }):Play()
                end)
            else
                pcall(function()
                    Object[Entry.Property] = Value
                end)
            end
        end
        if Ok then
            table.insert(Alive, Entry)
        end
    end
    Library.ThemeObjects = Alive
    Library.OnThemeChanged:Fire(Library.CurrentTheme, Library.Theme)
end

function Library:AddTheme(Name, Tokens)
    if type(Name) ~= "string" or type(Tokens) ~= "table" then
        return
    end
    Library.Themes[Name] = Merge(Library.Themes.Dark, Tokens)
    if not table.find(Library.ThemeOrder, Name) then
        table.insert(Library.ThemeOrder, Name)
    end
    return Library.Themes[Name]
end

function Library:ApplyTheme(Name)
    local Found = Library.Themes[Name]
    if not Found then
        return false
    end
    Library.CurrentTheme = Name
    Library.Theme = Found
    Library:RefreshTheme(true)
    return true
end

function Library:SetAccent(Color)
    if typeof(Color) ~= "Color3" then
        return
    end
    for _, Tokens in pairs(Library.Themes) do
        Tokens.Accent = Color
    end
    Library:RefreshTheme(true)
end

function Library:ExportTheme(Name)
    local Key = Name or Library.CurrentTheme
    local Tokens = Library.Themes[Key]
    if not Tokens then
        return nil
    end
    local Plain = { Name = Key }
    for Token, Value in pairs(Tokens) do
        if typeof(Value) == "Color3" then
            Plain[Token] = {
                math.floor(Value.R * 255 + 0.5),
                math.floor(Value.G * 255 + 0.5),
                math.floor(Value.B * 255 + 0.5)
            }
        else
            Plain[Token] = Value
        end
    end
    local Ok, Encoded = pcall(HttpService.JSONEncode, HttpService, Plain)
    return Ok and Encoded or nil
end

function Library:ImportTheme(Json)
    local Ok, Data = pcall(HttpService.JSONDecode, HttpService, Json)
    if not Ok or type(Data) ~= "table" then
        return false, "invalid json"
    end
    local Name = Data.Name or "Imported"
    local Tokens = {}
    for Token, Value in pairs(Data) do
        if Token ~= "Name" then
            if type(Value) == "table" and #Value == 3 then
                Tokens[Token] = Color3.fromRGB(Value[1], Value[2], Value[3])
            else
                Tokens[Token] = Value
            end
        end
    end
    Library:AddTheme(Name, Tokens)
    return true, Name
end

-- ============================================================ icons

local IconPack
do
    local Ok, Result = pcall(function()
        return loadstring(HttpGet("https://raw.githubusercontent.com/DSP-V1/NextGen/refs/heads/main/UILib/icons/UIIcons.lua"))()
    end)
    if Ok and type(Result) == "table" then
        IconPack = Result
        if IconPack.SetIconsType then
            pcall(IconPack.SetIconsType, "lucide")
        end
    end
end

Library.Icons = {
    Minimize = "minus",
    Maximize = "maximize-2",
    Restore = "minimize-2",
    Close = "x",
    Search = "search",
    Right = "chevron-right",
    Down = "chevron-down",
    Left = "chevron-left",
    Up = "chevron-up",
    Tab = "square",
    Lock = "lock",
    Unlock = "lock-open",
    Check = "check",
    Copy = "copy",
    Edit = "pencil",
    Key = "keyboard",
    Palette = "palette",
    Bot = "bot",
    Send = "send",
    Trash = "trash-2",
    User = "user",
    Clock = "clock",
    Finger = "fingerprint",
    Gauge = "gauge",
    Signal = "signal",
    Cpu = "cpu",
    Save = "save",
    Folder = "folder",
    Plus = "plus",
    Star = "star",
    Command = "command",
    Refresh = "refresh-cw",
    Settings = "settings",
    Info = "info",
    Menu = "menu",
    Grip = "grip-vertical",
    Sparkles = "sparkles"
}

function Library:NormalizeIcon(Name)
    if type(Name) ~= "string" or Name == "" then
        return "lucide:" .. Library.Icons.Tab
    end
    if Name:find("rbxassetid") or Name:find("rbxasset://") or Name:find("http") then
        return Name
    end
    if Name:find(":") then
        return Name
    end
    return "lucide:" .. Name
end

-- IconModule.Icon(name) returns { assetId, { ImageRectSize, ImageRectPosition } },
-- it does not take the label, so the sprite has to be applied by hand
function Library:SetIcon(Object, Name, Color)
    if not Object then
        return
    end
    local Resolved = Library:NormalizeIcon(Name)
    if Resolved:find("rbxasset") or Resolved:find("http") then
        Object.Image = Resolved
        Object.ImageRectSize = Vector2.new()
        Object.ImageRectOffset = Vector2.new()
    elseif IconPack and IconPack.Icon then
        local Ok, Data = pcall(IconPack.Icon, Resolved)
        if Ok and type(Data) == "table" and Data[1] then
            Object.Image = tostring(Data[1])
            local Rect = Data[2]
            Object.ImageRectSize = type(Rect) == "table" and Rect.ImageRectSize or Vector2.new()
            Object.ImageRectOffset = type(Rect) == "table" and Rect.ImageRectPosition or Vector2.new()
        elseif Ok and type(Data) == "string" and Data ~= "" then
            Object.Image = Data
        else
            Object.Image = ""
        end
    else
        Object.Image = ""
    end
    if Color then
        Object.ImageColor3 = Color
    end
    return Object
end

-- ============================================================ feedback

-- No click sounds. A UI library has no business making noise in someone
-- else's game, so Play and Vibrate stay inert unless explicitly switched on.
Library.Sound = false
Library.Haptics = false
Library.Particles = true

local ClickSound = "rbxasset://sounds/electronicpingshort.wav"

function Library:Play(Pitch)
    if not Library.Sound then
        return
    end
    task.spawn(function()
        pcall(function()
            local Emitter = New("Sound", {
                Parent = game:GetService("SoundService"),
                SoundId = ClickSound,
                Volume = 0.25,
                PlaybackSpeed = Pitch or 1
            })
            Emitter:Play()
            game:GetService("Debris"):AddItem(Emitter, 2)
        end)
    end)
end

function Library:Vibrate(Strength)
    if not Library.Haptics then
        return
    end
    pcall(function()
        local Haptic = game:GetService("HapticService")
        if Haptic:IsVibrationSupported(Enum.UserInputType.Gamepad1) then
            Haptic:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, Strength or 0.25)
            task.delay(0.09, function()
                Haptic:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
            end)
        end
    end)
end

function Library:Feedback(Pitch)
    if Library.Sound then
        Library:Play(Pitch)
    end
    if Library.Haptics then
        Library:Vibrate(0.2)
    end
end

-- ============================================================ primitives

function Library:Tween(Object, Info, Properties, Callback)
    local Animation = TweenService:Create(Object, Info or NORMAL, Properties)
    if Callback then
        Animation.Completed:Connect(Callback)
    end
    Animation:Play()
    return Animation
end

function Library:Corner(Object, Radius)
    return New("UICorner", {
        Parent = Object,
        CornerRadius = typeof(Radius) == "UDim" and Radius or UDim.new(0, Radius or Library.Theme.Radius)
    })
end

function Library:Stroke(Object, Key, Thickness)
    local Line = New("UIStroke", {
        Parent = Object,
        Thickness = Thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(Line, "Color", Key or "Stroke")
    Library:Themed(Line, "Transparency", (Key or "Stroke") .. "Alpha")
    return Line
end

function Library:Padding(Object, Top, Bottom, Left, Right)
    return New("UIPadding", {
        Parent = Object,
        PaddingTop = UDim.new(0, Top or 0),
        PaddingBottom = UDim.new(0, Bottom or Top or 0),
        PaddingLeft = UDim.new(0, Left or Top or 0),
        PaddingRight = UDim.new(0, Right or Left or Top or 0)
    })
end

function Library:Gradient(Object, Colors, Rotation, Transparencies)
    local Sequence = {}
    for Index, Color in ipairs(Colors) do
        table.insert(Sequence, ColorSequenceKeypoint.new((Index - 1) / math.max(#Colors - 1, 1), Color))
    end
    local Gradient = New("UIGradient", {
        Parent = Object,
        Color = ColorSequence.new(Sequence),
        Rotation = Rotation or 0
    })
    if Transparencies then
        local Alpha = {}
        for Index, Value in ipairs(Transparencies) do
            table.insert(Alpha, NumberSequenceKeypoint.new((Index - 1) / math.max(#Transparencies - 1, 1), Value))
        end
        Gradient.Transparency = NumberSequence.new(Alpha)
    end
    return Gradient
end

-- glass highlight: bright top edge fading out, only visible on glass themes
function Library:Sheen(Object, Rotation)
    local Layer = New("Frame", {
        Parent = Object,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = (Object.ZIndex or 1)
    })
    Library:Corner(Layer, Object:FindFirstChildOfClass("UICorner") and Object:FindFirstChildOfClass("UICorner").CornerRadius or UDim.new(0, Library.Theme.Radius))
    local Fill = New("Frame", {
        Parent = Layer,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Layer.ZIndex
    })
    Library:Corner(Fill, Layer:FindFirstChildOfClass("UICorner").CornerRadius)
    Library:Themed(Fill, "BackgroundColor3", "Sheen")
    Library:Themed(Fill, "BackgroundTransparency", "SheenAlpha")
    New("UIGradient", {
        Parent = Fill,
        Rotation = Rotation or 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.45, 0.75),
            NumberSequenceKeypoint.new(1, 1)
        })
    })
    return Layer
end

-- Drop shadows are off. The switch stays so a window can opt back in with
-- Library.Shadows = true before it is built.
Library.Shadows = false

function Library:Shadow(Object, Spread, Alpha)
    if not Library.Shadows then
        return nil
    end
    local Shadow = New("ImageLabel", {
        Parent = Object,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, Spread or 60, 1, Spread or 60),
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = Alpha or 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0
    })
    Library:Themed(Shadow, "ImageColor3", "Shadow")
    return Shadow
end

-- v1 divider: a line that fades out towards both ends
function Library:FadeLine(Object, Horizontal)
    local Gradient = New("UIGradient", {
        Parent = Object,
        Rotation = Horizontal and 0 or 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.15),
            NumberSequenceKeypoint.new(1, 1)
        })
    })
    Library:Themed(Object, "BackgroundColor3", "Accent")
    return Gradient
end

function Library:Hover(Trigger, Target, Property, Idle, Active, Duration)
    local Info = TweenInfo.new(Duration or 0.15, Quart, Out)
    Trigger.MouseEnter:Connect(function()
        Library:Tween(Target, Info, { [Property] = Active })
    end)
    Trigger.MouseLeave:Connect(function()
        Library:Tween(Target, Info, { [Property] = Idle })
    end)
end

function Library:Pop(Object, Duration, From)
    local Scale = New("UIScale", { Parent = Object, Scale = From or 0.9 })
    Library:Tween(Scale, TweenInfo.new(Duration or 0.34, Back, Out), { Scale = 1 }, function()
        Scale:Destroy()
    end)
end

function Library:StyleScroll(Scroll)
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageTransparency = 0.55
    Scroll.BorderSizePixel = 0
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.CanvasSize = UDim2.new()
    Library:Themed(Scroll, "ScrollBarImageColor3", "Accent")
    return Scroll
end

-- ============================================================ device

local Device = {}

function Device.Viewport()
    local Camera = workspace.CurrentCamera
    return Camera and Camera.ViewportSize or Vector2.new(1280, 720)
end

function Device.IsMobile()
    local Size = Device.Viewport()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return true
    end
    return Size.X < 720
end

function Device.Scale()
    local Size = Device.Viewport()
    if Device.IsMobile() then
        return Clamp(Size.X / 520, 0.62, 1)
    end
    return Clamp(math.min(Size.X / 1280, Size.Y / 720), 0.7, 1.25)
end

Library.Device = Device

-- ============================================================ flags

Library.Flags = {}
Library.Options = {}

function Library:GetFlag(Flag, Fallback)
    local Value = Library.Flags[Flag]
    if Value == nil then
        return Fallback
    end
    return Value
end

function Library:SetFlag(Flag, Value)
    local Option = Library.Options[Flag]
    if Option then
        Option:Set(Value)
    else
        Library.Flags[Flag] = Value
    end
end

-- serialise anything a component can hold into plain json-safe data
local function Encode(Value)
    if typeof(Value) == "Color3" then
        return { __t = "Color3", math.floor(Value.R * 255 + 0.5), math.floor(Value.G * 255 + 0.5), math.floor(Value.B * 255 + 0.5) }
    elseif typeof(Value) == "EnumItem" then
        return { __t = "Enum", tostring(Value.EnumType), Value.Name }
    elseif type(Value) == "table" then
        local Copy = {}
        for Key, Item in pairs(Value) do
            Copy[Key] = Encode(Item)
        end
        return Copy
    end
    return Value
end

local function Decode(Value)
    if type(Value) == "table" then
        if Value.__t == "Color3" then
            return Color3.fromRGB(Value[1], Value[2], Value[3])
        elseif Value.__t == "Enum" then
            local Ok, Item = pcall(function()
                local Category = Value[2]:gsub("^Enum%.", "")
                return Enum[Category][Value[3]]
            end)
            return Ok and Item or nil
        end
        local Copy = {}
        for Key, Item in pairs(Value) do
            Copy[Key] = Decode(Item)
        end
        return Copy
    end
    return Value
end

Library.Encode = Encode
Library.Decode = Decode

-- ============================================================ element base

local Element = {}
Element.__index = Element

function Element.new(Data)
    return setmetatable(Data, Element)
end

function Element:Get()
    if self.Handlers.Get then
        return self.Handlers.Get()
    end
    return self.Value
end

function Element:Set(Value, Silent)
    if self.Handlers.Set then
        self.Handlers.Set(Value, Silent)
    end
    return self
end

function Element:SetVisible(State)
    self.Frame.Visible = State ~= false
    return self
end

function Element:SetTitle(Text)
    if self.TitleLabel then
        self.TitleLabel.Text = tostring(Text)
    end
    self.Title = tostring(Text)
    return self
end

function Element:SetDescription(Text)
    if self.DescLabel then
        self.DescLabel.Text = tostring(Text)
        self.DescLabel.Visible = tostring(Text) ~= ""
    end
    return self
end

function Element:SetLocked(State, Reason)
    self.Locked = State and true or false
    if self.Handlers.Lock then
        self.Handlers.Lock(self.Locked, Reason)
    end
    if Reason or self.LockReason then
        self.LockReason = Reason or self.LockReason
    end
    if self.LockLabel and self.LockReason then
        self.LockLabel.Text = self.LockReason
    end
    if self.PaintLock then
        self.PaintLock(self.Locked)
    end
    return self
end

function Element:OnChanged(Callback)
    return self.Changed:Connect(Callback)
end

function Element:Destroy()
    if self.Flag then
        Library.Options[self.Flag] = nil
    end
    if self.Registry then
        self.Registry.Dead = true
    end
    self.Changed:Destroy()
    if self.Frame then
        self.Frame:Destroy()
    end
end

Library.Element = Element

-- ============================================================ shared builders

Library.Font = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold,
    Mono = Enum.Font.Code
}

local Components = {}
local WM = {}

local function Label(Parent, Text, Size, FontStyle, ColorKey)
    local Object = New("TextLabel", {
        Parent = Parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = FontStyle or Library.Font.Medium,
        Text = Text or "",
        TextSize = Size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
        Size = UDim2.fromScale(1, 1)
    })
    Library:Themed(Object, "TextColor3", ColorKey or "Text")
    return Object
end

local function IconLabel(Parent, Name, Size, ColorKey)
    local Object = New("ImageLabel", {
        Parent = Parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(Size or 16, Size or 16)
    })
    Library:SetIcon(Object, Name)
    Library:Themed(Object, "ImageColor3", ColorKey or "TextDim")
    return Object
end

local function Blank(Parent, Props)
    local Frame = New("Frame", Merge({
        Parent = Parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, Props or {}))
    return Frame
end

-- a pill button used across header, modals and footers
local function PillButton(Parent, Text, IconName, Width, Accent)
    local Button = New("TextButton", {
        Parent = Parent,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.new(0, Width or 96, 0, 30),
        Text = ""
    })
    Library:Corner(Button, 9)
    Library:Themed(Button, "BackgroundColor3", Accent and "Accent" or "Row")
    Library:Themed(Button, "BackgroundTransparency", Accent and "RowAlpha" or "RowAlpha")
    local Line = Library:Stroke(Button, "StrokeSoft", 1)

    local Holder = Blank(Button, { Size = UDim2.fromScale(1, 1) })
    New("UIListLayout", {
        Parent = Holder,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local Icon
    if IconName then
        Icon = IconLabel(Holder, IconName, 15, Accent and "AccentText" or "Text")
        Icon.LayoutOrder = 1
    end

    local TextPart = New("TextLabel", {
        Parent = Holder,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 30),
        Font = Library.Font.Medium,
        Text = Text or "",
        TextSize = 12,
        LayoutOrder = 2,
        Visible = (Text or "") ~= ""
    })
    Library:Themed(TextPart, "TextColor3", Accent and "AccentText" or "Text")

    Button.MouseEnter:Connect(function()
        Library:Tween(Line, FAST, { Transparency = 0.45 })
    end)
    Button.MouseLeave:Connect(function()
        Library:Tween(Line, FAST, { Transparency = Library.Theme.StrokeSoftAlpha })
    end)
    Button.MouseButton1Click:Connect(function()
        Library:Feedback(1.05)
    end)

    return Button, TextPart, Icon
end

-- circular header control (minimise / close / palette ...)
local function GlyphButton(Parent, IconName, Tip)
    local Button = New("TextButton", {
        Parent = Parent,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(30, 30),
        Text = ""
    })
    Library:Corner(Button, 9)
    Library:Themed(Button, "BackgroundColor3", "Row")

    local Icon = IconLabel(Button, IconName, 16, "TextDim")
    Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon.Position = UDim2.fromScale(0.5, 0.5)

    Button.MouseEnter:Connect(function()
        Library:Tween(Button, FAST, { BackgroundTransparency = 0.25 })
        Library:Tween(Icon, FAST, { ImageColor3 = Library.Theme.Text })
    end)
    Button.MouseLeave:Connect(function()
        Library:Tween(Button, FAST, { BackgroundTransparency = 1 })
        Library:Tween(Icon, FAST, { ImageColor3 = Library.Theme.TextDim })
    end)

    Button:SetAttribute("Tip", Tip or "")
    return Button, Icon
end

-- ============================================================ row factory

-- Every element sits in one of these. RightWidth reserves space for the
-- control so the title block can never overlap it on a narrow window.
local function MakeRow(Section, Kind, Title, Description, MinHeight, RightWidth)
    local Mobile = Section.Window.Mobile
    local Height = (MinHeight or 36) + (Mobile and 6 or 0)
    local Reserve = (RightWidth or 60) > 0 and ((RightWidth or 60) + 26) or 14

    local Row = New("Frame", {
        Parent = Section.Body,
        Name = Kind,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Height),
        LayoutOrder = Section.Count + 1
    })
    Section.Count = Section.Count + 1
    Library:Corner(Row, 7)
    Library:Themed(Row, "BackgroundColor3", "Row")
    Library:Themed(Row, "BackgroundTransparency", "RowAlpha")
    local Line = Library:Stroke(Row, "StrokeSoft", 1)

    New("UIPadding", {
        Parent = Row,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    })

    local Stack = New("Frame", {
        Parent = Row,
        Name = "Text",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -(Reserve + 14), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    })

    -- The row height is driven off the text stack instead of AutomaticSize:
    -- a visible full size child (the click layer on a toggle) makes Roblox
    -- add the padding on top of the minimum size and the row grows to 70px.
    local function Measure()
        local Wanted = math.max(Height, Stack.AbsoluteSize.Y + 20)
        if Row.Size.Y.Offset ~= Wanted then
            Row.Size = UDim2.new(1, 0, 0, Wanted)
        end
    end
    Stack:GetPropertyChangedSignal("AbsoluteSize"):Connect(Measure)
    task.defer(Measure)
    New("UIListLayout", {
        Parent = Stack,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3)
    })

    local TitleLabel = New("TextLabel", {
        Parent = Stack,
        BackgroundTransparency = 1,
        Font = Library.Font.Bold,
        Text = Title or Kind,
        TextSize = Mobile and 14 or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.new(1, 0, 0, Mobile and 18 or 16),
        LayoutOrder = 1,
        RichText = true
    })
    Library:Themed(TitleLabel, "TextColor3", "Text")

    local DescLabel = New("TextLabel", {
        Parent = Stack,
        BackgroundTransparency = 1,
        Font = Library.Font.Regular,
        Text = Description or "",
        TextSize = Mobile and 12 or 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Visible = (Description or "") ~= "",
        RichText = true
    })
    Library:Themed(DescLabel, "TextColor3", "TextDisabled")

    Row.MouseEnter:Connect(function()
        Library:Tween(Row, FAST, { BackgroundTransparency = Library.Theme.RowHoverAlpha })
        Library:Tween(Line, FAST, { Transparency = 0.55 })
    end)
    Row.MouseLeave:Connect(function()
        Library:Tween(Row, FAST, { BackgroundTransparency = Library.Theme.RowAlpha })
        Library:Tween(Line, FAST, { Transparency = Library.Theme.StrokeSoftAlpha })
    end)

    return Row, TitleLabel, DescLabel, Line, Stack
end

-- ============================================================ element wiring

local function Register(Section, Element)
    local Entry = {
        Kind = "Element",
        Name = Element.Title or "",
        Description = Element.Description or "",
        Tab = Section.Tab.Name,
        Section = Section.Title,
        Element = Element,
        Jump = function()
            Section.Window.SelectTab(Section.Tab)
            task.defer(function()
                Section.Window.Focus(Element.Frame)
            end)
        end
    }
    table.insert(Section.Window.Index, Entry)
    Element.Registry = Entry
    return Entry
end

-- A locked row is not a row with a sheet of glass over it. The control is
-- swapped for a lock chip and the label dims, so nothing bleeds through.
local function LockOverlay(Element, Config)
    local Window = Element.Section.Window
    local Row = Element.Frame

    local Blocker = New("TextButton", {
        Parent = Row,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 40
    })

    local Chip = New("Frame", {
        Parent = Blocker,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 41
    })
    Library:Corner(Chip, 8)
    Library:Themed(Chip, "BackgroundColor3", "Inset")
    Library:Themed(Chip, "BackgroundTransparency", "InsetAlpha")
    local ChipLine = Library:Stroke(Chip, "StrokeSoft", 1)
    New("UIPadding", {
        Parent = Chip,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })
    New("UISizeConstraint", { Parent = Chip, MaxSize = Vector2.new(190, 26) })
    New("UIListLayout", {
        Parent = Chip,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local Icon = IconLabel(Chip, Library.Icons.Lock, 13, "TextDisabled")
    Icon.ZIndex = 42
    Icon.LayoutOrder = 1

    local Text = New("TextLabel", {
        Parent = Chip,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 26),
        Font = Library.Font.Medium,
        Text = "Locked",
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 2,
        ZIndex = 42
    })
    Library:Themed(Text, "TextColor3", "TextDisabled")

    Element.LockOverlay = Blocker
    Element.LockLabel = Text

    -- everything the lock hid, so unlocking puts it back exactly as it was
    local Hidden = {}

    Element.PaintLock = function(State)
        Blocker.Visible = State
        if State then
            table.clear(Hidden)
            for _, Child in ipairs(Row:GetChildren()) do
                if Child:IsA("GuiObject") and Child ~= Blocker and Child.Name ~= "Text" and Child.Visible then
                    Child.Visible = false
                    table.insert(Hidden, Child)
                end
            end
            local Stack = Row:FindFirstChild("Text")
            if Stack then
                -- block content (bars, grids, pickers) lives past the title pair
                for _, Child in ipairs(Stack:GetChildren()) do
                    if Child:IsA("GuiObject") and Child.LayoutOrder >= 3 and Child.Visible then
                        Child.Visible = false
                        table.insert(Hidden, Child)
                    end
                end
            end
            if Element.TitleLabel then
                Library:Tween(Element.TitleLabel, FAST, { TextTransparency = 0.45 })
            end
            if Element.DescLabel then
                Library:Tween(Element.DescLabel, FAST, { TextTransparency = 0.6 })
            end
        else
            for _, Child in ipairs(Hidden) do
                if Child.Parent then
                    Child.Visible = true
                end
            end
            table.clear(Hidden)
            if Element.TitleLabel then
                Library:Tween(Element.TitleLabel, FAST, { TextTransparency = 0 })
            end
            if Element.DescLabel then
                Library:Tween(Element.DescLabel, FAST, { TextTransparency = 0 })
            end
        end
    end

    if Config and Config.Password then
        Text.Text = Config.Title or "Locked"
        Blocker.MouseEnter:Connect(function()
            Library:Tween(ChipLine, FAST, { Color = Library.Theme.Accent, Transparency = 0.35 })
            Library:Tween(Icon, FAST, { ImageColor3 = Library.Theme.Accent })
            Library:Tween(Text, FAST, { TextColor3 = Library.Theme.Text })
        end)
        Blocker.MouseLeave:Connect(function()
            Library:Tween(ChipLine, FAST, {
                Color = Library.Theme.StrokeSoft,
                Transparency = Library.Theme.StrokeSoftAlpha
            })
            Library:Tween(Icon, FAST, { ImageColor3 = Library.Theme.TextDisabled })
            Library:Tween(Text, FAST, { TextColor3 = Library.Theme.TextDisabled })
        end)
        Blocker.MouseButton1Click:Connect(function()
            Library:Feedback(0.9)
            WM.Password(Window, {
                Title = Config.Title or "Locked element",
                Description = Config.Description or "Enter the password to unlock",
                Password = tostring(Config.Password),
                Remember = Config.Remember ~= false,
                Key = Config.Key or ("element_" .. tostring(Element.Title)),
                OnUnlock = function()
                    Element:SetLocked(false)
                end
            })
        end)
    end
    return Blocker
end

-- Builds the public element object: flags, auto-config, changed signal,
-- locking, palette registration.
local function Finish(Section, Kind, Config, Frame, Handlers, TitleLabel, DescLabel)
    local Window = Section.Window
    local Element = Library.Element.new({
        Kind = Kind,
        Frame = Frame,
        Section = Section,
        Handlers = Handlers,
        Title = Config.Title or Kind,
        Description = Config.Description or Config.Desc or "",
        TitleLabel = TitleLabel,
        DescLabel = DescLabel,
        Flag = Config.Flag,
        Changed = Signal.new(),
        Locked = false
    })

    if Config.Flag then
        Library.Options[Config.Flag] = Element
        Window.Flags[Config.Flag] = Element
    end

    Element.Emit = function(Value, Silent)
        Element.Value = Value
        if Config.Flag then
            Library.Flags[Config.Flag] = Value
        end
        if not Silent then
            Element.Changed:Fire(Value)
            if Config.Flag then
                Window.QueueSave()
            end
            if Config.Callback then
                task.spawn(function()
                    local Ok, Err = pcall(Config.Callback, Value)
                    if not Ok then
                        warn("[sh1ttybanana] " .. tostring(Element.Title) .. " callback: " .. tostring(Err))
                    end
                end)
            end
        end
    end

    Register(Section, Element)

    if Config.Lock or Config.Locked then
        LockOverlay(Element, type(Config.Lock) == "table" and Config.Lock or nil)
        Element:SetLocked(true, type(Config.Lock) == "table" and Config.Lock.Title or nil)
    else
        LockOverlay(Element, nil)
    end

    if Config.Visible == false then
        Element:SetVisible(false)
    end

    table.insert(Section.Elements, Element)
    return Element
end

-- ============================================================ window

local function ParentGui(Gui)
    local Done = pcall(function()
        if type(gethui) == "function" then
            Gui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(Gui)
            Gui.Parent = game:GetService("CoreGui")
        else
            Gui.Parent = game:GetService("CoreGui")
        end
    end)
    if not Done or not Gui.Parent then
        Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function RandomName()
    local Chars = "abcdefghijklmnopqrstuvwxyz"
    local Name = ""
    for _ = 1, 12 do
        local Index = math.random(1, #Chars)
        Name = Name .. Chars:sub(Index, Index)
    end
    return Name
end

function Library:NewWindow(UserConfig)
    local W = {}
    W.Config = Merge({
        Title = "sh1ttybanana",
        Description = "full featured",
        Logo = "rbxassetid://89646749075297",
        Icon = nil,
        Color = Color3.fromRGB(179, 0, 255),
        Theme = "Dark",
        Size = UDim2.fromOffset(700, 500),
        AutoScale = true,
        AutoPosition = "Center",
        Transparency = nil,
        Blur = true,
        Version = "v" .. Library.Version,
        Tag = "beta",
        FolderName = "sh1ttybanana",
        ConfigName = "default",
        AutoSave = true,
        AutoLoad = true,
        ToggleKey = Enum.KeyCode.RightShift,
        PaletteKey = Enum.KeyCode.K,
        CloseKey = nil,
        ShowPlayerCard = true,
        ShowAI = true,
        Sound = false,
        Particles = true,
        GroqApiKey = nil,
        GroqPrompt = nil,
        GroqModel = nil,
        -- optional, off unless a table is passed
        KeySystem = nil
    }, UserConfig or {})

    W.Tabs = {}
    W.Groups = {}
    W.Index = {}
    W.Flags = {}
    W.Keybinds = {}
    W.Notifications = {}
    W.Connections = {}
    W.Pending = {}
    W.Favorites = {}
    W.Recent = {}
    W.Mobile = Device.IsMobile()
    W.Open = true
    W.Maximized = false

    Library.Sound = W.Config.Sound == true
    Library.Particles = W.Config.Particles ~= false

    if typeof(W.Config.Color) == "Color3" then
        for _, Tokens in pairs(Library.Themes) do
            Tokens.Accent = W.Config.Color
        end
    end
    if Library.Themes[W.Config.Theme] then
        Library.CurrentTheme = W.Config.Theme
        Library.Theme = Library.Themes[W.Config.Theme]
    end
    if type(W.Config.Transparency) == "number" then
        Library.Theme.WindowAlpha = W.Config.Transparency
    end

    -- ---------------------------------------------------------- storage

    W.Paths = {
        Root = "sh1ttybanana",
        Folder = "sh1ttybanana/" .. tostring(W.Config.FolderName),
        Configs = "sh1ttybanana/" .. tostring(W.Config.FolderName) .. "/configs"
    }
    W.Paths.State = W.Paths.Folder .. "/state.json"
    FS.Folder(W.Paths.Configs)
    W.State = FS.ReadJSON(W.Paths.State) or {}
    W.Profile = W.State.Profile or W.Config.ConfigName

    if W.State.Theme and Library.Themes[W.State.Theme] then
        Library.CurrentTheme = W.State.Theme
        Library.Theme = Library.Themes[W.State.Theme]
    end
    if type(W.State.Accent) == "table" and #W.State.Accent == 3 then
        local Saved = Color3.fromRGB(W.State.Accent[1], W.State.Accent[2], W.State.Accent[3])
        for _, Tokens in pairs(Library.Themes) do
            Tokens.Accent = Saved
        end
    end
    if type(W.State.Sound) == "boolean" then
        Library.Sound = W.State.Sound
    end
    if type(W.State.Particles) == "boolean" then
        Library.Particles = W.State.Particles
    end

    function W.SaveState()
        W.State.Profile = W.Profile
        W.State.Theme = Library.CurrentTheme
        W.State.Sound = Library.Sound
        W.State.Particles = Library.Particles
        local Accent = Library.Theme.Accent
        W.State.Accent = {
            math.floor(Accent.R * 255 + 0.5),
            math.floor(Accent.G * 255 + 0.5),
            math.floor(Accent.B * 255 + 0.5)
        }
        if W.Root then
            W.State.Position = { W.Root.Position.X.Offset, W.Root.Position.Y.Offset }
        end
        FS.WriteJSON(W.Paths.State, W.State)
    end

    -- ---------------------------------------------------------- shell

    W.Gui = New("ScreenGui", {
        Name = RandomName(),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999
    })
    ParentGui(W.Gui)

    -- ---------------------------------------------------------- key system
    -- Optional: only runs if UserConfig.KeySystem is a table. Blocks the
    -- rest of the window from building until a valid key is entered, or
    -- instantly skips if a previously-accepted key was saved to disk.
    if type(W.Config.KeySystem) == "table" and W.Config.KeySystem.Enabled ~= false then
        local KeyCfg = Merge({
            Title = "Key Required",
            Note = "",
            Keys = {},
            GetKeyLink = nil,
            SaveKey = true,
            Callback = nil
        }, W.Config.KeySystem)

        local function IsValidKey(Value)
            if type(KeyCfg.Callback) == "function" then
                local Ok, Result = pcall(KeyCfg.Callback, Value)
                return Ok and Result == true
            end
            for _, K in ipairs(KeyCfg.Keys) do
                if tostring(K) == Value then
                    return true
                end
            end
            return false
        end

        W.Paths.KeyFile = W.Paths.Folder .. "/key.txt"

        local Skip = false
        if KeyCfg.SaveKey ~= false then
            local Saved = FS.Read(W.Paths.KeyFile)
            if Saved and IsValidKey(Trim(Saved)) then
                Skip = true
            end
        end

        if not Skip then
            local Gate = New("Frame", {
                Parent = W.Gui,
                Name = "KeyGate",
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 1000
            })

            local Card = New("Frame", {
                Parent = Gate,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BorderSizePixel = 0,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(340, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 1001
            })
            Library:Corner(Card, 14)
            Library:Themed(Card, "BackgroundColor3", "Card")
            Library:Themed(Card, "BackgroundTransparency", "CardAlpha")
            Library:Stroke(Card, "Stroke", 1.2)
            Library:Shadow(Card, 60, 0.55)

            New("UIPadding", {
                Parent = Card,
                PaddingTop = UDim.new(0, 22),
                PaddingBottom = UDim.new(0, 20),
                PaddingLeft = UDim.new(0, 22),
                PaddingRight = UDim.new(0, 22)
            })
            New("UIListLayout", {
                Parent = Card,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 12)
            })

            local LockIcon = IconLabel(Card, Library.Icons.Lock, 26, "Accent")
            LockIcon.LayoutOrder = 0
            Library:Themed(LockIcon, "ImageColor3", "Accent")

            local GateTitle = New("TextLabel", {
                Parent = Card,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                Font = Library.Font.Bold,
                Text = KeyCfg.Title,
                TextSize = 17,
                LayoutOrder = 1
            })
            Library:Themed(GateTitle, "TextColor3", "Text")

            if KeyCfg.Note ~= "" then
                local GateNote = New("TextLabel", {
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Library.Font.Regular,
                    Text = KeyCfg.Note,
                    TextSize = 12,
                    TextWrapped = true,
                    LayoutOrder = 2
                })
                Library:Themed(GateNote, "TextColor3", "TextDim")
            end

            local Field = New("Frame", {
                Parent = Card,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 38),
                LayoutOrder = 3
            })
            Library:Corner(Field, 9)
            Library:Themed(Field, "BackgroundColor3", "Inset")
            Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
            local FieldLine = Library:Stroke(Field, "StrokeSoft", 1)

            local Box = New("TextBox", {
                Parent = Field,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -24, 1, 0),
                Font = Library.Font.Regular,
                PlaceholderText = "Enter key",
                Text = "",
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false
            })
            Library:Themed(Box, "TextColor3", "Text")
            Library:Themed(Box, "PlaceholderColor3", "TextDisabled")

            local GateError = New("TextLabel", {
                Parent = Card,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Font = Library.Font.Regular,
                Text = "",
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 4
            })
            Library:Themed(GateError, "TextColor3", "Error")

            local GateRow = Blank(Card, {
                Size = UDim2.new(1, 0, 0, 34),
                LayoutOrder = 5
            })
            New("UIListLayout", {
                Parent = GateRow,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            if KeyCfg.GetKeyLink then
                local GetKeyBtn = PillButton(GateRow, "Get Key", nil, 0)
                GetKeyBtn.Size = UDim2.new(0.42, -4, 1, 0)
                GetKeyBtn.LayoutOrder = 1
                GetKeyBtn.MouseButton1Click:Connect(function()
                    pcall(function()
                        if setclipboard then
                            setclipboard(KeyCfg.GetKeyLink)
                        end
                    end)
                    pcall(function()
                        if GuiService and GuiService.OpenBrowserWindow then
                            GuiService:OpenBrowserWindow(KeyCfg.GetKeyLink)
                        end
                    end)
                    GateError.Text = "Link copied to clipboard"
                    Library:Themed(GateError, "TextColor3", "TextDim")
                end)
            end

            local SubmitBtn = PillButton(GateRow, "Verify", Library.Icons.Check, 0, true)
            SubmitBtn.Size = UDim2.new(KeyCfg.GetKeyLink and 0.58 or 1, KeyCfg.GetKeyLink and -4 or 0, 1, 0)
            SubmitBtn.LayoutOrder = 2

            local Verified = false
            local function TrySubmit()
                local Value = Trim(Box.Text)
                if Value == "" then
                    return
                end
                if IsValidKey(Value) then
                    if KeyCfg.SaveKey ~= false then
                        FS.Folder(W.Paths.Folder)
                        FS.Write(W.Paths.KeyFile, Value)
                    end
                    Verified = true
                else
                    GateError.Text = "Invalid key"
                    Library:Themed(GateError, "TextColor3", "Error")
                    Library:Tween(FieldLine, FAST, { Color = Library.Theme.Error })
                    task.delay(0.3, function()
                        pcall(function()
                            Library:Tween(FieldLine, FAST, { Color = Library.Theme.StrokeSoft })
                        end)
                    end)
                end
            end

            SubmitBtn.MouseButton1Click:Connect(TrySubmit)
            Box.FocusLost:Connect(function(Enter)
                if Enter then
                    TrySubmit()
                end
            end)
            task.defer(function()
                Box:CaptureFocus()
            end)

            while not Verified and W.Gui.Parent do
                task.wait()
            end

            if Gate.Parent then
                Library:Tween(Gate, FAST, { BackgroundTransparency = 1 })
                Library:Tween(Card, FAST, { BackgroundTransparency = 1 })
                task.wait(0.15)
                Gate:Destroy()
            end
        end
    end

    if W.Config.Blur then
        pcall(function()
            W.Blur = New("BlurEffect", { Parent = Lighting, Size = 0, Name = RandomName() })
        end)
    end

    W.Root = New("Frame", {
        Parent = W.Gui,
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = W.Config.Size
    })
    W.Scale = New("UIScale", { Parent = W.Root, Scale = 1 })

    W.Main = New("Frame", {
        Parent = W.Root,
        Name = "Main",
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 2
    })
    Library:Corner(W.Main, 14)
    Library:Themed(W.Main, "BackgroundColor3", "Main")
    Library:Themed(W.Main, "BackgroundTransparency", "WindowAlpha")

    -- v1 edge: the window is outlined in the accent, not a neutral grey
    local MainStroke = New("UIStroke", {
        Parent = W.Main,
        Thickness = 1.4,
        Transparency = 0.55,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(MainStroke, "Color", "Accent")
    Library:Gradient(W.Main, {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(214, 214, 224)
    }, 90)
    Library:Shadow(W.Root, 80, 0.62)

    W.Sheen = Library:Sheen(W.Main, 90)
    W.Sheen.ZIndex = 2

    -- ---------------------------------------------------------- fitting

    function W.Fit()
        local Viewport = Device.Viewport()
        local Wanted = W.Config.Size
        local Width, Height
        local Scale = 1

        -- no enforced minimum: the configured size is used as-is on every
        -- device. The only floor left is a 1px technical guard so layout
        -- math never divides by zero -- it isn't a usability limit.
        if W.Mobile then
            Width = math.max(Viewport.X - 16, 1)
            Height = math.max(Viewport.Y - 70, 1)
        elseif W.Maximized then
            Width = Viewport.X - 40
            Height = Viewport.Y - 60
        else
            Width = math.max(Wanted.X.Offset, 1)
            Height = math.max(Wanted.Y.Offset, 1)
            -- the window keeps its designed size and only shrinks when the
            -- viewport cannot hold it, it never blows up on a big monitor
            if W.Config.AutoScale then
                Scale = Clamp(math.min((Viewport.X - 40) / Width, (Viewport.Y - 60) / Height), 0.4, 1)
            else
                Width = math.min(Width, Viewport.X - 40)
                Height = math.min(Height, Viewport.Y - 60)
            end
        end

        W.Root.Size = UDim2.fromOffset(Width, Height)
        W.Scale.Scale = Scale
        W.Clamp()
        W.Relayout()
    end

    function W.Clamp()
        local Viewport = Device.Viewport()
        local Size = W.Root.AbsoluteSize
        local Half = Size / 2
        local Position = W.Root.Position
        local X = Position.X.Offset
        local Y = Position.Y.Offset

        if Position.X.Scale ~= 0 or Position.Y.Scale ~= 0 then
            X = Position.X.Scale * Viewport.X + X - Viewport.X / 2
            Y = Position.Y.Scale * Viewport.Y + Y - Viewport.Y / 2
        end
        local LimitX = math.max(Viewport.X / 2 - Half.X + 8, 0)
        local LimitY = math.max(Viewport.Y / 2 - Half.Y + 8, 0)
        W.Root.Position = UDim2.new(0.5, Clamp(X, -LimitX, LimitX), 0.5, Clamp(Y, -LimitY, LimitY))
    end

    local function ApplyStartPosition()
        local Mode = W.Config.AutoPosition
        if typeof(Mode) == "UDim2" then
            W.Root.Position = Mode
        elseif Mode == "Remember" and type(W.State.Position) == "table" then
            W.Root.Position = UDim2.new(0.5, W.State.Position[1], 0.5, W.State.Position[2])
        else
            W.Root.Position = UDim2.fromScale(0.5, 0.5)
        end
    end

    -- ---------------------------------------------------------- header

    W.Header = New("Frame", {
        Parent = W.Main,
        Name = "Header",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, W.Mobile and 56 or 54),
        ZIndex = 4
    })

    W.HeaderLine = New("Frame", {
        Parent = W.Header,
        AnchorPoint = Vector2.new(0, 1),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 4
    })
    Library:FadeLine(W.HeaderLine, true)

    local Brand = Blank(W.Header, {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        ZIndex = 5
    })

    W.LogoTile = New("Frame", {
        Parent = Brand,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(36, 36),
        BackgroundTransparency = 0.86,
        ClipsDescendants = true,
        ZIndex = 5
    })
    Library:Corner(W.LogoTile, 9)
    Library:Themed(W.LogoTile, "BackgroundColor3", "Accent")
    local LogoStroke = New("UIStroke", { Parent = W.LogoTile, Thickness = 1, Transparency = 0.62 })
    Library:Themed(LogoStroke, "Color", "Accent")

    W.LogoImage = New("ImageLabel", {
        Parent = W.LogoTile,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        Image = W.Config.Logo or "",
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 6
    })
    if W.Config.Icon then
        Library:SetIcon(W.LogoImage, W.Config.Icon, Library.Theme.AccentText)
    end

    local TitleStack = Blank(Brand, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 46, 0.5, 0),
        Size = UDim2.new(1, -376, 0, 36),
        ZIndex = 5
    })

    W.TitleLabel = New("TextLabel", {
        Parent = TitleStack,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 18),
        Font = Library.Font.Bold,
        Text = W.Config.Title,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5
    })
    Library:Themed(W.TitleLabel, "TextColor3", "Text")

    local SubRow = Blank(TitleStack, {
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 5
    })
    New("UIListLayout", {
        Parent = SubRow,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    W.SubLabel = New("TextLabel", {
        Parent = SubRow,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 16),
        Font = Library.Font.Regular,
        Text = W.Config.Description or "",
        TextSize = 11,
        LayoutOrder = 1,
        ZIndex = 5
    })
    Library:Themed(W.SubLabel, "TextColor3", "TextDim")

    local function Badge(Text, ColorKey, Order)
        if not Text or Text == "" then
            return
        end
        local Holder = New("Frame", {
            Parent = SubRow,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(0, 16),
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = Order,
            BackgroundTransparency = 0.82,
            ZIndex = 5
        })
        Library:Corner(Holder, 6)
        Library:Themed(Holder, "BackgroundColor3", ColorKey)
        New("UIPadding", {
            Parent = Holder,
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6)
        })
        local Text2 = New("TextLabel", {
            Parent = Holder,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 16),
            Font = Library.Font.Bold,
            Text = Text,
            TextSize = 10,
            ZIndex = 6
        })
        Library:Themed(Text2, "TextColor3", ColorKey)
        return Holder
    end

    Badge(W.Config.Version, "Accent", 2)
    Badge(W.Config.Tag, "Success", 3)

    -- header controls
    W.Controls = Blank(W.Header, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 320, 0, 30),
        ZIndex = 5
    })
    New("UIListLayout", {
        Parent = W.Controls,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local function Control(IconName, Tip, Order, Handler, MobileVisible)
        local Button = GlyphButton(W.Controls, IconName, Tip)
        Button.LayoutOrder = Order
        Button.ZIndex = 6
        -- touch clients get the same controls as desktop, nothing is dropped
        Button.Visible = true
        Button.MouseButton1Click:Connect(function()
            Library:Feedback(1.1)
            Handler()
        end)
        return Button
    end

    W.MenuButton = Control(Library.Icons.Menu, "Tabs", 0, function()
        W.ToggleDrawer()
    end, true)
    W.MenuButton.Visible = false

    Control(Library.Icons.Command, "Command palette (Ctrl+K)", 1, function()
        WM.Palette(W)
    end, false)
    Control(Library.Icons.Palette, "Theme", 2, function()
        WM.ThemePanel(W)
    end, true)
    Control(Library.Icons.Save, "Configs", 3, function()
        WM.ConfigPanel(W)
    end, false)
    Control(Library.Icons.Key, "Keybinds", 4, function()
        WM.KeybindPanel(W)
    end, false)
    if W.Config.ShowAI then
        Control(Library.Icons.Bot, "AI assistant", 5, function()
            WM.ToggleAI(W)
        end, false)
    end
    if W.Config.ShowPlayerCard then
        Control(Library.Icons.User, "Player card", 6, function()
            WM.TogglePlayerCard(W)
        end, false)
    end
    Control(Library.Icons.Minimize, "Minimize", 7, function()
        W.SetOpen(false)
    end, true)
    W.MaxButton = Control(Library.Icons.Maximize, "Maximize", 8, function()
        W.Maximized = not W.Maximized
        Library:SetIcon(W.MaxButton:FindFirstChildOfClass("ImageLabel"),
            W.Maximized and Library.Icons.Restore or Library.Icons.Maximize)
        W.Fit()
    end, false)
    Control(Library.Icons.Close, "Close", 9, function()
        W.API:Destroy()
    end, true)

    -- ---------------------------------------------------------- body

    W.Body = Blank(W.Main, {
        Name = "Body",
        Position = UDim2.new(0, 0, 0, W.Header.Size.Y.Offset),
        Size = UDim2.new(1, 0, 1, -W.Header.Size.Y.Offset),
        ZIndex = 3
    })

    -- narrow screens get a tighter sidebar instead of losing it to a drawer
    W.SidebarWidth = Device.Viewport().X < 560 and 140 or 156
    W.Inset = 0

    -- v1 layout: a surface film panel closed by a fading accent line, always
    -- in the layout on every device.
    W.Sidebar = New("Frame", {
        Parent = W.Body,
        Name = "Sidebar",
        BorderSizePixel = 0,
        Size = UDim2.new(0, W.SidebarWidth, 1, 0),
        ZIndex = 3
    })
    Library:Themed(W.Sidebar, "BackgroundColor3", "Sidebar")
    Library:Themed(W.Sidebar, "BackgroundTransparency", "SidebarAlpha")

    W.SidebarLine = New("Frame", {
        Parent = W.Sidebar,
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 4
    })
    Library:FadeLine(W.SidebarLine, false)

    -- search box
    W.SearchBox = New("Frame", {
        Parent = W.Sidebar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 12),
        Size = UDim2.new(1, -21, 0, W.Mobile and 36 or 32),
        ZIndex = 4
    })
    Library:Corner(W.SearchBox, 8)
    Library:Themed(W.SearchBox, "BackgroundColor3", "Card")
    W.SearchBox.BackgroundTransparency = 0.93
    Library:Stroke(W.SearchBox, "StrokeSoft", 1)

    local SearchIcon = IconLabel(W.SearchBox, Library.Icons.Search, 14, "Accent")
    SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    SearchIcon.Position = UDim2.new(0, 10, 0.5, 0)
    SearchIcon.ZIndex = W.Sidebar.ZIndex + 2

    W.SearchInput = New("TextBox", {
        Parent = W.SearchBox,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Library.Font.Regular,
        PlaceholderText = "Search",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = W.Sidebar.ZIndex + 2
    })
    Library:Themed(W.SearchInput, "TextColor3", "Text")
    Library:Themed(W.SearchInput, "PlaceholderColor3", "TextDisabled")

    W.TabScroll = New("ScrollingFrame", {
        Parent = W.Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, W.SearchBox.Size.Y.Offset + 20),
        Size = UDim2.new(1, -16, 1, -(W.SearchBox.Size.Y.Offset + 20 + 44)),
        ZIndex = W.Sidebar.ZIndex + 1
    })
    Library:StyleScroll(W.TabScroll)

    New("UIPadding", {
        Parent = W.TabScroll,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3)
    })

    W.TabLayout = New("UIListLayout", {
        Parent = W.TabScroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })

    -- sidebar footer: active profile
    W.ProfileButton = New("TextButton", {
        Parent = W.Sidebar,
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -10),
        Size = UDim2.new(1, -24, 0, 30),
        Text = "",
        AutoButtonColor = false,
        ZIndex = W.Sidebar.ZIndex + 1
    })
    Library:Corner(W.ProfileButton, 8)
    Library:Themed(W.ProfileButton, "BackgroundColor3", "Row")
    Library:Themed(W.ProfileButton, "BackgroundTransparency", "RowAlpha")

    local ProfileIcon = IconLabel(W.ProfileButton, Library.Icons.Folder, 14, "Accent")
    ProfileIcon.AnchorPoint = Vector2.new(0, 0.5)
    ProfileIcon.Position = UDim2.new(0, 9, 0.5, 0)
    ProfileIcon.ZIndex = W.Sidebar.ZIndex + 2
    Library:Themed(ProfileIcon, "ImageColor3", "Accent")

    W.ProfileLabel = New("TextLabel", {
        Parent = W.ProfileButton,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(1, -38, 1, 0),
        Font = Library.Font.Medium,
        Text = W.Profile,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = W.Sidebar.ZIndex + 2
    })
    Library:Themed(W.ProfileLabel, "TextColor3", "TextDim")

    W.ProfileButton.MouseButton1Click:Connect(function()
        Library:Feedback(1.1)
        WM.ConfigPanel(W)
    end)

    -- ---------------------------------------------------------- content

    W.Content = Blank(W.Body, {
        Name = "Content",
        Position = UDim2.new(0, W.SidebarWidth, 0, 0),
        Size = UDim2.new(1, -W.SidebarWidth, 1, 0),
        ZIndex = 3
    })

    W.PageHeader = Blank(W.Content, {
        Size = UDim2.new(1, 0, 0, 46),
        ZIndex = 4
    })

    W.PageIcon = IconLabel(W.PageHeader, Library.Icons.Tab, 18, "Accent")
    W.PageIcon.AnchorPoint = Vector2.new(0, 0.5)
    W.PageIcon.Position = UDim2.new(0, 16, 0.5, 0)
    W.PageIcon.ZIndex = 5
    Library:Themed(W.PageIcon, "ImageColor3", "Accent")

    W.PageTitle = New("TextLabel", {
        Parent = W.PageHeader,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0.5, 0),
        Size = UDim2.new(1, -120, 0, 20),
        Font = Library.Font.Bold,
        Text = "",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5
    })
    Library:Themed(W.PageTitle, "TextColor3", "Text")

    W.PageDesc = New("TextLabel", {
        Parent = W.PageHeader,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0.5, 8),
        Size = UDim2.new(1, -120, 0, 14),
        Font = Library.Font.Regular,
        Text = "",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = false,
        ZIndex = 5
    })
    Library:Themed(W.PageDesc, "TextColor3", "TextDim")

    W.FavButton = GlyphButton(W.PageHeader, Library.Icons.Star, "Favorite")
    W.FavButton.AnchorPoint = Vector2.new(1, 0.5)
    W.FavButton.Position = UDim2.new(1, -12, 0.5, 0)
    W.FavButton.ZIndex = 5

    W.PageLine = New("Frame", {
        Parent = W.Content,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 46),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0.92,
        ZIndex = 4
    })
    Library:Themed(W.PageLine, "BackgroundColor3", "Stroke")

    W.Pages = Blank(W.Content, {
        Name = "Pages",
        Position = UDim2.new(0, 0, 0, 47),
        Size = UDim2.new(1, 0, 1, -47),
        ZIndex = 3
    })

    -- title text lifts up when the tab has a description, so an empty
    -- description never leaves a dead band under the header
    function W.SetPageHead(Title, Description, Icon)
        W.PageTitle.Text = Title or ""
        local HasDesc = (Description or "") ~= ""
        W.PageDesc.Text = Description or ""
        W.PageDesc.Visible = HasDesc
        W.PageTitle.Position = UDim2.new(0, 42, 0.5, HasDesc and -8 or 0)
        Library:SetIcon(W.PageIcon, Icon or Library.Icons.Tab, Library.Theme.Accent)
    end

    -- ---------------------------------------------------------- mobile drawer

    W.Backdrop = New("TextButton", {
        Parent = W.Body,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 20
    })

    W.DrawerOpen = true

    -- kept for API compatibility, the sidebar is always in the layout now
    function W.ToggleDrawer()
    end

    function W.Relayout()
        local HeaderHeight = W.Header.Size.Y.Offset
        W.Body.Position = UDim2.new(0, 0, 0, HeaderHeight)
        W.Body.Size = UDim2.new(1, 0, 1, -HeaderHeight)
        W.Content.Position = UDim2.new(0, W.SidebarWidth, 0, 0)
        W.Content.Size = UDim2.new(1, -W.SidebarWidth, 1, 0)
    end

    -- ---------------------------------------------------------- dragging

    do
        local Dragging, Origin, StartPosition = false, nil, nil
        local function Begin(Input)
            Dragging = true
            Origin = Input.Position
            StartPosition = W.Root.Position
        end
        W.Header.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                Begin(Input)
            end
        end)
        table.insert(W.Connections, UserInputService.InputChanged:Connect(function(Input)
            if not Dragging then
                return
            end
            if Input.UserInputType == Enum.UserInputType.MouseMovement
                or Input.UserInputType == Enum.UserInputType.Touch then
                local Delta = Input.Position - Origin
                W.Root.Position = UDim2.new(
                    StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
                    StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
                )
            end
        end))
        table.insert(W.Connections, UserInputService.InputEnded:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch) then
                Dragging = false
                W.Clamp()
                W.SaveState()
            end
        end))
    end

    -- ---------------------------------------------------------- visibility

    W.FloatButton = New("TextButton", {
        Parent = W.Gui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 70, 0.5, 0),
        Size = UDim2.fromOffset(W.Mobile and 54 or 46, W.Mobile and 54 or 46),
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 50
    })
    Library:Corner(W.FloatButton, UDim.new(1, 0))
    Library:Themed(W.FloatButton, "BackgroundColor3", "Main")
    Library:Stroke(W.FloatButton, "Stroke", 1.2)
    Library:Shadow(W.FloatButton, 40, 0.6)

    local FloatIcon = New("ImageLabel", {
        Parent = W.FloatButton,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W.Mobile and 28 or 24, W.Mobile and 28 or 24),
        Image = W.Config.Logo or "",
        ZIndex = 51
    })

    do
        local Dragging, Moved, Origin, StartPosition = false, false, nil, nil
        W.FloatButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging, Moved = true, false
                Origin = Input.Position
                StartPosition = W.FloatButton.Position
            end
        end)
        table.insert(W.Connections, UserInputService.InputChanged:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
                or Input.UserInputType == Enum.UserInputType.Touch) then
                local Delta = Input.Position - Origin
                if Delta.Magnitude > 6 then
                    Moved = true
                end
                W.FloatButton.Position = UDim2.new(
                    StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
                    StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
                )
            end
        end))
        table.insert(W.Connections, UserInputService.InputEnded:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch) then
                Dragging = false
                if not Moved then
                    W.SetOpen(true)
                end
            end
        end))
    end

    function W.SetOpen(State)
        if State == nil then
            State = not W.Open
        end
        W.Open = State
        if State then
            W.Root.Visible = true
            W.FloatButton.Visible = false
            Library:Pop(W.Main, 0.32, 0.94)
            Library:Tween(W.Main, NORMAL, { BackgroundTransparency = Library.Theme.WindowAlpha })
            if W.Blur then
                Library:Tween(W.Blur, NORMAL, { Size = Library.Theme.Blur })
            end
        else
            W.FloatButton.Visible = true
            Library:Pop(W.FloatButton, 0.3, 0.8)
            W.Root.Visible = false
            if W.Blur then
                Library:Tween(W.Blur, FAST, { Size = 0 })
            end
        end
        Library:Feedback(State and 1.1 or 0.9)
    end

    -- ---------------------------------------------------------- global input

    table.insert(W.Connections, UserInputService.InputBegan:Connect(function(Input, Typing)
        if Typing then
            return
        end
        if Input.KeyCode == W.Config.ToggleKey then
            W.SetOpen()
        elseif Input.KeyCode == W.Config.PaletteKey
            and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
            WM.Palette(W)
        end
        WM.FireKeybinds(W, Input)
    end))

    table.insert(W.Connections, UserInputService.InputEnded:Connect(function(Input)
        WM.FireKeybinds(W, Input, true)
    end))

    local Camera = workspace.CurrentCamera
    if Camera then
        table.insert(W.Connections, Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            local WasMobile = W.Mobile
            W.Mobile = Device.IsMobile()
            if WasMobile ~= W.Mobile then
                W.Relayout()
            end
            W.Fit()
        end))
    end

    -- ---------------------------------------------------------- config io

    W.SaveQueued = false

    function W.QueueSave()
        if not W.Config.AutoSave or W.SaveQueued then
            return
        end
        W.SaveQueued = true
        task.delay(0.75, function()
            W.SaveQueued = false
            W.API:SaveConfig(W.Profile)
        end)
    end

    ApplyStartPosition()
    W.Fit()
    return WM.BuildAPI(W)
end

-- ============================================================ tabs

local ComponentNames = {
    "Toggle", "Button", "Input", "Slider", "Dropdown", "Keybind",
    "Colorpicker", "ColorpickerRGB", "MultiButton", "Paragraph", "Label",
    "Tag", "Codeblock", "Progress", "Grid", "Table", "Image", "Viewport",
    "Separator", "Divider", "Space"
}

local Aliases = {
    AddSeperator = "AddSeparator",
    AddTextbox = "AddInput",
    AddTextBox = "AddInput",
    AddColorPicker = "AddColorpicker",
    AddColorPickerRGB = "AddColorpickerRGB",
    AddLine = "AddDivider"
}

local function BuildSection(Tab, Config)
    local W = Tab.Window
    if type(Config) == "string" then
        Config = { Title = Config }
    end
    Config = Merge({
        Title = "Section",
        Description = "",
        Opened = true,
        Collapsible = false,
        Headerless = false,
        Lock = nil
    }, Config or {})

    local Section = {
        Window = W,
        Tab = Tab,
        Title = Config.Title,
        Elements = {},
        Count = 0,
        Opened = Config.Opened ~= false
    }

    local Card = New("Frame", {
        Parent = Tab.Page,
        Name = "Section",
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = Config.Headerless and 1 or 0,
        LayoutOrder = Tab.SectionCount + 1,
        ClipsDescendants = false
    })
    Tab.SectionCount = Tab.SectionCount + 1
    Section.Frame = Card

    if not Config.Headerless then
        Library:Corner(Card, 9)
        Library:Themed(Card, "BackgroundColor3", "Card")
        Library:Themed(Card, "BackgroundTransparency", "CardAlpha")
        Library:Stroke(Card, "Stroke", 1)
    end

    New("UIPadding", {
        Parent = Card,
        PaddingTop = UDim.new(0, Config.Headerless and 0 or 10),
        PaddingBottom = UDim.new(0, Config.Headerless and 0 or 10),
        PaddingLeft = UDim.new(0, Config.Headerless and 0 or 10),
        PaddingRight = UDim.new(0, Config.Headerless and 0 or 10)
    })

    New("UIListLayout", {
        Parent = Card,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })

    local Header
    if not Config.Headerless then
        Header = New("TextButton", {
            Parent = Card,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 24),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = 0
        })

        local HeaderTitle = New("TextLabel", {
            Parent = Header,
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 4, 0.5, 0),
            Size = UDim2.new(1, -30, 0, 18),
            Font = Library.Font.Bold,
            Text = Config.Title,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        Library:Themed(HeaderTitle, "TextColor3", "Text")
        Section.TitleLabel = HeaderTitle

        local Chevron = IconLabel(Header, Library.Icons.Right, 14, "TextDisabled")
        Chevron.AnchorPoint = Vector2.new(1, 0.5)
        Chevron.Position = UDim2.new(1, -4, 0.5, 0)
        Chevron.Rotation = Section.Opened and 90 or 0
        Chevron.Visible = Config.Collapsible == true

        if Config.Collapsible then
            Header.MouseButton1Click:Connect(function()
                Section.Opened = not Section.Opened
                Library:Tween(Chevron, SPRING, { Rotation = Section.Opened and 90 or 0 })
                Section.Body.Visible = Section.Opened
                Library:Feedback(1.05)
            end)
        end
    end

    Section.Body = New("Frame", {
        Parent = Card,
        Name = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1
    })
    New("UIListLayout", {
        Parent = Section.Body,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })

    local API = {}
    Section.API = API
    API.Instance = Card
    API.Section = Section

    for _, Name in ipairs(ComponentNames) do
        API["Add" .. Name] = function(_, ElementConfig)
            local Builder = Components[Name]
            if not Builder then
                return
            end
            return Builder(Section, type(ElementConfig) == "table" and ElementConfig or { Title = ElementConfig })
        end
    end
    for Alias, Target in pairs(Aliases) do
        API[Alias] = function(Self, ElementConfig)
            return API[Target](Self, ElementConfig)
        end
    end

    function API:SetTitle(Text)
        if Section.TitleLabel then
            Section.TitleLabel.Text = tostring(Text)
        end
        Section.Title = tostring(Text)
    end

    function API:SetVisible(State)
        Card.Visible = State ~= false
    end

    function API:SetLocked(State, Reason)
        for _, Element in ipairs(Section.Elements) do
            Element:SetLocked(State, Reason)
        end
        Section.Locked = State and true or false
    end

    function API:Clear()
        for _, Element in ipairs(table.clone(Section.Elements)) do
            Element:Destroy()
        end
        table.clear(Section.Elements)
        Section.Count = 0
    end

    function API:Destroy()
        API:Clear()
        Card:Destroy()
    end

    if Config.Lock then
        task.defer(function()
            API:SetLocked(true, type(Config.Lock) == "table" and Config.Lock.Title or "Locked")
        end)
    end

    table.insert(Tab.Sections, Section)
    return API
end

local function BuildTab(W, Config, Group)
    if type(Config) == "string" then
        Config = { Title = Config }
    end
    Config = Merge({
        Title = "Tab",
        Icon = Library.Icons.Tab,
        Description = "",
        Lock = nil,
        LockPassword = nil
    }, Config or {})
    Config.Title = Config.Title or Config.Name or "Tab"

    local Tab = {
        Window = W,
        Name = Config.Title,
        Icon = Config.Icon,
        Description = Config.Description,
        Sections = {},
        SectionCount = 0,
        Group = Group
    }

    Tab.Page = New("ScrollingFrame", {
        Parent = W.Pages,
        Name = "Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 3
    })
    Library:StyleScroll(Tab.Page)
    New("UIPadding", {
        Parent = Tab.Page,
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14)
    })
    New("UIListLayout", {
        Parent = Tab.Page,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })

    -- sidebar button
    local Height = W.Mobile and 42 or 36
    Tab.Button = New("TextButton", {
        Parent = Group and Group.Holder or W.TabScroll,
        Name = "TabButton",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Height),
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #W.Tabs + 1,
        ZIndex = W.Sidebar.ZIndex + 1
    })
    Library:Corner(Tab.Button, 8)
    Library:Themed(Tab.Button, "BackgroundColor3", "Accent")
    Tab.Button.BackgroundTransparency = 1

    Tab.Indicator = New("Frame", {
        Parent = Tab.Button,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 0),
        ZIndex = W.Sidebar.ZIndex + 2
    })
    Library:Corner(Tab.Indicator, UDim.new(1, 0))
    Library:Themed(Tab.Indicator, "BackgroundColor3", "Accent")

    Tab.IconLabel = IconLabel(Tab.Button, Config.Icon, W.Mobile and 18 or 16, "Accent")
    Tab.IconLabel.AnchorPoint = Vector2.new(0, 0.5)
    Tab.IconLabel.Position = UDim2.new(0, 11, 0.5, 0)
    Tab.IconLabel.ImageTransparency = 0.35
    Library:Themed(Tab.IconLabel, "ImageColor3", "Accent")
    Tab.IconLabel.ZIndex = W.Sidebar.ZIndex + 2

    Tab.Label = New("TextLabel", {
        Parent = Tab.Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, W.Mobile and 38 or 34, 0, 0),
        Size = UDim2.new(1, -56, 1, 0),
        Font = Library.Font.Bold,
        Text = Config.Title,
        TextTransparency = 0.4,
        TextSize = W.Mobile and 13 or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = W.Sidebar.ZIndex + 2
    })
    Library:Themed(Tab.Label, "TextColor3", "TextDim")

    Tab.LockIcon = IconLabel(Tab.Button, Library.Icons.Lock, 13, "TextDisabled")
    Tab.LockIcon.AnchorPoint = Vector2.new(1, 0.5)
    Tab.LockIcon.Position = UDim2.new(1, -10, 0.5, 0)
    Tab.LockIcon.ZIndex = W.Sidebar.ZIndex + 2
    Tab.LockIcon.Visible = Config.Lock ~= nil

    Tab.Unlocked = Config.Lock == nil

    if Config.Lock then
        local LockConfig = type(Config.Lock) == "table" and Config.Lock or { Password = Config.LockPassword }
        local Remember = W.State["unlock_" .. Config.Title]
        if Remember and tostring(Remember) == tostring(LockConfig.Password) then
            Tab.Unlocked = true
            Tab.LockIcon.Visible = false
        end
        Tab.LockConfig = LockConfig
    end

    Tab.Button.MouseEnter:Connect(function()
        if W.Active ~= Tab then
            Library:Tween(Tab.Button, FAST, { BackgroundTransparency = 0.94 })
            Library:Tween(Tab.Label, FAST, { TextTransparency = 0.15 })
            Library:Tween(Tab.IconLabel, FAST, { ImageTransparency = 0.15 })
        end
    end)
    Tab.Button.MouseLeave:Connect(function()
        if W.Active ~= Tab then
            Library:Tween(Tab.Button, FAST, { BackgroundTransparency = 1 })
            Library:Tween(Tab.Label, FAST, { TextTransparency = 0.4 })
            Library:Tween(Tab.IconLabel, FAST, { ImageTransparency = 0.35 })
        end
    end)
    Tab.Button.MouseButton1Click:Connect(function()
        Library:Feedback(1.08)
        W.SelectTab(Tab)
    end)

    table.insert(W.Tabs, Tab)
    table.insert(W.Index, {
        Kind = "Tab",
        Name = Tab.Name,
        Tab = Tab.Name,
        Section = "",
        Jump = function()
            W.SelectTab(Tab)
        end
    })

    local API = {}
    Tab.API = API
    API.Instance = Tab.Page
    API.Tab = Tab

    function API:AddSection(SectionConfig, _, Headerless)
        if type(SectionConfig) == "string" then
            SectionConfig = { Title = SectionConfig, Headerless = Headerless }
        end
        return BuildSection(Tab, SectionConfig)
    end

    function API:AddTabSection(SectionConfig)
        if type(SectionConfig) == "string" then
            SectionConfig = { Title = SectionConfig }
        end
        SectionConfig = SectionConfig or {}
        SectionConfig.Collapsible = true
        return BuildSection(Tab, SectionConfig)
    end

    -- components added straight on the tab land in a lazily created card
    local function Default()
        if not Tab.DefaultSection then
            Tab.DefaultSection = BuildSection(Tab, { Title = Tab.Name, Headerless = true })
        end
        return Tab.DefaultSection
    end

    for _, Name in ipairs(ComponentNames) do
        API["Add" .. Name] = function(_, ElementConfig)
            return Default()["Add" .. Name](Default(), ElementConfig)
        end
    end
    for Alias, Target in pairs(Aliases) do
        API[Alias] = function(Self, ElementConfig)
            return API[Target](Self, ElementConfig)
        end
    end

    function API:Select()
        W.SelectTab(Tab)
    end

    function API:SetTitle(Text)
        Tab.Name = tostring(Text)
        Tab.Label.Text = Tab.Name
        if W.Active == Tab then
            W.SetPageHead(Tab.Name, Tab.Description, Tab.Icon)
        end
    end

    function API:SetIcon(Name)
        Tab.Icon = Name
        Library:SetIcon(Tab.IconLabel, Name)
    end

    function API:SetVisible(State)
        Tab.Button.Visible = State ~= false
    end

    function API:SetLocked(State, Password)
        Tab.Unlocked = not State
        Tab.LockIcon.Visible = State and true or false
        if State and Password then
            Tab.LockConfig = { Password = Password }
        end
    end

    function API:Destroy()
        for Index, Value in ipairs(W.Tabs) do
            if Value == Tab then
                table.remove(W.Tabs, Index)
                break
            end
        end
        Tab.Button:Destroy()
        Tab.Page:Destroy()
    end

    if #W.Tabs == 1 then
        task.defer(function()
            W.SelectTab(Tab)
        end)
    end
    return API
end

local function BuildGroup(W, Config)
    if type(Config) == "string" then
        Config = { Title = Config }
    end
    Config = Merge({ Title = "Group", Opened = true }, Config or {})

    local Group = { Window = W, Title = Config.Title, Opened = Config.Opened ~= false }

    Group.Frame = New("Frame", {
        Parent = W.TabScroll,
        Name = "Group",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #W.Groups + 1,
        ZIndex = W.Sidebar.ZIndex + 1
    })
    New("UIListLayout", {
        Parent = Group.Frame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3)
    })

    local Header = New("TextButton", {
        Parent = Group.Frame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26),
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = 0,
        ZIndex = W.Sidebar.ZIndex + 1
    })

    local HeaderLabel = New("TextLabel", {
        Parent = Header,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(1, -30, 0, 14),
        Font = Library.Font.Bold,
        Text = string.upper(Config.Title),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = W.Sidebar.ZIndex + 2
    })
    Library:Themed(HeaderLabel, "TextColor3", "TextDisabled")

    local Chevron = IconLabel(Header, Library.Icons.Down, 13, "TextDisabled")
    Chevron.AnchorPoint = Vector2.new(1, 0.5)
    Chevron.Position = UDim2.new(1, -8, 0.5, 0)
    Chevron.ZIndex = W.Sidebar.ZIndex + 2
    Chevron.Rotation = Group.Opened and 0 or -90

    Group.Holder = New("Frame", {
        Parent = Group.Frame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Visible = Group.Opened,
        ZIndex = W.Sidebar.ZIndex + 1
    })
    New("UIListLayout", {
        Parent = Group.Holder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3)
    })

    Header.MouseButton1Click:Connect(function()
        Group.Opened = not Group.Opened
        Group.Holder.Visible = Group.Opened
        Library:Tween(Chevron, SPRING, { Rotation = Group.Opened and 0 or -90 })
        Library:Feedback(1.02)
    end)

    table.insert(W.Groups, Group)

    local API = {}
    function API:Tab(Config2, IconName)
        if type(Config2) == "string" then
            Config2 = { Title = Config2, Icon = IconName }
        end
        return BuildTab(W, Config2, Group)
    end
    API.T = API.Tab
    API.AddTab = API.Tab
    function API:SetVisible(State)
        Group.Frame.Visible = State ~= false
    end
    function API:Destroy()
        Group.Frame:Destroy()
    end
    return API
end

-- ============================================================ overlays

local BindEscape

local function GetOverlay(W)
    if not W.Overlay then
        W.Overlay = Blank(W.Main, {
            Name = "Overlay",
            Size = UDim2.fromScale(1, 1),
            ZIndex = 100
        })
    end
    return W.Overlay
end

local function LocalPosition(W, Object)
    local Scale = W.Scale.Scale
    local Offset = Object.AbsolutePosition - W.Main.AbsolutePosition
    return Vector2.new(Offset.X / Scale, Offset.Y / Scale), Object.AbsoluteSize / Scale
end

-- floating panel anchored under a row, auto-flips when it would clip the bottom
local function Popup(W, Source, Width, Height)
    local Overlay = GetOverlay(W)
    local Backdrop = New("TextButton", {
        Parent = Overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 101
    })

    local Position, Size = LocalPosition(W, Source)
    local MainSize = W.Main.AbsoluteSize / W.Scale.Scale
    local X = Clamp(Position.X + Size.X - Width, 8, math.max(MainSize.X - Width - 8, 8))
    local Y = Position.Y + Size.Y + 6
    if Y + Height > MainSize.Y - 8 then
        Y = math.max(Position.Y - Height - 6, 8)
    end

    local Frame = New("Frame", {
        Parent = Overlay,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(X, Y),
        Size = UDim2.fromOffset(Width, Height),
        ZIndex = 102,
        ClipsDescendants = true
    })
    Library:Corner(Frame, 11)
    Library:Themed(Frame, "BackgroundColor3", "Elevated")
    Library:Themed(Frame, "BackgroundTransparency", "ElevatedAlpha")
    Library:Stroke(Frame, "Stroke", 1)
    Library:Shadow(Frame, 46, 0.55)
    Library:Pop(Frame, 0.24, 0.94)

    local Handle = {}
    Handle.Frame = Frame
    Handle.Open = true
    local Unbind = BindEscape(function()
        Handle:Close()
    end, W.Config.CloseKey)

    function Handle:Close()
        if not Handle.Open then
            return
        end
        Handle.Open = false
        Unbind()
        Backdrop:Destroy()
        Library:Tween(Frame, FAST, { BackgroundTransparency = 1 }, function()
            Frame:Destroy()
        end)
        if W.OpenPopup == Handle then
            W.OpenPopup = nil
        end
    end

    Backdrop.MouseButton1Click:Connect(function()
        Handle:Close()
    end)

    if W.OpenPopup then
        W.OpenPopup:Close()
    end
    W.OpenPopup = Handle
    return Handle
end

local function Boot(Section, Config, Element, Default)
    local Value = Default
    local FromConfig = false
    if Config.Flag then
        local Saved = Section.Window.Pending[Config.Flag]
        if Saved ~= nil then
            Value = Decode(Saved)
            FromConfig = true
        end
    end
    Element:Set(Value, not FromConfig)
    if Config.Flag then
        Library.Flags[Config.Flag] = Element:Get()
    end
end

-- ============================================================ toggle

function Components.Toggle(Section, Config)
    Config = Merge({
        Title = "Toggle",
        Description = "",
        Default = false,
        Flag = nil,
        Callback = function() end
    }, Config)

    local Row, TitleLabel, DescLabel = MakeRow(Section, "Toggle", Config.Title, Config.Description, 46, 46)

    local Track = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(Section.Window.Mobile and 46 or 40, Section.Window.Mobile and 25 or 22)
    })
    Library:Corner(Track, UDim.new(1, 0))
    Track.BackgroundColor3 = Color3.fromRGB(72, 72, 82)
    local TrackLine = Library:Stroke(Track, "StrokeSoft", 1)

    local Knob = New("Frame", {
        Parent = Track,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(Section.Window.Mobile and 20 or 17, Section.Window.Mobile and 20 or 17)
    })
    Library:Corner(Knob, UDim.new(1, 0))
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

    local Click = New("TextButton", {
        Parent = Row,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5
    })

    local State = false
    local Element

    local function Paint(Animated)
        local Info = Animated and TweenInfo.new(0.2, Back, Out) or TweenInfo.new(0)
        Library:Tween(Knob, Info, {
            Position = UDim2.new(0, State and (Track.Size.X.Offset - Knob.Size.X.Offset - 3) or 3, 0.5, 0)
        })
        Library:Tween(Track, FAST, {
            BackgroundColor3 = State and Library.Theme.Accent or Color3.fromRGB(72, 72, 82),
            BackgroundTransparency = 0
        })
        Library:Tween(Knob, FAST, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) })
        Library:Tween(TrackLine, FAST, { Transparency = State and 0.6 or Library.Theme.StrokeSoftAlpha })
    end

    local Handlers = {}
    function Handlers.Get()
        return State
    end
    function Handlers.Set(Value, Silent)
        State = Value and true or false
        Paint(not Silent)
        Element.Emit(State, Silent)
    end
    function Handlers.Lock(Locked)
        Click.Active = not Locked
    end

    Element = Finish(Section, "Toggle", Config, Row, Handlers, TitleLabel, DescLabel)

    -- the track colour depends on state, repaint it when the palette swaps
    Library.OnThemeChanged:Connect(function()
        Paint(false)
    end)

    Click.MouseButton1Click:Connect(function()
        if Element.Locked then
            return
        end
        Library:Feedback(State and 0.94 or 1.12)
        Handlers.Set(not State)
    end)

    Boot(Section, Config, Element, Config.Default and true or false)
    return Element
end

-- ============================================================ button

function Components.Button(Section, Config)
    Config = Merge({
        Title = "Button",
        Description = "",
        Confirm = false,
        Callback = function() end
    }, Config)

    local Row, TitleLabel, DescLabel = MakeRow(Section, "Button", Config.Title, Config.Description, 44, 30)

    local Arrow = IconLabel(Row, Library.Icons.Right, 16, "Accent")
    Arrow.AnchorPoint = Vector2.new(1, 0.5)
    Arrow.Position = UDim2.new(1, -14, 0.5, 0)
    Library:Themed(Arrow, "ImageColor3", "Accent")

    local Click = New("TextButton", {
        Parent = Row,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5
    })

    local Handlers = {}
    function Handlers.Get()
        return nil
    end
    function Handlers.Set()
    end

    local Element = Finish(Section, "Button", Config, Row, Handlers, TitleLabel, DescLabel)
    Element.Set = function(self)
        return self
    end

    local function Fire()
        Library:Feedback(1.15)
        Library:Tween(Arrow, TweenInfo.new(0.14, Quart, Out), { Position = UDim2.new(1, -8, 0.5, 0) }, function()
            Library:Tween(Arrow, SPRING, { Position = UDim2.new(1, -14, 0.5, 0) })
        end)
        Element.Changed:Fire(true)
        if Config.Callback then
            task.spawn(Config.Callback)
        end
    end

    Click.MouseButton1Click:Connect(function()
        if Element.Locked then
            return
        end
        if Config.Confirm then
            WM.Dialog(Section.Window, {
                Title = Config.Title,
                Description = type(Config.Confirm) == "string" and Config.Confirm or "Run this action?",
                Buttons = {
                    { Text = "Confirm", Accent = true, Callback = Fire },
                    { Text = "Cancel" }
                }
            })
        else
            Fire()
        end
    end)

    Element.Fire = Fire
    return Element
end

-- ============================================================ input

function Components.Input(Section, Config)
    Config = Merge({
        Title = "Input",
        Description = "",
        Placeholder = "",
        PlaceHolder = nil,
        Default = "",
        MaxLength = 0,
        Numeric = false,
        ClearOnFocus = false,
        Clear = true,
        Finished = false,
        Flag = nil,
        OnEnter = nil,
        Callback = function() end
    }, Config)
    Config.Placeholder = Config.PlaceHolder or Config.Placeholder

    local Mobile = Section.Window.Mobile
    local BoxWidth = Mobile and 130 or 168
    local Row, TitleLabel, DescLabel = MakeRow(Section, "Input", Config.Title, Config.Description, 48, BoxWidth)

    local Field = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(BoxWidth, Mobile and 34 or 30)
    })
    Library:Corner(Field, 8)
    Library:Themed(Field, "BackgroundColor3", "Inset")
    Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
    local FieldLine = Library:Stroke(Field, "StrokeSoft", 1)

    local Box = New("TextBox", {
        Parent = Field,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, Config.Clear and -34 or -20, 1, 0),
        Font = Library.Font.Regular,
        PlaceholderText = Config.Placeholder,
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = Config.ClearOnFocus == true
    })
    Library:Themed(Box, "TextColor3", "Text")
    Library:Themed(Box, "PlaceholderColor3", "TextDisabled")

    local ClearButton
    if Config.Clear then
        ClearButton = New("TextButton", {
            Parent = Field,
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.fromOffset(20, 20),
            Text = "",
            AutoButtonColor = false,
            Visible = false
        })
        local ClearIcon = IconLabel(ClearButton, Library.Icons.Close, 12, "TextDisabled")
        ClearIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        ClearIcon.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Counter
    if Config.MaxLength and Config.MaxLength > 0 then
        Counter = New("TextLabel", {
            Parent = Field,
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -6, 1, 14),
            Size = UDim2.fromOffset(60, 12),
            Font = Library.Font.Regular,
            Text = "",
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        Library:Themed(Counter, "TextColor3", "TextDisabled")
    end

    local Value = ""
    local Element

    local Handlers = {}
    function Handlers.Get()
        return Value
    end
    function Handlers.Set(NewValue, Silent)
        NewValue = tostring(NewValue == nil and "" or NewValue)
        if Config.MaxLength and Config.MaxLength > 0 then
            NewValue = NewValue:sub(1, Config.MaxLength)
        end
        if Config.Numeric then
            NewValue = NewValue:gsub("[^%d%.%-]", "")
        end
        Value = NewValue
        if Box.Text ~= NewValue then
            Box.Text = NewValue
        end
        if ClearButton then
            ClearButton.Visible = NewValue ~= ""
        end
        if Counter then
            Counter.Text = #NewValue .. "/" .. Config.MaxLength
        end
        Element.Emit(Config.Numeric and (tonumber(Value) or 0) or Value, Silent)
    end
    function Handlers.Lock(Locked)
        Box.TextEditable = not Locked
    end

    Element = Finish(Section, "Input", Config, Row, Handlers, TitleLabel, DescLabel)

    Box:GetPropertyChangedSignal("Text"):Connect(function()
        if Element.Locked then
            return
        end
        if not Config.Finished then
            Handlers.Set(Box.Text)
        elseif ClearButton then
            ClearButton.Visible = Box.Text ~= ""
        end
    end)

    Box.Focused:Connect(function()
        Library:Tween(FieldLine, FAST, { Color = Library.Theme.Accent, Transparency = 0.3 })
    end)

    Box.FocusLost:Connect(function(Enter)
        Library:Tween(FieldLine, FAST, {
            Color = Library.Theme.StrokeSoft,
            Transparency = Library.Theme.StrokeSoftAlpha
        })
        Handlers.Set(Box.Text)
        if Enter and Config.OnEnter then
            task.spawn(Config.OnEnter, Value)
        end
    end)

    if ClearButton then
        ClearButton.MouseButton1Click:Connect(function()
            if Element.Locked then
                return
            end
            Library:Feedback(0.95)
            Handlers.Set("")
        end)
    end

    Boot(Section, Config, Element, Config.Default or "")
    return Element
end

-- ============================================================ slider

function Components.Slider(Section, Config)
    Config = Merge({
        Title = "Slider",
        Description = "",
        Min = 0,
        Max = 100,
        Increment = 1,
        Default = nil,
        Suffix = "",
        Flag = nil,
        Callback = function() end
    }, Config)

    local Mobile = Section.Window.Mobile
    -- the readout is sized from the widest value it will ever hold, a fixed
    -- box clips things like "2000 studs"
    local Sample = tostring(Config.Max) .. tostring(Config.Suffix or "")
    local BoxWidth = Clamp(#Sample * 7 + 18, 48, 118)
    local BarWidth = Mobile and 0 or 150
    local Reserve = Mobile and (BoxWidth + 6) or (BarWidth + BoxWidth + 22)
    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "Slider", Config.Title, Config.Description,
        44, Reserve)

    local ValueBox = New("TextBox", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, Mobile and -12 or 0),
        Size = UDim2.fromOffset(BoxWidth, 24),
        ClipsDescendants = true,
        Font = Library.Font.Bold,
        Text = "",
        TextSize = 11,
        ClearTextOnFocus = false
    })
    Library:Corner(ValueBox, 7)
    Library:Themed(ValueBox, "BackgroundColor3", "Inset")
    Library:Themed(ValueBox, "BackgroundTransparency", "InsetAlpha")
    Library:Themed(ValueBox, "TextColor3", "Text")
    Library:Stroke(ValueBox, "StrokeSoft", 1)

    local Bar = New("Frame", {
        Parent = Row,
        BorderSizePixel = 0,
        Active = true
    })
    if Mobile then
        Bar.Parent = Stack
        Bar.LayoutOrder = 3
        Bar.Size = UDim2.new(1, 0, 0, 8)
    else
        Bar.AnchorPoint = Vector2.new(1, 0.5)
        Bar.Position = UDim2.new(1, -(BoxWidth + 24), 0.5, 0)
        Bar.Size = UDim2.fromOffset(BarWidth, 6)
    end
    Library:Corner(Bar, UDim.new(1, 0))
    Library:Themed(Bar, "BackgroundColor3", "Inset")
    Library:Themed(Bar, "BackgroundTransparency", "InsetAlpha")

    local Fill = New("Frame", {
        Parent = Bar,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1)
    })
    Library:Corner(Fill, UDim.new(1, 0))
    Library:Themed(Fill, "BackgroundColor3", "Accent")

    local Knob = New("Frame", {
        Parent = Bar,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(Mobile and 20 or 16, Mobile and 20 or 16),
        ZIndex = 3
    })
    Library:Corner(Knob, UDim.new(1, 0))
    Library:Themed(Knob, "BackgroundColor3", "AccentText")
    Library:Stroke(Knob, "Stroke", 1)

    local Value = Config.Default or Config.Min
    local Element
    local Dragging = false

    local Handlers = {}
    function Handlers.Get()
        return Value
    end
    function Handlers.Set(NewValue, Silent)
        NewValue = tonumber(NewValue) or Config.Min
        NewValue = Clamp(Round(NewValue, Config.Increment), Config.Min, Config.Max)
        Value = NewValue
        local Alpha = (NewValue - Config.Min) / math.max(Config.Max - Config.Min, 1e-6)
        local Info = (Silent or Dragging) and TweenInfo.new(0.06, Quart, Out) or FAST
        Library:Tween(Fill, Info, { Size = UDim2.fromScale(Alpha, 1) })
        Library:Tween(Knob, Info, { Position = UDim2.fromScale(Alpha, 0.5) })
        if not ValueBox:IsFocused() then
            ValueBox.Text = tostring(NewValue) .. (Config.Suffix or "")
        end
        Element.Emit(Value, Silent)
    end
    function Handlers.Lock(Locked)
        Bar.Active = not Locked
        ValueBox.TextEditable = not Locked
    end

    Element = Finish(Section, "Slider", Config, Row, Handlers, TitleLabel, DescLabel)

    local function FromInput(Position)
        local Start = Bar.AbsolutePosition.X
        local Width = math.max(Bar.AbsoluteSize.X, 1)
        local Alpha = Clamp((Position.X - Start) / Width, 0, 1)
        Handlers.Set(Config.Min + Alpha * (Config.Max - Config.Min))
    end

    Bar.InputBegan:Connect(function(Input)
        if Element.Locked then
            return
        end
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            Library:Feedback(1.2)
            Library:Tween(Knob, SPRING, { Size = UDim2.fromOffset(Mobile and 24 or 19, Mobile and 24 or 19) })
            FromInput(Input.Position)
        end
    end)

    table.insert(Section.Window.Connections, UserInputService.InputChanged:Connect(function(Input)
        if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
            or Input.UserInputType == Enum.UserInputType.Touch) then
            FromInput(Input.Position)
        end
    end))

    table.insert(Section.Window.Connections, UserInputService.InputEnded:Connect(function(Input)
        if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch) then
            Dragging = false
            Library:Tween(Knob, SPRING, { Size = UDim2.fromOffset(Mobile and 20 or 16, Mobile and 20 or 16) })
        end
    end))

    ValueBox.FocusLost:Connect(function()
        local Typed = tonumber((ValueBox.Text:gsub("[^%d%.%-]", "")))
        Handlers.Set(Typed or Value)
    end)

    Boot(Section, Config, Element, Config.Default or Config.Min)
    return Element
end

-- ============================================================ dropdown

function Components.Dropdown(Section, Config)
    Config = Merge({
        Title = "Dropdown",
        Description = "",
        Options = {},
        Values = nil,
        Default = nil,
        Multi = false,
        Search = nil,
        Placeholder = "Select",
        Flag = nil,
        Callback = function() end
    }, Config)
    Config.Options = Config.Values or Config.Options

    local Mobile = Section.Window.Mobile
    local ButtonWidth = Mobile and 130 or 170
    local Row, TitleLabel, DescLabel = MakeRow(Section, "Dropdown", Config.Title, Config.Description, 48, ButtonWidth)

    local Button = New("TextButton", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(ButtonWidth, Mobile and 34 or 30),
        Text = "",
        AutoButtonColor = false
    })
    Library:Corner(Button, 8)
    Library:Themed(Button, "BackgroundColor3", "Inset")
    Library:Themed(Button, "BackgroundTransparency", "InsetAlpha")
    local ButtonLine = Library:Stroke(Button, "StrokeSoft", 1)

    local Display = New("TextLabel", {
        Parent = Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -34, 1, 0),
        Font = Library.Font.Medium,
        Text = Config.Placeholder,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Library:Themed(Display, "TextColor3", "Text")

    local Chevron = IconLabel(Button, Library.Icons.Down, 14, "TextDim")
    Chevron.AnchorPoint = Vector2.new(1, 0.5)
    Chevron.Position = UDim2.new(1, -8, 0.5, 0)

    local Options = table.clone(Config.Options)
    local Selected = Config.Multi and {} or nil
    local Element
    local Handle

    local function Text()
        if Config.Multi then
            local Names = {}
            for Name, On in pairs(Selected) do
                if On then
                    table.insert(Names, tostring(Name))
                end
            end
            table.sort(Names)
            if #Names == 0 then
                return Config.Placeholder
            end
            return table.concat(Names, ", ")
        end
        return Selected == nil and Config.Placeholder or tostring(Selected)
    end

    local Handlers = {}
    function Handlers.Get()
        if Config.Multi then
            local Result = {}
            for Name, On in pairs(Selected) do
                if On then
                    Result[Name] = true
                end
            end
            return Result
        end
        return Selected
    end
    function Handlers.Set(Value, Silent)
        if Config.Multi then
            Selected = {}
            if type(Value) == "table" then
                for Key, Item in pairs(Value) do
                    if Item == true then
                        Selected[Key] = true
                    elseif type(Item) == "string" or type(Item) == "number" then
                        Selected[Item] = true
                    end
                end
            elseif Value ~= nil then
                Selected[Value] = true
            end
        else
            Selected = Value
        end
        Display.Text = Text()
        local Empty = Config.Multi and next(Selected) == nil or (not Config.Multi and Selected == nil)
        if Empty then
            Display.TextColor3 = Library.Theme.TextDisabled
        else
            Display.TextColor3 = Library.Theme.Text
        end
        if Handle and Handle.Open then
            Handle.Refresh()
        end
        Element.Emit(Handlers.Get(), Silent)
    end
    function Handlers.Lock(Locked)
        Button.Active = not Locked
    end

    Element = Finish(Section, "Dropdown", Config, Row, Handlers, TitleLabel, DescLabel)

    local function OpenList()
        local Count = math.min(#Options, 7)
        local UseSearch = Config.Search
        if UseSearch == nil then
            UseSearch = #Options > 8
        end
        local Height = 20 + (UseSearch and 38 or 0) + math.max(Count, 1) * 32
        Handle = Popup(Section.Window, Button, math.max(ButtonWidth, 190), Height)
        Library:Tween(Chevron, NORMAL, { Rotation = 180 })

        local SearchText = ""
        local List

        if UseSearch then
            local Field = New("Frame", {
                Parent = Handle.Frame,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 8, 0, 8),
                Size = UDim2.new(1, -16, 0, 28),
                ZIndex = 103
            })
            Library:Corner(Field, 7)
            Library:Themed(Field, "BackgroundColor3", "Inset")
            Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
            local Search = New("TextBox", {
                Parent = Field,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 0),
                Size = UDim2.new(1, -16, 1, 0),
                Font = Library.Font.Regular,
                PlaceholderText = "Search options",
                Text = "",
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                ZIndex = 104
            })
            Library:Themed(Search, "TextColor3", "Text")
            Library:Themed(Search, "PlaceholderColor3", "TextDisabled")
            Search:GetPropertyChangedSignal("Text"):Connect(function()
                SearchText = Search.Text:lower()
                Handle.Refresh()
            end)
        end

        List = New("ScrollingFrame", {
            Parent = Handle.Frame,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 6, 0, UseSearch and 42 or 6),
            Size = UDim2.new(1, -12, 1, UseSearch and -48 or -12),
            ZIndex = 103
        })
        Library:StyleScroll(List)
        New("UIPadding", {
            Parent = List,
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3)
        })
        New("UIListLayout", {
            Parent = List,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3)
        })

        function Handle.Refresh()
            List:ClearAllChildren()
            New("UIPadding", {
                Parent = List,
                PaddingTop = UDim.new(0, 3),
                PaddingBottom = UDim.new(0, 3),
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 3)
            })
            New("UIListLayout", {
                Parent = List,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 3)
            })
            for Index, Option in ipairs(Options) do
                local Name = tostring(Option)
                if SearchText == "" or Name:lower():find(SearchText, 1, true) then
                    local Active = Config.Multi and Selected[Option] == true or Selected == Option
                    local Item = New("TextButton", {
                        Parent = List,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 29),
                        Text = "",
                        AutoButtonColor = false,
                        LayoutOrder = Index,
                        BackgroundTransparency = Active and 0.85 or 1,
                        ZIndex = 104
                    })
                    Library:Corner(Item, 7)
                    Library:Themed(Item, "BackgroundColor3", "Accent")

                    local ItemLabel = New("TextLabel", {
                        Parent = Item,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 0),
                        Size = UDim2.new(1, -34, 1, 0),
                        Font = Library.Font.Medium,
                        Text = Name,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        TextColor3 = Active and Library.Theme.Text or Library.Theme.TextDim,
                        ZIndex = 105
                    })

                    if Active then
                        local Mark = IconLabel(Item, Library.Icons.Check, 14, "Accent")
                        Mark.AnchorPoint = Vector2.new(1, 0.5)
                        Mark.Position = UDim2.new(1, -8, 0.5, 0)
                        Mark.ZIndex = 105
                        Library:Themed(Mark, "ImageColor3", "Accent")
                    end

                    Item.MouseEnter:Connect(function()
                        if not Active then
                            Library:Tween(Item, FAST, { BackgroundTransparency = 0.93 })
                            Library:Tween(ItemLabel, FAST, { TextColor3 = Library.Theme.Text })
                        end
                    end)
                    Item.MouseLeave:Connect(function()
                        if not Active then
                            Library:Tween(Item, FAST, { BackgroundTransparency = 1 })
                            Library:Tween(ItemLabel, FAST, { TextColor3 = Library.Theme.TextDim })
                        end
                    end)
                    Item.MouseButton1Click:Connect(function()
                        Library:Feedback(1.1)
                        if Config.Multi then
                            Selected[Option] = not Selected[Option] or nil
                            Handlers.Set(Selected)
                        else
                            Handlers.Set(Option)
                            Handle:Close()
                        end
                    end)
                end
            end
        end

        Handle.Refresh()
        local Closed = Handle.Close
        Handle.Close = function(self)
            Library:Tween(Chevron, NORMAL, { Rotation = 0 })
            Closed(self)
        end
    end

    Button.MouseButton1Click:Connect(function()
        if Element.Locked then
            return
        end
        Library:Feedback(1.06)
        if Handle and Handle.Open then
            Handle:Close()
        else
            OpenList()
        end
    end)

    Library:Hover(Button, ButtonLine, "Transparency", Library.Theme.StrokeSoftAlpha, 0.5)

    function Element:SetOptions(NewOptions)
        Options = table.clone(NewOptions or {})
        if not Config.Multi and Selected ~= nil and not table.find(Options, Selected) then
            Handlers.Set(nil)
        end
        if Handle and Handle.Open then
            Handle.Refresh()
        end
        return Element
    end
    Element.Refresh = Element.SetOptions

    function Element:AddOption(Option)
        if not table.find(Options, Option) then
            table.insert(Options, Option)
        end
        if Handle and Handle.Open then
            Handle.Refresh()
        end
        return Element
    end

    function Element:RemoveOption(Option)
        local Index = table.find(Options, Option)
        if Index then
            table.remove(Options, Index)
        end
        if Config.Multi then
            Selected[Option] = nil
        elseif Selected == Option then
            Handlers.Set(nil)
        end
        if Handle and Handle.Open then
            Handle.Refresh()
        end
        return Element
    end

    function Element:GetOptions()
        return table.clone(Options)
    end

    Boot(Section, Config, Element, Config.Default)
    return Element
end

-- ============================================================ keybind

local KeyNames = {
    [Enum.KeyCode.LeftControl] = "LCtrl",
    [Enum.KeyCode.RightControl] = "RCtrl",
    [Enum.KeyCode.LeftShift] = "LShift",
    [Enum.KeyCode.RightShift] = "RShift",
    [Enum.KeyCode.LeftAlt] = "LAlt",
    [Enum.KeyCode.RightAlt] = "RAlt",
    [Enum.KeyCode.Backspace] = "Back",
    [Enum.KeyCode.Return] = "Enter"
}

local function KeyName(Key)
    if typeof(Key) ~= "EnumItem" then
        return "None"
    end
    if KeyNames[Key] then
        return KeyNames[Key]
    end
    if Key.EnumType == Enum.UserInputType then
        return (Key.Name:gsub("MouseButton", "M"))
    end
    return Key.Name
end

function Components.Keybind(Section, Config)
    Config = Merge({
        Title = "Keybind",
        Description = "",
        Default = nil,
        Mode = "Toggle",
        Flag = nil,
        Callback = function() end,
        OnRelease = nil
    }, Config)

    local Mobile = Section.Window.Mobile
    local Row, TitleLabel, DescLabel = MakeRow(Section, "Keybind", Config.Title, Config.Description, 46, 96)

    local Button = New("TextButton", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(96, Mobile and 32 or 28),
        Font = Library.Font.Bold,
        Text = "None",
        TextSize = 11,
        AutoButtonColor = false
    })
    Library:Corner(Button, 8)
    Library:Themed(Button, "BackgroundColor3", "Inset")
    Library:Themed(Button, "BackgroundTransparency", "InsetAlpha")
    Library:Themed(Button, "TextColor3", "Text")
    local Line = Library:Stroke(Button, "StrokeSoft", 1)

    local Key = nil
    local Listening = false
    local Element

    local Handlers = {}
    function Handlers.Get()
        return Key
    end
    function Handlers.Set(Value, Silent)
        if type(Value) == "string" then
            local Ok, Parsed = pcall(function()
                return Enum.KeyCode[Value]
            end)
            Value = Ok and Parsed or nil
        end
        Key = typeof(Value) == "EnumItem" and Value or nil
        Button.Text = KeyName(Key)
        Element.Emit(Key, Silent)
    end
    function Handlers.Lock(Locked)
        Button.Active = not Locked
    end

    Element = Finish(Section, "Keybind", Config, Row, Handlers, TitleLabel, DescLabel)
    Element.Mode = Config.Mode

    local Entry = { Element = Element, Config = Config }
    table.insert(Section.Window.Keybinds, Entry)

    function Entry.Match(Input)
        if not Key or Element.Locked then
            return false
        end
        return Input.KeyCode == Key or Input.UserInputType == Key
    end

    Button.MouseButton1Click:Connect(function()
        if Element.Locked then
            return
        end
        Listening = true
        Button.Text = "..."
        Library:Feedback(1.2)
        Library:Tween(Line, FAST, { Color = Library.Theme.Accent, Transparency = 0.3 })

        local Connection
        Connection = UserInputService.InputBegan:Connect(function(Input, Typing)
            if Typing then
                return
            end
            Connection:Disconnect()
            Listening = false
            Library:Tween(Line, FAST, {
                Color = Library.Theme.StrokeSoft,
                Transparency = Library.Theme.StrokeSoftAlpha
            })
            if Input.KeyCode == Enum.KeyCode.Escape then
                Button.Text = KeyName(Key)
            elseif Input.KeyCode == Enum.KeyCode.Backspace then
                Handlers.Set(nil)
            elseif Input.KeyCode ~= Enum.KeyCode.Unknown then
                Handlers.Set(Input.KeyCode)
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                Handlers.Set(Enum.UserInputType.MouseButton2)
            else
                Button.Text = KeyName(Key)
            end
        end)
    end)

    Entry.Fire = function(Released)
        if Config.Mode == "Hold" then
            if Released then
                if Config.OnRelease then
                    task.spawn(Config.OnRelease)
                else
                    task.spawn(Config.Callback, false)
                end
            else
                task.spawn(Config.Callback, true)
            end
        elseif not Released then
            task.spawn(Config.Callback, Key)
        end
    end

    Boot(Section, Config, Element, Config.Default)
    return Element
end

function WM.FireKeybinds(W, Input, Released)
    for _, Entry in ipairs(W.Keybinds) do
        if Entry.Match(Input) then
            Entry.Fire(Released)
        end
    end
end

-- ============================================================ colorpicker

local function HueBar(Parent)
    local Bar = New("Frame", {
        Parent = Parent,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Active = true
    })
    Library:Corner(Bar, 6)
    local Colors = {}
    for Index = 0, 6 do
        table.insert(Colors, ColorSequenceKeypoint.new(Index / 6, Color3.fromHSV(Index / 6, 1, 1)))
    end
    New("UIGradient", { Parent = Bar, Color = ColorSequence.new(Colors), Rotation = 90 })
    return Bar
end

local function SaturationBox(Parent)
    local Box = New("Frame", {
        Parent = Parent,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        Active = true
    })
    Library:Corner(Box, 8)
    local White = New("Frame", {
        Parent = Box,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2
    })
    Library:Corner(White, 8)
    New("UIGradient", {
        Parent = White,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
    })
    local Black = New("Frame", {
        Parent = Box,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 3
    })
    Library:Corner(Black, 8)
    New("UIGradient", {
        Parent = Black,
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        })
    })
    return Box
end

function Components.Colorpicker(Section, Config)
    Config = Merge({
        Title = "Color",
        Description = "",
        Default = Color3.fromRGB(179, 0, 255),
        Flag = nil,
        Callback = function() end
    }, Config)

    local Row, TitleLabel, DescLabel = MakeRow(Section, "Colorpicker", Config.Title, Config.Description, 46, 56)

    local Swatch = New("TextButton", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(52, 26),
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Config.Default
    })
    Library:Corner(Swatch, 7)
    Library:Stroke(Swatch, "Stroke", 1)

    local Hue, Saturation, Value = Color3.toHSV(Config.Default)
    local Element
    local Handle

    local Handlers = {}
    function Handlers.Get()
        return Color3.fromHSV(Hue, Saturation, Value)
    end
    function Handlers.Set(Color, Silent)
        if typeof(Color) == "table" and #Color == 3 then
            Color = Color3.fromRGB(Color[1], Color[2], Color[3])
        end
        if typeof(Color) ~= "Color3" then
            return
        end
        Hue, Saturation, Value = Color3.toHSV(Color)
        Swatch.BackgroundColor3 = Color
        if Handle and Handle.Open and Handle.Sync then
            Handle.Sync()
        end
        Element.Emit(Color, Silent)
    end
    function Handlers.Lock(Locked)
        Swatch.Active = not Locked
    end

    Element = Finish(Section, "Colorpicker", Config, Row, Handlers, TitleLabel, DescLabel)

    local function Open()
        Handle = Popup(Section.Window, Swatch, 218, 208)
        local Frame = Handle.Frame

        local Box = SaturationBox(Frame)
        Box.Position = UDim2.fromOffset(12, 12)
        Box.Size = UDim2.fromOffset(160, 120)
        Box.ZIndex = 103

        local Cursor = New("Frame", {
            Parent = Box,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(10, 10),
            ZIndex = 6
        })
        Library:Corner(Cursor, UDim.new(1, 0))
        Library:Stroke(Cursor, "Stroke", 1.5)

        local Bar = HueBar(Frame)
        Bar.Position = UDim2.fromOffset(180, 12)
        Bar.Size = UDim2.fromOffset(22, 120)
        Bar.ZIndex = 103

        local HueCursor = New("Frame", {
            Parent = Bar,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(1, 6, 0, 4),
            ZIndex = 104
        })
        Library:Corner(HueCursor, UDim.new(1, 0))

        local HexBox = New("TextBox", {
            Parent = Frame,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12, 144),
            Size = UDim2.fromOffset(120, 30),
            Font = Library.Font.Mono,
            Text = "",
            TextSize = 12,
            ClearTextOnFocus = false,
            ZIndex = 103
        })
        Library:Corner(HexBox, 7)
        Library:Stroke(HexBox, "StrokeSoft", 1)
        Library:Themed(HexBox, "BackgroundColor3", "Inset")
        Library:Themed(HexBox, "BackgroundTransparency", "InsetAlpha")
        Library:Themed(HexBox, "TextColor3", "Text")

        local Preview = New("Frame", {
            Parent = Frame,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(140, 144),
            Size = UDim2.fromOffset(62, 30),
            ZIndex = 103
        })
        Library:Corner(Preview, 7)
        Library:Stroke(Preview, "Stroke", 1)

        local Copy = PillButton(Frame, "Copy hex", Library.Icons.Copy, 194)
        Copy.Position = UDim2.fromOffset(12, 180)
        Copy.Size = UDim2.fromOffset(190, 22)
        Copy.ZIndex = 103

        function Handle.Sync()
            local Color = Color3.fromHSV(Hue, Saturation, Value)
            Box.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
            Cursor.Position = UDim2.fromScale(Saturation, 1 - Value)
            HueCursor.Position = UDim2.fromScale(0.5, Hue)
            Preview.BackgroundColor3 = Color
            Swatch.BackgroundColor3 = Color
            if not HexBox:IsFocused() then
                HexBox.Text = string.format("#%02X%02X%02X",
                    math.floor(Color.R * 255 + 0.5),
                    math.floor(Color.G * 255 + 0.5),
                    math.floor(Color.B * 255 + 0.5))
            end
        end

        local DragBox, DragBar = false, false

        local function UpdateBox(Position)
            local Origin = Box.AbsolutePosition
            local Size = Box.AbsoluteSize
            Saturation = Clamp((Position.X - Origin.X) / math.max(Size.X, 1), 0, 1)
            Value = 1 - Clamp((Position.Y - Origin.Y) / math.max(Size.Y, 1), 0, 1)
            Handlers.Set(Color3.fromHSV(Hue, Saturation, Value))
        end

        local function UpdateBar(Position)
            local Origin = Bar.AbsolutePosition
            local Size = Bar.AbsoluteSize
            Hue = Clamp((Position.Y - Origin.Y) / math.max(Size.Y, 1), 0, 1)
            Handlers.Set(Color3.fromHSV(Hue, Saturation, Value))
        end

        Box.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                DragBox = true
                UpdateBox(Input.Position)
            end
        end)
        Bar.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                DragBar = true
                UpdateBar(Input.Position)
            end
        end)

        local Moved = UserInputService.InputChanged:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement
                or Input.UserInputType == Enum.UserInputType.Touch then
                if DragBox then
                    UpdateBox(Input.Position)
                elseif DragBar then
                    UpdateBar(Input.Position)
                end
            end
        end)
        local Ended = UserInputService.InputEnded:Connect(function()
            DragBox, DragBar = false, false
        end)

        HexBox.FocusLost:Connect(function()
            local Hex = HexBox.Text:gsub("#", "")
            if #Hex == 6 then
                local Ok, Color = pcall(function()
                    return Color3.fromHex(Hex)
                end)
                if Ok then
                    Handlers.Set(Color)
                end
            end
            Handle.Sync()
        end)

        Copy.MouseButton1Click:Connect(function()
            if Env.setclipboard then
                pcall(Env.setclipboard, HexBox.Text)
            end
        end)

        local Closed = Handle.Close
        Handle.Close = function(self)
            Moved:Disconnect()
            Ended:Disconnect()
            Closed(self)
        end

        Handle.Sync()
    end

    Swatch.MouseButton1Click:Connect(function()
        if Element.Locked then
            return
        end
        Library:Feedback(1.05)
        if Handle and Handle.Open then
            Handle:Close()
        else
            Open()
        end
    end)

    Boot(Section, Config, Element, Config.Default)
    return Element
end

-- inline RGB sliders, no popup
function Components.ColorpickerRGB(Section, Config)
    Config = Merge({
        Title = "Color",
        Description = "",
        Default = Color3.fromRGB(179, 0, 255),
        Flag = nil,
        Callback = function() end
    }, Config)

    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "ColorpickerRGB", Config.Title, Config.Description, 44, 40)

    local Preview = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0, 10),
        Size = UDim2.fromOffset(34, 22),
        BackgroundColor3 = Config.Default
    })
    Library:Corner(Preview, 6)
    Library:Stroke(Preview, "Stroke", 1)

    local Holder = Blank(Stack, {
        Size = UDim2.new(1, 0, 0, 44),
        LayoutOrder = 3
    })
    New("UIListLayout", {
        Parent = Holder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        VerticalAlignment = Enum.VerticalAlignment.Bottom
    })

    local Channels = { R = 0, G = 0, B = 0 }
    local Element
    local Bars = {}

    local function Current()
        return Color3.fromRGB(Channels.R, Channels.G, Channels.B)
    end

    local Handlers = {}
    function Handlers.Get()
        return Current()
    end
    function Handlers.Set(Color, Silent)
        if typeof(Color) ~= "Color3" then
            return
        end
        Channels.R = math.floor(Color.R * 255 + 0.5)
        Channels.G = math.floor(Color.G * 255 + 0.5)
        Channels.B = math.floor(Color.B * 255 + 0.5)
        Preview.BackgroundColor3 = Color
        for Name, Bar in pairs(Bars) do
            Bar.Fill.Size = UDim2.fromScale(Channels[Name] / 255, 1)
            Bar.Label.Text = Name .. " " .. Channels[Name]
        end
        Element.Emit(Color, Silent)
    end

    Element = Finish(Section, "ColorpickerRGB", Config, Row, Handlers, TitleLabel, DescLabel)

    local Order = { "R", "G", "B" }
    for Index, Name in ipairs(Order) do
        local Line = Blank(Holder, { Size = UDim2.new(1, 0, 0, 12), LayoutOrder = Index })
        local Text = New("TextLabel", {
            Parent = Line,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(44, 12),
            Font = Library.Font.Bold,
            Text = Name .. " 0",
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Themed(Text, "TextColor3", "TextDim")

        local Track = New("Frame", {
            Parent = Line,
            AnchorPoint = Vector2.new(1, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(1, -50, 0, 6),
            Active = true
        })
        Library:Corner(Track, UDim.new(1, 0))
        Library:Themed(Track, "BackgroundColor3", "Inset")
        Library:Themed(Track, "BackgroundTransparency", "InsetAlpha")

        local Fill = New("Frame", {
            Parent = Track,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = Name == "R" and Color3.fromRGB(255, 90, 90)
                or Name == "G" and Color3.fromRGB(90, 235, 130)
                or Color3.fromRGB(100, 160, 255)
        })
        Library:Corner(Fill, UDim.new(1, 0))

        Bars[Name] = { Fill = Fill, Label = Text }

        local Dragging = false
        local function Apply(Position)
            local Alpha = Clamp((Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
            Channels[Name] = math.floor(Alpha * 255 + 0.5)
            Handlers.Set(Current())
        end
        Track.InputBegan:Connect(function(Input)
            if Element.Locked then
                return
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                Apply(Input.Position)
            end
        end)
        table.insert(Section.Window.Connections, UserInputService.InputChanged:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
                or Input.UserInputType == Enum.UserInputType.Touch) then
                Apply(Input.Position)
            end
        end))
        table.insert(Section.Window.Connections, UserInputService.InputEnded:Connect(function()
            Dragging = false
        end))
    end

    Boot(Section, Config, Element, Config.Default)
    return Element
end

-- ============================================================ static rows

function Components.MultiButton(Section, Config)
    Config = Merge({
        Title = "Actions",
        Description = "",
        Buttons = {}
    }, Config)

    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "MultiButton", Config.Title, Config.Description, 44, 0)

    local Holder = Blank(Stack, {
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = 3
    })
    New("UIListLayout", {
        Parent = Holder,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })

    local Count = math.max(#Config.Buttons, 1)
    for Index, Info in ipairs(Config.Buttons) do
        local Button, TextLabel = PillButton(Holder, Info.Title or Info.Text or "Button", Info.Icon, 0, Info.Accent)
        Button.Size = UDim2.new(1 / Count, -6 + 6 / Count, 1, 0)
        Button.LayoutOrder = Index
        TextLabel.TextSize = 11
        Button.MouseButton1Click:Connect(function()
            if Info.Callback then
                task.spawn(Info.Callback)
            end
        end)
    end

    local Handlers = { Get = function() end, Set = function() end }
    return Finish(Section, "MultiButton", Config, Row, Handlers, TitleLabel, DescLabel)
end

function Components.Paragraph(Section, Config)
    Config = Merge({
        Title = "Paragraph",
        Description = "",
        Content = "",
        Text = nil
    }, Config)

    local Body = Config.Text or Config.Content or Config.Description
    local Row, TitleLabel, Content = MakeRow(Section, "Paragraph", Config.Title, Body, 44, 0)
    Content.TextSize = 12

    local Handlers = {}
    function Handlers.Get()
        return Content.Text
    end
    function Handlers.Set(Value)
        Content.Text = tostring(Value)
    end

    return Finish(Section, "Paragraph", Config, Row, Handlers, TitleLabel, Content)
end

function Components.Label(Section, Config)
    Config = Merge({ Title = "Label", Description = "", Icon = nil }, Config)
    local Row, TitleLabel, DescLabel = MakeRow(Section, "Label", Config.Title, Config.Description, 38, 20)
    if Config.Icon then
        local Icon = IconLabel(Row, Config.Icon, 16, "Accent")
        Icon.AnchorPoint = Vector2.new(1, 0.5)
        Icon.Position = UDim2.new(1, -14, 0.5, 0)
        Library:Themed(Icon, "ImageColor3", "Accent")
    end
    local Handlers = {}
    function Handlers.Get()
        return TitleLabel.Text
    end
    function Handlers.Set(Value)
        TitleLabel.Text = tostring(Value)
    end
    return Finish(Section, "Label", Config, Row, Handlers, TitleLabel, DescLabel)
end

function Components.Tag(Section, Config)
    Config = Merge({
        Title = "Tag",
        Description = "",
        Value = "New",
        Color = nil
    }, Config)

    local Row, TitleLabel, DescLabel = MakeRow(Section, "Tag", Config.Title, Config.Description, 44, 80)

    local Pill = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(0, 22),
        AutomaticSize = Enum.AutomaticSize.X
    })
    Library:Corner(Pill, 7)
    if Config.Color then
        Pill.BackgroundColor3 = Config.Color
    else
        Library:Themed(Pill, "BackgroundColor3", "Accent")
    end
    New("UIPadding", {
        Parent = Pill,
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9)
    })

    local Text = New("TextLabel", {
        Parent = Pill,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 22),
        Font = Library.Font.Bold,
        Text = tostring(Config.Value),
        TextSize = 11
    })
    if Config.Color then
        Text.TextColor3 = Config.Color
    else
        Library:Themed(Text, "TextColor3", "Accent")
    end

    local Handlers = {}
    function Handlers.Get()
        return Text.Text
    end
    function Handlers.Set(Value)
        Text.Text = tostring(Value)
    end

    return Finish(Section, "Tag", Config, Row, Handlers, TitleLabel, DescLabel)
end

function Components.Codeblock(Section, Config)
    Config = Merge({
        Title = "Code",
        Description = "",
        Code = "",
        Text = nil,
        Copy = true
    }, Config)

    local Body = Config.Text or Config.Code
    local Row, TitleLabel, _, _, Stack = MakeRow(Section, "Codeblock", Config.Title, "", 44, 0)

    local Block = New("Frame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3
    })
    Library:Corner(Block, 8)
    Library:Themed(Block, "BackgroundColor3", "Inset")
    Library:Themed(Block, "BackgroundTransparency", "InsetAlpha")
    Library:Stroke(Block, "StrokeSoft", 1)
    New("UIPadding", {
        Parent = Block,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 34)
    })

    local Code = New("TextLabel", {
        Parent = Block,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Library.Font.Mono,
        Text = Body,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    Library:Themed(Code, "TextColor3", "TextDim")

    if Config.Copy then
        local CopyButton = New("TextButton", {
            Parent = Block,
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 26, 0, 0),
            Size = UDim2.fromOffset(22, 22),
            Text = "",
            AutoButtonColor = false
        })
        local CopyIcon = IconLabel(CopyButton, Library.Icons.Copy, 14, "TextDisabled")
        CopyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        CopyIcon.Position = UDim2.fromScale(0.5, 0.5)
        CopyButton.MouseButton1Click:Connect(function()
            if Env.setclipboard then
                pcall(Env.setclipboard, Code.Text)
            end
            Library:SetIcon(CopyIcon, Library.Icons.Check, Library.Theme.Success)
            task.delay(1.2, function()
                Library:SetIcon(CopyIcon, Library.Icons.Copy, Library.Theme.TextDisabled)
            end)
        end)
    end

    local Handlers = {}
    function Handlers.Get()
        return Code.Text
    end
    function Handlers.Set(Value)
        Code.Text = tostring(Value)
    end

    return Finish(Section, "Codeblock", Config, Row, Handlers, TitleLabel, Code)
end

function Components.Progress(Section, Config)
    Config = Merge({
        Title = "Progress",
        Description = "",
        Default = 0,
        Suffix = "%",
        Flag = nil,
        Callback = function() end
    }, Config)

    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "Progress", Config.Title, Config.Description, 44, 50)

    local Percent = New("TextLabel", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -14, 0, 10),
        Size = UDim2.fromOffset(50, 16),
        Font = Library.Font.Bold,
        Text = "0%",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    Library:Themed(Percent, "TextColor3", "Accent")

    local Track = New("Frame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 6),
        LayoutOrder = 3
    })
    Library:Corner(Track, UDim.new(1, 0))
    Library:Themed(Track, "BackgroundColor3", "Inset")
    Library:Themed(Track, "BackgroundTransparency", "InsetAlpha")

    local Fill = New("Frame", {
        Parent = Track,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1)
    })
    Library:Corner(Fill, UDim.new(1, 0))
    Library:Themed(Fill, "BackgroundColor3", "Accent")

    local Value = 0
    local Element

    local Handlers = {}
    function Handlers.Get()
        return Value
    end
    function Handlers.Set(NewValue, Silent)
        NewValue = Clamp(tonumber(NewValue) or 0, 0, 1)
        Value = NewValue
        Library:Tween(Fill, NORMAL, { Size = UDim2.fromScale(NewValue, 1) })
        Percent.Text = math.floor(NewValue * 100 + 0.5) .. (Config.Suffix or "")
        Element.Emit(Value, Silent)
    end

    Element = Finish(Section, "Progress", Config, Row, Handlers, TitleLabel, DescLabel)
    Handlers.Set(Config.Default or 0, true)
    return Element
end

function Components.Grid(Section, Config)
    Config = Merge({
        Title = "Grid",
        Description = "",
        Columns = 3,
        Height = 62,
        Items = {}
    }, Config)

    local Rows = math.ceil(math.max(#Config.Items, 1) / Config.Columns)
    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "Grid", Config.Title, Config.Description, 44, 0)

    local Holder = Blank(Stack, {
        Size = UDim2.new(1, 0, 0, Rows * (Config.Height + 6)),
        LayoutOrder = 3
    })
    local Layout = New("UIGridLayout", {
        Parent = Holder,
        CellPadding = UDim2.fromOffset(6, 6),
        CellSize = UDim2.new(1 / Config.Columns, -6, 0, Config.Height),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local API = {}
    local function AddItem(Info, Index)
        local Cell = New("TextButton", {
            Parent = Holder,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Index
        })
        Library:Corner(Cell, 9)
        Library:Themed(Cell, "BackgroundColor3", "Inset")
        Library:Themed(Cell, "BackgroundTransparency", "InsetAlpha")
        local Line = Library:Stroke(Cell, "StrokeSoft", 1)

        if Info.Icon then
            local Icon = IconLabel(Cell, Info.Icon, 20, "Accent")
            Icon.AnchorPoint = Vector2.new(0.5, 0)
            Icon.Position = UDim2.new(0.5, 0, 0, 12)
            Library:Themed(Icon, "ImageColor3", "Accent")
        end

        local Text = New("TextLabel", {
            Parent = Cell,
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 1, -8),
            Size = UDim2.new(1, -8, 0, 14),
            Font = Library.Font.Medium,
            Text = Info.Title or Info.Text or "",
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        Library:Themed(Text, "TextColor3", "Text")

        Library:Hover(Cell, Line, "Transparency", Library.Theme.StrokeSoftAlpha, 0.45)
        Cell.MouseButton1Click:Connect(function()
            Library:Feedback(1.1)
            if Info.Callback then
                task.spawn(Info.Callback)
            end
        end)
        return Cell
    end

    for Index, Info in ipairs(Config.Items) do
        AddItem(Info, Index)
    end

    local Handlers = { Get = function() end, Set = function() end }
    local Element = Finish(Section, "Grid", Config, Row, Handlers, TitleLabel, DescLabel)
    function Element:AddItem(Info)
        return AddItem(Info, #Holder:GetChildren())
    end
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    return Element
end

function Components.Table(Section, Config)
    Config = Merge({
        Title = "Table",
        Description = "",
        Columns = {},
        Rows = {}
    }, Config)

    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "Table", Config.Title, Config.Description, 44, 0)

    local Holder = Blank(Stack, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3
    })
    New("UIListLayout", {
        Parent = Holder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })

    local function Line(Values, Header, Order)
        local LineFrame = New("Frame", {
            Parent = Holder,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = Header and 0.9 or 1,
            LayoutOrder = Order
        })
        Library:Corner(LineFrame, 6)
        Library:Themed(LineFrame, "BackgroundColor3", "Accent")
        local Count = math.max(#Values, 1)
        for Index, Value in ipairs(Values) do
            local Cell = New("TextLabel", {
                Parent = LineFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new((Index - 1) / Count, 8, 0, 0),
                Size = UDim2.new(1 / Count, -12, 1, 0),
                Font = Header and Library.Font.Bold or Library.Font.Regular,
                Text = tostring(Value),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
            Library:Themed(Cell, "TextColor3", Header and "Text" or "TextDim")
        end
        return LineFrame
    end

    if #Config.Columns > 0 then
        Line(Config.Columns, true, 0)
    end
    for Index, Data in ipairs(Config.Rows) do
        Line(Data, false, Index)
    end

    local Handlers = { Get = function() end, Set = function() end }
    local Element = Finish(Section, "Table", Config, Row, Handlers, TitleLabel, DescLabel)

    function Element:SetRows(Rows)
        for _, Child in ipairs(Holder:GetChildren()) do
            if Child:IsA("Frame") and Child.LayoutOrder > 0 then
                Child:Destroy()
            end
        end
        for Index, Data in ipairs(Rows) do
            Line(Data, false, Index)
        end
        return Element
    end
    function Element:AddRow(Data)
        return Line(Data, false, #Holder:GetChildren())
    end
    return Element
end

function Components.Image(Section, Config)
    Config = Merge({
        Title = "",
        Description = "",
        Image = "",
        Height = 120,
        Ratio = nil,
        Corner = 10
    }, Config)

    local HasTitle = (Config.Title or "") ~= ""
    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "Image", Config.Title, Config.Description, 44, 0)

    local Picture = New("ImageLabel", {
        Parent = Stack,
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Size = UDim2.new(1, 0, 0, Config.Height),
        Image = Config.Image,
        ScaleType = Enum.ScaleType.Crop
    })
    Library:Corner(Picture, Config.Corner)
    if Config.Ratio then
        New("UIAspectRatioConstraint", { Parent = Picture, AspectRatio = Config.Ratio })
    end

    local Handlers = {}
    function Handlers.Get()
        return Picture.Image
    end
    function Handlers.Set(Value)
        Picture.Image = tostring(Value)
    end

    return Finish(Section, "Image", Config, Row, Handlers, TitleLabel, DescLabel)
end

function Components.Viewport(Section, Config)
    Config = Merge({
        Title = "",
        Description = "",
        Object = nil,
        Height = 180,
        Interactive = true,
        Corner = 10,
        Callback = function() end
    }, Config)

    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "Viewport", Config.Title, Config.Description, 44, 0)

    local Frame = New("Frame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Config.Height),
        LayoutOrder = 3,
        ClipsDescendants = true
    })
    Library:Corner(Frame, Config.Corner)
    Library:Themed(Frame, "BackgroundColor3", "Inset")
    Library:Themed(Frame, "BackgroundTransparency", "InsetAlpha")
    Library:Stroke(Frame, "StrokeSoft", 1)

    local Camera = New("Camera", {})
    local View = New("ViewportFrame", {
        Parent = Frame,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        CurrentCamera = Camera,
        Ambient = Color3.fromRGB(150, 150, 150),
        LightColor = Color3.fromRGB(255, 255, 255)
    })
    Camera.Parent = View

    -- cloned preview objects live in here, never the camera, so clearing
    -- the preview on SetObject can never destroy the camera it needs
    local Models = New("Folder", { Parent = View, Name = "Models" })

    local HintIcon = IconLabel(Frame, Library.Icons.Command, 20, "TextDisabled")
    HintIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    HintIcon.Position = UDim2.fromScale(0.5, 0.5)
    HintIcon.Visible = false

    local Current, Distance, Yaw, Pitch = nil, 6, 0, 0.35

    local function Frame3D()
        if not Current then
            return
        end
        local Center, Size
        local Ok = pcall(function()
            if Current:IsA("Model") then
                local CF, S = Current:GetBoundingBox()
                Center, Size = CF.Position, S
            elseif Current:IsA("BasePart") then
                Center, Size = Current.Position, Current.Size
            end
        end)
        if not Ok or not Center then
            return
        end
        Distance = math.max(Size.Magnitude, 2) * 1.15
        local Offset = Vector3.new(
            math.cos(Pitch) * math.sin(Yaw),
            math.sin(Pitch),
            math.cos(Pitch) * math.cos(Yaw)
        ) * Distance
        Camera.CFrame = CFrame.lookAt(Center + Offset, Center)
    end

    local Handlers = {}
    local Element
    function Handlers.Get()
        return Current
    end
    function Handlers.Set(NewObject, Silent)
        if Current then
            pcall(function() Current:Destroy() end)
            Current = nil
        end
        Models:ClearAllChildren()
        HintIcon.Visible = false
        if typeof(NewObject) == "Instance" then
            local Ok, Clone = pcall(function() return NewObject:Clone() end)
            if Ok and Clone then
                Clone.Parent = Models
                Current = Clone
                Yaw, Pitch = 0, 0.35
                Frame3D()
                HintIcon.Visible = Config.Interactive
            end
        end
        Element.Emit(Current, Silent)
    end

    Element = Finish(Section, "Viewport", Config, Row, Handlers, TitleLabel, DescLabel)
    Element.SetObject = Element.Set

    if Config.Interactive then
        local Dragging, LastX, LastY = false, 0, 0
        local Catcher = New("TextButton", {
            Parent = Frame,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 5
        })
        Catcher.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                LastX, LastY = Input.Position.X, Input.Position.Y
            end
        end)
        UserInputService.InputChanged:Connect(function(Input)
            if not Dragging then
                return
            end
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                local DX, DY = Input.Position.X - LastX, Input.Position.Y - LastY
                LastX, LastY = Input.Position.X, Input.Position.Y
                Yaw = Yaw - DX * 0.01
                Pitch = Clamp(Pitch - DY * 0.01, -1.3, 1.3)
                Frame3D()
            end
        end)
        UserInputService.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end)
    end

    if Config.Object then
        Element:Set(Config.Object, true)
    end

    return Element
end

function Components.Separator(Section, Config)
    Config = Merge({ Title = "", Text = nil }, Config)
    local Text = Config.Text or Config.Title or ""

    local Frame = New("Frame", {
        Parent = Section.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Text ~= "" and 26 or 12),
        LayoutOrder = Section.Count + 1
    })
    Section.Count = Section.Count + 1

    local LeftLine = New("Frame", {
        Parent = Frame,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.new(Text ~= "" and 0 or 1, Text ~= "" and 0 or -8, 0, 1)
    })
    Library:Themed(LeftLine, "BackgroundColor3", "Stroke")

    if Text ~= "" then
        local Label2 = New("TextLabel", {
            Parent = Frame,
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 4, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Library.Font.Bold,
            Text = string.upper(Text),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Themed(Label2, "TextColor3", "TextDisabled")
        task.defer(function()
            LeftLine.Position = UDim2.new(0, Label2.AbsoluteSize.X + 12, 0.5, 0)
            LeftLine.Size = UDim2.new(1, -(Label2.AbsoluteSize.X + 18), 0, 1)
        end)
    end

    local Handlers = { Get = function() end, Set = function() end }
    return Finish(Section, "Separator", Config, Frame, Handlers, nil, nil)
end

function Components.Divider(Section, Config)
    Config = Merge({ Title = "" }, Config or {})
    local Frame = New("Frame", {
        Parent = Section.Body,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        LayoutOrder = Section.Count + 1
    })
    Section.Count = Section.Count + 1
    Library:FadeLine(Frame, true)
    local Handlers = { Get = function() end, Set = function() end }
    return Finish(Section, "Divider", Config, Frame, Handlers, nil, nil)
end

function Components.Space(Section, Config)
    local Height = 10
    if type(Config) == "number" then
        Height = Config
        Config = {}
    elseif type(Config) == "table" then
        Height = Config.Height or Config.Size or tonumber(Config.Title) or 10
    else
        Config = {}
    end
    local Frame = New("Frame", {
        Parent = Section.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Height),
        LayoutOrder = Section.Count + 1
    })
    Section.Count = Section.Count + 1
    local Handlers = { Get = function() end, Set = function() end }
    return Finish(Section, "Space", Config, Frame, Handlers, nil, nil)
end

-- ============================================================ modals

-- Escape cannot be used to dismiss overlays: the core menu claims it before
-- any CAS priority we can ask for, and GuiService:SetMenuIsOpen(false) is
-- ignored, so pressing it would close the overlay and open the Roblox menu on
-- top. Overlays close on backdrop click or the X. A window can opt into a
-- close key of its own with Config.CloseKey.
local EscapeCount = 0
function BindEscape(OnEscape, Key)
    if typeof(Key) ~= "EnumItem" then
        return function() end
    end
    EscapeCount = EscapeCount + 1
    local Name = "sh1ttybanana_close_" .. EscapeCount
    ContextActionService:BindActionAtPriority(Name, function(_, State)
        if State == Enum.UserInputState.Begin then
            OnEscape()
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end, false, 4000, Key)
    return function()
        pcall(function()
            ContextActionService:UnbindAction(Name)
        end)
    end
end

function WM.Modal(W, Config)
    Config = Merge({
        Title = "Modal",
        Description = "",
        Icon = nil,
        Width = 380,
        Height = 260
    }, Config or {})

    W.Modals = W.Modals or {}

    local Overlay = GetOverlay(W)
    local Backdrop = New("TextButton", {
        Parent = Overlay,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 110 + #W.Modals * 4
    })

    local MainSize = W.Main.AbsoluteSize / W.Scale.Scale
    local Width = math.min(Config.Width, MainSize.X - 24)
    local Height = math.min(Config.Height, MainSize.Y - 24)

    local Card = New("Frame", {
        Parent = Overlay,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(Width, Height),
        ZIndex = Backdrop.ZIndex + 1
    })
    Library:Corner(Card, 14)
    Library:Themed(Card, "BackgroundColor3", "Elevated")
    Library:Themed(Card, "BackgroundTransparency", "ElevatedAlpha")
    Library:Stroke(Card, "Stroke", 1.2)
    Library:Shadow(Card, 70, 0.55)
    Library:Sheen(Card, 90).ZIndex = Card.ZIndex

    local Header = Blank(Card, {
        Size = UDim2.new(1, 0, 0, 46),
        ZIndex = Card.ZIndex + 1
    })

    local TitleLeft = 16
    if Config.Icon then
        local Icon = IconLabel(Header, Config.Icon, 18, "Accent")
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.Position = UDim2.new(0, 16, 0.5, 0)
        Icon.ZIndex = Card.ZIndex + 2
        Library:Themed(Icon, "ImageColor3", "Accent")
        TitleLeft = 42
    end

    local HasDesc = (Config.Description or "") ~= ""
    local Title = New("TextLabel", {
        Parent = Header,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, TitleLeft, 0.5, HasDesc and -7 or 0),
        Size = UDim2.new(1, -(TitleLeft + 44), 0, 18),
        Font = Library.Font.Bold,
        Text = Config.Title,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = Card.ZIndex + 2
    })
    Library:Themed(Title, "TextColor3", "Text")

    if HasDesc then
        local Desc = New("TextLabel", {
            Parent = Header,
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, TitleLeft, 0.5, 9),
            Size = UDim2.new(1, -(TitleLeft + 44), 0, 14),
            Font = Library.Font.Regular,
            Text = Config.Description,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = Card.ZIndex + 2
        })
        Library:Themed(Desc, "TextColor3", "TextDim")
    end

    local Close = GlyphButton(Header, Library.Icons.Close, "Close")
    Close.AnchorPoint = Vector2.new(1, 0.5)
    Close.Position = UDim2.new(1, -10, 0.5, 0)
    Close.ZIndex = Card.ZIndex + 2

    local Body = Blank(Card, {
        Position = UDim2.new(0, 14, 0, 46),
        Size = UDim2.new(1, -28, 1, -60),
        ZIndex = Card.ZIndex + 1
    })

    local Handle = { Frame = Card, Body = Body, Open = true }
    local Unbind = BindEscape(function()
        Handle:Close()
    end, W.Config.CloseKey)

    function Handle:Close()
        if not Handle.Open then
            return
        end
        Handle.Open = false
        Unbind()
        for Index, Value in ipairs(W.Modals) do
            if Value == Handle then
                table.remove(W.Modals, Index)
                break
            end
        end
        Library:Tween(Backdrop, FAST, { BackgroundTransparency = 1 })
        Library:Tween(Card, FAST, { BackgroundTransparency = 1 }, function()
            Card:Destroy()
            Backdrop:Destroy()
        end)
    end

    Close.MouseButton1Click:Connect(function()
        Handle:Close()
    end)
    Backdrop.MouseButton1Click:Connect(function()
        if Config.Persistent ~= true then
            Handle:Close()
        end
    end)

    Library:Tween(Backdrop, NORMAL, { BackgroundTransparency = 0.5 })
    Library:Pop(Card, 0.3, 0.94)
    table.insert(W.Modals, Handle)
    return Handle
end

function WM.CloseTop(W)
    if W.OpenPopup and W.OpenPopup.Open then
        W.OpenPopup:Close()
        return true
    end
    W.Modals = W.Modals or {}
    local Top = W.Modals[#W.Modals]
    if Top then
        Top:Close()
        return true
    end
    return false
end

function WM.Dialog(W, Config)
    Config = Merge({
        Title = "Dialog",
        Description = "",
        Content = nil,
        Buttons = {}
    }, Config or {})

    local Handle = WM.Modal(W, {
        Title = Config.Title,
        Icon = Config.Icon or Library.Icons.Info,
        Width = 400,
        Height = 190
    })

    local Text = New("TextLabel", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 2, 0, 4),
        Size = UDim2.new(1, -4, 1, -50),
        Font = Library.Font.Regular,
        Text = Config.Content or Config.Description,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        RichText = true,
        ZIndex = Handle.Frame.ZIndex + 2
    })
    Library:Themed(Text, "TextColor3", "TextDim")

    local Footer = Blank(Handle.Body, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 34),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    New("UIListLayout", {
        Parent = Footer,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    for Index, Info in ipairs(Config.Buttons) do
        local Button = PillButton(Footer, Info.Text or Info.Title or "Ok", Info.Icon, 110, Info.Accent)
        Button.LayoutOrder = Index
        Button.ZIndex = Handle.Frame.ZIndex + 3
        for _, Child in ipairs(Button:GetDescendants()) do
            if Child:IsA("GuiObject") then
                Child.ZIndex = Button.ZIndex + 1
            end
        end
        Button.MouseButton1Click:Connect(function()
            Handle:Close()
            if Info.Callback then
                task.spawn(Info.Callback)
            end
        end)
    end

    return Handle
end

-- single line text prompt, used by the config manager and password locks
function WM.Prompt(W, Config)
    Config = Merge({
        Title = "Input",
        Description = "",
        Placeholder = "",
        Default = "",
        Password = false,
        Confirm = "Confirm",
        Callback = function() end
    }, Config or {})

    local Handle = WM.Modal(W, {
        Title = Config.Title,
        Description = Config.Description,
        Icon = Config.Icon or Library.Icons.Edit,
        Width = 380,
        Height = 176
    })

    local Field = New("Frame", {
        Parent = Handle.Body,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 8),
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    Library:Corner(Field, 9)
    Library:Themed(Field, "BackgroundColor3", "Inset")
    Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
    Library:Stroke(Field, "StrokeSoft", 1)

    local Box = New("TextBox", {
        Parent = Field,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Font = Library.Font.Regular,
        PlaceholderText = Config.Placeholder,
        Text = Config.Default,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = Handle.Frame.ZIndex + 3
    })
    Library:Themed(Box, "TextColor3", "Text")
    Library:Themed(Box, "PlaceholderColor3", "TextDisabled")

    local Error = New("TextLabel", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 2, 0, 48),
        Size = UDim2.new(1, -4, 0, 14),
        Font = Library.Font.Regular,
        Text = "",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Handle.Frame.ZIndex + 2
    })
    Library:Themed(Error, "TextColor3", "Error")

    local Footer = Blank(Handle.Body, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    New("UIListLayout", {
        Parent = Footer,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local function Submit()
        local Value = Trim(Box.Text)
        local Ok, Message = Config.Callback(Value)
        if Ok == false then
            Error.Text = Message or "invalid value"
            Library:Tween(Field, FAST, { BackgroundColor3 = Library.Theme.Error })
            task.delay(0.25, function()
                Library:Tween(Field, FAST, { BackgroundColor3 = Library.Theme.Inset })
            end)
            return
        end
        Handle:Close()
    end

    local Cancel = PillButton(Footer, "Cancel", nil, 100)
    Cancel.LayoutOrder = 1
    Cancel.ZIndex = Handle.Frame.ZIndex + 3
    Cancel.MouseButton1Click:Connect(function()
        Handle:Close()
    end)

    local Accept = PillButton(Footer, Config.Confirm, Library.Icons.Check, 110, true)
    Accept.LayoutOrder = 2
    Accept.ZIndex = Handle.Frame.ZIndex + 3
    Accept.MouseButton1Click:Connect(Submit)

    for _, Button in ipairs({ Cancel, Accept }) do
        for _, Child in ipairs(Button:GetDescendants()) do
            if Child:IsA("GuiObject") then
                Child.ZIndex = Button.ZIndex + 1
            end
        end
    end

    Box.FocusLost:Connect(function(Enter)
        if Enter then
            Submit()
        end
    end)
    task.defer(function()
        Box:CaptureFocus()
    end)
    return Handle
end

function WM.Password(W, Config)
    WM.Prompt(W, {
        Title = Config.Title or "Locked",
        Description = Config.Description or "Enter the password to unlock",
        Placeholder = "password",
        Icon = Library.Icons.Lock,
        Confirm = "Unlock",
        Callback = function(Value)
            if Value ~= tostring(Config.Password) then
                return false, "wrong password"
            end
            if Config.Remember and Config.Key then
                W.State["unlock_" .. Config.Key] = tostring(Config.Password)
                W.SaveState()
            end
            if Config.OnUnlock then
                task.spawn(Config.OnUnlock)
            end
            return true
        end
    })
end

-- ============================================================ command palette

function WM.Palette(W)
    if W.PaletteOpen then
        return
    end
    W.PaletteOpen = true

    local Handle = WM.Modal(W, {
        Title = "Command palette",
        Description = "Search tabs, elements and actions",
        Icon = Library.Icons.Command,
        Width = 470,
        Height = 330
    })

    local Closed = Handle.Close
    Handle.Close = function(self)
        W.PaletteOpen = false
        Closed(self)
    end

    local Field = New("Frame", {
        Parent = Handle.Body,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 6),
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    Library:Corner(Field, 9)
    Library:Themed(Field, "BackgroundColor3", "Inset")
    Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
    Library:Stroke(Field, "StrokeSoft", 1)

    local Icon = IconLabel(Field, Library.Icons.Search, 15, "TextDisabled")
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Position = UDim2.new(0, 12, 0.5, 0)
    Icon.ZIndex = Handle.Frame.ZIndex + 3

    local Box = New("TextBox", {
        Parent = Field,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 36, 0, 0),
        Size = UDim2.new(1, -48, 1, 0),
        Font = Library.Font.Regular,
        PlaceholderText = "Type to search",
        Text = "",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = Handle.Frame.ZIndex + 3
    })
    Library:Themed(Box, "TextColor3", "Text")
    Library:Themed(Box, "PlaceholderColor3", "TextDisabled")

    local List = New("ScrollingFrame", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 50),
        Size = UDim2.new(1, 0, 1, -56),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    Library:StyleScroll(List)
    New("UIPadding", {
        Parent = List,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3)
    })
    New("UIListLayout", {
        Parent = List,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })

    local Results = {}
    local Cursor = 1

    local function Paint()
        for Index, Item in ipairs(Results) do
            local Active = Index == Cursor
            Library:Tween(Item.Frame, FAST, { BackgroundTransparency = Active and 0.86 or 1 })
            Item.Label.TextColor3 = Active and Library.Theme.Text or Library.Theme.TextDim
        end
    end

    local function Run(Index)
        local Item = Results[Index]
        if not Item then
            return
        end
        Handle:Close()
        task.defer(Item.Entry.Jump)
    end

    local function Refresh()
        for _, Child in ipairs(List:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
        table.clear(Results)
        Cursor = 1

        local Query = Box.Text:lower()
        local Shown = 0
        for _, Entry in ipairs(W.Index) do
            if Shown >= 40 then
                break
            end
            local Haystack = (Entry.Name .. " " .. (Entry.Tab or "") .. " " .. (Entry.Section or "")):lower()
            if Query == "" or Haystack:find(Query, 1, true) then
                Shown = Shown + 1
                local Item = New("TextButton", {
                    Parent = List,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -4, 0, 34),
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = Shown,
                    ZIndex = Handle.Frame.ZIndex + 3
                })
                Library:Corner(Item, 8)
                Library:Themed(Item, "BackgroundColor3", "Accent")

                local Kind = IconLabel(Item, Entry.Kind == "Tab" and Library.Icons.Tab or Library.Icons.Right, 14, "Accent")
                Kind.AnchorPoint = Vector2.new(0, 0.5)
                Kind.Position = UDim2.new(0, 10, 0.5, 0)
                Kind.ZIndex = Item.ZIndex + 1
                Library:Themed(Kind, "ImageColor3", "Accent")

                local Name = New("TextLabel", {
                    Parent = Item,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 32, 0, 0),
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Font = Library.Font.Medium,
                    Text = Entry.Name,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = Item.ZIndex + 1
                })
                Library:Themed(Name, "TextColor3", "TextDim")

                local Path = New("TextLabel", {
                    Parent = Item,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0.36, 0, 1, 0),
                    Font = Library.Font.Regular,
                    Text = Entry.Kind == "Tab" and "tab" or (Entry.Tab .. " / " .. Entry.Section),
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = Item.ZIndex + 1
                })
                Library:Themed(Path, "TextColor3", "TextDisabled")

                local Record = { Frame = Item, Label = Name, Entry = Entry }
                table.insert(Results, Record)
                local Position = Shown
                Item.MouseButton1Click:Connect(function()
                    Run(Position)
                end)
                Item.MouseEnter:Connect(function()
                    Cursor = Position
                    Paint()
                end)
            end
        end
        Paint()
    end

    Box:GetPropertyChangedSignal("Text"):Connect(Refresh)

    local Keys = UserInputService.InputBegan:Connect(function(Input)
        if not Handle.Open then
            return
        end
        if Input.KeyCode == Enum.KeyCode.Down then
            Cursor = math.min(Cursor + 1, #Results)
            Paint()
        elseif Input.KeyCode == Enum.KeyCode.Up then
            Cursor = math.max(Cursor - 1, 1)
            Paint()
        elseif Input.KeyCode == Enum.KeyCode.Return then
            Run(Cursor)
        end
    end)

    local Wrapped = Handle.Close
    Handle.Close = function(self)
        Keys:Disconnect()
        Wrapped(self)
    end

    Refresh()
    task.defer(function()
        Box:CaptureFocus()
    end)
    return Handle
end

-- ============================================================ config manager

function WM.ConfigPanel(W)
    local Handle = WM.Modal(W, {
        Title = "Configuration",
        Description = "Profiles are stored in " .. W.Paths.Configs,
        Icon = Library.Icons.Save,
        Width = 460,
        Height = 340
    })

    local List = New("ScrollingFrame", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 6),
        Size = UDim2.new(1, 0, 1, -50),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    Library:StyleScroll(List)
    New("UIPadding", {
        Parent = List,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3)
    })
    New("UIListLayout", {
        Parent = List,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })

    local Refresh

    local function Entry(Name, Order)
        local Active = Name == W.Profile
        local Item = New("Frame", {
            Parent = List,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -4, 0, 40),
            BackgroundTransparency = Active and 0.86 or 0,
            LayoutOrder = Order,
            ZIndex = Handle.Frame.ZIndex + 3
        })
        Library:Corner(Item, 9)
        if Active then
            Library:Themed(Item, "BackgroundColor3", "Accent")
        else
            Library:Themed(Item, "BackgroundColor3", "Row")
            Library:Themed(Item, "BackgroundTransparency", "RowAlpha")
        end
        Library:Stroke(Item, "StrokeSoft", 1)

        local Icon = IconLabel(Item, Active and Library.Icons.Check or Library.Icons.Folder, 15, Active and "Accent" or "TextDisabled")
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.Position = UDim2.new(0, 12, 0.5, 0)
        Icon.ZIndex = Item.ZIndex + 1

        local Label2 = New("TextLabel", {
            Parent = Item,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 36, 0, 0),
            Size = UDim2.new(1, -180, 1, 0),
            Font = Library.Font.Medium,
            Text = Name,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = Item.ZIndex + 1
        })
        Library:Themed(Label2, "TextColor3", "Text")

        local Actions = Blank(Item, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(140, 26),
            ZIndex = Item.ZIndex + 1
        })
        New("UIListLayout", {
            Parent = Actions,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        local function Action(IconName, Order2, Handler)
            local Button = GlyphButton(Actions, IconName, "")
            Button.Size = UDim2.fromOffset(26, 26)
            Button.LayoutOrder = Order2
            Button.ZIndex = Item.ZIndex + 2
            for _, Child in ipairs(Button:GetDescendants()) do
                if Child:IsA("GuiObject") then
                    Child.ZIndex = Button.ZIndex + 1
                end
            end
            Button.MouseButton1Click:Connect(Handler)
            return Button
        end

        Action(Library.Icons.Refresh, 1, function()
            W.API:LoadConfig(Name)
            Refresh()
            W.API:Notify({ Title = "Config loaded", Content = Name, Type = "Success" })
        end)
        Action(Library.Icons.Save, 2, function()
            W.API:SaveConfig(Name)
            W.API:Notify({ Title = "Config saved", Content = Name, Type = "Success" })
        end)
        Action(Library.Icons.Edit, 3, function()
            WM.Prompt(W, {
                Title = "Rename profile",
                Default = Name,
                Confirm = "Rename",
                Callback = function(Value)
                    if Value == "" then
                        return false, "name required"
                    end
                    W.API:RenameConfig(Name, Value)
                    Refresh()
                    return true
                end
            })
        end)
        Action(Library.Icons.Trash, 4, function()
            WM.Dialog(W, {
                Title = "Delete profile",
                Description = "Delete " .. Name .. " permanently?",
                Buttons = {
                    {
                        Text = "Delete",
                        Accent = true,
                        Callback = function()
                            W.API:DeleteConfig(Name)
                            Refresh()
                        end
                    },
                    { Text = "Cancel" }
                }
            })
        end)

        local Click = New("TextButton", {
            Parent = Item,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -150, 1, 0),
            Text = "",
            AutoButtonColor = false,
            ZIndex = Item.ZIndex + 1
        })
        Click.MouseButton1Click:Connect(function()
            W.API:LoadConfig(Name)
            Refresh()
        end)
    end

    function Refresh()
        for _, Child in ipairs(List:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
        for Index, Name in ipairs(W.API:ListConfigs()) do
            Entry(Name, Index)
        end
    end

    local Footer = Blank(Handle.Body, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 34),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    New("UIListLayout", {
        Parent = Footer,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local NewButton = PillButton(Footer, "New profile", Library.Icons.Plus, 140, true)
    NewButton.LayoutOrder = 1
    NewButton.ZIndex = Handle.Frame.ZIndex + 3
    NewButton.MouseButton1Click:Connect(function()
        WM.Prompt(W, {
            Title = "New profile",
            Placeholder = "legit / rage / farm",
            Confirm = "Create",
            Callback = function(Value)
                if Value == "" then
                    return false, "name required"
                end
                W.API:SaveConfig(Value)
                W.Profile = Value
                W.ProfileLabel.Text = Value
                W.SaveState()
                Refresh()
                return true
            end
        })
    end)

    local CopyButton = PillButton(Footer, "Copy to clipboard", Library.Icons.Copy, 170)
    CopyButton.LayoutOrder = 2
    CopyButton.ZIndex = Handle.Frame.ZIndex + 3
    CopyButton.MouseButton1Click:Connect(function()
        if Env.setclipboard then
            local Ok, Encoded = pcall(HttpService.JSONEncode, HttpService, W.API:GetConfig())
            if Ok then
                pcall(Env.setclipboard, Encoded)
                W.API:Notify({ Title = "Copied", Content = "Config json in clipboard", Type = "Success" })
            end
        end
    end)

    for _, Button in ipairs({ NewButton, CopyButton }) do
        for _, Child in ipairs(Button:GetDescendants()) do
            if Child:IsA("GuiObject") then
                Child.ZIndex = Button.ZIndex + 1
            end
        end
    end

    Refresh()
    return Handle
end

-- ============================================================ theme panel

function WM.ThemePanel(W)
    local Handle = WM.Modal(W, {
        Title = "Appearance",
        Description = "Theme, accent and feedback",
        Icon = Library.Icons.Palette,
        Width = 440,
        Height = 360
    })

    local Scroll = New("ScrollingFrame", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 4),
        Size = UDim2.new(1, 0, 1, -8),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    Library:StyleScroll(Scroll)
    New("UIPadding", {
        Parent = Scroll,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3)
    })
    New("UIListLayout", {
        Parent = Scroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })

    local function Caption(Text, Order)
        local Item = New("TextLabel", {
            Parent = Scroll,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -6, 0, 16),
            Font = Library.Font.Bold,
            Text = string.upper(Text),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = Order,
            ZIndex = Handle.Frame.ZIndex + 3
        })
        Library:Themed(Item, "TextColor3", "TextDisabled")
        return Item
    end

    Caption("Theme", 1)

    local Themes = New("Frame", {
        Parent = Scroll,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        ZIndex = Handle.Frame.ZIndex + 3
    })
    New("UIGridLayout", {
        Parent = Themes,
        CellPadding = UDim2.fromOffset(8, 8),
        CellSize = UDim2.new(0.5, -4, 0, 58),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local Cards = {}
    local function PaintThemes()
        for Name, Card in pairs(Cards) do
            local Active = Name == Library.CurrentTheme
            Library:Tween(Card.Line, FAST, {
                Color = Active and Library.Theme.Accent or Library.Theme.StrokeSoft,
                Transparency = Active and 0.2 or Library.Theme.StrokeSoftAlpha
            })
        end
    end

    for Index, Name in ipairs(Library.ThemeOrder) do
        local Tokens = Library.Themes[Name]
        local Card = New("TextButton", {
            Parent = Themes,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Index,
            BackgroundColor3 = Tokens.Main,
            ZIndex = Handle.Frame.ZIndex + 4
        })
        Library:Corner(Card, 10)
        local Line = Library:Stroke(Card, "StrokeSoft", 1.4)

        local Dot = New("Frame", {
            Parent = Card,
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Tokens.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            ZIndex = Card.ZIndex + 1
        })
        Library:Corner(Dot, UDim.new(1, 0))

        local Name2 = New("TextLabel", {
            Parent = Card,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 40, 0, 0),
            Size = UDim2.new(1, -48, 1, 0),
            Font = Library.Font.Medium,
            Text = Name,
            TextSize = 12,
            TextColor3 = Tokens.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = Card.ZIndex + 1
        })

        Cards[Name] = { Frame = Card, Line = Line, Label = Name2 }

        Card.MouseButton1Click:Connect(function()
            Library:Feedback(1.1)
            Library:ApplyTheme(Name)
            W.SaveState()
            PaintThemes()
            if W.Blur then
                Library:Tween(W.Blur, NORMAL, { Size = W.Open and Library.Theme.Blur or 0 })
            end
        end)
    end
    PaintThemes()

    -- the active card highlight is painted with the accent, so it has to
    -- follow a live accent change instead of keeping the colour it opened with
    local Repaint = Library.OnThemeChanged:Connect(PaintThemes)

    Caption("Accent", 3)

    local AccentRow = New("Frame", {
        Parent = Scroll,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 74),
        LayoutOrder = 4,
        ZIndex = Handle.Frame.ZIndex + 3
    })

    local Presets = {
        Color3.fromRGB(179, 0, 255), Color3.fromRGB(120, 80, 255), Color3.fromRGB(0, 170, 255),
        Color3.fromRGB(0, 220, 180), Color3.fromRGB(120, 220, 60), Color3.fromRGB(255, 190, 40),
        Color3.fromRGB(255, 120, 40), Color3.fromRGB(255, 60, 110)
    }

    local Swatches = Blank(AccentRow, { Size = UDim2.new(1, 0, 0, 30), ZIndex = AccentRow.ZIndex })
    New("UIListLayout", {
        Parent = Swatches,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    for Index, Color in ipairs(Presets) do
        local Swatch = New("TextButton", {
            Parent = Swatches,
            BackgroundColor3 = Color,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(30, 30),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Index,
            ZIndex = AccentRow.ZIndex + 1
        })
        Library:Corner(Swatch, 8)
        Library:Stroke(Swatch, "StrokeSoft", 1)
        Swatch.MouseButton1Click:Connect(function()
            Library:SetAccent(Color)
            W.SaveState()
            Library:Feedback(1.15)
        end)
    end

    local HueTrack = New("Frame", {
        Parent = AccentRow,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 42),
        Size = UDim2.new(1, 0, 0, 18),
        Active = true,
        ZIndex = AccentRow.ZIndex + 1
    })
    Library:Corner(HueTrack, 6)
    do
        local Colors = {}
        for Index = 0, 6 do
            table.insert(Colors, ColorSequenceKeypoint.new(Index / 6, Color3.fromHSV(Index / 6, 1, 1)))
        end
        New("UIGradient", { Parent = HueTrack, Color = ColorSequence.new(Colors) })
    end

    local HueDragging = false
    local function ApplyHue(Position)
        local Alpha = Clamp((Position.X - HueTrack.AbsolutePosition.X) / math.max(HueTrack.AbsoluteSize.X, 1), 0, 1)
        Library:SetAccent(Color3.fromHSV(Alpha, 0.85, 1))
    end
    HueTrack.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            HueDragging = true
            ApplyHue(Input.Position)
        end
    end)
    local HueMoved = UserInputService.InputChanged:Connect(function(Input)
        if HueDragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
            or Input.UserInputType == Enum.UserInputType.Touch) then
            ApplyHue(Input.Position)
        end
    end)
    local HueEnded = UserInputService.InputEnded:Connect(function()
        if HueDragging then
            HueDragging = false
            W.SaveState()
        end
    end)

    Caption("Effects", 5)

    local Switches = New("Frame", {
        Parent = Scroll,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 6,
        ZIndex = Handle.Frame.ZIndex + 3
    })
    New("UIListLayout", {
        Parent = Switches,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })

    local function Switch(Text, Getter, Setter, Order)
        local Button = New("TextButton", {
            Parent = Switches,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Order,
            ZIndex = Switches.ZIndex + 1
        })
        Library:Corner(Button, 8)
        Library:Themed(Button, "BackgroundColor3", "Row")
        Library:Themed(Button, "BackgroundTransparency", "RowAlpha")
        Library:Stroke(Button, "StrokeSoft", 1)

        local Name = New("TextLabel", {
            Parent = Button,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -60, 1, 0),
            Font = Library.Font.Medium,
            Text = Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = Button.ZIndex + 1
        })
        Library:Themed(Name, "TextColor3", "Text")

        local Pill = New("Frame", {
            Parent = Button,
            AnchorPoint = Vector2.new(1, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(36, 20),
            ZIndex = Button.ZIndex + 1
        })
        Library:Corner(Pill, UDim.new(1, 0))

        local Knob = New("Frame", {
            Parent = Pill,
            AnchorPoint = Vector2.new(0, 0.5),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(14, 14),
            ZIndex = Pill.ZIndex + 1
        })
        Library:Corner(Knob, UDim.new(1, 0))

        local function Paint()
            local On = Getter()
            Pill.BackgroundColor3 = On and Library.Theme.Accent or Library.Theme.Inset
            Knob.BackgroundColor3 = On and Library.Theme.AccentText or Library.Theme.TextDisabled
            Knob.Position = UDim2.new(0, On and 19 or 3, 0.5, 0)
        end

        Button.MouseButton1Click:Connect(function()
            Setter(not Getter())
            Paint()
            Library:Feedback(1.1)
            W.SaveState()
        end)
        Paint()
    end

    Switch("Glow effects", function()
        return Library.Particles
    end, function(Value)
        Library.Particles = Value
        W.Sheen.Visible = Value
    end, 3)

    Switch("Background blur", function()
        return W.Blur ~= nil and W.Blur.Size > 0
    end, function(Value)
        if W.Blur then
            Library:Tween(W.Blur, NORMAL, { Size = Value and math.max(Library.Theme.Blur, 12) or 0 })
        end
    end, 4)

    Caption("Import / export", 7)

    local IO = New("Frame", {
        Parent = Scroll,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 32),
        LayoutOrder = 8,
        ZIndex = Handle.Frame.ZIndex + 3
    })
    New("UIListLayout", {
        Parent = IO,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local ExportButton = PillButton(IO, "Export theme", Library.Icons.Copy, 150)
    ExportButton.LayoutOrder = 1
    ExportButton.ZIndex = IO.ZIndex + 1
    ExportButton.MouseButton1Click:Connect(function()
        local Json = Library:ExportTheme()
        if Json and Env.setclipboard then
            pcall(Env.setclipboard, Json)
            W.API:Notify({ Title = "Theme exported", Content = "json copied", Type = "Success" })
        end
    end)

    local ImportButton = PillButton(IO, "Import theme", Library.Icons.Plus, 150, true)
    ImportButton.LayoutOrder = 2
    ImportButton.ZIndex = IO.ZIndex + 1
    ImportButton.MouseButton1Click:Connect(function()
        WM.Prompt(W, {
            Title = "Import theme",
            Description = "Paste exported theme json",
            Confirm = "Import",
            Callback = function(Value)
                local Ok, Name = Library:ImportTheme(Value)
                if not Ok then
                    return false, Name
                end
                Library:ApplyTheme(Name)
                W.SaveState()
                Handle:Close()
                W.API:Notify({ Title = "Theme imported", Content = Name, Type = "Success" })
                return true
            end
        })
    end)

    for _, Button in ipairs({ ExportButton, ImportButton }) do
        for _, Child in ipairs(Button:GetDescendants()) do
            if Child:IsA("GuiObject") then
                Child.ZIndex = Button.ZIndex + 1
            end
        end
    end

    local Closed = Handle.Close
    Handle.Close = function(self)
        HueMoved:Disconnect()
        HueEnded:Disconnect()
        Repaint:Disconnect()
        Closed(self)
    end
    return Handle
end

-- ============================================================ keybind manager

function WM.KeybindPanel(W)
    local Handle = WM.Modal(W, {
        Title = "Keybinds",
        Description = "Every bind registered in this window",
        Icon = Library.Icons.Key,
        Width = 440,
        Height = 320
    })

    local List = New("ScrollingFrame", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 4),
        Size = UDim2.new(1, 0, 1, -46),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    Library:StyleScroll(List)
    New("UIPadding", {
        Parent = List,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3)
    })
    New("UIListLayout", {
        Parent = List,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })

    local Refresh

    local function Entry(Bind, Order)
        local Element = Bind.Element
        local Item = New("Frame", {
            Parent = List,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -4, 0, 38),
            LayoutOrder = Order,
            ZIndex = Handle.Frame.ZIndex + 3
        })
        Library:Corner(Item, 9)
        Library:Themed(Item, "BackgroundColor3", "Row")
        Library:Themed(Item, "BackgroundTransparency", "RowAlpha")
        Library:Stroke(Item, "StrokeSoft", 1)

        local Name = New("TextLabel", {
            Parent = Item,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -160, 1, 0),
            Font = Library.Font.Medium,
            Text = Element.Title,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = Item.ZIndex + 1
        })
        Library:Themed(Name, "TextColor3", "Text")

        local Path = New("TextLabel", {
            Parent = Item,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 20),
            Size = UDim2.new(1, -160, 0, 12),
            Font = Library.Font.Regular,
            Text = Element.Section.Tab.Name .. " / " .. Element.Section.Title,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = Item.ZIndex + 1
        })
        Library:Themed(Path, "TextColor3", "TextDisabled")
        Name.Position = UDim2.new(0, 12, 0, 5)
        Name.Size = UDim2.new(1, -160, 0, 16)

        local KeyButton = PillButton(Item, KeyName(Element:Get()), Library.Icons.Key, 96)
        KeyButton.AnchorPoint = Vector2.new(1, 0.5)
        KeyButton.Position = UDim2.new(1, -46, 0.5, 0)
        KeyButton.ZIndex = Item.ZIndex + 1
        for _, Child in ipairs(KeyButton:GetDescendants()) do
            if Child:IsA("GuiObject") then
                Child.ZIndex = KeyButton.ZIndex + 1
            end
        end
        KeyButton.MouseButton1Click:Connect(function()
            Handle:Close()
            Element.Registry.Jump()
        end)

        local ClearButton = GlyphButton(Item, Library.Icons.Trash, "Clear")
        ClearButton.AnchorPoint = Vector2.new(1, 0.5)
        ClearButton.Position = UDim2.new(1, -10, 0.5, 0)
        ClearButton.Size = UDim2.fromOffset(28, 28)
        ClearButton.ZIndex = Item.ZIndex + 1
        for _, Child in ipairs(ClearButton:GetDescendants()) do
            if Child:IsA("GuiObject") then
                Child.ZIndex = ClearButton.ZIndex + 1
            end
        end
        ClearButton.MouseButton1Click:Connect(function()
            Element:Set(nil)
            Refresh()
        end)
    end

    function Refresh()
        for _, Child in ipairs(List:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
        if #W.Keybinds == 0 then
            local Empty = New("TextLabel", {
                Parent = List,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 60),
                Font = Library.Font.Regular,
                Text = "No keybind registered yet",
                TextSize = 12,
                ZIndex = Handle.Frame.ZIndex + 3
            })
            Library:Themed(Empty, "TextColor3", "TextDisabled")
            return
        end
        for Index, Bind in ipairs(W.Keybinds) do
            Entry(Bind, Index)
        end
    end

    local Reset = PillButton(Handle.Body, "Reset all binds", Library.Icons.Refresh, 170, true)
    Reset.AnchorPoint = Vector2.new(0, 1)
    Reset.Position = UDim2.new(0, 0, 1, 0)
    Reset.ZIndex = Handle.Frame.ZIndex + 3
    for _, Child in ipairs(Reset:GetDescendants()) do
        if Child:IsA("GuiObject") then
            Child.ZIndex = Reset.ZIndex + 1
        end
    end
    Reset.MouseButton1Click:Connect(function()
        for _, Bind in ipairs(W.Keybinds) do
            Bind.Element:Set(Bind.Config.Default)
        end
        Refresh()
    end)

    Refresh()
    return Handle
end

-- ============================================================ changelog

function WM.Changelog(W, Config)
    Config = Merge({
        Title = "Changelog",
        Entries = {}
    }, Config or {})

    local Handle = WM.Modal(W, {
        Title = Config.Title,
        Description = W.Config.Title .. " " .. tostring(W.Config.Version),
        Icon = Library.Icons.Sparkles,
        Width = 440,
        Height = 340
    })

    local Scroll = New("ScrollingFrame", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Handle.Frame.ZIndex + 2
    })
    Library:StyleScroll(Scroll)
    New("UIPadding", {
        Parent = Scroll,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3)
    })
    New("UIListLayout", {
        Parent = Scroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })

    for Index, Entry in ipairs(Config.Entries) do
        local Block = New("Frame", {
            Parent = Scroll,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -6, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = Index,
            ZIndex = Handle.Frame.ZIndex + 3
        })
        Library:Corner(Block, 10)
        Library:Themed(Block, "BackgroundColor3", "Row")
        Library:Themed(Block, "BackgroundTransparency", "RowAlpha")
        Library:Stroke(Block, "StrokeSoft", 1)
        New("UIPadding", {
            Parent = Block,
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        })
        New("UIListLayout", {
            Parent = Block,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        })

        local Head = New("TextLabel", {
            Parent = Block,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Library.Font.Bold,
            Text = (Entry.Version or Entry.Title or "Update") ..
                (Entry.Date and ("  <font size=\"11\">" .. Entry.Date .. "</font>") or ""),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            RichText = true,
            LayoutOrder = 0,
            ZIndex = Block.ZIndex + 1
        })
        Library:Themed(Head, "TextColor3", "Text")

        for NoteIndex, Note in ipairs(Entry.Notes or {}) do
            local Line = New("TextLabel", {
                Parent = Block,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Library.Font.Regular,
                Text = "-  " .. Note,
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = NoteIndex,
                RichText = true,
                ZIndex = Block.ZIndex + 1
            })
            Library:Themed(Line, "TextColor3", "TextDim")
        end
    end

    return Handle
end

-- ============================================================ notifications

function WM.Notify(W, Config)
    Config = Merge({
        Title = "Notification",
        Content = "",
        Desc = nil,
        Type = "Info",
        Duration = 4,
        Buttons = {},
        Progress = false
    }, Config or {})

    local Body = Config.Content ~= "" and Config.Content or (Config.Desc or "")
    local Kinds = {
        Info = { Key = "Info", Icon = "info" },
        Success = { Key = "Success", Icon = "circle-check" },
        Warn = { Key = "Warn", Icon = "triangle-alert" },
        Error = { Key = "Error", Icon = "circle-x" }
    }
    local Kind = Kinds[Config.Type] or Kinds.Info
    local Tint = Library.Theme[Kind.Key]

    local HasButtons = #Config.Buttons > 0
    local Height = 64 + (Body ~= "" and 14 or 0) + (HasButtons and 34 or 0)
    local Width = W.Mobile and math.min(Device.Viewport().X - 24, 300) or 292

    local Card = New("Frame", {
        Parent = W.Gui,
        Name = "Notification",
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, 320, 0, 0),
        Size = UDim2.fromOffset(Width, Height),
        ZIndex = 300
    })
    Library:Corner(Card, 12)
    Library:Themed(Card, "BackgroundColor3", "Elevated")
    Library:Themed(Card, "BackgroundTransparency", "ElevatedAlpha")
    New("UIStroke", { Parent = Card, Color = Tint, Transparency = 0.55, Thickness = 1.2 })
    Library:Shadow(Card, 50, 0.6)
    Library:Sheen(Card, 90).ZIndex = 300

    local IconHolder = New("Frame", {
        Parent = Card,
        BackgroundColor3 = Tint,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.fromOffset(30, 30),
        ZIndex = 301
    })
    Library:Corner(IconHolder, 9)
    New("UIStroke", { Parent = IconHolder, Color = Tint, Transparency = 0.65, Thickness = 1 })

    local Icon = New("ImageLabel", {
        Parent = IconHolder,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16),
        ZIndex = 302
    })
    Library:SetIcon(Icon, Kind.Icon, Tint)

    local Title = New("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(52, 13),
        Size = UDim2.new(1, -84, 0, 16),
        Font = Library.Font.Bold,
        Text = Config.Title,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 302
    })
    Library:Themed(Title, "TextColor3", "Text")

    local Content = New("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(52, 30),
        Size = UDim2.new(1, -68, 0, 28),
        Font = Library.Font.Regular,
        Text = Body,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        RichText = true,
        ZIndex = 302
    })
    Library:Themed(Content, "TextColor3", "TextDim")

    local Close = New("TextButton", {
        Parent = Card,
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -8, 0, 10),
        Size = UDim2.fromOffset(20, 20),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 303
    })
    local CloseIcon = IconLabel(Close, Library.Icons.Close, 12, "TextDisabled")
    CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseIcon.Position = UDim2.fromScale(0.5, 0.5)
    CloseIcon.ZIndex = 304

    local Bar = New("Frame", {
        Parent = Card,
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Tint,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -6),
        Size = UDim2.new(1, -24, 0, 3),
        ZIndex = 302
    })
    Library:Corner(Bar, UDim.new(1, 0))

    if HasButtons then
        local Actions = Blank(Card, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 12, 1, -12),
            Size = UDim2.new(1, -24, 0, 26),
            ZIndex = 302
        })
        New("UIListLayout", {
            Parent = Actions,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local Count = #Config.Buttons
        for Index, Info in ipairs(Config.Buttons) do
            local Button, TextLabel = PillButton(Actions, Info.Text or "Ok", Info.Icon, 0, Info.Accent)
            Button.Size = UDim2.new(1 / Count, -6 + 6 / Count, 1, 0)
            Button.LayoutOrder = Index
            Button.ZIndex = 303
            TextLabel.TextSize = 11
            for _, Child in ipairs(Button:GetDescendants()) do
                if Child:IsA("GuiObject") then
                    Child.ZIndex = 304
                end
            end
            Button.MouseButton1Click:Connect(function()
                if Info.Callback then
                    task.spawn(Info.Callback)
                end
                if Info.Close ~= false then
                    Card:SetAttribute("Dismiss", true)
                end
            end)
        end
        Bar.Position = UDim2.new(0, 12, 1, -44)
    end

    local Record = { Card = Card, Height = Height }
    table.insert(W.Notifications, Record)

    local function Reflow()
        local Offset = 16
        for _, Item in ipairs(W.Notifications) do
            if Item.Card.Parent then
                Library:Tween(Item.Card, NORMAL, { Position = UDim2.new(1, -16, 0, Offset) })
                Offset = Offset + Item.Height + 10
            end
        end
    end

    local Closing = false
    local function Dismiss()
        if Closing then
            return
        end
        Closing = true
        for Index, Item in ipairs(W.Notifications) do
            if Item == Record then
                table.remove(W.Notifications, Index)
                break
            end
        end
        Reflow()
        Library:Tween(Card, TweenInfo.new(0.3, Quart, In), {
            Position = UDim2.new(1, 340, 0, Card.Position.Y.Offset)
        }, function()
            Card:Destroy()
        end)
    end

    Close.MouseButton1Click:Connect(Dismiss)
    Card:GetAttributeChangedSignal("Dismiss"):Connect(Dismiss)

    Reflow()
    Library:Pop(Card, 0.36, 0.9)
    Library:Play(1.25)

    local Handle = { Frame = Card, Close = Dismiss }

    if Config.Progress then
        Bar.Size = UDim2.new(0, 0, 0, 3)
        function Handle:SetProgress(Alpha)
            Library:Tween(Bar, FAST, { Size = UDim2.new(Clamp(Alpha, 0, 1), -24, 0, 3) })
        end
        function Handle:SetContent(Text)
            Content.Text = tostring(Text)
        end
        function Handle:SetTitle(Text)
            Title.Text = tostring(Text)
        end
    else
        local Timer = TweenService:Create(Bar, TweenInfo.new(Config.Duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 0, 3)
        })
        Timer:Play()
        Timer.Completed:Connect(function(State)
            if State == Enum.PlaybackState.Completed then
                Dismiss()
            end
        end)
    end

    return Handle
end

-- ============================================================ player card

local function ExecutorName()
    if Env.identifyexecutor then
        local Ok, Name, Version = pcall(Env.identifyexecutor)
        if Ok and Name then
            return tostring(Name) .. (Version and (" " .. tostring(Version)) or "")
        end
    end
    for _, Name in ipairs({ "Potassium", "Solara", "Xeno", "Wave", "Delta", "Krnl", "Synapse", "Fluxus" }) do
        if rawget(getfenv(), Name:lower()) ~= nil then
            return Name
        end
    end
    return "unknown"
end

local function HardwareId()
    local Id
    if Env.gethwid then
        local Ok, Value = pcall(Env.gethwid)
        if Ok and Value then
            Id = tostring(Value)
        end
    end
    if not Id then
        local Ok, Value = pcall(function()
            return game:GetService("RbxAnalyticsService"):GetClientId()
        end)
        Id = Ok and tostring(Value) or "unavailable"
    end
    return Id
end

local function Clock(Seconds)
    local Hours = math.floor(Seconds / 3600)
    local Minutes = math.floor((Seconds % 3600) / 60)
    local Rest = math.floor(Seconds % 60)
    if Hours > 0 then
        return string.format("%02d:%02d:%02d", Hours, Minutes, Rest)
    end
    return string.format("%02d:%02d", Minutes, Rest)
end

function WM.PlayerCard(W)
    if W.Card then
        return W.Card
    end

    local Card = New("Frame", {
        Parent = W.Gui,
        Name = "PlayerCard",
        AnchorPoint = Vector2.new(1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.fromOffset(268, 236),
        Visible = false,
        ZIndex = 260
    })
    Library:Corner(Card, 14)
    Library:Themed(Card, "BackgroundColor3", "Elevated")
    Library:Themed(Card, "BackgroundTransparency", "ElevatedAlpha")
    Library:Stroke(Card, "Stroke", 1.2)
    Library:Shadow(Card, 60, 0.6)
    Library:Sheen(Card, 90).ZIndex = 260

    local Avatar = New("ImageLabel", {
        Parent = Card,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(52, 52),
        ZIndex = 261
    })
    Library:Corner(Avatar, 12)
    Library:Themed(Avatar, "BackgroundColor3", "Row")

    task.spawn(function()
        local Ok, Url = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if Ok then
            Avatar.Image = Url
        end
    end)

    local Name = New("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(76, 18),
        Size = UDim2.new(1, -110, 0, 18),
        Font = Library.Font.Bold,
        Text = LocalPlayer.DisplayName,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 261
    })
    Library:Themed(Name, "TextColor3", "Text")

    local Handle2 = New("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(76, 36),
        Size = UDim2.new(1, -110, 0, 14),
        Font = Library.Font.Regular,
        Text = "@" .. LocalPlayer.Name,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 261
    })
    Library:Themed(Handle2, "TextColor3", "TextDim")

    local Badge = New("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(76, 52),
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Library.Font.Bold,
        Text = " " .. ExecutorName() .. " ",
        TextSize = 10,
        ZIndex = 261
    })
    Library:Corner(Badge, 5)
    Library:Themed(Badge, "BackgroundColor3", "Accent")
    Library:Themed(Badge, "TextColor3", "Accent")

    local Close = GlyphButton(Card, Library.Icons.Close, "Close")
    Close.AnchorPoint = Vector2.new(1, 0)
    Close.Position = UDim2.new(1, -8, 0, 10)
    Close.ZIndex = 262
    for _, Child in ipairs(Close:GetDescendants()) do
        if Child:IsA("GuiObject") then
            Child.ZIndex = 263
        end
    end

    local Rows = Blank(Card, {
        Position = UDim2.fromOffset(14, 78),
        Size = UDim2.new(1, -28, 1, -92),
        ZIndex = 261
    })
    New("UIListLayout", {
        Parent = Rows,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })

    local Values = {}
    local function Stat(IconName, Key, Text, Order, Copyable)
        local Row = New("Frame", {
            Parent = Rows,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 26),
            LayoutOrder = Order,
            ZIndex = 261
        })
        Library:Corner(Row, 7)
        Library:Themed(Row, "BackgroundColor3", "Row")
        Library:Themed(Row, "BackgroundTransparency", "RowAlpha")

        local Icon = IconLabel(Row, IconName, 13, "Accent")
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.Position = UDim2.new(0, 9, 0.5, 0)
        Icon.ZIndex = 262
        Library:Themed(Icon, "ImageColor3", "Accent")

        local Value = New("TextLabel", {
            Parent = Row,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 30, 0, 0),
            Size = UDim2.new(1, Copyable and -60 or -40, 1, 0),
            Font = Library.Font.Medium,
            Text = Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 262
        })
        Library:Themed(Value, "TextColor3", "TextDim")
        Values[Key] = Value

        if Copyable then
            local Copy = GlyphButton(Row, Library.Icons.Copy, "Copy")
            Copy.AnchorPoint = Vector2.new(1, 0.5)
            Copy.Position = UDim2.new(1, -4, 0.5, 0)
            Copy.Size = UDim2.fromOffset(24, 24)
            Copy.ZIndex = 262
            for _, Child in ipairs(Copy:GetDescendants()) do
                if Child:IsA("GuiObject") then
                    Child.ZIndex = 263
                end
            end
            Copy.MouseButton1Click:Connect(function()
                if Env.setclipboard then
                    pcall(Env.setclipboard, Copyable == true and Value.Text or Copyable)
                    W.API:Notify({ Title = "Copied", Content = Value.Text, Type = "Success", Duration = 2 })
                end
            end)
        end
        return Value
    end

    local Id = HardwareId()
    Stat(Library.Icons.Finger, "Hwid", "HWID " .. Id:sub(1, 12) .. "...", 1, Id)
    Stat(Library.Icons.User, "User", "UserId " .. LocalPlayer.UserId, 2, tostring(LocalPlayer.UserId))
    Stat(Library.Icons.Gauge, "Fps", "FPS --", 3)
    Stat(Library.Icons.Signal, "Ping", "Ping --", 4)
    Stat(Library.Icons.Clock, "Uptime", "Session 00:00", 5, true)

    local Start = os.clock()
    local Frames, Last, Fps = 0, os.clock(), 60
    table.insert(W.Connections, RunService.RenderStepped:Connect(function()
        Frames = Frames + 1
        local Now = os.clock()
        if Now - Last >= 1 then
            Fps = Frames / (Now - Last)
            Frames, Last = 0, Now
            if Card.Visible then
                Values.Fps.Text = "FPS " .. math.floor(Fps + 0.5)
                Values.Uptime.Text = "Session " .. Clock(os.clock() - Start)
                local Ping = 0
                if StatsService then
                    local Ok, Value = pcall(function()
                        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
                    end)
                    Ping = Ok and Value or 0
                end
                Values.Ping.Text = "Ping " .. math.floor(Ping + 0.5) .. " ms"
            end
        end
    end))

    do
        local Dragging, Origin, StartPosition = false, nil, nil
        Card.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                Origin = Input.Position
                StartPosition = Card.Position
            end
        end)
        table.insert(W.Connections, UserInputService.InputChanged:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
                or Input.UserInputType == Enum.UserInputType.Touch) then
                local Delta = Input.Position - Origin
                Card.Position = UDim2.new(
                    StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
                    StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
                )
            end
        end))
        table.insert(W.Connections, UserInputService.InputEnded:Connect(function()
            Dragging = false
        end))
    end

    Close.MouseButton1Click:Connect(function()
        WM.TogglePlayerCard(W, false)
    end)

    W.Card = Card
    return Card
end

function WM.TogglePlayerCard(W, State)
    local Card = WM.PlayerCard(W)
    if State == nil then
        State = not Card.Visible
    end
    if State then
        Card.Visible = true
        Library:Pop(Card, 0.3, 0.9)
    else
        Library:Tween(Card, FAST, { BackgroundTransparency = 1 }, function()
            Card.Visible = false
            Card.BackgroundTransparency = Library.Theme.ElevatedAlpha
        end)
    end
end

-- ============================================================ ai panel

Library.Groq = {
    Endpoint = "https://api.groq.com/openai/v1/chat/completions",
    Key = "",
    Prompt = "You are a concise assistant embedded in a Roblox script hub.",
    Model = "openai/gpt-oss-120b",
    -- Groq deprecated its Llama chat models (llama-3.3-70b-versatile,
    -- llama-3.1-8b-instant) and the old qwen/deepseek preview slugs have
    -- since rotated too -- verified against console.groq.com/docs/models.
    -- Kept to Production-tier models/systems only, since Preview models
    -- can be pulled without notice.
    Models = {
        "openai/gpt-oss-120b",
        "openai/gpt-oss-20b",
        "groq/compound",
        "groq/compound-mini"
    }
}

function Library:SetGroq(Key, Prompt, Model)
    if type(Key) == "string" and Key ~= "" then
        Library.Groq.Key = Key
    end
    if type(Prompt) == "string" then
        Library.Groq.Prompt = Prompt
    end
    if type(Model) == "string" and Model ~= "" then
        Library.Groq.Model = Model
    end
end

local function GroqAsk(History, OnDone)
    task.spawn(function()
        if not Env.request then
            return OnDone(false, "no http request function in this executor")
        end
        if Library.Groq.Key == "" then
            return OnDone(false, "no api key set, pass GroqApiKey in the window config")
        end
        local Messages = { { role = "system", content = Library.Groq.Prompt } }
        for _, Entry in ipairs(History) do
            table.insert(Messages, { role = Entry.Role, content = Entry.Text })
        end
        local Ok, Response = pcall(Env.request, {
            Url = Library.Groq.Endpoint,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. Library.Groq.Key
            },
            Body = HttpService:JSONEncode({
                model = Library.Groq.Model,
                messages = Messages,
                temperature = 0.6,
                max_tokens = 900
            })
        })
        if not Ok or not Response or not Response.Body then
            return OnDone(false, "request failed")
        end
        local Decoded, Data = pcall(HttpService.JSONDecode, HttpService, Response.Body)
        if not Decoded then
            return OnDone(false, "bad response")
        end
        if Data.error then
            return OnDone(false, tostring(Data.error.message or "api error"))
        end
        local Choice = Data.choices and Data.choices[1]
        local Text = Choice and Choice.message and Choice.message.content
        if not Text then
            return OnDone(false, "empty response")
        end
        OnDone(true, Trim(Text))
    end)
end

function WM.AI(W)
    if W.AIPanel then
        return W.AIPanel
    end

    local HistoryPath = W.Paths.Folder .. "/ai_history.json"
    local History = FS.ReadJSON(HistoryPath) or {}

    local Panel = New("Frame", {
        Parent = W.Main,
        Name = "AI",
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, W.Header.Size.Y.Offset),
        Size = UDim2.new(0, W.Mobile and 260 or 300, 1, -W.Header.Size.Y.Offset),
        Visible = false,
        ZIndex = 80,
        ClipsDescendants = true
    })
    Library:Themed(Panel, "BackgroundColor3", "Sidebar")
    Library:Themed(Panel, "BackgroundTransparency", "SidebarAlpha")

    local Edge = New("Frame", {
        Parent = Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundTransparency = 0.9,
        ZIndex = 81
    })
    Library:Themed(Edge, "BackgroundColor3", "Stroke")

    local Head = Blank(Panel, { Size = UDim2.new(1, 0, 0, 44), ZIndex = 82 })

    local HeadIcon = IconLabel(Head, Library.Icons.Bot, 18, "Accent")
    HeadIcon.AnchorPoint = Vector2.new(0, 0.5)
    HeadIcon.Position = UDim2.new(0, 14, 0.5, 0)
    HeadIcon.ZIndex = 83
    Library:Themed(HeadIcon, "ImageColor3", "Accent")

    local ModelButton = New("TextButton", {
        Parent = Head,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0.5, 0),
        Size = UDim2.new(1, -110, 0, 30),
        Font = Library.Font.Medium,
        Text = Library.Groq.Model,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false,
        ZIndex = 83
    })
    Library:Themed(ModelButton, "TextColor3", "Text")

    local ClearButton = GlyphButton(Head, Library.Icons.Trash, "Clear")
    ClearButton.AnchorPoint = Vector2.new(1, 0.5)
    ClearButton.Position = UDim2.new(1, -42, 0.5, 0)
    ClearButton.ZIndex = 83
    for _, Child in ipairs(ClearButton:GetDescendants()) do
        if Child:IsA("GuiObject") then
            Child.ZIndex = 84
        end
    end

    local CloseButton = GlyphButton(Head, Library.Icons.Close, "Close")
    CloseButton.AnchorPoint = Vector2.new(1, 0.5)
    CloseButton.Position = UDim2.new(1, -10, 0.5, 0)
    CloseButton.ZIndex = 83
    for _, Child in ipairs(CloseButton:GetDescendants()) do
        if Child:IsA("GuiObject") then
            Child.ZIndex = 84
        end
    end

    local Log = New("ScrollingFrame", {
        Parent = Panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 46),
        Size = UDim2.new(1, -20, 1, -104),
        ZIndex = 82
    })
    Library:StyleScroll(Log)
    New("UIPadding", {
        Parent = Log,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3)
    })
    New("UIListLayout", {
        Parent = Log,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })

    local function Bubble(Role, Text)
        local Mine = Role == "user"
        local Frame = New("Frame", {
            Parent = Log,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -6, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = Mine and 0.86 or 0,
            LayoutOrder = #Log:GetChildren(),
            ZIndex = 83
        })
        Library:Corner(Frame, 10)
        if Mine then
            Library:Themed(Frame, "BackgroundColor3", "Accent")
        else
            Library:Themed(Frame, "BackgroundColor3", "Row")
            Library:Themed(Frame, "BackgroundTransparency", "RowAlpha")
        end
        New("UIPadding", {
            Parent = Frame,
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        })
        local Content = New("TextLabel", {
            Parent = Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Library.Font.Regular,
            Text = Text,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 84
        })
        Library:Themed(Content, "TextColor3", Mine and "Text" or "TextDim")
        task.defer(function()
            Log.CanvasPosition = Vector2.new(0, math.max(Log.AbsoluteCanvasSize.Y, 0))
        end)
        return Content
    end

    for _, Entry in ipairs(History) do
        Bubble(Entry.Role, Entry.Text)
    end

    local Field = New("Frame", {
        Parent = Panel,
        AnchorPoint = Vector2.new(0, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, -10),
        Size = UDim2.new(1, -20, 0, 40),
        ZIndex = 82
    })
    Library:Corner(Field, 10)
    Library:Themed(Field, "BackgroundColor3", "Inset")
    Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
    Library:Stroke(Field, "StrokeSoft", 1)

    local Box = New("TextBox", {
        Parent = Field,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Library.Font.Regular,
        PlaceholderText = "Ask something",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 83
    })
    Library:Themed(Box, "TextColor3", "Text")
    Library:Themed(Box, "PlaceholderColor3", "TextDisabled")

    local Send = GlyphButton(Field, Library.Icons.Send, "Send")
    Send.AnchorPoint = Vector2.new(1, 0.5)
    Send.Position = UDim2.new(1, -6, 0.5, 0)
    Send.ZIndex = 83
    for _, Child in ipairs(Send:GetDescendants()) do
        if Child:IsA("GuiObject") then
            Child.ZIndex = 84
        end
    end

    local Busy = false
    local function Ask()
        local Text = Trim(Box.Text)
        if Text == "" or Busy then
            return
        end
        Busy = true
        Box.Text = ""
        table.insert(History, { Role = "user", Text = Text })
        Bubble("user", Text)
        local Pending = Bubble("assistant", "thinking...")
        GroqAsk(History, function(Ok, Reply)
            Busy = false
            Pending.Text = Ok and Reply or ("error: " .. tostring(Reply))
            if Ok then
                table.insert(History, { Role = "assistant", Text = Reply })
                FS.WriteJSON(HistoryPath, History)
            end
        end)
    end

    Send.MouseButton1Click:Connect(Ask)
    Box.FocusLost:Connect(function(Enter)
        if Enter then
            Ask()
        end
    end)

    ClearButton.MouseButton1Click:Connect(function()
        table.clear(History)
        FS.WriteJSON(HistoryPath, History)
        for _, Child in ipairs(Log:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
    end)

    ModelButton.MouseButton1Click:Connect(function()
        local Handle = Popup(W, ModelButton, 240, 10 + #Library.Groq.Models * 30)
        for Index, Model in ipairs(Library.Groq.Models) do
            local Item = New("TextButton", {
                Parent = Handle.Frame,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(6, 5 + (Index - 1) * 30),
                Size = UDim2.new(1, -12, 0, 28),
                Font = Library.Font.Medium,
                Text = Model,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                ZIndex = 103
            })
            Library:Corner(Item, 7)
            Library:Themed(Item, "TextColor3", Model == Library.Groq.Model and "Accent" or "TextDim")
            New("UIPadding", { Parent = Item, PaddingLeft = UDim.new(0, 10) })
            Item.MouseButton1Click:Connect(function()
                Library.Groq.Model = Model
                ModelButton.Text = Model
                Handle:Close()
            end)
        end
    end)

    CloseButton.MouseButton1Click:Connect(function()
        WM.ToggleAI(W, false)
    end)

    W.AIPanel = Panel
    return Panel
end

function WM.ToggleAI(W, State)
    local Panel = WM.AI(W)
    if State == nil then
        State = not Panel.Visible
    end
    local Width = Panel.Size.X.Offset
    local Top = W.Header.Size.Y.Offset
    if State then
        Panel.Visible = true
        Panel.Position = UDim2.new(1, Width, 0, Top)
        Library:Tween(Panel, NORMAL, { Position = UDim2.new(1, 0, 0, Top) })
    else
        Library:Tween(Panel, NORMAL, {
            Position = UDim2.new(1, Width, 0, Top)
        }, function()
            Panel.Visible = false
        end)
    end
end

-- ============================================================ public api

function WM.BuildAPI(W)
    local API = {}
    W.API = API
    API.Window = W
    API.Gui = W.Gui
    API.Flags = Library.Flags

    -- ---------------------------------------------------------- navigation

    function W.SelectTab(Tab)
        if type(Tab) == "string" then
            for _, Entry in ipairs(W.Tabs) do
                if Entry.Name == Tab then
                    Tab = Entry
                    break
                end
            end
        end
        if type(Tab) ~= "table" or not Tab.Page then
            return
        end

        if not Tab.Unlocked then
            WM.Password(W, {
                Title = Tab.LockConfig and Tab.LockConfig.Title or ("Locked: " .. Tab.Name),
                Description = Tab.LockConfig and Tab.LockConfig.Description or "Enter the password to unlock this tab",
                Password = Tab.LockConfig and Tab.LockConfig.Password or "",
                Remember = not (Tab.LockConfig and Tab.LockConfig.Remember == false),
                Key = Tab.Name,
                OnUnlock = function()
                    Tab.Unlocked = true
                    Tab.LockIcon.Visible = false
                    W.SelectTab(Tab)
                end
            })
            return
        end

        for _, Entry in ipairs(W.Tabs) do
            local Active = Entry == Tab
            Entry.Page.Visible = Active
            Library:Tween(Entry.Button, FAST, { BackgroundTransparency = Active and 0.9 or 1 })
            Library:Tween(Entry.Label, FAST, { TextTransparency = Active and 0 or 0.4 })
            Library:Tween(Entry.IconLabel, FAST, { ImageTransparency = Active and 0 or 0.35 })
            Library:Tween(Entry.Indicator, NORMAL, {
                Size = UDim2.fromOffset(3, Active and 18 or 0)
            })
        end

        W.Active = Tab
        W.SetPageHead(Tab.Name, Tab.Description, Tab.Icon)
        Library:Pop(Tab.Page, 0.24, 0.99)

        local Index = table.find(W.Recent, Tab.Name)
        if Index then
            table.remove(W.Recent, Index)
        end
        table.insert(W.Recent, 1, Tab.Name)

        local Favorited = table.find(W.State.Favorites or {}, Tab.Name) ~= nil
        Library:SetIcon(W.FavButton:FindFirstChildOfClass("ImageLabel"), Library.Icons.Star,
            Favorited and Library.Theme.Accent or Library.Theme.TextDim)

    end

    function W.Focus(Frame)
        local Page = Frame
        while Page and not Page:IsA("ScrollingFrame") do
            Page = Page.Parent
        end
        if Page then
            local Offset = Frame.AbsolutePosition.Y - Page.AbsolutePosition.Y + Page.CanvasPosition.Y
            Library:Tween(Page, NORMAL, { CanvasPosition = Vector2.new(0, math.max(Offset - 40, 0)) })
        end
        local Line = Frame:FindFirstChildOfClass("UIStroke")
        if Line then
            local Color, Alpha = Line.Color, Line.Transparency
            Line.Color = Library.Theme.Accent
            Line.Transparency = 0.1
            task.delay(1.1, function()
                Library:Tween(Line, NORMAL, { Color = Color, Transparency = Alpha })
            end)
        end
    end

    Library.OnThemeChanged:Connect(function()
        if W.Active then
            W.SelectTab(W.Active)
        end
    end)

    W.FavButton.MouseButton1Click:Connect(function()
        if not W.Active then
            return
        end
        W.State.Favorites = W.State.Favorites or {}
        local Index = table.find(W.State.Favorites, W.Active.Name)
        if Index then
            table.remove(W.State.Favorites, Index)
            W.Active.Button.LayoutOrder = 100
        else
            table.insert(W.State.Favorites, W.Active.Name)
            W.Active.Button.LayoutOrder = -1
        end
        W.SaveState()
        Library:Feedback(1.2)
        W.SelectTab(W.Active)
    end)

    -- sidebar filter: matches tab names and any element inside them
    W.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local Query = W.SearchInput.Text:lower()
        for _, Tab in ipairs(W.Tabs) do
            local Match = Query == "" or Tab.Name:lower():find(Query, 1, true) ~= nil
            if not Match then
                for _, Entry in ipairs(W.Index) do
                    if Entry.Tab == Tab.Name and Entry.Name:lower():find(Query, 1, true) then
                        Match = true
                        break
                    end
                end
            end
            Tab.Button.Visible = Match
        end
        for _, Group in ipairs(W.Groups) do
            local Any = false
            for _, Child in ipairs(Group.Holder:GetChildren()) do
                if Child:IsA("TextButton") and Child.Visible then
                    Any = true
                    break
                end
            end
            Group.Frame.Visible = Any
        end
    end)

    -- page up / page down walk the tab list
    table.insert(W.Connections, UserInputService.InputBegan:Connect(function(Input, Typing)
        if Typing or not W.Open or not W.Active then
            return
        end
        local Step = 0
        if Input.KeyCode == Enum.KeyCode.PageDown then
            Step = 1
        elseif Input.KeyCode == Enum.KeyCode.PageUp then
            Step = -1
        end
        if Step ~= 0 then
            local Index = table.find(W.Tabs, W.Active) or 1
            local Next = W.Tabs[Clamp(Index + Step, 1, #W.Tabs)]
            if Next then
                W.SelectTab(Next)
            end
        end
    end))

    -- ---------------------------------------------------------- structure

    function API:Section(Config)
        return BuildGroup(W, Config)
    end
    API.Group = API.Section
    API.AddGroup = API.Section

    function API:Tab(Config, Icon)
        if type(Config) == "string" then
            Config = { Title = Config, Icon = Icon }
        end
        return BuildTab(W, Config, nil)
    end
    API.T = API.Tab
    API.AddTab = API.Tab

    function API:SelectTab(Name)
        W.SelectTab(Name)
    end

    function API:GetTabs()
        local Names = {}
        for _, Tab in ipairs(W.Tabs) do
            table.insert(Names, Tab.Name)
        end
        return Names
    end

    -- ---------------------------------------------------------- config

    function API:GetConfig()
        local Data = { Flags = {}, Theme = Library.CurrentTheme }
        for Flag, Element in pairs(W.Flags) do
            local Ok, Value = pcall(function()
                return Element:Get()
            end)
            if Ok and Value ~= nil then
                Data.Flags[Flag] = Encode(Value)
            end
        end
        return Data
    end

    function API:SetConfig(Data)
        if type(Data) ~= "table" then
            return false
        end
        local Flags = Data.Flags or Data
        for Flag, Value in pairs(Flags) do
            W.Pending[Flag] = Value
            local Element = W.Flags[Flag]
            if Element then
                pcall(function()
                    Element:Set(Decode(Value))
                end)
            end
        end
        if Data.Theme and Library.Themes[Data.Theme] then
            Library:ApplyTheme(Data.Theme)
        end
        return true
    end

    function API:ListConfigs()
        local Names = {}
        for _, Path in ipairs(FS.List(W.Paths.Configs)) do
            local Name = tostring(Path):match("([^/\\]+)%.json$")
            if Name then
                table.insert(Names, Name)
            end
        end
        if not table.find(Names, W.Profile) then
            table.insert(Names, 1, W.Profile)
        end
        table.sort(Names)
        return Names
    end

    function API:SaveConfig(Name)
        Name = Name or W.Profile
        FS.Folder(W.Paths.Configs)
        local Saved = FS.WriteJSON(W.Paths.Configs .. "/" .. Name .. ".json", API:GetConfig())
        if Saved then
            W.Profile = Name
            W.ProfileLabel.Text = Name
            W.SaveState()
        end
        return Saved
    end

    function API:LoadConfig(Name)
        Name = Name or W.Profile
        local Data = FS.ReadJSON(W.Paths.Configs .. "/" .. Name .. ".json")
        if not Data then
            return false
        end
        W.Profile = Name
        W.ProfileLabel.Text = Name
        API:SetConfig(Data)
        W.SaveState()
        return true
    end

    function API:DeleteConfig(Name)
        if Name == W.Profile then
            W.Profile = "default"
            W.ProfileLabel.Text = W.Profile
        end
        return FS.Delete(W.Paths.Configs .. "/" .. Name .. ".json")
    end

    function API:RenameConfig(Old, New)
        local Data = FS.ReadJSON(W.Paths.Configs .. "/" .. Old .. ".json")
        if not Data then
            return false
        end
        FS.WriteJSON(W.Paths.Configs .. "/" .. New .. ".json", Data)
        FS.Delete(W.Paths.Configs .. "/" .. Old .. ".json")
        if W.Profile == Old then
            W.Profile = New
            W.ProfileLabel.Text = New
        end
        W.SaveState()
        return true
    end

    function API:SetFlag(Flag, Value)
        Library:SetFlag(Flag, Value)
    end

    function API:GetFlag(Flag, Fallback)
        return Library:GetFlag(Flag, Fallback)
    end

    function API:GetElement(Flag)
        return W.Flags[Flag]
    end

    -- ---------------------------------------------------------- panels

    function API:Notify(Config)
        return WM.Notify(W, Config)
    end

    function API:Dialog(Config)
        return WM.Dialog(W, Config)
    end
    API.Popup = API.Dialog

    function API:Prompt(Config)
        return WM.Prompt(W, Config)
    end

    function API:Changelog(Config)
        return WM.Changelog(W, Config)
    end

    function API:Palette()
        return WM.Palette(W)
    end
    API.CommandPalette = API.Palette

    function API:ConfigPanel()
        return WM.ConfigPanel(W)
    end

    function API:ThemePanel()
        return WM.ThemePanel(W)
    end

    function API:KeybindPanel()
        return WM.KeybindPanel(W)
    end

    function API:ToggleAI(State)
        WM.ToggleAI(W, State)
    end

    function API:TogglePlayerCard(State)
        WM.TogglePlayerCard(W, State)
    end

    function API:SetGroq(Key, Prompt, Model)
        Library:SetGroq(Key, Prompt, Model)
    end

    -- ---------------------------------------------------------- window

    function API:Toggle(State)
        W.SetOpen(State)
    end
    API.SetOpen = API.Toggle

    function API:SetTitle(Text)
        W.Config.Title = tostring(Text)
        W.TitleLabel.Text = W.Config.Title
    end

    function API:SetDescription(Text)
        W.Config.Description = tostring(Text)
        W.SubLabel.Text = W.Config.Description
    end

    function API:SetTheme(Name)
        local Ok = Library:ApplyTheme(Name)
        if Ok then
            W.SaveState()
        end
        return Ok
    end

    function API:SetAccent(Color)
        Library:SetAccent(Color)
        W.SaveState()
    end

    function API:SetTransparency(Value)
        Library.Theme.WindowAlpha = Clamp(tonumber(Value) or 0, 0, 1)
        W.Main.BackgroundTransparency = Library.Theme.WindowAlpha
    end

    function API:SetSize(Size)
        W.Config.Size = typeof(Size) == "UDim2" and Size or UDim2.fromOffset(Size.X, Size.Y)
        W.Fit()
    end

    function API:Center()
        W.Root.Position = UDim2.fromScale(0.5, 0.5)
        W.Clamp()
        W.SaveState()
    end

    function API:Destroy()
        W.SaveState()
        if W.Config.AutoSave then
            API:SaveConfig(W.Profile)
        end
        for _, Connection in ipairs(W.Connections) do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        for _, Bind in ipairs(W.Keybinds) do
            Bind.Element.Locked = true
        end
        if W.Blur then
            pcall(function()
                W.Blur:Destroy()
            end)
        end
        Library:Tween(W.Main, FAST, { BackgroundTransparency = 1 }, function()
            W.Gui:Destroy()
        end)
    end

    -- ---------------------------------------------------------- boot

    if W.Config.GroqApiKey then
        Library:SetGroq(W.Config.GroqApiKey, W.Config.GroqPrompt, W.Config.GroqModel)
    end

    if W.Config.AutoLoad then
        local Data = FS.ReadJSON(W.Paths.Configs .. "/" .. W.Profile .. ".json")
        if type(Data) == "table" then
            W.Pending = Data.Flags or Data
        end
    end

    W.SetOpen(true)
    return API
end

return Library
