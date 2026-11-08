--!strict
--[[
	Bridges the engine into Fusion state for the debug panel.

	The engine isn't reactive, so two counters stand in for change:
	- `mixRevision` moves when Presets.Changed fires: the layers and the shape of the mix changed
	- `liveRevision` moves a few times a second: volumes and insert properties may be mid-tween

	Getters build Computeds in the caller's scope. Primitive results (a volume, a formatted value) only reach their
	dependents when they actually change, so a tick redraws only what moved.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local peek = Fusion.peek

type Scope = Fusion.Scope<typeof(Fusion)>

-- How often live values are read, in seconds
local POLL_INTERVAL = 0.1

-- The Main layer is shown like a bus, under this key
local MAIN_KEY = "Main"

export type MixState = {
	MainKey: string,

	Platform: Fusion.StateObject<string>,
	OutputProfile: Fusion.StateObject<string?>,
	Layers: Fusion.StateObject<string>,
	Snapshots: Fusion.StateObject<string>,
	BusNames: Fusion.StateObject<{ string }>,

	-- The live volume of a bus fader, or of Master for MainKey
	VolumeOf: (scope: Scope, key: string) -> Fusion.Computed<number>,
	-- The Ids of the preset inserts on a chain, in chain order
	InsertIdsOf: (scope: Scope, key: string) -> Fusion.Computed<{ string }>,
	-- The props presets set on an insert, sorted
	PropKeysOf: (scope: Scope, key: string, id: string) -> Fusion.Computed<{ string }>,
	-- The live value of one of those props, formatted
	PropValueOf: (scope: Scope, key: string, id: string, prop: string) -> Fusion.Computed<string>,
	IsSnapshotActive: (scope: Scope, name: string) -> Fusion.Computed<boolean>,

	SetPlatform: (platform: string) -> (),
	ToggleOutputProfile: (name: string) -> (),
	ToggleSnapshot: (name: string, priority: number) -> (),
}

local function formatValue(value: any): string
	if typeof(value) == "number" then
		return string.format("%.2f", value)
	end
	return tostring(value)
end

local function MixState(scope: Scope, engine: any): MixState
	local presets = engine.Presets

	local mixRevision = scope:Value(0)
	local liveRevision = scope:Value(0)

	local function bump(revision: Fusion.Value<number>)
		revision:set(peek(revision) + 1)
	end

	table.insert(
		scope,
		presets.Changed:Connect(function()
			bump(mixRevision)
		end)
	)

	local elapsed = 0
	table.insert(
		scope,
		RunService.Heartbeat:Connect(function(deltaTime: number)
			elapsed += deltaTime
			if elapsed >= POLL_INTERVAL then
				elapsed = 0
				bump(liveRevision)
			end
		end)
	)

	-- Pushed snapshot handles by name, so a toggle can pop what it pushed
	local handles: { [string]: any } = {}

	local resolved = scope:Computed(function(use)
		use(mixRevision)
		return presets:GetResolved()
	end)

	local function gainOf(use: Fusion.Use, key: string): any
		local mix = use(resolved)
		if not mix then
			return nil
		end
		return if key == MAIN_KEY then mix.Main else mix.Buses[key]
	end

	local function chainOf(key: string): any
		return if key == MAIN_KEY then engine.MainInserts else engine.Inserts[key]
	end

	local function insertOf(use: Fusion.Use, key: string, id: string): any
		local gain = gainOf(use, key)
		if not gain then
			return nil
		end
		for _, insert in gain.Inserts do
			if insert.Id == id then
				return insert
			end
		end
		return nil
	end

	local state: MixState = {
		MainKey = MAIN_KEY,

		Platform = scope:Computed(function(use)
			use(mixRevision)
			return tostring(presets.Platform)
		end),

		OutputProfile = scope:Computed(function(use)
			use(mixRevision)
			return presets.OutputProfile
		end),

		Layers = scope:Computed(function(use)
			local mix = use(resolved)
			return if mix then table.concat(mix.Layers, " > ") else "-"
		end),

		Snapshots = scope:Computed(function(use)
			use(mixRevision)
			local names = {}
			for _, snapshot in presets:GetSnapshots() do
				table.insert(names, string.format("%s (%d)", snapshot.Name, snapshot.Priority))
			end
			return if #names > 0 then table.concat(names, ", ") else "-"
		end),

		BusNames = scope:Computed(function(use)
			use(mixRevision)
			return engine:GetBusNames()
		end),

		VolumeOf = function(innerScope: Scope, key: string)
			return innerScope:Computed(function(use)
				use(liveRevision)
				local fader = if key == MAIN_KEY then engine.Master else engine.Mixes[key]
				return if fader then fader.Instance.Volume else 0
			end)
		end,

		InsertIdsOf = function(innerScope: Scope, key: string)
			return innerScope:Computed(function(use)
				local gain = gainOf(use, key)
				local ids = {}
				for _, insert in if gain then gain.Inserts else {} do
					table.insert(ids, insert.Id)
				end
				return ids
			end)
		end,

		PropKeysOf = function(innerScope: Scope, key: string, id: string)
			return innerScope:Computed(function(use)
				local insert = insertOf(use, key, id)
				local keys = {}
				for prop in if insert then insert.Props else {} do
					table.insert(keys, prop)
				end
				table.sort(keys)
				return keys
			end)
		end,

		PropValueOf = function(innerScope: Scope, key: string, id: string, prop: string)
			return innerScope:Computed(function(use)
				use(liveRevision)
				for _, insert in chainOf(key):GetInserts() do
					if insert.Instance.Name == id then
						return formatValue((insert.Instance :: any)[prop])
					end
				end
				return "?"
			end)
		end,

		IsSnapshotActive = function(innerScope: Scope, name: string)
			return innerScope:Computed(function(use)
				use(mixRevision)
				local handle = handles[name]
				return handle ~= nil and handle.Active
			end)
		end,

		SetPlatform = function(platform: string)
			presets:SetPlatform(platform)
		end,

		ToggleOutputProfile = function(name: string)
			presets:SetOutputProfile(if presets.OutputProfile == name then nil else name)
		end,

		ToggleSnapshot = function(name: string, priority: number)
			local handle = handles[name]
			if handle and handle.Active then
				handle:Pop()
				handles[name] = nil
			else
				handles[name] = presets:Push(name, { Priority = priority })
			end
		end,
	}

	return state
end

return MixState
