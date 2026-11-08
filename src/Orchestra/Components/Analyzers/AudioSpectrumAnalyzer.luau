--!strict
-- Roblox Services
local RunService = game:GetService("RunService")

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove
local Signals = Dependencies.Signals

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")

-- Types
local Types = require("../../Types")

-- Functions
local tAudioAnalyzer = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

local function CreateAudioAnalyzer(parent: Instance, props: { [string]: any }?): AudioAnalyzer
	assert(tAudioAnalyzer(parent, props))

	local audioAnalyzer = Instance.new("AudioAnalyzer")
	audioAnalyzer.Parent = parent

	-- Apply properties
	applyInstanceProps(audioAnalyzer, props and props or {})

	-- Return our object
	return audioAnalyzer
end

-- Creates a signal that is updated with `read()` every frame. Returns the getter and a function to stop observing.
local function observe<T>(trove: any, read: () -> T): (Dependencies.Getter<T>, () -> ())
	local get, set = Signals.createSignal(read())

	local connection = RunService.RenderStepped:Connect(function()
		set(read())
	end)
	trove:Add(connection)

	local function stop()
		trove:Remove(connection)
	end

	return get, stop
end

---------------------------------------------------------------------
local AudioSpectrumAnalyzer = {}
AudioSpectrumAnalyzer.__index = AudioSpectrumAnalyzer

--[=[
    @class AudioSpectrumAnalyzer
    @tag Analyzer

    Represents an Audio Spectrum Analyzer. This is used to analyze audio data in real time.
]=]

function AudioSpectrumAnalyzer.new(parent: Instance, props: { [string]: any }?): Types.AUAnalyzer
	assert(tAudioAnalyzer(parent, props))

	-- Create a new AudioSpectrumAnalyzer
	local self = {}
	self.Type = "Analyzer"
	self.ClassName = "AudioSpectrumAnalyzer"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioSpectrumAnalyzer Instance
	self.Instance = CreateAudioAnalyzer(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance

	return setmetatable(self :: any, AudioSpectrumAnalyzer) :: Types.AUAnalyzer
end

--[=[
    Returns the current spectrum data. This is an array of 512 numbers representing the spectrum data of the audio.
]=]

function AudioSpectrumAnalyzer:GetSpectrum(): {}
	-- Spectrum data is only available on the client, so we need to check if we're on the server or not.
	if RunService:IsServer() then
		error("GetSpectrum can only be called on the client.")
	end

	-- Spectrum data is only available if we aren't connected to an AudioDeviceInput, so we need to check if we're connected to one or not.
	local Wires = self.Instance:GetConnectedWires()
	for _, wire in pairs(Wires) do
		if wire.SourceInstance and wire.SourceInstance:IsA("AudioDeviceInput") then
			error("GetSpectrum cannot be called while connected to an AudioDeviceInput.")
		end
	end

	return self.Instance:GetSpectrum()
end

--[=[
    Observes the spectrum data of the audio. This returns a signal that fires every frame with the current spectrum data. The second return value is a function that can be called to stop observing the spectrum data.
]=]

function AudioSpectrumAnalyzer:ObserveSpectrum()
	if RunService:IsServer() then
		error("ObserveSpectrum can only be called on the client.")
	end

	-- Spectrum data is only available if we aren't connected to an AudioDeviceInput, so we need to check if we're connected to one or not.
	local Wires = self.Instance:GetConnectedWires()
	for _, wire in Wires do
		if wire.SourceInstance and wire.SourceInstance:IsA("AudioDeviceInput") then
			error("ObserveSpectrum cannot be called while connected to an AudioDeviceInput.")
		end
	end

	return observe(self._trove, function()
		return self.Instance:GetSpectrum()
	end)
end

--[=[
    Returns the current peak level of the audio. This is a number between 0 and 1 representing the peak level of the audio.
]=]

function AudioSpectrumAnalyzer:GetPeak()
	if RunService:IsServer() then
		error("GetPeak can only be called on the client.")
	end

	return self.Instance.PeakLevel
end

--[=[
    Observes the peak level of the audio. This returns a signal that fires every frame with the current peak level of the audio. The second return value is a function that can be called to stop observing the peak level.
]=]

function AudioSpectrumAnalyzer:ObservePeak()
	if RunService:IsServer() then
		error("ObservePeak can only be called on the client.")
	end

	return observe(self._trove, function()
		return self.Instance.PeakLevel
	end)
end

--[=[
    Returns the current RMS level of the audio. This is a number between 0 and 1 representing the RMS level of the audio.
]=]

function AudioSpectrumAnalyzer:GetRMS()
	if RunService:IsServer() then
		error("GetRMS can only be called on the client.")
	end

	return self.Instance.RmsLevel
end

--[=[
    Observes the RMS level of the audio. This returns a signal that fires every frame with the current RMS level of the audio. The second return value is a function that can be called to stop observing the RMS level.
]=]

function AudioSpectrumAnalyzer:ObserveRMS()
	if RunService:IsServer() then
		error("ObserveRMS can only be called on the client.")
	end

	return observe(self._trove, function()
		return self.Instance.RmsLevel
	end)
end

function AudioSpectrumAnalyzer:__tostring()
	return "AudioSpectrumAnalyzer"
end

function AudioSpectrumAnalyzer:Destroy()
	self._trove:Destroy()
end

return AudioSpectrumAnalyzer
