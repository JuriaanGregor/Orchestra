--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Types
local Types = require(Package.Types)

-- Import > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)
local Routing = require(Package.Components.Routing)

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

	Represents an audio device output. This is used to output audio to a specific output device.
]=]

local tAudioDeviceOutput = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
--[=[
	Creates a new AudioDeviceOutput.
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

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioDeviceOutput) :: Types.AUDeviceOutput
end

function AudioDeviceOutput:__tostring()
	return "AudioDeviceOutput"
end

--[=[
	Destroys the AudioDeviceOutput.
]=]
function AudioDeviceOutput:Destroy()
	self._trove:Destroy()
end

return AudioDeviceOutput
