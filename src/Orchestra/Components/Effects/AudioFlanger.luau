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
local tAudioFlanger = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateFlanger(parent: Instance, props: { [string]: any }?): AudioFlanger
	assert(tAudioFlanger(parent, props))

	local audioFlanger = Instance.new("AudioFlanger")
	audioFlanger.Parent = parent

	-- Apply properties
	applyInstanceProps(audioFlanger, props and props or {})

	-- Return our object
	return audioFlanger
end

---------------------------------------------------------------------
local AudioFlanger = {}
AudioFlanger.__index = AudioFlanger

--[=[
	@class AudioFlanger
	@tag Effects

	Wraps an `AudioFlanger`, which mixes a sound with a short, modulated delay of itself.

	Create one with `Orchestra.Effects.new(Enums.Effect.Flanger, parent, props)`.
]=]

--[=[
	@prop Instance AudioFlanger
	@within AudioFlanger
	@readonly

	The wrapped `AudioFlanger` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioFlanger
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioFlanger
	@within AudioFlanger
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioFlanger
	@within AudioFlanger
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioFlanger under `parent`. Usually created through `Orchestra.Effects.new`.

	@param parent Instance -- Where the `AudioFlanger` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioFlanger
]=]
function AudioFlanger.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioFlanger(parent, props))

	-- Create a new AudioFlanger
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioFlanger"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioFlanger Instance
	self.Instance = CreateFlanger(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioFlanger)
end

function AudioFlanger:__tostring()
	return "AudioFlanger"
end

--[=[
	Destroys the AudioFlanger: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioFlanger:Destroy()
	self._trove:Destroy()
end

return AudioFlanger
