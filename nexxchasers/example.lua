local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/nexxchasers/loader.lua"))()

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
	CloseUIButton = { Enabled = true },
})

Window:SelectTab(1)

local Main = Window:Tab({ Title = "Main", Icon = "house" })
local Combat = Window:Tab({ Title = "Combat", Icon = "swords" })
local Settings = Window:Tab({ Title = "Settings", Icon = "gear" })

Main:Section({ Title = "Player" })
Main:Tag({ Text = "CORE", Color = Color3.fromRGB(255, 180, 50) })

Main:Toggle({
	Title = "Speed Hack",
	Desc = "Walk faster",
	Value = false,
	Callback = function(v) print("Speed", v) end,
})

Main:Slider({
	Title = "WalkSpeed",
	Min = 16,
	Max = 200,
	Value = 16,
	Rounding = 0,
	Callback = function(v) print("WS", v) end,
})

Main:Stepper({
	Title = "Jump Power",
	Min = 50,
	Max = 200,
	Value = 50,
	Step = 5,
	Callback = function(v) print("JP", v) end,
})

Main:Segmented({
	Title = "Mode",
	Options = { "Legit", "Rage", "AFK" },
	Value = "Legit",
	Callback = function(v) print("Mode", v) end,
})

Main:RangeSlider({
	Title = "FOV Range",
	Min = 10,
	Max = 120,
	ValueMin = 60,
	ValueMax = 90,
	Callback = function(a, b) print("FOV", a, b) end,
})

Main:Button({
	Title = "Reset Character",
	Callback = function()
		local c = game.Players.LocalPlayer.Character
		if c then c:BreakJoints() end
	end,
})

local lockedT = Main:Toggle({
	Title = "Premium Aim",
	Value = false,
	Locked = true,
	LockedText = "Locked",
	Callback = function(v) print("Premium", v) end,
})

local lockedS = Main:Slider({
	Title = "Premium Range",
	Min = 0,
	Max = 100,
	Value = 50,
	Locked = true,
	LockedText = "Locked",
})

Main:Button({
	Title = "Unlock Premium",
	Callback = function()
		if lockedT then lockedT:Unlock() end
		if lockedS then lockedS:Unlock() end
	end,
})

Combat:Toggle({
	Title = "Aimbot",
	Value = false,
	Callback = function(v) print("Aimbot", v) end,
})

Settings:Button({
	Title = "Export Config (clipboard)",
	Callback = function()
		print(Library:ExportConfig())
	end,
})

Settings:Button({
	Title = "Save Config",
	Callback = function() Library:SaveConfig("main") end,
})

Settings:Button({
	Title = "Load Config",
	Callback = function() Library:LoadConfig("main") end,
})

Settings:Button({
	Title = "Toggle Anonymous Profile",
	Callback = function()
		if Window.SetAnonymous then
			Window.SetAnonymous(true)
		end
	end,
})

Settings:Button({
	Title = "Show Real Profile",
	Callback = function()
		if Window.SetAnonymous then
			Window.SetAnonymous(false)
		end
	end,
})
