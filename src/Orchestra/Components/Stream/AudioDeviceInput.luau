--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local bindLifetime = require("../../Instances/bindLifetime")
local Routing = require("../Routing")

-- Types
local Types = require("../../Types")

-- Functions
local function CreateDeviceInput(parent: Instance, props: { [string]: any }?): AudioDeviceInput
	local input = Instance.new("AudioDeviceInput")
	input.Parent = parent

	-- Make sure that a valid player is provided if the access type is not "Everyone"
	if props then
		if props.Player then
			assert(
				typeof(props.Player) == "Instance" and props.Player:IsA("Player"),
				"Player property must be a Player instance"
			)
		end
	end

	-- Apply properties
	applyInstanceProps(input, props and props or {})

	-- Return our object
	return input
end

---------------------------------------------------------------------
local AudioDeviceInput = {}
AudioDeviceInput.__index = AudioDeviceInput

--[=[
	@class AudioDeviceInput
	@tag Stream

	Wraps an `AudioDeviceInput`, which captures a player's microphone.

	Create one with `Orchestra.Stream.new(Enums.Stream.Input, parent, props)`.
]=]

--[=[
	@prop Instance AudioDeviceInput
	@within AudioDeviceInput
	@readonly

	The wrapped `AudioDeviceInput` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioDeviceInput
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop Out AudioDeviceInput
	@within AudioDeviceInput
	@readonly

	The instance to wire from (same as `Instance`).
]=]
local tAudioDeviceInput = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	Creates a new AudioDeviceInput under `parent`. Usually created through `Orchestra.Stream.new`.

	@param parent Instance -- Where the `AudioDeviceInput` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioDeviceInput
]=]
function AudioDeviceInput.new(parent: Instance, props: { [string]: any }?): Types.AUInput
	assert(tAudioDeviceInput(parent, props))

	-- Create a new Audio Device input
	local self = {}
	self.Type = "Stream"
	self.ClassName = "AudioDeviceInput"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our Audio Device Input Instance
	self.Instance = CreateDeviceInput(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.Out = self.Instance

	return setmetatable(self :: any, AudioDeviceInput) :: Types.AUInput
end

local tIsAudible = t.tuple(t.instanceIsA("Player"))
--[=[
	Returns whether this input is heard by `player`: it is ready, active, not muted, and the player passes its `AccessType` / user id access list.

	@param player Player
	@return boolean
]=]
function AudioDeviceInput:IsAudible(player: Player): boolean
	assert(tIsAudible(player))

	local input = self.Instance

	if input.IsReady == false then
		return false
	end

	if input.Muted then
		return false
	end

	if input.Active == false then
		return false
	end

	-- Get the access type of the player
	local permissionList = input:GetUserIdAccessList()
	if input.AccessType == Enum.AccessModifierType.Allow then
		for _, userId in permissionList do
			if userId == player.UserId then
				return true
			end
		end
	elseif input.AccessType == Enum.AccessModifierType.Deny then
		for _, userId in permissionList do
			if userId == player.UserId then
				return false
			end
		end

		return true
	end

	return false
end

--[=[
	Mutes the input.
]=]
function AudioDeviceInput:Mute()
	self.Instance.Muted = true
end

function AudioDeviceInput:__tostring()
	return "AudioDeviceInput"
end

--[=[
	Destroys the AudioDeviceInput: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioDeviceInput:Destroy()
	self._trove:Destroy()
end

return AudioDeviceInput
