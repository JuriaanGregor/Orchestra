--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)
local Signal = require(Package.Packages.Signal)

-- Import > Package
local Types = require(Package.Types)

-- Variables
local WIRES = {}

-- Functions
local tCreateWire = t.tuple(t.Instance, t.optional(t.Instance), t.optional(t.Instance))
local tAudioMember = t.valueOf(Types.AudioChildren)
local function CreateWire(parent: Instance, props: { [string]: any }): Wire
	assert(tCreateWire(parent, props and props.Input, props and props.Output))

	if props.Input then
		assert(tAudioMember(props.Input.ClassName))
	end

	if props.Output then
		assert(tAudioMember(props.Output.ClassName))
	end

	local Wire = Instance.new("Wire")
	Wire.Name = "AudioWire"
	Wire.Parent = parent

	if props.Input then
		Wire.SourceInstance = props.Input
	end

	if props.Output then
		Wire.TargetInstance = props.Output
	end

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
		if not props.Input then
			assert(tAudioMember(props.Input.ClassName))
		end

		if props.Output then
			assert(tAudioMember(props.Output.ClassName))
		end
	end

	-- Creature our Wire instance ID..
	local ID = HttpService:GenerateGUID(false)

	-- Apply it to our props so it can be used in our CreateWire function
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
