--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local Routing = require("../Routing")

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
	@tag Effects

	Represents an audio chorus. This is used to adjust the audio chorus properties.
]=]

--[=[
	Creates a new AudioChorus.
]=]

function AudioChorus.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioChorus(parent, props))
	-- Create a new AudioChorus
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioChorus"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioChorus Instance
	self.Instance = CreateChorus(parent, props)

	-- Routing
	self.Routing = Routing.new(self.Instance)

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
