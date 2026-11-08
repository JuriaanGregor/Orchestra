--!strict

-- Roblox Services
local TweenService = game:GetService("TweenService")

-- Import > Packages
local Dependencies = require("./Dependencies")
local t = Dependencies.t
local Promise = Dependencies.Promise
local Trove = Dependencies.Trove

-- Import > Package
local resolve = require("@self/resolve")
local layers = require("@self/layers")
local diff = require("@self/diff")
local detectPlatform = require("./Utility/detectPlatform")
local Enums = require("./Enums")

export type Definition = resolve.Definition
export type Resolved = resolve.Resolved
export type ResolvedInsert = resolve.ResolvedInsert
export type InsertEntry = resolve.InsertEntry
export type Platform = detectPlatform.Platform

-- How long a chain fades out (and back in) while its inserts are rebuilt
local DIP_TIME = 0.05

-- Properties a preset can't set on an insert: the chain owns these
local RESERVED_PROPS = { Name = true, Parent = true, Archivable = true }

-- t
local tVolume = t.numberConstrained(0, 3)
local function tInsertType(value: any): (boolean, string?)
	if Enums.Effect:BelongsTo(value) or Enums.Transform:BelongsTo(value) then
		return true
	end

	return false, "Effect must be an Enums.Effect or Enums.Transform item"
