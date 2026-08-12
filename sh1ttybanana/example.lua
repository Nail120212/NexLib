local src = game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/sh1ttybanana/sh1ttybanana.lua")
src = src:gsub("clickBtn:Activated:Connect", "clickBtn.Activated:Connect")
src = src:gsub("Layout%.CanvasSize = UDim2%.new%(0, 0, 1, 0%)", "Layout.CanvasSize = UDim2.new(0, 0, 0, 0)\n        Layout.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y\n        Layout.ScrollBarThickness = 2")
local Library = loadstring(src)()

local Window = Library:NewWindow({
    Title = "sh1ttybanana",
    Description = "full demo",
    Logo = "rbxassetid://89646749075297",
    Color = Color3.fromRGB(179, 0, 255),
    Size = UDim2.new(0, 620, 0, 420),
    Transparent = 0.07,
    AutoScale = true
})

Window:SetGroqConfig("YOUR_GROQ_API_KEY_HERE", "You are a helpful assistant. Suggest tabs with [tab:TabName].")
Window:Tag({Title = "FULL", Color = Color3.fromRGB(48, 255, 106)})

local Main = Window:T("Main", "home")
local Combat = Window:T("Combat", "swords")
local Visuals = Window:T("Visuals", "eye")
local Misc = Window:T("Misc", "settings")
local Settings = Window:T("Settings", "sliders-horizontal")

local G = Main:AddSection("General")
G:AddToggle({Title = "Master Enable", Description = "main switch", Default = false, Callback = function(v) print("Master:", v) end})
G:AddButton({Title = "Notify Success", Description = "test notify", Callback = function()
    Window:Notify({Title = "Success", Content = "working", Type = "Success", Duration = 3})
end})
G:AddButton({Title = "Notify Error", Callback = function()
    Window:Notify({Title = "Error", Content = "failed", Type = "Error", Duration = 3})
end})
G:AddButton({Title = "Dialog", Callback = function()
    Window:Dialog({
        Title = "Confirm",
        Content = "are you sure?",
        Buttons = {
            {Title = "Yes", Variant = "Primary", Callback = function() print("yes") end},
            {Title = "No", Callback = function() print("no") end}
        }
    })
end})
G:AddDivider()
G:AddSlider({Title = "WalkSpeed", Description = "speed", Min = 16, Max = 200, Default = 16, Increment = 1, Callback = function(v)
    local c = game.Players.LocalPlayer.Character
    if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = v end
end})
G:AddSlider({Title = "JumpPower", Min = 50, Max = 200, Default = 50, Increment = 1, Callback = function(v)
    local c = game.Players.LocalPlayer.Character
    if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = v end
end})
G:AddDropdown({Title = "Mode", Description = "play style", Values = {"Normal", "Rage", "Legit", "Custom"}, Default = "Normal", Callback = function(v) print(v) end})
G:AddInput({Title = "Target", Description = "player name", PlaceHolder = "username", Default = "", Callback = function(v) print(v) end})
G:AddKeybind({Title = "Panic Key", Description = "hide key", Default = Enum.KeyCode.P, Callback = function(k) print(k.Name) end})
G:AddColorpicker({Title = "Accent", Description = "color", Default = Color3.fromRGB(179, 0, 255), Callback = function(c) end})
G:AddTag({Title = "LIVE", Color = Color3.fromRGB(48, 255, 106)})
G:AddSeperator("Actions")
G:AddMultiButton({
    Full = {Title = "Full Action", Callback = function() Window:Notify({Title = "Full", Content = "pressed", Type = "Info", Duration = 2}) end},
    Left = {Title = "Left", Callback = function() end},
    Right = {Title = "Right", Callback = function() end}
})
G:AddCodeblock({Title = "Lua Runner", Code = "print('hello from sh1ttybanana')", Callback = function() end})
G:AddParagraph({Title = "Info", Content = "AI bot icon is on the sidebar bottom bar. Set Groq key in Settings."})
G:AddSpace(8)

