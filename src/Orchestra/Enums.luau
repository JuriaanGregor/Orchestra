--!strict
-- Import > Packages
local Dependencies = require("./Dependencies")
local Enums = Dependencies.EnumList

export type EnumList = Dependencies.EnumList
export type EnumItem = Dependencies.EnumItem

--[=[
	@class Enums
	@tag Engine

	EnumLists used to pick component types, reached through `Orchestra.Enums`.

	```lua
	local Enums = Orchestra.Enums
	Orchestra.Effects.new(Enums.Effect.Reverb, speaker)
	```
]=]

--[=[
	@prop Stream EnumList
	@within Enums
	@readonly

	`Player`, `Input`, `Listener`, `TextToSpeech`. Used by [Stream] and [Layer].
]=]

--[=[
	@prop Output EnumList
	@within Enums
	@readonly

	`Device`, `Emitter`. Used by [Output].
]=]

--[=[
	@prop Effect EnumList
	@within Enums
	@readonly

	`Chorus`, `Compressor`, `Distortion`, `Echo`, `Equalizer`, `Flanger`, `PitchShifter`, `Reverb`, `Tremolo`. Used by [Effects].
]=]

--[=[
	@prop Transform EnumList
	@within Enums
	@readonly

	`ChannelMixer`, `ChannelSplitter`, `Limiter`, `Gate`. Used by [Transforms].
]=]

--[=[
	@prop Analyzer EnumList
	@within Enums
	@readonly

	`Spectrum`. Used by [Analyzers].
]=]

--[=[
	@prop Pin EnumList
	@within Enums
	@readonly

	`Input`, `Output`, `Sidechain`. Pin types for [Routing:Wire].
]=]

--[=[
	@prop AudioMembers EnumList
	@within Enums
	@readonly

	Class names of every audio instance Orchestra can wire.
]=]
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
