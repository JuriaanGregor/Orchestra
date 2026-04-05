--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Types
local Types = require(Package.Types)

-- Imports > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)
local Routing = require(Package.Components.Routing)

-- Functions
local tAudioChannelMixer = t.tuple(t.Enum, t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateAudioMixer(
	channelLayout: Enum.AudioChannelLayout,
	parent: Instance,
	props: { [string]: any }?
): AudioChannelMixer
	assert(tAudioChannelMixer(channelLayout, parent, props))

	local audioChannelMixer = Instance.new("AudioChannelMixer")
	audioChannelMixer.Parent = parent
	audioChannelMixer.Layout = channelLayout

	if not props then
		return audioChannelMixer
	end

	-- Apply properties
	applyInstanceProps(audioChannelMixer, props and props or {})

	-- Return our object
	return audioChannelMixer
end

---------------------------------------------------------------------
local AudioChannelMixer = {}
AudioChannelMixer.__index = AudioChannelMixer

--[=[
	@class AudioChannelMixer
	@tag Transforms

	Represents an AudioChannelMixer. This is used to mix audio channels, allowing for individual channel processing.
]=]

--[=[
	Creates a new AudioChannelMixer.
]=]

function AudioChannelMixer.new(
	channelLayout: Enum.AudioChannelLayout,
	parent: Instance,
	props: { [string]: any }?
): Types.AUChannelMixer
	assert(tAudioChannelMixer(channelLayout, parent, props))

	-- Create a new AudioChannelMixer
	local self = {}
	self.ClassName = "AudioChannelMixer"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioChannelMixer Instance
	self.Instance = CreateAudioMixer(channelLayout, parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioChannelMixer) :: Types.AUChannelMixer
end

function AudioChannelMixer:__tostring()
	return "AudioChannelMixer"
end

--[=[
	Destroys the AudioChannelMixer
]=]
function AudioChannelMixer:Destroy()
	self._trove:Destroy()
end

return AudioChannelMixer
