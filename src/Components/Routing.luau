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
local Wire = require(script.Parent.Wire)

-- Base Types
local Types = require(script.Parent.Parent.Types)

---------------------------------------------------------------------
local AudioRouting = {}
AudioRouting.__index = AudioRouting

--[=[
	@class AudioRouting 
	@tag Base

	Represents an AudioRouting, which is used to route audio from one instance to another.
]=]

local tAudioRouting = t.tuple(t.Instance, t.array(t.string))
--[=[
	Creates a new AudioRouting
]=]
function AudioRouting.new(parent: Instance, pins: { Types.AudioPin }): Types.AURouting
	assert(tAudioRouting(parent, pins))

	-- Create a new AudioRouting
	local self = {}
	self.ClassName = "AudioRouting"

	-- Create our Trove
	self._trove = Trove.new()

	-- Store our pins and routing
	self.Pins = pins
	self.Routing = {}

	-- Create our Changed signal
	self.Changed = self._trove:Construct(Signal)

	-- Create a new Folder for our AudioRouting
	local AudioRoute = Instance.new("Folder")
	AudioRoute.Name = "AudioRouting"
	AudioRoute.Parent = parent

	self.Instance = AudioRoute :: Folder
	self._baseInstance = parent :: Types.AudioMembers
	self._trove:Add(AudioRoute)

	-- Set up our routing
	for _, pin in pins do
		self.Routing[pin] = {}
	end

	-- Return our AudioRouting
	return setmetatable(self :: any, AudioRouting) :: Types.AURouting
end

function AudioRouting:__tostring()
	local elements = {
		Input = nil,
		Output = nil,
	}

	for _, pin in self.Pins do
		elements[pin] = self.Routing[pin]
	end

	return string.format(
		"AudioRouting \n Input: %s \n Output: %s",
		elements.Input and (#elements.Input > 0 and "Pins are connected" or "No pins connected") or "Pin does not exist",
		elements.Output and (#elements.Output > 0 and "Pins are connected" or "No pins connected")
			or "Pin does not exist"
	)
end

local tIsPin = t.tuple(t.string)
--[=[
	Checks if a pin exists in the AudioRouting
]=]
function AudioRouting:IsPin(pin: Types.AudioPin): boolean
	assert(tIsPin(pin))
	return table.find(self.Pins, pin) ~= nil
end

local tGetWiresAtPin = t.tuple(t.string)
--[=[
	Get all the wires that are connected to a pin
]=]
function AudioRouting:GetWiresAtPin(pin: Types.AudioPin): { Types.AUWire }
	assert(tGetWiresAtPin(pin))
	assert(self:IsPin(pin), "Pin does not exist in this AudioRouting")

	return self.Pins[pin]
end

local tAddWire = t.tuple(t.string, t.table)
--[=[
	Adds a wire to the AudioRouting
]=]
function AudioRouting:AddWire(pin: Types.AudioPin, wire: Types.AUWire)
	assert(tAddWire(pin, wire))
	assert(self:IsPin(pin), "Pin does not exist in this AudioRouting")

	-- Add the wire to the routing
	local pinRouting = self.Routing[pin]

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

	-- Emit the changed signal
	self:_Difference(_oldRecord, self.Routing)
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

	local hasInputPin = self:IsPin("Input")
	local hasOutputPin = self:IsPin("Output")

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
	local wire = Wire.new(self.Instance, from, to)

	-- Add the wire to the AudioRouting
	local direction = to == self._baseInstance and "Input" or "Output"
	self:AddWire(direction, wire)
end

--[=[
	Destroys the AudioRouting
]=]
function AudioRouting:Destroy()
	self._trove:Destroy()
end

return AudioRouting
