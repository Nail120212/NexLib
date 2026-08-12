local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()

local Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "full featured",
    Color = Color3.fromRGB(179, 0, 255),
    Size = UDim2.new(0, 620, 0, 440),
    Logo = "rbxassetid://89646749075297",
    Icon = "rbxassetid://89646749075297",
    Transparent = 0.07,
    AutoScale = true
})

Window:Tag({ Title = "v1.0", Color = Color3.fromRGB(236, 162, 1), Icon = "tag" })
Window:Tag({ Title = "UI Library", Color = Color3.fromRGB(16, 197, 80), Icon = "box" })

Window:Section({ Title = "Section without tabs" })

local OpenedSec = Window:Section({ Title = "Opened Section", Opened = true })
local Main = OpenedSec:Tab("General", "home")
local Settings = OpenedSec:Tab("Settings", "settings")

local ClosedSec = Window:Section({ Title = "Closed Section", Opened = false })
local Components = ClosedSec:Tab("Components", "layout-grid")
local About = ClosedSec:Tab("About", "info")

local Admin = Window:T({
    Title = "Admin",
    Icon = "shield",
    Locked = true,
    LockPassword = "admin123",
    LockTitle = "Private Tab",
    LockDesc = "Enter the password to unlock",
    RememberKey = "sh1ttybanana_admin"
})

local Sec1 = Main:AddSection("Main Controls")

Sec1:AddToggle({
    Title = "Enable Feature",
    Description = "Smooth toggle",
    Default = false,
    Callback = function(v) print("Toggle:", v) end
})

Sec1:AddSlider({
    Title = "UI Transparency",
    Description = "Live transparency",
    Min = 0, Max = 80, Default = 7, Increment = 1,
    Callback = function(v) Window:SetTransparency(v / 100) end
})

Sec1:AddButton({
    Title = "Run Action",
    Callback = function()
        Window:Notify({ Title = "Action", Content = "Button clicked", Type = "Success", Duration = 3 })
    end
})

Sec1:AddKeybind({
    Title = "Toggle Key",
    Default = Enum.KeyCode.RightControl,
    Callback = function(k) print("Key:", k.Name) end
})

Sec1:AddSpace(6)
Sec1:AddDivider()

Sec1:AddInput({ Title = "Username", PlaceHolder = "Enter name...", Callback = function(t) print(t) end })
Sec1:AddDropdown({ Title = "Mode", Values = {"Normal", "Fast", "Extreme"}, Default = "Normal", Callback = function(v) print(v) end })
Sec1:AddColorpicker({ Title = "Accent", Default = Color3.fromRGB(179, 0, 255), Callback = function(c) print(c) end })
Sec1:AddParagraph({ Title = "Info", Content = "Sidebar TabSection · Colorpicker fix · Slider polish · Stacked notifies" })

local Sec2 = Settings:AddSection("Appearance & Config")

Sec2:AddToggle({
    Title = "Light Theme Hint",
    Default = false,
    Callback = function()
        Window:Notify({ Title = "Theme", Content = "Use palette icon top-right", Type = "Info" })
    end
})

Sec2:AddColorpicker({ Title = "Theme Accent", Default = Color3.fromRGB(0, 170, 255), Callback = function() end })

Sec2:AddMultiButton({
    Full = { Title = "Export Config", Callback = function()
        Window:SaveConfig("sh1ttybanana")
        Window:Notify({ Title = "Config", Content = "Exported", Type = "Success" })
    end },
    Left = { Title = "Import", Callback = function()
        Window:LoadConfig("sh1ttybanana")
        Window:Notify({ Title = "Config", Content = "Imported", Type = "Info" })
    end },
    Right = { Title = "Reset", Callback = function()
        Window:Notify({ Title = "Config", Content = "Reset", Type = "Warn" })
    end }
})

Sec2:AddButton({
    Title = "Show Dialog",
    Callback = function()
        Window:Dialog({
            Title = "Confirm",
            Content = "Are you sure?",
            Buttons = {
                { Title = "Cancel", Variant = "Secondary", Callback = function() end },
                { Title = "OK", Variant = "Primary", Callback = function()
                    Window:Notify({ Title = "Dialog", Content = "Confirmed", Type = "Success" })
                end }
            }
        })
    end
})

Sec2:AddButton({
    Title = "Test All Notifies",
    Callback = function()
        Window:Notify({ Title = "Info", Content = "Info type", Type = "Info", Duration = 3 })
        task.wait(0.25)
        Window:Notify({ Title = "Success", Content = "Success type", Type = "Success", Duration = 3 })
        task.wait(0.25)
        Window:Notify({ Title = "Warn", Content = "Warn type", Type = "Warn", Duration = 3 })
        task.wait(0.25)
        Window:Notify({ Title = "Error", Content = "Error type", Type = "Error", Duration = 3 })
    end
})

local Sec3 = Components:AddSection("All Elements")

Sec3:AddButton({ Title = "Button", Callback = function() end })
Sec3:AddToggle({ Title = "Toggle", Default = true, Callback = function() end })
Sec3:AddSlider({ Title = "Slider", Min = 1, Max = 10, Default = 5, Callback = function() end })
Sec3:AddDropdown({ Title = "Dropdown", Values = {"A", "B", "C"}, Multi = true, Callback = function() end })
Sec3:AddInput({ Title = "Input", PlaceHolder = "Type...", Callback = function() end })
Sec3:AddColorpicker({ Title = "Colorpicker", Default = Color3.fromRGB(255, 100, 100), Callback = function() end })
Sec3:AddKeybind({ Title = "Keybind", Default = Enum.KeyCode.F, Callback = function() end })
Sec3:AddSpace(6)
Sec3:AddDivider()

Sec3:AddMultiButton({
    Full = { Title = "Full Width", Callback = function() print("Full") end },
    Left = { Title = "Left", Callback = function() print("Left") end },
    Right = { Title = "Right", Callback = function() print("Right") end }
})

Sec3:AddCodeblock({
    Title = "Code Block",
    Code = "print('sh1ttybanana')\nprint('full example')",
    Callback = function() end
})

local SecAdmin = Admin:AddSection("Restricted")
SecAdmin:AddParagraph({ Title = "Admin Only", Content = "Password: admin123" })
SecAdmin:AddButton({ Title = "Secret", Callback = function()
    Window:Notify({ Title = "Admin", Content = "Secret action", Type = "Success" })
end })
SecAdmin:AddToggle({ Title = "God Mode", Default = false, Callback = function(v) print("God:", v) end })

local SecAbout = About:AddSection("Credits")
SecAbout:AddParagraph({
    Title = "sh1ttybanana",
    Content = "Window:Section (sidebar TabSection) · Colorpicker color fix · Wind-style slider · Stacked typed notifies"
})

Window:Notify({ Title = "Loaded", Content = "sh1ttybanana ready", Type = "Success", Duration = 3 })