local C = Combat:AddSection("Aim")
C:AddToggle({Title = "Aimbot", Default = false, Callback = function(v) end})
C:AddToggle({Title = "Silent Aim", Default = false, Callback = function(v) end})
C:AddSlider({Title = "FOV", Min = 50, Max = 500, Default = 120, Increment = 5, Callback = function(v) end})
C:AddSlider({Title = "Smoothness", Min = 1, Max = 20, Default = 5, Increment = 1, Callback = function(v) end})
C:AddDropdown({Title = "Target Part", Values = {"Head", "Torso", "HumanoidRootPart"}, Default = "Head", Callback = function(v) end})
C:AddDropdown({Title = "Priority", Values = {"Closest", "Lowest HP", "Highest HP"}, Default = "Closest", Callback = function(v) end})
C:AddKeybind({Title = "Aim Key", Default = Enum.KeyCode.E, Callback = function(k) end})
C:AddColorpicker({Title = "FOV Color", Default = Color3.fromRGB(255, 50, 50), Callback = function(c) end})

local V = Visuals:AddSection("ESP")
V:AddToggle({Title = "Box ESP", Default = false, Callback = function(v) end})
V:AddToggle({Title = "Name ESP", Default = false, Callback = function(v) end})
V:AddToggle({Title = "Tracer", Default = false, Callback = function(v) end})
V:AddSlider({Title = "Max Distance", Min = 100, Max = 5000, Default = 1000, Increment = 50, Callback = function(v) end})
V:AddColorpicker({Title = "Enemy Color", Default = Color3.fromRGB(255, 60, 60), Callback = function(c) end})
V:AddColorpicker({Title = "Team Color", Default = Color3.fromRGB(60, 255, 120), Callback = function(c) end})
V:AddSeperator("Chams")
V:AddToggle({Title = "Chams", Default = false, Callback = function(v) end})
V:AddDropdown({Title = "Chams Style", Values = {"Outline", "Fill", "Both"}, Default = "Outline", Callback = function(v) end})

local M = Misc:AddSection("World")
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
M:AddToggle({Title = "No Fog", Default = false, Callback = function(v)
    game.Lighting.FogEnd = v and 100000 or 1000
end})
M:AddSlider({Title = "Time of Day", Min = 0, Max = 24, Default = 14, Increment = 0.5, Callback = function(v)
    game.Lighting.ClockTime = v
end})
M:AddInput({Title = "Teleport To", PlaceHolder = "player name", Default = "", Callback = function(name)
    local p = game.Players:FindFirstChild(name)
    local lp = game.Players.LocalPlayer
    if p and p.Character and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
    end
end})
M:AddButton({Title = "Rejoin", Callback = function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
end})
M:AddMultiButton({
    Full = {Title = "Server Hop", Callback = function() end},
    Left = {Title = "Copy JobId", Callback = function() if setclipboard then setclipboard(game.JobId) end end},
    Right = {Title = "Copy PlaceId", Callback = function() if setclipboard then setclipboard(tostring(game.PlaceId)) end end}
})

local S = Settings:AddSection("Config")
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
S:AddSlider({Title = "UI Transparency", Min = 0, Max = 80, Default = 7, Increment = 1, Callback = function(v)
    Window:SetTransparency(v / 100)
end})
S:AddDropdown({Title = "Jump Tab", Values = {"Main", "Combat", "Visuals", "Misc", "Settings"}, Default = "Main", Callback = function(n)
    Window:SelectTab(n)
end})
S:AddKeybind({Title = "UI Toggle", Default = Enum.KeyCode.RightControl, Callback = function(k) end})
S:AddParagraph({Title = "AI", Content = "Window:SetGroqConfig(key, prompt). Open AI from the bot icon on the sidebar bottom bar."})

Window:Notify({Title = "Loaded", Content = "all components ready", Type = "Success", Duration = 3})
