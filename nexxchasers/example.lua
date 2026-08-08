local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/nexxchasers/loader.lua"))()

local Window = Library:CreateWindow({
    Title = "NexxChasers",
    Author = "by Nexx • Chasers",
    Theme = "Dark",
    Transparency = 0.06,
    Logo = 10734943674,
    ToggleKeybind = Enum.KeyCode.RightShift,
    Folder = "NexxChasers",
})

Library:EnableAutoSave("main")
Library:LoadConfig("main")

local Main = Window:create_tab("Main", "home")
local Combat = Window:create_tab("Combat", "swords")
local Visuals = Window:create_tab("Visuals", "eye")
local Settings = Window:create_tab("Settings", "settings")

Main:create_paragraph({
    Title = "Welcome",
    Content = "Clean rewrite with large readable text. WindUI-style buttons, toggles, and components.",
})

Main:create_divider("Player")

Main:create_toggle({
    Title = "Speed Hack",
    Flag = "SpeedHack",
    default = false,
    callback = function(state) print("Speed:", state) end,
})

Main:create_slider({
    Title = "WalkSpeed",
    Flag = "WalkSpeed",
    Min = 16,
    Max = 200,
    default = 16,
    Step = 1,
    callback = function(v) print("WalkSpeed", v) end,
})

Main:create_button({
    Title = "Reset Character",
    callback = function()
        local c = game.Players.LocalPlayer.Character
        if c then c:BreakJoints() end
    end,
})

Main:create_codebox({
    Title = "Example Script",
    Code = [[print("Hello from NexxChasers")
print(game.Players.LocalPlayer.Name)]],
})

Main:create_colorpicker({
    Title = "Accent Color",
    Flag = "AccentColor",
    default = Color3.fromRGB(255, 255, 255),
    callback = function(c) print(c) end,
})

Combat:create_divider("Aimbot")

Combat:create_toggle({
    Title = "Enable Aimbot",
    Flag = "Aimbot",
    default = false,
    callback = function(s) print("Aimbot", s) end,
})

local locked = Combat:create_toggle({
    Title = "Premium Aim",
    Locked = true,
    LockedText = "VIP Only",
    default = false,
})

Combat:create_button({
    Title = "Unlock Premium",
    callback = function()
        locked:Unlock()
        Library:Notify({ title = "Unlocked", content = "Premium Aim available", duration = 3 })
    end,
})

Visuals:create_toggle({
    Title = "Box ESP",
    Flag = "BoxESP",
    default = false,
    callback = function(s) print("Box", s) end,
})

Visuals:create_colorpicker({
    Title = "ESP Color",
    Flag = "ESPColor",
    default = Color3.fromRGB(255, 50, 50),
})

Settings:create_divider("UI")

Settings:create_dropdown({
    Title = "Theme",
    options = { "Dark", "Light", "Custom" },
    default = "Dark",
    callback = function(v)
        if v == "Custom" then Library:OpenThemeEditor()
        else Library:SetTheme(v) end
    end,
})

Settings:create_button({
    Title = "Open Theme Editor",
    callback = function() Library:OpenThemeEditor() end,
})

Settings:create_button({
    Title = "Save Config",
    callback = function()
        Library:SaveConfig("main")
        Library:Notify({ title = "Config", content = "Saved", duration = 2 })
    end,
})

Settings:create_button({
    Title = "Close UI",
    callback = function() Library:Close() end,
})

task.wait(0.4)
Library:Notify({
    title = "NexxChasers",
    content = "Loaded • RightShift to toggle",
    duration = 4,
})
