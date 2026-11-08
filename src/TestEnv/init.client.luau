--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for the packages to replicate: the modules below index them directly
local Orchestra = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Orchestra")
ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("Fusion")

local AudioEngine = require(Orchestra)

local DemoScene = require("@self/DemoScene")
local DebugPanel = require("@self/DebugPanel")

-- Register the demo presets (one ModuleScript each), start the engine (it applies the platform's preset), then build
-- the scene and the panel
AudioEngine.Presets:RegisterFolder(script:WaitForChild("DemoPresets"))
AudioEngine:Start()
DemoScene(AudioEngine)
DebugPanel(AudioEngine)

print(AudioEngine)
