--!strict
-- A button that shows whether its option is on, with a hover state. Colours ease with a spring.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local Theme = require("../Theme")

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

type Scope = Fusion.Scope<typeof(Fusion)>
type UsedAs<T> = Fusion.UsedAs<T>

export type Props = {
	Text: string,
	Active: UsedAs<boolean>,
	OnActivated: () -> (),
	LayoutOrder: number?,
	Width: number?,
}

local function ToggleButton(scope: Scope, props: Props): Fusion.Child
	local hovering = scope:Value(false)

	local color = scope:Computed(function(use)
		if use(props.Active) then
			return Theme.Colors.Accent
		end
		return if use(hovering) then Theme.Colors.ButtonHover else Theme.Colors.Button
	end)

	return scope:New("TextButton")({
		Name = props.Text,
		Text = props.Text,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromOffset(props.Width or 104, Theme.ButtonHeight),
		BackgroundColor3 = scope:Spring(color, 40),
		AutoButtonColor = false,
		Font = Theme.Fonts.Body,
		TextSize = Theme.TextSizes.Body,
		TextColor3 = Theme.Colors.Text,

		[OnEvent("Activated")] = props.OnActivated,
		[OnEvent("MouseEnter")] = function()
			hovering:set(true)
		end,
		[OnEvent("MouseLeave")] = function()
			hovering:set(false)
		end,

		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		},
	})
end

return ToggleButton
