--[[
  KingBanana FULL EXAMPLE
  Upload kingbanana.lua to your raw URL first.
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/kingbanana/library.lua"))()

-- Optional key system (customize freely)
--[[
Library:KeySystem({
    Title = "KingBanana",
    Subtitle = "Access",
    Note = "Verify key to continue",
    Placeholder = "Enter your key...",
    GetKeyText = "Get Key",
    VerifyText = "Verify",
    GetKeyLink = "https://example.com/getkey",
    Key = "banana",
    Keys = {"banana", "demo"},
    SaveKey = true,
    FileName = "kb_key",
    Callback = function()
        loadHub()
    end,
    OnFail = function() end
})
return
]]

local function loadHub()
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

-- Title tags
Window:AddTag({ Title = "v1.0", Color = Color3.fromRGB(255, 200, 50), TextColor = Color3.fromRGB(20, 20, 25) })
Window:AddTag({ Title = "UI Library", Color = Color3.fromRGB(80, 220, 120), TextColor = Color3.fromRGB(20, 20, 25) })

local Main = Window:T("Main", "home")
local PlayersTab = Window:T("Players", "users")
local Visual = Window:T("Visual", "palette")
local Misc = Window:T("Misc", "settings")

-- Labels
Main:AddLabel({ Title = "General", Content = "All core controls" })

-- Toggle + Flag + Lock
Main:AddToggle({
    Title = "Enable Feature",
    Description = "Saved with Flag",
    Default = false,
    Flag = "EnableFeature",
    Position = "left",
    Callback = function(v) print("Toggle", v) end
})

Main:AddToggle({
    Title = "Locked Feature",
    Description = "Premium only",
    Default = false,
    Locked = true,
    Locktext = "premium",
    Position = "left",
    Callback = function() end
})

-- Color toggle (swatch click cycles color, track toggles on/off)
Main:AddColorToggle({
    Title = "ESP Color Toggle",
    Color = Color3.fromRGB(80, 180, 255),
    Default = false,
    Flag = "ESPToggle",
    Position = "left",
    Callback = function(on, color) print(on, color) end
})

-- Keybind
Main:AddKeybind({
    Title = "Action Key",
    Default = "E",
    Locked = false,
    Position = "left",
    Callback = function(k)
        Window:Notify({ Title = "Keybind", Content = "Pressed " .. tostring(k), Type = "Info", Duration = 2 })
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

-- Buttons
Main:AddButton({
    Title = "Normal Button",
    Description = "Single action",
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
            Window:Notify({ Title = "Single", Content = "Top full width", Type = "Info", Duration = 2 })
        end },
        { Title = "Example", Callback = function()
            Window:Notify({ Title = "Example", Content = "Half", Type = "Success", Duration = 2 })
        end },
        { Title = "Example Off", Callback = function()
            Window:Notify({ Title = "Off", Content = "Half", Type = "Error", Duration = 2 })
        end },
    }
})

-- Slider / Dropdown / Input / Color
Main:AddSlider({
    Title = "Speed",
    Min = 1, Max = 100, Default = 16, Increment = 1,
    Flag = "Speed",
    Locked = false,
    Position = "right",
    Callback = function(v) Library:SetFlag("Speed", v) end
})

Main:AddDropdown({
    Title = "Mode",
    Values = {"Normal", "Fast", "Ultra"},
    Default = "Normal",
    Multi = false,
    Flag = "Mode",
    Position = "right",
    Callback = function(v) print(v) end
})

Main:AddDropdown({
    Title = "Multi Select",
    Values = {"A", "B", "C"},
    Default = {},
    Multi = true,
    Flag = "MultiModes",
    Position = "right",
    Callback = function(v) print(v) end
})

Main:AddInput({
    Title = "Username",
    PlaceHolder = "Type...",
    Flag = "Username",
    Position = "right",
    Callback = function(t) Library:SetFlag("Username", t) end
})

Main:AddColorPicker({
    Title = "Accent",
    Default = Color3.fromRGB(158, 158, 158),
    Position = "right",
    Callback = function(c) print(c) end
})

Main:AddProgressBar({ Title = "Progress", Value = 45, Position = "right" })

-- Dialog
Main:AddButton({
    Title = "Open Dialog",
    Position = "left",
    Callback = function()
        Window:Dialog({
            Title = "Confirm",
            Content = "Extendable dialog with any number of buttons.",
            Buttons = {
                { Title = "Yes", Callback = function()
                    Window:Notify({ Title = "Yes", Content = "OK", Type = "Success", Duration = 2 })
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
    Title = "Code",
    Code = "print(\"KingBanana\")\nlocal x = 1",
    Height = 80,
    Position = "left"
})

Main:AddImage("Banner", {
    Image = "rbxassetid://89646749075297",
    Height = 90,
    Button = "Open",
    Position = "left",
    Callback = function()
        Window:Notify({ Title = "Image", Content = "Button under image", Type = "Info", Duration = 2 })
    end
})

-- Players
PlayersTab:AddPlayerDropdown({
    Title = "Select Player",
    Flag = "SelectedPlayer",
    Position = "left",
    Callback = function(n)
        Window:Notify({ Title = "Player", Content = tostring(n), Type = "Info", Duration = 2 })
    end
})

PlayersTab:AddParagraph({
    Title = "Info",
    Content = "Drag ONLY the bottom center line. Resize from bottom-right corner. ToggleKey = RightControl.",
    Position = "left"
})

-- Theme
Visual:AddButton({ Title = "Dark", Position = "left", Callback = function() Library:SetTheme("Dark") end })
Visual:AddButton({ Title = "Light", Position = "left", Callback = function() Library:SetTheme("Light") end })
Visual:AddSlider({ Title = "Transparency", Min = 0, Max = 50, Default = 6, Position = "left", Callback = function(v) Library:SetTransparency(v / 100) end })
Visual:AddButton({
    Title = "Export Theme",
    Position = "right",
    Callback = function()
        Library:ExportTheme()
        Window:Notify({ Title = "Theme", Content = "JSON copied", Type = "Success", Duration = 2 })
    end
})
Visual:AddButton({
    Title = "Custom Purple",
    Position = "right",
    Callback = function()
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
        Library:SetTheme("Purple")
    end
})
Visual:AddButton({
    Title = "Success Notify",
    Position = "left",
    Callback = function() Window:Notify({ Title = "OK", Content = "Success", Type = "Success", Duration = 2 }) end
})
Visual:AddButton({
    Title = "Error Notify",
    Position = "left",
    Callback = function() Window:Notify({ Title = "Err", Content = "Failed", Type = "Error", Duration = 2 }) end
})

-- Config groupboxes
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

local RightBox = Misc:AddRightGroupbox("System")
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

Misc:AddSeperator("Notes")
Misc:AddParagraph({
    Title = "Controls",
    Content = "Bottom center line = drag only. Bottom-right square = resize. Floating logo = open/close with same scale animation. Search filters tabs + elements.",
    Position = "left"
})

-- Global keybind manager example
Library:RegisterKeybind("F6", function()
    Window:Notify({ Title = "F6", Content = "Global keybind fired", Type = "Info", Duration = 2 })
end)

end

loadHub()
