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
--[=[
	@class Analyzers
	@tag Analyzer

	Creates analyzer components: [AudioSpectrumAnalyzer]. Reached through `Orchestra.Analyzers`.

	```lua
	Orchestra.Analyzers.new(Enums.Analyzer.Spectrum, speaker)
	```
]=]
local AudioAnalyzer = {}
AudioAnalyzer.__index = AudioAnalyzer

local tAudioAnalyzer = t.tuple(Types.tAudioAnalyzer, t.Instance, t.optional(t.map(t.string, t.any)))
--[=[
	@within Analyzers
	Creates a component of type `analyzerType`.

	@param analyzerType EnumItem -- One of [Enums.Analyzer]
	@param parent Instance -- Where the instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return any -- The component, see the classes listed above
]=]
function AudioAnalyzer.new(analyzerType: Enums.EnumItem, parent: Instance, props: { [string]: any }?): Types.AUAnalyzer
	assert(tAudioAnalyzer(analyzerType.Name, parent, props))

	local Analyzer = CreateAnalyzer(analyzerType, parent, props)
	if not Analyzer then
		error("Was not able to create analyzer with type: " .. analyzerType.Name)
	end

	return Analyzer
end

return AudioAnalyzer
