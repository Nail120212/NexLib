local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_REPO/Source.lua"))()
local Window = Library:Window({
    Title = "MyHub",
    Subtitle = "v1.0",
    Size = Vector2.new(650, 400),
    IconImage = Library.Icons["sword"]
})
local MainPage = Window:Page({
    Name = "Combat",
    Icon = Library.Icons["sword"],
    Columns = 2
})
local VisPage = Window:Page({
    Name = "Visuals",
    Icon = Library.Icons["eye"],
    Columns = 2
})
local MiscPage = Window:Page({
    Name = "Misc",
    Icon = Library.Icons["settings"],
    Columns = 2
})
local CombatSub = MainPage:SubPage({
    Name = "Main",
    Columns = 2
})
local AimSub = MainPage:SubPage({
    Name = "Aim",
    Columns = 2
})
local CombatSection = CombatSub:Section({
    Name = "Combat",
    Side = 1
})
CombatSection:Toggle({
    Name = "Auto Farm",
    Flag = "AutoFarm",
    Default = false,
    Callback = function(Value)
        print("AutoFarm", Value)
    end
})
CombatSection:Toggle({
    Name = "Kill Aura",
    Flag = "KillAura",
    Default = false,
    Callback = function(Value)
        print("KillAura", Value)
    end
})
CombatSection:Slider({
    Name = "Walk Speed",
    Flag = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 500,
    Decimals = 1,
    Suffix = " WS",
    Callback = function(Value)
        local char = game.Players.LocalPlayer.Character
        if char then char.Humanoid.WalkSpeed = Value end
    end
})
CombatSection:Slider({
    Name = "Jump Power",
    Flag = "JumpPower",
    Default = 50,
    Min = 0,
    Max = 500,
    Decimals = 1,
    Suffix = " JP",
    Callback = function(Value)
        local char = game.Players.LocalPlayer.Character
        if char then char.Humanoid.JumpPower = Value end
    end
})
CombatSection:Dropdown({
    Name = "Target Priority",
    Flag = "TargetPriority",
    Items = { "Nearest", "Farthest", "Lowest HP", "Highest HP" },
    Default = "Nearest",
    Callback = function(Value)
        print("Priority", Value)
    end
})
local QuickSection = CombatSub:Section({
    Name = "Quick Options",
    Side = 2
})
local Row1 = QuickSection:Row()
Row1:Toggle({
    Name = "Silent Aim",
    Flag = "SilentAim",
    Default = false,
    Callback = function(Value)
        print("SilentAim", Value)
    end
})
Row1:Toggle({
    Name = "No Recoil",
    Flag = "NoRecoil",
    Default = false,
    Callback = function(Value)
        print("NoRecoil", Value)
    end
})
local Row2 = QuickSection:Row()
Row2:Toggle({
    Name = "Inf Ammo",
    Flag = "InfAmmo",
    Default = false,
    Callback = function(Value)
        print("InfAmmo", Value)
    end
})
Row2:Toggle({
    Name = "Auto Reload",
    Flag = "AutoReload",
    Default = false,
    Callback = function(Value)
        print("AutoReload", Value)
    end
})
local Row3 = QuickSection:Row()
Row3:Toggle({
    Name = "Fly",
    Flag = "Fly",
    Default = false,
    Callback = function(Value)
        print("Fly", Value)
    end
})
Row3:Dropdown({
    Name = "Mode",
    Flag = "FlyMode",
    Items = { "Normal", "Fast", "Slow" },
    Default = "Normal",
    Callback = function(Value)
        print("FlyMode", Value)
    end
})
local AimSection = AimSub:Section({
    Name = "Aimbot",
    Side = 1
})
AimSection:Toggle({
    Name = "Aimbot",
    Flag = "Aimbot",
    Default = false,
    Callback = function(Value)
        print("Aimbot", Value)
    end
})
AimSection:Slider({
    Name = "FOV",
    Flag = "AimbotFOV",
    Default = 90,
    Min = 10,
    Max = 360,
    Decimals = 1,
    Suffix = "°",
    Callback = function(Value)
        print("FOV", Value)
    end
})
AimSection:Slider({
    Name = "Smoothness",
    Flag = "AimbotSmooth",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Decimals = 0.01,
    Callback = function(Value)
        print("Smooth", Value)
    end
})
AimSection:Dropdown({
    Name = "Hitpart",
    Flag = "AimbotHitpart",
    Items = { "Head", "HumanoidRootPart", "Torso", "LeftArm", "RightArm" },
    Default = "Head",
    Callback = function(Value)
        print("Hitpart", Value)
    end
})
local AimRow = AimSection:Row()
AimRow:Toggle({
    Name = "Visible Only",
    Flag = "AimbotVisible",
    Default = true,
    Callback = function(Value)
        print("VisibleOnly", Value)
    end
})
AimRow:Toggle({
    Name = "Team Check",
    Flag = "AimbotTeam",
    Default = true,
    Callback = function(Value)
        print("TeamCheck", Value)
    end
})
local VisSub = VisPage:SubPage({
    Name = "ESP",
    Columns = 2
})
local ESPSection = VisSub:Section({
    Name = "ESP",
    Side = 1
})
ESPSection:Toggle({
    Name = "Player ESP",
    Flag = "PlayerESP",
    Default = false,
    Callback = function(Value)
        print("PlayerESP", Value)
    end
})
ESPSection:Toggle({
    Name = "Box ESP",
    Flag = "BoxESP",
    Default = false,
    Callback = function(Value)
        print("BoxESP", Value)
    end
})
ESPSection:Toggle({
    Name = "Tracers",
    Flag = "Tracers",
    Default = false,
    Callback = function(Value)
        print("Tracers", Value)
    end
})
local ESPRow = ESPSection:Row()
ESPRow:Toggle({
    Name = "Rainbow",
    Flag = "RainbowESP",
    Default = false,
    Callback = function(Value)
        print("RainbowESP", Value)
    end
})
ESPRow:Toggle({
    Name = "Chams",
    Flag = "Chams",
    Default = false,
    Callback = function(Value)
        print("Chams", Value)
    end
})
local MiscSub = MiscPage:SubPage({
    Name = "General",
    Columns = 2
})
local MiscSection = MiscSub:Section({
    Name = "Misc",
    Side = 1
})
MiscSection:Toggle({
    Name = "Anti AFK",
    Flag = "AntiAFK",
    Default = true,
    Callback = function(Value)
        print("AntiAFK", Value)
    end
})
MiscSection:Toggle({
    Name = "Noclip",
    Flag = "Noclip",
    Default = false,
    Callback = function(Value)
        print("Noclip", Value)
    end
})
MiscSection:Button():Add("Rejoin", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end)
MiscSection:Button():Add("Copy PlaceId", function()
    setclipboard(tostring(game.PlaceId))
end)
local MiscRow = MiscSection:Row()
MiscRow:Toggle({
    Name = "Fullbright",
    Flag = "Fullbright",
    Default = false,
    Callback = function(Value)
        print("Fullbright", Value)
    end
})
MiscRow:Toggle({
    Name = "No Fog",
    Flag = "NoFog",
    Default = false,
    Callback = function(Value)
        print("NoFog", Value)
    end
})
local Watermark = Library:Watermark("MyHub")
local KeyList = Library:KeybindList()
Library:Notification("MyHub", "Loaded successfully", 4)
