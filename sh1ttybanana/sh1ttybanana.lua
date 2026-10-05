local Library = {}
Library.Version = "0.5.0-vind"

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local Quint = Enum.EasingStyle.Quint
local Back = Enum.EasingStyle.Back
local Out = Enum.EasingDirection.Out

local FAST = TweenInfo.new(0.14, Quint, Out)
local NORMAL = TweenInfo.new(0.26, Quint, Out)
local SLOW = TweenInfo.new(0.42, Quint, Out)
local SPRING = TweenInfo.new(0.38, Back, Out)

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

Library.Themes = {
    Dark = {
        Window = Color3.fromRGB(17, 17, 21),
        WindowAlpha = 0.14,
        Overlay = Color3.fromRGB(255, 255, 255),
        SidebarAlpha = 0.975,
        RowAlpha = 0.948,
        RowHoverAlpha = 0.915,
        ActiveAlpha = 0.885,
        ButtonAlpha = 0.935,
        ButtonHoverAlpha = 0.89,
        InsetAlpha = 0.9,
        TrackAlpha = 0.84,
        StrokeAlpha = 0.91,
        StrokeStrongAlpha = 0.8,
        Text = Color3.fromRGB(242, 242, 246),
        TextDim = Color3.fromRGB(150, 150, 160),
        TextFaint = Color3.fromRGB(108, 108, 118),
        Accent = Color3.fromRGB(238, 238, 243),
        AccentText = Color3.fromRGB(16, 16, 20),
        Success = Color3.fromRGB(112, 214, 152),
        Warn = Color3.fromRGB(240, 192, 96),
        Error = Color3.fromRGB(240, 104, 104),
        Info = Color3.fromRGB(128, 172, 255)
    },
    Midnight = {
        Window = Color3.fromRGB(9, 12, 24),
        WindowAlpha = 0.1,
        Overlay = Color3.fromRGB(176, 196, 255),
        SidebarAlpha = 0.97,
        RowAlpha = 0.945,
        RowHoverAlpha = 0.91,
        ActiveAlpha = 0.86,
        ButtonAlpha = 0.93,
        ButtonHoverAlpha = 0.88,
        InsetAlpha = 0.9,
        TrackAlpha = 0.82,
        StrokeAlpha = 0.9,
        StrokeStrongAlpha = 0.78,
        Text = Color3.fromRGB(232, 238, 255),
        TextDim = Color3.fromRGB(140, 152, 186),
        TextFaint = Color3.fromRGB(100, 112, 146),
        Accent = Color3.fromRGB(168, 190, 255),
        AccentText = Color3.fromRGB(8, 10, 22),
        Success = Color3.fromRGB(112, 214, 152),
        Warn = Color3.fromRGB(240, 192, 96),
        Error = Color3.fromRGB(240, 104, 104),
        Info = Color3.fromRGB(128, 172, 255)
    },
    Light = {
        Window = Color3.fromRGB(246, 246, 249),
        WindowAlpha = 0.04,
        Overlay = Color3.fromRGB(0, 0, 0),
        SidebarAlpha = 0.97,
        RowAlpha = 0.955,
        RowHoverAlpha = 0.92,
        ActiveAlpha = 0.88,
        ButtonAlpha = 0.94,
        ButtonHoverAlpha = 0.89,
        InsetAlpha = 0.92,
        TrackAlpha = 0.86,
        StrokeAlpha = 0.9,
        StrokeStrongAlpha = 0.8,
        Text = Color3.fromRGB(24, 24, 30),
        TextDim = Color3.fromRGB(98, 98, 110),
        TextFaint = Color3.fromRGB(140, 140, 152),
        Accent = Color3.fromRGB(26, 26, 32),
        AccentText = Color3.fromRGB(246, 246, 250),
        Success = Color3.fromRGB(34, 160, 92),
        Warn = Color3.fromRGB(200, 138, 20),
        Error = Color3.fromRGB(210, 60, 60),
        Info = Color3.fromRGB(46, 110, 220)
    }
}

Library.ThemeOrder = { "Dark", "Midnight", "Light" }
Library.CurrentTheme = "Dark"
Library.Theme = Library.Themes.Dark
Library.Binds = {}
Library.OnThemeChanged = Signal.new()

function Library:Bind(Object, Callback)
    table.insert(Library.Binds, { Object = Object, Callback = Callback })
    Callback()
    return Object
end

function Library:Themed(Object, Map)
    return Library:Bind(Object, function()
        for Property, Key in pairs(Map) do
            local Value = Library.Theme[Key]
            if Value ~= nil then
                Object[Property] = Value
            end
        end
    end)
end

function Library:RefreshTheme()
    local Alive = {}
    for _, Entry in ipairs(Library.Binds) do
        if Entry.Object.Parent ~= nil then
            pcall(Entry.Callback)
            table.insert(Alive, Entry)
        end
    end
    Library.Binds = Alive
    Library.OnThemeChanged:Fire(Library.CurrentTheme, Library.Theme)
end

function Library:AddTheme(Name, Tokens)
    if type(Name) ~= "string" or type(Tokens) ~= "table" then
        return nil
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
    Library:RefreshTheme()
    return true
end

Library.Font = {
    Regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    Medium = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
    SemiBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
    Bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    Mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
}

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

Library.IconPack = IconPack

local IconCache = {}

local function ResolveIcon(Name)
    if type(Name) ~= "string" or Name == "" then
        return nil
    end
    if IconCache[Name] ~= nil then
        return IconCache[Name] or nil
    end
    local Result = false
    if Name:find("rbxassetid") or Name:find("rbxasset://") or Name:find("http") then
        Result = { Image = Name, Size = Vector2.new(), Offset = Vector2.new() }
    elseif IconPack and IconPack.Icon then
        for Candidate in Name:gmatch("[^|]+") do
            local Key = Candidate:find(":") and Candidate or ("lucide:" .. Candidate)
            local Ok, Data = pcall(IconPack.Icon, Key)
            if Ok and type(Data) == "table" and Data[1] then
                local Rect = type(Data[2]) == "table" and Data[2] or {}
                Result = {
                    Image = tostring(Data[1]),
                    Size = Rect.ImageRectSize or Vector2.new(),
                    Offset = Rect.ImageRectPosition or Vector2.new()
                }
                break
            elseif Ok and type(Data) == "string" and Data ~= "" then
                Result = { Image = Data, Size = Vector2.new(), Offset = Vector2.new() }
                break
            end
        end
    end
    IconCache[Name] = Result
    return Result or nil
end

function Library:SetIcon(Object, Name)
    local Data = ResolveIcon(Name)
    if Data then
        Object.Image = Data.Image
        Object.ImageRectSize = Data.Size
        Object.ImageRectOffset = Data.Offset
    else
        Object.Image = ""
        Object.ImageRectSize = Vector2.new()
        Object.ImageRectOffset = Vector2.new()
    end
    return Object
end

local function Tween(Object, Info, Props)
    local Item = TweenService:Create(Object, Info, Props)
    Item:Play()
    return Item
end

Library.Tween = function(_, Object, Info, Props)
    return Tween(Object, Info, Props)
end

local function Corner(Object, Radius)
    return New("UICorner", {
        Parent = Object,
        CornerRadius = typeof(Radius) == "UDim" and Radius or UDim.new(0, Radius or 8)
    })
end

local function Stroke(Object, AlphaKey, Thickness)
    local Line = New("UIStroke", {
        Parent = Object,
        Thickness = Thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round
    })
    Library:Themed(Line, { Color = "Overlay", Transparency = AlphaKey or "StrokeAlpha" })
    return Line
end

local function Padding(Object, Top, Bottom, Left, Right)
    return New("UIPadding", {
        Parent = Object,
        PaddingTop = UDim.new(0, Top or 0),
        PaddingBottom = UDim.new(0, Bottom or 0),
        PaddingLeft = UDim.new(0, Left or 0),
        PaddingRight = UDim.new(0, Right or 0)
    })
end

local function List(Parent, Gap, Horizontal, HAlign, VAlign)
    return New("UIListLayout", {
        Parent = Parent,
        Padding = UDim.new(0, Gap or 0),
        FillDirection = Horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        HorizontalAlignment = HAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = VAlign or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
end

local function Frame(Parent, Props)
    local Data = {
        Parent = Parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1)
    }
    for Key, Value in pairs(Props or {}) do
        Data[Key] = Value
    end
    return New("Frame", Data)
end

local function Label(Parent, Text, Size, Weight, Token, Props)
    local Data = {
        Parent = Parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        FontFace = Library.Font[Weight or "Regular"],
        Text = Text or "",
        TextSize = Size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0)
    }
    for Key, Value in pairs(Props or {}) do
        Data[Key] = Value
    end
    local Item = New("TextLabel", Data)
    Library:Themed(Item, { TextColor3 = Token or "Text" })
    return Item
end

local function Icon(Parent, Name, Size, Token, Props)
    local Data = {
        Parent = Parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(Size, Size),
        ScaleType = Enum.ScaleType.Fit,
        Image = ""
    }
    for Key, Value in pairs(Props or {}) do
        Data[Key] = Value
    end
    local Item = New("ImageLabel", Data)
    Library:SetIcon(Item, Name)
    Library:Themed(Item, { ImageColor3 = Token or "TextDim" })
    return Item
end

local function Fill(Object, Color, Alpha)
    Library:Themed(Object, { BackgroundColor3 = Color or "Overlay", BackgroundTransparency = Alpha or "RowAlpha" })
end

local function Call(Callback, ...)
    if type(Callback) ~= "function" then
        return
    end
    local Args = table.pack(...)
    task.spawn(function()
        local Ok, Err = pcall(Callback, table.unpack(Args, 1, Args.n))
        if not Ok then
            warn("[sh1ttybanana] callback: " .. tostring(Err))
        end
    end)
end

