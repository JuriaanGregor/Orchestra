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
local AudioPitchShift = {}
AudioPitchShift.__index = AudioPitchShift

--[=[
	@class AudioPitchShift
	@tag Audio 
	@client 

	Represents an audio pitch shift. This is used to adjust the audio pitch shift properties.
]=]

--[=[
	Creates a new AudioPitchShift.
]=]

function AudioPitchShift.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioPitchShift(parent, props))

	-- Create a new AudioPitchShift
	local self = {}
	self.ClassName = "AudioPitchShift"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioPitchShift Instance
	self.Instance = CreatePitchShift(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioPitchShift)
end

function AudioPitchShift:__tostring()
	return "AudioPitchShift"
end

--[=[
	Destroys the AudioPitchShift.
]=]
function AudioPitchShift:Destroy()
	self._trove:Destroy()
end

return AudioPitchShift
