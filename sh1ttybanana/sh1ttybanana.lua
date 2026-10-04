local Library = {}
Library.Version = "0.3.0-glass"
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

-- ============================================================================
-- Key system providers. A provider is: function(Cfg, KeyCfg) -> function(Key) -> ok, message
-- Built in: "Supabase" and "Http". Add your own:
--   Library.KeyProviders.MyAuth = function(Cfg, KeyCfg) return function(Key) return true end end
-- ============================================================================
local function UrlEncode(Value)
    return (tostring(Value):gsub("[^%w%-_%.~]", function(Char)
        return string.format("%%%02X", string.byte(Char))
    end))
end

local function ReadHwid()
    if Env.gethwid then
        local Ok, Value = pcall(Env.gethwid)
        if Ok and Value then
            return tostring(Value)
        end
    end
    local Ok, Value = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return Ok and tostring(Value) or "unavailable"
end
Library.GetHwid = ReadHwid

local function HttpCall(Options)
    if Env.request then
        local Ok, Response = pcall(Env.request, Options)
        if Ok and type(Response) == "table" then
            return tonumber(Response.StatusCode or Response.Status) or 0, tostring(Response.Body or "")
        end
        return 0, tostring(Response)
    end
    local Ok, Response = pcall(function()
        return HttpService:RequestAsync(Options)
    end)
    if Ok and type(Response) == "table" then
        return tonumber(Response.StatusCode) or 0, tostring(Response.Body or "")
    end
    return 0, tostring(Response)
end

local function JsonDecode(Text)
    local Ok, Result = pcall(function()
        return HttpService:JSONDecode(Text)
    end)
    if Ok then
        return Result
    end
    return nil
end

local function DeepFill(Value, Fill)
    if type(Value) == "string" then
        return (Value:gsub("{key}", function() return Fill.key end):gsub("{hwid}", function() return Fill.hwid end))
    elseif type(Value) == "table" then
        local Copy = {}
        for Index, Item in pairs(Value) do
            Copy[Index] = DeepFill(Item, Fill)
        end
        return Copy
    end
    return Value
end

Library.KeyProviders = {}

-- Supabase (REST). Two modes:
--   Table mode: looks the key up in a table (default table "keys", column "key").
--     Optional columns: active (bool), expires_at (timestamp), and HwidColumn to bind a key to one device.
--   RPC mode: set Rpc = "function_name"; it receives (p_key, p_hwid) and must return true/false.
Library.KeyProviders.Supabase = function(Cfg)
    local Base = tostring(Cfg.Url or ""):gsub("/+$", "")
    local Anon = tostring(Cfg.AnonKey or Cfg.Key or "")
    local Headers = {
        ["apikey"] = Anon,
        ["Authorization"] = "Bearer " .. Anon,
        ["Content-Type"] = "application/json"
    }
    return function(Value)
        if Base == "" or Anon == "" then
            return false, "Supabase is not configured"
        end
        local Hwid = ReadHwid()

        if Cfg.Rpc then
            local Status, Body = HttpCall({
                Url = Base .. "/rest/v1/rpc/" .. tostring(Cfg.Rpc),
                Method = "POST",
                Headers = Headers,
                Body = HttpService:JSONEncode({
                    [Cfg.RpcKeyArg or "p_key"] = Value,
                    [Cfg.RpcHwidArg or "p_hwid"] = Hwid
                })
            })
            if Status < 200 or Status >= 300 then
                return false, "Server error (" .. Status .. ")"
            end
            local Decoded = JsonDecode(Body)
            if type(Decoded) == "table" then
                Decoded = Decoded.valid or Decoded.ok or Decoded[1]
            end
            if Decoded == true then
                return true
            end
            return false, "Invalid key"
        end

        local Table = tostring(Cfg.Table or "keys")
        local KeyColumn = tostring(Cfg.KeyColumn or "key")
        local RowUrl = string.format("%s/rest/v1/%s?%s=eq.%s", Base, Table, KeyColumn, UrlEncode(Value))
        local Status, Body = HttpCall({
            Url = RowUrl .. "&select=*&limit=1",
            Method = "GET",
            Headers = Headers
        })
        if Status ~= 200 then
            return false, "Server error (" .. Status .. ")"
        end
        local Rows = JsonDecode(Body)
        local Row = type(Rows) == "table" and Rows[1] or nil
        if type(Row) ~= "table" then
            return false, "Invalid key"
        end

        local ActiveColumn = Cfg.ActiveColumn
        if ActiveColumn == nil then
            ActiveColumn = "active"
        end
        if ActiveColumn and Row[ActiveColumn] == false then
            return false, "Key disabled"
        end

        local ExpiresColumn = Cfg.ExpiresColumn
        if ExpiresColumn == nil then
            ExpiresColumn = "expires_at"
        end
        if ExpiresColumn and type(Row[ExpiresColumn]) == "string" then
            local Ok, Date = pcall(DateTime.fromIsoDate, Row[ExpiresColumn])
            if Ok and Date and Date.UnixTimestamp < os.time() then
                return false, "Key expired"
            end
        end

        local HwidColumn = Cfg.HwidColumn
        if HwidColumn then
            local Bound = Row[HwidColumn]
            if type(Bound) == "string" and Bound ~= "" then
                if Bound ~= Hwid then
                    return false, "Key is locked to another device"
                end
            elseif Cfg.BindHwid ~= false then
                local PatchHeaders = {}
                for Name, Header in pairs(Headers) do
                    PatchHeaders[Name] = Header
                end
                PatchHeaders["Prefer"] = "return=minimal"
                local PatchStatus = HttpCall({
                    Url = RowUrl,
                    Method = "PATCH",
                    Headers = PatchHeaders,
                    Body = HttpService:JSONEncode({ [HwidColumn] = Hwid })
                })
                if PatchStatus < 200 or PatchStatus >= 300 then
                    return false, "Could not bind key to this device"
                end
            end
        end
        return true
    end
end

-- Generic HTTP endpoint. {key} and {hwid} are replaced in Url, Headers and Body.
--   Http = { Url = "https://api.site.com/verify?key={key}&hwid={hwid}", Method = "GET",
--            SuccessField = "valid"   -- JSON path (dots allowed), or
--            SuccessText = "true"     -- text the body must contain, or leave both nil for any 2xx,
--            MessageField = "message" -- optional failure message path }
Library.KeyProviders.Http = function(Cfg)
    return function(Value)
        if not Cfg.Url then
            return false, "Http provider has no Url"
        end
        local Fill = { key = tostring(Value), hwid = ReadHwid(), nonce = HttpService:GenerateGUID(false) }
        local Url = tostring(Cfg.Url):gsub("{key}", function() return UrlEncode(Fill.key) end)
            :gsub("{hwid}", function() return UrlEncode(Fill.hwid) end)
            :gsub("{nonce}", function() return UrlEncode(Fill.nonce) end)
        local Headers = type(Cfg.Headers) == "table" and DeepFill(Cfg.Headers, Fill) or {}
        local Request = { Url = Url, Method = Cfg.Method or "GET", Headers = Headers }
        if Cfg.Body ~= nil then
            local Body = DeepFill(Cfg.Body, Fill)
            Request.Body = type(Body) == "table" and HttpService:JSONEncode(Body) or tostring(Body)
            if not Headers["Content-Type"] then
                Headers["Content-Type"] = "application/json"
            end
            if Request.Method == "GET" then
                Request.Method = "POST"
            end
        end
        local Status, Body = HttpCall(Request)
        local function Path(Decoded, Dotted)
            local Node = Decoded
            for Part in tostring(Dotted):gmatch("[^%.]+") do
                if type(Node) ~= "table" then
                    return nil
                end
                Node = Node[Part]
            end
            return Node
        end
        if Status < 200 or Status >= 300 then
            local Decoded = JsonDecode(Body)
            local Message = Cfg.MessageField and Decoded and Path(Decoded, Cfg.MessageField)
            return false, type(Message) == "string" and Message or ("Server error (" .. Status .. ")")
        end
        local Success
        if Cfg.SuccessField then
            local Decoded = JsonDecode(Body)
            local Found = Decoded and Path(Decoded, Cfg.SuccessField)
            if Cfg.SuccessValue ~= nil then
                Success = Found == Cfg.SuccessValue
            else
                Success = Found == true or Found == "true" or Found == 1
            end
            if not Success then
                local Message = Cfg.MessageField and Decoded and Path(Decoded, Cfg.MessageField)
                return false, type(Message) == "string" and Message or "Invalid key"
            end
            if Cfg.NonceField and Path(Decoded, Cfg.NonceField) ~= Fill.nonce then
                return false, "Response did not match this request"
            end
            if Cfg.PayloadField then
                return true, nil, Path(Decoded, Cfg.PayloadField)
            end
            return true
        elseif Cfg.SuccessText then
            Success = Body:find(tostring(Cfg.SuccessText), 1, true) ~= nil
        else
            Success = true
        end
        if Success then
            return true
        end
        return false, "Invalid key"
    end
end

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

Library.Themes = {
    Dark = {
        Main = Color3.fromRGB(8, 8, 9),
        Sidebar = Color3.fromRGB(255, 255, 255),
        Card = Color3.fromRGB(255, 255, 255),
        Row = Color3.fromRGB(255, 255, 255),
        Inset = Color3.fromRGB(0, 0, 0),
        Elevated = Color3.fromRGB(14, 14, 15),
        Ink = Color3.fromRGB(255, 255, 255),
        InkText = Color3.fromRGB(10, 10, 10),
        Text = Color3.fromRGB(245, 245, 245),
        TextDim = Color3.fromRGB(172, 172, 172),
        TabText = Color3.fromRGB(228, 228, 228),
        TextDisabled = Color3.fromRGB(120, 120, 120),
        Neutral = Color3.fromRGB(200, 200, 200),
        Stroke = Color3.fromRGB(236, 236, 236),
        StrokeSoft = Color3.fromRGB(200, 200, 200),
        Sheen = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        Track = Color3.fromRGB(96, 96, 96),
        Success = Color3.fromRGB(232, 232, 232),
        Warn = Color3.fromRGB(190, 190, 190),
        Error = Color3.fromRGB(255, 255, 255),
        Info = Color3.fromRGB(150, 150, 150),
        WindowAlpha = 0,
        SidebarAlpha = 0.955,
        CardAlpha = 0.95,
        RowAlpha = 0.93,
        RowHoverAlpha = 0.88,
        InsetAlpha = 0.35,
        ElevatedAlpha = 0,
        StrokeAlpha = 0.84,
        StrokeSoftAlpha = 0.9,
        SheenAlpha = 0.92,
        ButtonAlpha = 0.88,
        ButtonHoverAlpha = 0.8,
        InkFillAlpha = 0.1,
        InkHoverAlpha = 0.0,
        TrackAlpha = 0.35,
        TabActiveAlpha = 0.84,
        TabHoverAlpha = 0.93,
        Radius = 18,
        Blur = 0,
        Glass = true
    }
}

Library.ThemeOrder = { "Dark" }
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
    local Base = Library.Themes.Dark or Library.Themes[Library.ThemeOrder[1]]
    Library.Themes[Name] = Merge(Base, Tokens)
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


local GravityIcons = {}
local GravityPending = {}

local function ApplyGravityAsset(Object, Key)
    if not Object then
        return false
    end
    Key = tostring(Key or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local Asset = GravityIcons[Key] or GravityIcons[Key:gsub("_", "-")]
    if type(Asset) ~= "string" or Asset == "" then
        return false
    end
    Object.Image = Asset
    Object.ImageRectSize = Vector2.new()
    Object.ImageRectOffset = Vector2.new()
    pcall(function()
        Object.ScaleType = Enum.ScaleType.Fit
    end)
    return true
end

local function FlushGravity()
    for Index = #GravityPending, 1, -1 do
        local Item = GravityPending[Index]
        if Item and Item.Object and ApplyGravityAsset(Item.Object, Item.Key) then
            table.remove(GravityPending, Index)
        elseif not Item or not Item.Object or not Item.Object.Parent then
            table.remove(GravityPending, Index)
        end
    end
end

local function LoadGravityPack()
    local Url = "https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/Icons/gravity.lua"
    local Src
    local Ok, Result = pcall(HttpGet, Url)
    if Ok and type(Result) == "string" and #Result > 40 then
        Src = Result
    elseif Env.request then
        local OkReq, Response = pcall(Env.request, { Url = Url, Method = "GET" })
        if OkReq and type(Response) == "table" and type(Response.Body) == "string" then
            Src = Response.Body
        end
    end
    if type(Src) ~= "string" or #Src < 40 then
        return false
    end
    local OkLoad, Data = pcall(function()
        local Fn = loadstring(Src)
        if type(Fn) ~= "function" then
            error("gravity pack")
        end
        return Fn()
    end)
    if not OkLoad or type(Data) ~= "table" then
        return false
    end
    GravityIcons = Data
    FlushGravity()
    return true
end

task.spawn(function()
    if not LoadGravityPack() then
        task.wait(0.8)
        LoadGravityPack()
    end
end)


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
    Refresh = "refresh-cw",
    Settings = "settings",
    Info = "info",
    Menu = "menu",
    Grip = "grip-vertical",
    Sparkles = "sparkles",
    Eye = "eye",
    EyeOff = "eye-off",
    Scan = "scan"
}

function Library:NormalizeIcon(Name)
    if type(Name) ~= "string" or Name == "" then
        return "lucide:" .. Library.Icons.Tab
    end
    if Name:find("rbxassetid") or Name:find("rbxasset://") or Name:find("http") then
        return Name
    end
    local Lower = Name:lower()
    if Lower:sub(1, 8) == "gravity:" then
        return "gravity:" .. Name:sub(9)
    end
    if Lower:sub(1, 7) == "lucide:" then
        return "lucide:" .. Name:sub(8)
    end
    if Name:find(":") then
        return Name
    end
    return "lucide:" .. Name
end

function Library:SetIcon(Object, Name, Color)
    if not Object then
        return
    end
    local Resolved = Library:NormalizeIcon(Name)
    if Resolved:sub(1, 8) == "gravity:" then
        local Key = Resolved:sub(9):gsub("^%s+", ""):gsub("%s+$", "")
        if ApplyGravityAsset(Object, Key) then
            if Color then
                Object.ImageColor3 = Color
            end
            return Object
        end
        table.insert(GravityPending, { Object = Object, Key = Key, Color = Color })
        if IconPack and IconPack.Icon then
            local Ok, Data = pcall(IconPack.Icon, "lucide:" .. Key)
            if Ok and type(Data) == "table" and Data[1] then
                Object.Image = tostring(Data[1])
                local Rect = Data[2]
                Object.ImageRectSize = type(Rect) == "table" and Rect.ImageRectSize or Vector2.new()
                Object.ImageRectOffset = type(Rect) == "table" and Rect.ImageRectPosition or Vector2.new()
            end
        end
        if Color then
            Object.ImageColor3 = Color
        end
        return Object
    elseif Resolved:find("rbxasset") or Resolved:find("http") then
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


Library.Motion = {
    Enabled = true,
    Reduce = false,
}

function Library:SetMotion(State)
    if type(State) == "table" then
        if State.Enabled ~= nil then Library.Motion.Enabled = State.Enabled and true or false end
        if State.Reduce ~= nil then Library.Motion.Reduce = State.Reduce and true or false end
    elseif type(State) == "boolean" then
        Library.Motion.Enabled = State
    end
end

function Library:Animate(Object, Info, Props, Callback)
    if not Object or Library.Motion.Reduce or not Library.Motion.Enabled then
        if Props then
            for K, V in pairs(Props) do
                pcall(function() Object[K] = V end)
            end
        end
        if Callback then task.defer(Callback) end
        return
    end
    return Library:Tween(Object, Info or FAST, Props, Callback)
end

function Library:Press(Object)
    if not Object or Library.Motion.Reduce then return end
    local Scale = Object:FindFirstChildOfClass("UIScale")
    if not Scale then
        Scale = New("UIScale", { Parent = Object, Scale = 1 })
    end
    Library:Tween(Scale, TweenInfo.new(0.08, Quart, Out), { Scale = 0.96 }, function()
        Library:Tween(Scale, SPRING, { Scale = 1 })
    end)
end

function Library:Shake(Object, Amount)
    if not Object or Library.Motion.Reduce then return end
    Amount = Amount or 6
    local Origin = Object.Position
    task.spawn(function()
        for i = 1, 4 do
            Object.Position = Origin + UDim2.fromOffset((i % 2 == 0 and Amount or -Amount), 0)
            task.wait(0.03)
        end
        Object.Position = Origin
    end)
end

function Library:StaggerIn(Objects, DelayStep)
    if Library.Motion.Reduce or not Library.Motion.Enabled then return end
    DelayStep = DelayStep or 0.04
    for i, Obj in ipairs(Objects) do
        if Obj and Obj.Parent then
            Obj.BackgroundTransparency = 1
            task.delay((i - 1) * DelayStep, function()
                if Obj.Parent then
                    Library:Tween(Obj, NORMAL, { BackgroundTransparency = Library.Theme.ElevatedAlpha or 0.15 })
                end
            end)
        end
    end
end

function Library:Feedback(Pitch)
    if Library.Sound then
        Library:Play(Pitch)
    end
    if Library.Haptics then
        Library:Vibrate(0.2)
    end
end

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

-- glass rim: bright white at the top-left and bottom-right corners, fading through the middle
function Library:GlassEdge(Object, Thickness, Base)
    local Line = New("UIStroke", {
        Parent = Object,
        Thickness = Thickness or 1.1,
        Transparency = Base or 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(Line, "Color", "Stroke")
    -- specular edge: brightest along the top, falling away down the sides
    New("UIGradient", {
        Parent = Line,
        Rotation = 80,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.22, 0.6),
            NumberSequenceKeypoint.new(0.55, 0.95),
            NumberSequenceKeypoint.new(0.85, 0.72),
            NumberSequenceKeypoint.new(1, 0.4)
        })
    })
    return Line
end

-- soft top-lit highlight laid over a surface (skipped automatically when the
-- surface lays out its own children, so it can never push content around)
function Library:Gloss(Object, Alpha)
    local Layer = New("Frame", {
        Parent = Object,
        Name = "Gloss",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = Alpha or 0.93,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Object.ZIndex
    })
    New("UIGradient", {
        Parent = Layer,
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.45, 0.75),
            NumberSequenceKeypoint.new(1, 1)
        })
    })
    -- specular edge: a thin bright line just inside the top, fading out at both ends
    local Spec = New("Frame", {
        Parent = Layer,
        Name = "Specular",
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.62,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0, 1),
        Size = UDim2.new(0.78, 0, 0, 1)
    })
    New("UIGradient", {
        Parent = Spec,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0.2),
            NumberSequenceKeypoint.new(0.8, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
    })
    task.defer(function()
        if not Layer.Parent then
            return
        end
        if Object:FindFirstChildWhichIsA("UIListLayout") or Object:FindFirstChildWhichIsA("UIGridLayout") or Object:FindFirstChildWhichIsA("UIPageLayout") then
            Layer:Destroy()
            return
        end
        local Corner = Object:FindFirstChildOfClass("UICorner")
        if Corner then
            New("UICorner", { Parent = Layer, CornerRadius = Corner.CornerRadius })
        end
    end)
    return Layer
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
        Rotation = (Rotation == nil or Rotation == 90) and 40 or Rotation,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.35, 0.8),
            NumberSequenceKeypoint.new(0.65, 1),
            NumberSequenceKeypoint.new(1, 0.7)
        })
    })
    return Layer
end

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
    Library:Themed(Object, "BackgroundColor3", "Ink")
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
    if Library.ReduceMotion then
        if Object and Object:IsA("GuiObject") then
            local Scale = Object:FindFirstChildOfClass("UIScale") or New("UIScale", { Parent = Object })
            Scale.Scale = 1
        end
        return
    end
    local Scale = New("UIScale", { Parent = Object, Scale = From or 0.9 })
    Library:Tween(Scale, TweenInfo.new(Duration or 0.34, Back, Out), { Scale = 1 }, function()
        Scale:Destroy()
    end)
end

function Library:Rise(Objects)
    if Library.Motion.Reduce or Library.ReduceMotion or not Library.Motion.Enabled then
        return
    end
    for Index, Object in ipairs(Objects) do
        if Object and Object.Parent then
            local Scale = New("UIScale", { Parent = Object, Scale = 0.95 })
            local Info = TweenInfo.new(0.38, Back, Out, 0, false, math.min((Index - 1) * 0.04, 0.28))
            Library:Tween(Scale, Info, { Scale = 1 }, function()
                Scale:Destroy()
            end)
        end
    end
end

function Library:StyleScroll(Scroll)
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageTransparency = 0.55
    Scroll.BorderSizePixel = 0
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.CanvasSize = UDim2.new()
    Library:Themed(Scroll, "ScrollBarImageColor3", "Ink")
    return Scroll
end

local Device = {}

function Device.Viewport()
    local Camera = workspace.CurrentCamera
    return Camera and Camera.ViewportSize or Vector2.new(1280, 720)
end

function Device.IsTouch()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Device.IsMobile()
    return Device.IsTouch() or Device.Viewport().X < 640
end

function Device.Class()
    local Size = Device.Viewport()
    if Device.IsTouch() then
        return math.min(Size.X, Size.Y) >= 600 and "Tablet" or "Mobile"
    end
    if Size.X < 640 then
        return "Mobile"
    end
    if Size.X < 1024 then
        return "Tablet"
    end
    return "Desktop"
end

function Device.IsKeyInput(Input)
    local Type = Input.UserInputType
    if Type == Enum.UserInputType.Keyboard then
        return UserInputService.KeyboardEnabled
    end
    if Type == Enum.UserInputType.MouseButton2 or Type == Enum.UserInputType.MouseButton3 then
        return UserInputService.MouseEnabled
    end
    return false
end

function Device.Zone()
    local Size = Device.Viewport()
    local Pad = 8
    if not Device.IsTouch() then
        return Vector2.new(Pad, Pad), Vector2.new(math.max(Size.X - Pad * 2, 1), math.max(Size.Y - Pad * 2, 1))
    end
    local Top = Pad
    local Ok, Inset = pcall(function()
        return GuiService:GetGuiInset()
    end)
    if Ok and Inset then
        Top = Pad + Clamp(Inset.Y, 0, 64)
    end
    if Size.X >= Size.Y then
        local Side = Clamp(Size.X * 0.2, 120, 240)
        return Vector2.new(Side, Top), Vector2.new(math.max(Size.X - Side * 2, 1), math.max(Size.Y - Top - Pad, 1))
    end
    local Bottom = Clamp(Size.Y * 0.3, 170, 280)
    return Vector2.new(Pad, Top), Vector2.new(math.max(Size.X - Pad * 2, 1), math.max(Size.Y - Top - Bottom, 1))
end

function Device.Band()
    local Size = Device.Viewport()
    local Position, ZoneSize = Device.Zone()
    if not Device.IsTouch() then
        return Position, ZoneSize
    end
    local Height = Size.X >= Size.Y and Size.Y * 0.4 or ZoneSize.Y
    return Vector2.new(8, Position.Y), Vector2.new(math.max(Size.X - 16, 1), math.max(Height, 1))
end

function Device.Scale()
    local Size = Device.Viewport()
    return Clamp(math.min(Size.X / 1280, Size.Y / 720), 0.5, 1.25)
end

Library.Device = Device

function Library.TextSize(Base, MobileBoost)
    Base = Base or 13
    MobileBoost = MobileBoost or 2
    local Scale = Device.Scale()
    local Size = Base * Clamp(Scale, 0.85, 1.15)
    if Device.IsMobile() then
        Size = Size + MobileBoost
    end
    return math.floor(Size + 0.5)
end

local DragLockCount = 0
local DragLockPrevBehavior = nil
local DragLockPrevIcon = nil

function Library:BeginDragLock()
    DragLockCount = DragLockCount + 1
    if DragLockCount ~= 1 or Device.IsTouch() then
        return
    end
    pcall(function()
        DragLockPrevBehavior = UserInputService.MouseBehavior
        DragLockPrevIcon = UserInputService.MouseIconEnabled
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
    pcall(function()
        ContextActionService:BindActionAtPriority("sh1ttybanana_drag_lock", function()
            return Enum.ContextActionResult.Sink
        end, false, 9000,
            Enum.UserInputType.MouseButton2,
            Enum.UserInputType.MouseWheel)
    end)
end

function Library:ReleaseDragLock()
    DragLockCount = 0
    pcall(function()
        ContextActionService:UnbindAction("sh1ttybanana_drag_lock")
    end)
    pcall(function()
        if DragLockPrevBehavior ~= nil then
            UserInputService.MouseBehavior = DragLockPrevBehavior
        end
        if DragLockPrevIcon ~= nil then
            UserInputService.MouseIconEnabled = DragLockPrevIcon
        end
    end)
    DragLockPrevBehavior = nil
    DragLockPrevIcon = nil
end

function Library:EndDragLock()
    DragLockCount = math.max(DragLockCount - 1, 0)
    if DragLockCount == 0 then
        Library:ReleaseDragLock()
    end
end


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
    local Show = State ~= false
    if self.Frame then
        self.Frame:SetAttribute("UserHidden", not Show)
        self.Frame.Visible = Show
    end
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

local function PillButton(Parent, Text, IconName, Width, Filled)
    local Button = New("TextButton", {
        Parent = Parent,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.new(0, Width or 96, 0, 30),
        Text = ""
    })
    Library:Corner(Button, UDim.new(1, 0))
    Library:Themed(Button, "BackgroundColor3", Filled and "Ink" or "Row")
    Library:Themed(Button, "BackgroundTransparency", Filled and "InkFillAlpha" or "ButtonAlpha")

    local Line = New("UIStroke", {
        Parent = Button,
        Thickness = 1,
        Transparency = Filled and 0.3 or 0.45,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(Line, "Color", Filled and "Ink" or "Stroke")
    local IdleLine = Filled and 0.3 or 0.45
    -- same corner-lit rim as the window
    New("UIGradient", {
        Parent = Line,
        Rotation = 45,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.6),
            NumberSequenceKeypoint.new(1, 0.1)
        })
    })
    if Filled then
        New("UIGradient", {
            Parent = Button,
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 196, 196))
        })
    else
        New("UIGradient", {
            Parent = Button,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 0.45)
            })
        })
    end

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
        Icon = IconLabel(Holder, IconName, 15, Filled and "InkText" or "Text")
        Icon.LayoutOrder = 1
    end

    local TextPart = New("TextLabel", {
        Parent = Holder,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 30),
        Font = Library.Font.Bold,
        Text = Text or "",
        TextSize = 12,
        LayoutOrder = 2,
        Visible = (Text or "") ~= ""
    })
    Library:Themed(TextPart, "TextColor3", Filled and "InkText" or "Text")

    Button.MouseEnter:Connect(function()
        Library:Tween(Button, FAST, {
            BackgroundTransparency = Filled and (Library.Theme.InkHoverAlpha or 0) or (Library.Theme.ButtonHoverAlpha or 0.8)
        })
        Library:Tween(Line, FAST, { Transparency = Filled and 0.1 or 0.2 })
    end)
    Button.MouseLeave:Connect(function()
        Library:Tween(Button, FAST, {
            BackgroundTransparency = Filled and (Library.Theme.InkFillAlpha or 0.1) or (Library.Theme.ButtonAlpha or 0.88)
        })
        Library:Tween(Line, FAST, { Transparency = IdleLine })
    end)
    Button.MouseButton1Click:Connect(function()
        Library:Feedback(1.05)
        Library:Press(Button)
    end)

    return Button, TextPart, Icon
end

local function GlyphButton(Parent, IconName, Tip)
    local Button = New("TextButton", {
        Parent = Parent,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(30, 30),
        Text = ""
    })
    Library:Corner(Button, UDim.new(1, 0))
    Library:Themed(Button, "BackgroundColor3", "Row")

    local Icon = IconLabel(Button, IconName, 16, "TextDim")
    Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon.Position = UDim2.fromScale(0.5, 0.5)

    Button.MouseEnter:Connect(function()
        Library:Tween(Button, FAST, { BackgroundTransparency = Library.Theme.ButtonHoverAlpha or 0.8 })
        Library:Tween(Icon, FAST, { ImageColor3 = Library.Theme.Text })
    end)
    Button.MouseLeave:Connect(function()
        Library:Tween(Button, FAST, { BackgroundTransparency = 1 })
        Library:Tween(Icon, FAST, { ImageColor3 = Library.Theme.TextDim })
    end)

    Button:SetAttribute("Tip", Tip or "")
    return Button, Icon
end

local function MakeRow(Section, Kind, Title, Description, MinHeight, RightWidth)
    local Mobile = Section.Window.Mobile
    local Compact = Section.Window.Config and Section.Window.Config.Compact
    local Height = (MinHeight or 36) + (Mobile and (Compact and 4 or 10) or 0) - (Compact and not Mobile and 4 or 0)
    local Reserve = (RightWidth or 60) > 0 and ((RightWidth or 60) + 26) or 14
    local TitleSize = Library.TextSize(13, 2)
    local DescSize = Library.TextSize(11, 2)
    local TitleH = TitleSize + 4

    local Row = New("Frame", {
        Parent = Section.Body,
        Name = Kind,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Height),
        LayoutOrder = Section.Count + 1,
        ClipsDescendants = false
    })
    Section.Count = Section.Count + 1
    Library:Corner(Row, UDim.new(0, 14))
    Library:Themed(Row, "BackgroundColor3", "Row")
    Library:Themed(Row, "BackgroundTransparency", "RowAlpha")
    Library:Gloss(Row, 0.95)
    local Line = Library:Stroke(Row, "StrokeSoft", 1)
    if Library.Theme.Glass then
        Line.Transparency = Library.Theme.StrokeSoftAlpha or 0.85
    end

    New("UIPadding", {
        Parent = Row,
        PaddingTop = UDim.new(0, Compact and 8 or 10),
        PaddingBottom = UDim.new(0, Compact and 8 or 10)
    })

    local Stack = New("Frame", {
        Parent = Row,
        Name = "Text",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.new(1, -(Reserve + 14), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    })

    local StackLayout = New("UIListLayout", {
        Parent = Stack,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, Compact and 2 or 3)
    })

    local function Measure()
        local ContentY = math.max(StackLayout.AbsoluteContentSize.Y, Stack.AbsoluteSize.Y)
        local Pad = Compact and 16 or 20
        local Wanted = math.max(Height, math.ceil(ContentY + Pad))
        if Row.Size.Y.Offset ~= Wanted then
            Row.Size = UDim2.new(1, 0, 0, Wanted)
        end
    end
    Stack:GetPropertyChangedSignal("AbsoluteSize"):Connect(Measure)
    StackLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Measure)
    task.defer(Measure)
    task.delay(0.05, Measure)
    task.delay(0.2, Measure)
    task.delay(0.6, Measure)

    local TitleLabel = New("TextLabel", {
        Parent = Stack,
        BackgroundTransparency = 1,
        Font = Library.Font.Bold,
        Text = Title or Kind,
        TextSize = TitleSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.new(1, 0, 0, TitleH),
        LayoutOrder = 1,
        RichText = true
    })
    Library:Themed(TitleLabel, "TextColor3", "Text")

    local DescLabel = New("TextLabel", {
        Parent = Stack,
        BackgroundTransparency = 1,
        Font = Library.Font.Regular,
        Text = Description or "",
        TextSize = DescSize,
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

    Row:SetAttribute("Measure", true)
    return Row, TitleLabel, DescLabel, Line, Stack, Measure
end

local function Register(Section, Element)
    local Entry = {
        Kind = "Element",
        Name = Element.Title or "",
        Description = Element.Description or "",
        Tab = Section.Tab.Name,
        Section = Section.Title,
        Element = Element,
        Jump = function()
            Section.Window.SelectTab(Section.Tab.Owner or Section.Tab)
            if Section.Tab.Subtab then
                Section.Tab.Subtab.Select(false)
            end
            task.defer(function()
                Section.Window.Focus(Element.Frame)
            end)
        end
    }
    table.insert(Section.Window.Index, Entry)
    Element.Registry = Entry
    return Entry
end

Library.Auth = {}

function Library.Auth.Has(Lock)
    if type(Lock) ~= "table" then
        return false
    end
    return Lock.Verify ~= nil or Lock.Auth ~= nil or Lock.Provider ~= nil or Lock.Http ~= nil
        or Lock.Supabase ~= nil or Lock.Keys ~= nil or Lock.Password ~= nil
end

function Library.Auth.Resolve(Lock)
    Lock = type(Lock) == "table" and Lock or {}
    local Checks = {}
    if type(Lock.Verify) == "function" then
        table.insert(Checks, Lock.Verify)
    end
    if type(Lock.Auth) == "function" then
        table.insert(Checks, Lock.Auth)
    end
    local Name = Lock.Provider
    if not Name then
        if Lock.Supabase then
            Name = "Supabase"
        elseif Lock.Http then
            Name = "Http"
        end
    end
    if Name then
        local Maker = Library.KeyProviders[Name]
        if Maker then
            local Ok, Check = pcall(Maker, Lock[Name] or Lock.ProviderConfig or {}, Lock)
            if Ok and type(Check) == "function" then
                table.insert(Checks, Check)
            else
                warn("[sh1ttybanana] lock provider failed to start: " .. tostring(Check))
            end
        else
            warn("[sh1ttybanana] unknown lock provider: " .. tostring(Name))
        end
    end
    local Keys = Lock.Keys
    if type(Keys) ~= "table" and Lock.Password ~= nil then
        Keys = { Lock.Password }
    end
    if type(Keys) == "table" then
        table.insert(Checks, function(Value)
            for _, Key in ipairs(Keys) do
                if tostring(Key) == Value then
                    return true
                end
            end
            return false, "Wrong key"
        end)
    end

    local RequireAll = Lock.Require == "all"
    return function(Value, Context)
        if #Checks == 0 then
            return false, "No authentication is configured for this lock"
        end
        local Message, Payload
        for _, Check in ipairs(Checks) do
            local Ok, Result, Reason, Extra = pcall(Check, Value, Context)
            local Passed = Ok and Result == true
            if Passed then
                Payload = Payload or Extra
                if not RequireAll then
                    return true, nil, Payload
                end
            else
                Message = Message or (Ok and Reason) or "Authentication error"
                if RequireAll then
                    return false, Message
                end
            end
        end
        if RequireAll then
            return true, nil, Payload
        end
        return false, Message or "Access denied"
    end
end

function Library.Auth.IsRemembered(W, Id)
    local Slot = "unlock_" .. tostring(Id)
    local Entry = W.State[Slot]
    if Entry == nil then
        return false
    end
    if type(Entry) == "table" and Entry.pw == nil then
        local Until = tonumber(Entry["until"] or Entry.Until)
        if Until and Until > os.time() then
            return true
        end
    end
    W.State[Slot] = nil
    return false
end

function Library.Auth.Remember(W, Id, Minutes)
    W.State["unlock_" .. tostring(Id)] = { ["until"] = os.time() + math.floor(Minutes * 60) }
    W.SaveState()
end

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
    Library:Corner(Chip, UDim.new(1, 0))
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

    if Library.Auth.Has(Config) then
        local Verify = Library.Auth.Resolve(Config)
        local LockId = Config.Id or Config.Key or ("element_" .. tostring(Element.Title))
        Text.Text = Config.Title or "Locked"
        Blocker.MouseEnter:Connect(function()
            Library:Tween(ChipLine, FAST, { Color = Library.Theme.Ink, Transparency = 0.35 })
            Library:Tween(Icon, FAST, { ImageColor3 = Library.Theme.Ink })
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
                Description = Config.Description,
                Placeholder = Config.Placeholder,
                Confirm = Config.Confirm,
                Verify = Verify,
                Remember = Config.Remember ~= false,
                RememberMinutes = Config.RememberMinutes,
                Key = LockId,
                OnUnlock = function(Payload)
                    Element:SetLocked(false)
                    if Config.OnUnlock then
                        task.spawn(Config.OnUnlock, Payload)
                    end
                end
            })
        end)
    end
    return Blocker
