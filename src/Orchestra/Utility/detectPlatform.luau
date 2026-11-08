--!strict
--[[
	Best guess of the device class Orchestra runs on, for picking a platform preset.

	Roblox has no "device type" API, so this reads input and UI signals, in this order:
	- Console: GuiService:IsTenFootInterface(), a TV screen (a console or a Smart TV)
	- Mobile: UserInputService.PreferredInput is Touch (phones and tablets, with or without a keyboard attached)
	- Desktop: everything else

	PreferredInput is the input Roblox expects the player to use. Unlike KeyboardEnabled, it doesn't flip to keyboard
	when one is attached: in Studio's phone emulator, KeyboardEnabled turns true shortly after the game starts. On
	engines without PreferredInput, Mobile falls back to a touch screen without a keyboard.

	Runs once per session; a gamepad plugged into a PC doesn't make it a console.
]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

export type Platform = "Mobile" | "Desktop" | "Console"

-- PreferredInput, or nil on engines that don't have it yet
local function preferredInput(): EnumItem?
	local ok, value = pcall(function()
		return (UserInputService :: any).PreferredInput
	end)

	return if ok and typeof(value) == "EnumItem" then value else nil
end

local function detectPlatform(): Platform
	if GuiService:IsTenFootInterface() then
		return "Console"
	end

	local preferred = preferredInput()
	if preferred then
		return if preferred.Name == "Touch" then "Mobile" else "Desktop"
	end

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Mobile"
	end

	return "Desktop"
end

return detectPlatform