local function IsPress(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
    return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

local function Track(Object, OnBegin, OnMove, OnEnd)
    return Object.InputBegan:Connect(function(Input)
        if not IsPress(Input) then
            return
        end
        if OnBegin and OnBegin(Input) == false then
            return
        end
        local Moved
        local Ended
        local function Stop()
            if Moved then
                Moved:Disconnect()
                Moved = nil
            end
            if Ended then
                Ended:Disconnect()
                Ended = nil
            end
            if OnEnd then
                OnEnd()
            end
        end
        Moved = UserInputService.InputChanged:Connect(function(Changed)
            if IsMove(Changed) then
                OnMove(Changed.Position)
            end
        end)
        Ended = UserInputService.InputEnded:Connect(function(Done)
            if Done.UserInputType == Input.UserInputType and Done.UserInputState == Enum.UserInputState.End then
                Stop()
            end
        end)
        OnMove(Input.Position)
    end)
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
    local Found = Library.Options[Flag]
    if Found then
        Found:Set(Value)
        return true
    end
    return false
end

local function Encode(Value)
    local Kind = typeof(Value)
    if Kind == "Color3" then
        return { __t = "Color3", r = Value.R, g = Value.G, b = Value.B }
    elseif Kind == "EnumItem" then
        return { __t = "Enum", Type = tostring(Value.EnumType), Name = Value.Name }
    elseif Kind == "table" then
        local Copy = {}
        for Key, Item in pairs(Value) do
            Copy[Key] = Encode(Item)
        end
        return Copy
    elseif Kind == "nil" or Kind == "boolean" or Kind == "number" or Kind == "string" then
        return Value
    end
    return tostring(Value)
end

local function Decode(Value)
    if type(Value) ~= "table" then
        return Value
    end
    if Value.__t == "Color3" then
        return Color3.new(Value.r, Value.g, Value.b)
    elseif Value.__t == "Enum" then
        local Ok, Found = pcall(function()
            return Enum[Value.Type][Value.Name]
        end)
        return Ok and Found or nil
    end
    local Copy = {}
    for Key, Item in pairs(Value) do
        Copy[Key] = Decode(Item)
    end
    return Copy
end

Library.Encode = Encode
Library.Decode = Decode

local Element = {}
Element.__index = Element

function Element.new(Data)
    Data.Changed = Signal.new()
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

function Element:Emit(Value, Silent)
    self.Value = Value
    if self.Flag then
        Library.Flags[self.Flag] = Value
    end
    if Silent then
        return
    end
    self.Changed:Fire(Value)
    if self.Flag then
        self.Window.QueueSave()
    end
    local Callback = self.Config.Callback
    if self.Spread and type(Value) == "table" then
        Call(Callback, Value[1], Value[2])
    else
        Call(Callback, Value)
    end
end

function Element:SetVisible(State)
    self.Frame.Visible = State ~= false
    return self
end

function Element:SetTitle(Text)
    self.Title = tostring(Text)
    if self.TitleLabel then
        self.TitleLabel.Text = self.Title
    end
    return self
end

function Element:SetDescription(Text)
    self.Description = tostring(Text)
    if self.DescLabel then
        self.DescLabel.Text = self.Description
        self.DescLabel.Visible = self.Description ~= ""
    end
    return self
end

function Element:SetLocked(State, Reason)
    self.Locked = State and true or false
    if Reason and self.LockLabel then
        self.LockLabel.Text = Reason
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
    self.Dead = true
    if self.Flag then
        if Library.Options[self.Flag] == self then
            Library.Options[self.Flag] = nil
        end
        if self.Window.Flags[self.Flag] == self then
            self.Window.Flags[self.Flag] = nil
        end
    end
    if self.Search then
        self.Search.Dead = true
    end
    self.Changed:Destroy()
    if self.Frame then
        self.Frame:Destroy()
    end
end

Library.Element = Element

local Components = {}
Library.Components = Components

local function Apply(Object, Animate, Props, Info)
    if Animate then
        Tween(Object, Info or NORMAL, Props)
    else
        for Key, Value in pairs(Props) do
            Object[Key] = Value
        end
    end
end

local function Boot(El, Config, Default)
    local Value = Default
    local FromConfig = false
    if Config.Flag then
        local Saved = El.Window.Pending[Config.Flag]
        if Saved ~= nil then
            Value = Decode(Saved)
            El.Window.Pending[Config.Flag] = nil
            FromConfig = true
        end
    end
    El:Set(Value, not FromConfig)
    if Config.Flag then
        Library.Flags[Config.Flag] = El:Get()
    end
end

local function DescOf(Config)
    return Config.Description or Config.Desc or Config.Content or ""
end

local function MakeRow(Container, Config, Opts)
    Opts = Opts or {}
    local Flat = Container.Flat
    local MinHeight = Opts.MinHeight or 52
    local Row = Frame(Container.Holder, {
        Size = UDim2.new(1, 0, 0, MinHeight),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = Container.NextOrder()
    })
    Corner(Row, 8)
    if Flat then
        Library:Themed(Row, { BackgroundColor3 = "Overlay" })
        Row.BackgroundTransparency = 1
    else
        Fill(Row, "Overlay", "RowAlpha")
        Stroke(Row, "StrokeAlpha")
    end

    local Hit
    if Opts.Clickable then
        Hit = New("TextButton", {
            Parent = Row,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 1
        })
        Hit.MouseEnter:Connect(function()
            Tween(Row, FAST, { BackgroundTransparency = Library.Theme.RowHoverAlpha })
        end)
        Hit.MouseLeave:Connect(function()
            Tween(Row, FAST, { BackgroundTransparency = Flat and 1 or Library.Theme.RowAlpha })
        end)
    end

    local RightWidth = Opts.RightWidth or 0
    local Body = Frame(Row, {
        Size = UDim2.new(1, 0, 0, MinHeight),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 2
    })
    Padding(Body, 10, 10 + (Opts.PadBottom or 0), 14, RightWidth > 0 and (RightWidth + 26) or 14)
    List(Body, 0, false, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local Inner = Frame(Body, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    List(Inner, 12, true, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local IconLabel
    if Config.Icon then
        IconLabel = Icon(Inner, Config.Icon, 18, "TextDim", { LayoutOrder = 1 })
    end

    local Stack = Frame(Inner, {
        Size = UDim2.new(1, IconLabel and -30 or 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2
    })
    List(Stack, 2)

    local Description = DescOf(Config)
    local Title = Label(Stack, Config.Title or "", 13, "Medium", "Text", {
        LayoutOrder = 1,
        Visible = (Config.Title or "") ~= ""
    })
    local Desc = Label(Stack, Description, 11.5, "Regular", "TextDim", {
        LayoutOrder = 2,
        Visible = Description ~= ""
    })

    local Right
    if RightWidth > 0 then
        local Top = Opts.RightTop
        Right = Frame(Row, {
            AnchorPoint = Vector2.new(1, Top and 0 or 0.5),
            Position = UDim2.new(1, -12, Top and 0 or 0.5, Top or 0),
            Size = UDim2.fromOffset(RightWidth, Opts.RightHeight or 28),
            ZIndex = 3
        })
    end

    return {
        Frame = Row,
        Hit = Hit,
        Body = Body,
        Right = Right,
        TitleLabel = Title,
        DescLabel = Desc,
        IconLabel = IconLabel
    }
end

local function AttachLock(El, Config)
    if not Config.Lock and not Config.Locked then
        return
    end
    local W = El.Window
    local LockCfg = type(Config.Lock) == "table" and Config.Lock or nil
    local Row = El.Frame

    local Blocker = New("TextButton", {
        Parent = Row,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Visible = false,
        ZIndex = 40
    })

    local Dim = Frame(Blocker, { ZIndex = 1 })
    Corner(Dim, 8)
    Library:Themed(Dim, { BackgroundColor3 = "Window" })
    Dim.BackgroundTransparency = 0.3

    local Chip = Frame(Blocker, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 2
    })
    Corner(Chip, UDim.new(1, 0))
    Fill(Chip, "Overlay", "InsetAlpha")
    Stroke(Chip, "StrokeStrongAlpha")
    Padding(Chip, 0, 0, 10, 10)
    List(Chip, 6, true, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    New("UISizeConstraint", { Parent = Chip, MaxSize = Vector2.new(200, 26) })

    Icon(Chip, "lock", 13, "TextDim", { LayoutOrder = 1 })
    local Text = Label(Chip, "Locked", 11.5, "Medium", "TextDim", {
        LayoutOrder = 2,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 26),
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    El.LockLabel = Text

    El.PaintLock = function(State)
        Blocker.Visible = State
        if El.TitleLabel then
            El.TitleLabel.TextTransparency = State and 0.45 or 0
        end
    end

    local Has = LockCfg and Library.Auth.Has(LockCfg)
    local LockId = Has and (LockCfg.Id or LockCfg.Key or ("element_" .. tostring(El.Title)))

    if Has then
        local Verify = Library.Auth.Resolve(LockCfg)
        Blocker.MouseButton1Click:Connect(function()
            W.Dialog({
                Title = LockCfg.Title or "Locked",
                Content = LockCfg.Description or "Enter your key to unlock this control.",
                Type = "Question",
                Input = { Placeholder = LockCfg.Placeholder or "key", Default = "" },
                Buttons = {
                    { Title = "Cancel" },
                    {
                        Title = LockCfg.Confirm or "Unlock",
                        Filled = true,
                        Callback = function(Value)
                            local Ok, Reason, Payload = Verify(Trim(Value or ""), { Kind = "Element", Id = LockId })
                            if Ok then
                                El:SetLocked(false)
                                if LockCfg.Remember ~= false then
                                    Library.Auth.Remember(W, LockId, tonumber(LockCfg.RememberMinutes) or 30)
                                end
                                W.Notify({ Title = "Unlocked", Content = tostring(El.Title), Type = "Success", Duration = 3 })
                                Call(LockCfg.OnUnlock, Payload)
                            else
                                W.Notify({ Title = "Locked", Content = tostring(Reason or "Access denied"), Type = "Error", Duration = 4 })
                            end
                        end
                    }
                }
            })
        end)
    end

    if not (Has and LockCfg.Remember ~= false and Library.Auth.IsRemembered(W, LockId)) then
        El:SetLocked(true, LockCfg and LockCfg.Title or nil)
    end
end

local function Finish(Container, Kind, Config, R, Handlers)
    local W = Container.Window
    local El = Element.new({
        Kind = Kind,
        Config = Config,
        Container = Container,
        Window = W,
        Frame = R.Frame,
        TitleLabel = R.TitleLabel,
        DescLabel = R.DescLabel,
        Title = Config.Title or Kind,
        Description = DescOf(Config),
        Handlers = Handlers,
        Flag = Config.Flag,
        Locked = false
    })
    if Config.Flag then
        Library.Options[Config.Flag] = El
        W.Flags[Config.Flag] = El
    end
    if Kind ~= "MultiButton" and Kind ~= "Separator" then
        El.Search = W.AddSearch(El)
    end
    AttachLock(El, Config)
    if Config.Visible == false then
        El:SetVisible(false)
    end
    table.insert(Container.Elements, El)
    if Container.OnAdd then
        Container.OnAdd()
    end
    return El
end

local function ButtonStyle(Button, Filled)
    if Filled then
        Library:Themed(Button, { BackgroundColor3 = "Accent", TextColor3 = "AccentText" })
        Button.BackgroundTransparency = 0
    else
        Library:Themed(Button, { BackgroundColor3 = "Overlay", BackgroundTransparency = "ButtonAlpha", TextColor3 = "Text" })
    end
end

local function Format(Value)
    local Rounded = math.floor(Value * 1000 + 0.5) / 1000
    return tostring(Rounded)
end

function Components.Toggle(Container, Config)
    Config = Merge({ Title = "Toggle", Default = false }, Config)
    local R = MakeRow(Container, Config, { Clickable = true, RightWidth = 40, RightHeight = 22 })

    local Track = Frame(R.Right, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0 })
    Corner(Track, UDim.new(1, 0))
    local Line = Stroke(Track, "StrokeStrongAlpha")
    local Knob = Frame(Track, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 0,
        ZIndex = 2
    })
    Corner(Knob, UDim.new(1, 0))

    local State = false
    local El

    local function Paint(Animate)
        local Theme = Library.Theme
        if State then
            Apply(Track, Animate, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0 })
            Apply(Knob, Animate, {
                BackgroundColor3 = Theme.AccentText,
                BackgroundTransparency = 0,
                Position = UDim2.new(0, 21, 0.5, 0)
            })
            Apply(Line, Animate, { Transparency = 1 })
        else
            Apply(Track, Animate, { BackgroundColor3 = Theme.Overlay, BackgroundTransparency = Theme.TrackAlpha })
            Apply(Knob, Animate, {
                BackgroundColor3 = Theme.Text,
                BackgroundTransparency = 0.35,
                Position = UDim2.new(0, 3, 0.5, 0)
            })
            Apply(Line, Animate, { Transparency = Theme.StrokeStrongAlpha })
        end
    end

    Library:Bind(Track, function()
        Paint(false)
    end)

    local function SetValue(Value, Silent)
        State = Value and true or false
        Paint(not Silent)
        El:Emit(State, Silent)
    end

    R.Hit.MouseButton1Click:Connect(function()
        if not El.Locked then
            SetValue(not State)
        end
    end)

    El = Finish(Container, "Toggle", Config, R, { Set = SetValue })
    Boot(El, Config, Config.Default)
    return El
end

function Components.Button(Container, Config)
    Config = Merge({ Title = "Button" }, Config)
    local R = MakeRow(Container, Config, { Clickable = true, RightWidth = 18, RightHeight = 18 })

    local Chevron = Icon(R.Right, Config.RightIcon or "chevron-right", 16, "TextFaint", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5)
    })

    local El

    R.Hit.MouseEnter:Connect(function()
        Tween(Chevron, FAST, { Position = UDim2.new(0.5, 3, 0.5, 0) })
        Tween(Chevron, FAST, { ImageColor3 = Library.Theme.Text })
    end)
    R.Hit.MouseLeave:Connect(function()
        Tween(Chevron, FAST, { Position = UDim2.fromScale(0.5, 0.5), ImageColor3 = Library.Theme.TextFaint })
    end)
    R.Hit.MouseButton1Click:Connect(function()
        if El.Locked then
            return
        end
        Tween(R.Frame, FAST, { BackgroundTransparency = Library.Theme.ActiveAlpha })
        task.delay(0.12, function()
            if R.Frame.Parent then
                Tween(R.Frame, NORMAL, { BackgroundTransparency = Container.Flat and 1 or Library.Theme.RowAlpha })
            end
        end)
        El.Changed:Fire(true)
        Call(Config.Callback)
    end)

    El = Finish(Container, "Button", Config, R, {})
    return El
end

function Components.MultiButton(Container, Config)
    Config = Merge({ Buttons = {} }, Config)
    local Count = math.max(#Config.Buttons, 1)
    local Gap = 8

    local Holder = Frame(Container.Holder, {
        Size = UDim2.new(1, 0, 0, 38),
        LayoutOrder = Container.NextOrder()
    })
    List(Holder, Gap, true)

    local El

    for Index, Spec in ipairs(Config.Buttons) do
        local Button = New("TextButton", {
            Parent = Holder,
            Size = UDim2.new(1 / Count, -(Gap * (Count - 1)) / Count, 1, 0),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Index,
            BackgroundTransparency = 0
        })
        Corner(Button, 8)
        if Spec.Filled then
            Library:Themed(Button, { BackgroundColor3 = "Accent" })
            Button.BackgroundTransparency = 0
        else
            Fill(Button, "Overlay", "ButtonAlpha")
            Stroke(Button, "StrokeAlpha")
        end

        local Content = Frame(Button, { ZIndex = 2 })
        List(Content, 8, true, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
        local Token = Spec.Filled and "AccentText" or "Text"
        if Spec.Icon then
            Icon(Content, Spec.Icon, 15, Token, { LayoutOrder = 1 })
        end
        Label(Content, Spec.Title or "Button", 12.5, "Medium", Token, {
            LayoutOrder = 2,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.fromOffset(0, 0),
            TextWrapped = false
        })

        Button.MouseEnter:Connect(function()
            if not Spec.Filled then
                Tween(Button, FAST, { BackgroundTransparency = Library.Theme.ButtonHoverAlpha })
            else
                Tween(Button, FAST, { BackgroundTransparency = 0.12 })
            end
        end)
        Button.MouseLeave:Connect(function()
            Tween(Button, FAST, { BackgroundTransparency = Spec.Filled and 0 or Library.Theme.ButtonAlpha })
        end)
        Button.MouseButton1Click:Connect(function()
            if El.Locked then
                return
            end
            El.Changed:Fire(Spec.Title)
            Call(Spec.Callback)
        end)
    end

    El = Finish(Container, "MultiButton", Config, { Frame = Holder }, {})
    return El
end

function Components.Slider(Container, Config)
    Config = Merge({ Title = "Slider", Min = 0, Max = 100, Increment = 1, Suffix = "" }, Config)
    local Min = tonumber(Config.Min) or 0
    local Max = tonumber(Config.Max) or 100
    if Max <= Min then
        Max = Min + 1
    end
    local Step = tonumber(Config.Increment) or 1
    local Suffix = tostring(Config.Suffix or "")
    local W = Container.Window

    local R = MakeRow(Container, Config, {
        MinHeight = 68,
        PadBottom = 22,
        RightWidth = 72,
        RightHeight = 24,
        RightTop = 11
    })

    local Box = New("TextBox", {
        Parent = R.Right,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        FontFace = Library.Font.Medium,
        TextSize = 12,
        Text = "",
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Corner(Box, 6)
    Fill(Box, "Overlay", "InsetAlpha")
    Stroke(Box, "StrokeAlpha")
    Library:Themed(Box, { TextColor3 = "Text" })

    local Hit = New("TextButton", {
        Parent = R.Frame,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -9),
        Size = UDim2.new(1, -28, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3
    })
    local Bar = Frame(Hit, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 6)
    })
    Corner(Bar, UDim.new(1, 0))
    Fill(Bar, "Overlay", "TrackAlpha")
    local Level = Frame(Bar, { Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 0 })
    Corner(Level, UDim.new(1, 0))
    Library:Themed(Level, { BackgroundColor3 = "Accent" })
    local Knob = Frame(Bar, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 0,
        ZIndex = 2
    })
    Corner(Knob, UDim.new(1, 0))
    Library:Themed(Knob, { BackgroundColor3 = "Accent" })

    local Value = Min
    local Dragging = false
    local El

    local function Paint(Animate)
        local Alpha = (Value - Min) / (Max - Min)
        Apply(Level, Animate, { Size = UDim2.new(Alpha, 0, 1, 0) }, FAST)
        Apply(Knob, Animate, { Position = UDim2.new(Alpha, 0, 0.5, 0) }, FAST)
        Box.Text = Format(Value) .. Suffix
    end

    local function SetValue(New_, Silent, Animate, Gate)
        local Number = tonumber(New_) or Min
        Number = Clamp(Round(Number, Step), Min, Max)
        local Changed = Number ~= Value
        Value = Number
        Paint(Animate ~= false and not Silent)
        if Silent or not Gate or Changed then
            El:Emit(Value, Silent)
        end
    end

    Box.Focused:Connect(function()
        Box.Text = Format(Value)
    end)
    Box.FocusLost:Connect(function()
        local Parsed = tonumber(Box.Text:match("^%s*(-?%d*%.?%d+)"))
        if Parsed then
            SetValue(Parsed, false)
        else
            Paint(false)
        end
    end)

    Track(Hit, function()
        if El.Locked then
            return false
        end
        Dragging = true
        W.SetScrollLock(true)
        Tween(Knob, FAST, { Size = UDim2.fromOffset(17, 17) })
    end, function(Position)
        local Alpha = Clamp((Position.X - Hit.AbsolutePosition.X) / math.max(Hit.AbsoluteSize.X, 1), 0, 1)
        SetValue(Min + (Max - Min) * Alpha, false, false, true)
    end, function()
        Dragging = false
        W.SetScrollLock(false)
        Tween(Knob, FAST, { Size = UDim2.fromOffset(14, 14) })
    end)

    Hit.MouseEnter:Connect(function()
        if not Dragging then
            Tween(Knob, FAST, { Size = UDim2.fromOffset(16, 16) })
        end
    end)
    Hit.MouseLeave:Connect(function()
        if not Dragging then
            Tween(Knob, FAST, { Size = UDim2.fromOffset(14, 14) })
        end
    end)

    El = Finish(Container, "Slider", Config, R, {
        Set = function(New_, Silent)
            SetValue(New_, Silent, true, false)
        end
    })
    Boot(El, Config, tonumber(Config.Default) or Min)
    return El
end

function Components.RangeSlider(Container, Config)
    Config = Merge({ Title = "Range", Min = 0, Max = 100, Increment = 1, Suffix = "" }, Config)
    local Min = tonumber(Config.Min) or 0
    local Max = tonumber(Config.Max) or 100
    if Max <= Min then
        Max = Min + 1
    end
    local Step = tonumber(Config.Increment) or 1
    local Suffix = tostring(Config.Suffix or "")
    local W = Container.Window

    local R = MakeRow(Container, Config, {
        MinHeight = 68,
        PadBottom = 22,
        RightWidth = 96,
        RightHeight = 24,
        RightTop = 11
    })

    local Readout = New("TextLabel", {
        Parent = R.Right,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        FontFace = Library.Font.Medium,
        TextSize = 12,
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Right
    })
    Library:Themed(Readout, { TextColor3 = "TextDim" })

    local Hit = New("TextButton", {
        Parent = R.Frame,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -9),
        Size = UDim2.new(1, -28, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3
    })
    local Bar = Frame(Hit, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 6)
    })
    Corner(Bar, UDim.new(1, 0))
    Fill(Bar, "Overlay", "TrackAlpha")
    local Level = Frame(Bar, { Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 0 })
    Corner(Level, UDim.new(1, 0))
    Library:Themed(Level, { BackgroundColor3 = "Accent" })

    local function MakeKnob()
        local Knob = Frame(Bar, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 0,
            ZIndex = 2
        })
        Corner(Knob, UDim.new(1, 0))
        Library:Themed(Knob, { BackgroundColor3 = "Accent" })
        return Knob
    end
    local LowKnob = MakeKnob()
    local HighKnob = MakeKnob()

    local Low = Min
    local High = Max
    local Active
    local El

    local function Paint(Animate)
        local A = (Low - Min) / (Max - Min)
        local B = (High - Min) / (Max - Min)
        Apply(Level, Animate, { Position = UDim2.new(A, 0, 0, 0), Size = UDim2.new(B - A, 0, 1, 0) }, FAST)
        Apply(LowKnob, Animate, { Position = UDim2.new(A, 0, 0.5, 0) }, FAST)
        Apply(HighKnob, Animate, { Position = UDim2.new(B, 0, 0.5, 0) }, FAST)
        Readout.Text = Format(Low) .. Suffix .. "  -  " .. Format(High) .. Suffix
    end

    local function SetValue(NewLow, NewHigh, Silent, Animate, Gate)
        local A = Clamp(Round(tonumber(NewLow) or Min, Step), Min, Max)
        local B = Clamp(Round(tonumber(NewHigh) or Max, Step), Min, Max)
        if A > B then
            A, B = B, A
        end
        local Changed = A ~= Low or B ~= High
        Low, High = A, B
        Paint(Animate ~= false and not Silent)
        if Silent or not Gate or Changed then
            El:Emit({ Low, High }, Silent)
        end
    end

    local function AlphaAt(Position)
        return Clamp((Position.X - Hit.AbsolutePosition.X) / math.max(Hit.AbsoluteSize.X, 1), 0, 1)
    end

    Track(Hit, function(Input)
        if El.Locked then
            return false
        end
        local Alpha = AlphaAt(Input.Position)
        local Pressed = Min + (Max - Min) * Alpha
        local DistLow = math.abs(Pressed - Low)
        local DistHigh = math.abs(Pressed - High)
        if DistLow == DistHigh then
            Active = Pressed > Low and "High" or "Low"
        else
            Active = DistLow < DistHigh and "Low" or "High"
        end
        W.SetScrollLock(true)
        Tween(Active == "Low" and LowKnob or HighKnob, FAST, { Size = UDim2.fromOffset(17, 17) })
    end, function(Position)
        local Value = Min + (Max - Min) * AlphaAt(Position)
        if Active == "Low" then
            SetValue(math.min(Value, High), High, false, false, true)
        else
            SetValue(Low, math.max(Value, Low), false, false, true)
        end
    end, function()
        W.SetScrollLock(false)
        Tween(LowKnob, FAST, { Size = UDim2.fromOffset(14, 14) })
        Tween(HighKnob, FAST, { Size = UDim2.fromOffset(14, 14) })
        Active = nil
    end)

    El = Finish(Container, "RangeSlider", Config, R, {
        Set = function(Value, Silent)
            if type(Value) == "table" then
                SetValue(Value[1], Value[2], Silent, true, false)
            end
        end
    })
    El.Spread = true
    local Default = type(Config.Default) == "table" and Config.Default or { Min, Max }
    Boot(El, Config, { tonumber(Default[1]) or Min, tonumber(Default[2]) or Max })
    return El
