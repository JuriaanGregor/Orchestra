--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Types
local Types = require("../../Types")

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local bindLifetime = require("../../Instances/bindLifetime")
local Routing = require("../Routing")

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

	Wraps an `AudioEmitter`, which emits audio in 3D from its parent (a Part, Attachment, ...).

	Listeners only hear emitters that share their `AudioInteractionGroup`. Set it to a mix bus name (such as `"Music"`) to send the emitter to that bus.

	Create one with `Orchestra.Output.new(Enums.Output.Emitter, parent, props)`.
]=]

--[=[
	@prop Instance AudioEmitter
	@within AudioEmitter
	@readonly

	The wrapped `AudioEmitter` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioEmitter
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop In AudioEmitter
	@within AudioEmitter
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	Creates a new AudioEmitter under `parent`. Usually created through `Orchestra.Output.new`.

	@param parent Instance -- Where the `AudioEmitter` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioEmitter
]=]
function AudioEmitter.new(parent: Instance, props: { [string]: any }?): Types.AUEmitter
	assert(tAudioEmitter(parent, props))

	local self = {}
	self.Type = "Output"
	self.ClassName = "AudioEmitter"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioEmitter Instance
	self.Instance = CreateAudioEmitter(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Expose our members
	self.In = self.Instance

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	return setmetatable(self :: any, AudioEmitter) :: Types.AUEmitter
end

function AudioEmitter:__tostring()
	return "AudioEmitter"
end

local tDistanceAttenuation = t.map(t.numberMin(0), t.numberConstrained(0, 1))
--[=[
	Sets how the emitter's volume falls off with distance.

	@param attenuation { [number]: number } -- Distance (studs, 0+) to volume (0 - 1), at most 400 entries
]=]
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
--[=[
	Sets how the emitter's volume falls off with the angle from its facing direction.

	@param attenuation { [number]: number } -- Angle (degrees, 0 - 180) to volume (0 - 1), at most 400 entries
]=]
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
	Destroys the AudioEmitter: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioEmitter:Destroy()
	self._trove:Destroy()
end

return AudioEmitter
