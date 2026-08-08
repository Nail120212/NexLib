local Library = loadstring(game:HttpGet("YOUR_RAW_KINGBANANA_URL_HERE"))()

local Window = Library:NewWindow({
    Title = "KingBanana Hub",
    Description = "Simple Example",
    Icon = "rbxassetid://89646749075297",
    Size = UDim2.new(0, 555, 0, 350),
    Theme = "Dark",
    Transparency = 0.06,
    ToggleKey = "RightControl"
})

local Main = Window:T("Main", "home")
local Misc = Window:T("Misc", "settings")

Main:AddTag({
    Title = "v1.0",
    Color = Color3.fromRGB(255, 200, 50),
    TextColor = Color3.fromRGB(20, 20, 25)
})

Main:AddTag({
    Title = "UI Library",
    Color = Color3.fromRGB(80, 220, 120),
    TextColor = Color3.fromRGB(20, 20, 25)
})

Main:AddToggle({
    Title = "Enable Feature",
    Description = "Turns the main feature on or off",
    Default = false,
    Callback = function(Value)
        Library:SetFlag("EnableFeature", Value)
        print("Toggle:", Value)
    end
})

Main:AddKeybind({
    Title = "Action Key",
    Description = "Press to trigger action",
    Default = "E",
    Callback = function(Key)
        print("Keybind pressed:", Key)
    end
})

Main:AddButton({
    Title = "Execute",
    Description = "Runs the selected action",
    Callback = function()
        Window:Notify({
            Title = "Executed",
            Content = "Action completed successfully",
            Duration = 3
        })
    end
})

Main:AddSlider({
    Title = "Speed",
    Description = "Adjust the speed value",
    Min = 1,
    Max = 100,
    Default = 50,
    Increment = 1,
    Callback = function(Value)
        Library:SetFlag("Speed", Value)
        print("Speed:", Value)
    end
})

Main:AddDropdown({
    Title = "Mode",
    Description = "Choose operating mode",
    Values = {"Normal", "Fast", "Ultra", "Custom"},
    Default = "Normal",
    Multi = false,
    Callback = function(Value)
        Library:SetFlag("Mode", Value)
        print("Mode:", Value)
    end
})

Main:AddInput({
    Title = "Username",
    Description = "Enter target name",
    PlaceHolder = "Player name...",
    Default = "",
    Callback = function(Text)
        print("Input:", Text)
    end
})

Misc:AddSeperator("Extra")

Misc:AddToggle({
    Title = "Show FPS",
    Default = true,
    Locked = true,
    Locktext = "premium",
    Callback = function(v)
        print("FPS:", v)
    end
})

Misc:AddKeybind({
    Title = "Locked Key",
    Default = "Q",
    Locked = true,
    Locktext = "vip",
    Callback = function() end
})

Misc:AddParagraph({
    Title = "Info",
    Content = "ToggleKey opens/closes the UI. Tags, Keybinds, Lock and Config are available."
})

Misc:AddButton({
    Title = "Save Config",
    Callback = function()
        if Library:SaveConfig("myhub") then
            Window:Notify({Title = "Config", Content = "Saved", Duration = 2})
        end
    end
})

Misc:AddButton({
    Title = "Load Config",
    Callback = function()
        if Library:LoadConfig("myhub") then
            Window:Notify({Title = "Config", Content = "Loaded", Duration = 2})
        end
    end
})

Misc:AddButton({
    Title = "Notify Test",
    Callback = function()
        Window:Notify({
            Title = "Test",
            Content = "Notification system is working",
            Duration = 4
        })
    end
})
