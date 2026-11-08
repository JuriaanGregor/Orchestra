--!strict
--[[
	The panel's frame: a titled card down the left of the screen that scrolls when its content is taller than the
	screen. It scales down on small screens, and its title bar has a button that collapses it to just that bar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local Theme = require("../Theme")

local Children = Fusion.Children
local Child = Fusion.Child
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

type Scope = Fusion.Scope<typeof(Fusion)>

local TITLE_HEIGHT = 22
local COLLAPSE_SIZE = 22

-- The title bar is the collapse toggle: when the panel is scaled down, it grows so it stays this tall on screen
local MIN_TAP_HEIGHT = 32

-- The panel takes at most this share of the screen width, and is laid out for at least this screen height
local MAX_WIDTH_SHARE = 0.42
local DESIGN_HEIGHT = 640
local MIN_SCALE = 0.55

export type Props = {
	Title: string,
	Content: Fusion.Child,
}

-- The viewport size, kept up to date as the window or the camera changes
local function viewportSize(scope: Scope): Fusion.Value<Vector2>
	local size = scope:Value(Vector2.new(1920, 1080))
	local cameraConnection: RBXScriptConnection? = nil

	local function watch(camera: Camera?)
		if cameraConnection then
			cameraConnection:Disconnect()
			cameraConnection = nil
		end
		if not camera then
			return
		end
		size:set(camera.ViewportSize)
		cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			size:set(camera.ViewportSize)
		end)
	end

	watch(workspace.CurrentCamera)
	table.insert(
		scope,
		workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			watch(workspace.CurrentCamera)
		end)
	)
	table.insert(scope, function()
		if cameraConnection then
			cameraConnection:Disconnect()
		end
	end)

	return size
end

local function Panel(scope: Scope, props: Props): Fusion.Child
	local collapsed = scope:Value(false)
	local viewport = viewportSize(scope)

	local scale = scope:Computed(function(use)
		local size: Vector2 = use(viewport)
		local fit = math.min(size.X * MAX_WIDTH_SHARE / Theme.Width, size.Y / DESIGN_HEIGHT)
		return math.clamp(fit, MIN_SCALE, 1)
	end)

	local expanded = scope:Computed(function(use)
		return not use(collapsed)
	end)

	-- In panel units: UIScale shrinks it again, so divide to keep MIN_TAP_HEIGHT on screen
	local titleHeight = scope:Computed(function(use)
		local currentScale: number = use(scale)
		return if currentScale < 1 then math.max(TITLE_HEIGHT, MIN_TAP_HEIGHT / currentScale) else TITLE_HEIGHT
	end)

	local function toggle()
		collapsed:set(not peek(collapsed))
	end

	return scope:New("ScrollingFrame")({
		Name = "Panel",
		Position = UDim2.fromOffset(Theme.Margin, Theme.Margin),
		-- Open: the screen's height less the margins, divided by the scale since UIScale shrinks it again.
		-- Collapsed: just the title bar.
		Size = scope:Computed(function(use)
			if use(collapsed) then
				return UDim2.fromOffset(Theme.Width, use(titleHeight) + 2 * Theme.Padding)
			end
			local currentScale: number = use(scale)
			return UDim2.new(0, Theme.Width, 1 / currentScale, -2 * Theme.Margin / currentScale)
		end),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollingEnabled = expanded,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Colors.Quiet,

		[Children] = Child({
			scope:New("UIScale")({ Scale = scale }),
			scope:New("UICorner")({ CornerRadius = UDim.new(0, Theme.CornerRadius) }),
			scope:New("UIPadding")({
				PaddingTop = UDim.new(0, Theme.Padding),
				PaddingBottom = UDim.new(0, Theme.Padding),
				PaddingLeft = UDim.new(0, Theme.Padding),
				PaddingRight = UDim.new(0, Theme.Padding),
			}),
			scope:New("UIListLayout")({
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			-- The whole bar toggles the panel, so it's easy to hit on a touch screen
			scope:New("TextButton")({
				Name = "TitleBar",
				LayoutOrder = 0,
				Text = "",
				Size = scope:Computed(function(use)
					return UDim2.new(1, 0, 0, use(titleHeight))
				end),
				BackgroundTransparency = 1,
				AutoButtonColor = false,

				[OnEvent("Activated")] = toggle,

				[Children] = Child({
					scope:New("TextLabel")({
						Name = "Title",
						Text = props.Title,
						Size = UDim2.new(1, -(COLLAPSE_SIZE + Theme.Gap), 1, 0),
						BackgroundTransparency = 1,
						Font = Theme.Fonts.Title,
						TextSize = Theme.TextSizes.Title,
						TextColor3 = Theme.Colors.Text,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					-- Shows the state; the bar around it takes the taps
					scope:New("TextLabel")({
						Name = "Collapse",
						Text = scope:Computed(function(use)
							return if use(collapsed) then "+" else "–"
						end),
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(COLLAPSE_SIZE, COLLAPSE_SIZE),
						BackgroundColor3 = Theme.Colors.Button,
						Font = Theme.Fonts.Label,
						TextSize = Theme.TextSizes.Title,
						TextColor3 = Theme.Colors.Text,

						[Children] = scope:New("UICorner")({ CornerRadius = UDim.new(0, 6) }),
					}),
				}),
			}),

			scope:New("Frame")({
				Name = "Body",
				LayoutOrder = 1,
				Visible = expanded,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,

				[Children] = Child({
					scope:New("UIListLayout")({
						Padding = UDim.new(0, 10),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					props.Content,
				}),
			}),
		}),
	})
end

return Panel
