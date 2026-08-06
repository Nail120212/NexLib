local Library = loadstring(game:HttpGet("YOUR_RAW_LINK_HERE"))()

--> initialize with title, logo (lucide icon or rbxassetid), and custom size
local Window = Library:init({
    title = "euphoria.rewritten",
    logo = "zap", -- lucide icon name
    size = UDim2.new(0, 720, 0, 480),
})

--> notify on load
Window:notify({
    title = "Loaded",
    content = "Euphoria UI Library has been successfully loaded!",
    duration = 4,
    notify_type = "success"
})

--> create tabs
local CombatTab = Window:create_tab("Combat", "sword")
local VisualsTab = Window:create_tab("Visuals", "eye")
local SettingsTab = Window:create_tab("Settings", "settings")

--> combat tab elements
CombatTab:create_divider("Aimbot")

CombatTab:create_checkbox({
    title = "Enabled",
    default = false,
    callback = function(state)
        print("Aimbot:", state)
    end
})

CombatTab:create_slider({
    title = "FOV",
    minimum = 10,
    maximum = 500,
    default = 100,
    rounding = 5,
    callback = function(value)
        print("FOV:", value)
    end
})

CombatTab:create_dropdown({
    title = "Target Part",
    options = { "Head", "Torso", "HumanoidRootPart" },
    default = "Head",
    multi_selection = false,
    callback = function(value)
        print("Target:", value)
    end
})

CombatTab:create_divider("Silent Aim")

local SilentModule = CombatTab:create_module({
    title = "Silent Aim",
    default = false,
    callback = function(state)
        print("Silent Aim toggled:", state)
    end
})

SilentModule:create_slider({
    title = "Hit Chance",
    minimum = 0,
    maximum = 100,
    default = 85,
    rounding = 1,
    callback = function(value)
        print("Hit Chance:", value)
    end
})

SilentModule:create_dropdown({
    title = "Hitboxes",
    options = { "Head", "UpperTorso", "LowerTorso", "LeftArm", "RightArm" },
    default = { "Head", "UpperTorso" },
    multi_selection = true,
    callback = function(values)
        print("Selected hitboxes:", table.concat(values, ", "))
    end
})

SilentModule:create_textbox({
    title = "Prediction",
    placeholder = "0.165",
    callback = function(text)
        print("Prediction set to:", text)
    end
})

--> visuals tab
VisualsTab:create_divider("ESP")

VisualsTab:create_checkbox({
    title = "Boxes",
    default = true,
    callback = function(state)
        print("Boxes:", state)
    end
})

VisualsTab:create_checkbox({
    title = "Names",
    default = true,
    callback = function(state)
        print("Names:", state)
    end
})

VisualsTab:create_slider({
    title = "Max Distance",
    minimum = 100,
    maximum = 5000,
    default = 1000,
    rounding = 50,
    callback = function(value)
        print("Distance:", value)
    end
})

VisualsTab:create_button({
    title = "Refresh ESP",
    callback = function()
        Window:notify({
            title = "ESP",
            content = "ESP cache has been refreshed.",
            duration = 2,
            notify_type = "normal"
        })
    end
})

--> settings tab
SettingsTab:create_divider("Configuration")

SettingsTab:create_textbox({
    title = "Config Name",
    placeholder = "default-config",
    callback = function(text)
        print("Config name:", text)
    end
})

SettingsTab:create_dropdown({
    title = "Theme",
    options = { "Dark", "Darker", "Amoled" },
    default = "Dark",
    callback = function(value)
        print("Theme:", value)
    end
})

SettingsTab:create_button({
    title = "Save Config",
    callback = function()
        Window:notify({
            title = "Config",
            content = "Configuration saved successfully!",
            duration = 3,
            notify_type = "success"
        })
    end
})

SettingsTab:create_button({
    title = "Load Config",
    callback = function()
        Window:notify({
            title = "Config",
            content = "Configuration loaded!",
            duration = 3,
            notify_type = "success"
        })
    end
})

SettingsTab:create_divider("Keybinds")

local FlyModule = SettingsTab:create_module({
    title = "Fly",
    default = false,
    callback = function(state)
        print("Fly:", state)
    end
})

FlyModule:create_slider({
    title = "Speed",
    minimum = 1,
    maximum = 100,
    default = 50,
    rounding = 1,
    callback = function(value)
        print("Fly speed:", value)
    end
})

FlyModule:create_checkbox({
    title = "NoClip",
    default = false,
    callback = function(state)
        print("NoClip:", state)
    end
})

--> example of using Set methods
local SpeedSlider = CombatTab:create_slider({
    title = "WalkSpeed",
    minimum = 16,
    maximum = 200,
    default = 16,
    rounding = 1,
    callback = function(value)
        print("WalkSpeed:", value)
    end
})

-- later in your code you can do:
-- SpeedSlider:Set(50)

print("Euphoria UI loaded successfully!")
