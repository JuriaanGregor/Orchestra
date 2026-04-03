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
local tAudioFlanger = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateFlanger(parent: Instance, props: { [string]: any }?): AudioFlanger
	assert(tAudioFlanger(parent, props))

	local audioFlanger = Instance.new("AudioFlanger")
	audioFlanger.Parent = parent

	-- Apply properties
	applyInstanceProps(audioFlanger, props and props or {})

	-- Return our object
	return audioFlanger
end

---------------------------------------------------------------------
local AudioFlanger = {}
AudioFlanger.__index = AudioFlanger

--[=[
	@class AudioFlanger
	@tag Effects

	Represents an audio flanger. This is used to adjust the audio flanger properties.
]=]

--[=[
	Creates a new AudioFlanger.
]=]

function AudioFlanger.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioFlanger(parent, props))

	-- Create a new AudioFlanger
	local self = {}
	self.ClassName = "AudioFlanger"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioFlanger Instance
	self.Instance = CreateFlanger(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioFlanger)
end

function AudioFlanger:__tostring()
	return "AudioFlanger"
end

--[=[
	Destroys the AudioFlanger.
]=]
function AudioFlanger:Destroy()
	self._trove:Destroy()
end

return AudioFlanger
