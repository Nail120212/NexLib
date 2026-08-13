local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua"))()

local groqapi = "gsk_YOURKEYHERE"
local groqprompt = "You are a helpful assistant inside a Roblox cheat menu called sh1ttybanana. Help users understand features. Use **bold** for important things. To send the user to a tab write [TAB:TabName]. Keep replies short."

local Window = Library:NewWindow({
    Title       = "sh1ttybanana",
    Description = "full featured",
    Logo        = "rbxassetid://89646749075297",
    Color       = Color3.fromRGB(179, 0, 255),
    Size        = UDim2.new(0, 580, 0, 380),
    Transparent = 0.07,
    AutoScale   = true,
    GroqAPI     = groqapi,
    GroqPrompt  = groqprompt,
})

Window:Tag({ Title = "v1.0",  Color = Color3.fromRGB(255, 165, 0)  })
Window:Tag({ Title = "beta",  Color = Color3.fromRGB(50, 180, 100) })

local GeneralTab  = Window:T({ Title = "General",  Icon = "layout-dashboard" })
local CombatTab   = Window:T({ Title = "Combat",   Icon = "crosshair"        })
local VisualTab   = Window:T({ Title = "Visual",   Icon = "eye"              })
local WorldTab    = Window:T({ Title = "World",    Icon = "globe"            })
local MiscTab     = Window:T({ Title = "Misc",     Icon = "box"              })
local SettingsTab = Window:T({ Title = "Settings", Icon = "settings"         })

-- ══════════════════════════════════════════════════════════════
--  GENERAL TAB
-- ══════════════════════════════════════════════════════════════
local MovSec  = GeneralTab:AddSection("Movement")
local CharSec = GeneralTab:AddSection("Character")
local InfoSec = GeneralTab:AddSection("Info")

MovSec:AddSlider({
    Title = "Walk Speed", Min = 16, Max = 500, Increment = 1, Default = 16,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = v
        end
    end,
})

MovSec:AddSlider({
    Title = "Jump Power", Min = 7, Max = 500, Increment = 1, Default = 50,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = v
        end
    end,
})

MovSec:AddToggle({
    Title = "Noclip", Default = false,
    Callback = function(state)
        local noclip = state
        game:GetService("RunService").Stepped:Connect(function()
            if noclip then
                local char = game.Players.LocalPlayer.Character
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end
        end)
    end,
})

MovSec:AddToggle({
    Title = "Fly", Default = false,
    Callback = function(state) print("Fly:", state) end,
})

MovSec:AddKeybind({
    Title = "Fly Keybind", Default = Enum.KeyCode.F,
    Callback = function(key) print("Fly key:", key.Name) end,
})

CharSec:AddSlider({
    Title = "Gravity", Min = 0, Max = 200, Increment = 1, Default = 196,
    Callback = function(v) workspace.Gravity = v end,
})

CharSec:AddToggle({
    Title = "Infinite Jump", Default = false,
    Callback = function(state)
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if state then
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end,
})

CharSec:AddButton({
    Title = "Respawn",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
        end
    end,
})

CharSec:AddInput({
    Title = "Chat Message", PlaceHolder = "Type and press enter...",
    Callback = function(txt)
        game:GetService("Players").LocalPlayer:Chat(txt)
    end,
})

InfoSec:AddParagraph({
    Title   = "Game",
    Content = "Place: " .. game.PlaceId .. "  |  Job: " .. game.JobId:sub(1,8) .. "...",
})

InfoSec:AddParagraph({
    Title   = "Player",
    Content = "User: " .. game.Players.LocalPlayer.Name .. "  |  ID: " .. game.Players.LocalPlayer.UserId,
})

-- ══════════════════════════════════════════════════════════════
--  COMBAT TAB
-- ══════════════════════════════════════════════════════════════
local AimSec   = CombatTab:AddSection("Aimbot")
local HitSec   = CombatTab:AddSection("Hitbox")
local SilentSec = CombatTab:AddSection("Silent Aim")

AimSec:AddToggle({
    Title = "Aimbot", Default = false,
    Callback = function(state) print("Aimbot:", state) end,
})

AimSec:AddSlider({
    Title = "FOV", Min = 10, Max = 800, Increment = 1, Default = 120,
    Callback = function(v) print("FOV:", v) end,
})

AimSec:AddSlider({
    Title = "Smoothness", Min = 1, Max = 50, Increment = 1, Default = 10,
    Callback = function(v) print("Smooth:", v) end,
})

AimSec:AddDropdown({
    Title = "Target Part", Values = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }, Default = "Head",
    Callback = function(v) print("Target:", v) end,
})

AimSec:AddColorpicker({
    Title = "FOV Circle Color", Default = Color3.fromRGB(255, 0, 80),
    Callback = function(c) print("FOV color:", c) end,
})

