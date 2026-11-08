--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Types
local Types = require("../../Types")

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local bindLifetime = require("../../Instances/bindLifetime")
local Routing = require("../Routing")

-- Functions
local tAudioChannelMixer = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateAudioMixer(parent: Instance, props: { [string]: any }?): AudioChannelMixer
	assert(tAudioChannelMixer(parent, props))

	local audioChannelMixer = Instance.new("AudioChannelMixer")
	audioChannelMixer.Parent = parent

	-- Apply properties
	applyInstanceProps(audioChannelMixer, props and props or {})

	-- Return our object
	return audioChannelMixer
end

---------------------------------------------------------------------
local AudioChannelMixer = {}
AudioChannelMixer.__index = AudioChannelMixer

--[=[
	@class AudioChannelMixer
	@tag Transforms

	Wraps an `AudioChannelMixer`, which combines individual channels (`Left`, `Right`, `Center`, ...) into one multichannel stream.

	Create one with `Orchestra.Transforms.new(Enums.Transform.ChannelMixer, parent, props)`.
]=]

--[=[
	@prop Instance AudioChannelMixer
	@within AudioChannelMixer
	@readonly

	The wrapped `AudioChannelMixer` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioChannelMixer
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioChannelMixer
	@within AudioChannelMixer
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioChannelMixer
	@within AudioChannelMixer
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioChannelMixer under `parent`. Usually created through `Orchestra.Transforms.new`.

	@param parent Instance -- Where the `AudioChannelMixer` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioChannelMixer
]=]
function AudioChannelMixer.new(parent: Instance, props: { [string]: any }?): Types.AUChannelMixer
	assert(tAudioChannelMixer(parent, props))

	-- Create a new AudioChannelMixer
	local self = {}
	self.Type = "Transform"
	self.ClassName = "AudioChannelMixer"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioChannelMixer Instance
	self.Instance = CreateAudioMixer(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioChannelMixer) :: Types.AUChannelMixer
end

function AudioChannelMixer:__tostring()
	return "AudioChannelMixer"
end

--[=[
	Destroys the AudioChannelMixer: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioChannelMixer:Destroy()
	self._trove:Destroy()
end

return AudioChannelMixer
