--[[
  NexxWare SB V0.1 — full example
  author: nexxzel
  base: kingrua
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()
-- or: local Library = loadfile("sh1ttybanana.lua")()

local Window = Library:NewWindow({
    Title = "NexxWare",
    Description = "SB full demo",
    Version = "V0.1 Alpha",
    Theme = "Liquid Glass", -- or "Fluid Glass Black"
    Size = UDim2.fromOffset(720, 520),
    WatermarkText = "NexxWare SB V0.1",
    ShowWatermark = true,
    ShowAI = true,
    ShowPlayerCard = true,
    DockPanels = true,
    ShowChangelog = false,
    SafeArea = false,
    NotifyMax = 4,
    PanicKey = Enum.KeyCode.End,
    KeySystem = {
        Enabled = false, -- set true + Keys / Custom to test gate
        Title = "NexxWare",
        Note = "Verify Key to enjoy",
        Keys = { "FREE-KEY-1234" },
        GetKeyLink = "https://discord.gg/example",
        Changelog = {
            { Version = "V0.1", Date = "2026", Notes = { "Liquid Glass", "Fluid Glass Black", "All components" } },
        },
    },
    AdvancedTheme = {
        -- Neutral = Color3.fromRGB(200, 200, 210),
        -- TabText = Color3.fromRGB(235, 235, 245),
        -- Accent = Color3.fromRGB(198, 108, 255),
    },
})

-- ═══════════════════════════════════════
-- BUTTONS
-- ═══════════════════════════════════════
local ButtonsTab = Window:Tab({ Title = "Buttons", Icon = "mouse-pointer-click" })

local NormalSec = ButtonsTab:AddSection("Normal Button")
NormalSec:AddButton({
    Title = "Primary action",
    Description = "Cooldown 1s example",
    Cooldown = 1,
    Callback = function()
        Window:Notify({ Title = "Button", Content = "clicked", Type = "Success" })
    end,
})
NormalSec:AddButton({
    Title = "About modal",
    Callback = function()
        Window:About()
    end,
})

local MultiSec = ButtonsTab:AddSection("Multibutton")
MultiSec:AddMultiButton({
    Title = "Quick actions",
    Buttons = {
        { Title = "A", Callback = function() print("A") end },
        { Title = "B", Accent = true, Callback = function() print("B") end },
        { Title = "C", Callback = function() print("C") end },
    },
})
MultiSec:AddHotbar({
    Title = "Icon hotbar",
    Items = {
        { Icon = "lucide:sparkles", Tip = "Sparkle", Callback = function() print("sparkle") end },
        { Icon = "gravity:ban", Tip = "Ban (gravity)", Callback = function() print("ban") end },
        { Icon = "refresh-cw", Tip = "Refresh", Callback = function() print("refresh") end },
    },
})

-- ═══════════════════════════════════════
-- INPUTS
-- ═══════════════════════════════════════
local InputsTab = Window:Tab({ Title = "Inputs", Icon = "keyboard" })

local ToggleSec = InputsTab:AddSection("Toggles")
ToggleSec:AddToggle({
    Title = "Enable feature",
    Description = "Standard toggle",
    Flag = "FeatOn",
    Default = false,
    Callback = function(v) print("toggle", v) end,
})
ToggleSec:AddConfirmToggle({
    Title = "Dangerous flag",
    Description = "Confirms before ON",
    ConfirmOn = true,
    ConfirmTitle = "Enable?",
    ConfirmContent = "This is destructive.",
    Flag = "Danger",
    Callback = function(v) print("confirm", v) end,
})
ToggleSec:AddToggleGroup({
    Title = "Mode",
    Options = { "Legit", "Rage", "Silent" },
    Default = "Legit",
    Flag = "Mode",
    Callback = function(v) print("mode", v) end,
})

local SliderSec = InputsTab:AddSection("Sliders")
SliderSec:AddSlider({
    Title = "WalkSpeed",
    Min = 0, Max = 100, Default = 16, Increment = 1,
    Flag = "WalkSpeed",
    Callback = function(v) print("speed", v) end,
})
SliderSec:AddRangeSlider({
    Title = "FOV band",
    Min = 10, Max = 500, Default = { 70, 120 }, Increment = 5,
    Flag = "FovBand",
    Callback = function(v) print("range", v[1], v[2]) end,
})
SliderSec:AddProgress({ Title = "Load", Default = 0.42, Flag = "LoadPct" })

local FieldSec = InputsTab:AddSection("Fields")
FieldSec:AddInput({
    Title = "Nickname",
    Placeholder = "Enter name",
    Flag = "Nick",
    Callback = function(t) print("nick", t) end,
})
FieldSec:AddKeybind({
    Title = "Panic bind",
    Default = Enum.KeyCode.End,
    Flag = "PanicBind",
    Callback = function() print("key") end,
})
FieldSec:AddDropdown({
    Title = "Weapon",
    Options = { "Pistol", "Rifle", "Sniper", "SMG", "Shotgun" },
    Default = "Rifle",
    Search = true,
    Flag = "Weapon",
    Callback = function(v) print("weapon", v) end,
})
FieldSec:AddPlayerSelector({
    Title = "Target",
    Flag = "Target",
    Callback = function(name) print("target", name) end,
})

-- ═══════════════════════════════════════
-- COLORS / MEDIA
-- ═══════════════════════════════════════
local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })

