--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Import > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)

-- Types
local Types = require(Package.Types)

-- Functions
local tAudioDeviceOutput = t.tuple(t.Instance, t.optional(t.instanceIsA("Player")), t.optional(t.map(t.string, t.any)))
local function CreateDeviceOutput(parent: Instance, listener: Player?, props: { [string]: any }?): AudioDeviceOutput
	assert(tAudioDeviceOutput(parent, listener))
	local deviceOutput = Instance.new("AudioDeviceOutput")
	deviceOutput.Parent = parent

	if listener then
		deviceOutput.Player = listener
	end

	if not props then
		return deviceOutput
	end

	-- Apply properties
	applyInstanceProps(deviceOutput, props)

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

--[=[
	Creates a new AudioDeviceOutput.
]=]

function AudioDeviceOutput.new(parent: Instance, listener: Player?, props: { [string]: any }?): Types.AUDeviceOutput
	assert(tAudioDeviceOutput(parent, listener))

	-- Create a new AudioDeviceOutput
	local self = {}
	self.ClassName = "AudioDeviceOutput"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioDeviceOutput Instance
	self.Instance = CreateDeviceOutput(parent, listener, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance

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
