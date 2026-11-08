--!strict
--[[
	Debug panel for trying presets in Studio: switch the platform, toggle the Headphones output profile, push and pop
	the demo snapshots, and watch the live mix (volumes and insert properties as they tween).

	Needs the demo presets (DemoPresets). Destroy the returned Trove to remove it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Trove"))

local PLATFORMS = { "Mobile", "Desktop", "Console" }
local SNAPSHOTS = {
	{ Name = "PauseMenu", Priority = 10 },
	{ Name = "Underwater", Priority = 0 },
}

local COLOR_PANEL = Color3.fromRGB(24, 24, 28)
local COLOR_BUTTON = Color3.fromRGB(52, 52, 60)
local COLOR_ACTIVE = Color3.fromRGB(46, 110, 220)
local COLOR_TEXT = Color3.fromRGB(235, 235, 240)
local COLOR_QUIET = Color3.fromRGB(150, 150, 160)

local REFRESH_INTERVAL = 0.1

local function create(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className :: any)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	for _, child in (children or {}) :: { Instance } do
		child.Parent = instance
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

local function label(text: string, order: number): TextLabel
	return create("TextLabel", {
		Text = text,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = COLOR_QUIET,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

local function row(order: number): Frame
	return create("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local function button(parent: Instance, text: string, order: number): TextButton
	return create("TextButton", {
		Parent = parent,
		Name = text,
		Text = text,
		LayoutOrder = order,
		Size = UDim2.new(0, 96, 1, 0),
		BackgroundColor3 = COLOR_BUTTON,
		AutoButtonColor = true,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = COLOR_TEXT,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
	})
end

local function formatValue(value: any): string
	if typeof(value) == "number" then
		return string.format("%.2f", value)
	end
	return tostring(value)
end

-- One line per bus, plus Main: live volume, then each preset insert with the live value of every prop presets set
local function describeMix(engine: any): string
	local presets = engine.Presets
	local resolved = presets:GetResolved()
	if not resolved then
		return "Not started"
	end

	local snapshots = {}
	for _, snapshot in presets:GetSnapshots() do
		table.insert(snapshots, string.format("%s (%d)", snapshot.Name, snapshot.Priority))
	end

	local lines = {
		string.format("Platform  %s", tostring(presets.Platform)),
		string.format("Profile   %s", presets.OutputProfile or "-"),
		string.format("Snapshots %s", if #snapshots > 0 then table.concat(snapshots, ", ") else "-"),
		string.format("Layers    %s", table.concat(resolved.Layers, " > ")),
		"",
	}

	local function describeChain(name: string, volume: number, chain: any, inserts: { any }): string
		local parts = { string.format("%-11s %s", name, formatValue(volume)) }

		local live = {}
		for _, insert in chain:GetInserts() do
			live[insert.Instance.Name] = insert.Instance
		end

		for _, insert in inserts do
			local instance = live[insert.Id]
			local props = {}
			for key in insert.Props do
				local value = if instance then (instance :: any)[key] else "?"
				table.insert(props, string.format("%s %s", key, formatValue(value)))
			end
			table.sort(props)
			table.insert(
				parts,
				string.format("  %s%s", insert.Id, if #props > 0 then " (" .. table.concat(props, ", ") .. ")" else "")
			)
		end

		return table.concat(parts, "\n")
	end

	for _, bus in engine:GetBusNames() do
		local gain = resolved.Buses[bus]
		table.insert(lines, describeChain(bus, engine.Mixes[bus].Instance.Volume, engine.Inserts[bus], gain.Inserts))
	end

	table.insert(lines, describeChain("Main", engine.Master.Instance.Volume, engine.MainInserts, resolved.Main.Inserts))

	return table.concat(lines, "\n")
end

local function DebugPanel(engine: any)
	local trove = Trove.new()
	local presets = engine.Presets
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = trove:Add(create("ScreenGui", {
		Name = "OrchestraDebug",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}))

	local panel = create("Frame", {
		Name = "Panel",
		Parent = gui,
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(340, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COLOR_PANEL,
		BackgroundTransparency = 0.1,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	create("TextLabel", {
		Parent = panel,
		Text = "Orchestra presets",
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = COLOR_TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Platform
	label("Platform", 1).Parent = panel
	local platformRow = row(2)
	platformRow.Name = "Platform"
	platformRow.Parent = panel

	local platformButtons: { [string]: TextButton } = {}
	for index, platform in PLATFORMS do
		local platformButton = button(platformRow, platform, index)
		platformButtons[platform] = platformButton
		trove:Connect(platformButton.Activated, function()
			presets:SetPlatform(platform)
		end)
	end

	-- Output profile
	label("Output profile", 3).Parent = panel
	local profileRow = row(4)
	profileRow.Name = "Profile"
	profileRow.Parent = panel

	local headphonesButton = button(profileRow, "Headphones", 1)
	trove:Connect(headphonesButton.Activated, function()
		presets:SetOutputProfile(if presets.OutputProfile == "Headphones" then nil else "Headphones")
	end)

	-- Snapshots
	label("Snapshots", 5).Parent = panel
	local snapshotRow = row(6)
	snapshotRow.Name = "Snapshots"
	snapshotRow.Parent = panel

	local handles: { [string]: any } = {}
	local snapshotButtons: { [string]: TextButton } = {}
	for index, snapshot in SNAPSHOTS do
		local snapshotButton = button(snapshotRow, snapshot.Name, index)
		snapshotButtons[snapshot.Name] = snapshotButton
		trove:Connect(snapshotButton.Activated, function()
			local handle = handles[snapshot.Name]
			if handle and handle.Active then
				handle:Pop()
				handles[snapshot.Name] = nil
			else
				handles[snapshot.Name] = presets:Push(snapshot.Name, { Priority = snapshot.Priority })
			end
		end)
	end

	-- Live readout
	local readout = create("TextLabel", {
		Name = "Readout",
		Parent = panel,
		LayoutOrder = 7,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.RobotoMono,
		TextSize = 12,
		TextColor3 = COLOR_TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Text = "",
	})

	local function refresh()
		for platform, platformButton in platformButtons do
			platformButton.BackgroundColor3 = if presets.Platform == platform then COLOR_ACTIVE else COLOR_BUTTON
		end

		headphonesButton.BackgroundColor3 = if presets.OutputProfile == "Headphones" then COLOR_ACTIVE else COLOR_BUTTON

		for name, snapshotButton in snapshotButtons do
			local handle = handles[name]
			snapshotButton.BackgroundColor3 = if handle and handle.Active then COLOR_ACTIVE else COLOR_BUTTON
		end

		readout.Text = describeMix(engine)
	end

	-- Live values tween, so poll a few times a second rather than only on Changed
	local elapsed = 0
	trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
	trove:Connect(presets.Changed, refresh)

	refresh()
	gui.Parent = playerGui

	return trove
end

return DebugPanel