end

function Components.Dropdown(Container, Config)
    Config = Merge({ Title = "Dropdown", Options = {}, Multi = false, Placeholder = "Select" }, Config)
    local W = Container.Window
    local Multi = Config.Multi == true
    local Options = table.clone(Config.Options)

    local R = MakeRow(Container, Config, { Clickable = true, RightWidth = 142, RightHeight = 30 })

    local Select = Frame(R.Right, { Size = UDim2.fromScale(1, 1) })
    Corner(Select, 7)
    Fill(Select, "Overlay", "ButtonAlpha")
    Stroke(Select, "StrokeAlpha")
    local ValueLabel = Label(Select, "", 12, "Medium", "Text", {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -34, 1, 0),
        AutomaticSize = Enum.AutomaticSize.None,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Icon(Select, "chevron-down", 14, "TextDim", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0)
    })

    local Current
    local Chosen = {}
    local Live
    local El

    local function IsSelected(Name)
        if Multi then
            return Chosen[Name] == true
        end
        return Current == Name
    end

    local function ListChosen()
        local Result = {}
        for _, Name in ipairs(Options) do
            if Chosen[Name] then
                table.insert(Result, Name)
            end
        end
        return Result
    end

    local function Display()
        if Multi then
            local Picked = ListChosen()
            if #Picked == 0 then
                return Config.Placeholder, true
            elseif #Picked <= 2 then
                return table.concat(Picked, ", "), false
            end
            return Picked[1] .. ", " .. Picked[2] .. " +" .. (#Picked - 2), false
        end
        if Current == nil then
            return Config.Placeholder, true
        end
        return tostring(Current), false
    end

    local function Paint()
        local Text, Empty = Display()
        ValueLabel.Text = Text
        ValueLabel.TextTransparency = Empty and 0.4 or 0
        if Live then
            Live.Refresh()
        end
    end

    local function SetValue(Value, Silent)
        if Multi then
            table.clear(Chosen)
            if type(Value) == "table" then
                for Key, Item in pairs(Value) do
                    if type(Key) == "number" then
                        Chosen[Item] = true
                    elseif Item == true then
                        Chosen[Key] = true
                    end
                end
            end
            Paint()
            El:Emit(ListChosen(), Silent)
        else
            Current = Value
            Paint()
            El:Emit(Current, Silent)
        end
    end

    local function Open()
        if El.Locked then
            return
        end
        local Count = #Options
        local Searchable = Config.Searchable == true or (Config.Searchable == nil and Count > 7)
        local RowsHeight = math.max(math.min(Count * 30, 196), 30)
        local Height = RowsHeight + 10 + (Searchable and 34 or 0)

        local Popup = W.OpenPopup(Select, {
            Width = math.max(Select.AbsoluteSize.X, 170),
            Height = Height
        }, function(Panel, Close)
            Padding(Panel, 5, 5, 5, 5)
            local Query = ""

            if Searchable then
                local Box = New("TextBox", {
                    Parent = Panel,
                    Size = UDim2.new(1, 0, 0, 28),
                    BorderSizePixel = 0,
                    FontFace = Library.Font.Regular,
                    TextSize = 12,
                    Text = "",
                    PlaceholderText = "Search...",
                    ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                Corner(Box, 6)
                Fill(Box, "Overlay", "InsetAlpha")
                Stroke(Box, "StrokeAlpha")
                Padding(Box, 0, 0, 10, 10)
                Library:Themed(Box, { TextColor3 = "Text", PlaceholderColor3 = "TextFaint" })
                Box:GetPropertyChangedSignal("Text"):Connect(function()
                    Query = Box.Text:lower()
                    Live.Refresh()
                end)
            end

            local Scroll = New("ScrollingFrame", {
                Parent = Panel,
                Position = UDim2.fromOffset(0, Searchable and 34 or 0),
                Size = UDim2.new(1, 0, 0, RowsHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageTransparency = 0.6,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y
            })
            Library:Themed(Scroll, { ScrollBarImageColor3 = "Overlay" })
            List(Scroll, 0)

            local Items = {}

            local function Rebuild()
                for _, Item in ipairs(Items) do
                    Item:Destroy()
                end
                table.clear(Items)
                local Shown = 0
                for Index, Name in ipairs(Options) do
                    if Query == "" or tostring(Name):lower():find(Query, 1, true) then
                        Shown = Shown + 1
                        local Selected = IsSelected(Name)
                        local Item = New("TextButton", {
                            Parent = Scroll,
                            Size = UDim2.new(1, 0, 0, 30),
                            BorderSizePixel = 0,
                            Text = "",
                            AutoButtonColor = false,
                            LayoutOrder = Index,
                            BackgroundTransparency = Selected and Library.Theme.ActiveAlpha or 1
                        })
                        Library:Themed(Item, { BackgroundColor3 = "Overlay" })
                        Corner(Item, 6)
                        Label(Item, tostring(Name), 12.5, Selected and "Medium" or "Regular", "Text", {
                            Position = UDim2.fromOffset(10, 0),
                            Size = UDim2.new(1, -36, 1, 0),
                            AutomaticSize = Enum.AutomaticSize.None,
                            TextWrapped = false,
                            TextTruncate = Enum.TextTruncate.AtEnd
                        })
                        if Selected then
                            Icon(Item, "check", 14, "Text", {
                                AnchorPoint = Vector2.new(1, 0.5),
                                Position = UDim2.new(1, -9, 0.5, 0)
                            })
                        end
                        Item.MouseEnter:Connect(function()
                            if not IsSelected(Name) then
                                Tween(Item, FAST, { BackgroundTransparency = Library.Theme.ButtonAlpha })
                            end
                        end)
                        Item.MouseLeave:Connect(function()
                            if not IsSelected(Name) then
                                Tween(Item, FAST, { BackgroundTransparency = 1 })
                            end
                        end)
                        Item.MouseButton1Click:Connect(function()
                            if Multi then
                                Chosen[Name] = not Chosen[Name] or nil
                                Paint()
                                El:Emit(ListChosen(), false)
                            else
                                SetValue(Name, false)
                                Close()
                            end
                        end)
                        table.insert(Items, Item)
                    end
                end
                if Shown == 0 then
                    local Empty = Label(Scroll, "No results", 12, "Regular", "TextFaint", {
                        Size = UDim2.new(1, 0, 0, 30),
                        AutomaticSize = Enum.AutomaticSize.None,
                        TextXAlignment = Enum.TextXAlignment.Center
                    })
                    table.insert(Items, Empty)
                end
            end

            Live = { Refresh = Rebuild }
            Rebuild()
        end)
        Popup.OnClose = function()
            Live = nil
        end
    end

    R.Hit.MouseButton1Click:Connect(Open)

    El = Finish(Container, "Dropdown", Config, R, { Set = SetValue })
    function El:SetOptions(NewOptions)
        Options = table.clone(NewOptions or {})
        if Multi then
            for Name in pairs(Chosen) do
                if not table.find(Options, Name) then
                    Chosen[Name] = nil
                end
            end
        elseif Current ~= nil and not table.find(Options, Current) then
            Current = nil
        end
        Paint()
        El:Emit(Multi and ListChosen() or Current, true)
    end
    function El:GetOptions()
        return table.clone(Options)
    end

    local Default = Config.Default
    if Multi then
        Boot(El, Config, type(Default) == "table" and Default or {})
    else
        Boot(El, Config, Default)
    end
    return El
end

function Components.Input(Container, Config)
    Config = Merge({ Title = "Input", Default = "", Placeholder = "", Numeric = false }, Config)
    local R = MakeRow(Container, Config, { RightWidth = 164, RightHeight = 30 })

    local Box = New("TextBox", {
        Parent = R.Right,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        FontFace = Library.Font.Regular,
        TextSize = 12,
        Text = "",
        PlaceholderText = Config.Placeholder,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Corner(Box, 7)
    Fill(Box, "Overlay", "InsetAlpha")
    local Line = Stroke(Box, "StrokeAlpha")
    Padding(Box, 0, 0, 10, 10)
    Library:Themed(Box, { TextColor3 = "Text", PlaceholderColor3 = "TextFaint" })

    local El
    local Last = ""

    local function SetValue(Value, Silent)
        Last = tostring(Value == nil and "" or Value)
        Box.Text = Last
        El:Emit(Last, Silent)
    end

    Box.Focused:Connect(function()
        Tween(Line, FAST, { Transparency = 0.5 })
    end)

    Box.FocusLost:Connect(function()
        Tween(Line, FAST, { Transparency = Library.Theme.StrokeAlpha })
        if El.Locked then
            Box.Text = Last
            return
        end
        SetValue(Box.Text, false)
    end)

    if Config.Numeric then
        Box:GetPropertyChangedSignal("Text"):Connect(function()
            local Clean = Box.Text:gsub("[^%d%.%-]", "")
            if Clean ~= Box.Text then
                Box.Text = Clean
            end
        end)
    end

    El = Finish(Container, "Input", Config, R, { Set = SetValue })
    Boot(El, Config, Config.Default)
    return El
end

local KeyShort = {
    LeftShift = "LShift",
    RightShift = "RShift",
    LeftControl = "LCtrl",
    RightControl = "RCtrl",
    LeftAlt = "LAlt",
    RightAlt = "RAlt",
    Return = "Enter",
    Backspace = "Bksp",
    Escape = "Esc",
    MouseButton2 = "MB2",
    MouseButton3 = "MB3"
}

local function KeyName(Key)
    if not Key then
        return "None"
    end
    return KeyShort[Key.Name] or Key.Name
end

local function ResolveKey(Value)
    if typeof(Value) == "EnumItem" then
        return Value
    end
    if type(Value) == "string" and Value ~= "" and Value ~= "None" then
        local Ok, Found = pcall(function()
            return Enum.KeyCode[Value]
        end)
        if Ok then
            return Found
        end
    end
    return nil
end

function Components.Keybind(Container, Config)
    Config = Merge({ Title = "Keybind", Mode = "Press" }, Config)
    local W = Container.Window
    local R = MakeRow(Container, Config, { Clickable = true, RightWidth = 78, RightHeight = 28 })

    local Pill = New("TextButton", {
        Parent = R.Right,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        FontFace = Library.Font.Medium,
        TextSize = 12,
        Text = "None",
        AutoButtonColor = false,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Corner(Pill, 7)
    Fill(Pill, "Overlay", "ButtonAlpha")
    Stroke(Pill, "StrokeAlpha")
    Library:Themed(Pill, { TextColor3 = "Text" })

    local Key
    local Listening = false
    local El

    local function Paint()
        Pill.Text = Listening and "..." or KeyName(Key)
    end

    local function SetKey(Value, Silent)
        Key = ResolveKey(Value)
        Listening = false
        Paint()
        El.Value = Key
        if El.Flag then
            Library.Flags[El.Flag] = Key
        end
        if not Silent then
            El.Changed:Fire(Key)
            if El.Flag then
                W.QueueSave()
            end
        end
    end

    local function Matches(Input)
        if not Key then
            return false
        end
        if Key.EnumType == Enum.KeyCode then
            return Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Key
        end
        return Input.UserInputType == Key
    end

    local function BeginListen()
        if El.Locked or Listening then
            return
        end
        Listening = true
        Paint()
        W.Listening = function(Input)
            local Type = Input.UserInputType
            if Type == Enum.UserInputType.Keyboard then
                if Input.KeyCode == Enum.KeyCode.Escape then
                    Listening = false
                    Paint()
                elseif Input.KeyCode == Enum.KeyCode.Backspace or Input.KeyCode == Enum.KeyCode.Delete then
                    SetKey(nil, false)
                else
                    SetKey(Input.KeyCode, false)
                end
            elseif Type == Enum.UserInputType.MouseButton2 or Type == Enum.UserInputType.MouseButton3 then
                SetKey(Type, false)
            elseif Type == Enum.UserInputType.MouseButton1 then
                Listening = false
                Paint()
            else
                return false
            end
            W.Listening = nil
            return true
        end
    end

    R.Hit.MouseButton1Click:Connect(BeginListen)
    Pill.MouseButton1Click:Connect(BeginListen)

    local FinishConfig = Merge(Config, {})
    FinishConfig.Callback = nil
    El = Finish(Container, "Keybind", FinishConfig, R, { Set = SetKey })
    El.Active = false

    El.Press = function(Input, Down)
        if El.Dead or El.Locked or not Matches(Input) then
            return
        end
        local Mode = tostring(Config.Mode)
        if Mode == "Hold" then
            El.Active = Down
            Call(Config.Callback, Down)
        elseif Down then
            if Mode == "Toggle" then
                El.Active = not El.Active
                Call(Config.Callback, El.Active)
            else
                Call(Config.Callback, true)
            end
        end
    end

    function El:GetState()
        return El.Active
    end

    table.insert(W.Keybinds, El)
    Boot(El, Config, Config.Default)
    return El
end

function Components.Colorpicker(Container, Config)
    Config = Merge({ Title = "Color", Default = Color3.fromRGB(255, 255, 255) }, Config)
    local W = Container.Window
    local R = MakeRow(Container, Config, { Clickable = true, RightWidth = 38, RightHeight = 22 })

    local Swatch = Frame(R.Right, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0 })
    Corner(Swatch, 6)
    Stroke(Swatch, "StrokeStrongAlpha")

    local Hue, Sat, Val = 0, 0, 1
    local Live
    local El

    local function Current()
        return Color3.fromHSV(Hue, Sat, Val)
    end

    local function SetHSV(H, S, V, Silent)
        Hue, Sat, Val = H, S, V
        local Color = Current()
        Swatch.BackgroundColor3 = Color
        if Live then
            Live.Refresh()
        end
        El:Emit(Color, Silent)
    end

    local function SetValue(Value, Silent)
        if typeof(Value) == "Color3" then
            local H, S, V = Value:ToHSV()
            SetHSV(H, S, V, Silent)
        end
    end

    local function Open()
        if El.Locked then
            return
        end
        local PanelWidth = 232
        local Popup = W.OpenPopup(Swatch, { Width = PanelWidth, Height = 218 }, function(Panel, Close)
            local Inner = PanelWidth - 20

            local SV = New("TextButton", {
                Parent = Panel,
                Position = UDim2.fromOffset(10, 10),
                Size = UDim2.fromOffset(Inner, 120),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ClipsDescendants = true,
                BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
            })
            Corner(SV, 6)
            local White = Frame(SV, { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 1 })
            New("UIGradient", {
                Parent = White,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                })
            })
            local Shade = Frame(SV, { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0, ZIndex = 2 })
            New("UIGradient", {
                Parent = Shade,
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                })
            })
            local Cursor = Frame(SV, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(12, 12),
                BackgroundTransparency = 1,
                ZIndex = 3
            })
            Corner(Cursor, UDim.new(1, 0))
            New("UIStroke", { Parent = Cursor, Thickness = 2, Color = Color3.new(1, 1, 1) })

            local HueBar = New("TextButton", {
                Parent = Panel,
                Position = UDim2.fromOffset(10, 140),
                Size = UDim2.fromOffset(Inner, 12),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                BackgroundColor3 = Color3.new(1, 1, 1)
            })
            Corner(HueBar, UDim.new(1, 0))
            New("UIGradient", {
                Parent = HueBar,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                })
            })
            local HueCursor = Frame(HueBar, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(6, 16),
                BackgroundTransparency = 0,
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = 2
            })
            Corner(HueCursor, 3)
            New("UIStroke", { Parent = HueCursor, Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.6 })

            local Hex = New("TextBox", {
                Parent = Panel,
                Position = UDim2.fromOffset(10, 172),
                Size = UDim2.fromOffset(Inner - 36, 30),
                BorderSizePixel = 0,
                FontFace = Library.Font.Mono,
                TextSize = 12,
                Text = "",
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                PlaceholderText = "#FFFFFF"
            })
            Corner(Hex, 7)
            Fill(Hex, "Overlay", "InsetAlpha")
            Stroke(Hex, "StrokeAlpha")
            Padding(Hex, 0, 0, 10, 10)
            Library:Themed(Hex, { TextColor3 = "Text", PlaceholderColor3 = "TextFaint" })

            local Preview = Frame(Panel, {
                Position = UDim2.fromOffset(Inner - 22, 172),
                Size = UDim2.fromOffset(32, 30),
                BackgroundTransparency = 0
            })
            Corner(Preview, 7)
            Stroke(Preview, "StrokeStrongAlpha")

            local function Refresh()
                local Color = Current()
                SV.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
                Cursor.Position = UDim2.fromScale(Sat, 1 - Val)
                HueCursor.Position = UDim2.new(Hue, 0, 0.5, 0)
                Preview.BackgroundColor3 = Color
                if not Hex:IsFocused() then
                    Hex.Text = "#" .. Color:ToHex():upper()
                end
            end
            Live = { Refresh = Refresh }
            Refresh()

            Track(SV, function()
                W.SetScrollLock(true)
            end, function(Position)
                local S = Clamp((Position.X - SV.AbsolutePosition.X) / math.max(SV.AbsoluteSize.X, 1), 0, 1)
                local V = 1 - Clamp((Position.Y - SV.AbsolutePosition.Y) / math.max(SV.AbsoluteSize.Y, 1), 0, 1)
                SetHSV(Hue, S, V, false)
            end, function()
                W.SetScrollLock(false)
            end)

            Track(HueBar, function()
                W.SetScrollLock(true)
            end, function(Position)
                local H = Clamp((Position.X - HueBar.AbsolutePosition.X) / math.max(HueBar.AbsoluteSize.X, 1), 0, 0.999)
                SetHSV(H, Sat, Val, false)
            end, function()
                W.SetScrollLock(false)
            end)

            Hex.FocusLost:Connect(function()
                local Text = Hex.Text:gsub("#", "")
                if #Text == 6 and Text:match("^%x+$") then
                    local Color = Color3.fromRGB(
                        tonumber(Text:sub(1, 2), 16),
                        tonumber(Text:sub(3, 4), 16),
                        tonumber(Text:sub(5, 6), 16)
                    )
                    SetValue(Color, false)
                end
                Refresh()
            end)
        end)
        Popup.OnClose = function()
            Live = nil
        end
    end

    R.Hit.MouseButton1Click:Connect(Open)

    El = Finish(Container, "Colorpicker", Config, R, { Set = SetValue })
    Boot(El, Config, Config.Default)
    return El
