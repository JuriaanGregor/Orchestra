--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Enums
local Enums = require("../../Enums")

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local bindLifetime = require("../../Instances/bindLifetime")
local Routing = require("../Routing")

-- Functions
local tAudioCompressor = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateCompressor(parent: Instance, props: { [string]: any }?): AudioCompressor
	assert(tAudioCompressor(parent, props))

	local audioCompressor = Instance.new("AudioCompressor")
	audioCompressor.Parent = parent

	-- Apply properties
	applyInstanceProps(audioCompressor, props and props or {})

	return audioCompressor
end

---------------------------------------------------------------------
local AudioCompressor = {}
AudioCompressor.__index = AudioCompressor

--[=[
	@class AudioCompressor
	@tag Effects

	Wraps an `AudioCompressor`, which reduces the dynamic range of a sound.

	Besides `Input`, it has a `Sidechain` input pin, so another source can drive the compression:

	```lua
	kick.Routing:WireTo(compressor.In, "Sidechain")
	```

	Create one with `Orchestra.Effects.new(Enums.Effect.Compressor, parent, props)`.
]=]

--[=[
	@prop Instance AudioCompressor
	@within AudioCompressor
	@readonly

	The wrapped `AudioCompressor` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioCompressor
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioCompressor
	@within AudioCompressor
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioCompressor
	@within AudioCompressor
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioCompressor under `parent`. Usually created through `Orchestra.Effects.new`.

	@param parent Instance -- Where the `AudioCompressor` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioCompressor
]=]
function AudioCompressor.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioCompressor(parent, props))

	-- Create a new AudioCompressor
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioCompressor"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioCompressor Instance
	self.Instance = CreateCompressor(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance, { Enums.Pin.Input, Enums.Pin.Output, Enums.Pin.Sidechain })

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioCompressor)
end

function AudioCompressor:__tostring()
	return "AudioCompressor"
end

--[=[
	Destroys the AudioCompressor: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioCompressor:Destroy()
	self._trove:Destroy()
end

return AudioCompressor
