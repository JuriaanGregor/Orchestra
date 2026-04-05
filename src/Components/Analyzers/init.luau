--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Import > Package
local Routing = require(Package.Components.Routing)

-- Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

-- Variables
local AUDIO_ANALYZERS: { [string]: any } = {
	[Enums.Analyzer.Spectrum.Name] = require(script.AudioSpectrumAnalyzer),
}

-- Functions
local tCreateAnalyzer = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))

local function CreateAnalyzer(
	analyzerType: Enums.EnumItem,
	parent: Instance,
	props: { [string]: any }?
): Types.AUAnalyzer
	assert(tCreateAnalyzer(analyzerType.Name, parent, props))

	local Analyzer = AUDIO_ANALYZERS[analyzerType.Name]
	if not Analyzer then
		error("Invalid analyzer type")
	end

	return Analyzer.new(parent, props) :: Types.AUAnalyzer
end
---------------------------------------------------------------------

local AudioAnalyzer = {}
AudioAnalyzer.__index = AudioAnalyzer

--[=[
	@class AudioAnalyzer
    @tag Analyzer   

    Represents an Audio Analyzer. This is used to analyze audio data in real time.
]=]

local tAudioAnalyzer = t.tuple(Types.tAudioAnalyzer, t.Instance, t.optional(t.map(t.string, t.any)))
--[=[
    Creates a new AudioAnalyzer. This is used to analyze audio data in real time.

	@param analyzerType Types.AudioAnalyzerType -- The type of the analyzer. This can be "Spectrum" or other audio analyzers.
	@param parent Instance -- The parent of the analyzer.
	@param props {[string]: any}? -- A table of properties to set on the analyzer.
	@return Types.AudioAnalyzer -- The new AudioAnalyzer.
]=]
function AudioAnalyzer.new(analyzerType: Enums.EnumItem, parent: Instance, props: { [string]: any }?): Types.AUAnalyzer
	assert(tAudioAnalyzer(analyzerType.Name, parent, props))

	-- Create a new AudioAnalyzer
	local self = {}
	self.ClassName = "AudioAnalyzer"
	self.AnalyzerType = analyzerType

	-- Create our Trove
	self._trove = Trove.new()

	local Analyzer = CreateAnalyzer(analyzerType, parent, props)
	if not Analyzer then
		error("Invalid analyzer type")
	end

	-- Store the analyzer
	self.Analyzer = Analyzer

	-- Expose our members
	self.Routing = Routing.new(Analyzer.Instance :: Instance, { Enums.Pin.Input })
	self.Instance = Analyzer.Instance
	self.In = self.Instance

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioAnalyzer) :: Types.AUAnalyzer
end

function AudioAnalyzer:__tostring()
	return string.format("AudioAnalyzer<%s>", self.AnalyzerType.Name)
end

--[=[
	Destroys the AudioAnalyzer.
]=]
function AudioAnalyzer:Destroy()
	self._trove:Destroy()
end

return AudioAnalyzer
