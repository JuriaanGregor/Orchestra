--!strict
-- Instance requires: Jest 3.10 doesn't support require-by-string
local JestGlobals = require(game:GetService("ReplicatedStorage").DevPackages.JestGlobals)
local describe, it, expect = JestGlobals.describe, JestGlobals.it, JestGlobals.expect

local layers = require(script.Parent.layers)

describe("layers", function()
	it("is empty with nothing active", function()
		expect(layers(nil, nil, {})).toEqual({})
	end)

	it("puts the platform preset first, then the output profile", function()
		expect(layers("Mobile", "Headphones", {})).toEqual({ "Mobile", "Headphones" })
		expect(layers(nil, "Headphones", {})).toEqual({ "Headphones" })
	end)

	it("puts snapshots last, lowest Priority first", function()
		local result = layers("Desktop", nil, {
			{ Name = "Cutscene", Priority = 20, Order = 1 },
			{ Name = "PauseMenu", Priority = 10, Order = 2 },
		})

		expect(result).toEqual({ "Desktop", "PauseMenu", "Cutscene" })
	end)

	it("orders snapshots with the same Priority by push order", function()
		local result = layers(nil, nil, {
			{ Name = "B", Priority = 0, Order = 2 },
			{ Name = "A", Priority = 0, Order = 1 },
		})

		expect(result).toEqual({ "A", "B" })
	end)

	it("merges a snapshot pushed twice once, at its highest place", function()
		local result = layers(nil, nil, {
			{ Name = "Underwater", Priority = 0, Order = 1 },
			{ Name = "PauseMenu", Priority = 0, Order = 2 },
			{ Name = "Underwater", Priority = 0, Order = 3 },
		})

		expect(result).toEqual({ "PauseMenu", "Underwater" })
	end)

	it("doesn't reorder the snapshots it was given", function()
		local snapshots = {
			{ Name = "B", Priority = 5, Order = 1 },
			{ Name = "A", Priority = 1, Order = 2 },
		}

		layers(nil, nil, snapshots)

		expect(snapshots[1].Name).toBe("B")
	end)
end)
