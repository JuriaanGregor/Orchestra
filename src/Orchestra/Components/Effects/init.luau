--!strict

-- Import
local Dependencies = require("../Dependencies")
local t = Dependencies.t

-- Types
local Types = require("../Types")

-- Enums
local Enums = require("../Enums")

-- Variables
local AUDIO_EFFECTS: { [string]: any } = {
	[Enums.Effect.Equalizer.Name] = require("@self/AudioEqualizer"),
	[Enums.Effect.Reverb.Name] = require("@self/AudioReverb"),
	[Enums.Effect.Compressor.Name] = require("@self/AudioCompressor"),
	[Enums.Effect.Chorus.Name] = require("@self/AudioChorus"),
	[Enums.Effect.Distortion.Name] = require("@self/AudioDistortion"),
	[Enums.Effect.Echo.Name] = require("@self/AudioEcho"),
	[Enums.Effect.Flanger.Name] = require("@self/AudioFlanger"),
	[Enums.Effect.PitchShifter.Name] = require("@self/AudioPitchShifter"),
	[Enums.Effect.Tremolo.Name] = require("@self/AudioTremolo"),
}

-- Functions
local tCreateEffect = t.tuple(Types.tAudioEffect, t.Instance, t.optional(t.map(t.string, t.any)))

local function CreateEffect(effectType: Enums.EnumItem, parent: Instance, props: { [string]: any }?)
	assert(tCreateEffect(effectType.Name, parent, props))

	if not AUDIO_EFFECTS[effectType.Name] then
		error("Invalid effect type")
	end

	return AUDIO_EFFECTS[effectType.Name].new(parent, props) :: Types.AUEffect
end

---------------------------------------------------------------------
local AudioEffect = {}
AudioEffect.__index = AudioEffect

local tAudioEffect = t.tuple(Types.tAudioEffect, t.Instance, t.optional(t.map(t.string, t.any)))
function AudioEffect.new(effectType: Enums.EnumItem, parent: Instance, props: { [string]: any }?): Types.AUEffect
	assert(tAudioEffect(effectType.Name, parent, props))

	local Effect = CreateEffect(effectType, parent, props)
	if not Effect then
		error("Was not able to create effect with type: " .. effectType.Name)
	end

	return Effect
end

return AudioEffect
