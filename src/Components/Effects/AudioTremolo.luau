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
local tAudioTremolo = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateTremolo(parent: Instance, props: { [string]: any }?): AudioTremolo
	assert(tAudioTremolo(parent, props))

	local audioTremolo = Instance.new("AudioTremolo")
	audioTremolo.Parent = parent

	-- Apply properties
	applyInstanceProps(audioTremolo, props and props or {})

	-- Return our object
	return audioTremolo
end

---------------------------------------------------------------------
local AudioTremolo = {}
AudioTremolo.__index = AudioTremolo

--[=[
	@class AudioTremolo
	@tag Audio 
	@client 

	Represents an audio tremolo. This is used to adjust the audio tremolo properties.
]=]

--[=[
	Creates a new AudioTremolo.
]=]

function AudioTremolo.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioTremolo(parent, props))

	-- Create a new AudioTremolo
	local self = {}
	self.ClassName = "AudioTremolo"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioTremolo Instance
	self.Instance = CreateTremolo(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioTremolo)
end

function AudioTremolo:__tostring()
	return "AudioTremolo"
end

--[=[
	Destroys the AudioTremolo.
]=]
function AudioTremolo:Destroy()
	self._trove:Destroy()
end

return AudioTremolo
