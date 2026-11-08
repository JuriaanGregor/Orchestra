# Orchestra

**Orchestra** is a Roblox audio framework written in Luau. It wraps Roblox's Audio API instances (`AudioPlayer`, `AudioFader`, `AudioEmitter`, `Wire`, ...) in components you wire together, like a DAW or a mixing desk. On the client it builds a mixer for you: one bus per sound category (`SFX`, `Music`, `UI`, ...), feeding into a Master fader. Every bus, and the Main layer before Master, has an insert chain for effects:

```
Listener:<bus> -> Inserts:<bus> -> MixBus:<bus> -> Trim:<bus> -> Inserts:Main -> Master -> MainOut
```

> **Status:** early development (`v0.0.2`). The API may still change.

## Installation

Add Orchestra to your `wally.toml` and run `wally install`:

```toml
[dependencies]
Orchestra = "juriaan/orchestra@0.0.2"
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

`test.project.json` mounts Orchestra at `ReplicatedStorage.Packages.Orchestra`, next to its dependencies (the layout Wally uses). It also adds a client script (`src/TestEnv`) that starts the engine and builds a demo scene.

Checks (also in `.lute/analyze.luau`):

```sh
selene src
stylua -c src
luau-lsp analyze --definitions=@roblox=globalTypes.d.luau --sourcemap sourcemap.json src
```

`globalTypes.d.luau` comes from the [luau-lsp repository](https://github.com/JohnnyMorganz/luau-lsp/blob/master/scripts/globalTypes.d.luau); `.lute/build.luau` downloads it.

Dependencies are listed in `wally.toml`. Locally, Signals is patched (`WallyPatches/`) so its React module can find React; Orchestra itself doesn't use that module, so the published package doesn't need the patch.
