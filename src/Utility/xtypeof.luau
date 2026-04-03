--!strict
--!nolint LocalUnused
--!nolint LocalShadow

local function xtypeof(x: unknown): string
	local typeOf = typeof(x)
	if typeOf == "table" then
		local metaInfo = x :: { type: unknown }
		if typeof(metaInfo.type) == "string" then
			return metaInfo.type
		end
	end

	return typeOf
end

return xtypeof
