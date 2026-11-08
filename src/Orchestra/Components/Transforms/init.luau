--!strict

-- Import > Packages
local Dependencies = require("../Dependencies")
local t = Dependencies.t

-- Types
local Types = require("../Types")

-- Enums
local Enums = require("../Enums")

-- Variables
local AUDIO_TRANSFORMS: { [string]: any } = {
	[Enums.Transform.ChannelMixer.Name] = require("@self/AudioChannelMixer"),
	[Enums.Transform.ChannelSplitter.Name] = require("@self/AudioChannelSplitter"),
	[Enums.Transform.Limiter.Name] = require("@self/AudioLimiter"),
	[Enums.Transform.Gate.Name] = require("@self/AudioGate"),
}

-- Functions
local tCreateTransform = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))
function CreateTransform(transformType: Enums.EnumItem, parent: Instance, props: { [string]: any }?)
	assert(tCreateTransform(transformType.Name, parent, props))

	if not AUDIO_TRANSFORMS[transformType.Name] then
		error("Invalid transform type")
	end

	return AUDIO_TRANSFORMS[transformType.Name].new(parent, props)
end

---------------------------------------------------------------------
local AudioTransforms = {}
AudioTransforms.__index = AudioTransforms

function AudioTransforms.new(
	transformType: Enums.EnumItem,
	parent: Instance,
	props: { [string]: any }?
): Types.AUTransform
	assert(tCreateTransform(transformType.Name, parent, props))

	return CreateTransform(transformType, parent, props)
end

return AudioTransforms
