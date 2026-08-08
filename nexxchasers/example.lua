--[[
    NexxChasers UI Library - Example
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_REPO/NexxChasers/main/loader.lua"))()
-- For local testing you can also do:
-- local Library = require(script.Parent.loader)  -- or load the file content

local Window = Library:CreateWindow({
    Title = "NexxChasers",
    Author = "by Nexx • Chasers",
    Theme = "Dark",          -- "Dark" or "Light"
    Transparency = 0.08,     -- 0 = solid, 1 = fully transparent
    Logo = nil,              -- nil = default lucide icon, or pass rbxassetid / lucide name
    ToggleKeybind = Enum.KeyCode.RightShift,
})

-- Tabs (icon name from Lucide)
local MainTab = Window:create_tab("Main", "home")
local CombatTab = Window:create_tab("Combat", "swords")
local VisualsTab = Window:create_tab("Visuals", "eye")
local SettingsTab = Window:create_tab("Settings", "settings")

-- ========== MAIN TAB ==========
MainTab:create_divider("Player")

MainTab:create_checkbox({
    title = "Speed Hack",
    default = false,
    callback = function(state)
        print("Speed:", state)
    end
})

MainTab:create_slider({
    title = "WalkSpeed",
    minimum = 16,
    maximum = 200,
    default = 16,
    rounding = 1,
    callback = function(value)
        print("WalkSpeed =", value)
    end
})

MainTab:create_slider({
    title = "JumpPower",
    minimum = 50,
    maximum = 300,
    default = 50,
    rounding = 1,
    callback = function(value)
        print("JumpPower =", value)
    end
})

MainTab:create_divider("Actions")

MainTab:create_button({
    title = "Reset Character",
    callback = function()
        local char = game.Players.LocalPlayer.Character
        if char then char:BreakJoints() end
    end
})

MainTab:create_textbox({
    title = "Custom Name",
    placeholder = "Enter name...",
    callback = function(text)
        print("Name set to:", text)
    end
})

MainTab:create_dropdown({
    title = "Teleport",
    options = { "Spawn", "Bank", "Shop", "Safezone" },
    default = "Spawn",
    multi_selection = false,
    callback = function(value)
        print("Teleport to:", value)
    end
})

-- ========== COMBAT TAB ==========
CombatTab:create_divider("Aimbot")

CombatTab:create_checkbox({
    title = "Enable Aimbot",
    default = false,
    callback = function(state)
        print("Aimbot:", state)
    end
})

CombatTab:create_slider({
    title = "FOV",
    minimum = 10,
    maximum = 360,
    default = 90,
    rounding = 1,
    callback = function(v) print("FOV", v) end
})

CombatTab:create_dropdown({
    title = "Target Part",
    options = { "Head", "Torso", "HumanoidRootPart" },
    default = "Head",
    callback = function(v) print("Part:", v) end
})

CombatTab:create_divider("Silent Aim")

local silentModule = CombatTab:create_module({
    title = "Silent Aim",
    default = false,
    callback = function(state)
        print("Silent Aim module:", state)
    end
})

silentModule:create_checkbox({
    title = "Visible Check",
    default = true,
    callback = function(s) print("Vis check", s) end
})

silentModule:create_button({
    title = "Force Hit",
    callback = function() print("Force hit!") end
})

-- ========== VISUALS TAB ==========
VisualsTab:create_divider("ESP")

VisualsTab:create_checkbox({
    title = "Box ESP",
    default = false,
    callback = function(s) print("Box ESP", s) end
})

VisualsTab:create_checkbox({
    title = "Name ESP",
    default = false,
    callback = function(s) print("Name ESP", s) end
})

VisualsTab:create_checkbox({
    title = "Tracer ESP",
    default = false,
    callback = function(s) print("Tracer", s) end
})

VisualsTab:create_slider({
    title = "ESP Distance",
    minimum = 100,
    maximum = 5000,
    default = 1000,
    rounding = 50,
    callback = function(v) print("Dist", v) end
})

-- ========== SETTINGS TAB ==========
SettingsTab:create_divider("UI")

SettingsTab:create_dropdown({
    title = "Theme",
    options = { "Dark", "Light" },
    default = "Dark",
    callback = function(value)
        -- Theme switching would require re-creating or a SetTheme method
        -- For now just notify
        Library:notify({
            title = "Theme",
            content = "Selected " .. value .. " (restart to apply fully)",
            duration = 3
        })
    end
})

SettingsTab:create_button({
    title = "Test Notification",
    callback = function()
        Library:notify({
            title = "NexxChasers",
            content = "Everything is working smoothly!",
            duration = 4,
            notify_type = "normal"
        })
    end
})

SettingsTab:create_button({
    title = "Close UI",
    callback = function()
        Library:Close()
    end
})

-- Welcome notification
task.wait(0.6)
Library:notify({
    title = "NexxChasers UI",
    content = "Loaded successfully • Press RightShift to toggle",
    duration = 4
})

print("[NexxChasers] Example loaded")
