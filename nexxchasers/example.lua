local ok, Library = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/nexxchasers/loader.lua"))()
end)
if not ok or type(Library) ~= "table" then
	warn("[NexxChasers] load failed:", Library)
	return
end

local Window = Library:Window({
	Title = "NexxChasers",
	Desc = "Nexx • Chasers",
	Icon = "house",
	Theme = "Galaxy",
	Config = {
		Keybind = Enum.KeyCode.RightShift,
		Size = UDim2.new(0, 560, 0, 440),
		AutoScale = true,
		Transparency = 0.05,
		Anonymous = false,
		Tags = {
			{ Text = "BETA", Color = Color3.fromRGB(255, 200, 50) },
			{ Text = "v2", Color = Color3.fromRGB(120, 200, 255) },
		},
	},
	CloseUIButton = { Enabled = true, Text = "Nexx" },
})

Window:SelectTab(1)

local ButtonsTab = Window:Tab({ Title = "Buttons", Icon = "house" })
local TogglesTab = Window:Tab({ Title = "Toggles", Icon = "house" })
local ScalesTab = Window:Tab({ Title = "Sliders", Icon = "house" })
local InputsTab = Window:Tab({ Title = "Inputs", Icon = "house" })
local DropsTab = Window:Tab({ Title = "Dropdowns", Icon = "house" })
local KeysTab = Window:Tab({ Title = "Keybinds", Icon = "house" })
local ColorsTab = Window:Tab({ Title = "Colors", Icon = "house" })
local CodeTab = Window:Tab({ Title = "Code", Icon = "house" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "house" })

ButtonsTab:Section({ Title = "Buttons" })
ButtonsTab:Button({
	Title = "Normal Button",
	Desc = "Click me",
	Callback = function() print("clicked") end,
})
ButtonsTab:Button({
	Title = "Reset Character",
	Callback = function()
		local c = game.Players.LocalPlayer.Character
		if c then c:BreakJoints() end
	end,
})
local lockedBtn = ButtonsTab:Button({
	Title = "Locked Button",
	Locked = true,
	LockedText = "Locked",
	Callback = function() print("should not fire") end,
})
ButtonsTab:Button({
	Title = "Unlock Locked Button",
	Callback = function()
		if lockedBtn and lockedBtn.Unlock then lockedBtn:Unlock() end
	end,
})

TogglesTab:Section({ Title = "Toggles" })
TogglesTab:Toggle({
	Title = "Speed Hack",
	Desc = "Walk faster",
	Value = false,
	Callback = function(v) print("Speed", v) end,
})
local lockedToggle = TogglesTab:Toggle({
	Title = "Premium Aim",
	Value = false,
	Locked = true,
	LockedText = "Locked",
	Callback = function(v) print("Premium", v) end,
})
TogglesTab:Button({
	Title = "Unlock Premium",
	Callback = function()
		if lockedToggle and lockedToggle.Unlock then lockedToggle:Unlock() end
	end,
})

ScalesTab:Section({ Title = "Sliders" })
ScalesTab:Slider({
	Title = "WalkSpeed",
	Min = 16,
	Max = 200,
	Value = 16,
	Rounding = 0,
	Callback = function(v) print("WS", v) end,
})
ScalesTab:Slider({
	Title = "JumpPower",
	Min = 50,
	Max = 200,
	Value = 50,
	Rounding = 0,
	Callback = function(v) print("JP", v) end,
})

InputsTab:Section({ Title = "Inputs" })
InputsTab:Textbox({
	Title = "Username",
	Callback = function(t) print("Name", t) end,
})
InputsTab:Label({
	Title = "Info",
	Desc = "Label component",
})

DropsTab:Section({ Title = "Dropdowns" })
DropsTab:Dropdown({
	Title = "Teleport",
	Options = { "Spawn", "Bank", "Shop" },
	Value = "Spawn",
	Callback = function(v) print("TP", v) end,
})

KeysTab:Section({ Title = "Keybinds" })
KeysTab:Keybind({
	Title = "Panic Key",
	Value = Enum.KeyCode.P,
	Callback = function(k) print("Panic", k) end,
})

ColorsTab:Section({ Title = "Colors" })
ColorsTab:ColorPicker({
	Title = "ESP Color",
	Value = Color3.fromRGB(255, 50, 50),
	Callback = function(c) print(c) end,
})

CodeTab:Section({ Title = "Code" })
CodeTab:Code({
	Title = "example.lua",
	Code = 'print("Hello NexxChasers")',
})

SettingsTab:Section({ Title = "Config" })
SettingsTab:Button({
	Title = "Export Config",
	Callback = function() print(Library:ExportConfig()) end,
})
SettingsTab:Button({
	Title = "Save Config",
	Callback = function() Library:SaveConfig("main") end,
})
SettingsTab:Button({
	Title = "Load Config",
	Callback = function() Library:LoadConfig("main") end,
})
SettingsTab:Section({ Title = "Profile" })
SettingsTab:Button({
	Title = "Anonymous On",
	Callback = function()
		if Window.SetAnonymous then Window.SetAnonymous(true) end
	end,
})
SettingsTab:Button({
	Title = "Anonymous Off",
	Callback = function()
		if Window.SetAnonymous then Window.SetAnonymous(false) end
	end,
})
