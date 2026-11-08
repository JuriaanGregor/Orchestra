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

	The Orchestra engine: the module returns this object. Requiring it has no side effects; call [Orchestra:Start] on
	the client to build the mixer:

	```
	Listener:<bus> -> MixBus:<bus> -> Master -> MainOut
	```

	Each bus in [Config.MIX_BUSES] gets an `AudioListener` on the camera, filtered by `AudioInteractionGroup`. Give an
	emitter a bus name as its `AudioInteractionGroup` to send it to that bus.

	:::caution
	Set `SoundService.DefaultListenerLocation` to `None` in your place. Otherwise Roblox's default listener wires itself
	into `MainOut`, and emitters without an `AudioInteractionGroup` skip the mix buses. Game scripts can't set it.
	:::
]=]

--[=[
	@prop VERSION string
	@within Orchestra
	@readonly

	The Orchestra version.
]=]

--[=[
	@prop Started boolean
	@within Orchestra
	@readonly

	Whether [Orchestra:Start] has run.
]=]

--[=[
	@prop Enums Enums
	@within Orchestra
	@readonly

	The [Enums] used to pick component types.
]=]

--[=[
	@prop MainOut AudioDeviceOutput
	@within Orchestra
	@readonly

	The device output everything plays through. Set by [Orchestra:Start].
]=]

--[=[
	@prop Master Fader
	@within Orchestra
	@readonly

	The Master [Fader], wired into `MainOut`. Set by [Orchestra:Start].
]=]

--[=[
	@prop Mixes { [string]: Fader }
	@within Orchestra
	@readonly

	The mix bus Faders by bus name, see [Orchestra:AddMix].
]=]

--[=[
	@prop Stream Stream
	@within Orchestra
	@readonly

	The [Stream] factory.
]=]

--[=[
	@prop Output Output
	@within Orchestra
	@readonly

	The [Output] factory.
]=]

--[=[
	@prop Effects Effects
	@within Orchestra
	@readonly

	The [Effects] factory.
]=]

--[=[
	@prop Transforms Transforms
	@within Orchestra
	@readonly

	The [Transforms] factory.
]=]

--[=[
	@prop Analyzers Analyzers
	@within Orchestra
	@readonly

	The [Analyzers] factory.
]=]

--[=[
	@prop Fader Fader
	@within Orchestra
	@readonly

	The [Fader] class, for `Orchestra.Fader.new`.
]=]

--[=[
	@prop Layer Layer
	@within Orchestra
	@readonly

	The [Layer] class, for `Orchestra.Layer.new`.
]=]

--[=[
	@prop Routing Routing
	@within Orchestra
	@readonly

	The [Routing] class.
]=]

--[=[
	@prop Wire Wire
	@within Orchestra
	@readonly

	The [Wire] class.
]=]
local Orchestra = {}
Orchestra.__index = Orchestra
Orchestra.VERSION = "0.0.2"

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
	@within Orchestra
	Builds the mixer: `MainOut`, the Master Fader, and a mix bus + listener for every bus in [Config.MIX_BUSES].
	Errors on the server; warns and does nothing if already started.

	@client
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
	@within Orchestra
	Adds a mix bus: a [Fader] named `MixBus:<busName>` in `SoundService.Mixes`, wired into Master.
	Warns and returns nothing if the bus already exists. Call [Orchestra:AddListener] to give it a listener.

	@param busName string
	@return Fader?
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
--[=[
	@within Orchestra
	Adds an `AudioListener` on the camera for an existing mix bus, hearing emitters whose `AudioInteractionGroup` is
	`busName`, and wires it into that bus.

	@param busName string -- An existing bus, see [Orchestra:AddMix]
	@return AudioListener
	@client
]=]
function Orchestra:AddListener(busName: string)
	assert(tAddListener(busName))

	if not RunService:IsClient() then
		error("Orchestra:AddListener - Listeners can only be added on the client")
	end

	if not self.Mixes[busName] then
		error("Orchestra:AddListener - Mix bus does not exist for listener: " .. busName)
	end

	-- Create a new Audio Listener
	local listener = self._trove:Construct(self.Stream, Enums.Stream.Listener, game.Workspace.CurrentCamera, {
		Name = string.format("Listener:%s", busName),
		AudioInteractionGroup = busName,
	})

	-- Wire it to the appropriate mix bus
	listener.Routing:WireTo(self.Mixes[busName].In)

	return listener
end

-- Requiring Orchestra has no side effects: call `:Start()` on the client to set up the engine
return Orchestra.new()
