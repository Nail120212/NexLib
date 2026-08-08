local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/kingbanana/library.lua"))()

local Window = Library:NewWindow({
    Title = "KingBanana Hub",
    Description = "Simple Example",
    Icon = "rbxassetid://89646749075297",
    Size = UDim2.new(0, 555, 0, 350),
    Theme = "Dark",
    Transparency = 0.06,
    Color = Color3.fromRGB(158, 158, 158)
})

local Main = Window:T("Main", "home")
local Misc = Window:T("Misc", "settings")

Main:AddToggle({
    Title = "Enable Feature",
    Description = "Turns the main feature on or off",
    Default = false,
    Callback = function(Value)
        print("Toggle:", Value)
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

Main:AddColorPicker({
    Title = "Accent Color",
    Description = "Change highlight color",
    Default = Color3.fromRGB(158, 158, 158),
    Callback = function(Color)
        print("Color:", Color)
    end
})

Misc:AddSeperator("Extra")

Misc:AddToggle({
    Title = "Show FPS",
    Default = true,
    Callback = function(v)
        print("FPS:", v)
    end
})

Misc:AddParagraph({
    Title = "Info",
    Content = "Simple API: create tab then call AddToggle / AddButton / etc directly on it."
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
