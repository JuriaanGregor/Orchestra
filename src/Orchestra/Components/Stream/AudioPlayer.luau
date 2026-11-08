--!strict

-- Roblox Services
local RunService = game:GetService("RunService")

-- Import > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Types
local Types = require("../../Types")

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local Routing = require("../Routing")

-- Functions
local tResolveAssetId = t.union(t.string, t.number, t.instanceIsA("Sound"))
local function ResolveAssetId(asset: string | number | Sound): string?
	assert(tResolveAssetId(asset))
	if typeof(asset) == "string" then
		if string.match(asset, "rbxassetid://") then
			return asset
		elseif string.match(asset, "rbxasset://") then
			if not RunService:IsStudio() then
				error(
					string.format(
						"Asset paths starting with 'rbxasset://' are only supported in Studio, got %s.",
						tostring(asset)
					),
					2
				)
			end

			-- Check or the path ends with a file extension and check or that file extension is .wav, .mp3, .ogg
			local ALLOWED_EXTENSIONS = { ".wav", ".mp3", ".ogg" }
			local hasAllowedExtension = false
			for _, ext in ALLOWED_EXTENSIONS do
				if string.match(asset, ext .. "$") then
					hasAllowedExtension = true
					break
				end
			end

			if not hasAllowedExtension then
				error(
					string.format(
						"Invalid asset path format for %s. Expected a path starting with 'rbxasset://' and ending with .wav, .mp3, .ogg extension.",
						tostring(asset)
					),
					2
				)
			end

			return asset
		end
	elseif typeof(asset) == "number" then
		return "rbxassetid://" .. asset
	elseif typeof(asset) == "Instance" and asset:IsA("Sound") then
		return asset.SoundId
	end

	return nil
end

local tCreatePlayer = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreatePlayer(parent: Instance, props: { [string]: any }?): AudioPlayer
	assert(tCreatePlayer(parent, props))

	local audioPlayer = Instance.new("AudioPlayer") :: AudioPlayer
	audioPlayer.Parent = parent

	-- Work on a copy, we strip and rewrite the asset fields below
	props = if props then table.clone(props) else nil

	-- Let's find our assetId if we have one
	local assetId: any? = nil

	if props then
		local ASSET_FIELDS = { "Asset", "AssetId", "Sound", "SoundId", "Content" }
		for _, field in ASSET_FIELDS do
			if props[field] then
				if assetId then
					warn(
						"Multiple asset fields found in props for AudioPlayer. This can lead to unexpected behavior. Found multiple of the following fields: "
							.. table.concat(ASSET_FIELDS, ", ")
					)
					break
				end

				-- Resolve the assetId from the field
				local id = ResolveAssetId(props[field])

				if id then
					assetId = id
				else
					warn("Failed to resolve asset id from field " .. field .. " with value: " .. tostring(props[field]))
				end

				props[field] = nil
			end
		end

		if assetId then
			props.Asset = assetId
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
	self.Type = "Stream"
	self.ClassName = "AudioPlayer"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our Audio Instance
	self.Instance = CreatePlayer(parent, props)

	-- Create our Routing
	self.Routing = Routing.new(self.Instance)

	-- Create our Signals
	self.Ended = self.Instance.Ended
	self.Looped = self.Instance.Looped

	self._trove:Connect(self.Instance:GetPropertyChangedSignal("TimeLength"), function()
		--self.Loaded:Fire(self.Instance.TimeLength)
	end)

	-- Expose our members
	self.Out = self.Instance

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioPlayer) :: Types.AUPlayback
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
