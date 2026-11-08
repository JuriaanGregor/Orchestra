--!strict

-- Import > Packages
local Dependencies = require("../Dependencies")
local t = Dependencies.t

-- Types
local Types = require("../Types")

-- Enums
local Enums = require("../Enums")

-- Variables
local AUDIO_STREAMS = {
	[Enums.Stream.Player.Name] = require("@self/AudioPlayer"),
	[Enums.Stream.Input.Name] = require("@self/AudioDeviceInput"),
	[Enums.Stream.Listener.Name] = require("@self/AudioListener"),
	[Enums.Stream.TextToSpeech.Name] = require("@self/AudioTextToSpeech"),
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
--[=[
	@class Stream
	@tag Stream

	Creates stream (source) components: [AudioPlayer], [AudioDeviceInput], [AudioListener] and [AudioTextToSpeech]. Reached through `Orchestra.Stream`.

	```lua
	Orchestra.Stream.new(Enums.Stream.Player, speaker, { Asset = "rbxassetid://15287092994" })
	```
]=]
local AudioStream = {}
AudioStream.__index = AudioStream

local tAudioStream = t.tuple(t.table, t.Instance, t.optional(t.map(t.string, t.any)))
--[=[
	@within Stream
	Creates a component of type `streamType`.

	@param streamType EnumItem -- One of [Enums.Stream]
	@param parent Instance -- Where the instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return any -- The component, see the classes listed above
]=]
function AudioStream.new(streamType: Enums.EnumItem, parent: Instance, props: { [string]: any }?): Types.AUStream
	assert(tAudioStream(streamType, parent, props))

	return CreateStream(streamType, parent, props)
end

return AudioStream
