local Library = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

Library:SetGroq(
    "gsk_YOUR_GROQ_KEY_HERE",
    "You are a helpful assistant inside a Roblox script menu called sh1ttybanana. Help users understand features. Use **bold** for important things. To navigate tabs use [[tab:TabName]]. Keep replies short and friendly.",
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

Window:Tag({ Title = "v1.0", Color = Color3.fromRGB(255, 165, 0)  })
Window:Tag({ Title = "beta", Color = Color3.fromRGB(50, 180, 100) })

-- tabs
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
    LockTitle    = "Developer Only",
    LockDesc     = "Password: 1234",
})

local lp  = game:GetService("Players").LocalPlayer
local uis = game:GetService("UserInputService")
local rs  = game:GetService("RunService")
local lighting = game:GetService("Lighting")

local function getChar() return lp.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChild("Humanoid")
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ══════════════════════════════════════════
--  GENERAL
-- ══════════════════════════════════════════
local MovSec  = GeneralTab:AddSection("Movement")
local CharSec = GeneralTab:AddSection("Character")
local InfoSec = GeneralTab:AddSection("Info")

MovSec:AddSlider({
    Title = "Walk Speed", Min = 16, Max = 500, Increment = 1, Default = 16,
    Callback = function(v) local h = getHum() if h then h.WalkSpeed = v end end,
})

MovSec:AddSlider({
    Title = "Jump Power", Min = 7, Max = 500, Increment = 1, Default = 50,
    Callback = function(v) local h = getHum() if h then h.JumpPower = v end end,
})

