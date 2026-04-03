--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Import > Package
local Stream = require(Package.Components.Stream)
local Fader = require(Package.Components.Fader)
local Types = require(Package.Types)

---------------------------------------------------------------------
local AudioLayer = {}
AudioLayer.__index = AudioLayer

--[=[
	@class AudioLayer 
	@tag Audio 
	@client 

	Represents an AudioLayer object.
	A layer is a combination of an AudioStream and an AudioFader connected together.
]=]

local tAudioLayer = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	Creates a new AudioLayer object
]=]
function AudioLayer.new(inputType: Types.AudioStreamType, parent: Instance, props: { [string]: any }?): Types.AULayer
	assert(tAudioLayer(inputType, parent, props))

	-- Create a new AudioLayer
	local self = {}
	self.ClassName = "AudioLayer"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our Components
	self._components = {}
	self._components.AudioStream = Stream.new(inputType, parent, props)
	self._components.AudioFader = Fader.new(self._components.AudioStream.Instance, props)

	-- Create our Routing
	self.Routing = self._components.AudioFader.Routing

	-- Expose our Members
	self.Stream = self._components.AudioStream
	self.Fader = self._components.AudioFader
	self.Out = self._components.AudioFader.Out

	-- Wire our AudioStream to our AudioFader
	self.Stream.Routing:WireTo(self.Fader.In)

	return setmetatable(self :: any, AudioLayer) :: Types.AULayer
end

function AudioLayer.__tostring()
	return "AudioLayer"
end

function AudioLayer:Stop()
	self.Stream:Stop()
end

function AudioLayer:Play(completeHandler: () -> ()?)
	if completeHandler then
		self.Stream.Ended:Once(completeHandler)
	end
	self.Stream:Play()
end

--[=[
	Destroys the AudioLayer object
]=]

function AudioLayer:Destroy()
	self._trove:Destroy()
end

return AudioLayer
