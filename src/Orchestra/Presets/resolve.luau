--!strict
--[[
	Merges preset layers into one resolved mix. Pure: no Roblox services, no side effects, so it is easy to test.

	Each layer is a preset name. A layer is expanded into its `Extends` chain, root first, and the layers are merged in
	order: later values replace earlier ones. Anything no layer sets keeps its default (volume 1, no inserts).

	Insert lists merge by `Id`:
	- a known Id merges its `Props` and `Bypass` into the insert
	- a new Id adds an insert (it needs an `Effect`), after the insert named by `After`, or at the end
	- `Remove = true` takes an insert out
	An insert keeps the type and position it was added with: changing either means removing it and adding a new Id.
]]

export type InsertEntry = {
	Id: string,
	-- An Enums.Effect or Enums.Transform item
	Effect: any?,
	Props: { [string]: any }?,
	Bypass: boolean?,
	Remove: boolean?,
	After: string?,
}

export type Gain = {
	Volume: number?,
	Inserts: { InsertEntry }?,
}

export type Transition = {
	Time: number?,
	EasingStyle: Enum.EasingStyle?,
	EasingDirection: Enum.EasingDirection?,
}

export type Definition = {
	Name: string,
	Extends: string?,
	Transition: Transition?,
	Buses: { [string]: Gain }?,
	Main: Gain?,
}

export type ResolvedInsert = {
	Id: string,
	Effect: any,
	-- Every property a layer set, `Bypass` included
	Props: { [string]: any },
	-- The preset that last set each property, for error messages
	Sources: { [string]: string },
}

export type ResolvedGain = {
	Volume: number,
	Inserts: { ResolvedInsert },
}

export type Resolved = {
	-- The preset names merged, in order, each with its Extends chain expanded root first
	Layers: { string },
	Buses: { [string]: ResolvedGain },
	Main: ResolvedGain,
	Transition: {
		Time: number,
		EasingStyle: Enum.EasingStyle?,
		EasingDirection: Enum.EasingDirection?,
	},
}

local DEFAULT_TRANSITION_TIME = 0.5

local function effectName(effect: any): string
	return if typeof(effect) == "table" and typeof(effect.Name) == "string" then effect.Name else tostring(effect)
end

-- Returns the preset and everything it extends, root first. Errors on an unknown preset or an Extends cycle.
local function expand(registry: { [string]: Definition }, name: string): { Definition }
	local chain: { Definition } = {}
	local path: { string } = {}
	local current: string? = name

	while current do
		if table.find(path, current) then
			table.insert(path, current)
			error(string.format("Preset Extends cycle: %s", table.concat(path, " -> ")), 0)
		end

		local definition = registry[current]
		if not definition then
			if #path == 0 then
				error(string.format("Unknown preset '%s'", current), 0)
			end

			error(string.format("Preset '%s' extends unknown preset '%s'", path[#path], current), 0)
		end

		table.insert(path, current)
		table.insert(chain, 1, definition)
		current = definition.Extends
	end

	return chain
end

local function findInsert(inserts: { ResolvedInsert }, id: string): number?
	for index, insert in inserts do
		if insert.Id == id then
			return index
		end
	end

	return nil
end

-- Merges one preset's insert entries into `inserts`, in place. `where` names the bus for error messages.
local function mergeInserts(inserts: { ResolvedInsert }, entries: { InsertEntry }, presetName: string, where: string)
	local function fail(message: string, ...: any)
		error(string.format("Preset '%s', %s: " .. message, presetName, where, ...), 0)
	end

	for _, entry in entries do
		local index = findInsert(inserts, entry.Id)

		if entry.Remove then
			if entry.Effect ~= nil or entry.Props ~= nil or entry.Bypass ~= nil or entry.After ~= nil then
				fail("insert '%s' has Remove and other fields; Remove takes only the Id", entry.Id)
			end

			if not index then
				fail("removes insert '%s', which isn't there", entry.Id)
			end

			table.remove(inserts, index :: number)
			continue
		end

		if index then
			local insert = inserts[index]

			if entry.Effect ~= nil and entry.Effect ~= insert.Effect then
				fail(
					"changes insert '%s' from %s to %s; remove it and add one with a new Id",
					entry.Id,
					effectName(insert.Effect),
					effectName(entry.Effect)
				)
			end

			if entry.After ~= nil then
				fail("moves insert '%s' with After; an insert keeps the position it was added with", entry.Id)
			end

			if entry.Props then
				for key, value in entry.Props do
					insert.Props[key] = value
					insert.Sources[key] = presetName
				end
			end

			if entry.Bypass ~= nil then
				insert.Props.Bypass = entry.Bypass
				insert.Sources.Bypass = presetName
			end

			continue
		end

		if entry.Effect == nil then
			fail("adds insert '%s' without an Effect", entry.Id)
		end

		local insert: ResolvedInsert = { Id = entry.Id, Effect = entry.Effect, Props = {}, Sources = {} }

		if entry.Props then
			for key, value in entry.Props do
				insert.Props[key] = value
				insert.Sources[key] = presetName
			end
		end

		if entry.Bypass ~= nil then
			insert.Props.Bypass = entry.Bypass
			insert.Sources.Bypass = presetName
		end

		if entry.After ~= nil then
			local after = findInsert(inserts, entry.After)
			if not after then
				fail("places insert '%s' after '%s', which isn't there", entry.Id, entry.After)
			end

			table.insert(inserts, (after :: number) + 1, insert)
		else
			table.insert(inserts, insert)
		end
	end
end

local function resolve(registry: { [string]: Definition }, layers: { string }, busNames: { string }): Resolved
	local resolved: Resolved = {
		Layers = {},
		Buses = {},
		Main = { Volume = 1, Inserts = {} },
		Transition = { Time = DEFAULT_TRANSITION_TIME },
	}

	for _, bus in busNames do
		resolved.Buses[bus] = { Volume = 1, Inserts = {} }
	end

	local function mergeGain(target: ResolvedGain, gain: Gain, presetName: string, where: string)
		if gain.Volume ~= nil then
			target.Volume = gain.Volume
		end

		if gain.Inserts then
			mergeInserts(target.Inserts, gain.Inserts, presetName, where)
		end
	end

	for _, layer in layers do
		for _, definition in expand(registry, layer) do
			table.insert(resolved.Layers, definition.Name)

			if definition.Buses then
				for bus, gain in definition.Buses do
					local target = resolved.Buses[bus]
					if not target then
						local known = table.clone(busNames)
						table.sort(known)
						error(
							string.format(
								"Preset '%s' sets bus '%s', which does not exist (buses: %s)",
								definition.Name,
								bus,
								table.concat(known, ", ")
							),
							0
						)
					end

					mergeGain(target, gain, definition.Name, string.format("bus '%s'", bus))
				end
			end

			if definition.Main then
				mergeGain(resolved.Main, definition.Main, definition.Name, "Main")
			end

			local transition = definition.Transition
			if transition then
				if transition.Time ~= nil then
					resolved.Transition.Time = transition.Time
				end

				if transition.EasingStyle ~= nil then
					resolved.Transition.EasingStyle = transition.EasingStyle
				end

				if transition.EasingDirection ~= nil then
					resolved.Transition.EasingDirection = transition.EasingDirection
				end
			end
		end
	end

	return resolved
end

return resolve
