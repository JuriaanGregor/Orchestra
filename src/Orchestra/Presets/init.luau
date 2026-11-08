--!strict

-- Import > Packages
local Dependencies = require("./Dependencies")
local t = Dependencies.t
local Promise = Dependencies.Promise

-- Import > Package
local resolve = require("@self/resolve")
local detectPlatform = require("./Utility/detectPlatform")

export type Definition = resolve.Definition
export type Resolved = resolve.Resolved
export type Platform = detectPlatform.Platform

-- t
local tVolume = t.numberConstrained(0, 3)
local tGain = t.strictInterface({
	Volume = t.optional(tVolume),
})
local tTransition = t.strictInterface({
	Time = t.optional(t.numberMin(0)),
	EasingStyle = t.optional(t.enum(Enum.EasingStyle)),
	EasingDirection = t.optional(t.enum(Enum.EasingDirection)),
})
local tDefinition = t.strictInterface({
	Name = t.string,
	Extends = t.optional(t.string),
	Transition = t.optional(tTransition),
	Buses = t.optional(t.map(t.string, tGain)),
	Main = t.optional(tGain),
})
local tPlatform = t.literal("Mobile", "Desktop", "Console")

-- Copies a definition so later changes to the caller's table don't leak in
local function copyDefinition(definition: Definition): Definition
	local copy = table.clone(definition)

	if definition.Transition then
		copy.Transition = table.clone(definition.Transition)
	end

	if definition.Main then
		copy.Main = table.clone(definition.Main)
	end

	if definition.Buses then
		local buses = {}
		for bus, gain in definition.Buses do
			buses[bus] = table.clone(gain)
		end
		copy.Buses = buses
	end

	return copy
end

---------------------------------------------------------------------
local Presets = {}
Presets.__index = Presets

--[=[
	@class Presets
	@tag Engine

	Presets describe a mix as data: a volume per mix bus and for the Main layer (Master). Reached through
	`Orchestra.Presets`.

	The active mix is merged from these layers, later ones winning:

	1. The **platform preset**: picked for the detected [Presets.Platform] (`Mobile`, `Desktop` or `Console`). By
	default that's the preset with the platform's name, falling back to `Base`; `Orchestra:Start({ Presets = ... })`
	maps platforms to other names.
	2. The **output profile**: a preset the player picks in settings, such as `Headphones`, see
	[Presets:SetOutputProfile].

	A preset can `Extends` another: the parent is merged first. Anything no layer sets stays at volume 1.

	```lua
	Orchestra.Presets:Register({
		Name = "Base",
		Transition = { Time = 0.5 },
		Buses = { Music = { Volume = 0.8 }, Dialogue = { Volume = 1 } },
	})

	Orchestra.Presets:Register({
		Name = "Mobile",
		Extends = "Base",
		Buses = { Dialogue = { Volume = 1.2 } },
	})

	Orchestra:Start() -- applies Mobile on phones, Base elsewhere
	```

	Presets own the mix bus Faders and Master: applying a preset tweens them. Use [Orchestra:SetPlayerVolume] for
	player settings, and your own Faders for game logic.
]=]

--[=[
	@prop Platform "Mobile" | "Desktop" | "Console" | nil
	@within Presets
	@readonly

	The platform whose preset is applied. Detected by [Orchestra:Start] unless forced; `nil` before that.
]=]

--[=[
	@prop OutputProfile string?
	@within Presets
	@readonly

	The active output profile, see [Presets:SetOutputProfile].
]=]

function Presets.new(engine: any)
	local self = {}
	self.ClassName = "Presets"

	self._engine = engine
	self._registry = {} :: { [string]: Definition }
	self._platformPresets = {} :: { [string]: string }
	-- The goal each Fader was last sent to, by Fader, so re-applying doesn't restart running tweens
	self._applied = setmetatable({} :: { [any]: number }, { __mode = "k" })
	self._resolved = nil :: Resolved?
	self._started = false

	self.Platform = nil :: Platform?
	self.OutputProfile = nil :: string?

	return setmetatable(self :: any, Presets)
end

function Presets:__tostring()
	return string.format("Presets<%s, %s>", tostring(self.Platform), tostring(self.OutputProfile))
end

--[=[
	@within Presets
	Registers a preset, replacing any preset with the same name. Errors if the definition is malformed, for example an
	unknown field or a volume outside 0 - 3. Bus names and `Extends` are checked when the preset is applied.

	After [Orchestra:Start], the mix is applied again, so re-registering a preset updates the live mix.

	@param definition { Name: string, Extends: string?, Transition: { Time: number?, EasingStyle: Enum.EasingStyle?, EasingDirection: Enum.EasingDirection? }?, Buses: { [string]: { Volume: number? } }?, Main: { Volume: number? }? }
]=]
function Presets:Register(definition: Definition)
	local ok, message = tDefinition(definition)
	if not ok then
		local name = if typeof(definition) == "table" and typeof(definition.Name) == "string"
			then definition.Name
			else "?"
		error(string.format("Presets:Register - Invalid preset '%s': %s", name, tostring(message)), 2)
	end

	self._registry[definition.Name] = table.freeze(copyDefinition(definition))

	if self._started then
		self:_apply(false)
	end
