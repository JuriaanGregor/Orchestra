--!strict
local HttpService = game:GetService("HttpService")

-- Import > Packages
local Dependencies = require("../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Import > Components
local Wire = require("./Wire")

-- Base Types
local Types = require("../Types")

-- Enums
local Enums = require("../Enums")

-- Types
export type AudioRoutingPin = Types.AudioRoutingPin

local function CreateWire(from: AudioRoutingPin, to: AudioRoutingPin): Types.AUWire
	assert(Types.tAudioMembers(from.Instance.ClassName), "From instance must be an AudioMember")
	assert(Types.tAudioMembers(to.Instance.ClassName), "To instance must be an AudioMember")

	return Wire.new(from.Instance:FindFirstChild("AudioRouter") or from.Instance, {
		SourceInstance = from.Instance,
		TargetInstance = to.Instance,
		SourceName = typeof(from.Pin) == "string" and from.Pin or nil,
		TargetName = typeof(to.Pin) == "string" and to.Pin or nil,
		Name = string.format(
			"%s:%s -> %s:%s",
			from.Instance.Name,
			(typeof(from.Pin) == "string" and from.Pin) or from.PinType.Name,
			to.Instance.Name,
			(typeof(to.Pin) == "string" and to.Pin) or to.PinType.Name
		),
	})
end

-- Returns the names of an instance's input or output pins, or nil when the instance can't report them.
-- Pins may come back as names or as `{ Name = ... }` tables, so both are normalized to names.
local function getPinNames(instance: Instance, method: "GetInputPins" | "GetOutputPins"): { string }?
	local ok, pins = pcall(function()
		return (instance :: any)[method](instance)
	end)

	if not ok or typeof(pins) ~= "table" then
		return nil
	end

	local names = {}
	for _, pin in pins do
		if typeof(pin) == "string" then
			table.insert(names, pin)
		elseif typeof(pin) == "table" and typeof(pin.Name) == "string" then
			table.insert(names, pin.Name)
		end
	end

	return names
end

---------------------------------------------------------------------
local AudioRouting = {}
AudioRouting.__index = AudioRouting

local tAudioRouting = t.tuple(t.Instance, t.optional(t.array(t.table)))
--[=[
	@class Routing
	@tag Base

	Represents an AudioRouting, which is used to route audio from one instance to another.
]=]

function AudioRouting.new(parent: Types.AudioMembers | Instance, pins: { Enums.EnumItem }?)
	assert(tAudioRouting(parent, pins))

	local self = {}
	self.ClassName = "AudioRouting"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our Routing container
	local AudioRouter = self._trove:Construct(Instance, "Folder")
	AudioRouter.Name = "AudioRouter"
	AudioRouter.Parent = parent
	AudioRouter:AddTag("AudioRouter")
	AudioRouter:SetAttribute("ID", HttpService:GenerateGUID(false))

	self.AudioRouter = AudioRouter

	local validPins = {}
	-- Let's figure out, if we have a valid AudioMember, if so, we will automatically figure out the pins for this member, if not, we will just use the pins that were provided to us
	if Types.tAudioMembers(parent.ClassName) then
		-- Mark our self as an AudioMember
		self.IsAudioMember = true
		self.AudioMember = parent :: Types.AudioMembers

		-- We have a valid AudioMember, let's figure out the pins for this member.
		-- If the instance can't report its pins, we allow wiring through its default pin (empty list).
		local inputPins = getPinNames(parent, "GetInputPins")
		local outputPins = getPinNames(parent, "GetOutputPins")

		if inputPins == nil or #inputPins > 0 then
			validPins[Enums.Pin.Input.Name] = inputPins or {}
		end

		if outputPins == nil or #outputPins > 0 then
			validPins[Enums.Pin.Output.Name] = outputPins or {}
		end

		-- TODO: We need to add support for AudioCompressor, which has a Sidechain pin, which is neither an input nor an output pin, it's a special pin that can only be wired to an output pin, we need to figure out how to handle this case
		if parent.ClassName == "AudioCompressor" then
			validPins[Enums.Pin.Sidechain.Name] = {}
		end
	elseif pins then
		for _, pin in pins do
			validPins[pin.Name] = {}
		end
	else
		error("AudioRouting requires either a valid AudioMember or an array of pins to function properly")
	end

	self.Pins = validPins

	return setmetatable(self :: any, AudioRouting) :: Types.AURouting
end

--[=[
	@within Routing
	Wires this AudioRouting from a given pin to another AudioRouting's pin
]=]

function AudioRouting:Wire(from: AudioRoutingPin, to: AudioRoutingPin)
	local wire

	local function isValidPinRouting(fromRoute: AudioRoutingPin, toRoute: AudioRoutingPin)
		if fromRoute.PinType == Enums.Pin.Output and toRoute.PinType == Enums.Pin.Input then
			return true
		elseif fromRoute.PinType == Enums.Pin.Input and toRoute.PinType == Enums.Pin.Output then
			return true
		elseif fromRoute.PinType == Enums.Pin.Output and toRoute.PinType == Enums.Pin.Sidechain then
			return true
		end

		return false
	end

	if not isValidPinRouting(from, to) then
		error(
			string.format(
				"Invalid pin routing from %s:%s to %s:%s, only Output > Input, or Input > Output, or Output > Sidechain",
				from.Instance.Name,
				from.Pin or from.PinType.Name,
				to.Instance.Name,
				to.Pin or to.PinType.Name
			)
		)
	end

	-- Create our wire..
	wire = CreateWire(from, to)

	-- Add the wire to our Trove so we can easily clean it up later
	self._trove:Add(wire)
end

--[=[
	@within Routing
	Wires this AudioRouting from a given AudioMember to another AudioMember, it will automatically figure out the pins to wire from and to based on the available pins on the source and target AudioMembers
]=]

function AudioRouting:WireTo(to: Types.AudioMembers, toPin: string?)
	if not self.AudioMember then
		error("Only AudioMembers can be wired to other AudioMembers, this routing is not an AudioMember")
	end

	-- Let's make sure that we have an Output pin to wire from
	if not self.Pins[Enums.Pin.Output.Name] then
		error("This AudioRouting does not have an Output pin to wire from")
	end

	-- Let's make sure that the target has an Input pin to wire to (nil = the target can't report its pins)
	local targetPins = getPinNames(to, "GetInputPins")
	if targetPins and #targetPins == 0 then
		error("The target AudioMember does not have any Input pins to wire to")
	end

	-- Validate a requested pin; without one we wire to the target's default Input pin
	if toPin and targetPins and not table.find(targetPins, toPin) then
		error(string.format("The target AudioMember does not have an Input pin named '%s'", toPin))
	end

	local wire = CreateWire(
		{ Instance = self.AudioMember, PinType = Enums.Pin.Output, Pin = nil },
		{ Instance = to, PinType = Enums.Pin.Input, Pin = toPin }
	)

	self._trove:Add(wire)
