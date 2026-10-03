--[[
    sh1ttybanana  |  example.lua   (v0.3.0-glass)
    Solid dark fluid-glass UI. Every component and config key below exists in the library.
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()

local Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "fluid glass",
    Theme = "Dark",                    -- the single theme; window is solid by default
    Size = UDim2.fromOffset(720, 520),
    -- Color = Color3.fromRGB(150, 118, 255), -- optional accent override
    -- Transparency = 0.15,                   -- optional: make the window see-through again
    ToggleKey = Enum.KeyCode.RightShift
})

local Main     = Window:Tab({ Title = "Main",     Icon = "sparkles" })
local Cards    = Window:Tab({ Title = "Cards",    Icon = "palette" })
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Main -----------------------------------------------------------------------
local Combat = Main:AddSection({ Title = "Combat" })

Combat:AddToggle({
    Title = "Auto Farm",
    Description = "Glass toggle with a lit accent track",
    Default = false,
    Flag = "AutoFarm",
    Callback = function(Value) print("Auto Farm:", Value) end
})

Combat:AddSlider({
    Title = "Walk Speed",
    Description = "Drag the knob",
    Min = 16, Max = 120, Increment = 1, Default = 16,
    Suffix = " sps",
    Flag = "WalkSpeed",
    Callback = function(Value)
        local Character = game.Players.LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then Humanoid.WalkSpeed = Value end
    end
})

Combat:AddRangeSlider({
    Title = "Target Range",
    Min = 0, Max = 100, Default = { 20, 80 },
    Flag = "TargetRange",
    Callback = function(Value) print("Range:", Value[1], Value[2]) end
})

Combat:AddDropdown({
    Title = "Target Part",
    Options = { "Head", "Torso", "Random" },
    Default = "Head",
    Flag = "TargetPart"
})

Combat:AddKeybind({
    Title = "Quick Action",
    Default = Enum.KeyCode.E,
    Mode = "Toggle",
    Flag = "QuickKey",
    Callback = function() print("Keybind fired") end
})

local Actions = Main:AddSection({ Title = "Actions" })

Actions:AddButton({
    Title = "Send Notification",
    Description = "Glass button with an accent chip",
    Callback = function()
        Window:Notify({ Title = "Hello", Content = "Fluid glass notification", Type = "Success", Duration = 4 })
    end
})

Actions:AddButton({
    Title = "Dangerous Action",
    Description = "Asks before running",
    Confirm = "Are you sure you want to run this?",
    Callback = function()
        Window:Notify({ Title = "Done", Content = "Action confirmed", Type = "Info" })
    end
})

Actions:AddMultiButton({
    Title = "Quick Row",
    Buttons = {
        { Title = "Accent", Accent = true, Callback = function() print("accent") end },
        { Title = "Normal", Callback = function() print("normal") end }
    }
})

Actions:AddProgress({ Title = "Loading", Default = 65, Suffix = "%" })

-- Cards: containers that hold ANY other component -----------------------------
local Showcase = Cards:AddSection({ Title = "Card showcase" })

-- 1) Declarative: describe the contents as a list. "Type" is any component name.
Showcase:AddCard({
    Title = "Aimbot",
    Description = "Everything in this card is described by a table",
    Icon = "crosshair",
    Collapsible = true,                -- adds a chevron to fold the card
    Actions = {                        -- little round buttons in the header
        { Icon = "settings", Tip = "Settings", Callback = function() print("card settings") end }
    },
    Items = {
        { Type = "Toggle",  Title = "Enabled",  Default = true,  Flag = "CardAimEnabled" },
        { Type = "Slider",  Title = "Smoothness", Min = 1, Max = 20, Default = 6, Flag = "CardAimSmooth" },
        { Type = "Dropdown", Title = "Bone", Options = { "Head", "Neck", "Chest" }, Default = "Head", Flag = "CardAimBone" },
        { Type = "Button",  Title = "Reset", Callback = function() print("reset") end }
    }
})

-- 2) Method style: build it, then keep adding things any time.
local Visual = Showcase:AddCard({
    Title = "Visual Pack",
    Description = "Add elements with the same Add* methods as a section",
    Icon = "eye"
})
Visual:AddToggle({ Title = "Boxes", Default = true, Flag = "CardBoxes" })
Visual:AddColorpicker({ Title = "Box Color", Default = Color3.fromRGB(150, 118, 255), Flag = "CardBoxColor" })
Visual:AddInput({ Title = "Label Text", Placeholder = "type here...", Flag = "CardLabel" })

-- 3) Build callback, with a card nested inside a card.
Showcase:AddCard({
    Title = "Advanced",
    Icon = "cpu",
    Opened = false,                    -- starts folded
    Collapsible = true,
    Build = function(Card)
        Card:AddParagraph({ Title = "Note", Content = "Cards can be nested and folded." })
        local Inner = Card:AddCard({ Title = "Nested card", Description = "A card inside a card" })
        Inner:AddSlider({ Title = "Value", Min = 0, Max = 100, Default = 50 })
    end
})

-- More controls (all rebuilt for the glass design) -----------------------------
local More = Cards:AddSection({ Title = "More controls" })

More:AddSeparator({ Text = "Toggles and groups" })

More:AddConfirmToggle({
    Title = "Risky Mode",
    Description = "Asks before turning on",
    ConfirmTitle = "Enable Risky Mode?",
    ConfirmContent = "This can get you flagged.",
    Flag = "RiskyMode"
})

More:AddToggleGroup({
    Title = "Mode",
    Options = { "Legit", "Rage", "Silent" },
    Default = "Legit",
    Flag = "AimMode"
})

More:AddTag({ Title = "Status", Name = "Undetected" })

More:AddHotbar({
    Title = "Quick Slots",
    Items = {
        { Icon = "settings", Tip = "Settings", Callback = function() print("slot 1") end },
        { Icon = "eye",      Tip = "Visuals",  Callback = function() print("slot 2") end },
        { Icon = "sparkles", Tip = "Effects",  Callback = function() print("slot 3") end }
    }
})

-- Settings -------------------------------------------------------------------
local Appearance = Settings:AddSection({ Title = "Appearance" })

Appearance:AddSlider({
    Title = "Window Transparency",
    Description = "0 = solid (default), higher = see-through",
    Min = 0, Max = 60, Default = 0, Suffix = "%",
    Callback = function(Value) Window:SetTransparency(Value / 100) end
})

Appearance:AddParagraph({ Title = "Tip", Content = "Press RightShift to hide or show the window." })

Window:Notify({ Title = "sh1ttybanana", Content = "Loaded fluid glass UI", Type = "Success" })
