--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Import > Package
local Routing = require(Package.Components.Routing)

-- Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

-- Variables
local AUDIO_STREAMS: { [Types.AudioStreamType]: any } = {
	[Enums.Stream.Player.Name] = require(script.AudioPlayer),
	[Enums.Stream.Input.Name] = require(script.AudioDeviceInput),
	[Enums.Stream.Listener.Name] = require(script.AudioListener),
	[Enums.Stream.TextToSpeech.Name] = require(script.AudioTextToSpeech),
}

-- Functions
local tCreateStream = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateStream(
	streamType: Types.AudioStreamType,
	parent: Instance,
	props: { [string]: any }?
): (Types.AUInput | Types.AUPlayback | Types.AUListener | Types.AUTextToSpeech)?
	assert(tCreateStream(streamType, parent, props))

	if AUDIO_STREAMS[streamType] then
		return AUDIO_STREAMS[streamType].new(parent, props)
	end

	return nil
end

---------------------------------------------------------------------
local AudioStream = {}
AudioStream.__index = AudioStream

--[=[
	@class AudioStream 
	@tag Stream

	Represents an audio stream. This can be a playback stream, input stream or listener stream.
]=]

local tAudioStream = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))
--[=[
	Creates a new AudioStream. This can be a playback stream, input stream or listener stream.

	@param streamType Types.AudioStreamType -- The type of the stream. This can be "Player", "Input" or "Listener".
	@param parent Instance -- The parent of the stream.
	@param props {[string]: any}? -- A table of properties to set on the stream.

	@return Types.AUStream -- The new AudioStream.
]=]
function AudioStream.new(streamType: Types.AudioStreamType, parent: Instance, props: { [string]: any }?): Types.AUStream
	assert(tAudioStream(streamType, parent, props))

	-- Create a new AudioStream
	local self = {}
	self.ClassName = "AudioStream"
	self._trove = Trove.new()

	local AudioComponent = CreateStream(streamType, parent, props)
	if not AudioComponent then
		error("Invalid streamType")
	end

	-- Creature our Routing
	self.Routing = Routing.new(AudioComponent.Instance :: Instance, { Enums.Pin.Output })

	-- Set our Stream type
	self.StreamType = streamType

	-- Expose our members
	self.Stream = AudioComponent
	self.Instance = AudioComponent.Instance :: Instance
	self.Out = self.Instance

	if self.StreamType == Enums.Stream.Player then
		self.Ended = (self.Stream :: Types.AUPlayback).Ended
		self.Looped = (self.Stream :: Types.AUPlayback).Looped
		self.Loaded = (self.Stream :: Types.AUPlayback).Loaded
		self.Changed = (self.Stream :: Types.AUPlayback).Changed
	elseif self.StreamType == Enums.Stream.TextToSpeech then
		self.Ended = (self.Stream :: Types.AUTextToSpeech).Ended
		self.Looped = (self.Stream :: Types.AUTextToSpeech).Looped
	end

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioStream) :: Types.AUStream
end

function AudioStream:__tostring()
	return string.format("AudioStream<%s>", self.Instance.Name)
end

--[=[
	@within AudioStream

	Plays the audio stream. This only works for playback streams.
]=]
function AudioStream:Play()
	if self.Stream["Play"] then
		return self.Stream:Play()
	else
		error(string.format("AudioStream<%s> does not have a Play method", self.StreamType))
	end
end

--[=[
	@within AudioStream

	Stops the AudioStream. This only works for playback streams.
]=]
function AudioStream:Stop()
	if self.Stream["Stop"] then
		self.Stream:Stop()
	else
		error(string.format("AudioStream<%s> does not have a Stop method", self.StreamType))
	end
end

--[=[
	@within AudioStream

	Pauses the AudioStream. This only works for playback streams.
]=]
function AudioStream:Pause()
	if self.Stream["Pause"] then
		self.Stream:Pause()
	else
		error(string.format("AudioStream<%s> does not have a Pause method", self.StreamType))
	end
end

--[=[
	Destroys the AudioStream.
]=]
function AudioStream:Destroy()
	self._trove:Destroy()
end

return AudioStream
