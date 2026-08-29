local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()

Library:AddTheme("Sunset", {
    Main = Color3.fromRGB(20, 12, 16),
    Accent = Color3.fromRGB(255, 106, 61),
    Card = Color3.fromRGB(28, 18, 22),
    Text = Color3.fromRGB(255, 244, 240),
    Stroke = Color3.fromRGB(255, 160, 120),
})

local Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "full featured",
    Logo = "rbxassetid://89646749075297",
    Color = Color3.fromRGB(179, 0, 255),
    Theme = "Dark",
    Size = UDim2.fromOffset(700, 500),
    AutoScale = true,
    AutoPosition = "Center",
    Blur = true,
    Version = "v2.1.3",
    Tag = "beta",
    FolderName = "sh1ttybanana",
    ConfigName = "default",
    AutoSave = true,
    AutoLoad = true,
    ToggleKey = Enum.KeyCode.RightShift,
    PaletteKey = Enum.KeyCode.K,
    ShowPlayerCard = true,
    ShowAI = true,
    ShowPalette = true,
    ShowTheme = true,
    ShowConfig = true,
    ShowKeybinds = true,
    ShowChangelog = false,
    ShowWatermark = true,
    Compact = false,
    Sound = false,
    Particles = true,
    GroqApiKey = nil,
    GroqPrompt = "You are a helpful assistant inside a Roblox script menu called sh1ttybanana.",
    GroqModel = "openai/gpt-oss-120b",
    PanicKey = Enum.KeyCode.End,
    -- Built-in key UI by default. To use your own:
    -- KeySystem = { Enabled = true, Custom = function(api)
    --   -- build UI on api.Gui, then api.Resolve(true, key) or api.Resolve(false)
    --   -- api.IsValid(key), api.SaveKey(key), api.Theme, api.Library, api.New
    -- end },
    KeySystem = {
        Enabled = true,
        Title = "sh1ttybanana",
        Note = "Verify Key to enjoy",
        Keys = { "FREE-KEY-1234", "TESTKEY" },
        GetKeyLink = "https://discord.gg/example",
        SaveKey = true,
        Changelog = {
            { Version = "v2.1.3", Date = os.date("%b %d, %Y"), Notes = {
                "Patriot-style key system",
                "RangeSlider, ToggleGroup, FilePicker",
                "ConfirmToggle, Hotbar",
                "Panic key + roles + unload cleanup",
                "Tab lock remember 10 minutes",
            }},
            { Version = "v2.1.0", Date = "Aug 2026", Notes = { "Mobile layout", "AI key field", "Search highlight" } },
        },
    },
})

local MainGroup = Window:Section({ Title = "Main", Opened = true })
local GeneralTab = MainGroup:Tab({ Title = "General", Icon = "layout-dashboard" })
local CombatTab = MainGroup:Tab({ Title = "Combat", Icon = "crosshair" })
local VisualTab = MainGroup:Tab({ Title = "Visual", Icon = "eye" })

local WorldGroup = Window:Section({ Title = "World", Opened = true })
local WorldTab = WorldGroup:Tab({ Title = "World", Icon = "globe" })
local MiscTab = WorldGroup:Tab({ Title = "Misc", Icon = "box" })

local SystemGroup = Window:Section({ Title = "System", Opened = true })
local SettingsTab = SystemGroup:Tab({ Title = "Settings", Icon = "settings" })
local DevTab = SystemGroup:Tab({
    Title = "Dev",
    Icon = "terminal",
    Lock = { Password = "1234", Title = "Developer Only", RememberMinutes = 10 },
})

local MovSec = GeneralTab:AddSection("Movement")
local InfoSec = GeneralTab:AddSection("Info")

MovSec:AddSlider({
    Title = "Walk Speed",
    Flag = "WalkSpeed",
    Min = 16, Max = 500, Increment = 1, Default = 16,
    Callback = function(v)
        print("WalkSpeed:", v)
    end,
})

MovSec:AddSlider({
    Title = "Jump Power",
    Flag = "JumpPower",
    Min = 7, Max = 500, Increment = 1, Default = 50,
    Callback = function(v)
        print("100 power")
    end,
})

MovSec:AddToggle({
    Title = "Noclip",
    Flag = "Noclip",
    Default = false,
    Callback = function(s)
        print("Noclip:", s)
    end,
})

MovSec:AddToggle({
    Title = "Fly",
    Flag = "Fly",
    Default = false,
    Callback = function(s)
        print("Fly:", s)
    end,
})

