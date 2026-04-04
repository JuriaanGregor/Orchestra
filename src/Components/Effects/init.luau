--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

local Routing = require(Package.Components.Routing)

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
	[Enums.Effect.PitchShift.Name] = require(script.AudioPitchShift),
	[Enums.Effect.Tremolo.Name] = require(script.AudioTremolo),
	[Enums.Effect.Gate.Name] = require(script.AudioGate),
}

-- Functions
local tCreateEffect = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))

local function CreateEffect(effectType: string, parent: Instance, props: { [string]: any }?)
	assert(tCreateEffect(effectType, parent, props))

	-- Create the effect based on the effectType
	local AudioEffect = AUDIO_EFFECTS[effectType]

	return AudioEffect.new(parent, props) :: Types.AUEffect
end

---------------------------------------------------------------------

local AudioEffect = {}
AudioEffect.__index = AudioEffect

--[=[
	@class AudioEffect
	@tag Effects

	Represents an audio effect. This can be an equalizer or other audio effect.
]=]

local tAudioEffect = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))
--[=[
	Creates a new AudioEffect. This can be an equalizer or other audio effect.

	@param effectType string -- The type of the effect. This can be "Equalizer" or other audio effects.
	@param parent Instance -- The parent of the effect.
	@param props {[string]: any}? -- A table of properties to set on the effect.
	@return Types.AudioEffect -- The new AudioEffect.
]=]
function AudioEffect.new(effectType: string, parent: Instance, props: { [string]: any }?): Types.AUEffect
	assert(tAudioEffect(effectType, parent, props))

	-- Create a new AudioEffect
	local self = {}
	self.ClassName = "AudioEffect"
	self._trove = Trove.new()

	local Effect = CreateEffect(effectType, parent, props)
	if not Effect then
		error("Invalid effectType")
	end

	self.Routing = Routing.new(Effect.Instance :: Instance, { Enums.Pin.Input, Enums.Pin.Output, Enums.Pin.Sidechain })
	self.EffectType = effectType
	self.Instance = Effect.Instance

	self.In = self.Instance
	self.Out = self.Instance

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioEffect)
end

function AudioEffect:__tostring()
	return string.format("AudioEffect<%s>", self.Instance.Name)
end

--[=[
	@within AudioEffect

	Disables the AudioEffect.
]=]
function AudioEffect:Disable()
	if not self.Instance.Bypass then
		self.Instance.Bypass = true
	end
end

--[=[
	@within AudioEffect

	Enables the AudioEffect.
]=]

function AudioEffect:Enable()
	if self.Instance.Bypass then
		self.Instance.Bypass = false
	end
end

--[=[
	@within AudioEffect

	Destroys the AudioEffect.
]=]
function AudioEffect:Destroy()
	self._trove:Destroy()
end

return AudioEffect
