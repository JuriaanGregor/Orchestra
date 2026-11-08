--!strict

-- Roblox Services
local TweenService = game:GetService("TweenService")

-- Import > Packages
local Dependencies = require("../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove
local Promise = Dependencies.Promise

-- Import > Package
local Routing = require("./Routing")
local bindLifetime = require("../Instances/bindLifetime")

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
	@class Fader
	@tag Base

	Wraps an `AudioFader`, which controls the volume of everything wired through it (0 - 3, where 1 is unchanged).
	The mix buses and Master created by [Orchestra:Start] are Faders too.

	`Tween`, `FadeIn`, `FadeOut` and `Mute` return a [Promise](https://eryn.io/roblox-lua-promise/) that resolves when the
	fade completes. Starting another `Tween` / `Set`, or destroying the Fader, cancels it instead and leaves the volume
	where it was.

	```lua
	music.Fader:FadeOut(2):andThen(function()
		music:Stop()
	end)
	```
]=]

--[=[
	@prop Instance AudioFader
	@within Fader
	@readonly

	The wrapped `AudioFader` instance.
]=]

--[=[
	@prop Routing Routing
	@within Fader
	@readonly

	Wires this Fader to others, see [Routing].
]=]

--[=[
	@prop In AudioFader
	@within Fader
	@readonly

	The instance to wire into (same as `Instance`).
]=]

--[=[
	@prop Out AudioFader
	@within Fader
	@readonly

	The instance to wire from (same as `Instance`).
]=]

--[=[
	@prop IsMuted boolean
	@within Fader
	@readonly

	Whether the Fader is muted with [Fader:Mute].
]=]

local tAudioFader = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	@within Fader
	Creates a new Fader under `parent`.

	@param parent Instance -- Where the `AudioFader` instance is created
	@param props { Name: string?, Volume: number? }? -- `Name`, and a starting `Volume` (clamped to 0 - 3)
	@return Fader
]=]
function AudioFader.new(parent: Instance, props: { [string]: any }?)
	assert(tAudioFader(parent, props))

	-- Create a new Audio Fader
	local self = {}
	self.Type = "Base"
	self.ClassName = "AudioFader"

	-- Create our Trove
	self._trove = Trove.new()
	self._tweenTrove = self._trove:Extend()

	-- Create our AudioFader Instanc
	self.Instance = CreateFader(parent, props) :: AudioFader

	-- Create our Routing
	self.Routing = Routing.new(self.Instance)

	-- Expose our members
	self.IsMuted = false
	self.In = self.Instance
	self.Out = self.Instance

	-- Destroying the instance cleans us up, and Destroy() removes the instance and its wires
	bindLifetime(self._trove, self.Instance, self.Routing)

	return setmetatable(self :: any, AudioFader)
end

function AudioFader:__tostring()
	return string.format("AudioFader<%s>", self.Instance.Name)
end

local tSetFader = t.tuple(tVolume)

--[=[
	@within Fader
	Sets the volume immediately, cancelling any running fade. While muted, the volume is stored for when you unmute.

	@param volume number -- 0 (silent) to 3, where 1 is unchanged
]=]
function AudioFader:Set(volume: number)
	assert(tSetFader(volume))

	-- Clean any Tweens we have, as we are doing a hard set
	self._tweenTrove:Clean()

	if self.IsMuted then
		self._previousVolume = volume
		warn(
			string.format(
				"AudioFader %s is muted, setting volume to %.2f will not have any effect",
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

local tTween = t.tuple(tVolume, t.optional(t.TweenInfo))
--[=[
	@within Fader
	Tweens the volume to `goal`. While muted, the goal is stored for when you unmute and the Promise resolves right away.

	@param goal number -- Target volume, 0 - 3
	@param tweenInfo TweenInfo? -- Defaults to a 1 second linear tween
	@return Promise -- Resolves when the tween completes, cancelled when interrupted or the Fader is destroyed
]=]
function AudioFader:Tween(goal: number, tweenInfo: TweenInfo?)
	assert(tTween(goal, tweenInfo))

	-- Cancel any running tween (and its Promise), the volume stays where it was interrupted
	self._tweenTrove:Clean()

	if self.IsMuted then
		-- We store the goal for when we unmute, but we are muted
		self._previousVolume = goal

		-- Let the user know that we are muted
		warn(
			string.format(
				"AudioFader %s is muted, tweening to volume %.2f will not have any effect",
				self.Instance.Name,
				goal
			)
		)

		return Promise.resolve()
	end

	local promise = Promise.new(function(resolve, _reject, onCancel)
		local tween = TweenService:Create(self.Instance, tweenInfo or TweenInfo.new(1, Enum.EasingStyle.Linear), {
			Volume = goal,
		})

		local connection
		connection = tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
			connection:Disconnect()
			tween:Destroy()

			if playbackState == Enum.PlaybackState.Completed then
				resolve()
			end
		end)

		onCancel(function()
			connection:Disconnect()
			tween:Cancel()
			tween:Destroy()
		end)

		tween:Play()
	end)

	-- The tween trove cancels this Promise when it's cleaned (new Tween / Set) or the Fader is destroyed
	return self._tweenTrove:AddPromise(promise)
end

local tFadeOut = t.tuple(t.numberPositive, t.optional(tVolume))
--[=[
	@within Fader
	Fades the volume down linearly over `duration` seconds.

	@param duration number -- Seconds, greater than 0
	@param goal number? -- Target volume, 0 - 3. Defaults to 0
	@return Promise -- See [Fader:Tween]
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
	@within Fader
	Fades the volume up linearly over `duration` seconds.

	@param duration number -- Seconds, greater than 0
	@param goal number? -- Target volume, 0 - 3. Defaults to 1
	@return Promise -- See [Fader:Tween]
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
	@within Fader
	Toggles mute. Muting fades to 0 over 0.5 seconds and remembers the volume; calling it again fades back to that volume.

	@param noTween boolean? -- Cut immediately instead of fading
	@return Promise -- Resolves when the fade completes, right away with `noTween`
]=]
function AudioFader:Mute(noTween: boolean?)
	assert(tMute(noTween))

	local promise
	if self.IsMuted == false then
		self._previousVolume = self.Instance.Volume

		if noTween then
			self:Set(0)
			promise = Promise.resolve()
		else
			promise = self:FadeOut(0.5, 0)
		end

		self.IsMuted = true
	else
		self.IsMuted = false

		if noTween then
			self:Set(self._previousVolume)
			promise = Promise.resolve()
		else
			promise = self:FadeIn(0.5, self._previousVolume)
		end
	end

	return promise
end

--[=[
	@within Fader
	Destroys the Fader: its instance, and every wire into or out of it.
	Destroying the instance directly does the same.
]=]
function AudioFader:Destroy()
	self._trove:Destroy()
end

return AudioFader
