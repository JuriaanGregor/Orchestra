--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

-- Variables
local AUDIO_OUTPUTS: { [Types.AudioOutputType]: any } = {
	[Enums.Output.Device.Name] = require(script.AudioDeviceOutput),
	[Enums.Output.Emitter.Name] = require(script.AudioEmitter),
}

-- Functions
local tCreateOutput = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateOutput(
	outputType: Types.AudioOutputType,
	parent: Instance,
	props: { [string]: any }?
): Types.AUOutput?
	assert(tCreateOutput(outputType, parent, props))

	if AUDIO_OUTPUTS[outputType] then
		return AUDIO_OUTPUTS[outputType].new(parent, props)
	end

	return nil
end

---------------------------------------------------------------------
local AudioOutput = {}
AudioOutput.__index = AudioOutput

--[=[
    @class AudioOutput 
    @tag Output

    Represents an audio output. This can be a device output or an emitter.
]=]

local tAudioOutput = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
    Creates a new AudioOutput, which can be used to play audio to either a device or an emitter.
]=]
function AudioOutput.new(outputType: Types.AudioOutputType, parent: Instance, props: { [string]: any }?): Types.AUOutput
	assert(tAudioOutput(outputType, parent, props))

	-- Create a new AudioOutput
	local self = {}
	self.ClassName = "AudioOutput"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our Output
	local Output = CreateOutput(outputType, parent, props)
	if not Output then
		error("Failed to create output")
	end

	self.Output = Output
	self.Instance = Output.Instance
	self.In = self.Instance

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance :: any)

	return setmetatable(self :: any, AudioOutput) :: Types.AUOutput
end

function AudioOutput:__tostring()
	return "AudioOutput"
end

--[=[
    Destroys the AudioOutput and all of its children.
]=]
function AudioOutput:Destroy()
	self._trove:Destroy()
end

return AudioOutput
