--!strict
--[[
	Orders the preset layers to merge, lowest first. Pure, so it is easy to test.

	1. the platform preset
	2. the output profile
	3. the snapshots: lowest Priority first; on a tie, the one pushed first. A snapshot pushed more than once is merged
	   once, at its highest place, so its inserts aren't added twice.
]]

export type Snapshot = {
	Name: string,
	Priority: number,
	-- Push order, counting up
	Order: number,
}

local function layers(platformPreset: string?, outputProfile: string?, snapshots: { Snapshot }): { string }
	local result: { string } = {}

	if platformPreset then
		table.insert(result, platformPreset)
	end

	if outputProfile then
		table.insert(result, outputProfile)
	end

	local sorted = table.clone(snapshots)
	table.sort(sorted, function(a, b)
		if a.Priority ~= b.Priority then
			return a.Priority < b.Priority
		end

		return a.Order < b.Order
	end)

	-- Walk from the top, keeping each name's highest place, then put them back lowest first
	local seen: { [string]: boolean } = {}
	local kept: { string } = {}
	for index = #sorted, 1, -1 do
		local name = sorted[index].Name
		if not seen[name] then
			seen[name] = true
			table.insert(kept, 1, name)
		end
	end

	table.move(kept, 1, #kept, #result + 1, result)

	return result
end

return layers
