# Changelog

## 0.1.0

Presets: one mix definition per platform, with insert effects on every bus and on the Main layer.

### Breaking changes

- **Wire into a bus through its inserts.** Each bus now runs `Listener:<bus> → Inserts:<bus> → MixBus:<bus> → Trim:<bus> → Inserts:Main → Master → MainOut`. Code that wires straight into `Orchestra.Mixes[bus].In` skips the bus's inserts; wire into `Orchestra.Inserts[bus].In` instead. Emitters picked up by a bus listener (through `AudioInteractionGroup`) need no change.
- **`Orchestra:AddMix` errors before `Orchestra:Start()`.** It used to fail with an unclear error; call `Start()` first, or declare the buses with `Start({ Buses = { ... } })`.
- **Presets own the bus faders and Master.** Applying a preset (including the one `Start()` applies) sets `Orchestra.Mixes[bus]` and `Orchestra.Master`. With no presets registered they stay at volume 1, as before. Put player volume settings on the new trim faders (`Orchestra:SetPlayerVolume`) and game-driven fades on your own faders.

### Added

- **Insert chains**: `InsertChain` component (`Add`, `Remove`, `SetInserts`, `GetInserts`), on every bus (`Orchestra.Inserts`) and the Main layer (`Orchestra.MainInserts`).
- **Player trims**: a trim fader after each bus fader (`Orchestra.Trims`), set with `Orchestra:SetPlayerVolume(bus, volume)`.
- **Custom buses**: `Orchestra:Start({ Buses = { ... } })`; the six in `Config.MIX_BUSES` stay the default. `Orchestra:GetBusNames()`.
- **Presets** (`Orchestra.Presets`):
  - `Register`, and `RegisterFolder` to register one ModuleScript per preset
  - `Extends`, per-bus and Main `Volume` and `Inserts` (merged by `Id`; `Props`, `Bypass`, `Remove`, `After`), `Transition`
  - Platform detection with `Start({ Platform, Presets })` and `SetPlatform`: Console on a TV screen (`GuiService:IsTenFootInterface()`), Mobile when touch is the preferred input (`UserInputService.PreferredInput`), Desktop otherwise
  - Output profiles, such as Headphones: `SetOutputProfile`
  - Snapshots: `Push(name, { Priority })` returns a handle with `Pop()`
  - `GetLayers`, `GetResolved`, `GetSnapshots`, `Changed`
  - Changes tween; a chain whose inserts change dips for 0.05 seconds and is rebuilt. A change whose mix doesn't resolve is rolled back and leaves the live mix as it was.

### Fixed

- `scripts/test.lua` looked for Jest in `Packages` instead of `DevPackages`, and ran other packages' tests too.
