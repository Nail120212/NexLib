local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()

local Window

Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "fluid glass",
    Size = UDim2.fromOffset(720, 520),
    TopbarStyle = "Mac",
    ToggleKey = Enum.KeyCode.RightShift,
    Background = nil,
    TopbarButtons = {
        {
            Icon = "sparkles",
            Title = "About",
            Callback = function()
                Window:Dialog({
                    Title = "sh1ttybanana",
                    Content = "Fluid glass UI v0.4. Floating subtab bar, header search, blur and smoother motion.",
                    Type = "Info",
                    Buttons = { { Title = "Nice", Filled = true } }
                })
            end
        }
    }
})

local Main = Window:Tab({ Title = "Main", Icon = "sparkles" })
local Visuals = Window:Tab({ Title = "Visuals", Icon = "eye" })
local Premium = Window:Tab({
    Title = "Premium",
    Icon = "crown",
    Lock = {
        Title = "Premium access",
        Description = "Enter your license key",
        Provider = "Http",
        Http = {
            Url = "https://api.yoursite.com/verify?key={key}&hwid={hwid}&nonce={nonce}",
            SuccessField = "valid",
            MessageField = "message",
            NonceField = "nonce",
            PayloadField = "token"
        },
        Remember = true,
        RememberMinutes = 30,
        OnUnlock = function(Token)
            print("server token", Token)
        end
    }
})
local Showcase = Window:Tab({ Title = "Showcase", Icon = "layout-dashboard" })
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })

local General = Main:AddSubtab({ Title = "General", Icon = "layout-dashboard" })
local Movement = Main:AddSubtab({ Title = "Movement", Icon = "footprints" })
local Misc = Main:AddSubtab({ Title = "Misc", Icon = "box" })

local ShowcaseNames = {
    { "Overview", "layout-dashboard" },
    { "Aim", "crosshair" },
    { "Visual", "eye" },
    { "World", "box" },
    { "Player", "footprints" },
    { "Teleport", "sparkles" },
    { "Config", "settings" },
    { "Credits", "crown" }
}

for Index, Entry in ipairs(ShowcaseNames) do
    local Sub = Showcase:AddSubtab({ Title = Entry[1], Icon = Entry[2] })
    local Group = Sub:AddSection({ Title = Entry[1] })
    for Row = 1, 6 do
        Group:AddToggle({
            Title = Entry[1] .. " option " .. Row,
            Description = "Scroll down and the bar at the bottom shrinks out of the way",
            Default = Row % 2 == 0,
            Flag = "Showcase" .. Index .. "_" .. Row
        })
    end
end

local Combat = General:AddSection({ Title = "Combat" })

Combat:AddToggle({
    Title = "Auto Farm",
    Description = "Neutral glass toggle",
    Default = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        print("Auto Farm:", Value)
    end
})

Combat:AddDropdown({
    Title = "Target Part",
    Options = { "Head", "Torso", "Random" },
    Default = "Head",
    Flag = "TargetPart"
})

Combat:AddDropdown({
    Title = "Targets",
    Options = { "Players", "NPCs", "Bosses", "Chests", "Vehicles", "Pets", "Objects", "Portals", "Drops" },
    Multi = true,
    Flag = "Targets"
})

Combat:AddKeybind({
    Title = "Quick Action",
    Default = Enum.KeyCode.E,
    Mode = "Toggle",
    Flag = "QuickKey",
    Callback = function()
        print("Keybind fired")
    end
})

local Walk = Movement:AddSection({ Title = "Walking" })

Walk:AddSlider({
    Title = "Walk Speed",
    Min = 16,
    Max = 120,
    Increment = 1,
    Default = 16,
    Suffix = " sps",
    Flag = "WalkSpeed",
    Callback = function(Value)
        local Character = game.Players.LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = Value
        end
    end
})

Walk:AddRangeSlider({
    Title = "Target Range",
    Min = 0,
    Max = 100,
    Default = { 20, 80 },
    Flag = "TargetRange"
})

Movement:AddToggle({
    Title = "Infinite Jump",
    Description = "Added straight to the subtab",
    Flag = "InfJump"
})

