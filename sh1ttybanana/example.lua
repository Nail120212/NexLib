--[[
  NexxWare SB V0.1 example
  Author: nexxzel
  One section per component
]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"
))()

local Window = Library:NewWindow({
    Title = "NexxWare",
    Description = "by nexxzel · SB V0.1",
    Version = "V0.1 Alpha",
    Theme = "Liquid Glass",
    Size = UDim2.fromOffset(720, 520),
    WatermarkText = "NexxWare SB V0.1",
    ShowWatermark = true,
    ShowAI = true,
    ShowPlayerCard = true,
    DockPanels = true,
    ShowChangelog = false,
    PanicKey = Enum.KeyCode.End,
    KeySystem = { Enabled = false },
})

-- ───────────── BUTTONS ─────────────
local Buttons = Window:Tab({ Title = "Buttons", Icon = "mouse-pointer-click" })

local SecButton = Buttons:AddSection("Button")
SecButton:AddButton({
    Title = "Normal Button",
    Description = "Single action row",
    Cooldown = 0.5,
    Callback = function()
        Window:Notify({ Title = "Button", Content = "clicked", Type = "Success" })
    end,
})

local SecMulti = Buttons:AddSection("MultiButton")
SecMulti:AddMultiButton({
    Title = "MultiButton",
    Description = "Two on top (half) · one full width below",
    Buttons = {
        { Title = "One", Callback = function() print("one") end },
        { Title = "Two", Accent = true, Callback = function() print("two") end },
        { Title = "Three", Callback = function() print("three") end },
    },
})

local SecHotbar = Buttons:AddSection("Hotbar")
SecHotbar:AddHotbar({
    Title = "Hotbar",
    Items = {
        { Icon = "lucide:sparkles", Tip = "Lucide", Callback = function() print("sparkles") end },
        { Icon = "gravity:ban", Tip = "Gravity", Callback = function() print("ban") end },
        { Icon = "refresh-cw", Tip = "Bare lucide", Callback = function() print("refresh") end },
    },
})

local SecConfirm = Buttons:AddSection("ConfirmToggle")
SecConfirm:AddConfirmToggle({
    Title = "ConfirmToggle",
    Description = "Asks before enabling",
    ConfirmOn = true,
    ConfirmTitle = "Enable?",
    ConfirmContent = "Are you sure?",
    Flag = "ConfirmDemo",
    Callback = function(v) print("confirm", v) end,
})

-- ───────────── TOGGLES ─────────────
local Toggles = Window:Tab({ Title = "Toggles", Icon = "toggle-left" })

local SecToggle = Toggles:AddSection("Toggle")
SecToggle:AddToggle({
    Title = "Toggle",
    Description = "On / off",
    Flag = "ToggleDemo",
    Default = false,
    Callback = function(v) print("toggle", v) end,
})

local SecGroup = Toggles:AddSection("ToggleGroup")
SecGroup:AddToggleGroup({
    Title = "ToggleGroup",
    Options = { "Legit", "Rage", "Silent" },
    Default = "Legit",
    Flag = "ModeDemo",
    Callback = function(v) print("group", v) end,
})

-- ───────────── SLIDERS ─────────────
local Sliders = Window:Tab({ Title = "Sliders", Icon = "sliders-horizontal" })

local SecSlider = Sliders:AddSection("Slider")
SecSlider:AddSlider({
    Title = "Slider",
    Min = 0, Max = 100, Default = 25, Increment = 1,
    Flag = "SliderDemo",
    Callback = function(v) print("slider", v) end,
})

local SecRange = Sliders:AddSection("RangeSlider")
SecRange:AddRangeSlider({
    Title = "RangeSlider",
    Min = 0, Max = 200, Default = { 40, 120 }, Increment = 5,
    Flag = "RangeDemo",
    Callback = function(v) print("range", v[1], v[2]) end,
})

local SecProg = Sliders:AddSection("Progress")
SecProg:AddProgress({
    Title = "Progress",
    Default = 0.65,
    Flag = "ProgressDemo",
})

-- ───────────── FIELDS ─────────────
local Fields = Window:Tab({ Title = "Fields", Icon = "keyboard" })

local SecInput = Fields:AddSection("Input")
SecInput:AddInput({
    Title = "Input",
    Placeholder = "Type here",
    Flag = "InputDemo",
    Callback = function(t) print("input", t) end,
})

local SecKeybind = Fields:AddSection("Keybind")
SecKeybind:AddKeybind({
    Title = "Keybind",
    Default = Enum.KeyCode.Q,
    Flag = "KeyDemo",
    Callback = function() print("keybind") end,
})

local SecDropdown = Fields:AddSection("Dropdown")
SecDropdown:AddDropdown({
    Title = "Dropdown",
    Options = { "Alpha", "Beta", "Gamma", "Delta" },
    Default = "Beta",
    Search = true,
    Flag = "DropDemo",
    Callback = function(v) print("dropdown", v) end,
})

local SecPlayer = Fields:AddSection("PlayerSelector")
SecPlayer:AddPlayerSelector({
    Title = "PlayerSelector",
    Flag = "PlayerDemo",
    Callback = function(name) print("player", name) end,
})

-- ───────────── COLORS ─────────────
local Colors = Window:Tab({ Title = "Colors", Icon = "palette" })

local SecCP = Colors:AddSection("Colorpicker")
SecCP:AddColorpicker({
    Title = "Colorpicker",
    Default = Color3.fromRGB(198, 108, 255),
    Flag = "ColorDemo",
    Callback = function(c) print("color", c) end,
})

