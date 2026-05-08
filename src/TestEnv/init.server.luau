--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Orchestra = ReplicatedStorage:WaitForChild("Orchestra")
local AudioEngine = require(Orchestra)

print(AudioEngine)
