local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/nexxchasers/loader.lua"))() -- or require the local loader

local Window = Library:Window({
	Title = "NexxChasers",
	Author = "UI Library",
	Theme = "Dark",
	Logo = "house",
	Config = {
		ToggleKeybind = Enum.KeyCode.LeftControl,
		Size = UDim2.new(0, 580, 0, 420),
		AutoScale = true,
		Transparency = 0,
		Tags = {
			{Text = "BETA", Color = Color3.fromRGB(255, 180, 0)}
		},
		Anonymous = false
	}
})

local Buttons = Window:Tab({Title = "Buttons", Icon = "mouse-pointer-click"})
Buttons:Section({Title = "Buttons"})
Buttons:Button({
	Title = "Normal Button",
	Desc = "Standard clickable button",
	Callback = function()
		Window:Notify({Title = "Clicked", Desc = "Normal button pressed", Time = 3})
	end
})
Buttons:Button({
	Title = "Locked Button",
	Desc = "This one is locked",
	Locked = true,
	LockText = "Premium"
})
Buttons:MultiButton({
	Title = "Multi Button",
	Buttons = {
		{Title = "Full Width", Callback = function() Window:Notify({Title = "Full", Desc = "Line 1", Time = 2}) end},
		{Title = "Left", Callback = function() Window:Notify({Title = "Left", Desc = "Half A", Time = 2}) end},
		{Title = "Right", Callback = function() Window:Notify({Title = "Right", Desc = "Half B", Time = 2}) end}
	}
})

local Toggles = Window:Tab({Title = "Toggles", Icon = "toggle-left"})
Toggles:Section({Title = "Toggles"})
Toggles:Toggle({
	Title = "Enable Feature",
	Desc = "Toggle with callback",
	Value = false,
	Flag = "feature1",
	Callback = function(v) print("Toggle:", v) end
})
Toggles:Toggle({
	Title = "Colored Toggle",
	Value = true,
	Color = Color3.fromRGB(0, 200, 100),
	Flag = "feature2"
})
Toggles:Toggle({
	Title = "Locked Toggle",
	Locked = true,
	LockText = "VIP Only"
})

local Sliders = Window:Tab({Title = "Sliders", Icon = "sliders"})
Sliders:Section({Title = "Sliders & Steppers"})
Sliders:Slider({
	Title = "Volume",
	Min = 0, Max = 100, Value = 50,
	Flag = "volume",
	Callback = function(v) print("Volume", v) end
})
Sliders:Slider({
	Title = "Locked Slider",
	Min = 0, Max = 10, Value = 5,
	Locked = true,
	LockText = "Locked"
})
Sliders:Stepper({
	Title = "Count",
	Min = 0, Max = 20, Value = 5,
	Flag = "count",
	Callback = function(v) print("Count", v) end
})
Sliders:RangeSlider({
	Title = "Range",
	Min = 0, Max = 100,
	Value = {20, 80},
	Callback = function(v) print(v[1], v[2]) end
})

local Inputs = Window:Tab({Title = "Inputs", Icon = "text"})
Inputs:Section({Title = "Text Inputs"})
Inputs:Textbox({
	Title = "Username",
	Placeholder = "Enter name...",
	Value = "",
	Flag = "username",
	Callback = function(t) print("Text:", t) end
})
Inputs:Paragraph({
	Title = "Info",
	Content = "This is a paragraph component for longer descriptive text."
})
Inputs:Label({Title = "Simple Label"})

local Dropdowns = Window:Tab({Title = "Dropdowns", Icon = "chevron-down"})
Dropdowns:Section({Title = "Dropdowns & Segmented"})
Dropdowns:Dropdown({
	Title = "Select Mode",
	List = {"Easy", "Normal", "Hard", "Nightmare"},
	Value = "Normal",
	Flag = "mode",
	Callback = function(v) print("Mode:", v) end
})
Dropdowns:Segmented({
	Title = "View",
	Options = {"List", "Grid", "Detail"},
	Value = "List",
	Callback = function(v) print("View:", v) end
})

local Keybinds = Window:Tab({Title = "Keybinds", Icon = "keyboard"})
Keybinds:Section({Title = "Keybinds"})
Keybinds:Keybind({
	Title = "Toggle Menu",
	Key = Enum.KeyCode.E,
	Flag = "menukey",
	Callback = function(key, state) print("Key", key, "State", state) end
})

local Colors = Window:Tab({Title = "Colors", Icon = "palette"})
Colors:Section({Title = "Color Picker"})
Colors:ColorPicker({
	Title = "Accent Color",
	Value = Color3.fromRGB(0, 122, 255),
	Flag = "accent",
	Callback = function(r, g, b) print(r, g, b) end
})

local CodeTab = Window:Tab({Title = "Code", Icon = "code"})
CodeTab:Section({Title = "Code Box"})
CodeTab:Code({
	Title = "example.lua",
	Code = 'print("Hello from NexxChasers")\\nlocal x = 10\\nprint(x * 2)'
})

local Settings = Window:Tab({Title = "Settings", Icon = "settings"})
Settings:Section({Title = "Config System"})
Settings:Button({
	Title = "Save Config",
	Callback = function()
		Window:SaveConfig("default")
		Window:Notify({Title = "Saved", Desc = "Config exported to clipboard", Time = 3})
	end
})
Settings:Button({
	Title = "Load Config",
	Callback = function()
		Window:LoadConfig("default")
		Window:Notify({Title = "Loaded", Desc = "Config applied", Time = 3})
	end
})
Settings:Button({
	Title = "Export JSON",
	Callback = function()
		Window:ExportConfig()
		Window:Notify({Title = "Exported", Desc = "JSON on clipboard", Time = 3})
	end
})
Settings:Button({
	Title = "Show Dialog",
	Callback = function()
		Window:Dialog({
			Title = "Are you sure you want to continue?",
			Buttons = {
				{Title = "Yes", Color = Color3.fromRGB(0, 180, 0), Callback = function()
					Window:Notify({Title = "Confirmed", Desc = "Action done", Time = 2})
				end},
				{Title = "No", Color = Color3.fromRGB(200, 50, 50)}
			}
		})
	end
})

Window:Notify({
	Title = "NexxChasers Loaded",
	Desc = "Press LeftControl to toggle UI",
	Time = 5
})