end

local Kinds = {
    "Toggle", "Button", "MultiButton", "Slider", "RangeSlider", "Dropdown",
    "Input", "Keybind", "Colorpicker", "Paragraph", "Label", "Progress", "Card", "Separator"
}

local function NewContainer(Props)
    local Order = 0
    Props.Elements = {}
    Props.NextOrder = function()
        Order = Order + 1
        return Order
    end
    return Props
end

function Components.Paragraph(Container, Config)
    Config = Merge({ Title = "Paragraph" }, Config)
    local R = MakeRow(Container, Config, { MinHeight = 48 })
    R.TitleLabel.FontFace = Library.Font.SemiBold
    local El
    El = Finish(Container, "Paragraph", Config, R, {
        Set = function(Value)
            El:SetDescription(tostring(Value or ""))
        end
    })
    return El
end

function Components.Label(Container, Config)
    Config = Merge({ Title = Config and Config.Text or "Label" }, Config)
    local R = MakeRow(Container, Config, { MinHeight = 36 })
    R.TitleLabel.TextColor3 = Library.Theme.TextDim
    Library:Themed(R.TitleLabel, { TextColor3 = "TextDim" })
    local El
    El = Finish(Container, "Label", Config, R, {
        Set = function(Value)
            El:SetTitle(tostring(Value or ""))
        end
    })
    return El
end

function Components.Progress(Container, Config)
    Config = Merge({ Title = "Progress", Default = 0, Suffix = "%" }, Config)
    local R = MakeRow(Container, Config, {
        MinHeight = 62,
        PadBottom = 14,
        RightWidth = 56,
        RightHeight = 20,
        RightTop = 10
    })

    local Percent = New("TextLabel", {
        Parent = R.Right,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        FontFace = Library.Font.Medium,
        TextSize = 12,
        Text = "0",
        TextXAlignment = Enum.TextXAlignment.Right
    })
    Library:Themed(Percent, { TextColor3 = "TextDim" })

    local Bar = Frame(R.Frame, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -14),
        Size = UDim2.new(1, -28, 0, 6),
        ZIndex = 3
    })
    Corner(Bar, UDim.new(1, 0))
    Fill(Bar, "Overlay", "TrackAlpha")
    local Level = Frame(Bar, { Size = UDim2.fromScale(0, 1), BackgroundTransparency = 0 })
    Corner(Level, UDim.new(1, 0))
    Library:Themed(Level, { BackgroundColor3 = "Accent" })

    local El
    local function SetValue(Value, Silent)
        local Alpha = Clamp(tonumber(Value) or 0, 0, 1)
        Percent.Text = math.floor(Alpha * 100 + 0.5) .. tostring(Config.Suffix or "")
        if Silent then
            Level.Size = UDim2.fromScale(Alpha, 1)
        else
            Tween(Level, NORMAL, { Size = UDim2.fromScale(Alpha, 1) })
        end
        El:Emit(Alpha, Silent)
    end

    El = Finish(Container, "Progress", Config, R, { Set = SetValue })
    SetValue(Config.Default, true)
    return El
end

function Components.Separator(Container, Config)
    Config = Merge({ Title = "" }, Config)
    local HasTitle = (Config.Title or "") ~= ""
    local Holder = Frame(Container.Holder, {
        Size = UDim2.new(1, 0, 0, HasTitle and 28 or 10),
        LayoutOrder = Container.NextOrder()
    })
    local Line = Frame(Holder, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, HasTitle and -2 or -4),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0
    })
    Fill(Line, "Overlay", "StrokeAlpha")
    local TitleLabel
    if HasTitle then
        TitleLabel = Label(Holder, Config.Title, 11, "SemiBold", "TextFaint", {
            Position = UDim2.fromOffset(4, 0),
            Size = UDim2.new(1, -4, 0, 20),
            AutomaticSize = Enum.AutomaticSize.None,
            TextWrapped = false
        })
    end
    return Finish(Container, "Separator", Config, { Frame = Holder, TitleLabel = TitleLabel }, {})
end

function Components.Card(Container, Config)
    Config = Merge({ Title = "Card", Collapsible = false, Open = true }, Config)
    local W = Container.Window

    local Outer = Frame(Container.Holder, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = Container.NextOrder()
    })
    Corner(Outer, 8)
    Fill(Outer, "Overlay", "RowAlpha")
    Stroke(Outer, "StrokeAlpha")
    List(Outer, 0)

    local HeadHost = NewContainer({ Holder = Outer, Flat = true, Window = W })
    local R = MakeRow(HeadHost, Config, {
        Clickable = Config.Collapsible,
        MinHeight = 52,
        RightWidth = Config.Collapsible and 18 or 0,
        RightHeight = 18
    })
    R.Frame.LayoutOrder = 1

    local Chevron
    if Config.Collapsible then
        Chevron = Icon(R.Right, "chevron-down", 16, "TextDim", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5)
        })
    end

    local Body = Frame(Outer, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Visible = Config.Open ~= false
    })
    Padding(Body, 0, 10, 10, 10)
    List(Body, 8)
    local Divider = Frame(Body, {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0,
        LayoutOrder = 0
    })
    Fill(Divider, "Overlay", "StrokeAlpha")
    local Holder = Frame(Body, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1
    })
    List(Holder, 2)

    local Inner = NewContainer({
        Window = W,
        Tab = Container.Tab,
        Subtab = Container.Subtab,
        Scroll = Container.Scroll,
        Holder = Holder,
        Flat = true
    })

    if Config.Collapsible then
        local Opened = Config.Open ~= false
        Tween(Chevron, FAST, { Rotation = Opened and 0 or -90 })
        R.Hit.MouseButton1Click:Connect(function()
            Opened = not Opened
            Body.Visible = Opened
            Tween(Chevron, NORMAL, { Rotation = Opened and 0 or -90 })
        end)
    end

    local El = Finish(Container, "Card", Config, {
        Frame = Outer,
        TitleLabel = R.TitleLabel,
        DescLabel = R.DescLabel
    }, {})
    El.Container = Inner
    El.Items = Inner.Elements

    for _, Kind in ipairs(Kinds) do
        El["Add" .. Kind] = function(_, Item)
            return Components[Kind](Inner, Item or {})
        end
        El[Kind] = El["Add" .. Kind]
    end

    if type(Config.Items) == "table" then
        for _, Item in ipairs(Config.Items) do
            local Kind = Item.Type or Item.Kind
            if Components[Kind] then
                Components[Kind](Inner, Item)
            else
                warn("[sh1ttybanana] unknown card item type: " .. tostring(Kind))
            end
        end
    end
    return El
