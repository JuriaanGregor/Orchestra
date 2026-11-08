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
local bindLifetime = require("../../Instances/bindLifetime")
local Routing = require("../Routing")

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

	Wraps an `AudioAnalyzer`, which measures the level and spectrum of the audio wired into it. Readings are only available on the client.

	Create one with `Orchestra.Analyzers.new(Enums.Analyzer.Spectrum, parent, props)`.
]=]

--[=[
	@prop Instance AudioAnalyzer
	@within AudioSpectrumAnalyzer
	@readonly

	The wrapped `AudioAnalyzer` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioSpectrumAnalyzer
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioAnalyzer
	@within AudioSpectrumAnalyzer
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	Creates a new AudioSpectrumAnalyzer under `parent`. Usually created through `Orchestra.Analyzers.new`.

	@param parent Instance -- Where the `AudioAnalyzer` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioSpectrumAnalyzer
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

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	-- Create our routing, so wires into the analyzer are removed with it
	self.Routing = Routing.new(self.Instance)

	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance

	return setmetatable(self :: any, AudioSpectrumAnalyzer) :: Types.AUAnalyzer
end

--[=[
	Returns the current frequency spectrum. Errors on the server, or while an `AudioDeviceInput` is wired into the analyzer.

	@return { number } -- Magnitude per frequency band
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
	Observes the frequency spectrum, updated every frame. Errors on the server, or while an `AudioDeviceInput` is wired into the analyzer.

	@return Getter<{ number }> -- A Signals getter holding the latest spectrum
	@return () -> () -- Call to stop observing
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
	Returns the current peak level. Errors on the server.

	@return number
]=]
function AudioSpectrumAnalyzer:GetPeak()
	if RunService:IsServer() then
		error("GetPeak can only be called on the client.")
	end

	return self.Instance.PeakLevel
end

--[=[
	Observes the peak level, updated every frame. Errors on the server.

	@return Getter<number> -- A Signals getter holding the latest peak level
	@return () -> () -- Call to stop observing
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
	Returns the current RMS (average) level. Errors on the server.

	@return number
]=]
function AudioSpectrumAnalyzer:GetRMS()
	if RunService:IsServer() then
		error("GetRMS can only be called on the client.")
	end

	return self.Instance.RmsLevel
end

--[=[
	Observes the RMS (average) level, updated every frame. Errors on the server.

	@return Getter<number> -- A Signals getter holding the latest RMS level
	@return () -> () -- Call to stop observing
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

--[=[
	Destroys the AudioSpectrumAnalyzer: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioSpectrumAnalyzer:Destroy()
	self._trove:Destroy()
end

return AudioSpectrumAnalyzer
