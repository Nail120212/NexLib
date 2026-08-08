local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/kingbanana/library.lua"))()

Library:LoadConfig("kingbanana_hub")

Library:CreateCustomTheme("Purple", {
    Main = Color3.fromRGB(18, 12, 28),
    Accent = Color3.fromRGB(160, 100, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDisabled = Color3.fromRGB(170, 160, 190),
    Background = Color3.fromRGB(28, 22, 40),
    Stroke = Color3.fromRGB(100, 80, 140),
    Card = Color3.fromRGB(255, 255, 255),
    CardTransparency = 0.94,
    Section = Color3.fromRGB(255, 255, 255),
    SectionTransparency = 0.97
})

Library:CreateCustomTheme("Ocean", {
    Main = Color3.fromRGB(10, 18, 28),
    Accent = Color3.fromRGB(60, 180, 220),
    Text = Color3.fromRGB(240, 248, 255),
    TextDisabled = Color3.fromRGB(140, 170, 190),
    Background = Color3.fromRGB(20, 32, 48),
    Stroke = Color3.fromRGB(50, 100, 130),
    Card = Color3.fromRGB(255, 255, 255),
    CardTransparency = 0.95,
    Section = Color3.fromRGB(255, 255, 255),
    SectionTransparency = 0.97
})

local Window = Library:NewWindow({
    Title = "KingBanana Hub",
    Description = "Full API + Custom Theme Showcase",
    Icon = "rbxassetid://89646749075297",
    Theme = "Dark",
    Transparency = 0.06,
    ToggleKey = "RightControl"
})

Window:AddTag({
    Title = "v1.0",
    Color = Color3.fromRGB(255, 200, 50),
    TextColor = Color3.fromRGB(20, 20, 25)
})

Window:AddTag({
    Title = "UI Library",
    Color = Color3.fromRGB(80, 220, 120),
    TextColor = Color3.fromRGB(20, 20, 25)
})

local Main = Window:T("Main", "home")
local Combat = Window:T("Combat", "sword")
local PlayersTab = Window:T("Players", "users")
local Visual = Window:T("Visual", "palette")
local Misc = Window:T("Misc", "settings")

Main:AddLabel({ Title = "General", Content = "Core controls + flags" })

Main:AddToggle({
    Title = "Enable Feature",
    Description = "Main feature toggle",
    Default = false,
    Flag = "EnableFeature",
    Position = "left",
    Callback = function(Value)
        print("EnableFeature:", Value)
    end
})

Main:AddToggle({
    Title = "Locked Feature",
    Description = "Requires premium",
    Default = false,
    Locked = true,
    Locktext = "premium",
    Position = "left",
    Callback = function() end
})

Main:AddColorToggle({
    Title = "ESP Color Toggle",
    Description = "Swatch cycles color, track toggles",
    Color = Color3.fromRGB(80, 180, 255),
    Default = false,
    Flag = "ESPToggle",
    Position = "left",
    Callback = function(Enabled, Color)
        print("ESP", Enabled, Color)
    end
})

Main:AddKeybind({
    Title = "Action Key",
    Description = "Press to fire",
    Default = "E",
    Position = "left",
    Callback = function(Key)
        Window:Notify({
            Title = "Keybind",
            Content = "Pressed " .. tostring(Key),
            Type = "Info",
            Duration = 2
        })
    end
})

Main:AddKeybind({
    Title = "Locked Key",
    Default = "Q",
    Locked = true,
    Locktext = "vip",
    Position = "left",
    Callback = function() end
})

Main:AddButton({
    Title = "Normal Button",
    Description = "Single action button",
    Position = "left",
    Callback = function()
        Window:Notify({
            Title = "Button",
            Content = "Normal button clicked",
            Type = "Success",
            Duration = 2
        })
    end
})

Main:AddMultiButton({
    Title = "Button Section",
    Position = "left",
    Opened = true,
    Buttons = {
        {
            Title = "Example Single",
            Callback = function()
                Window:Notify({ Title = "Single", Content = "Top full width", Type = "Info", Duration = 2 })
            end
        },
        {
            Title = "Example",
            Callback = function()
                Window:Notify({ Title = "Example", Content = "Half width", Type = "Success", Duration = 2 })
            end
        },
        {
            Title = "Example Off",
            Callback = function()
                Window:Notify({ Title = "Off", Content = "Half width", Type = "Error", Duration = 2 })
            end
        }
    }
})

Main:AddSlider({
    Title = "Speed",
    Description = "Walk / value speed",
    Min = 1,
    Max = 100,
    Default = 16,
    Increment = 1,
    Flag = "Speed",
    Position = "right",
    Callback = function(Value)
        Library:SetFlag("Speed", Value)
    end
})

Main:AddDropdown({
    Title = "Mode",
    Description = "Select one mode",
    Values = {"Normal", "Fast", "Ultra", "Custom"},
    Default = "Normal",
    Multi = false,
    Flag = "Mode",
    Position = "right",
    Callback = function(Value)
        print("Mode:", Value)
    end
})

Main:AddDropdown({
    Title = "Multi Select",
    Description = "Pick multiple",
    Values = {"Option A", "Option B", "Option C", "Option D"},
    Default = {},
    Multi = true,
    Flag = "MultiModes",
    Position = "right",
    Callback = function(Value)
        print("Multi:", Value)
    end
})

Main:AddInput({
    Title = "Username",
    Description = "Type a name",
    PlaceHolder = "Player name...",
    Default = "",
    Flag = "Username",
    Position = "right",
    Callback = function(Text)
        Library:SetFlag("Username", Text)
    end
})

Main:AddColorPicker({
    Title = "Accent Color",
    Description = "Real HSV picker",
    Default = Color3.fromRGB(158, 158, 158),
    Position = "right",
    Callback = function(Color)
        print("Color:", Color)
    end
})

Main:AddProgressBar({
    Title = "Load Progress",
    Value = 42,
    Min = 0,
    Max = 100,
    Position = "right"
})

Main:AddButton({
    Title = "Open Dialog",
    Position = "left",
    Callback = function()
        Window:Dialog({
            Title = "Confirm Action",
            Content = "Extendable dialog with any number of buttons. Continue?",
            Buttons = {
                {
                    Title = "Yes",
                    Callback = function()
                        Window:Notify({ Title = "Yes", Content = "Confirmed", Type = "Success", Duration = 2 })
                    end
                },
                {
                    Title = "No",
                    Callback = function()
                        Window:Notify({ Title = "No", Content = "Cancelled", Type = "Warning", Duration = 2 })
                    end
                },
                {
                    Title = "Later",
                    Callback = function() end
                }
            }
        })
    end
})

Main:AddButton({
    Title = "Popup Alias",
    Position = "left",
    Callback = function()
        Window:Popup({
            Title = "Popup",
            Content = "Popup is the same as Dialog.",
            Buttons = {
                { Title = "OK", Callback = function() end }
            }
        })
    end
})

Main:AddCodeBox({
    Title = "Script Snippet",
    Code = "print(\"Hello KingBanana\")\nlocal speed = 16\nprint(speed)",
    Height = 90,
    Position = "left"
})

Main:AddImage("Banner", {
    Image = "rbxassetid://89646749075297",
    Height = 100,
    Button = "Open Link",
    Position = "left",
    Callback = function()
        Window:Notify({
            Title = "Image",
            Content = "Button under image clicked",
            Type = "Info",
            Duration = 2
        })
    end
})

Main:AddSeperator("Extras")

Main:AddParagraph({
    Title = "Notes",
    Content = "Drag = bottom center line outside UI. Resize = bottom right line outside UI. Size auto-scales for phone and PC. ToggleKey = RightControl.",
    Position = "left"
})

Combat:AddToggle({
    Title = "Kill Aura",
    Default = false,
    Flag = "KillAura",
    Position = "left",
    Callback = function(v) print("KillAura", v) end
})

Combat:AddSlider({
    Title = "Aura Range",
    Min = 5,
    Max = 50,
    Default = 15,
    Flag = "AuraRange",
    Position = "left",
    Callback = function(v) Library:SetFlag("AuraRange", v) end
})

Combat:AddDropdown({
    Title = "Target Priority",
    Values = {"Closest", "Lowest HP", "Highest HP"},
    Default = "Closest",
    Flag = "TargetPriority",
    Position = "right",
    Callback = function(v) print(v) end
})

Combat:AddColorToggle({
    Title = "Hitbox Color",
    Color = Color3.fromRGB(255, 80, 80),
    Flag = "HitboxColorOn",
    Position = "right",
    Callback = function(on, c) print(on, c) end
})

PlayersTab:AddPlayerDropdown({
    Title = "Select Player",
    Description = "Live player list",
    Multi = false,
    Flag = "SelectedPlayer",
    Position = "left",
    Callback = function(Name)
        Window:Notify({
            Title = "Player",
            Content = tostring(Name),
            Type = "Info",
            Duration = 2
        })
    end
})

PlayersTab:AddDropdown({
    Title = "Team Filter",
    Values = {"All", "Enemy", "Friendly"},
    Default = "All",
    Flag = "TeamFilter",
    Position = "right",
    Callback = function(v) print(v) end
})

PlayersTab:AddParagraph({
    Title = "Info",
    Content = "PlayerDropdown refreshes when players join or leave the server.",
    Position = "left"
})

Visual:AddButton({
    Title = "Dark Theme",
    Position = "left",
    Callback = function()
        Library:SetTheme("Dark")
        Window:Notify({ Title = "Theme", Content = "Dark applied", Type = "Success", Duration = 2 })
    end
})

Visual:AddButton({
    Title = "Light Theme",
    Position = "left",
    Callback = function()
        Library:SetTheme("Light")
        Window:Notify({ Title = "Theme", Content = "Light applied", Type = "Success", Duration = 2 })
    end
})

Visual:AddButton({
    Title = "Purple Theme",
    Position = "left",
    Callback = function()
        Library:SetTheme("Purple")
        Window:Notify({ Title = "Theme", Content = "Purple applied", Type = "Info", Duration = 2 })
    end
})

Visual:AddButton({
    Title = "Ocean Theme",
    Position = "left",
    Callback = function()
        Library:SetTheme("Ocean")
        Window:Notify({ Title = "Theme", Content = "Ocean applied", Type = "Info", Duration = 2 })
    end
})

Visual:AddSlider({
    Title = "Transparency",
    Min = 0,
    Max = 50,
    Default = 6,
    Position = "right",
    Callback = function(Value)
        Library:SetTransparency(Value / 100)
    end
})

Visual:AddButton({
    Title = "Export Theme JSON",
    Position = "right",
    Callback = function()
        Library:ExportTheme()
        Window:Notify({ Title = "Theme", Content = "JSON copied to clipboard", Type = "Success", Duration = 2 })
    end
})

Visual:AddSeperator("Notifications")

Visual:AddButton({
    Title = "Info Notify",
    Position = "left",
    Callback = function()
        Window:Notify({ Title = "Info", Content = "Information message", Type = "Info", Duration = 3 })
    end
})

Visual:AddButton({
    Title = "Success Notify",
    Position = "left",
    Callback = function()
        Window:Notify({ Title = "Success", Content = "Everything worked", Type = "Success", Duration = 3 })
    end
})

Visual:AddButton({
    Title = "Warning Notify",
    Position = "right",
    Callback = function()
        Window:Notify({ Title = "Warning", Content = "Be careful", Type = "Warning", Duration = 3 })
    end
})

Visual:AddButton({
    Title = "Error Notify",
    Position = "right",
    Callback = function()
        Window:Notify({ Title = "Error", Content = "Something failed", Type = "Error", Duration = 3 })
    end
})

Visual:AddImage("Theme Preview", {
    Image = "rbxassetid://89646749075297",
    Height = 90,
    Position = "left"
})

local ConfigBox = Misc:AddLeftGroupbox("Config")

ConfigBox:AddButton({
    Title = "Save Config",
    Callback = function()
        if Library:SaveConfig("kingbanana_hub") then
            Window:Notify({ Title = "Config", Content = "Saved kingbanana_hub.json", Type = "Success", Duration = 2 })
        end
    end
})

ConfigBox:AddButton({
    Title = "Load Config",
    Callback = function()
        if Library:LoadConfig("kingbanana_hub") then
            Window:Notify({ Title = "Config", Content = "Loaded + applied to UI", Type = "Info", Duration = 2 })
        else
            Window:Notify({ Title = "Config", Content = "No config file found", Type = "Warning", Duration = 2 })
        end
    end
})

ConfigBox:AddToggle({
    Title = "Auto Save Example",
    Default = true,
    Flag = "AutoSave",
    Callback = function(v) print("AutoSave", v) end
})

local SystemBox = Misc:AddRightGroupbox("System")

SystemBox:AddButton({
    Title = "Destroy UI",
    Callback = function()
        Window:Dialog({
            Title = "Destroy UI",
            Content = "This will close and destroy the entire interface.",
            Buttons = {
                {
                    Title = "Destroy",
                    Callback = function()
                        Window:Destroy()
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function() end
                }
            }
        })
    end
})

SystemBox:AddButton({
    Title = "Notify Test",
    Callback = function()
        Window:Notify({ Title = "System", Content = "Still running", Type = "Info", Duration = 2 })
    end
})

Misc:AddParagraph({
    Title = "API Summary",
    Content = "Toggle, ColorToggle, Button, MultiButton, Keybind, Slider, Dropdown, PlayerDropdown, Input, ColorPicker, ProgressBar, Label, CodeBox, Image+Button, Paragraph, Seperator, Left/Right Groupbox, Dialog, Popup, Notify types, Tags, Live Theme, Custom Theme, Export Theme, Config Flags, Destroy, Global Keybinds, Auto Scale, Drag/Resize lines outside.",
    Position = "left"
})

Misc:AddSeperator("Global Keybind")

Misc:AddLabel({ Title = "Press F6", Content = "Registered via Library:RegisterKeybind" })

Library:RegisterKeybind("F6", function()
    Window:Notify({
        Title = "F6",
        Content = "Global keybind fired",
        Type = "Info",
        Duration = 2
    })
end)

Window:Notify({
    Title = "KingBanana",
    Content = "UI loaded. Theme, config, and all components ready.",
    Type = "Success",
    Duration = 4
})
