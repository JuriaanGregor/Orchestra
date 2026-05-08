--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Imports > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)
local Routing = require(Package.Components.Routing)

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

	Represents an audio equalizer. This is used to adjust the audio frequencies.
]=]

--[=[
	Creates a new AudioEqualizer.
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

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioEqualizer)
end

function AudioEqualizer:__tostring()
	return "AudioEqualizer"
end

local tSetGain = t.tuple(t.union(t.literal("Low"), t.literal("Mid"), t.literal("High")), t.number)
--[=[
    Sets the gain for a specific band.

    @param bandIndex "Low" | "Mid" | "High" -- The band to set the gain for.
    @param gain number -- The gain value to set.
]=]

function AudioEqualizer:SetGain(bandIndex: "Low" | "Mid" | "High", gain: number)
	assert(tSetGain(bandIndex, gain))

	if bandIndex == "Low" then
		self.Instance.LowGain = gain
	elseif bandIndex == "Mid" then
		self.Instance.MidGain = gain
	elseif bandIndex == "High" then
		self.Instance.HighGain = gain
	end
end

local tSetRange = t.tuple(t.numberConstrained(200, 20000), t.numberConstrained(200, 20000))
--[=[
    Sets the frequency range for the mid band.

    @param minFrequency number -- The minimum frequency for the mid band.
    @param maxFrequency number -- The maximum frequency for the mid band.
]=]
function AudioEqualizer:SetRange(minFrequency: number, maxFrequency: number)
	assert(tSetRange(minFrequency, maxFrequency))

	if maxFrequency < minFrequency then
		error("maxFrequency must be greater than or equal to minFrequency")
	end

	self.Instance.MidRange = NumberRange.new(minFrequency, maxFrequency)
end

--[=[
	Destroys the AudioEqualizer.
]=]
function AudioEqualizer:Destroy()
	self._trove:Destroy()
end

return AudioEqualizer
