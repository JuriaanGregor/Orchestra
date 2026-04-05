--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Import > Enums
local Enums = require(Package.Enums)
local VolumeUtility = require(Package.Utility.volume)

-- Constants
local DEFAULT_MIX_BUSES = {
	"Music",
	"SFX",
	"Voice",
	"Ambient",
}

---------------------------------------------------------------------

--[=[
	@class Orchestra
	@tag Engine

	Represents the main Orchestra engine, which is responsible for managing all audio components / our top level API.
]=]
local Orchestra = {}
Orchestra.__index = Orchestra
Orchestra.VERSION = "0.0.1"

function Orchestra.new()
	local self = {}
	self.ClassName = "Orchestra"
	self._trove = Trove.new()

	self.Started = false

	local comps = require(script.Components)
	for compIndex, compValue in comps do
		self[compIndex] = compValue
	end

	return setmetatable(self :: any, Orchestra)
end

function Orchestra:__tostring()
	return string.format("Orchestra Engine | Version: %s", self.VERSION)
end

--[=[
	Starts the Orchestra engine. This will set up the main output and master mix bus, as well as create a default listener and emitter.
]=]

function Orchestra:Start()
	if not self.Started then
		self.Started = true
	else
		warn("Orchestra:Start - Audio Engine already started")
		return
	end

	if SoundService:FindFirstChild("Mixes") then
		warn("Orchestra:Start - SoundService already has Mixes folder")
		return
	end

	self.MainOut = self._trove:Construct(self.Output, Enums.Output.Device, SoundService, {
		Name = "MainOut",
		Player = Players.LocalPlayer,
	})

	-- Create Mixes folder
	local Mixes = self._trove:Construct(Instance, "Folder")
	Mixes.Name = "Mixes"
	Mixes.Parent = SoundService

	-- Create our Master fader..
	self.Master = self._trove:Construct(self.Fader, SoundService.Mixes, {
		Name = "Master",
	})

	-- Wire out Master to MainOut
	self.Master.Routing:WireTo(self.MainOut.In)

	-- Add default mix buses
	for _, busName in DEFAULT_MIX_BUSES do
		self:AddMix(busName)
		self:AddListener(busName)
	end

	-- Create a new Default part with a SoundId in it..
	local audioPart = self._trove:Construct(Instance, "Part")
	audioPart.Name = "AudioEngine"
	audioPart.Position = Vector3.new(0, 4, 0)
	audioPart.Size = Vector3.new(4, 4, 4)
	audioPart.Transparency = 1
	audioPart.Anchored = true
	audioPart.CanCollide = false
	audioPart.Parent = workspace

	local audioPartL = self._trove:Construct(Instance, "Part")
	audioPartL.Name = "AudioEngineL"
	audioPartL.Position = Vector3.new(-10, 4, 0)
	audioPartL.Size = Vector3.new(4, 4, 4)
	audioPartL.Transparency = 0
	audioPartL.Anchored = true
	audioPartL.CanCollide = false
	audioPartL.Parent = workspace

	local audioPartR = self._trove:Construct(Instance, "Part")
	audioPartR.Name = "AudioEngineR"
	audioPartR.Position = Vector3.new(10, 4, 0)
	audioPartR.Size = Vector3.new(4, 4, 4)
	audioPartR.Transparency = 0
	audioPartR.Anchored = true
	audioPartR.CanCollide = false
	audioPartR.Parent = workspace

	-- Create a new AudioLayer
	local audioLayer = self._trove:Construct(self.Layer, Enums.Stream.Player, audioPart, {
		Name = "DefaultAudioLayer",
		Asset = "rbxassetid://15287092994",
	})

	-- Add a AudioEffect to the Emitter
	local audioEffect = self._trove:Construct(self.Effects, Enums.Effect.Equalizer, audioLayer.Instance, {
		Name = "DefaultEqualizer",
	})

	-- Create our AudioAnalyzer
	local audioAnalyzer = self._trove:Construct(self.Analyzers, Enums.Analyzer.Spectrum, audioLayer.Instance, {
		Name = "SpectrumAnalyzer",
	})

	audioEffect.Routing:WireTo(audioAnalyzer.In)

	-- Create a channel transform
	local audioTransform =
		self._trove:Construct(self.Transforms, Enums.Transform.ChannelSplitter, audioLayer.Instance, {
			Name = "ChannelSplitter",
			Layout = Enum.AudioChannelLayout.Stereo,
		})

	audioEffect.Routing:WireTo(audioTransform.In)

	-- Wire the AudioLayer to the Emitter through the AudioEffect
	audioLayer.Routing:WireTo(audioEffect.In)

	-- Create a new Emitter
	local emitterL = self._trove:Construct(self.Output, Enums.Output.Emitter, audioPartL, {
		AudioInteractionGroup = "Music",
		Name = "EmitterL",
	})

	local emitterR = self._trove:Construct(self.Output, Enums.Output.Emitter, audioPartR, {
		AudioInteractionGroup = "Music",
		Name = "EmitterR",
	})

	audioTransform.Routing:Wire(
		{ Instance = audioTransform.Instance, PinType = Enums.Pin.Output, Pin = "Left" },
		{ Instance = emitterL.Instance, PinType = Enums.Pin.Input }
	)

	audioTransform.Routing:Wire(
		{ Instance = audioTransform.Instance, PinType = Enums.Pin.Output, Pin = "Right" },
		{ Instance = emitterR.Instance, PinType = Enums.Pin.Input }
	)

	-- Play the Stream connected to the AudioLayer
	audioLayer.Stream:Play()

	-- Tween our Sound over a duration of 10 seconds..
	audioLayer.Fader:Tween(3, TweenInfo.new(1))
end

local tAddMix = t.string

--[=[
	Adds a new mix bus to the engine with the given name. Mix buses are used to route audio from listeners to the master output.
]=]
function Orchestra:AddMix(busName: string)
	assert(tAddMix(busName))

	-- Check if mix bus already exists
	if SoundService.Mixes:FindFirstChild(busName) then
		warn("Orchestra:AddMix - Mix bus already exists: " .. busName)
		return
	end

	-- Create a new mix bus
	local mixBus = self._trove:Construct(self.Fader, SoundService.Mixes, {
		Name = string.format("MixBus:%s", busName),
	})

	self.Mixes = self.Mixes or {}
	self.Mixes[busName] = mixBus

	-- Wire our mix bus to Master
	mixBus.Routing:WireTo(self.Master.In)

	-- Return our mix bus
	return mixBus
end

local tAddListener = t.string
function Orchestra:AddListener(listenerName: string)
	assert(tAddListener(listenerName))

	if not self.Mixes or not self.Mixes[listenerName] then
		error("Orchestra:AddListener - Mix bus does not exist for listener: " .. listenerName)
	end

	-- Create a new Audio Listener
	local listener = self._trove:Construct(self.Stream, Enums.Stream.Listener, game.Workspace.CurrentCamera, {
		Name = string.format("Listener:%s", listenerName),
		AudioInteractionGroup = listenerName,
	})

	-- Wire it to the appropriate mix bus
	listener.Routing:WireTo(self.Mixes[listenerName].In)

	return listener
end

local OrchestraEngine = Orchestra.new()

-- Start the engine
OrchestraEngine:Start()

return OrchestraEngine
