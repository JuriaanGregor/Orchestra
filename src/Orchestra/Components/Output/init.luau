--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)

-- Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

-- Variables
local AUDIO_OUTPUTS = {
	[Enums.Output.Device.Name] = require(script.AudioDeviceOutput),
	[Enums.Output.Emitter.Name] = require(script.AudioEmitter),
} :: { [string]: any }

-- Functions
local tCreateOutput = t.tuple(t.table, t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateOutput(outputType: Enums.EnumItem, parent: Instance, props: { [string]: any }?): Types.AUOutput?
	assert(tCreateOutput(outputType, parent, props))

	if not AUDIO_OUTPUTS[outputType.Name] then
		error("Invalid output type")
	end

	return AUDIO_OUTPUTS[outputType.Name].new(parent, props)
end

---------------------------------------------------------------------
local AudioOutput = {}
AudioOutput.__index = AudioOutput

function AudioOutput.new(outputType: Enums.EnumItem, parent: Instance, props: { [string]: any }?): Types.AUOutput
	assert(tCreateOutput(outputType, parent, props))

	local Output = CreateOutput(outputType, parent, props)
	if not Output then
		error("Invalid outputType")
	end

	return Output
end

return AudioOutput
