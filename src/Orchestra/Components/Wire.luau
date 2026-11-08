--!strict

-- Roblox Services
local HttpService = game:GetService("HttpService")

-- Import > Packages
local applyInstanceProps = require("../Instances/applyInstanceProps")
local bindLifetime = require("../Instances/bindLifetime")
local Dependencies = require("../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Types
local Types = require("../Types")

-- Variables
local WIRES = {}

-- Functions
local tCreateWire = t.tuple(t.Instance, t.optional(t.Instance), t.optional(t.Instance))

local function CreateWire(parent: Instance, props: { [string]: any }): Wire
	assert(tCreateWire(parent, props.SourceInstance, props.TargetInstance))

	local wire = Instance.new("Wire")
	wire.Parent = parent

	applyInstanceProps(wire, props)

	return wire
end

---------------------------------------------------------------------
local AudioWire = {}
AudioWire.__index = AudioWire

--[=[
	@class Wire
	@tag Base

	Wraps a Roblox `Wire`, which carries audio from one instance's output pin to another's input pin.
	[Routing] creates these for you.
]=]

--[=[
	@prop Instance Wire
	@within Wire
	@readonly

	The wrapped `Wire` instance. Its `ID` attribute matches [Wire.GetWireById].
]=]

local tAudioWire = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	@within Wire
	Creates a new Wire under `parent`.

	@param parent Instance
	@param props { [string]: any }? -- `Wire` properties such as `SourceInstance`, `TargetInstance`, `SourceName` and `TargetName`, plus `Name`, `Tags` and `Attributes`
	@return Wire
]=]
function AudioWire.new(parent: Instance, props: { [string]: any }?): Types.AUWire
	assert(tAudioWire(parent, props))

	-- Create a new Audio Wire
	local self = {}
	self.ClassName = "AudioWire"

	if props then
		if props.SourceInstance then
			assert(Types.tAudioMembers(props.SourceInstance.ClassName))
		end

		if props.TargetInstance then
			assert(Types.tAudioMembers(props.TargetInstance.ClassName))
		end
	end

	-- Create our Wire instance ID, and add it to a copy of the props (so the caller's table is untouched)
	local ID = HttpService:GenerateGUID(false)

	local wireProps: { [string]: any } = if props then table.clone(props) else {}
	wireProps.Attributes = if typeof(wireProps.Attributes) == "table" then table.clone(wireProps.Attributes) else {}
	wireProps.Attributes.ID = ID

	-- Create our Wire Instance
	self.Instance = CreateWire(parent, wireProps)

	-- Create our Trove
	self._trove = Trove.new()

	self._trove:Add(self.Instance:GetPropertyChangedSignal("SourceInstance"):Connect(function()
		--self.Changed:Fire("SourceInstance", self.Instance.SourceInstance)
	end))

	self._trove:Add(self.Instance:GetPropertyChangedSignal("TargetInstance"):Connect(function()
		--self.Changed:Fire("TargetInstance", self.Instance.TargetInstance)
	end))

	self._trove:Add(function()
		WIRES[ID] = nil
	end)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance)

	-- Add our Wire our WIRES table
	WIRES[ID] = self.Instance

	return setmetatable(self :: any, AudioWire) :: Types.AUWire
end

local tGetWireById = t.tuple(t.string)
--[=[
	@within Wire
	Returns the `Wire` instance with the given `ID` attribute, if it still exists.

	@param id string
	@return Wire?
]=]
function AudioWire.GetWireById(id: string): Wire?
	assert(tGetWireById(id))
	if WIRES[id] then
		return WIRES[id]
	end

	return nil
end

function AudioWire:__tostring()
	local _input = (typeof(self.Instance.SourceInstance) == "Instance") and self.Instance.SourceInstance.Name
		or "No Input"
	local _output = (typeof(self.Instance.TargetInstance) == "Instance") and self.Instance.TargetInstance.Name
		or "No Output"

	return string.format("AudioWire<%s>: %s > %s", self.Instance.Name, _input, _output)
end

--[=[
	@within Wire
	Returns whether audio flows through the wire (both ends are set and their pins are compatible).

	@return boolean
]=]
function AudioWire:IsConnected(): boolean
	return self.Instance.Connected
end

--[=[
	@within Wire
	Destroys the Wire and its `Wire` instance.
]=]
function AudioWire:Destroy()
	self._trove:Destroy()
end

return AudioWire
