--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)
local Signal = require(Package.Packages.Signal)
local TableUtil = require(Package.Packages.TableUtil)

-- Import > Components
local Wire = require(Package.Components.Wire)

-- Base Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

---------------------------------------------------------------------
local AudioRouting = {}
AudioRouting.__index = AudioRouting

--[=[
	@class AudioRouting 
	@tag Base

	Represents an AudioRouting, which is used to route audio from one instance to another.
]=]

local tAudioRouting = t.tuple(t.Instance, t.array(t.table))
--[=[
	Creates a new AudioRouting
]=]
function AudioRouting.new(parent: Instance, pins: { Enums.EnumItem }): Types.AURouting
	assert(tAudioRouting(parent, pins))

	-- Create a new AudioRouting
	local self = {}
	self.ClassName = "AudioRouting"

	-- Create our Trove
	self._trove = Trove.new()

	-- Store our pins and routing
	self.Pins = {}
	self.Routing = {}

	-- Create our Changed signal
	self.Changed = self._trove:Construct(Signal)

	-- Create a new Folder for our AudioRouting
	local AudioRoute = Instance.new("Folder")
	AudioRoute.Name = "AudioRouting"
	AudioRoute.Parent = parent
	self._trove:Add(AudioRoute)

	-- Set up our routing
	for _, pin in pins do
		self.Routing[pin.Name] = {}
	end

	-- Expose our members
	self.Instance = AudioRoute :: Folder
	self._baseInstance = parent :: Types.AudioMembers

	-- Attach our Trove to the AudioRouting Folder
	self._trove:AttachToInstance(self.Instance)

	-- Return our AudioRouting
	return setmetatable(self :: any, AudioRouting) :: Types.AURouting
end

function AudioRouting:__tostring()
	local elements = {
		[Enums.Pin.Input.Name] = nil,
		[Enums.Pin.Output.Name] = nil,
		[Enums.Pin.Sidechain.Name] = nil,
	}

	for _, pin in self.Pins do
		elements[pin] = self.Routing[pin]
	end

	return string.format(
		"AudioRouting \n Input: %s \n Output: %s \n Sidechain: %s",
		elements[Enums.Pin.Input.Name]
				and (#elements[Enums.Pin.Input.Name] > 0 and "Pins are connected" or "No pins connected")
			or "Pin does not exist",
		elements[Enums.Pin.Output.Name]
				and (#elements[Enums.Pin.Output.Name] > 0 and "Pins are connected" or "No pins connected")
			or "Pin does not exist",
		elements[Enums.Pin.Sidechain.Name]
				and (#elements[Enums.Pin.Sidechain.Name] > 0 and "Pins are connected" or "No pins connected")
			or "Pin does not exist"
	)
end

local tIsPin = t.tuple(t.table)
--[=[
	Checks if a pin exists in the AudioRouting
]=]
function AudioRouting:IsPin(pin: Enums.EnumItem): boolean
	assert(tIsPin(pin))

	if not self.Routing[pin.Name] then
		return false
	end

	return true
end

local tGetWiresAtPin = t.tuple(t.string)
--[=[
	Get all the wires that are connected to a pin
]=]
function AudioRouting:GetWiresAtPin(pin: Types.AudioPin): { Types.AUWire }
	assert(tGetWiresAtPin(pin))
	assert(self:IsPin(pin), "Pin does not exist in this AudioRouting")

	return self.Routing[pin]
end

local tAddWire = t.tuple(t.table, t.table)
--[=[
	Adds a wire to the AudioRouting
]=]
function AudioRouting:AddWire(pin: Enums.EnumItem, wire: Types.AUWire)
	assert(tAddWire(pin, wire))
	assert(self:IsPin(pin), "Pin does not exist in this AudioRouting")

	-- Add the wire to the routing
	local pinRouting = self.Routing[pin.Name]

	-- Go thru the routing and check if the wire is already there
	local filteredWires = TableUtil.Filter(pinRouting, function(value)
		return value.ID == wire.ID
	end)

	-- If the wire is already in the routing, then we don't need to add it
	if #filteredWires > 0 then
		return
	end

	table.insert(pinRouting, wire)
end

local tClearPin = t.tuple(t.string)
--[=[
	Disconnects all the wires that are connected to a pin
]=]
function AudioRouting:ClearPin(pin: Types.AudioPin)
	assert(tClearPin(pin))
	assert(self:IsPin(pin), "Pin does not exist in this AudioRouting")

	-- Make a snapshot of the old record
	local _oldRecord = self.Routing

	-- Clear the pin
	self.Routing[pin] = {}
end

local tGetPinsFromInstance = t.tuple(t.Instance)
--[=[
	Gets all the wires that are connected to a specific instance
]=]
function AudioRouting:GetPinsFromInstance(instance: Instance): { [Types.AudioPin]: { Wire } }
	assert(tGetPinsFromInstance(instance))

	local result = {}
	local pinMap = {} :: { [string]: boolean }

	for _, currentPin in self.Pins do
		result[currentPin] = {}
		pinMap[currentPin] = true
	end

	-- Go thru all the Wires
	local Wires = CollectionService:GetTagged("AudioWire")
	for _, wire in Wires :: { Wire } do
		-- Based on the SourceInstance and TargetInstance we can now populate the list
		if pinMap.Input then
			if wire.SourceInstance then
				if wire.SourceInstance == instance then
					table.insert(result.Input, wire)
				end
			end
		end

		if pinMap.Output then
			if wire.TargetInstance then
				if wire.TargetInstance == instance then
					table.insert(result.Output, wire)
				end
			end
		end
	end

	return result
end

local tWireTo = t.tuple(t.Instance)
--[=[
	Wires the base instance to another instance
]=]
function AudioRouting:WireTo(to: Types.AudioMembers)
	assert(tWireTo(to))
	self:Wire(self._baseInstance, to)
end

local tWire = t.tuple(t.Instance, t.Instance)
--[=[
	Creates a new Wire and adds it to the AudioRouting
]=]
function AudioRouting:Wire(from: Types.AudioMembers, to: Types.AudioMembers)
	assert(tWire(from, to))

	local hasInputPin = self:IsPin(Enums.Pin.Input)
	local hasOutputPin = self:IsPin(Enums.Pin.Output)

	if not hasInputPin then
		if to == self._baseInstance then
			error(
				string.format(
					"<AudioRouting> Cannot wire %s to the base instance, as it does not have an input pin",
					from.Name :: string
				),
				2
			)
		end
	end

	if not hasOutputPin then
		if from == self._baseInstance then
			error(
				string.format(
					"<AudioRouting> Cannot wire %s to the base instance, as it does not have an output pin",
					to.Name :: string
				),
				2
			)
		end
	end

	-- Create a new Wire
	local wire = self._trove:Construct(Wire, self.Instance, {
		Input = from,
		Output = to,
	})

	-- Add the wire to the AudioRouting
	local direction = to == self._baseInstance and Enums.Pin.Input or Enums.Pin.Output
	self:AddWire(direction, wire)
end

--[=[
	Destroys the AudioRouting
]=]
function AudioRouting:Destroy()
	self._trove:Destroy()
end

return AudioRouting
