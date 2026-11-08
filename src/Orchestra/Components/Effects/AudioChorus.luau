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
local tAudioChorus = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateChorus(parent: Instance, props: { [string]: any }?): AudioChorus
	assert(tAudioChorus(parent, props))

	local audioChorus = Instance.new("AudioChorus")
	audioChorus.Parent = parent

	-- Apply properties
	applyInstanceProps(audioChorus, props and props or {})

	-- Return our object
	return audioChorus
end

---------------------------------------------------------------------
local AudioChorus = {}
AudioChorus.__index = AudioChorus

--[=[
	@class AudioChorus
	@tag Effects

	Wraps an `AudioChorus`, which thickens a sound by layering slightly detuned, delayed copies of it.

	Create one with `Orchestra.Effects.new(Enums.Effect.Chorus, parent, props)`.
]=]

--[=[
	@prop Instance AudioChorus
	@within AudioChorus
	@readonly

	The wrapped `AudioChorus` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioChorus
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioChorus
	@within AudioChorus
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioChorus
	@within AudioChorus
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioChorus under `parent`. Usually created through `Orchestra.Effects.new`.

	@param parent Instance -- Where the `AudioChorus` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioChorus
]=]
function AudioChorus.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioChorus(parent, props))
	-- Create a new AudioChorus
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioChorus"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioChorus Instance
	self.Instance = CreateChorus(parent, props)

	-- Routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioChorus)
end

function AudioChorus:__tostring()
	return "AudioChorus"
end

--[=[
	Destroys the AudioChorus: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioChorus:Destroy()
	self._trove:Destroy()
end

return AudioChorus