MovSec:AddKeybind({
    Title = "Fly Keybind",
    Flag = "FlyKey",
    Default = Enum.KeyCode.F,
    Mode = "Toggle",
    Callback = function(k)
        print("Key:", k)
    end,
})

MovSec:AddSeparator({ Title = "Danger Zone" })

MovSec:AddButton({
    Title = "Reset Character",
    Callback = function()
        Window:Dialog({
            Title = "Reset Character",
            Content = "This will respawn your character. Continue?",
            Buttons = {
                { Title = "Cancel" },
                { Title = "Reset", Accent = true, Callback = function()
                    print("Reset Character")
                end },
            },
        })
    end,
})

MovSec:AddInput({
    Title = "Nickname",
    Description = "Shown in chat commands",
    Flag = "Nickname",
    Placeholder = "Enter a nickname",
    MaxLength = 20,
    Clear = true,
    OnEnter = function(text)
        print("Nickname set:", text)
    end,
    Callback = function(text)
        print("Nickname changed:", text)
    end,
})

local SessionProg = InfoSec:AddProgress({ Title = "Session Time", Default = 0, Suffix = "%" })
task.spawn(function()
    local t = 0
    while task.wait(1) do
        t = math.min(t + 1, 100)
        SessionProg:Set(t)
    end
end)

InfoSec:AddTable({
    Title = "Game Info",
    Columns = { "Key", "Value" },
    Rows = {
        { "Place ID", "0000000000" },
        { "Username", "Player" },
        { "User ID", "0" },
    },
})

InfoSec:AddParagraph({
    Title = "About this tab",
    Content = "Movement and character tools live here.",
})

local AimSec = CombatTab:AddSection("Aimbot")
local SilentSec = CombatTab:AddSection("Silent Aim")

AimSec:AddToggle({
    Title = "Aimbot",
    Flag = "Aimbot",
    Default = false,
    Callback = function(s)
        print("Aimbot:", s)
    end,
})

AimSec:AddSlider({
    Title = "FOV",
    Flag = "AimFOV",
    Min = 10, Max = 800, Increment = 1, Default = 120,
    Callback = function(v)
        print("FOV:", v)
    end,
})

AimSec:AddDropdown({
    Title = "Target Part",
    Flag = "TargetPart",
    Options = { "Head", "HumanoidRootPart", "Torso" },
    Default = "Head",
    Callback = function(v)
        print("Target:", v)
    end,
})

AimSec:AddColorpicker({
    Title = "FOV Circle Color",
    Flag = "FOVColor",
    Default = Color3.fromRGB(255, 0, 80),
    Callback = function(c)
        print("Color:", c)
    end,
})

AimSec:AddKeybind({
    Title = "Hold to Aim",
    Flag = "AimKey",
    Default = Enum.KeyCode.Q,
    Mode = "Hold",
    Callback = function()
        print("Aiming")
    end,
    OnRelease = function()
        print("Stopped aiming")
    end,
})

AimSec:AddMultiButton({
    Title = "Quick Actions",
    Buttons = {
        { Title = "Reset FOV", Callback = function() print("Reset FOV") end },
        { Title = "Reset Target", Callback = function() print("Reset Target") end },
    },
})

SilentSec:AddToggle({
    Title = "Silent Aim",
    Flag = "SilentAim",
    Default = false,
    Callback = function(s)
        print("Silent:", s)
    end,
})

SilentSec:AddSlider({
    Title = "Prediction",
    Flag = "Prediction",
    Min = 0, Max = 100, Increment = 1, Default = 10,
    Callback = function(v)
        print("Pred:", v)
    end,
})

SilentSec:AddCodeblock({
    Title = "Silent Aim Notes",
    Code = "-- fires without rotating your camera",
    Copy = true,
})

local ESPSec = VisualTab:AddSection("ESP")

ESPSec:AddToggle({
    Title = "Player ESP",
    Flag = "PlayerESP",
    Default = false,
    Callback = function(s)
        print("ESP:", s)
    end,
})

ESPSec:AddToggle({
    Title = "Box ESP",
    Flag = "BoxESP",
    Default = false,
    Callback = function(s)
        print("BoxESP:", s)
    end,
})

ESPSec:AddColorpickerRGB({
    Title = "ESP Color",
    Flag = "ESPColor",
    Default = Color3.fromRGB(255, 60, 60),
    Callback = function(c)
        print("ESPCol:", c)
    end,
})

ESPSec:AddSlider({
    Title = "ESP Range",
    Flag = "ESPRange",
    Min = 50, Max = 2000, Increment = 50, Default = 500,
    Callback = function(v)
        print("Range:", v)
    end,
})

