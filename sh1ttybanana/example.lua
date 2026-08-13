local Library = https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua

Library:SetGroq(
    "gsk_YOUR_GROQ_KEY_HERE",
    "You are a helpful assistant inside a Roblox script hub called sh1ttybanana. Help users find features using [[tab:TabName]] syntax. Keep replies short.",
    "llama-3.3-70b-versatile"
)

local Window = Library:NewWindow({
    Title       = "sh1ttybanana",
    Description = "full featured",
    Logo        = "rbxassetid://89646749075297",
    Color       = Color3.fromRGB(179, 0, 255),
    Size        = UDim2.new(0, 620, 0, 420),
    Transparent = 0.07,
    AutoScale   = true,
})

Window:Tag({ Title = "v1.0",  Color = Color3.fromRGB(255, 165, 0)  })
Window:Tag({ Title = "beta",  Color = Color3.fromRGB(50, 180, 100) })

local GeneralTab  = Window:T({ Title = "General",  Icon = "layout-dashboard" })
local CombatTab   = Window:T({ Title = "Combat",   Icon = "crosshair"        })
local VisualTab   = Window:T({ Title = "Visual",   Icon = "eye"              })
local WorldTab    = Window:T({ Title = "World",    Icon = "globe"            })
local MiscTab     = Window:T({ Title = "Misc",     Icon = "box"              })
local SettingsTab = Window:T({ Title = "Settings", Icon = "settings"         })
local DevTab      = Window:T({
    Title        = "Dev",
    Icon         = "terminal",
    Locked       = true,
    LockPassword = "1234",
    LockTitle    = "Developer Tab",
    LockDesc     = "Enter password to unlock",
})

-- ══════════════ GENERAL ══════════════
local MovSec  = GeneralTab:AddSection("Movement")
local CharSec = GeneralTab:AddSection("Character")
local InfoSec = GeneralTab:AddSection("Info")

local SpeedSlider = MovSec:AddSlider({
    Title = "Walk Speed", Min = 16, Max = 500, Increment = 1, Default = 16,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = v end
    end,
})

local JumpSlider = MovSec:AddSlider({
    Title = "Jump Power", Min = 7, Max = 500, Increment = 1, Default = 50,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.JumpPower = v end
    end,
})

MovSec:AddToggle({
    Title = "Noclip", Default = false,
    Callback = function(state)
        game:GetService("RunService").Stepped:Connect(function()
            if state then
                local char = game.Players.LocalPlayer.Character
                if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
            end
        end)
    end,
})

MovSec:AddToggle({ Title = "Fly", Default = false, Callback = function(state) print("Fly:", state) end })
MovSec:AddKeybind({ Title = "Fly Key", Default = Enum.KeyCode.F, Callback = function(k) print("Fly key:", k.Name) end })

local GravSlider = CharSec:AddSlider({
    Title = "Gravity", Min = 0, Max = 400, Increment = 1, Default = 196,
    Callback = function(v) workspace.Gravity = v end,
})

CharSec:AddToggle({
    Title = "Infinite Jump", Default = false,
    Callback = function(state)
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if state then
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end,
})

CharSec:AddButton({ Title = "Respawn", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.Health = 0 end
end })

CharSec:AddInput({ Title = "Chat Message", PlaceHolder = "Type and press enter...", Callback = function(txt)
    game:GetService("Players").LocalPlayer:Chat(txt)
end })

local SessionProg = InfoSec:AddProgress({ Title = "Session", Value = 0, Max = 3600 })
task.spawn(function()
    local start = os.time()
    while task.wait(1) do
        SessionProg:Set(math.min(os.time() - start, 3600))
    end
end)

