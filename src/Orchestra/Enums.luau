--!strict
-- Import > Packages
local Dependencies = require("./Dependencies")
local Enums = Dependencies.EnumList

export type EnumList = Dependencies.EnumList
export type EnumItem = Dependencies.EnumItem

local AudioEnums = {
	Output = Enums.new("Output", {
		"Device",
		"Emitter",
	}),
	Stream = Enums.new("Stream", {
		"Player",
		"Input",
		"Listener",
		"TextToSpeech",
	}),
	Transform = Enums.new("Transform", {
		"ChannelMixer",
		"ChannelSplitter",
		"Limiter",
		"Gate",
	}),
	Pin = Enums.new("Pin", {
		"Input",
		"Output",
		"Sidechain",
	}),
	Effect = Enums.new("Effect", {
		"Chorus",
		"Compressor",
		"Distortion",
		"Echo",
		"Equalizer",
		"Flanger",
		"PitchShifter",
		"Reverb",
		"Tremolo",
	}),
	Analyzer = Enums.new("Analyzer", {
		"Spectrum",
	}),
	AudioMembers = Enums.new("AudioMembers", {
		"AudioPlayer",
		"AudioDeviceInput",
		"AudioListener",
		"AudioTextToSpeech",
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
		"AudioChannelSplitter",
		"AudioChannelMixer",
		"AudioLimiter",
	}),
} :: { [string]: EnumList }

return table.freeze(AudioEnums)
