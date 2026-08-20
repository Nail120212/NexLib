local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()

Library:SetGroq(
    "gsk_YOUR_GROQ_KEY_HERE",
    "You are a helpful assistant inside a Roblox script menu called sh1ttybanana. Use [[tab:TabName]] to link to a tab.",
    "openai/gpt-oss-120b"
)

Library:AddTheme("Ocean", {
    Main = Color3.fromRGB(8, 14, 20),
    Accent = Color3.fromRGB(0, 170, 255),
    Background = Color3.fromRGB(16, 24, 32),
    Elevated = Color3.fromRGB(6, 10, 14),
    Secondary = Color3.fromRGB(20, 30, 40),
})

local Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "full featured",
    Logo = "rbxassetid://89646749075297",
    Color = Color3.fromRGB(179, 0, 255),
    Size = UDim2.new(0, 620, 0, 420),
    Transparent = 0.07,
    Version = "v1.1",
    Changelog = {
        { Version = "v1.1", Notes = { "Added custom theme support", "Added changelog popup", "Discord-style AI chat", "Fixed colorpicker accuracy", "Fixed window drag snapping back" } },
        { Version = "v1.0", Notes = { "Initial release" } },
    },
})

Window:Tag({ Title = "v1.1", Color = Color3.fromRGB(255, 165, 0) })
Window:Tag({ Title = "beta", Color = Color3.fromRGB(50, 180, 100) })

local lp = game:GetService("Players").LocalPlayer
local lighting = game:GetService("Lighting")

local function getHum()
    return lp.Character and lp.Character:FindFirstChild("Humanoid")
end

local MainGroup = Window:Section({ Title = "Main", Opened = true })
local GeneralTab = MainGroup:T({ Title = "General", Icon = "layout-dashboard" })
local CombatTab = MainGroup:T({ Title = "Combat", Icon = "crosshair" })
local VisualTab = MainGroup:T({ Title = "Visual", Icon = "eye" })

local WorldGroup = Window:Section({ Title = "World", Opened = true })
local WorldTab = WorldGroup:T({ Title = "World", Icon = "globe" })
local MiscTab = WorldGroup:T({ Title = "Misc", Icon = "box" })

local SystemGroup = Window:Section({ Title = "System", Opened = true })
local SettingsTab = SystemGroup:T({ Title = "Settings", Icon = "settings" })
local DevTab = SystemGroup:T({
    Title = "Dev",
    Icon = "terminal",
    Locked = true,
    LockPassword = "1234",
    LockTitle = "Developer Only",
    LockDesc = "Password: 1234",
})

local MovSec = GeneralTab:AddSection("Movement")
local InfoSec = GeneralTab:AddSection("Info")

MovSec:AddSlider({
    Title = "Walk Speed",
    Min = 16, Max = 500, Increment = 1, Default = 16,
    Callback = function(v)
        local h = getHum()
        if h then h.WalkSpeed = v end
    end,
})

MovSec:AddSlider({
    Title = "Jump Power",
    Min = 7, Max = 500, Increment = 1, Default = 50,
    Callback = function(v)
        local h = getHum()
        if h then h.JumpPower = v end
    end,
})

MovSec:AddToggle({ Title = "Noclip", Default = false, Callback = function(s) print("Noclip:", s) end })
MovSec:AddToggle({ Title = "Fly", Default = false, Callback = function(s) print("Fly:", s) end })
MovSec:AddKeybind({ Title = "Fly Keybind", Default = Enum.KeyCode.F, Callback = function(k) print("Key:", k.Name) end })
MovSec:AddSeperator({ Title = "Danger Zone" })

MovSec:AddButton({
    Title = "Reset Character",
    Callback = function()
        Window:Dialog({
            Title = "Reset Character",
            Content = "This will respawn your character. Continue?",
            Buttons = {
                { Title = "Cancel", Variant = "Secondary" },
                { Title = "Reset", Variant = "Primary", Callback = function()
                    local h = getHum()
                    if h then h.Health = 0 end
                end },
            },
        })
    end,
})

local sessionProg = InfoSec:AddProgress({ Title = "Session Time", Value = 0, Max = 3600 })
local sessionStart = os.time()
task.spawn(function()
    while task.wait(1) do
        sessionProg:Set(math.min(os.time() - sessionStart, 3600))
    end
end)

