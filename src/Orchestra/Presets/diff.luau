--!strict
--[[
	Plans how to bring the live mix to a resolved one. Pure: the caller reads the live state, passes it in, and carries
	out the plan, so this is easy to test.

	- chain: compares a chain's live inserts with the resolved ones. Same shape (same Ids, types and order, all still
	  alive) means props change in place; anything else means a rebuild, reusing inserts by Id and type.
	- props: works out which properties of one insert tween and which switch outright. Properties presets set before
	  but not now go back to their default.
]]

export type LiveInsert = {
	Id: string,
	Effect: any,
	-- False when its instance was destroyed outside the presets
	Alive: boolean,
}

export type TargetInsert = {
	Id: string,
	Effect: any,
}

export type ChainStep = {
	Id: string,
	-- True: keep the live insert with this Id. False: create a new one
	Reuse: boolean,
}

export type ChainPlan = {
	SameShape: boolean,
	-- One per target insert, in chain order
	Steps: { ChainStep },
	-- Ids of live inserts that aren't reused, in chain order
	Discard: { string },
}

export type PropPlan = {
	-- Numbers that tween
	Tween: { [string]: number },
	-- Everything else: switched when the tween ends, or right away when nothing tweens
	Set: { [string]: any },
}

local function chain(live: { LiveInsert }, target: { TargetInsert }): ChainPlan
	local sameShape = #live == #target
	if sameShape then
		for index, insert in target do
			local current = live[index]
			if current.Id ~= insert.Id or current.Effect ~= insert.Effect or not current.Alive then
				sameShape = false
				break
			end
		end
	end

	local liveById: { [string]: LiveInsert } = {}
	for _, current in live do
		liveById[current.Id] = current
	end

	local steps: { ChainStep } = {}
	local reused: { [string]: boolean } = {}
	for _, insert in target do
		local current = liveById[insert.Id]
		local reuse = current ~= nil and current.Effect == insert.Effect and current.Alive
		if reuse then
			reused[insert.Id] = true
		end
		table.insert(steps, { Id = insert.Id, Reuse = reuse })
	end

	local discard: { string } = {}
	for _, current in live do
		if not reused[current.Id] then
			table.insert(discard, current.Id)
		end
	end

	return { SameShape = sameShape, Steps = steps, Discard = discard }
end

local function props(
	previous: { [string]: any },
	target: { [string]: any },
	current: (key: string) -> any,
	default: (key: string) -> any,
	animate: boolean
): PropPlan
	local goals: { [string]: any } = {}
	for key in previous do
		goals[key] = default(key)
	end
	for key, value in target do
		goals[key] = value
	end

	local plan: PropPlan = { Tween = {}, Set = {} }
	for key, value in goals do
		if current(key) == value then
			continue
		end

		if animate and typeof(value) == "number" then
			plan.Tween[key] = value
		else
			plan.Set[key] = value
		end
	end

	return plan
end

return table.freeze({
	chain = chain,
	props = props,
})
