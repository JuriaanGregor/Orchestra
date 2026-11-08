--!strict
-- The panel's frame: a titled card down the left of the screen that scrolls when its content is taller than the screen

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local Theme = require("../Theme")

local Children = Fusion.Children
local Child = Fusion.Child

type Scope = Fusion.Scope<typeof(Fusion)>

export type Props = {
	Title: string,
	Content: Fusion.Child,
}

local function Panel(scope: Scope, props: Props): Fusion.Child
	return scope:New("ScrollingFrame")({
		Name = "Panel",
		Position = UDim2.fromOffset(Theme.Margin, Theme.Margin),
		Size = UDim2.new(0, Theme.Width, 1, -2 * Theme.Margin),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Colors.Quiet,

		[Children] = Child({
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

			scope:New("TextLabel")({
				Name = "Title",
				LayoutOrder = 0,
				Text = props.Title,
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Title,
				TextSize = Theme.TextSizes.Title,
				TextColor3 = Theme.Colors.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			props.Content,
		}),
	})
end

return Panel
