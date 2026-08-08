local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/nexxchasers/loader.lua"))()

local Window = Library:CreateWindow({
    Title = "NexxChasers",
    Author = "by Nexx • Chasers",
    Theme = "Dark",
    Transparency = 0.08,
    Logo = 10734943674,
    ToggleKeybind = Enum.KeyCode.RightShift,
    Folder = "NexxChasers",
})

Library:EnableAutoSave("main")
Library:LoadConfig("main")

local MainTab = Window:create_tab("Main", "home")
local CombatTab = Window:create_tab("Combat", "swords")
local VisualsTab = Window:create_tab("Visuals", "eye")
local SettingsTab = Window:create_tab("Settings", "settings")

MainTab:create_paragraph({
    Title = "Welcome",
    Content = "Larger text, WindUI-style buttons with accent bar. Logo accepts rbxassetid numbers.",
})

MainTab:create_divider("Player")

MainTab:create_toggle({
    Title = "Speed Hack",
    Flag = "SpeedHack",
    default = false,
    callback = function(state)
        print("Speed:", state)
    end,
})

MainTab:create_slider({
    Title = "WalkSpeed",
    Flag = "WalkSpeed",
    Min = 16,
    Max = 200,
    default = 16,
    Step = 1,
    callback = function(value)
        print("WalkSpeed =", value)
    end,
})

MainTab:create_button({
    Title = "Reset Character",
    callback = function()
        local char = game.Players.LocalPlayer.Character
        if char then char:BreakJoints() end
    end,
})

MainTab:create_codebox({
    Title = "Example Script",
    Code = [[print("Hello from NexxChasers")
local p = game.Players.LocalPlayer
print(p.Name)]],
    Runnable = true,
    Copyable = true,
})

MainTab:create_colorpicker({
    Title = "Accent Color",
    Flag = "AccentColor",
    default = Color3.fromRGB(255, 255, 255),
    callback = function(c)
        print("Color", c)
    end,
})

CombatTab:create_divider("Aimbot")

CombatTab:create_toggle({
    Title = "Enable Aimbot",
    Flag = "Aimbot",
    default = false,
    callback = function(s) print("Aimbot", s) end,
})

local lockedToggle = CombatTab:create_toggle({
    Title = "Premium Aim",
    Locked = true,
    LockedText = "VIP Only",
    default = false,
    callback = function() end,
})

CombatTab:create_button({
    Title = "Unlock Premium",
    callback = function()
        lockedToggle:Unlock()
        Library:notify({ title = "Unlocked", content = "Premium Aim available", duration = 3 })
    end,
})

VisualsTab:create_toggle({
    Title = "Box ESP",
    Flag = "BoxESP",
    default = false,
    callback = function(s) print("Box", s) end,
})

VisualsTab:create_colorpicker({
    Title = "ESP Color",
    Flag = "ESPColor",
    default = Color3.fromRGB(255, 50, 50),
    callback = function(c) print(c) end,
})

SettingsTab:create_divider("UI")

SettingsTab:create_dropdown({
    Title = "Theme",
    options = { "Dark", "Light", "Custom" },
    default = "Dark",
    callback = function(value)
        if value == "Custom" then
            Library:OpenThemeEditor()
        else
            Library:SetTheme(value)
            Library:notify({ title = "Theme", content = "Switched to " .. value, duration = 2 })
        end
    end,
})

SettingsTab:create_button({
    Title = "Open Theme Editor",
    callback = function()
        Library:OpenThemeEditor()
    end,
})

SettingsTab:create_button({
    Title = "Save Config",
    callback = function()
        Library:SaveConfig("main")
        Library:notify({ title = "Config", content = "Saved", duration = 2 })
    end,
})

SettingsTab:create_button({
    Title = "Close UI",
    callback = function()
        Library:Close()
    end,
})

task.wait(0.5)
Library:notify({
    title = "NexxChasers UI",
    content = "Loaded • RightShift to toggle",
    duration = 4,
})
