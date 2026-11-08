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
local tAudioDistortion = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateDistortion(parent: Instance, props: { [string]: any }?): AudioDistortion
	assert(tAudioDistortion(parent, props))

	local audioDistortion = Instance.new("AudioDistortion")
	audioDistortion.Parent = parent

	-- Apply properties
	applyInstanceProps(audioDistortion, props and props or {})

	-- Return our object
	return audioDistortion
end

---------------------------------------------------------------------
local AudioDistortion = {}
AudioDistortion.__index = AudioDistortion

--[=[
	@class AudioDistortion
	@tag Effects

	Wraps an `AudioDistortion`, which overdrives a sound.

	Create one with `Orchestra.Effects.new(Enums.Effect.Distortion, parent, props)`.
]=]

--[=[
	@prop Instance AudioDistortion
	@within AudioDistortion
	@readonly

	The wrapped `AudioDistortion` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioDistortion
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioDistortion
	@within AudioDistortion
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioDistortion
	@within AudioDistortion
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioDistortion under `parent`. Usually created through `Orchestra.Effects.new`.

	@param parent Instance -- Where the `AudioDistortion` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioDistortion
]=]
function AudioDistortion.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioDistortion(parent, props))

	-- Create a new AudioDistortion
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioDistortion"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioDistortion Instance
	self.Instance = CreateDistortion(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioDistortion)
end

function AudioDistortion:__tostring()
	return "AudioDistortion"
end

--[=[
	Destroys the AudioDistortion: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioDistortion:Destroy()
	self._trove:Destroy()
end

return AudioDistortion
