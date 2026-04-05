--!strict
-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)
local Signal = require(Package.Packages.Signal)

-- Imports > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)

-- Types
local Types = require(Package.Types)

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

function AudioSpectrumAnalyzer:ObserveSpectrum(): (Types.Signal, () -> ())
	-- Create a Trove that we will use to clean up our connection when the AudioAnalyzer is destroyed.
	local observeTrove = self._trove:Extend()
	local observeSignal = observeTrove:Construct(Signal)

	observeTrove:Connect(RunService.Heartbeat, function()
		-- Get our Spectrum data
		local ok, result = pcall(function()
			return self.Instance:GetSpectrum()
		end)

		if ok then
			observeSignal:Fire(result)
		else
			observeSignal:Fire(nil)
		end
	end)

	return observeSignal, function()
		observeTrove:Destroy()
	end
end

function AudioSpectrumAnalyzer:GetPeak()
	if RunService:IsServer() then
		error("GetPeak can only be called on the client.")
	end

	return self.Instance.PeakLevel
end

function AudioSpectrumAnalyzer:ObservePeak(): (Types.Signal, () -> ())
	local observeTrove = self._trove:Extend()
	local observeSignal = observeTrove:Construct(Signal)

	observeTrove:Connect(RunService.Heartbeat, function()
		local ok, result = pcall(function()
			return self.Instance.PeakLevel
		end)

		if ok then
			observeSignal:Fire(result)
		else
			observeSignal:Fire(nil)
		end
	end)

	return observeSignal, function()
		observeTrove:Destroy()
	end
end

function AudioSpectrumAnalyzer:GetRMS()
	if RunService:IsServer() then
		error("GetRMS can only be called on the client.")
	end

	return self.Instance.RmsLevel
end

function AudioSpectrumAnalyzer:ObserveRMS(): (Types.Signal, () -> ())
	local observeTrove = self._trove:Extend()
	local observeSignal = observeTrove:Construct(Signal)

	observeTrove:Connect(RunService.Heartbeat, function()
		local ok, result = pcall(function()
			return self.Instance.RmsLevel
		end)

		if ok then
			observeSignal:Fire(result)
		else
			observeSignal:Fire(nil)
		end
	end)

	return observeSignal, function()
		observeTrove:Destroy()
	end
end

function AudioSpectrumAnalyzer:__tostring()
	return "AudioSpectrumAnalyzer"
end

function AudioSpectrumAnalyzer:Destroy()
	self._trove:Destroy()
end

return AudioSpectrumAnalyzer
