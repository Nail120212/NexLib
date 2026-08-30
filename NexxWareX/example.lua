--[[
	Fluid Glass — example
	Place library.lua next to this file, then run.

	Icons:
	  "crosshair"      → Lucide (default)
	  "Lucide:eye"     → Lucide pack
	  "gravity:gear"   → Gravity pack
]]

local Library
do
	local ok, src = pcall(readfile, "library.lua")
	if ok and src then
		Library = loadstring(src)()
	else
		-- fallback: same folder via HttpGet if you host it
		error("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/NexxWareX/library.lua")
	end
end

local Window = Library:CreateWindow({
	Title = "Fluid Glass",
	Subtitle = "Liquid Glass",
	Icon = "layers",
	Size = UDim2.fromOffset(800, 540),
	Keybind = Enum.KeyCode.RightShift,
	ConfigFolder = "FluidGlass",
	Blur = true,
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
	Rounding = 0,
	Suffix = "°",
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
	Callback = function(key)
		print("bind", key)
	end,
})

Aim:AddButton({
	Name = "Reset aimbot",
	Icon = "rotate-ccw",
	Dialog = {
		Title = "Reset aimbot?",
		Content = "Restores FOV, target, and binds to defaults.",
		Confirm = "Reset",
	},
	Callback = function()
		if Library.Flags["combat.fov"] then
			Library.Flags["combat.fov"]:SetValue(72)
		end
		Library:Notify({ Title = "Aimbot", Content = "Reset to defaults", Icon = "check" })
	end,
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
	Callback = function(c)
		print("color", c)
	end,
})

Visual:AddDropdown({
	Name = "Boxes",
	Flag = "vis.boxes",
	Multi = true,
	Values = { "Box", "Name", "Health", "Distance" },
	Default = { "Box", "Name" },
})

Visual:AddParagraph({
	Name = "Icons",
	Content = "Use Lucide:name, gravity:name, or name (Lucide default).",
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
		Library:Notify({ Title = "Copied", Content = "Invite on clipboard", Icon = "check" })
	end,
})

Misc:AddButton({
	Name = "Unload library",
	Icon = "x",
	Dialog = {
		Title = "Unload Fluid Glass?",
		Content = "Destroys the UI and disconnects blur.",
		Confirm = "Unload",
	},
	Callback = function()
		Library:Unload()
	end,
})

Misc:AddDivider()
Misc:AddParagraph({
	Name = "ZIndex map",
	Content = "Window 10 · Sidebar 20 · Header 26 · Popup 50 · Dialog 86 · Notify 96",
})

-- Settings: Save / Load / Export / Import / Delete
Window:AddLibrarySettings()

Library:Notify({
	Title = "Fluid Glass",
	Content = "RightShift toggles the menu",
	Icon = "layers",
})
