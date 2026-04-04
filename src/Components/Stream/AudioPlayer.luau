--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)
local Signal = require(Package.Packages.Signal)

-- Imports > Package
local applyInstanceProps = require(Package.Instances.applyInstanceProps)

-- Types
local Types = require(Package.Types)

-- Functions
local tResolveAssetId = t.union(t.string, t.number, t.instanceIsA("Sound"))
local function ResolveAssetId(asset: string | number | Sound): string?
	assert(tResolveAssetId(asset))
	if typeof(asset) == "string" then
		-- Look for the string rbxassetId:// in the asset variable
		local id = string.match(asset, "rbxassetid://(%d+)")
		if id then
			return "rbxassetid://" .. id
		else
			warn("Failed to resolve asset id from string: " .. asset)
		end
	elseif typeof(asset) == "number" then
		return "rbxassetid://" .. asset
	elseif typeof(asset) == "Instance" and asset:IsA("Sound") then
		return asset.SoundId
	end

	return nil
end

local tCreatePlayer = t.tuple(t.Instance, t.map(t.string, t.any))
local function CreatePlayer(parent: Instance, props: { [string]: any }?): AudioPlayer
	assert(tCreatePlayer(parent, props))

	local audioPlayer = Instance.new("AudioPlayer") :: AudioPlayer
	audioPlayer.Parent = parent

	if props and props.Asset then
		local id = ResolveAssetId(props.Asset)
		if not id then
			error("Failed to resolve asset id for AudioPlayer with asset: " .. tostring(props.Asset))
		end
	end

	-- Apply properties
	applyInstanceProps(audioPlayer, props and props or {})

	-- Return our object
	return audioPlayer
end

---------------------------------------------------------------------
local AudioPlayer = {}
AudioPlayer.__index = AudioPlayer

--[=[
	@class AudioPlayer 
	@tag Stream
	
	Represents an audio player that can be used to play audio in the game.
]=]

local tAudioPlayer = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	Creates a new AudioPlayer
]=]
function AudioPlayer.new(parent: Instance, props: { [string]: any }?): Types.AUPlayback
	assert(tAudioPlayer(parent, props))

	-- Create a new Audio Player
	local self = {}
	self.ClassName = "AudioPlayer"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our Audio Instance
	self.Instance = CreatePlayer(parent, props)

	-- Create our Signals
	self.Changed = self._trove:Construct(Signal)
	self.Loaded = self._trove:Construct(Signal)
	self.Ended = self._trove:Construct(Signal)
	self.Looped = self._trove:Construct(Signal)

	self._trove:Connect(self.Instance:GetPropertyChangedSignal("TimeLength"), function()
		self.Loaded:Fire(self.Instance.TimeLength)
	end)

	self._trove:Connect(self.Instance.Ended, function()
		self.Ended:Fire()
	end)

	self._trove:Connect(self.Instance.Looped, function()
		self.Looped:Fire()
	end)

	-- Expose our members
	self.Out = self.Instance

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioPlayer) :: Types.AUPlayback
end

function AudioPlayer:__tostring()
	return string.format("AudioPlayer<%s>", self.Instance.Name)
end

--[=[
	Plays the audio
]=]
function AudioPlayer:Play()
	self.Instance:Play()

	return self.Instance.TimeLength
end

--[=[
	Pauses the audio
]=]
function AudioPlayer:Pause()
	self.Instance:Pause()
end

--[=[
	Stops the audio
]=]
function AudioPlayer:Stop()
	self.Instance:Stop()
	self.Instance.TimePosition = 0
end

--[=[
	Destroys the AudioPlayer
]=]
function AudioPlayer:Destroy()
	self._trove:Destroy()
end

return AudioPlayer
