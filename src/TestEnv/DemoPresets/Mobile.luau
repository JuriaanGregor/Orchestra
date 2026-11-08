--!nonstrict
-- Demo preset for the test environment. The values make each change easy to hear; they are not mixing advice.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Packages.Orchestra).Enums
local Effect = Enums.Effect

-- Small speakers: less low end, more compression, a presence boost
return {
	Extends = "Base",
	Buses = {
		Music = { Inserts = { { Id = "Tone", Props = { LowGain = -12, HighGain = 2 } } } },
	},
	Main = {
		Inserts = {
			{ Id = "Glue", Props = { Ratio = 6 } },
			{ Id = "Presence", Effect = Effect.Equalizer, After = "Glue", Props = { MidGain = 3 } },
		},
	},
}
