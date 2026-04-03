--!strict

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Import > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local t = require(Package.Packages.t)
local Trove = require(Package.Packages.Trove)
local Signal = require(Package.Packages.Signal)

-- Import > Package
local Routing = require(Package.Components.Routing)
local Types = require(Package.Types)

-- t
local tVolume = t.numberConstrained(0, 3)

-- Functions
local tCreateMixBus = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateMixBus(parent: Instance, props: { [string]: any }?): AudioFader
	assert(tCreateMixBus(parent))

	local Bus = Instance.new("AudioFader")
	Bus.Name = "AudioMixBus"
	Bus.Parent = parent

	if not props then
		return Bus
	end

	local Volume = (typeof(props.Volume) == "number") and props.Volume or nil
	if Volume then
		Bus.Volume = math.clamp(Volume, 0, 3)
	end

	if typeof(props.Name) == "string" then
		Bus.Name = props.Name
	end

	return Bus
end

---------------------------------------------------------------------
local AudioMixBus = {}
AudioMixBus.__index = AudioMixBus

--[=[
	@class AudioMixBus
	@tag Audio
	@client 

	Represents an AudioMixBus, which is a fader that can be used to control the volume of an audio source.
]=]

local tAudioMixBus = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	Creates a new AudioMixBus
]=]
function AudioMixBus.new(parent: Instance, props: { [string]: any }?): Types.AUMixBus
	assert(tAudioMixBus(parent, props))

	-- Create a new Audio Fader
	local self = {}
	self.ClassName = "AudioMixBus"

	-- Create our Trove
	self._trove = Trove.new()

	-- Create our AudioMixBus Instance
	self.Instance = CreateMixBus(parent, props) :: AudioFader

	-- Create our Routing
	self.Routing = Routing.new(self.Instance, { "Input", "Output" })

	self._isMuted = false
	self.In = self.Instance
	self.Out = self.Instance

	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioMixBus) :: Types.AUMixBus
end

function AudioMixBus:__tostring()
	return string.format("AudioMixBus<%s>", self.Instance.Name)
end

local tSetVolume = t.tuple(tVolume)

--[=[
	Sets the AudioMixBus to the desired volume
	@param volume number[0,3] -- A number between 0 (min) and 3 (max)
]=]
function AudioMixBus:Set(volume: number)
	assert(tSetVolume(volume))
	if self._isMuted then
		self._previousVolume = volume
		warn(
			string.format(
				"AudioMixBus %s is muted, setting volume to %d will not have any effect",
				self.Instance.Name,
				volume
			)
		)

		return
	end

	local mixBus = self.Instance :: AudioFader

	if mixBus.Volume ~= volume then
		mixBus.Volume = volume
	end
end

local tTween = t.tuple(tVolume, t.TweenInfo)
--[=[
	Tweens a MixBus volume to a set goal
	@param goal number[0,3] -- The goal for the Volume of the MixBus
	@param tweenInfo TweenInfo? -- TweenInfo, if not provided a default TweenInfo will be used

	@return Signal
]=]
function AudioMixBus:Tween(goal: number, tweenInfo: TweenInfo?): Types.Signal
	assert(tTween(goal, tweenInfo))

	local _signal = self._trove:Construct(Signal)
	if self._isMuted then
		-- We set our volume to the goal, but we are muted
		self._previousVolume = goal

		-- Let the user know that we are muted
		warn(
			string.format(
				"AudioFader %s is muted, tweening to volume %d will not have any effect",
				self.Instance.Name,
				goal
			)
		)

		-- We need to defer the signal firing because we are muted
		task.defer(function()
			_signal:Fire()
		end)
	end

	if not self._isMuted then
		-- Create a new Tween
		local _tween =
			self._trove:Add(TweenService:Create(self.Instance, tweenInfo or TweenInfo.new(1, Enum.EasingStyle.Linear), {
				Volume = goal,
			}))

		-- Play our Tween
		_tween:Play()

		-- Connect our Completed event to our Signal
		self._trove:Connect(_tween.Completed, function()
			_signal:Fire()
		end)
	end

	return _signal
end

local tFadeOut = t.tuple(t.numberPositive, t.optional(tVolume))
--[=[
	FadeOut a MixBus in X duration
	@param duration number -- The amount of seconds that it should take to fade-out the MixBus
	@param goal number[0,3] -- The goal that we are targetting

	@return Signal
]=]

function AudioMixBus:FadeOut(duration: number, goal: number?)
	assert(tFadeOut(duration, goal))

	local baseVolume = self.Instance.Volume
	local target = typeof(goal) == "number" and goal or 0
	local direction = baseVolume >= target and Enum.EasingDirection.Out or Enum.EasingDirection.In
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, direction)

	return self:Tween(target, tweenInfo)
end

local tFadeIn = t.tuple(t.numberPositive, t.optional(tVolume))
--[=[
	FadeIn a MixBus in X duration
	@param duration number -- The amount of seconds that it should take to fade-in the MixBus
	@param goal number[0,3] -- The goal that we are targetting

	@return Signal
]=]
function AudioMixBus:FadeIn(duration: number, goal: number?)
	assert(tFadeIn(duration, goal))

	local baseVolume = self.Instance.Volume
	local target = typeof(goal) == "number" and goal or 1
	local direction = baseVolume >= target and Enum.EasingDirection.Out or Enum.EasingDirection.In
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, direction)

	return self:Tween(target, tweenInfo)
end

local tMute = t.tuple(t.optional(t.boolean))
--[=[
	Mutes a Fader
	@param noTween boolean? -- When provided and set to true, this will disable any tweening and do a hard-cut instead.
]=]

function AudioMixBus:Mute(noTween: boolean?)
	assert(tMute(noTween))

	if self._isMuted == false then
		self._previousVolume = self.Instance.Volume

		if noTween then
			self:Set(0)
		else
			self:FadeOut(0.5, 0)
		end

		self._isMuted = true
	else
		self._isMuted = false

		if noTween then
			self:Set(self._previousVolume)
		else
			self:FadeIn(0.5, self._previousVolume)
		end
	end
end

--[=[
	Destroys the AudioMixBus
]=]
function AudioMixBus:Destroy()
	self._trove:Destroy()
end

return AudioMixBus
