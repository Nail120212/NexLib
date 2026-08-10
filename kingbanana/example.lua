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
    Description = "Full API Showcase",
    Icon = "89646749075297",
    Logo = "89646749075297",
    Theme = "Dark",
    Transparency = 0.06,
    ToggleKey = "RightControl",
    CustomBackground = false,
    CustomBackgroundId = "6015897843",
    Extras = {
        FpsTag = true,
        ResizeLine = true,
        AutoScale = true,
        -- Size = UDim2.new(0, 560, 0, 380), -- only when AutoScale = false
    }
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

local ToggleTab = Window:T("Toggle", "check")
local ButtonTab = Window:T("Button", "mouse")
local InputTab = Window:T("Input", "type")
local SliderTab = Window:T("Slider", "sliders")
local DropTab = Window:T("Dropdown", "list")
local ColorTab = Window:T("Color", "palette")
local KeyTab = Window:T("Keybind", "keyboard")
local MediaTab = Window:T("Media", "image")
local ThemeTab = Window:T("Theme", "paintbrush")
local ConfigTab = Window:T("Config", "settings")

ToggleTab:SetBadge(2)

local TLeft = ToggleTab:AddSection({
    Title = "General",
    Tag = "Core",
    Opened = true,
    Position = "left"
})

TLeft:AddToggle({
    Title = "Enable Feature",
    Description = "Normal toggle with Flag",
    Default = false,
    Flag = "EnableFeature",
    Callback = function(Value)
        print("EnableFeature:", Value)
    end
})

TLeft:AddToggle({
    Title = "Locked Toggle",
    Description = "Needs premium",
    Default = false,
    Locked = true,
    Locktext = "premium",
    Callback = function() end
})

local TRight = ToggleTab:AddSection({
    Title = "ESP",
    Tag = "Visual",
    Opened = true,
    Position = "right"
})

TRight:AddColorToggle({
    Title = "ESP Color Toggle",
    Description = "Swatch cycles color",
    Color = Color3.fromRGB(80, 180, 255),
    Default = false,
    Flag = "ESPToggle",
    Callback = function(Enabled, Color)
        print("ESP", Enabled, Color)
    end
})

TRight:AddColorToggle({
    Title = "Hitbox",
    Color = Color3.fromRGB(255, 80, 80),
    Default = true,
    Flag = "HitboxOn",
    Callback = function(on, c) print(on, c) end
})

local BLeft = ButtonTab:AddSection({
    Title = "Actions",
    Tag = "UI",
    Opened = true,
    Position = "left"
})

BLeft:AddButton({
    Title = "Normal Button",
    Description = "Single action",
    Callback = function()
        Window:Notify({
            Title = "Button",
            Content = "Normal button clicked",
            Type = "Success",
            Duration = 2
        })
    end
})

