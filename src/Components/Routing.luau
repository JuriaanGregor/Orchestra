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

---------------------------------------------------------------------
local AudioRouting = {}
AudioRouting.__index = AudioRouting

local tAudioRouting = t.tuple(t.Instance, t.optional(t.array(t.table)))
--[=[
	@class AudioRouting 
	@tag Base

	Represents an AudioRouting, which is used to route audio from one instance to another.
]=]

function AudioRouting.new(parent: Instance, pins: { Enums.EnumItem }?): Types.AURouting
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

		parent = parent :: Types.AudioMembers

		-- We have a valid AudioMember, let's figure out the pins for this member
		local inputPins = parent:GetInputPins()
		local outputPins = parent:GetOutputPins()

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
		print(parent.ClassName)
		print(Types.tAudioMembers(parent))
		print(pins)

		error("AudioRouting requires either a valid AudioMember or an array of pins to function properly")
	end

	self.Pins = validPins

	return setmetatable(self :: any, AudioRouting) :: Types.AURouting
end

function AudioRouting:WireTo(to: Types.AudioMembers)
	if not self.AudioMember then
		error("Only AudioMembers can be wired to other AudioMembers, this routing is not an AudioMember")
	end

	-- Let's make sure that we have an Output pin to wire from
	if not self.Pins[Enums.Pin.Output.Name] then
		error("This AudioRouting does not have an Output pin to wire from")
	end

	-- Let's make sure that the target has an Input pin to wire to
	local targetPins = to:GetInputPins()
	if not targetPins or #targetPins == 0 then
		error("The target AudioMember does not have any Input pins to wire to")
	end

	-- Let's create a new Wire!
	self._trove:Construct(Wire, self.AudioRouter, {
		Input = self.AudioMember,
		Output = to,
		Attributes = {
			AudioRouterId = self.AudioRouter:GetAttribute("ID") or "Unknown",
		},
	})
end

function AudioRouting:Destroy()
	self._trove:Destroy()
end

return AudioRouting
