local function Fetch(url)
    local ok, res = pcall(function()
        if type(game.HttpGet) == "function" then
            return game:HttpGet(url)
        end
        if type(game.HttpGetAsync) == "function" then
            return game:HttpGetAsync(url)
        end
        if syn and syn.request then
            return syn.request({Url = url, Method = "GET"}).Body
        end
        if request then
            return request({Url = url, Method = "GET"}).Body
        end
        if http_request then
            return http_request({Url = url, Method = "GET"}).Body
        end
        return game:GetService("HttpService"):GetAsync(url)
    end)
    if ok and type(res) == "string" and #res > 50 then
        return res
    end
    return nil
end

local src = nil
if readfile and isfile and isfile("sh1ttybanana.lua") then
    local ok, data = pcall(readfile, "sh1ttybanana.lua")
    if ok and type(data) == "string" and #data > 50 then
        src = data
    end
end
if not src then
    src = Fetch("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua")
end
assert(src, "failed to download sh1ttybanana source")

if not src:find("UIIcons failed to load", 1, true) and src:find("UIIcons.SetIconsType", 1, true) then
    src = src:gsub(
        "local UIIcons%s*=%s*loadstring%s*%(%s*Get%s*%(%s*[\"'][^\"']+[\"']%s*%)%s*%)%s*%(%s*%)%s*UIIcons%.SetIconsType%s*%(%s*[\"'][^\"']+[\"']%s*%)",
        [[local UIIcons
do
    local ok, result = pcall(function()
        local s = Get("https://raw.githubusercontent.com/DSP-V1/NextGen/refs/heads/main/UILib/icons/UIIcons.lua")
        if not s or s == "" then error("empty") end
        local fn = loadstring(s)
        if not fn then error("compile") end
        return fn()
    end)
    if ok and type(result) == "table" then
        UIIcons = result
        pcall(function()
            if UIIcons.SetIconsType then
                UIIcons.SetIconsType("lucide")
            end
        end)
    else
        UIIcons = {
            SetIconsType = function() end,
            Icon2 = function() return nil end,
            Icon = function() return nil end
        }
        warn("[sh1ttybanana] UIIcons fallback:", result)
    end
end]]
    )
end

local chunk, compileErr = loadstring(src)
if not chunk then
    error("sh1ttybanana compile error: " .. tostring(compileErr))
end

local okLib, Library = pcall(chunk)
if not okLib then
    error("sh1ttybanana runtime error: " .. tostring(Library))
end
if type(Library) ~= "table" or type(Library.NewWindow) ~= "function" then
    error("sh1ttybanana did not return Library table")
end

local Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "full component demo",
    Logo = "rbxassetid://89646749075297",
    Color = Color3.fromRGB(179, 0, 255),
    Size = UDim2.new(0, 620, 0, 420),
    Transparent = 0.07,
    AutoScale = true
})

Window:SetGroqConfig("", "You are a helpful assistant for this Roblox hub. When suggesting tabs use [tab:TabName] format.")

Window:Tag({
    Title = "FULL",
    Color = Color3.fromRGB(48, 255, 106),
    Icon = "check"
})
Window:Tag({
    Title = "v1.0",
    Color = Color3.fromRGB(179, 0, 255)
})

local PlayerSec = Window:Section({
    Title = "Player",
    Opened = true
})
local WorldSec = Window:Section({
    Title = "World",
    Opened = true
})
local ConfigSec = Window:Section({
    Title = "Config",
    Opened = false
})

local Main = PlayerSec:T({Title = "Main", Icon = "home"})
local Combat = PlayerSec:T({Title = "Combat", Icon = "swords"})
local Visuals = WorldSec:T({Title = "Visuals", Icon = "eye"})
local Misc = WorldSec:T({Title = "Misc", Icon = "settings"})
local Config = ConfigSec:T({Title = "Settings", Icon = "sliders-horizontal"})
local Locked = PlayerSec:T({
    Title = "Private",
    Icon = "lock",
    Locked = true,
    LockPassword = "1234",
    LockTitle = "Private Tab",
    LockDesc = "Password is 1234"
})

