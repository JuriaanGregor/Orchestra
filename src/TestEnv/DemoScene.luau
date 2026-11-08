--!strict
--[[
	Demo scene for manually testing Orchestra in Studio.

	Plays a track through an Equalizer, splits it into stereo channels, and sends Left / Right
	to two emitters placed either side of the origin. An analyzer is wired off the Equalizer.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Trove"))

local function createPart(name: string, position: Vector3, transparency: number): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Position = position
	part.Size = Vector3.new(4, 4, 4)
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.Parent = workspace

	return part
end

-- Builds the demo scene on a started engine. Destroy the returned Trove to tear it down.
local function DemoScene(engine: any)
	local Enums = engine.Enums
	local trove = Trove.new()

	-- Parts to hold our audio
	local audioPart = trove:Add(createPart("AudioEngine", Vector3.new(0, 4, 0), 1))
	local audioPartL = trove:Add(createPart("AudioEngineL", Vector3.new(-10, 4, 0), 0))
	local audioPartR = trove:Add(createPart("AudioEngineR", Vector3.new(10, 4, 0), 0))

	-- Create a new AudioLayer
	local audioLayer = trove:Construct(engine.Layer, Enums.Stream.Player, audioPart, {
		Name = "DefaultAudioLayer",
		Content = "rbxassetid://15287092994",
	})

	-- Add an Equalizer after the layer
	local audioEffect = trove:Construct(engine.Effects, Enums.Effect.Equalizer, audioLayer.Instance, {
		Name = "DefaultEqualizer",
	})

	-- Create our AudioAnalyzer
	local audioAnalyzer = trove:Construct(engine.Analyzers, Enums.Analyzer.Spectrum, audioLayer.Instance, {
		Name = "SpectrumAnalyzer",
	})

	audioEffect.Routing:WireTo(audioAnalyzer.In)

	-- Create a channel transform
	local audioTransform = trove:Construct(engine.Transforms, Enums.Transform.ChannelSplitter, audioLayer.Instance, {
		Name = "ChannelSplitter",
		Layout = Enum.AudioChannelLayout.Stereo,
	})

	audioEffect.Routing:WireTo(audioTransform.In)

	-- Wire the AudioLayer into the Equalizer
	audioLayer.Routing:WireTo(audioEffect.In)

	-- Create our Emitters
	local emitterL = trove:Construct(engine.Output, Enums.Output.Emitter, audioPartL, {
		AudioInteractionGroup = "Music",
		Name = "EmitterL",
	})

	local emitterR = trove:Construct(engine.Output, Enums.Output.Emitter, audioPartR, {
		AudioInteractionGroup = "Music",
		Name = "EmitterR",
	})

	audioTransform.Routing:Wire(
		{ Instance = audioTransform.Instance, PinType = Enums.Pin.Output, Pin = "Left" },
		{ Instance = emitterL.Instance, PinType = Enums.Pin.Input }
	)

	audioTransform.Routing:Wire(
		{ Instance = audioTransform.Instance, PinType = Enums.Pin.Output, Pin = "Right" },
		{ Instance = emitterR.Instance, PinType = Enums.Pin.Input }
	)

	-- Play the Stream connected to the AudioLayer
	audioLayer.Stream:Play()

	-- Fade the layer up to full volume over 1 second
	audioLayer.Fader:Tween(3, TweenInfo.new(1))

	return trove
end

return DemoScene
