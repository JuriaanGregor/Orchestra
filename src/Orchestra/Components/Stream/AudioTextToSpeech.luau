--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove
local Promise = Dependencies.Promise

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local Routing = require("../Routing")

-- Types
local Types = require("../../Types")

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
	self.Type = "Stream"
	self.ClassName = "AudioTextToSpeech"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioTextToSpeech Instance
	self.Instance = CreateTextToSpeech(parent, props)

	-- Create our routing
	self.Routing = Routing.new(self.Instance)

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
	if self.Instance.IsLoaded then
		self.Instance:Play()
		return
	end

	-- Not loaded yet: load first, then play
	self:Load()
		:andThen(function()
			self.Instance:Play()
		end)
		:catch(function(err)
			warn(string.format("AudioTextToSpeech: Failed to play, could not load: %s", tostring(err)))
		end)
end

--[=[
	Pauses the AudioTextToSpeech.
]=]

function AudioTextToSpeech:Pause()
	self.Instance:Pause()
end

--[=[
	Loads the AudioTextToSpeech's current Text. Returns a Promise that resolves once it's loaded.
]=]

function AudioTextToSpeech:Load()
	-- LoadAsync yields, so we run it inside a Promise. The trove cancels it if we're destroyed mid-load.
	return self._trove:AddPromise(Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return self.Instance:LoadAsync()
		end)

		if not success then
			reject(result)
		elseif result == Enum.AssetFetchStatus.Success then
			resolve()
		elseif result == Enum.AssetFetchStatus.TimedOut then
			reject("Text to speech loading timed out.")
		else
			reject(string.format("Failed to load text to speech (%s).", tostring(result)))
		end
	end))
end

--[=[
	Sets the text to speak and loads it. Returns a Promise that resolves once the text is loaded.
]=]

function AudioTextToSpeech:LoadText(text: string)
	self.Text = text
	self.Instance.Text = text

	return self:Load()
end

--[=[
	Destroys the AudioTextToSpeech
]=]
function AudioTextToSpeech:Destroy()
	self._trove:Destroy()
end

return AudioTextToSpeech
