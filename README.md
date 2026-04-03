# Orchestra

**Orchestra** is a Roblox audio framework written in Luau that provides a structured, signal-graph-style API for building audio pipelines in Roblox games. It wraps Roblox's native Audio API instances (`AudioPlayer`, `AudioFader`, `AudioWire`, etc.) in composable components that you wire together — similar to a DAW or audio mixing desk.

## Overview

Orchestra models audio as a graph of **nodes** connected by **wires**. Each node has input/output pins and can be routed to other nodes. This lets you build chains like:

```
AudioPlayer → AudioFader → AudioEqualizer → AudioDeviceOutput
```

All cleanup is handled automatically via [Trove](https://github.com/Sleitnick/RbxUtil), and signals use [Signal](https://github.com/Sleitnick/RbxUtil).

## Components

### Stream (Sources)
Audio sources that produce audio signals.

| Component | Description |
|---|---|
| `AudioPlayer` | Plays an audio asset. Supports `Play`, `Pause`, `Stop`, and fires `Loaded`, `Ended`, `Looped` signals. |
| `AudioDeviceInput` | Wraps a microphone / device input. |
| `AudioListener` | Spatial audio listener. |
| `AudioTextToSpeech` | Text-to-speech audio source. |

### Fader
- **`AudioFader`** — Controls volume (0–3) with `Set`, `Tween`, `FadeIn`, `FadeOut`, and `Mute`. Tweens return a `Signal` that fires on completion.
- **`AudioMixBus`** — Same as Fader but intended as a submix bus. Useful for grouping channels (e.g. music bus, SFX bus).

### Layer
- **`AudioLayer`** — A convenience wrapper that pairs an `AudioStream` and `AudioFader` together and wires them automatically. Use this as the main building block for a single audio channel.

### Effects
Effects process the audio signal in-place. All effects support `Enable` and `Disable` (via the Roblox `Bypass` property).

| Effect | Roblox Instance |
|---|---|
| `Equalizer` | `AudioEqualizer` |
| `Reverb` | `AudioReverb` |
| `Compressor` | `AudioCompressor` |
| `Chorus` | `AudioChorus` |
| `Distortion` | `AudioDistortion` |
| `Echo` | `AudioEcho` |
| `Flanger` | `AudioFlanger` |
| `PitchShift` | `AudioPitchShift` |
| `Tremolo` | `AudioTremolo` |
| `Gate` | `AudioGate` |

### Transforms
| Component | Description |
|---|---|
| `AudioChannelMixer` | Mixes multiple channels into one. |
| `AudioChannelSplitter` | Splits a signal into multiple channels. |

### Output
| Component | Description |
|---|---|
| `AudioDeviceOutput` | Routes audio to the player's audio device (speakers/headphones). |
| `AudioEmitter` | 3D spatial audio emitter attached to a part in the world. |

### Routing & Wire
- **`AudioRouting`** — Manages the input/output pin state for a node. Tracks which wires are connected and exposes helpers like `WireTo`, `ClearPin`, `GetWiresAtPin`.
- **`Wire`** — Wraps Roblox's `Wire` instance. Created automatically when you call `Routing:Wire()` or `Routing:WireTo()`.

## Installation

Orchestra is published as a [Wally](https://wally.run) package.

Add it to your `wally.toml`:

```toml
[dependencies]
Orchestra = "juriaan/orchestra@0.1.0"
```

Then run:

```
wally install
```

## Dependencies

| Package | Version |
|---|---|
| sleitnick/component | 2.4.8 |
| sleitnick/trove | 1.5.1 |
| sleitnick/signal | 2.0.3 |
| sleitnick/table-util | 1.2.1 |
| evaera/promise | 4.0.0 |

## Version

`v0.0.1`