BLeft:AddButton({
    Title = "Open Dialog",
    Callback = function()
        Window:Dialog({
            Title = "Confirm Action",
            Content = "Extendable dialog with multiple buttons. Continue?",
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

BLeft:AddButton({
    Title = "Popup",
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

local BRight = ButtonTab:AddSection({
    Title = "Multi",
    Tag = "Grid",
    Opened = true,
    Position = "right"
})

BRight:AddMultiButton({
    Title = "Button Section",
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

local BClosed = ButtonTab:AddSection({
    Title = "Collapsed",
    Tag = "Hidden",
    Opened = false,
    Position = "right"
})

BClosed:AddButton({
    Title = "Inside collapsed section",
    Callback = function()
        Window:Notify({ Title = "Collapsed", Content = "Still works", Type = "Info", Duration = 2 })
    end
})

local ILeft = InputTab:AddSection({ Title = "Text", Tag = "Input", Opened = true, Position = "left" })

ILeft:AddInput({
    Title = "Username",
    Description = "Type anything",
    PlaceHolder = "Player name...",
    Default = "",
    Flag = "Username",
    Callback = function(Text)
        Library:SetFlag("Username", Text)
    end
})

ILeft:AddInput({
    Title = "Webhook",
    PlaceHolder = "https://...",
    Flag = "Webhook",
    Callback = function(t) print(t) end
})

local IRight = InputTab:AddSection({ Title = "Code", Opened = true, Position = "right" })

IRight:AddCodeBox({
    Title = "Script Snippet",
    Code = "print(\"Hello KingBanana\")\nlocal speed = 16\nprint(speed)",
    Height = 100
})

local SLeft = SliderTab:AddSection({ Title = "Values", Tag = "Range", Opened = true, Position = "left" })

SLeft:AddSlider({
    Title = "Speed",
    Description = "Walk speed",
    Min = 1,
    Max = 100,
    Default = 16,
    Increment = 1,
    Flag = "Speed",
    Callback = function(Value)
        Library:SetFlag("Speed", Value)
    end
})

SLeft:AddSlider({
    Title = "Range",
    Min = 5,
    Max = 50,
    Default = 15,
    Flag = "Range",
    Callback = function(v) print(v) end
})

local SRight = SliderTab:AddSection({ Title = "Progress", Opened = true, Position = "right" })

SRight:AddProgressBar({
    Title = "Load Progress",
    Value = 42,
    Min = 0,
    Max = 100
})

SRight:AddProgressBar({
    Title = "Farm %",
    Value = 20
})

local DLeft = DropTab:AddSection({ Title = "Select", Tag = "List", Opened = true, Position = "left" })

DLeft:AddDropdown({
    Title = "Mode",
    Description = "Select one mode",
    Values = {"Normal", "Fast", "Ultra", "Custom"},
    Default = "Normal",
    Multi = false,
    Flag = "Mode",
    Callback = function(Value)
        print("Mode:", Value)
    end
})

DLeft:AddDropdown({
    Title = "Multi Select",
    Description = "Pick multiple",
    Values = {"Option A", "Option B", "Option C", "Option D"},
    Default = {},
    Multi = true,
    Flag = "MultiModes",
    Callback = function(Value)
        print("Multi:", Value)
    end
})

local DRight = DropTab:AddSection({ Title = "Players", Opened = true, Position = "right" })

DRight:AddPlayerDropdown({
    Title = "Select Player",
    Description = "Live player list",
    Multi = false,
    Flag = "SelectedPlayer",
    Callback = function(Name)
        Window:Notify({
            Title = "Player",
            Content = tostring(Name),
            Type = "Info",
            Duration = 2
        })
    end
})

local CLeft = ColorTab:AddSection({ Title = "Pickers", Tag = "HSV", Opened = true, Position = "left" })

CLeft:AddColorPicker({
    Title = "Accent Color",
    Description = "Real HSV picker",
    Default = Color3.fromRGB(158, 158, 158),
    Callback = function(Color)
        print("Color:", Color)
    end
})

CLeft:AddColorPicker({
    Title = "ESP Color",
    Default = Color3.fromRGB(80, 180, 255),
    Callback = function(c) print(c) end
})

local CRight = ColorTab:AddSection({ Title = "Toggles", Opened = true, Position = "right" })

CRight:AddColorToggle({
    Title = "Glow",
    Color = Color3.fromRGB(160, 100, 255),
    Flag = "GlowOn",
    Callback = function(on, c) print(on, c) end
})

local KLeft = KeyTab:AddSection({ Title = "Binds", Tag = "Keys", Opened = true, Position = "left" })

KLeft:AddKeybind({
    Title = "Action Key",
    Description = "Press to fire",
    Default = "E",
    Callback = function(Key)
        Window:Notify({
            Title = "Keybind",
            Content = "Pressed " .. tostring(Key),
            Type = "Info",
            Duration = 2
        })
    end
})

KLeft:AddKeybind({
    Title = "Locked Key",
    Default = "Q",
    Locked = true,
    Locktext = "vip",
    Callback = function() end
})

local KRight = KeyTab:AddSection({ Title = "Extra", Opened = true, Position = "right" })

KRight:AddKeybind({
    Title = "Secondary",
    Default = "F",
    Callback = function(k) print(k) end
})

local MLeft = MediaTab:AddSection({ Title = "Images", Tag = "Media", Opened = true, Position = "left" })

MLeft:AddImage("Banner", {
    Image = "89646749075297",
    Height = 110,
    Button = "Open Link",
    Callback = function()
        Window:Notify({
            Title = "Image",
            Content = "Button under image clicked",
            Type = "Info",
            Duration = 2
        })
    end
})

MLeft:AddImage("Logo", {
    Image = "89646749075297",
    Height = 80
})

local MRight = MediaTab:AddSection({ Title = "Text", Opened = true, Position = "right" })

MRight:AddParagraph({
    Title = "Paragraph",
    Content = "Asset ids work as numbers only. Icon = \"89646749075297\". Drag = bottom center line. Resize = L lines outside. FPS inside bottom center."
})

MRight:AddSeperator("Divider")
MRight:AddLabel({ Title = "Label", Content = "Live text label" })

local ThLeft = ThemeTab:AddSection({ Title = "Themes", Tag = "Live", Opened = true, Position = "left" })

ThLeft:AddButton({
    Title = "Dark Theme",
    Callback = function()
        Library:SetTheme("Dark")
        Window:Notify({ Title = "Theme", Content = "Dark applied", Type = "Success", Duration = 2 })
    end
})

ThLeft:AddButton({
    Title = "Light Theme",
    Callback = function()
        Library:SetTheme("Light")
        Window:Notify({ Title = "Theme", Content = "Light applied", Type = "Success", Duration = 2 })
    end
})

ThLeft:AddButton({
    Title = "Purple Theme",
    Callback = function()
        Library:SetTheme("Purple")
        Window:Notify({ Title = "Theme", Content = "Purple applied", Type = "Info", Duration = 2 })
    end
})

ThLeft:AddButton({
    Title = "Ocean Theme",
    Callback = function()
        Library:SetTheme("Ocean")
        Window:Notify({ Title = "Theme", Content = "Ocean applied", Type = "Info", Duration = 2 })
    end
})

local ThRight = ThemeTab:AddSection({ Title = "Notify + FX", Opened = true, Position = "right" })

ThRight:AddSlider({
    Title = "Transparency",
    Min = 0,
    Max = 50,
    Default = 6,
    Callback = function(Value)
        Library:SetTransparency(Value / 100)
    end
})

ThRight:AddButton({
    Title = "Export Theme JSON",
    Callback = function()
        Library:ExportTheme()
        Window:Notify({ Title = "Theme", Content = "JSON copied", Type = "Success", Duration = 2 })
    end
})

ThRight:AddButton({
    Title = "Info Notify",
    Callback = function()
        Window:Notify({ Title = "Info", Content = "Information message", Type = "Info", Duration = 3 })
    end
})

ThRight:AddButton({
    Title = "Success Notify",
    Callback = function()
        Window:Notify({ Title = "Success", Content = "Everything worked", Type = "Success", Duration = 3 })
    end
})

ThRight:AddButton({
    Title = "Warning Notify",
    Callback = function()
        Window:Notify({ Title = "Warning", Content = "Be careful", Type = "Warning", Duration = 3 })
    end
})

ThRight:AddButton({
    Title = "Error Notify",
    Callback = function()
        Window:Notify({ Title = "Error", Content = "Something failed", Type = "Error", Duration = 3 })
    end
})

local CfLeft = ConfigTab:AddLeftGroupbox({ Title = "Config", Tag = "JSON", Opened = true })

CfLeft:AddButton({
    Title = "Save Config",
    Callback = function()
        if Library:SaveConfig("kingbanana_hub") then
            Window:Notify({ Title = "Config", Content = "Saved kingbanana_hub.json", Type = "Success", Duration = 2 })
        end
    end
})

CfLeft:AddButton({
    Title = "Load Config",
    Callback = function()
        if Library:LoadConfig("kingbanana_hub") then
            Window:Notify({ Title = "Config", Content = "Loaded + applied", Type = "Info", Duration = 2 })
        else
            Window:Notify({ Title = "Config", Content = "No config file found", Type = "Warning", Duration = 2 })
        end
    end
})

CfLeft:AddButton({
    Title = "Export Config Clipboard",
    Callback = function()
        Library:ExportConfig()
        Window:Notify({ Title = "Config", Content = "JSON copied", Type = "Success", Duration = 2 })
    end
})

CfLeft:AddToggle({
    Title = "Auto Save Flag",
    Default = true,
    Flag = "AutoSave",
    Callback = function(v) print("AutoSave", v) end
})

local CfRight = ConfigTab:AddRightGroupbox({ Title = "System", Opened = true })

CfRight:AddParagraph({
    Title = "Controls",
    Content = "Drag = bottom center curved line outside. Resize = L curved lines outside. Theme button top-right. FPS inside bottom center. Lock badges hide under 520px width."
})

CfRight:AddButton({
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
    Content = "Full example loaded. Theme picker top-right. Sections + tags ready.",
    Type = "Success",
    Duration = 4
})
