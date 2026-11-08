--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local bindLifetime = require("../../Instances/bindLifetime")
local Routing = require("../Routing")

-- Functions
local tAudioEqualizer = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateEqualizer(parent: Instance, props: { [string]: any }?): AudioEqualizer
	assert(tAudioEqualizer(parent, props))

	local audioEqualizer = Instance.new("AudioEqualizer")
	audioEqualizer.Parent = parent

	-- Apply properties
	applyInstanceProps(audioEqualizer, props and props or {})

	-- Return our object
	return audioEqualizer
end

---------------------------------------------------------------------
local AudioEqualizer = {}
AudioEqualizer.__index = AudioEqualizer

--[=[
	@class AudioEqualizer
	@tag Effects

	Wraps an `AudioEqualizer`, a three-band (Low / Mid / High) equalizer.

	Create one with `Orchestra.Effects.new(Enums.Effect.Equalizer, parent, props)`.
]=]

--[=[
	@prop Instance AudioEqualizer
	@within AudioEqualizer
	@readonly

	The wrapped `AudioEqualizer` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioEqualizer
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioEqualizer
	@within AudioEqualizer
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioEqualizer
	@within AudioEqualizer
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	Creates a new AudioEqualizer under `parent`. Usually created through `Orchestra.Effects.new`.

	@param parent Instance -- Where the `AudioEqualizer` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioEqualizer
]=]
function AudioEqualizer.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioEqualizer(parent, props))

	-- Create a new AudioEqualizer
	local self = {}
	self.Type = "Effects"
	self.ClassName = "AudioEqualizer"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioEqualizer Instance
	self.Instance = CreateEqualizer(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioEqualizer)
end

function AudioEqualizer:__tostring()
	return "AudioEqualizer"
end

local tSetGain = t.tuple(t.union(t.literal("Low"), t.literal("Mid"), t.literal("High")), t.number)
--[=[
	Sets the gain of one band.

	@param band "Low" | "Mid" | "High" -- The band to change
	@param gain number -- The gain in decibels
]=]
function AudioEqualizer:SetGain(band: "Low" | "Mid" | "High", gain: number)
	assert(tSetGain(band, gain))

	if band == "Low" then
		self.Instance.LowGain = gain
	elseif band == "Mid" then
		self.Instance.MidGain = gain
	elseif band == "High" then
		self.Instance.HighGain = gain
	end
end

local tSetRange = t.tuple(t.numberConstrained(200, 20000), t.numberConstrained(200, 20000))
--[=[
	Sets the frequency range of the Mid band. Frequencies below it fall in the Low band, above it in the High band.

	@param minFrequency number -- Lower edge of the Mid band in Hz (200 - 20000)
	@param maxFrequency number -- Upper edge of the Mid band in Hz (200 - 20000), at least `minFrequency`
]=]
function AudioEqualizer:SetRange(minFrequency: number, maxFrequency: number)
	assert(tSetRange(minFrequency, maxFrequency))

	if maxFrequency < minFrequency then
		error("maxFrequency must be greater than or equal to minFrequency")
	end

	self.Instance.MidRange = NumberRange.new(minFrequency, maxFrequency)
end

--[=[
	Destroys the AudioEqualizer: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioEqualizer:Destroy()
	self._trove:Destroy()
end

return AudioEqualizer
