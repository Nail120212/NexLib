local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/kingbanana/library.lua"))()

Library:LoadConfig("myhub")

local Window = Library:NewWindow({
    Title = "KingBanana Hub",
    Description = "Full API Showcase",
    Icon = "rbxassetid://89646749075297",
    Size = UDim2.new(0, 580, 0, 380),
    Theme = "Dark",
    Transparency = 0.06,
    ToggleKey = "RightControl"
})

Window:AddTag({ Title = "v1.0", Color = Color3.fromRGB(255, 200, 50), TextColor = Color3.fromRGB(20, 20, 25) })
Window:AddTag({ Title = "UI Library", Color = Color3.fromRGB(80, 220, 120), TextColor = Color3.fromRGB(20, 20, 25) })

local Main = Window:T("Main", "home")
local PlayersTab = Window:T("Players", "users")
local Visual = Window:T("Visual", "palette")
local Misc = Window:T("Misc", "settings")

Main:AddLabel({ Title = "General controls" })

Main:AddToggle({
    Title = "Enable Feature",
    Description = "Saved with Flag",
    Default = false,
    Flag = "EnableFeature",
    Position = "left",
    Callback = function(v) print("Toggle:", v) end
})

Main:AddColorToggle({
    Title = "ESP Color Toggle",
    Color = Color3.fromRGB(80, 180, 255),
    Default = false,
    Flag = "ESPToggle",
    Position = "left",
    Callback = function(on, color)
        print("ColorToggle", on, color)
    end
})

Main:AddKeybind({
    Title = "Action Key",
    Default = "E",
    Position = "left",
    Callback = function(key)
        Window:Notify({ Title = "Keybind", Content = "Pressed " .. tostring(key), Type = "Info", Duration = 2 })
    end
})

Main:AddButton({
    Title = "Normal Button",
    Position = "left",
    Callback = function()
        Window:Notify({ Title = "Button", Content = "Clicked", Type = "Success", Duration = 2 })
    end
})

Main:AddMultiButton({
    Title = "Button Section",
    Position = "left",
    Opened = true,
    Buttons = {
        { Title = "Example Single", Callback = function()
            Window:Notify({ Title = "Single", Content = "Full width top", Type = "Info", Duration = 2 })
        end },
        { Title = "Example", Callback = function()
            Window:Notify({ Title = "Example", Content = "Half", Type = "Success", Duration = 2 })
        end },
        { Title = "Example Off", Callback = function()
            Window:Notify({ Title = "Off", Content = "Half", Type = "Error", Duration = 2 })
        end },
    }
})

Main:AddSlider({
    Title = "Speed",
    Min = 1, Max = 100, Default = 16, Increment = 1,
    Flag = "Speed",
    Position = "right",
    Callback = function(v) Library:SetFlag("Speed", v) end
})

Main:AddDropdown({
    Title = "Mode",
    Values = {"Normal", "Fast", "Ultra", "Custom"},
    Default = "Normal",
    Multi = false,
    Flag = "Mode",
    Position = "right",
    Callback = function(v) print("Mode:", v) end
})

Main:AddDropdown({
    Title = "Multi Modes",
    Values = {"A", "B", "C"},
    Default = {},
    Multi = true,
    Flag = "MultiModes",
    Position = "right",
    Callback = function(v) print(v) end
})

Main:AddInput({
    Title = "Username",
    PlaceHolder = "Player...",
    Flag = "Username",
    Position = "right",
    Callback = function(t) Library:SetFlag("Username", t) end
})

Main:AddColorPicker({
    Title = "Accent Color",
    Default = Color3.fromRGB(158, 158, 158),
    Position = "right",
    Callback = function(c) print(c) end
})

Main:AddProgressBar({ Title = "Load Progress", Value = 40, Position = "right" })

Main:AddButton({
    Title = "Open Dialog",
    Position = "left",
    Callback = function()
        Window:Dialog({
            Title = "Confirm Action",
            Content = "Extendable dialog with multiple buttons.",
            Buttons = {
                { Title = "Yes", Callback = function()
                    Window:Notify({ Title = "Yes", Content = "Confirmed", Type = "Success", Duration = 2 })
                end },
                { Title = "No", Callback = function()
                    Window:Notify({ Title = "No", Content = "Cancelled", Type = "Warning", Duration = 2 })
                end },
                { Title = "Later", Callback = function() end },
            }
        })
    end
})

Main:AddCodeBox({
    Title = "Snippet",
    Code = "print(\"KingBanana\")\nlocal speed = 16",
    Height = 80,
    Position = "left"
})

Main:AddImage("Preview", {
    Image = "rbxassetid://89646749075297",
    Height = 100,
    Button = "Open Link",
    Position = "left",
    Callback = function()
        Window:Notify({ Title = "Image", Content = "Button under image clicked", Type = "Info", Duration = 2 })
    end
})

PlayersTab:AddPlayerDropdown({
    Title = "Select Player",
    Multi = false,
    Flag = "SelectedPlayer",
    Position = "left",
    Callback = function(name)
        Window:Notify({ Title = "Player", Content = tostring(name), Type = "Info", Duration = 2 })
    end
})

PlayersTab:AddParagraph({
    Title = "Note",
    Content = "PlayerDropdown auto-refreshes. Config Flags restore toggles/dropdowns on LoadConfig.",
    Position = "left"
})

Visual:AddButton({ Title = "Dark Theme", Position = "left", Callback = function() Library:SetTheme("Dark") end })
Visual:AddButton({ Title = "Light Theme", Position = "left", Callback = function() Library:SetTheme("Light") end })
Visual:AddSlider({ Title = "Transparency", Min = 0, Max = 50, Default = 6, Position = "left", Callback = function(v) Library:SetTransparency(v / 100) end })

Visual:AddButton({
    Title = "Success Notify",
    Position = "right",
    Callback = function()
        Window:Notify({ Title = "Success", Content = "OK", Type = "Success", Duration = 2 })
    end
})
Visual:AddButton({
    Title = "Error Notify",
    Position = "right",
    Callback = function()
        Window:Notify({ Title = "Error", Content = "Failed", Type = "Error", Duration = 2 })
    end
})

local LeftBox = Misc:AddLeftGroupbox("Config")
LeftBox:AddButton({
    Title = "Save Config",
    Callback = function()
        Library:SaveConfig("myhub")
        Window:Notify({ Title = "Config", Content = "Saved", Type = "Success", Duration = 2 })
    end
})
LeftBox:AddButton({
    Title = "Load Config",
    Callback = function()
        if Library:LoadConfig("myhub") then
            Window:Notify({ Title = "Config", Content = "Loaded + applied", Type = "Info", Duration = 2 })
        else
            Window:Notify({ Title = "Config", Content = "No file", Type = "Warning", Duration = 2 })
        end
    end
})

local RightBox = Misc:AddRightGroupbox("Danger")
RightBox:AddButton({
    Title = "Destroy UI",
    Callback = function()
        Window:Dialog({
            Title = "Destroy",
            Content = "Close the entire UI?",
            Buttons = {
                { Title = "Destroy", Callback = function() Window:Destroy() end },
                { Title = "Cancel", Callback = function() end },
            }
        })
    end
})

Misc:AddParagraph({
    Title = "Flags",
    Content = "Use Flag = \"Name\" on Toggle, Dropdown, ColorToggle, Slider. LoadConfig auto-calls :Set() on bound elements including dropdowns.",
    Position = "left"
})
