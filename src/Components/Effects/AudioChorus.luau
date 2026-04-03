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
local tAudioChorus = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateChorus(parent: Instance, props: { [string]: any }?): AudioChorus
	assert(tAudioChorus(parent, props))

	local audioChorus = Instance.new("AudioChorus")
	audioChorus.Parent = parent

	-- Apply properties
	applyInstanceProps(audioChorus, props and props or {})

	-- Return our object
	return audioChorus
end

---------------------------------------------------------------------
local AudioChorus = {}
AudioChorus.__index = AudioChorus

--[=[
	@class AudioChorus
	@tag Audio 
	@client 

	Represents an audio chorus. This is used to adjust the audio chorus properties.
]=]

--[=[
	Creates a new AudioChorus.
]=]

function AudioChorus.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioChorus(parent, props))
	-- Create a new AudioChorus
	local self = {}
	self.ClassName = "AudioChorus"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioChorus Instance
	self.Instance = CreateChorus(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioChorus)
end

function AudioChorus:__tostring()
	return "AudioChorus"
end

--[=[
	Destroys the AudioChorus.
]=]
function AudioChorus:Destroy()
	self._trove:Destroy()
end

return AudioChorus
