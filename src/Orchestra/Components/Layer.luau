--!strict

-- Import > Packages
local Dependencies = require("../Dependencies")
local bindLifetime = require("../Instances/bindLifetime")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Import > Package
local Stream = require("./Stream")
local Fader = require("./Fader")

-- Enums
local Enums = require("../Enums")

---------------------------------------------------------------------
local AudioLayer = {}
AudioLayer.__index = AudioLayer

--[=[
	@class Layer
	@tag Base

	A stream and a [Fader], wired together: the main building block for a single sound.
	Wire the Layer onwards through its `Routing`, which belongs to its Fader.

	```lua
	local music = Orchestra.Layer.new(Enums.Stream.Player, speaker, {
		Name = "Music",
		Asset = "rbxassetid://15287092994",
	})

	music.Routing:WireTo(emitter.In)
	music:Play()
	```
]=]

--[=[
	@prop Instance Folder
	@within Layer
	@readonly

	The `AudioLayer` folder holding the stream instance.
]=]

--[=[
	@prop Stream AudioPlayer | AudioDeviceInput | AudioListener | AudioTextToSpeech
	@within Layer
	@readonly

	The Layer's stream component.
]=]

--[=[
	@prop Fader Fader
	@within Layer
	@readonly

	The Layer's [Fader], wired after the stream.
]=]

--[=[
	@prop Routing Routing
	@within Layer
	@readonly

	The Fader's [Routing], used to wire the Layer onwards.
]=]

--[=[
	@prop Out AudioFader
	@within Layer
	@readonly

	The instance to wire from (the Fader's instance).
]=]

local tAudioLayer = t.tuple(t.any, t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	@within Layer
	Creates a new Layer: a stream of type `streamType` in an `AudioLayer` folder under `parent`, wired into a Fader.

	@param streamType EnumItem -- One of [Enums.Stream]
	@param parent Instance -- Where the `AudioLayer` folder is created
	@param props { [string]: any }? -- Passed to the stream (see its `new`). The Fader gets the same `Name` with a `:Fader` suffix
	@return Layer
]=]
function AudioLayer.new(streamType: Enums.EnumItem, parent: Instance, props: { [string]: any }?)
	assert(tAudioLayer(streamType.Name, parent, props))

	-- Create a new AudioLayer
	local self = {}
	self.Type = "Base"
	self.ClassName = "AudioLayer"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioLayer folder
	local layerFolder = Instance.new("Folder")
	layerFolder.Name = "AudioLayer"
	layerFolder.Parent = parent

	-- Create our Components
	self._components = {}
	self._components.AudioStream = Stream.new(streamType, layerFolder, if props then table.clone(props) else nil)

	-- Make sure that our Fader is named props.Name with an AudioFader suffix if props.Name exists
	local faderProps = if props then table.clone(props) else nil
	if faderProps and typeof(faderProps.Name) == "string" then
		faderProps.Name = faderProps.Name .. ":Fader"
	end

	self._components.AudioFader = Fader.new(self._components.AudioStream.Instance, faderProps)

	-- Expose our components
	self.Stream = self._components.AudioStream
	self.Fader = self._components.AudioFader

	-- Expose our members
	self.Routing = self.Fader.Routing
	self.Out = self.Fader.Out
	self.Instance = layerFolder

	-- Destroy our stream and fader first, then the folder. Destroying the folder cleans us up too.
	self._trove:Add(self.Stream)
	self._trove:Add(self.Fader)
	bindLifetime(self._trove, layerFolder)

	-- Wire our AudioStream to our AudioFader
	self.Stream.Routing:WireTo(self.Fader.In)

	return setmetatable(self :: any, AudioLayer)
end

function AudioLayer.__tostring()
	return "AudioLayer"
end

--[=[
	@within Layer
	Stops the stream.
]=]
function AudioLayer:Stop()
	self.Stream:Stop()
end

--[=[
	@within Layer
	Plays the stream.

	@param onEnded (() -> ())? -- Called once when the stream's `Ended` event fires
]=]
function AudioLayer:Play(onEnded: () -> ()?)
	if onEnded then
		self.Stream.Ended:Once(onEnded)
	end
	self.Stream:Play()
end

--[=[
	@within Layer
	Destroys the Layer: its stream, its Fader (and their wires) and its `AudioLayer` folder.
]=]
function AudioLayer:Destroy()
	self._trove:Destroy()
end

return AudioLayer