InfoSec:AddTable({
    Title = "Game Info",
    Headers = { "Key", "Value" },
    Rows = {
        { "Place ID", tostring(game.PlaceId) },
        { "Username", lp.Name },
        { "User ID", tostring(lp.UserId) },
    },
})

InfoSec:AddParagraph({
    Title = "About this tab",
    Content = "Movement and character tools live here.",
})

local AimSec = CombatTab:AddSection("Aimbot")
local SilentSec = CombatTab:AddSection("Silent Aim")

AimSec:AddToggle({ Title = "Aimbot", Default = false, Callback = function(s) print("Aimbot:", s) end })
AimSec:AddSlider({ Title = "FOV", Min = 10, Max = 800, Increment = 1, Default = 120, Callback = function(v) print("FOV:", v) end })
AimSec:AddDropdown({
    Title = "Target Part",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Default = "Head",
    Callback = function(v) print("Target:", v) end,
})
AimSec:AddColorpicker({ Title = "FOV Circle Color", Default = Color3.fromRGB(255, 0, 80), Callback = function(c) print("Color:", c) end })
AimSec:AddKeybind({ Title = "Hold to Aim", Default = Enum.KeyCode.Q, Callback = function(k) print("Aim key:", k.Name) end })
AimSec:AddMultiButton({
    Title = "Quick Actions",
    Buttons = {
        { Title = "Reset FOV", Callback = function() print("Reset FOV") end },
        { Title = "Reset Target", Callback = function() print("Reset Target") end },
    },
})

SilentSec:AddToggle({ Title = "Silent Aim", Default = false, Callback = function(s) print("Silent:", s) end })
SilentSec:AddSlider({ Title = "Prediction", Min = 0, Max = 100, Increment = 1, Default = 10, Callback = function(v) print("Pred:", v) end })
SilentSec:AddCodeblock({
    Title = "Silent Aim Notes",
    Language = "lua",
    Code = "-- fires without rotating your camera",
})

local ESPSec = VisualTab:AddSection("ESP")

ESPSec:AddToggle({ Title = "Player ESP", Default = false, Callback = function(s) print("ESP:", s) end })
ESPSec:AddToggle({ Title = "Box ESP", Default = false, Callback = function(s) print("BoxESP:", s) end })
ESPSec:AddColorpicker({ Title = "ESP Color", Default = Color3.fromRGB(255, 60, 60), Callback = function(c) print("ESPCol:", c) end })
ESPSec:AddSlider({ Title = "ESP Range", Min = 50, Max = 2000, Increment = 50, Default = 500, Callback = function(v) print("Range:", v) end })

local AdvVisual = VisualTab:AddTabSection({ Title = "Advanced Visuals", Opened = false })

AdvVisual:AddToggle({
    Title = "Remove Fog",
    Default = false,
    Callback = function(s) lighting.FogEnd = s and 100000 or 1000 end,
})

AdvVisual:AddSlider({
    Title = "Camera FOV",
    Min = 60, Max = 120, Increment = 1, Default = 70,
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end,
})

AdvVisual:AddGrid({
    Title = "Weapon Slots",
    Items = { "Pistol", "Rifle", "Sniper", "SMG", "Shotgun", "Knife" },
    Columns = 3,
    Default = { "Pistol", "Knife" },
    Callback = function(sel) print("Selected:", table.concat(sel, ", ")) end,
})

AdvVisual:AddImage({ Title = "Map Preview", Asset = "rbxassetid://6894586021", Height = 100, Rounded = true })

local WorldSec = WorldTab:AddSection("World")
local TpSec = WorldTab:AddSection("Teleport")

WorldSec:AddSlider({
    Title = "Global Speed",
    Min = 0, Max = 100, Increment = 1, Default = 16,
    Callback = function(v)
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Humanoid") then
                p.Character.Humanoid.WalkSpeed = v
            end
        end
    end,
})

WorldSec:AddColorpickerRGB({
    Title = "Ambient Color",
    Default = Color3.fromRGB(70, 70, 70),
    Callback = function(c) lighting.Ambient = c end,
})

