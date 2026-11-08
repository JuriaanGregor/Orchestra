--!nonstrict
-- Demo snapshot for the test environment: duck the music fast, mute SFX.
return {
	Transition = { Time = 0.2 },
	Buses = {
		Music = { Volume = 0.3 },
		SFX = { Volume = 0 },
	},
}
