local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/nexxchasers/loader.lua"))()

local Window = Library:Window({
	Title = "NexxChasers",
	Desc = "Nexx • Chasers",
	Icon = "house",
	Theme = "Galaxy",
	Config = {
		Keybind = Enum.KeyCode.RightShift,
		Size = UDim2.new(0, 560, 0, 420),
		AutoScale = true,
	},
	CloseUIButton = {
		Enabled = true,
		Text = "Nexx",
	},
})

Window:SelectTab(1)

local Main = Window:Tab({ Title = "Main", Icon = "house" })
local Combat = Window:Tab({ Title = "Combat", Icon = "swords" })
local Settings = Window:Tab({ Title = "Settings", Icon = "gear" })

Main:Section({ Title = "Player" })

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

Main:Button({
	Title = "Reset Character",
	Callback = function()
		local c = game.Players.LocalPlayer.Character
		if c then c:BreakJoints() end
	end,
})

local lockedT = Main:Toggle({
	Title = "Premium Aim",
	Desc = "VIP feature",
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
	Callback = function(v) end,
})

Main:Button({
	Title = "Unlock All",
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
	Title = "Export Config",
	Callback = function()
		local json = Library:ExportConfig()
		print("Exported", json)
	end,
})

Settings:Button({
	Title = "Save Config",
	Callback = function()
		Library:SaveConfig("main")
	end,
})

Settings:Button({
	Title = "Load Config",
	Callback = function()
		Library:LoadConfig("main")
	end,
})
