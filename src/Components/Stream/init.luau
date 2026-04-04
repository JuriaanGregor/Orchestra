--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Import > Package
local Routing = require(Package.Components.Routing)
local Types = require(Package.Types)

-- Variables
local AUDIO_STREAMS: { [Types.AudioStreamType]: any } = {
	["Player"] = require(script.AudioPlayer),
	["Input"] = require(script.AudioDeviceInput),
	["Listener"] = require(script.AudioListener),
	["TextToSpeech"] = require(script.AudioTextToSpeech),
}

-- Functions
local tCreateStream = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateStream(
	streamType: Types.AudioStreamType,
	parent: Instance,
	props: { [string]: any }?
): (Types.AUInput | Types.AUPlayback | Types.AUListener | Types.AUTextToSpeech)?
	assert(tCreateStream(streamType, parent, props))

	if streamType == "Player" then
		local AudioPlayer = AUDIO_STREAMS[streamType]
		return AudioPlayer.new(parent, props) :: Types.AUPlayback
	elseif streamType == "Input" then
		local AudioDeviceInput = AUDIO_STREAMS[streamType]
		return AudioDeviceInput.new(parent, props) :: Types.AUInput
	elseif streamType == "Listener" then
		local AudioListener = AUDIO_STREAMS[streamType]
		return AudioListener.new(parent, props) :: Types.AUListener
	elseif streamType == "TextToSpeech" then
		local AudioTextToSpeech = AUDIO_STREAMS[streamType]
		return AudioTextToSpeech.new(parent, props) :: Types.AUTextToSpeech
	else
		error(string.format("Invalid streamType: %s", streamType))
	end
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

	self.Routing = Routing.new(AudioComponent.Instance :: Instance, { "Output" })
	self.StreamType = streamType
	self.Stream = AudioComponent
	self.Instance = AudioComponent.Instance :: Instance
	self.Out = self.Instance

	if self.StreamType == "Player" then
		self.Ended = (self.Stream :: Types.AUPlayback).Ended
		self.Looped = (self.Stream :: Types.AUPlayback).Looped
		self.Loaded = (self.Stream :: Types.AUPlayback).Loaded
		self.Changed = (self.Stream :: Types.AUPlayback).Changed
	elseif self.StreamType == "TextToSpeech" then
		self.Ended = (self.Stream :: Types.AUTextToSpeech).Ended
		self.Looped = (self.Stream :: Types.AUTextToSpeech).Looped
	end

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
