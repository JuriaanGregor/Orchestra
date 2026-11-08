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
local tAudioGate = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateGate(parent: Instance, props: { [string]: any }?): AudioGate
	assert(tAudioGate(parent, props))

	local audioGate = Instance.new("AudioGate")
	audioGate.Parent = parent

	-- Apply properties
	applyInstanceProps(audioGate, props and props or {})

	-- Return our object
	return audioGate
end

---------------------------------------------------------------------
local AudioGate = {}
AudioGate.__index = AudioGate

--[=[
	@class AudioGate
	@tag Transforms

	Wraps an `AudioGate`, which silences the signal while it is below a threshold.

	Create one with `Orchestra.Transforms.new(Enums.Transform.Gate, parent, props)`.
]=]

--[=[
	@prop Instance AudioGate
	@within AudioGate
	@readonly

	The wrapped `AudioGate` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioGate
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioGate
	@within AudioGate
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioGate
	@within AudioGate
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioGate under `parent`. Usually created through `Orchestra.Transforms.new`.

	@param parent Instance -- Where the `AudioGate` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioGate
]=]
function AudioGate.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioGate(parent, props))

	-- Create a new AudioGate
	local self = {}
	self.Type = "Transform"
	self.ClassName = "AudioGate"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioGate Instance
	self.Instance = CreateGate(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioGate)
end

function AudioGate:__tostring()
	return "AudioGate"
end

--[=[
	Destroys the AudioGate: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioGate:Destroy()
	self._trove:Destroy()
end

return AudioGate
