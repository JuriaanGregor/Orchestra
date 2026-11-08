--!strict
-- A titled group of controls: a quiet heading over a row that wraps when it runs out of width

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local Theme = require("../Theme")

local Children = Fusion.Children
local Child = Fusion.Child

type Scope = Fusion.Scope<typeof(Fusion)>

export type Props = {
	Title: string,
	LayoutOrder: number?,
	Content: Fusion.Child,
}

local function Section(scope: Scope, props: Props): Fusion.Child
	return scope:New("Frame")({
		Name = props.Title,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		[Children] = Child({
			scope:New("UIListLayout")({
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			scope:New("TextLabel")({
				Name = "Title",
				LayoutOrder = 1,
				Text = props.Title,
				Size = UDim2.new(1, 0, 0, Theme.RowHeight),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Label,
				TextSize = Theme.TextSizes.Body,
				TextColor3 = Theme.Colors.Quiet,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			scope:New("Frame")({
				Name = "Content",
				LayoutOrder = 2,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,

				[Children] = Child({
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						Wraps = true,
						Padding = UDim.new(0, Theme.Gap),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					props.Content,
				}),
			}),
		}),
	})
end

return Section
