# Orchestra

**Orchestra** is a Roblox audio framework written in Luau. It wraps Roblox's Audio API instances (`AudioPlayer`, `AudioFader`, `AudioEmitter`, `Wire`, ...) in components you wire together, similar to a DAW or a mixing desk.

> **Status:** early development (`v0.0.1`). The API may still change, and Orchestra is not published to Wally yet.

## Overview

Orchestra models audio as a graph of **nodes** connected by **wires**. Every node wraps one Roblox audio instance, exposes `In` / `Out` for wiring, and owns a `Routing` object that creates the `Wire` instances for you:

```
AudioPlayer → AudioFader → AudioReverb → AudioEmitter
```

On top of the nodes, the engine builds a mix bus setup on the client:

```
Listener:SFX   ──► MixBus:SFX   ──┐
Listener:Music ──► MixBus:Music ──┼──► Master ──► MainOut (AudioDeviceOutput)
...one per bus in Config        ──┘
```

Each bus has its own `AudioListener`, filtered by `AudioInteractionGroup`. To send a sound to a bus, give its emitter the bus name as its `AudioInteractionGroup` (for example `"Music"`). The default buses are `SFX`, `UI`, `Voice`, `Dialogue`, `Music` and `Environment` (see `Config.luau`).

Cleanup is handled with [Trove](https://github.com/Sleitnick/RbxUtil): destroying a component also destroys its instance and wires.

## Getting started

Requiring Orchestra has no side effects. Start the engine from a client script, then create components through the factories.

> **Set `SoundService.DefaultListenerLocation` to `None` in your place.** Otherwise Roblox creates its own listener on the camera and wires it into Orchestra's `MainOut`. Any emitter without an `AudioInteractionGroup` then reaches the output directly, skipping Master and the mix buses. Game scripts can't change this property, so set it in Studio or through your Rojo project (`test.project.json` does this).


```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Orchestra = require(ReplicatedStorage.Packages.Orchestra)
local Enums = Orchestra.Enums

-- Sets up MainOut, Master and the mix buses (client only)
Orchestra:Start()

local speaker = workspace.Speaker

-- A Layer is a stream + fader, wired together
local music = Orchestra.Layer.new(Enums.Stream.Player, speaker, {
	Name = "Music",
	Asset = "rbxassetid://15287092994",
})

local reverb = Orchestra.Effects.new(Enums.Effect.Reverb, speaker, { Name = "Reverb" })

-- Emit in 3D, routed to the Music bus
local emitter = Orchestra.Output.new(Enums.Output.Emitter, speaker, {
	Name = "Emitter",
	AudioInteractionGroup = "Music",
})

music.Routing:WireTo(reverb.In)
reverb.Routing:WireTo(emitter.In)

music:Play()
music.Fader:FadeIn(2)
```

`Layer` and the category factories (`Stream`, `Output`, `Effects`, `Transforms`, `Analyzers`) take a type from `Orchestra.Enums`, a parent instance, and an optional props table. `Fader.new` takes only a parent and props. Props are applied to the created instance: Roblox properties, plus `Tags` and `Attributes`.

## Components

### Stream (sources) — `Orchestra.Stream`

| Type | Instance | Notes |
|---|---|---|
| `Enums.Stream.Player` | `AudioPlayer` | `Play` (returns the track length), `Pause`, `Stop`. Exposes the `Ended` and `Looped` events. The asset can be passed as `Asset`, `AssetId`, `SoundId`, `Sound` or `Content`. |
| `Enums.Stream.Input` | `AudioDeviceInput` | Microphone input. `IsAudible(player)`, `Mute()`. |
| `Enums.Stream.Listener` | `AudioListener` | Spatial listener. The engine creates one per mix bus. |
| `Enums.Stream.TextToSpeech` | `AudioTextToSpeech` | `LoadText(text)` and `Load()` return a Promise. `Play()` loads first when needed. |

### Fader — `Orchestra.Fader`

Wraps `AudioFader` and controls volume (0–3) with `Set`, `Tween`, `FadeIn`, `FadeOut` and `Mute` (call it again to unmute). Mix buses and Master are Faders too.

`Tween`, `FadeIn`, `FadeOut` and `Mute` return a [Promise](https://eryn.io/roblox-lua-promise/) that resolves when the fade completes. If another `Tween`/`Set` interrupts it, or the fader is destroyed, the Promise is cancelled instead, and the volume stays wherever it was.

```lua
music.Fader:FadeOut(2):andThen(function()
	music:Stop()
end)
```

### Layer — `Orchestra.Layer`

Combines a stream and a fader and wires them together. This is the main building block for a single sound. It exposes `Stream`, `Fader` and `Routing`, plus `Play(onEnded?)` and `Stop()`.

### Effects — `Orchestra.Effects`

| Type | Instance |
|---|---|
| `Enums.Effect.Chorus` | `AudioChorus` |
| `Enums.Effect.Compressor` | `AudioCompressor` (also has a `Sidechain` pin) |
| `Enums.Effect.Distortion` | `AudioDistortion` |
| `Enums.Effect.Echo` | `AudioEcho` |
| `Enums.Effect.Equalizer` | `AudioEqualizer`: `SetGain(band, gain)`, `SetRange(min, max)` |
| `Enums.Effect.Flanger` | `AudioFlanger` |
| `Enums.Effect.PitchShifter` | `AudioPitchShifter` |
| `Enums.Effect.Reverb` | `AudioReverb` |
| `Enums.Effect.Tremolo` | `AudioTremolo` |

### Transforms — `Orchestra.Transforms`

| Type | Instance |
|---|---|
| `Enums.Transform.ChannelMixer` | `AudioChannelMixer` |
| `Enums.Transform.ChannelSplitter` | `AudioChannelSplitter` |
| `Enums.Transform.Gate` | `AudioGate` |
| `Enums.Transform.Limiter` | `AudioLimiter` |

### Analyzers — `Orchestra.Analyzers`

| Type | Instance | Notes |
|---|---|---|
| `Enums.Analyzer.Spectrum` | `AudioAnalyzer` | `GetSpectrum`, `GetPeak`, `GetRMS`. Each has an `Observe*` version that returns a [Signals](https://github.com/Roblox/signals) getter updated every frame, plus a function to stop observing. Client only. |

### Output — `Orchestra.Output`

| Type | Instance | Notes |
|---|---|---|
| `Enums.Output.Device` | `AudioDeviceOutput` | Plays to the player's speakers/headphones. The engine creates `MainOut`. |
| `Enums.Output.Emitter` | `AudioEmitter` | 3D emitter. `SetDistanceAttenuation`, `SetAngleAttenuation`. |

### Routing & Wire

Every node has a `Routing` (`AudioRouting`) that knows the node's pins and creates `Wire` instances:

- `Routing:WireTo(target, pin?)`: wires this node's output into `target`. Without `pin`, the target's default input pin is used.
- `Routing:WireFrom(source, pin?)`: wires `source`'s output into this node.
- `Routing:Wire(from, to)`: wires explicit pins, e.g. a `ChannelSplitter`'s `Left` output:

```lua
splitter.Routing:Wire(
	{ Instance = splitter.Instance, PinType = Enums.Pin.Output, Pin = "Left" },
	{ Instance = emitterL.Instance, PinType = Enums.Pin.Input }
)
```

`Wire` wraps Roblox's `Wire` instance. You normally don't create it yourself.

## Development

The toolchain is managed with [Rokit](https://github.com/rojo-rbx/rokit) (see `rokit.toml`: Rojo, Wally, Selene, StyLua, luau-lsp, Lute and rocale-cli).

```sh
rokit install                     # install the toolchain
wally install                     # install packages
wally-patch-package               # apply WallyPatches/ to the installed packages
rojo sourcemap test.project.json -o sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/   # re-export package types for luau-lsp
rojo serve test.project.json      # sync into Studio
```

`test.project.json` mounts Orchestra at `ReplicatedStorage.Packages.Orchestra`, next to its dependencies (the same layout Wally uses). It also mounts `src/TestEnv` as a client script that starts the engine and builds a demo scene (`src/TestEnv/DemoScene.luau`).

Checks (also in `.lute/analyze.luau`):

```sh
selene src
stylua -c src
luau-lsp analyze --definitions=@roblox=globalTypes.d.luau --sourcemap sourcemap.json src
```

`globalTypes.d.luau` comes from the [luau-lsp repository](https://github.com/JohnnyMorganz/luau-lsp/blob/master/scripts/globalTypes.d.luau). `.lute/build.luau` downloads it.

## Dependencies

| Package | Version | Used for |
|---|---|---|
| sleitnick/trove | 1.8.0 | Cleanup |
| sleitnick/enum-list | 2.1.0 | `Enums` and `Config` |
| roblox/signals | 0.9.0 | Analyzer `Observe*` getters (patched, see `WallyPatches/`) |
| evaera/promise | 4.0.0 | Text-to-speech loading |
| jsdotlua/react | 17.2.1 | Required by `signals-react` inside Signals |
| sleitnick/component | 2.4.8 | Not used yet |
| [t](https://github.com/osyrisrblx/t) | vendored in `Lib/t` | Runtime type checks |

Dev: `jsdotlua/jest` 3.10.0.

## Version

`v0.0.1`
