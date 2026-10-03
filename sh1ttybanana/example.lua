--[[
    sh1ttybanana  |  example.lua
    Fluid-glass dark UI demo. Every component and config key used here exists
    in sh1ttybanana.lua (v0.2.0-glass).
]]

-- Load the library: local file first (executor workspace), otherwise your own host.
local Library
if isfile and readfile and isfile("sh1ttybanana.lua") then
    Library = loadstring(readfile("sh1ttybanana.lua"))()
else
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()
end

local Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "fluid glass",
    Theme = "Dark",                    -- the single fluid-glass theme
    Size = UDim2.fromOffset(720, 520),
    Blur = true,
    -- Color = Color3.fromRGB(150, 118, 255), -- optional: overrides the accent of every theme
    -- Transparency = 0.2,                    -- optional: window glass opacity (0 = solid, 1 = clear)
    ToggleKey = Enum.KeyCode.RightShift
})

-- Tabs -----------------------------------------------------------------------
local Main     = Window:Tab({ Title = "Main",     Icon = "sparkles" })
local Visuals  = Window:Tab({ Title = "Visuals",  Icon = "eye" })
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Main -----------------------------------------------------------------------
local Combat = Main:AddSection({ Title = "Combat" })

Combat:AddToggle({
    Title = "Auto Farm",
    Description = "Glass toggle with an accent-lit track",
    Default = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        print("Auto Farm:", Value)
    end
})

Combat:AddSlider({
    Title = "Walk Speed",
    Description = "Drag the knob",
    Min = 16,
    Max = 120,
    Increment = 1,
    Default = 16,
    Suffix = " sps",
    Flag = "WalkSpeed",
    Callback = function(Value)
        local Character = game.Players.LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = Value
        end
    end
})

Combat:AddRangeSlider({
    Title = "Target Range",
    Min = 0,
    Max = 100,
    Default = { 20, 80 },
    Flag = "TargetRange",
    Callback = function(Value)
        print("Range:", Value[1], Value[2])
    end
})

Combat:AddDropdown({
    Title = "Target Part",
    Options = { "Head", "Torso", "Random" },
    Default = "Head",
    Flag = "TargetPart",
    Callback = function(Value)
        print("Target:", Value)
    end
})

Combat:AddKeybind({
    Title = "Quick Action",
    Default = Enum.KeyCode.E,
    Mode = "Toggle",
    Flag = "QuickKey",
    Callback = function()
        print("Keybind fired")
    end
})

local Actions = Main:AddSection({ Title = "Actions" })

Actions:AddButton({
    Title = "Send Notification",
    Description = "Rounded accent chip button",
    Callback = function()
        Window:Notify({
            Title = "Hello",
            Content = "Fluid glass notification",
            Type = "Success",
            Duration = 4
        })
    end
})

Actions:AddButton({
    Title = "Dangerous Action",
    Description = "Asks before running",
    Confirm = "Are you sure you want to run this?",
    Callback = function()
        Window:Notify({ Title = "Done", Content = "Action confirmed", Type = "Info" })
    end
})

Actions:AddMultiButton({
    Title = "Quick Row",
    Buttons = {
        { Title = "Accent", Accent = true, Callback = function() print("accent") end },
        { Title = "Normal", Callback = function() print("normal") end },
        { Title = "Other",  Callback = function() print("other") end }
    }
})

Actions:AddProgress({
    Title = "Loading",
    Default = 65,
    Suffix = "%"
})

-- Visuals --------------------------------------------------------------------
local ESP = Visuals:AddSection({ Title = "ESP" })

ESP:AddToggle({ Title = "Boxes", Default = true, Flag = "ESPBoxes" })
ESP:AddToggle({ Title = "Names", Default = false, Flag = "ESPNames" })
ESP:AddToggleGroup({
    Title = "Mode",
    Options = { "Outline", "Fill", "Both" },
    Default = "Outline",
    Flag = "ESPMode"
})
ESP:AddColorpicker({
    Title = "ESP Color",
    Default = Color3.fromRGB(150, 118, 255),
    Flag = "ESPColor",
    Callback = function(Color)
        print("Color:", Color)
    end
})
ESP:AddInput({
    Title = "Custom Text",
    Placeholder = "type here...",
    Flag = "ESPText",
    Callback = function(Text)
        print("Text:", Text)
    end
})

-- Settings -------------------------------------------------------------------
local Appearance = Settings:AddSection({ Title = "Appearance" })

Appearance:AddSlider({
    Title = "Window Transparency",
    Description = "0 = solid, 1 = fully clear",
    Min = 0,
    Max = 100,
    Default = 20,
    Suffix = "%",
    Callback = function(Value)
        Window:SetTransparency(Value / 100)
    end
})

Appearance:AddParagraph({
    Title = "Tip",
    Content = "Press RightShift to hide or show the window."
})

Window:Notify({
    Title = "sh1ttybanana",
    Content = "Loaded fluid glass UI",
    Type = "Success"
})
