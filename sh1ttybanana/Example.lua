local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()

local Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "full featured",
    Color = Color3.fromRGB(179, 0, 255),
    Size = UDim2.new(0, 600, 0, 420),
    Logo = "rbxassetid://89646749075297",
    Icon = "rbxassetid://89646749075297",
    FloatTransparency = 0.45
})

local Main = Window:T("General", "home")
local Settings = Window:T("Settings", "settings")
local Components = Window:T("Components", "layout-grid")

local Admin = Window:T({
    Title = "Admin",
    Icon = "shield",
    Locked = true,
    LockPassword = "admin123",
    LockTitle = "Private Tab",
    LockDesc = "Enter the password to unlock",
    RememberKey = "sh1ttybanana_admin"
})

local About = Window:T("About", "info")

local Sec1 = Main:AddSection("Main Controls")

Sec1:AddToggle({
    Title = "Enable Feature",
    Description = "Smooth toggle",
    Default = false,
    Callback = function(v)
        print("Toggle:", v)
    end
})

Sec1:AddSlider({
    Title = "Speed",
    Description = "0 - 100",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 1,
    Callback = function(v)
        print("Slider:", v)
    end
})

Sec1:AddButton({
    Title = "Run Action",
    Description = "Click me",
    Callback = function()
        print("Button clicked")
    end
})

Sec1:AddKeybind({
    Title = "Toggle Key",
    Description = "Bind a key",
    Default = Enum.KeyCode.RightControl,
    Callback = function(k)
        print("Keybind:", k.Name)
    end
})

Sec1:AddDivider()

Sec1:AddInput({
    Title = "Username",
    Description = "Type something",
    PlaceHolder = "Enter name...",
    Default = "",
    Callback = function(t)
        print("Input:", t)
    end
})

Sec1:AddDropdown({
    Title = "Mode",
    Description = "Select one",
    Values = {"Normal", "Fast", "Extreme"},
    Default = "Normal",
    Callback = function(v)
        print("Dropdown:", v)
    end
})

Sec1:AddColorpicker({
    Title = "Accent Color",
    Description = "Real colorpicker",
    Default = Color3.fromRGB(179, 0, 255),
    Callback = function(c)
        print("Color:", c)
    end
})

Sec1:AddTag({
    Title = "BETA",
    Color = Color3.fromRGB(179, 0, 255)
})

Sec1:AddParagraph({
    Title = "Info",
    Content = "All new elements included"
})

local Sec2 = Settings:AddSection("Appearance")

Sec2:AddToggle({
    Title = "Transparent UI",
    Default = true,
    Callback = function() end
})

Sec2:AddColorpicker({
    Title = "Theme Accent",
    Default = Color3.fromRGB(0, 170, 255),
    Callback = function() end
})

Sec2:AddMultiButton({
    Full = {
        Title = "Export Config",
        Callback = function()
            print("Export config")
        end
    },
    Left = {
        Title = "Import",
        Callback = function()
            print("Import config")
        end
    },
    Right = {
        Title = "Reset",
        Callback = function()
            print("Reset config")
        end
    }
})

local Sec3 = Components:AddSection("All Elements")

Sec3:AddButton({ Title = "Button", Callback = function() end })
Sec3:AddToggle({ Title = "Toggle", Default = true, Callback = function() end })
Sec3:AddSlider({ Title = "Slider", Min = 1, Max = 10, Default = 5, Callback = function() end })
Sec3:AddDropdown({ Title = "Dropdown", Values = {"A", "B", "C"}, Callback = function() end })
Sec3:AddInput({ Title = "Input", PlaceHolder = "Type...", Callback = function() end })
Sec3:AddColorpicker({ Title = "Colorpicker", Default = Color3.fromRGB(255, 100, 100), Callback = function() end })
Sec3:AddKeybind({ Title = "Keybind", Default = Enum.KeyCode.F, Callback = function() end })
Sec3:AddTag({ Title = "NEW", Color = Color3.fromRGB(0, 200, 100) })
Sec3:AddDivider()

Sec3:AddMultiButton({
    Full = { Title = "Full Width Button", Callback = function() print("Full") end },
    Left = { Title = "Half Left", Callback = function() print("Left") end },
    Right = { Title = "Half Right", Callback = function() print("Right") end }
})

Sec3:AddCodeblock({
    Title = "Code Block",
    Code = "print('Hello from sh1ttybanana')\nprint('Run works')",
    Callback = function(code)
        print("Code ran")
    end
})

Sec3:AddParagraph({ Title = "Paragraph", Content = "Everything is here" })

local SecAdmin = Admin:AddSection("Restricted")

SecAdmin:AddParagraph({
    Title = "Admin Only",
    Content = "Password: admin123"
})

SecAdmin:AddButton({
    Title = "Secret Action",
    Callback = function()
        print("Admin action")
    end
})

SecAdmin:AddToggle({
    Title = "God Mode",
    Default = false,
    Callback = function(v)
        print("God:", v)
    end
})

local SecAbout = About:AddSection("Credits")

SecAbout:AddParagraph({
    Title = "sh1ttybanana",
    Content = "Your original base + real colorpicker, keybind, multibutton, codeblock, lock tabs, floating restyle, smoother animations"
})
