--!strict

-- Import > Packages
local Dependencies = require("../Dependencies")
local t = Dependencies.t

-- Types
local Types = require("../Types")

-- Enums
local Enums = require("../Enums")

-- Variables
local AUDIO_TRANSFORMS: { [string]: any } = {
	[Enums.Transform.ChannelMixer.Name] = require("@self/AudioChannelMixer"),
	[Enums.Transform.ChannelSplitter.Name] = require("@self/AudioChannelSplitter"),
	[Enums.Transform.Limiter.Name] = require("@self/AudioLimiter"),
	[Enums.Transform.Gate.Name] = require("@self/AudioGate"),
}

-- Functions
local tCreateTransform = t.tuple(t.string, t.Instance, t.optional(t.map(t.string, t.any)))
function CreateTransform(transformType: Enums.EnumItem, parent: Instance, props: { [string]: any }?)
	assert(tCreateTransform(transformType.Name, parent, props))

	if not AUDIO_TRANSFORMS[transformType.Name] then
		error("Invalid transform type")
	end

	return AUDIO_TRANSFORMS[transformType.Name].new(parent, props)
end

---------------------------------------------------------------------
--[=[
	@class Transforms
	@tag Transforms

	Creates transform components: [AudioChannelMixer], [AudioChannelSplitter], [AudioGate] and [AudioLimiter]. Reached through `Orchestra.Transforms`.

	```lua
	Orchestra.Transforms.new(Enums.Transform.ChannelSplitter, speaker, { Layout = Enum.AudioChannelLayout.Stereo })
	```
]=]
local AudioTransforms = {}
AudioTransforms.__index = AudioTransforms

--[=[
	@within Transforms
	Creates a component of type `transformType`.

	@param transformType EnumItem -- One of [Enums.Transform]
	@param parent Instance -- Where the instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return any -- The component, see the classes listed above
]=]
function AudioTransforms.new(
	transformType: Enums.EnumItem,
	parent: Instance,
	props: { [string]: any }?
): Types.AUTransform
	assert(tCreateTransform(transformType.Name, parent, props))

	return CreateTransform(transformType, parent, props)
end

return AudioTransforms
