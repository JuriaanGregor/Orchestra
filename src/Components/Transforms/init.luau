--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)

-- Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

-- Variables
local AUDIO_TRANSFORMS: { [string]: any } = {
	[Enums.Transform.ChannelMixer.Name] = require(script.AudioChannelMixer),
	[Enums.Transform.ChannelSplitter.Name] = require(script.AudioChannelSplitter),
	[Enums.Transform.Limiter.Name] = require(script.AudioLimiter),
	[Enums.Transform.Gate.Name] = require(script.AudioGate),
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
