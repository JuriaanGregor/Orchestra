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
local tAudioReverb = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateReverb(parent: Instance, props: { [string]: any }?): AudioReverb
	assert(tAudioReverb(parent, props))

	local audioReverb = Instance.new("AudioReverb")
	audioReverb.Parent = parent

	-- Apply properties
	applyInstanceProps(audioReverb, props and props or {})

	-- Return our object
	return audioReverb
end

---------------------------------------------------------------------
local AudioReverb = {}
AudioReverb.__index = AudioReverb

--[=[
	@class AudioReverb
	@tag Effects

	Represents an audio reverb. This is used to adjust the audio reverb properties.
]=]

--[=[
	Creates a new AudioReverb.
]=]

function AudioReverb.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioReverb(parent, props))

	-- Create a new AudioReverb
	local self = {}
	self.ClassName = "AudioReverb"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioReverb Instance
	self.Instance = CreateReverb(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioReverb)
end

function AudioReverb:__tostring()
	return "AudioReverb"
end

--[=[
	Destroys the AudioReverb.
]=]
function AudioReverb:Destroy()
	self._trove:Destroy()
end

return AudioReverb
