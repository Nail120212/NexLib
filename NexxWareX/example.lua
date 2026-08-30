local Library = loadstring(readfile("library.lua"))()

local Window = Library:Window({
    Name = "NexxWareX",
    SubName = "1.0 Alpha",
    Logo = "rbxassetid://114856413138528",
})

local Page = Window:Page({ Name = "Combat", Icon = "rbxassetid://118813823415057" })
local Sub = Page:SubPage({ Name = "Aimbot", Description = "Combat options", Icon = "rbxassetid://74595432438103" })
local Sec = Sub:Section({ Name = "General", Side = 1 })

Sec:Toggle({ Name = "Enabled", Flag = "aim.enabled", Default = false, Callback = function(v) print(v) end })
Sec:Slider({ Name = "FOV", Flag = "aim.fov", Min = 1, Max = 180, Default = 90, Callback = function(v) print(v) end })
Sec:Dropdown({ Name = "Target", Flag = "aim.target", Items = { "Closest", "Lowest HP", "FOV" }, Default = "Closest" })
Sec:Button({ Name = "Minimize UI", Callback = function() Window:SetOpen(false) end })

Library:CreateSettingsPage()