AimSec:AddKeybind({
    Title = "Aimbot Key", Default = Enum.KeyCode.Q,
    Callback = function(k) print("Aim key:", k.Name) end,
})

HitSec:AddToggle({
    Title = "Expand Hitbox", Default = false,
    Callback = function(state) print("Hitbox:", state) end,
})

HitSec:AddSlider({
    Title = "Hitbox Size", Min = 1, Max = 20, Increment = 1, Default = 5,
    Callback = function(v) print("HBSize:", v) end,
})

HitSec:AddToggle({
    Title = "Show Hitbox", Default = false,
    Callback = function(state) print("ShowHB:", state) end,
})

SilentSec:AddToggle({
    Title = "Silent Aim", Default = false,
    Callback = function(state) print("SilentAim:", state) end,
})

SilentSec:AddSlider({
    Title = "Prediction", Min = 0, Max = 100, Increment = 1, Default = 10,
    Callback = function(v) print("Pred:", v) end,
})

SilentSec:AddDropdown({
    Title = "Check Mode", Values = { "Raycast", "Magnitude", "None" }, Default = "Raycast",
    Callback = function(v) print("CheckMode:", v) end,
})

-- ══════════════════════════════════════════════════════════════
--  VISUAL TAB
-- ══════════════════════════════════════════════════════════════
local ESPSec    = VisualTab:AddSection("ESP")
local ChamssSec = VisualTab:AddSection("Chams")
local MiscVisSec = VisualTab:AddSection("Misc Visual")

ESPSec:AddToggle({
    Title = "Player ESP", Default = false,
    Callback = function(state) print("ESP:", state) end,
})

ESPSec:AddToggle({
    Title = "Box ESP", Default = false,
    Callback = function(state) print("BoxESP:", state) end,
})

ESPSec:AddToggle({
    Title = "Name ESP", Default = true,
    Callback = function(state) print("NameESP:", state) end,
})

ESPSec:AddToggle({
    Title = "Health Bar", Default = true,
    Callback = function(state) print("HealthBar:", state) end,
})

ESPSec:AddColorpicker({
    Title = "ESP Color", Default = Color3.fromRGB(255, 60, 60),
    Callback = function(c) print("ESPColor:", c) end,
})

ESPSec:AddSlider({
    Title = "ESP Range", Min = 50, Max = 2000, Increment = 50, Default = 500,
    Callback = function(v) print("ESPRange:", v) end,
})

ChamssSec:AddToggle({
    Title = "Enable Chams", Default = false,
    Callback = function(state) print("Chams:", state) end,
})

ChamssSec:AddColorpicker({
    Title = "Chams Color", Default = Color3.fromRGB(0, 200, 255),
    Callback = function(c) print("ChamsColor:", c) end,
})

ChamssSec:AddDropdown({
    Title = "Chams Material", Values = { "Neon", "Glass", "ForceField", "SmoothPlastic" }, Default = "Neon",
    Callback = function(v) print("ChamsMat:", v) end,
})

MiscVisSec:AddToggle({
    Title = "Fullbright", Default = false,
    Callback = function(state)
        game:GetService("Lighting").Brightness = state and 10 or 1
        game:GetService("Lighting").ClockTime = state and 14 or 14
        game:GetService("Lighting").FogEnd = state and 100000 or 100000
    end,
})

MiscVisSec:AddToggle({
    Title = "Remove Fog", Default = false,
    Callback = function(state)
        game:GetService("Lighting").FogEnd = state and 100000 or 1000
    end,
})

MiscVisSec:AddSlider({
    Title = "Camera FOV", Min = 60, Max = 120, Increment = 1, Default = 70,
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end,
})

-- ══════════════════════════════════════════════════════════════
--  WORLD TAB
-- ══════════════════════════════════════════════════════════════
local WorldSec  = WorldTab:AddSection("World")
local TimesSec  = WorldTab:AddSection("Time & Weather")
local TpSec     = WorldTab:AddSection("Teleport")

WorldSec:AddSlider({
    Title = "Walk Speed (Global)", Min = 0, Max = 100, Increment = 1, Default = 16,
    Callback = function(v)
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Humanoid") then
                p.Character.Humanoid.WalkSpeed = v
            end
        end
    end,
})

WorldSec:AddToggle({
    Title = "Freeze Players", Default = false,
    Callback = function(state)
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Anchored = state end
                end
            end
        end
    end,
})

WorldSec:AddButton({
    Title = "Delete All Baseparts",
    Callback = function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not game.Players.LocalPlayer.Character:IsAncestorOf(v) then
                v:Destroy()
            end
        end
    end,
})

TimesSec:AddSlider({
    Title = "Time of Day", Min = 0, Max = 24, Increment = 1, Default = 14,
    Callback = function(v) game:GetService("Lighting").ClockTime = v end,
})