local AdvVisual = VisualTab:AddTabSection({ Title = "Advanced Visuals", Opened = false })

AdvVisual:AddToggle({
    Title = "Remove Fog",
    Flag = "RemoveFog",
    Default = false,
    Callback = function(s)
        print("RemoveFog:", s)
    end,
})

AdvVisual:AddSlider({
    Title = "Camera FOV",
    Flag = "CamFOV",
    Min = 60, Max = 120, Increment = 1, Default = 70,
    Callback = function(v)
        print("CamFOV:", v)
    end,
})

AdvVisual:AddGrid({
    Title = "Weapon Slots",
    Columns = 3,
    Height = 62,
    Items = {
        { Title = "Pistol", Icon = "crosshair", Callback = function() print("Pistol") end },
        { Title = "Rifle", Icon = "crosshair", Callback = function() print("Rifle") end },
        { Title = "Sniper", Icon = "crosshair", Callback = function() print("Sniper") end },
        { Title = "SMG", Icon = "crosshair", Callback = function() print("SMG") end },
        { Title = "Shotgun", Icon = "crosshair", Callback = function() print("Shotgun") end },
        { Title = "Knife", Icon = "crosshair", Callback = function() print("Knife") end },
    },
})

local DemoPart = Instance.new("Part")
DemoPart.Shape = Enum.PartType.Ball
DemoPart.Size = Vector3.new(4, 4, 4)
DemoPart.Color = Color3.fromRGB(179, 0, 255)
DemoPart.Material = Enum.Material.Neon

AdvVisual:AddImage({ Title = "Map Preview", Image = "rbxassetid://6894586021", Height = 100 })

AdvVisual:AddViewport({
    Title = "Item Preview",
    Description = "Drag to rotate",
    Object = DemoPart,
    Height = 160,
    Interactive = true,
})

AdvVisual:AddToggle({
    Title = "Restricted Feature",
    Description = "Requires elevated access",
    Locked = true,
    Default = false,
    Callback = function() end,
})

local WorldSec = WorldTab:AddSection("World")
local TpSec = WorldTab:AddSection("Teleport")

WorldSec:AddSlider({
    Title = "Global Speed",
    Flag = "GlobalSpeed",
    Min = 0, Max = 100, Increment = 1, Default = 16,
    Callback = function(v)
        print("GlobalSpeed:", v)
    end,
})

TpSec:AddInput({
    Title = "Teleport to Player",
    Placeholder = "Username",
    Clear = true,
    OnEnter = function(name)
        print("Teleport to:", name)
    end,
})

TpSec:AddButton({
    Title = "Teleport to Spawn",
    Callback = function()
        print("Teleport to Spawn")
    end,
})

local AntiSec = MiscTab:AddSection({ Title = "Anti", Lock = { Title = "Beta only" } })
local LogSec = MiscTab:AddSection("Logger")

AntiSec:AddToggle({
    Title = "Anti AFK",
    Flag = "AntiAFK",
    Default = true,
    Callback = function(s)
        print("AntiAFK:", s)
    end,
})

AntiSec:AddToggle({
    Title = "Anti Void",
    Flag = "AntiVoid",
    Default = false,
    Callback = function(s)
        print("AntiVoid:", s)
    end,
})

LogSec:AddToggle({
    Title = "Remote Spy",
    Flag = "RemoteSpy",
    Default = false,
    Callback = function(s)
        print("RemoteSpy:", s)
    end,
})

local UISec = SettingsTab:AddSection("UI")
local ConfigSec = SettingsTab:AddSection("Config")

UISec:AddButton({ Title = "Open Theme Panel", Callback = function() Window:ThemePanel() end })
UISec:AddButton({ Title = "Open Command Palette", Callback = function() Window:Palette() end })
UISec:AddButton({ Title = "Open Keybind Manager", Callback = function() Window:KeybindPanel() end })
UISec:AddSlider({
    Title = "Window Transparency",
    Min = 0, Max = 50, Increment = 1, Default = 3, Suffix = "%",
    Callback = function(v)
        Window:SetTransparency(v / 100)
    end,
})
UISec:AddKeybind({
    Title = "Toggle AI Assistant",
    Default = Enum.KeyCode.RightAlt,
    Callback = function()
        Window:ToggleAI()
    end,
})
UISec:AddKeybind({
    Title = "Toggle Player Card",
    Default = Enum.KeyCode.RightControl,
    Callback = function()
        Window:TogglePlayerCard()
    end,
})

