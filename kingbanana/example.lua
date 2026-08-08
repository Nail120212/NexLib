local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/kingbanana/library.lua"))()

local Window = Library:NewWindow({
    Title = "KingBanana Hub",
    Description = "Full API Example",
    Icon = "rbxassetid://89646749075297",
    Size = UDim2.new(0, 555, 0, 350),
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
local Misc = Window:T("Misc", "settings")
local ThemeTab = Window:T("Theme", "palette")

Main:AddToggle({
    Title = "Enable Feature",
    Description = "Left side by default",
    Default = false,
    Position = "left",
    Callback = function(Value)
        Library:SetFlag("EnableFeature", Value)
        print("Toggle:", Value)
    end
})

Main:AddKeybind({
    Title = "Action Key",
    Description = "Press to trigger",
    Default = "E",
    Position = "left",
    Callback = function(Key)
        print("Keybind:", Key)
    end
})

Main:AddButton({
    Title = "Execute",
    Description = "Runs action",
    Position = "left",
    Callback = function()
        Window:Notify({
            Title = "Executed",
            Content = "Action completed",
            Duration = 3
        })
    end
})

Main:AddSlider({
    Title = "Speed",
    Description = "Adjust speed",
    Min = 1,
    Max = 100,
    Default = 50,
    Increment = 1,
    Position = "left",
    Callback = function(Value)
        Library:SetFlag("Speed", Value)
        print("Speed:", Value)
    end
})

Main:AddDropdown({
    Title = "Mode",
    Description = "Choose mode",
    Values = {"Normal", "Fast", "Ultra"},
    Default = "Normal",
    Position = "right",
    Callback = function(Value)
        Library:SetFlag("Mode", Value)
        print("Mode:", Value)
    end
})

Main:AddInput({
    Title = "Username",
    Description = "Enter name",
    PlaceHolder = "Player...",
    Default = "",
    Position = "right",
    Callback = function(Text)
        Library:SetFlag("Username", Text)
        print("Input:", Text)
    end
})

Main:AddColorPicker({
    Title = "Accent",
    Description = "Pick color",
    Default = Color3.fromRGB(158, 158, 158),
    Position = "right",
    Callback = function(Color)
        print("Color:", Color)
    end
})

Misc:AddSeperator("Groupbox API")

local LeftBox = Misc:AddLeftGroupbox("Left Box")
LeftBox:AddToggle({
    Title = "Left Only",
    Default = true,
    Callback = function(v) print(v) end
})
LeftBox:AddSlider({
    Title = "Value",
    Min = 0,
    Max = 10,
    Default = 5,
    Callback = function(v) print(v) end
})

local RightBox = Misc:AddRightGroupbox("Right Box")
RightBox:AddButton({
    Title = "Right Button",
    Callback = function()
        Window:Notify({Title = "Right", Content = "From right groupbox", Duration = 2})
    end
})
RightBox:AddKeybind({
    Title = "Hotkey",
    Default = "Q",
    Callback = function(k) print(k) end
})

Misc:AddParagraph({
    Title = "Info",
    Content = "Position = left/right on components. Tags on window title. ToggleKey opens UI. Live theme switch below.",
    Position = "left"
})

Misc:AddToggle({
    Title = "Locked Feature",
    Default = false,
    Locked = true,
    Locktext = "premium",
    Position = "right",
    Callback = function() end
})

Misc:AddButton({
    Title = "Save Config",
    Position = "left",
    Callback = function()
        if Library:SaveConfig("myhub") then
            Window:Notify({Title = "Config", Content = "Saved", Duration = 2})
        end
    end
})

Misc:AddButton({
    Title = "Load Config",
    Position = "left",
    Callback = function()
        if Library:LoadConfig("myhub") then
            Window:Notify({Title = "Config", Content = "Loaded", Duration = 2})
        end
    end
})

Misc:AddImage("Banner", {
    Image = "rbxassetid://89646749075297",
    Height = 100,
    Position = "right"
})

ThemeTab:AddButton({
    Title = "Dark Theme",
    Position = "left",
    Callback = function()
        Library:SetTheme("Dark")
        Window:Notify({Title = "Theme", Content = "Switched to Dark", Duration = 2})
    end
})

ThemeTab:AddButton({
    Title = "Light Theme",
    Position = "left",
    Callback = function()
        Library:SetTheme("Light")
        Window:Notify({Title = "Theme", Content = "Switched to Light", Duration = 2})
    end
})

ThemeTab:AddSlider({
    Title = "Transparency",
    Min = 0,
    Max = 50,
    Default = 6,
    Increment = 1,
    Position = "left",
    Callback = function(v)
        Library:SetTransparency(v / 100)
    end
})

ThemeTab:AddButton({
    Title = "Custom Purple Theme",
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
        Window:Notify({Title = "Theme", Content = "Custom Purple applied", Duration = 2})
    end
})
