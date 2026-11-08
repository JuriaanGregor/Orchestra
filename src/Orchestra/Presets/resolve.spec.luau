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
			SFX = { Volume = 1, Inserts = {} },
			Music = { Volume = 1, Inserts = {} },
			Dialogue = { Volume = 1, Inserts = {} },
		})
		expect(resolved.Main).toEqual({ Volume = 1, Inserts = {} })
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

-- Stand-ins for Enums items: resolve only compares them by identity and reads their Name
local EQ = { Name = "Equalizer" }
local COMPRESSOR = { Name = "Compressor" }
local LIMITER = { Name = "Limiter" }

local function ids(inserts: { resolve.ResolvedInsert }): { string }
	local result = {}
	for _, insert in inserts do
		table.insert(result, insert.Id)
	end
	return result
end

describe("resolve inserts", function()
	local base: Definition = {
		Name = "Base",
		Buses = {
			Music = { Inserts = { { Id = "Tone", Effect = EQ, Props = { LowGain = 0, HighGain = 1 } } } },
		},
		Main = {
			Inserts = {
				{ Id = "Glue", Effect = COMPRESSOR, Props = { Ratio = 2 } },
				{ Id = "Ceiling", Effect = LIMITER },
			} :: { resolve.InsertEntry },
		},
	}

	it("keeps a preset's inserts in order", function()
		local resolved = resolve(registry({ base }), { "Base" }, BUSES)

		expect(ids(resolved.Main.Inserts)).toEqual({ "Glue", "Ceiling" })
		expect(resolved.Main.Inserts[1].Effect).toBe(COMPRESSOR)
		expect(resolved.Main.Inserts[2].Props).toEqual({})
		expect(resolved.Buses.Music.Inserts[1].Props).toEqual({ LowGain = 0, HighGain = 1 })
	end)

	it("merges props by Id, keeping props the override leaves out", function()
		local mobile: Definition = {
			Name = "Mobile",
			Extends = "Base",
			Buses = { Music = { Inserts = { { Id = "Tone", Props = { LowGain = -6 } } } } },
		}

		local resolved = resolve(registry({ base, mobile }), { "Mobile" }, BUSES)

		expect(resolved.Buses.Music.Inserts[1].Props).toEqual({ LowGain = -6, HighGain = 1 })
		expect(resolved.Buses.Music.Inserts[1].Effect).toBe(EQ)
	end)

	it("merges Bypass into the props", function()
		local quiet: Definition = { Name = "Quiet", Main = { Inserts = { { Id = "Glue", Bypass = true } } } }

		local resolved = resolve(registry({ base, quiet }), { "Base", "Quiet" }, BUSES)

		expect(resolved.Main.Inserts[1].Props).toEqual({ Ratio = 2, Bypass = true })
	end)

	it("records which preset last set each prop", function()
		local mobile: Definition = {
			Name = "Mobile",
			Extends = "Base",
			Buses = { Music = { Inserts = { { Id = "Tone", Props = { LowGain = -6 }, Bypass = false } } } },
		}

		local resolved = resolve(registry({ base, mobile }), { "Mobile" }, BUSES)

		expect(resolved.Buses.Music.Inserts[1].Sources).toEqual({
			LowGain = "Mobile",
			HighGain = "Base",
			Bypass = "Mobile",
		})
	end)

	it("adds a new insert at the end, or after the one named by After", function()
		local mobile: Definition = {
			Name = "Mobile",
			Extends = "Base",
			Main = {
				Inserts = {
					{ Id = "Presence", Effect = EQ, After = "Glue", Props = { MidGain = 2 } },
					{ Id = "Last", Effect = EQ },
				} :: { resolve.InsertEntry },
			},
		}

		local resolved = resolve(registry({ base, mobile }), { "Mobile" }, BUSES)

		expect(ids(resolved.Main.Inserts)).toEqual({ "Glue", "Presence", "Ceiling", "Last" })
	end)

	it("removes an insert with Remove, and a later layer can add the Id back", function()
		local mobile: Definition =
			{ Name = "Mobile", Extends = "Base", Main = { Inserts = { { Id = "Glue", Remove = true } } } }
		local again: Definition = { Name = "Again", Main = { Inserts = { { Id = "Glue", Effect = LIMITER } } } }
		local presets = registry({ base, mobile, again })

		expect(ids(resolve(presets, { "Mobile" }, BUSES).Main.Inserts)).toEqual({ "Ceiling" })

		local resolved = resolve(presets, { "Mobile", "Again" }, BUSES)
		expect(ids(resolved.Main.Inserts)).toEqual({ "Ceiling", "Glue" })
		expect(resolved.Main.Inserts[2].Effect).toBe(LIMITER)
	end)

	it("doesn't let a later layer change the props of the earlier preset's tables", function()
		local mobile: Definition = {
			Name = "Mobile",
			Extends = "Base",
			Buses = { Music = { Inserts = { { Id = "Tone", Props = { LowGain = -6 } } } } },
		}
		local presets = registry({ base, mobile })

		resolve(presets, { "Mobile" }, BUSES)

		expect(resolve(presets, { "Base" }, BUSES).Buses.Music.Inserts[1].Props.LowGain).toBe(0)
	end)

	it("errors when a new insert has no Effect", function()
		local bad: Definition = { Name = "Bad", Main = { Inserts = { { Id = "Nope" } } } }

		expect(function()
			resolve(registry({ bad }), { "Bad" }, BUSES)
		end).toThrow("Preset 'Bad', Main: adds insert 'Nope' without an Effect")
	end)

	it("errors when an override changes an insert's type", function()
		local bad: Definition = { Name = "Bad", Main = { Inserts = { { Id = "Glue", Effect = LIMITER } } } }

		expect(function()
			resolve(registry({ base, bad }), { "Base", "Bad" }, BUSES)
		end).toThrow("changes insert 'Glue' from Compressor to Limiter")
	end)

	it("errors when an override moves an insert", function()
		local bad: Definition = { Name = "Bad", Main = { Inserts = { { Id = "Ceiling", After = "Glue" } } } }

		expect(function()
			resolve(registry({ base, bad }), { "Base", "Bad" }, BUSES)
		end).toThrow("moves insert 'Ceiling' with After")
	end)

	it("errors when After names a missing insert", function()
		local bad: Definition = { Name = "Bad", Main = { Inserts = { { Id = "New", Effect = EQ, After = "Gleu" } } } }

		expect(function()
			resolve(registry({ base, bad }), { "Base", "Bad" }, BUSES)
		end).toThrow("places insert 'New' after 'Gleu', which isn't there")
	end)

	it("errors when Remove names a missing insert, or comes with other fields", function()
		local missing: Definition =
			{ Name = "Missing", Buses = { SFX = { Inserts = { { Id = "Tone", Remove = true } } } } }
		local mixed: Definition =
			{ Name = "Mixed", Main = { Inserts = { { Id = "Glue", Remove = true, Bypass = true } } } }
		local presets = registry({ base, missing, mixed })

		expect(function()
			resolve(presets, { "Base", "Missing" }, BUSES)
		end).toThrow("Preset 'Missing', bus 'SFX': removes insert 'Tone', which isn't there")

		expect(function()
			resolve(presets, { "Base", "Mixed" }, BUSES)
		end).toThrow("insert 'Glue' has Remove and other fields")
	end)
end)
