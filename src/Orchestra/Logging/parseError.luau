--!strict
--!nolint LocalUnused
--!nolint LocalShadow

local Types = require("../Types")

local function parseError(err: string): Types.Error
	return {
		type = "Error",
		raw = err,
		message = err:gsub("^.+:%d+:%s*", ""),
		trace = debug.traceback(nil, 2),
		context = nil,
	}
end

return parseError
