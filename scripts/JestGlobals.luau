--!strict
--[[
	Stand-in for jsdotlua/jest-globals, mounted at ReplicatedStorage.DevPackages.JestGlobals by test.project.json.

	Jest intercepts require() of any module named JestGlobals and returns its globals (describe, it, expect, jest)
	instead of running it. The real package can't be installed next to Orchestra's dependencies (Wally refuses a dev
	dependency shared with a non-dev one), so this module only needs to exist. Required outside Jest, it errors.
]]

return setmetatable({}, {
	__index = function(_, key)
		error(string.format("JestGlobals.%s is only available inside a Jest test run", tostring(key)), 2)
	end,
}) :: any
