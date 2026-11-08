--!strict

-- Import > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Import > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local bindLifetime = require("../../Instances/bindLifetime")
local Routing = require("../Routing")

-- Types
local Types = require("../../Types")

-- Functions
local function CreateListener(parent: Instance, props: { [string]: any }?): AudioListener
	local listener = Instance.new("AudioListener")
	listener.Parent = parent

	-- Apply properties
	applyInstanceProps(listener, typeof(props) == "table" and props or {})

	-- Return our object
	return listener
end

---------------------------------------------------------------------
--[=[
	@class AudioListener
	@tag Stream

	Wraps an `AudioListener`, which picks up emitters in 3D from its parent. The engine creates one per mix bus on the camera.

	Create one with `Orchestra.Stream.new(Enums.Stream.Listener, parent, props)`.
]=]

--[=[
	@prop Instance AudioListener
	@within AudioListener
	@readonly

	The wrapped `AudioListener` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioListener
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop Out AudioListener
	@within AudioListener
	@readonly

	The instance to wire from (same as `Instance`).
]=]

local AudioListener = {}
AudioListener.__index = AudioListener

local tAudioListener = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	Creates a new AudioListener under `parent`. Usually created through `Orchestra.Stream.new`.

	@param parent Instance -- Where the `AudioListener` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioListener
]=]
function AudioListener.new(parent: Instance, props: { [string]: any }?): Types.AUListener
	assert(tAudioListener(parent, props))

	local self = {}
	self.Type = "Stream"
	self.ClassName = "AudioListener"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioListener Instance
	self.Instance = CreateListener(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Expose our members
	self.Out = self.Instance

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	return setmetatable(self :: any, AudioListener) :: Types.AUListener
end

function AudioListener:__tostring()
	return "AudioListener"
end

--[=[
	Destroys the AudioListener: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioListener:Destroy()
	self._trove:Destroy()
end

return AudioListener
