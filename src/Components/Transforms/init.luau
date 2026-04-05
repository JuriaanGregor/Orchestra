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
}

-- Functions
local tCreateTransform = t.tuple(t.table, t.Enum, t.Instance, t.optional(t.map(t.string, t.any)))
function CreateTransform(
	transformType: Enums.EnumItem,
	layoutMode: Enum.AudioChannelLayout,
	parent: Instance,
	props: { [string]: any }?
)
	assert(tCreateTransform(transformType, layoutMode, parent, props))

	if not AUDIO_TRANSFORMS[transformType.Name] then
		error("Invalid transform type")
	end

	return AUDIO_TRANSFORMS[transformType.Name].new(layoutMode, parent, props)
end

---------------------------------------------------------------------
local AudioTransforms = {}
AudioTransforms.__index = AudioTransforms

function AudioTransforms.new(
	transformType: Enums.EnumItem,
	layoutMode: Enum.AudioChannelLayout,
	parent: Instance,
	props: { [string]: any }?
): Types.AUTransform
	assert(tCreateTransform(transformType, layoutMode, parent, props))

	return CreateTransform(transformType, layoutMode, parent, props)
end

return AudioTransforms