local ColorSec = VisualTab:AddSection("Colors")
ColorSec:AddColorpicker({
    Title = "Accent pick",
    Default = Color3.fromRGB(198, 108, 255),
    Flag = "AccentPick",
    Callback = function(c) print("color", c) end,
})
ColorSec:AddColorpickerRGB({
    Title = "ESP Color",
    Default = Color3.fromRGB(255, 80, 120),
    Flag = "EspColor",
    Callback = function(c) print("rgb", c) end,
})

local MediaSec = VisualTab:AddSection("Media")
MediaSec:AddImage({
    Title = "Banner",
    Image = "rbxassetid://89646749075297",
    Height = 100,
})
MediaSec:AddViewport({
    Title = "Item Preview",
    Description = "Drag to rotate",
    Height = 140,
})
MediaSec:AddGrid({
    Title = "Weapon Slots",
    Columns = 3,
    Height = 64,
    Items = {
        { Title = "Pistol", Icon = "lucide:crosshair", Callback = function() print("pistol") end },
        { Title = "Rifle", Icon = "gravity:ban", Callback = function() print("rifle") end },
        { Title = "Sniper", Icon = "lucide:focus", Callback = function() print("sniper") end },
        { Title = "SMG", Icon = "lucide:zap", Callback = function() print("smg") end },
        { Title = "Shotgun", Icon = "lucide:flame", Callback = function() print("shotgun") end },
        { Title = "Knife", Icon = "lucide:sword", Callback = function() print("knife") end },
    },
})

-- ═══════════════════════════════════════
-- DATA / TEXT
-- ═══════════════════════════════════════
local DataTab = Window:Tab({ Title = "Data", Icon = "table" })

local TableSec = DataTab:AddSection("Table & tags")
TableSec:AddTable({
    Title = "Game Info",
    Columns = { "Key", "Value" },
    Rows = {
        { "PlaceId", tostring(game.PlaceId) },
        { "User", game.Players.LocalPlayer.Name },
        { "Theme", "Liquid Glass" },
    },
})
TableSec:AddTag({
    Title = "Channel",
    Name = "Beta",
    Icon = "lucide:sparkles",
    Color = Color3.fromRGB(255, 180, 60),
})
TableSec:AddLabel({ Title = "Plain label", Icon = "lucide:info" })
TableSec:AddParagraph({
    Title = "About this tab",
    Content = "Tables, tags, labels, paragraphs, and code live here.",
})

local CodeSec = DataTab:AddSection("Codeblock")
CodeSec:AddCodeblock({
    Title = "Example",
    Code = 'print("NexxWare SB V0.1")\nlocal x = 1 + 2\nreturn x',
    Copy = true,
})
CodeSec:AddLogConsole({
    Title = "Console",
    Height = 110,
})
CodeSec:AddFilePicker({
    Title = "Configs",
    Extension = ".json",
    Callback = function(n) print("file", n) end,
})

-- ═══════════════════════════════════════
-- ICONS DEMO
-- ═══════════════════════════════════════
local IconsTab = Window:Tab({ Title = "Icons", Icon = "lucide:sparkles" })
local LucideSec = IconsTab:AddSection("Lucide (default)")
LucideSec:AddButton({ Title = "lucide:home", Icon = "lucide:home", Callback = function() end })
LucideSec:AddButton({ Title = "bare name → lucide", Icon = "settings", Callback = function() end })
local GravSec = IconsTab:AddSection("Gravity")
GravSec:AddButton({ Title = "gravity:ban", Icon = "gravity:ban", Callback = function() end })
GravSec:AddButton({ Title = "gravity:alarm", Icon = "gravity:alarm", Callback = function() end })
GravSec:AddHotbar({
    Title = "Mix",
    Items = {
        { Icon = "lucide:star", Tip = "Lucide star" },
        { Icon = "gravity:archive", Tip = "Gravity archive" },
        { Icon = "bot", Tip = "Bare lucide bot" },
    },
})

-- ═══════════════════════════════════════
-- SYSTEM
-- ═══════════════════════════════════════
local SystemTab = Window:Tab({ Title = "System", Icon = "settings" })
local SysSec = SystemTab:AddSection("Tools")
SysSec:AddButton({
    Title = "SelfTest",
    Callback = function() Window:SelfTest() end,
})
SysSec:AddButton({
    Title = "Panic",
    Callback = function() Window:Panic(true) end,
})
SysSec:AddButton({
    Title = "Theme → Fluid Glass Black",
    Callback = function() Window:SetTheme("Fluid Glass Black") end,
})
SysSec:AddButton({
    Title = "Theme → Liquid Glass",
    Callback = function() Window:SetTheme("Liquid Glass") end,
})
SysSec:AddSeparator({ Title = "Layout" })
SysSec:AddButton({
    Title = "Notify test",
    Callback = function()
        Window:Notify({ Title = "NexxWare", Content = "Hello from SB V0.1", Type = "Info" })
    end,
})

local DevTab = Window:Tab({
    Title = "Dev",
    Icon = "terminal",
    Lock = { Password = "1234", Title = "Dev only", RememberMinutes = 10 },
})
DevTab:AddSection("Locked area"):AddParagraph({
    Title = "Unlocked",
    Content = "Password 1234 · remembers 10 minutes",
})

print("NexxWare SB V0.1 example loaded")
