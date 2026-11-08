--!strict
local Dependencies = require("./Dependencies")
local Enums = Dependencies.EnumList

local MIX_BUSES = Enums.new("MixBuses", {
	"SFX",
	"UI",
	"Voice",
	"Dialogue",
	"Music",
	"Environment",
})

return table.freeze({
	MIX_BUSES = MIX_BUSES,
})