end

local function BuildSection(Parent, Config)
    if type(Config) == "string" then
        Config = { Title = Config }
    end
    Config = Merge({ Title = "Section" }, Config)
    local W = Parent.Window

    local Group = Frame(Parent.Holder, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = Parent.NextOrder()
    })
    List(Group, 8)

    local Head = Frame(Group, { Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 0 })
    Padding(Head, 0, 0, 4, 0)
    List(Head, 8, true, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    if Config.Icon then
        Icon(Head, Config.Icon, 14, "TextFaint", { LayoutOrder = 1 })
    end
    local Title = Label(Head, string.upper(tostring(Config.Title)), 11, "SemiBold", "TextFaint", {
        LayoutOrder = 2,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 16),
        TextWrapped = false
    })

    local Holder = Frame(Group, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1
    })
    List(Holder, 8)

    local Section = NewContainer({
        Window = W,
        Tab = Parent.Tab,
        Subtab = Parent.Subtab,
        Scroll = Parent.Scroll,
        Holder = Holder,
        Frame = Group,
        TitleLabel = Title
    })

    for _, Kind in ipairs(Kinds) do
        Section["Add" .. Kind] = function(self, Item)
            return Components[Kind](self, Item or {})
        end
        Section[Kind] = Section["Add" .. Kind]
    end

    function Section:SetTitle(Text)
        Title.Text = string.upper(tostring(Text))
        return self
    end

    function Section:SetVisible(State)
        Group.Visible = State ~= false
        return self
    end

    function Section:Destroy()
        for _, El in ipairs(self.Elements) do
            El.Dead = true
            if El.Search then
                El.Search.Dead = true
            end
            if El.Flag and Library.Options[El.Flag] == El then
                Library.Options[El.Flag] = nil
                W.Flags[El.Flag] = nil
            end
        end
        Group:Destroy()
    end

    return Section
end

local TOPBAR = 56
local SIDEBAR = 190
local SIDEBAR_COMPACT = 62
local USERCARD = 64

local NotifyTypes = {
    Info = { Icon = "info", Token = "Info" },
    Success = { Icon = "circle-check|check-circle|check", Token = "Success" },
    Warn = { Icon = "triangle-alert|alert-triangle|info", Token = "Warn" },
    Error = { Icon = "circle-x|x-circle|x", Token = "Error" },
    Danger = { Icon = "triangle-alert|alert-triangle|info", Token = "Error" },
    Question = { Icon = "circle-help|help-circle|info", Token = "Info" }
}

local function ParentGui(Gui)
    local Ok = false
    if type(gethui) == "function" then
        Ok = pcall(function()
            Gui.Parent = gethui()
        end)
    end
    if Ok and Gui.Parent then
        return
    end
    Ok = pcall(function()
        Gui.Parent = game:GetService("CoreGui")
    end)
    if Ok and Gui.Parent then
        return
    end
    Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function ViewportSize()
    local Camera = workspace.CurrentCamera
    return Camera and Camera.ViewportSize or Vector2.new(1280, 720)
end

local function MakeScroll(Parent, Props)
    local Data = {
        Parent = Parent,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 0.7,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        VerticalScrollBarInset = Enum.ScrollBarInset.None
    }
    for Key, Value in pairs(Props or {}) do
        Data[Key] = Value
    end
    local Scroll = New("ScrollingFrame", Data)
    Library:Themed(Scroll, { ScrollBarImageColor3 = "Overlay" })
    return Scroll
end

local function Expose(Class, GetContainer)
    for _, Kind in ipairs(Kinds) do
        Class["Add" .. Kind] = function(self, Config)
            return Components[Kind](GetContainer(self), Config or {})
        end
        Class[Kind] = Class["Add" .. Kind]
    end
    Class.AddSection = function(self, Config)
        return BuildSection(GetContainer(self), Config)
    end
    Class.Section = Class.AddSection
end

