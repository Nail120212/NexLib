local src = game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua")
src = src:gsub("clickBtn:Activated:Connect", "clickBtn.Activated:Connect")
local Library = loadstring(src)()

local Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "full demo",
    Color = Color3.fromRGB(179, 0, 255),
    Size = UDim2.new(0, 620, 0, 420),
    Transparent = 0.07,
    AutoScale = true
})

Window:SetGroqConfig(
    "YOUR_GROQ_API_KEY_HERE",
    "You are a helpful assistant for this Roblox hub. Suggest tabs with [tab:TabName]."
)

Window:Tag({Title = "FULL", Color = Color3.fromRGB(48, 255, 106)})

local PlayerSec = Window:Section({Title = "Player", Opened = true})
local WorldSec = Window:Section({Title = "World", Opened = true})
local ConfigSec = Window:Section({Title = "Config", Opened = true})

local Main = PlayerSec:T({Title = "Main", Icon = "home"})
local Combat = PlayerSec:T({Title = "Combat", Icon = "swords"})
local Visuals = WorldSec:T({Title = "Visuals", Icon = "eye"})
local Misc = WorldSec:T({Title = "Misc", Icon = "settings"})
local Settings = ConfigSec:T({Title = "Settings", Icon = "sliders-horizontal"})

local G = Main:AddSection({Title = "General"})
G:AddToggle({Title = "Master Enable", Default = false, Callback = function(v) print("Master:", v) end})
G:AddButton({Title = "Notify", Callback = function()
    Window:Notify({Title = "OK", Content = "working", Type = "Success", Duration = 3})
end})
G:AddButton({Title = "Dialog", Callback = function()
    Window:Dialog({
        Title = "Confirm",
        Content = "continue?",
        Buttons = {
            {Title = "Yes", Variant = "Primary", Callback = function() end},
            {Title = "No", Callback = function() end}
        }
    })
end})
G:AddDivider()
G:AddSlider({Title = "WalkSpeed", Min = 16, Max = 200, Default = 16, Increment = 1, Callback = function(v)
    local c = game.Players.LocalPlayer.Character
    if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = v end
end})
G:AddDropdown({Title = "Mode", Values = {"Normal", "Rage", "Legit"}, Default = "Normal", Callback = function(v) print(v) end})
G:AddInput({Title = "Target", PlaceHolder = "username", Default = "", Callback = function(v) print(v) end})
G:AddKeybind({Title = "Panic", Default = Enum.KeyCode.P, Callback = function(k) print(k.Name) end})
G:AddColorpicker({Title = "Accent", Default = Color3.fromRGB(179, 0, 255), Callback = function(c) end})
G:AddTag({Title = "LIVE", Color = Color3.fromRGB(48, 255, 106)})
G:AddMultiButton({
    Full = {Title = "Full Action", Callback = function() end},
    Left = {Title = "Left", Callback = function() end},
    Right = {Title = "Right", Callback = function() end}
})
G:AddCodeblock({Title = "Runner", Code = "print('hello')", Callback = function() end})
G:AddParagraph({Title = "AI", Content = "sidebar bottom: Reorder | AI | PlayerCard"})
G:AddSpace(6)

local C = Combat:AddSection({Title = "Aim"})
C:AddToggle({Title = "Aimbot", Default = false, Callback = function(v) end})
C:AddSlider({Title = "FOV", Min = 50, Max = 500, Default = 120, Increment = 5, Callback = function(v) end})
C:AddDropdown({Title = "Part", Values = {"Head", "Torso", "HumanoidRootPart"}, Default = "Head", Callback = function(v) end})
C:AddKeybind({Title = "Aim Key", Default = Enum.KeyCode.E, Callback = function(k) end})
C:AddColorpicker({Title = "FOV Color", Default = Color3.fromRGB(255, 50, 50), Callback = function(c) end})

local V = Visuals:AddSection({Title = "ESP"})
V:AddToggle({Title = "Box ESP", Default = false, Callback = function(v) end})
V:AddToggle({Title = "Names", Default = false, Callback = function(v) end})
V:AddSlider({Title = "Distance", Min = 100, Max = 5000, Default = 1000, Increment = 50, Callback = function(v) end})
V:AddColorpicker({Title = "Enemy", Default = Color3.fromRGB(255, 60, 60), Callback = function(c) end})
V:AddSeperator("Chams")
V:AddToggle({Title = "Chams", Default = false, Callback = function(v) end})
V:AddDropdown({Title = "Style", Values = {"Outline", "Fill", "Both"}, Default = "Outline", Callback = function(v) end})

local M = Misc:AddSection({Title = "World"})
M:AddToggle({Title = "Fullbright", Default = false, Callback = function(v)
    if v then
        game.Lighting.Brightness = 2
        game.Lighting.ClockTime = 14
        game.Lighting.FogEnd = 100000
        game.Lighting.GlobalShadows = false
    else
        game.Lighting.Brightness = 1
        game.Lighting.GlobalShadows = true
    end
end})
M:AddSlider({Title = "Time", Min = 0, Max = 24, Default = 14, Increment = 0.5, Callback = function(v) game.Lighting.ClockTime = v end})
M:AddInput({Title = "Teleport", PlaceHolder = "player", Default = "", Callback = function(name)
    local p = game.Players:FindFirstChild(name)
    local lp = game.Players.LocalPlayer
    if p and p.Character and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
    end
end})
M:AddButton({Title = "Rejoin", Callback = function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
end})

local S = Settings:AddSection({Title = "Config"})
S:AddInput({
    Title = "Groq API Key",
    PlaceHolder = "gsk_...",
    Default = "",
    Callback = function(key)
        Window:SetGroqConfig(key, "You are a helpful assistant. Suggest tabs with [tab:TabName].")
        Window:Notify({Title = "Groq", Content = "key saved", Type = "Success", Duration = 2})
    end
})
S:AddButton({Title = "Save Config", Callback = function()
    Window:SaveConfig("sh1ttybanana_config")
    Window:Notify({Title = "Saved", Content = "ok", Type = "Success", Duration = 2})
end})
S:AddButton({Title = "Load Config", Callback = function()
    Window:LoadConfig("sh1ttybanana_config")
    Window:Notify({Title = "Loaded", Content = "ok", Type = "Success", Duration = 2})
end})
S:AddSlider({Title = "Transparency", Min = 0, Max = 80, Default = 7, Increment = 1, Callback = function(v)
    Window:SetTransparency(v / 100)
end})
S:AddDropdown({Title = "Jump Tab", Values = {"Main", "Combat", "Visuals", "Misc", "Settings"}, Default = "Main", Callback = function(n)
    Window:SelectTab(n)
end})
S:AddParagraph({Title = "AI", Content = "SetGroqConfig(key, prompt). Open AI from bot icon on sidebar bottom bar."})

Window:Notify({Title = "Loaded", Content = "ready", Type = "Success", Duration = 3})