Misc:AddButton({
    Title = "Send Notification",
    Callback = function()
        Window:Notify({ Title = "Hello", Content = "Fluid glass notification", Type = "Success", Duration = 4 })
    end
})

Misc:AddButton({
    Title = "Open Dialog",
    Description = "Danger dialog with stacked actions on mobile",
    Callback = function()
        Window:Dialog({
            Title = "Reset everything?",
            Content = "All saved flags in this profile will be cleared.",
            Type = "Danger",
            Buttons = {
                { Title = "Cancel" },
                { Title = "Reset", Filled = true, Callback = function()
                    Window:Notify({ Title = "Reset", Content = "Profile cleared", Type = "Info" })
                end }
            }
        })
    end
})

Misc:AddButton({
    Title = "Dialog With Input",
    Callback = function()
        Window:Dialog({
            Title = "Rename profile",
            Content = "Choose a new name.",
            Type = "Question",
            Input = { Placeholder = "profile name", Default = "default" },
            Buttons = {
                { Title = "Cancel" },
                { Title = "Save", Filled = true, Callback = function(Value)
                    print("new name", Value)
                end }
            }
        })
    end
})

Misc:AddMultiButton({
    Title = "Quick Row",
    Buttons = {
        { Title = "Primary", Filled = true, Callback = function() print("primary") end },
        { Title = "Normal", Callback = function() print("normal") end }
    }
})

Misc:AddProgress({ Title = "Loading", Default = 0.65, Suffix = "%" })

local Esp = Visuals:AddSection({ Title = "ESP" })
Esp:AddToggle({ Title = "Boxes", Default = true, Flag = "Boxes" })
Esp:AddToggle({ Title = "Names", Default = true, Flag = "Names" })
Esp:AddColorpicker({ Title = "Box Color", Default = Color3.fromRGB(255, 255, 255), Flag = "BoxColor" })

Esp:AddCard({
    Title = "Aimbot",
    Description = "Everything here is described by a table",
    Icon = "crosshair",
    Collapsible = true,
    Items = {
        { Type = "Toggle", Title = "Enabled", Default = true, Flag = "CardAimEnabled" },
        { Type = "Slider", Title = "Smoothness", Min = 1, Max = 20, Default = 6, Flag = "CardAimSmooth" },
        { Type = "Dropdown", Title = "Bone", Options = { "Head", "Neck", "Chest" }, Default = "Head", Flag = "CardAimBone" }
    }
})

local Vip = Premium:AddSection({ Title = "Premium tools" })
Vip:AddToggle({ Title = "Unlimited Everything", Flag = "Unlimited" })

local Secure = Settings:AddSection({ Title = "Locked controls" })

Secure:AddButton({
    Title = "Wipe Data",
    Description = "Needs a key from your own function",
    Lock = {
        Title = "Admin only",
        Verify = function(Value)
            if Value == "letmein" then
                return true
            end
            return false, "Wrong key"
        end
    },
    Callback = function()
        Window:Notify({ Title = "Wiped", Content = "Data removed", Type = "Warn" })
    end
})

Secure:AddToggle({
    Title = "Server Backed",
    Description = "Needs both the key list and the HTTP check to pass",
    Lock = {
        Require = "all",
        Keys = { "KEY-1234", "KEY-5678" },
        Provider = "Http",
        Http = {
            Url = "https://api.yoursite.com/verify?key={key}&hwid={hwid}&nonce={nonce}",
            SuccessField = "valid",
            NonceField = "nonce"
        }
    },
    Flag = "ServerBacked"
})

local Look = Settings:AddSection({ Title = "Appearance" })

Look:AddSlider({
    Title = "Window Transparency",
    Min = 0,
    Max = 60,
    Default = 30,
    Suffix = "%",
    Callback = function(Value)
        Window:SetTransparency(Value / 100)
    end
})

Look:AddInput({
    Title = "Background Image",
    Description = "Asset id or image url, empty to clear",
    Placeholder = "rbxassetid://0",
    Callback = function(Value)
        Window:SetBackground(Value ~= "" and { Image = Value, Transparency = 0.55, Dim = 0.45 } or nil)
    end
})

Window:Notify({ Title = "sh1ttybanana", Content = "Press RightShift to hide or show", Type = "Success" })