end
local tInsertEntry = t.strictInterface({
	Id = t.string,
	Effect = t.optional(tInsertType),
	Props = t.optional(t.map(t.string, t.any)),
	Bypass = t.optional(t.boolean),
	Remove = t.optional(t.literal(true)),
	After = t.optional(t.string),
})
local tGain = t.strictInterface({
	Volume = t.optional(tVolume),
	Inserts = t.optional(t.array(tInsertEntry)),
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
local tPush = t.tuple(
	t.string,
	t.optional(t.strictInterface({
		Priority = t.optional(t.number),
	}))
)

-- Copies a gain and its insert entries. Effect items are kept by reference: they're compared by identity
local function copyGain(gain: resolve.Gain): resolve.Gain
	local copy = table.clone(gain)

	if gain.Inserts then
		local inserts = {}
		for _, entry in gain.Inserts do
			local entryCopy = table.clone(entry)
			if entry.Props then
				entryCopy.Props = table.clone(entry.Props)
			end
			table.insert(inserts, entryCopy)
		end
		copy.Inserts = inserts
	end

	return copy
end

-- Copies a definition so later changes to the caller's table don't leak in
local function copyDefinition(definition: Definition): Definition
	local copy = table.clone(definition)

	if definition.Transition then
		copy.Transition = table.clone(definition.Transition)
	end

	if definition.Main then
		copy.Main = copyGain(definition.Main)
	end

	if definition.Buses then
		local buses = {}
		for bus, gain in definition.Buses do
			buses[bus] = copyGain(gain)
		end
		copy.Buses = buses
	end

	return copy
end

---------------------------------------------------------------------
-- Insert properties

-- The Roblox class an Effect or Transform item creates, for example Enums.Effect.Reverb -> AudioReverb
local function classNameOf(effect: any): string
	return "Audio" .. effect.Name
end

-- One unparented instance per class, to read property names and default values from
local templates: { [string]: Instance } = {}

-- Returns whether the class has the property, and its default value
local function defaultOf(className: string, key: string): (boolean, any)
	local template = templates[className]
	if not template then
		template = Instance.new(className :: any)
		templates[className] = template
	end

	return pcall(function()
		return (template :: any)[key]
	end)
end

-- Errors if a property doesn't exist on the insert's class, is reserved, or gets a value of the wrong type
local function checkProps(effect: any, props: { [string]: any }, context: string)
	local className = classNameOf(effect)

	for key, value in props do
		if RESERVED_PROPS[key] then
			error(string.format("%s: '%s' can't be set by a preset", context, key), 0)
		end

		local exists, default = defaultOf(className, key)
		if not exists then
			error(string.format("%s: %s has no property '%s'", context, className, key), 0)
		end

		if typeof(value) ~= typeof(default) then
			error(
				string.format("%s: %s.%s takes a %s, got a %s", context, className, key, typeof(default), typeof(value)),
				0
			)
		end
	end
end

-- Register-time checks on one insert list: unique Ids, and the props of entries that name their Effect
local function checkEntries(entries: { InsertEntry }, presetName: string, where: string)
	local seen = {}

	for _, entry in entries do
		local context = string.format("Preset '%s', %s, insert '%s'", presetName, where, entry.Id)

		if seen[entry.Id] then
			error(string.format("%s: Id is listed twice", context), 0)
		end
		seen[entry.Id] = true

		if entry.Effect and entry.Props then
			checkProps(entry.Effect, entry.Props, context)
		end
	end
end

---------------------------------------------------------------------
local Presets = {}
Presets.__index = Presets

--[=[
	@class Presets
	@tag Engine

	Presets describe a mix as data: a volume and a list of inserts (effects and transforms) per mix bus and for the
	Main layer. Reached through `Orchestra.Presets`.

	The active mix is merged from these layers, later ones winning:

	1. The **platform preset**: picked for the detected [Presets.Platform] (`Mobile`, `Desktop` or `Console`). By
	default that's the preset with the platform's name, falling back to `Base`; `Orchestra:Start({ Presets = ... })`
	maps platforms to other names.
	2. The **output profile**: a preset the player picks in settings, such as `Headphones`, see
	[Presets:SetOutputProfile].
	3. The **snapshots**: temporary states the game pushes and pops, such as `PauseMenu` or `Underwater`, see
	[Presets:Push]. Lowest `Priority` first, so the highest wins.

	A preset can `Extends` another: the parent is merged first. Anything no layer sets stays at volume 1, with no
	inserts.

	```lua
	local Effect = Orchestra.Enums.Effect
	local Transform = Orchestra.Enums.Transform

	Orchestra.Presets:Register({
		Name = "Base",
		Transition = { Time = 0.5 },
		Buses = {
			Music = { Volume = 0.8, Inserts = {
				{ Id = "Tone", Effect = Effect.Equalizer, Props = { LowGain = 0 } },
			} },
		},
		Main = { Inserts = {
			{ Id = "Glue", Effect = Effect.Compressor, Props = { Ratio = 2 } },
			{ Id = "Ceiling", Effect = Transform.Limiter },
		} },
	})

	Orchestra.Presets:Register({
		Name = "Mobile",
		Extends = "Base",
		Buses = {
			Music = { Inserts = { { Id = "Tone", Props = { LowGain = -6 } } } },
		},
		Main = { Inserts = {
			{ Id = "Glue", Props = { Ratio = 4 } },
			{ Id = "Presence", Effect = Effect.Equalizer, After = "Glue", Props = { MidGain = 2 } },
		} },
	})

	Orchestra:Start() -- applies Mobile on phones, Base elsewhere
	```

	**Inserts** merge by `Id`. Each entry is `{ Id, Effect?, Props?, Bypass?, Remove?, After? }`:

	- A new `Id` adds an insert: `Effect` is an [Enums.Effect] or [Enums.Transform] item, `Props` are properties of
	its instance (`AudioEqualizer`, `AudioLimiter`, ...), placed after the insert named by `After` or at the end.
	- A known `Id` changes its `Props`, or turns it off with `Bypass = true` (the instance's `Bypass` property).
	- `Remove = true` takes it out.
	- An insert keeps the type and position it was added with. To change either, remove it and add a new `Id`.

	When the mix changes, numeric properties tween over the `Transition`; other properties switch when it ends. If the
	inserts themselves change, the chain fades out for 0.05 seconds, is rebuilt, and fades back in. Inserts are reused
	by `Id`, and a property no layer sets anymore goes back to its default.

	Presets own the mix bus Faders, Master, and the inserts they create. Use [Orchestra:SetPlayerVolume] for player
	settings, and your own Faders for game logic. Inserts you add to a chain yourself stay after the preset's.
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

--[=[
	@prop Changed RBXScriptSignal
	@within Presets
	@readonly

	Fires after the mix is applied (at Start, and on every change), when the new mix starts tweening, not when the
	tweens end. It passes nothing: call [Presets:GetResolved] for the mix.
]=]

--[=[
	@class SnapshotHandle
	@tag Engine

	A pushed snapshot, returned by [Presets:Push].
]=]

--[=[
	@prop Name string
	@within SnapshotHandle
	@readonly

	The snapshot's preset name.
]=]

--[=[
	@prop Priority number
	@within SnapshotHandle
	@readonly

	Its priority: higher priorities are merged later, so they win.
]=]

--[=[
	@prop Active boolean
	@within SnapshotHandle
	@readonly

	Whether it's still pushed.
]=]

--[=[
	@prop Applied Promise
	@within SnapshotHandle
	@readonly

	Resolves when the push has finished tweening; right away before [Orchestra:Start].
]=]

--[=[
	@function Pop
	@within SnapshotHandle

	Takes the snapshot out of the mix and tweens back. Popping twice does nothing.

	@return Promise -- Resolves when the tweens complete
]=]

type SnapshotEntry = layers.Snapshot & {
	Handle: any,
}

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
	-- The inserts each chain got from presets, by chain key (a bus name, or Main): see _applyInserts
	self._chains = {} :: { [string]: ChainState }

	-- Pushed snapshots, in push order
	self._snapshots = {} :: { SnapshotEntry }
	self._pushCount = 0

	self._changedEvent = Instance.new("BindableEvent")
	self.Changed = self._changedEvent.Event

	self.Platform = nil :: Platform?
	self.OutputProfile = nil :: string?

	return setmetatable(self :: any, Presets)
end

function Presets:__tostring()
	return string.format("Presets<%s, %s>", tostring(self.Platform), tostring(self.OutputProfile))
end

--[=[
	@within Presets
	Registers a preset, replacing any preset with the same name. Errors if the definition is malformed: an unknown
	field, a volume outside 0 - 3, an insert `Id` listed twice in one list, or a property its `Effect` doesn't have.
	Bus names, `Extends`, and the merge rules for inserts are checked when the preset is applied.

	After [Orchestra:Start], the mix is applied again, so re-registering a preset updates the live mix. If the new mix
	doesn't resolve (for example an override names a property its insert doesn't have), the previous definition is put
	back, the live mix is left as it was, and it errors. [Presets:SetPlatform] and [Presets:SetOutputProfile] do the
	same.

	@param definition { Name: string, Extends: string?, Transition: { Time: number?, EasingStyle: Enum.EasingStyle?, EasingDirection: Enum.EasingDirection? }?, Buses: { [string]: { Volume: number?, Inserts: { InsertEntry }? } }?, Main: { Volume: number?, Inserts: { InsertEntry }? }? }
]=]
function Presets:Register(definition: Definition)
	self:_registerAll({ definition }, "Presets:Register")
end

--[=[
	@within Presets
	Registers every preset in a folder: each ModuleScript returns one preset definition. A preset without a `Name` is
	named after its ModuleScript. Folders inside `folder` are searched too; ModuleScripts inside a ModuleScript are
	left alone, so a preset module can keep helpers as children.

	```
	ReplicatedStorage
	└─ Presets
	   ├─ Base          -- return { Buses = { ... } }
	   ├─ Mobile        -- return { Extends = "Base", ... }
	   └─ Snapshots
	      └─ PauseMenu
	```

	```lua
	Orchestra.Presets:RegisterFolder(ReplicatedStorage.Presets)
	Orchestra:Start()
	```

	Every preset is checked before any is registered, and after [Orchestra:Start] the mix is applied once, after all
	of them are in. If one fails (a module errors or returns something else than a table, a definition is malformed, two
	modules use the same name, or the new mix doesn't resolve), none are kept and it errors.

	@param folder Instance
	@return { string } -- The names registered, in the order the modules were found
]=]
function Presets:RegisterFolder(folder: Instance): { string }
	assert(t.Instance(folder))

	local modules: { ModuleScript } = {}
	local function collect(parent: Instance)
		local children = parent:GetChildren()
		table.sort(children, function(a, b)
			return a.Name < b.Name
		end)

		for _, child in children do
			if child:IsA("ModuleScript") then
				table.insert(modules, child)
			elseif child:IsA("Folder") then
				collect(child)
			end
		end
	end
	collect(folder)

	local definitions: { Definition } = {}
	for _, module in modules do
		local loaded, result = pcall(require :: any, module)
		if not loaded then
			error(
				string.format("Presets:RegisterFolder - %s failed to load: %s", module:GetFullName(), tostring(result)),
				2
			)
		end

		if typeof(result) ~= "table" then
			error(
				string.format(
					"Presets:RegisterFolder - %s must return a preset table, got a %s",
					module:GetFullName(),
					typeof(result)
				),
				2
			)
		end

		local definition = table.clone(result)
		if definition.Name == nil then
			definition.Name = module.Name
		end
		table.insert(definitions, definition)
	end

	self:_registerAll(definitions, "Presets:RegisterFolder")

	local names = {}
	for _, definition in definitions do
		table.insert(names, definition.Name)
	end
	return names
end

-- Checks a definition: its shape (t), unique insert Ids, and the props of inserts that name their Effect
local function validateDefinition(definition: any): string?
	local ok, message = tDefinition(definition)
	if not ok then
		local name = if typeof(definition) == "table" and typeof(definition.Name) == "string"
			then definition.Name
			else "?"
		return string.format("Invalid preset '%s': %s", name, tostring(message))
	end

	local checked, checkError = pcall(function()
		if definition.Buses then
			for bus, gain in definition.Buses do
				if gain.Inserts then
					checkEntries(gain.Inserts, definition.Name, string.format("bus '%s'", bus))
				end
			end
		end

		if definition.Main and definition.Main.Inserts then
			checkEntries(definition.Main.Inserts, definition.Name, "Main")
		end
	end)

	return if checked then nil else tostring(checkError)
end

-- Registers definitions all or nothing: each is checked first, then all are stored, and after Start the mix is
-- applied once. If that fails, every previous definition is put back.
function Presets:_registerAll(definitions: { Definition }, context: string)
	local seen: { [string]: boolean } = {}
	for _, definition in definitions do
		local problem = validateDefinition(definition)
		if problem then
			error(string.format("%s - %s", context, problem), 3)
		end

		if seen[definition.Name] then
			error(string.format("%s - Preset '%s' is defined twice", context, definition.Name), 3)
		end
		seen[definition.Name] = true
	end

	-- What each name held before (nil: it wasn't registered), so a restore can put it back
	local registry: { [string]: Definition? } = self._registry
	local previous: { { Name: string, Definition: Definition? } } = {}
	for _, definition in definitions do
		table.insert(previous, { Name = definition.Name, Definition = registry[definition.Name] })
		registry[definition.Name] = table.freeze(copyDefinition(definition))
	end

	if self._started then
		self:_applyOrRestore(function()
			for _, entry in previous do
				registry[entry.Name] = entry.Definition
			end
		end, context, nil, 4)
	end
end

-- Applies the mix with tweens. If the new mix doesn't resolve, `restore` undoes the change that caused it and the
-- error is raised: the live mix is untouched, since every check runs before anything changes
function Presets:_applyOrRestore(restore: () -> (), context: string, transition: resolve.Transition?, level: number?)
	local ok, result = pcall(self._apply, self, false, transition)
	if not ok then
		restore()
		error(string.format("%s - %s", context, tostring(result)), level or 3)
	end

	return result
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
	preset (if any), the output profile (if any), then the snapshots.

	@return { string }
]=]
function Presets:GetLayers(): { string }
	return layers(self:_platformPresetName(), self.OutputProfile, self._snapshots)
end

--[=[
	@within Presets
	Pushes a snapshot: a preset merged on top of everything else until it's popped, for a temporary state such as a
	pause menu or being underwater. Higher `Priority` wins (default 0); on a tie, the later push wins. Pushing a
	snapshot that's already pushed keeps one copy in the mix, at the highest place.

	The push and the pop tween over the snapshot's own `Transition` when it sets one, otherwise over the mix's.
	Before [Orchestra:Start], the snapshot waits and is applied by Start. Errors if no preset has that name, or the
	new mix doesn't resolve (the snapshot is then not pushed).

	A snapshot is usually a small preset without `Extends`: extending `Base` would merge Base over the platform
	preset again.

	```lua
	local paused = Orchestra.Presets:Push("PauseMenu", { Priority = 10 })
	-- later
	paused:Pop()
	```

	@param name string -- A registered preset
	@param options { Priority: number? }?
	@return SnapshotHandle
]=]
function Presets:Push(name: string, options: { Priority: number? }?)
	assert(tPush(name, options))

	if not self._registry[name] then
		error(string.format("Presets:Push - Unknown preset '%s'", name), 2)
	end

	local order: number = (self._pushCount :: number) + 1
	self._pushCount = order

	local handle = {
		Name = name,
		Priority = if options and options.Priority then options.Priority else 0,
		Active = true,
		Applied = nil :: any,
	}

	local entry: SnapshotEntry = {
		Name = name,
		Priority = handle.Priority,
		Order = order,
		Handle = handle,
	}

	local function remove()
		local index = table.find(self._snapshots, entry)
		if index then
			table.remove(self._snapshots, index)
		end
	end

	function handle.Pop(_self: any)
		if not handle.Active then
			return Promise.resolve()
		end

		handle.Active = false
		remove()

		if not self._started then
			return Promise.resolve()
		end

		return self:_applyOrRestore(function()
			handle.Active = true
			table.insert(self._snapshots, entry)
		end, "SnapshotHandle:Pop", self:_transitionOf(name))
	end

	table.insert(self._snapshots, entry)

	if self._started then
		handle.Applied = self:_applyOrRestore(function()
			handle.Active = false
			remove()
		end, "Presets:Push", self:_transitionOf(name))
	else
		handle.Applied = Promise.resolve()
	end

	return handle
end

--[=[
	@within Presets
	Returns the pushed snapshots, in merge order (the last one wins).

	@return { { Name: string, Priority: number } }
]=]
function Presets:GetSnapshots(): { { Name: string, Priority: number } }
	-- A snapshot pushed more than once is listed once, with the highest priority it was pushed with
	local highest: { [string]: number } = {}
	for _, entry in self._snapshots do
		highest[entry.Name] = math.max(highest[entry.Name] or -math.huge, entry.Priority)
	end

	local result = {}
	for _, name in layers(nil, nil, self._snapshots) do
		table.insert(result, { Name = name, Priority = highest[name] })
	end
	return result
end

-- The Transition a preset sets itself, merged up its Extends chain (the preset's own fields win), or nil if none does
function Presets:_transitionOf(name: string): resolve.Transition?
	local merged: { [string]: any } = {}
	local found = false
	local current: string? = name
	local visited: { [string]: boolean } = {}

	while current and not visited[current] do
		visited[current] = true

		local definition = self._registry[current]
		if not definition then
			break
		end

		if definition.Transition then
			found = true
			for key, value in definition.Transition :: any do
				if merged[key] == nil then
					merged[key] = value
				end
			end
		end

		current = definition.Extends
	end

	return if found then merged :: any else nil
end

--[=[
	@within Presets
	Returns the mix as last applied: the merged layers (with `Extends` chains expanded), every bus and the Main layer
	with its volume and inserts, and the transition. `nil` before [Orchestra:Start]. The table is a copy.

	@return { Layers: { string }, Buses: { [string]: { Volume: number, Inserts: { { Id: string, Effect: EnumItem, Props: { [string]: any } } } } }, Main: { Volume: number, Inserts: { { Id: string, Effect: EnumItem, Props: { [string]: any } } } }, Transition: { Time: number } }?
]=]
function Presets:GetResolved(): Resolved?
	local resolved = self._resolved
	if not resolved then
		return nil
	end

	local function copy(gain: resolve.ResolvedGain): resolve.ResolvedGain
		local inserts = {}
		for _, insert in gain.Inserts do
			table.insert(inserts, {
				Id = insert.Id,
				Effect = insert.Effect,
				Props = table.clone(insert.Props),
				Sources = table.clone(insert.Sources),
			})
		end
		return { Volume = gain.Volume, Inserts = inserts }
	end

	local buses = {}
	for bus, gain in resolved.Buses do
		buses[bus] = copy(gain)
	end

	return {
		Layers = table.clone(resolved.Layers),
		Buses = buses,
		Main = copy(resolved.Main),
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

	local previous = self.Platform
	self.Platform = platform

	if not self._started then
		return Promise.resolve()
	end

	return self:_applyOrRestore(function()
		self.Platform = previous
	end, "Presets:SetPlatform")
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

	local previous = self.OutputProfile
	self.OutputProfile = name

	if not self._started then
		return Promise.resolve()
	end

	return self:_applyOrRestore(function()
		self.OutputProfile = previous
	end, "Presets:SetOutputProfile")
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

-- Resolves the layers, then sends every bus Fader and Master to its volume and every chain to its inserts.
-- `transitionOverride` replaces the mix's Transition fields it sets, for a snapshot's push and pop.
function Presets:_apply(instant: boolean, transitionOverride: resolve.Transition?)
	local engine = self._engine
	local resolved = resolve(self._registry, self:GetLayers(), engine:GetBusNames())

	-- Check every insert's props before changing anything: entries that only override props are checked here
	local function checkGain(gain: resolve.ResolvedGain, where: string)
		for _, insert in gain.Inserts do
			-- One prop at a time, so the error names the preset that set it
			for key, value in insert.Props do
				local context =
					string.format("Preset '%s', %s, insert '%s'", insert.Sources[key] or "?", where, insert.Id)
				checkProps(insert.Effect, { [key] = value }, context)
			end
		end
	end

	for bus, gain in resolved.Buses do
		checkGain(gain, string.format("bus '%s'", bus))
	end
	checkGain(resolved.Main, "Main")

	self._resolved = resolved

	local transition = table.clone(resolved.Transition)
	if transitionOverride then
		for key, value in transitionOverride :: any do
			(transition :: any)[key] = value
		end
	end

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

	local function sendInserts(key: string, chain: any, inserts: { ResolvedInsert })
		local promise = self:_applyInserts(key, chain, inserts, if snap then nil else tweenInfo)
		if promise then
			table.insert(promises, promise)
		end
	end

	for bus, gain in resolved.Buses do
		sendInserts("Bus:" .. bus, engine.Inserts[bus], gain.Inserts)
	end

	sendInserts("Main", engine.MainInserts, resolved.Main.Inserts)

	-- No arguments: a BindableEvent copies them, and Effect items are cyclic tables
	self._changedEvent:Fire()

	return Promise.all(promises)
end

---------------------------------------------------------------------
-- Inserts

type LiveInsert = {
	Id: string,
	Effect: any,
	Component: any,
	-- The props the presets set on it, so props that are no longer set go back to their default
	Props: { [string]: any },
}

type ChainState = {
	-- Live inserts in chain order
	Inserts: { LiveInsert },
	-- Cleaned on every apply: cancels the previous apply's dip and property tweens on this chain
	Trove: any,
}

local function isAlive(live: LiveInsert): boolean
	return live.Component.Instance.Parent ~= nil
end

-- Sends an insert to `props`. Props set before but not now go back to their class default. With `tweenInfo`, numbers
-- tween and everything else switches at the end; without it, all switch now.
function Presets:_setProps(state: ChainState, live: LiveInsert, props: { [string]: any }, tweenInfo: TweenInfo?)
	local instance = live.Component.Instance :: any
	local className = instance.ClassName

	local plan = diff.props(live.Props, props, function(key)
		return instance[key]
	end, function(key)
		local _, default = defaultOf(className, key)
		return default
	end, tweenInfo ~= nil)
	live.Props = table.clone(props)

	local tweened = plan.Tween

	local function setLater()
		for key, value in plan.Set do
			instance[key] = value
		end
	end

	if not tweenInfo or next(tweened) == nil then
		setLater()
		return nil
	end

	local promise = Promise.new(function(resolvePromise, _reject, onCancel)
		local tween = TweenService:Create(instance, tweenInfo, tweened)

		local connection
		connection = tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
			connection:Disconnect()
			tween:Destroy()

			if playbackState == Enum.PlaybackState.Completed then
				setLater()
				resolvePromise()
			end
		end)

		onCancel(function()
			connection:Disconnect()
			tween:Cancel()
			tween:Destroy()
		end)

		tween:Play()
	end)

	return state.Trove:AddPromise(promise)
end

-- Creates the component for an insert: an effect or a transform, named after its Id
function Presets:_createInsert(insert: ResolvedInsert, chain: any): any
	local engine = self._engine
	local factory: any = if Enums.Effect:BelongsTo(insert.Effect) then engine.Effects else engine.Transforms

	return factory.new(insert.Effect, chain.Instance, { Name = insert.Id })
end

-- Brings a chain to `inserts`. Same Ids, types and order: props tween in place. Otherwise the chain dips, is rebuilt
-- (reusing inserts by Id and type), and comes back. Without `tweenInfo`, everything happens now.
function Presets:_applyInserts(key: string, chain: any, inserts: { ResolvedInsert }, tweenInfo: TweenInfo?)
	local state = self._chains[key]
	if not state then
		-- Presets never put inserts on this chain: leave it alone
		if #inserts == 0 then
			return nil
		end

		state = { Inserts = {}, Trove = Trove.new() }
		self._chains[key] = state
	end

	local chainState = state :: ChainState
	chainState.Trove:Clean()

	local function plan()
		local live = {}
		for _, current in chainState.Inserts do
			table.insert(live, { Id = current.Id, Effect = current.Effect, Alive = isAlive(current) })
		end
		local targets = {}
		for _, insert in inserts do
			table.insert(targets, { Id = insert.Id, Effect = insert.Effect })
		end
		return diff.chain(live, targets)
	end

	if plan().SameShape then
		local promises = {}

		for index, insert in inserts do
			local promise = self:_setProps(chainState, chainState.Inserts[index], insert.Props, tweenInfo)
			if promise then
				table.insert(promises, promise)
			end
		end

		-- An earlier apply was interrupted mid-dip
		if chain.Fader.Instance.Volume ~= 1 then
			if tweenInfo then
				table.insert(promises, chain.Fader:Tween(1, TweenInfo.new(DIP_TIME)))
			else
				chain.Fader:Set(1)
			end
		end

		return Promise.all(promises)
	end

	-- Planned again when it runs: after a dip, the live state may have changed
	local function rebuild()
		local chainPlan = plan()

		local previous: { [string]: LiveInsert } = {}
		local owned: { [any]: boolean } = {}
		for _, live in chainState.Inserts do
			previous[live.Id] = live
			owned[live.Component] = true
		end

		local nextInserts: { LiveInsert } = {}
		local components = {}

		for index, step in chainPlan.Steps do
			local insert = inserts[index]
			local live: LiveInsert = if step.Reuse
				then previous[step.Id]
				else {
					Id = insert.Id,
					Effect = insert.Effect,
					Component = self:_createInsert(insert, chain),
					Props = {},
				}

			self:_setProps(chainState, live, insert.Props, nil)
			table.insert(nextInserts, live)
			table.insert(components, live.Component)
		end

		-- Inserts added by hand stay after the preset's
		for _, insert in chain:GetInserts() do
			if not owned[insert] then
				table.insert(components, insert)
			end
		end

		-- Discarded inserts still in the chain come back from SetInserts; ones destroyed elsewhere are already gone
		for _, insert in chain:SetInserts(components) do
			insert:Destroy()
		end

		chainState.Inserts = nextInserts
	end

	if not tweenInfo then
		rebuild()
		chain.Fader:Set(1)
		return nil
	end

	local dipInfo = TweenInfo.new(DIP_TIME, Enum.EasingStyle.Linear)

	return chainState.Trove:AddPromise(chain.Fader:Tween(0, dipInfo):andThen(function()
		rebuild()
		return chain.Fader:Tween(1, dipInfo)
	end))
end

return Presets
