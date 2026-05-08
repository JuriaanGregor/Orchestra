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

-- Types
local Types = require(Package.Types)

-- Enums
local Enums = require(Package.Enums)

---------------------------------------------------------------------
local AudioLayer = {}
AudioLayer.__index = AudioLayer

--[=[
	@class Layer 
	@tag Base

	Represents an AudioLayer object.
	A layer is a combination of an AudioStream and an AudioFader connected together.
]=]

local tAudioLayer = t.tuple(Types.tAudioStream, t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	@within Layer
	Creates a new AudioLayer object
]=]
function AudioLayer.new(inputType: Enums.EnumItem, parent: Instance, props: { [string]: any }?): Types.AULayer
	assert(tAudioLayer(inputType.Name, parent, props))

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
	self._components.AudioStream = Stream.new(inputType, layerFolder, props)

	-- Make sure that our Fader is named props.Name with an AudioFader suffix if props.Name exists
	if props and typeof(props.Name) == "string" then
		props.Name = props.Name .. ":Fader"
	end

	self._components.AudioFader = Fader.new(self._components.AudioStream.Instance, props) :: Types.AUFader

	-- Expose our components
	self.Stream = self._components.AudioStream
	self.Fader = self._components.AudioFader

	-- Expose our members
	self.Routing = self.Fader.Routing
	self.Out = self.Fader.Out
	self.Instance = layerFolder

	-- Attach to Trove
	self._trove:AttachToInstance(layerFolder)
	self._trove:Add(self.Stream)
	self._trove:Add(self.Fader)

	-- Wire our AudioStream to our AudioFader
	self.Stream.Routing:WireTo(self.Fader.In)

	return setmetatable(self :: any, AudioLayer) :: Types.AULayer
end

function AudioLayer.__tostring()
	return "AudioLayer"
end

--[=[
	@within Layer
	Pauses the AudioLayer
]=]

function AudioLayer:Stop()
	self.Stream:Stop()
end

--[=[
	@within Layer
	Pauses the AudioLayer
]=]

function AudioLayer:Play(completeHandler: () -> ()?)
	if completeHandler then
		self.Stream.Ended:Once(completeHandler)
	end
	self.Stream:Play()
end

--[=[
	@within Layer
	Destroys the AudioLayer object
]=]

function AudioLayer:Destroy()
	self._trove:Destroy()
end

return AudioLayer
