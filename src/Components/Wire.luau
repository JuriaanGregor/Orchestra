--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local applyInstanceProps = require("../Instances/applyInstanceProps")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)
local Signal = require(Package.Packages.Signal)

-- Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

-- Variables
local WIRES = {}

-- Functions
local tCreateWire = t.tuple(t.Instance, t.optional(t.Instance), t.optional(t.Instance))

local audioMembers = {}
for _, item in ipairs(Enums.AudioMembers:GetEnumItems()) do
	table.insert(audioMembers, item.Name)
end

local tAudioMember = t.valueOf(audioMembers)

local function CreateWire(parent: Instance, props: { [string]: any }): Wire
	assert(tCreateWire(parent, props and props.Input, props and props.Output))

	local Wire = Instance.new("Wire")
	Wire.Parent = parent

	applyInstanceProps(Wire, props and props or {})

	return Wire
end

---------------------------------------------------------------------
local AudioWire = {}
AudioWire.__index = AudioWire

--[=[
	@class AudioWire
	@tag Base

	Represents an AudioWire that connects two Audio Instances together.
]=]

local tAudioWire = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	Creates a new AudioWire
]=]
function AudioWire.new(parent: Instance, props: { [string]: any }?): Types.AUWire
	assert(tAudioWire(parent, props))

	-- Create a new Audio Wire
	local self = {}
	self.ClassName = "AudioWire"

	if props then
		if props.SourceInstance then
			assert(tAudioMember(props.SourceInstance.ClassName))
		end

		if props.TargetInstance then
			assert(tAudioMember(props.TargetInstance.ClassName))
		end
	end

	-- Creature our Wire instance ID..
	local ID = HttpService:GenerateGUID(false)

	-- Apply it to our props so it can be used in our Create Wire function
	if props and props.Attributes and typeof(props.Attributes) == "table" then
		props.Attributes.ID = ID
	elseif props then
		if props.Attributes and typeof(props.Attributes) == "table" then
			props.Attributes.ID = ID
		else
			props.Attributes = { ID = ID }
		end
	end

	-- Create our Wire Instance
	self.Instance = CreateWire(parent, typeof(props) == "table" and props or {})

	-- Create our Trove
	self._trove = Trove.new()

	-- Signals
	self.Changed = self._trove:Construct(Signal)

	self._trove:Add(self.Instance:GetPropertyChangedSignal("SourceInstance"):Connect(function()
		self.Changed:Fire("SourceInstance", self.Instance.SourceInstance)
	end))

	self._trove:Add(self.Instance:GetPropertyChangedSignal("TargetInstance"):Connect(function()
		self.Changed:Fire("TargetInstance", self.Instance.TargetInstance)
	end))

	self._trove:Add(function()
		WIRES[ID] = nil
	end)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	-- Add our Wire our WIRES table
	WIRES[ID] = self.Instance

	return setmetatable(self :: any, AudioWire) :: Types.AUWire
end

local tGetWireById = t.tuple(t.string)
--[=[
	Gets an AudioWire by its ID
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
    Checks if the AudioWire is connected
]=]
function AudioWire:IsConnected(): boolean
	return self.Instance.Connected
end

--[=[
	Destroys the AudioWire
]=]
function AudioWire:Destroy()
	self._trove:Destroy()
end

return AudioWire
