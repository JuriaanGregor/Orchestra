--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Imports > Package
local Types = require(Package.Types)
local applyInstanceProps = require(Package.Instances.applyInstanceProps)

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

	Represents an audio device input. This is used to capture audio from a specific player device
]=]
local tAudioDeviceInput = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	Creates a new AudioDeviceInput
]=]
function AudioDeviceInput.new(parent: Instance, props: { [string]: any }?): Types.AUInput
	assert(tAudioDeviceInput(parent, props))

	-- Create a new Audio Device input
	local self = {}
	self.ClassName = "AudioDeviceInput"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our Audio Device Input Instance
	self.Instance = CreateDeviceInput(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.Out = self.Instance

	return setmetatable(self :: any, AudioDeviceInput) :: Types.AUInput
end

local tIsAudible = t.tuple(t.instanceIsA("Player"))
--[=[
	Returns whether the audio device input is audible for the given player
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
	Mutes the audio device input
]=]
function AudioDeviceInput:Mute()
	self.Instance.Muted = true
end

function AudioDeviceInput:__tostring()
	return "AudioDeviceInput"
end

--[=[
	Destroys the AudioDeviceInput
]=]
function AudioDeviceInput:Destroy()
	self._trove:Destroy()
end

return AudioDeviceInput