end

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
        local LockConfig = type(Config.Lock) == "table" and Config.Lock or nil
        LockOverlay(Element, LockConfig)
        local LockId = LockConfig and Library.Auth.Has(LockConfig)
            and (LockConfig.Id or LockConfig.Key or ("element_" .. tostring(Element.Title)))
        if not (LockId and LockConfig.Remember ~= false and Library.Auth.IsRemembered(Window, LockId)) then
            Element:SetLocked(true, LockConfig and LockConfig.Title or nil)
        end
    else
        LockOverlay(Element, nil)
    end

    if Config.Visible == false then
        Element:SetVisible(false)
    end

    table.insert(Section.Elements, Element)
    return Element
end

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
        Theme = "Dark",
        Size = UDim2.fromOffset(700, 500),
        AutoScale = true,
        AutoPosition = "Center",
        Transparency = nil,
        Blur = false,
        Version = "V0.1 Alpha",
        Tag = "beta",
        FolderName = "sh1ttybanana",
        ConfigName = "default",
        AutoSave = true,
        AutoLoad = true,
        ToggleKey = Enum.KeyCode.RightShift,
        CloseKey = nil,
        TopbarStyle = "Classic",
        TopbarButtons = nil,
        Background = nil,
        ShowPlayerCard = true,
        ShowAI = true,
        DockPanels = true,
        ShowTheme = true,
        ShowConfig = true,
        ShowKeybinds = true,
        ShowChangelog = false,
        ShowWatermark = true,
        WatermarkText = "NexxWare SB V0.1",
        Compact = false,
        Sound = false,
        Particles = true,
        SafeArea = false,
        StrictMode = false,
        ShowPerf = false,
        ReduceMotion = false,
        NotifyDND = false,
        NotifyMax = 4,
        OnSave = nil,
        OnLoad = nil,
        AdvancedTheme = nil,
        DebugLayout = false,
        GroqApiKey = nil,
        GroqPrompt = nil,
        GroqModel = nil,
        KeySystem = nil,
        PanicKey = Enum.KeyCode.End,
        PanicFlags = nil,
        Roles = nil
    }, UserConfig or {})
    if W.Config.ReduceMotion then
        Library.Motion.Reduce = true
    end

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

    if Library.Themes[W.Config.Theme] then
        Library.CurrentTheme = W.Config.Theme
        Library.Theme = Library.Themes[W.Config.Theme]
    end
    if type(W.Config.Transparency) == "number" then
        Library.Theme.WindowAlpha = W.Config.Transparency
    end

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
    if type(W.State.Sound) == "boolean" then
        Library.Sound = W.State.Sound
    end
    if type(W.State.Particles) == "boolean" then
        Library.Particles = W.State.Particles
    end
    if W.Config.ReduceMotion then
        Library.ReduceMotion = true
    end
    if type(W.Config.AdvancedTheme) == "table" then
        for K, V in pairs(W.Config.AdvancedTheme) do
            Library.Theme[K] = V
            if Library.Themes[Library.CurrentTheme] then
                Library.Themes[Library.CurrentTheme][K] = V
            end
        end
    end

    function W.SaveState()
        W.State.Profile = W.Profile
        W.State.Theme = Library.CurrentTheme
        W.State.Sound = Library.Sound
        W.State.Particles = Library.Particles
        if W.Root then
            W.State.Position = { W.Root.Position.X.Offset, W.Root.Position.Y.Offset }
        end
        if W.FloatButton then
            W.State.FloatPosition = {
                W.FloatButton.Position.X.Scale,
                W.FloatButton.Position.X.Offset,
                W.FloatButton.Position.Y.Scale,
                W.FloatButton.Position.Y.Offset
            }
        end
        FS.WriteJSON(W.Paths.State, W.State)
    end

    W.Gui = New("ScreenGui", {
        Name = RandomName(),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999
    })
    ParentGui(W.Gui)

    W.KeySystem = { Config = nil, IsValid = function() return true end }

    if type(W.Config.KeySystem) == "table" and W.Config.KeySystem.Enabled ~= false then
        local KeyCfg = Merge({
            Title = "Key Required",
            Note = "",
            Keys = {},
            GetKeyLink = nil,
            SaveKey = true,
            Callback = nil,
            Custom = nil,
            Provider = nil,
            Supabase = nil,
            Http = nil,
            OnSuccess = nil,
            UI = "default"
        }, W.Config.KeySystem)

        -- pick the remote provider (if any): Provider = "Supabase" | "Http" | your own name
        local RemoteCheck
        do
            local Name = KeyCfg.Provider
            if not Name then
                if KeyCfg.Supabase then
                    Name = "Supabase"
                elseif KeyCfg.Http then
                    Name = "Http"
                end
            end
            if Name then
                local Maker = Library.KeyProviders[Name]
                if Maker then
                    local Ok, Result = pcall(Maker, KeyCfg[Name] or KeyCfg.ProviderConfig or {}, KeyCfg)
                    if Ok and type(Result) == "function" then
                        RemoteCheck = Result
                    else
                        warn("[sh1ttybanana] KeySystem provider failed to start:", tostring(Result))
                    end
                else
                    warn("[sh1ttybanana] Unknown KeySystem provider: " .. tostring(Name))
                end
            end
        end

        -- returns ok, message
        local function IsValidKey(Value)
            for _, K in ipairs(KeyCfg.Keys) do
                if tostring(K) == Value then
                    return true
                end
            end
            if type(KeyCfg.Callback) == "function" then
                local Ok, Result, Message = pcall(KeyCfg.Callback, Value)
                if Ok and Result == true then
                    return true
                end
                if not RemoteCheck then
                    return false, Ok and Message or nil
                end
            end
            if RemoteCheck then
                local Ok, Result, Message = pcall(RemoteCheck, Value)
                if Ok and Result == true then
                    return true
                end
                return false, Ok and Message or "Could not reach the key server"
            end
            return false
        end

        W.KeySystem.Config = KeyCfg
        W.KeySystem.IsValid = IsValidKey
        W.Paths.KeyFile = W.Paths.Folder .. "/key.txt"

        local Skip = false
        if KeyCfg.SaveKey ~= false then
            local Saved = FS.Read(W.Paths.KeyFile)
            if Saved and IsValidKey(Trim(Saved)) then
                Skip = true
            end
        end

        if not Skip and type(KeyCfg.Custom) == "function" then
            local Done, Verified = false, false
            local KeyApi = {
                Gui = W.Gui,
                Window = W,
                Config = KeyCfg,
                Theme = Library.Theme,
                Library = Library,
                IsValid = IsValidKey,
                New = New,
                Icons = Library.Icons,
                SaveKey = function(Value)
                    if KeyCfg.SaveKey ~= false and Value then
                        FS.Folder(W.Paths.Folder)
                        FS.Write(W.Paths.KeyFile, tostring(Value))
                    end
                end,
                Resolve = function(Ok, Value)
                    if Ok then
                        if Value and KeyCfg.SaveKey ~= false then
                            FS.Folder(W.Paths.Folder)
                            FS.Write(W.Paths.KeyFile, tostring(Value))
                        end
                        Verified = true
                    end
                    Done = true
                end,
            }
            local Ok, Err = pcall(KeyCfg.Custom, KeyApi)
            if not Ok then
                warn("[sh1ttybanana] KeySystem.Custom error:", Err)
                Done = true
                Verified = false
            end
            while not Done and W.Gui.Parent do
                task.wait()
            end
            if not Verified then
                pcall(function()
                    W.Gui:Destroy()
                end)
                return setmetatable({}, { __index = function() return function() end end })
            end
            Skip = true
        end

        if not Skip then
            local Gate = New("Frame", {
                Parent = W.Gui,
                Name = "KeyGate",
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.45,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 1000
            })

            local Shell = New("Frame", {
                Parent = Gate,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(W.Mobile and 320 or 840, W.Mobile and 440 or 360),
                ZIndex = 1001
            })
            New("UIListLayout", {
                Parent = Shell,
                FillDirection = W.Mobile and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            local DraggingGate, DragStart, ShellStart = false, nil, nil
            local function BeginShellDrag(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                DraggingGate = true
                DragStart = Input.Position
                ShellStart = Shell.Position
                Library:BeginDragLock()
            end
            local function EndShellDrag()
                if DraggingGate then
                    DraggingGate = false
                    Library:EndDragLock()
                end
            end
            table.insert(W.Connections, UserInputService.InputChanged:Connect(function(Input)
                if not DraggingGate then
                    return
                end
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    local Delta = Input.Position - DragStart
                    Shell.Position = UDim2.new(
                        ShellStart.X.Scale, ShellStart.X.Offset + Delta.X,
                        ShellStart.Y.Scale, ShellStart.Y.Offset + Delta.Y
                    )
                end
            end))
            table.insert(W.Connections, UserInputService.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    EndShellDrag()
                end
            end))

            local function Panel(Width, Order)
                local P = New("Frame", {
                    Parent = Shell,
                    BorderSizePixel = 0,
                    Size = UDim2.new(W.Mobile and 1 or 0, W.Mobile and 0 or Width, W.Mobile and 0 or 1, W.Mobile and 160 or 0),
                    LayoutOrder = Order,
                    ZIndex = 1002
                })
                Library:Corner(P, Library.Theme.Radius or 14)
                Library:Themed(P, "BackgroundColor3", "Elevated")
                Library:Themed(P, "BackgroundTransparency", "ElevatedAlpha")
                local Stroke = Library:Stroke(P, "Stroke", 1.2)
                Stroke.Transparency = Library.Theme.StrokeAlpha or 0.55
                local Sh = Library:Sheen(P, 90)
                if Sh then
                    Sh.ZIndex = 1002
                end
                Library:Shadow(P, 40, 0.55)
                New("UIPadding", {
                    Parent = P,
                    PaddingTop = UDim.new(0, 14),
                    PaddingBottom = UDim.new(0, 14),
                    PaddingLeft = UDim.new(0, 14),
                    PaddingRight = UDim.new(0, 14)
                })
                P.InputBegan:Connect(BeginShellDrag)
                return P
            end

            local CloseKey = New("TextButton", {
                Parent = Shell,
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -4, 0, -36),
                Size = UDim2.fromOffset(32, 32),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 1010,
                LayoutOrder = 0
            })
            if W.Mobile then
                CloseKey.Position = UDim2.new(1, -4, 0, -40)
            end
            Library:Corner(CloseKey, UDim.new(0, 12))
            Library:Themed(CloseKey, "BackgroundColor3", "Elevated")
            Library:Stroke(CloseKey, "StrokeSoft", 1)
            local CloseIc = IconLabel(CloseKey, Library.Icons.Close, 14, "Text")
            CloseIc.AnchorPoint = Vector2.new(0.5, 0.5)
            CloseIc.Position = UDim2.fromScale(0.5, 0.5)
            CloseIc.ZIndex = 1011
            CloseKey.MouseButton1Click:Connect(function()
                pcall(function()
                    Gate:Destroy()
                    W.Gui:Destroy()
                end)
            end)

            local Left = Panel(220, 1)
            local Mid = Panel(300, 2)
            local Right = Panel(260, 3)
            task.defer(function()
                Library:Pop(Left, 0.34, 0.9)
                task.wait(0.05)
                Library:Pop(Mid, 0.34, 0.9)
                task.wait(0.05)
                if Right.Visible then
                    Library:Pop(Right, 0.34, 0.9)
                end
            end)
            task.defer(function()
                Library:StaggerIn({ Left, Mid, Right }, 0.05)
            end)
            if W.Mobile then
                Left.Size = UDim2.new(1, 0, 0, 0)
                Left.AutomaticSize = Enum.AutomaticSize.Y
                Mid.Size = UDim2.new(1, 0, 0, 0)
                Mid.AutomaticSize = Enum.AutomaticSize.Y
                Right.Visible = KeyCfg.Changelog ~= nil
                if Right.Visible then
                    Right.Size = UDim2.new(1, 0, 0, 180)
                end
            end

            local Avatar = New("ImageLabel", {
                Parent = Left,
                BackgroundTransparency = 0.85,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(64, 64),
                Position = UDim2.new(0.5, -32, 0, 4),
                ZIndex = 1003
            })
            Library:Corner(Avatar, UDim.new(0, 16))
            Library:Themed(Avatar, "BackgroundColor3", "Ink")
            task.spawn(function()
                local Ok, Url = pcall(function()
                    return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                end)
                if Ok then
                    Avatar.Image = Url
                end
            end)

            local Welcome = New("TextLabel", {
                Parent = Left,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 76),
                Size = UDim2.new(1, 0, 0, 18),
                Font = Library.Font.Bold,
                Text = "Welcome, " .. (LocalPlayer.DisplayName or LocalPlayer.Name),
                TextSize = 12,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 1003
            })
            Library:Themed(Welcome, "TextColor3", "Text")

            local function Meta(Y, Label, Value)
                local L = New("TextLabel", {
                    Parent = Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, Y),
                    Size = UDim2.new(1, 0, 0, 14),
                    Font = Library.Font.Regular,
                    Text = Label,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 1003
                })
                Library:Themed(L, "TextColor3", "TextDim")
                local V = New("TextLabel", {
                    Parent = Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, Y + 14),
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Library.Font.Bold,
                    Text = Value,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 1003
                })
                Library:Themed(V, "TextColor3", "Ink")
                return V
            end

            local ExecName = "unknown"
            if Env.identifyexecutor then
                local Ok, N = pcall(Env.identifyexecutor)
                if Ok and N then
                    ExecName = tostring(N)
                end
            end
            Meta(100, "Executor", ExecName)
            Meta(140, "Device", Device.IsMobile() and "Mobile" or "Desktop")
            local Hwid = "unavailable"
            if Env.gethwid then
                local Ok, V = pcall(Env.gethwid)
                if Ok and V then
                    Hwid = tostring(V)
                end
            end
            local HwidLabel = Meta(180, "HWID", Hwid:sub(1, 14) .. (#Hwid > 14 and "..." or ""))
            local CopyH = New("TextButton", {
                Parent = Left,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -22, 0, 194),
                Size = UDim2.fromOffset(20, 20),
                Text = "",
                ZIndex = 1004
            })
            local CopyIcon = IconLabel(CopyH, Library.Icons.Copy, 14, "TextDim")
            CopyIcon.Size = UDim2.fromOffset(14, 14)
            CopyH.MouseButton1Click:Connect(function()
                if Env.setclipboard then
                    pcall(Env.setclipboard, Hwid)
                end
            end)

            local ClockL = New("TextLabel", {
                Parent = Left,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, -2),
                Size = UDim2.new(1, 0, 0, 32),
                Font = Library.Font.Medium,
                Text = os.date("%I:%M:%S %p\n%b %d, %Y"),
                TextSize = 11,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 1003
            })
            Library:Themed(ClockL, "TextColor3", "TextDim")
            task.spawn(function()
                while Gate.Parent do
                    ClockL.Text = os.date("%I:%M:%S %p\n%b %d, %Y")
                    task.wait(1)
                end
            end)

            local MidTitle = New("TextLabel", {
                Parent = Mid,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                Font = Library.Font.Bold,
                Text = KeyCfg.Title or W.Config.Title or "Access",
                TextSize = 18,
                ZIndex = 1003
            })
            Library:Themed(MidTitle, "TextColor3", "Text")

            local Banner = New("Frame", {
                Parent = Mid,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 36),
                Size = UDim2.new(1, 0, 0, 36),
                ZIndex = 1003
            })
            Library:Corner(Banner, UDim.new(0, 14))
            Library:Themed(Banner, "BackgroundColor3", "Inset")
            Library:Themed(Banner, "BackgroundTransparency", "InsetAlpha")
            Library:Stroke(Banner, "StrokeSoft", 1)
            local BanIcon = IconLabel(Banner, Library.Icons.User, 16, "Ink")
            BanIcon.Position = UDim2.new(0, 12, 0.5, -8)
            BanIcon.ZIndex = 1004
            local BanText = New("TextLabel", {
                Parent = Banner,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 36, 0, 0),
                Size = UDim2.new(1, -44, 1, 0),
                Font = Library.Font.Medium,
                Text = KeyCfg.Note ~= "" and KeyCfg.Note or "Verify Key to enjoy",
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 1004
            })
            Library:Themed(BanText, "TextColor3", "Ink")

            local Field = New("Frame", {
                Parent = Mid,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 84),
                Size = UDim2.new(1, 0, 0, 40),
                ZIndex = 1003
            })
            Library:Corner(Field, UDim.new(0, 14))
            Library:Themed(Field, "BackgroundColor3", "Inset")
            Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
            Library:Gloss(Field, 0.96)
            local FieldLine = Library:Stroke(Field, "StrokeSoft", 1)

            local Box = New("TextBox", {
                Parent = Field,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -28, 1, 0),
                Font = Library.Font.Regular,
                PlaceholderText = "Enter your key...",
                Text = "",
                TextSize = 13,
                ClearTextOnFocus = false,
                ZIndex = 1004
            })
            Library:Themed(Box, "TextColor3", "Text")
            Library:Themed(Box, "PlaceholderColor3", "TextDisabled")

            local GateError = New("TextLabel", {
                Parent = Mid,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 128),
                Size = UDim2.new(1, 0, 0, 14),
                Font = Library.Font.Regular,
                Text = "",
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 1003
            })
            Library:Themed(GateError, "TextColor3", "Error")

            if KeyCfg.GetKeyLink then
                local GetKeyBtn = New("TextButton", {
                    Parent = Mid,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 150),
                    Size = UDim2.new(1, 0, 0, 36),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 1003
                })
                Library:Corner(GetKeyBtn, UDim.new(0, 14))
                Library:Themed(GetKeyBtn, "BackgroundColor3", "Row")
                Library:Themed(GetKeyBtn, "BackgroundTransparency", "RowAlpha")
                Library:Stroke(GetKeyBtn, "StrokeSoft", 1)
                local Gk = New("TextLabel", {
                    Parent = GetKeyBtn,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Font = Library.Font.Medium,
                    Text = "  Get Key",
                    TextSize = 13,
                    ZIndex = 1004
                })
                Library:Themed(Gk, "TextColor3", "Text")
                GetKeyBtn.MouseButton1Click:Connect(function()
                    if Env.setclipboard then
                        pcall(Env.setclipboard, KeyCfg.GetKeyLink)
                    end
                    pcall(function()
                        if GuiService.OpenBrowserWindow then
                            GuiService:OpenBrowserWindow(KeyCfg.GetKeyLink)
                        end
                    end)
                    GateError.Text = "Link copied"
                    Library:Themed(GateError, "TextColor3", "TextDim")
                end)
            end

            local VerifyBtn = New("TextButton", {
                Parent = Mid,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, KeyCfg.GetKeyLink and 196 or 150),
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 1003
            })
            Library:Corner(VerifyBtn, UDim.new(0, 14))
            Library:Themed(VerifyBtn, "BackgroundColor3", "Ink")
            local Vtx = New("TextLabel", {
                Parent = VerifyBtn,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Font = Library.Font.Bold,
                Text = "Verify Key",
                TextSize = 14,
                ZIndex = 1004
            })
            Library:Themed(Vtx, "TextColor3", "InkText")

            local Verified = false
            local Busy = false
            local function TrySubmit()
                if Busy then
                    return
                end
                local Value = Trim(Box.Text)
                if Value == "" then
                    GateError.Text = "Enter a key"
                    return
                end
                Busy = true
                GateError.Text = "Checking..."
                Library:Themed(GateError, "TextColor3", "TextDim")
                local Valid, Reason = IsValidKey(Value)
                Busy = false
                if Valid then
                    if KeyCfg.SaveKey ~= false then
                        FS.Folder(W.Paths.Folder)
                        FS.Write(W.Paths.KeyFile, Value)
                    end
                    if type(KeyCfg.OnSuccess) == "function" then
                        task.spawn(KeyCfg.OnSuccess, Value)
                    end
                    Verified = true
                else
                    GateError.Text = Reason or "Invalid key"
                    Library:Themed(GateError, "TextColor3", "Error")
                    Library:Shake(Mid, 5)
                    Library:Animate(FieldLine, FAST, { Color = Library.Theme.Error })
                    task.delay(0.35, function()
                        pcall(function()
                            Library:Animate(FieldLine, FAST, { Color = Library.Theme.StrokeSoft })
                        end)
                    end)
                end
            end
            VerifyBtn.MouseButton1Click:Connect(TrySubmit)
            Box.FocusLost:Connect(function(Enter)
                if Enter then
                    TrySubmit()
                end
            end)
            task.defer(function()
                Box:CaptureFocus()
            end)

            local LogEntries = KeyCfg.Changelog or {
                { Version = "v" .. Library.Version, Date = os.date("%b %d, %Y"), Notes = { "Key system UI", "New components", "Panic + roles" } }
            }
            local LogTitle = New("TextLabel", {
                Parent = Right,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Font = Library.Font.Bold,
                Text = "Changelog",
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 1003
            })
            Library:Themed(LogTitle, "TextColor3", "Text")
            local LogScroll = New("ScrollingFrame", {
                Parent = Right,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 28),
                Size = UDim2.new(1, 0, 1, -28),
                ZIndex = 1003
            })
            Library:StyleScroll(LogScroll)
            New("UIListLayout", {
                Parent = LogScroll,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10)
            })
            for Index, Entry in ipairs(LogEntries) do
                local Block = New("Frame", {
                    Parent = LogScroll,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = Index,
                    ZIndex = 1004
                })
                local Head = New("TextLabel", {
                    Parent = Block,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Library.Font.Bold,
                    Text = tostring(Entry.Version or "Update") .. (Entry.Date and ("  ·  " .. Entry.Date) or ""),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 1005
                })
                Library:Themed(Head, "TextColor3", "Ink")
                for Ni, Note in ipairs(Entry.Notes or {}) do
                    local N = New("TextLabel", {
                        Parent = Block,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 16 + (Ni - 1) * 14),
                        Size = UDim2.new(1, 0, 0, 14),
                        Font = Library.Font.Regular,
                        Text = "·  " .. tostring(Note),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1005
                    })
                    Library:Themed(N, "TextColor3", "TextDim")
                end
            end

            while not Verified and W.Gui.Parent do
                task.wait()
            end

            if Gate.Parent then
                Library:Tween(Gate, FAST, { BackgroundTransparency = 1 })
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
        Size = W.Config.Size,
        ZIndex = 10
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
    Library:Corner(W.Main, UDim.new(0, 20))
    Library:Themed(W.Main, "BackgroundColor3", "Main")
    Library:Themed(W.Main, "BackgroundTransparency", "WindowAlpha")

    -- glass rim: bright on the top-left edge, fading across the window
    Library:GlassEdge(W.Main, 1.4, 0.15)
    Library:Gradient(W.Main, {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(190, 190, 190)
    }, 90)
    Library:Shadow(W.Root, 80, 0.62)

    -- soft ambient colour blobs behind the content (fluid look). Sized by window
    -- height so they stay inside the rounded corners, and never take input.
    W.Background = New("ImageLabel", {
        Parent = W.Main,
        Name = "Background",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ScaleType = Enum.ScaleType.Crop,
        ImageTransparency = 1,
        Visible = false,
        ZIndex = 1
    })
    Library:Corner(W.Background, UDim.new(0, 20))
    W.Scrim = New("Frame", {
        Parent = W.Main,
        Name = "Scrim",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 1
    })
    Library:Corner(W.Scrim, UDim.new(0, 20))

    local function ResolveAsset(Image)
        Image = tostring(Image)
        if Image:match("^%\d+$") then
            return "rbxassetid://" .. Image
        end
        if Image:find("^rbxassetid://") or Image:find("^rbxasset://") or Image:find("^rbxthumb://") then
            return Image
        end
        local Getter
        pcall(function()
            Getter = getcustomasset or getsynasset
        end)
        if not Getter then
            return nil
        end
        local Path = Image
        if Image:find("^https?://") then
            local Ok, Body = pcall(HttpGet, Image)
            if not Ok or type(Body) ~= "string" or #Body < 16 then
                return nil
            end
            Path = W.Paths.Folder .. "/background.bin"
            if not FS.Write(Path, Body) then
                return nil
            end
        end
        local Ok, Asset = pcall(Getter, Path)
        return Ok and Asset or nil
    end

    function W.SetBackground(Spec)
        if type(Spec) == "string" or type(Spec) == "number" then
            Spec = { Image = Spec }
        end
        if type(Spec) ~= "table" or Spec.Image == nil or tostring(Spec.Image) == "" then
            W.State.Background = nil
            W.Scrim.Visible = false
            Library:Animate(W.Background, NORMAL, { ImageTransparency = 1 }, function()
                if not W.State.Background then
                    W.Background.Visible = false
                    W.Background.Image = ""
                end
            end)
            return true
        end
        local Saved = {
            Image = tostring(Spec.Image),
            Transparency = Clamp(tonumber(Spec.Transparency) or 0.55, 0, 1),
            Dim = Clamp(tonumber(Spec.Dim) or 0.45, 0, 0.9)
        }
        W.State.Background = Saved
        task.spawn(function()
            local Asset = ResolveAsset(Saved.Image)
            if not Asset or W.State.Background ~= Saved then
                if not Asset then
                    W.State.Background = nil
                end
                return
            end
            W.Background.Image = Asset
            W.Background.Visible = true
            W.Scrim.BackgroundTransparency = 1 - Saved.Dim
            W.Scrim.Visible = true
            Library:Animate(W.Background, SLOW, { ImageTransparency = Saved.Transparency })
        end)
        return true
    end

    W.Ambient = Blank(W.Main, {
        Name = "Ambient",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1
    })
    local function Orb(ScaleX, ScaleY, Height, Key)
        for Layer = 1, 6 do
            local Disc = New("Frame", {
                Parent = W.Ambient,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BorderSizePixel = 0,
                Position = UDim2.fromScale(ScaleX, ScaleY),
                Size = UDim2.fromScale(0, Height * (1 - (Layer - 1) * 0.15)),
                BackgroundTransparency = 0.965,
                ZIndex = 1
            })
            New("UIAspectRatioConstraint", {
                Parent = Disc,
                AspectRatio = 1,
                DominantAxis = Enum.DominantAxis.Height
            })
            Library:Corner(Disc, UDim.new(1, 0))
            Library:Themed(Disc, "BackgroundColor3", Key)
        end
    end
    Orb(0.78, 0.3, 0.52, "Ink")
    Orb(0.3, 0.78, 0.44, "Info")
    Orb(0.14, 0.22, 0.34, "Ink")

    Library:Gloss(W.Main, 0.97)
    W.Sheen = Library:Sheen(W.Main, 90)
    W.Sheen.ZIndex = 2

    local InitialBackground = W.Config.Background or W.State.Background
    if InitialBackground then
        W.SetBackground(InitialBackground)
    end

    task.spawn(function()
        local Step = 0
        local Drift = TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        while W.Gui and W.Gui.Parent do
            Step = Step + 1
            if W.Open ~= false and Library.Particles and not Library.Motion.Reduce then
                Library:Tween(W.Ambient, Drift, {
                    Position = UDim2.fromScale(math.sin(Step * 1.7) * 0.05, math.cos(Step * 1.1) * 0.05)
                })
            end
            task.wait(7)
        end
    end)

    function W.Fit()
        local _, ZoneSize = Device.Zone()
        local Wanted = W.Config.Size
        local Scale = 1
        if W.Config.AutoScale then
            Scale = Clamp(math.min(ZoneSize.X / 420, ZoneSize.Y / 300), 0.6, 1)
        end
        local MaxWidth = ZoneSize.X / Scale
        local MaxHeight = ZoneSize.Y / Scale
        local Width, Height
        if W.Maximized then
            Width, Height = MaxWidth, MaxHeight
        else
            Width = math.min(math.max(Wanted.X.Offset, 1), MaxWidth)
            Height = math.min(math.max(Wanted.Y.Offset, 1), MaxHeight)
        end

        W.Root.Size = UDim2.fromOffset(Width, Height)
        W.Scale.Scale = Scale
        if W.Maximized or Device.IsTouch() then
            W.Recenter()
        end
        W.Clamp(Vector2.new(Width * Scale, Height * Scale))
        W.Relayout()
        if W.ClampFloat then
            W.ClampFloat()
        end
    end

    function W.Recenter()
        local Viewport = Device.Viewport()
        local ZonePosition, ZoneSize = Device.Zone()
        W.Root.Position = UDim2.new(
            0.5, ZonePosition.X + ZoneSize.X / 2 - Viewport.X / 2,
            0.5, ZonePosition.Y + ZoneSize.Y / 2 - Viewport.Y / 2
        )
    end

    function W.Clamp(KnownSize)
        local Viewport = Device.Viewport()
        local ZonePosition, ZoneSize = Device.Zone()
        local Half = (KnownSize or W.Root.AbsoluteSize) / 2
        local Position = W.Root.Position
        local CenterX = Position.X.Scale * Viewport.X + Position.X.Offset
        local CenterY = Position.Y.Scale * Viewport.Y + Position.Y.Offset
        local MinX, MaxX = ZonePosition.X + Half.X, ZonePosition.X + ZoneSize.X - Half.X
        local MinY, MaxY = ZonePosition.Y + Half.Y, ZonePosition.Y + ZoneSize.Y - Half.Y
        if MaxX < MinX then
            CenterX = ZonePosition.X + ZoneSize.X / 2
        else
            CenterX = Clamp(CenterX, MinX, MaxX)
        end
        if MaxY < MinY then
            CenterY = ZonePosition.Y + ZoneSize.Y / 2
        else
            CenterY = Clamp(CenterY, MinY, MaxY)
        end
        W.Root.Position = UDim2.new(0.5, CenterX - Viewport.X / 2, 0.5, CenterY - Viewport.Y / 2)
    end

    local function ApplyStartPosition()
        local Mode = W.Config.AutoPosition
        if typeof(Mode) == "UDim2" then
            W.Root.Position = Mode
        elseif Mode == "Remember" and type(W.State.Position) == "table" then
            W.Root.Position = UDim2.new(0.5, W.State.Position[1], 0.5, W.State.Position[2])
        else
            W.Recenter()
        end
    end

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

    local TopbarMac = tostring(W.Config.TopbarStyle or "Classic"):lower() == "mac"
    local BrandInset = TopbarMac and (W.Mobile and 92 or 84) or 14
    local Brand = Blank(W.Header, {
        Position = UDim2.new(0, BrandInset, 0, 0),
        Size = UDim2.new(1, -(BrandInset + 14), 1, 0),
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
    Library:Corner(W.LogoTile, UDim.new(0, 12))
    Library:Themed(W.LogoTile, "BackgroundColor3", "Ink")
    local LogoStroke = New("UIStroke", { Parent = W.LogoTile, Thickness = 1, Transparency = 0.62 })
    Library:Themed(LogoStroke, "Color", "Ink")

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
        Library:SetIcon(W.LogoImage, W.Config.Icon, Library.Theme.InkText)
    end

    local TitleStack = Blank(Brand, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 46, 0.5, 0),
        Size = UDim2.new(1, W.Mobile and -230 or -376, 0, 36),
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
        Library:Corner(Holder, UDim.new(1, 0))
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

    Badge(W.Config.Version, "Ink", 2)
    Badge(W.Config.Tag, "Success", 3)

    local ToolCount = 0
    W.Controls = Blank(W.Header, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 30),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 6
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
        if W.Mobile and MobileVisible == false then
            return nil
        end
        local Button = GlyphButton(W.Controls, IconName, Tip)
        Button.LayoutOrder = Order
        Button.ZIndex = 6
        Button.Size = UDim2.fromOffset(W.Mobile and 34 or 30, W.Mobile and 34 or 30)
        Button.MouseButton1Click:Connect(function()
            Library:Feedback(1.1)
            Library:Press(Button)
            Handler()
        end)
        ToolCount = ToolCount + 1
        return Button
    end

    W.MenuButton = Control(Library.Icons.Menu, "Tabs", 0, function()
        W.ToggleDrawer()
    end, false)
    if W.MenuButton then
        W.MenuButton.Visible = false
    else
        W.MenuButton = New("Frame", { Visible = false, BackgroundTransparency = 1 })
    end

    if W.Config.ShowTheme then
        Control(Library.Icons.Palette, "Appearance", 2, function()
            WM.ThemePanel(W)
        end, true)
    end
    if W.Config.ShowConfig then
        Control(Library.Icons.Save, "Configs", 3, function()
            WM.ConfigPanel(W)
        end, false)
    end
    if W.Config.ShowKeybinds and not Device.IsTouch() then
        Control(Library.Icons.Key, "Keybinds", 4, function()
            WM.KeybindPanel(W)
        end, false)
    end
    if W.Config.ShowAI then
        Control(Library.Icons.Bot, "AI assistant", 5, function()
            WM.ToggleAI(W)
        end, true)
    end
    if W.Config.ShowPlayerCard then
        Control(Library.Icons.User, "Player", 6, function()
            WM.TogglePlayerCard(W)
        end, true)
    end
    if W.Config.ShowChangelog then
        Control(Library.Icons.Sparkles, "Changelog", 6.5, function()
            WM.Changelog(W, {
                Entries = {
                    { Version = "v2.2.0", Notes = { "Fluid glass redesign", "Player dashboard cards", "AI chat rebuild", "Subtabs and custom locks", "Mac and Classic topbars" } },
                    { Version = "v2.0.0", Notes = { "Rebuilt component API", "Added config profiles" } },
                    { Version = "v1.0.0", Notes = { "Initial release" } },
                },
            })
        end, false)
    end
    if type(W.Config.TopbarButtons) == "table" then
        for Index, Info in ipairs(W.Config.TopbarButtons) do
            if type(Info) == "table" and type(Info.Callback) == "function" then
                Control(Info.Icon or Library.Icons.Sparkles, Info.Title or Info.Tip or "", 7 + Index / 100, Info.Callback, true)
            end
        end
    end

    local function RequestClose()
        W.API:Dialog({
            Title = "Close window?",
            Content = "Hide keeps everything running. Close unloads the UI completely.",
            Type = "Danger",
            Buttons = {
                { Title = "Cancel" },
                { Title = "Hide", Callback = function()
                    W.SetOpen(false)
                end },
                { Title = "Close", Filled = true, Callback = function()
                    W.API:Destroy()
                end },
            },
        })
    end

    local function ToggleMaximize()
        W.Maximized = not W.Maximized
        W.Fit()
        W.SaveState()
    end

    if TopbarMac then
        W.Traffic = Blank(W.Header, {
            Name = "Traffic",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 16, 0.5, 0),
            Size = UDim2.fromOffset(W.Mobile and 74 or 58, 20),
            ZIndex = 6
        })
        New("UIListLayout", {
            Parent = W.Traffic,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, W.Mobile and 12 or 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local Lights = {
            { Color3.fromRGB(255, 95, 86), "x", "Close", RequestClose },
            { Color3.fromRGB(255, 189, 46), "minus", "Hide", function()
                W.SetOpen(false)
            end },
            { Color3.fromRGB(39, 201, 63), "maximize-2", "Expand", ToggleMaximize },
        }
        local Glyphs = {}
        local DotSize = W.Mobile and 20 or 14
        for Index, Light in ipairs(Lights) do
            local Dot = New("TextButton", {
                Parent = W.Traffic,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Text = "",
                Size = UDim2.fromOffset(DotSize, DotSize),
                BackgroundColor3 = Light[1],
                LayoutOrder = Index,
                ZIndex = 7
            })
            Library:Corner(Dot, UDim.new(1, 0))
            New("UIStroke", {
                Parent = Dot,
                Thickness = 1,
                Transparency = 0.75,
                Color = Color3.fromRGB(0, 0, 0),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            local Glyph = New("ImageLabel", {
                Parent = Dot,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(DotSize * 0.62, DotSize * 0.62),
                ImageColor3 = Color3.fromRGB(40, 20, 20),
                ImageTransparency = Device.IsTouch() and 0.35 or 1,
                ZIndex = 8
            })
            Library:SetIcon(Glyph, Light[2])
            Glyphs[Index] = Glyph
            Dot:SetAttribute("Tip", Light[3])
            Dot.MouseEnter:Connect(function()
                for _, Item in ipairs(Glyphs) do
                    Library:Tween(Item, FAST, { ImageTransparency = 0.1 })
                end
            end)
            Dot.MouseLeave:Connect(function()
                if Device.IsTouch() then
                    return
                end
                for _, Item in ipairs(Glyphs) do
                    Library:Tween(Item, FAST, { ImageTransparency = 1 })
                end
            end)
            Dot.MouseButton1Click:Connect(function()
                Library:Feedback(1.05)
                Library:Press(Dot)
                Light[4]()
            end)
        end
    else
        Control(Library.Icons.Close, "Close", 9, RequestClose, true)
    end

    local ControlsReserve = ToolCount * (W.Mobile and 36 or 32) + 8
    TitleStack.Size = UDim2.new(1, -(46 + ControlsReserve + 8), 0, 36)

    W.Body = Blank(W.Main, {
        Name = "Body",
        Position = UDim2.new(0, 0, 0, W.Header.Size.Y.Offset),
        Size = UDim2.new(1, 0, 1, -W.Header.Size.Y.Offset),
        ZIndex = 3
    })

    W.SidebarWidth = Device.Viewport().X < 560 and 140 or 156
    W.Inset = 0

    W.Sidebar = New("Frame", {
        Parent = W.Body,
        Name = "Sidebar",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 6),
        Size = UDim2.new(0, W.SidebarWidth - 12, 1, -14),
        ZIndex = 3
    })
    Library:Themed(W.Sidebar, "BackgroundColor3", "Sidebar")
    Library:Themed(W.Sidebar, "BackgroundTransparency", "SidebarAlpha")
    Library:Corner(W.Sidebar, UDim.new(0, 18))
    Library:GlassEdge(W.Sidebar, 1.1, 0.6)
    Library:Gloss(W.Sidebar, 0.95)

    W.SidebarLine = New("Frame", {
        Parent = W.Sidebar,
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 4
    })
    Library:FadeLine(W.SidebarLine, false)
    W.SidebarLine.Visible = false

    W.SearchBox = New("Frame", {
        Parent = W.Sidebar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 12),
        Size = UDim2.new(1, -21, 0, W.Mobile and 36 or 32),
        ZIndex = 4
    })
    Library:Corner(W.SearchBox, UDim.new(1, 0))
    Library:Themed(W.SearchBox, "BackgroundColor3", "Card")
    Library:Themed(W.SearchBox, "BackgroundTransparency", "ButtonAlpha")
    Library:Stroke(W.SearchBox, "StrokeSoft", 1)

    local SearchIcon = IconLabel(W.SearchBox, Library.Icons.Search, 14, "Ink")
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
    Library:Corner(W.ProfileButton, UDim.new(1, 0))
    Library:Themed(W.ProfileButton, "BackgroundColor3", "Row")
    Library:Themed(W.ProfileButton, "BackgroundTransparency", "RowAlpha")

    local ProfileIcon = IconLabel(W.ProfileButton, Library.Icons.Folder, 14, "Ink")
    ProfileIcon.AnchorPoint = Vector2.new(0, 0.5)
    ProfileIcon.Position = UDim2.new(0, 9, 0.5, 0)
    ProfileIcon.ZIndex = W.Sidebar.ZIndex + 2
    Library:Themed(ProfileIcon, "ImageColor3", "Ink")

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

    W.PageIcon = IconLabel(W.PageHeader, Library.Icons.Tab, 18, "Ink")
    W.PageIcon.AnchorPoint = Vector2.new(0, 0.5)
    W.PageIcon.Position = UDim2.new(0, 16, 0.5, 0)
    W.PageIcon.ZIndex = 5
    Library:Themed(W.PageIcon, "ImageColor3", "Ink")

    W.PageTitle = New("TextLabel", {
        Parent = W.PageHeader,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0.5, 0),
        Size = UDim2.new(1, -120, 0, 20),
        Font = Library.Font.Bold,
        Text = "",
        TextSize = Library.TextSize(15, 1),
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

    local StarYellow = Color3.fromRGB(235, 235, 235)
    function W.PaintFav()
        local Favorited = W.Active ~= nil and table.find(W.State.Favorites or {}, W.Active.Name) ~= nil
        local StarIcon = W.FavButton:FindFirstChildOfClass("ImageLabel")
        W.FavButton.BackgroundColor3 = Favorited and StarYellow or Library.Theme.Row
        Library:Tween(W.FavButton, FAST, { BackgroundTransparency = Favorited and 0.82 or 1 })
        if StarIcon then
            Library:Tween(StarIcon, FAST, { ImageColor3 = Favorited and StarYellow or Library.Theme.TextDim })
        end
    end
    -- these run after the shared hover handlers, so the yellow wins
    W.FavButton.MouseEnter:Connect(function()
        local StarIcon = W.FavButton:FindFirstChildOfClass("ImageLabel")
        if W.Active and table.find(W.State.Favorites or {}, W.Active.Name) and StarIcon then
            Library:Tween(StarIcon, FAST, { ImageColor3 = StarYellow })
            Library:Tween(W.FavButton, FAST, { BackgroundTransparency = 0.7 })
        end
    end)
    W.FavButton.MouseLeave:Connect(function()
        W.PaintFav()
    end)
    Library.OnThemeChanged:Connect(function()
        W.PaintFav()
    end)

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

    function W.SetPageHead(Title, Description, Icon)
        W.PageTitle.Text = Title or ""
        local HasDesc = (Description or "") ~= ""
        W.PageDesc.Text = Description or ""
        W.PageDesc.Visible = HasDesc
        W.PageTitle.Position = UDim2.new(0, 42, 0.5, HasDesc and -8 or 0)
        Library:SetIcon(W.PageIcon, Icon or Library.Icons.Tab, Library.Theme.Ink)
    end

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
    W.Backdrop.MouseButton1Click:Connect(function()
    end)

    W.DrawerOpen = true

    function W.ToggleDrawer()
    end

    function W.ApplyTabRail(Tab, Rail)
        Tab.Label.Visible = not Rail
        if Tab.RoleBadge then
            Tab.RoleBadge.Visible = not Rail and Tab.RoleBadge.Text ~= ""
        end
        Tab.IconLabel.AnchorPoint = Rail and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
        Tab.IconLabel.Position = Rail and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 16, 0.5, 0)
        Tab.LockIcon.AnchorPoint = Rail and Vector2.new(1, 0) or Vector2.new(1, 0.5)
        Tab.LockIcon.Position = Rail and UDim2.new(1, -4, 0, 4) or UDim2.new(1, -10, 0.5, 0)
    end

    function W.ApplyRail(Rail)
        if W.RailState == Rail then
            return
        end
        W.RailState = Rail
        local Top = Rail and 10 or (W.SearchBox.Size.Y.Offset + 20)
        W.SearchBox.Visible = not Rail
        W.TabScroll.Position = UDim2.new(0, 8, 0, Top)
        W.TabScroll.Size = UDim2.new(1, -16, 1, -(Top + 44))
        W.ProfileLabel.Visible = not Rail
        ProfileIcon.AnchorPoint = Rail and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
        ProfileIcon.Position = Rail and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 9, 0.5, 0)
        for _, Group in ipairs(W.Groups) do
            if Group.HeaderLabel then
                Group.HeaderLabel.Visible = not Rail
                Group.Chevron.Visible = not Rail
                Group.Header.Size = UDim2.new(1, 0, 0, Rail and 8 or 26)
                Group.Holder.Visible = Rail or Group.Opened
            end
        end
        for _, Tab in ipairs(W.Tabs) do
            W.ApplyTabRail(Tab, Rail)
        end
    end

    function W.Relayout()
        local HeaderHeight = W.Header.Size.Y.Offset
        W.Body.Position = UDim2.new(0, 0, 0, HeaderHeight)
        W.Body.Size = UDim2.new(1, 0, 1, -HeaderHeight)
        W.MenuButton.Visible = false
        local Class = Device.Class()
        local Rail = Class == "Mobile"
        W.SidebarWidth = Rail and 70 or (Class == "Tablet" and 164 or 156)
        W.ApplyRail(Rail)
        W.Sidebar.Size = UDim2.new(0, W.SidebarWidth - 12, 1, -14)
        W.Sidebar.Visible = true
        W.Sidebar.Position = UDim2.fromOffset(8, 6)
        W.Sidebar.ZIndex = 3
        W.Backdrop.Visible = false
        W.Content.Position = UDim2.new(0, W.SidebarWidth, 0, 0)
        W.Content.Size = UDim2.new(1, -W.SidebarWidth, 1, 0)
    end

    do
        local Dragging, Origin, StartPosition = false, nil, nil
        local function Begin(Input)
            if Dragging then
                return
            end
            Dragging = true
            Origin = Input.Position
            StartPosition = W.Root.Position
            Library:BeginDragLock()
        end
        local function End()
            if not Dragging then
                return
            end
            Dragging = false
            Library:EndDragLock()
            W.Clamp()
            W.SaveState()
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
                End()
            end
        end))
    end

    local FloatW = W.Mobile and 168 or 156
    local FloatH = W.Mobile and 52 or 48
    local FloatTouch = Device.IsTouch()
    local BandPosition, BandSize = Device.Band()
    W.FloatButton = New("Frame", {
        Parent = W.Gui,
        AnchorPoint = FloatTouch and Vector2.new(0.5, 0.5) or Vector2.new(1, 1),
        BorderSizePixel = 0,
        Position = FloatTouch
            and UDim2.fromOffset(BandPosition.X + BandSize.X - FloatW / 2, BandPosition.Y + FloatH / 2)
            or UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(FloatW, FloatH),
        Visible = false,
        ZIndex = 600
    })
    Library:Corner(W.FloatButton, UDim.new(0, 16))
    Library:Themed(W.FloatButton, "BackgroundColor3", "Elevated")
    Library:Themed(W.FloatButton, "BackgroundTransparency", "ElevatedAlpha")
    Library:GlassEdge(W.FloatButton, 1.4, 0.2)
    Library:Shadow(W.FloatButton, 40, 0.55)
    Library:Sheen(W.FloatButton, 90).ZIndex = 600

    local FloatLogo = New("Frame", {
        Parent = W.FloatButton,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(W.Mobile and 32 or 30, W.Mobile and 32 or 30),
        BackgroundTransparency = 0.86,
        ZIndex = 601
    })
    Library:Corner(FloatLogo, UDim.new(0, 12))
    Library:Themed(FloatLogo, "BackgroundColor3", "Ink")
    local FloatLogoImg = New("ImageLabel", {
        Parent = FloatLogo,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Image = W.Config.Logo or "",
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 602
    })
    if W.Config.Icon then
        Library:SetIcon(FloatLogoImg, W.Config.Icon, Library.Theme.InkText)
    end

    local FloatTitle = New("TextLabel", {
        Parent = W.FloatButton,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, W.Mobile and 46 or 44, 0, 0),
        Size = UDim2.new(1, W.Mobile and -90 or -86, 1, 0),
        Font = Library.Font.Bold,
        Text = W.Config.Title or "sh1ttybanana",
        TextSize = W.Mobile and 13 or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 601
    })
    Library:Themed(FloatTitle, "TextColor3", "Text")

    local FloatOpen = New("TextButton", {
        Parent = W.FloatButton,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(W.Mobile and 34 or 32, W.Mobile and 34 or 32),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 603
    })
    Library:Corner(FloatOpen, UDim.new(0, 12))
    Library:Themed(FloatOpen, "BackgroundColor3", "Ink")
    FloatOpen.BackgroundTransparency = 0.82
    local FloatScan = IconLabel(FloatOpen, Library.Icons.Scan, W.Mobile and 18 or 16, "Ink")
    FloatScan.AnchorPoint = Vector2.new(0.5, 0.5)
    FloatScan.Position = UDim2.fromScale(0.5, 0.5)
    FloatScan.ZIndex = 604
    Library:Themed(FloatScan, "ImageColor3", "Ink")

    FloatOpen.MouseEnter:Connect(function()
        Library:Tween(FloatOpen, FAST, { BackgroundTransparency = 0.55 })
    end)
    FloatOpen.MouseLeave:Connect(function()
        Library:Tween(FloatOpen, FAST, { BackgroundTransparency = 0.82 })
    end)
    FloatOpen.MouseButton1Click:Connect(function()
        Library:Feedback(1.15)
        W.SetOpen(true)
    end)

    do
        local Dragging, Origin, StartPosition, Moved = false, nil, nil, false
        W.FloatButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                Moved = false
                Origin = Input.Position
                StartPosition = W.FloatButton.Position
                Library:BeginDragLock()
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
                Library:EndDragLock()
                if W.ClampFloat then
                    W.ClampFloat()
                end
                W.SaveState()
            end
        end))
    end

    if not FloatTouch and type(W.State.FloatPosition) == "table" and #W.State.FloatPosition >= 4 then
        local FP = W.State.FloatPosition
        W.FloatButton.Position = UDim2.new(FP[1], FP[2], FP[3], FP[4])
    end

    function W.ClampFloat()
        if not FloatTouch then
            return
        end
        local Viewport = Device.Viewport()
        local Origin, Area = Device.Band()
        local Half = Vector2.new(FloatW, FloatH) / 2
        local Current = W.FloatButton.Position
        local X = Current.X.Scale * Viewport.X + Current.X.Offset
        local Y = Current.Y.Scale * Viewport.Y + Current.Y.Offset
        local MaxX = math.max(Origin.X + Area.X - Half.X, Origin.X + Half.X)
        local MaxY = math.max(Origin.Y + Area.Y - Half.Y, Origin.Y + Half.Y)
        W.FloatButton.Position = UDim2.fromOffset(
            Clamp(X, Origin.X + Half.X, MaxX),
            Clamp(Y, Origin.Y + Half.Y, MaxY)
        )
    end

    Library.OnThemeChanged:Connect(function()
        if W.FloatButton and W.FloatButton.Parent then
            pcall(function()
                W.FloatButton.BackgroundColor3 = Library.Theme.Elevated
                W.FloatButton.BackgroundTransparency = Library.Theme.ElevatedAlpha
            end)
        end
    end)


    do
        local TipCard = New("Frame", {
            Parent = W.Gui,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 700,
            Size = UDim2.fromOffset(0, 28),
            AutomaticSize = Enum.AutomaticSize.X
        })
        Library:Corner(TipCard, UDim.new(0, 10))
        Library:Themed(TipCard, "BackgroundColor3", "Elevated")
        Library:Themed(TipCard, "BackgroundTransparency", "ElevatedAlpha")
        Library:Stroke(TipCard, "StrokeSoft", 1)
        New("UIPadding", {
            Parent = TipCard,
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        })
        local TipText = New("TextLabel", {
            Parent = TipCard,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 28),
            Font = Library.Font.Medium,
            Text = "",
            TextSize = 11,
            ZIndex = 701
        })
        Library:Themed(TipText, "TextColor3", "Text")
        W.Tooltip = TipCard
        W.TooltipLabel = TipText

        local function ShowTip(Obj)
            local Tip = Obj:GetAttribute("Tip")
            if type(Tip) ~= "string" or Tip == "" then
                TipCard.Visible = false
                return
            end
            TipText.Text = Tip
            TipCard.Visible = true
            local Pos = Obj.AbsolutePosition
            local Size = Obj.AbsoluteSize
            local Vp = Device.Viewport()
            local X = Pos.X + Size.X / 2 - TipCard.AbsoluteSize.X / 2
            local Y = Pos.Y - 34
            if Y < 8 then
                Y = Pos.Y + Size.Y + 8
            end
            X = Clamp(X, 8, Vp.X - TipCard.AbsoluteSize.X - 8)
            TipCard.Position = UDim2.fromOffset(X, Y)
        end

        local function HookTips(Root)
            local function Bind(Obj)
                if not Obj:IsA("GuiObject") then
                    return
                end
                if Obj:GetAttribute("TipBound") then
                    return
                end
                Obj:SetAttribute("TipBound", true)
                Obj.MouseEnter:Connect(function()
                    ShowTip(Obj)
                end)
                Obj.MouseLeave:Connect(function()
                    TipCard.Visible = false
                end)
            end
            for _, D in ipairs(Root:GetDescendants()) do
                if D:GetAttribute("Tip") then
                    Bind(D)
                end
            end
            Root.DescendantAdded:Connect(function(D)
                task.defer(function()
                    if D.Parent and D:GetAttribute("Tip") then
                        Bind(D)
                    end
                end)
            end)
        end
        HookTips(W.Gui)
    end


    if W.Config.ShowWatermark ~= false then
        local Mark = New("TextLabel", {
            Parent = W.Gui,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 12, 1, -10),
            Size = UDim2.fromOffset(280, 16),
            Font = Library.Font.Medium,
            Text = W.Config.WatermarkText or "NexxWare SB V0.1",
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.45,
            ZIndex = 5
        })
        Library:Themed(Mark, "TextColor3", "TextDim")
        W.Watermark = Mark
    end

    function W.SetOpen(State)
        if State == nil then
            State = not W.Open
        end
        W.Open = State
        if State then
            W.Root.Visible = true
            W.FloatButton.Visible = false
            local Closing = W.Main:FindFirstChild("CloseScale")
            if Closing then
                Closing:Destroy()
            end
            Library:Pop(W.Main, 0.42, 0.9)
            Library:Animate(W.Main, SLOW, { BackgroundTransparency = Library.Theme.WindowAlpha })
            if W.Sidebar then
                W.Sidebar.Position = UDim2.fromOffset(-18, 6)
                Library:Animate(W.Sidebar, SLOW, { Position = UDim2.fromOffset(8, 6) })
            end
            if W.Pages then
                W.Pages.Position = UDim2.new(0, 0, 0, 62)
                Library:Animate(W.Pages, SLOW, { Position = UDim2.new(0, 0, 0, 47) })
            end
            W.Header.Position = UDim2.fromOffset(0, -10)
            Library:Animate(W.Header, NORMAL, { Position = UDim2.fromOffset(0, 0) })
            if W.Blur then
                Library:Animate(W.Blur, NORMAL, { Size = Library.Theme.Blur })
            end
        else
            W.FloatButton.Visible = true
            Library:Pop(W.FloatButton, 0.34, 0.7)
            local Shrink = New("UIScale", { Name = "CloseScale", Parent = W.Main, Scale = 1 })
            Library:Animate(Shrink, FAST, { Scale = 0.92 }, function()
                if not W.Open then
                    W.Root.Visible = false
                end
                if Shrink.Parent then
                    Shrink:Destroy()
                end
            end)
            if W.Blur then
                Library:Animate(W.Blur, FAST, { Size = 0 })
            end
        end
        Library:Feedback(State and 1.1 or 0.9)
    end

    table.insert(W.Connections, UserInputService.InputBegan:Connect(function(Input, Typing)
        if Typing or not Device.IsKeyInput(Input) then
            return
        end
        if Input.KeyCode == W.Config.ToggleKey then
            W.SetOpen()
        end
        WM.FireKeybinds(W, Input)
    end))

    table.insert(W.Connections, UserInputService.InputEnded:Connect(function(Input)
        if Device.IsKeyInput(Input) then
            WM.FireKeybinds(W, Input, true)
        end
    end))

    local Camera = workspace.CurrentCamera
    if Camera then
        table.insert(W.Connections, Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            W.Mobile = Device.IsMobile()
            W.Fit()
            W.Relayout()
            W.Clamp()
        end))
    end

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
    W.Relayout()
    return WM.BuildAPI(W)