end

--[=[
	@within Routing
	Wires this AudioRouting from a given AudioMember to another AudioMember, it will automatically figure out the pins to wire from and to based on the available pins on the source and target AudioMembers
]=]

function AudioRouting:WireFrom(from: Types.AudioMembers, fromPin: string?)
	if not self.AudioMember then
		error("Only AudioMembers can be wired from other AudioMembers, this routing is not an AudioMember")
	end

	-- Let's make sure that we have an Input pin to wire to
	if not self.Pins[Enums.Pin.Input.Name] then
		error("This AudioRouting does not have an Input pin to wire to")
	end

	-- Let's make sure that the source has an Output pin to wire from (nil = the source can't report its pins)
	local sourcePins = getPinNames(from, "GetOutputPins")
	if sourcePins and #sourcePins == 0 then
		error("The source AudioMember does not have any Output pins to wire from")
	end

	-- Validate a requested pin; without one we wire from the source's default Output pin
	if fromPin and sourcePins and not table.find(sourcePins, fromPin) then
		error(string.format("The source AudioMember does not have an Output pin named '%s'", fromPin))
	end

	local wire = CreateWire(
		{ Instance = from, PinType = Enums.Pin.Output, Pin = fromPin },
		{ Instance = self.AudioMember, PinType = Enums.Pin.Input, Pin = nil }
	)

	self._trove:Add(wire)
end

--[=[
	@within Routing
	Clears all wires from a given pin on this AudioRouting
]=]

function AudioRouting:Destroy()
	self._trove:Destroy()
end

return AudioRouting
