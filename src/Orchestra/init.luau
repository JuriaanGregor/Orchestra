--!strict
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import > Packages
local Dependencies = require("@self/Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Import > Enums
local Enums = require("@self/Enums")

-- Import > Configs
local Config = require("@self/Config")

---------------------------------------------------------------------

local function createMaster(trove: Dependencies.Trove, fader: any)
	if not SoundService:FindFirstChild("Mixes") then
		error("SoundService is missing Mixes folder")
	end

	if SoundService.Mixes:FindFirstChild("Master") then
		error("SoundService already has Master mix bus")
	end

	local Master = fader.new(SoundService.Mixes, {
		Name = "Master",
	})

	trove:Add(Master)

	-- Return our master fader
	return Master
end

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

	-- Mix buses by name, filled by :AddMix
	self.Mixes = {}

	-- Expose our Enums, these are needed to create components through the factories
	self.Enums = Enums

	local comps = require("@self/Components")
	for compIndex, compValue in comps do
		self[compIndex] = compValue
	end

	return setmetatable(self :: any, Orchestra)
end

function Orchestra:__tostring()
	return string.format("Orchestra Engine | Version: %s", self.VERSION)
end

--[=[
	Starts the Orchestra engine. This sets up the main output, the Master fader, and a mix bus + listener
	for every bus in `Config.MIX_BUSES`. Must be called on the client.
]=]
function Orchestra:Start()
	if self.Started then
		warn("Orchestra:Start - Audio Engine already started")
		return
	end

	if not RunService:IsClient() then
		error("Orchestra:Start - The audio engine can only be started on the client")
	end

	if SoundService:FindFirstChild("Mixes") then
		warn("Orchestra:Start - SoundService already has Mixes folder")
		return
	end

	self.Started = true

	-- Typed local: `self` is untyped here, so Luau would otherwise infer Trove's methods from their first use
	local trove: Dependencies.Trove = self._trove

	-- Note: SoundService.DefaultListenerLocation should be set to None in the place (game scripts can't set it).
	-- Otherwise Roblox's default listener wires itself into MainOut, letting ungrouped emitters bypass the mix buses.

	self.MainOut = trove:Construct(self.Output, Enums.Output.Device, SoundService, {
		Name = "MainOut",
		Player = Players.LocalPlayer,
	})

	-- Create Mixes folder
	local Mixes = Instance.new("Folder")
	Mixes.Name = "Mixes"
	Mixes.Parent = SoundService
	trove:Add(Mixes)

	-- Create our Master fader..
	self.Master = createMaster(trove, self.Fader)

	-- Wire out Master to MainOut
	self.Master.Routing:WireTo(self.MainOut.In)

	-- Add default mix buses
	for _, bus in Config.MIX_BUSES:GetEnumItems() do
		self:AddMix(bus.Name)
		self:AddListener(bus.Name)
	end
end

local tAddMix = t.string

--[=[
	Adds a new mix bus to the engine with the given name. Mix buses are used to route audio from listeners to the master output.
]=]
function Orchestra:AddMix(busName: string)
	assert(tAddMix(busName))

	-- Check if mix bus already exists
	if self.Mixes[busName] then
		warn("Orchestra:AddMix - Mix bus already exists: " .. busName)
		return
	end

	-- Create a new mix bus
	local mixBus = self._trove:Construct(self.Fader, SoundService.Mixes, {
		Name = string.format("MixBus:%s", busName),
	})

	self.Mixes[busName] = mixBus

	-- Wire our mix bus to Master
	mixBus.Routing:WireTo(self.Master.In)

	-- Return our mix bus
	return mixBus
end

local tAddListener = t.string
function Orchestra:AddListener(listenerName: string)
	assert(tAddListener(listenerName))

	if not RunService:IsClient() then
		error("Orchestra:AddListener - Listeners can only be added on the client")
	end

	if not self.Mixes[listenerName] then
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

-- Requiring Orchestra has no side effects: call `:Start()` on the client to set up the engine
return Orchestra.new()
