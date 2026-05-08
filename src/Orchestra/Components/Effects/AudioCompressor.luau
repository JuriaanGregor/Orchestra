--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Enums
local Enums = require(Package.Enums)

-- Imports > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)
local Routing = require(Package.Components.Routing)

-- Functions
local tAudioCompressor = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateCompressor(parent: Instance, props: { [string]: any }?): AudioCompressor
	assert(tAudioCompressor(parent, props))

	local audioCompressor = Instance.new("AudioCompressor")
	audioCompressor.Parent = parent

	-- Apply properties
	applyInstanceProps(audioCompressor, props and props or {})

	return audioCompressor
end

---------------------------------------------------------------------
local AudioCompressor = {}
AudioCompressor.__index = AudioCompressor

--[=[
	@class AudioCompressor
	@tag Effects

	Represents an audio compressor. This is used to adjust the audio compressor properties.
]=]

--[=[
	Creates a new AudioCompressor.
]=]

function AudioCompressor.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioCompressor(parent, props))

	-- Create a new AudioCompressor
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioCompressor"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioCompressor Instance
	self.Instance = CreateCompressor(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance, { Enums.Pin.Input, Enums.Pin.Output, Enums.Pin.Sidechain })

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioCompressor)
end

function AudioCompressor:__tostring()
	return "AudioCompressor"
end

--[=[
	Destroys the AudioCompressor.
]=]
function AudioCompressor:Destroy()
	self._trove:Destroy()
end

return AudioCompressor