TimesSec:AddSlider({
    Title = "Ambient Brightness", Min = 0, Max = 10, Increment = 1, Default = 1,
    Callback = function(v) game:GetService("Lighting").Brightness = v end,
})

TimesSec:AddColorpicker({
    Title = "Ambient Color", Default = Color3.fromRGB(70, 70, 70),
    Callback = function(c) game:GetService("Lighting").Ambient = c end,
})

TpSec:AddInput({
    Title = "Teleport to Player", PlaceHolder = "Username",
    Callback = function(name)
        local target = game.Players:FindFirstChild(name)
        if target and target.Character then
            local lp = game.Players.LocalPlayer
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end,
})

TpSec:AddButton({
    Title = "Teleport to Spawn",
    Callback = function()
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
        end
    end,
})

-- ══════════════════════════════════════════════════════════════
--  MISC TAB
-- ══════════════════════════════════════════════════════════════
local AntiSec  = MiscTab:AddSection("Anti")
local SpamSec  = MiscTab:AddSection("Spam")
local LogSec   = MiscTab:AddSection("Logger")

AntiSec:AddToggle({
    Title = "Anti AFK", Default = true,
    Callback = function(state)
        if state then
            game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.delay(0.5, function()
                game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end,
})

AntiSec:AddToggle({
    Title = "Anti Ragdoll", Default = false,
    Callback = function(state) print("AntiRagdoll:", state) end,
})

AntiSec:AddToggle({
    Title = "Anti Void", Default = false,
    Callback = function(state) print("AntiVoid:", state) end,
})

SpamSec:AddInput({
    Title = "Chat Spam Text", PlaceHolder = "Text to spam...",
    Callback = function(v) print("SpamText:", v) end,
})

SpamSec:AddSlider({
    Title = "Spam Delay (ms)", Min = 100, Max = 5000, Increment = 100, Default = 1000,
    Callback = function(v) print("SpamDelay:", v) end,
})

SpamSec:AddToggle({
    Title = "Start Spam", Default = false,
    Callback = function(state) print("Spam:", state) end,
})

LogSec:AddToggle({
    Title = "Remote Spy", Default = false,
    Callback = function(state) print("RemoteSpy:", state) end,
})

LogSec:AddToggle({
    Title = "Chat Logger", Default = false,
    Callback = function(state)
        if state then
            game.Players.PlayerChatted:Connect(function(_, msg)
                print("[Chat]", msg)
            end)
        end
    end,
})

-- ══════════════════════════════════════════════════════════════
--  SETTINGS TAB
-- ══════════════════════════════════════════════════════════════
local UISec     = SettingsTab:AddSection("UI")
local ConfigSec = SettingsTab:AddSection("Config")
local AboutSec  = SettingsTab:AddSection("About")

UISec:AddToggle({
    Title = "Keybind Visible", Default = true,
    Callback = function(state) print("Keybinds:", state) end,
})

UISec:AddColorpicker({
    Title = "Accent Color", Default = Color3.fromRGB(179, 0, 255),
    Callback = function(c)
        Library.Theme.Accent = c
    end,
})

UISec:AddDropdown({
    Title = "Notification Style", Values = { "Info", "Success", "Warn", "Error" }, Default = "Info",
    Callback = function(v) print("NotifStyle:", v) end,
})

UISec:AddKeybind({
    Title = "Toggle UI", Default = Enum.KeyCode.RightShift,
    Callback = function(k) print("ToggleKey:", k.Name) end,
})

ConfigSec:AddInput({
    Title = "Config Name", PlaceHolder = "my_config", Default = "sh1ttybanana_v1",
    Callback = function(v) print("ConfigName:", v) end,
})

ConfigSec:AddMultiButton({
    Full  = { Title = "Save Config",  Callback = function() Window:SaveConfig("sh1ttybanana_v1") end },
    Left  = { Title = "Load",         Callback = function() Window:LoadConfig("sh1ttybanana_v1") end },
    Right = { Title = "Reset",        Callback = function() print("Reset") end },
})

AboutSec:AddParagraph({
    Title   = "sh1ttybanana UI",
    Content = "Full-featured Roblox UI library. Color picker, tab drag, Groq AI, player card and more.",
})

AboutSec:AddDivider()

AboutSec:AddButton({
    Title = "Copy Discord",
    Callback = function()
        if setclipboard then setclipboard("discord.gg/example") end
        Window:Notify({ Title = "Copied!", Content = "Discord link copied.", Type = "Success", Duration = 3 })
    end,
})

-- ══════════════════════════════════════════════════════════════
--  WELCOME NOTIFICATION
-- ══════════════════════════════════════════════════════════════
task.delay(1, function()
    Window:Notify({
        Title    = "Welcome!",
        Content  = "sh1ttybanana loaded. Click the bot icon for Groq AI, and the contact icon for your Player Card.",
        Type     = "Success",
        Duration = 5,
    })
end)
