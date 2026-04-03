--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Types
local Types = require(Package.Types)

-- Variables
local AUDIO_OUTPUTS: { [Types.AudioOutputType]: any } = {
	["Device"] = require(script.AudioDeviceOutput),
	["Emitter"] = require(script.AudioEmitter),
}

-- Functions
local tCreateOutput = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))
function CreateOutput(outputType: Types.AudioOutputType, parent: Instance, props: { [string]: any }?): Types.AUOutput?
	assert(tCreateOutput(outputType, parent, props))

	if outputType == "Device" then
		local AudioDeviceOutput = AUDIO_OUTPUTS[outputType]

		local listener = nil :: Player?
		if props then
			listener = typeof(props.Listener) == "Player" and props.Listener or nil
		end
		return AudioDeviceOutput.new(parent, listener, props)
	elseif outputType == "Emitter" then
		local AudioEmitter = AUDIO_OUTPUTS[outputType]
		return AudioEmitter.new(parent, props)
	end

	return nil
end

---------------------------------------------------------------------
local AudioOutput = {}
AudioOutput.__index = AudioOutput

--[=[
    @class AudioOutput 
    @tag Audio
    @client 

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

	local AudioComponent = AUDIO_OUTPUTS[outputType]
	if not AudioComponent then
		error("Invalid outputType")
	end

	self.In = nil :: Types.AudioMembers?
	self.Output = nil :: Types.AUOutput?
	self.Instance = nil :: Types.AudioMembers?

	-- Create our Output
	local Output = CreateOutput(outputType, parent, props)
	if not Output then
		error("Failed to create output")
	end

	self.Output = Output
	self.Instance = Output.Instance
	self.In = self.Instance

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
