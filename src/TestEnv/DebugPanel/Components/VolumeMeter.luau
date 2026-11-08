--!strict
-- A horizontal bar for a fader volume (0 - 3), with a mark at 1 (unity). The bar turns warm above unity.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local Theme = require("../Theme")

local Children = Fusion.Children

type Scope = Fusion.Scope<typeof(Fusion)>
type UsedAs<T> = Fusion.UsedAs<T>

export type Props = {
	Volume: UsedAs<number>,
	LayoutOrder: number?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
}

local function VolumeMeter(scope: Scope, props: Props): Fusion.Child
	local fraction = scope:Computed(function(use)
		local volume: number = use(props.Volume)
		return math.clamp(volume / Theme.MaxVolume, 0, 1)
	end)

	return scope:New("Frame")({
		Name = "VolumeMeter",
		LayoutOrder = props.LayoutOrder,
		Size = props.Size or UDim2.new(1, 0, 0, 6),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = Theme.Colors.Surface,
		ClipsDescendants = true,

		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 3) }),

			scope:New("Frame")({
				Name = "Fill",
				Size = scope:Computed(function(use)
					return UDim2.fromScale(use(fraction), 1)
				end),
				BackgroundColor3 = scope:Computed(function(use)
					return if use(props.Volume) > 1 then Theme.Colors.MeterHot else Theme.Colors.Meter
				end),
				BorderSizePixel = 0,
			}),

			scope:New("Frame")({
				Name = "Unity",
				Position = UDim2.fromScale(1 / Theme.MaxVolume, 0),
				Size = UDim2.new(0, 1, 1, 0),
				BackgroundColor3 = Theme.Colors.Unity,
				BorderSizePixel = 0,
			}),
		},
	})
end

return VolumeMeter
