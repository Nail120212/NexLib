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
        local Fill = { key = tostring(Value), hwid = ReadHwid() }
        local Url = tostring(Cfg.Url):gsub("{key}", function() return UrlEncode(Fill.key) end)
            :gsub("{hwid}", function() return UrlEncode(Fill.hwid) end)
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
        Main = Color3.fromRGB(10, 12, 22),
        Sidebar = Color3.fromRGB(255, 255, 255),
        Card = Color3.fromRGB(255, 255, 255),
        Row = Color3.fromRGB(255, 255, 255),
        Inset = Color3.fromRGB(2, 4, 12),
        Elevated = Color3.fromRGB(11, 13, 25),
        Accent = Color3.fromRGB(150, 118, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(240, 243, 255),
        TextDim = Color3.fromRGB(172, 180, 208),
        TabText = Color3.fromRGB(226, 231, 250),
        TextDisabled = Color3.fromRGB(128, 136, 164),
        Neutral = Color3.fromRGB(200, 205, 225),
        Stroke = Color3.fromRGB(225, 232, 255),
        StrokeSoft = Color3.fromRGB(185, 195, 240),
        Sheen = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 10),
        Track = Color3.fromRGB(92, 100, 136),
        Success = Color3.fromRGB(110, 240, 168),
        Warn = Color3.fromRGB(255, 218, 120),
        Error = Color3.fromRGB(255, 120, 130),
        Info = Color3.fromRGB(120, 180, 255),
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
        AccentFillAlpha = 0.1,
        AccentHoverAlpha = 0.0,
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
    Command = "command",
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

function Library:StyleScroll(Scroll)
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageTransparency = 0.55
    Scroll.BorderSizePixel = 0
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.CanvasSize = UDim2.new()
    Library:Themed(Scroll, "ScrollBarImageColor3", "Accent")
    return Scroll
end

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
    if DragLockCount ~= 1 then
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
            Enum.UserInputType.MouseWheel,
            Enum.KeyCode.Thumbstick2)
    end)
    pcall(function()
        GuiService.TouchControlsEnabled = false
    end)
end

function Library:EndDragLock()
    DragLockCount = math.max(DragLockCount - 1, 0)
    if DragLockCount ~= 0 then
        return
    end
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
        GuiService.TouchControlsEnabled = true
    end)
    DragLockPrevBehavior = nil
    DragLockPrevIcon = nil
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

