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
local tAudioTremolo = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateTremolo(parent: Instance, props: { [string]: any }?): AudioTremolo
	assert(tAudioTremolo(parent, props))

	local audioTremolo = Instance.new("AudioTremolo")
	audioTremolo.Parent = parent

	-- Apply properties
	applyInstanceProps(audioTremolo, props and props or {})

	-- Return our object
	return audioTremolo
end

---------------------------------------------------------------------
local AudioTremolo = {}
AudioTremolo.__index = AudioTremolo

--[=[
	@class AudioTremolo
	@tag Effects

	Wraps an `AudioTremolo`, which modulates the volume of a sound.

	Create one with `Orchestra.Effects.new(Enums.Effect.Tremolo, parent, props)`.
]=]

--[=[
	@prop Instance AudioTremolo
	@within AudioTremolo
	@readonly

	The wrapped `AudioTremolo` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioTremolo
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioTremolo
	@within AudioTremolo
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioTremolo
	@within AudioTremolo
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioTremolo under `parent`. Usually created through `Orchestra.Effects.new`.

	@param parent Instance -- Where the `AudioTremolo` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioTremolo
]=]
function AudioTremolo.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioTremolo(parent, props))

	-- Create a new AudioTremolo
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioTremolo"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioTremolo Instance
	self.Instance = CreateTremolo(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioTremolo)
end

function AudioTremolo:__tostring()
	return "AudioTremolo"
end

--[=[
	Destroys the AudioTremolo: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioTremolo:Destroy()
	self._trove:Destroy()
end

return AudioTremolo
