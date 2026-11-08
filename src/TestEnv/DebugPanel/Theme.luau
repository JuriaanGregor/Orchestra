--!strict
-- Colours, fonts and sizes shared by the debug panel's components

return table.freeze({
	Colors = table.freeze({
		Panel = Color3.fromRGB(24, 24, 28),
		Surface = Color3.fromRGB(36, 36, 42),
		Button = Color3.fromRGB(52, 52, 60),
		ButtonHover = Color3.fromRGB(66, 66, 76),
		Accent = Color3.fromRGB(46, 110, 220),
		Text = Color3.fromRGB(235, 235, 240),
		Quiet = Color3.fromRGB(150, 150, 160),
		Meter = Color3.fromRGB(64, 180, 120),
		MeterHot = Color3.fromRGB(230, 160, 60),
		Unity = Color3.fromRGB(200, 200, 210),
	}),

	Fonts = table.freeze({
		Title = Enum.Font.GothamBold,
		Label = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Mono = Enum.Font.RobotoMono,
	}),

	TextSizes = table.freeze({
		Title = 16,
		Body = 13,
		Small = 12,
	}),

	Width = 360,
	Margin = 16,
	Padding = 12,
	Gap = 6,
	CornerRadius = 8,
	ButtonHeight = 28,
	RowHeight = 18,

	-- Faders go up to 3; the meter is scaled to that, with a mark at 1 (unity)
	MaxVolume = 3,
})
