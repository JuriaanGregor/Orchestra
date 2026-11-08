--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Orchestra = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Orchestra")
local AudioEngine = require(Orchestra)

local DemoPresets = require("@self/DemoPresets")
local DemoScene = require("@self/DemoScene")
local DebugPanel = require("@self/DebugPanel")

-- Register the demo presets, start the engine (it applies the platform's preset), then build the scene and the panel
DemoPresets(AudioEngine)
AudioEngine:Start()
DemoScene(AudioEngine)
DebugPanel(AudioEngine)

print(AudioEngine)
