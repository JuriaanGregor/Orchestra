--!strict
local Dependencies = require("./Dependencies")
local Enums = Dependencies.EnumList

--[=[
	@class Config
	@tag Engine

	Engine configuration.
]=]

--[=[
	@prop MIX_BUSES EnumList
	@within Config
	@readonly

	The mix buses [Orchestra:Start] creates: `SFX`, `UI`, `Voice`, `Dialogue`, `Music`, `Environment`.
]=]
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
