--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Import > Components
local Wire = require(Package.Components.Wire)

-- Base Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

-- Types
type AudioRoute = {
	Instance: Types.AudioMembers,
	Pin: string?,
}

export type AudioRoutingPin = {
	Instance: Types.AudioMembers,
	PinType: "Input" | "Output" | "Sidechain",
	Pin: string?,
}

local function CreateWire(from: AudioRoutingPin, to: AudioRoutingPin): Wire
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
			from.Pin or "Default",
			to.Instance.Name,
			to.Pin or "Default"
		),
		Attributes = {
			ID = HttpService:GenerateGUID(false),
		},
	})
end

---------------------------------------------------------------------
local AudioRouting = {}
AudioRouting.__index = AudioRouting

local tAudioRouting = t.tuple(t.Instance, t.optional(t.array(t.table)))
--[=[
	@class AudioRouting 
	@tag Base

	Represents an AudioRouting, which is used to route audio from one instance to another.
]=]

function AudioRouting.new(parent: Types.AudioMembers | Instance, pins: { Enums.EnumItem }?): Types.AURouting
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

		-- We have a valid AudioMember, let's figure out the pins for this member
		local inputPins = self.AudioMember:GetInputPins()
		local outputPins = self.AudioMember:GetOutputPins()

		if inputPins and #inputPins > 0 then
			validPins[Enums.Pin.Input.Name] = {}
			for _, pin in inputPins do
				table.insert(validPins[Enums.Pin.Input.Name], pin)
			end
		end

		if outputPins and #outputPins > 0 then
			validPins[Enums.Pin.Output.Name] = {}
			for _, pin in outputPins do
				table.insert(validPins[Enums.Pin.Output.Name], pin)
			end
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
				from.Pin,
				to.Instance.Name,
				to.Pin
			)
		)
	end

	-- Create our wire..
	wire = CreateWire(from, to)

	-- Add the wire to our Trove so we can easily clean it up later
	self._trove:Add(wire)
end

function AudioRouting:WireTo(to: Types.AudioMembers, toPin: string?)
	if not self.AudioMember then
		error("Only AudioMembers can be wired to other AudioMembers, this routing is not an AudioMember")
	end

	-- Let's make sure that we have an Output pin to wire from
	if not self.Pins[Enums.Pin.Output.Name] then
		error("This AudioRouting does not have an Output pin to wire from")
	end

	-- Let's make sure that the target has an Input pin to wire to
	local targetPins = to:GetInputPins()
	if not targetPins or not next(targetPins) then
		error("The target AudioMember does not have any Input pins to wire to")
	end

	-- If we don't have a valid toPin, let's just wire to the first available Input pin on the target
	if toPin and not table.find(targetPins, toPin) then
		error("The target AudioMember does not have the specified Input pin to wire to")
	else
		toPin = targetPins[1]
	end

	local wire = CreateWire(
		{ Instance = self.AudioMember, PinType = Enums.Pin.Output.Name, Pin = nil },
		{ Instance = to, PinType = Enums.Pin.Input.Name, Pin = typeof(toPin) == "string" and toPin or nil }
	)

	self._trove:Add(wire)
end

function AudioRouting:WireFrom(from: Types.AudioMembers, fromPin: string?)
	if not self.AudioMember then
		error("Only AudioMembers can be wired from other AudioMembers, this routing is not an AudioMember")
	end

	-- Let's make sure that we have an Input pin to wire to
	if not self.Pins[Enums.Pin.Input.Name] then
		error("This AudioRouting does not have an Input pin to wire to")
	end

	-- Let's make sure that the source has an Output pin to wire from
	local sourcePins = from:GetOutputPins()
	if not sourcePins or not next(sourcePins) then
		error("The source AudioMember does not have any Output pins to wire from")
	end

	-- If we don't have a valid fromPin, let's just wire from the first available Output pin on the source
	if fromPin and not table.find(sourcePins, fromPin) then
		error("The source AudioMember does not have the specified Output pin to wire from")
	else
		fromPin = sourcePins[1]
	end

	local wire = CreateWire(
		{ Instance = from, PinType = Enums.Pin.Output, Pin = typeof(fromPin) == "string" and fromPin or nil },
		{ Instance = self.AudioMember, PinType = Enums.Pin.Input, Pin = typeof(fromPin) == "string" and fromPin or nil }
	)

	self._trove:Add(wire)
end

function AudioRouting:Destroy()
	self._trove:Destroy()
end

return AudioRouting