local SecRGB = Colors:AddSection("ColorpickerRGB")
SecRGB:AddColorpickerRGB({
    Title = "ColorpickerRGB",
    Default = Color3.fromRGB(255, 80, 120),
    Flag = "RgbDemo",
    Callback = function(c) print("rgb", c) end,
})

-- ───────────── MEDIA ─────────────
local Media = Window:Tab({ Title = "Media", Icon = "image" })

local SecImage = Media:AddSection("Image")
SecImage:AddImage({
    Title = "Image",
    Image = "rbxassetid://89646749075297",
    Height = 110,
})

local SecView = Media:AddSection("Viewport")
SecView:AddViewport({
    Title = "Viewport",
    Description = "Drag to rotate",
    Height = 150,
})

local SecGrid = Media:AddSection("Grid")
SecGrid:AddGrid({
    Title = "Grid",
    Columns = 3,
    Height = 64,
    Items = {
        { Title = "A", Icon = "lucide:star", Callback = function() print("A") end },
        { Title = "B", Icon = "gravity:ban", Callback = function() print("B") end },
        { Title = "C", Icon = "lucide:zap", Callback = function() print("C") end },
        { Title = "D", Icon = "lucide:flame", Callback = function() print("D") end },
        { Title = "E", Icon = "lucide:focus", Callback = function() print("E") end },
        { Title = "F", Icon = "sword", Callback = function() print("F") end },
    },
})

-- ───────────── TEXT / DATA ─────────────
local Data = Window:Tab({ Title = "Data", Icon = "table" })

local SecTable = Data:AddSection("Table")
SecTable:AddTable({
    Title = "Table",
    Columns = { "Key", "Value" },
    Rows = {
        { "Author", "nexxzel" },
        { "Lib", "sh1ttybanana" },
        { "Version", "V0.1 Alpha" },
    },
})

local SecTag = Data:AddSection("Tag")
SecTag:AddTag({
    Title = "Tag",
    Name = "Beta",
    Icon = "lucide:sparkles",
    Color = Color3.fromRGB(255, 180, 60),
})

local SecLabel = Data:AddSection("Label")
SecLabel:AddLabel({
    Title = "Label",
    Icon = "lucide:info",
})

local SecPara = Data:AddSection("Paragraph")
SecPara:AddParagraph({
    Title = "Paragraph",
    Content = "Longer text block for descriptions and notes.",
})

local SecCode = Data:AddSection("Codeblock")
SecCode:AddCodeblock({
    Title = "Codeblock",
    Code = 'print("nexxzel")\nlocal n = 1 + 2\nreturn n',
    Copy = true,
})

local SecLog = Data:AddSection("LogConsole")
SecLog:AddLogConsole({
    Title = "LogConsole",
    Height = 120,
})

local SecFile = Data:AddSection("FilePicker")
SecFile:AddFilePicker({
    Title = "FilePicker",
    Extension = ".json",
    Callback = function(n) print("file", n) end,
})

local SecSep = Data:AddSection("Separator / Divider / Space")
SecSep:AddSeparator({ Title = "Separator" })
SecSep:AddDivider()
SecSep:AddSpace({ Height = 12 })

-- ───────────── ICONS ─────────────
local Icons = Window:Tab({ Title = "Icons", Icon = "lucide:sparkles" })

local SecLucide = Icons:AddSection("Lucide")
SecLucide:AddButton({ Title = "lucide:home", Icon = "lucide:home", Callback = function() end })
SecLucide:AddButton({ Title = "settings (bare → lucide)", Icon = "settings", Callback = function() end })

local SecGrav = Icons:AddSection("Gravity")
SecGrav:AddButton({ Title = "gravity:ban", Icon = "gravity:ban", Callback = function() end })
SecGrav:AddButton({ Title = "gravity:alarm", Icon = "gravity:alarm", Callback = function() end })
SecGrav:AddHotbar({
    Title = "Mixed icons",
    Items = {
        { Icon = "lucide:star", Tip = "lucide star" },
        { Icon = "gravity:archive", Tip = "gravity archive" },
        { Icon = "bot", Tip = "bare lucide bot" },
    },
})

-- ───────────── SYSTEM ─────────────
local System = Window:Tab({ Title = "System", Icon = "settings" })

local SecTheme = System:AddSection("Theme")
SecTheme:AddButton({
    Title = "Liquid Glass",
    Callback = function() Window:SetTheme("Liquid Glass") end,
})
SecTheme:AddButton({
    Title = "Fluid Glass Black",
    Callback = function() Window:SetTheme("Fluid Glass Black") end,
})

local SecTools = System:AddSection("Tools")
SecTools:AddButton({
    Title = "About",
    Callback = function() Window:About() end,
})
SecTools:AddButton({
    Title = "SelfTest",
    Callback = function() Window:SelfTest() end,
})
SecTools:AddButton({
    Title = "Notify",
    Callback = function()
        Window:Notify({ Title = "NexxWare", Content = "by nexxzel", Type = "Info" })
    end,
})
SecTools:AddButton({
    Title = "Panic",
    Callback = function() Window:Panic(true) end,
})

local Dev = Window:Tab({
    Title = "Dev",
    Icon = "terminal",
    Lock = { Password = "1234", Title = "Dev only", RememberMinutes = 10 },
})
local SecDev = Dev:AddSection("Locked")
SecDev:AddParagraph({
    Title = "Dev tab",
    Content = "Password: 1234 · remember 10 minutes",
})

print("[nexxzel] NexxWare SB V0.1 example ready")
