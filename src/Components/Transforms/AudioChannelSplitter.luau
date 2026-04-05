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
local tAudioChannelSplitter = t.tuple(t.Enum, t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateChannelSplitter(
	channelLayout: Enum.AudioChannelLayout,
	parent: Instance,
	props: { [string]: any }?
): AudioChannelSplitter
	assert(tAudioChannelSplitter(channelLayout, parent, props))

	local audioChannelSplitter = Instance.new("AudioChannelSplitter")
	audioChannelSplitter.Parent = parent
	audioChannelSplitter.Layout = channelLayout

	if not props then
		return audioChannelSplitter
	end

	-- Apply properties
	applyInstanceProps(audioChannelSplitter, props and props or {})

	-- Return our object
	return audioChannelSplitter
end

---------------------------------------------------------------------
local AudioChannelSplitter = {}
AudioChannelSplitter.__index = AudioChannelSplitter

--[=[
	@class AudioChannelSplitter
	@tag Transforms

	Represents an AudioChannelSplitter. This is used to split audio channels, allowing for individual channel processing.
]=]

--[=[
	Creates a new AudioChannelSplitter.
]=]

function AudioChannelSplitter.new(
	channelLayout: Enum.AudioChannelLayout,
	parent: Instance,
	props: { [string]: any }?
): Types.AUChannelSplitter
	assert(tAudioChannelSplitter(channelLayout, parent, props))

	-- Create a new AudioChannelSplitter
	local self = {}
	self.ClassName = "AudioChannelSplitter"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioChannelSplitter Instance
	self.Instance = CreateChannelSplitter(channelLayout, parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioChannelSplitter) :: Types.AUChannelSplitter
end

function AudioChannelSplitter:__tostring()
	return "AudioChannelSplitter"
end

--[=[
	Destroys the AudioChannelSplitter
]=]
function AudioChannelSplitter:Destroy()
	self._trove:Destroy()
end

return AudioChannelSplitter
