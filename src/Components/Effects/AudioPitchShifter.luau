--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Imports > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)
local Routing = require(Package.Components.Routing)

-- Functions
local tAudioPitchShift = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreatePitchShift(parent: Instance, props: { [string]: any }?): AudioPitchShifter
	assert(tAudioPitchShift(parent, props))

	local audioPitchShift = Instance.new("AudioPitchShifter")
	audioPitchShift.Parent = parent

	-- Apply properties
	applyInstanceProps(audioPitchShift, props and props or {})

	-- Return our object
	return audioPitchShift
end

---------------------------------------------------------------------
local AudioPitchShifter = {}
AudioPitchShifter.__index = AudioPitchShifter

--[=[
	@class AudioPitchShifter
	@tag Effects

	Represents an audio pitch shifter. This is used to adjust the audio pitch shifter properties.
]=]

--[=[
	Creates a new AudioPitchShift.
]=]

function AudioPitchShifter.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioPitchShift(parent, props))

	-- Create a new AudioPitchShift
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioPitchShifter"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioPitchShifter Instance
	self.Instance = CreatePitchShift(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioPitchShifter)
end

function AudioPitchShifter:__tostring()
	return "AudioPitchShifter"
end

--[=[
	Destroys the AudioPitchShifter.
]=]
function AudioPitchShifter:Destroy()
	self._trove:Destroy()
end

return AudioPitchShifter