end

local ComponentNames = {
    "Toggle", "Button", "Input", "Slider", "Dropdown", "Keybind",
    "Colorpicker", "ColorpickerRGB", "MultiButton", "Paragraph", "Label",
    "Tag", "Codeblock", "Progress", "Grid", "Table", "Image", "Viewport",
    "RangeSlider", "ToggleGroup", "FilePicker", "ConfirmToggle", "Hotbar",
    "PlayerSelector", "LogConsole",
    "Separator", "Divider", "Space", "Card"
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
        ClipsDescendants = true
    })
    Tab.SectionCount = Tab.SectionCount + 1
    Section.Frame = Card

    if not Config.Headerless then
        Library:Corner(Card, UDim.new(0, 16))
        Library:Themed(Card, "BackgroundColor3", "Card")
        Library:Themed(Card, "BackgroundTransparency", "CardAlpha")
        Library:GlassEdge(Card, 1, 0.65)
    end

    New("UIPadding", {
        Parent = Card,
        PaddingTop = UDim.new(0, Config.Headerless and 0 or 12),
        PaddingBottom = UDim.new(0, Config.Headerless and 0 or 12),
        PaddingLeft = UDim.new(0, Config.Headerless and 0 or 12),
        PaddingRight = UDim.new(0, Config.Headerless and 0 or 12)
    })

    New("UIListLayout", {
        Parent = Card,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, W.Mobile and 6 or 8)
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

local function BuildSubtab(Tab, Config)
    local W = Tab.Window
    local Mobile = W.Mobile

    if not Tab.SubBar then
        Tab.Subtabs = {}
        Tab.SubBar = New("ScrollingFrame", {
            Parent = Tab.Page,
            Name = "Subtabs",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, Mobile and 42 or 36),
            LayoutOrder = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            ScrollingDirection = Enum.ScrollingDirection.X,
            ElasticBehavior = Enum.ElasticBehavior.Never
        })
        Tab.SubTrack = New("Frame", {
            Parent = Tab.SubBar,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, Mobile and 36 or 30),
            AutomaticSize = Enum.AutomaticSize.X
        })
        Library:Corner(Tab.SubTrack, UDim.new(1, 0))
        Library:Themed(Tab.SubTrack, "BackgroundColor3", "Row")
        Library:Themed(Tab.SubTrack, "BackgroundTransparency", "RowAlpha")
        Library:GlassEdge(Tab.SubTrack, 1, 0.6)
        Tab.SubIndicator = New("Frame", {
            Parent = Tab.SubTrack,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 3, 0.5, 0),
            Size = UDim2.fromOffset(0, Mobile and 30 or 24),
            BackgroundTransparency = 0.06,
            Visible = false,
            ZIndex = 1
        })
        Library:Corner(Tab.SubIndicator, UDim.new(1, 0))
        Library:Themed(Tab.SubIndicator, "BackgroundColor3", "Ink")
        Tab.SubLane = New("Frame", {
            Parent = Tab.SubTrack,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex = 2
        })
        New("UIPadding", {
            Parent = Tab.SubLane,
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3)
        })
        New("UIListLayout", {
            Parent = Tab.SubLane,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        local function Move(Animated)
            local Active = Tab.ActiveSub
            if not Active or Tab.SubTrack.AbsoluteSize.X <= 0 then
                return
            end
            local Scale = math.max(W.Scale.Scale, 0.001)
            local Offset = (Active.Button.AbsolutePosition.X - Tab.SubTrack.AbsolutePosition.X) / Scale
            local Width = Active.Button.AbsoluteSize.X / Scale
            Tab.SubIndicator.Visible = true
            local Info = Animated and TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) or TweenInfo.new(0)
            Library:Tween(Tab.SubIndicator, Info, {
                Position = UDim2.new(0, Offset, 0.5, 0),
                Size = UDim2.new(0, Width, 0, Mobile and 30 or 24)
            })
        end
        Tab.MoveSubIndicator = Move
        Tab.OnShow = function()
            task.defer(Move, false)
        end
        Tab.SubTrack:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Move(false)
        end)
    end

    local Sub = { Title = Config.Title }
    Sub.Container = New("Frame", {
        Parent = Tab.Page,
        Name = "Subpage",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 500,
        Visible = false
    })
    New("UIListLayout", {
        Parent = Sub.Container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, Mobile and 8 or 10)
    })

    local Proxy = setmetatable({
        Page = Sub.Container,
        SectionCount = 0,
        Owner = Tab,
        Subtab = Sub
    }, { __index = Tab })

    Sub.Button = New("TextButton", {
        Parent = Tab.SubLane,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, Mobile and 30 or 24),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #Tab.Subtabs + 1,
        ZIndex = 3
    })
    Library:Corner(Sub.Button, UDim.new(1, 0))
    New("UIPadding", {
        Parent = Sub.Button,
        PaddingLeft = UDim.new(0, Mobile and 16 or 14),
        PaddingRight = UDim.new(0, Mobile and 16 or 14)
    })
    New("UIListLayout", {
        Parent = Sub.Button,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    if Config.Icon then
        Sub.Icon = IconLabel(Sub.Button, Config.Icon, 13, "TextDim")
        Sub.Icon.LayoutOrder = 1
        Sub.Icon.ZIndex = 4
    end
    Sub.Label = New("TextLabel", {
        Parent = Sub.Button,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Library.Font.Bold,
        Text = Config.Title,
        TextSize = Mobile and 13 or 12,
        LayoutOrder = 2,
        ZIndex = 4
    })
    Library:Themed(Sub.Label, "TextColor3", "TextDim")

    table.insert(Tab.Subtabs, Sub)
    Sub.Button.MouseEnter:Connect(function()
        if Tab.ActiveSub ~= Sub then
            Library:Tween(Sub.Label, FAST, { TextColor3 = Library.Theme.Text })
        end
    end)
    Sub.Button.MouseLeave:Connect(function()
        if Tab.ActiveSub ~= Sub then
            Library:Tween(Sub.Label, FAST, { TextColor3 = Library.Theme.TextDim })
        end
    end)

    function Sub.Select(Animated)
        if Tab.ActiveSub == Sub then
            return
        end
        Tab.ActiveSub = Sub
        for _, Other in ipairs(Tab.Subtabs) do
            local Active = Other == Sub
            Other.Container.Visible = Active
            Library:Tween(Other.Label, FAST, { TextColor3 = Active and Library.Theme.InkText or Library.Theme.TextDim })
            if Other.Icon then
                Library:Tween(Other.Icon, FAST, { ImageColor3 = Active and Library.Theme.InkText or Library.Theme.TextDim })
            end
        end
        Tab.MoveSubIndicator(Animated ~= false)
        if Animated ~= false then
            local Cards = {}
            for _, Child in ipairs(Sub.Container:GetChildren()) do
                if Child:IsA("Frame") then
                    table.insert(Cards, Child)
                end
            end
            table.sort(Cards, function(A, B)
                return A.LayoutOrder < B.LayoutOrder
            end)
            Library:Rise(Cards)
        end
    end

    Sub.Button.MouseButton1Click:Connect(function()
        Library:Feedback(1.05)
        Sub.Select(true)
    end)

    local API = {}
    Sub.API = API
    API.Instance = Sub.Container

    function API:AddSection(SectionConfig, _, Headerless)
        if type(SectionConfig) == "string" then
            SectionConfig = { Title = SectionConfig, Headerless = Headerless }
        end
        return BuildSection(Proxy, SectionConfig)
    end

    function API:AddTabSection(SectionConfig)
        if type(SectionConfig) == "string" then
            SectionConfig = { Title = SectionConfig }
        end
        SectionConfig = SectionConfig or {}
        SectionConfig.Collapsible = true
        return BuildSection(Proxy, SectionConfig)
    end

    local DefaultSection
    local function Default()
        if not DefaultSection then
            DefaultSection = BuildSection(Proxy, { Title = Sub.Title, Headerless = true })
        end
        return DefaultSection
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
        Sub.Select(true)
    end

    function API:SetTitle(Text)
        Sub.Title = tostring(Text)
        Sub.Label.Text = Sub.Title
        task.defer(Tab.MoveSubIndicator, false)
    end

    function API:SetVisible(State)
        Sub.Button.Visible = State ~= false
    end

    if #Tab.Subtabs == 1 then
        task.defer(Sub.Select, false)
    end

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
    local PagePad = W.Mobile and 10 or 14
    New("UIPadding", {
        Parent = Tab.Page,
        PaddingTop = UDim.new(0, W.Mobile and 8 or 12),
        PaddingBottom = UDim.new(0, W.Mobile and 12 or 16),
        PaddingLeft = UDim.new(0, PagePad),
        PaddingRight = UDim.new(0, PagePad)
    })
    New("UIListLayout", {
        Parent = Tab.Page,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, W.Mobile and 8 or 10)
    })

    local Height = W.Mobile and 46 or 36
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
    Library:Corner(Tab.Button, UDim.new(0, 14))
    Library:Themed(Tab.Button, "BackgroundColor3", "Ink")
    Tab.Button.BackgroundTransparency = 1

    Tab.Stroke = New("UIStroke", {
        Parent = Tab.Button,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(Tab.Stroke, "Color", "Ink")

    Tab.Indicator = New("Frame", {
        Parent = Tab.Button,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0.5, 0),
        Size = UDim2.fromOffset(3, 0),
        ZIndex = W.Sidebar.ZIndex + 2
    })
    Library:Corner(Tab.Indicator, UDim.new(1, 0))
    Library:Themed(Tab.Indicator, "BackgroundColor3", "Ink")

    Tab.IconLabel = IconLabel(Tab.Button, Config.Icon, W.Mobile and 20 or 16, "Ink")
    Tab.IconLabel.AnchorPoint = Vector2.new(0, 0.5)
    Tab.IconLabel.Position = UDim2.new(0, 16, 0.5, 0)
    Tab.IconLabel.ImageTransparency = 0.35
    Library:Themed(Tab.IconLabel, "ImageColor3", "Ink")
    Tab.IconLabel.ZIndex = W.Sidebar.ZIndex + 2

    Tab.Label = New("TextLabel", {
        Parent = Tab.Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, W.Mobile and 43 or 39, 0, 0),
        Size = UDim2.new(1, -62, 1, 0),
        Font = Library.Font.Bold,
        Text = Config.Title,
        TextTransparency = 0.4,
        TextSize = Library.TextSize(12, 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = W.Sidebar.ZIndex + 2
    })
    Library:Themed(Tab.Label, "TextColor3", "TabText")
    if not Library.Theme.TabText then
        Library:Themed(Tab.Label, "TextColor3", "TextDim")
    end

    Tab.LockIcon = IconLabel(Tab.Button, Library.Icons.Lock, 13, "TextDisabled")
    Tab.LockIcon.AnchorPoint = Vector2.new(1, 0.5)
    Tab.LockIcon.Position = UDim2.new(1, -10, 0.5, 0)
    Tab.LockIcon.ZIndex = W.Sidebar.ZIndex + 2
    Tab.LockIcon.Visible = Config.Lock ~= nil

    Tab.RoleBadge = New("TextLabel", {
        Parent = Tab.Button,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, Config.Lock and -28 or -10, 0.5, 0),
        Size = UDim2.fromOffset(0, 14),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Library.Font.Bold,
        Text = Config.Role and (" " .. tostring(Config.Role) .. " ") or "",
        TextSize = 9,
        Visible = Config.Role ~= nil,
        ZIndex = W.Sidebar.ZIndex + 2
    })
    Library:Corner(Tab.RoleBadge, UDim.new(1, 0))
    Library:Themed(Tab.RoleBadge, "BackgroundColor3", "Ink")
    Library:Themed(Tab.RoleBadge, "TextColor3", "Ink")

    Tab.Unlocked = Config.Lock == nil
    Tab.Role = Config.Role

    if Config.Lock then
        local LockConfig = type(Config.Lock) == "table" and Config.Lock or { Password = Config.LockPassword }
        LockConfig.RememberMinutes = tonumber(LockConfig.RememberMinutes) or 10
        LockConfig.Id = LockConfig.Id or LockConfig.Key or Config.Title
        LockConfig.Check = Library.Auth.Resolve(LockConfig)
        if LockConfig.Remember ~= false and Library.Auth.IsRemembered(W, LockConfig.Id) then
            Tab.Unlocked = true
            Tab.LockIcon.Visible = false
        end
        Tab.LockConfig = LockConfig
    end

    Tab.Button.MouseEnter:Connect(function()
        if W.Active ~= Tab then
            Library:Tween(Tab.Button, FAST, { BackgroundTransparency = Library.Theme.TabHoverAlpha or 0.93 })
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

    W.ApplyTabRail(Tab, W.RailState == true)

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

    function API:AddSubtab(SubConfig)
        if type(SubConfig) == "string" then
            SubConfig = { Title = SubConfig }
        end
        return BuildSubtab(Tab, Merge({ Title = "Subtab", Icon = nil }, SubConfig or {}))
    end
    API.Subtab = API.AddSubtab

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
            local LockConfig = type(Password) == "table" and Password or { Password = Password }
            LockConfig.Id = LockConfig.Id or LockConfig.Key or Tab.Name
            LockConfig.Check = Library.Auth.Resolve(LockConfig)
            Tab.LockConfig = LockConfig
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
    Group.Header = Header
    Group.HeaderLabel = HeaderLabel

    local Chevron = IconLabel(Header, Library.Icons.Down, 13, "TextDisabled")
    Group.Chevron = Chevron
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
    if W.RailState then
        HeaderLabel.Visible = false
        Chevron.Visible = false
        Header.Size = UDim2.new(1, 0, 0, 8)
        Group.Holder.Visible = true
    end

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

local BindEscape

local function GetOverlay(W)
    if not W.Overlay then
        W.Overlay = Blank(W.Main, {
            Name = "Overlay",
            Size = UDim2.fromScale(1, 1),
            ZIndex = 200
        })
    end
    return W.Overlay
end

local function LocalPosition(W, Object)
    local Scale = W.Scale.Scale
    local Offset = Object.AbsolutePosition - W.Main.AbsolutePosition
    return Vector2.new(Offset.X / Scale, Offset.Y / Scale), Object.AbsoluteSize / Scale
end

local function Popup(W, Source, Width, Height)
    local Overlay = GetOverlay(W)
    local PopupBase = 201
    if W.Modals and #W.Modals > 0 then
        PopupBase = 214 + #W.Modals * 4
    end
    local Backdrop = New("TextButton", {
        Parent = Overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = PopupBase
    })

    local Position, Size = LocalPosition(W, Source)
    local MainSize = W.Main.AbsoluteSize / math.max(W.Scale.Scale, 0.001)
    Width = math.min(Width, math.max(MainSize.X - 16, 120))
    Height = math.min(Height, math.max(MainSize.Y - 16, 80))
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
        ZIndex = PopupBase + 1,
        ClipsDescendants = true
    })
    Library:Corner(Frame, UDim.new(0, 14))
    Library:Themed(Frame, "BackgroundColor3", "Elevated")
    Library:Themed(Frame, "BackgroundTransparency", "ElevatedAlpha")
    Library:GlassEdge(Frame, 1.2, 0.3)
    Library:Shadow(Frame, 46, 0.55)
    Library:Pop(Frame, 0.3, 0.88)

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
        local Shrink = New("UIScale", { Parent = Frame, Scale = 1 })
        Library:Tween(Shrink, FAST, { Scale = 0.94 })
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