local noclipOn = false
MovSec:AddToggle({
    Title = "Noclip", Default = false,
    Callback = function(s)
        noclipOn = s
        rs.Stepped:Connect(function()
            if noclipOn then
                local c = getChar()
                if c then
                    for _, p in ipairs(c:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end
        end)
    end,
})

local flyOn = false
local flyConn
MovSec:AddToggle({
    Title = "Fly", Default = false,
    Callback = function(s)
        flyOn = s
        local root = getRoot()
        if not root then return end
        if s then
            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(1e5,1e5,1e5)
            bp.Parent = root
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
            bg.Parent = root
            flyConn = rs.RenderStepped:Connect(function()
                if not flyOn then
                    bp:Destroy() bg:Destroy()
                    if flyConn then flyConn:Disconnect() end
                    return
                end
                local cam = workspace.CurrentCamera
                local dir = Vector3.new()
                if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
                bp.Position = root.Position + dir * 1.2
                bg.CFrame = cam.CFrame
            end)
        end
    end,
})

MovSec:AddKeybind({
    Title = "Fly Keybind", Default = Enum.KeyCode.F,
    Callback = function(k) print("Fly keybind:", k.Name) end,
})

CharSec:AddSlider({
    Title = "Gravity", Min = 0, Max = 400, Increment = 1, Default = 196,
    Callback = function(v) workspace.Gravity = v end,
})

CharSec:AddToggle({
    Title = "Infinite Jump", Default = false,
    Callback = function(s)
        uis.JumpRequest:Connect(function()
            if s then
                local h = getHum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end,
})

CharSec:AddButton({
    Title = "Respawn",
    Callback = function()
        local h = getHum()
        if h then h.Health = 0 end
    end,
})

CharSec:AddInput({
    Title = "Chat Message", PlaceHolder = "Type and press enter...",
    Callback = function(txt) lp:Chat(txt) end,
})

local sessionProg = InfoSec:AddProgress({ Title = "Session Time", Value = 0, Max = 3600 })
local sessionStart = os.time()
task.spawn(function()
    while task.wait(1) do
        sessionProg:Set(math.min(os.time() - sessionStart, 3600))
    end
end)

InfoSec:AddTable({
    Title = "Game Info",
    Headers = { "Key", "Value" },
    Rows = {
        { "Place ID", tostring(game.PlaceId)           },
        { "Players",  tostring(#game.Players:GetPlayers()) },
        { "Username", lp.Name                           },
        { "User ID",  tostring(lp.UserId)               },
        { "Ping",     tostring(math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())) .. "ms" },
    },
})

-- ══════════════════════════════════════════
--  COMBAT
-- ══════════════════════════════════════════
local AimSec    = CombatTab:AddSection("Aimbot")
local HitSec    = CombatTab:AddSection("Hitbox")
local SilentSec = CombatTab:AddSection("Silent Aim")

local aimbotOn = false
local aimbotFov = 120
local aimbotSmooth = 10
local aimbotPart = "Head"

AimSec:AddToggle({
    Title = "Aimbot", Default = false,
    Callback = function(s) aimbotOn = s end,
})
AimSec:AddSlider({
    Title = "FOV", Min = 10, Max = 800, Increment = 1, Default = 120,
    Callback = function(v) aimbotFov = v end,
})
AimSec:AddSlider({
    Title = "Smoothness", Min = 1, Max = 50, Increment = 1, Default = 10,
    Callback = function(v) aimbotSmooth = v end,
})
AimSec:AddDropdown({
    Title = "Target Part",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" },
    Default = "Head",
    Callback = function(v) aimbotPart = v end,
})
AimSec:AddColorpicker({
    Title = "FOV Circle Color", Default = Color3.fromRGB(255, 0, 80),
    Callback = function(c) print("FOV color:", c) end,
})
AimSec:AddKeybind({
    Title = "Hold to Aim", Default = Enum.KeyCode.Q,
    Callback = function(k) print("Aim key:", k.Name) end,
})

HitSec:AddToggle({ Title = "Expand Hitbox", Default = false, Callback = function(s) print("Hitbox:", s) end })
HitSec:AddSlider({ Title = "Hitbox Size", Min = 1, Max = 30, Increment = 1, Default = 5, Callback = function(v) print("HBSize:", v) end })
HitSec:AddToggle({ Title = "Show Hitbox", Default = false, Callback = function(s) print("ShowHB:", s) end })

SilentSec:AddToggle({ Title = "Silent Aim", Default = false, Callback = function(s) print("Silent:", s) end })
SilentSec:AddSlider({ Title = "Prediction", Min = 0, Max = 100, Increment = 1, Default = 10, Callback = function(v) print("Pred:", v) end })
SilentSec:AddDropdown({
    Title = "Check Mode", Values = { "Raycast", "Magnitude", "None" }, Default = "Raycast",
    Callback = function(v) print("Mode:", v) end,
})

-- ══════════════════════════════════════════
--  VISUAL
-- ══════════════════════════════════════════
local ESPSec     = VisualTab:AddSection("ESP")
local ChamsSec   = VisualTab:AddSection("Chams")
local MiscVisSec = VisualTab:AddSection("Misc Visual")

ESPSec:AddToggle({ Title = "Player ESP",  Default = false, Callback = function(s) print("ESP:", s)       end })
ESPSec:AddToggle({ Title = "Box ESP",     Default = false, Callback = function(s) print("BoxESP:", s)    end })
ESPSec:AddToggle({ Title = "Name ESP",    Default = true,  Callback = function(s) print("NameESP:", s)   end })
ESPSec:AddToggle({ Title = "Health Bar",  Default = true,  Callback = function(s) print("HealthBar:", s) end })
ESPSec:AddColorpicker({
    Title = "ESP Color", Default = Color3.fromRGB(255, 60, 60),
    Callback = function(c) print("ESPCol:", c) end,
})
ESPSec:AddSlider({
    Title = "ESP Range", Min = 50, Max = 2000, Increment = 50, Default = 500,
    Callback = function(v) print("Range:", v) end,
})

ChamsSec:AddToggle({ Title = "Enable Chams", Default = false, Callback = function(s) print("Chams:", s) end })
ChamsSec:AddColorpickerRGB({
    Title = "Chams Color",
    Default = Color3.fromRGB(0, 200, 255),
    Callback = function(c) print("Chams RGB:", c) end,
})
ChamsSec:AddDropdown({
    Title = "Material",
    Values = { "Neon", "Glass", "ForceField", "SmoothPlastic" },
    Default = "Neon",
    Callback = function(v) print("Mat:", v) end,
})

MiscVisSec:AddToggle({
    Title = "Fullbright", Default = false,
    Callback = function(s)
        lighting.Brightness   = s and 10 or 1
        lighting.ClockTime    = s and 14 or 14
        lighting.FogEnd       = s and 100000 or 100000
        lighting.GlobalShadows = not s
    end,
})
MiscVisSec:AddToggle({
    Title = "Remove Fog", Default = false,
    Callback = function(s) lighting.FogEnd = s and 100000 or 1000 end,
})
MiscVisSec:AddSlider({
    Title = "Camera FOV", Min = 60, Max = 120, Increment = 1, Default = 70,
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end,
})

-- ══════════════════════════════════════════
--  WORLD
-- ══════════════════════════════════════════
local WorldSec = WorldTab:AddSection("World")
local TimeSec  = WorldTab:AddSection("Time & Weather")
local TpSec    = WorldTab:AddSection("Teleport")

WorldSec:AddSlider({
    Title = "Global Speed", Min = 0, Max = 100, Increment = 1, Default = 16,
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
    Callback = function(s)
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= lp and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Anchored = s end
                end
            end
        end
    end,
})
WorldSec:AddButton({
    Title = "Kill All Players",
    Callback = function()
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= lp and p.Character and p.Character:FindFirstChild("Humanoid") then
                p.Character.Humanoid.Health = 0
            end
        end
    end,
})

TimeSec:AddSlider({
    Title = "Time of Day", Min = 0, Max = 24, Increment = 1, Default = 14,
    Callback = function(v) lighting.ClockTime = v end,
})
TimeSec:AddSlider({
    Title = "Brightness", Min = 0, Max = 10, Increment = 1, Default = 1,
    Callback = function(v) lighting.Brightness = v end,
})
TimeSec:AddColorpicker({
    Title = "Ambient Color", Default = Color3.fromRGB(70, 70, 70),
    Callback = function(c) lighting.Ambient = c end,
})

TpSec:AddInput({
    Title = "Teleport to Player", PlaceHolder = "Username",
    Callback = function(name)
        local t = game.Players:FindFirstChild(name)
        local root = getRoot()
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and root then
            root.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end,
})
TpSec:AddButton({
    Title = "Teleport to Spawn",
    Callback = function()
        local root = getRoot()
        if root then root.CFrame = CFrame.new(0, 10, 0) end
    end,
})

-- ══════════════════════════════════════════
--  MISC
-- ══════════════════════════════════════════
local AntiSec = MiscTab:AddSection("Anti")
local SpamSec = MiscTab:AddSection("Chat Spam")
local LogSec  = MiscTab:AddSection("Logger")

AntiSec:AddToggle({ Title = "Anti AFK",     Default = true,  Callback = function(s) print("AntiAFK:", s)     end })
AntiSec:AddToggle({ Title = "Anti Ragdoll", Default = false, Callback = function(s) print("AntiRagdoll:", s) end })
AntiSec:AddToggle({ Title = "Anti Void",    Default = false, Callback = function(s) print("AntiVoid:", s)    end })

local spamText  = ""
local spamDelay = 1000
local spamOn    = false

SpamSec:AddInput({
    Title = "Spam Text", PlaceHolder = "Text to spam...",
    Callback = function(v) spamText = v end,
})
SpamSec:AddSlider({
    Title = "Delay (ms)", Min = 100, Max = 5000, Increment = 100, Default = 1000,
    Callback = function(v) spamDelay = v end,
})
SpamSec:AddToggle({
    Title = "Start Spam", Default = false,
    Callback = function(s)
        spamOn = s
        if s then
            task.spawn(function()
                while spamOn do
                    if spamText ~= "" then lp:Chat(spamText) end
                    task.wait(spamDelay / 1000)
                end
            end)
        end
    end,
})

LogSec:AddToggle({ Title = "Remote Spy",  Default = false, Callback = function(s) print("RemoteSpy:", s)  end })
LogSec:AddToggle({ Title = "Chat Logger", Default = false, Callback = function(s)
    if s then
        game.Players.PlayerChatted:Connect(function(_, msg) print("[Chat]", msg) end)
    end
end })

-- ══════════════════════════════════════════
--  SETTINGS
-- ══════════════════════════════════════════
local UISec     = SettingsTab:AddSection("UI")
local ConfigSec = SettingsTab:AddSection("Config")
local AboutSec  = SettingsTab:AddSection("About")

UISec:AddColorpicker({
    Title = "Accent Color", Default = Color3.fromRGB(179, 0, 255),
    Callback = function(c) Library.Theme.Accent = c end,
})
UISec:AddToggle({ Title = "Keybind Visible", Default = true, Callback = function(s) print("Keybinds:", s) end })
UISec:AddDropdown({
    Title = "Notification Style",
    Values = { "Info", "Success", "Warn", "Error" },
    Default = "Info",
    Callback = function(v) print("NotifStyle:", v) end,
})
UISec:AddKeybind({
    Title = "Toggle UI", Default = Enum.KeyCode.RightShift,
    Callback = function(k) print("ToggleKey:", k.Name) end,
})

ConfigSec:AddInput({ Title = "Config Name", PlaceHolder = "my_config", Default = "sh1ttybanana_v1", Callback = function(v) print("Config:", v) end })
ConfigSec:AddButton({ Title = "Save Config",  Callback = function() print("Saved!")  end })
ConfigSec:AddButton({ Title = "Load Config",  Callback = function() print("Loaded!") end })
ConfigSec:AddButton({ Title = "Reset Config", Callback = function() print("Reset!")  end })

AboutSec:AddParagraph({
    Title   = "sh1ttybanana UI",
    Content = "Full-featured Roblox UI. AI assistant (bot icon), Player Card (person icon), color picker, tab drag, all new elements and more.",
})
AboutSec:AddDivider()
AboutSec:AddButton({
    Title = "Copy Discord",
    Callback = function()
        if setclipboard then setclipboard("discord.gg/example") end
        Window:Notify({ Title = "Copied!", Content = "Discord link copied.", Type = "Success", Duration = 3 })
    end,
})

-- ══════════════════════════════════════════
--  DEV (locked pw: 1234) — showcases all new elements
-- ══════════════════════════════════════════
local DemoSec  = DevTab:AddSection("New Elements Demo")
local CodeSec  = DevTab:AddSection("Codeblock")

-- AddProgress
local hpBar = DemoSec:AddProgress({ Title = "Player Health", Value = 100, Max = 100 })
task.spawn(function()
    while task.wait(0.5) do
        local h = getHum()
        if h then hpBar:Set(h.Health) end
    end
end)

-- AddColorpickerRGB
DemoSec:AddColorpickerRGB({
    Title = "Team Color",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(c) print("Team color:", c) end,
})

-- AddGrid
DemoSec:AddGrid({
    Title   = "Weapon Slots",
    Items   = { "Pistol", "Rifle", "Sniper", "SMG", "Shotgun", "Knife", "Grenade", "Shield" },
    Columns = 4,
    Default = { "Pistol", "Knife" },
    Callback = function(sel) print("Selected:", table.concat(sel, ", ")) end,
})

-- AddTable
DemoSec:AddTable({
    Title   = "Kill Feed",
    Headers = { "Player", "Weapon", "Time" },
    Rows    = {
        { "PlayerA", "Pistol",  "0:32" },
        { "PlayerB", "Rifle",   "1:14" },
        { "PlayerC", "Sniper",  "2:05" },
        { "PlayerD", "Shotgun", "3:47" },
    },
})

-- AddImage
DemoSec:AddImage({
    Title   = "Map Preview",
    Asset   = "rbxassetid://6894586021",
    Height  = 100,
    Rounded = true,
})

-- AddCodeblock
CodeSec:AddCodeblock({
    Title    = "Kill Self",
    Language = "lua",
    Code     = 'local h = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")\nif h then h.Health = 0 end',
    Callback = function(code)
        local fn, err = loadstring(code)
        if fn then fn() else print("Error:", err) end
    end,
})

CodeSec:AddCodeblock({
    Title    = "Print All Players",
    Language = "lua",
    Code     = 'for _, p in ipairs(game.Players:GetPlayers()) do\n    print(p.Name, p.UserId)\nend',
    Callback = function(code)
        local fn, err = loadstring(code)
        if fn then fn() else print("Error:", err) end
    end,
})

-- ══════════════════════════════════════════
--  WELCOME
-- ══════════════════════════════════════════
task.delay(1, function()
    Window:Notify({
        Title    = "Welcome!",
        Content  = "sh1ttybanana loaded. Bot icon = Groq AI, Person icon = Player Card. Dev tab password: 1234",
        Type     = "Success",
        Duration = 6,
    })
end)
