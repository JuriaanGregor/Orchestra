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
local function CreateWire(parent: Instance, input: Instance?, output: Instance?): Wire
	assert(tCreateWire(parent, input, output))

	if input then
		assert(tAudioMember(input.ClassName))
	end

	if output then
		assert(tAudioMember(output.ClassName))
	end

	local Wire = Instance.new("Wire")
	Wire.Name = "AudioWire"
	Wire.Parent = parent

	if input then
		Wire.SourceInstance = input
	end

	if output then
		Wire.TargetInstance = output
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

local tAudioWire = t.tuple(t.Instance, t.optional(t.Instance), t.optional(t.Instance))

--[=[
	Creates a new AudioWire
]=]
function AudioWire.new(parent: Instance, input: Instance?, output: Instance?): Types.AUWire
	assert(tAudioWire(parent, input, output))

	if input then
		assert(tAudioMember(input.ClassName))
	end

	if output then
		assert(tAudioMember(output.ClassName))
	end

	-- Create a new Audio Wire
	local self = {}
	self.ClassName = "AudioWire"

	-- Create our Wire Instance & ID
	self.Instance = CreateWire(parent, input, output)
	self.ID = HttpService:GenerateGUID(false)

	-- Create our Trove
	self._trove = Trove.new()

	-- Signals
	self.Changed = self._trove:Construct(Signal)

	-- Add our ID to our Wire
	self.Instance:SetAttribute("ID", self.ID)

	-- Set the AudioWire tag
	self.Instance:AddTag("AudioWire")

	self._trove:Add(self.Instance:GetPropertyChangedSignal("SourceInstance"):Connect(function()
		self.Changed:Fire("SourceInstance", self.Instance.SourceInstance)
	end))

	self._trove:Add(self.Instance:GetPropertyChangedSignal("TargetInstance"):Connect(function()
		self.Changed:Fire("TargetInstance", self.Instance.TargetInstance)
	end))

	self._trove:Add(function()
		WIRES[self.ID] = nil
	end)

	self._trove:AttachToInstance(self.Instance)

	-- Add our Wire our WIRES table
	WIRES[self.ID] = self.Instance

	return setmetatable(self :: any, AudioWire) :: Types.AUWire
end

local tGetWireById = t.tuple(t.string)
--[=[
	Gets an AudioWire by its ID
]=]

function AudioWire:GetWireById(id: string): Wire?
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
