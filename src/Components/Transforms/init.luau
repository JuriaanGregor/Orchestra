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
local AUDIO_TRANSFORMS: { [string]: any } = {
	[Enums.Transform.ChannelMixer.Name] = require(script.AudioChannelMixer),
	[Enums.Transform.ChannelSplitter.Name] = require(script.AudioChannelSplitter),
}

-- Functions
local tCreateTransform = t.tuple(t.string, t.Enum, t.Instance, t.optional(t.map(t.string, t.any)))
function CreateTransform(
	transformType: Types.AudioTransformType,
	layoutMode: Enum.AudioChannelLayout,
	parent: Instance,
	props: { [string]: any }?
)
	assert(tCreateTransform(transformType, layoutMode, parent, props))

	if AUDIO_TRANSFORMS[transformType] then
		return AUDIO_TRANSFORMS[transformType].new(layoutMode, parent, props)
	end

	return nil
end

---------------------------------------------------------------------
local AudioTransform = {}
AudioTransform.__index = AudioTransform

--[=[
	@class AudioTransform
	@tag Transforms

	Represnts an audio transform. This can be a channel mixer or channel splitter.
]=]

local tAudioTransform = t.tuple(t.string, t.Enum, t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	Creates a new AudioTransform. This can be a channel mixer or channel splitter.

	@param transformType Types.AudioTransformType -- The type of the transform. This can be "ChannelMixer" or "ChannelSplitter".
	@param parent Instance -- The parent of the transform.
	@param props {[string]: any}? -- A table of properties to set on the transform.
	
	@return Types.AUTransform -- The new AudioTransform.
]=]
function AudioTransform.new(
	transformType: Types.AudioTransformType,
	layoutMode: Enum.AudioChannelLayout,
	parent: Instance,
	props: { [string]: any }?
): Types.AUTransform
	assert(tAudioTransform(transformType, layoutMode, parent, props))

	-- Create a new AudioTransform
	local self = {}
	self.ClassName = "AudioTransform"
	self._trove = Trove.new()

	local AudioComponent = CreateTransform(transformType, layoutMode, parent, props)
	if not AudioComponent then
		error("Invalid transformType")
	end

	self.Routing = Routing.new(AudioComponent.Instance :: Instance, { Enums.Pin.Input, Enums.Pin.Output })
	self.TransformType = transformType
	self.Transform = AudioComponent

	-- Expose our members
	self.Instance = AudioComponent.Instance
	self.Out = self.Instance

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioTransform) :: Types.AUTransform
end

function AudioTransform:__tostring()
	return string.format("AudioTransform<%s>", self.Instance.Name)
end

--[=[
	Destroys the AudioStream.
]=]
function AudioTransform:Destroy()
	self._trove:Destroy()
end

return AudioTransform
