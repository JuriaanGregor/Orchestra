--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)
local Promise = require(Package.Packages.Promise)

-- Imports > Package
local Types = require(Package.Types)
local applyInstanceProps = require(Package.Instances.applyInstanceProps)

-- Functions
local tAudioTextToSpeech = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

local function CreateTextToSpeech(parent: Instance, props: { [string]: any }?): AudioTextToSpeech
	assert(tAudioTextToSpeech(parent, props))

	local audioTextToSpeech = Instance.new("AudioTextToSpeech")
	audioTextToSpeech.Parent = parent

	if not props then
		return audioTextToSpeech
	end

	-- Apply properties
	applyInstanceProps(audioTextToSpeech, props and props or {})

	-- Return our object
	return audioTextToSpeech
end

---------------------------------------------------------------------
local AudioTextToSpeech = {}
AudioTextToSpeech.__index = AudioTextToSpeech

--[=[
	@class AudioTextToSpeech
	@tag Stream

	Represents an AudioTextToSpeech. This is used to convert text to speech.
]=]

--[=[
	Creates a new AudioTextToSpeech.
]=]

function AudioTextToSpeech.new(parent: Instance, props: { [string]: any }?): Types.AUTextToSpeech
	assert(tAudioTextToSpeech(parent, props))

	-- Create a new AudioTextToSpeech
	local self = {}
	self.ClassName = "AudioTextToSpeech"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioTextToSpeech Instance
	self.Instance = CreateTextToSpeech(parent, props)

	-- Attach to Instance
	self._trove:AttachToInstance(self.Instance)

	-- Make sure to unload our text to speech when destroyed
	self._trove:Add(function()
		self.Instance:Unload()
	end)

	self.Text = nil :: string?

	self.Ended = self.Instance.Ended :: RBXScriptSignal
	self.Looped = self.Instance.Looped :: RBXScriptSignal

	self.In = self.Instance
	self.Out = self.Instance

	return setmetatable(self :: any, AudioTextToSpeech) :: Types.AUTextToSpeech
end

function AudioTextToSpeech:__tostring()
	return "AudioTextToSpeech"
end

--[=[
	Plays the AudioTextToSpeech.
]=]

function AudioTextToSpeech:Play()
	-- Ensure the AudioTextToSpeech is loaded
	if not self.Instance.IsLoaded then
		-- If not loaded, attempt to load it once..
		self.Instance:Load()

		warn("AudioTextToSpeech: Cannot play because it is not loaded.")
		return
	end

	self.Instance:Play()
end

--[=[
	Pauses the AudioTextToSpeech.
]=]

function AudioTextToSpeech:Pause()
	self.Instance:Pause()
end

--[=[
	Loads the AudioTextToSpeech with the given text
]=]

function AudioTextToSpeech:LoadText(text: string)
	self.Text = text

	-- Load the text into the AudioTextToSpeech instance, this is a yielding call!
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			self.Instance:LoadText(text)
		end)

		if success then
			if result == Enum.AssetFetchStatus.Success then
				resolve()
			elseif result == Enum.AssetFetchStatus.Failure then
				reject("Failed to load text to speech.")
			elseif result == Enum.AssetFetchStatus.TimedOut then
				reject("Text to speech loading timed out.")
			end
		else
			reject(result)
		end
	end)
end

--[=[
	Destroys the AudioTextToSpeech
]=]
function AudioTextToSpeech:Destroy()
	self._trove:Destroy()
end

return AudioTextToSpeech
