local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()

local Window

Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "Interactive Showcase · v0.5.0",
    Icon = "sparkles",
    Size = UDim2.fromOffset(700, 480),
    ToggleKey = Enum.KeyCode.RightShift,
    TopbarButtons = {
        {
            Icon = "info",
            Title = "About",
            Callback = function()
                Window:Dialog({
                    Title = "sh1ttybanana",
                    Content = "Version 0.5.0. Glass sidebar, top tabs, pill rows, header search and a cleaner component set.",
                    Type = "Info",
                    Buttons = { { Title = "Nice", Filled = true } }
                })
            end
        }
    }
})

local Settings = Window:Tab({ Title = "Settings", Icon = "sliders-horizontal|settings", Group = "Workspace" })
local About = Window:Tab({ Title = "About", Icon = "info", Group = "Workspace" })
local Appearance = Window:Tab({ Title = "Appearance", Icon = "palette", Group = "Workspace" })

local Insights = Window:Tab({ Title = "Insights", Icon = "layout-dashboard", Group = "All Elements" })
local Actions = Window:Tab({ Title = "API & Actions", Icon = "zap", Group = "All Elements" })
local Components = Window:Tab({ Title = "Components", Icon = "grid-3x3|layout-grid|box", Group = "All Elements" })
local Premium = Window:Tab({
    Title = "Premium",
    Icon = "crown",
    Group = "All Elements",
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

local General = Settings:AddSubtab({ Title = "General", Icon = "layout-dashboard" })
local Movement = Settings:AddSubtab({ Title = "Movement", Icon = "footprints" })
local Misc = Settings:AddSubtab({ Title = "Misc", Icon = "box" })

local Combat = General:AddSection({ Title = "Combat", Icon = "crosshair" })

Combat:AddToggle({
    Title = "Auto Farm",
    Description = "Runs the farm loop while enabled",
    Icon = "repeat",
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
    Description = "Multi select with search",
    Options = { "Players", "NPCs", "Bosses", "Chests", "Vehicles", "Pets", "Objects", "Portals", "Drops" },
    Multi = true,
    Flag = "Targets"
})

Combat:AddKeybind({
    Title = "Quick Action",
    Default = Enum.KeyCode.E,
    Mode = "Toggle",
    Flag = "QuickKey",
    Callback = function(State)
        print("Keybind state:", State)
    end
})

local Walk = Movement:AddSection({ Title = "Walking", Icon = "footprints" })

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
    Flag = "TargetRange",
    Callback = function(Low, High)
        print("Range:", Low, High)
    end
})

Movement:AddToggle({
    Title = "Infinite Jump",
    Description = "Added straight to the subtab",
    Flag = "InfJump"
})

local Notify = Misc:AddSection({ Title = "Feedback", Icon = "bell" })

Notify:AddButton({
    Title = "Send Notification",
    Description = "Slides a toast in from the corner",
    Icon = "bell",
    Callback = function()
        Window:Notify({ Title = "Hello", Content = "Glass notification", Type = "Success", Duration = 4 })
    end
})

Notify:AddButton({
    Title = "Open Dialog",
    Description = "Danger dialog with two actions",
    Icon = "triangle-alert|alert-triangle",
    Callback = function()
        Window:Dialog({
            Title = "Reset everything?",
            Content = "All saved flags in this profile will be cleared.",
            Type = "Danger",
            Buttons = {
                { Title = "Cancel" },
                {
                    Title = "Reset",
                    Filled = true,
                    Callback = function()
                        Window:Notify({ Title = "Reset", Content = "Profile cleared", Type = "Info" })
                    end
                }
            }
        })
    end
})

Notify:AddButton({
    Title = "Dialog With Input",
    Description = "Press Enter to confirm",
    Icon = "pencil",
    Callback = function()
        Window:Dialog({
            Title = "Rename profile",
            Content = "Choose a new name.",
            Type = "Question",
            Input = { Placeholder = "profile name", Default = "default" },
            Buttons = {
                { Title = "Cancel" },
                {
                    Title = "Save",
                    Filled = true,
                    Callback = function(Value)
                        print("new name", Value)
                    end
                }
            }
        })
    end
})

Notify:AddMultiButton({
    Buttons = {
        { Title = "Primary", Filled = true, Callback = function() print("primary") end },
        { Title = "Normal", Callback = function() print("normal") end }
    }
})

local Overview = About:AddSection({ Title = "About", Icon = "info" })
Overview:AddParagraph({
    Title = "sh1ttybanana 0.5.0",
    Description = "A glass UI library with a grouped sidebar, top tabs, pill rows and a header search that jumps straight to any element."
})
Overview:AddLabel({ Title = "Toggle the window with RightShift" })
Overview:AddProgress({ Title = "Showcase progress", Default = 0.65, Suffix = "%" })

local Look = Appearance:AddSection({ Title = "Window", Icon = "palette" })

