--!nonstrict
-- Demo preset for the test environment. The values make each change easy to hear; they are not mixing advice.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Packages.Orchestra).Enums
local Effect, Transform = Enums.Effect, Enums.Transform

-- The full mix: every insert the platforms build on
return {
	Transition = { Time = 0.5 },
	Buses = {
		Music = {
			Volume = 1,
			Inserts = {
				{ Id = "Tone", Effect = Effect.Equalizer, Props = { LowGain = 0, MidGain = 0, HighGain = 0 } },
			},
		},
	},
	Main = {
		Volume = 1,
		Inserts = {
			{ Id = "Glue", Effect = Effect.Compressor, Props = { Ratio = 2 } },
			{ Id = "Ceiling", Effect = Transform.Limiter },
		},
	},
}
