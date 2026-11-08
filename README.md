# Orchestra

**Orchestra** is a Roblox audio framework written in Luau. It wraps Roblox's Audio API instances (`AudioPlayer`, `AudioFader`, `AudioEmitter`, `Wire`, ...) in components you wire together, like a DAW or a mixing desk. On the client it builds a mixer for you: one bus per sound category (`SFX`, `Music`, `UI`, ...), feeding into a Master fader. Every bus, and the Main layer before Master, has an insert chain for effects:

```
Listener:<bus> -> Inserts:<bus> -> MixBus:<bus> -> Trim:<bus> -> Inserts:Main -> Master -> MainOut
```

> **Status:** early development (`v0.1.0`). The API may still change.

## Installation

Add Orchestra to your `wally.toml` and run `wally install`:

```toml
[dependencies]
Orchestra = "juriaan/orchestra@0.1.0"
```

## Getting started

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Orchestra = require(ReplicatedStorage.Packages.Orchestra)
local Enums = Orchestra.Enums

-- Builds the mixer (client only). Requiring Orchestra has no side effects.
Orchestra:Start()

local speaker = workspace.Speaker

local music = Orchestra.Layer.new(Enums.Stream.Player, speaker, { Asset = "rbxassetid://15287092994" })
local reverb = Orchestra.Effects.new(Enums.Effect.Reverb, speaker)
local emitter = Orchestra.Output.new(Enums.Output.Emitter, speaker, { AudioInteractionGroup = "Music" })

music.Routing:WireTo(reverb.In)
reverb.Routing:WireTo(emitter.In)

music:Play()
music.Fader:FadeIn(2)
```

The emitter's `AudioInteractionGroup` picks the mix bus it plays through.

Add effects to a bus, or to the whole mix, through its insert chain. Player volume settings go on the trim faders:

```lua
local chain = Orchestra.Inserts.Music
chain:Add(Orchestra.Effects.new(Enums.Effect.Equalizer, chain.Instance, { Name = "Tone" }))

Orchestra.MainInserts:Add(Orchestra.Transforms.new(Enums.Transform.Limiter, Orchestra.MainInserts.Instance))

Orchestra:SetPlayerVolume("Music", 0.5)
```

### Presets

Presets set the bus and Main (Master) volumes per platform. Register them before `Start()`; Start detects the platform (`Mobile`, `Desktop` or `Console`) and applies the preset with that name, falling back to `Base`. A player-picked output profile, such as `Headphones`, goes on top:

```lua
Orchestra.Presets:Register({ Name = "Base", Buses = { Music = { Volume = 0.8 } } })
Orchestra.Presets:Register({ Name = "Mobile", Extends = "Base", Buses = { Dialogue = { Volume = 1.2 } } })
Orchestra.Presets:Register({ Name = "Headphones", Main = { Volume = 0.8 } })

Orchestra:Start({
	Buses = { "SFX", "Music", "Dialogue", "UI" }, -- optional: the default is SFX, UI, Voice, Dialogue, Music, Environment
})

Orchestra.Presets:SetOutputProfile("Headphones") -- from your settings menu; nil clears it
```

Presets can also put inserts on a bus or on the Main layer. Entries merge by `Id`: a later preset retunes `Props`, turns one off with `Bypass = true`, adds a new one (placed with `After`, or at the end), or takes one out with `Remove = true`:

```lua
local Effect, Transform = Orchestra.Enums.Effect, Orchestra.Enums.Transform

Orchestra.Presets:Register({
	Name = "Base",
	Main = { Inserts = {
		{ Id = "Glue", Effect = Effect.Compressor, Props = { Ratio = 2 } },
		{ Id = "Ceiling", Effect = Transform.Limiter },
	} },
})

Orchestra.Presets:Register({
	Name = "Mobile",
	Extends = "Base",
	Main = { Inserts = {
		{ Id = "Glue", Props = { Ratio = 4 } },
		{ Id = "Presence", Effect = Effect.Equalizer, After = "Glue", Props = { MidGain = 2 } },
	} },
})
```

Changes tween over the preset's `Transition` (0.5 seconds by default). When a chain's inserts change, it fades out briefly, is rebuilt, and fades back in. Presets own the bus faders, Master and the inserts they create, so keep player settings on the trims.

Snapshots are presets pushed on top for a temporary state, such as a pause menu. The highest `Priority` wins, and a snapshot's own `Transition` is used for its push and pop:

```lua
Orchestra.Presets:Register({ Name = "PauseMenu", Transition = { Time = 0.2 }, Buses = { Music = { Volume = 0.3 } } })

local paused = Orchestra.Presets:Push("PauseMenu", { Priority = 10 })
paused:Pop()
```

To keep one preset per file, put a ModuleScript per preset in a folder and register them together. Each module returns a definition; one without a `Name` is named after its module:

```lua
Orchestra.Presets:RegisterFolder(ReplicatedStorage.Presets) -- Base, Mobile, Headphones, ...
Orchestra:Start()
```

Upgrading from 0.0.2? See [CHANGELOG.md](CHANGELOG.md) for the breaking changes.

> **Set `SoundService.DefaultListenerLocation` to `None` in your place.** Otherwise Roblox's default listener wires itself into Orchestra's output, and emitters without an `AudioInteractionGroup` skip the mixer. Game scripts can't set this property, so set it in Studio or in your Rojo project (`test.project.json` does this).

## Documentation

**[juriaangregor.github.io/Orchestra](https://juriaangregor.github.io/Orchestra/)**: API docs for every component, the factories, `Enums` and the engine.

They're generated from the source with [Moonwave](https://eryn.io/moonwave/). To preview them locally:

```sh
moonwave dev
```

## Development

The toolchain is managed with [Rokit](https://github.com/rojo-rbx/rokit) (see `rokit.toml`).

```sh
rokit install                     # install the toolchain
wally install                     # install packages
wally-patch-package               # apply WallyPatches/ to the installed packages
rojo sourcemap test.project.json -o sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/   # re-export package types for luau-lsp
rojo serve test.project.json      # sync into Studio
```

`test.project.json` mounts Orchestra at `ReplicatedStorage.Packages.Orchestra`, next to its dependencies (the layout Wally uses). It also adds a client script (`src/TestEnv`) that registers demo presets, starts the engine, builds a demo scene, and opens a debug panel: switch the platform, toggle Headphones, push and pop the demo snapshots, and watch the live volumes and insert properties. The panel is built with [Fusion](https://elttob.uk/Fusion/) 0.3, a dev dependency (`src/TestEnv/DebugPanel`).

Tests are Jest specs (`*.spec.luau`) next to the code. `scripts/test.lua` runs them in Roblox; in Studio, run it from the command bar while `rojo serve` is syncing. `test.project.json` mounts a `JestGlobals` stub (`scripts/JestGlobals.luau`) in `DevPackages`: Jest intercepts requires of that name and hands back `describe`, `it` and `expect`.

Checks (also in `.lute/analyze.luau`):

```sh
selene src
stylua -c src
luau-lsp analyze --definitions=@roblox=globalTypes.d.luau --sourcemap sourcemap.json src
```

`globalTypes.d.luau` comes from the [luau-lsp repository](https://github.com/JohnnyMorganz/luau-lsp/blob/master/scripts/globalTypes.d.luau); `.lute/build.luau` downloads it.

Dependencies are listed in `wally.toml`. Locally, Signals is patched (`WallyPatches/`) so its React module can find React; Orchestra itself doesn't use that module, so the published package doesn't need the patch.
