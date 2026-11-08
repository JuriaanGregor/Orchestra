--!strict

-- Imports > Packages
local Dependencies = require("../../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove
local Promise = Dependencies.Promise

-- Imports > Package
local applyInstanceProps = require("../../Instances/applyInstanceProps")
local bindLifetime = require("../../Instances/bindLifetime")
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

	Wraps an `AudioTextToSpeech`, which speaks text aloud.

	Create one with `Orchestra.Stream.new(Enums.Stream.TextToSpeech, parent, props)`.
]=]

--[=[
	@prop Instance AudioTextToSpeech
	@within AudioTextToSpeech
	@readonly

	The wrapped `AudioTextToSpeech` instance.
]=]

--[=[
	@prop Routing Routing
	@within AudioTextToSpeech
	@readonly

	Wires this component to others, see [Routing].
]=]

--[=[
	@prop Out AudioTextToSpeech
	@within AudioTextToSpeech
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	@prop Text string?
	@within AudioTextToSpeech
	@readonly

	The text last passed to [AudioTextToSpeech:LoadText].
]=]

--[=[
	@prop Ended RBXScriptSignal
	@within AudioTextToSpeech
	@readonly

	The instance's `Ended` event, fired when the speech finishes.
]=]

--[=[
	@prop Looped RBXScriptSignal
	@within AudioTextToSpeech
	@readonly

	The instance's `Looped` event, fired each time the speech loops.
]=]

--[=[
	Creates a new AudioTextToSpeech under `parent`. Usually created through `Orchestra.Stream.new`.

	@param parent Instance -- Where the `AudioTextToSpeech` instance is created
	@param props { [string]: any }? -- Properties to apply to the instance (any of its Roblox properties, plus `Name`, `Tags` and `Attributes`)
	@return AudioTextToSpeech
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

	-- Make sure to unload our text to speech when destroyed
	self._trove:Add(function()
		self.Instance:Unload()
	end)

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	self.Text = nil :: string?

	self.Ended = self.Instance.Ended :: RBXScriptSignal
	self.Looped = self.Instance.Looped :: RBXScriptSignal

	-- AudioTextToSpeech only has an Output pin, so there is no `In`
	self.Out = self.Instance

	return setmetatable(self :: any, AudioTextToSpeech) :: Types.AUTextToSpeech
end

function AudioTextToSpeech:__tostring()
	return "AudioTextToSpeech"
end

--[=[
	Plays the speech. If the text isn't loaded yet, it loads it first and then plays; a failed load is reported with `warn`.
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
	Pauses the speech.
]=]
function AudioTextToSpeech:Pause()
	self.Instance:Pause()
end

--[=[
	Loads the instance's current `Text`. The Promise is cancelled if the AudioTextToSpeech is destroyed while loading.

	@return Promise -- Resolves once loaded, rejects if loading fails or times out
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
	Sets the text to speak and loads it.

	@param text string -- The text to speak
	@return Promise -- See [AudioTextToSpeech:Load]
]=]
function AudioTextToSpeech:LoadText(text: string)
	self.Text = text
	self.Instance.Text = text

	return self:Load()
end

--[=[
	Destroys the AudioTextToSpeech: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioTextToSpeech:Destroy()
	self._trove:Destroy()
end

return AudioTextToSpeech
