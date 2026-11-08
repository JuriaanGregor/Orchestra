--!nonstrict
-- Demo preset for the test environment. The values make each change easy to hear; they are not mixing advice.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Packages.Orchestra).Enums
local Effect = Enums.Effect

-- Snapshot: muffle the music with an extra EQ
return {
	Transition = { Time = 0.8 },
	Buses = {
		Music = {
			Inserts = {
				{ Id = "Muffle", Effect = Effect.Equalizer, Props = { HighGain = -40, MidGain = -12 } },
			},
		},
	},
}
