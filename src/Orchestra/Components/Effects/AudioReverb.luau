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
local tAudioReverb = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateReverb(parent: Instance, props: { [string]: any }?): AudioReverb
	assert(tAudioReverb(parent, props))

	local audioReverb = Instance.new("AudioReverb")
	audioReverb.Parent = parent

	-- Apply properties
	applyInstanceProps(audioReverb, props and props or {})

	-- Return our object
	return audioReverb
end

---------------------------------------------------------------------
local AudioReverb = {}
AudioReverb.__index = AudioReverb

--[=[
	@class AudioReverb
	@tag Effects

	Wraps an `AudioReverb`, which simulates the reflections of a room or space.

	Create one with `Orchestra.Effects.new(Enums.Effect.Reverb, parent, props)`.
]=]

--[=[
	@prop Instance AudioReverb
	@within AudioReverb
	@readonly

	The wrapped `AudioReverb` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioReverb
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioReverb
	@within AudioReverb
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioReverb
	@within AudioReverb
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioReverb under `parent`. Usually created through `Orchestra.Effects.new`.

	@param parent Instance -- Where the `AudioReverb` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioReverb
]=]
function AudioReverb.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioReverb(parent, props))

	-- Create a new AudioReverb
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioReverb"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioReverb Instance
	self.Instance = CreateReverb(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioReverb)
end

function AudioReverb:__tostring()
	return "AudioReverb"
end

--[=[
	Destroys the AudioReverb: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioReverb:Destroy()
	self._trove:Destroy()
end

return AudioReverb