local G = Main:AddSection({Title = "General"})
G:AddToggle({
    Title = "Master Enable",
    Description = "turns the whole script on",
    Default = false,
    Callback = function(v)
        print("Master:", v)
        Window:SetFlag("Master", v)
    end
})
G:AddButton({
    Title = "Notify Success",
    Description = "fires a success notification",
    Callback = function()
        Window:Notify({
            Title = "Success",
            Content = "everything is working",
            Type = "Success",
            Duration = 3
        })
    end
})
G:AddButton({
    Title = "Notify Error",
    Description = "fires an error notification",
    Callback = function()
        Window:Notify({
            Title = "Error",
            Content = "something went wrong",
            Type = "Error",
            Duration = 3
        })
    end
})
G:AddButton({
    Title = "Notify Warn",
    Description = "fires a warn notification",
    Callback = function()
        Window:Notify({
            Title = "Warning",
            Content = "check your settings",
            Type = "Warn",
            Duration = 3
        })
    end
})
G:AddButton({
    Title = "Open Dialog",
    Description = "popup confirm dialog",
    Callback = function()
        Window:Dialog({
            Title = "Confirm Action",
            Content = "are you sure you want to continue?",
            Buttons = {
                {
                    Title = "Yes",
                    Variant = "Primary",
                    Callback = function()
                        Window:Notify({Title = "Confirmed", Content = "you pressed yes", Type = "Success", Duration = 2})
                    end
                },
                {
                    Title = "No",
                    Callback = function()
                        Window:Notify({Title = "Cancelled", Content = "you pressed no", Type = "Info", Duration = 2})
                    end
                }
            }
        })
    end
})
G:AddButton({
    Title = "Open Popup",
    Description = "same as dialog",
    Callback = function()
        Window:Popup({
            Title = "Popup",
            Content = "popup alias of dialog",
            Buttons = {
                {Title = "OK", Variant = "Primary", Callback = function() end}
            }
        })
    end
})
G:AddDivider()
G:AddParagraph({
    Title = "About",
    Content = "this example shows every component in sh1ttybanana including AI assistant, player card, tabs, sections, and all controls"
})
G:AddSeperator("Controls")
G:AddSlider({
    Title = "WalkSpeed",
    Description = "character walk speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Callback = function(v)
        print("WalkSpeed:", v)
        Window:SetFlag("WalkSpeed", v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = v
        end
    end
})
G:AddSlider({
    Title = "JumpPower",
    Description = "character jump power",
    Min = 50,
    Max = 200,
    Default = 50,
    Increment = 1,
    Callback = function(v)
        print("JumpPower:", v)
        Window:SetFlag("JumpPower", v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = v
        end
    end
})
G:AddDropdown({
    Title = "Mode",
    Description = "select play style",
    Values = {"Normal", "Rage", "Legit", "Custom"},
    Default = "Normal",
    Callback = function(v)
        print("Mode:", v)
        Window:SetFlag("Mode", v)
    end
})
G:AddInput({
    Title = "Target",
    Description = "player name to target",
    Default = "",
    PlaceHolder = "enter username",
    Callback = function(v)
        print("Target:", v)
        Window:SetFlag("Target", v)
    end
})
G:AddKeybind({
    Title = "Panic Key",
    Description = "instant hide key",
    Default = Enum.KeyCode.P,
    Callback = function(k)
        print("Panic:", k.Name)
        Window:SetFlag("PanicKey", k.Name)
    end
})
G:AddColorpicker({
    Title = "Accent Color",
    Description = "main ui accent",
    Default = Color3.fromRGB(179, 0, 255),
    Callback = function(c)
        print("Accent:", c)
        Window:SetFlag("Accent", {c.R, c.G, c.B})
    end
})
G:AddTag({
    Title = "LIVE",
    Color = Color3.fromRGB(48, 255, 106)
})
G:AddSpace(8)
G:AddMultiButton({
    Full = {
        Title = "Full Width Action",
        Callback = function()
            Window:Notify({Title = "Full", Content = "full button pressed", Type = "Info", Duration = 2})
        end
    },
    Left = {
        Title = "Left",
        Callback = function()
            Window:Notify({Title = "Left", Content = "left button", Type = "Info", Duration = 2})
        end
    },
    Right = {
        Title = "Right",
        Callback = function()
            Window:Notify({Title = "Right", Content = "right button", Type = "Info", Duration = 2})
        end
    }
})
G:AddCodeblock({
    Title = "Lua Runner",
    Code = "print('hello from sh1ttybanana')\nprint(game.Players.LocalPlayer.Name)",
    Callback = function(code)
        print("Code ran, length:", #code)
    end
})

local C = Combat:AddSection({Title = "Aim"})
C:AddToggle({
    Title = "Aimbot",
    Description = "enable aim assist",
    Default = false,
    Callback = function(v)
        print("Aimbot:", v)
    end
})
C:AddToggle({
    Title = "Silent Aim",
    Description = "server-side aim",
    Default = false,
    Callback = function(v)
        print("Silent:", v)
    end
})
C:AddSlider({
    Title = "FOV",
    Description = "field of view radius",
    Min = 50,
    Max = 500,
    Default = 120,
    Increment = 5,
    Callback = function(v)
        print("FOV:", v)
    end
})
C:AddSlider({
    Title = "Smoothness",
    Description = "aim smoothing",
    Min = 1,
    Max = 20,
    Default = 5,
    Increment = 1,
    Callback = function(v)
        print("Smooth:", v)
    end
})
C:AddDropdown({
    Title = "Target Part",
    Description = "body part to aim",
    Values = {"Head", "Torso", "HumanoidRootPart", "UpperTorso"},
    Default = "Head",
    Callback = function(v)
        print("Part:", v)
    end
})
C:AddDropdown({
    Title = "Priority",
    Description = "target priority",
    Values = {"Closest", "Lowest HP", "Highest HP", "Crosshair"},
    Default = "Closest",
    Callback = function(v)
        print("Priority:", v)
    end
})
C:AddKeybind({
    Title = "Aim Key",
    Description = "hold to aim",
    Default = Enum.KeyCode.E,
    Callback = function(k)
        print("AimKey:", k.Name)
    end
})
C:AddColorpicker({
    Title = "FOV Color",
    Description = "fov circle color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(c)
        print("FOVColor:", c)
    end
})
C:AddDivider()
C:AddParagraph({
    Title = "Tip",
    Content = "sidebar bottom bar has Reorder, AI Assistant, and Player Card buttons"
})

local V = Visuals:AddSection({Title = "ESP"})
V:AddToggle({
    Title = "Box ESP",
    Description = "draw boxes on players",
    Default = false,
    Callback = function(v) end
})
V:AddToggle({
    Title = "Name ESP",
    Description = "show player names",
    Default = false,
    Callback = function(v) end
})
V:AddToggle({
    Title = "Tracer",
    Description = "lines to players",
    Default = false,
    Callback = function(v) end
})
V:AddSlider({
    Title = "Max Distance",
    Description = "esp render distance",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Increment = 50,
    Callback = function(v) end
})
V:AddColorpicker({
    Title = "Enemy Color",
    Default = Color3.fromRGB(255, 60, 60),
    Callback = function(c) end
})
V:AddColorpicker({
    Title = "Team Color",
    Default = Color3.fromRGB(60, 255, 120),
    Callback = function(c) end
})
V:AddSeperator("Chams")
V:AddToggle({
    Title = "Chams",
    Description = "highlight characters",
    Default = false,
    Callback = function(v) end
})
V:AddDropdown({
    Title = "Chams Style",
    Values = {"Outline", "Fill", "Both"},
    Default = "Outline",
    Callback = function(v) end
})

local M = Misc:AddSection({Title = "World"})
M:AddToggle({
    Title = "Fullbright",
    Description = "remove darkness",
    Default = false,
    Callback = function(v)
        if v then
            game.Lighting.Brightness = 2
            game.Lighting.ClockTime = 14
            game.Lighting.FogEnd = 100000
            game.Lighting.GlobalShadows = false
            game.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        else
            game.Lighting.Brightness = 1
            game.Lighting.GlobalShadows = true
        end
    end
})
M:AddToggle({
    Title = "No Fog",
    Default = false,
    Callback = function(v)
        game.Lighting.FogEnd = v and 100000 or 1000
    end
})
M:AddSlider({
    Title = "Time of Day",
    Min = 0,
    Max = 24,
    Default = 14,
    Increment = 0.5,
    Callback = function(v)
        game.Lighting.ClockTime = v
    end
})
M:AddInput({
    Title = "Teleport To",
    PlaceHolder = "player name",
    Default = "",
    Callback = function(name)
        local plr = game.Players:FindFirstChild(name)
        local lp = game.Players.LocalPlayer
        if plr and plr.Character and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
        end
    end
})
M:AddButton({
    Title = "Rejoin",
    Description = "rejoin current server",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end
})
M:AddMultiButton({
    Full = {
        Title = "Server Hop",
        Callback = function()
            Window:Notify({Title = "Server", Content = "hopping...", Type = "Info", Duration = 2})
        end
    },
    Left = {
        Title = "Copy JobId",
        Callback = function()
            if setclipboard then
                setclipboard(game.JobId)
            end
            Window:Notify({Title = "Copied", Content = "JobId copied", Type = "Success", Duration = 2})
        end
    },
    Right = {
        Title = "Copy PlaceId",
        Callback = function()
            if setclipboard then
                setclipboard(tostring(game.PlaceId))
            end
            Window:Notify({Title = "Copied", Content = "PlaceId copied", Type = "Success", Duration = 2})
        end
    }
})
M:AddSpace(6)
M:AddCodeblock({
    Title = "Quick Script",
    Code = "for _,p in pairs(game.Players:GetPlayers()) do\n    print(p.Name, p.UserId)\nend",
    Callback = function() end
})

local S = Config:AddSection({Title = "Configuration"})
S:AddButton({
    Title = "Save Config",
    Description = "write flags to file",
    Callback = function()
        Window:SaveConfig("sh1ttybanana_config")
        Window:Notify({Title = "Saved", Content = "config written", Type = "Success", Duration = 2})
    end
})
S:AddButton({
    Title = "Load Config",
    Description = "read flags from file",
    Callback = function()
        Window:LoadConfig("sh1ttybanana_config")
        Window:Notify({Title = "Loaded", Content = "config applied", Type = "Success", Duration = 2})
    end
})
S:AddSlider({
    Title = "UI Transparency",
    Description = "window background transparency",
    Min = 0,
    Max = 80,
    Default = 7,
    Increment = 1,
    Callback = function(v)
        Window:SetTransparency(v / 100)
    end
})
S:AddDropdown({
    Title = "Select Tab",
    Description = "jump to a tab by name",
    Values = {"Main", "Combat", "Visuals", "Misc", "Settings"},
    Default = "Main",
    Callback = function(name)
        Window:SelectTab(name)
    end
})
S:AddParagraph({
    Title = "Flags",
    Content = "use Window:SetFlag / GetFlag with SaveConfig and LoadConfig for persistence"
})
S:AddTag({
    Title = "CONFIG",
    Color = Color3.fromRGB(100, 180, 255)
})
S:AddDivider()
S:AddKeybind({
    Title = "UI Toggle",
    Description = "show or hide window",
    Default = Enum.KeyCode.RightControl,
    Callback = function(k)
        print("UIToggle:", k.Name)
    end
})
S:AddColorpicker({
    Title = "Theme Preview",
    Description = "pick any color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) end
})
S:AddInput({
    Title = "Config Name",
    PlaceHolder = "my_config",
    Default = "sh1ttybanana_config",
    Callback = function(v)
        print("ConfigName:", v)
    end
})
S:AddSpace(10)
S:AddSeperator("AI Setup")
S:AddInput({
    Title = "Groq API Key",
    Description = "paste key then tab out to apply",
    PlaceHolder = "gsk_...",
    Default = "",
    Callback = function(key)
        Window:SetGroqConfig(key, "You are a helpful assistant for this Roblox hub. Suggest tabs with [tab:TabName].")
        Window:Notify({Title = "Groq", Content = "api key updated", Type = "Success", Duration = 2})
    end
})
S:AddParagraph({
    Title = "AI Button",
    Content = "bottom bar of the sidebar has Reorder, AI Assistant, and Player Card. open AI after setting your Groq key."
})

local L = Locked:AddSection({Title = "Secret"})
L:AddToggle({
    Title = "Secret Feature",
    Description = "only visible after unlock",
    Default = false,
    Callback = function(v)
        print("Secret:", v)
    end
})
L:AddParagraph({
    Title = "Unlocked",
    Content = "password was 1234. locked tabs use RememberKey so you only enter once."
})
L:AddButton({
    Title = "Secret Action",
    Callback = function()
        Window:Notify({Title = "Secret", Content = "private tab action", Type = "Success", Duration = 2})
    end
})

Window:Notify({
    Title = "Loaded",
    Content = "full sh1ttybanana example ready",
    Type = "Success",
    Duration = 4
})