local function Sanitize(Name)
    return (tostring(Name or ""):gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function Library:NewWindow(UserConfig)
    local W = {}
    W.Config = Merge({
        Title = "sh1ttybanana",
        Description = "v" .. Library.Version,
        Icon = "sparkles",
        Theme = "Dark",
        Size = UDim2.fromOffset(720, 520),
        Transparency = nil,
        Blur = false,
        FolderName = "sh1ttybanana",
        ConfigName = "default",
        AutoSave = true,
        AutoLoad = true,
        ToggleKey = Enum.KeyCode.RightShift,
        TopbarButtons = nil,
        Background = nil,
        Search = true,
        ShowUser = true,
        ConfirmClose = true,
        NotifyMax = 4
    }, UserConfig or {})

    W.Tabs = {}
    W.Groups = {}
    W.GroupMap = {}
    W.Flags = {}
    W.Keybinds = {}
    W.Notifs = {}
    W.Connections = {}
    W.Scrolls = {}
    W.SearchList = {}
    W.Pending = {}
    W.Open = true
    W.Maximized = false
    W.Minimized = false
    W.Compact = false
    W.Destroyed = false
    W.ScrollLocks = 0
    W.Width = 0
    W.Height = 0
    W.NotifyCounter = 0

    if Library.Themes[W.Config.Theme] then
        Library.CurrentTheme = W.Config.Theme
        Library.Theme = Library.Themes[W.Config.Theme]
    end

    W.Paths = {
        Folder = "sh1ttybanana/" .. tostring(W.Config.FolderName),
        Configs = "sh1ttybanana/" .. tostring(W.Config.FolderName) .. "/configs"
    }
    W.Paths.State = W.Paths.Folder .. "/state.json"
    FS.Folder(W.Paths.Configs)
    W.State = FS.ReadJSON(W.Paths.State) or {}
    W.Profile = Sanitize(W.State.Profile or W.Config.ConfigName)
    if W.Profile == "" then
        W.Profile = "default"
    end
    if W.State.Theme and Library.Themes[W.State.Theme] then
        Library.CurrentTheme = W.State.Theme
        Library.Theme = Library.Themes[W.State.Theme]
    end

    function W.SaveState()
        W.State.Profile = W.Profile
        W.State.Theme = Library.CurrentTheme
        FS.WriteJSON(W.Paths.State, W.State)
    end

    function W.ConfigPath(Name)
        return W.Paths.Configs .. "/" .. Sanitize(Name) .. ".json"
    end

    function W.Collect()
        local Data = {}
        for Flag, El in pairs(W.Flags) do
            local Ok, Value = pcall(El.Get, El)
            if Ok and Value ~= nil then
                Data[Flag] = Encode(Value)
            end
        end
        return Data
    end

    function W.WriteConfig(Name)
        Name = Sanitize(Name)
        if Name == "" then
            return false
        end
        local Ok = FS.WriteJSON(W.ConfigPath(Name), { Version = Library.Version, Flags = W.Collect() })
        if Ok and type(W.Config.OnSave) == "function" then
            Call(W.Config.OnSave, Name)
        end
        return Ok
    end

    function W.ReadConfig(Name)
        Name = Sanitize(Name)
        local Data = FS.ReadJSON(W.ConfigPath(Name))
        if type(Data) ~= "table" then
            return false
        end
        local Flags = type(Data.Flags) == "table" and Data.Flags or Data
        for Flag, Value in pairs(Flags) do
            local El = W.Flags[Flag]
            if El then
                pcall(El.Set, El, Decode(Value), false)
            else
                W.Pending[Flag] = Value
            end
        end
        if type(W.Config.OnLoad) == "function" then
            Call(W.Config.OnLoad, Name)
        end
        return true
    end

    local SavePending = false
    function W.QueueSave()
        if not W.Config.AutoSave or SavePending then
            return
        end
        SavePending = true
        task.delay(1.5, function()
            SavePending = false
            if not W.Destroyed then
                W.WriteConfig(W.Profile)
            end
        end)
    end

    if W.Config.AutoLoad then
        local Data = FS.ReadJSON(W.ConfigPath(W.Profile))
        if type(Data) == "table" then
            W.Pending = type(Data.Flags) == "table" and Data.Flags or Data
        end
    end

    function W.SetScrollLock(State)
        W.ScrollLocks = math.max(W.ScrollLocks + (State and 1 or -1), 0)
        local Enabled = W.ScrollLocks == 0
        for _, Scroll in ipairs(W.Scrolls) do
            if Scroll.Parent then
                Scroll.ScrollingEnabled = Enabled
            end
        end
    end

    local Gui = New("ScreenGui", {
        Name = HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000
    })
    ParentGui(Gui)
    W.Gui = Gui

    local Root = Frame(Gui, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(720, 520),
        ZIndex = 1
    })
    W.Root = Root

    local Main = Frame(Root, { BackgroundTransparency = 0, ClipsDescendants = true, ZIndex = 1 })
    Corner(Main, 14)
    Stroke(Main, "StrokeStrongAlpha")
    W.Main = Main
    Library:Bind(Main, function()
        Main.BackgroundColor3 = Library.Theme.Window
        Main.BackgroundTransparency = W.AlphaOverride or Library.Theme.WindowAlpha
    end)

    local PopupLayer = Frame(Gui, { ZIndex = 200 })
    local ModalLayer = Frame(Gui, { ZIndex = 300 })
    local NotifyLayer = Frame(Gui, {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 320, 1, -32),
        ZIndex = 400
    })
    List(NotifyLayer, 8, false, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

    local Backdrop
    local BackdropDim

    function W.SetBackground(Spec)
        if Backdrop then
            Backdrop:Destroy()
            Backdrop = nil
            BackdropDim = nil
        end
        if type(Spec) == "string" then
            Spec = { Image = Spec }
        end
        if type(Spec) ~= "table" or not Spec.Image or Spec.Image == "" then
            return false
        end
        local Image = tostring(Spec.Image)
        if Image:match("^%d+$") then
            Image = "rbxassetid://" .. Image
        end
        Backdrop = New("ImageLabel", {
            Parent = Main,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = Image,
            ImageTransparency = Spec.Transparency or 0.55,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 1
        })
        Corner(Backdrop, 14)
        BackdropDim = Frame(Backdrop, {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1 - (Spec.Dim or 0.45),
            ZIndex = 1
        })
        Corner(BackdropDim, 14)
        return true
    end

    local Topbar = Frame(Main, { Size = UDim2.new(1, 0, 0, TOPBAR), ZIndex = 20 })
    local TopLine = Frame(Main, {
        Position = UDim2.fromOffset(0, TOPBAR),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0,
        ZIndex = 20
    })
    Fill(TopLine, "Overlay", "StrokeAlpha")

    local Controls = Frame(Topbar, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(0, 30),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 3
    })
    List(Controls, 4, true, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

    local ControlCount = 3
    local function Glyph(IconName, Order, Danger)
        local Button = New("TextButton", {
            Parent = Controls,
            Size = UDim2.fromOffset(30, 30),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = Order
        })
        Corner(Button, 8)
        Library:Themed(Button, { BackgroundColor3 = Danger and "Error" or "Overlay" })
        local Mark = Icon(Button, IconName, 16, "TextDim", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5)
        })
        Button.MouseEnter:Connect(function()
            Tween(Button, FAST, { BackgroundTransparency = Danger and 0.8 or Library.Theme.ButtonHoverAlpha })
            Tween(Mark, FAST, { ImageColor3 = Danger and Library.Theme.Error or Library.Theme.Text })
        end)
        Button.MouseLeave:Connect(function()
            Tween(Button, FAST, { BackgroundTransparency = 1 })
            Tween(Mark, FAST, { ImageColor3 = Library.Theme.TextDim })
        end)
        return Button, Mark
    end

    local Custom = type(W.Config.TopbarButtons) == "table" and W.Config.TopbarButtons or {}
    for Index, Spec in ipairs(Custom) do
        local Button = Glyph(Spec.Icon or "settings", Index, false)
        Button.MouseButton1Click:Connect(function()
            Call(Spec.Callback)
        end)
        ControlCount = ControlCount + 1
    end

    local SearchButton
    if W.Config.Search ~= false then
        SearchButton = Glyph("search", 100, false)
        ControlCount = ControlCount + 1
    end
    local MinButton = Glyph("minus", 101, false)
    local MaxButton, MaxMark = Glyph("maximize-2|maximize", 102, false)
    local CloseButton = Glyph("x", 103, true)

    local ControlsWidth = ControlCount * 30 + (ControlCount - 1) * 4

    local DragArea = New("TextButton", {
        Parent = Topbar,
        Size = UDim2.new(1, -(ControlsWidth + 20), 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 1
    })

    local Logo = Icon(Topbar, W.Config.Icon, 22, "Text", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 18, 0.5, 0),
        ZIndex = 2
    })

    local TitleLabel = Label(Topbar, tostring(W.Config.Title), 14, "SemiBold", "Text", {
        Position = UDim2.fromOffset(52, 11),
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        TextWrapped = false,
        ZIndex = 2
    })
    local SubLabel = Label(Topbar, tostring(W.Config.Description), 11, "Regular", "TextDim", {
        Position = UDim2.fromOffset(52, 29),
        Size = UDim2.fromOffset(0, 15),
        AutomaticSize = Enum.AutomaticSize.X,
        TextWrapped = false,
        ZIndex = 2
    })
    W.TitleLabel = TitleLabel
    W.SubLabel = SubLabel

    local Sidebar = Frame(Main, {
        Position = UDim2.fromOffset(0, TOPBAR + 1),
        Size = UDim2.new(0, SIDEBAR, 1, -(TOPBAR + 1)),
        ZIndex = 10
    })
    local SideScroll = MakeScroll(Sidebar, {
        Size = UDim2.new(1, 0, 1, W.Config.ShowUser ~= false and -USERCARD or 0),
        ScrollBarThickness = 2
    })
    table.insert(W.Scrolls, SideScroll)
    Padding(SideScroll, 10, 10, 10, 10)
    List(SideScroll, 10)

    local SideLine = Frame(Sidebar, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundTransparency = 0,
        ZIndex = 5
    })
    Fill(SideLine, "Overlay", "StrokeAlpha")

    local UserCard = Frame(Sidebar, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, -1, 0, USERCARD),
        Visible = W.Config.ShowUser ~= false,
        ZIndex = 4
    })
    local UserLine = Frame(UserCard, {
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 0
    })
    Fill(UserLine, "Overlay", "StrokeAlpha")
    local Avatar = New("ImageLabel", {
        Parent = UserCard,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 14, 0.5, 1),
        Size = UDim2.fromOffset(38, 38),
        BorderSizePixel = 0,
        Image = "",
        ZIndex = 2
    })
    Corner(Avatar, UDim.new(1, 0))
    Fill(Avatar, "Overlay", "ActiveAlpha")
    local UserName = Label(UserCard, LocalPlayer and LocalPlayer.DisplayName or "Player", 13, "SemiBold", "Text", {
        Position = UDim2.new(0, 62, 0.5, -16),
        Size = UDim2.new(1, -72, 0, 16),
        AutomaticSize = Enum.AutomaticSize.None,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2
    })
    local UserTag = Label(UserCard, "@" .. (LocalPlayer and LocalPlayer.Name or "player"), 11, "Regular", "TextDim", {
        Position = UDim2.new(0, 62, 0.5, 1),
        Size = UDim2.new(1, -72, 0, 14),
        AutomaticSize = Enum.AutomaticSize.None,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2
    })
    if LocalPlayer then
        task.spawn(function()
            local Ok, Thumb = pcall(function()
                return Players:GetUserThumbnailAsync(
                    LocalPlayer.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size100x100
                )
            end)
            if Ok and Avatar.Parent then
                Avatar.Image = Thumb
            end
        end)
    end

    local Content = Frame(Main, {
        Position = UDim2.fromOffset(SIDEBAR + 1, TOPBAR + 1),
        Size = UDim2.new(1, -(SIDEBAR + 1), 1, -(TOPBAR + 1)),
        ClipsDescendants = true,
        ZIndex = 5
    })

    local SearchBox
    local Results
    local ResultsHost

    local function Navigate(Entry)
        local El = Entry.Element
        local Container = El.Container
        if not El.Frame or not El.Frame.Parent then
            return
        end
        local Tab = Container.Tab
        if Tab then
            W.SelectTab(Tab)
            if Container.Subtab then
                Tab.SelectSub(Container.Subtab)
            end
        end
        task.defer(function()
            local Scroll = Container.Scroll
            if Scroll and Scroll.Parent and El.Frame.Parent then
                local Target = El.Frame.AbsolutePosition.Y - Scroll.AbsolutePosition.Y + Scroll.CanvasPosition.Y - 12
                Scroll.CanvasPosition = Vector2.new(0, math.max(Target, 0))
            end
            local Mark = New("UIStroke", {
                Parent = El.Frame,
                Thickness = 1.5,
                Color = Library.Theme.Accent,
                Transparency = 0.2,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            Tween(Mark, SLOW, { Transparency = 1 })
            task.delay(0.6, function()
                Mark:Destroy()
            end)
        end)
    end

    local ResultItems = {}

    function W.UpdateSearch(Query)
        Query = tostring(Query or ""):lower()
        for _, Item in ipairs(ResultItems) do
            Item:Destroy()
        end
        table.clear(ResultItems)
        if Query == "" then
            ResultsHost.Visible = false
            return
        end
        ResultsHost.Visible = true
        local Shown = 0
        for _, Entry in ipairs(W.SearchList) do
            local El = Entry.Element
            if not Entry.Dead and not El.Dead and El.Frame and El.Frame.Parent and tostring(El.Title) ~= "" then
                local Hay = (tostring(El.Title) .. " " .. tostring(El.Description) .. " " .. El.Kind):lower()
                if Hay:find(Query, 1, true) then
                    Shown = Shown + 1
                    if Shown > 40 then
                        break
                    end
                    local Container = El.Container
                    local Path = Container.Tab and tostring(Container.Tab.Title) or ""
                    if Container.Subtab then
                        Path = Path .. "  /  " .. tostring(Container.Subtab.Title)
                    end
                    local Item = New("TextButton", {
                        Parent = Results,
                        Size = UDim2.new(1, 0, 0, 48),
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        LayoutOrder = Shown
                    })
                    Corner(Item, 8)
                    Fill(Item, "Overlay", "RowAlpha")
                    Stroke(Item, "StrokeAlpha")
                    Label(Item, tostring(El.Title), 13, "Medium", "Text", {
                        Position = UDim2.fromOffset(14, 7),
                        Size = UDim2.new(1, -28, 0, 17),
                        AutomaticSize = Enum.AutomaticSize.None,
                        TextWrapped = false,
                        TextTruncate = Enum.TextTruncate.AtEnd
                    })
                    Label(Item, Path .. "  -  " .. El.Kind, 11, "Regular", "TextDim", {
                        Position = UDim2.fromOffset(14, 25),
                        Size = UDim2.new(1, -28, 0, 15),
                        AutomaticSize = Enum.AutomaticSize.None,
                        TextWrapped = false,
                        TextTruncate = Enum.TextTruncate.AtEnd
                    })
                    Item.MouseEnter:Connect(function()
                        Tween(Item, FAST, { BackgroundTransparency = Library.Theme.RowHoverAlpha })
                    end)
                    Item.MouseLeave:Connect(function()
                        Tween(Item, FAST, { BackgroundTransparency = Library.Theme.RowAlpha })
                    end)
                    Item.MouseButton1Click:Connect(function()
                        if SearchBox then
                            SearchBox.Text = ""
                        end
                        Navigate(Entry)
                    end)
                    table.insert(ResultItems, Item)
                end
            end
        end
        if Shown == 0 then
            local Empty = Label(Results, "Nothing matches that search", 12.5, "Regular", "TextFaint", {
                Size = UDim2.new(1, 0, 0, 60),
                AutomaticSize = Enum.AutomaticSize.None,
                TextXAlignment = Enum.TextXAlignment.Center
            })
            table.insert(ResultItems, Empty)
        end
    end

    ResultsHost = Frame(Content, { Visible = false, BackgroundTransparency = 0.02, ZIndex = 60 })
    Library:Themed(ResultsHost, { BackgroundColor3 = "Window" })
    Results = MakeScroll(ResultsHost, {})
    table.insert(W.Scrolls, Results)
    Padding(Results, 10, 14, 14, 18)
    List(Results, 8)

    function W.AddSearch(El)
        local Entry = { Element = El, Dead = false }
        table.insert(W.SearchList, Entry)
        return Entry
    end

    function W.ClosePopup()
        if W.Popup then
            W.Popup.Close()
        end
    end

    function W.OpenPopup(Anchor, Spec, Build)
        W.ClosePopup()
        local Width = Spec.Width or 180
        local Height = Spec.Height or 160

        local Catcher = New("TextButton", {
            Parent = PopupLayer,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 1
        })

        local LayerPos = PopupLayer.AbsolutePosition
        local View = PopupLayer.AbsoluteSize
        local Place = Anchor.AbsolutePosition - LayerPos
        local Extent = Anchor.AbsoluteSize
        local X = Clamp(Place.X + Extent.X - Width, 8, math.max(View.X - Width - 8, 8))
        local Y = Place.Y + Extent.Y + 6
        if Y + Height > View.Y - 8 then
            Y = Place.Y - Height - 6
        end
        Y = Clamp(Y, 8, math.max(View.Y - Height - 8, 8))

        local Panel = Frame(PopupLayer, {
            Position = UDim2.fromOffset(X, Y),
            Size = UDim2.fromOffset(Width, Height),
            BackgroundTransparency = 0.02,
            Active = true,
            ZIndex = 2
        })
        Library:Themed(Panel, { BackgroundColor3 = "Window" })
        Corner(Panel, 10)
        Stroke(Panel, "StrokeStrongAlpha")
        local Scale = New("UIScale", { Parent = Panel, Scale = 0.96 })
        Tween(Scale, FAST, { Scale = 1 })

        local Popup = { Panel = Panel, Dead = false }
        function Popup.Close()
            if Popup.Dead then
                return
            end
            Popup.Dead = true
            if W.Popup == Popup then
                W.Popup = nil
            end
            if Popup.OnClose then
                pcall(Popup.OnClose)
            end
            Panel:Destroy()
            Catcher:Destroy()
        end
        Catcher.MouseButton1Click:Connect(Popup.Close)
        W.Popup = Popup
        Build(Panel, Popup.Close)
        return Popup
    end

    function W.Notify(Cfg)
        if type(Cfg) == "string" then
            Cfg = { Content = Cfg }
        end
        Cfg = Merge({ Title = "Notice", Content = "", Type = "Info", Duration = 4 }, Cfg)
        local Spec = NotifyTypes[Cfg.Type] or NotifyTypes.Info
        W.NotifyCounter = W.NotifyCounter + 1

        local Wrap = Frame(NotifyLayer, {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = W.NotifyCounter
        })
        local Card = Frame(Wrap, {
            Position = UDim2.fromOffset(340, 0),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 0.03,
            ClipsDescendants = true
        })
        Library:Themed(Card, { BackgroundColor3 = "Window" })
        Corner(Card, 12)
        Stroke(Card, "StrokeStrongAlpha")

        local Inner = Frame(Card, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
        Padding(Inner, 12, 16, 14, 14)
        List(Inner, 12, true, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

        local Badge = Frame(Inner, {
            Size = UDim2.fromOffset(30, 30),
            BackgroundTransparency = 0,
            LayoutOrder = 1
        })
        Corner(Badge, UDim.new(1, 0))
        Library:Themed(Badge, { BackgroundColor3 = Spec.Token })
        Badge.BackgroundTransparency = 0.84
        Icon(Badge, Spec.Icon, 16, Spec.Token, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5)
        })

        local Stack = Frame(Inner, {
            Size = UDim2.new(1, -44, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2
        })
        List(Stack, 2)
        Label(Stack, tostring(Cfg.Title), 13, "SemiBold", "Text", { LayoutOrder = 1 })
        Label(Stack, tostring(Cfg.Content), 12, "Regular", "TextDim", {
            LayoutOrder = 2,
            Visible = tostring(Cfg.Content) ~= ""
        })

        local Timer = Frame(Card, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundTransparency = 0.4
        })
        Library:Themed(Timer, { BackgroundColor3 = Spec.Token })

        local Hit = New("TextButton", {
            Parent = Card,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 5
        })

        local Item = { Dead = false }
        function Item.Dismiss()
            if Item.Dead then
                return
            end
            Item.Dead = true
            local Index = table.find(W.Notifs, Item)
            if Index then
                table.remove(W.Notifs, Index)
            end
            Tween(Card, NORMAL, { Position = UDim2.fromOffset(340, 0) })
            task.delay(0.28, function()
                Wrap:Destroy()
            end)
        end
        Hit.MouseButton1Click:Connect(Item.Dismiss)

        table.insert(W.Notifs, Item)
        while #W.Notifs > (tonumber(W.Config.NotifyMax) or 4) do
            W.Notifs[1].Dismiss()
        end

        Tween(Card, SPRING, { Position = UDim2.fromOffset(0, 0) })
        local Duration = tonumber(Cfg.Duration) or 4
        if Duration > 0 then
            Tween(Timer, TweenInfo.new(Duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
            task.delay(Duration, Item.Dismiss)
        else
            Timer.Visible = false
        end
        return Item
    end

    local ModalStack = {}

    function W.Dialog(Cfg)
        Cfg = Merge({
            Title = "Dialog",
            Content = "",
            Type = "Info",
            Buttons = { { Title = "OK", Filled = true } },
            Dismissable = true
        }, Cfg)
        local Spec = NotifyTypes[Cfg.Type] or NotifyTypes.Info
        local View = ViewportSize()
        local Width = Clamp(View.X - 32, 260, 380)

        local Dim = New("TextButton", {
            Parent = ModalLayer,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = #ModalStack + 1
        })
        Tween(Dim, NORMAL, { BackgroundTransparency = 0.5 })

        local Card = Frame(Dim, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(Width, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 0.02,
            Active = true,
            ZIndex = 2
        })
        Library:Themed(Card, { BackgroundColor3 = "Window" })
        Corner(Card, 14)
        Stroke(Card, "StrokeStrongAlpha")
        local Scale = New("UIScale", { Parent = Card, Scale = 0.94 })
        Tween(Scale, SPRING, { Scale = 1 })
        Padding(Card, 20, 20, 20, 20)
        List(Card, 14)

        local Head = Frame(Card, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 })
        List(Head, 12, true, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
        local Badge = Frame(Head, { Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 0.84, LayoutOrder = 1 })
        Corner(Badge, UDim.new(1, 0))
        Library:Themed(Badge, { BackgroundColor3 = Spec.Token })
        Badge.BackgroundTransparency = 0.84
        Icon(Badge, Spec.Icon, 18, Spec.Token, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5)
        })
        local Stack = Frame(Head, {
            Size = UDim2.new(1, -48, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2
        })
        List(Stack, 4)
        Label(Stack, tostring(Cfg.Title), 15, "SemiBold", "Text", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 36) })
        Label(Stack, tostring(Cfg.Content), 12.5, "Regular", "TextDim", {
            LayoutOrder = 2,
            Visible = tostring(Cfg.Content) ~= ""
        })

        local Box
        if type(Cfg.Input) == "table" then
            Box = New("TextBox", {
                Parent = Card,
                Size = UDim2.new(1, 0, 0, 34),
                BorderSizePixel = 0,
                FontFace = Library.Font.Regular,
                TextSize = 13,
                Text = tostring(Cfg.Input.Default or ""),
                PlaceholderText = tostring(Cfg.Input.Placeholder or ""),
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 2
            })
            Corner(Box, 8)
            Fill(Box, "Overlay", "InsetAlpha")
            Stroke(Box, "StrokeAlpha")
            Padding(Box, 0, 0, 12, 12)
            Library:Themed(Box, { TextColor3 = "Text", PlaceholderColor3 = "TextFaint" })
        end

        local Buttons = Cfg.Buttons
        local Stacked = #Buttons > 2 or Width < 300
        local Row = Frame(Card, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3 })
        List(Row, 8, not Stacked)

        local Closed = false
        local Entry = {}
        local function Close(Value, Callback)
            if Closed then
                return
            end
            Closed = true
            local Index = table.find(ModalStack, Entry)
            if Index then
                table.remove(ModalStack, Index)
            end
            W.ModalClose = ModalStack[#ModalStack] and ModalStack[#ModalStack].Dismiss or nil
            Tween(Dim, FAST, { BackgroundTransparency = 1 })
            Tween(Scale, FAST, { Scale = 0.96 })
            task.delay(0.16, function()
                Dim:Destroy()
            end)
            if Callback then
                Call(Callback, Value)
            end
        end
        Entry.Dismiss = function()
            if Cfg.Dismissable ~= false then
                Close(nil, nil)
            end
        end
        table.insert(ModalStack, Entry)
        W.ModalClose = Entry.Dismiss
        Dim.MouseButton1Click:Connect(Entry.Dismiss)

        local PrimaryAction
        for Index, Spec_ in ipairs(Buttons) do
            local Danger = Spec_.Filled and (Cfg.Type == "Danger" or Cfg.Type == "Error")
            local Button = New("TextButton", {
                Parent = Row,
                Size = Stacked and UDim2.new(1, 0, 0, 36) or UDim2.new(1 / #Buttons, -(8 * (#Buttons - 1)) / #Buttons, 0, 36),
                BorderSizePixel = 0,
                FontFace = Library.Font.Medium,
                TextSize = 13,
                Text = tostring(Spec_.Title or "OK"),
                AutoButtonColor = false,
                LayoutOrder = Index
            })
            Corner(Button, 8)
            if Spec_.Filled then
                Library:Themed(Button, {
                    BackgroundColor3 = Danger and "Error" or "Accent",
                    TextColor3 = Danger and "Text" or "AccentText"
                })
                Button.BackgroundTransparency = 0
                PrimaryAction = function()
                    Close(Box and Box.Text or nil, Spec_.Callback)
                end
            else
                Fill(Button, "Overlay", "ButtonAlpha")
                Stroke(Button, "StrokeAlpha")
                Library:Themed(Button, { TextColor3 = "Text" })
            end
            Button.MouseEnter:Connect(function()
                Tween(Button, FAST, { BackgroundTransparency = Spec_.Filled and 0.12 or Library.Theme.ButtonHoverAlpha })
            end)
            Button.MouseLeave:Connect(function()
                Tween(Button, FAST, { BackgroundTransparency = Spec_.Filled and 0 or Library.Theme.ButtonAlpha })
            end)
            Button.MouseButton1Click:Connect(function()
                Close(Box and Box.Text or nil, Spec_.Callback)
            end)
        end

        if Box then
            Box.FocusLost:Connect(function(Enter)
                if Enter and PrimaryAction then
                    PrimaryAction()
                end
            end)
            task.defer(function()
                if Box.Parent then
                    Box:CaptureFocus()
                end
            end)
        end
        return Entry
    end

    local Tabs = W.Tabs

    local function PaintTab(Tab)
        local Theme = Library.Theme
        local Active = W.CurrentTab == Tab
        Tab.Item.BackgroundTransparency = Active and Theme.ActiveAlpha or 1
        Tab.IconLabel.ImageColor3 = Active and Theme.Text or Theme.TextDim
        Tab.Text.TextColor3 = Active and Theme.Text or Theme.TextDim
    end

    function W.SelectTab(Tab)
        if W.CurrentTab == Tab then
            return
        end
        W.CurrentTab = Tab
        for _, Other in ipairs(Tabs) do
            Other.Page.Visible = Other == Tab
            Tween(Other.Item, FAST, {
                BackgroundTransparency = Other == Tab and Library.Theme.ActiveAlpha or 1
            })
            Tween(Other.IconLabel, FAST, { ImageColor3 = Other == Tab and Library.Theme.Text or Library.Theme.TextDim })
            Tween(Other.Text, FAST, { TextColor3 = Other == Tab and Library.Theme.Text or Library.Theme.TextDim })
        end
        W.ClosePopup()
    end

    local function GetGroup(Name)
        Name = Name or ""
        if W.GroupMap[Name] then
            return W.GroupMap[Name]
        end
        local Group = { Name = Name, Open = true }
        Group.Frame = Frame(SideScroll, {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = #W.Groups + 1
        })
        List(Group.Frame, 4)
        if Name ~= "" then
            Group.Head = New("TextButton", {
                Parent = Group.Frame,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = 0
            })
            Group.Chevron = Icon(Group.Head, "chevron-down", 13, "TextFaint", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 6, 0.5, 0)
            })
            Group.Title = Label(Group.Head, string.upper(Name), 10.5, "SemiBold", "TextFaint", {
                Position = UDim2.fromOffset(26, 0),
                Size = UDim2.new(1, -30, 1, 0),
                AutomaticSize = Enum.AutomaticSize.None,
                TextWrapped = false
            })
        end
        Group.Items = Frame(Group.Frame, {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1
        })
        List(Group.Items, 3)
        if Group.Head then
            Group.Head.MouseButton1Click:Connect(function()
                Group.Open = not Group.Open
                Group.Items.Visible = Group.Open
                Tween(Group.Chevron, NORMAL, { Rotation = Group.Open and 0 or -90 })
            end)
        end
        W.GroupMap[Name] = Group
        table.insert(W.Groups, Group)
        return Group
    end

    function W.ApplyCompact()
        local Width = W.Compact and SIDEBAR_COMPACT or SIDEBAR
        Sidebar.Size = UDim2.new(0, Width, 1, -(TOPBAR + 1))
        Content.Position = UDim2.fromOffset(Width + 1, TOPBAR + 1)
        Content.Size = UDim2.new(1, -(Width + 1), 1, -(TOPBAR + 1))
        for _, Group in ipairs(W.Groups) do
            if Group.Head then
                Group.Head.Visible = not W.Compact
                Group.Items.Visible = W.Compact or Group.Open
            end
        end
        for _, Tab in ipairs(Tabs) do
            Tab.Text.Visible = not W.Compact
            Tab.LockMark.Visible = Tab.Locked and not W.Compact
            Tab.IconLabel.AnchorPoint = W.Compact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
            Tab.IconLabel.Position = W.Compact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 12, 0.5, 0)
        end
        UserName.Visible = not W.Compact
        UserTag.Visible = not W.Compact
        Avatar.AnchorPoint = W.Compact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
        Avatar.Position = W.Compact and UDim2.new(0.5, 0, 0.5, 1) or UDim2.new(0, 14, 0.5, 1)
        TitleLabel.Visible = true
        SubLabel.Visible = not W.Compact
    end

    function W.ClampPosition()
        local View = ViewportSize()
        local Position = Root.Position
        local HalfW = W.Width / 2
        local HalfH = (W.Minimized and TOPBAR + 1 or W.Height) / 2
        local MaxX = View.X / 2 + HalfW - 120
        local MaxY = View.Y / 2 - HalfH + (HalfH * 2 - TOPBAR) - 8
        local OffsetX = Clamp(Position.X.Offset, -MaxX, MaxX)
        local OffsetY = Clamp(Position.Y.Offset, -(View.Y / 2 - HalfH), MaxY)
        Root.Position = UDim2.new(0.5, OffsetX, 0.5, OffsetY)
    end

    function W.Fit(Animate)
        local View = ViewportSize()
        local Want = W.Config.Size
        local Wide, High
        if typeof(Want) == "UDim2" then
            Wide = Want.X.Offset + Want.X.Scale * View.X
            High = Want.Y.Offset + Want.Y.Scale * View.Y
        elseif typeof(Want) == "Vector2" then
            Wide, High = Want.X, Want.Y
        else
            Wide, High = 720, 520
        end
        if W.Maximized then
            Wide, High = View.X - 40, View.Y - 40
            Root.Position = UDim2.fromScale(0.5, 0.5)
        else
            Wide = Clamp(Wide, 300, math.max(View.X - 24, 300))
            High = Clamp(High, 260, math.max(View.Y - 24, 260))
        end
        W.Width = math.floor(Wide)
        W.Height = math.floor(High)
        W.Compact = W.Width < 560
        local Target = UDim2.fromOffset(W.Width, W.Minimized and TOPBAR + 1 or W.Height)
        if Animate then
            Tween(Root, NORMAL, { Size = Target })
        else
            Root.Size = Target
        end
        W.ApplyCompact()
        W.ClampPosition()
    end

    Track(DragArea, function(Input)
        W.DragStart = Vector2.new(Input.Position.X, Input.Position.Y)
        W.DragOrigin = Root.Position
        W.ClosePopup()
        if W.Maximized then
            return false
        end
    end, function(Position)
        if not W.DragStart then
            return
        end
        local Delta = Vector2.new(Position.X, Position.Y) - W.DragStart
        local Origin = W.DragOrigin
        Root.Position = UDim2.new(0.5, Origin.X.Offset + Delta.X, 0.5, Origin.Y.Offset + Delta.Y)
        W.ClampPosition()
    end, function()
        W.DragStart = nil
    end)

    if SearchButton then
        SearchBox = New("TextBox", {
            Parent = Topbar,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -(ControlsWidth + 22), 0.5, 0),
            Size = UDim2.fromOffset(0, 30),
            BorderSizePixel = 0,
            FontFace = Library.Font.Regular,
            TextSize = 12.5,
            Text = "",
            PlaceholderText = "Search elements...",
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClipsDescendants = true,
            Visible = false,
            ZIndex = 4
        })
        Corner(SearchBox, 8)
        Fill(SearchBox, "Overlay", "InsetAlpha")
        Stroke(SearchBox, "StrokeAlpha")
        Padding(SearchBox, 0, 0, 12, 12)
        Library:Themed(SearchBox, { TextColor3 = "Text", PlaceholderColor3 = "TextFaint" })

        local SearchOpen = false
        local function SetSearch(State)
            SearchOpen = State
            if State then
                SearchBox.Visible = true
                local Wide = Clamp(W.Width - ControlsWidth - 200, 90, 200)
                Tween(SearchBox, NORMAL, { Size = UDim2.fromOffset(Wide, 30) })
                SearchBox:CaptureFocus()
            else
                SearchBox.Text = ""
                Tween(SearchBox, NORMAL, { Size = UDim2.fromOffset(0, 30) })
                task.delay(0.26, function()
                    if not SearchOpen then
                        SearchBox.Visible = false
                    end
                end)
            end
        end
        SearchButton.MouseButton1Click:Connect(function()
            SetSearch(not SearchOpen)
        end)
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            W.UpdateSearch(SearchBox.Text)
        end)
        SearchBox.FocusLost:Connect(function()
            if SearchBox.Text == "" and SearchOpen then
                SetSearch(false)
            end
        end)
    end

    MinButton.MouseButton1Click:Connect(function()
        W.Minimized = not W.Minimized
        W.ClosePopup()
        W.Fit(true)
    end)

    MaxButton.MouseButton1Click:Connect(function()
        W.Maximized = not W.Maximized
        W.Minimized = false
        Library:SetIcon(MaxMark, W.Maximized and "minimize-2|minimize" or "maximize-2|maximize")
        W.Fit(true)
    end)

    CloseButton.MouseButton1Click:Connect(function()
        if W.Config.ConfirmClose == false then
            W.API:Destroy()
            return
        end
        W.Dialog({
            Title = "Close window?",
            Content = "The interface will be removed. Run the script again to bring it back.",
            Type = "Danger",
            Buttons = {
                { Title = "Cancel" },
                {
                    Title = "Close",
                    Filled = true,
                    Callback = function()
                        W.API:Destroy()
                    end
                }
            }
        })
    end)

    function W.SetOpen(State)
        W.Open = State and true or false
        Root.Visible = W.Open
        if not W.Open then
            W.ClosePopup()
        end
        if W.Blur then
            Tween(W.Blur, NORMAL, { Size = W.Open and 14 or 0 })
        end
    end

    table.insert(W.Connections, UserInputService.InputBegan:Connect(function(Input)
        if W.Destroyed then
            return
        end
        if W.Listening and W.Listening(Input) then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        local Toggle = W.Config.ToggleKey
        if Toggle and Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Toggle then
            W.SetOpen(not W.Open)
            return
        end
        if Input.KeyCode == Enum.KeyCode.Escape then
            if W.ModalClose then
                W.ModalClose()
                return
            elseif W.Popup then
                W.ClosePopup()
                return
            end
        end
        for _, Bind in ipairs(W.Keybinds) do
            Bind.Press(Input, true)
        end
    end))

    table.insert(W.Connections, UserInputService.InputEnded:Connect(function(Input)
        if W.Destroyed then
            return
        end
        for _, Bind in ipairs(W.Keybinds) do
            Bind.Press(Input, false)
        end
    end))

    local Camera = workspace.CurrentCamera
    if Camera then
        table.insert(W.Connections, Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            W.Fit(false)
        end))
    end

    if W.Config.Blur then
        W.Blur = New("BlurEffect", { Parent = Lighting, Size = 0, Name = HttpService:GenerateGUID(false) })
    end

    local Tab = {}
    Tab.__index = Tab
    Expose(Tab, function(self)
        return self:Direct()
    end)

    local Subtab = {}
    Subtab.__index = Subtab
    Expose(Subtab, function(self)
        return self.Container
    end)

    function Tab:Direct()
        if not self.DirectContainer then
            local Scroll = MakeScroll(self.Body, { Visible = #self.Subtabs == 0 })
            table.insert(W.Scrolls, Scroll)
            Padding(Scroll, 8, 18, 14, 18)
            List(Scroll, 14)
            self.DirectContainer = NewContainer({
                Window = W,
                Tab = self,
                Scroll = Scroll,
                Holder = Scroll
            })
        end
        return self.DirectContainer
    end

    function Tab:Select()
        W.SelectTab(self)
        return self
    end

    function Tab.SelectSub(Target)
        local Owner = Target.Tab
        Owner.ActiveSub = Target
        for _, Sub in ipairs(Owner.Subtabs) do
            Sub.Container.Scroll.Visible = Sub == Target
            Sub.Paint()
        end
    end

    function Subtab:Select()
        W.SelectTab(self.Tab)
        Tab.SelectSub(self)
        return self
    end

    function Tab:AddSubtab(Config)
        if type(Config) == "string" then
            Config = { Title = Config }
        end
        Config = Merge({ Title = "Subtab" }, Config)

        if #self.Subtabs == 0 then
            self.Bar.Visible = true
            self.Body.Position = UDim2.fromOffset(0, 46)
            self.Body.Size = UDim2.new(1, 0, 1, -46)
            if self.DirectContainer then
                self.DirectContainer.Scroll.Visible = false
            end
        end

        local Sub = setmetatable({ Title = Config.Title, Tab = self }, Subtab)

        local Pill = New("TextButton", {
            Parent = self.Bar,
            Size = UDim2.fromOffset(0, 32),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #self.Subtabs + 1
        })
        Corner(Pill, 8)
        Library:Themed(Pill, { BackgroundColor3 = "Overlay" })
        local Line = New("UIStroke", {
            Parent = Pill,
            Thickness = 1,
            Transparency = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        Library:Themed(Line, { Color = "Overlay" })
        Padding(Pill, 0, 0, 12, 14)
        List(Pill, 7, true, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
        local Mark
        if Config.Icon then
            Mark = Icon(Pill, Config.Icon, 15, "TextDim", { LayoutOrder = 1 })
        end
        local Text = Label(Pill, tostring(Config.Title), 12.5, "Medium", "TextDim", {
            LayoutOrder = 2,
            Size = UDim2.fromOffset(0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
            TextWrapped = false
        })

        local Hover = false
        function Sub.Paint()
            local Theme = Library.Theme
            local Active = self.ActiveSub == Sub
            Tween(Pill, FAST, {
                BackgroundTransparency = Active and Theme.ActiveAlpha or (Hover and Theme.ButtonAlpha or 1)
            })
            Tween(Line, FAST, { Transparency = Active and Theme.StrokeAlpha or 1 })
            Tween(Text, FAST, { TextColor3 = Active and Theme.Text or Theme.TextDim })
            if Mark then
                Tween(Mark, FAST, { ImageColor3 = Active and Theme.Text or Theme.TextDim })
            end
        end
        Pill.MouseEnter:Connect(function()
            Hover = true
            Sub.Paint()
        end)
        Pill.MouseLeave:Connect(function()
            Hover = false
            Sub.Paint()
        end)
        Pill.MouseButton1Click:Connect(function()
            Tab.SelectSub(Sub)
        end)

        local Scroll = MakeScroll(self.Body, { Visible = false })
        table.insert(W.Scrolls, Scroll)
        Padding(Scroll, 8, 18, 14, 18)
        List(Scroll, 14)
        Sub.Container = NewContainer({
            Window = W,
            Tab = self,
            Subtab = Sub,
            Scroll = Scroll,
            Holder = Scroll
        })

        table.insert(self.Subtabs, Sub)
        if #self.Subtabs == 1 then
            Tab.SelectSub(Sub)
        else
            Sub.Paint()
        end
        return Sub
    end

    local function BuildLock(Owner, LockCfg)
        local Has = Library.Auth.Has(LockCfg)
        local LockId = LockCfg.Id or LockCfg.Key or ("tab_" .. tostring(Owner.Title))
        local Verify = Has and Library.Auth.Resolve(LockCfg) or nil

        local Cover = New("TextButton", {
            Parent = Owner.Page,
            Size = UDim2.fromScale(1, 1),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 0.04,
            ZIndex = 50
        })
        Library:Themed(Cover, { BackgroundColor3 = "Window" })

        local Card = Frame(Cover, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(290, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 0,
            Active = true,
            ZIndex = 51
        })
        Fill(Card, "Overlay", "RowAlpha")
        Corner(Card, 14)
        Stroke(Card, "StrokeAlpha")
        Padding(Card, 22, 22, 22, 22)
        List(Card, 12, false, Enum.HorizontalAlignment.Center)

        local Badge = Frame(Card, { Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 0, LayoutOrder = 1 })
        Fill(Badge, "Overlay", "ActiveAlpha")
        Corner(Badge, UDim.new(1, 0))
        Icon(Badge, "lock", 20, "Text", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5)
        })
        Label(Card, tostring(LockCfg.Title or "Locked"), 15, "SemiBold", "Text", {
            LayoutOrder = 2,
            TextXAlignment = Enum.TextXAlignment.Center
        })
        Label(Card, tostring(LockCfg.Description or "Enter your key to unlock this page."), 12, "Regular", "TextDim", {
            LayoutOrder = 3,
            TextXAlignment = Enum.TextXAlignment.Center
        })

        local Box = New("TextBox", {
            Parent = Card,
            Size = UDim2.new(1, 0, 0, 34),
            BorderSizePixel = 0,
            FontFace = Library.Font.Regular,
            TextSize = 13,
            Text = "",
            PlaceholderText = tostring(LockCfg.Placeholder or "key"),
            ClearTextOnFocus = false,
            LayoutOrder = 4
        })
        Corner(Box, 8)
        Fill(Box, "Overlay", "InsetAlpha")
        Stroke(Box, "StrokeAlpha")
        Library:Themed(Box, { TextColor3 = "Text", PlaceholderColor3 = "TextFaint" })

        local Status = Label(Card, "", 11.5, "Medium", "Error", {
            LayoutOrder = 5,
            TextXAlignment = Enum.TextXAlignment.Center,
            Visible = false
        })

        local Button = New("TextButton", {
            Parent = Card,
            Size = UDim2.new(1, 0, 0, 36),
            BorderSizePixel = 0,
            FontFace = Library.Font.Medium,
            TextSize = 13,
            Text = tostring(LockCfg.Confirm or "Unlock"),
            AutoButtonColor = false,
            LayoutOrder = 6
        })
        Corner(Button, 8)
        Library:Themed(Button, { BackgroundColor3 = "Accent", TextColor3 = "AccentText" })
        Button.BackgroundTransparency = 0

        local function Unlock(Payload)
            Owner.Locked = false
            Cover.Visible = false
            Owner.LockMark.Visible = false
            Call(LockCfg.OnUnlock, Payload)
        end

        local Busy = false
        local function Attempt()
            if Busy or not Verify then
                return
            end
            Busy = true
            Button.Text = "Checking..."
            task.spawn(function()
                local Ok, Reason, Payload = Verify(Trim(Box.Text), { Kind = "Tab", Id = LockId })
                Busy = false
                if not Button.Parent then
                    return
                end
                Button.Text = tostring(LockCfg.Confirm or "Unlock")
                if Ok then
                    if LockCfg.Remember ~= false then
                        Library.Auth.Remember(W, LockId, tonumber(LockCfg.RememberMinutes) or 30)
                    end
                    W.Notify({ Title = "Unlocked", Content = tostring(Owner.Title), Type = "Success", Duration = 3 })
                    Unlock(Payload)
                else
                    Status.Text = tostring(Reason or "Access denied")
                    Status.Visible = true
                end
            end)
        end
        Button.MouseButton1Click:Connect(Attempt)
        Box.FocusLost:Connect(function(Enter)
            if Enter then
                Attempt()
            end
        end)

        Owner.Locked = true
        if Has and LockCfg.Remember ~= false and Library.Auth.IsRemembered(W, LockId) then
            Owner.Locked = false
            Cover.Visible = false
        end
    end

    function W.AddTab(Config)
        if type(Config) == "string" then
            Config = { Title = Config }
        end
        Config = Merge({ Title = "Tab", Icon = "square" }, Config)
        local Group = GetGroup(Config.Group)

        local Item = New("TextButton", {
            Parent = Group.Items,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #Tabs + 1
        })
        Corner(Item, 8)
        Library:Themed(Item, { BackgroundColor3 = "Overlay" })
        local Mark = Icon(Item, Config.Icon, 18, "TextDim", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0),
            ZIndex = 2
        })
        local Text = Label(Item, tostring(Config.Title), 13, "Medium", "TextDim", {
            Position = UDim2.fromOffset(40, 0),
            Size = UDim2.new(1, -66, 1, 0),
            AutomaticSize = Enum.AutomaticSize.None,
            TextWrapped = false,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2
        })
        local LockMark = Icon(Item, "lock", 12, "TextFaint", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Visible = false,
            ZIndex = 2
        })

        local Page = Frame(Content, { Visible = false, ZIndex = 1 })
        local Bar = New("ScrollingFrame", {
            Parent = Page,
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageTransparency = 0.55,
            ScrollingDirection = Enum.ScrollingDirection.X,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            HorizontalScrollBarInset = Enum.ScrollBarInset.None,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            Visible = false,
            ZIndex = 3
        })
        Library:Themed(Bar, { ScrollBarImageColor3 = "Overlay" })
        table.insert(W.Scrolls, Bar)
        Padding(Bar, 6, 0, 14, 14)
        List(Bar, 6, true)
        Bar.InputChanged:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseWheel then
                local Limit = math.max(Bar.AbsoluteCanvasSize.X - Bar.AbsoluteWindowSize.X, 0)
                Bar.CanvasPosition = Vector2.new(Clamp(Bar.CanvasPosition.X - Input.Position.Z * 60, 0, Limit), 0)
            end
        end)
        local Body = Frame(Page, { ZIndex = 1 })

        local Entry = setmetatable({
            Title = Config.Title,
            Icon = Config.Icon,
            Item = Item,
            IconLabel = Mark,
            Text = Text,
            LockMark = LockMark,
            Page = Page,
            Bar = Bar,
            Body = Body,
            Subtabs = {},
            Locked = false
        }, Tab)

        table.insert(Tabs, Entry)

        local Hover = false
        Item.MouseEnter:Connect(function()
            Hover = true
            if W.CurrentTab ~= Entry then
                Tween(Item, FAST, { BackgroundTransparency = Library.Theme.ButtonAlpha })
            end
        end)
        Item.MouseLeave:Connect(function()
            Hover = false
            if W.CurrentTab ~= Entry then
                Tween(Item, FAST, { BackgroundTransparency = 1 })
            end
        end)
        Item.MouseButton1Click:Connect(function()
            W.SelectTab(Entry)
        end)
        Library:Bind(Item, function()
            PaintTab(Entry)
        end)

        if type(Config.Lock) == "table" then
            BuildLock(Entry, Config.Lock)
            LockMark.Visible = Entry.Locked and not W.Compact
        end

        W.ApplyCompact()
        if not W.CurrentTab then
            W.SelectTab(Entry)
        end
        return Entry
    end

    local API = {}
    API.Window = W
    API.Tabs = Tabs
    API.Flags = W.Flags
    W.API = API

    function API:Tab(Config)
        return W.AddTab(Config)
    end
    API.AddTab = API.Tab

    function API:Dialog(Config)
        return W.Dialog(Config)
    end
    API.Popup = API.Dialog

    function API:Prompt(Config)
        Config = Merge({
            Title = "Input",
            Content = "",
            Placeholder = "",
            Default = "",
            Confirm = "OK",
            Callback = nil
        }, Config)
        return W.Dialog({
            Title = Config.Title,
            Content = Config.Content,
            Type = "Question",
            Input = { Placeholder = Config.Placeholder, Default = Config.Default },
            Buttons = {
                { Title = "Cancel" },
                { Title = Config.Confirm, Filled = true, Callback = Config.Callback }
            }
        })
    end

    function API:Notify(Config)
        return W.Notify(Config)
    end

    function API:GetFlag(Flag, Fallback)
        return Library:GetFlag(Flag, Fallback)
    end

    function API:GetElement(Flag)
        return W.Flags[Flag]
    end

    function API:SaveConfig(Name)
        Name = Sanitize(Name or W.Profile)
        local Ok = W.WriteConfig(Name)
        if Ok then
            W.Profile = Name
            W.SaveState()
        end
        return Ok
    end

    function API:LoadConfig(Name)
        Name = Sanitize(Name or W.Profile)
        local Ok = W.ReadConfig(Name)
        if Ok then
            W.Profile = Name
            W.SaveState()
        end
        return Ok
    end

    function API:DeleteConfig(Name)
        return FS.Delete(W.ConfigPath(Name))
    end

    function API:ListConfigs()
        local Names = {}
        for _, Path in ipairs(FS.List(W.Paths.Configs)) do
            local Name = tostring(Path):match("([^/\\]+)%.json$")
            if Name then
                table.insert(Names, Name)
            end
        end
        table.sort(Names)
        return Names
    end

    function API:ConfigPanel(Target)
        Target = Target or API:Tab({ Title = "Configs", Icon = "save" })
        local Section = Target:AddSection({ Title = "Config Profiles", Icon = "save" })
        local Name = Section:AddInput({ Title = "Profile Name", Default = W.Profile, Placeholder = "default" })
        local Choice
        Choice = Section:AddDropdown({
            Title = "Saved Profiles",
            Options = API:ListConfigs(),
            Placeholder = "Pick a profile",
            Callback = function(Value)
                if Value then
                    Name:Set(Value)
                end
            end
        })
        local function Refresh()
            Choice:SetOptions(API:ListConfigs())
        end
        Section:AddMultiButton({
            Buttons = {
                {
                    Title = "Save",
                    Icon = "save",
                    Callback = function()
                        local Value = Sanitize(Name:Get())
                        if Value == "" then
                            W.Notify({ Title = "Save failed", Content = "Enter a profile name", Type = "Error" })
                        elseif API:SaveConfig(Value) then
                            Refresh()
                            W.Notify({ Title = "Saved", Content = Value, Type = "Success" })
                        else
                            W.Notify({ Title = "Save failed", Content = "File access is unavailable", Type = "Error" })
                        end
                    end
                },
                {
                    Title = "Load",
                    Icon = "folder-open|folder",
                    Callback = function()
                        local Value = Sanitize(Name:Get())
                        if API:LoadConfig(Value) then
                            W.Notify({ Title = "Loaded", Content = Value, Type = "Success" })
                        else
                            W.Notify({ Title = "Load failed", Content = "No profile named " .. Value, Type = "Error" })
                        end
                    end
                },
                {
                    Title = "Delete",
                    Icon = "trash-2|trash",
                    Callback = function()
                        local Value = Sanitize(Name:Get())
                        W.Dialog({
                            Title = "Delete profile?",
                            Content = Value .. " will be removed permanently.",
                            Type = "Danger",
                            Buttons = {
                                { Title = "Cancel" },
                                {
                                    Title = "Delete",
                                    Filled = true,
                                    Callback = function()
                                        if API:DeleteConfig(Value) then
                                            Refresh()
                                            W.Notify({ Title = "Deleted", Content = Value, Type = "Info" })
                                        else
                                            W.Notify({ Title = "Delete failed", Content = Value, Type = "Error" })
                                        end
                                    end
                                }
                            }
                        })
                    end
                }
            }
        })
        return Section
    end

    function API:ThemePanel(Target)
        Target = Target or API:Tab({ Title = "Appearance", Icon = "palette" })
        local Section = Target:AddSection({ Title = "Theme", Icon = "palette" })
        Section:AddDropdown({
            Title = "Theme",
            Options = Library.ThemeOrder,
            Default = Library.CurrentTheme,
            Callback = function(Value)
                API:SetTheme(Value)
            end
        })
        Section:AddSlider({
            Title = "Window Transparency",
            Min = 0,
            Max = 60,
            Default = 0,
            Suffix = "%",
            Callback = function(Value)
                API:SetTransparency(Value / 100)
            end
        })
        return Section
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
        W.AlphaOverride = Clamp(tonumber(Value) or 0, 0, 1)
        Main.BackgroundTransparency = W.AlphaOverride
    end

    function API:SetTitle(Text)
        W.Config.Title = tostring(Text)
        TitleLabel.Text = W.Config.Title
    end

    function API:SetDescription(Text)
        W.Config.Description = tostring(Text)
        SubLabel.Text = W.Config.Description
    end

    function API:SetSize(Size)
        W.Config.Size = Size
        W.Fit(true)
    end

    function API:Center()
        Root.Position = UDim2.fromScale(0.5, 0.5)
        W.ClampPosition()
    end

    function API:Toggle(State)
        if State == nil then
            State = not W.Open
        end
        W.SetOpen(State)
    end
    API.SetOpen = API.Toggle

    function API:Destroy()
        if W.Destroyed then
            return
        end
        W.SaveState()
        if W.Config.AutoSave then
            W.WriteConfig(W.Profile)
        end
        W.Destroyed = true
        W.ClosePopup()
        for _, Connection in ipairs(W.Connections) do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(W.Connections)
        if W.Blur then
            pcall(function()
                W.Blur:Destroy()
            end)
        end
        for Flag, El in pairs(W.Flags) do
            if Library.Options[Flag] == El then
                Library.Options[Flag] = nil
            end
        end
        Gui:Destroy()
    end

    function API:GetTheme()
        return Library.CurrentTheme
    end

    W.Fit(false)
    W.SetBackground(W.Config.Background)
    if type(W.Config.Transparency) == "number" then
        API:SetTransparency(W.Config.Transparency)
    end
    W.SetOpen(true)

    return API
end

return Library
