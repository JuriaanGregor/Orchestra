--!strict
-- Instance requires: Jest 3.10 doesn't support require-by-string
local JestGlobals = require(game:GetService("ReplicatedStorage").DevPackages.JestGlobals)
local describe, it, expect = JestGlobals.describe, JestGlobals.it, JestGlobals.expect

local resolve = require(script.Parent.resolve)

type Definition = resolve.Definition

local BUSES = { "SFX", "Music", "Dialogue" }

local function registry(definitions: { Definition }): { [string]: Definition }
	local result = {}
	for _, definition in definitions do
		result[definition.Name] = definition
	end
	return result
end

describe("resolve", function()
	it("defaults every bus and Main to volume 1 with no layers", function()
		local resolved = resolve({}, {}, BUSES)

		expect(resolved.Layers).toEqual({})
		expect(resolved.Buses).toEqual({
			SFX = { Volume = 1 },
			Music = { Volume = 1 },
			Dialogue = { Volume = 1 },
		})
		expect(resolved.Main.Volume).toBe(1)
		expect(resolved.Transition.Time).toBe(0.5)
	end)

	it("applies a single preset and keeps defaults for what it leaves out", function()
		local presets = registry({
			{ Name = "Base", Buses = { Music = { Volume = 0.8 } }, Main = { Volume = 0.9 } },
		})

		local resolved = resolve(presets, { "Base" }, BUSES)

		expect(resolved.Buses.Music.Volume).toBe(0.8)
		expect(resolved.Buses.SFX.Volume).toBe(1)
		expect(resolved.Main.Volume).toBe(0.9)
	end)

	it("merges an Extends chain root first, the child winning", function()
		local presets = registry({
			{ Name = "Base", Buses = { Music = { Volume = 0.8 }, Dialogue = { Volume = 1 } } },
			{ Name = "Mobile", Extends = "Base", Buses = { Dialogue = { Volume = 1.2 } } },
		})

		local resolved = resolve(presets, { "Mobile" }, BUSES)

		expect(resolved.Layers).toEqual({ "Base", "Mobile" })
		expect(resolved.Buses.Music.Volume).toBe(0.8)
		expect(resolved.Buses.Dialogue.Volume).toBe(1.2)
	end)

	it("merges layers in order: platform, then output profile", function()
		local presets = registry({
			{ Name = "Base", Buses = { Music = { Volume = 0.8 } }, Main = { Volume = 1 } },
			{ Name = "Desktop", Extends = "Base", Buses = { Music = { Volume = 0.9 } } },
			{ Name = "Headphones", Main = { Volume = 0.7 }, Buses = { Music = { Volume = 0.6 } } },
		})

		local resolved = resolve(presets, { "Desktop", "Headphones" }, BUSES)

		expect(resolved.Layers).toEqual({ "Base", "Desktop", "Headphones" })
		expect(resolved.Buses.Music.Volume).toBe(0.6)
		expect(resolved.Main.Volume).toBe(0.7)
	end)

	it("lets a later layer set a volume back to 0", function()
		local presets = registry({
			{ Name = "Base", Buses = { Music = { Volume = 0.8 } } },
			{ Name = "Silent", Buses = { Music = { Volume = 0 } } },
		})

		expect(resolve(presets, { "Base", "Silent" }, BUSES).Buses.Music.Volume).toBe(0)
	end)

	it("merges Transition field by field", function()
		local presets = registry({
			{ Name = "Base", Transition = { Time = 2, EasingStyle = Enum.EasingStyle.Quad } },
			{ Name = "Mobile", Extends = "Base", Transition = { Time = 1 } },
		})

		local transition = resolve(presets, { "Mobile" }, BUSES).Transition

		expect(transition.Time).toBe(1)
		expect(transition.EasingStyle).toBe(Enum.EasingStyle.Quad)
	end)

	it("errors on an unknown preset", function()
		expect(function()
			resolve({}, { "Nope" }, BUSES)
		end).toThrow("Unknown preset 'Nope'")
	end)

	it("errors when Extends names an unknown preset", function()
		local presets = registry({ { Name = "Mobile", Extends = "Bsae" } })

		expect(function()
			resolve(presets, { "Mobile" }, BUSES)
		end).toThrow("Preset 'Mobile' extends unknown preset 'Bsae'")
	end)

	it("errors on an Extends cycle", function()
		local presets = registry({
			{ Name = "A", Extends = "B" },
			{ Name = "B", Extends = "A" },
		})

		expect(function()
			resolve(presets, { "A" }, BUSES)
		end).toThrow("Preset Extends cycle: A -> B -> A")
	end)

	it("errors on a bus that doesn't exist, listing the buses", function()
		local presets = registry({ { Name = "Base", Buses = { Musik = { Volume = 1 } } } })

		expect(function()
			resolve(presets, { "Base" }, BUSES)
		end).toThrow("Preset 'Base' sets bus 'Musik', which does not exist (buses: Dialogue, Music, SFX)")
	end)
end)
