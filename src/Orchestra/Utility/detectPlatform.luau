--!strict
--[[
	Best guess of the device class Orchestra runs on, for picking a platform preset.

	Roblox has no "device type" API, so this reads input and UI signals, in this order:
	- Console: GuiService:IsTenFootInterface(), a TV screen (a console or a Smart TV)
	- Mobile: a touch screen without a keyboard (tablets with a keyboard read as Desktop)
	- Desktop: everything else

	Runs once per session; a gamepad plugged into a PC doesn't make it a console.
]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

export type Platform = "Mobile" | "Desktop" | "Console"

local function detectPlatform(): Platform
	if GuiService:IsTenFootInterface() then
		return "Console"
	end

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Mobile"
	end

	return "Desktop"
end

return detectPlatform
