--!strict

-- Imports
local Dependencies = require("../Dependencies")
local t = Dependencies.t

-- Types
local Types = require("../Types")

-- Enums
local Enums = require("../Enums")

-- Variables
local AUDIO_OUTPUTS = {
	[Enums.Output.Device.Name] = require("@self/AudioDeviceOutput"),
	[Enums.Output.Emitter.Name] = require("@self/AudioEmitter"),
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
