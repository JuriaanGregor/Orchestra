--!strict
-- A bus (or the Main layer): its name, a volume meter and the value, then a row per preset insert

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local Theme = require("../Theme")
local MixState = require("../MixState")
local VolumeMeter = require("./VolumeMeter")
local InsertRow = require("./InsertRow")

local Children = Fusion.Children
local Child = Fusion.Child

type Scope = Fusion.Scope<typeof(Fusion)>

local NAME_WIDTH = 88
local VALUE_WIDTH = 40

export type Props = {
	State: MixState.MixState,
	ChainKey: string,
	LayoutOrder: number?,
}

local function BusRow(scope: Scope, props: Props): Fusion.Child
	local volume = props.State.VolumeOf(scope, props.ChainKey)
	local insertIds = props.State.InsertIdsOf(scope, props.ChainKey)

	return scope:New("Frame")({
		Name = props.ChainKey,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		[Children] = Child({
			scope:New("UIListLayout")({
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			scope:New("Frame")({
				Name = "Header",
				LayoutOrder = 0,
				Size = UDim2.new(1, 0, 0, Theme.RowHeight),
				BackgroundTransparency = 1,

				[Children] = Child({
					scope:New("TextLabel")({
						Name = "Name",
						Text = props.ChainKey,
						Size = UDim2.new(0, NAME_WIDTH, 1, 0),
						BackgroundTransparency = 1,
						Font = Theme.Fonts.Label,
						TextSize = Theme.TextSizes.Small,
						TextColor3 = Theme.Colors.Text,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					VolumeMeter(scope, {
						Volume = volume,
						Size = UDim2.new(1, -(NAME_WIDTH + VALUE_WIDTH + 8), 0, 6),
						Position = UDim2.new(0, NAME_WIDTH, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
					}),

					scope:New("TextLabel")({
						Name = "Value",
						Text = scope:Computed(function(use)
							return string.format("%.2f", use(volume))
						end),
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Size = UDim2.new(0, VALUE_WIDTH, 1, 0),
						BackgroundTransparency = 1,
						Font = Theme.Fonts.Mono,
						TextSize = Theme.TextSizes.Small,
						TextColor3 = Theme.Colors.Text,
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
				}),
			}),

			scope:ForPairs(insertIds, function(_use, innerScope: Scope, index: number, id: string)
				return index,
					InsertRow(innerScope, {
						State = props.State,
						ChainKey = props.ChainKey,
						Id = id,
						LayoutOrder = index,
					})
			end),
		}),
	})
end

return BusRow
