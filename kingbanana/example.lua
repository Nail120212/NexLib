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

Window:AddTag({ Title = "v1.0", Color = Color3.fromRGB(255, 200, 50), TextColor = Color3.fromRGB(20, 20, 25) })
Window:AddTag({ Title = "UI Library", Color = Color3.fromRGB(80, 220, 120), TextColor = Color3.fromRGB(20, 20, 25) })

local Main = Window:T("Main", "home")
local Misc = Window:T("Misc", "settings")
local ThemeTab = Window:T("Theme", "palette")

Main:AddToggle({ Title = "Enable Feature", Description = "Left side", Default = false, Position = "left", Callback = function(Value) Library:SetFlag("EnableFeature", Value) end })
Main:AddKeybind({ Title = "Action Key", Default = "E", Position = "left", Callback = function(Key) print("Key:", Key) end })
Main:AddButton({ Title = "Open Dialog", Position = "left", Callback = function()
    Window:Dialog({
        Title = "Confirm",
        Content = "Do you want to continue this action?",
        Buttons = {
            { Title = "Yes", Callback = function() Window:Notify({ Title = "OK", Content = "Confirmed", Type = "Success", Duration = 2 }) end },
            { Title = "No", Callback = function() Window:Notify({ Title = "Cancelled", Content = "Action cancelled", Type = "Warning", Duration = 2 }) end },
        }
    })
end })
Main:AddMultiButton({
    Title = "Button Section",
    Position = "left",
    Buttons = {
        { Title = "Example", Callback = function() Window:Notify({ Title = "Example", Content = "Clicked", Type = "Info", Duration = 2 }) end },
        { Title = "Example Off", Callback = function() Window:Notify({ Title = "Off", Content = "Clicked", Type = "Error", Duration = 2 }) end },
        { Title = "Example Single", Callback = function() print("single") end },
    }
})
Main:AddSlider({ Title = "Speed", Min = 1, Max = 100, Default = 50, Position = "right", Callback = function(Value) Library:SetFlag("Speed", Value) end })
Main:AddDropdown({ Title = "Mode", Values = {"Normal", "Fast", "Ultra"}, Default = "Normal", Multi = true, Position = "right", Callback = function(Value) print(Value) end })
Main:AddColorPicker({ Title = "Accent", Default = Color3.fromRGB(158, 158, 158), Position = "right", Callback = function(Color) print(Color) end })
Main:AddInput({ Title = "Username", PlaceHolder = "Player...", Position = "right", Callback = function(Text) Library:SetFlag("Username", Text) end })

local LeftBox = Misc:AddLeftGroupbox("Left Box")
LeftBox:AddToggle({ Title = "Left Only", Default = true, Callback = function(v) end })
local RightBox = Misc:AddRightGroupbox("Right Box")
RightBox:AddButton({ Title = "Notify Error", Callback = function() Window:Notify({ Title = "Error", Content = "Something failed", Type = "Error", Duration = 3 }) end })
RightBox:AddKeybind({ Title = "Hotkey", Default = "Q", Callback = function(k) print(k) end })

Misc:AddParagraph({ Title = "Info", Content = "Search filters tabs and elements. Dialog/Popup, MultiButton, live theme, config flags.", Position = "left" })
Misc:AddButton({ Title = "Save Config", Position = "left", Callback = function() Library:SaveConfig("myhub") Window:Notify({ Title = "Config", Content = "Saved", Type = "Success", Duration = 2 }) end })
Misc:AddButton({ Title = "Load Config", Position = "left", Callback = function() Library:LoadConfig("myhub") Window:Notify({ Title = "Config", Content = "Loaded", Type = "Info", Duration = 2 }) end })
Misc:AddButton({ Title = "Destroy UI", Position = "right", Callback = function() Window:Destroy() end })

ThemeTab:AddButton({ Title = "Dark Theme", Position = "left", Callback = function() Library:SetTheme("Dark") end })
ThemeTab:AddButton({ Title = "Light Theme", Position = "left", Callback = function() Library:SetTheme("Light") end })
ThemeTab:AddSlider({ Title = "Transparency", Min = 0, Max = 50, Default = 6, Position = "right", Callback = function(v) Library:SetTransparency(v / 100) end })