end

--[=[
	@within Presets
	Returns whether a preset with this name is registered.

	@param name string
	@return boolean
]=]
function Presets:Has(name: string): boolean
	return self._registry[name] ~= nil
end

--[=[
	@within Presets
	Returns the preset names that make up the mix, in merge order, before `Extends` chains are expanded: the platform
	preset (if any) and the output profile (if any).

	@return { string }
]=]
function Presets:GetLayers(): { string }
	local layers = {}

	local platformPreset = self:_platformPresetName()
	if platformPreset then
		table.insert(layers, platformPreset)
	end

	if self.OutputProfile then
		table.insert(layers, self.OutputProfile)
	end

	return layers
end

--[=[
	@within Presets
	Returns the mix as last applied: the merged layers (with `Extends` chains expanded), every bus volume, the Main
	volume and the transition. `nil` before [Orchestra:Start]. The table is a copy.

	@return { Layers: { string }, Buses: { [string]: { Volume: number } }, Main: { Volume: number }, Transition: { Time: number } }?
]=]
function Presets:GetResolved(): Resolved?
	local resolved = self._resolved
	if not resolved then
		return nil
	end

	local buses = {}
	for bus, gain in resolved.Buses do
		buses[bus] = table.clone(gain)
	end

	return {
		Layers = table.clone(resolved.Layers),
		Buses = buses,
		Main = table.clone(resolved.Main),
		Transition = table.clone(resolved.Transition),
	}
end

--[=[
	@within Presets
	Switches to another platform's preset, tweening to the new mix. Before [Orchestra:Start], this forces the platform
	Start would otherwise detect.

	@param platform "Mobile" | "Desktop" | "Console"
	@return Promise -- Resolves when every tween completes; right away before Start
]=]
function Presets:SetPlatform(platform: Platform)
	assert(tPlatform(platform))

	self.Platform = platform

	if not self._started then
		return Promise.resolve()
	end

	return self:_apply(false)
end

--[=[
	@within Presets
	Sets the output profile: a preset merged on top of the platform preset, for a listening setup the player picks in
	settings (the output device can't be detected). Pass `nil` to clear it. Errors if no preset has that name.

	```lua
	Orchestra.Presets:SetOutputProfile(if settings.Headphones then "Headphones" else nil)
	```

	@param name string? -- A registered preset, or nil
	@return Promise -- Resolves when every tween completes; right away before Start
]=]
function Presets:SetOutputProfile(name: string?)
	assert(t.optional(t.string)(name))

	if name and not self._registry[name] then
		error(string.format("Presets:SetOutputProfile - Unknown preset '%s'", name), 2)
	end

	self.OutputProfile = name

	if not self._started then
		return Promise.resolve()
	end

	return self:_apply(false)
end

-- The preset for the current platform: the mapped name, else one named after the platform, else Base
function Presets:_platformPresetName(): string?
	local platform = self.Platform
	if not platform then
		return nil
	end

	local mapped = self._platformPresets[platform]
	if mapped then
		return mapped
	end

	if self._registry[platform] then
		return platform
	end

	if self._registry.Base then
		return "Base"
	end

	return nil
end

-- Called by Orchestra:Start once the buses exist: picks the platform and applies the mix without tweening
function Presets:_start(platform: Platform?, platformPresets: { [string]: string }?)
	self._platformPresets = if platformPresets then table.clone(platformPresets) else {}
	self.Platform = platform or self.Platform or detectPlatform()
	self._started = true

	self:_apply(true)
end

-- Resolves the layers and sends every bus Fader and Master to its volume
function Presets:_apply(instant: boolean)
	local engine = self._engine
	local resolved = resolve(self._registry, self:GetLayers(), engine:GetBusNames())
	self._resolved = resolved

	local transition = resolved.Transition
	local snap = instant or transition.Time == 0
	local tweenInfo = TweenInfo.new(
		transition.Time,
		transition.EasingStyle or Enum.EasingStyle.Linear,
		transition.EasingDirection or Enum.EasingDirection.InOut
	)

	local promises = {}

	local function send(fader: any, volume: number)
		-- Already there, or a running tween is already heading there
		if not instant and self._applied[fader] == volume then
			return
		end

		self._applied[fader] = volume

		if snap then
			fader:Set(volume)
		else
			table.insert(promises, fader:Tween(volume, tweenInfo))
		end
	end

	for bus, gain in resolved.Buses do
		send(engine.Mixes[bus], gain.Volume)
	end

	send(engine.Master, resolved.Main.Volume)

	return Promise.all(promises)
end

return Presets