function Components.Toggle(Section, Config)
    Config = Merge({
        Title = "Toggle",
        Description = "",
        Default = false,
        Flag = nil,
        Callback = function() end
    }, Config)

    local Mobile = Section.Window.Mobile
    local Row, TitleLabel, DescLabel = MakeRow(Section, "Toggle", Config.Title, Config.Description, 46, 50)

    local TrackW, TrackH = Mobile and 54 or 44, Mobile and 30 or 24
    local KnobSize = TrackH - 6

    local Track = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(TrackW, TrackH),
        ZIndex = 2
    })
    Library:Corner(Track, UDim.new(1, 0))
    Track.BackgroundColor3 = Library.Theme.Track or Color3.fromRGB(96, 96, 96)
    Track.BackgroundTransparency = Library.Theme.TrackAlpha or 0.2
    local TrackLine = Library:Stroke(Track, "StrokeSoft", 1)

    local Knob = New("Frame", {
        Parent = Track,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(KnobSize, KnobSize),
        BackgroundColor3 = Color3.fromRGB(210, 210, 210),
        ZIndex = 3
    })
    Library:Corner(Knob, UDim.new(1, 0))
    New("UIStroke", {
        Parent = Knob,
        Thickness = 1,
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.82,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })

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
        local Info = Animated and TweenInfo.new(0.26, Quint, Out) or TweenInfo.new(0)
        local Theme = Library.Theme
        Library:Tween(Knob, Info, {
            Position = UDim2.new(0, State and (TrackW - KnobSize - 3) or 3, 0.5, 0),
            BackgroundColor3 = State and Library.Theme.InkText or Color3.fromRGB(210, 210, 210)
        })
        Library:Tween(Track, Info, {
            BackgroundColor3 = State and Theme.Ink or (Theme.Track or Color3.fromRGB(96, 96, 96)),
            BackgroundTransparency = State and 0.05 or (Theme.TrackAlpha or 0.2)
        })
        Library:Tween(TrackLine, Info, {
            Color = State and Theme.Ink or Theme.StrokeSoft,
            Transparency = State and 0.3 or Theme.StrokeSoftAlpha
        })
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

