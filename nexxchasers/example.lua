local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nail120212/NexLib/refs/heads/main/nexxchasers/loader.lua"))()

local Window = Library:Window({
	Title = "NexxChasers",
	Author = "UI Library",
	Theme = "Dark",
	Logo = "house",
	Color = Color3.fromRGB(0,122,255),
	Config = {
		ToggleKeybind = Enum.KeyCode.LeftControl,
		Size = UDim2.new(0,520,0,400),
		AutoScale = true,
		Transparency = 0.05,
		Tags = {{Text="BETA",Color=Color3.fromRGB(255,180,0)}},
		Anonymous = false
	}
})

local Buttons = Window:Tab({Title="Buttons",Icon="mouse-pointer-click"})
local Sec1 = Buttons:Section({Title="Buttons",Opened=true})
Sec1:Button({
	Title="Normal Button",
	Desc="Click me",
	Callback=function()
		Window:Notify({Title="Clicked",Desc="Button works",Delay=2})
	end
})
Sec1:Button({
	Title="Locked Button",
	Locked=true,
	LockText="Premium"
})
Sec1:MultiButton({
	Title="Multi Button",
	Buttons={
		{Title="Full",Callback=function() print("full") end},
		{Title="A",Callback=function() print("A") end},
		{Title="B",Callback=function() print("B") end}
	}
})
local SecClosed = Buttons:Section({Title="Closed Section",Opened=false})
SecClosed:Button({Title="Hidden until open"})

local Toggles = Window:Tab({Title="Toggles",Icon="toggle-left"})
local TSec = Toggles:Section({Title="Toggles",Opened=true})
TSec:Toggle({
	Title="Enable Feature",
	Desc="Test toggle",
	Value=false,
	Flag="enable",
	Callback=function(v) print(v) end
})
TSec:Toggle({
	Title="Colored",
	Value=true,
	Color=Color3.fromRGB(0,200,100),
	Flag="colored"
})
TSec:Toggle({
	Title="Locked Toggle",
	Locked=true,
	LockText="VIP"
})

local Sliders = Window:Tab({Title="Sliders",Icon="sliders"})
local SSec = Sliders:Section({Title="Sliders",Opened=true})

SSec:Slider({
	Title="Volume",
	Min=0,Max=100,Value=50,
	Flag="vol",
	Callback=function(v) print(v) end
})
SSec:Slider({
	Title="Locked Slider",
	Min=0,Max=10,Value=5,
	Locked=true,
	LockText="Locked"
})
SSec:Stepper({
	Title="Count",
	Min=0,Max=20,Value=3,
	Flag="cnt"
})
SSec:RangeSlider({
	Title="Range",
	Min=0,Max=100,
	Value={20,80}
})

local Inputs = Window:Tab({Title="Inputs",Icon="text"})
local ISec = Inputs:Section({Title="Inputs",Opened=true})
ISec:Textbox({
	Title="Username",
	Placeholder="Type...",
	Flag="user"
})
ISec:Dropdown({
	Title="Mode",
	List={"Easy","Normal","Hard"},
	Value="Normal",
	Flag="mode"
})
ISec:Segmented({
	Title="View",
	Options={"List","Grid","Detail"},
	Value="List"
})
ISec:Paragraph({
	Title="Info",
	Content="Paragraph text component"
})
ISec:Label({Title="Simple Label"})

local More = Window:Tab({Title="More",Icon="settings"})
local MSec = More:Section({Title="Keybind & Color",Opened=true})
MSec:Keybind({
	Title="Action Key",
	Key=Enum.KeyCode.E,
	Flag="key"
})
MSec:ColorPicker({
	Title="Accent",
	Value=Color3.fromRGB(0,122,255),
	Flag="accent"
})
MSec:Code({
	Title="Script",
	Code='print("NexxChasers")'
})
local CSec = More:Section({Title="Config",Opened=true})
CSec:Button({
	Title="Save Config",
	Callback=function()
		Window:SaveConfig("default")
		Window:Notify({Title="Saved",Desc="Config exported",Delay=2})
	end
})
CSec:Button({
	Title="Load Config",
	Callback=function()
		Window:LoadConfig("default")
		Window:Notify({Title="Loaded",Desc="Config applied",Delay=2})
	end
})
CSec:Button({
	Title="Dialog",
	Callback=function()
		Window:Dialog({
			Title="Continue?",
			Buttons={
				{Title="Yes",Color=Color3.fromRGB(0,180,0),Callback=function()
					Window:Notify({Title="Yes",Desc="Confirmed",Delay=2})
				end},
				{Title="No",Color=Color3.fromRGB(200,50,50)}
			}
		})
	end
})

Window:Notify({
	Title="NexxChasers",
	Desc="Loaded - LeftControl to toggle",
	Delay=4
})
