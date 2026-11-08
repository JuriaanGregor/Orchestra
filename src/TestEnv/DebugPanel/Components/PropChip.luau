--!strict
-- One insert property and its live value, as a small chip

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local Theme = require("../Theme")

local Children = Fusion.Children

type Scope = Fusion.Scope<typeof(Fusion)>
type UsedAs<T> = Fusion.UsedAs<T>

export type Props = {
	Name: string,
	Value: UsedAs<string>,
	LayoutOrder: number?,
}

local function PropChip(scope: Scope, props: Props): Fusion.Child
	return scope:New("TextLabel")({
		Name = props.Name,
		LayoutOrder = props.LayoutOrder,
		Text = scope:Computed(function(use)
			return string.format("%s %s", props.Name, use(props.Value))
		end),
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Colors.Surface,
		Font = Theme.Fonts.Mono,
		TextSize = Theme.TextSizes.Small - 1,
		TextColor3 = Theme.Colors.Text,

		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 4) }),
			scope:New("UIPadding")({
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
			}),
		},
	})
end

return PropChip
