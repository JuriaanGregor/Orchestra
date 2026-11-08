--!strict
--[[
	Merges preset layers into one resolved mix. Pure: no Roblox services, no side effects, so it is easy to test.

	Each layer is a preset name. A layer is expanded into its `Extends` chain, root first, and the layers are merged in
	order: later values replace earlier ones. Anything no layer sets keeps its default (volume 1).
]]

export type Gain = {
	Volume: number?,
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

export type Resolved = {
	-- The preset names merged, in order, each with its Extends chain expanded root first
	Layers: { string },
	Buses: { [string]: { Volume: number } },
	Main: { Volume: number },
	Transition: {
		Time: number,
		EasingStyle: Enum.EasingStyle?,
		EasingDirection: Enum.EasingDirection?,
	},
}

local DEFAULT_TRANSITION_TIME = 0.5

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

local function resolve(registry: { [string]: Definition }, layers: { string }, busNames: { string }): Resolved
	local resolved: Resolved = {
		Layers = {},
		Buses = {},
		Main = { Volume = 1 },
		Transition = { Time = DEFAULT_TRANSITION_TIME },
	}

	for _, bus in busNames do
		resolved.Buses[bus] = { Volume = 1 }
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

					if gain.Volume ~= nil then
						target.Volume = gain.Volume
					end
				end
			end

			if definition.Main and definition.Main.Volume ~= nil then
				resolved.Main.Volume = definition.Main.Volume
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
