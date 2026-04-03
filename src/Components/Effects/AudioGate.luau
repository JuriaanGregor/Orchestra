--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Imports > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)

-- Functions
local tAudioGate = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateGate(parent: Instance, props: { [string]: any }?): AudioGate
	assert(tAudioGate(parent, props))

	local audioGate = Instance.new("AudioGate")
	audioGate.Parent = parent

	-- Apply properties
	applyInstanceProps(audioGate, props and props or {})

	-- Return our object
	return audioGate
end

---------------------------------------------------------------------
local AudioGate = {}
AudioGate.__index = AudioGate

--[=[
	@class AudioGate
	@tag Effects

	Represents an audio gate. This is used to adjust the audio gate properties.
]=]

--[=[
	Creates a new AudioGate.
]=]

function AudioGate.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioGate(parent, props))

	-- Create a new AudioGate
	local self = {}
	self.ClassName = "AudioGate"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioGate Instance
	self.Instance = CreateGate(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioGate)
end

function AudioGate:__tostring()
	return "AudioGate"
end

--[=[
	Destroys the AudioGate.
]=]
function AudioGate:Destroy()
	self._trove:Destroy()
end

return AudioGate
