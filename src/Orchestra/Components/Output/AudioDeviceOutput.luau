--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Types
local Types = require("../../Types")

-- Import > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local bindLifetime = require("../../Instances/bindLifetime")
local Routing = require("../Routing")

-- Functions
local function CreateDeviceOutput(parent: Instance, props: { [string]: any }?): AudioDeviceOutput
	local deviceOutput = Instance.new("AudioDeviceOutput")
	deviceOutput.Parent = parent

	if props and props.Player then
		deviceOutput.Player = props.Player
		props.Player = nil
	end

	-- Apply properties
	applyInstanceProps(deviceOutput, typeof(props) == "table" and props or {})

	-- Return our object
	return deviceOutput
end

---------------------------------------------------------------------
local AudioDeviceOutput = {}
AudioDeviceOutput.__index = AudioDeviceOutput

--[=[
	@class AudioDeviceOutput
	@tag Output

	Wraps an `AudioDeviceOutput`, which plays audio on a player's speakers or headphones. The engine creates one, `MainOut`, in [Orchestra:Start].

	Create one with `Orchestra.Output.new(Enums.Output.Device, parent, props)`.
]=]

--[=[
	@prop Instance AudioDeviceOutput
	@within AudioDeviceOutput
	@readonly

	The wrapped `AudioDeviceOutput` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioDeviceOutput
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioDeviceOutput
	@within AudioDeviceOutput
	@readonly

	The instance to wire into (same as `Instance`).
]=]

local tAudioDeviceOutput = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
--[=[
	Creates a new AudioDeviceOutput under `parent`. Usually created through `Orchestra.Output.new`.

	@param parent Instance -- Where the `AudioDeviceOutput` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioDeviceOutput
]=]
function AudioDeviceOutput.new(parent: Instance, props: { [string]: any }?): Types.AUDeviceOutput
	assert(tAudioDeviceOutput(parent, props))

	-- Create a new AudioDeviceOutput
	local self = {}
	self.Type = "Output"
	self.ClassName = "AudioDeviceOutput"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioDeviceOutput Instance
	self.Instance = CreateDeviceOutput(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Expose our members
	self.In = self.Instance

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	return setmetatable(self :: any, AudioDeviceOutput) :: Types.AUDeviceOutput
end

function AudioDeviceOutput:__tostring()
	return "AudioDeviceOutput"
end

--[=[
	Destroys the AudioDeviceOutput: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioDeviceOutput:Destroy()
	self._trove:Destroy()
end

return AudioDeviceOutput
