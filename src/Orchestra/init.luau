--!strict
--!nolint LocalUnused
--!nolint LocalShadow

--[[
	The entry point for the Audio SDK
]]

local Package = script
local Types = require(Package.Types)

type Orchestra = Types.Orchesta

local Orchestra: Orchestra = table.freeze({
	Version = {
		major = 0,
		minor = 1,
		isRelease = false,
	},
	Components = {
		Wire = require(script.Components.Wire),
	},
	New = require(Package.Instances.New)
})

return Orchestra
