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
local tAudioChannelSplitter = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateChannelSplitter(parent: Instance, props: { [string]: any }?): AudioChannelSplitter
	assert(tAudioChannelSplitter(parent, props))

	local audioChannelSplitter = Instance.new("AudioChannelSplitter")
	audioChannelSplitter.Parent = parent

	-- Apply properties
	applyInstanceProps(audioChannelSplitter, props and props or {})

	-- Return our object
	return audioChannelSplitter
end

---------------------------------------------------------------------
local AudioChannelSplitter = {}
AudioChannelSplitter.__index = AudioChannelSplitter

--[=[
	@class AudioChannelSplitter
	@tag Transforms

	Wraps an `AudioChannelSplitter`, which splits a multichannel stream into one output pin per channel (`Left`, `Right`, `Center`, ...).

	Use [Routing:Wire] to wire a specific channel:

	```lua
	splitter.Routing:Wire(
		{ Instance = splitter.Instance, PinType = Enums.Pin.Output, Pin = "Left" },
		{ Instance = emitterL.Instance, PinType = Enums.Pin.Input }
	)
	```

	Create one with `Orchestra.Transforms.new(Enums.Transform.ChannelSplitter, parent, props)`.
]=]

--[=[
	@prop Instance AudioChannelSplitter
	@within AudioChannelSplitter
	@readonly

	The wrapped `AudioChannelSplitter` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioChannelSplitter
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioChannelSplitter
	@within AudioChannelSplitter
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioChannelSplitter
	@within AudioChannelSplitter
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioChannelSplitter under `parent`. Usually created through `Orchestra.Transforms.new`.

	@param parent Instance -- Where the `AudioChannelSplitter` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioChannelSplitter
]=]
function AudioChannelSplitter.new(parent: Instance, props: { [string]: any }?): Types.AUChannelSplitter
	assert(tAudioChannelSplitter(parent, props))

	-- Create a new AudioChannelSplitter
	local self = {}
	self.Type = "Transform"
	self.ClassName = "AudioChannelSplitter"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioChannelSplitter Instance
	self.Instance = CreateChannelSplitter(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioChannelSplitter) :: Types.AUChannelSplitter
end

function AudioChannelSplitter:__tostring()
	return "AudioChannelSplitter"
end

--[=[
	Destroys the AudioChannelSplitter: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioChannelSplitter:Destroy()
	self._trove:Destroy()
end

return AudioChannelSplitter
