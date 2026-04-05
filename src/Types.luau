--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports > Packages
local Package = ReplicatedStorage:WaitForChild("Audio")
local Trove = require(Package.Packages.Trove)
local Signal = require(Package.Packages.Signal)
local t = require(Package.Packages.t)

-- Imports > Package
local Enums = require(Package.Enums)

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

export type AudioMembers =
	-- Streams
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
	| AudioChorus
	| AudioCompressor
	| AudioDistortion
	| AudioEcho
	| AudioEqualizer
	| AudioFlanger
	| AudioGate
	| AudioPitchShifter
	| AudioReverb
	| AudioTremolo

export type AudioEffects =
	AudioChorus
	| AudioCompressor
	| AudioDistortion
	| AudioEcho
	| AudioEqualizer
	| AudioFlanger
	| AudioGate
	| AudioPitchShifter
	| AudioReverb
	| AudioTremolo
export type AudioTransforms = AudioChannelMixer | AudioChannelSplitter
export type AudioAnalyzers = AudioAnalyzer

local EnumValues = {} :: { [string]: any }

for enumListIndex, enumList in Enums do
	-- Create the Enum table for each EnumList
	EnumValues[enumListIndex] = {}

	for _, enumItem in enumList:GetEnumItems() do
		table.insert(EnumValues[enumListIndex], enumItem.Name)
	end
end

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
	Pins: { string },
	Routing: { [string]: { AUWire } },
	IsPin: (pin: string) -> boolean,
	GetWiresAtPin: (pin: string) -> { AUWire },
	ClearPin: (pin: string) -> (),
	GetPinsFromInstance: (Instance: AudioMembers) -> { [string]: { AUWire } },
	WireTo: (target: AudioMembers) -> (),
	AddWire: (wire: AUWire, pin: string) -> (),
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

export type AUAnalyzer = AudioBase & {
	Instance: AudioAnalyzer,
	In: AudioMembers,
}

export type AUParameter = AudioBase & {
	_trove: Trove,
	_value: number,
	_range: NumberRange?,
	Changed: Signal,
	Get: () -> number,
	Set: (value: number) -> (),
}

return table.freeze({
	tAudioOutput = t.valueOf(EnumValues.Output),
	tAudioPin = t.valueOf(EnumValues.Pin),
	tAudioStream = t.valueOf(EnumValues.Stream),
	tAudioTransform = t.valueOf(EnumValues.Transform),
	tAudioEffect = t.valueOf(EnumValues.Effect),
	tAudioAnalyzer = t.valueOf(EnumValues.Analyzer),
	tAudioMembers = t.valueOf(EnumValues.AudioMembers),
})
