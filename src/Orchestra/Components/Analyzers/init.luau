--!strict

-- Import
local Dependencies = require("../Dependencies")
local t = Dependencies.t

-- Types
local Types = require("../Types")

-- Enums
local Enums = require("../Enums")

-- Variables
local AUDIO_ANALYSERS: { [string]: any } = {
	[Enums.Analyzer.Spectrum.Name] = require("@self/AudioSpectrumAnalyzer"),
}

-- Functions
local tCreateAnalyzer = t.tuple(Types.tAudioAnalyzer, t.Instance, t.optional(t.map(t.string, t.any)))

local function CreateAnalyzer(analyzerType: Enums.EnumItem, parent: Instance, props: { [string]: any }?)
	assert(tCreateAnalyzer(analyzerType.Name, parent, props))

	if not AUDIO_ANALYSERS[analyzerType.Name] then
		error("Invalid analyzer type")
	end

	return AUDIO_ANALYSERS[analyzerType.Name].new(parent, props) :: Types.AUAnalyzer
end

---------------------------------------------------------------------
local AudioAnalyzer = {}
AudioAnalyzer.__index = AudioAnalyzer

local tAudioAnalyzer = t.tuple(Types.tAudioAnalyzer, t.Instance, t.optional(t.map(t.string, t.any)))
function AudioAnalyzer.new(analyzerType: Enums.EnumItem, parent: Instance, props: { [string]: any }?): Types.AUAnalyzer
	assert(tAudioAnalyzer(analyzerType.Name, parent, props))

	local Analyzer = CreateAnalyzer(analyzerType, parent, props)
	if not Analyzer then
		error("Was not able to create analyzer with type: " .. analyzerType.Name)
	end

	return Analyzer
end

return AudioAnalyzer
