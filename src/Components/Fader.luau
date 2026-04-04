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
local tCreateFader = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))
local function CreateFader(parent: Instance, props: { [string]: any }?): AudioFader
	assert(tCreateFader(parent))

	local Fader = Instance.new("AudioFader")
	Fader.Name = "AudioFader"
	Fader.Parent = parent

	if props then
		local Volume = (typeof(props.Volume) == "number") and props.Volume or nil
		if Volume then
			Fader.Volume = math.clamp(Volume, 0, 3)
		end

		if typeof(props.Name) == "string" then
			Fader.Name = props.Name
		end
	end

	return Fader
end

---------------------------------------------------------------------
local AudioFader = {}
AudioFader.__index = AudioFader

--[=[
	@class AudioFader
	@tag Base

	Represents an AudioFader, which is a fader that can be used to control the volume of an audio source.
]=]

local tAudioFader = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	Creates a new AudioFader
]=]
function AudioFader.new(parent: Instance, props: { [string]: any }?): Types.AUFader
	assert(tAudioFader(parent, props))

	-- Create a new Audio Fader
	local self = {}
	self.ClassName = "AudioFader"

	-- Create our Trove
	self._trove = Trove.new()
	self._tweenTrove = self._trove:Extend()

	-- Create our AudioFader Instanc
	self.Instance = CreateFader(parent, props) :: AudioFader

	-- Create our Routing
	self.Routing = Routing.new(self.Instance, { "Input", "Output" })

	-- Expose our members
	self.IsMuted = false
	self.In = self.Instance
	self.Out = self.Instance

	-- Create our Completed Signal
	self.Completed = self._tweenTrove:Construct(Signal)

	self._trove:AttachToInstance(self.Instance)

	return setmetatable(self :: any, AudioFader) :: Types.AUFader
end

function AudioFader:__tostring()
	return string.format("AudioFader<%s>", self.Instance.Name)
end

local tSetFader = t.tuple(tVolume)

--[=[
	Sets the AudioFader to the desired volume
	@param volume number[0,3] -- A number between 0 (min) and 3 (max)
]=]
function AudioFader:Set(volume: number)
	assert(tSetFader(volume))

	-- Clean any Tweens we have, as we are doing a hard set
	self._tweenTrove:Clean()

	if self.IsMuted then
		self._previousVolume = volume
		warn(
			string.format(
				"AudioFader %s is muted, setting volume to %d will not have any effect",
				self.Instance.Name,
				volume
			)
		)

		return
	end

	local fader = self.Instance :: AudioFader

	if fader.Volume ~= volume then
		fader.Volume = volume
	end
end

local tTween = t.tuple(tVolume, t.TweenInfo)
--[=[
	Tweens a Fader to goal
	@param goal number[0,3] -- The goal for the Volume of the fader
	@param tweenInfo TweenInfo? -- TweenInfo, if not provided a default TweenInfo will be used

	@return Signal
]=]
function AudioFader:Tween(goal: number, tweenInfo: TweenInfo?): Types.Signal
	assert(tTween(goal, tweenInfo))

	-- Clean our Tween Trove
	self._tweenTrove:Clean()

	if self.IsMuted then
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
			self.Completed:Fire()
		end)
	end

	if not self.IsMuted then
		-- Create a new Tween
		local tween = self._tweenTrove:Add(
			TweenService:Create(self.Instance, tweenInfo or TweenInfo.new(1, Enum.EasingStyle.Linear), {
				Volume = goal,
			})
		)

		-- Play our Tween
		tween:Play()

		-- Connect our Completed event to our Signal
		self._tweenTrove:Connect(tween.Completed, function()
			self.Completed:Fire()
		end)
	end

	return self.Completed
end

local tFadeOut = t.tuple(t.numberPositive, t.optional(tVolume))
--[=[
	FadeOut a fader in X duration
	@param duration number -- The amount of seconds that it should take to fade-out the fader
	@param goal number[0,3] -- The goal that we are targetting

	@return Signal
]=]

function AudioFader:FadeOut(duration: number, goal: number?)
	assert(tFadeOut(duration, goal))

	local baseVolume = self.Instance.Volume
	local target = typeof(goal) == "number" and goal or 0
	local direction = baseVolume >= target and Enum.EasingDirection.Out or Enum.EasingDirection.In
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, direction)

	return self:Tween(target, tweenInfo)
end

local tFadeIn = t.tuple(t.numberPositive, t.optional(tVolume))
--[=[
	FadeIn a fader in X duration
	@param duration number -- The amount of seconds that it should take to fade-in the fader
	@param goal number[0,3] -- The goal that we are targetting

	@return Signal
]=]
function AudioFader:FadeIn(duration: number, goal: number?)
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

function AudioFader:Mute(noTween: boolean?)
	assert(tMute(noTween))

	if self.IsMuted == false then
		self._previousVolume = self.Instance.Volume

		if noTween then
			self:Set(0)
		else
			self:FadeOut(0.5, 0)
		end

		self.IsMuted = true
	else
		self.IsMuted = false

		if noTween then
			self:Set(self._previousVolume)
		else
			self:FadeIn(0.5, self._previousVolume)
		end
	end
end

--[=[
	Destroys the AudioFader
]=]
function AudioFader:Destroy()
	self._trove:Destroy()
end

return AudioFader