InfoSec:AddTable({
    Title = "Game Info",
    Headers = { "Key", "Value" },
    Rows = {
        { "Place ID", tostring(game.PlaceId) },
        { "Players", tostring(#game.Players:GetPlayers()) },
        { "Player",  game.Players.LocalPlayer.Name },
        { "User ID", tostring(game.Players.LocalPlayer.UserId) },
    },
})

-- ══════════════ COMBAT ══════════════
local AimSec    = CombatTab:AddSection("Aimbot")
local HitSec    = CombatTab:AddSection("Hitbox")
local SilentSec = CombatTab:AddSection("Silent Aim")

AimSec:AddToggle({ Title = "Aimbot", Default = false, Callback = function(s) print("Aimbot:", s) end })
AimSec:AddSlider({ Title = "FOV", Min = 10, Max = 800, Increment = 1, Default = 120, Callback = function(v) print("FOV:", v) end })
AimSec:AddSlider({ Title = "Smoothness", Min = 1, Max = 50, Increment = 1, Default = 10, Callback = function(v) print("Smooth:", v) end })
AimSec:AddDropdown({ Title = "Target Part", Values = {"Head","HumanoidRootPart","UpperTorso","Torso"}, Default = "Head", Callback = function(v) print("Target:", v) end })
AimSec:AddColorpicker({ Title = "FOV Circle Color", Default = Color3.fromRGB(255, 0, 80), Callback = function(c) print("FOV color:", c) end })
AimSec:AddKeybind({ Title = "Aimbot Key", Default = Enum.KeyCode.Q, Callback = function(k) print("Aim key:", k.Name) end })

HitSec:AddToggle({ Title = "Expand Hitbox", Default = false, Callback = function(s) print("Hitbox:", s) end })
HitSec:AddSlider({ Title = "Hitbox Size", Min = 1, Max = 30, Increment = 1, Default = 5, Callback = function(v) print("HBSize:", v) end })
HitSec:AddToggle({ Title = "Show Hitbox", Default = false, Callback = function(s) print("ShowHB:", s) end })

SilentSec:AddToggle({ Title = "Silent Aim", Default = false, Callback = function(s) print("Silent:", s) end })
SilentSec:AddSlider({ Title = "Prediction", Min = 0, Max = 100, Increment = 1, Default = 10, Callback = function(v) print("Pred:", v) end })
SilentSec:AddDropdown({ Title = "Check Mode", Values = {"Raycast","Magnitude","None"}, Default = "Raycast", Callback = function(v) print("Mode:", v) end })

-- ══════════════ VISUAL ══════════════
local ESPSec     = VisualTab:AddSection("ESP")
local ChamsSec   = VisualTab:AddSection("Chams")
local MiscVisSec = VisualTab:AddSection("Misc Visual")

ESPSec:AddToggle({ Title = "Player ESP", Default = false, Callback = function(s) print("ESP:", s) end })
ESPSec:AddToggle({ Title = "Box ESP",    Default = false, Callback = function(s) print("BoxESP:", s) end })
ESPSec:AddToggle({ Title = "Name ESP",   Default = true,  Callback = function(s) print("NameESP:", s) end })
ESPSec:AddToggle({ Title = "Health Bar", Default = true,  Callback = function(s) print("HealthBar:", s) end })
ESPSec:AddColorpicker({ Title = "ESP Color", Default = Color3.fromRGB(255,60,60), Callback = function(c) print("ESPCol:", c) end })
ESPSec:AddSlider({ Title = "ESP Range", Min = 50, Max = 2000, Increment = 50, Default = 500, Callback = function(v) print("Range:", v) end })

ChamsSec:AddToggle({ Title = "Enable Chams", Default = false, Callback = function(s) print("Chams:", s) end })
ChamsSec:AddColorpickerRGB({ Title = "Chams Color (RGB)", Default = Color3.fromRGB(0,200,255), Callback = function(c) print("Chams RGB:", c) end })
ChamsSec:AddDropdown({ Title = "Material", Values = {"Neon","Glass","ForceField","SmoothPlastic"}, Default = "Neon", Callback = function(v) print("Mat:", v) end })

MiscVisSec:AddToggle({ Title = "Fullbright", Default = false, Callback = function(s)
    game:GetService("Lighting").Brightness = s and 10 or 1
end })
MiscVisSec:AddToggle({ Title = "Remove Fog", Default = false, Callback = function(s)
    game:GetService("Lighting").FogEnd = s and 100000 or 1000
end })
MiscVisSec:AddSlider({ Title = "Camera FOV", Min = 60, Max = 120, Increment = 1, Default = 70, Callback = function(v)
    workspace.CurrentCamera.FieldOfView = v
end })

-- ══════════════ WORLD ══════════════
local WorldSec = WorldTab:AddSection("World")
local TimeSec  = WorldTab:AddSection("Time & Weather")
local TpSec    = WorldTab:AddSection("Teleport")

WorldSec:AddSlider({ Title = "Gravity", Min = 0, Max = 200, Increment = 1, Default = 196, Callback = function(v) workspace.Gravity = v end })
WorldSec:AddToggle({ Title = "Freeze Players", Default = false, Callback = function(s)
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = s end
            end
        end
    end
end })
WorldSec:AddButton({ Title = "Kill All Players", Callback = function()
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
            p.Character.Humanoid.Health = 0
        end
    end
end })

TimeSec:AddSlider({ Title = "Time of Day", Min = 0, Max = 24, Increment = 1, Default = 14, Callback = function(v) game:GetService("Lighting").ClockTime = v end })
TimeSec:AddSlider({ Title = "Brightness", Min = 0, Max = 10, Increment = 1, Default = 1, Callback = function(v) game:GetService("Lighting").Brightness = v end })
TimeSec:AddColorpicker({ Title = "Ambient", Default = Color3.fromRGB(70,70,70), Callback = function(c) game:GetService("Lighting").Ambient = c end })

TpSec:AddInput({ Title = "Teleport to Player", PlaceHolder = "Username", Callback = function(name)
    local t = game.Players:FindFirstChild(name)
    if t and t.Character then
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
        end
    end
end })
TpSec:AddButton({ Title = "Teleport to Spawn", Callback = function()
    local lp = game.Players.LocalPlayer
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = CFrame.new(0,10,0)
    end
end })

-- ══════════════ MISC ══════════════
local AntiSec = MiscTab:AddSection("Anti")
local SpamSec = MiscTab:AddSection("Spam")
local LogSec  = MiscTab:AddSection("Logger")

AntiSec:AddToggle({ Title = "Anti AFK", Default = true, Callback = function(s) print("AntiAFK:", s) end })
AntiSec:AddToggle({ Title = "Anti Ragdoll", Default = false, Callback = function(s) print("AntiRagdoll:", s) end })
AntiSec:AddToggle({ Title = "Anti Void", Default = false, Callback = function(s) print("AntiVoid:", s) end })

SpamSec:AddInput({ Title = "Chat Spam Text", PlaceHolder = "Text...", Callback = function(v) print("SpamText:", v) end })
SpamSec:AddSlider({ Title = "Spam Delay (ms)", Min = 100, Max = 5000, Increment = 100, Default = 1000, Callback = function(v) print("Delay:", v) end })
SpamSec:AddToggle({ Title = "Start Spam", Default = false, Callback = function(s) print("Spam:", s) end })

LogSec:AddToggle({ Title = "Remote Spy", Default = false, Callback = function(s) print("RemoteSpy:", s) end })
LogSec:AddToggle({ Title = "Chat Logger", Default = false, Callback = function(s) print("ChatLog:", s) end })

-- ══════════════ SETTINGS ══════════════
local UISec     = SettingsTab:AddSection("UI")
local ConfigSec = SettingsTab:AddSection("Config")
local AboutSec  = SettingsTab:AddSection("About")

UISec:AddToggle({ Title = "Keybind Visible", Default = true, Callback = function(s) print("Keybinds:", s) end })
UISec:AddColorpicker({ Title = "Accent Color", Default = Color3.fromRGB(179,0,255), Callback = function(c) Library.Theme.Accent = c end })
UISec:AddDropdown({ Title = "Notification Style", Values = {"Info","Success","Warn","Error"}, Default = "Info", Callback = function(v) print("Notif:", v) end })
UISec:AddKeybind({ Title = "Toggle UI", Default = Enum.KeyCode.RightShift, Callback = function(k) print("Toggle key:", k.Name) end })

ConfigSec:AddInput({ Title = "Config Name", PlaceHolder = "my_config", Default = "sh1ttybanana_v1", Callback = function(v) print("Config:", v) end })
ConfigSec:AddButton({ Title = "Save Config",  Callback = function() print("Saved")  end })
ConfigSec:AddButton({ Title = "Load Config",  Callback = function() print("Loaded") end })
ConfigSec:AddButton({ Title = "Reset Config", Callback = function() print("Reset")  end })

AboutSec:AddParagraph({ Title = "sh1ttybanana UI", Content = "Full-featured Roblox UI. Color picker, tab drag, Groq AI, player card and all new elements." })
AboutSec:AddDivider()
AboutSec:AddButton({ Title = "Copy Discord", Callback = function()
    if setclipboard then setclipboard("discord.gg/example") end
    Window:Notify({ Title = "Copied!", Content = "Discord link copied.", Type = "Success", Duration = 3 })
end })

-- ══════════════ DEV TAB (locked, pw = 1234) ══════════════
local DevSec    = DevTab:AddSection("New Elements Demo")
local DevSec2   = DevTab:AddSection("Codeblock")

DevSec:AddProgress({ Title = "Health", Value = 75, Max = 100 })
DevSec:AddColorpickerRGB({ Title = "Team Color", Default = Color3.fromRGB(255,80,80), Callback = function(c) print("Team color:", c) end })
DevSec:AddGrid({
    Title = "Weapon Slots",
    Items = {"Pistol","Rifle","Sniper","SMG","Shotgun","Knife","Grenade","Shield"},
    Columns = 4,
    Default = {"Pistol","Knife"},
    Callback = function(selected) print("Selected:", table.concat(selected, ", ")) end,
})
DevSec:AddTable({
    Title = "Kill Feed",
    Headers = {"Player","Weapon","Time"},
    Rows = {
        {"PlayerA","Pistol","0:32"},
        {"PlayerB","Rifle","1:14"},
        {"PlayerC","Sniper","2:05"},
    },
})
DevSec:AddImage({ Title = "Map Preview", Asset = "rbxassetid://6894586021", Height = 110, Rounded = true })

DevSec2:AddCodeblock({
    Title = "Kill Script",
    Language = "lua",
    Code = 'local char = game.Players.LocalPlayer.Character\nif char and char:FindFirstChild("Humanoid") then\n    char.Humanoid.Health = 0\nend',
    Callback = function(code)
        local fn, err = loadstring(code)
        if fn then fn() else print("Error:", err) end
    end,
})

-- ══════════════ NOTIFY ON LOAD ══════════════
task.delay(1, function()
    Window:Notify({ Title = "Loaded!", Content = "sh1ttybanana ready. Click the bot icon for Groq AI, person icon for Player Card.", Type = "Success", Duration = 5 })
end)
