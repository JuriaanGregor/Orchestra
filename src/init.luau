--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)

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

	-- Create our Main Out
	self.MainOut = self.Output.new("Device", SoundService, {
		Name = "MainOut",
		Player = Players.LocalPlayer,
	})

	-- Create Mixes folder
	local Mixes = Instance.new("Folder")
	Mixes.Name = "Mixes"
	Mixes.Parent = SoundService

	-- Create our Master fader..
	self.Master = self.MixBus.new(Mixes, {
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
	local audioPart = Instance.new("Part")
	audioPart.Name = "AudioEngine"
	audioPart.Size = Vector3.new(1, 1, 1)
	audioPart.Transparency = 1
	audioPart.Anchored = true
	audioPart.CanCollide = false
	audioPart.Parent = workspace

	-- Create a new Emitter
	local emitter = self.Output.new("Emitter", audioPart, {
		AudioInteractionGroup = "Music",
		Name = "DefaultEmitter",
	})

	-- Add a new AudioLayer to the part
	local audioLayer = self.Layer.new("Player", audioPart, {
		AssetId = "rbxassetid://15287092994",
	})

	-- Add a AudioEffect to the Emitter
	local audioEffect = self.Effects.new("Equalizer", emitter.Instance, {
		Name = "DefaultEqualizer",
	})

	-- Wire the AudioLayer to the Emitter through the AudioEffect
	audioLayer.Routing:Wire(audioLayer.Out, audioEffect.In)
	audioEffect.Routing:Wire(audioEffect.Out, emitter.In)

	-- Play the Stream connected to the AudioLayer
	audioLayer.Stream:Play()
end

local tAddMix = t.union(t.string)

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
	local mixBus = self.MixBus.new(SoundService.Mixes, {
		Name = string.format("MixBus:%s", busName),
	})

	self.Mixes = self.Mixes or {}
	self.Mixes[busName] = mixBus

	-- Wire our mix bus to Master
	mixBus.Routing:WireTo(self.Master.In)

	-- Return our mix bus
	return mixBus
end

local tAddListener = t.union(t.string)
function Orchestra:AddListener(listenerName: string)
	assert(tAddListener(listenerName))

	-- Create a new Audio Listener
	local listener = self.Stream.new("Listener", game.Workspace.CurrentCamera, {
		Name = string.format("Listener:%s", listenerName),
		AudioInteractionGroup = listenerName,
	})

	-- Create a new Wire to connect the Listener to the MainOut
	self.Wire.new(listener.Instance, listener.Out, self.Mixes[listenerName].In)

	return listener
end

local OrchestraEngine = Orchestra.new()

-- Start the engine
OrchestraEngine:Start()

return OrchestraEngine
