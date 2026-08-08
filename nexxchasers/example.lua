local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/nexxchasers/loader.lua"))()

local Window = Library:CreateWindow({
    Title = "NexxChasers",
    Author = "by Nexx • Chasers",
    Theme = "Dark",
    Transparency = 0.08,
    Logo = "layout-dashboard",
    ToggleKeybind = Enum.KeyCode.RightShift,
    Folder = "NexxChasers",
})

local MainTab = Window:create_tab("Main", "home")
local CombatTab = Window:create_tab("Combat", "swords")
local VisualsTab = Window:create_tab("Visuals", "eye")
local SettingsTab = Window:create_tab("Settings", "settings")

MainTab:create_paragraph({
    Title = "Welcome",
    Content = "NexxChasers UI. RightShift toggles. Drag bottom bar to move. Flags auto-save.",
})

MainTab:create_imageparagraph({
    Title = "Features",
    Content = "Live themes, locked badges, config autosave, colorpicker, theme editor.",
    Image = "sparkles",
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

MainTab:create_textbox({
    Title = "Custom Name",
    Placeholder = "Enter name...",
    callback = function(text)
        print("Name:", text)
    end,
})

MainTab:create_dropdown({
    Title = "Teleport",
    options = { "Spawn", "Bank", "Shop", "Safezone" },
    default = "Spawn",
    callback = function(value)
        print("Teleport:", value)
    end,
})

MainTab:create_keybind({
    Title = "Panic Key",
    default = Enum.KeyCode.P,
    callback = function(key)
        print("Panic:", key.Name)
    end,
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

CombatTab:create_slider({
    Title = "FOV",
    Flag = "FOV",
    Min = 10,
    Max = 360,
    default = 90,
    callback = function(v) print("FOV", v) end,
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

VisualsTab:create_divider("ESP")

VisualsTab:create_toggle({
    Title = "Box ESP",
    Flag = "BoxESP",
    default = false,
    callback = function(s) print("Box", s) end,
})

VisualsTab:create_toggle({
    Title = "Name ESP",
    Flag = "NameESP",
    default = false,
    callback = function(s) print("Name", s) end,
})

VisualsTab:create_colorpicker({
    Title = "ESP Color",
    Flag = "ESPColor",
    default = Color3.fromRGB(0, 255, 128),
    callback = function(c) print("ESP", c) end,
})

SettingsTab:create_divider("UI")

SettingsTab:create_dropdown({
    Title = "Theme",
    options = { "Dark", "Light", "Custom" },
    default = "Dark",
    callback = function(value)
        if value == "Custom" then
            Library:ThemeEditor()
        else
            Library:SetTheme(value)
            Library:notify({ title = "Theme", content = "Switched to " .. value, duration = 2 })
        end
    end,
})

SettingsTab:create_button({
    Title = "Open Theme Editor",
    callback = function()
        Library:ThemeEditor()
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
    Title = "Load Config",
    callback = function()
        Library:LoadConfig("main")
        Library:notify({ title = "Config", content = "Loaded", duration = 2 })
    end,
})

SettingsTab:create_button({
    Title = "Open Dialog",
    callback = function()
        Library:Dialog({
            Title = "Confirm",
            Content = "Do you want to continue?",
            Buttons = {
                { Title = "Cancel" },
                { Title = "Yes", Callback = function()
                    Library:notify({ title = "OK", content = "Confirmed", duration = 2 })
                end },
            },
        })
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
    content = "Loaded • RightShift to toggle • Flags auto-save",
    duration = 4,
})
