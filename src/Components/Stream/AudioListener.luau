--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Import > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)

-- Types
local Types = require(script.Parent.Parent.Parent.Types)

-- Functions
local tCreateAudioListener = t.tuple(t.Instance, t.optional(t.string), t.optional(t.map(t.string, t.any)))
local function CreateListener(
	parent: Instance,
	audioInteractionGroup: string?,
	props: { [string]: any }?
): AudioListener
	assert(tCreateAudioListener(parent, audioInteractionGroup))

	local listener = Instance.new("AudioListener")
	listener.Parent = parent

	if audioInteractionGroup then
		listener.AudioInteractionGroup = audioInteractionGroup
	end

	if not props then
		return listener
	end

	-- Apply properties
	applyInstanceProps(listener, props)

	-- Return our object
	return listener
end

---------------------------------------------------------------------
local AudioListener = {}
AudioListener.__index = AudioListener

local tAudioListener = t.tuple(t.Instance, t.optional(t.string), t.optional(t.map(t.string, t.any)))
function AudioListener.new(
	parent: Instance,
	audioInteractionGroup: string?,
	props: { [string]: any }?
): Types.AUListener
	assert(tAudioListener(parent, audioInteractionGroup, props))

	local self = {}
	self.ClassName = "AudioListener"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioListener Instance
	self.Instance = CreateListener(parent, audioInteractionGroup, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	self.Out = self.Instance

	return setmetatable(self :: any, AudioListener) :: Types.AUListener
end

function AudioListener:__tostring()
	return "AudioListener"
end

function AudioListener:Destroy()
	self._trove:Destroy()
end

return AudioListener
