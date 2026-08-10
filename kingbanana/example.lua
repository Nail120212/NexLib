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
    Description = "Updated features showcase",
    Icon = "89646749075297",
    Theme = "Dark",
    Transparency = 0.06,
    ToggleKey = "RightControl"
})

Window:AddTag({ Title = "v1.0", Color = Color3.fromRGB(255, 200, 50), TextColor = Color3.fromRGB(20, 20, 25) })
Window:AddTag({ Title = "UI Library", Color = Color3.fromRGB(80, 220, 120), TextColor = Color3.fromRGB(20, 20, 25) })

local ToggleTab = Window:T("Toggle", "check")
local ButtonTab = Window:T("Button", "mouse")
local InputTab = Window:T("Input", "type")
local SliderTab = Window:T("Slider", "sliders")
local DropTab = Window:T("Dropdown", "list")
local ColorTab = Window:T("Color", "palette")
local KeyTab = Window:T("Keybind", "keyboard")
local MediaTab = Window:T("Media", "image")
local ConfigTab = Window:T("Config", "settings")

ToggleTab:SetBadge(2)
ToggleTab:AddToggle({
    Title = "Enable Feature",
    Description = "Normal toggle",
    Default = false,
    Flag = "EnableFeature",
    Position = "left",
    Callback = function(v) print(v) end
})
ToggleTab:AddToggle({
    Title = "Locked Toggle",
    Locked = true,
    Locktext = "premium",
    Position = "left",
    Callback = function() end
})
ToggleTab:AddColorToggle({
    Title = "ESP Color",
    Color = Color3.fromRGB(80, 180, 255),
    Flag = "ESPToggle",
    Position = "right",
    Callback = function(on, c) print(on, c) end
})

ButtonTab:AddButton({
    Title = "Normal Button",
    Position = "left",
    Callback = function()
        Window:Notify({ Title = "Button", Content = "Clicked", Type = "Success", Duration = 2 })
    end
})
ButtonTab:AddMultiButton({
    Title = "Button Section",
    Position = "left",
    Opened = true,
    Buttons = {
        { Title = "Example Single", Callback = function()
            Window:Notify({ Title = "Single", Content = "Full width", Type = "Info", Duration = 2 })
        end },
        { Title = "Example", Callback = function()
            Window:Notify({ Title = "Example", Content = "Half", Type = "Success", Duration = 2 })
        end },
        { Title = "Example Off", Callback = function()
            Window:Notify({ Title = "Off", Content = "Half", Type = "Error", Duration = 2 })
        end },
    }
})
ButtonTab:AddButton({
    Title = "Dialog",
    Position = "right",
    Callback = function()
        Window:Dialog({
            Title = "Confirm",
            Content = "Continue?",
            Buttons = {
                { Title = "Yes", Callback = function()
                    Window:Notify({ Title = "Yes", Content = "OK", Type = "Success", Duration = 2 })
                end },
                { Title = "No", Callback = function() end },
            }
        })
    end
})

InputTab:AddInput({
    Title = "Username",
    PlaceHolder = "Type...",
    Flag = "Username",
    Position = "left",
    Callback = function(t) Library:SetFlag("Username", t) end
})
InputTab:AddCodeBox({
    Title = "Code",
    Code = "print(\"KingBanana\")",
    Height = 90,
    Position = "right"
})

SliderTab:AddSlider({
    Title = "Speed",
    Min = 1, Max = 100, Default = 16,
    Flag = "Speed",
    Position = "left",
    Callback = function(v) Library:SetFlag("Speed", v) end
})
SliderTab:AddProgressBar({ Title = "Progress", Value = 40, Position = "right" })

DropTab:AddDropdown({
    Title = "Mode",
    Values = {"Normal", "Fast", "Ultra"},
    Default = "Normal",
    Flag = "Mode",
    Position = "left",
    Callback = function(v) print(v) end
})
DropTab:AddPlayerDropdown({
    Title = "Player",
    Flag = "SelectedPlayer",
    Position = "right",
    Callback = function(n)
        Window:Notify({ Title = "Player", Content = tostring(n), Type = "Info", Duration = 2 })
    end
})

ColorTab:AddColorPicker({
    Title = "Accent",
    Default = Color3.fromRGB(158, 158, 158),
    Position = "left",
    Callback = function(c) print(c) end
})
ColorTab:AddColorToggle({
    Title = "Glow",
    Color = Color3.fromRGB(160, 100, 255),
    Flag = "GlowOn",
    Position = "right",
    Callback = function(on, c) print(on, c) end
})

KeyTab:AddKeybind({
    Title = "Action Key",
    Default = "E",
    Position = "left",
    Callback = function(k)
        Window:Notify({ Title = "Key", Content = tostring(k), Type = "Info", Duration = 2 })
    end
})
KeyTab:AddKeybind({
    Title = "Locked Key",
    Default = "Q",
    Locked = true,
    Locktext = "vip",
    Position = "right",
    Callback = function() end
})

MediaTab:AddImage("Banner", {
    Image = "89646749075297",
    Height = 100,
    Button = "Open",
    Position = "left",
    Callback = function()
        Window:Notify({ Title = "Image", Content = "Clicked", Type = "Info", Duration = 2 })
    end
})
MediaTab:AddParagraph({
    Title = "Info",
    Content = "Theme picker is top-right next to X. FPS under window. Drag/resize lines outside. Min size limited.",
    Position = "right"
})

local LeftBox = ConfigTab:AddLeftGroupbox("Config")
LeftBox:AddButton({
    Title = "Save Config JSON",
    Callback = function()
        Library:SaveConfig("kingbanana_hub")
        Window:Notify({ Title = "Config", Content = "Saved JSON", Type = "Success", Duration = 2 })
    end
})
LeftBox:AddButton({
    Title = "Load Config",
    Callback = function()
        if Library:LoadConfig("kingbanana_hub") then
            Window:Notify({ Title = "Config", Content = "Loaded", Type = "Info", Duration = 2 })
        end
    end
})
LeftBox:AddButton({
    Title = "Export Config Clipboard",
    Callback = function()
        Library:ExportConfig()
        Window:Notify({ Title = "Config", Content = "JSON copied", Type = "Success", Duration = 2 })
    end
})

local RightBox = ConfigTab:AddRightGroupbox("System")
RightBox:AddButton({
    Title = "Minimize",
    Callback = function()
        -- floating button toggles; same as logo
        Window:Notify({ Title = "Tip", Content = "Use logo / RightControl to minimize", Type = "Info", Duration = 2 })
    end
})
RightBox:AddButton({
    Title = "Destroy UI",
    Callback = function()
        Window:Dialog({
            Title = "Destroy",
            Content = "Close UI?",
            Buttons = {
                { Title = "Destroy", Callback = function() Window:Destroy() end },
                { Title = "Cancel", Callback = function() end },
            }
        })
    end
})

Library:RegisterKeybind("F6", function()
    Window:Notify({ Title = "F6", Content = "Global keybind", Type = "Info", Duration = 2 })
end)

Window:Notify({
    Title = "KingBanana",
    Content = "Theme button top-right. FPS below. Config JSON import/export ready.",
    Type = "Success",
    Duration = 4
})
