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
local tAudioEcho = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateEcho(parent: Instance, props: { [string]: any }?): AudioEcho
	assert(tAudioEcho(parent, props))

	local audioEcho = Instance.new("AudioEcho")
	audioEcho.Parent = parent

	-- Apply properties
	applyInstanceProps(audioEcho, props and props or {})

	-- Return our object
	return audioEcho
end

---------------------------------------------------------------------
local AudioEcho = {}
AudioEcho.__index = AudioEcho

--[=[
	@class AudioEcho
	@tag Effects

	Represents an audio echo. This is used to adjust the audio echo properties.
]=]

--[=[
	Creates a new AudioEcho.
]=]

function AudioEcho.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioEcho(parent, props))

	-- Create a new AudioEcho
	local self = {}
	self.ClassName = "AudioEcho"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioEcho Instance
	self.Instance = CreateEcho(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioEcho)
end

function AudioEcho:__tostring()
	return "AudioEcho"
end

--[=[
	Destroys the AudioEcho.
]=]
function AudioEcho:Destroy()
	self._trove:Destroy()
end

return AudioEcho
