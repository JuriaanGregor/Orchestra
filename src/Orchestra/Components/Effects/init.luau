--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)

-- Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

-- Variables
local AUDIO_EFFECTS: { [string]: any } = {
	[Enums.Effect.Equalizer.Name] = require(script.AudioEqualizer),
	[Enums.Effect.Reverb.Name] = require(script.AudioReverb),
	[Enums.Effect.Compressor.Name] = require(script.AudioCompressor),
	[Enums.Effect.Chorus.Name] = require(script.AudioChorus),
	[Enums.Effect.Distortion.Name] = require(script.AudioDistortion),
	[Enums.Effect.Echo.Name] = require(script.AudioEcho),
	[Enums.Effect.Flanger.Name] = require(script.AudioFlanger),
	[Enums.Effect.PitchShifter.Name] = require(script.AudioPitchShifter),
	[Enums.Effect.Tremolo.Name] = require(script.AudioTremolo),
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
