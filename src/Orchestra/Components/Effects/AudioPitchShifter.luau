--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local bindLifetime = require("../../Instances/bindLifetime")
local Routing = require("../Routing")

-- Functions
local tAudioPitchShift = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreatePitchShift(parent: Instance, props: { [string]: any }?): AudioPitchShifter
	assert(tAudioPitchShift(parent, props))

	local audioPitchShift = Instance.new("AudioPitchShifter")
	audioPitchShift.Parent = parent

	-- Apply properties
	applyInstanceProps(audioPitchShift, props and props or {})

	-- Return our object
	return audioPitchShift
end

---------------------------------------------------------------------
local AudioPitchShifter = {}
AudioPitchShifter.__index = AudioPitchShifter

--[=[
	@class AudioPitchShifter
	@tag Effects

	Wraps an `AudioPitchShifter`, which changes the pitch of a sound without changing its speed.

	Create one with `Orchestra.Effects.new(Enums.Effect.PitchShifter, parent, props)`.
]=]

--[=[
	@prop Instance AudioPitchShifter
	@within AudioPitchShifter
	@readonly

	The wrapped `AudioPitchShifter` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioPitchShifter
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioPitchShifter
	@within AudioPitchShifter
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioPitchShifter
	@within AudioPitchShifter
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioPitchShifter under `parent`. Usually created through `Orchestra.Effects.new`.

	@param parent Instance -- Where the `AudioPitchShifter` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioPitchShifter
]=]
function AudioPitchShifter.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioPitchShift(parent, props))

	-- Create a new AudioPitchShift
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioPitchShifter"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioPitchShifter Instance
	self.Instance = CreatePitchShift(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioPitchShifter)
end

function AudioPitchShifter:__tostring()
	return "AudioPitchShifter"
end

--[=[
	Destroys the AudioPitchShifter: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioPitchShifter:Destroy()
	self._trove:Destroy()
end

return AudioPitchShifter