Look:AddSlider({
    Title = "Window Transparency",
    Min = 0,
    Max = 60,
    Default = 0,
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

Look:AddColorpicker({ Title = "Box Color", Default = Color3.fromRGB(255, 255, 255), Flag = "BoxColor" })

Window:ThemePanel(Appearance)

local Stats = Insights:AddSubtab({ Title = "Overview", Icon = "layout-dashboard" })
local Detail = Insights:AddSubtab({ Title = "Detail", Icon = "scan|eye" })

local Live = Stats:AddSection({ Title = "Live", Icon = "activity|zap" })
Live:AddProgress({ Title = "Loading", Default = 0.4, Suffix = "%" })
Live:AddLabel({ Title = "Nothing else to report" })

local Rows = Detail:AddSection({ Title = "Rows", Icon = "list" })
for Index = 1, 6 do
    Rows:AddToggle({
        Title = "Detail option " .. Index,
        Description = "Scroll the page, the tab bar stays pinned",
        Default = Index % 2 == 0,
        Flag = "Detail" .. Index
    })
end

local Welcome = Actions:AddSubtab({ Title = "Welcome", Icon = "info" })
local Profile = Actions:AddSubtab({ Title = "Profile", Icon = "user" })
local Quick = Actions:AddSubtab({ Title = "Actions", Icon = "zap" })
local Win = Actions:AddSubtab({ Title = "Window", Icon = "app-window|layout-dashboard" })
local Lab = Actions:AddSubtab({ Title = "API Lab", Icon = "braces|code" })

Welcome:AddSection({ Title = "Welcome", Icon = "info" }):AddParagraph({
    Title = "Everything is flag driven",
    Description = "Mark an element with a Flag and it is saved, restored and searchable."
})

local Me = Profile:AddSection({ Title = "Player", Icon = "user" })
Me:AddLabel({ Title = "Signed in as " .. game.Players.LocalPlayer.DisplayName })
Me:AddInput({ Title = "Nickname", Placeholder = "type here", Flag = "Nickname" })

local Quickies = Quick:AddSection({ Title = "Quick Actions", Icon = "zap" })

Quickies:AddMultiButton({
    Buttons = {
        {
            Title = "Save",
            Icon = "save",
            Callback = function()
                Window:SaveConfig()
                Window:Notify({ Title = "Saved", Content = "Settings written to disk", Type = "Success" })
            end
        },
        {
            Title = "Load",
            Icon = "folder-open|folder",
            Callback = function()
                local Ok = Window:LoadConfig()
                Window:Notify({
                    Title = Ok and "Loaded" or "Nothing saved",
                    Content = Ok and "Settings restored" or "Save once first",
                    Type = Ok and "Success" or "Warn"
                })
            end
        },
        {
            Title = "Delete",
            Icon = "trash-2|trash",
            Callback = function()
                Window:Notify({
                    Title = Window:DeleteConfig("default") and "Deleted" or "Delete failed",
                    Content = "Profile: default",
                    Type = "Info"
                })
            end
        }
    }
})

Quickies:AddButton({
    Title = "Save Settings",
    Description = "Saves every setting marked with a Flag",
    Icon = "save",
    Callback = function()
        Window:SaveConfig()
        Window:Notify({ Title = "Saved", Content = "Settings written to disk", Type = "Success" })
    end
})

Quickies:AddButton({
    Title = "Load Settings",
    Description = "Restores whatever was last saved",
    Icon = "folder-open|folder",
    Callback = function()
        Window:LoadConfig()
    end
})

Quickies:AddButton({
    Title = "Print Current Config",
    Description = "Dumps every flagged value to the console",
    Icon = "code-xml|code",
    Callback = function()
        for Flag, Element in pairs(Window.Flags) do
            print(Flag, Element:Get())
        end
    end
})

Quickies:AddButton({
    Title = "List Saved Configs",
    Description = "Shows every local profile on disk",
    Icon = "list-checks|list",
    Callback = function()
        local Names = Window:ListConfigs()
        Window:Notify({
            Title = "Saved configs",
            Content = #Names > 0 and table.concat(Names, ", ") or "None yet",
            Type = "Info"
        })
    end
})

Window:ConfigPanel(Win)

local Api = Lab:AddSection({ Title = "Element API", Icon = "braces|code" })
local Target = Api:AddToggle({ Title = "Target Toggle", Description = "Driven by the buttons below", Flag = "LabToggle" })

Api:AddMultiButton({
    Buttons = {
        { Title = "Enable", Callback = function() Target:Set(true) end },
        { Title = "Disable", Callback = function() Target:Set(false) end },
        {
            Title = "Lock",
            Callback = function()
                Target:SetLocked(not Target.Locked, "Locked from code")
            end
        }
    }
})

Api:AddSeparator({ Title = "Cards" })

Api:AddCard({
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

local Parts = Components:AddSection({ Title = "Inputs", Icon = "keyboard" })
Parts:AddInput({ Title = "Text", Placeholder = "anything", Flag = "DemoText" })
Parts:AddInput({ Title = "Number", Placeholder = "digits only", Numeric = true, Flag = "DemoNumber" })
Parts:AddKeybind({ Title = "Hold To Run", Default = Enum.KeyCode.LeftShift, Mode = "Hold", Flag = "HoldKey" })
Parts:AddColorpicker({ Title = "Accent", Default = Color3.fromRGB(120, 180, 255), Flag = "DemoAccent" })

local Vip = Premium:AddSection({ Title = "Premium tools", Icon = "crown" })
Vip:AddToggle({ Title = "Unlimited Everything", Flag = "Unlimited" })

local Secure = Components:AddSection({ Title = "Locked controls", Icon = "lock" })

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

Settings:Select()
Window:Notify({ Title = "sh1ttybanana", Content = "Press RightShift to hide or show", Type = "Success" })
