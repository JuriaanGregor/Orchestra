--!strict
-- Instance requires: Jest 3.10 doesn't support require-by-string
local JestGlobals = require(game:GetService("ReplicatedStorage").DevPackages.JestGlobals)
local describe, it, expect = JestGlobals.describe, JestGlobals.it, JestGlobals.expect

local diff = require(script.Parent.diff)

-- Stand-ins for Enums items: diff only compares them by identity
local EQ = { Name = "Equalizer" }
local COMPRESSOR = { Name = "Compressor" }
local LIMITER = { Name = "Limiter" }

local function live(id: string, effect: any, alive: boolean?): diff.LiveInsert
	return { Id = id, Effect = effect, Alive = if alive == nil then true else alive }
end

local function target(id: string, effect: any): diff.TargetInsert
	return { Id = id, Effect = effect }
end

describe("diff.chain", function()
	it("is the same shape with the same Ids, types and order", function()
		local plan = diff.chain(
			{ live("Glue", COMPRESSOR), live("Ceiling", LIMITER) },
			{ target("Glue", COMPRESSOR), target("Ceiling", LIMITER) }
		)

		expect(plan.SameShape).toBe(true)
		expect(plan.Steps).toEqual({ { Id = "Glue", Reuse = true }, { Id = "Ceiling", Reuse = true } })
		expect(plan.Discard).toEqual({})
	end)

	it("is the same shape for an empty chain", function()
		expect(diff.chain({}, {}).SameShape).toBe(true)
	end)

	it("rebuilds when an insert is added, reusing the others", function()
		local plan = diff.chain(
			{ live("Glue", COMPRESSOR), live("Ceiling", LIMITER) },
			{ target("Glue", COMPRESSOR), target("Presence", EQ), target("Ceiling", LIMITER) }
		)

		expect(plan.SameShape).toBe(false)
		expect(plan.Steps).toEqual({
			{ Id = "Glue", Reuse = true },
			{ Id = "Presence", Reuse = false },
			{ Id = "Ceiling", Reuse = true },
		})
		expect(plan.Discard).toEqual({})
	end)

	it("rebuilds when an insert is removed, discarding it", function()
		local plan = diff.chain(
			{ live("Glue", COMPRESSOR), live("Presence", EQ), live("Ceiling", LIMITER) },
			{ target("Glue", COMPRESSOR), target("Ceiling", LIMITER) }
		)

		expect(plan.SameShape).toBe(false)
		expect(plan.Steps).toEqual({ { Id = "Glue", Reuse = true }, { Id = "Ceiling", Reuse = true } })
		expect(plan.Discard).toEqual({ "Presence" })
	end)

	it("rebuilds on a new order, reusing every insert", function()
		local plan = diff.chain({ live("A", EQ), live("B", COMPRESSOR) }, { target("B", COMPRESSOR), target("A", EQ) })

		expect(plan.SameShape).toBe(false)
		expect(plan.Steps).toEqual({ { Id = "B", Reuse = true }, { Id = "A", Reuse = true } })
	end)

	it("replaces an insert whose type changed under the same Id", function()
		local plan = diff.chain({ live("Glue", COMPRESSOR) }, { target("Glue", LIMITER) })

		expect(plan.SameShape).toBe(false)
		expect(plan.Steps).toEqual({ { Id = "Glue", Reuse = false } })
		expect(plan.Discard).toEqual({ "Glue" })
	end)

	it("replaces an insert destroyed outside the presets", function()
		local plan = diff.chain(
			{ live("Glue", COMPRESSOR), live("Ceiling", LIMITER, false) },
			{ target("Glue", COMPRESSOR), target("Ceiling", LIMITER) }
		)

		expect(plan.SameShape).toBe(false)
		expect(plan.Steps).toEqual({ { Id = "Glue", Reuse = true }, { Id = "Ceiling", Reuse = false } })
		expect(plan.Discard).toEqual({ "Ceiling" })
	end)
end)

describe("diff.props", function()
	-- Live values and class defaults for an AudioCompressor-like insert
	local defaults = { Ratio = 1, Threshold = -10, Bypass = false }

	local function current(values: { [string]: any }): (string) -> any
		return function(key)
			return values[key]
		end
	end

	local function default(key: string): any
		return defaults[key]
	end

	it("tweens numbers and switches the rest when animating", function()
		local plan = diff.props({}, { Ratio = 4, Bypass = true }, current({ Ratio = 2, Bypass = false }), default, true)

		expect(plan.Tween).toEqual({ Ratio = 4 })
		expect(plan.Set).toEqual({ Bypass = true })
	end)

	it("switches everything when not animating", function()
		local plan = diff.props(
			{},
			{ Ratio = 4, Bypass = true },
			current({ Ratio = 2, Bypass = false }),
			default,
			false
		)

		expect(plan.Tween).toEqual({})
		expect(plan.Set).toEqual({ Ratio = 4, Bypass = true })
	end)

	it("leaves out props already at their goal", function()
		local plan = diff.props({ Ratio = 4 }, { Ratio = 4 }, current({ Ratio = 4 }), default, true)

		expect(plan.Tween).toEqual({})
		expect(plan.Set).toEqual({})
	end)

	it("sends props that are no longer set back to their default", function()
		local plan = diff.props(
			{ Ratio = 4, Bypass = true },
			{ Threshold = -20 },
			current({ Ratio = 4, Bypass = true, Threshold = -10 }),
			default,
			true
		)

		expect(plan.Tween).toEqual({ Ratio = 1, Threshold = -20 })
		expect(plan.Set).toEqual({ Bypass = false })
	end)
end)
