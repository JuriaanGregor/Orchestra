--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)

-- Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

-- Variables
local AUDIO_STREAMS = {
	[Enums.Stream.Player.Name] = require(script.AudioPlayer),
	[Enums.Stream.Input.Name] = require(script.AudioDeviceInput),
	[Enums.Stream.Listener.Name] = require(script.AudioListener),
	[Enums.Stream.TextToSpeech.Name] = require(script.AudioTextToSpeech),
} :: { [string]: any }

-- Functions
local tCreateStream = t.tuple(Types.tAudioStream, t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateStream(streamType: Enums.EnumItem, parent: Instance, props: { [string]: any }?)
	assert(tCreateStream(streamType.Name, parent, props))

	if not AUDIO_STREAMS[streamType.Name] then
		error("Invalid stream type")
	end

	return AUDIO_STREAMS[streamType.Name].new(parent, props)
end

---------------------------------------------------------------------
local AudioStream = {}
AudioStream.__index = AudioStream

local tAudioStream = t.tuple(t.table, t.Instance, t.optional(t.map(t.string, t.any)))
function AudioStream.new(streamType: Enums.EnumItem, parent: Instance, props: { [string]: any }?): Types.AUStream
	assert(tAudioStream(streamType, parent, props))

	return CreateStream(streamType, parent, props)
end

return AudioStream
