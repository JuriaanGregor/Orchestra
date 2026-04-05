--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)

-- Import > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)
local Routing = require(Package.Components.Routing)

-- Types
local Types = require(Package.Types)

-- Functions
local function CreateListener(parent: Instance, props: { [string]: any }?): AudioListener
	local listener = Instance.new("AudioListener")
	listener.Parent = parent

	-- Apply properties
	applyInstanceProps(listener, typeof(props) == "table" and props or {})

	-- Return our object
	return listener
end

---------------------------------------------------------------------
--[=[
	@class AudioListener
	@tag Stream

	Represents an audio listener. This is used to listen to audio in the world.
]=]

local AudioListener = {}
AudioListener.__index = AudioListener

local tAudioListener = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
function AudioListener.new(parent: Instance, props: { [string]: any }?): Types.AUListener
	assert(tAudioListener(parent, props))

	local self = {}
	self.ClassName = "AudioListener"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioListener Instance
	self.Instance = CreateListener(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

	-- Expose our members
	self.Out = self.Instance

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioListener) :: Types.AUListener
end

function AudioListener:__tostring()
	return "AudioListener"
end

function AudioListener:Destroy()
	self._trove:Destroy()
end

return AudioListener