ConfigSec:AddButton({ Title = "Open Config Manager", Callback = function() Window:ConfigPanel() end })
ConfigSec:AddButton({
    Title = "Save Current Config",
    Callback = function()
        Window:SaveConfig()
        Window:Notify({
            Title = "Saved",
            Content = "Config saved to file.",
            Type = "Success",
            Buttons = { { Text = "Open Manager", Callback = function() Window:ConfigPanel() end } },
        })
    end,
})
ConfigSec:AddButton({
    Title = "Load Legit Profile",
    Callback = function()
        if Window:LoadConfig("Legit") then
            Window:Notify({ Title = "Loaded", Content = "Legit profile loaded.", Type = "Info" })
        else
            Window:Notify({ Title = "Not Found", Content = "No Legit profile saved yet.", Type = "Warn" })
        end
    end,
})

local DemoSec = DevTab:AddSection("New Elements Demo")
local CodeSec = DevTab:AddSection("Codeblock")

local HpBar = DemoSec:AddProgress({ Title = "Player Health", Default = 100, Suffix = "%" })
task.spawn(function()
    local h = 100
    while task.wait(0.5) do
        h = h > 0 and h - 1 or 100
        HpBar:Set(h)
    end
end)

DemoSec:AddSpace(6)
DemoSec:AddTag({ Title = "Status", Value = "Stable" })
DemoSec:AddDivider()

DemoSec:AddMultiButton({
    Title = "Debug Actions",
    Buttons = {
        { Title = "Print Tabs", Callback = function() print(table.concat(Window:GetTabs(), ", ")) end },
        { Title = "Open Card", Callback = function() Window:TogglePlayerCard(true) end },
        { Title = "Show Changelog", Callback = function()
            Window:Changelog({
                Entries = {
                    { Version = "v2.1.0", Notes = {
                        "Mobile drawer sidebar (no size lock)",
                        "Configurable topbar icons",
                        "AI panel drag + API key textbox",
                        "Default themes: Dark, Liquid Glass",
                        "Tighter mobile spacing",
                    }},
                    { Version = "v2.0.0", Notes = {
                        "Rebuilt component API",
                        "Added Liquid Glass theme",
                        "Added config profiles",
                    }},
                    { Version = "v1.0.0", Notes = { "Initial release" } },
                },
            })
        end },
    },
})

local LockedInput = CodeSec:AddInput({
    Title = "Admin Command",
    Locked = true,
    Placeholder = "Locked until unlocked programmatically",
})

CodeSec:AddCodeblock({
    Title = "Example Code",
    Code = 'print("example")',
    Copy = true,
})

local ToolsSection = DevTab:AddTabSection({ Title = "More Tools", Opened = false })

ToolsSection:AddButton({
    Title = "Jump to Combat Tab",
    Callback = function()
        Window:SelectTab("Combat")
    end,
})

ToolsSection:AddButton({
    Title = "Unlock Admin Command",
    Callback = function()
        LockedInput:SetLocked(false)
        Window:Notify({ Title = "Unlocked", Content = "Admin Command is now editable.", Type = "Success" })
    end,
})

ToolsSection:AddButton({
    Title = "Prompt Example",
    Callback = function()
        Window:Prompt({
            Title = "Enter a value",
            Placeholder = "Type something",
            Confirm = "Submit",
            Callback = function(text)
                print("Prompted:", text)
            end,
        })
    end,
})

ToolsSection:AddButton({
    Title = "Add a Key at Runtime",
    Callback = function()
        Window:AddKey("RUNTIME-KEY-9999")
        Window:Notify({ Title = "Key System", Content = "Added RUNTIME-KEY-9999 as a valid key.", Type = "Info" })
    end,
})

ToolsSection:AddButton({
    Title = "Run SelfTest",
    Callback = function()
        Window:SelfTest()
    end,
})

ToolsSection:AddButton({
    Title = "Clear Groq Key",
    Callback = function()
        Window:ClearGroqKey()
        Window:Notify({ Title = "Groq", Content = "API key cleared", Type = "Info" })
    end,
})

ToolsSection:AddButton({
    Title = "Check a Key",
    Callback = function()
        print("Is 'TESTKEY' valid?", Window:CheckKey("TESTKEY"))
    end,
})

task.delay(1, function()
    Window:Notify({
        Title = "Welcome!",
        Content = "sh1ttybanana v2.1.2 loaded. Dev tab password: 1234 (remembers 10 min)",
        Type = "Success",
        Duration = 6,
    })
end)
