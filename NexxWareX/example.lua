local Library = loadstring(readfile("library.lua"))()

local Window = Library:CreateWindow({
	Title = "NexxWareX",
	Subtitle = "Liquid Glass",
	Icon = "layers",
	Size = UDim2.fromOffset(800, 540),
	Keybind = Enum.KeyCode.RightShift,
	ConfigFolder = "NexxWareX",
	Blur = true,
	Mobile = true,
})

Window:Tag({
	Title = "v2.1",
	Icon = "github",
	Color = Color3.fromHex("#30ff6a"),
	Radius = 13,
})

Window:Tag({
	Title = "BETA",
	Color = Color3.fromHex("#315dff"),
})

Window:AddTabLabel("Combat")

local Combat = Window:AddTab({
	Name = "Combat",
	Icon = "crosshair",
})

local Aim = Combat:AddSection({ Name = "Aimbot", Side = "Left" })
local Visual = Combat:AddSection({ Name = "Visuals", Side = "Right" })

Aim:AddToggle({
	Name = "Enabled",
	Flag = "combat.aim",
	Default = false,
	ToolTip = "Master aimbot switch",
	Callback = function(v)
		print("aimbot", v)
	end,
})

Aim:AddToggle({
	Name = "Rage mode",
	Flag = "combat.rage",
	Default = false,
	Dialog = {
		Title = "Enable rage?",
		Content = "High-risk option. Confirm to turn this on.",
		Confirm = "Enable",
		Cancel = "Stay safe",
		When = "on",
	},
	Callback = function(v)
		print("rage", v)
	end,
})

Aim:AddSlider({
	Name = "Field of view",
	Flag = "combat.fov",
	Min = 1,
	Max = 180,
	Default = 72,
	Suffix = "°",
	ToolTip = "Aim FOV radius",
	Callback = function(v)
		print("fov", v)
	end,
})

Aim:AddDropdown({
	Name = "Target",
	Flag = "combat.target",
	Values = { "Closest", "Lowest HP", "FOV" },
	Default = "Closest",
	Callback = function(v)
		print("target", v)
	end,
})

Aim:AddKeybind({
	Name = "Aim bind",
	Flag = "combat.bind",
	Default = Enum.KeyCode.E,
	Mode = "Hold",
	Callback = function(key, active, mode)
		print("bind", key, active, mode)
	end,
})

Aim:AddMultiButton({
	Buttons = {
		{
			Title = "Reset",
			Callback = function()
				if Library.Flags["combat.fov"] then
					Library.Flags["combat.fov"]:SetValue(72)
				end
				Library:Notify({ Title = "Aimbot", Content = "Reset", Type = "Success" })
			end,
		},
		{
			Title = "Panic",
			Dialog = {
				Title = "Panic unload?",
				Content = "Destroys the entire UI.",
				Confirm = "Unload",
			},
			Callback = function()
				Library:Unload()
			end,
		},
		{
			Title = "Apply preset",
			Callback = function()
				Library:Notify({ Title = "Preset", Content = "Applied", Type = "Info" })
			end,
		},
	},
})

Visual:AddToggle({
	Name = "ESP",
	Flag = "vis.esp",
	Default = true,
	Callback = function(v)
		print("esp", v)
	end,
})

Visual:AddColorPicker({
	Name = "ESP color",
	Flag = "vis.color",
	Default = Color3.fromRGB(154, 212, 255),
})

Visual:AddDropdown({
	Name = "Boxes",
	Flag = "vis.boxes",
	Multi = true,
	Values = { "Box", "Name", "Health", "Distance" },
	Default = { "Box", "Name" },
})

Visual:AddCodeBox({
	Title = "example.luau",
	Code = [[local Players = game:GetService("Players")
print(Players.LocalPlayer.Name)]],
})

local Silent = Combat:AddSubTab({
	Name = "Silent",
	Icon = "Lucide:eye",
})

local SilentSec = Silent:AddSection({ Name = "Silent aim", Side = "Left" })
SilentSec:AddToggle({
	Name = "Enabled",
	Flag = "silent.on",
	Default = false,
})
SilentSec:AddSlider({
	Name = "Hit chance",
	Flag = "silent.chance",
	Min = 0,
	Max = 100,
	Default = 80,
	Suffix = "%",
})

Window:AddTabLabel("World")

local World = Window:AddTab({
	Name = "World",
	Icon = "Lucide:globe",
})

local Env = World:AddSection({ Name = "Environment", Side = "Left" })
local Misc = World:AddSection({ Name = "Misc", Side = "Right" })

Env:AddSlider({
	Name = "Time of day",
	Flag = "world.clock",
	Min = 0,
	Max = 24,
	Default = 14,
	Rounding = 1,
	Suffix = "h",
})

Env:AddToggle({
	Name = "Fullbright",
	Flag = "world.fullbright",
	Default = false,
})

Env:AddTextInput({
	Name = "Walkspeed",
	Flag = "world.speed",
	Default = "16",
	Placeholder = "16",
})

Misc:AddButton({
	Name = "Copy Discord",
	Icon = "gravity:link",
	Callback = function()
		if setclipboard then
			setclipboard("https://discord.gg/example")
		end
		Library:Notify({ Title = "Copied", Content = "Invite on clipboard", Type = "Success" })
	end,
})

Misc:AddButton({
	Name = "Test error",
	Icon = "x",
	Callback = function()
		Library:Notify({ Title = "Error", Content = "Something failed", Type = "Error" })
	end,
})

Misc:AddButton({
	Name = "Test warn",
	Icon = "triangle-alert",
	Callback = function()
		Library:Notify({ Title = "Warning", Content = "Be careful", Type = "Warn" })
	end,
})

Misc:AddParagraph({
	Name = "Icons",
	Content = "Lucide:name · gravity:name · name (Lucide default)",
	ToolTip = "Icon pack syntax",
})

Window:AddLibrarySettings()

local wm = Window:Watermark()
wm:SetRender(true)
wm:AddBlock("layers", "NexxWareX")
wm:AddBlock("gauge", "60 FPS")

Library:Notify({
	Title = "NexxWareX",
	Content = "RightShift toggles the menu",
	Type = "Info",
	Icon = "layers",
})
