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
local AUDIO_TRANSFORMS: { [string]: any } = {
	["ChannelMixer"] = require(script.AudioChannelMixer),
	["ChannelSplitter"] = require(script.AudioChannelSplitter),
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

	if transformType == "ChannelMixer" then
		local audioMixer = AUDIO_TRANSFORMS[transformType]

		return audioMixer.new(layoutMode, parent, props)
	elseif transformType == "ChannelSplitter" then
		local audioSplitter = AUDIO_TRANSFORMS[transformType]

		return audioSplitter.new(layoutMode, parent, props)
	else
		error("Invalid audioTransform")
	end
end

---------------------------------------------------------------------
local AudioTransform = {}
AudioTransform.__index = AudioTransform

--[=[
	@class AudioTransform
	@tag Audio
	@client 

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

	self.Routing = Routing.new(AudioComponent.Instance :: Instance, { "Output" })
	self.TransformType = transformType
	self.Transform = AudioComponent
	self.Instance = AudioComponent.Instance
	self.Out = self.Instance

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
