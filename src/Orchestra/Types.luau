--!strict
--[[
	Shared types for Orchestra.

	Two kinds of things live here:
	- Instance unions (`AudioMembers`, `AudioEffectInstance`, ...) describing the Roblox audio instances we wrap.
	- Object types (`AU*`) describing the Luau wrapper objects each component returns.

	It also exports runtime `t` checkers generated from `Enums`, so factories can validate the type names they receive.
]]

local Dependencies = require("./Dependencies")
local t = Dependencies.t
local Enums = require("./Enums")

type Trove = Dependencies.Trove
type EnumItem = Enums.EnumItem

---------------------------------------------------------------------
-- Generic

export type Error = {
	type: "Error",
	raw: string,
	message: string,
	trace: string,
	context: string?,
}

---------------------------------------------------------------------
-- Roblox audio instances

export type AudioStreamInstance = AudioPlayer | AudioDeviceInput | AudioListener | AudioTextToSpeech

export type AudioOutputInstance = AudioDeviceOutput | AudioEmitter

export type AudioEffectInstance =
	AudioChorus
	| AudioCompressor
	| AudioDistortion
	| AudioEcho
	| AudioEqualizer
	| AudioFlanger
	| AudioPitchShifter
	| AudioReverb
	| AudioTremolo

export type AudioTransformInstance = AudioChannelMixer | AudioChannelSplitter | AudioGate | AudioLimiter

-- Every audio instance that has pins and can be wired
export type AudioMembers =
	AudioStreamInstance
	| AudioOutputInstance
	| AudioEffectInstance
	| AudioTransformInstance
	| AudioFader
	| AudioAnalyzer

---------------------------------------------------------------------
-- Base objects

type Object<T> = {
	Type: string,
	ClassName: string,
	Instance: T,
	_trove: Trove,
	Destroy: (self: any) -> (),
}

-- An object that owns a Routing, and can therefore be wired
type Node<T> = Object<T> & {
	Routing: AURouting,
}

---------------------------------------------------------------------
-- Routing

export type AudioRoutingPin = {
	Instance: AudioMembers,
	-- One of Enums.Pin (Input / Output / Sidechain)
	PinType: EnumItem,
	-- Name of a specific pin on the instance, nil for its default pin
	Pin: string?,
}

export type AUWire = {
	ClassName: string,
	Instance: Wire,
	_trove: Trove,
	IsConnected: (self: any) -> boolean,
	Destroy: (self: any) -> (),
}

export type AURouting = {
	ClassName: string,
	AudioRouter: Folder,
	IsAudioMember: boolean?,
	AudioMember: AudioMembers?,
	-- Pin names keyed by Enums.Pin name
	Pins: { [string]: { string } },
	_trove: Trove,
	Wire: (self: any, from: AudioRoutingPin, to: AudioRoutingPin) -> (),
	WireTo: (self: any, to: AudioMembers, toPin: string?) -> (),
	WireFrom: (self: any, from: AudioMembers, fromPin: string?) -> (),
	Destroy: (self: any) -> (),
}

---------------------------------------------------------------------
-- Stream

export type AUPlayback = Node<AudioPlayer> & {
	Out: AudioPlayer,
	Ended: RBXScriptSignal,
	Looped: RBXScriptSignal,
	-- Returns the TimeLength of the loaded asset
	Play: (self: any) -> number,
	Pause: (self: any) -> (),
	Stop: (self: any) -> (),
}

export type AUInput = Node<AudioDeviceInput> & {
	Out: AudioDeviceInput,
	IsAudible: (self: any, player: Player) -> boolean,
	Mute: (self: any) -> (),
}

export type AUListener = Node<AudioListener> & {
	Out: AudioListener,
}

export type AUTextToSpeech = Node<AudioTextToSpeech> & {
	Out: AudioTextToSpeech,
	Text: string?,
	Ended: RBXScriptSignal,
	Looped: RBXScriptSignal,
	Play: (self: any) -> (),
	Pause: (self: any) -> (),
	-- Both return a Promise that settles once the text has loaded
	Load: (self: any) -> any,
	LoadText: (self: any, text: string) -> any,
}

export type AUStream = AUPlayback | AUInput | AUListener | AUTextToSpeech

---------------------------------------------------------------------
-- Output

export type AUDeviceOutput = Node<AudioDeviceOutput> & {
	In: AudioDeviceOutput,
}

