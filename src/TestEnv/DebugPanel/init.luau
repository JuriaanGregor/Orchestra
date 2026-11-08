--!strict
--[[
	Debug panel for trying presets in Studio, built with Fusion: switch the platform, toggle the Headphones output
	profile, push and pop the demo snapshots, and watch the live mix (volumes and insert properties as they tween).

	Needs the demo presets (DemoPresets). Call the returned function to remove it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)

local MixState = require("@self/MixState")
local Panel = require("@self/Components/Panel")
local Section = require("@self/Components/Section")
local ToggleButton = require("@self/Components/ToggleButton")
local InfoLine = require("@self/Components/InfoLine")
local MixView = require("@self/Components/MixView")

local Children = Fusion.Children

type Scope = Fusion.Scope<typeof(Fusion)>

local PLATFORMS = { "Mobile", "Desktop", "Console" }
local OUTPUT_PROFILE = "Headphones"
local SNAPSHOTS = {
	{ Name = "PauseMenu", Priority = 10 },
	{ Name = "Underwater", Priority = 0 },
}

local function DebugPanel(engine: any): () -> ()
	local scope: Scope = Fusion.scoped(Fusion)
	local state = MixState(scope, engine)

	local platformButtons = {}
	for index, platform in PLATFORMS do
		table.insert(
			platformButtons,
			ToggleButton(scope, {
				Text = platform,
				LayoutOrder = index,
				Active = scope:Computed(function(use)
					return use(state.Platform) == platform
				end),
				OnActivated = function()
					state.SetPlatform(platform)
				end,
			})
		)
	end

	local snapshotButtons = {}
	for index, snapshot in SNAPSHOTS do
		table.insert(
			snapshotButtons,
			ToggleButton(scope, {
				Text = snapshot.Name,
				LayoutOrder = index,
				Active = state.IsSnapshotActive(scope, snapshot.Name),
				OnActivated = function()
					state.ToggleSnapshot(snapshot.Name, snapshot.Priority)
				end,
			})
		)
	end

	scope:New("ScreenGui")({
		Name = "OrchestraDebug",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),

		[Children] = Panel(scope, {
			Title = "Orchestra presets",
			Content = {
				Section(scope, {
					Title = "Platform",
					LayoutOrder = 1,
					Content = platformButtons,
				}),

				Section(scope, {
					Title = "Output profile",
					LayoutOrder = 2,
					Content = ToggleButton(scope, {
						Text = OUTPUT_PROFILE,
						Active = scope:Computed(function(use)
							return use(state.OutputProfile) == OUTPUT_PROFILE
						end),
						OnActivated = function()
							state.ToggleOutputProfile(OUTPUT_PROFILE)
						end,
					}),
				}),

				Section(scope, {
					Title = "Snapshots",
					LayoutOrder = 3,
					Content = snapshotButtons,
				}),

				Section(scope, {
					Title = "Layers",
					LayoutOrder = 4,
					Content = {
						InfoLine(scope, { Label = "Merged", Value = state.Layers, LayoutOrder = 1 }),
						InfoLine(scope, { Label = "Snapshots", Value = state.Snapshots, LayoutOrder = 2 }),
					},
				}),

				MixView(scope, {
					State = state,
					LayoutOrder = 5,
				}),
			},
		}),
	})

	return function()
		Fusion.doCleanup(scope)
	end
end

return DebugPanel
