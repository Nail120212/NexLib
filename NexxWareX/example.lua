local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/NexxWareX/library.lua"))()

local Window = Library:CreateWindow({
	Title = "NexxWareX",
	Subtitle = "Liquid Glass",
	Icon = "layers",
	Size = UDim2.fromOffset(800, 540),
	Keybind = Enum.KeyCode.RightShift,
	ConfigFolder = "NexxWareX",
	Blur = true,
	Acrylic = true,
	Mobile = true,
	AutoLoad = "Default",
})

Window:Tag({
	Title = "1.0 Alpha",
	Icon = "github",
	Color = Color3.fromHex("#30ff6a"),
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

local aimToggle = Aim:AddToggle({
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
		Content = "High-risk option.",
		Confirm = "Enable",
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
})

Aim:AddDropdown({
	Name = "Target",
	Flag = "combat.target",
	Values = { "Closest", "Lowest HP", "FOV" },
	Default = "Closest",
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
			Title = "Lock aim",
			Callback = function()
				aimToggle:Lock()
				Library:Notify({ Title = "Locked", Content = "Aim toggle locked", Type = "Warn" })
			end,
		},
		{
			Title = "Unlock",
			Callback = function()
				aimToggle:Unlock()
				Library:Notify({ Title = "Unlocked", Content = "Aim toggle free", Type = "Success" })
			end,
		},
		{
			Title = "Rename + destroy demo",
			Callback = function()
				aimToggle:SetTitle("Aim (renamed)")
			end,
		},
	},
})

Visual:AddToggle({
	Name = "ESP",
	Flag = "vis.esp",
	Default = true,
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
	Code = [[print("NexxWareX")]],
})

Visual:AddParagraph({
	Name = "NexxWareX",
	Content = "Liquid glass UI with tags, code, and multi-button rows.",
	Buttons = {
		{
			Title = "GitHub",
			Callback = function()
				Library:Notify({ Title = "GitHub", Content = "Opened (demo)", Type = "Info" })
			end,
		},
		{
			Title = "Discord",
			Callback = function()
				if setclipboard then setclipboard("https://discord.gg/example") end
				Library:Notify({ Title = "Copied", Content = "Invite", Type = "Success" })
			end,
		},
	},
})

local Silent = Combat:AddSubTab({
	Name = "Silent",
	Icon = "Lucide:eye",
})

local SilentSec = Silent:AddSection({ Name = "Silent aim", Side = "Left" })
SilentSec:AddToggle({ Name = "Enabled", Flag = "silent.on", Default = false })
SilentSec:AddSlider({ Name = "Hit chance", Flag = "silent.chance", Min = 0, Max = 100, Default = 80, Suffix = "%" })

Window:AddTabLabel("World")

local World = Window:AddTab({ Name = "World", Icon = "Lucide:globe" })
local Env = World:AddSection({ Name = "Environment", Side = "Left" })
local Misc = World:AddSection({ Name = "Misc", Side = "Right" })

Env:AddSlider({ Name = "Time of day", Flag = "world.clock", Min = 0, Max = 24, Default = 14, Rounding = 1, Suffix = "h" })
Env:AddToggle({ Name = "Fullbright", Flag = "world.fullbright", Default = false })
Env:AddTextInput({ Name = "Walkspeed", Flag = "world.speed", Default = "16", Placeholder = "16" })

Misc:AddButton({
	Name = "Spam notify",
	Icon = "bell",
	Callback = function()
		for i = 1, 8 do
			Library:Notify({ Title = "Stack " .. i, Content = "Limited to 5", Type = i % 2 == 0 and "Warn" or "Info" })
		end
	end,
})

Misc:AddButton({
	Name = "Unload",
	Icon = "x",
	Dialog = {
		Title = "Unload?",
		Content = "Destroys UI, blur, acrylic, signals.",
		Confirm = "Unload",
	},
	Callback = function()
		Library:Unload()
	end,
})

Window:AddLibrarySettings()

local wm = Window:Watermark()
wm:SetRender(true)
wm:AddBlock("layers", "NexxWareX")

Library:Notify({
	Title = "NexxWareX",
	Content = "RightShift toggles · AutoLoad Default",
	Type = "Info",
	Icon = "layers",
})
