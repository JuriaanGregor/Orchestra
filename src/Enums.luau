--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local EnumList = require(Package.Packages.EnumList)

export type EnumList = EnumList.EnumList
export type EnumItem = EnumList.EnumItem

local Enums = {
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
		"PitchShifter",
		"Reverb",
		"Tremolo",
	}),
	Analyzer = EnumList.new("Analyzer", {
		"Spectrum",
	}),
	AudioMembers = EnumList.new("AudioMembers", {
		"AudioPlayer",
		"AudioDeviceInput",
		"AudioListener",
		"AudioDeviceOutput",
		"AudioEmitter",
		"AudioFader",
		"AudioAnalyzer",
		"AudioChorus",
		"AudioCompressor",
		"AudioDistortion",
		"AudioEcho",
		"AudioEqualizer",
		"AudioFlanger",
		"AudioGate",
		"AudioPitchShifter",
		"AudioReverb",
		"AudioTremolo",
	}),
} :: { [string]: EnumList }

return table.freeze(Enums)
