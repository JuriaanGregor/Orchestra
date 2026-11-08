--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Types
local Types = require("../../Types")

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local Routing = require("../Routing")

-- Functions
local tAudioLimiter = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

local function CreateAudioLimiter(parent: Instance, props: { [string]: any }?): AudioLimiter
	assert(tAudioLimiter(parent, props))

	local audioLimiter = Instance.new("AudioLimiter")
	audioLimiter.Parent = parent

	-- Apply properties
	applyInstanceProps(audioLimiter, props and props or {})

	-- Return our object
	return audioLimiter
end

---------------------------------------------------------------------
local AudioLimiter = {}
AudioLimiter.__index = AudioLimiter

--[=[
	@class AudioLimiter
	@tag Transforms

	Represents an AudioLimiter. This is used to limit the audio signal to a specified threshold.
]=]

--[=[
	Creates a new AudioLimiter.
]=]

function AudioLimiter.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioLimiter(parent, props))

	-- Create a new AudioLimiter
	local self = {}
	self.Type = "Transform"
	self.ClassName = "AudioLimiter"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioLimiter Instance
	self.Instance = CreateAudioLimiter(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioLimiter) :: Types.AULimiter
end

function AudioLimiter:__tostring()
	return "AudioLimiter"
end

function AudioLimiter:Destroy()
	self._trove:Destroy()
end

return AudioLimiter