export type AUEmitter = Node<AudioEmitter> & {
	In: AudioEmitter,
	SetDistanceAttenuation: (self: any, attenuation: { [number]: number }) -> (),
	SetAngleAttenuation: (self: any, attenuation: { [number]: number }) -> (),
}

export type AUOutput = AUDeviceOutput | AUEmitter

---------------------------------------------------------------------
-- Effects

export type AUEffect = Node<AudioEffectInstance> & {
	In: AudioEffectInstance,
	Out: AudioEffectInstance,
}

export type AUEqualizer = AUEffect & {
	SetGain: (self: any, band: "Low" | "Mid" | "High", gain: number) -> (),
	SetRange: (self: any, minFrequency: number, maxFrequency: number) -> (),
}

---------------------------------------------------------------------
-- Transforms

export type AUTransform = Node<AudioTransformInstance> & {
	In: AudioTransformInstance,
	Out: AudioTransformInstance,
}

export type AUChannelMixer = Node<AudioChannelMixer> & {
	In: AudioChannelMixer,
	Out: AudioChannelMixer,
}

export type AUChannelSplitter = Node<AudioChannelSplitter> & {
	In: AudioChannelSplitter,
	Out: AudioChannelSplitter,
}

export type AUGate = Node<AudioGate> & {
	In: AudioGate,
	Out: AudioGate,
}

export type AULimiter = Node<AudioLimiter> & {
	In: AudioLimiter,
	Out: AudioLimiter,
}

---------------------------------------------------------------------
-- Analyzers

export type AUAnalyzer = Node<AudioAnalyzer> & {
	In: AudioAnalyzer,
	GetSpectrum: (self: any) -> { number },
	ObserveSpectrum: (self: any) -> (Dependencies.Getter<{ number }>, () -> ()),
	GetPeak: (self: any) -> number,
	ObservePeak: (self: any) -> (Dependencies.Getter<number>, () -> ()),
	GetRMS: (self: any) -> number,
	ObserveRMS: (self: any) -> (Dependencies.Getter<number>, () -> ()),
}

---------------------------------------------------------------------
-- Base components

export type AUFader = Node<AudioFader> & {
	In: AudioFader,
	Out: AudioFader,
	IsMuted: boolean,
	_tweenTrove: Trove,
	_previousVolume: number?,
	Set: (self: any, volume: number) -> (),
	-- Tween / FadeOut / FadeIn / Mute return a Promise (evaera/promise has no Luau types)
	Tween: (self: any, goal: number, tweenInfo: TweenInfo?) -> any,
	FadeOut: (self: any, duration: number, goal: number?) -> any,
	FadeIn: (self: any, duration: number, goal: number?) -> any,
	Mute: (self: any, noTween: boolean?) -> any,
}

-- Anything that can sit in an InsertChain: a component with an `In` and `Out` audio instance
export type AUInsert = AUEffect | AUTransform | AUFader

export type AUInsertChain = Object<Folder> & {
	Routing: AURouting,
	In: AudioFader,
	Out: AudioFader,
	Add: (self: any, insert: AUInsert, index: number?) -> AUInsert,
	Remove: (self: any, insert: AUInsert) -> AUInsert,
	GetInserts: (self: any) -> { AUInsert },
}

export type AULayer = Object<Folder> & {
	Stream: AUStream,
	Fader: AUFader,
	Routing: AURouting,
	Out: AudioFader,
	_components: {
		AudioStream: AUStream,
		AudioFader: AUFader,
	},
	Play: (self: any, completeHandler: (() -> ())?) -> (),
	Stop: (self: any) -> (),
}

---------------------------------------------------------------------
-- Runtime checkers, generated from Enums

local function enumNames(enumList: Enums.EnumList): { string }
	local names = {}
	for _, item in enumList:GetEnumItems() do
		table.insert(names, item.Name)
	end
	return table.freeze(names)
end

return table.freeze({
	tAudioOutput = t.valueOf(enumNames(Enums.Output)),
	tAudioPin = t.valueOf(enumNames(Enums.Pin)),
	tAudioStream = t.valueOf(enumNames(Enums.Stream)),
	tAudioTransform = t.valueOf(enumNames(Enums.Transform)),
	tAudioEffect = t.valueOf(enumNames(Enums.Effect)),
	tAudioAnalyzer = t.valueOf(enumNames(Enums.Analyzer)),
	tAudioMembers = t.valueOf(enumNames(Enums.AudioMembers)),
})
