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
local tAudioDistortion = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateDistortion(parent: Instance, props: { [string]: any }?): AudioDistortion
	assert(tAudioDistortion(parent, props))

	local audioDistortion = Instance.new("AudioDistortion")
	audioDistortion.Parent = parent

	-- Apply properties
	applyInstanceProps(audioDistortion, props and props or {})

	-- Return our object
	return audioDistortion
end

---------------------------------------------------------------------
local AudioDistortion = {}
AudioDistortion.__index = AudioDistortion

--[=[
	@class AudioDistortion
	@tag Audio 
	@client 

	Represents an audio distortion. This is used to adjust the audio distortion properties.
]=]

--[=[
	Creates a new AudioDistortion.
]=]

function AudioDistortion.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioDistortion(parent, props))

	-- Create a new AudioDistortion
	local self = {}
	self.ClassName = "AudioDistortion"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioDistortion Instance
	self.Instance = CreateDistortion(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioDistortion)
end

function AudioDistortion:__tostring()
	return "AudioDistortion"
end

--[=[
	Destroys the AudioDistortion.
]=]
function AudioDistortion:Destroy()
	self._trove:Destroy()
end

return AudioDistortion
