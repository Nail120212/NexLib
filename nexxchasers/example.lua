local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/nexxchasers/loader.lua"))()

Library:AddTheme("Nexx", {
	['Shadow'] = Color3.fromRGB(20, 20, 28),
	['Background'] = Color3.fromRGB(18, 18, 24),
	['Page'] = Color3.fromRGB(24, 24, 32),
	['Main'] = Color3.fromRGB(255, 255, 255),
	['Text & Icon'] = Color3.fromRGB(240, 240, 250),
	['Function'] = {
		['Toggle'] = {
			['Background'] = Color3.fromRGB(28, 28, 38),
			['True'] = {
				['Toggle Background'] = Color3.fromRGB(255, 255, 255),
				['Toggle Value'] = Color3.fromRGB(20, 20, 28),
			},
			['False'] = {
				['Toggle Background'] = Color3.fromRGB(45, 45, 55),
				['Toggle Value'] = Color3.fromRGB(140, 140, 160),
			}
		},
		['Label'] = { ['Background'] = Color3.fromRGB(28, 28, 38) },
		['Dropdown'] = {
			['Background'] = Color3.fromRGB(28, 28, 38),
			['Value Background'] = Color3.fromRGB(35, 35, 48),
			['Value Stroke'] = Color3.fromRGB(70, 70, 90),
			['Dropdown Select'] = {
				['Background'] = Color3.fromRGB(30, 30, 42),
				['Search'] = Color3.fromRGB(40, 40, 55),
				['Item Background'] = Color3.fromRGB(36, 36, 50),
			}
		},
		['Slider'] = {
			['Background'] = Color3.fromRGB(28, 28, 38),
			['Value Background'] = Color3.fromRGB(35, 35, 48),
			['Value Stroke'] = Color3.fromRGB(70, 70, 90),
			['Slider Bar'] = Color3.fromRGB(60, 60, 75),
			['Slider Bar Value'] = Color3.fromRGB(255, 255, 255),
			['Circle Value'] = Color3.fromRGB(255, 255, 255)
		},
		['Code'] = {
			['Background'] = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 30)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
			},
			['Background Code'] = Color3.fromRGB(28, 28, 38),
			['Background Code Value'] = Color3.fromRGB(40, 40, 55),
			['ScrollingFrame Code'] = Color3.fromRGB(180, 180, 200)
		},
		['Button'] = {
			['Background'] = Color3.fromRGB(28, 28, 38),
			['Click'] = Color3.fromRGB(255, 255, 255)
		},
		['Textbox'] = {
			['Background'] = Color3.fromRGB(28, 28, 38),
			['Value Background'] = Color3.fromRGB(35, 35, 48),
			['Value Stroke'] = Color3.fromRGB(70, 70, 90),
		},
		['Keybind'] = {
			['Background'] = Color3.fromRGB(28, 28, 38),
			['Value Background'] = Color3.fromRGB(35, 35, 48),
			['Value Stroke'] = Color3.fromRGB(70, 70, 90),
			['True'] = {
				['Toggle Background'] = Color3.fromRGB(255, 255, 255),
				['Toggle Value'] = Color3.fromRGB(20, 20, 28),
			},
			['False'] = {
				['Toggle Background'] = Color3.fromRGB(45, 45, 55),
				['Toggle Value'] = Color3.fromRGB(140, 140, 160),
			}
		},
		['Color Picker'] = {
			['Background'] = Color3.fromRGB(28, 28, 38),
			['Color Select'] = {
				['Background'] = Color3.fromRGB(35, 35, 48),
				['UIStroke'] = Color3.fromRGB(70, 70, 90),
			}
		}
	}
})

local Window = Library:Window({
	Title = "NexxChasers",
	Desc = "by Nexx • Chasers",
	Icon = "layout-dashboard",
	Theme = "Dark",
	Config = {
		Keybind = Enum.KeyCode.RightShift,
		Size = UDim2.new(0, 560, 0, 420),
	},
})

local Main = Window:Tab({ Title = "Main", Icon = "home" })
local Combat = Window:Tab({ Title = "Combat", Icon = "swords" })
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })

Main:Toggle({
	Title = "Speed Hack",
	Desc = "Increase walk speed",
	Value = false,
	Callback = function(v) print("Speed", v) end,
})

Main:Button({
	Title = "Reset Character",
	Desc = "Respawn",
	Callback = function()
		local c = game.Players.LocalPlayer.Character
		if c then c:BreakJoints() end
	end,
})

local locked = Main:Toggle({
	Title = "Premium Feature",
	Desc = "Requires VIP",
	Value = false,
	Locked = true,
	LockedText = "VIP Only",
	Callback = function(v) print("Premium", v) end,
})

Main:Button({
	Title = "Unlock Premium",
	Callback = function()
		if locked then locked:Unlock() end
	end,
})

Combat:Toggle({
	Title = "Aimbot",
	Value = false,
	Callback = function(v) print("Aimbot", v) end,
})

Settings:Button({
	Title = "Notify Test",
	Callback = function()
		print("NexxChasers ready")
	end,
})
