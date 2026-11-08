--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Orchestra = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Orchestra")
local AudioEngine = require(Orchestra)

local DemoScene = require("@self/DemoScene")

-- Start the engine, then build our demo scene on top of it
AudioEngine:Start()
DemoScene(AudioEngine)

print(AudioEngine)
