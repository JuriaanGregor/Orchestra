--!strict
-- A label and a value on one line, the value wrapping under itself when it's long

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local Theme = require("../Theme")

local Children = Fusion.Children

type Scope = Fusion.Scope<typeof(Fusion)>
type UsedAs<T> = Fusion.UsedAs<T>

local LABEL_WIDTH = 76

export type Props = {
	Label: string,
	Value: UsedAs<string>,
	LayoutOrder: number?,
}

local function InfoLine(scope: Scope, props: Props): Fusion.Child
	return scope:New("Frame")({
		Name = props.Label,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		[Children] = {
			scope:New("TextLabel")({
				Name = "Label",
				Text = props.Label,
				Size = UDim2.fromOffset(LABEL_WIDTH, Theme.RowHeight),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Body,
				TextSize = Theme.TextSizes.Small,
				TextColor3 = Theme.Colors.Quiet,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			scope:New("TextLabel")({
				Name = "Value",
				Text = props.Value,
				Position = UDim2.fromOffset(LABEL_WIDTH, 0),
				Size = UDim2.new(1, -LABEL_WIDTH, 0, Theme.RowHeight),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Mono,
				TextSize = Theme.TextSizes.Small,
				TextColor3 = Theme.Colors.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
			}),
		},
	})
end

return InfoLine