TpSec:AddInput({
    Title = "Teleport to Player",
    PlaceHolder = "Username",
    Callback = function(name)
        local t = game.Players:FindFirstChild(name)
        local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and root then
            root.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end,
})

TpSec:AddButton({
    Title = "Teleport to Spawn",
    Callback = function()
        local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(0, 10, 0) end
    end,
})

local AntiSec = MiscTab:AddSection("Anti")
local LogSec = MiscTab:AddSection("Logger")

AntiSec:AddToggle({ Title = "Anti AFK", Default = true, Callback = function(s) print("AntiAFK:", s) end })
AntiSec:AddToggle({ Title = "Anti Void", Default = false, Callback = function(s) print("AntiVoid:", s) end })
LogSec:AddToggle({ Title = "Remote Spy", Default = false, Callback = function(s) print("RemoteSpy:", s) end })

local UISec = SettingsTab:AddSection("UI")
local ConfigSec = SettingsTab:AddSection("Config")

UISec:AddColorpicker({
    Title = "Accent Color",
    Default = Color3.fromRGB(179, 0, 255),
    Callback = function(c) Library.Theme.Accent = c end,
})

UISec:AddSlider({
    Title = "Window Transparency",
    Min = 0, Max = 50, Increment = 1, Default = 7, Suffix = "%",
    Callback = function(v) Window:SetTransparency(v / 100) end,
})

UISec:AddKeybind({ Title = "Toggle UI", Default = Enum.KeyCode.RightShift, Callback = function() Window:Toggle() end })
UISec:AddKeybind({ Title = "Toggle AI Assistant", Default = Enum.KeyCode.RightAlt, Callback = function() Window:ToggleAI() end })
UISec:AddKeybind({ Title = "Toggle Player Card", Default = Enum.KeyCode.RightControl, Callback = function() Window:TogglePlayerCard() end })

ConfigSec:AddInput({ Title = "Config Name", PlaceHolder = "my_config", Default = "sh1ttybanana_v1", Callback = function(v) print("Config:", v) end })

ConfigSec:AddButton({
    Title = "Save Config",
    Callback = function()
        Window:SaveConfig(Window:GetFlag("ConfigName") or "sh1ttybanana_v1")
        Window:Notify({ Title = "Saved!", Content = "Config saved to file.", Type = "Success", Duration = 3 })
    end,
})

ConfigSec:AddButton({
    Title = "Load Config",
    Callback = function()
        Window:LoadConfig(Window:GetFlag("ConfigName") or "sh1ttybanana_v1")
        Window:Notify({ Title = "Loaded!", Content = "Config loaded from file.", Type = "Info", Duration = 3 })
    end,
})

local DemoSec = DevTab:AddSection("New Elements Demo")
local CodeSec = DevTab:AddSection("Codeblock")

local hpBar = DemoSec:AddProgress({ Title = "Player Health", Value = 100, Max = 100 })
task.spawn(function()
    while task.wait(0.5) do
        local h = getHum()
        if h then hpBar:Set(h.Health) end
    end
end)

DemoSec:AddSpace(6)
DemoSec:AddTag({ Title = "Stable", Color = Color3.fromRGB(48, 255, 106) })
DemoSec:AddDivider()

DemoSec:AddMultiButton({
    Title = "Debug Actions",
    Buttons = {
        { Title = "Print Tabs", Callback = function() print(table.concat(Window:GetTabs(), ", ")) end },
        { Title = "Open Card", Callback = function() Window:TogglePlayerCard(true) end },
    },
})

CodeSec:AddCodeblock({
    Title = "Kill Self",
    Language = "lua",
    Code = 'local h = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")\nif h then h.Health = 0 end',
    Callback = function(code)
        local fn, err = loadstring(code)
        if fn then fn() else print("Error:", err) end
    end,
})

local ToolsSection = DevTab:AddTabSection({ Title = "More Tools", Opened = false })

ToolsSection:AddButton({ Title = "Jump to Combat Tab", Callback = function() Window:SelectTab("Combat") end })
ToolsSection:AddButton({ Title = "Show Changelog", Callback = function() Window:Changelog() end })

task.delay(1, function()
    Window:Notify({
        Title = "Welcome!",
        Content = "sh1ttybanana loaded. Dev tab password: 1234",
        Type = "Success",
        Duration = 6,
    })
end)
