--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Orchestra")
local Enums = require(Package.Packages.EnumList)

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
		"Gate",
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
} :: { [string]: Enums.EnumList }

return table.freeze(AudioEnums)
