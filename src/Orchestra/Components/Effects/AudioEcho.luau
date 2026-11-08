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
local tAudioEcho = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateEcho(parent: Instance, props: { [string]: any }?): AudioEcho
	assert(tAudioEcho(parent, props))

	local audioEcho = Instance.new("AudioEcho")
	audioEcho.Parent = parent

	-- Apply properties
	applyInstanceProps(audioEcho, props and props or {})

	-- Return our object
	return audioEcho
end

---------------------------------------------------------------------
local AudioEcho = {}
AudioEcho.__index = AudioEcho

--[=[
	@class AudioEcho
	@tag Effects

	Wraps an `AudioEcho`, which repeats a sound after a delay.

	Create one with `Orchestra.Effects.new(Enums.Effect.Echo, parent, props)`.
]=]

--[=[
	@prop Instance AudioEcho
	@within AudioEcho
	@readonly

	The wrapped `AudioEcho` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioEcho
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioEcho
	@within AudioEcho
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioEcho
	@within AudioEcho
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioEcho under `parent`. Usually created through `Orchestra.Effects.new`.

	@param parent Instance -- Where the `AudioEcho` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioEcho
]=]
function AudioEcho.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioEcho(parent, props))

	-- Create a new AudioEcho
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioEcho"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioEcho Instance
	self.Instance = CreateEcho(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioEcho)
end

function AudioEcho:__tostring()
	return "AudioEcho"
end

--[=[
	Destroys the AudioEcho: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioEcho:Destroy()
	self._trove:Destroy()
end

return AudioEcho
