--!nonstrict
--[[
	Demo presets for trying the preset system in Studio. The values are only there to make each change easy to hear;
	they're not mixing advice.

	- Base, with Mobile, Desktop and Console on top: the platform presets
	- Headphones: an output profile
	- PauseMenu and Underwater: snapshots
]]

local function DemoPresets(engine: any)
	local Effect = engine.Enums.Effect
	local Transform = engine.Enums.Transform
	local Presets = engine.Presets

	Presets:Register({
		Name = "Base",
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
	})

	-- Small speakers: less low end, more compression
	Presets:Register({
		Name = "Mobile",
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
	})

	Presets:Register({
		Name = "Desktop",
		Extends = "Base",
	})

	-- TV speakers: a bit more low end, lighter compression
	Presets:Register({
		Name = "Console",
		Extends = "Base",
		Buses = {
			Music = { Inserts = { { Id = "Tone", Props = { LowGain = 4 } } } },
		},
		Main = {
			Inserts = { { Id = "Glue", Props = { Ratio = 1.5 } } },
		},
	})

	-- Output profile: no bus compression on headphones
	Presets:Register({
		Name = "Headphones",
		Main = {
			Inserts = { { Id = "Glue", Bypass = true } },
		},
	})

	-- Snapshot: duck the music fast, mute SFX
	Presets:Register({
		Name = "PauseMenu",
		Transition = { Time = 0.2 },
		Buses = {
			Music = { Volume = 0.3 },
			SFX = { Volume = 0 },
		},
	})

	-- Snapshot: muffle the music with an extra EQ
	Presets:Register({
		Name = "Underwater",
		Transition = { Time = 0.8 },
		Buses = {
			Music = {
				Inserts = {
					{ Id = "Muffle", Effect = Effect.Equalizer, Props = { HighGain = -40, MidGain = -12 } },
				},
			},
		},
	})
end

return DemoPresets
