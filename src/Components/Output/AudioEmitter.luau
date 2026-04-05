--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Types
local Types = require(Package.Types)

-- Imports > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)
local Routing = require(Package.Components.Routing)

-- Functions
local tAudioEmitter = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateAudioEmitter(parent: Instance, props: { [string]: any }?): AudioEmitter
	assert(tAudioEmitter(parent, props))

	local emitter = Instance.new("AudioEmitter")
	emitter.Parent = parent

	if not props then
		return emitter
	end

	if props.DistanceAttenuation then
		emitter:SetDistanceAttenuation(props.DistanceAttenuation)
		props.DistanceAttenuation = nil
	end

	if props.AudioInteractionGroup then
		emitter.AudioInteractionGroup = props.AudioInteractionGroup
		props.AudioInteractionGroup = nil
	end

	-- Apply properties
	applyInstanceProps(emitter, props)

	-- Return our object
	return emitter
end

---------------------------------------------------------------------
local AudioEmitter = {}
AudioEmitter.__index = AudioEmitter

--[=[
	@class AudioEmitter
	@tag Output

	Represents an Audio Emitter. This is used to play 3D sounds in the world attached to a transform
]=]

--[=[
	Creates a new AudioEmitter
]=]

function AudioEmitter.new(parent: Instance, props: { [string]: any }?): Types.AUEmitter
	assert(tAudioEmitter(parent, props))

	local self = {}
	self.ClassName = "AudioEmitter"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioEmitter Instance
	self.Instance = CreateAudioEmitter(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Expose our members
	self.In = self.Instance

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioEmitter) :: Types.AUEmitter
end

function AudioEmitter:__tostring()
	return "AudioEmitter"
end

local tDistanceAttenuation = t.map(t.numberMin(0), t.numberConstrained(0, 1))
function AudioEmitter:SetDistanceAttenuation(attenuation: { [number]: number })
	assert(
		tDistanceAttenuation(attenuation),
		"[AudioEmitter] SetDistanceAttenuation expects a table of number (0+) to number (0-1) pairs"
	)

	-- Count the total amount of entries, max entries if 400
	local count = 0
	for _ in attenuation do
		count += 1
	end

	-- All the keys need to be unique..
	local keys = {}
	for key, _ in attenuation do
		if keys[key] then
			error(
				string.format(
					"[AudioEmitter] SetDistanceAttenuation expects unique distance values in the attenuation table\nFound duplicate key: %s",
					tostring(key)
				),
				2
			)
		end

		keys[key] = true
	end

	if count > 400 then
		error("[AudioEmitter] SetDistanceAttenuation expects a maximum of 400 entries in the attenuation table", 2)
	end

	-- Apply our distance attenuation to our emitter
	self.Instance:SetDistanceAttenuation(attenuation)
end

local tAngleAttenuation = t.map(t.numberConstrained(0, 180), t.numberConstrained(0, 1))
function AudioEmitter:SetAngleAttenuation(attenuation: { [number]: number })
	assert(
		tAngleAttenuation(attenuation),
		"[AudioEmitter] SetAngleAttenuation expects a table of number (0-180) to number (0-1) pairs"
	)

	-- Count the total amount of entries, max entries if 400
	local count = 0
	for _ in attenuation do
		count += 1
	end

	if count > 400 then
		error("[AudioEmitter] SetAngleAttenuation expects a maximum of 400 entries in the attenuation table", 2)
	end

	-- Apply our angle attenuation to our emitter
	self.Instance:SetAngleAttenuation(attenuation)
end

--[=[
	Destroys the AudioEmitter
]=]
function AudioEmitter:Destroy()
	self._trove:Destroy()
end

return AudioEmitter
