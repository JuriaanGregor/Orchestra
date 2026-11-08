--!nonstrict
-- Demo preset for the test environment. The values make each change easy to hear; they are not mixing advice.

-- TV speakers: a bit more low end, lighter compression
return {
	Extends = "Base",
	Buses = {
		Music = { Inserts = { { Id = "Tone", Props = { LowGain = 4 } } } },
	},
	Main = {
		Inserts = { { Id = "Glue", Props = { Ratio = 1.5 } } },
	},
}
