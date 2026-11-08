--!strict
local function lin2dB(linear: number): number
	return math.clamp(math.log10(linear) * 20.0, -80.0, 0.0)
end

return {
	Lin2DB = lin2dB,
}
