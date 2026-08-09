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
		Size = UDim2.new(0, 580, 0, 460),
		AutoScale = true,
		Transparency = 0.05,
		Anonymous = false,
		Tags = {
			{ Text = "BETA", Color = Color3.fromRGB(255, 200, 50) },
			{ Text = "v2", Color = Color3.fromRGB(120, 200, 255) },
		},
	},
	CloseUIButton = { Enabled = true },
})

Window:SelectTab(1)

local ButtonsTab = Window:Tab({ Title = "Buttons", Icon = "house" })
local TogglesTab = Window:Tab({ Title = "Toggles", Icon = "house" })
local SlidersTab = Window:Tab({ Title = "Sliders", Icon = "house" })
local InputsTab = Window:Tab({ Title = "Inputs", Icon = "house" })
local DropdownsTab = Window:Tab({ Title = "Dropdowns", Icon = "house" })
local KeybindsTab = Window:Tab({ Title = "Keybinds", Icon = "house" })
local ColorsTab = Window:Tab({ Title = "Colors", Icon = "house" })
local CodeTab = Window:Tab({ Title = "Code", Icon = "house" })
local ExtraTab = Window:Tab({ Title = "Extra", Icon = "house" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "house" })

ButtonsTab:Section({ Title = "Buttons" })
ButtonsTab:Button({
	Title = "Normal Button",
	Desc = "Click me",
	Callback = function()
		print("Normal button clicked")
	end,
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
	Desc = "VIP only",
	Locked = true,
	LockedText = "Locked",
	Callback = function()
		print("locked click")
	end,
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
TogglesTab:Toggle({
	Title = "Infinite Jump",
	Value = false,
	Callback = function(v) print("Jump", v) end,
})
local lockedToggle = TogglesTab:Toggle({
	Title = "Premium Aim",
	Desc = "Requires VIP",
	Value = false,
	Locked = true,
	LockedText = "Locked",
	Callback = function(v) print("Premium", v) end,
})
TogglesTab:Button({
	Title = "Unlock Premium Toggle",
	Callback = function()
		if lockedToggle and lockedToggle.Unlock then lockedToggle:Unlock() end
	end,
})

SlidersTab:Section({ Title = "Sliders" })
SlidersTab:Slider({
	Title = "WalkSpeed",
	Min = 16,
	Max = 200,
	Value = 16,
	Rounding = 0,
	Callback = function(v) print("WS", v) end,
})
SlidersTab:Slider({
	Title = "JumpPower",
	Min = 50,
	Max = 200,
	Value = 50,
	Rounding = 0,
	Callback = function(v) print("JP", v) end,
})
local lockedSlider = SlidersTab:Slider({
	Title = "Premium Range",
	Min = 0,
	Max = 100,
	Value = 50,
	Locked = true,
	LockedText = "Locked",
	Callback = function(v) end,
})
SlidersTab:Button({
	Title = "Unlock Premium Slider",
	Callback = function()
		if lockedSlider and lockedSlider.Unlock then lockedSlider:Unlock() end
	end,
})
SlidersTab:Stepper({
	Title = "Stepped Value",
	Min = 0,
	Max = 50,
	Value = 10,
	Step = 5,
	Callback = function(v) print("Step", v) end,
})
SlidersTab:RangeSlider({
	Title = "FOV Range",
	Min = 10,
	Max = 120,
	ValueMin = 60,
	ValueMax = 90,
	Callback = function(a, b) print("FOV", a, b) end,
})

InputsTab:Section({ Title = "Text Inputs" })
InputsTab:Textbox({
	Title = "Username",
	Placeholder = "Enter name...",
	Callback = function(t) print("Name", t) end,
})
InputsTab:Label({
	Title = "Info",
	Desc = "Use textbox above",
})

DropdownsTab:Section({ Title = "Dropdowns" })
DropdownsTab:Dropdown({
	Title = "Teleport",
	Options = { "Spawn", "Bank", "Shop", "Safezone" },
	Value = "Spawn",
	Callback = function(v) print("TP", v) end,
})
DropdownsTab:Segmented({
	Title = "Mode",
	Options = { "Legit", "Rage", "AFK" },
	Value = "Legit",
	Callback = function(v) print("Mode", v) end,
})

KeybindsTab:Section({ Title = "Keybinds" })
KeybindsTab:Keybind({
	Title = "Panic Key",
	Value = Enum.KeyCode.P,
	Callback = function(k) print("Panic", k) end,
})

ColorsTab:Section({ Title = "Color Pickers" })
ColorsTab:ColorPicker({
	Title = "ESP Color",
	Value = Color3.fromRGB(255, 50, 50),
	Callback = function(c) print(c) end,
})

CodeTab:Section({ Title = "Code" })
CodeTab:Code({
	Title = "example.lua",
	Code = 'print("Hello from NexxChasers")\nprint(game.Players.LocalPlayer.Name)',
})

ExtraTab:Section({ Title = "Tags" })
ExtraTab:Tag({ Text = "CORE", Color = Color3.fromRGB(255, 180, 50) })
ExtraTab:Tag({ Text = "SAFE", Color = Color3.fromRGB(80, 220, 120) })
ExtraTab:Section({ Title = "Profile" })
ExtraTab:Button({
	Title = "Set Anonymous",
	Callback = function()
		if Window.SetAnonymous then Window.SetAnonymous(true) end
	end,
})
ExtraTab:Button({
	Title = "Show Real Profile",
	Callback = function()
		if Window.SetAnonymous then Window.SetAnonymous(false) end
	end,
})

SettingsTab:Section({ Title = "Config" })
SettingsTab:Button({
	Title = "Export Config",
	Callback = function()
		print(Library:ExportConfig())
	end,
})
SettingsTab:Button({
	Title = "Save Config",
	Callback = function()
		Library:SaveConfig("main")
	end,
})
SettingsTab:Button({
	Title = "Load Config",
	Callback = function()
		Library:LoadConfig("main")
	end,
})
