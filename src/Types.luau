--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local Trove = require(Package.Packages.Trove)
local Signal = require(Package.Packages.Signal)

-- Generic Types for our Packages
export type Trove = typeof(Trove.new())
export type Signal = typeof(Signal.new())

-- Generic Types
export type Error = {
	type: "Error",
	raw: string,
	message: string,
	trace: string,
	context: string?,
}

export type AudioPin = "Input" | "Output" | "Sidechain"
export type AudioStreamType = "Player" | "Input" | "Listener" | "TextToSpeech"
export type AudioTransformType = "ChannelMixer" | "ChannelSplitter"
export type AudioOutputType = "Device" | "Emitter"

export type AudioMembers =
	-- Sources
	AudioPlayer
	| AudioDeviceInput
	| AudioListener
	-- Output
	| AudioDeviceOutput
	| AudioEmitter
	-- Fader
	| AudioFader
	-- Analyzer 
	| AudioAnalyzer
	-- Effects
	| AudioEqualizer
	| AudioFlanger
	| AudioReverb
	| AudioPitchShifter
	| AudioChorus
	| AudioDistortion

export type AudioEffects = AudioEqualizer | AudioFlanger | AudioReverb | AudioPitchShifter | AudioChorus | AudioDistortion

export type AudioTransforms = AudioChannelMixer | AudioChannelSplitter

export type AudioAnalyzers = AudioAnalyzer

type AudioBase = typeof(setmetatable({}, {})) & {
	ClassName: string,
	_trove: Trove,
	Destroy: () -> (),
}

export type AUWire = AudioBase & {
	Instance: Wire,
	ID: string,
	Changed: Signal,
}

export type AURouting = AudioBase & {
	Instance: Folder,
	Pins: { AudioPin },
	Routing: { [AudioPin]: { AUWire } },
	IsPin: (pin: AudioPin) -> boolean,
	GetWiresAtPin: (pin: AudioPin) -> { AUWire },
	ClearPin: (pin: AudioPin) -> (),
	GetPinsFromInstance: (Instance: AudioMembers) -> { [AudioPin]: { AUWire } },
	WireTo: (target: AudioMembers) -> (),
	AddWire: (wire: AUWire, pin: AudioPin) -> (),
	Wire: (from: AudioMembers, to: AudioMembers) -> (),
}

export type AUInput = AudioBase & {
	Instance: AudioDeviceInput,
	IsAudible: (player: Player) -> boolean,
	Out: AudioMembers,
	Mute: () -> (),
}

export type AUPlayback = AudioBase & {
	Instance: AudioPlayer,
	Changed: Signal,
	Ended: Signal,
	Loaded: Signal,
	Looped: Signal,
	Out: AudioMembers,
}

export type AUListener = AudioBase & {
	Instance: AudioListener,
	Out: AudioMembers,
}

export type AUTextToSpeech = AudioBase & {
	Instance: AudioTextToSpeech,
	Looped: Signal,
	Ended: Signal,
	Text: string?,
	Out: AudioMembers,
}

export type AUStream = AudioBase & {
	StreamType: AudioStreamType,
	Instance: AudioPlayer | AudioListener | AudioDeviceInput,
	Stream: AUPlayback | AUListener | AUInput | AUTextToSpeech,
	Play: () -> (),
	Pause: () -> (),
	Stop: () -> (),
	Routing: AURouting,
	Out: AudioMembers,
}

export type AUDeviceOutput = AudioBase & {
	Instance: AudioDeviceOutput,
	In: AudioMembers,
}

export type AUEmitter = AudioBase & {
	Instance: AudioEmitter,
	In: AudioMembers,
}

export type AUEffect = AudioBase & {
	EffectType: string,
	Instance: AudioEffects,
	In: AudioMembers,
	Out: AudioMembers,
}

export type AUChannelMixer = AudioBase & {
	Instance: AudioChannelMixer,
	In: AudioMembers,
	Out: AudioMembers,
}

export type AUChannelSplitter = AudioBase & {
	Instance: AudioChannelSplitter,
	In: AudioMembers,
	Out: AudioMembers,
}

export type AUOutput = AudioBase & {
	OutputType: AudioOutputType,
	Instance: AudioDeviceOutput | AudioEmitter,
	In: AudioMembers,
	Output: AUDeviceOutput | AUEmitter,
}

export type AUFader = AudioBase & {
	Instance: AudioFader,
	In: AudioMembers,
	Out: AudioMembers,
	Routing: AURouting,
	Set: (volume: number) -> (),
	Tween: (goal: number, tweenInfo: TweenInfo?) -> Signal,
	FadeOut: (duration: number, goal: number?) -> Signal,
	FadeIn: (duration: number, goal: number?) -> Signal,
	Mute: (noTween: boolean?) -> (),
	IsMuted: boolean,
	Completed: Signal,
}

export type AUTransform = AudioBase & {
	TransformType: AudioTransformType,
	Routing: AURouting,
	Instance: AudioTransforms,
	In: AudioMembers,
	Out: AudioMembers,
}

export type AULayer = AudioBase & {
	Stream: AUStream,
	Fader: AUFader,
	_components: {
		["AudioStream"]: AUStream,
		["AudioFader"]: AUFader,
		[string]: any,
	},
	Routing: AURouting,
	Out: AudioMembers,
}

export type AUParameter = AudioBase & {
	_trove: Trove,
	_value: number,
	_range: NumberRange?,
	Changed: Signal,
	Get: () -> number,
	Set: (value: number) -> (),
}

local AudioEffects = {
	"AudioEqualizer",
	"AudioFlanger",
	"AudioReverb",
	"AudioPitchShifter",
	"AudioChorus",
	"AudioDistortion",
}

local AudioMembers = {
	"AudioPlayer",
	"AudioDeviceInput",
	"AudioListener",
	"AudioDeviceOutput",
	"AudioEmitter",
	"AudioFader",
	"AudioEqualizer",
	"AudioFlanger",
	"AudioReverb",
	"AudioPitchShifter",
	"AudioChorus",
	"AudioDistortion",
	"AudioAnalyzer",
}

local AudioSources = {
	"Player",
	"Input",
	"Listener",
	"Mix",
	"Effect",
}

local AudioTransforms = {
	"AudioChannelMixer",
	"AudioChannelSplitter",
}

return {
	AudioEffects = table.freeze(AudioEffects),
	AudioChildren = table.freeze(AudioMembers),
	AudioSources = table.freeze(AudioSources),
	AudioTransforms = table.freeze(AudioTransforms),
}