local function PillButton(Parent, Text, IconName, Width, Accent)
    local Button = New("TextButton", {
        Parent = Parent,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.new(0, Width or 96, 0, 30),
        Text = ""
    })
    Library:Corner(Button, UDim.new(1, 0))
    Library:Themed(Button, "BackgroundColor3", Accent and "Accent" or "Row")
    Library:Themed(Button, "BackgroundTransparency", Accent and "AccentFillAlpha" or "ButtonAlpha")

    local Line = New("UIStroke", {
        Parent = Button,
        Thickness = 1,
        Transparency = Accent and 0.3 or 0.45,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(Line, "Color", Accent and "Accent" or "Stroke")
    local IdleLine = Accent and 0.3 or 0.45
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
    if Accent then
        New("UIGradient", {
            Parent = Button,
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 196, 218))
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
        Icon = IconLabel(Holder, IconName, 15, Accent and "AccentText" or "Text")
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
    Library:Themed(TextPart, "TextColor3", Accent and "AccentText" or "Text")

    Button.MouseEnter:Connect(function()
        Library:Tween(Button, FAST, {
            BackgroundTransparency = Accent and (Library.Theme.AccentHoverAlpha or 0) or (Library.Theme.ButtonHoverAlpha or 0.8)
        })
        Library:Tween(Line, FAST, { Transparency = Accent and 0.1 or 0.2 })
    end)
    Button.MouseLeave:Connect(function()
        Library:Tween(Button, FAST, {
            BackgroundTransparency = Accent and (Library.Theme.AccentFillAlpha or 0.1) or (Library.Theme.ButtonAlpha or 0.88)
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
        Color = nil,
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
        local Accent = Library.Theme.Accent
        W.State.Accent = {
            math.floor(Accent.R * 255 + 0.5),
            math.floor(Accent.G * 255 + 0.5),
            math.floor(Accent.B * 255 + 0.5)
        }
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
            Library:Themed(Avatar, "BackgroundColor3", "Accent")
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
                Library:Themed(V, "TextColor3", "Accent")
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
            local BanIcon = IconLabel(Banner, Library.Icons.User, 16, "Accent")
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
            Library:Themed(BanText, "TextColor3", "Accent")

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
            Library:Themed(VerifyBtn, "BackgroundColor3", "Accent")
            local Vtx = New("TextLabel", {
                Parent = VerifyBtn,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Font = Library.Font.Bold,
                Text = "Verify Key",
                TextSize = 14,
                ZIndex = 1004
            })
            Library:Themed(Vtx, "TextColor3", "AccentText")

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
                Library:Themed(Head, "TextColor3", "Accent")
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
        Color3.fromRGB(176, 184, 220)
    }, 90)
    Library:Shadow(W.Root, 80, 0.62)

    -- soft ambient colour blobs behind the content (fluid look). Sized by window
    -- height so they stay inside the rounded corners, and never take input.
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
    Orb(0.78, 0.3, 0.52, "Accent")
    Orb(0.3, 0.78, 0.44, "Info")
    Orb(0.14, 0.22, 0.34, "Accent")

    Library:Gloss(W.Main, 0.97)
    W.Sheen = Library:Sheen(W.Main, 90)
    W.Sheen.ZIndex = 2

    function W.Fit()
        local Viewport = Device.Viewport()
        local Inset = 0
        if W.Config.SafeArea then
            local Ok, GuiInset = pcall(function()
                return GuiService:GetGuiInset()
            end)
            if Ok and GuiInset then
                Inset = (GuiInset.Y or 0) + 8
            else
                Inset = W.Mobile and 24 or 0
            end
        end
        local Wanted = W.Config.Size
        local Width, Height
        local Scale = 1

        if W.Maximized then
            Width = Viewport.X - 40
            Height = Viewport.Y - 60 - (W.Config.SafeArea and (W.Mobile and 28 or 0) or 0)
        else
            Width = math.max(Wanted.X.Offset, 1)
            Height = math.max(Wanted.Y.Offset, 1)
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
    Library:Corner(W.LogoTile, UDim.new(0, 12))
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

    Badge(W.Config.Version, "Accent", 2)
    Badge(W.Config.Tag, "Success", 3)

    local ControlsWidth = W.Mobile and 200 or 320
    W.Controls = Blank(W.Header, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, ControlsWidth, 0, 30),
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

    if W.Config.ShowTheme then
        Control(Library.Icons.Palette, "Theme", 2, function()
            WM.ThemePanel(W)
        end, true)
    end
    if W.Config.ShowConfig then
        Control(Library.Icons.Save, "Configs", 3, function()
            WM.ConfigPanel(W)
        end, false)
    end
    if W.Config.ShowKeybinds then
        Control(Library.Icons.Key, "Keybinds", 4, function()
            WM.KeybindPanel(W)
        end, false)
    end
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
    if W.Config.ShowChangelog then
        Control(Library.Icons.Sparkles, "Changelog", 6.5, function()
            WM.Changelog(W, {
                Entries = {
                    { Version = "v2.1.0", Notes = { "Removed mobile size limit", "Configurable topbar icons", "AI panel API key input", "Design consistency pass", "Version 2.1.0" } },
                    { Version = "v2.0.0", Notes = { "Rebuilt component API", "Added Dark glass theme", "Added config profiles" } },
                    { Version = "v1.0.0", Notes = { "Initial release" } },
                },
            })
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
        if W.API and W.API.Dialog then
            W.API:Dialog({
                Title = "Close window?",
                Content = "This will unload the UI. You can open it again from the float button if you only minimize.",
                Buttons = {
                    { Title = "Cancel" },
                    { Title = "Close", Accent = true, Callback = function()
                        W.API:Destroy()
                    end },
                },
            })
        else
            W.API:Destroy()
        end
    end, true)

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

    local StarYellow = Color3.fromRGB(255, 205, 64)
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
        Library:SetIcon(W.PageIcon, Icon or Library.Icons.Tab, Library.Theme.Accent)
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

    function W.Relayout()
        local HeaderHeight = W.Header.Size.Y.Offset
        W.Body.Position = UDim2.new(0, 0, 0, HeaderHeight)
        W.Body.Size = UDim2.new(1, 0, 1, -HeaderHeight)
        W.MenuButton.Visible = false
        W.SidebarWidth = W.Mobile and 148 or (Device.Viewport().X < 560 and 140 or 156)
        W.Sidebar.Size = UDim2.new(0, W.SidebarWidth - 12, 1, -14)
        W.Sidebar.Visible = true
        W.Sidebar.Position = UDim2.fromOffset(8, 6)
        W.Sidebar.ZIndex = 3
        W.Backdrop.Visible = false
        W.Content.Position = UDim2.new(0, W.SidebarWidth, 0, 0)
        W.Content.Size = UDim2.new(1, -W.SidebarWidth, 1, 0)
        W.Controls.Size = UDim2.new(0, W.Mobile and 220 or 320, 0, 30)
        if W.MaxButton then
            W.MaxButton.Visible = not W.Mobile
        end
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
    W.FloatButton = New("Frame", {
        Parent = W.Gui,
        AnchorPoint = Vector2.new(1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -18, 1, -18),
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
    Library:Themed(FloatLogo, "BackgroundColor3", "Accent")
    local FloatLogoImg = New("ImageLabel", {
        Parent = FloatLogo,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Image = W.Config.Logo or "",
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 602
    })
    if W.Config.Icon then
        Library:SetIcon(FloatLogoImg, W.Config.Icon, Library.Theme.AccentText)
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
    Library:Themed(FloatOpen, "BackgroundColor3", "Accent")
    FloatOpen.BackgroundTransparency = 0.82
    local FloatScan = IconLabel(FloatOpen, Library.Icons.Scan, W.Mobile and 18 or 16, "Accent")
    FloatScan.AnchorPoint = Vector2.new(0.5, 0.5)
    FloatScan.Position = UDim2.fromScale(0.5, 0.5)
    FloatScan.ZIndex = 604
    Library:Themed(FloatScan, "ImageColor3", "Accent")

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
                W.SaveState()
            end
        end))
    end

    if type(W.State.FloatPosition) == "table" and #W.State.FloatPosition >= 4 then
        local FP = W.State.FloatPosition
        W.FloatButton.Position = UDim2.new(FP[1], FP[2], FP[3], FP[4])
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
            Library:Pop(W.Main, 0.32, 0.94)
            Library:Animate(W.Main, NORMAL, { BackgroundTransparency = Library.Theme.WindowAlpha })
            if W.Sidebar then
                local SideScale = W.Sidebar:FindFirstChildOfClass("UIScale") or New("UIScale", { Parent = W.Sidebar, Scale = 0.92 })
                SideScale.Scale = 0.92
                Library:Animate(SideScale, SPRING, { Scale = 1 })
            end
            if W.Blur then
                Library:Animate(W.Blur, NORMAL, { Size = Library.Theme.Blur })
            end
        else
            W.FloatButton.Visible = true
            Library:Pop(W.FloatButton, 0.3, 0.8)
            W.Root.Visible = false
            if W.Blur then
                Library:Animate(W.Blur, FAST, { Size = 0 })
            end
        end
        Library:Feedback(State and 1.1 or 0.9)
    end

    table.insert(W.Connections, UserInputService.InputBegan:Connect(function(Input, Typing)
        if Typing then
            return
        end
        if Input.KeyCode == W.Config.ToggleKey then
            W.SetOpen()
        end
        WM.FireKeybinds(W, Input)
    end))

    table.insert(W.Connections, UserInputService.InputEnded:Connect(function(Input)
        WM.FireKeybinds(W, Input, true)
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
    Library:Themed(Tab.Button, "BackgroundColor3", "Accent")
    Tab.Button.BackgroundTransparency = 1

    Tab.Stroke = New("UIStroke", {
        Parent = Tab.Button,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(Tab.Stroke, "Color", "Accent")

    Tab.Indicator = New("Frame", {
        Parent = Tab.Button,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0.5, 0),
        Size = UDim2.fromOffset(3, 0),
        ZIndex = W.Sidebar.ZIndex + 2
    })
    Library:Corner(Tab.Indicator, UDim.new(1, 0))
    Library:Themed(Tab.Indicator, "BackgroundColor3", "Accent")

    Tab.IconLabel = IconLabel(Tab.Button, Config.Icon, W.Mobile and 20 or 16, "Accent")
    Tab.IconLabel.AnchorPoint = Vector2.new(0, 0.5)
    Tab.IconLabel.Position = UDim2.new(0, 16, 0.5, 0)
    Tab.IconLabel.ImageTransparency = 0.35
    Library:Themed(Tab.IconLabel, "ImageColor3", "Accent")
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
    Library:Themed(Tab.RoleBadge, "BackgroundColor3", "Accent")
    Library:Themed(Tab.RoleBadge, "TextColor3", "Accent")

    Tab.Unlocked = Config.Lock == nil
    Tab.Role = Config.Role

    if Config.Lock then
        local LockConfig = type(Config.Lock) == "table" and Config.Lock or { Password = Config.LockPassword }
        LockConfig.RememberMinutes = tonumber(LockConfig.RememberMinutes) or 10
        local Remember = W.State["unlock_" .. Config.Title]
        local Ok = false
        if type(Remember) == "table" then
            local Until = tonumber(Remember["until"] or Remember.Until)
            local Pw = tostring(Remember.pw or Remember.Password or "")
            if Until and Until > os.time() and Pw == tostring(LockConfig.Password) then
                Ok = true
            else
                W.State["unlock_" .. Config.Title] = nil
            end
        elseif type(Remember) == "string" then
            W.State["unlock_" .. Config.Title] = nil
        end
        if Ok then
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
    local Backdrop = New("TextButton", {
        Parent = Overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 201
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
        ZIndex = 202,
        ClipsDescendants = true
    })
    Library:Corner(Frame, UDim.new(0, 14))
    Library:Themed(Frame, "BackgroundColor3", "Elevated")
    Library:Themed(Frame, "BackgroundTransparency", "ElevatedAlpha")
    Library:GlassEdge(Frame, 1.2, 0.3)
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
    Track.BackgroundColor3 = Library.Theme.Track or Color3.fromRGB(78, 84, 112)
    Track.BackgroundTransparency = Library.Theme.TrackAlpha or 0.2
    local TrackLine = Library:Stroke(Track, "StrokeSoft", 1)

    local Knob = New("Frame", {
        Parent = Track,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(KnobSize, KnobSize),
        BackgroundColor3 = Color3.fromRGB(205, 210, 228),
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
            BackgroundColor3 = State and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(205, 210, 228)
        })
        Library:Tween(Track, Info, {
            BackgroundColor3 = State and Theme.Accent or (Theme.Track or Color3.fromRGB(78, 84, 112)),
            BackgroundTransparency = State and 0.05 or (Theme.TrackAlpha or 0.2)
        })
        Library:Tween(TrackLine, Info, {
            Color = State and Theme.Accent or Theme.StrokeSoft,
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
    Library:Themed(Chip, "BackgroundColor3", "Accent")
    local ChipLine = New("UIStroke", {
        Parent = Chip,
        Thickness = 1,
        Transparency = 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(ChipLine, "Color", "Accent")

    local Arrow = IconLabel(Chip, Config.Icon or Library.Icons.Right, 14, "Accent")
    Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    Arrow.Position = UDim2.fromScale(0.5, 0.5)
    Arrow.ZIndex = 7
    Library:Themed(Arrow, "ImageColor3", "Accent")

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
        Library:Themed(Chip, "BackgroundColor3", "Accent")
        local ChipLine = New("UIStroke", {
            Parent = Chip,
            Thickness = 1,
            Transparency = 0.6,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Library:Themed(ChipLine, "Color", "Accent")
        local Glyph = IconLabel(Chip, Config.Icon, 16, "Accent")
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
    Library:Themed(Fill, "BackgroundColor3", "Accent")
    New("UIGradient", {
        Parent = Fill,
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 215))
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
    Library:Themed(KnobHalo, "Color", "Accent")
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
                        Size = UDim2.new(1, 0, 0, 29),
                        Text = "",
                        AutoButtonColor = false,
                        LayoutOrder = Index,
                        BackgroundTransparency = Active and 0.85 or 1,
                        ZIndex = (Handle and Handle.Frame and Handle.Frame.ZIndex or 202) + 2
                    })
                    Library:Corner(Item, UDim.new(0, 14))
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
                        ZIndex = (Handle and Handle.Frame and Handle.Frame.ZIndex or 202) + 3
                    })

                    if Active then
                        local Mark = IconLabel(Item, Library.Icons.Check, 14, "Accent")
                        Mark.AnchorPoint = Vector2.new(1, 0.5)
                        Mark.Position = UDim2.new(1, -8, 0.5, 0)
                        Mark.ZIndex = (Handle and Handle.Frame and Handle.Frame.ZIndex or 202) + 3
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
        Default = Color3.fromRGB(179, 0, 255),
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
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 215))
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
            local Left, LeftText = PillButton(Line, First.Title or First.Text or "Button", First.Icon, 0, First.Accent)
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

            local Right, RightText = PillButton(Line, Second.Title or Second.Text or "Button", Second.Icon, 0, Second.Accent)
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
            local Full, FullText = PillButton(Line, First.Title or First.Text or "Button", First.Icon, 0, First.Accent)
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
    Library:Themed(NoteBar, "BackgroundColor3", "Accent")
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
        Library:Themed(Chip, "BackgroundColor3", "Accent")
        local ChipLine = New("UIStroke", {
            Parent = Chip,
            Thickness = 1,
            Transparency = 0.6,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Library:Themed(ChipLine, "Color", "Accent")
        local Icon = IconLabel(Chip, Config.Icon, 15, "Accent")
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.Position = UDim2.fromScale(0.5, 0.5)
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
        Library:Themed(PillLine, "Color", "Accent")
    end
    if typeof(TagColor) == "Color3" then
        Pill.BackgroundColor3 = TagColor
    else
        Library:Themed(Pill, "BackgroundColor3", "Accent")
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
            Library:Themed(TagIcon, "ImageColor3", "Accent")
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
        Library:Themed(Text, "TextColor3", "Accent")
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
    for Index, DotColor in ipairs({ Color3.fromRGB(255, 95, 86), Color3.fromRGB(255, 189, 46), Color3.fromRGB(39, 201, 63) }) do
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
    Library:Themed(PercentChip, "BackgroundColor3", "Accent")
    local PercentLine = New("UIStroke", {
        Parent = PercentChip,
        Thickness = 1,
        Transparency = 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(PercentLine, "Color", "Accent")
    local Percent = New("TextLabel", {
        Parent = PercentChip,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Library.Font.Bold,
        Text = "0%",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    Library:Themed(Percent, "TextColor3", "Accent")

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
    Library:Themed(Fill, "BackgroundColor3", "Accent")
    New("UIGradient", {
        Parent = Fill,
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 215))
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
            Library:Themed(Chip, "BackgroundColor3", "Accent")
            local ChipLine = New("UIStroke", {
                Parent = Chip,
                Thickness = 1,
                Transparency = 0.6,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            Library:Themed(ChipLine, "Color", "Accent")
            local Icon = IconLabel(Chip, Info.Icon, 15, "Accent")
            Icon.AnchorPoint = Vector2.new(0.5, 0.5)
            Icon.Position = UDim2.fromScale(0.5, 0.5)
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
    Library:Themed(Fill, "BackgroundColor3", "Accent")
    New("UIGradient", {
        Parent = Fill,
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 215))
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
        Library:Themed(Halo, "Color", "Accent")
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
            Btn.BackgroundColor3 = Library.Theme.Accent
            Library:Tween(Btn, FAST, { BackgroundTransparency = On and 0.08 or 1 })
            local Lab = Btn:FindFirstChildOfClass("TextLabel")
            if Lab then
                Library:Tween(Lab, FAST, {
                    TextColor3 = On and Library.Theme.AccentText or Library.Theme.TextDim
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
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 196, 218))
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
            Entry.Item.BackgroundColor3 = On and Library.Theme.Accent or Library.Theme.Inset
            Library:Tween(Entry.Item, FAST, { BackgroundTransparency = On and 0.8 or Library.Theme.InsetAlpha })
            Library:Tween(Entry.Label, FAST, { TextColor3 = On and Library.Theme.Accent or Library.Theme.TextDim })
            Library:Tween(Entry.Line, FAST, { Color = On and Library.Theme.Accent or Library.Theme.StrokeSoft, Transparency = On and 0.45 or Library.Theme.StrokeSoftAlpha })
            Entry.Icon.ImageColor3 = On and Library.Theme.Accent or Library.Theme.TextDisabled
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
    Switch.BackgroundColor3 = Library.Theme.Track or Color3.fromRGB(92, 100, 136)
    Switch.BackgroundTransparency = Library.Theme.TrackAlpha or 0.35
    local SwitchLine = Library:Stroke(Switch, "StrokeSoft", 1)

    local Knob = New("Frame", {
        Parent = Switch,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(KnobSize, KnobSize),
        BackgroundColor3 = Color3.fromRGB(205, 210, 228),
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
            BackgroundColor3 = State and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(205, 210, 228)
        })
        Library:Tween(Switch, Info, {
            BackgroundColor3 = State and Theme.Accent or (Theme.Track or Color3.fromRGB(92, 100, 136)),
            BackgroundTransparency = State and 0.05 or (Theme.TrackAlpha or 0.35)
        })
        Library:Tween(SwitchLine, Info, {
            Color = State and Theme.Accent or Theme.StrokeSoft,
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
                { Title = "Confirm", Accent = true, Callback = function()
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
            local Ic = IconLabel(Btn, Info.Icon, 18, "Accent")
            Ic.AnchorPoint = Vector2.new(0.5, 0.5)
            Ic.Position = UDim2.fromScale(0.5, 0.5)
            Library:Themed(Ic, "ImageColor3", "Accent")
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

    local ButtonCount = #Config.Buttons
    for Index, Info in ipairs(Config.Buttons) do
        local Button = PillButton(Footer, Info.Text or Info.Title or "Ok", Info.Icon, 110, Info.Accent)
        if ButtonCount >= 3 then
            Button.Size = UDim2.new(1 / ButtonCount, -(8 * (ButtonCount - 1)) / ButtonCount, 0, 30)
        end
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
                local Mins = 10
                if Config.RememberMinutes then
                    Mins = tonumber(Config.RememberMinutes) or 10
                end
                W.State["unlock_" .. Config.Key] = {
                    pw = tostring(Config.Password),
                    ["until"] = os.time() + math.floor(Mins * 60)
                }
                W.SaveState()
            end
            if Config.OnUnlock then
                task.spawn(Config.OnUnlock)
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
        Library:Corner(Card, UDim.new(0, 14))
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
        Library:Corner(Swatch, UDim.new(0, 12))
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
    Library:Corner(HueTrack, UDim.new(0, 9))
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


    Caption("Tokens", 4.5)
    local TokenHost = New("Frame", {
        Parent = Scroll,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 4.5,
        ZIndex = Handle.Frame.ZIndex + 3
    })
    New("UIListLayout", {
        Parent = TokenHost,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })
    local TokenKeys = { "Accent", "TabText", "Text", "TextDim", "Success", "Warn", "Error", "Info" }
    for Ti, Tk in ipairs(TokenKeys) do
        local Row = New("Frame", {
            Parent = TokenHost,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 28),
            LayoutOrder = Ti,
            ZIndex = TokenHost.ZIndex + 1
        })
        Library:Corner(Row, UDim.new(0, 10))
        Library:Themed(Row, "BackgroundColor3", "Row")
        Library:Themed(Row, "BackgroundTransparency", "RowAlpha")
        local Lab = New("TextLabel", {
            Parent = Row,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -50, 1, 0),
            Font = Library.Font.Medium,
            Text = Tk,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = Row.ZIndex + 1
        })
        Library:Themed(Lab, "TextColor3", "TextDim")
        local Sw = New("TextButton", {
            Parent = Row,
            AnchorPoint = Vector2.new(1, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(22, 18),
            Text = "",
            AutoButtonColor = false,
            BackgroundColor3 = Library.Theme[Tk] or Color3.new(1,1,1),
            ZIndex = Row.ZIndex + 1
        })
        Library:Corner(Sw, UDim.new(0, 7))
        Sw.MouseButton1Click:Connect(function()
            local H = Popup(W, Sw, 160, 28)
            local Track = New("Frame", {
                Parent = H.Frame,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(8, 6),
                Size = UDim2.new(1, -16, 0, 16),
                ZIndex = H.Frame.ZIndex + 2,
                Active = true
            })
            Library:Corner(Track, UDim.new(0, 6))
            local Kp = {}
            for i = 0, 6 do
                table.insert(Kp, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.9, 1)))
            end
            New("UIGradient", { Parent = Track, Color = ColorSequence.new(Kp) })
            local function Apply(Pos)
                local A = Clamp((Pos.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
                local Col = Color3.fromHSV(A, 0.85, 1)
                Library.Theme[Tk] = Col
                if Library.Themes[Library.CurrentTheme] then
                    Library.Themes[Library.CurrentTheme][Tk] = Col
                end
                Sw.BackgroundColor3 = Col
                Library:RefreshTheme()
            end
            Track.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Apply(Input.Position)
                end
            end)
        end)
    end

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
        Library:Corner(Button, UDim.new(0, 12))
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
            local Button, TextLabel = PillButton(Actions, Info.Text or "Ok", Info.Icon, 0, Info.Accent)
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

function WM.PlayerCard(W)
    if W.Card then
        return W.Card
    end

    local Mobile = Device.IsMobile()
    local Yellow = Color3.fromRGB(255, 205, 64)

    local Card = New("Frame", {
        Parent = W.Gui,
        Name = "PlayerCard",
        AnchorPoint = Vector2.new(1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.fromOffset(Mobile and 304 or 348, Mobile and 344 or 456),
        Visible = false,
        ZIndex = 400
    })
    Library:Corner(Card, UDim.new(0, 22))
    Library:Themed(Card, "BackgroundColor3", "Elevated")
    Library:Themed(Card, "BackgroundTransparency", "ElevatedAlpha")
    Library:GlassEdge(Card, 1.3, 0.25)
    Library:Shadow(Card, 60, 0.6)
    Library:Sheen(Card, 90).ZIndex = 400

    -- ------------------------------------------------------------------ hero card
    local Hero = New("Frame", {
        Parent = Card,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.new(1, -28, 0, 100),
        ZIndex = 401
    })
    Library:Corner(Hero, UDim.new(0, 18))
    Library:Themed(Hero, "BackgroundColor3", "Row")
    Library:Themed(Hero, "BackgroundTransparency", "RowAlpha")
    Library:GlassEdge(Hero, 1, 0.45)
    Library:Gloss(Hero, 0.93)

    local Avatar = New("ImageLabel", {
        Parent = Hero,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(72, 72),
        ZIndex = 402
    })
    Library:Corner(Avatar, UDim.new(1, 0))
    Library:Themed(Avatar, "BackgroundColor3", "Row")
    local Ring = New("UIStroke", {
        Parent = Avatar,
        Thickness = 2.5,
        Transparency = 0.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(Ring, "Color", "Accent")

    local OnlineDot = New("Frame", {
        Parent = Avatar,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Library.Theme.Success,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 1, -1),
        Size = UDim2.fromOffset(16, 16),
        ZIndex = 404
    })
    Library:Corner(OnlineDot, UDim.new(1, 0))
    Library:Themed(OnlineDot, "BackgroundColor3", "Success")
    local DotCut = New("UIStroke", {
        Parent = OnlineDot,
        Thickness = 3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(DotCut, "Color", "Elevated")

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
        Parent = Hero,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(100, 16),
        Size = UDim2.new(1, -150, 0, 22),
        Font = Library.Font.Bold,
        Text = LocalPlayer.DisplayName,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 402
    })
    Library:Themed(Name, "TextColor3", "Text")

    local Handle2 = New("TextLabel", {
        Parent = Hero,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(100, 38),
        Size = UDim2.new(1, -150, 0, 14),
        Font = Library.Font.Regular,
        Text = "@" .. LocalPlayer.Name,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 402
    })
    Library:Themed(Handle2, "TextColor3", "TextDim")

    local function Chip(Parent, Text, Tone, Order)
        local Item = New("TextLabel", {
            Parent = Parent,
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 18),
            Font = Library.Font.Bold,
            Text = "  " .. Text .. "  ",
            TextSize = 10,
            LayoutOrder = Order,
            ZIndex = 402
        })
        Library:Corner(Item, UDim.new(1, 0))
        local Line = New("UIStroke", {
            Parent = Item,
            Thickness = 1,
            Transparency = 0.6,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        if typeof(Tone) == "Color3" then
            Item.BackgroundColor3 = Tone
            Item.TextColor3 = Tone
            Line.Color = Tone
        else
            Library:Themed(Item, "BackgroundColor3", Tone)
            Library:Themed(Item, "TextColor3", Tone)
            Library:Themed(Line, "Color", Tone)
        end
        return Item
    end

    local Badges = New("Frame", {
        Parent = Hero,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(100, 62),
        Size = UDim2.new(1, -112, 0, 20),
        ZIndex = 402
    })
    New("UIListLayout", {
        Parent = Badges,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Chip(Badges, ExecutorName(), "Accent", 1)
    Chip(Badges, Device.IsMobile() and "Mobile" or "Desktop", "Info", 2)
    if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
        Chip(Badges, "Premium", Yellow, 3)
    end

    local Close = GlyphButton(Hero, Library.Icons.Close, "Close")
    Close.AnchorPoint = Vector2.new(1, 0)
    Close.Position = UDim2.new(1, -8, 0, 8)
    Close.ZIndex = 403
    for _, Child in ipairs(Close:GetDescendants()) do
        if Child:IsA("GuiObject") then
            Child.ZIndex = 404
        end
    end

    -- ------------------------------------------------------------------ info cards
    local Grid = New("ScrollingFrame", {
        Parent = Card,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 126),
        Size = UDim2.new(1, -28, 1, -(126 + 58)),
        ZIndex = 401,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Library:StyleScroll(Grid)
    local GridLayout = New("UIGridLayout", {
        Parent = Grid,
        CellPadding = UDim2.fromOffset(8, 8),
        CellSize = UDim2.new(0.5, -4, 0, 66),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirectionMaxCells = 2
    })
    New("UIPadding", {
        Parent = Grid,
        PaddingBottom = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })

    local Values = {}
    local Ordered = {}

    local function Tile(Key, IconName, Label, Text, Order, Copyable, Live)
        local Box = New("Frame", {
            Parent = Grid,
            BorderSizePixel = 0,
            LayoutOrder = Order,
            ZIndex = 401
        })
        Library:Corner(Box, UDim.new(0, 16))
        Library:Themed(Box, "BackgroundColor3", "Row")
        Library:Themed(Box, "BackgroundTransparency", "RowAlpha")
        Library:GlassEdge(Box, 1, 0.6)
        Library:Gloss(Box, 0.95)

        local ChipIcon = New("Frame", {
            Parent = Box,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(10, 9),
            Size = UDim2.fromOffset(22, 22),
            BackgroundTransparency = 0.82,
            ZIndex = 402
        })
        Library:Corner(ChipIcon, UDim.new(1, 0))
        Library:Themed(ChipIcon, "BackgroundColor3", "Accent")
        local Icon = IconLabel(ChipIcon, IconName, 12, "Accent")
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.Position = UDim2.fromScale(0.5, 0.5)
        Icon.ZIndex = 403
        Library:Themed(Icon, "ImageColor3", "Accent")

        local Tag = New("TextLabel", {
            Parent = Box,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(40, 9),
            Size = UDim2.new(1, Copyable and -72 or -48, 0, 22),
            Font = Library.Font.Bold,
            Text = string.upper(Label),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 402
        })
        Library:Themed(Tag, "TextColor3", "TextDisabled")

        local Value = New("TextLabel", {
            Parent = Box,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(11, 36),
            Size = UDim2.new(1, -22, 0, 18),
            Font = Library.Font.Bold,
            Text = Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 402
        })
        Library:Themed(Value, "TextColor3", "Text")

        local Fill
        if Live then
            local BarTrack = New("Frame", {
                Parent = Box,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(11, 58),
                Size = UDim2.new(1, -22, 0, 3),
                ZIndex = 402
            })
            Library:Corner(BarTrack, UDim.new(1, 0))
            Library:Themed(BarTrack, "BackgroundColor3", "Track")
            Library:Themed(BarTrack, "BackgroundTransparency", "TrackAlpha")
            Fill = New("Frame", {
                Parent = BarTrack,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(0, 1),
                BackgroundColor3 = Library.Theme.Success,
                ZIndex = 403
            })
            Library:Corner(Fill, UDim.new(1, 0))
        end

        if Copyable then
            local Copy = GlyphButton(Box, Library.Icons.Copy, "Copy")
            Copy.AnchorPoint = Vector2.new(1, 0)
            Copy.Position = UDim2.new(1, -6, 0, 6)
            Copy.Size = UDim2.fromOffset(26, 26)
            Copy.ZIndex = 403
            for _, Child in ipairs(Copy:GetDescendants()) do
                if Child:IsA("GuiObject") then
                    Child.ZIndex = 404
                end
            end
            Copy.MouseButton1Click:Connect(function()
                if Env.setclipboard then
                    pcall(Env.setclipboard, Copyable == true and Value.Text or Copyable)
                    W.API:Notify({ Title = "Copied", Content = Label, Type = "Success", Duration = 2 })
                end
            end)
        end

        Values[Key] = { Value = Value, Fill = Fill, Label = Label, Copy = Copyable }
        table.insert(Ordered, Key)
        return Value
    end

    local Id = HardwareId()
    local Days = LocalPlayer.AccountAge
    Tile("Fps", Library.Icons.Gauge, "FPS", "--", 1, nil, true)
    Tile("Ping", Library.Icons.Signal, "Ping", "--", 2, nil, true)
    Tile("Uptime", Library.Icons.Clock, "Session", "00:00", 3, true)
    Tile("Players", Library.Icons.User, "Players", "--", 4, nil, true)
    Tile("Age", Library.Icons.Sparkles, "Account age",
        Days >= 365 and string.format("%.1f yrs", Days / 365) or (Days .. " days"), 5)
    Tile("Time", Library.Icons.Clock, "Local time", os.date("%H:%M:%S"), 6)
    Tile("User", Library.Icons.User, "User ID", tostring(LocalPlayer.UserId), 7, tostring(LocalPlayer.UserId))
    Tile("Name", Library.Icons.User, "Username", LocalPlayer.Name, 8, LocalPlayer.Name)
    Tile("Display", Library.Icons.Cpu, "Display name", LocalPlayer.DisplayName or "", 9, LocalPlayer.DisplayName or "")
    Tile("Hwid", Library.Icons.Finger, "HWID", Id:sub(1, 14) .. "...", 10, Id)
    Tile("Place", Library.Icons.Cpu, "Place ID", tostring(game.PlaceId), 11, tostring(game.PlaceId))
    Tile("Job", Library.Icons.Signal, "Server ID", tostring(game.JobId):sub(1, 12) .. "...", 12, tostring(game.JobId))
    Tile("Device", Library.Icons.Cpu, "Device", Device.IsMobile() and "Mobile" or "Desktop", 13)
    Tile("Game", Library.Icons.Info, "Game", "Loading...", 14, true)

    task.spawn(function()
        local Ok, Info = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        if Ok and type(Info) == "table" and Info.Name and Values.Game then
            Values.Game.Value.Text = tostring(Info.Name)
        end
    end)

    -- 2 columns when narrow, 3 when the card is docked into a wide page
    local function Relayout()
        local Scale = (W.Scale and W.Scale.Scale) or 1
        local Width = Card.AbsoluteSize.X / math.max(Scale, 0.001)
        local Cols = Width >= 470 and 3 or 2
        GridLayout.FillDirectionMaxCells = Cols
        GridLayout.CellSize = UDim2.new(1 / Cols, -math.ceil(8 * (Cols - 1) / Cols), 0, 66)
    end
    Card:GetPropertyChangedSignal("AbsoluteSize"):Connect(Relayout)
    task.defer(Relayout)

    -- ------------------------------------------------------------------ footer actions
    local Footer = New("Frame", {
        Parent = Card,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -12),
        Size = UDim2.new(1, -28, 0, 36),
        ZIndex = 401
    })
    New("UIListLayout", {
        Parent = Footer,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local CopyAll = PillButton(Footer, "Copy all", Library.Icons.Copy, 0, true)
    CopyAll.Size = UDim2.new(0.5, -4, 1, 0)
    CopyAll.LayoutOrder = 1
    local Rejoin = PillButton(Footer, "Rejoin", Library.Icons.Refresh, 0, false)
    Rejoin.Size = UDim2.new(0.5, -4, 1, 0)
    Rejoin.LayoutOrder = 2

    CopyAll.MouseButton1Click:Connect(function()
        local Lines = {}
        for _, Key in ipairs(Ordered) do
            local Entry = Values[Key]
            local Text = Entry.Copy and Entry.Copy ~= true and tostring(Entry.Copy) or Entry.Value.Text
            table.insert(Lines, Entry.Label .. ": " .. Text)
        end
        if Env.setclipboard then
            pcall(Env.setclipboard, table.concat(Lines, "\n"))
            W.API:Notify({ Title = "Player info", Content = "Copied all details", Type = "Success", Duration = 2 })
        end
    end)
    Rejoin.MouseButton1Click:Connect(function()
        W.API:Notify({ Title = "Rejoin", Content = "Rejoining this server...", Type = "Info", Duration = 3 })
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end)

    -- ------------------------------------------------------------------ live stats
    local function Tone(Good)
        if Good == 2 then
            return Library.Theme.Success
        elseif Good == 1 then
            return Library.Theme.Warn
        end
        return Library.Theme.Error
    end

    local Start = os.clock()
    local Frames, Last, Fps = 0, os.clock(), 60
    table.insert(W.Connections, RunService.RenderStepped:Connect(function()
        Frames = Frames + 1
        local Now = os.clock()
        if Now - Last >= 1 then
            Fps = Frames / (Now - Last)
            Frames, Last = 0, Now
            if Card.Visible then
                local Rounded = math.floor(Fps + 0.5)
                Values.Fps.Value.Text = tostring(Rounded)
                Values.Fps.Fill.BackgroundColor3 = Tone(Rounded >= 55 and 2 or (Rounded >= 30 and 1 or 0))
                Library:Tween(Values.Fps.Fill, FAST, { Size = UDim2.fromScale(Clamp(Rounded / 60, 0.04, 1), 1) })

                local Ping = 0
                if StatsService then
                    local Ok, Value = pcall(function()
                        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
                    end)
                    Ping = Ok and Value or 0
                end
                local PingRounded = math.floor(Ping + 0.5)
                Values.Ping.Value.Text = PingRounded .. " ms"
                Values.Ping.Fill.BackgroundColor3 = Tone(PingRounded < 90 and 2 or (PingRounded < 170 and 1 or 0))
                Library:Tween(Values.Ping.Fill, FAST, { Size = UDim2.fromScale(Clamp(1 - PingRounded / 300, 0.04, 1), 1) })

                Values.Uptime.Value.Text = Clock(os.clock() - Start)
                local Count = #Players:GetPlayers()
                local Max = Players.MaxPlayers
                Values.Players.Value.Text = Count .. " / " .. Max
                Values.Players.Fill.BackgroundColor3 = Library.Theme.Info
                Library:Tween(Values.Players.Fill, FAST, { Size = UDim2.fromScale(Clamp(Count / math.max(Max, 1), 0.04, 1), 1) })
                Values.Time.Value.Text = os.date("%H:%M:%S")
            end
        end
    end))

    do
        local Dragging, Origin, StartPosition = false, nil, nil
        Card.InputBegan:Connect(function(Input)
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

    Close.MouseButton1Click:Connect(function()
        WM.TogglePlayerCard(W, false)
    end)

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
    for _, D in ipairs(Panel:GetDescendants()) do
        if D:IsA("GuiObject") then
            D.ZIndex = math.max(D.ZIndex or 1, 61)
        end
    end
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
    if W.Config.DockPanels and W.Content then
        if State then
            DockPanel(W, Card)
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
    },
    Temperature = 0.6,
    MaxTokens = 900
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
        if tostring(Library.Groq.Endpoint):find("groq.com") and not Key:lower():find("^gsk") then
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

-- asks the API which models this key can use and keeps only chat models
function Library:FetchGroqModels(Key, OnDone)
    task.spawn(function()
        Key = Trim(tostring(Key or Library.Groq.Key or ""))
        if Key == "" then
            return OnDone(false, "no key set")
        end
        if not Env.request then
            return OnDone(false, "no request function")
        end
        local Url = tostring(Library.Groq.Endpoint):gsub("/chat/completions$", "/models")
        local Ok, Response = pcall(Env.request, {
            Url = Url,
            Method = "GET",
            Headers = { ["Authorization"] = "Bearer " .. Key }
        })
        if not Ok or type(Response) ~= "table" or not Response.Body then
            return OnDone(false, "request failed")
        end
        local Decoded, Data = pcall(HttpService.JSONDecode, HttpService, Response.Body)
        if not Decoded or type(Data) ~= "table" then
            return OnDone(false, "bad response")
        end
        if Data.error then
            return OnDone(false, tostring(Data.error.message or "api error"))
        end
        local Found = {}
        for _, Item in ipairs(Data.data or {}) do
            local Name = tostring(Item.id or "")
            local Lower = Name:lower()
            if Name ~= "" and not (Lower:find("whisper") or Lower:find("tts") or Lower:find("guard")
                or Lower:find("embed") or Lower:find("orpheus") or Lower:find("playai")) then
                table.insert(Found, Name)
            end
        end
        table.sort(Found)
        if #Found == 0 then
            return OnDone(false, "no chat models returned")
        end
        OnDone(true, Found)
    end)
end

do
    -- ------------------------------------------------------------------ rich text helpers
    local LuaKeywords, LuaBuiltins = {}, {}
    for _, Word in ipairs({ "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto",
        "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue" }) do
        LuaKeywords[Word] = true
    end
    for _, Word in ipairs({ "print", "warn", "error", "pcall", "xpcall", "pairs", "ipairs", "next", "type", "typeof",
        "tostring", "tonumber", "select", "require", "game", "workspace", "script", "task", "wait", "spawn", "delay",
        "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim2", "UDim", "Enum", "math", "string", "table", "os",
        "coroutine", "setmetatable", "getmetatable", "assert", "unpack", "loadstring", "tick", "time", "Players",
        "RunService", "TweenService", "UserInputService", "HttpService", "ReplicatedStorage" }) do
        LuaBuiltins[Word] = true
    end

    local function Esc(Text)
        return (tostring(Text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
    end

    local function Tint(Hex, Text)
        return '<font color="#' .. Hex .. '">' .. Esc(Text) .. "</font>"
    end

    local function HighlightLua(Code)
        local Out, I, N = {}, 1, #Code
        while I <= N do
            local C = Code:sub(I, I)
            if Code:sub(I, I + 1) == "--" then
                local E = Code:find("\n", I, true) or (N + 1)
                table.insert(Out, Tint("6b7599", Code:sub(I, E - 1)))
                I = E
            elseif C == '"' or C == "'" then
                local J = I + 1
                while J <= N do
                    local D = Code:sub(J, J)
                    if D == "\\" then
                        J = J + 2
                    elseif D == C or D == "\n" then
                        break
                    else
                        J = J + 1
                    end
                end
                table.insert(Out, Tint("9ae6a9", Code:sub(I, math.min(J, N))))
                I = J + 1
            elseif C:match("%d") then
                local Num = Code:match("^%d[%w%._]*", I) or C
                table.insert(Out, Tint("ffb86c", Num))
                I = I + #Num
            elseif C:match("[%a_]") then
                local Word = Code:match("^[%a_][%w_]*", I) or C
                if LuaKeywords[Word] then
                    table.insert(Out, Tint("c4a0ff", Word))
                elseif LuaBuiltins[Word] then
                    table.insert(Out, Tint("82c4ff", Word))
                else
                    table.insert(Out, Esc(Word))
                end
                I = I + #Word
            else
                table.insert(Out, Esc(C))
                I = I + 1
            end
        end
        return table.concat(Out)
    end

    local function Highlight(Code, Lang)
        Lang = tostring(Lang or ""):lower()
        if Lang == "" or Lang == "lua" or Lang == "luau" then
            return HighlightLua(Code)
        end
        return Esc(Code)
    end

    local function Inline(Text)
        local Out, Pos, CodeMode = {}, 1, false
        local CodeHex = Library.Theme.Info:ToHex()
        while true do
            local Tick = Text:find("`", Pos, true)
            local Chunk = Text:sub(Pos, (Tick or (#Text + 1)) - 1)
            if CodeMode then
                table.insert(Out, '<font color="#' .. CodeHex .. '" face="RobotoMono">' .. Esc(Chunk) .. "</font>")
            else
                local Safe = Esc(Chunk)
                Safe = Safe:gsub("%*%*(.-)%*%*", "<b>%1</b>")
                Safe = Safe:gsub("%*([^%*\n]+)%*", "<i>%1</i>")
                Safe = Safe:gsub("%[(.-)%]%((.-)%)", "<u>%1</u>")
                table.insert(Out, Safe)
            end
            if not Tick then
                break
            end
            Pos = Tick + 1
            CodeMode = not CodeMode
        end
        return table.concat(Out)
    end

    -- markdown -> blocks: { Kind = "text"|"code"|"rule", ... }
    local function Parse(Text)
        local Blocks, Buffer = {}, {}
        local function Flush()
            if #Buffer > 0 then
                table.insert(Blocks, { Kind = "text", Rich = table.concat(Buffer, "\n") })
                Buffer = {}
            end
        end
        local InCode, Lang, CodeLines = false, "", {}
        local Source = (Text:gsub("\r", "")) .. "\n"
        for Line in Source:gmatch("(.-)\n") do
            if Line:match("^%s*```") then
                if InCode then
                    table.insert(Blocks, { Kind = "code", Lang = Lang, Code = table.concat(CodeLines, "\n") })
                    InCode, CodeLines, Lang = false, {}, ""
                else
                    Flush()
                    InCode = true
                    Lang = Line:match("^%s*```%s*([%w_%-%+#]*)") or ""
                end
            elseif InCode then
                table.insert(CodeLines, Line)
            else
                local Hashes, Title = Line:match("^(#+)%s+(.+)$")
                local Bullet = Line:match("^%s*[%-%*%+]%s+(.+)$")
                local Number, NumberBody = Line:match("^%s*(%d+)[%.%)]%s+(.+)$")
                local Quote = Line:match("^>%s?(.*)$")
                if Hashes then
                    local Sizes = { 20, 17, 15 }
                    table.insert(Buffer, '<font size="' .. Sizes[math.min(#Hashes, 3)] .. '"><b>' .. Inline(Title) .. "</b></font>")
                elseif Bullet then
                    table.insert(Buffer, "•  " .. Inline(Bullet))
                elseif Number then
                    table.insert(Buffer, Number .. ".  " .. Inline(NumberBody))
                elseif Quote then
                    table.insert(Buffer, '<font color="#8892b0">> ' .. Inline(Quote) .. "</font>")
                elseif Line:match("^%s*%-%-%-+%s*$") then
                    Flush()
                    table.insert(Blocks, { Kind = "rule" })
                elseif Line:match("^%s*$") then
                    Flush()
                else
                    table.insert(Buffer, Inline(Line))
                end
            end
        end
        if InCode then
            table.insert(Blocks, { Kind = "code", Lang = Lang, Code = table.concat(CodeLines, "\n") })
        end
        Flush()
        return Blocks
    end

    -- ------------------------------------------------------------------ request
    local function ChatRequest(Messages, OnDone)
        task.spawn(function()
            if not Env.request then
                return OnDone(false, "This executor has no HTTP request function.", { Kind = "env" })
            end
            if Library.Groq.Key == "" then
                return OnDone(false, "No API key is set.", { Kind = "auth" })
            end
            local Started = os.clock()
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
                    temperature = Library.Groq.Temperature or 0.6,
                    max_tokens = Library.Groq.MaxTokens or 900
                })
            })
            local Latency = os.clock() - Started
            if not Ok or type(Response) ~= "table" or not Response.Body then
                return OnDone(false, "The request failed. Check your connection.", { Kind = "net", Latency = Latency })
            end
            local Status = tonumber(Response.StatusCode or Response.Status) or 0
            local Decoded, Data = pcall(HttpService.JSONDecode, HttpService, tostring(Response.Body))
            if not Decoded or type(Data) ~= "table" then
                return OnDone(false, "The server sent a reply I could not read (" .. Status .. ").",
                    { Kind = "http", Status = Status, Latency = Latency })
            end
            if Data.error then
                local Kind = (Status == 401 or Status == 403) and "auth" or (Status == 429 and "rate" or "http")
                return OnDone(false, tostring(Data.error.message or "API error"),
                    { Kind = Kind, Status = Status, Latency = Latency })
            end
            local Choice = Data.choices and Data.choices[1]
            local Text = Choice and Choice.message and Choice.message.content
            if type(Text) ~= "string" or Text == "" then
                return OnDone(false, "The model sent an empty reply.", { Kind = "empty", Status = Status, Latency = Latency })
            end
            Text = Text:gsub("<think>.-</think>", "")
            OnDone(true, Trim(Text), {
                Status = Status,
                Latency = Latency,
                Tokens = Data.usage and Data.usage.total_tokens or nil
            })
        end)
    end

    Library._AI = {
        Highlight = Highlight,
        Inline = Inline,
        Parse = Parse,
        ChatRequest = ChatRequest,
        Esc = Esc
    }
end

function WM.AI(W)
    if W.AIPanel then
        return W.AIPanel
    end

    local AI = Library._AI
    local Folder = W.Paths.Folder
    local HistoryPath = Folder .. "/ai_history.json"
    local SettingsPath = Folder .. "/ai_settings.json"
    local History = FS.ReadJSON(HistoryPath) or {}
    local Saved = FS.ReadJSON(SettingsPath) or {}
    local Mobile = W.Mobile
    local HeadH = 58
    local MaxChars = 4000

    local Settings = {
        Persona = type(Saved.Persona) == "string" and Saved.Persona or "Hub default",
        Custom = type(Saved.Custom) == "string" and Saved.Custom or "",
        Context = Saved.Context ~= false,
        Typewriter = Saved.Typewriter ~= false,
        Save = Saved.Save ~= false
    }
    if type(Saved.Temperature) == "number" then
        Library.Groq.Temperature = Saved.Temperature
    end
    if type(Saved.MaxTokens) == "number" then
        Library.Groq.MaxTokens = Saved.MaxTokens
    end
    if type(Saved.Model) == "string" and Saved.Model ~= "" and not W.Config.GroqModel then
        Library.Groq.Model = Saved.Model
    end

    local Personas = {
        { Name = "Hub default", Text = function() return Library.Groq.Prompt end },
        { Name = "Concise", Text = function() return "You are a concise assistant embedded in a Roblox script hub. Answer in a few short sentences." end },
        { Name = "Teacher", Text = function() return "You are a patient teacher. Explain step by step with simple examples." end },
        { Name = "Scripter", Text = function() return "You are an expert Luau and Roblox scripter. Give working, commented code in fenced blocks and explain it briefly." end },
        { Name = "Casual", Text = function() return "You are a friendly, casual assistant. Keep replies short and fun." end },
        { Name = "Custom", Text = function() return Settings.Custom end }
    }
    local PersonaNames = {}
    for _, Item in ipairs(Personas) do
        table.insert(PersonaNames, Item.Name)
    end

    local Booting = true
    local function SaveSettings()
        if Booting then
            return
        end
        FS.WriteJSON(SettingsPath, {
            Persona = Settings.Persona,
            Custom = Settings.Custom,
            Context = Settings.Context,
            Typewriter = Settings.Typewriter,
            Save = Settings.Save,
            Temperature = Library.Groq.Temperature,
            MaxTokens = Library.Groq.MaxTokens,
            Model = Library.Groq.Model
        })
    end
    local function SaveHistory()
        if not Settings.Save then
            return
        end
        while #History > 80 do
            table.remove(History, 1)
        end
        FS.WriteJSON(HistoryPath, History)
    end

    local function Notify(Title, Content, Kind, Duration)
        if W.API then
            W.API:Notify({ Title = Title, Content = Content, Type = Kind or "Info", Duration = Duration or 3 })
        end
    end

    local UI = {}
    local Fn = {}
    local State = { Mode = "idle", Skip = false, Order = 0 }
    local Rows = {}
    local Bubbles = {}

    local function Scale()
        return math.max((W.Scale and W.Scale.Scale) or 1, 0.001)
    end

    -- ------------------------------------------------------------------ panel shell
    local Panel = New("Frame", {
        Parent = W.Main,
        Name = "AI",
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, W.Header.Size.Y.Offset),
        Size = UDim2.new(0, 320, 1, -W.Header.Size.Y.Offset),
        Visible = false,
        ZIndex = 90,
        ClipsDescendants = true
    })
    UI.Panel = Panel

    local function FitPanelWidth()
        if Panel:GetAttribute("Docked") then
            Panel.AnchorPoint = Vector2.new(0, 0)
            Panel.Position = UDim2.fromOffset(0, 0)
            Panel.Size = UDim2.new(1, 0, 1, 0)
            return
        end
        local MainWidth = W.Main.AbsoluteSize.X
        if MainWidth <= 0 then
            return
        end
        local Target = math.min(340, math.floor(MainWidth * 0.84))
        Panel.Size = UDim2.new(0, Target, 1, -W.Header.Size.Y.Offset)
    end
    table.insert(W.Connections, W.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitPanelWidth))
    task.defer(FitPanelWidth)
    Library:Themed(Panel, "BackgroundColor3", "Elevated")
    Library:Themed(Panel, "BackgroundTransparency", "ElevatedAlpha")
    Library:Stroke(Panel, "StrokeSoft", 1)

    local Edge = New("Frame", {
        Parent = Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundTransparency = 0.9,
        ZIndex = 81
    })
    Library:Themed(Edge, "BackgroundColor3", "Stroke")

    -- ------------------------------------------------------------------ header
    UI.Head = Blank(Panel, { Size = UDim2.new(1, 0, 0, HeadH), ZIndex = 92 })

    local BotChip = New("Frame", {
        Parent = UI.Head,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(38, 38),
        BackgroundTransparency = 0.82
    })
    Library:Corner(BotChip, UDim.new(1, 0))
    Library:Themed(BotChip, "BackgroundColor3", "Accent")
    local BotRing = New("UIStroke", {
        Parent = BotChip,
        Thickness = 1,
        Transparency = 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(BotRing, "Color", "Accent")
    local BotIcon = IconLabel(BotChip, Library.Icons.Bot, 19, "Accent")
    BotIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    BotIcon.Position = UDim2.fromScale(0.5, 0.5)
    Library:Themed(BotIcon, "ImageColor3", "Accent")
    UI.StatusDot = New("Frame", {
        Parent = BotChip,
        AnchorPoint = Vector2.new(1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(1, 1, 1, 1),
        Size = UDim2.fromOffset(11, 11),
        BackgroundColor3 = Library.Theme.Warn
    })
    Library:Corner(UI.StatusDot, UDim.new(1, 0))
    local StatusCut = New("UIStroke", {
        Parent = UI.StatusDot,
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(StatusCut, "Color", "Elevated")

    local HeadTitle = New("TextLabel", {
        Parent = UI.Head,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 62, 0, 10),
        Size = UDim2.new(1, -160, 0, 18),
        Font = Library.Font.Bold,
        Text = "AI Assistant",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Library:Themed(HeadTitle, "TextColor3", "Text")

    UI.ModelPill = New("TextButton", {
        Parent = UI.Head,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 62, 0, 31),
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = "",
        AutoButtonColor = false
    })
    Library:Corner(UI.ModelPill, UDim.new(1, 0))
    Library:Themed(UI.ModelPill, "BackgroundColor3", "Inset")
    Library:Themed(UI.ModelPill, "BackgroundTransparency", "InsetAlpha")
    local PillLine = Library:Stroke(UI.ModelPill, "StrokeSoft", 1)
    Library:Hover(UI.ModelPill, PillLine, "Transparency", Library.Theme.StrokeSoftAlpha, 0.35)
    New("UIPadding", { Parent = UI.ModelPill, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 7) })
    New("UIListLayout", {
        Parent = UI.ModelPill,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    UI.ModelLabel = New("TextLabel", {
        Parent = UI.ModelPill,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 18),
        Font = Library.Font.Medium,
        Text = Library.Groq.Model,
        TextSize = 10,
        LayoutOrder = 1
    })
    Library:Themed(UI.ModelLabel, "TextColor3", "TextDim")
    local PillChevron = IconLabel(UI.ModelPill, Library.Icons.Down, 10, "TextDim")
    PillChevron.LayoutOrder = 2

    local function HeadButton(IconName, Tip, Offset)
        local Button = GlyphButton(UI.Head, IconName, Tip)
        Button.AnchorPoint = Vector2.new(1, 0.5)
        Button.Position = UDim2.new(1, Offset, 0.5, 0)
        return Button
    end
    local CloseButton = HeadButton(Library.Icons.Close, "Close", -10)
    local ClearButton = HeadButton(Library.Icons.Trash, "Clear chat", -42)
    local ExportButton = HeadButton(Library.Icons.Copy, "Export chat", -74)
    local SettingsButton = HeadButton(Library.Icons.Settings, "Settings", -106)

    -- ------------------------------------------------------------------ chat list
    UI.Log = New("ScrollingFrame", {
        Parent = Panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, HeadH),
        Size = UDim2.new(1, 0, 1, -(HeadH + 110)),
        ZIndex = 91,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    })
    Library:StyleScroll(UI.Log)
    New("UIPadding", {
        Parent = UI.Log,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 14)
    })
    New("UIListLayout", {
        Parent = UI.Log,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12)
    })

    local Following = true
    UI.Log:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        Following = UI.Log.CanvasPosition.Y >= UI.Log.AbsoluteCanvasSize.Y - UI.Log.AbsoluteSize.Y - 60
    end)
    local function ScrollEnd(Force)
        task.delay(0.04, function()
            if UI.Log.Parent and (Force or Following) then
                UI.Log.CanvasPosition = Vector2.new(0, 1e6)
            end
        end)
    end
    local function RefreshBubbles()
        local Max = math.max(140, (UI.Log.AbsoluteSize.X / Scale()) * 0.8 - 26)
        for Index = #Bubbles, 1, -1 do
            local Constraint = Bubbles[Index]
            if Constraint.Parent then
                Constraint.MaxSize = Vector2.new(Max, math.huge)
            else
                table.remove(Bubbles, Index)
            end
        end
    end
    UI.Log:GetPropertyChangedSignal("AbsoluteSize"):Connect(RefreshBubbles)

    local function NextOrder()
        State.Order = State.Order + 1
        return State.Order
    end

    local function Stamp(Time)
        return os.date("%H:%M", Time or os.time())
    end

    local function MiniAvatar(Parent)
        local Chip = New("Frame", {
            Parent = Parent,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 2),
            Size = UDim2.fromOffset(28, 28),
            BackgroundTransparency = 0.82
        })
        Library:Corner(Chip, UDim.new(1, 0))
        Library:Themed(Chip, "BackgroundColor3", "Accent")
        local Line = New("UIStroke", {
            Parent = Chip,
            Thickness = 1,
            Transparency = 0.55,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Library:Themed(Line, "Color", "Accent")
        local Glyph = IconLabel(Chip, Library.Icons.Bot, 14, "Accent")
        Glyph.AnchorPoint = Vector2.new(0.5, 0.5)
        Glyph.Position = UDim2.fromScale(0.5, 0.5)
        Library:Themed(Glyph, "ImageColor3", "Accent")
        return Chip
    end

    local function GlassCard(Parent, Props)
        local Card = New("Frame", {
            Parent = Parent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 36, 0, 0),
            Size = UDim2.new(1, -36, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        })
        Library:Corner(Card, UDim.new(0, 16))
        Library:Themed(Card, "BackgroundColor3", "Row")
        Library:Themed(Card, "BackgroundTransparency", "RowAlpha")
        Library:GlassEdge(Card, 1, 0.65)
        Library:Gloss(Card, 0.95)
        local Inner = New("Frame", {
            Parent = Card,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        })
        Library:Padding(Inner, 10, 8, 13, 13)
        New("UIListLayout", {
            Parent = Inner,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })
        return Card, Inner
    end

    local function RowShell()
        return New("Frame", {
            Parent = UI.Log,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = NextOrder()
        })
    end

    -- user message: accent capsule on the right
    function Fn.UserMessage(Text)
        local Row = RowShell()
        local Bubble = New("Frame", {
            Parent = Row,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            BorderSizePixel = 0,
            BackgroundTransparency = 0.8
        })
        Library:Corner(Bubble, UDim.new(0, 18))
        Library:Themed(Bubble, "BackgroundColor3", "Accent")
        local Line = New("UIStroke", {
            Parent = Bubble,
            Thickness = 1,
            Transparency = 0.55,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Library:Themed(Line, "Color", "Accent")
        Library:Padding(Bubble, 9, 9, 13, 13)
        local Label = New("TextLabel", {
            Parent = Bubble,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            Font = Library.Font.Regular,
            Text = Text,
            TextSize = Library.TextSize(13, 1),
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        Library:Themed(Label, "TextColor3", "Text")
        local Constraint = New("UISizeConstraint", {
            Parent = Label,
            MaxSize = Vector2.new(math.max(140, (UI.Log.AbsoluteSize.X / Scale()) * 0.8 - 26), math.huge)
        })
        table.insert(Bubbles, Constraint)
        Library:Pop(Bubble, 0.22, 0.96)
        local Entry = { Role = "user", Row = Row }
        table.insert(Rows, Entry)
        return Entry
    end

    -- assistant message: card with markdown blocks, code blocks, actions and footer
    function Fn.AssistantMessage(Text, Meta)
        Meta = Meta or {}
        local Tabs = {}
        local Clean = Text:gsub("%[%[tab:(.-)%]%]", function(Name)
            table.insert(Tabs, Trim(Name))
            return ""
        end)
        Clean = Trim(Clean)

        local Row = RowShell()
        MiniAvatar(Row)
        local Card, Inner = GlassCard(Row)
        local Reveal = {}

        for Index, Block in ipairs(AI.Parse(Clean)) do
            if Block.Kind == "text" then
                local Label = New("TextLabel", {
                    Parent = Inner,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Library.Font.Regular,
                    RichText = true,
                    Text = Block.Rich,
                    TextSize = Library.TextSize(13, 1),
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    LineHeight = 1.12,
                    LayoutOrder = Index
                })
                Library:Themed(Label, "TextColor3", "Text")
                table.insert(Reveal, Label)
            elseif Block.Kind == "code" then
                local Box = New("Frame", {
                    Parent = Inner,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = Index
                })
                Library:Corner(Box, UDim.new(0, 12))
                Library:Themed(Box, "BackgroundColor3", "Inset")
                Library:Themed(Box, "BackgroundTransparency", "InsetAlpha")
                Library:GlassEdge(Box, 1, 0.55)
                local BoxInner = New("Frame", {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                New("UIListLayout", { Parent = BoxInner, SortOrder = Enum.SortOrder.LayoutOrder })
                local Bar = New("Frame", {
                    Parent = BoxInner,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 28),
                    LayoutOrder = 1
                })
                local Dots = New("Frame", {
                    Parent = Bar,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 10, 0.5, 0),
                    Size = UDim2.fromOffset(40, 8)
                })
                New("UIListLayout", {
                    Parent = Dots,
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                for DotIndex, DotColor in ipairs({ Color3.fromRGB(255, 95, 86), Color3.fromRGB(255, 189, 46), Color3.fromRGB(39, 201, 63) }) do
                    local Dot = New("Frame", {
                        Parent = Dots,
                        BackgroundColor3 = DotColor,
                        BorderSizePixel = 0,
                        Size = UDim2.fromOffset(8, 8),
                        LayoutOrder = DotIndex
                    })
                    Library:Corner(Dot, UDim.new(1, 0))
                end
                local LangLabel = New("TextLabel", {
                    Parent = Bar,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 58, 0.5, 0),
                    Size = UDim2.new(1, -140, 0, 14),
                    Font = Library.Font.Bold,
                    Text = string.upper(Block.Lang ~= "" and Block.Lang or "code"),
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                Library:Themed(LangLabel, "TextColor3", "TextDisabled")

                local CopyChip = New("TextButton", {
                    Parent = Bar,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(0, 20),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 0.88
                })
                Library:Corner(CopyChip, UDim.new(1, 0))
                Library:Themed(CopyChip, "BackgroundColor3", "Row")
                New("UIPadding", { Parent = CopyChip, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 9) })
                New("UIListLayout", {
                    Parent = CopyChip,
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                local CopyGlyph = IconLabel(CopyChip, Library.Icons.Copy, 11, "TextDim")
                CopyGlyph.LayoutOrder = 1
                local CopyText = New("TextLabel", {
                    Parent = CopyChip,
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.fromOffset(0, 20),
                    Font = Library.Font.Bold,
                    Text = "Copy",
                    TextSize = 10,
                    LayoutOrder = 2
                })
                Library:Themed(CopyText, "TextColor3", "TextDim")
                CopyChip.MouseEnter:Connect(function()
                    Library:Tween(CopyChip, FAST, { BackgroundTransparency = 0.7 })
                end)
                CopyChip.MouseLeave:Connect(function()
                    Library:Tween(CopyChip, FAST, { BackgroundTransparency = 0.88 })
                end)
                CopyChip.MouseButton1Click:Connect(function()
                    if Env.setclipboard then
                        pcall(Env.setclipboard, Block.Code)
                    end
                    CopyText.Text = "Copied"
                    Library:SetIcon(CopyGlyph, Library.Icons.Check, Library.Theme.Success)
                    Library:Feedback(1.1)
                    task.delay(1.3, function()
                        if CopyText.Parent then
                            CopyText.Text = "Copy"
                            Library:SetIcon(CopyGlyph, Library.Icons.Copy, Library.Theme.TextDim)
                        end
                    end)
                end)

                local Rule = New("Frame", {
                    Parent = BoxInner,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundTransparency = 0.92,
                    LayoutOrder = 2
                })
                Library:Themed(Rule, "BackgroundColor3", "Stroke")

                local Body = New("Frame", {
                    Parent = BoxInner,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 3
                })
                Library:Padding(Body, 8, 10, 12, 12)
                local Code = New("TextLabel", {
                    Parent = Body,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Library.Font.Mono,
                    RichText = true,
                    Text = AI.Highlight(Block.Code, Block.Lang),
                    TextSize = Library.TextSize(12, 1),
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                })
                Library:Themed(Code, "TextColor3", "Neutral")
                table.insert(Reveal, Code)
            elseif Block.Kind == "rule" then
                local Line = New("Frame", {
                    Parent = Inner,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundTransparency = 0.88,
                    LayoutOrder = Index
                })
                Library:Themed(Line, "BackgroundColor3", "Stroke")
            end
        end

        -- quick actions the model asked for: [[tab:Name]]
        if #Tabs > 0 then
            local Actions = New("Frame", {
                Parent = Inner,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = 998
            })
            local ActionLayout = New("UIListLayout", {
                Parent = Actions,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            pcall(function()
                ActionLayout.Wraps = true
            end)
            for Index, TabName in ipairs(Tabs) do
                local Pill = PillButton(Actions, "Open " .. TabName, Library.Icons.Right, 42 + #TabName * 7, false)
                Pill.LayoutOrder = Index
                Pill.MouseButton1Click:Connect(function()
                    if W.API then
                        W.API:SelectTab(TabName)
                    end
                end)
            end
        end

        -- footer: time, latency, tokens, copy / regenerate
        local Footer = New("Frame", {
            Parent = Inner,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 24),
            LayoutOrder = 999
        })
        local Info = Meta.Info or {}
        local Parts = { Stamp(Meta.Time) }
        if Info.Latency then
            table.insert(Parts, string.format("%.1fs", Info.Latency))
        end
        if Info.Tokens then
            table.insert(Parts, Info.Tokens .. " tok")
        end
        local StampLabel = New("TextLabel", {
            Parent = Footer,
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, -60, 0, 14),
            Font = Library.Font.Regular,
            Text = table.concat(Parts, "  ·  "),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Themed(StampLabel, "TextColor3", "TextDisabled")
        local Tools = New("Frame", {
            Parent = Footer,
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X
        })
        New("UIListLayout", {
            Parent = Tools,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local CopyAll, CopyAllIcon = GlyphButton(Tools, Library.Icons.Copy, "Copy reply")
        CopyAll.Size = UDim2.fromOffset(24, 24)
        CopyAll.LayoutOrder = 2
        CopyAll.MouseButton1Click:Connect(function()
            if Env.setclipboard then
                pcall(Env.setclipboard, Clean)
            end
            Library:SetIcon(CopyAllIcon, Library.Icons.Check, Library.Theme.Success)
            task.delay(1.2, function()
                if CopyAllIcon.Parent then
                    Library:SetIcon(CopyAllIcon, Library.Icons.Copy, Library.Theme.TextDim)
                end
            end)
        end)
        local Retry = GlyphButton(Tools, Library.Icons.Refresh, "Regenerate")
        Retry.Size = UDim2.fromOffset(24, 24)
        Retry.LayoutOrder = 1
        Retry.MouseButton1Click:Connect(function()
            Fn.Retry()
        end)

        Library:Pop(Card, 0.24, 0.97)
        local Entry = { Role = "assistant", Row = Row, Retry = Retry, Reveal = Reveal }
        table.insert(Rows, Entry)
        for _, Other in ipairs(Rows) do
            if Other ~= Entry and Other.Retry then
                Other.Retry.Visible = false
            end
        end
        return Entry
    end

    -- "thinking" card with animated dots
    function Fn.Typing()
        local Row = RowShell()
        MiniAvatar(Row)
        local Card = New("Frame", {
            Parent = Row,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 36, 0, 0),
            Size = UDim2.fromOffset(112, 34)
        })
        Library:Corner(Card, UDim.new(1, 0))
        Library:Themed(Card, "BackgroundColor3", "Row")
        Library:Themed(Card, "BackgroundTransparency", "RowAlpha")
        Library:GlassEdge(Card, 1, 0.65)
        local Think = New("TextLabel", {
            Parent = Card,
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(52, 14),
            Font = Library.Font.Medium,
            Text = "Thinking",
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Themed(Think, "TextColor3", "TextDim")
        local Dots = New("Frame", {
            Parent = Card,
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(30, 8)
        })
        New("UIListLayout", {
            Parent = Dots,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local DotList = {}
        for Index = 1, 3 do
            local Dot = New("Frame", {
                Parent = Dots,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(6, 6),
                BackgroundTransparency = 0.7,
                LayoutOrder = Index
            })
            Library:Corner(Dot, UDim.new(1, 0))
            Library:Themed(Dot, "BackgroundColor3", "Accent")
            DotList[Index] = Dot
        end
        local Alive = true
        task.spawn(function()
            while Alive and Row.Parent do
                for _, Dot in ipairs(DotList) do
                    if not Dot.Parent then
                        return
                    end
                    Library:Tween(Dot, TweenInfo.new(0.22, Quart, Out), { BackgroundTransparency = 0.05 })
                    task.delay(0.24, function()
                        if Dot.Parent then
                            Library:Tween(Dot, TweenInfo.new(0.3, Quart, Out), { BackgroundTransparency = 0.7 })
                        end
                    end)
                    task.wait(0.16)
                end
                task.wait(0.3)
            end
        end)
        Library:Pop(Card, 0.2, 0.94)
        return {
            Row = Row,
            Destroy = function()
                Alive = false
                if Row.Parent then
                    Row:Destroy()
                end
            end
        }
    end

    -- error card with context-aware actions
    function Fn.ErrorMessage(Message, Kind)
        local Row = RowShell()
        MiniAvatar(Row)
        local Card = New("Frame", {
            Parent = Row,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 36, 0, 0),
            Size = UDim2.new(1, -36, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 0.86
        })
        Library:Corner(Card, UDim.new(0, 16))
        Library:Themed(Card, "BackgroundColor3", "Error")
        local Line = New("UIStroke", {
            Parent = Card,
            Thickness = 1,
            Transparency = 0.55,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Library:Themed(Line, "Color", "Error")
        local Inner = New("Frame", {
            Parent = Card,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        })
        Library:Padding(Inner, 10, 10, 13, 13)
        New("UIListLayout", { Parent = Inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
        local Heading = ({
            auth = "API key problem",
            rate = "Slow down a moment",
            net = "Connection problem",
            env = "Not supported here",
            empty = "Empty reply"
        })[Kind] or "Something went wrong"
        local Title = New("TextLabel", {
            Parent = Inner,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = Library.Font.Bold,
            Text = Heading,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1
        })
        Library:Themed(Title, "TextColor3", "Error")
        local Detail = New("TextLabel", {
            Parent = Inner,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Library.Font.Regular,
            Text = tostring(Message),
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = 2
        })
        Library:Themed(Detail, "TextColor3", "TextDim")
        local Buttons = New("Frame", {
            Parent = Inner,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = 3
        })
        New("UIListLayout", {
            Parent = Buttons,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        if Kind ~= "env" then
            local Again = PillButton(Buttons, "Try again", Library.Icons.Refresh, 104, true)
            Again.LayoutOrder = 1
            Again.MouseButton1Click:Connect(function()
                if Row.Parent then
                    Row:Destroy()
                end
                Fn.Query()
            end)
        end
        if Kind == "auth" then
            local Open = PillButton(Buttons, "Open settings", Library.Icons.Settings, 126, false)
            Open.LayoutOrder = 2
            Open.MouseButton1Click:Connect(function()
                Fn.OpenSettings(true)
            end)
        end
        Library:Pop(Card, 0.24, 0.97)
        return { Row = Row }
    end

    -- ------------------------------------------------------------------ empty state
    UI.Empty = New("ScrollingFrame", {
        Parent = Panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, HeadH),
        Size = UDim2.new(1, 0, 1, -(HeadH + 110)),
        ZIndex = 91,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    New("UIPadding", {
        Parent = UI.Empty,
        PaddingTop = UDim.new(0, 20),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14)
    })
    New("UIListLayout", {
        Parent = UI.Empty,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })

    local HeroChip = New("Frame", {
        Parent = UI.Empty,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(68, 68),
        BackgroundTransparency = 0.82,
        LayoutOrder = 1
    })
    Library:Corner(HeroChip, UDim.new(1, 0))
    Library:Themed(HeroChip, "BackgroundColor3", "Accent")
    local HeroRing = New("UIStroke", {
        Parent = HeroChip,
        Thickness = 1.5,
        Transparency = 0.35,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(HeroRing, "Color", "Accent")
    local HeroIcon = IconLabel(HeroChip, Library.Icons.Bot, 30, "Accent")
    HeroIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    HeroIcon.Position = UDim2.fromScale(0.5, 0.5)
    Library:Themed(HeroIcon, "ImageColor3", "Accent")
    task.spawn(function()
        while HeroChip.Parent do
            Library:Tween(HeroRing, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.8 })
            task.wait(1.6)
            Library:Tween(HeroRing, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.3 })
            task.wait(1.6)
        end
    end)

    local EmptyTitle = New("TextLabel", {
        Parent = UI.Empty,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Font = Library.Font.Bold,
        Text = "How can I help?",
        TextSize = 19,
        LayoutOrder = 2
    })
    Library:Themed(EmptyTitle, "TextColor3", "Text")
    local EmptySub = New("TextLabel", {
        Parent = UI.Empty,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Library.Font.Regular,
        Text = "Ask about this hub, or get help with Luau.",
        TextSize = 12,
        LayoutOrder = 3
    })
    Library:Themed(EmptySub, "TextColor3", "TextDim")

    -- shown while no API key is set
    UI.Banner = New("Frame", {
        Parent = UI.Empty,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.84,
        LayoutOrder = 4,
        Visible = false
    })
    Library:Corner(UI.Banner, UDim.new(0, 16))
    Library:Themed(UI.Banner, "BackgroundColor3", "Warn")
    local BannerLine = New("UIStroke", {
        Parent = UI.Banner,
        Thickness = 1,
        Transparency = 0.55,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    Library:Themed(BannerLine, "Color", "Warn")
    local BannerInner = New("Frame", {
        Parent = UI.Banner,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    Library:Padding(BannerInner, 12, 12, 14, 14)
    New("UIListLayout", { Parent = BannerInner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
    local BannerTitle = New("TextLabel", {
        Parent = BannerInner,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Library.Font.Bold,
        Text = "Connect an API key",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1
    })
    Library:Themed(BannerTitle, "TextColor3", "Warn")
    local BannerBody = New("TextLabel", {
        Parent = BannerInner,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Library.Font.Regular,
        Text = "Paste a key below (or open settings) to start chatting.",
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = 2
    })
    Library:Themed(BannerBody, "TextColor3", "TextDim")

    local Starters = {
        { Icon = Library.Icons.Info, Title = "Explain this hub", Sub = "A quick tour of every tab",
            Prompt = "Give me a quick tour of this hub and what each tab does." },
        { Icon = Library.Icons.Cpu, Title = "Write a Luau snippet", Sub = "A working example to adapt",
            Prompt = "Write a short, well-commented Luau example I can adapt, and explain it briefly." },
        { Icon = Library.Icons.Edit, Title = "Review my code", Sub = "Paste a script to check",
            Fill = "Review this script and point out bugs or improvements:\n```lua\n\n```" },
        { Icon = Library.Icons.Sparkles, Title = "Tips for this game", Sub = "Ideas and tricks",
            Prompt = "Give me a few practical tips for getting better at this game." }
    }
    UI.Cards = New("Frame", {
        Parent = UI.Empty,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 130),
        LayoutOrder = 5
    })
    local CardGrid = New("UIGridLayout", {
        Parent = UI.Cards,
        CellPadding = UDim2.fromOffset(8, 8),
        CellSize = UDim2.new(1, 0, 0, 58),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirectionMaxCells = 1
    })
    for Index, Starter in ipairs(Starters) do
        local Button = New("TextButton", {
            Parent = UI.Cards,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Index
        })
        Library:Corner(Button, UDim.new(0, 16))
        Library:Themed(Button, "BackgroundColor3", "Row")
        Library:Themed(Button, "BackgroundTransparency", "RowAlpha")
        Library:Gloss(Button, 0.95)
        local ButtonLine = Library:Stroke(Button, "StrokeSoft", 1)
        Library:Hover(Button, ButtonLine, "Transparency", Library.Theme.StrokeSoftAlpha, 0.35)
        local Chip = New("Frame", {
            Parent = Button,
            AnchorPoint = Vector2.new(0, 0.5),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.fromOffset(32, 32),
            BackgroundTransparency = 0.82
        })
        Library:Corner(Chip, UDim.new(1, 0))
        Library:Themed(Chip, "BackgroundColor3", "Accent")
        local Glyph = IconLabel(Chip, Starter.Icon, 16, "Accent")
        Glyph.AnchorPoint = Vector2.new(0.5, 0.5)
        Glyph.Position = UDim2.fromScale(0.5, 0.5)
        Library:Themed(Glyph, "ImageColor3", "Accent")
        local CardTitle = New("TextLabel", {
            Parent = Button,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 56, 0, 11),
            Size = UDim2.new(1, -66, 0, 16),
            Font = Library.Font.Bold,
            Text = Starter.Title,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        Library:Themed(CardTitle, "TextColor3", "Text")
        local CardSub = New("TextLabel", {
            Parent = Button,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 56, 0, 30),
            Size = UDim2.new(1, -66, 0, 14),
            Font = Library.Font.Regular,
            Text = Starter.Sub,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        Library:Themed(CardSub, "TextColor3", "TextDim")
        Button.MouseButton1Click:Connect(function()
            Library:Feedback(1.05)
            if Starter.Fill then
                UI.Box.Text = Starter.Fill
                UI.Box:CaptureFocus()
            else
                Fn.Submit(Starter.Prompt)
            end
        end)
    end

    local function RelayoutEmpty()
        local Width = Panel.AbsoluteSize.X / Scale()
        local Cols = Width >= 440 and 2 or 1
        CardGrid.FillDirectionMaxCells = Cols
        CardGrid.CellSize = UDim2.new(1 / Cols, -math.ceil(8 * (Cols - 1) / Cols), 0, 58)
        local RowCount = math.ceil(#Starters / Cols)
        UI.Cards.Size = UDim2.new(1, 0, 0, RowCount * 58 + (RowCount - 1) * 8)
    end
    Panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(RelayoutEmpty)
    task.defer(RelayoutEmpty)

    function Fn.UpdateEmpty()
        local Show = #Rows == 0
        UI.Empty.Visible = Show
        UI.Log.Visible = not Show
    end

    -- ------------------------------------------------------------------ composer
    UI.Composer = New("Frame", {
        Parent = Panel,
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 110),
        ZIndex = 93
    })

    UI.Suggest = New("ScrollingFrame", {
        Parent = UI.Composer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 4),
        Size = UDim2.new(1, -24, 0, 28),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        Visible = false
    })
    New("UIListLayout", {
        Parent = UI.Suggest,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    UI.Field = New("Frame", {
        Parent = UI.Composer,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 36),
        Size = UDim2.new(1, -24, 0, 46),
        Visible = false
    })
    Library:Corner(UI.Field, UDim.new(0, 22))
    Library:Themed(UI.Field, "BackgroundColor3", "Inset")
    Library:Themed(UI.Field, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(UI.Field, 0.96)
    UI.FieldLine = Library:GlassEdge(UI.Field, 1, 0.5)

    UI.Box = New("TextBox", {
        Parent = UI.Field,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 6),
        Size = UDim2.new(1, -66, 1, -12),
        Font = Library.Font.Regular,
        PlaceholderText = "Ask something...",
        Text = "",
        TextSize = Library.TextSize(13, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        MultiLine = true,
        ClearTextOnFocus = false
    })
    Library:Themed(UI.Box, "TextColor3", "Text")
    Library:Themed(UI.Box, "PlaceholderColor3", "TextDisabled")

    UI.Send = New("TextButton", {
        Parent = UI.Field,
        AnchorPoint = Vector2.new(1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -6, 1, -6),
        Size = UDim2.fromOffset(34, 34),
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 0.7
    })
    Library:Corner(UI.Send, UDim.new(1, 0))
    Library:Themed(UI.Send, "BackgroundColor3", "Accent")
    UI.SendIcon = IconLabel(UI.Send, Library.Icons.Send, 16, "AccentText")
    UI.SendIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.SendIcon.Position = UDim2.fromScale(0.5, 0.5)
    Library:Themed(UI.SendIcon, "ImageColor3", "AccentText")

    UI.Hint = New("TextLabel", {
        Parent = UI.Composer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 86),
        Size = UDim2.new(1, -36, 0, 14),
        Font = Library.Font.Regular,
        Text = Mobile and "Tap the arrow to send" or "Enter to send  ·  Shift+Enter for a new line",
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = false
    })
    Library:Themed(UI.Hint, "TextColor3", "TextDisabled")
    UI.Count = New("TextLabel", {
        Parent = UI.Composer,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -18, 0, 86),
        Size = UDim2.fromOffset(90, 14),
        Font = Library.Font.Regular,
        Text = "",
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    Library:Themed(UI.Count, "TextColor3", "TextDisabled")

    -- inline key entry (shown instead of the field while no key is set)
    UI.KeyField = New("Frame", {
        Parent = UI.Composer,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 44),
        Visible = false
    })
    Library:Corner(UI.KeyField, UDim.new(0, 22))
    Library:Themed(UI.KeyField, "BackgroundColor3", "Inset")
    Library:Themed(UI.KeyField, "BackgroundTransparency", "InsetAlpha")
    Library:Gloss(UI.KeyField, 0.96)
    Library:GlassEdge(UI.KeyField, 1, 0.5)

    local KeyReal, KeyShown = "", false
    local function Mask(Text)
        if Text == "" then
            return ""
        end
        return string.rep("•", math.min(#Text, 28))
    end
    local KeyBox = New("TextBox", {
        Parent = UI.KeyField,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -92, 1, 0),
        Font = Library.Font.Regular,
        PlaceholderText = "Paste your API key",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    Library:Themed(KeyBox, "TextColor3", "Text")
    Library:Themed(KeyBox, "PlaceholderColor3", "TextDisabled")
    KeyBox:GetPropertyChangedSignal("Text"):Connect(function()
        if KeyBox:GetAttribute("Lock") then
            return
        end
        local T = KeyBox.Text
        if KeyShown then
            KeyReal = T
        else
            if T:find("•") then
                return
            end
            KeyReal = T
            KeyBox:SetAttribute("Lock", true)
            KeyBox.Text = Mask(KeyReal)
            KeyBox:SetAttribute("Lock", false)
            KeyBox.CursorPosition = #KeyBox.Text + 1
        end
    end)
    local EyeBtn = GlyphButton(UI.KeyField, Library.Icons.EyeOff, "Show key")
    EyeBtn.AnchorPoint = Vector2.new(1, 0.5)
    EyeBtn.Position = UDim2.new(1, -44, 0.5, 0)
    EyeBtn.Size = UDim2.fromOffset(28, 28)
    EyeBtn.MouseButton1Click:Connect(function()
        KeyShown = not KeyShown
        local Icon = EyeBtn:FindFirstChildOfClass("ImageLabel")
        if Icon then
            Library:SetIcon(Icon, KeyShown and Library.Icons.Eye or Library.Icons.EyeOff)
        end
        KeyBox:SetAttribute("Lock", true)
        KeyBox.Text = KeyShown and KeyReal or Mask(KeyReal)
        KeyBox:SetAttribute("Lock", false)
        Library:Feedback(1.05)
    end)
    local KeySave = GlyphButton(UI.KeyField, Library.Icons.Check, "Verify and save")
    KeySave.AnchorPoint = Vector2.new(1, 0.5)
    KeySave.Position = UDim2.new(1, -8, 0.5, 0)
    KeySave.Size = UDim2.fromOffset(28, 28)

    function Fn.Layout()
        local HasKey = Library.Groq.Key ~= ""
        local SuggestH = (HasKey and UI.Suggest.Visible) and 34 or 0
        local Total
        if HasKey then
            local FieldH = Clamp(UI.Box.TextBounds.Y + 24, 46, 124)
            UI.Field.Position = UDim2.new(0, 12, 0, SuggestH + 4)
            UI.Field.Size = UDim2.new(1, -24, 0, FieldH)
            UI.Hint.Position = UDim2.new(0, 18, 0, SuggestH + 4 + FieldH + 4)
            UI.Count.Position = UDim2.new(1, -18, 0, SuggestH + 4 + FieldH + 4)
            Total = SuggestH + 4 + FieldH + 4 + 14 + 8
        else
            Total = 8 + 44 + 14
        end
        UI.Composer.Size = UDim2.new(1, 0, 0, Total)
        UI.Log.Size = UDim2.new(1, 0, 1, -(HeadH + Total))
        UI.Empty.Size = UDim2.new(1, 0, 1, -(HeadH + Total))
    end

    function Fn.PaintSend()
        local HasText = Trim(UI.Box.Text) ~= ""
        local Busy = State.Mode ~= "idle"
        Library:SetIcon(UI.SendIcon, Busy and Library.Icons.Close or Library.Icons.Send)
        Library:Tween(UI.Send, FAST, { BackgroundTransparency = (HasText or Busy) and 0.05 or 0.7 })
    end

    function Fn.PaintConnection()
        local HasKey = Library.Groq.Key ~= ""
        UI.StatusDot.BackgroundColor3 = HasKey and Library.Theme.Success or Library.Theme.Warn
        UI.Field.Visible = HasKey
        UI.Hint.Visible = HasKey
        UI.Count.Visible = HasKey
        UI.KeyField.Visible = not HasKey
        UI.Suggest.Visible = HasKey
        UI.Banner.Visible = not HasKey
        if UI.Status then
            UI.Status.Text = HasKey and "Connected" or "No key set"
            UI.Status.TextColor3 = HasKey and Library.Theme.Success or Library.Theme.Warn
        end
        Fn.Layout()
    end
    Library.OnThemeChanged:Connect(function()
        if Panel.Parent then
            Fn.PaintConnection()
        end
    end)

    UI.Box:GetPropertyChangedSignal("Text"):Connect(function()
        local T = UI.Box.Text
        if #T > MaxChars then
            UI.Box.Text = T:sub(1, MaxChars)
            return
        end
        if Fn.PendingEnter and T:find("\n$") then
            Fn.PendingEnter = false
            UI.Box.Text = (T:gsub("\n+$", ""))
            Fn.Submit()
            return
        end
        UI.Count.Text = #T > 200 and (#T .. " / " .. MaxChars) or ""
        Fn.PaintSend()
        Fn.Layout()
    end)
    UI.Box:GetPropertyChangedSignal("TextBounds"):Connect(Fn.Layout)
    UI.Box.Focused:Connect(function()
        Library:Tween(UI.FieldLine, FAST, { Transparency = 0.1 })
    end)
    UI.Box.FocusLost:Connect(function()
        Library:Tween(UI.FieldLine, FAST, { Transparency = 0.5 })
    end)
    table.insert(W.Connections, UserInputService.InputBegan:Connect(function(Input)
        if (Input.KeyCode == Enum.KeyCode.Return or Input.KeyCode == Enum.KeyCode.KeypadEnter)
            and UI.Box:IsFocused()
            and not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
            Fn.PendingEnter = true
            task.delay(0.25, function()
                Fn.PendingEnter = false
            end)
        end
    end))

    -- ------------------------------------------------------------------ conversation logic
    local function HubContext()
        local Lines = {}
        for TabIndex, Tab in ipairs(W.Tabs) do
            if TabIndex > 14 then
                break
            end
            local Parts = {}
            for _, Section in ipairs(Tab.Sections or {}) do
                local Names = {}
                for ElementIndex, Element in ipairs(Section.Elements or {}) do
                    if ElementIndex > 10 then
                        break
                    end
                    table.insert(Names, tostring(Element.Title) .. " (" .. tostring(Element.Kind) .. ")")
                end
                table.insert(Parts, tostring(Section.Title) .. ": " .. table.concat(Names, ", "))
            end
            table.insert(Lines, "- " .. tostring(Tab.Name) .. " | " .. table.concat(Parts, " | "))
        end
        return table.concat(Lines, "\n"):sub(1, 1800)
    end

    local function BuildSystem()
        local Persona = Library.Groq.Prompt
        for _, Item in ipairs(Personas) do
            if Item.Name == Settings.Persona then
                local Text = Item.Text()
                if Trim(tostring(Text)) ~= "" then
                    Persona = Text
                end
            end
        end
        local Parts = { Persona }
        table.insert(Parts, "The user is " .. tostring(LocalPlayer.DisplayName) .. ". Format replies in Markdown and use fenced code blocks with a language for code.")
        table.insert(Parts, "To open a tab of this hub for the user, include [[tab:Exact Tab Name]] in your reply.")
        if Settings.Context then
            table.insert(Parts, "This hub has these tabs and controls:\n" .. HubContext())
        end
        return table.concat(Parts, "\n\n")
    end

    local function BuildMessages()
        local Messages = { { role = "system", content = BuildSystem() } }
        for Index = math.max(1, #History - 23), #History do
            local Entry = History[Index]
            if Entry and (Entry.Role == "user" or Entry.Role == "assistant") then
                table.insert(Messages, { role = Entry.Role, content = Entry.Text })
            end
        end
        return Messages
    end

    function Fn.SetMode(Mode)
        State.Mode = Mode
        Fn.PaintSend()
    end

    function Fn.Reveal(Labels)
        State.Skip = false
        if not Settings.Typewriter then
            return
        end
        for _, Label in ipairs(Labels) do
            Label.MaxVisibleGraphemes = 0
        end
        for _, Label in ipairs(Labels) do
            local Plain = Label.ContentText
            if Plain == "" then
                Plain = Label.Text:gsub("<[^>]+>", "")
            end
            local Total = utf8.len(Plain) or #Plain
            local Shown = 0
            local Rate = math.max(520, Total / 2.2)
            while Shown < Total and Label.Parent and not State.Skip do
                Shown = Shown + Rate * RunService.Heartbeat:Wait()
                Label.MaxVisibleGraphemes = math.floor(Shown)
                ScrollEnd(false)
            end
            Label.MaxVisibleGraphemes = -1
        end
        for _, Label in ipairs(Labels) do
            Label.MaxVisibleGraphemes = -1
        end
    end

    function Fn.Query()
        Fn.SetMode("waiting")
        local Request = { Cancelled = false }
        State.Request = Request
        local Typing = Fn.Typing()
        State.Typing = Typing
        ScrollEnd(true)
        AI.ChatRequest(BuildMessages(), function(Ok, Text, Info)
            if Request.Cancelled then
                return
            end
            Typing.Destroy()
            State.Typing = nil
            if not Ok then
                Fn.SetMode("idle")
                Fn.ErrorMessage(Text, Info and Info.Kind)
                ScrollEnd(true)
                return
            end
            table.insert(History, { Role = "assistant", Text = Text, Time = os.time() })
            SaveHistory()
            local Entry = Fn.AssistantMessage(Text, { Time = os.time(), Info = Info })
            Fn.SetMode("revealing")
            ScrollEnd(true)
            Fn.Reveal(Entry.Reveal)
            Fn.SetMode("idle")
        end)
    end

    function Fn.Submit(Override)
        if State.Mode ~= "idle" then
            Fn.Stop()
            return
        end
        local Text = Trim(Override or UI.Box.Text)
        if Text == "" then
            return
        end
        if Library.Groq.Key == "" then
            Fn.OpenSettings(true)
            Notify("AI Assistant", "Add an API key first", "Warn")
            return
        end
        if Override == nil then
            UI.Box.Text = ""
        end
        table.insert(History, { Role = "user", Text = Text, Time = os.time() })
        Fn.UserMessage(Text)
        Fn.UpdateEmpty()
        Fn.Query()
    end

    function Fn.Stop()
        if State.Mode == "waiting" then
            if State.Request then
                State.Request.Cancelled = true
            end
            if State.Typing then
                State.Typing.Destroy()
                State.Typing = nil
            end
            -- put the question back in the box so it can be edited
            local Last = History[#History]
            if Last and Last.Role == "user" then
                table.remove(History)
                for Index = #Rows, 1, -1 do
                    if Rows[Index].Role == "user" then
                        Rows[Index].Row:Destroy()
                        table.remove(Rows, Index)
                        break
                    end
                end
                UI.Box.Text = Last.Text
            end
            Fn.SetMode("idle")
            Fn.UpdateEmpty()
        elseif State.Mode == "revealing" then
            State.Skip = true
        end
    end

    function Fn.Retry()
        if State.Mode ~= "idle" then
            return
        end
        local Last = History[#History]
        if not (Last and Last.Role == "assistant") then
            return
        end
        table.remove(History)
        for Index = #Rows, 1, -1 do
            if Rows[Index].Role == "assistant" then
                Rows[Index].Row:Destroy()
                table.remove(Rows, Index)
                break
            end
        end
        Fn.Query()
    end

    function Fn.Clear()
        table.clear(History)
        SaveHistory()
        FS.WriteJSON(HistoryPath, History)
        for _, Child in ipairs(UI.Log:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
        table.clear(Rows)
        State.Skip = true
        Fn.UpdateEmpty()
    end

    function Fn.Export()
        local Lines = {}
        for _, Entry in ipairs(History) do
            table.insert(Lines, string.upper(Entry.Role) .. ": " .. Entry.Text)
        end
        if Env.setclipboard then
            pcall(Env.setclipboard, table.concat(Lines, "\n\n"))
        end
        Notify("Chat", "Exported to clipboard", "Success", 2)
    end

    UI.Send.MouseButton1Click:Connect(function()
        Library:Feedback(1.05)
        Fn.Submit()
    end)
    UI.Send.MouseEnter:Connect(function()
        if Trim(UI.Box.Text) ~= "" or State.Mode ~= "idle" then
            Library:Tween(UI.Send, FAST, { Size = UDim2.fromOffset(37, 37) })
        end
    end)
    UI.Send.MouseLeave:Connect(function()
        Library:Tween(UI.Send, FAST, { Size = UDim2.fromOffset(34, 34) })
    end)
    ClearButton.MouseButton1Click:Connect(Fn.Clear)
    ExportButton.MouseButton1Click:Connect(Fn.Export)

    -- ------------------------------------------------------------------ key handling
    local function ApplyKey(Value)
        local Key = Trim(Value or KeyReal or "")
        if Key == "" then
            Notify("API Key", "Paste your key first", "Warn")
            return
        end
        if tostring(Library.Groq.Endpoint):find("groq.com") and not Key:lower():find("^gsk") then
            Notify("API Key", "Key must start with gsk", "Error")
            return
        end
        Notify("API Key", "Verifying...", "Info", 2)
        Library:TestGroqKey(Key, function(Ok, Message)
            if not Ok then
                Notify("API Key", tostring(Message or "invalid"), "Error", 4)
                return
            end
            Library.Groq.Key = Key
            FS.Write(Folder .. "/groq_key.txt", Key)
            KeyReal = ""
            KeyBox:SetAttribute("Lock", true)
            KeyBox.Text = ""
            KeyBox:SetAttribute("Lock", false)
            Fn.PaintConnection()
            Notify("API Key", "Verified and saved", "Success")
        end)
    end
    function Fn.RemoveKey()
        Library:ClearGroqKey()
        FS.Write(Folder .. "/groq_key.txt", "")
        Fn.PaintConnection()
        Notify("API Key", "Key removed", "Info", 2)
    end
    KeySave.MouseButton1Click:Connect(function()
        ApplyKey(KeyReal)
    end)
    KeyBox.FocusLost:Connect(function(Enter)
        if Enter then
            ApplyKey(KeyReal)
        end
    end)

    -- ------------------------------------------------------------------ suggestion chips (rotating, with tab jumps)
    local SuggestSeed = { "Explain this hub", "Jump to Combat", "Jump to Visual", "List toggles", "How to use configs" }
    local function RenderSuggest(List)
        for _, Child in ipairs(UI.Suggest:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
        for Index, Item in ipairs(List or SuggestSeed) do
            local Chip = New("TextButton", {
                Parent = UI.Suggest,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(0, 26),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = Index
            })
            Library:Corner(Chip, UDim.new(1, 0))
            Library:Themed(Chip, "BackgroundColor3", "Inset")
            Library:Themed(Chip, "BackgroundTransparency", "InsetAlpha")
            local ChipLine = Library:Stroke(Chip, "StrokeSoft", 1)
            Library:Hover(Chip, ChipLine, "Transparency", Library.Theme.StrokeSoftAlpha, 0.35)
            New("UIPadding", { Parent = Chip, PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11) })
            local Lab = New("TextLabel", {
                Parent = Chip,
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 26),
                Font = Library.Font.Medium,
                Text = tostring(Item),
                TextSize = 11
            })
            Library:Themed(Lab, "TextColor3", "TextDim")
            Chip.MouseButton1Click:Connect(function()
                local Text = tostring(Item)
                local Jump = Text:match("[Jj]ump to (.+)")
                if Jump and W.API then
                    W.API:SelectTab(Jump)
                    return
                end
                Fn.Submit(Text)
            end)
        end
    end
    RenderSuggest(SuggestSeed)
    task.spawn(function()
        while Panel.Parent do
            task.wait(5)
            if Library.Groq.Key ~= "" and State.Mode == "idle" then
                local Names = {}
                for _, Tab in ipairs(W.Tabs) do
                    table.insert(Names, Tab.Name)
                end
                local Pick = Names[math.random(1, math.max(#Names, 1))] or "General"
                RenderSuggest({
                    "Jump to " .. Pick,
                    "Summarize settings",
                    "Best config tip",
                    "What is panic key?",
                    SuggestSeed[math.random(1, #SuggestSeed)]
                })
            end
        end
    end)

    -- "Open <tab>" chips under the starter cards
    do
        local Jumps = New("Frame", {
            Parent = UI.Empty,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6
        })
        local JumpLayout = New("UIListLayout", {
            Parent = Jumps,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        pcall(function()
            JumpLayout.Wraps = true
        end)
        for Index, Tab in ipairs(W.Tabs) do
            if Index > 4 then
                break
            end
            local Pill = PillButton(Jumps, Tab.Name, Library.Icons.Right, 36 + #tostring(Tab.Name) * 7, false)
            Pill.LayoutOrder = Index
            Pill.MouseButton1Click:Connect(function()
                if W.API then
                    W.API:SelectTab(Tab.Name)
                end
            end)
        end
    end

    -- ------------------------------------------------------------------ model popup
    UI.ModelPill.MouseButton1Click:Connect(function()
        local Count = #Library.Groq.Models
        local Handle = Popup(W, UI.ModelPill, 280, math.min(14 + Count * 34, 300))
        local List = New("ScrollingFrame", {
            Parent = Handle.Frame,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 203
        })
        Library:StyleScroll(List)
        Library:Padding(List, 6, 6, 6, 6)
        New("UIListLayout", { Parent = List, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
        for Index, Model in ipairs(Library.Groq.Models) do
            local Current = Model == Library.Groq.Model
            local Item = New("TextButton", {
                Parent = List,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 30),
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = Current and 0.84 or 1,
                LayoutOrder = Index,
                ZIndex = 204
            })
            Library:Corner(Item, UDim.new(1, 0))
            Library:Themed(Item, "BackgroundColor3", Current and "Accent" or "Row")
            local Label = New("TextLabel", {
                Parent = Item,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -44, 1, 0),
                Font = Library.Font.Medium,
                Text = Model,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 205
            })
            Library:Themed(Label, "TextColor3", Current and "Accent" or "TextDim")
            if Current then
                local Tick = IconLabel(Item, Library.Icons.Check, 13, "Accent")
                Tick.AnchorPoint = Vector2.new(1, 0.5)
                Tick.Position = UDim2.new(1, -12, 0.5, 0)
                Tick.ZIndex = 205
            end
            Item.MouseEnter:Connect(function()
                if not Current then
                    Library:Tween(Item, FAST, { BackgroundTransparency = 0.9 })
                end
            end)
            Item.MouseLeave:Connect(function()
                if not Current then
                    Library:Tween(Item, FAST, { BackgroundTransparency = 1 })
                end
            end)
            Item.MouseButton1Click:Connect(function()
                Library.Groq.Model = Model
                UI.ModelLabel.Text = Model
                SaveSettings()
                Handle:Close()
            end)
        end
    end)

    CloseButton.MouseButton1Click:Connect(function()
        WM.ToggleAI(W, false)
    end)

    -- ------------------------------------------------------------------ settings drawer
    UI.Drawer = New("Frame", {
        Parent = Panel,
        Name = "Settings",
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 96,
        ClipsDescendants = true
    })
    Library:Themed(UI.Drawer, "BackgroundColor3", "Elevated")
    Library:Themed(UI.Drawer, "BackgroundTransparency", "ElevatedAlpha")

    local DrawerBar = Blank(UI.Drawer, { Size = UDim2.new(1, 0, 0, HeadH), ZIndex = 97 })
    local BackButton = GlyphButton(DrawerBar, Library.Icons.Left, "Back")
    BackButton.AnchorPoint = Vector2.new(0, 0.5)
    BackButton.Position = UDim2.new(0, 10, 0.5, 0)
    local DrawerTitle = New("TextLabel", {
        Parent = DrawerBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 10),
        Size = UDim2.new(1, -70, 0, 18),
        Font = Library.Font.Bold,
        Text = "Assistant settings",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Library:Themed(DrawerTitle, "TextColor3", "Text")
    UI.Status = New("TextLabel", {
        Parent = DrawerBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 30),
        Size = UDim2.new(1, -70, 0, 14),
        Font = Library.Font.Medium,
        Text = "",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local DrawerScroll = New("ScrollingFrame", {
        Parent = UI.Drawer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, HeadH),
        Size = UDim2.new(1, 0, 1, -HeadH),
        ZIndex = 97,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3
    })
    Library:StyleScroll(DrawerScroll)
    Library:Padding(DrawerScroll, 4, 14, 12, 14)
    New("UIListLayout", { Parent = DrawerScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })

    local Fake = {
        Window = W,
        Tab = { Name = "AI Assistant" },
        Title = "AI Assistant",
        Elements = {},
        Count = 0,
        Body = DrawerScroll,
        Opened = true
    }

    -- connection card
    local Connection = Components.Card(Fake, {
        Title = "Connection",
        Description = "Your API key is stored on this device only",
        Icon = Library.Icons.Key
    })
    local KeyRow = New("Frame", {
        Parent = Connection.Body,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        LayoutOrder = 0
    })
    local KeyHolder = New("Frame", {
        Parent = KeyRow,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0)
    })
    Library:Corner(KeyHolder, UDim.new(1, 0))
    Library:Themed(KeyHolder, "BackgroundColor3", "Inset")
    Library:Themed(KeyHolder, "BackgroundTransparency", "InsetAlpha")
    Library:GlassEdge(KeyHolder, 1, 0.5)
    local DrawerKey = ""
    local DrawerShown = false
    local DrawerBox = New("TextBox", {
        Parent = KeyHolder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -56, 1, 0),
        Font = Library.Font.Regular,
        PlaceholderText = "Paste your API key",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    Library:Themed(DrawerBox, "TextColor3", "Text")
    Library:Themed(DrawerBox, "PlaceholderColor3", "TextDisabled")
    DrawerBox:GetPropertyChangedSignal("Text"):Connect(function()
        if DrawerBox:GetAttribute("Lock") then
            return
        end
        local T = DrawerBox.Text
        if DrawerShown then
            DrawerKey = T
        else
            if T:find("•") then
                return
            end
            DrawerKey = T
            DrawerBox:SetAttribute("Lock", true)
            DrawerBox.Text = Mask(DrawerKey)
            DrawerBox:SetAttribute("Lock", false)
            DrawerBox.CursorPosition = #DrawerBox.Text + 1
        end
    end)
    local DrawerEye = GlyphButton(KeyHolder, Library.Icons.EyeOff, "Show key")
    DrawerEye.AnchorPoint = Vector2.new(1, 0.5)
    DrawerEye.Position = UDim2.new(1, -8, 0.5, 0)
    DrawerEye.Size = UDim2.fromOffset(28, 28)
    DrawerEye.MouseButton1Click:Connect(function()
        DrawerShown = not DrawerShown
        local Icon = DrawerEye:FindFirstChildOfClass("ImageLabel")
        if Icon then
            Library:SetIcon(Icon, DrawerShown and Library.Icons.Eye or Library.Icons.EyeOff)
        end
        DrawerBox:SetAttribute("Lock", true)
        DrawerBox.Text = DrawerShown and DrawerKey or Mask(DrawerKey)
        DrawerBox:SetAttribute("Lock", false)
    end)
    Connection:AddMultiButton({
        Title = "Key",
        Buttons = {
            { Title = "Verify & save", Accent = true, Callback = function()
                ApplyKey(DrawerKey)
            end },
            { Title = "Remove key", Callback = function()
                Fn.RemoveKey()
            end }
        }
    })

    -- model card
    local ModelCard = Components.Card(Fake, {
        Title = "Model",
        Description = "Pick the model that answers you",
        Icon = Library.Icons.Cpu
    })
    local ModelDrop = ModelCard:AddDropdown({
        Title = "Model",
        Options = Library.Groq.Models,
        Default = Library.Groq.Model,
        Callback = function(Value)
            if type(Value) == "string" and Value ~= "" then
                Library.Groq.Model = Value
                UI.ModelLabel.Text = Value
                SaveSettings()
            end
        end
    })
    ModelCard:AddButton({
        Title = "Refresh model list",
        Description = "Ask the API which models your key can use",
        Callback = function()
            Library:FetchGroqModels(nil, function(Ok, Result)
                if not Ok then
                    Notify("Models", tostring(Result), "Error", 3)
                    return
                end
                Library:RefreshGroqModels(Result)
                ModelDrop:SetOptions(Result)
                ModelDrop:Set(Library.Groq.Model, true)
                UI.ModelLabel.Text = Library.Groq.Model
                Notify("Models", #Result .. " models found", "Success", 2)
            end)
        end
    })

    -- behaviour card
    local Behavior = Components.Card(Fake, {
        Title = "Behavior",
        Description = "How the assistant talks and what it knows",
        Icon = Library.Icons.Sparkles
    })
    Behavior:AddDropdown({
        Title = "Personality",
        Options = PersonaNames,
        Default = Settings.Persona,
        Callback = function(Value)
            Settings.Persona = tostring(Value)
            SaveSettings()
        end
    })
    Behavior:AddInput({
        Title = "Custom instructions",
        Description = "Used when personality is Custom",
        Placeholder = "e.g. Answer like a pirate",
        Default = Settings.Custom,
        Callback = function(Text)
            Settings.Custom = tostring(Text or "")
            SaveSettings()
        end
    })
    Behavior:AddToggle({
        Title = "Know this hub",
        Description = "Share tab and control names so it can guide you",
        Default = Settings.Context,
        Callback = function(Value)
            Settings.Context = Value and true or false
            SaveSettings()
        end
    })
    Behavior:AddToggle({
        Title = "Typewriter effect",
        Description = "Type replies out instead of showing them at once",
        Default = Settings.Typewriter,
        Callback = function(Value)
            Settings.Typewriter = Value and true or false
            SaveSettings()
        end
    })
    Behavior:AddToggle({
        Title = "Remember chat",
        Description = "Keep the conversation between sessions",
        Default = Settings.Save,
        Callback = function(Value)
            Settings.Save = Value and true or false
            SaveSettings()
        end
    })

    -- generation card
    local Generation = Components.Card(Fake, {
        Title = "Generation",
        Description = "Creativity and reply length",
        Icon = Library.Icons.Gauge
    })
    Generation:AddSlider({
        Title = "Creativity",
        Description = "Lower is focused, higher is more varied",
        Min = 0, Max = 1.2, Increment = 0.05,
        Default = Library.Groq.Temperature or 0.6,
        Callback = function(Value)
            Library.Groq.Temperature = tonumber(Value) or 0.6
            SaveSettings()
        end
    })
    Generation:AddSlider({
        Title = "Max reply length",
        Description = "Tokens per answer",
        Min = 200, Max = 2000, Increment = 50,
        Default = Library.Groq.MaxTokens or 900,
        Callback = function(Value)
            Library.Groq.MaxTokens = math.floor(tonumber(Value) or 900)
            SaveSettings()
        end
    })

    -- data card
    local Data = Components.Card(Fake, {
        Title = "Chat data",
        Description = "Export or wipe the conversation",
        Icon = Library.Icons.Folder
    })
    Data:AddMultiButton({
        Title = "Chat",
        Buttons = {
            { Title = "Copy chat", Callback = function()
                Fn.Export()
            end },
            { Title = "Clear chat", Callback = function()
                Fn.Clear()
                Notify("Chat", "Conversation cleared", "Info", 2)
            end }
        }
    })

    -- these controls are not part of the hub, so keep them out of the hub search
    local function Unindex(List)
        for _, Item in ipairs(List) do
            local Entry = Item.Registry
            if Entry then
                local At = table.find(W.Index, Entry)
                if At then
                    table.remove(W.Index, At)
                end
            end
            if Item.Elements then
                Unindex(Item.Elements)
            end
        end
    end
    Unindex(Fake.Elements)

    -- lift every control above the dock's z-index flattening, keeping their relative order
    for _, Descendant in ipairs(DrawerScroll:GetDescendants()) do
        if Descendant:IsA("GuiObject") then
            Descendant.ZIndex = Descendant.ZIndex + 90
        end
    end

    function Fn.OpenSettings(Open)
        UI.Open = Open
        if Open then
            UI.Drawer.Visible = true
            UI.Drawer.Position = UDim2.new(1, 0, 0, 0)
            Library:Tween(UI.Drawer, NORMAL, { Position = UDim2.new(0, 0, 0, 0) })
        else
            Library:Tween(UI.Drawer, NORMAL, { Position = UDim2.new(1, 0, 0, 0) }, function()
                if not UI.Open then
                    UI.Drawer.Visible = false
                end
            end)
        end
    end
    SettingsButton.MouseButton1Click:Connect(function()
        Fn.OpenSettings(not UI.Open)
    end)
    BackButton.MouseButton1Click:Connect(function()
        Fn.OpenSettings(false)
    end)

    -- ------------------------------------------------------------------ drag (floating mode only)
    do
        local Dragging, Origin, StartPos = false, nil, nil
        UI.Head.InputBegan:Connect(function(Input)
            if Panel:GetAttribute("Docked") then
                return
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                Origin = Input.Position
                StartPos = Panel.Position
                Library:BeginDragLock()
            end
        end)
        table.insert(W.Connections, UserInputService.InputChanged:Connect(function(Input)
            if not Dragging then
                return
            end
            if Input.UserInputType == Enum.UserInputType.MouseMovement
                or Input.UserInputType == Enum.UserInputType.Touch then
                local Delta = Input.Position - Origin
                Panel.Position = UDim2.new(
                    StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                    StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
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

    -- ------------------------------------------------------------------ boot
    local SavedKey = FS.Read(Folder .. "/groq_key.txt")
    if type(SavedKey) == "string" and Trim(SavedKey) ~= "" and Library.Groq.Key == "" then
        Library.Groq.Key = Trim(SavedKey)
    end
    for _, Entry in ipairs(History) do
        if Entry.Role == "user" then
            Fn.UserMessage(Entry.Text)
        elseif Entry.Role == "assistant" then
            Fn.AssistantMessage(Entry.Text, { Time = Entry.Time })
        end
    end
    Booting = false
    UI.ModelLabel.Text = Library.Groq.Model
    Fn.PaintConnection()
    Fn.PaintSend()
    Fn.UpdateEmpty()
    ScrollEnd(true)

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
    if W.Config.DockPanels and W.Content then
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
            WM.Password(W, {
                Title = Tab.LockConfig and Tab.LockConfig.Title or ("Locked: " .. Tab.Name),
                Description = Tab.LockConfig and Tab.LockConfig.Description or "Enter the password to unlock this tab",
                Password = Tab.LockConfig and Tab.LockConfig.Password or "",
                Remember = not (Tab.LockConfig and Tab.LockConfig.Remember == false),
                RememberMinutes = Tab.LockConfig and Tab.LockConfig.RememberMinutes or 10,
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
        Library:Pop(Tab.Page, 0.24, 0.99)

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
            Library:EndDragLock()
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