function Components.Button(Section, Config)
    Config = Merge({
        Title = "Button",
        Description = "",
        Confirm = false,
        Cooldown = 0,
        Icon = nil,
        Callback = function() end
    }, Config)
    local Cool = tonumber(Config.Cooldown) or 0
    local LastFire = 0

    local Row, TitleLabel, DescLabel = MakeRow(Section, "Button", Config.Title, Config.Description, 44, 30)

    -- round accent chip that holds the arrow
    local Chip = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 0.8,
        ZIndex = 6
    })
    Library:Corner(Chip, UDim.new(1, 0))
    Library:Themed(Chip, "BackgroundColor3", "Ink")
    local ChipLine = New("UIStroke", {
        Parent = Chip,
        Thickness = 1,
        Transparency = 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(ChipLine, "Color", "Ink")

    local Arrow = IconLabel(Chip, Config.Icon or Library.Icons.Right, 14, "Ink")
    Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    Arrow.Position = UDim2.fromScale(0.5, 0.5)
    Arrow.ZIndex = 7
    Library:Themed(Arrow, "ImageColor3", "Ink")

    local Click = New("TextButton", {
        Parent = Row,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 8
    })

    Click.MouseEnter:Connect(function()
        Library:Tween(Chip, FAST, { BackgroundTransparency = 0.55 })
        Library:Tween(ChipLine, FAST, { Transparency = 0.3 })
    end)
    Click.MouseLeave:Connect(function()
        Library:Tween(Chip, FAST, { BackgroundTransparency = 0.8 })
        Library:Tween(ChipLine, FAST, { Transparency = 0.6 })
    end)

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
        if Cool > 0 then
            local Now = os.clock()
            if Now - LastFire < Cool then
                return
            end
            LastFire = Now
        end
        Library:Feedback(1.15)
        Library:Press(Row)
        Library:Animate(Arrow, TweenInfo.new(0.14, Quart, Out), { Position = UDim2.new(0.5, 4, 0.5, 0) }, function()
            Library:Animate(Arrow, SPRING, { Position = UDim2.fromScale(0.5, 0.5) })
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
                    { Text = "Confirm", Filled = true, Callback = Fire },
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

-- Card: a glass container that hosts any other component. Build it with a declarative
-- Items list, a Build(Card) callback, or by calling Card:AddButton / :AddSlider / ... later.
function Components.Card(Section, Config)
    Config = Merge({
        Title = "Card",
        Description = "",
        Icon = nil,
        Collapsible = false,
        Opened = true,
        Actions = nil,
        Items = nil,
        Build = nil
    }, Config)

    local Window = Section.Window
    local Mobile = Window.Mobile

    local Frame = New("Frame", {
        Parent = Section.Body,
        Name = "CardBlock",
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = Section.Count + 1
    })
    Section.Count = Section.Count + 1
    Library:Corner(Frame, UDim.new(0, 18))
    Library:Themed(Frame, "BackgroundColor3", "Row")
    Library:Themed(Frame, "BackgroundTransparency", "RowAlpha")
    Library:GlassEdge(Frame, 1, 0.55)
    Library:Gloss(Frame, 0.94)

    -- inner holder owns the layout so the lock overlay can still cover the whole card
    local Inner = New("Frame", {
        Parent = Frame,
        Name = "Text",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    Library:Padding(Inner, 12, 12, 12, 12)
    New("UIListLayout", {
        Parent = Inner,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })

    -- header: [icon chip] [title + description] [actions]
    local Header = New("Frame", {
        Parent = Inner,
        Name = "Header",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1
    })
    New("UIListLayout", {
        Parent = Header,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })

    local Used = 0
    if Config.Icon then
        local Chip = New("Frame", {
            Parent = Header,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(34, 34),
            BackgroundTransparency = 0.82,
            LayoutOrder = 1
        })
        Library:Corner(Chip, UDim.new(1, 0))
        Library:Themed(Chip, "BackgroundColor3", "Ink")
        local ChipLine = New("UIStroke", {
            Parent = Chip,
            Thickness = 1,
            Transparency = 0.6,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Library:Themed(ChipLine, "Color", "Ink")
        local Glyph = IconLabel(Chip, Config.Icon, 16, "Ink")
        Glyph.AnchorPoint = Vector2.new(0.5, 0.5)
        Glyph.Position = UDim2.fromScale(0.5, 0.5)
        Used = Used + 44
    end

    local ActionList = {}
    if type(Config.Actions) == "table" then
        for _, Action in ipairs(Config.Actions) do
            table.insert(ActionList, Action)
        end
    end
    local ActionCount = #ActionList + (Config.Collapsible and 1 or 0)
    local ActionsWidth = ActionCount * 32
    if ActionCount > 0 then
        Used = Used + ActionsWidth + 10
    end

    local TextStack = New("Frame", {
        Parent = Header,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -Used, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2
    })
    New("UIListLayout", {
        Parent = TextStack,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })
    local TitleLabel = New("TextLabel", {
        Parent = TextStack,
        BackgroundTransparency = 1,
        Font = Library.Font.Bold,
        Text = Config.Title or "Card",
        TextSize = Library.TextSize(14, 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.new(1, 0, 0, Library.TextSize(14, 2) + 4),
        LayoutOrder = 1,
        RichText = true
    })
    Library:Themed(TitleLabel, "TextColor3", "Text")
    local DescLabel = New("TextLabel", {
        Parent = TextStack,
        BackgroundTransparency = 1,
        Font = Library.Font.Regular,
        Text = Config.Description or "",
        TextSize = Library.TextSize(11, 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Visible = (Config.Description or "") ~= "",
        RichText = true
    })
    Library:Themed(DescLabel, "TextColor3", "TextDisabled")

    local Actions
    local ChevronIcon
    local Opened = Config.Opened ~= false
    local Divider, Body

    local function PaintOpen(Animated)
        if Body then
            Body.Visible = Opened
        end
        if Divider then
            Divider.Visible = Opened
        end
        if ChevronIcon then
            if Animated then
                Library:Tween(ChevronIcon, FAST, { Rotation = Opened and 0 or -90 })
            else
                ChevronIcon.Rotation = Opened and 0 or -90
            end
        end
    end

    if ActionCount > 0 then
        Actions = New("Frame", {
            Parent = Header,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(ActionsWidth, 30),
            LayoutOrder = 3
        })
        New("UIListLayout", {
            Parent = Actions,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2)
        })
        for Index, Action in ipairs(ActionList) do
            local Button = GlyphButton(Actions, Action.Icon or Library.Icons.Right, Action.Tip)
            Button.LayoutOrder = Index
            Button.MouseButton1Click:Connect(function()
                if Action.Callback then
                    task.spawn(Action.Callback)
                end
            end)
        end
        if Config.Collapsible then
            local Chevron, Icon = GlyphButton(Actions, Library.Icons.Down, "Collapse")
            Chevron.LayoutOrder = #ActionList + 1
            ChevronIcon = Icon
            Chevron.MouseButton1Click:Connect(function()
                Opened = not Opened
                PaintOpen(true)
            end)
        end
    end

    Divider = New("Frame", {
        Parent = Inner,
        Name = "Divider",
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0.9,
        LayoutOrder = 2
    })
    Library:Themed(Divider, "BackgroundColor3", "Stroke")

    Body = New("Frame", {
        Parent = Inner,
        Name = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3
    })
    New("UIListLayout", {
        Parent = Body,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })
    PaintOpen(false)

    -- a section-shaped context so every component can be built inside the card
    local CardSection = {
        Window = Window,
        Tab = Section.Tab,
        Title = Config.Title,
        Elements = {},
        Count = 0,
        Body = Body,
        Opened = true,
        Parent = Section
    }

    local Handlers = {}
    function Handlers.Get()
        return nil
    end
    function Handlers.Set()
    end
    function Handlers.Lock(Locked, Reason)
        for _, Child in ipairs(CardSection.Elements) do
            Child:SetLocked(Locked, Reason)
        end
    end

    local Card = Finish(Section, "Card", Config, Frame, Handlers, TitleLabel, DescLabel)
    Card.Instance = Frame
    Card.Body = Body
    Card.Elements = CardSection.Elements

    local function Add(Kind, ElementConfig)
        local Builder = Components[Kind]
        if not Builder then
            return nil
        end
        return Builder(CardSection, type(ElementConfig) == "table" and ElementConfig or { Title = ElementConfig })
    end

    for _, Name in ipairs(ComponentNames) do
        Card["Add" .. Name] = function(_, ElementConfig)
            return Add(Name, ElementConfig)
        end
    end
    for Alias, Target in pairs(Aliases) do
        Card[Alias] = function(Self, ElementConfig)
            return Card[Target](Self, ElementConfig)
        end
    end

    function Card:Add(Kind, ElementConfig)
        local Key = tostring(Kind):gsub("^Add", ""):lower()
        for _, Name in ipairs(ComponentNames) do
            if Name:lower() == Key then
                return Add(Name, ElementConfig)
            end
        end
        return nil
    end

    function Card:SetOpened(State)
        Opened = State ~= false
        PaintOpen(true)
        return self
    end

    function Card:Clear()
        for _, Child in ipairs(table.clone(CardSection.Elements)) do
            Child:Destroy()
        end
        table.clear(CardSection.Elements)
        CardSection.Count = 0
        return self
    end

    function Card:Destroy()
        Card:Clear()
        Library.Element.Destroy(self)
    end

    if type(Config.Items) == "table" then
        for _, Item in ipairs(Config.Items) do
            local Kind = Item.Type or Item.Kind or Item.Component
            if Kind then
                Card:Add(Kind, Item)
            end
        end
    end
    if type(Config.Build) == "function" then
        local Ok, Err = pcall(Config.Build, Card)
        if not Ok then
            warn("[sh1ttybanana] Card build: " .. tostring(Err))
        end
    end

    return Card
end

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
    Library:Corner(Field, UDim.new(1, 0))
    Library:Themed(Field, "BackgroundColor3", "Inset")
    Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(Field, 0.96)
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
        Library:Tween(FieldLine, FAST, { Color = Library.Theme.Ink, Transparency = 0.3 })
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
    local Sample = tostring(Config.Max) .. tostring(Config.Suffix or "")
    local BoxWidth = Clamp(#Sample * 7 + 18, Mobile and 52 or 48, Mobile and 90 or 118)
    local BarWidth = Mobile and 120 or 150
    local Reserve = Mobile and (BoxWidth + 6) or (BarWidth + BoxWidth + 22)
    local SliderMobileExtra = Mobile and ((Section.Window.Config and Section.Window.Config.Compact) and 4 or 10) or 0
    local SliderNeed = 20 + 17 + ((Config.Description or "") ~= "" and 17 or 0) + 3 + 30
    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "Slider", Config.Title, Config.Description,
        Mobile and math.max(44, SliderNeed - SliderMobileExtra) or 44, Reserve)
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
    Library:Corner(ValueBox, UDim.new(1, 0))
    Library:Themed(ValueBox, "BackgroundColor3", "Inset")
    Library:Themed(ValueBox, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(ValueBox, 0.96)
    Library:Themed(ValueBox, "TextColor3", "Text")
    Library:Stroke(ValueBox, "StrokeSoft", 1)
    -- Hit is the (larger) touch area; Bar is the visible track inset inside it so the
    -- knob never pokes out of the row or into the description text.
    local KnobSize = Mobile and 22 or 18
    local Pad = math.floor(KnobSize / 2) + 4
    local Hit = New("Frame", {
        Parent = Row,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true
    })
    if Mobile then
        Hit.Parent = Stack
        Hit.LayoutOrder = 3
        Hit.Size = UDim2.new(1, 0, 0, KnobSize + 8)
    else
        Hit.AnchorPoint = Vector2.new(1, 0.5)
        Hit.Position = UDim2.new(1, -(BoxWidth + 24) + Pad, 0.5, 0)
        Hit.Size = UDim2.fromOffset(BarWidth + Pad * 2, KnobSize + 8)
    end
    local Bar = New("Frame", {
        Parent = Hit,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -Pad * 2, 0, 8)
    })
    Library:Corner(Bar, UDim.new(1, 0))
    Library:Themed(Bar, "BackgroundColor3", "Track")
    Library:Themed(Bar, "BackgroundTransparency", "TrackAlpha")
    local Fill = New("Frame", {
        Parent = Bar,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1)
    })
    Library:Corner(Fill, UDim.new(1, 0))
    Library:Themed(Fill, "BackgroundColor3", "Ink")
    New("UIGradient", {
        Parent = Fill,
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190))
    })
    local Knob = New("Frame", {
        Parent = Bar,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(KnobSize, KnobSize),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 3
    })
    Library:Corner(Knob, UDim.new(1, 0))
    local KnobHalo = New("UIStroke", {
        Parent = Knob,
        Thickness = 3,
        Transparency = 0.7,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(KnobHalo, "Color", "Ink")
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
        Hit.Active = not Locked
        ValueBox.TextEditable = not Locked
    end
    Element = Finish(Section, "Slider", Config, Row, Handlers, TitleLabel, DescLabel)
    local function FromInput(Position)
        local Start = Bar.AbsolutePosition.X
        local Width = math.max(Bar.AbsoluteSize.X, 1)
        local Alpha = Clamp((Position.X - Start) / Width, 0, 1)
        Handlers.Set(Config.Min + Alpha * (Config.Max - Config.Min))
    end
    Hit.InputBegan:Connect(function(Input)
        if Element.Locked then
            return
        end
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            Library:Feedback(1.2)
            Library:Tween(Knob, SPRING, { Size = UDim2.fromOffset(KnobSize + 4, KnobSize + 4) })
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
            Library:Tween(Knob, SPRING, { Size = UDim2.fromOffset(KnobSize, KnobSize) })
        end
    end))
    ValueBox.FocusLost:Connect(function()
        local Typed = tonumber((ValueBox.Text:gsub("[^%d%.%-]", "")))
        Handlers.Set(Typed or Value)
    end)
    Boot(Section, Config, Element, Config.Default or Config.Min)
    return Element
end
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
    Library:Corner(Button, UDim.new(1, 0))
    Library:Themed(Button, "BackgroundColor3", "Inset")
    Library:Themed(Button, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(Button, 0.96)
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

    Button.MouseEnter:Connect(function()
        Library:Tween(ButtonLine, FAST, { Transparency = 0.55 })
        Library:Tween(Chevron, FAST, { ImageColor3 = Library.Theme.Text })
    end)
    Button.MouseLeave:Connect(function()
        Library:Tween(ButtonLine, FAST, { Transparency = Library.Theme.StrokeSoftAlpha })
        Library:Tween(Chevron, FAST, { ImageColor3 = Library.Theme.TextDim })
    end)

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
            if #Names > 2 then
                return #Names .. " selected"
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
        local Mobile = Section.Window.Mobile
        local MaxItems = Mobile and 12 or 8
        local Count = math.min(#Options, MaxItems)
        local UseSearch = Config.Search
        if UseSearch == nil then
            UseSearch = #Options > (Mobile and 6 or 8)
        end
        local RowH = Mobile and 36 or 32
        local Height = 20 + (UseSearch and 38 or 0) + math.max(Count, 1) * RowH
        local Vp = Device.Viewport()
        Height = math.min(Height, math.floor(Vp.Y * 0.55))
        Handle = Popup(Section.Window, Button, math.max(ButtonWidth, Mobile and 200 or 190), Height)
        Library:Tween(Chevron, NORMAL, { Rotation = 180 })

        local SearchText = ""
        local List

        if UseSearch then
            local Field = New("Frame", {
                Parent = Handle.Frame,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 8, 0, 8),
                Size = UDim2.new(1, -16, 0, 28),
                ZIndex = (Handle and Handle.Frame and Handle.Frame.ZIndex or 202) + 1
            })
            Library:Corner(Field, UDim.new(1, 0))
            Library:Themed(Field, "BackgroundColor3", "Inset")
            Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
            Library:Gloss(Field, 0.96)
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
                ZIndex = (Handle and Handle.Frame and Handle.Frame.ZIndex or 202) + 2
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
            ZIndex = (Handle and Handle.Frame and Handle.Frame.ZIndex or 202) + 1
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
                        Size = UDim2.new(1, 0, 0, Section.Window.Mobile and 36 or 31),
                        Text = "",
                        AutoButtonColor = false,
                        LayoutOrder = Index,
                        BackgroundTransparency = Active and 0.88 or 1,
                        ZIndex = (Handle and Handle.Frame and Handle.Frame.ZIndex or 202) + 2
                    })
                    Library:Corner(Item, UDim.new(0, 10))
                    Library:Themed(Item, "BackgroundColor3", "Ink")
                    Item.MouseEnter:Connect(function()
                        Library:Tween(Item, FAST, { BackgroundTransparency = Active and 0.8 or 0.93 })
                    end)
                    Item.MouseLeave:Connect(function()
                        Library:Tween(Item, FAST, { BackgroundTransparency = Active and 0.88 or 1 })
                    end)
                    if Active then
                        local Bar = New("Frame", {
                            Parent = Item,
                            AnchorPoint = Vector2.new(0, 0.5),
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 3, 0.5, 0),
                            Size = UDim2.fromOffset(3, 14),
                            ZIndex = Item.ZIndex + 1
                        })
                        Library:Corner(Bar, UDim.new(1, 0))
                        Library:Themed(Bar, "BackgroundColor3", "Ink")
                    end

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
                        ZIndex = (Handle and Handle.Frame and Handle.Frame.ZIndex or 202) + 3
                    })

                    if Active then
                        local Mark = IconLabel(Item, Library.Icons.Check, 14, "Ink")
                        Mark.AnchorPoint = Vector2.new(1, 0.5)
                        Mark.Position = UDim2.new(1, -8, 0.5, 0)
                        Mark.ZIndex = (Handle and Handle.Frame and Handle.Frame.ZIndex or 202) + 3
                        Library:Themed(Mark, "ImageColor3", "Ink")
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
    Library:Corner(Button, UDim.new(1, 0))
    Library:Themed(Button, "BackgroundColor3", "Inset")
    Library:Themed(Button, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(Button, 0.96)
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
        if Element.Locked or not (UserInputService.KeyboardEnabled or UserInputService.MouseEnabled) then
            return
        end
        Listening = true
        Button.Text = "..."
        Library:Feedback(1.2)
        Library:Tween(Line, FAST, { Color = Library.Theme.Ink, Transparency = 0.3 })

        local Connection
        Connection = UserInputService.InputBegan:Connect(function(Input, Typing)
            if Typing or not Device.IsKeyInput(Input) then
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

local function HueBar(Parent)
    local Bar = New("Frame", {
        Parent = Parent,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Active = true
    })
    Library:Corner(Bar, UDim.new(0, 9))
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
    Library:Corner(Box, UDim.new(0, 12))
    local White = New("Frame", {
        Parent = Box,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2
    })
    Library:Corner(White, UDim.new(0, 12))
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
    Library:Corner(Black, UDim.new(0, 12))
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
        Default = Color3.fromRGB(255, 255, 255),
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
    Library:Corner(Swatch, UDim.new(1, 0))
    Library:GlassEdge(Swatch, 1.2, 0.35)

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
        local Mobile = Section.Window.Mobile
        local Pw = Mobile and math.min(Device.Viewport().X - 24, 320) or 218
        local Ph = Mobile and 260 or 208
        Handle = Popup(Section.Window, Swatch, Pw, Ph)
        if Mobile and Handle and Handle.Frame then
            local Vp = Device.Viewport()
            Handle.Frame.Position = UDim2.fromOffset(math.floor((Vp.X - Pw) / 2), math.max(Vp.Y - Ph - 24, 40))
            Handle.Frame.AnchorPoint = Vector2.new(0, 0)
        end
        local Frame = Handle.Frame
        local BoxW = Mobile and (Pw - 50) or 160
        local BoxH = Mobile and 140 or 120

        local Box = SaturationBox(Frame)
        Box.Position = UDim2.fromOffset(12, 12)
        Box.Size = UDim2.fromOffset(BoxW, BoxH)
        Box.ZIndex = 103

        local Cursor = New("Frame", {
            Parent = Box,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(Mobile and 14 or 10, Mobile and 14 or 10),
            ZIndex = 6
        })
        Library:Corner(Cursor, UDim.new(1, 0))
        Library:Stroke(Cursor, "Stroke", 1.5)

        local Bar = HueBar(Frame)
        Bar.Position = UDim2.fromOffset(12 + BoxW + 8, 12)
        Bar.Size = UDim2.fromOffset(Mobile and 28 or 22, BoxH)
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

        local BottomY = 12 + BoxH + 12
        local HexBox = New("TextBox", {
            Parent = Frame,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12, BottomY),
            Size = UDim2.fromOffset(Mobile and BoxW - 70 or 120, Mobile and 34 or 30),
            Font = Library.Font.Mono,
            Text = "",
            TextSize = Library.TextSize(12, 1),
            ClearTextOnFocus = false,
            ZIndex = 103
        })
        Library:Corner(HexBox, UDim.new(1, 0))
        Library:Stroke(HexBox, "StrokeSoft", 1)
        Library:Themed(HexBox, "BackgroundColor3", "Inset")
        Library:Themed(HexBox, "BackgroundTransparency", "InsetAlpha")
        Library:Gloss(HexBox, 0.96)
        Library:Themed(HexBox, "TextColor3", "Text")

        local Preview = New("Frame", {
            Parent = Frame,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12 + (Mobile and BoxW - 58 or 128), BottomY),
            Size = UDim2.fromOffset(Mobile and 58 or 62, Mobile and 34 or 30),
            ZIndex = 103
        })
        Library:Corner(Preview, UDim.new(0, 10))
        Library:Stroke(Preview, "Stroke", 1)

        local Copy = PillButton(Frame, "Copy hex", Library.Icons.Copy, Mobile and (Pw - 24) or 194)
        Copy.Position = UDim2.fromOffset(12, BottomY + (Mobile and 42 or 36))
        Copy.Size = UDim2.fromOffset(Mobile and (Pw - 24) or 190, Mobile and 28 or 22)
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

function Components.ColorpickerRGB(Section, Config)
    Config = Merge({
        Title = "Color",
        Description = "",
        Default = Color3.fromRGB(255, 255, 255),
        Flag = nil,
        Callback = function() end
    }, Config)
    local Mobile = Section.Window.Mobile
    local BarH = Mobile and 18 or 14
    local Gap = Mobile and 6 or 4
    local BarsH = BarH * 3 + Gap * 2
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "ColorpickerRGB", Config.Title, Config.Description, 48 + BarsH, 40)
    local Preview = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0, 10),
        Size = UDim2.fromOffset(Mobile and 30 or 28, Mobile and 30 or 28),
        BackgroundColor3 = Config.Default
    })
    Library:Corner(Preview, UDim.new(1, 0))
    Library:GlassEdge(Preview, 1.4, 0.2)
    local Holder = Blank(Stack, {
        Size = UDim2.new(1, 0, 0, BarsH),
        LayoutOrder = 3
    })
    New("UIListLayout", {
        Parent = Holder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, Gap)
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
            Bar.Knob.Position = UDim2.fromScale(Channels[Name] / 255, 0.5)
            Bar.Label.Text = Name .. " " .. Channels[Name]
        end
        Element.Emit(Color, Silent)
    end
    Element = Finish(Section, "ColorpickerRGB", Config, Row, Handlers, TitleLabel, DescLabel)
    local Order = { "R", "G", "B" }
    for Index, Name in ipairs(Order) do
        local Line = Blank(Holder, { Size = UDim2.new(1, 0, 0, BarH), LayoutOrder = Index })
        local Text = New("TextLabel", {
            Parent = Line,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(Mobile and 52 or 44, BarH),
            Font = Library.Font.Bold,
            Text = Name .. " 0",
            TextSize = Library.TextSize(10, 1),
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Themed(Text, "TextColor3", "TextDim")
        local Track = New("Frame", {
            Parent = Line,
            AnchorPoint = Vector2.new(1, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(1, Mobile and -58 or -50, 0, Mobile and 10 or 8),
            Active = true
        })
        Library:Corner(Track, UDim.new(1, 0))
        Library:Themed(Track, "BackgroundColor3", "Track")
        Library:Themed(Track, "BackgroundTransparency", "TrackAlpha")
        local Fill = New("Frame", {
            Parent = Track,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = Name == "R" and Color3.fromRGB(255, 90, 90)
                or Name == "G" and Color3.fromRGB(90, 235, 130)
                or Color3.fromRGB(100, 160, 255)
        })
        Library:Corner(Fill, UDim.new(1, 0))
        New("UIGradient", {
            Parent = Fill,
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190))
        })
        local BarKnob = New("Frame", {
            Parent = Track,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(Mobile and 16 or 14, Mobile and 16 or 14),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 3
        })
        Library:Corner(BarKnob, UDim.new(1, 0))
        New("UIStroke", {
            Parent = BarKnob,
            Thickness = 2,
            Color = Fill.BackgroundColor3,
            Transparency = 0.45,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Bars[Name] = { Fill = Fill, Label = Text, Knob = BarKnob }
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
    if Measure then
        task.defer(Measure)
        task.delay(0.08, Measure)
    end
    Boot(Section, Config, Element, Config.Default)
    return Element
end
function Components.MultiButton(Section, Config)
    Config = Merge({
        Title = "Actions",
        Description = "",
        Buttons = {}
    }, Config)

    local Mobile = Section.Window.Mobile
    local List = Config.Buttons or {}
    local Count = math.max(#List, 1)
    local BtnH = Mobile and 36 or 32
    local Gap = 8
    local RowCount = math.ceil(Count / 2)
    local HolderH = RowCount * BtnH + math.max(RowCount - 1, 0) * Gap
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "MultiButton", Config.Title, Config.Description, 48 + HolderH, 0)
    Row.ClipsDescendants = false

    local Holder = Blank(Stack, {
        Size = UDim2.new(1, 0, 0, HolderH),
        LayoutOrder = 3,
        ZIndex = 4
    })
    New("UIListLayout", {
        Parent = Holder,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, Gap)
    })

    for RowIndex = 1, RowCount do
        local First = List[(RowIndex - 1) * 2 + 1]
        local Second = List[(RowIndex - 1) * 2 + 2]
        local Line = Blank(Holder, {
            Size = UDim2.new(1, 0, 0, BtnH),
            LayoutOrder = RowIndex,
            ZIndex = 5
        })
        if First and Second then
            local Left, LeftText = PillButton(Line, First.Title or First.Text or "Button", First.Icon, 0, First.Filled)
            Left.AnchorPoint = Vector2.new(0, 0)
            Left.Position = UDim2.new(0, 0, 0, 0)
            Left.Size = UDim2.new(0.5, -Gap * 0.5, 1, 0)
            Left.ZIndex = 6
            if LeftText then
                LeftText.TextSize = Library.TextSize(11, 1)
                LeftText.ZIndex = 7
            end
            Left.MouseButton1Click:Connect(function()
                if First.Callback then
                    task.spawn(First.Callback)
                end
            end)

            local Right, RightText = PillButton(Line, Second.Title or Second.Text or "Button", Second.Icon, 0, Second.Filled)
            Right.AnchorPoint = Vector2.new(1, 0)
            Right.Position = UDim2.new(1, 0, 0, 0)
            Right.Size = UDim2.new(0.5, -Gap * 0.5, 1, 0)
            Right.ZIndex = 6
            if RightText then
                RightText.TextSize = Library.TextSize(11, 1)
                RightText.ZIndex = 7
            end
            Right.MouseButton1Click:Connect(function()
                if Second.Callback then
                    task.spawn(Second.Callback)
                end
            end)
        elseif First then
            local Full, FullText = PillButton(Line, First.Title or First.Text or "Button", First.Icon, 0, First.Filled)
            Full.Size = UDim2.new(1, 0, 1, 0)
            Full.ZIndex = 6
            if FullText then
                FullText.TextSize = Library.TextSize(11, 1)
                FullText.ZIndex = 7
            end
            Full.MouseButton1Click:Connect(function()
                if First.Callback then
                    task.spawn(First.Callback)
                end
            end)
        end
    end
    if Measure then
        task.defer(Measure)
        task.delay(0.08, Measure)
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
    local Row, TitleLabel, Content, _, _, Measure = MakeRow(Section, "Paragraph", Config.Title, Body, 44, 0)
    if Content then
        Content.TextSize = Library.TextSize(12, 1)
    end
    local NoteBar = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0.5, 0),
        Size = UDim2.new(0, 3, 1, -4),
        BackgroundTransparency = 0.1
    })
    Library:Corner(NoteBar, UDim.new(1, 0))
    Library:Themed(NoteBar, "BackgroundColor3", "Ink")
    if Measure then
        task.defer(Measure)
        task.delay(0.08, Measure)
    end
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
    local Row, TitleLabel, DescLabel = MakeRow(Section, "Label", Config.Title, Config.Description, 38, Config.Icon and 34 or 20)
    if Config.Icon then
        local Chip = New("Frame", {
            Parent = Row,
            AnchorPoint = Vector2.new(1, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(28, 28),
            BackgroundTransparency = 0.82
        })
        Library:Corner(Chip, UDim.new(1, 0))
        Library:Themed(Chip, "BackgroundColor3", "Ink")
        local ChipLine = New("UIStroke", {
            Parent = Chip,
            Thickness = 1,
            Transparency = 0.6,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Library:Themed(ChipLine, "Color", "Ink")
        local Icon = IconLabel(Chip, Config.Icon, 15, "Ink")
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.Position = UDim2.fromScale(0.5, 0.5)
        Library:Themed(Icon, "ImageColor3", "Ink")
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
        Value = nil,
        Name = nil,
        Icon = nil,
        Color = nil
    }, Config)
    local TagName = Config.Name or Config.Value or "Beta"
    local TagColor = Config.Color
    if type(TagColor) == "table" and #TagColor >= 3 then
        TagColor = Color3.fromRGB(TagColor[1], TagColor[2], TagColor[3])
    end

    local Mobile = Section.Window.Mobile
    local PillH = Mobile and 26 or 22
    local Row, TitleLabel, DescLabel = MakeRow(Section, "Tag", Config.Title, Config.Description, 44, 100)

    local Pill = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(0, PillH),
        AutomaticSize = Enum.AutomaticSize.X
    })
    Library:Corner(Pill, UDim.new(1, 0))
    local PillLine = New("UIStroke", {
        Parent = Pill,
        Thickness = 1,
        Transparency = 0.55,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    if typeof(TagColor) == "Color3" then
        PillLine.Color = TagColor
    else
        Library:Themed(PillLine, "Color", "Ink")
    end
    if typeof(TagColor) == "Color3" then
        Pill.BackgroundColor3 = TagColor
    else
        Library:Themed(Pill, "BackgroundColor3", "Ink")
    end
    New("UIPadding", {
        Parent = Pill,
        PaddingLeft = UDim.new(0, Config.Icon and 6 or 9),
        PaddingRight = UDim.new(0, 9)
    })
    New("UIListLayout", {
        Parent = Pill,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local TagIcon
    if Config.Icon then
        TagIcon = IconLabel(Pill, Config.Icon, Mobile and 14 or 12, nil)
        TagIcon.Size = UDim2.fromOffset(Mobile and 14 or 12, Mobile and 14 or 12)
        TagIcon.LayoutOrder = 1
        if typeof(TagColor) == "Color3" then
            TagIcon.ImageColor3 = TagColor
        else
            Library:Themed(TagIcon, "ImageColor3", "Ink")
        end
    end

    local Text = New("TextLabel", {
        Parent = Pill,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, PillH),
        Font = Library.Font.Bold,
        Text = tostring(TagName),
        TextSize = Library.TextSize(11, 1),
        LayoutOrder = 2
    })
    if typeof(TagColor) == "Color3" then
        Text.TextColor3 = TagColor
    else
        Library:Themed(Text, "TextColor3", "Ink")
    end

    local Handlers = {}
    function Handlers.Get()
        return Text.Text
    end
    function Handlers.Set(Value)
        if type(Value) == "table" then
            if Value.Name or Value.Value then
                Text.Text = tostring(Value.Name or Value.Value)
            end
            if Value.Color then
                local Col = Value.Color
                if type(Col) == "table" then
                    Col = Color3.fromRGB(Col[1], Col[2], Col[3])
                end
                if typeof(Col) == "Color3" then
                    Pill.BackgroundColor3 = Col
                    Text.TextColor3 = Col
                    if TagIcon then
                        TagIcon.ImageColor3 = Col
                    end
                end
            end
            if Value.Icon and TagIcon then
                Library:SetIcon(TagIcon, Value.Icon)
            end
        else
            Text.Text = tostring(Value)
        end
    end

    return Finish(Section, "Tag", Config, Row, Handlers, TitleLabel, DescLabel)
end

function Components.Codeblock(Section, Config)
    Config = Merge({
        Title = "Code",
        Description = "",
        Code = "",
        Text = nil,
        Copy = true,
        Language = "lua"
    }, Config)
    local Body = tostring(Config.Text or Config.Code or "")
    local Row, TitleLabel, _, _, Stack, Measure = MakeRow(Section, "Codeblock", Config.Title, "", 72, 0)
    Row.ClipsDescendants = false
    local Block = New("Frame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3,
        ClipsDescendants = false,
        ZIndex = 4
    })
    Library:Corner(Block, UDim.new(0, 16))
    Library:Themed(Block, "BackgroundColor3", "Inset")
    Library:Themed(Block, "BackgroundTransparency", "InsetAlpha")
    Library:GlassEdge(Block, 1, 0.5)
    New("UIPadding", {
        Parent = Block,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12)
    })
    New("UIListLayout", {
        Parent = Block,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })

    -- header: traffic-light dots, language tag, copy button
    local Chrome = New("Frame", {
        Parent = Block,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 24),
        LayoutOrder = 1,
        ZIndex = 5
    })
    local Dots = New("Frame", {
        Parent = Chrome,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(46, 10),
        ZIndex = 5
    })
    New("UIListLayout", {
        Parent = Dots,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    for Index, DotColor in ipairs({ Color3.fromRGB(150, 150, 150), Color3.fromRGB(190, 190, 190), Color3.fromRGB(230, 230, 230) }) do
        local Dot = New("Frame", {
            Parent = Dots,
            BackgroundColor3 = DotColor,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(10, 10),
            LayoutOrder = Index,
            ZIndex = 6
        })
        Library:Corner(Dot, UDim.new(1, 0))
    end
    local LangTag = New("TextLabel", {
        Parent = Chrome,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 60, 0.5, 0),
        Size = UDim2.new(1, -100, 0, 14),
        Font = Library.Font.Bold,
        Text = string.upper(tostring(Config.Language or "lua")),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5
    })
    Library:Themed(LangTag, "TextColor3", "TextDisabled")
    local Rule = New("Frame", {
        Parent = Block,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0.9,
        LayoutOrder = 2,
        ZIndex = 5
    })
    Library:Themed(Rule, "BackgroundColor3", "Stroke")

    local Code = New("TextLabel", {
        Parent = Block,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Library.Font.Mono,
        Text = Body,
        TextSize = Library.TextSize(12, 1),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        RichText = false,
        LayoutOrder = 3,
        ZIndex = 5
    })
    Library:Themed(Code, "TextColor3", "Neutral")
    if not Library.Theme.Neutral then
        Library:Themed(Code, "TextColor3", "TextDim")
    end

    if Config.Copy then
        local CopyButton = New("TextButton", {
            Parent = Chrome,
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(28, 24),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 8
        })
        local CopyIcon = IconLabel(CopyButton, Library.Icons.Copy, 15, "TextDim")
        CopyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        CopyIcon.Position = UDim2.fromScale(0.5, 0.5)
        CopyIcon.ZIndex = 9
        CopyButton.MouseButton1Click:Connect(function()
            if Env.setclipboard then
                pcall(Env.setclipboard, Code.Text)
            end
            Library:SetIcon(CopyIcon, Library.Icons.Check, Library.Theme.Success)
            task.delay(1.2, function()
                Library:SetIcon(CopyIcon, Library.Icons.Copy, Library.Theme.TextDim)
            end)
        end)
    end

    if Measure then
        task.defer(Measure)
        task.delay(0.05, Measure)
        task.delay(0.2, Measure)
        Code:GetPropertyChangedSignal("TextBounds"):Connect(function()
            task.defer(Measure)
        end)
        Code:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            task.defer(Measure)
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
    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "Progress", Config.Title, Config.Description, 44, 60)
    local PercentChip = New("Frame", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(46, 22),
        BackgroundTransparency = 0.82
    })
    Library:Corner(PercentChip, UDim.new(1, 0))
    Library:Themed(PercentChip, "BackgroundColor3", "Ink")
    local PercentLine = New("UIStroke", {
        Parent = PercentChip,
        Thickness = 1,
        Transparency = 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(PercentLine, "Color", "Ink")
    local Percent = New("TextLabel", {
        Parent = PercentChip,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Library.Font.Bold,
        Text = "0%",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    Library:Themed(Percent, "TextColor3", "Ink")

    local Track = New("Frame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 8),
        LayoutOrder = 3
    })
    Library:Corner(Track, UDim.new(1, 0))
    Library:Themed(Track, "BackgroundColor3", "Track")
    Library:Themed(Track, "BackgroundTransparency", "TrackAlpha")
    local Fill = New("Frame", {
        Parent = Track,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1)
    })
    Library:Corner(Fill, UDim.new(1, 0))
    Library:Themed(Fill, "BackgroundColor3", "Ink")
    New("UIGradient", {
        Parent = Fill,
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190))
    })
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
    local Cols = math.max(Config.Columns or 3, 1)
    local Count = math.max(#Config.Items, 1)
    local Rows = math.ceil(Count / Cols)
    local CellH = Config.Height or 62
    local Gap = 6
    local GridH = Rows * CellH + math.max(Rows - 1, 0) * Gap
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "Grid", Config.Title, Config.Description, 44 + GridH, 0)
    local Holder = Blank(Stack, {
        Size = UDim2.new(1, 0, 0, GridH),
        LayoutOrder = 3,
        ClipsDescendants = true
    })
    local Layout = New("UIGridLayout", {
        Parent = Holder,
        CellPadding = UDim2.fromOffset(Gap, Gap),
        CellSize = UDim2.new(1 / Cols, -math.ceil(Gap * (Cols - 1) / Cols), 0, CellH),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirectionMaxCells = Cols
    })
    if Measure then
        task.defer(Measure)
        task.delay(0.08, Measure)
    end
    local API = {}
    local function AddItem(Info, Index)
        local Cell = New("TextButton", {
            Parent = Holder,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Index
        })
        Library:Corner(Cell, UDim.new(0, 16))
        Library:Themed(Cell, "BackgroundColor3", "Inset")
        Library:Themed(Cell, "BackgroundTransparency", "InsetAlpha")
        Library:Gloss(Cell, 0.95)
        local Line = Library:Stroke(Cell, "StrokeSoft", 1)
        if Info.Icon then
            local Chip = New("Frame", {
                Parent = Cell,
                AnchorPoint = Vector2.new(0.5, 0),
                BorderSizePixel = 0,
                Position = UDim2.new(0.5, 0, 0, 8),
                Size = UDim2.fromOffset(26, 26),
                BackgroundTransparency = 0.82
            })
            Library:Corner(Chip, UDim.new(1, 0))
            Library:Themed(Chip, "BackgroundColor3", "Ink")
            local ChipLine = New("UIStroke", {
                Parent = Chip,
                Thickness = 1,
                Transparency = 0.6,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            Library:Themed(ChipLine, "Color", "Ink")
            local Icon = IconLabel(Chip, Info.Icon, 15, "Ink")
            Icon.AnchorPoint = Vector2.new(0.5, 0.5)
            Icon.Position = UDim2.fromScale(0.5, 0.5)
            Library:Themed(Icon, "ImageColor3", "Ink")
        end
        local Text = New("TextLabel", {
            Parent = Cell,
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 1, -8),
            Size = UDim2.new(1, -8, 0, 14),
            Font = Library.Font.Medium,
            Text = Info.Title or Info.Text or "",
            TextSize = Library.TextSize(11, 1),
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
    if Measure then
        task.defer(Measure)
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
    local LineCount = (#Config.Columns > 0 and 1 or 0) + #Config.Rows
    local TableH = math.max(LineCount, 1) * 28
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "Table", Config.Title, Config.Description, 52 + TableH, 0)
    local Holder = New("Frame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3
    })
    Library:Corner(Holder, UDim.new(0, 16))
    Library:Themed(Holder, "BackgroundColor3", "Inset")
    Library:Themed(Holder, "BackgroundTransparency", "InsetAlpha")
    Library:Stroke(Holder, "StrokeSoft", 1)
    Library:Padding(Holder, 4, 4, 4, 4)
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
            BackgroundTransparency = Header and 0.8 or (Order % 2 == 0 and 0.95 or 1),
            LayoutOrder = Order
        })
        Library:Corner(LineFrame, Header and UDim.new(1, 0) or UDim.new(0, 12))
        Library:Themed(LineFrame, "BackgroundColor3", "Ink")
        local Count = math.max(#Values, 1)
        for Index, Value in ipairs(Values) do
            local Cell = New("TextLabel", {
                Parent = LineFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new((Index - 1) / Count, 8, 0, 0),
                Size = UDim2.new(1 / Count, -12, 1, 0),
                Font = Header and Library.Font.Bold or Library.Font.Regular,
                Text = tostring(Value),
                TextSize = Library.TextSize(11, 1),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
            Library:Themed(Cell, "TextColor3", Header and "Text" or "TextDim")
        end
        if Measure then
            task.defer(Measure)
        end
        return LineFrame
    end
    if #Config.Columns > 0 then
        Line(Config.Columns, true, 0)
    end
    for Index, Data in ipairs(Config.Rows) do
        Line(Data, false, Index)
    end
    if Measure then
        task.defer(Measure)
        task.delay(0.08, Measure)
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
        Corner = 16
    }, Config)
    local ImgH = Config.Height or 120
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "Image", Config.Title, Config.Description, 44 + ImgH, 0)
    local Picture = New("ImageLabel", {
        Parent = Stack,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        LayoutOrder = 3,
        Size = UDim2.new(1, 0, 0, ImgH),
        Image = Config.Image,
        ScaleType = Enum.ScaleType.Crop
    })
    Library:Corner(Picture, Config.Corner or 16)
    Library:GlassEdge(Picture, 1.1, 0.4)
    Library:Themed(Picture, "BackgroundColor3", "Inset")
    if Config.Ratio then
        New("UIAspectRatioConstraint", { Parent = Picture, AspectRatio = Config.Ratio })
    end
    if Measure then
        task.defer(Measure)
        task.delay(0.08, Measure)
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
        Corner = 16,
        Callback = function() end
    }, Config)
    local VpH = Config.Height or 180
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "Viewport", Config.Title, Config.Description, 44 + VpH, 0)
    local Frame = New("Frame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, VpH),
        LayoutOrder = 3,
        ClipsDescendants = true
    })
    if Measure then
        task.defer(Measure)
        task.delay(0.08, Measure)
    end
    Library:Corner(Frame, Config.Corner)
    Library:Themed(Frame, "BackgroundColor3", "Inset")
    Library:Themed(Frame, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(Frame, 0.96)
    Library:GlassEdge(Frame, 1.1, 0.4)
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
    local Models = New("Folder", { Parent = View, Name = "Models" })
    local HintIcon = IconLabel(Frame, "box", 20, "TextDisabled")
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

function Components.RangeSlider(Section, Config)
    Config = Merge({
        Title = "Range",
        Description = "",
        Min = 0,
        Max = 100,
        Increment = 1,
        Default = { 20, 80 },
        Flag = nil,
        Callback = function() end
    }, Config)
    local MinV, MaxV = Config.Min, Config.Max
    local Low = tonumber(Config.Default and Config.Default[1]) or MinV
    local High = tonumber(Config.Default and Config.Default[2]) or MaxV
    Low, High = Clamp(Low, MinV, MaxV), Clamp(High, MinV, MaxV)
    if Low > High then
        Low, High = High, Low
    end
    local RangeMobile = Section.Window.Mobile
    local RangeExtra = RangeMobile and ((Section.Window.Config and Section.Window.Config.Compact) and 4 or 10) or 0
    local RangeNeed = 20 + 17 + ((Config.Description or "") ~= "" and 17 or 0) + 3 + ((RangeMobile and 22 or 18) + 8)
    local Row, TitleLabel, DescLabel, _, Stack = MakeRow(Section, "RangeSlider", Config.Title, Config.Description, math.max(48, RangeNeed - RangeExtra), 90)
    local ValueLabel = New("TextLabel", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(80, 18),
        Font = Library.Font.Medium,
        Text = tostring(Low) .. " - " .. tostring(High),
        TextSize = Library.TextSize(11, 1),
        TextXAlignment = Enum.TextXAlignment.Right
    })
    Library:Themed(ValueLabel, "TextColor3", "TextDim")
    local ThumbSize = Section.Window.Mobile and 22 or 18
    local Pad = math.floor(ThumbSize / 2) + 4
    local Hit = New("Frame", {
        Parent = Stack,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, ThumbSize + 8),
        LayoutOrder = 3
    })
    local Track = New("Frame", {
        Parent = Hit,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -Pad * 2, 0, 8)
    })
    Library:Corner(Track, UDim.new(1, 0))
    Library:Themed(Track, "BackgroundColor3", "Track")
    Library:Themed(Track, "BackgroundTransparency", "TrackAlpha")
    local Fill = New("Frame", {
        Parent = Track,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0.5, 1)
    })
    Library:Corner(Fill, UDim.new(1, 0))
    Library:Themed(Fill, "BackgroundColor3", "Ink")
    New("UIGradient", {
        Parent = Fill,
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190))
    })
    local function Thumb()
        local T = New("TextButton", {
            Parent = Track,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(ThumbSize, ThumbSize),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 5
        })
        Library:Corner(T, UDim.new(1, 0))
        local Halo = New("UIStroke", {
            Parent = T,
            Thickness = 3,
            Transparency = 0.7,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Library:Themed(Halo, "Color", "Ink")
        return T
    end
    local T1, T2 = Thumb(), Thumb()
    local Element
    local function Paint()
        local Span = math.max(MaxV - MinV, 1e-6)
        local A = (Low - MinV) / Span
        local B = (High - MinV) / Span
        T1.Position = UDim2.fromScale(A, 0.5)
        T2.Position = UDim2.fromScale(B, 0.5)
        Fill.Position = UDim2.fromScale(A, 0)
        Fill.Size = UDim2.fromScale(math.max(B - A, 0), 1)
        ValueLabel.Text = tostring(Low) .. " - " .. tostring(High)
    end
    local function FromX(X)
        local Abs = Track.AbsolutePosition.X
        local Wd = math.max(Track.AbsoluteSize.X, 1)
        local Alpha = Clamp((X - Abs) / Wd, 0, 1)
        return Round(MinV + Alpha * (MaxV - MinV), Config.Increment)
    end
    local Active = nil
    local function Begin(Which)
        Active = Which
        Library:BeginDragLock()
    end
    local function End()
        if Active then
            Active = nil
            Library:EndDragLock()
        end
    end
    T1.InputBegan:Connect(function(I)
        if I.UserInputType == Enum.UserInputType.MouseButton1 or I.UserInputType == Enum.UserInputType.Touch then
            Begin(1)
        end
    end)
    T2.InputBegan:Connect(function(I)
        if I.UserInputType == Enum.UserInputType.MouseButton1 or I.UserInputType == Enum.UserInputType.Touch then
            Begin(2)
        end
    end)
    table.insert(Section.Window.Connections, UserInputService.InputChanged:Connect(function(I)
        if not Active then
            return
        end
        if I.UserInputType == Enum.UserInputType.MouseMovement or I.UserInputType == Enum.UserInputType.Touch then
            local V = FromX(I.Position.X)
            if Active == 1 then
                Low = Clamp(V, MinV, High)
            else
                High = Clamp(V, Low, MaxV)
            end
            Paint()
            Element.Emit({ Low, High })
        end
    end))
    table.insert(Section.Window.Connections, UserInputService.InputEnded:Connect(function(I)
        if I.UserInputType == Enum.UserInputType.MouseButton1 or I.UserInputType == Enum.UserInputType.Touch then
            End()
        end
    end))
    local Handlers = {}
    function Handlers.Get()
        return { Low, High }
    end
    function Handlers.Set(Value, Silent)
        if type(Value) == "table" then
            Low = Clamp(tonumber(Value[1]) or Low, MinV, MaxV)
            High = Clamp(tonumber(Value[2]) or High, MinV, MaxV)
            if Low > High then
                Low, High = High, Low
            end
            Paint()
            Element.Emit({ Low, High }, Silent)
        end
    end
    Element = Finish(Section, "RangeSlider", Config, Row, Handlers, TitleLabel, DescLabel)
    Paint()
    return Element
end
function Components.ToggleGroup(Section, Config)
    Config = Merge({
        Title = "Mode",
        Description = "",
        Options = { "A", "B", "C" },
        Default = nil,
        Flag = nil,
        Callback = function() end
    }, Config)
    local Options = Config.Options or {}
    local Selected = Config.Default or Options[1]
    local GroupMobile = Section.Window.Mobile
    local GroupExtra = GroupMobile and ((Section.Window.Config and Section.Window.Config.Compact) and 4 or 10) or 0
    local GroupNeed = 20 + 17 + ((Config.Description or "") ~= "" and 17 or 0) + 3 + (GroupMobile and 40 or 36)
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "ToggleGroup", Config.Title, Config.Description, math.max(48, GroupNeed - GroupExtra), 0)
    local Holder = New("Frame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Section.Window.Mobile and 40 or 36),
        LayoutOrder = 3
    })
    Library:Corner(Holder, UDim.new(1, 0))
    Library:Themed(Holder, "BackgroundColor3", "Inset")
    Library:Themed(Holder, "BackgroundTransparency", "InsetAlpha")
    Library:Stroke(Holder, "StrokeSoft", 1)
    Library:Padding(Holder, 3, 3, 3, 3)
    New("UIListLayout", {
        Parent = Holder,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local Buttons = {}
    local Element
    local function Paint()
        for Name, Btn in pairs(Buttons) do
            local On = Name == Selected
            Btn.BackgroundColor3 = Library.Theme.Ink
            Library:Tween(Btn, FAST, { BackgroundTransparency = On and 0.08 or 1 })
            local Lab = Btn:FindFirstChildOfClass("TextLabel")
            if Lab then
                Library:Tween(Lab, FAST, {
                    TextColor3 = On and Library.Theme.InkText or Library.Theme.TextDim
                })
            end
        end
    end
    for Index, Opt in ipairs(Options) do
        local Name = tostring(Opt)
        local Btn = New("TextButton", {
            Parent = Holder,
            BorderSizePixel = 0,
            Size = UDim2.new(1 / #Options, -2, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Index
        })
        Library:Corner(Btn, UDim.new(1, 0))
        New("UIGradient", {
            Parent = Btn,
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 196, 196))
        })
        local Lab = New("TextLabel", {
            Parent = Btn,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = Library.Font.Medium,
            Text = Name,
            TextSize = Library.TextSize(12, 1)
        })
        Buttons[Name] = Btn
        Btn.MouseButton1Click:Connect(function()
            Selected = Name
            Paint()
            Element.Emit(Selected)
            Library:Feedback(1.05)
        end)
    end
    local Handlers = {}
    function Handlers.Get()
        return Selected
    end
    function Handlers.Set(Value, Silent)
        if Value ~= nil then
            Selected = tostring(Value)
            Paint()
            Element.Emit(Selected, Silent)
        end
    end
    Element = Finish(Section, "ToggleGroup", Config, Row, Handlers, TitleLabel, DescLabel)
    Paint()
    Library.OnThemeChanged:Connect(Paint)
    if Measure then
        task.defer(Measure)
    end
    return Element
end

function Components.FilePicker(Section, Config)
    Config = Merge({
        Title = "Files",
        Description = "",
        Folder = nil,
        Extension = ".json",
        Flag = nil,
        Callback = function() end
    }, Config)
    local Folder = Config.Folder or (Section.Window.Paths and Section.Window.Paths.Configs) or "sh1ttybanana"
    local FileMobile = Section.Window.Mobile
    local FileExtra = FileMobile and ((Section.Window.Config and Section.Window.Config.Compact) and 4 or 10) or 0
    local FileNeed = 20 + 17 + ((Config.Description or "") ~= "" and 17 or 0) + 3 + 104
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "FilePicker", Config.Title, Config.Description, math.max(80, FileNeed - FileExtra), 0)
    local List = New("ScrollingFrame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 104),
        LayoutOrder = 3,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Library:Corner(List, UDim.new(0, 16))
    Library:Themed(List, "BackgroundColor3", "Inset")
    Library:Themed(List, "BackgroundTransparency", "InsetAlpha")
    Library:Stroke(List, "StrokeSoft", 1)
    Library:StyleScroll(List)
    Library:Padding(List, 5, 5, 5, 5)
    New("UIListLayout", {
        Parent = List,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })
    local Selected, Element
    local Entries = {}
    local function PaintFiles()
        for Name, Entry in pairs(Entries) do
            local On = Name == Selected
            Entry.Item.BackgroundColor3 = On and Library.Theme.Ink or Library.Theme.Inset
            Library:Tween(Entry.Item, FAST, { BackgroundTransparency = On and 0.8 or Library.Theme.InsetAlpha })
            Library:Tween(Entry.Label, FAST, { TextColor3 = On and Library.Theme.Ink or Library.Theme.TextDim })
            Library:Tween(Entry.Line, FAST, { Color = On and Library.Theme.Ink or Library.Theme.StrokeSoft, Transparency = On and 0.45 or Library.Theme.StrokeSoftAlpha })
            Entry.Icon.ImageColor3 = On and Library.Theme.Ink or Library.Theme.TextDisabled
        end
    end
    local function Refresh()
        for _, Child in ipairs(List:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
        table.clear(Entries)
        local Files = FS.List(Folder)
        local Order = 0
        for _, Path in ipairs(Files) do
            local Name = tostring(Path):match("([^/\\]+)$") or tostring(Path)
            if not Config.Extension or Name:sub(-#Config.Extension) == Config.Extension or Config.Extension == "" then
                Order = Order + 1
                local Item = New("TextButton", {
                    Parent = List,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -4, 0, 30),
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = Order
                })
                Library:Corner(Item, UDim.new(1, 0))
                Library:Themed(Item, "BackgroundColor3", "Inset")
                Library:Themed(Item, "BackgroundTransparency", "InsetAlpha")
                local ItemLine = Library:Stroke(Item, "StrokeSoft", 1)
                local FileIcon = IconLabel(Item, Library.Icons.Folder, 14, "TextDisabled")
                FileIcon.AnchorPoint = Vector2.new(0, 0.5)
                FileIcon.Position = UDim2.new(0, 12, 0.5, 0)
                local Lab = New("TextLabel", {
                    Parent = Item,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 34, 0, 0),
                    Size = UDim2.new(1, -46, 1, 0),
                    Font = Library.Font.Medium,
                    Text = Name,
                    TextSize = Library.TextSize(11, 1),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                Library:Themed(Lab, "TextColor3", "TextDim")
                Entries[Name] = { Item = Item, Label = Lab, Line = ItemLine, Icon = FileIcon }
                Item.MouseButton1Click:Connect(function()
                    Selected = Name
                    PaintFiles()
                    Element.Emit(Name)
                    Library:Feedback(1.05)
                end)
            end
        end
        PaintFiles()
        if Measure then
            task.defer(Measure)
        end
    end
    Refresh()
    local Handlers = {}
    function Handlers.Get()
        return Selected
    end
    function Handlers.Set(Value, Silent)
        Selected = Value and tostring(Value) or nil
        PaintFiles()
        Element.Emit(Selected, Silent)
    end
    Element = Finish(Section, "FilePicker", Config, Row, Handlers, TitleLabel, DescLabel)
    function Element:Refresh()
        Refresh()
    end
    return Element
end
function Components.ConfirmToggle(Section, Config)
    Config = Merge({
        Title = "Confirm Toggle",
        Description = "",
        Default = false,
        ConfirmOn = true,
        ConfirmOff = false,
        ConfirmTitle = "Confirm",
        ConfirmContent = "Are you sure?",
        Flag = nil,
        Callback = function() end
    }, Config)
    local State = Config.Default and true or false
    local Mobile = Section.Window.Mobile
    local Row, TitleLabel, DescLabel = MakeRow(Section, "ConfirmToggle", Config.Title, Config.Description, 46, 50)

    local TrackW, TrackH = Mobile and 54 or 44, Mobile and 30 or 24
    local KnobSize = TrackH - 6

    local Switch = New("TextButton", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(TrackW, TrackH),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 2
    })
    Library:Corner(Switch, UDim.new(1, 0))
    Switch.BackgroundColor3 = Library.Theme.Track or Color3.fromRGB(96, 96, 96)
    Switch.BackgroundTransparency = Library.Theme.TrackAlpha or 0.35
    local SwitchLine = Library:Stroke(Switch, "StrokeSoft", 1)

    local Knob = New("Frame", {
        Parent = Switch,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(KnobSize, KnobSize),
        BackgroundColor3 = Color3.fromRGB(210, 210, 210),
        ZIndex = 3
    })
    Library:Corner(Knob, UDim.new(1, 0))
    New("UIStroke", {
        Parent = Knob,
        Thickness = 1,
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.82,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })

    local Element
    local function Paint(Animated)
        local Info = Animated and TweenInfo.new(0.26, Quint, Out) or TweenInfo.new(0)
        local Theme = Library.Theme
        Library:Tween(Knob, Info, {
            Position = UDim2.new(0, State and (TrackW - KnobSize - 3) or 3, 0.5, 0),
            BackgroundColor3 = State and Library.Theme.InkText or Color3.fromRGB(210, 210, 210)
        })
        Library:Tween(Switch, Info, {
            BackgroundColor3 = State and Theme.Ink or (Theme.Track or Color3.fromRGB(96, 96, 96)),
            BackgroundTransparency = State and 0.05 or (Theme.TrackAlpha or 0.35)
        })
        Library:Tween(SwitchLine, Info, {
            Color = State and Theme.Ink or Theme.StrokeSoft,
            Transparency = State and 0.3 or Theme.StrokeSoftAlpha
        })
    end
    local function Apply(NewState, Silent)
        State = NewState and true or false
        Paint(not Silent)
        Element.Emit(State, Silent)
    end
    local function Request(NewState)
        local Need = (NewState and Config.ConfirmOn) or ((not NewState) and Config.ConfirmOff)
        if not Need then
            Apply(NewState)
            return
        end
        Section.Window.API:Dialog({
            Title = Config.ConfirmTitle,
            Content = Config.ConfirmContent,
            Buttons = {
                { Title = "Cancel" },
                { Title = "Confirm", Filled = true, Callback = function()
                    Apply(NewState)
                end }
            }
        })
    end
    Switch.MouseButton1Click:Connect(function()
        Request(not State)
    end)
    local Handlers = {}
    function Handlers.Get()
        return State
    end
    function Handlers.Set(Value, Silent)
        Apply(Value and true or false, Silent)
    end
    Element = Finish(Section, "ConfirmToggle", Config, Row, Handlers, TitleLabel, DescLabel)
    Library.OnThemeChanged:Connect(function()
        Paint(false)
    end)
    Paint(false)
    return Element
end

function Components.Hotbar(Section, Config)
    Config = Merge({
        Title = "Quick Actions",
        Description = "",
        Items = {}
    }, Config)
    local HotMobile = Section.Window.Mobile
    local HotExtra = HotMobile and ((Section.Window.Config and Section.Window.Config.Compact) and 4 or 10) or 0
    local HotNeed = 20 + 17 + ((Config.Description or "") ~= "" and 17 or 0) + 3 + 40
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "Hotbar", Config.Title, Config.Description, math.max(56, HotNeed - HotExtra), 0)
    local Holder = Blank(Stack, {
        Size = UDim2.new(1, 0, 0, 40),
        LayoutOrder = 3
    })
    New("UIListLayout", {
        Parent = Holder,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    for Index, Info in ipairs(Config.Items or {}) do
        local Btn = New("TextButton", {
            Parent = Holder,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(40, 36),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Index
        })
        Library:Corner(Btn, UDim.new(0, 14))
        Library:Themed(Btn, "BackgroundColor3", "Inset")
        Library:Themed(Btn, "BackgroundTransparency", "InsetAlpha")
        local BtnLine = Library:Stroke(Btn, "StrokeSoft", 1)
        Library:Gloss(Btn, 0.95)
        Library:Hover(Btn, BtnLine, "Transparency", Library.Theme.StrokeSoftAlpha, 0.35)
        if Info.Icon then
            local Ic = IconLabel(Btn, Info.Icon, 18, "Ink")
            Ic.AnchorPoint = Vector2.new(0.5, 0.5)
            Ic.Position = UDim2.fromScale(0.5, 0.5)
            Library:Themed(Ic, "ImageColor3", "Ink")
        end
        if Info.Tip then
            Btn:SetAttribute("Tip", Info.Tip)
        end
        Btn.MouseButton1Click:Connect(function()
            Library:Feedback(1.1)
            if Info.Callback then
                task.spawn(Info.Callback)
            end
        end)
    end
    if Measure then
        task.defer(Measure)
    end
    local Handlers = { Get = function() end, Set = function() end }
    return Finish(Section, "Hotbar", Config, Row, Handlers, TitleLabel, DescLabel)
end


function Components.PlayerSelector(Section, Config)
    Config = Merge({
        Title = "Player",
        Description = "",
        ExcludeSelf = true,
        Flag = nil,
        Callback = function() end
    }, Config)
    local Selected = nil
    local Options = {}
    local function RefreshList()
        table.clear(Options)
        for _, Plr in ipairs(Players:GetPlayers()) do
            if not (Config.ExcludeSelf and Plr == LocalPlayer) then
                table.insert(Options, Plr.Name)
            end
        end
        table.sort(Options)
    end
    RefreshList()
    local Element = Components.Dropdown(Section, {
        Title = Config.Title,
        Description = Config.Description or "Select a player",
        Options = Options,
        Default = Options[1],
        Search = true,
        Flag = Config.Flag,
        Callback = function(V)
            Selected = V
            if Config.Callback then
                Config.Callback(V, Players:FindFirstChild(tostring(V)))
            end
        end
    })
    function Element:Refresh()
        RefreshList()
        Element:SetOptions(Options)
    end
    local RefreshBtn = New("TextButton", {
        Parent = Element.Frame,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(26, 26),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 6
    })
    -- sit just left of the dropdown field
    local FieldWidth = 0
    for _, Child in ipairs(Element.Frame:GetChildren()) do
        if Child:IsA("TextButton") and Child ~= RefreshBtn and Child.AnchorPoint.X == 1 then
            FieldWidth = math.max(FieldWidth, Child.Size.X.Offset)
        end
    end
    RefreshBtn.Position = UDim2.new(1, -(14 + FieldWidth + 6), 0.5, 0)
    Library:Corner(RefreshBtn, UDim.new(1, 0))
    Library:Themed(RefreshBtn, "BackgroundColor3", "Row")
    Library:Themed(RefreshBtn, "BackgroundTransparency", "ButtonAlpha")
    local RefreshLine = Library:Stroke(RefreshBtn, "StrokeSoft", 1)
    local Ric = IconLabel(RefreshBtn, Library.Icons.Refresh, 14, "TextDim")
    Ric.Size = UDim2.fromOffset(14, 14)
    Ric.AnchorPoint = Vector2.new(0.5, 0.5)
    Ric.Position = UDim2.fromScale(0.5, 0.5)
    Library:Hover(RefreshBtn, RefreshLine, "Transparency", Library.Theme.StrokeSoftAlpha, 0.35)
    RefreshBtn.MouseButton1Click:Connect(function()
        Element:Refresh()
        Library:Feedback(1.05)
        Ric.Rotation = 0
        Library:Tween(Ric, TweenInfo.new(0.5, Quart, Out), { Rotation = 360 })
    end)
    return Element
end
function Components.LogConsole(Section, Config)
    Config = Merge({
        Title = "Console",
        Description = "",
        MaxLines = 80,
        Height = 120,
        Timestamps = true
    }, Config)
    local Mobile = Section.Window.Mobile
    local H = Mobile and math.max(Config.Height, 140) or Config.Height
    local Row, TitleLabel, DescLabel, _, Stack, Measure = MakeRow(Section, "LogConsole", Config.Title, Config.Description, 48 + H, 0)
    local Frame = New("ScrollingFrame", {
        Parent = Stack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, H),
        LayoutOrder = 3,
        ZIndex = 3,
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 3
    })
    Library:Corner(Frame, UDim.new(0, 16))
    Library:GlassEdge(Frame, 1, 0.5)
    Library:Themed(Frame, "BackgroundColor3", "Inset")
    Library:Themed(Frame, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(Frame, 0.96)
    Library:StyleScroll(Frame)
    local Layout = New("UIListLayout", {
        Parent = Frame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })
    New("UIPadding", { Parent = Frame, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
    local Lines, Order = {}, 0
    local Colors = {
        info = "TextDim",
        warn = "Warn",
        error = "Error",
        success = "Success"
    }
    local function Push(Text, Level)
        Order = Order + 1
        Level = (Level or "info"):lower()
        local Lab = New("TextLabel", {
            Parent = Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Library.Font.Mono,
            Text = (Config.Timestamps ~= false and (os.date("%H:%M:%S") .. "  ") or "") .. tostring(Text),
            TextSize = Library.TextSize(11, 1),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = Order
        })
        Library:Themed(Lab, "TextColor3", Colors[Level] or "TextDim")
        table.insert(Lines, Lab)
        while #Lines > (Config.MaxLines or 80) do
            local Old = table.remove(Lines, 1)
            if Old then Old:Destroy() end
        end
        task.defer(function()
            Frame.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 12)
            Frame.CanvasPosition = Vector2.new(0, math.max(Layout.AbsoluteContentSize.Y - Frame.AbsoluteSize.Y, 0))
        end)
        if Measure then task.defer(Measure) end
    end
    local Handlers = {
        Get = function() return #Lines end,
        Set = function() end
    }
    local Element = Finish(Section, "LogConsole", Config, Row, Handlers, TitleLabel, DescLabel)
    function Element:Log(Text, Level) Push(Text, Level) return Element end
    function Element:Clear()
        for _, L in ipairs(Lines) do L:Destroy() end
        table.clear(Lines)
        return Element
    end
    function Element:Copy()
        local Buf = {}
        for _, L in ipairs(Lines) do table.insert(Buf, L.Text) end
        if Env.setclipboard then pcall(Env.setclipboard, table.concat(Buf, "\n")) end
        return Element
    end
    if Measure then task.defer(Measure) end
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
    New("UIGradient", {
        Parent = LeftLine,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

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
        ZIndex = 210 + #W.Modals * 4
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
    Library:Corner(Card, UDim.new(0, 18))
    Library:Themed(Card, "BackgroundColor3", "Elevated")
    Library:Themed(Card, "BackgroundTransparency", "ElevatedAlpha")
    Library:GlassEdge(Card, 1.2, 0.3)
    Library:Shadow(Card, 70, 0.55)
    Library:Sheen(Card, 90).ZIndex = Card.ZIndex

    local Header = Blank(Card, {
        Size = UDim2.new(1, 0, 0, 46),
        ZIndex = Card.ZIndex + 1
    })

    local TitleLeft = 16
    if Config.Icon then
        local Icon = IconLabel(Header, Config.Icon, 18, "Ink")
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.Position = UDim2.new(0, 16, 0.5, 0)
        Icon.ZIndex = Card.ZIndex + 2
        Library:Themed(Icon, "ImageColor3", "Ink")
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

    if Config.Headerless then
        Header.Visible = false
        Body.Position = UDim2.new(0, 18, 0, 18)
        Body.Size = UDim2.new(1, -36, 1, -36)
    end

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
        local Shrink = New("UIScale", { Parent = Card, Scale = 1 })
        Library:Tween(Shrink, FAST, { Scale = 0.95 })
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

    Library:Tween(Backdrop, NORMAL, { BackgroundTransparency = 0.45 })
    Library:Pop(Card, 0.4, 0.88)
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

local DialogIcons = {
    Info = "info",
    Success = "circle-check",
    Warn = "triangle-alert",
    Danger = "octagon-alert",
    Question = "circle-help"
}

function WM.Dialog(W, Config)
    Config = Merge({
        Title = "Dialog",
        Description = "",
        Content = nil,
        Buttons = {},
        Type = "Info",
        Input = nil,
        Persistent = false,
        Width = 380
    }, Config or {})

    local Mobile = W.Mobile
    local Kind = DialogIcons[Config.Type] and Config.Type or "Info"
    local MainSize = W.Main.AbsoluteSize / math.max(W.Scale.Scale, 0.001)
    local Width = math.max(math.min(Config.Width, MainSize.X - 28), 200)

    local Handle = WM.Modal(W, {
        Title = Config.Title,
        Width = Width,
        Height = 200,
        Headerless = true,
        Persistent = Config.Persistent
    })

    local Layout = New("UIListLayout", {
        Parent = Handle.Body,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })

    local Tile = New("Frame", {
        Parent = Handle.Body,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(48, 48),
        LayoutOrder = 1
    })
    Library:Corner(Tile, UDim.new(1, 0))
    local Filled = Kind == "Danger" or Kind == "Warn"
    if Filled then
        Library:Themed(Tile, "BackgroundColor3", "Ink")
        Tile.BackgroundTransparency = Kind == "Danger" and 0.04 or 0.14
    else
        Library:Themed(Tile, "BackgroundColor3", "Row")
        Library:Themed(Tile, "BackgroundTransparency", "RowAlpha")
        Library:GlassEdge(Tile, 1, 0.55)
    end
    local TileIcon = IconLabel(Tile, DialogIcons[Kind], 24, Filled and "InkText" or "Ink")
    TileIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    TileIcon.Position = UDim2.fromScale(0.5, 0.5)
    task.defer(function()
        if Tile.Parent then
            Library:Pop(TileIcon, 0.5, 0.4)
        end
    end)

    local Title = New("TextLabel", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Library.Font.Bold,
        Text = Config.Title,
        TextSize = Mobile and 17 or 16,
        TextWrapped = true,
        LayoutOrder = 2
    })
    Library:Themed(Title, "TextColor3", "Text")

    local Message = tostring(Config.Content or Config.Description or "")
    if Message ~= "" then
        local Text = New("TextLabel", {
            Parent = Handle.Body,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Library.Font.Regular,
            Text = Message,
            TextSize = Mobile and 13 or 12,
            TextWrapped = true,
            RichText = true,
            LayoutOrder = 3
        })
        Library:Themed(Text, "TextColor3", "TextDim")
    end

    local Box
    if type(Config.Input) == "table" then
        local Field = New("Frame", {
            Parent = Handle.Body,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, Mobile and 40 or 36),
            LayoutOrder = 4
        })
        Library:Corner(Field, UDim.new(0, 12))
        Library:Themed(Field, "BackgroundColor3", "Inset")
        Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
        local Line = Library:Stroke(Field, "StrokeSoft", 1)
        Box = New("TextBox", {
            Parent = Field,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -24, 1, 0),
            Font = Library.Font.Regular,
            PlaceholderText = Config.Input.Placeholder or "",
            Text = Config.Input.Default or "",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false
        })
        Library:Themed(Box, "TextColor3", "Text")
        Library:Themed(Box, "PlaceholderColor3", "TextDisabled")
        Box.Focused:Connect(function()
            Library:Tween(Line, FAST, { Transparency = 0.3 })
        end)
        Box.FocusLost:Connect(function()
            Library:Tween(Line, FAST, { Transparency = Library.Theme.StrokeSoftAlpha })
        end)
    end

    local Buttons = {}
    for _, Info in ipairs(Config.Buttons) do
        table.insert(Buttons, Info)
    end
    if #Buttons == 0 then
        Buttons[1] = { Title = "Ok", Filled = true }
    end
    local Stacked = Mobile or #Buttons > 2 or Width < 300

    local Footer = New("Frame", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 5
    })
    New("UIPadding", { Parent = Footer, PaddingTop = UDim.new(0, 6) })
    New("UIListLayout", {
        Parent = Footer,
        FillDirection = Stacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local Ordered = table.clone(Buttons)
    if Stacked then
        table.sort(Ordered, function(A, B)
            return (A.Filled and 1 or 0) > (B.Filled and 1 or 0)
        end)
    end
    local Height = Mobile and 42 or 36
    for Index, Info in ipairs(Ordered) do
        local Button = PillButton(Footer, Info.Text or Info.Title or "Ok", Info.Icon, 110, Info.Filled)
        Button.LayoutOrder = Index
        if Stacked then
            Button.Size = UDim2.new(1, 0, 0, Height)
        else
            Button.Size = UDim2.new(1 / #Ordered, -(8 * (#Ordered - 1)) / #Ordered, 0, Height)
        end
        Button.MouseButton1Click:Connect(function()
            local Value = Box and Box.Text or nil
            Handle:Close()
            if Info.Callback then
                task.spawn(Info.Callback, Value)
            end
        end)
    end

    local function Resize()
        local Wanted = Layout.AbsoluteContentSize.Y + 36
        Handle.Frame.Size = UDim2.fromOffset(Width, math.min(Wanted, MainSize.Y - 24))
    end
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Resize)
    task.defer(Resize)

    return Handle
end

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
    Library:Corner(Field, UDim.new(0, 12))
    Library:Themed(Field, "BackgroundColor3", "Inset")
    Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(Field, 0.96)
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

    local Busy = false
    local function Submit()
        if Busy then
            return
        end
        Busy = true
        Error.Text = "verifying..."
        local Value = Trim(Box.Text)
        local Called, Ok, Message = pcall(Config.Callback, Value)
        Busy = false
        if not Called then
            Error.Text = "something went wrong"
            return
        end
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
    local Verify = Config.Verify or Library.Auth.Resolve(Config)
    WM.Prompt(W, {
        Title = Config.Title or "Locked",
        Description = Config.Description or "Enter your key to unlock",
        Placeholder = Config.Placeholder or "key",
        Icon = Library.Icons.Lock,
        Confirm = Config.Confirm or "Unlock",
        Callback = function(Value)
            if Value == "" then
                return false, "enter a key"
            end
            local Ok, Message, Payload = Verify(Value, { Id = Config.Key, Window = W })
            if not Ok then
                return false, Message or "access denied"
            end
            if Config.Remember and Config.Key then
                Library.Auth.Remember(W, Config.Key, tonumber(Config.RememberMinutes) or 10)
            end
            if Config.OnUnlock then
                task.spawn(Config.OnUnlock, Payload)
            end
            return true
        end
    })
end

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
        Library:Corner(Item, UDim.new(0, 12))
        if Active then
            Library:Themed(Item, "BackgroundColor3", "Ink")
        else
            Library:Themed(Item, "BackgroundColor3", "Row")
            Library:Themed(Item, "BackgroundTransparency", "RowAlpha")
        end
        Library:Stroke(Item, "StrokeSoft", 1)

        local Icon = IconLabel(Item, Active and Library.Icons.Check or Library.Icons.Folder, 15, Active and "Ink" or "TextDisabled")
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
                        Filled = true,
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
    NewButton.Size = UDim2.new(1 / 3, -6, 0, 30)
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

    local CopyButton = PillButton(Footer, "Copy JSON", Library.Icons.Copy, 170)
    CopyButton.Size = UDim2.new(1 / 3, -6, 0, 30)
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

    local ImportButton = PillButton(Footer, "Import JSON", Library.Icons.Folder, 130)
    ImportButton.Size = UDim2.new(1 / 3, -6, 0, 30)
    ImportButton.LayoutOrder = 3
    ImportButton.ZIndex = Handle.Frame.ZIndex + 3
    ImportButton.MouseButton1Click:Connect(function()
        WM.Prompt(W, {
            Title = "Import config JSON",
            Placeholder = "Paste config JSON here",
            Confirm = "Import",
            Callback = function(Text)
                local Ok, Data = pcall(HttpService.JSONDecode, HttpService, Text)
                if not Ok or type(Data) ~= "table" then
                    W.API:Notify({ Title = "Import failed", Content = "Invalid JSON", Type = "Error" })
                    return
                end
                W.API:SetConfig(Data)
                W.API:Notify({ Title = "Imported", Content = "Config applied", Type = "Success" })
                Refresh()
            end
        })
    end)

    for _, Button in ipairs({ NewButton, CopyButton, ImportButton }) do
        for _, Child in ipairs(Button:GetDescendants()) do
            if Child:IsA("GuiObject") then
                Child.ZIndex = Button.ZIndex + 1
            end
        end
    end

    Refresh()
    return Handle
end

function WM.About(W)
    local Exec = "unknown"
    if Env.identifyexecutor then
        local Ok, N = pcall(Env.identifyexecutor)
        if Ok and N then Exec = tostring(N) end
    end
    local Handle = WM.Modal(W, {
        Title = "About",
        Description = (W.Config.Title or "NexxWare") .. " · " .. tostring(W.Config.Version or Library.Version),
        Icon = Library.Icons.Info,
        Width = 400,
        Height = 260
    })
    local Lines = {
        "Library: sh1ttybanana " .. tostring(Library.Version),
        "Watermark: " .. tostring(W.Config.WatermarkText or ""),
        "Executor: " .. Exec,
        "Device: " .. (Device.IsMobile() and "Mobile" or "Desktop"),
        "User: " .. (LocalPlayer.Name or "?"),
        "Theme: " .. tostring(Library.CurrentTheme),
        "Flags: " .. tostring((function() local n=0 for _ in pairs(W.Flags) do n=n+1 end return n end)()),
    }
    for i, Text in ipairs(Lines) do
        local L = New("TextLabel", {
            Parent = Handle.Body,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, (i - 1) * 22),
            Size = UDim2.new(1, 0, 0, 20),
            Font = Library.Font.Medium,
            Text = Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = Handle.Frame.ZIndex + 2
        })
        Library:Themed(L, "TextColor3", "TextDim")
    end
end

function WM.ThemePanel(W)
    local Handle = WM.Modal(W, {
        Title = "Appearance",
        Description = "Glass, motion and background",
        Icon = Library.Icons.Palette,
        Width = 440,
        Height = 430
    })
    local Z = Handle.Frame.ZIndex + 2

    local Scroll = New("ScrollingFrame", {
        Parent = Handle.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 4),
        Size = UDim2.new(1, 0, 1, -8),
        ZIndex = Z
    })
    Library:StyleScroll(Scroll)
    New("UIPadding", {
        Parent = Scroll,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 6)
    })
    New("UIListLayout", {
        Parent = Scroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })

    local Order = 0
    local function Caption(Text)
        Order = Order + 1
        local Item = New("TextLabel", {
            Parent = Scroll,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = Library.Font.Bold,
            Text = string.upper(Text),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = Order,
            ZIndex = Z + 1
        })
        Library:Themed(Item, "TextColor3", "TextDisabled")
    end

    local function Row(Height)
        Order = Order + 1
        local Item = New("Frame", {
            Parent = Scroll,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, Height or 40),
            LayoutOrder = Order,
            ZIndex = Z + 1
        })
        Library:Corner(Item, UDim.new(0, 12))
        Library:Themed(Item, "BackgroundColor3", "Row")
        Library:Themed(Item, "BackgroundTransparency", "RowAlpha")
        Library:Stroke(Item, "StrokeSoft", 1)
        return Item
    end

    local function RowLabel(Parent, Text, Width)
        local Item = New("TextLabel", {
            Parent = Parent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(Width or 1, -24, 1, 0),
            Font = Library.Font.Medium,
            Text = Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = Z + 2
        })
        Library:Themed(Item, "TextColor3", "Text")
        return Item
    end

    local function Switch(Text, Getter, Setter)
        local Item = Row(40)
        RowLabel(Item, Text, 0.7)
        local Click = New("TextButton", {
            Parent = Item,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            AutoButtonColor = false,
            ZIndex = Z + 4
        })
        local Pill = New("Frame", {
            Parent = Item,
            AnchorPoint = Vector2.new(1, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(38, 22),
            ZIndex = Z + 2
        })
        Library:Corner(Pill, UDim.new(1, 0))
        local Knob = New("Frame", {
            Parent = Pill,
            AnchorPoint = Vector2.new(0, 0.5),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(16, 16),
            ZIndex = Z + 3
        })
        Library:Corner(Knob, UDim.new(1, 0))
        local function Paint(Animated)
            local On = Getter()
            local Info = Animated and SPRING or TweenInfo.new(0)
            Library:Tween(Pill, Info, {
                BackgroundColor3 = On and Library.Theme.Ink or Library.Theme.Track,
                BackgroundTransparency = On and 0.05 or Library.Theme.TrackAlpha
            })
            Library:Tween(Knob, Info, {
                Position = UDim2.new(0, On and 19 or 3, 0.5, 0),
                BackgroundColor3 = On and Library.Theme.InkText or Library.Theme.Text
            })
        end
        Click.MouseButton1Click:Connect(function()
            Setter(not Getter())
            Paint(true)
            Library:Feedback(1.1)
            W.SaveState()
        end)
        Paint(false)
    end

    local function Slider(Text, Min, Max, Getter, Setter, Format)
        local Item = Row(54)
        RowLabel(Item, Text, 0.6).Position = UDim2.new(0, 12, 0, 6)
        Item:FindFirstChildOfClass("TextLabel").Size = UDim2.new(0.6, -24, 0, 20)
        local Value = New("TextLabel", {
            Parent = Item,
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -12, 0, 6),
            Size = UDim2.fromOffset(60, 20),
            Font = Library.Font.Medium,
            Text = Format(Getter()),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = Z + 2
        })
        Library:Themed(Value, "TextColor3", "TextDim")
        local Track = New("Frame", {
            Parent = Item,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 1, -17),
            Size = UDim2.new(1, -24, 0, 6),
            Active = true,
            ZIndex = Z + 2
        })
        Library:Corner(Track, UDim.new(1, 0))
        Library:Themed(Track, "BackgroundColor3", "Track")
        Library:Themed(Track, "BackgroundTransparency", "TrackAlpha")
        local Fill = New("Frame", {
            Parent = Track,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(0, 1),
            ZIndex = Z + 3
        })
        Library:Corner(Fill, UDim.new(1, 0))
        Library:Themed(Fill, "BackgroundColor3", "Ink")
        local Thumb = New("Frame", {
            Parent = Fill,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(14, 14),
            ZIndex = Z + 4
        })
        Library:Corner(Thumb, UDim.new(1, 0))
        Library:Themed(Thumb, "BackgroundColor3", "Ink")
        local function Paint()
            Fill.Size = UDim2.fromScale(Clamp((Getter() - Min) / (Max - Min), 0, 1), 1)
            Value.Text = Format(Getter())
        end
        local Dragging = false
        local function Apply(Position)
            local Alpha = Clamp((Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
            Setter(Min + (Max - Min) * Alpha)
            Paint()
        end
        Track.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                Library:BeginDragLock()
                Apply(Input.Position)
            end
        end)
        table.insert(W.Connections, UserInputService.InputChanged:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                Apply(Input.Position)
            end
        end))
        table.insert(W.Connections, UserInputService.InputEnded:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                Dragging = false
                Library:EndDragLock()
                W.SaveState()
            end
        end))
        Paint()
    end

    local function Percent(Value)
        return math.floor(Value * 100 + 0.5) .. "%"
    end

    Caption("Glass")
    Slider("Window transparency", 0, 0.6, function()
        return Library.Theme.WindowAlpha
    end, function(Value)
        Library.Theme.WindowAlpha = Value
        W.Main.BackgroundTransparency = Value
    end, Percent)
    Slider("Card opacity", 0.7, 1, function()
        return Library.Theme.CardAlpha
    end, function(Value)
        Library.Theme.CardAlpha = Value
        Library.Theme.RowAlpha = math.min(Value - 0.02, 0.98)
        Library:RefreshTheme()
    end, function(Value)
        return Percent(1 - Value)
    end)
    Switch("Background blur", function()
        return W.Blur ~= nil and W.Blur.Size > 0
    end, function(Value)
        if W.Blur then
            Library:Tween(W.Blur, NORMAL, { Size = Value and math.max(Library.Theme.Blur, 14) or 0 })
        end
    end)

    Caption("Motion")
    Switch("Ambient glow", function()
        return Library.Particles
    end, function(Value)
        Library.Particles = Value
        W.Sheen.Visible = Value
        W.Ambient.Visible = Value
    end)
    Switch("Reduce motion", function()
        return Library.Motion.Reduce
    end, function(Value)
        Library.Motion.Reduce = Value
        Library.ReduceMotion = Value
    end)
    Switch("Sound feedback", function()
        return Library.Sound
    end, function(Value)
        Library.Sound = Value
    end)
    Switch("Haptics", function()
        return Library.Haptics
    end, function(Value)
        Library.Haptics = Value
    end)

    Caption("Background")
    local BackgroundRow = Row(46)
    RowLabel(BackgroundRow, "Custom image", 0.4)
    local Actions = Blank(BackgroundRow, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.6, -8, 0, 30),
        ZIndex = Z + 2
    })
    New("UIListLayout", {
        Parent = Actions,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local SetButton = PillButton(Actions, "Set", Library.Icons.Plus, 70)
    SetButton.LayoutOrder = 1
    local ClearButton = PillButton(Actions, "Clear", Library.Icons.Trash, 74)
    ClearButton.LayoutOrder = 2
    SetButton.MouseButton1Click:Connect(function()
        WM.Prompt(W, {
            Title = "Background image",
            Description = "Asset id, rbxassetid or image url",
            Placeholder = "rbxassetid://0",
            Default = W.State.Background and W.State.Background.Image or "",
            Confirm = "Apply",
            Callback = function(Value)
                if Value == "" then
                    return false, "enter an image"
                end
                W.SetBackground({ Image = Value })
                W.SaveState()
                return true
            end
        })
    end)
    ClearButton.MouseButton1Click:Connect(function()
        W.SetBackground(nil)
        W.SaveState()
    end)
    Slider("Image visibility", 0, 1, function()
        return W.State.Background and 1 - W.State.Background.Transparency or 0.45
    end, function(Value)
        if W.State.Background then
            W.State.Background.Transparency = 1 - Value
            W.Background.ImageTransparency = 1 - Value
        end
    end, Percent)
    Slider("Image dim", 0, 0.9, function()
        return W.State.Background and W.State.Background.Dim or 0.45
    end, function(Value)
        if W.State.Background then
            W.State.Background.Dim = Value
            W.Scrim.BackgroundTransparency = 1 - Value
        end
    end, Percent)

    return Handle
end

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
        Library:Corner(Item, UDim.new(0, 12))
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
        Library:Corner(Block, UDim.new(0, 14))
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

Library.NotifyTemplates = Library.NotifyTemplates or {}

function Library:RegisterNotifyTemplate(Name, Template)
    if type(Name) == "string" and type(Template) == "table" then
        Library.NotifyTemplates[Name] = Template
    end
end

function WM.Notify(W, Config)
    Config = Merge({
        Title = "Notification",
        Content = "",
        Desc = nil,
        Type = "Info",
        Duration = 4,
        Buttons = {},
        Progress = false,
        Color = nil,
        Icon = nil,
        Template = nil
    }, Config or {})

    if Config.Template and Library.NotifyTemplates[Config.Template] then
        Config = Merge(Library.NotifyTemplates[Config.Template], Config)
    end
    if W.Config.NotifyDND and Config.Type ~= "Error" then
        return
    end
    local MaxN = tonumber(W.Config.NotifyMax) or 4
    while #W.Notifications >= MaxN do
        local Old = table.remove(W.Notifications, 1)
        if Old and Old.Card then
            pcall(function() Old.Card:Destroy() end)
        end
    end

    local Body = Config.Content ~= "" and Config.Content or (Config.Desc or "")
    local Kinds = {
        Info = { Key = "Info", Icon = "info" },
        Success = { Key = "Success", Icon = "circle-check" },
        Warn = { Key = "Warn", Icon = "triangle-alert" },
        Error = { Key = "Error", Icon = "circle-x" }
    }
    local Kind = Kinds[Config.Type] or Kinds.Info
    local Tint = Config.Color or Library.Theme[Kind.Key]
    if Config.Icon then
        Kind = { Key = Kind.Key, Icon = Config.Icon }
    end

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
        ZIndex = 500
    })
    Library:Corner(Card, UDim.new(0, 16))
    Library:Themed(Card, "BackgroundColor3", "Elevated")
    Library:Themed(Card, "BackgroundTransparency", "ElevatedAlpha")
    New("UIStroke", { Parent = Card, Color = Tint, Transparency = 0.55, Thickness = 1.2 })
    Library:Shadow(Card, 50, 0.6)
    Library:Sheen(Card, 90).ZIndex = 500

    local IconHolder = New("Frame", {
        Parent = Card,
        BackgroundColor3 = Tint,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.fromOffset(30, 30),
        ZIndex = 501
    })
    Library:Corner(IconHolder, UDim.new(0, 12))
    New("UIStroke", { Parent = IconHolder, Color = Tint, Transparency = 0.65, Thickness = 1 })

    local Icon = New("ImageLabel", {
        Parent = IconHolder,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16),
        ZIndex = 502
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
        ZIndex = 502
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
        ZIndex = 502
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
        ZIndex = 503
    })
    local CloseIcon = IconLabel(Close, Library.Icons.Close, 12, "TextDisabled")
    CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseIcon.Position = UDim2.fromScale(0.5, 0.5)
    CloseIcon.ZIndex = 504

    local Bar = New("Frame", {
        Parent = Card,
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Tint,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -6),
        Size = UDim2.new(1, -24, 0, 3),
        ZIndex = 502
    })
    Library:Corner(Bar, UDim.new(1, 0))

    if HasButtons then
        local Actions = Blank(Card, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 12, 1, -12),
            Size = UDim2.new(1, -24, 0, 26),
            ZIndex = 502
        })
        New("UIListLayout", {
            Parent = Actions,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local Count = #Config.Buttons
        for Index, Info in ipairs(Config.Buttons) do
            local Button, TextLabel = PillButton(Actions, Info.Text or "Ok", Info.Icon, 0, Info.Filled)
            Button.Size = UDim2.new(1 / Count, -6 + 6 / Count, 1, 0)
            Button.LayoutOrder = Index
            Button.ZIndex = 503
            TextLabel.TextSize = 11
            for _, Child in ipairs(Button:GetDescendants()) do
                if Child:IsA("GuiObject") then
                    Child.ZIndex = 504
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

local function InfoCard(Parent, Spec)
    local Mobile = Spec.Mobile
    local Card = New("TextButton", {
        Parent = Parent,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Text = "",
        LayoutOrder = Spec.Order
    })
    Library:Corner(Card, UDim.new(0, 16))
    Library:Themed(Card, "BackgroundColor3", "Card")
    Library:Themed(Card, "BackgroundTransparency", "CardAlpha")
    local Edge = Library:GlassEdge(Card, 1, 0.68)
    New("UIPadding", {
        Parent = Card,
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    })

    local Tile = New("Frame", {
        Parent = Card,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 0.9
    })
    Library:Corner(Tile, UDim.new(0, 9))
    Library:Themed(Tile, "BackgroundColor3", "Ink")
    local Icon = IconLabel(Tile, Spec.Icon, 15, "Ink")
    Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon.Position = UDim2.fromScale(0.5, 0.5)

    local Caption = New("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(36, 0),
        Size = UDim2.new(1, -36, 0, 28),
        Font = Library.Font.Bold,
        Text = string.upper(Spec.Caption),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Library:Themed(Caption, "TextColor3", "TextDisabled")

    local Value = New("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Library.Font.Bold,
        Text = Spec.Value or "",
        TextSize = Mobile and 15 or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Library:Themed(Value, "TextColor3", "Text")

    local Sub = New("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 55),
        Size = UDim2.new(1, 0, 0, 14),
        Font = Library.Font.Regular,
        Text = Spec.Sub or "",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Library:Themed(Sub, "TextColor3", "TextDim")

    Card.MouseEnter:Connect(function()
        Library:Tween(Card, FAST, { BackgroundTransparency = math.max(Library.Theme.CardAlpha - 0.045, 0) })
        Library:Tween(Edge, FAST, { Transparency = 0.38 })
        Library:Tween(Tile, FAST, { BackgroundTransparency = 0.82 })
    end)
    Card.MouseLeave:Connect(function()
        Library:Tween(Card, FAST, { BackgroundTransparency = Library.Theme.CardAlpha })
        Library:Tween(Edge, FAST, { Transparency = 0.68 })
        Library:Tween(Tile, FAST, { BackgroundTransparency = 0.9 })
    end)

    local Handle = { Frame = Card, Value = Value, Sub = Sub }
    if Spec.Copy then
        Card.MouseButton1Click:Connect(function()
            Library:Press(Card)
            Library:Feedback(1.1)
            local Text = type(Spec.Copy) == "function" and Spec.Copy() or Value.Text
            if Env.setclipboard then
                pcall(Env.setclipboard, tostring(Text))
            end
            Library:SetIcon(Icon, "check")
            Sub.Text = "Copied"
            task.delay(1.2, function()
                if Card.Parent then
                    Library:SetIcon(Icon, Spec.Icon)
                    Sub.Text = Handle.SubText or Spec.Sub or ""
                end
            end)
        end)
    end
    function Handle:SetSub(Text)
        Handle.SubText = Text
        if Sub.Text ~= "Copied" then
            Sub.Text = Text
        end
    end
    return Handle
end

function WM.PlayerCard(W)
    if W.Card then
        return W.Card
    end

    local Mobile = W.Mobile
    local Card = New("Frame", {
        Parent = W.Gui,
        Name = "PlayerCard",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.fromOffset(420, 520),
        Visible = false,
        ZIndex = 400
    })
    Library:Corner(Card, UDim.new(0, 20))
    Library:Themed(Card, "BackgroundColor3", "Elevated")
    Library:Themed(Card, "BackgroundTransparency", "ElevatedAlpha")
    Library:GlassEdge(Card, 1.2, 0.3)
    Library:Shadow(Card, 60, 0.6)
    Library:Sheen(Card, 90)

    local function FitFloat()
        if Card:GetAttribute("Docked") then
            return
        end
        local Viewport = Device.Viewport()
        Card.Size = UDim2.fromOffset(
            Clamp(Viewport.X - 24, 260, 420),
            Clamp(Viewport.Y - 60, 280, 540)
        )
    end
    FitFloat()
    local Camera = workspace.CurrentCamera
    if Camera then
        table.insert(W.Connections, Camera:GetPropertyChangedSignal("ViewportSize"):Connect(FitFloat))
    end

    local Head = Blank(Card, { Size = UDim2.new(1, 0, 0, 50) })
    local HeadIcon = IconLabel(Head, Library.Icons.User, 18, "Ink")
    HeadIcon.AnchorPoint = Vector2.new(0, 0.5)
    HeadIcon.Position = UDim2.new(0, 16, 0.5, 0)
    local HeadTitle = New("TextLabel", {
        Parent = Head,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 42, 0.5, 0),
        Size = UDim2.new(1, -90, 0, 20),
        Font = Library.Font.Bold,
        Text = "Player",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Library:Themed(HeadTitle, "TextColor3", "Text")
    local Close = GlyphButton(Head, Library.Icons.Close, "Close")
    Close.AnchorPoint = Vector2.new(1, 0.5)
    Close.Position = UDim2.new(1, -10, 0.5, 0)
    Close.MouseButton1Click:Connect(function()
        WM.TogglePlayerCard(W, false)
    end)

    local Scroll = New("ScrollingFrame", {
        Parent = Card,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 50),
        Size = UDim2.new(1, 0, 1, -50)
    })
    Library:StyleScroll(Scroll)
    New("UIPadding", {
        Parent = Scroll,
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 14)
    })
    New("UIListLayout", {
        Parent = Scroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })

    local Items = {}

    local Hero = New("Frame", {
        Parent = Scroll,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Mobile and 104 or 96),
        LayoutOrder = 1
    })
    Library:Corner(Hero, UDim.new(0, 18))
    Library:Themed(Hero, "BackgroundColor3", "Card")
    Library:Themed(Hero, "BackgroundTransparency", "CardAlpha")
    Library:GlassEdge(Hero, 1, 0.55)
    Library:Gloss(Hero, 0.94)
    table.insert(Items, Hero)

    local Avatar = New("ImageLabel", {
        Parent = Hero,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 0.88,
        Position = UDim2.new(0, 16, 0.5, 0),
        Size = UDim2.fromOffset(68, 68),
        ScaleType = Enum.ScaleType.Crop
    })
    Library:Corner(Avatar, UDim.new(1, 0))
    Library:Themed(Avatar, "BackgroundColor3", "Ink")
    local AvatarRing = New("UIStroke", {
        Parent = Avatar,
        Thickness = 2,
        Transparency = 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(AvatarRing, "Color", "Ink")
    task.spawn(function()
        local Ok, Url = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if Ok and Avatar.Parent then
            Avatar.Image = Url
        end
    end)

    local Presence = New("Frame", {
        Parent = Avatar,
        AnchorPoint = Vector2.new(1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -2, 1, -2),
        Size = UDim2.fromOffset(14, 14)
    })
    Library:Corner(Presence, UDim.new(1, 0))
    Library:Themed(Presence, "BackgroundColor3", "Ink")
    local PresenceRing = New("UIStroke", {
        Parent = Presence,
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(PresenceRing, "Color", "Main")
    task.spawn(function()
        while Presence.Parent do
            if Card.Visible and not Library.Motion.Reduce then
                Library:Tween(Presence, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.45 })
                task.wait(0.9)
                Library:Tween(Presence, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0 })
            end
            task.wait(0.9)
        end
    end)

    local HeroText = Blank(Hero, {
        Position = UDim2.fromOffset(98, 0),
        Size = UDim2.new(1, -110, 1, 0)
    })
    New("UIListLayout", {
        Parent = HeroText,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3)
    })
    local HeroName = New("TextLabel", {
        Parent = HeroText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Library.Font.Bold,
        Text = LocalPlayer.DisplayName,
        TextSize = Mobile and 19 or 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 1
    })
    Library:Themed(HeroName, "TextColor3", "Text")
    local HeroHandle = New("TextLabel", {
        Parent = HeroText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Library.Font.Regular,
        Text = "@" .. LocalPlayer.Name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 2
    })
    Library:Themed(HeroHandle, "TextColor3", "TextDim")
    local Badges = Blank(HeroText, { Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 3 })
    New("UIListLayout", {
        Parent = Badges,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local function Badge(Text, Order, Filled)
        local Holder = New("Frame", {
            Parent = Badges,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = Order
        })
        Library:Corner(Holder, UDim.new(1, 0))
        Library:Themed(Holder, "BackgroundColor3", "Ink")
        Holder.BackgroundTransparency = Filled and 0.06 or 0.86
        New("UIPadding", { Parent = Holder, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
        local Text2 = New("TextLabel", {
            Parent = Holder,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 18),
            Font = Library.Font.Bold,
            Text = Text,
            TextSize = 10
        })
        Library:Themed(Text2, "TextColor3", Filled and "InkText" or "Text")
    end
    Badge("ONLINE", 1, true)
    Badge(string.upper(ExecutorName()), 2, false)

    local Grid = New("Frame", {
        Parent = Scroll,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2
    })
    local GridLayout = New("UIGridLayout", {
        Parent = Grid,
        CellPadding = UDim2.fromOffset(10, 10),
        CellSize = UDim2.new(0.5, -5, 0, 92),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local Days = LocalPlayer.AccountAge
    local Created = os.time() - Days * 86400
    local Membership = tostring(LocalPlayer.MembershipType):gsub("Enum.MembershipType.", "")
    local Hardware = HardwareId()

    local function Make(Order, Icon, Caption, Value, Sub, Copy)
        local Handle = InfoCard(Grid, {
            Order = Order,
            Icon = Icon,
            Caption = Caption,
            Value = Value,
            Sub = Sub,
            Copy = Copy,
            Mobile = Mobile
        })
        table.insert(Items, Handle.Frame)
        return Handle
    end

    Make(1, "at-sign", "Username", LocalPlayer.Name, "Tap to copy", true)
    Make(2, "badge", "Display name", LocalPlayer.DisplayName, "Tap to copy", true)
    Make(3, "hash", "User ID", tostring(LocalPlayer.UserId), "Tap to copy", true)
    Make(4, "hourglass", "Account age", Days .. " days", math.floor(Days / 365) .. "y " .. math.floor((Days % 365) / 30) .. "m")
    Make(5, "calendar", "Created", os.date("!%b %d, %Y", Created), "Account creation date")
    Make(6, "crown", "Membership", Membership == "None" and "Standard" or Membership, "Roblox plan")
    local Status = Make(7, "radio", "Presence", "In experience", "Session 00:00")
    local Server = Make(8, "server", "Server", "-- / " .. Players.MaxPlayers, "Job " .. tostring(game.JobId):sub(1, 8), function()
        return game.JobId
    end)
    local Place = Make(9, "map-pin", "Place", tostring(game.PlaceId), "Loading name", true)
    local Perf = Make(10, "activity", "Performance", "-- FPS", "Ping -- ms")
    Make(11, "smartphone", "Device", Device.Class(), ExecutorName())
    Make(12, "globe", "Locale", tostring(LocalPlayer.LocaleId), "Language and region")
    Make(13, "fingerprint", "Hardware", Hardware:sub(1, 10), "Tap to copy ID", function()
        return Hardware
    end)
    if LocalPlayer.Team then
        Make(14, "flag", "Team", LocalPlayer.Team.Name, "Current team")
    end

    task.spawn(function()
        local Ok, Info = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        if Ok and type(Info) == "table" and Info.Name then
            Place:SetSub(tostring(Info.Name))
        else
            Place:SetSub("Place id")
        end
    end)

    local function FitGrid()
        local Factor = Card:GetAttribute("Docked") and math.max(W.Scale.Scale, 0.001) or 1
        local Width = Scroll.AbsoluteSize.X / Factor - 24
        local Columns = Clamp(math.floor((Width + 10) / 168), 1, 3)
        GridLayout.CellSize = UDim2.new(1 / Columns, -((Columns - 1) * 10) / Columns, 0, Mobile and 96 or 92)
    end
    Scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitGrid)
    Card:GetAttributeChangedSignal("Docked"):Connect(function()
        task.defer(FitGrid)
        task.defer(FitFloat)
    end)
    task.defer(FitGrid)

    local Start = os.clock()
    local Frames, Last, Fps = 0, os.clock(), 60
    table.insert(W.Connections, RunService.Heartbeat:Connect(function()
        Frames = Frames + 1
        local Now = os.clock()
        if Now - Last < 1 then
            return
        end
        Fps = Frames / (Now - Last)
        Frames, Last = 0, Now
        if not Card.Visible then
            return
        end
        local Ping = 0
        if StatsService then
            local Ok, Value = pcall(function()
                return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            Ping = Ok and Value or 0
        end
        Perf.Value.Text = math.floor(Fps + 0.5) .. " FPS"
        Perf:SetSub("Ping " .. math.floor(Ping + 0.5) .. " ms")
        Status:SetSub("Session " .. Clock(Now - Start))
        Server.Value.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
        Server:SetSub("Up " .. Clock(workspace.DistributedGameTime) .. " | " .. tostring(game.JobId):sub(1, 6))
    end))

    do
        local Dragging, Origin, StartPosition = false, nil, nil
        Head.InputBegan:Connect(function(Input)
            if Card:GetAttribute("Docked") then
                return
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                Origin = Input.Position
                StartPosition = Card.Position
                Library:BeginDragLock()
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
        table.insert(W.Connections, UserInputService.InputEnded:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch) then
                Dragging = false
                Library:EndDragLock()
            end
        end))
    end

    W.CardItems = Items
    W.Card = Card
    return Card
end

local function RestorePages(W)
    if W.Pages then
        W.Pages.Visible = true
    end
    if W.PageHeader then
        W.PageHeader.Visible = true
    end
    if W.PageLine then
        W.PageLine.Visible = true
    end
    if W.Active then
        W.SetPageHead(W.Active.Name, W.Active.Description, W.Active.Icon)
    end
end

local function DockPanel(W, Panel)
    if W.AIPanel and W.AIPanel ~= Panel then
        W.AIPanel.Visible = false
        W.AIPanel:SetAttribute("Docked", false)
    end
    if W.Card and W.Card ~= Panel then
        W.Card.Visible = false
        W.Card:SetAttribute("Docked", false)
    end
    Panel.Parent = W.Content
    Panel.AnchorPoint = Vector2.new(0, 0)
    Panel.Position = UDim2.fromOffset(0, 0)
    Panel.Size = UDim2.new(1, 0, 1, 0)
    Panel.ZIndex = 60
    Panel:SetAttribute("Docked", true)
    pcall(function()
        Panel.BackgroundColor3 = Library.Theme.Elevated
        Panel.BackgroundTransparency = math.min(Library.Theme.ElevatedAlpha or 0.12, 0.16)
    end)
    if W.Pages then
        W.Pages.Visible = false
    end
    if W.PageHeader then
        W.PageHeader.Visible = false
    end
    if W.PageLine then
        W.PageLine.Visible = false
    end
    Panel.Visible = true
    Library:Pop(Panel, 0.22, 0.97)
end

function WM.TogglePlayerCard(W, State)
    local Card = WM.PlayerCard(W)
    if State == nil then
        State = not Card.Visible
    end
    if (W.Config.DockPanels or Device.IsTouch()) and W.Content then
        if State then
            DockPanel(W, Card)
            Library:Rise(W.CardItems or {})
        else
            Card.Visible = false
            Card:SetAttribute("Docked", false)
            RestorePages(W)
        end
        return
    end
    if State then
        Card.Visible = true
        Library:Pop(Card, 0.3, 0.9)
        Library:Rise(W.CardItems or {})
    else
        Library:Tween(Card, FAST, { BackgroundTransparency = 1 }, function()
            Card.Visible = false
            Card.BackgroundTransparency = Library.Theme.ElevatedAlpha
        end)
    end
end

Library.Groq = {
    Endpoint = "https://api.groq.com/openai/v1/chat/completions",
    Key = "",
    Prompt = "You are a concise assistant embedded in a Roblox script hub.",
    Model = "openai/gpt-oss-120b",
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

function Library:ClearGroqKey()
    Library.Groq.Key = ""
end

function Library:TestGroqKey(Key, OnDone)
    task.spawn(function()
        Key = Trim(tostring(Key or ""))
        if Key == "" then
            return OnDone(false, "empty key")
        end
        if not Key:lower():find("^gsk") then
            return OnDone(false, "key should start with gsk")
        end
        if not Env.request then
            return OnDone(false, "no request function")
        end
        local Ok, Response = pcall(Env.request, {
            Url = Library.Groq.Endpoint,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. Key
            },
            Body = HttpService:JSONEncode({
                model = Library.Groq.Model,
                messages = { { role = "user", content = "ping" } },
                max_tokens = 4
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
            return OnDone(false, tostring(Data.error.message or "invalid key"))
        end
        OnDone(true, "ok")
    end)
end

function Library:RefreshGroqModels(List)
    if type(List) == "table" and #List > 0 then
        Library.Groq.Models = List
        if not table.find(List, Library.Groq.Model) then
            Library.Groq.Model = List[1]
        end
        return true
    end
    return false
end

local function GroqAsk(History, OnDone)
    task.spawn(function()
        if not Env.request then
            return OnDone(false, "no http request function in this executor")
        end
        if Library.Groq.Key == "" then
            return OnDone(false, "no api key set")
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

local function EscapeRich(Text)
    Text = Text:gsub("&", "&amp;")
    Text = Text:gsub("<", "&lt;")
    Text = Text:gsub(">", "&gt;")
    return Text
end

local function InlineRich(Text)
    local Codes = {}
    Text = Text:gsub("`([^`\n]+)`", function(Code)
        table.insert(Codes, Code)
        return "\\1" .. #Codes .. "\\1"
    end)
    Text = EscapeRich(Text)
    Text = Text:gsub("%*%*(.-)%*%*", "<b>%1</b>")
    Text = Text:gsub("__(.-)__", "<b>%1</b>")
    Text = Text:gsub("%*([^%*\n]+)%*", "<i>%1</i>")
    Text = Text:gsub("~~(.-)~~", "<s>%1</s>")
    Text = Text:gsub("%[(.-)%]%((.-)%)", "<u>%1</u>")
    Text = Text:gsub("\\1(%d+)\\1", function(Index)
        return '<mark color="#ffffff" transparency="0.86"><font face="Code"> ' .. EscapeRich(Codes[tonumber(Index)]) .. " </font></mark>"
    end)
    return Text
end

local function ParseBlocks(Source)
    local Blocks = {}
    local function AddText(Chunk)
        local Lines = {}
        local function Flush()
            if #Lines > 0 then
                table.insert(Blocks, { Kind = "text", Rich = table.concat(Lines, "\n") })
                Lines = {}
            end
        end
        for Line in (Chunk .. "\n"):gmatch("(.-)\n") do
            local Trimmed = Trim(Line)
            if Trimmed == "" then
                Flush()
            elseif Trimmed:match("^#+%s+.+$") then
                local Heading = Trimmed:gsub("^#+%s+", "")
                table.insert(Lines, '<font size="15"><b>' .. InlineRich(Heading) .. "</b></font>")
            elseif Trimmed:match("^[%-%*]%s+.+$") then
                local Item = Trimmed:gsub("^[%-%*]%s+", "")
                table.insert(Lines, "  \u{2022}  " .. InlineRich(Item))
            elseif Trimmed:match("^%d+[%.%)]%s+.+$") then
                local Number, Rest = Trimmed:match("^(%d+)[%.%)]%s+(.+)$")
                table.insert(Lines, "  " .. Number .. ".  " .. InlineRich(Rest))
            elseif Trimmed:match("^>%s?.*$") then
                local Quote = Trimmed:gsub("^>%s?", "")
                table.insert(Lines, "<i>" .. InlineRich(Quote) .. "</i>")
            elseif Trimmed:match("^%-%-%-+$") then
                table.insert(Lines, '<font transparency="0.7">\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}</font>')
            else
                table.insert(Lines, InlineRich(Line))
            end
        end
        Flush()
    end

    local Position = 1
    while true do
        local Start, Fence = Source:find("```", Position, true)
        if not Start then
            AddText(Source:sub(Position))
            break
        end
        AddText(Source:sub(Position, Start - 1))
        local LineEnd = Source:find("\n", Fence + 1, true)
        local Lang = ""
        local CodeStart = Fence + 1
        if LineEnd then
            Lang = Trim(Source:sub(Fence + 1, LineEnd - 1))
            CodeStart = LineEnd + 1
        end
        local Close = Source:find("```", CodeStart, true)
        local Code = Close and Source:sub(CodeStart, Close - 1) or Source:sub(CodeStart)
        Code = Code:gsub("\n+$", "")
        table.insert(Blocks, { Kind = "code", Lang = Lang, Code = Code })
        if not Close then
            break
        end
        Position = Close + 3
    end
    return Blocks
end

local ChatSeeds = {
    "Explain what this hub can do",
    "How do configs work?",
    "What is the panic key?",
    "Give me a quick tour"
}

local function Ago(Stamp)
    local Delta = math.max(os.time() - (tonumber(Stamp) or 0), 0)
    if Delta < 60 then
        return "just now"
    end
    if Delta < 3600 then
        return math.floor(Delta / 60) .. "m ago"
    end
    if Delta < 86400 then
        return math.floor(Delta / 3600) .. "h ago"
    end
    return math.floor(Delta / 86400) .. "d ago"
end

function WM.AI(W)
    if W.AIPanel then
        return W.AIPanel
    end

    local Mobile = W.Mobile
    local StorePath = W.Paths.Folder .. "/ai_chats.json"
    local Store = FS.ReadJSON(StorePath)
    if type(Store) ~= "table" or type(Store.Chats) ~= "table" then
        Store = { Chats = {}, Active = nil }
        local Legacy = FS.ReadJSON(W.Paths.Folder .. "/ai_history.json")
        if type(Legacy) == "table" and #Legacy > 0 then
            table.insert(Store.Chats, {
                Id = HttpService:GenerateGUID(false),
                Title = "Previous chat",
                Updated = os.time(),
                Messages = Legacy
            })
            Store.Active = Store.Chats[1].Id
        end
    end

    local function Save()
        FS.WriteJSON(StorePath, Store)
    end

    local function NewChat()
        local Chat = {
            Id = HttpService:GenerateGUID(false),
            Title = "New chat",
            Updated = os.time(),
            Messages = {}
        }
        table.insert(Store.Chats, 1, Chat)
        Store.Active = Chat.Id
        return Chat
    end

    local function Current()
        for _, Chat in ipairs(Store.Chats) do
            if Chat.Id == Store.Active then
                return Chat
            end
        end
        local First = Store.Chats[1]
        if First then
            Store.Active = First.Id
            return First
        end
        return NewChat()
    end

    local Panel = New("Frame", {
        Parent = W.Main,
        Name = "AI",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, W.Header.Size.Y.Offset),
        Size = UDim2.new(0, 340, 1, -W.Header.Size.Y.Offset),
        Visible = false,
        ZIndex = 90,
        ClipsDescendants = true
    })
    Library:Themed(Panel, "BackgroundColor3", "Elevated")
    Library:Themed(Panel, "BackgroundTransparency", "ElevatedAlpha")
    Library:Stroke(Panel, "StrokeSoft", 1)

    local Chat = Blank(Panel, { Name = "Chat", Size = UDim2.fromScale(1, 1), ZIndex = 1 })
    local Scrim = New("TextButton", {
        Parent = Panel,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 4
    })
    local Drawer = New("Frame", {
        Parent = Panel,
        Name = "Drawer",
        BorderSizePixel = 0,
        Size = UDim2.new(0, 220, 1, 0),
        Position = UDim2.fromOffset(-230, 0),
        ZIndex = 5
    })
    Library:Themed(Drawer, "BackgroundColor3", "Main")
    Drawer.BackgroundTransparency = 0.04
    local DrawerEdge = New("Frame", {
        Parent = Drawer,
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundTransparency = 0.88
    })
    Library:Themed(DrawerEdge, "BackgroundColor3", "Stroke")

    local Head = Blank(Chat, { Size = UDim2.new(1, 0, 0, 54) })
    local MenuButton = GlyphButton(Head, "panel-left", "Chats")
    MenuButton.AnchorPoint = Vector2.new(0, 0.5)
    MenuButton.Position = UDim2.new(0, 10, 0.5, 0)

    local HeadIcon = New("Frame", {
        Parent = Head,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.88,
        Size = UDim2.fromOffset(30, 30)
    })
    Library:Corner(HeadIcon, UDim.new(1, 0))
    Library:Themed(HeadIcon, "BackgroundColor3", "Ink")
    local HeadGlyph = IconLabel(HeadIcon, Library.Icons.Bot, 16, "Ink")
    HeadGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    HeadGlyph.Position = UDim2.fromScale(0.5, 0.5)

    local HeadTitle = New("TextLabel", {
        Parent = Head,
        BackgroundTransparency = 1,
        Font = Library.Font.Bold,
        Text = "AI Assistant",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Library:Themed(HeadTitle, "TextColor3", "Text")
    local ModelButton = New("TextButton", {
        Parent = Head,
        BackgroundTransparency = 1,
        Font = Library.Font.Medium,
        Text = Library.Groq.Model,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false
    })
    Library:Themed(ModelButton, "TextColor3", "TextDim")

    local CloseButton = GlyphButton(Head, Library.Icons.Close, "Close")
    CloseButton.AnchorPoint = Vector2.new(1, 0.5)
    CloseButton.Position = UDim2.new(1, -10, 0.5, 0)
    local NewButton = GlyphButton(Head, Library.Icons.Plus, "New chat")
    NewButton.AnchorPoint = Vector2.new(1, 0.5)
    NewButton.Position = UDim2.new(1, -44, 0.5, 0)
    local ExportButton = GlyphButton(Head, Library.Icons.Copy, "Copy chat")
    ExportButton.AnchorPoint = Vector2.new(1, 0.5)
    ExportButton.Position = UDim2.new(1, -78, 0.5, 0)

    local HeadLine = New("Frame", {
        Parent = Head,
        AnchorPoint = Vector2.new(0, 1),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.92,
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 1)
    })
    Library:Themed(HeadLine, "BackgroundColor3", "Stroke")

    local Log = New("ScrollingFrame", {
        Parent = Chat,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 54),
        Size = UDim2.new(1, 0, 1, -120)
    })
    Library:StyleScroll(Log)
    New("UIPadding", {
        Parent = Log,
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, Mobile and 10 or 14),
        PaddingRight = UDim.new(0, Mobile and 10 or 14)
    })
    New("UIListLayout", {
        Parent = Log,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 14)
    })

    local Footer = Blank(Chat, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 66)
    })
    local Field = New("Frame", {
        Parent = Footer,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(Mobile and 10 or 12, 8),
        Size = UDim2.new(1, Mobile and -20 or -24, 0, 46)
    })
    Library:Corner(Field, UDim.new(0, 23))
    Library:Themed(Field, "BackgroundColor3", "Inset")
    Library:Themed(Field, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(Field, 0.96)
    local FieldLine = Library:Stroke(Field, "StrokeSoft", 1)

    local Box = New("TextBox", {
        Parent = Field,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 12),
        Size = UDim2.new(1, -66, 1, -24),
        Font = Library.Font.Regular,
        PlaceholderText = "Message the assistant",
        Text = "",
        TextSize = Mobile and 14 or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        MultiLine = true,
        ClearTextOnFocus = false
    })
    Library:Themed(Box, "TextColor3", "Text")
    Library:Themed(Box, "PlaceholderColor3", "TextDisabled")

    local Send = New("TextButton", {
        Parent = Field,
        AnchorPoint = Vector2.new(1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -6, 1, -6),
        Size = UDim2.fromOffset(34, 34),
        Text = ""
    })
    Library:Corner(Send, UDim.new(1, 0))
    Library:Themed(Send, "BackgroundColor3", "Ink")
    local SendIcon = IconLabel(Send, "arrow-up", 17, "InkText")
    SendIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    SendIcon.Position = UDim2.fromScale(0.5, 0.5)

    local Jump = New("TextButton", {
        Parent = Chat,
        AnchorPoint = Vector2.new(0.5, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 1, -76),
        Size = UDim2.fromOffset(32, 32),
        Text = "",
        Visible = false,
        ZIndex = 3
    })
    Library:Corner(Jump, UDim.new(1, 0))
    Library:Themed(Jump, "BackgroundColor3", "Elevated")
    Library:GlassEdge(Jump, 1, 0.4)
    Library:Shadow(Jump, 24, 0.6)
    local JumpIcon = IconLabel(Jump, "arrow-down", 15, "Text")
    JumpIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    JumpIcon.Position = UDim2.fromScale(0.5, 0.5)

    local Limits = {}
    local Rows = {}
    local Busy = false
    local Pinned = false
    local DrawerOpen = false
    local LastAssistant = nil
    local Stick = true

    local function ReducedMotion()
        return Library.Motion.Reduce or Library.ReduceMotion or not Library.Motion.Enabled
    end

    local function Bottom()
        return math.max(Log.AbsoluteCanvasSize.Y - Log.AbsoluteSize.Y, 0)
    end

    local function ToBottom(Animated)
        task.spawn(function()
            RunService.Heartbeat:Wait()
            if not Log.Parent then
                return
            end
            if Animated and not ReducedMotion() then
                Library:Tween(Log, NORMAL, { CanvasPosition = Vector2.new(0, Bottom()) })
            else
                Log.CanvasPosition = Vector2.new(0, Bottom())
            end
        end)
    end

    Log:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        Stick = Bottom() - Log.CanvasPosition.Y < 70
        Jump.Visible = not Stick
    end)
    Jump.MouseButton1Click:Connect(function()
        Library:Press(Jump)
        Stick = true
        ToBottom(true)
    end)

    local function Notify(Title, Content, Kind)
        if W.API then
            W.API:Notify({ Title = Title, Content = Content, Type = Kind or "Info", Duration = 2.5 })
        end
    end

    local function CopyText(Text)
        if Env.setclipboard then
            pcall(Env.setclipboard, Text)
            Notify("Copied", "Copied to clipboard", "Success")
        else
            Notify("Copy", "Clipboard is not available here", "Warn")
        end
    end

    local function Pill(Parent, Text, IconName, Order)
        local Button = New("TextButton", {
            Parent = Parent,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = "",
            LayoutOrder = Order or 0
        })
        Library:Corner(Button, UDim.new(1, 0))
        Library:Themed(Button, "BackgroundColor3", "Ink")
        Button.BackgroundTransparency = 0.92
        New("UIPadding", { Parent = Button, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 10) })
        New("UIListLayout", {
            Parent = Button,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local Glyph = IconLabel(Button, IconName, 12, "TextDim")
        Glyph.LayoutOrder = 1
        local Label2 = New("TextLabel", {
            Parent = Button,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Library.Font.Medium,
            Text = Text,
            TextSize = 11,
            LayoutOrder = 2
        })
        Library:Themed(Label2, "TextColor3", "TextDim")
        Button.MouseEnter:Connect(function()
            Library:Tween(Button, FAST, { BackgroundTransparency = 0.84 })
            Library:Tween(Label2, FAST, { TextColor3 = Library.Theme.Text })
            Library:Tween(Glyph, FAST, { ImageColor3 = Library.Theme.Text })
        end)
        Button.MouseLeave:Connect(function()
            Library:Tween(Button, FAST, { BackgroundTransparency = 0.92 })
            Library:Tween(Label2, FAST, { TextColor3 = Library.Theme.TextDim })
            Library:Tween(Glyph, FAST, { ImageColor3 = Library.Theme.TextDim })
        end)
        return Button, Label2, Glyph
    end

    local function Reveal(Items)
        if ReducedMotion() then
            return
        end
        local Counts, Total = {}, 0
        for Index, Item in ipairs(Items) do
            if Item.Label then
                Counts[Index] = utf8.len(Item.Label.ContentText) or #Item.Label.ContentText
                Total = Total + Counts[Index]
                Item.Label.MaxVisibleGraphemes = 0
            else
                Item.Frame.Visible = false
            end
        end
        task.spawn(function()
            local Speed = math.max(Total / 1.2, 160)
            local Progress = 0
            while Log.Parent do
                Progress = Progress + RunService.Heartbeat:Wait() * Speed
                local Remaining = math.floor(Progress)
                local Done = true
                for Index, Item in ipairs(Items) do
                    if Item.Label then
                        local Shown = Clamp(Remaining, 0, Counts[Index])
                        Item.Label.MaxVisibleGraphemes = Shown >= Counts[Index] and -1 or Shown
                        Remaining = Remaining - Counts[Index]
                        if Shown < Counts[Index] then
                            Done = false
                            break
                        end
                    else
                        if Remaining < 0 then
                            Done = false
                            break
                        end
                        Item.Frame.Visible = true
                    end
                end
                if Stick then
                    Log.CanvasPosition = Vector2.new(0, Bottom())
                end
                if Done then
                    break
                end
            end
            for _, Item in ipairs(Items) do
                if Item.Label then
                    Item.Label.MaxVisibleGraphemes = -1
                else
                    Item.Frame.Visible = true
                end
            end
        end)
    end

    local function RowShell(Role)
        local Row = New("Frame", {
            Parent = Log,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = #Rows + 1
        })
        table.insert(Rows, Row)
        Row:SetAttribute("Role", Role)
        return Row
    end

    local function AssistantShell(Row, Error)
        local Avatar = New("Frame", {
            Parent = Row,
            BorderSizePixel = 0,
            BackgroundTransparency = 0.88,
            Size = UDim2.fromOffset(28, 28)
        })
        Library:Corner(Avatar, UDim.new(1, 0))
        Library:Themed(Avatar, "BackgroundColor3", "Ink")
        local Glyph = IconLabel(Avatar, Error and "triangle-alert" or Library.Icons.Bot, 15, "Ink")
        Glyph.AnchorPoint = Vector2.new(0.5, 0.5)
        Glyph.Position = UDim2.fromScale(0.5, 0.5)

        local Card = New("Frame", {
            Parent = Row,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(Mobile and 34 or 38, 0),
            Size = UDim2.new(1, -(Mobile and 34 or 38), 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        })
        Library:Corner(Card, UDim.new(0, 16))
        Library:Themed(Card, "BackgroundColor3", "Card")
        Library:Themed(Card, "BackgroundTransparency", "CardAlpha")
        Library:GlassEdge(Card, 1, Error and 0.3 or 0.7)
        New("UIPadding", {
            Parent = Card,
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        })
        New("UIListLayout", {
            Parent = Card,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })
        return Card
    end

    local function CodeBlock(Parent, Block, Order)
        local Frame = New("Frame", {
            Parent = Parent,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = Order
        })
        Library:Corner(Frame, UDim.new(0, 12))
        Library:Themed(Frame, "BackgroundColor3", "Inset")
        Library:Themed(Frame, "BackgroundTransparency", "InsetAlpha")
        Library:Stroke(Frame, "StrokeSoft", 1)
        New("UIListLayout", { Parent = Frame, SortOrder = Enum.SortOrder.LayoutOrder })

        local Bar = Blank(Frame, { Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1 })
        local Lang = New("TextLabel", {
            Parent = Bar,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -90, 1, 0),
            Font = Library.Font.Mono,
            Text = Block.Lang ~= "" and string.lower(Block.Lang) or "code",
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Themed(Lang, "TextColor3", "TextDim")
        local CopyButton, CopyLabel, CopyGlyph = Pill(Bar, "Copy", Library.Icons.Copy, 1)
        CopyButton.AnchorPoint = Vector2.new(1, 0.5)
        CopyButton.Position = UDim2.new(1, -6, 0.5, 0)
        CopyButton.MouseButton1Click:Connect(function()
            Library:Press(CopyButton)
            CopyText(Block.Code)
            CopyLabel.Text = "Copied"
            Library:SetIcon(CopyGlyph, Library.Icons.Check)
            task.delay(1.4, function()
                if CopyButton.Parent then
                    CopyLabel.Text = "Copy"
                    Library:SetIcon(CopyGlyph, Library.Icons.Copy)
                end
            end)
        end)

        local Body = New("TextLabel", {
            Parent = Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Library.Font.Mono,
            Text = Block.Code,
            TextSize = Mobile and 12 or 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = 2
        })
        Library:Themed(Body, "TextColor3", "Text")
        New("UIPadding", {
            Parent = Body,
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 2)
        })
        return Frame
    end

    local function AddUser(Text)
        local Row = RowShell("user")
        local Bubble = New("Frame", {
            Parent = Row,
            AnchorPoint = Vector2.new(1, 0),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.new(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.XY
        })
        Library:Corner(Bubble, UDim.new(0, 18))
        Library:Themed(Bubble, "BackgroundColor3", "Ink")
        Bubble.BackgroundTransparency = 0.06
        New("UIPadding", {
            Parent = Bubble,
            PaddingTop = UDim.new(0, 9),
            PaddingBottom = UDim.new(0, 9),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14)
        })
        local Label2 = New("TextLabel", {
            Parent = Bubble,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            Font = Library.Font.Medium,
            Text = EscapeRich(Text),
            RichText = true,
            TextSize = Mobile and 14 or 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        Library:Themed(Label2, "TextColor3", "InkText")
        local Limit = New("UISizeConstraint", { Parent = Label2, MaxSize = Vector2.new(260, 100000) })
        table.insert(Limits, Limit)
        return Row
    end

    local Regenerate
    local Retry

    local function AddAssistant(Text, Options)
        Options = Options or {}
        local Row = RowShell("assistant")
        local Card = AssistantShell(Row, false)
        local Items = {}
        local Order = 0
        for _, Block in ipairs(ParseBlocks(Text)) do
            Order = Order + 1
            if Block.Kind == "text" then
                local Label2 = New("TextLabel", {
                    Parent = Card,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Library.Font.Regular,
                    Text = Block.Rich,
                    RichText = true,
                    TextSize = Mobile and 14 or 13,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    LayoutOrder = Order
                })
                Library:Themed(Label2, "TextColor3", "Text")
                table.insert(Items, { Label = Label2 })
            else
                table.insert(Items, { Frame = CodeBlock(Card, Block, Order) })
            end
        end

        local Actions = Blank(Card, { Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1000 })
        New("UIListLayout", {
            Parent = Actions,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local CopyButton, CopyLabel, CopyGlyph = Pill(Actions, "Copy", Library.Icons.Copy, 1)
        CopyButton.MouseButton1Click:Connect(function()
            Library:Press(CopyButton)
            CopyText(Text)
            CopyLabel.Text = "Copied"
            Library:SetIcon(CopyGlyph, Library.Icons.Check)
            task.delay(1.4, function()
                if CopyButton.Parent then
                    CopyLabel.Text = "Copy"
                    Library:SetIcon(CopyGlyph, Library.Icons.Copy)
                end
            end)
        end)
        local Again = Pill(Actions, "Regenerate", Library.Icons.Refresh, 2)
        Again.MouseButton1Click:Connect(function()
            Library:Press(Again)
            Regenerate()
        end)
        local Stamp = New("TextLabel", {
            Parent = Actions,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Library.Font.Regular,
            Text = os.date("%H:%M"),
            TextSize = 10,
            LayoutOrder = 3
        })
        Library:Themed(Stamp, "TextColor3", "TextDisabled")

        if LastAssistant and LastAssistant.Parent then
            local Old = LastAssistant:FindFirstChild("Again", true)
            if Old then
                Old.Visible = false
            end
        end
        Again.Name = "Again"
        LastAssistant = Row

        if Options.Animate then
            Reveal(Items)
        end
        return Row
    end

    local function AddError(Message, CanRetry)
        local Row = RowShell("error")
        local Card = AssistantShell(Row, true)
        local Label2 = New("TextLabel", {
            Parent = Card,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Library.Font.Medium,
            Text = EscapeRich(Message),
            RichText = true,
            TextSize = Mobile and 13 or 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1
        })
        Library:Themed(Label2, "TextColor3", "Text")
        if CanRetry then
            local Holder = Blank(Card, { Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 2 })
            local Again = Pill(Holder, "Retry", Library.Icons.Refresh, 1)
            Again.MouseButton1Click:Connect(function()
                Library:Press(Again)
                Retry(Row)
            end)
        end
        Library:Rise({ Row })
        return Row
    end

    local TypingRow
    local function ShowTyping()
        if TypingRow and TypingRow.Parent then
            return
        end
        TypingRow = RowShell("typing")
        local Card = AssistantShell(TypingRow, false)
        local Dots = Blank(Card, { Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1 })
        New("UIListLayout", {
            Parent = Dots,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        for Index = 1, 3 do
            local Dot = New("Frame", {
                Parent = Dots,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(7, 7),
                LayoutOrder = Index
            })
            Library:Corner(Dot, UDim.new(1, 0))
            Library:Themed(Dot, "BackgroundColor3", "Ink")
            Dot.BackgroundTransparency = 0.75
            local Scale = New("UIScale", { Parent = Dot, Scale = 0.8 })
            if not ReducedMotion() then
                local Loop = TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, Index * 0.16)
                TweenService:Create(Dot, Loop, { BackgroundTransparency = 0.1 }):Play()
                TweenService:Create(Scale, Loop, { Scale = 1.25 }):Play()
            end
        end
        Library:Rise({ TypingRow })
        Stick = true
        ToBottom(true)
    end

    local function HideTyping()
        if TypingRow then
            local Index = table.find(Rows, TypingRow)
            if Index then
                table.remove(Rows, Index)
            end
            TypingRow:Destroy()
            TypingRow = nil
        end
    end

    local Empty = Blank(Chat, {
        Position = UDim2.fromOffset(0, 54),
        Size = UDim2.new(1, 0, 1, -120),
        ZIndex = 2
    })
    local EmptyStack = Blank(Empty, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -32, 0, 0)
    })
    EmptyStack.AutomaticSize = Enum.AutomaticSize.Y
    New("UIListLayout", {
        Parent = EmptyStack,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })
    local EmptyTile = New("Frame", {
        Parent = EmptyStack,
        BorderSizePixel = 0,
        BackgroundTransparency = 0.9,
        Size = UDim2.fromOffset(60, 60),
        LayoutOrder = 1
    })
    Library:Corner(EmptyTile, UDim.new(1, 0))
    Library:Themed(EmptyTile, "BackgroundColor3", "Ink")
    Library:GlassEdge(EmptyTile, 1, 0.5)
    local EmptyGlyph = IconLabel(EmptyTile, "sparkles", 26, "Ink")
    EmptyGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    EmptyGlyph.Position = UDim2.fromScale(0.5, 0.5)
    local EmptyTitle = New("TextLabel", {
        Parent = EmptyStack,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Font = Library.Font.Bold,
        Text = "How can I help?",
        TextSize = 19,
        LayoutOrder = 2
    })
    Library:Themed(EmptyTitle, "TextColor3", "Text")
    local EmptyText = New("TextLabel", {
        Parent = EmptyStack,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Library.Font.Regular,
        Text = "Ask about this hub, its settings, or anything else.",
        TextSize = 12,
        TextWrapped = true,
        LayoutOrder = 3
    })
    Library:Themed(EmptyText, "TextColor3", "TextDim")
    local Chips = Blank(EmptyStack, { Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 4 })
    Chips.AutomaticSize = Enum.AutomaticSize.Y
    New("UIListLayout", {
        Parent = Chips,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })
    New("UIPadding", { Parent = Chips, PaddingTop = UDim.new(0, 8) })
    local ChipList = {}
    local Ask

    for Index, Seed in ipairs(ChatSeeds) do
        local Chip = New("TextButton", {
            Parent = Chips,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, Mobile and 40 or 36),
            Text = "",
            LayoutOrder = Index
        })
        Library:Corner(Chip, UDim.new(0, 14))
        Library:Themed(Chip, "BackgroundColor3", "Row")
        Library:Themed(Chip, "BackgroundTransparency", "RowAlpha")
        local ChipEdge = Library:GlassEdge(Chip, 1, 0.7)
        New("UISizeConstraint", { Parent = Chip, MaxSize = Vector2.new(340, 100) })
        local ChipText = New("TextLabel", {
            Parent = Chip,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(1, -40, 1, 0),
            Font = Library.Font.Medium,
            Text = Seed,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        Library:Themed(ChipText, "TextColor3", "TextDim")
        local Arrow = IconLabel(Chip, Library.Icons.Right, 14, "TextDisabled")
        Arrow.AnchorPoint = Vector2.new(1, 0.5)
        Arrow.Position = UDim2.new(1, -12, 0.5, 0)
        Chip.MouseEnter:Connect(function()
            Library:Tween(Chip, FAST, { BackgroundTransparency = 0.84 })
            Library:Tween(ChipEdge, FAST, { Transparency = 0.4 })
            Library:Tween(ChipText, FAST, { TextColor3 = Library.Theme.Text })
            Library:Tween(Arrow, FAST, { Position = UDim2.new(1, -8, 0.5, 0) })
        end)
        Chip.MouseLeave:Connect(function()
            Library:Tween(Chip, FAST, { BackgroundTransparency = Library.Theme.RowAlpha })
            Library:Tween(ChipEdge, FAST, { Transparency = 0.7 })
            Library:Tween(ChipText, FAST, { TextColor3 = Library.Theme.TextDim })
            Library:Tween(Arrow, FAST, { Position = UDim2.new(1, -12, 0.5, 0) })
        end)
        Chip.MouseButton1Click:Connect(function()
            Library:Press(Chip)
            Ask(Seed)
        end)
        table.insert(ChipList, Chip)
    end

    local Gate = Blank(Chat, {
        Position = UDim2.fromOffset(0, 54),
        Size = UDim2.new(1, 0, 1, -54),
        Visible = false,
        ZIndex = 3
    })
    Library:Themed(Gate, "BackgroundColor3", "Elevated")
    Gate.BackgroundTransparency = 0.02
    local GateStack = Blank(Gate, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -40, 0, 0)
    })
    GateStack.AutomaticSize = Enum.AutomaticSize.Y
    New("UIListLayout", {
        Parent = GateStack,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
    local GateTile = New("Frame", {
        Parent = GateStack,
        BorderSizePixel = 0,
        BackgroundTransparency = 0.9,
        Size = UDim2.fromOffset(56, 56),
        LayoutOrder = 1
    })
    Library:Corner(GateTile, UDim.new(1, 0))
    Library:Themed(GateTile, "BackgroundColor3", "Ink")
    Library:GlassEdge(GateTile, 1, 0.5)
    local GateGlyph = IconLabel(GateTile, Library.Icons.Key, 24, "Ink")
    GateGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    GateGlyph.Position = UDim2.fromScale(0.5, 0.5)
    local GateTitle = New("TextLabel", {
        Parent = GateStack,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Library.Font.Bold,
        Text = "Connect Groq",
        TextSize = 17,
        LayoutOrder = 2
    })
    Library:Themed(GateTitle, "TextColor3", "Text")
    local GateText = New("TextLabel", {
        Parent = GateStack,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Library.Font.Regular,
        Text = "Paste your Groq API key (gsk...) to start chatting.",
        TextSize = 12,
        TextWrapped = true,
        LayoutOrder = 3
    })
    Library:Themed(GateText, "TextColor3", "TextDim")
    local KeyField = New("Frame", {
        Parent = GateStack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        LayoutOrder = 4
    })
    New("UISizeConstraint", { Parent = KeyField, MaxSize = Vector2.new(360, 44) })
    Library:Corner(KeyField, UDim.new(0, 22))
    Library:Themed(KeyField, "BackgroundColor3", "Inset")
    Library:Themed(KeyField, "BackgroundTransparency", "InsetAlpha")
    local KeyLine = Library:Stroke(KeyField, "StrokeSoft", 1)

    local KeyReal = ""
    local KeyShown = false
    local KeyBox = New("TextBox", {
        Parent = KeyField,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -92, 1, 0),
        Font = Library.Font.Regular,
        PlaceholderText = "gsk_...",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    Library:Themed(KeyBox, "TextColor3", "Text")
    Library:Themed(KeyBox, "PlaceholderColor3", "TextDisabled")

    local function Mask(Text)
        return Text == "" and "" or string.rep("\u{2022}", math.min(#Text, 28))
    end
    local function ShowKeyText()
        KeyBox:SetAttribute("Lock", true)
        KeyBox.Text = KeyShown and KeyReal or Mask(KeyReal)
        KeyBox:SetAttribute("Lock", false)
    end
    KeyBox:GetPropertyChangedSignal("Text"):Connect(function()
        if KeyBox:GetAttribute("Lock") then
            return
        end
        local Typed = KeyBox.Text
        if KeyShown then
            KeyReal = Typed
        elseif not Typed:find("\u{2022}") then
            KeyReal = Typed
            ShowKeyText()
            KeyBox.CursorPosition = #KeyBox.Text + 1
        end
    end)
    KeyBox.Focused:Connect(function()
        Library:Tween(KeyLine, FAST, { Transparency = 0.3 })
    end)
    KeyBox.FocusLost:Connect(function()
        Library:Tween(KeyLine, FAST, { Transparency = Library.Theme.StrokeSoftAlpha })
    end)

    local Eye = GlyphButton(KeyField, Library.Icons.EyeOff, "Show key")
    Eye.AnchorPoint = Vector2.new(1, 0.5)
    Eye.Position = UDim2.new(1, -44, 0.5, 0)
    Eye.Size = UDim2.fromOffset(28, 28)
    Eye.MouseButton1Click:Connect(function()
        KeyShown = not KeyShown
        Library:SetIcon(Eye:FindFirstChildOfClass("ImageLabel"), KeyShown and Library.Icons.Eye or Library.Icons.EyeOff)
        ShowKeyText()
    end)
    local KeySave = GlyphButton(KeyField, Library.Icons.Check, "Save key")
    KeySave.AnchorPoint = Vector2.new(1, 0.5)
    KeySave.Position = UDim2.new(1, -8, 0.5, 0)
    KeySave.Size = UDim2.fromOffset(28, 28)

    local function SetGate(Visible)
        Gate.Visible = Visible
        Field.Visible = not Visible
        Empty.Visible = not Visible and #Current().Messages == 0
        if Visible then
            Library:Rise({ GateTile, GateTitle, GateText, KeyField })
        end
    end

    local function ApplyKey(Value)
        local Key = Trim(Value or "")
        if Key == "" then
            Notify("API key", "Paste a Groq key (gsk...)", "Warn")
            return
        end
        if not Key:lower():find("^gsk") then
            Notify("API key", "Key must start with gsk", "Error")
            Library:Shake(KeyField, 5)
            return
        end
        Notify("API key", "Verifying...", "Info")
        Library:TestGroqKey(Key, function(Ok, Message)
            if not Ok then
                Notify("API key", tostring(Message or "invalid"), "Error")
                Library:Shake(KeyField, 5)
                return
            end
            Library.Groq.Key = Key
            FS.Write(W.Paths.Folder .. "/groq_key.txt", Key)
            KeyReal = ""
            ShowKeyText()
            SetGate(false)
            Notify("API key", "Verified and saved", "Success")
        end)
    end
    KeySave.MouseButton1Click:Connect(function()
        Library:Press(KeySave)
        ApplyKey(KeyReal)
    end)
    KeyBox.FocusLost:Connect(function(Enter)
        if Enter then
            ApplyKey(KeyReal)
        end
    end)

    local SavedKey = FS.Read(W.Paths.Folder .. "/groq_key.txt")
    if type(SavedKey) == "string" and Trim(SavedKey) ~= "" and Library.Groq.Key == "" then
        Library.Groq.Key = Trim(SavedKey)
    end

    local SpinThread
    local function SetBusy(State)
        Busy = State
        Box.PlaceholderText = State and "Waiting for a reply..." or "Message the assistant"
        if State then
            Library:SetIcon(SendIcon, Library.Icons.Refresh)
            Library:Tween(Send, FAST, { BackgroundTransparency = 0.5 })
            SpinThread = task.spawn(function()
                while Busy and SendIcon.Parent do
                    SendIcon.Rotation = 0
                    Library:Tween(SendIcon, TweenInfo.new(0.8, Enum.EasingStyle.Linear), { Rotation = 360 })
                    task.wait(0.8)
                end
                SendIcon.Rotation = 0
            end)
        else
            Library:SetIcon(SendIcon, "arrow-up")
            Library:Tween(Send, FAST, { BackgroundTransparency = 0 })
        end
    end

    local function Context(Chat2)
        local List = {}
        local First = math.max(#Chat2.Messages - 23, 1)
        for Index = First, #Chat2.Messages do
            table.insert(List, Chat2.Messages[Index])
        end
        return List
    end

    local function Request(Chat2)
        SetBusy(true)
        ShowTyping()
        GroqAsk(Context(Chat2), function(Ok, Reply)
            SetBusy(false)
            HideTyping()
            local Visible = Chat2.Id == Store.Active
            if not Ok then
                local Lower = tostring(Reply):lower()
                if Lower:find("api key") or Lower:find("401") or Lower:find("invalid") or Lower:find("unauthorized") or Lower:find("authentication") then
                    Library.Groq.Key = ""
                    if Visible then
                        AddError("The API key was rejected. Paste a valid key to continue.", false)
                        SetGate(true)
                    end
                elseif Visible then
                    AddError(tostring(Reply), true)
                    Stick = true
                    ToBottom(true)
                end
                return
            end
            table.insert(Chat2.Messages, { Role = "assistant", Text = Reply })
            Chat2.Updated = os.time()
            Save()
            if Visible then
                AddAssistant(Reply, { Animate = true })
                Stick = true
                ToBottom(true)
            end
        end)
    end

    local function ClearRows()
        for _, Row in ipairs(Rows) do
            Row:Destroy()
        end
        table.clear(Rows)
        LastAssistant = nil
        TypingRow = nil
    end

    local RefreshList

    local function Render(Animated)
        ClearRows()
        local Chat2 = Current()
        HeadTitle.Text = Chat2.Title
        for _, Message in ipairs(Chat2.Messages) do
            if Message.Role == "user" then
                AddUser(Message.Text)
            else
                AddAssistant(Message.Text)
            end
        end
        Empty.Visible = #Chat2.Messages == 0 and not Gate.Visible
        if Empty.Visible and Animated then
            Library:Rise({ EmptyTile, EmptyTitle, EmptyText, Chips })
        end
        if Animated then
            Library:Rise(Rows)
        end
        Stick = true
        ToBottom(false)
        if Busy then
            ShowTyping()
        end
    end

    function Ask(Text)
        Text = Trim(Text or "")
        if Text == "" then
            return
        end
        if Busy then
            Notify("Chat", "Wait for the current reply", "Warn")
            return
        end
        if Library.Groq.Key == "" then
            SetGate(true)
            return
        end
        local Chat2 = Current()
        table.insert(Chat2.Messages, { Role = "user", Text = Text })
        if Chat2.Title == "New chat" then
            Chat2.Title = Text:sub(1, 34)
            HeadTitle.Text = Chat2.Title
        end
        Chat2.Updated = os.time()
        Save()
        Empty.Visible = false
        AddUser(Text)
        Library:Rise({ Rows[#Rows] })
        Stick = true
        RefreshList()
        Request(Chat2)
    end

    function Regenerate()
        if Busy then
            return
        end
        local Chat2 = Current()
        local Last = Chat2.Messages[#Chat2.Messages]
        if not Last or Last.Role ~= "assistant" then
            return
        end
        table.remove(Chat2.Messages)
        Save()
        if LastAssistant then
            local Index = table.find(Rows, LastAssistant)
            if Index then
                table.remove(Rows, Index)
            end
            LastAssistant:Destroy()
            LastAssistant = nil
        end
        Request(Chat2)
    end

    function Retry(Row)
        if Busy then
            return
        end
        local Index = table.find(Rows, Row)
        if Index then
            table.remove(Rows, Index)
        end
        Row:Destroy()
        local Chat2 = Current()
        local Last = Chat2.Messages[#Chat2.Messages]
        if Last and Last.Role == "user" then
            Request(Chat2)
        end
    end

    local List = New("ScrollingFrame", {
        Parent = Drawer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 64),
        Size = UDim2.new(1, 0, 1, -64),
        ZIndex = 6
    })
    Library:StyleScroll(List)
    New("UIPadding", {
        Parent = List,
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 10)
    })
    New("UIListLayout", {
        Parent = List,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })
    local DrawerTitle = New("TextLabel", {
        Parent = Drawer,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -64, 0, 54),
        Font = Library.Font.Bold,
        Text = "Chats",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6
    })
    Library:Themed(DrawerTitle, "TextColor3", "Text")
    local DrawerNew = GlyphButton(Drawer, Library.Icons.Plus, "New chat")
    DrawerNew.AnchorPoint = Vector2.new(1, 0)
    DrawerNew.Position = UDim2.new(1, -10, 0, 12)
    DrawerNew.ZIndex = 6

    local function SetDrawer(Open)
        DrawerOpen = Open
        if Pinned then
            return
        end
        Scrim.Visible = Open
        Library:Animate(Drawer, NORMAL, { Position = UDim2.fromOffset(Open and 0 or -Drawer.AbsoluteSize.X - 10, 0) })
        Library:Animate(Scrim, NORMAL, { BackgroundTransparency = Open and 0.5 or 1 })
        if not Open then
            task.delay(0.28, function()
                if not DrawerOpen then
                    Scrim.Visible = false
                end
            end)
        end
    end

    local function SwitchTo(Id)
        if Store.Active == Id then
            SetDrawer(false)
            return
        end
        Store.Active = Id
        Save()
        Render(true)
        RefreshList()
        SetDrawer(false)
    end

    function RefreshList()
        for _, Child in ipairs(List:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
        table.sort(Store.Chats, function(A, B)
            return (A.Updated or 0) > (B.Updated or 0)
        end)
        local Active = Current()
        for Index, Chat2 in ipairs(Store.Chats) do
            local IsActive = Chat2.Id == Active.Id
            local Item = New("TextButton", {
                Parent = List,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 48),
                Text = "",
                LayoutOrder = Index,
                BackgroundTransparency = IsActive and 0.86 or 1,
                ZIndex = 6
            })
            Library:Corner(Item, UDim.new(0, 12))
            Library:Themed(Item, "BackgroundColor3", "Ink")
            local Title = New("TextLabel", {
                Parent = Item,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 7),
                Size = UDim2.new(1, -46, 0, 18),
                Font = Library.Font.Medium,
                Text = Chat2.Title,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 7
            })
            Library:Themed(Title, "TextColor3", IsActive and "Text" or "TextDim")
            local Sub = New("TextLabel", {
                Parent = Item,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 25),
                Size = UDim2.new(1, -46, 0, 14),
                Font = Library.Font.Regular,
                Text = #Chat2.Messages .. " messages  |  " .. Ago(Chat2.Updated),
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 7
            })
            Library:Themed(Sub, "TextColor3", "TextDisabled")
            local Delete = GlyphButton(Item, Library.Icons.Trash, "Delete")
            Delete.AnchorPoint = Vector2.new(1, 0.5)
            Delete.Position = UDim2.new(1, -6, 0.5, 0)
            Delete.Size = UDim2.fromOffset(28, 28)
            Delete.ZIndex = 8
            Delete.Visible = IsActive or Device.IsTouch()
            Item.MouseEnter:Connect(function()
                Delete.Visible = true
                if not IsActive then
                    Library:Tween(Item, FAST, { BackgroundTransparency = 0.93 })
                end
            end)
            Item.MouseLeave:Connect(function()
                Delete.Visible = IsActive or Device.IsTouch()
                if not IsActive then
                    Library:Tween(Item, FAST, { BackgroundTransparency = 1 })
                end
            end)
            Item.MouseButton1Click:Connect(function()
                SwitchTo(Chat2.Id)
            end)
            Delete.MouseButton1Click:Connect(function()
                W.API:Dialog({
                    Title = "Delete chat?",
                    Content = "This conversation will be removed permanently.",
                    Type = "Danger",
                    Buttons = {
                        { Title = "Cancel" },
                        { Title = "Delete", Filled = true, Callback = function()
                            local Position = table.find(Store.Chats, Chat2)
                            if Position then
                                table.remove(Store.Chats, Position)
                            end
                            if Store.Active == Chat2.Id then
                                Store.Active = Store.Chats[1] and Store.Chats[1].Id or nil
                                Render(true)
                            end
                            Save()
                            RefreshList()
                        end },
                    },
                })
            end)
        end
    end

    local function StartNew()
        local Chat2 = Current()
        if #Chat2.Messages == 0 then
            SetDrawer(false)
            Box:CaptureFocus()
            return
        end
        NewChat()
        Save()
        Render(true)
        RefreshList()
        SetDrawer(false)
    end

    local function FitField()
        local Wanted = Clamp(Box.TextBounds.Y + 24, 46, 128)
        Field.Size = UDim2.new(1, Mobile and -20 or -24, 0, Wanted)
        Footer.Size = UDim2.new(1, 0, 0, Wanted + 16)
        Log.Size = UDim2.new(1, 0, 1, -(54 + Wanted + 16))
        Empty.Size = Log.Size
        Jump.Position = UDim2.new(0.5, 0, 1, -(Wanted + 26))
    end

    local function Fit()
        local Width = Panel.AbsoluteSize.X / math.max(W.Scale.Scale, 0.001)
        if Width <= 0 then
            return
        end
        Pinned = Width >= 560
        local DrawerWidth = Pinned and 210 or math.min(250, math.floor(Width * 0.82))
        Drawer.Size = UDim2.new(0, DrawerWidth, 1, 0)
        if Pinned then
            Drawer.Position = UDim2.fromOffset(0, 0)
            Chat.Position = UDim2.fromOffset(DrawerWidth, 0)
            Chat.Size = UDim2.new(1, -DrawerWidth, 1, 0)
            Scrim.Visible = false
            MenuButton.Visible = false
        else
            Chat.Position = UDim2.fromOffset(0, 0)
            Chat.Size = UDim2.fromScale(1, 1)
            MenuButton.Visible = true
            Drawer.Position = UDim2.fromOffset(DrawerOpen and 0 or -DrawerWidth - 10, 0)
            Scrim.Visible = DrawerOpen
        end
        local ChatWidth = Pinned and Width - DrawerWidth or Width
        local Left = MenuButton.Visible and 52 or 14
        HeadIcon.Position = UDim2.new(0, Left, 0.5, 0)
        HeadTitle.Position = UDim2.fromOffset(Left + 40, 9)
        HeadTitle.Size = UDim2.new(1, -(Left + 40 + 118), 0, 18)
        ModelButton.Position = UDim2.fromOffset(Left + 40, 27)
        ModelButton.Size = UDim2.new(1, -(Left + 40 + 118), 0, 16)
        for _, Limit in ipairs(Limits) do
            Limit.MaxSize = Vector2.new(math.max(ChatWidth * 0.78 - 28, 120), 100000)
        end
    end
    Panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
    Box:GetPropertyChangedSignal("TextBounds"):Connect(FitField)

    Box:GetPropertyChangedSignal("Text"):Connect(function()
        local Text = Box.Text
        if Text:sub(-1) == "\n" and UserInputService.KeyboardEnabled
            and not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
            Box.Text = Text:sub(1, -2)
            local Value = Box.Text
            Box.Text = ""
            Ask(Value)
        end
    end)
    Box.Focused:Connect(function()
        Library:Tween(FieldLine, FAST, { Transparency = 0.3 })
    end)
    Box.FocusLost:Connect(function()
        Library:Tween(FieldLine, FAST, { Transparency = Library.Theme.StrokeSoftAlpha })
    end)
    Send.MouseButton1Click:Connect(function()
        Library:Press(Send)
        local Value = Box.Text
        Box.Text = ""
        Ask(Value)
    end)

    MenuButton.MouseButton1Click:Connect(function()
        SetDrawer(not DrawerOpen)
    end)
    Scrim.MouseButton1Click:Connect(function()
        SetDrawer(false)
    end)
    NewButton.MouseButton1Click:Connect(StartNew)
    DrawerNew.MouseButton1Click:Connect(StartNew)
    ExportButton.MouseButton1Click:Connect(function()
        local Chat2 = Current()
        local Lines = {}
        for _, Message in ipairs(Chat2.Messages) do
            table.insert(Lines, (Message.Role == "user" and "**You**" or "**Assistant**") .. "\n" .. Message.Text)
        end
        if #Lines == 0 then
            Notify("Chat", "Nothing to copy yet", "Warn")
            return
        end
        CopyText(table.concat(Lines, "\n\n"))
    end)
    CloseButton.MouseButton1Click:Connect(function()
        WM.ToggleAI(W, false)
    end)

    ModelButton.MouseButton1Click:Connect(function()
        local Handle = Popup(W, ModelButton, 240, 14 + #Library.Groq.Models * 34)
        for Index, Model in ipairs(Library.Groq.Models) do
            local Item = New("TextButton", {
                Parent = Handle.Frame,
                BackgroundTransparency = Model == Library.Groq.Model and 0.88 or 1,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(6, 7 + (Index - 1) * 34),
                Size = UDim2.new(1, -12, 0, 31),
                Font = Library.Font.Medium,
                Text = Model,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                ZIndex = Handle.Frame.ZIndex + 1
            })
            Library:Corner(Item, UDim.new(0, 10))
            Library:Themed(Item, "BackgroundColor3", "Ink")
            Library:Themed(Item, "TextColor3", Model == Library.Groq.Model and "Text" or "TextDim")
            New("UIPadding", { Parent = Item, PaddingLeft = UDim.new(0, 12) })
            Item.MouseEnter:Connect(function()
                if Model ~= Library.Groq.Model then
                    Library:Tween(Item, FAST, { BackgroundTransparency = 0.93 })
                end
            end)
            Item.MouseLeave:Connect(function()
                if Model ~= Library.Groq.Model then
                    Library:Tween(Item, FAST, { BackgroundTransparency = 1 })
                end
            end)
            Item.MouseButton1Click:Connect(function()
                Library.Groq.Model = Model
                ModelButton.Text = Model
                Handle:Close()
            end)
        end
    end)

    Panel:SetAttribute("Docked", false)
    task.defer(function()
        Fit()
        FitField()
        RefreshList()
        Render(false)
        SetGate(Library.Groq.Key == "")
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
    if (W.Config.DockPanels or Device.IsTouch()) and W.Content then
        if State then
            DockPanel(W, Panel)
            Panel.Size = UDim2.new(1, 0, 1, 0)
            Panel.Position = UDim2.fromOffset(0, 0)
        else
            Panel.Visible = false
            Panel:SetAttribute("Docked", false)
            RestorePages(W)
        end
        return
    end
    Panel:SetAttribute("Docked", false)
    if State then
        Panel.Visible = true
        Panel.Parent = W.Main
        Panel.AnchorPoint = Vector2.new(1, 0)
        Panel.Size = UDim2.new(0, math.min(320, (W.Main and W.Main.AbsoluteSize.X or 400) * 0.42), 1, -(Top or 54))
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

function WM.BuildAPI(W)
    local API = {}
    W.API = API
    API.Window = W
    API.Gui = W.Gui
    API.Flags = Library.Flags

    function API:AddKey(Key)
        if W.KeySystem.Config then
            table.insert(W.KeySystem.Config.Keys, tostring(Key))
        end
    end

    function API:RemoveKey(Key)
        if W.KeySystem.Config then
            Key = tostring(Key)
            for i = #W.KeySystem.Config.Keys, 1, -1 do
                if W.KeySystem.Config.Keys[i] == Key then
                    table.remove(W.KeySystem.Config.Keys, i)
                end
            end
        end
    end

    function API:SetKeys(List)
        if W.KeySystem.Config then
            W.KeySystem.Config.Keys = List or {}
        end
    end

    function API:GetKeys()
        if W.KeySystem.Config then
            local Copy = {}
            for _, K in ipairs(W.KeySystem.Config.Keys) do
                table.insert(Copy, K)
            end
            return Copy
        end
        return {}
    end

    function API:SetKeyCallback(Fn)
        if W.KeySystem.Config then
            W.KeySystem.Config.Callback = type(Fn) == "function" and Fn or nil
        end
    end

    function API:CheckKey(Value)
        return W.KeySystem.IsValid(tostring(Value))
    end

    function API:ForgetSavedKey()
        if W.Paths.KeyFile then
            pcall(function() FS.Write(W.Paths.KeyFile, "") end)
        end
    end

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

        if Tab.Role then
            local Roles = W.Config.Roles
            local Allowed = true
            if type(Roles) == "table" then
                Allowed = Roles[Tab.Role] == true or Roles[tostring(Tab.Role)] == true
            elseif type(W.RoleCheck) == "function" then
                local Ok, Res = pcall(W.RoleCheck, Tab.Role)
                Allowed = Ok and Res == true
            end
            if not Allowed then
                API:Notify({ Title = "Access denied", Content = "Missing role: " .. tostring(Tab.Role), Type = "Error", Duration = 3 })
                return
            end
        end

        if not Tab.Unlocked then
            local LockConfig = Tab.LockConfig or {}
            WM.Password(W, {
                Title = LockConfig.Title or ("Locked: " .. Tab.Name),
                Description = LockConfig.Description or "Enter your key to unlock this tab",
                Placeholder = LockConfig.Placeholder,
                Confirm = LockConfig.Confirm,
                Verify = LockConfig.Check,
                Remember = LockConfig.Remember ~= false,
                RememberMinutes = LockConfig.RememberMinutes or 10,
                Key = LockConfig.Id or Tab.Name,
                OnUnlock = function(Payload)
                    Tab.Unlocked = true
                    Tab.LockIcon.Visible = false
                    W.SelectTab(Tab)
                    if LockConfig.OnUnlock then
                        task.spawn(LockConfig.OnUnlock, Payload)
                    end
                end
            })
            return
        end

        for _, Entry in ipairs(W.Tabs) do
            local Active = Entry == Tab
            Entry.Page.Visible = Active
            Library:Tween(Entry.Button, FAST, { BackgroundTransparency = Active and (Library.Theme.TabActiveAlpha or 0.84) or 1 })
            if Entry.Stroke then
                Library:Tween(Entry.Stroke, FAST, { Transparency = Active and 0.7 or 1 })
            end
            Library:Tween(Entry.Label, FAST, { TextTransparency = Active and 0 or 0.4 })
            Library:Tween(Entry.IconLabel, FAST, { ImageTransparency = Active and 0 or 0.35 })
            Library:Tween(Entry.Indicator, NORMAL, {
                Size = UDim2.fromOffset(3, Active and 16 or 0)
            })
        end

        W.Active = Tab
        if W.AIPanel and W.AIPanel.Visible and W.AIPanel:GetAttribute("Docked") then
            W.AIPanel.Visible = false
            W.AIPanel:SetAttribute("Docked", false)
        end
        if W.Card and W.Card.Visible and W.Card:GetAttribute("Docked") then
            W.Card.Visible = false
            W.Card:SetAttribute("Docked", false)
        end
        RestorePages(W)
        W.SetPageHead(Tab.Name, Tab.Description, Tab.Icon)
        local Cards = {}
        for _, Child in ipairs(Tab.Page:GetChildren()) do
            if Child:IsA("Frame") and Child.Visible then
                table.insert(Cards, Child)
            end
        end
        table.sort(Cards, function(A, B)
            return A.LayoutOrder < B.LayoutOrder
        end)
        Tab.Page.CanvasPosition = Vector2.new(0, 0)
        Library:Rise(Cards)
        if Tab.OnShow then
            Tab.OnShow()
        end

        local Index = table.find(W.Recent, Tab.Name)
        if Index then
            table.remove(W.Recent, Index)
        end
        table.insert(W.Recent, 1, Tab.Name)

        W.PaintFav()

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
            Line.Color = Library.Theme.Ink
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

    local function HighlightText(Label, Full, Query)
        if not Label then
            return
        end
        Full = tostring(Full or "")
        if Query == "" then
            Label.Text = Full
            Label.RichText = true
            return
        end
        local Lower = Full:lower()
        local Start = Lower:find(Query, 1, true)
        if not Start then
            Label.Text = Full
            return
        end
        local Stop = Start + #Query - 1
        local Before = Full:sub(1, Start - 1)
        local Match = Full:sub(Start, Stop)
        local After = Full:sub(Stop + 1)
        Label.RichText = true
        Label.Text = Before .. '<font color="#FFE566">' .. Match .. '</font>' .. After
    end

    W.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local Query = W.SearchInput.Text:lower()
        for _, Tab in ipairs(W.Tabs) do
            local Match = Query == "" or Tab.Name:lower():find(Query, 1, true) ~= nil
            if not Match then
                for _, Entry in ipairs(W.Index) do
                    if Entry.Tab == Tab.Name and (
                        Entry.Name:lower():find(Query, 1, true)
                        or (Entry.Description or ""):lower():find(Query, 1, true)
                    ) then
                        Match = true
                        break
                    end
                end
            end
            Tab.Button.Visible = Match
            if Tab.Label then
                HighlightText(Tab.Label, Tab.Name, Query)
            end
        end
        for _, Entry in ipairs(W.Index) do
            local Element = Entry.Element
            if Element and Element.Frame and not Element.Registry.Dead then
                local NameHit = Query ~= "" and Entry.Name:lower():find(Query, 1, true)
                local DescHit = Query ~= "" and (Entry.Description or ""):lower():find(Query, 1, true)
                local Hit = Query == "" or NameHit or DescHit
                if Element.TitleLabel then
                    HighlightText(Element.TitleLabel, Element.Title or Entry.Name, Query)
                end
                if Element.DescLabel and (Element.Description or "") ~= "" then
                    HighlightText(Element.DescLabel, Element.Description, Query)
                end
                if Query ~= "" and Element.Frame then
                    Element.Frame.Visible = Hit and (Element.Frame:GetAttribute("UserHidden") ~= true)
                elseif Query == "" and Element.Frame and Element.Frame:GetAttribute("UserHidden") ~= true then
                    Element.Frame.Visible = true
                end
            end
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

    W.SearchInput.FocusLost:Connect(function(Enter)
        if not Enter then
            return
        end
        local Query = W.SearchInput.Text:lower()
        if Query == "" then
            return
        end
        for _, Entry in ipairs(W.Index) do
            if Entry.Name:lower():find(Query, 1, true) or (Entry.Description or ""):lower():find(Query, 1, true) then
                if Entry.Jump then
                    Entry.Jump()
                end
                break
            end
        end
    end)

    W.Panicked = false
    function W.Panic(State)
        if State == nil then
            State = not W.Panicked
        end
        W.Panicked = State and true or false
        if W.Panicked then
            W.SetOpen(false)
            local Flags = W.Config.PanicFlags
            if type(Flags) == "table" then
                for _, Flag in ipairs(Flags) do
                    pcall(function()
                        API:SetFlag(Flag, false)
                    end)
                end
            else
                for Flag, Element in pairs(W.Flags) do
                    if Element and Element.Kind == "Toggle" then
                        pcall(function()
                            Element:Set(false)
                        end)
                    end
                end
            end
            API:Notify({ Title = "Panic", Content = "UI hidden and toggles disabled", Type = "Warn", Duration = 3 })
        else
            W.SetOpen(true)
        end
    end

    table.insert(W.Connections, UserInputService.InputBegan:Connect(function(Input, Typing)
        if Typing then
            return
        end
        if W.Config.PanicKey and Input.KeyCode == W.Config.PanicKey then
            W.Panic()
            return
        end
        if not W.Open or not W.Active then
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
        local Payload = API:GetConfig()
        if type(W.Config.OnSave) == "function" then
            pcall(W.Config.OnSave, Payload, Name)
        end
        local Saved = FS.WriteJSON(W.Paths.Configs .. "/" .. Name .. ".json", Payload)
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
        if type(W.Config.OnLoad) == "function" then
            pcall(W.Config.OnLoad, Data, Name)
        end
        W.Profile = Name
        W.ProfileLabel.Text = Name
        API:SetConfig(Data)
        W.SaveState()
        return true
    end

    function API:ImportConfigURL(Url)
        if type(Url) ~= "string" or Url == "" then
            return false
        end
        local Ok, Body = pcall(HttpGet, Url)
        if not Ok or type(Body) ~= "string" then
            API:Notify({ Title = "Import", Content = "Fetch failed", Type = "Error" })
            return false
        end
        local Ok2, Data = pcall(HttpService.JSONDecode, HttpService, Body)
        if not Ok2 or type(Data) ~= "table" then
            API:Notify({ Title = "Import", Content = "Invalid JSON", Type = "Error" })
            return false
        end
        API:SetConfig(Data.Flags or Data)
        API:Notify({ Title = "Import", Content = "Loaded from URL", Type = "Success" })
        return true
    end

    function API:ResetTabFlags(TabName)
        for Flag, Element in pairs(W.Flags) do
            if Element and Element.Tab == TabName then
                pcall(function()
                    if Element.Default ~= nil then
                        Element:Set(Element.Default, true)
                    end
                end)
            end
        end
    end

    function API:About()
        WM.About(W)
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

    function API:RefreshGroqModels(List)
        return Library:RefreshGroqModels(List)
    end

    function API:ClearGroqKey()
        Library.Groq.Key = ""
        pcall(function()
            FS.Write(W.Paths.Folder .. "/groq_key.txt", "")
        end)
        if W.AIPanel then
            W.AIPanel = nil
        end
    end

    function API:SetCompact(State)
        W.Config.Compact = State and true or false
        W.Relayout()
    end

    function API:SelfTest()
        local Report = { ok = 0, fail = 0, errors = {} }
        local Tab = API:Tab({ Title = "_SelfTest", Icon = "terminal" })
        local Sec = Tab:AddSection("Probe")
        local kinds = {
            function() return Sec:AddToggle({ Title = "t", Default = false }) end,
            function() return Sec:AddSlider({ Title = "s", Min = 0, Max = 10, Default = 1 }) end,
            function() return Sec:AddDropdown({ Title = "d", Options = { "a", "b" }, Default = "a" }) end,
            function() return Sec:AddButton({ Title = "b", Callback = function() end }) end,
            function() return Sec:AddInput({ Title = "i", Default = "" }) end,
            function() return Sec:AddKeybind({ Title = "k", Default = Enum.KeyCode.G }) end,
            function() return Sec:AddParagraph({ Title = "p", Content = "x" }) end,
            function() return Sec:AddProgress({ Title = "pr", Default = 50 }) end,
        }
        for _, Fn in ipairs(kinds) do
            local Ok, Err = pcall(Fn)
            if Ok then
                Report.ok = Report.ok + 1
            else
                Report.fail = Report.fail + 1
                table.insert(Report.errors, tostring(Err))
            end
        end
        pcall(function() Tab:Destroy() end)
        API:Notify({
            Title = "SelfTest",
            Content = string.format("%d ok / %d fail", Report.ok, Report.fail),
            Type = Report.fail == 0 and "Success" or "Warn",
            Duration = 5
        })
        return Report
    end

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

    function API:SetBackground(Spec)
        return W.SetBackground(Spec)
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
            pcall(function()
                API:SaveConfig(W.Profile)
            end)
        end
        for Flag, Element in pairs(W.Flags) do
            pcall(function()
                if Element.Kind == "Toggle" then
                    Element:Set(false, true)
                end
                Element.Locked = true
            end)
        end
        for _, Connection in ipairs(W.Connections) do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(W.Connections)
        for _, Bind in ipairs(W.Keybinds) do
            pcall(function()
                Bind.Element.Locked = true
            end)
        end
        pcall(function()
            Library:ReleaseDragLock()
        end)
        if W.Blur then
            pcall(function()
                W.Blur:Destroy()
            end)
        end
        if W.OnDestroy then
            pcall(W.OnDestroy)
        end
        Library:Tween(W.Main, FAST, { BackgroundTransparency = 1 }, function()
            pcall(function()
                W.Gui:Destroy()
            end)
        end)
    end

    function API:Panic(State)
        return W.Panic(State)
    end

    function API:SetRole(Role, Allowed)
        W.Config.Roles = W.Config.Roles or {}
        W.Config.Roles[Role] = Allowed and true or false
    end

    function API:SetRoleCheck(Fn)
        W.RoleCheck = type(Fn) == "function" and Fn or nil
    end

    function API:RegisterNotifyTemplate(Name, Template)
        Library:RegisterNotifyTemplate(Name, Template)
    end

    if W.Config.GroqApiKey then
        Library:SetGroq(W.Config.GroqApiKey, W.Config.GroqPrompt, W.Config.GroqModel)
    end

    if W.Config.AutoLoad then
        local Data = FS.ReadJSON(W.Paths.Configs .. "/" .. W.Profile .. ".json")
        if type(Data) == "table" then
            W.Pending = Data.Flags or Data
        end
    end

    if W.Config.DebugLayout or W.Config.ShowPerf then
        local Hud = New("TextLabel", {
            Parent = W.Gui,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -8, 0, 8),
            Size = UDim2.fromOffset(160, 48),
            Font = Library.Font.Mono,
            Text = "perf",
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 900
        })
        Library:Corner(Hud, UDim.new(0, 12))
        Library:Themed(Hud, "BackgroundColor3", "Elevated")
        Library:Themed(Hud, "TextColor3", "TextDim")
        New("UIPadding", { Parent = Hud, PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6) })
        task.spawn(function()
            while W.Gui and W.Gui.Parent do
                local Flags = 0
                for _ in pairs(W.Flags) do Flags = Flags + 1 end
                Hud.Text = string.format("flags %d\nconns %d\ntabs %d", Flags, #W.Connections, #W.Tabs)
                if W.Config.DebugLayout and W.Main then
                    for _, D in ipairs(W.Main:GetDescendants()) do
                        if D:IsA("GuiObject") and D:GetAttribute("Dbg") then
                            -- already marked
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end

    W.SetOpen(true)
    return API
end

return Library
