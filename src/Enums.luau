--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local EnumList = require(Package.Packages.EnumList)

local Enums = table.freeze({
	Output = EnumList.new("Output", {
		"Device",
		"Emitter",
	}),
	Stream = EnumList.new("Stream", {
		"Player",
		"Input",
		"Listener",
		"TextToSpeech",
	}),
	Transform = EnumList.new("Transform", {
		"ChannelMixer",
		"ChannelSplitter",
	}),
	Pin = EnumList.new("Pin", {
		"Input",
		"Output",
		"Sidechain",
	}),
	Effect = EnumList.new("Effect", {
		"Chorus",
		"Compressor",
		"Distortion",
		"Echo",
		"Equalizer",
		"Flanger",
		"Gate",
		"PitchShift",
		"Reverb",
		"Tremolo",
	}),
})

export type EnumList = EnumList.EnumList
export type EnumItem = EnumList.EnumItem

return Enums
