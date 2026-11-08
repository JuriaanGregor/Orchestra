--!strict
-- One preset insert on a chain: its Id, then a chip per property the presets set, with the live value

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local Theme = require("../Theme")
local MixState = require("../MixState")
local PropChip = require("./PropChip")

local Children = Fusion.Children
local Child = Fusion.Child

type Scope = Fusion.Scope<typeof(Fusion)>

local INDENT = 12
local ID_WIDTH = 76

export type Props = {
	State: MixState.MixState,
	ChainKey: string,
	Id: string,
	LayoutOrder: number?,
}

local function InsertRow(scope: Scope, props: Props): Fusion.Child
	local propKeys = props.State.PropKeysOf(scope, props.ChainKey, props.Id)

	return scope:New("Frame")({
		Name = props.Id,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		[Children] = Child({
			scope:New("UIPadding")({ PaddingLeft = UDim.new(0, INDENT) }),

			scope:New("TextLabel")({
				Name = "Id",
				Text = props.Id,
				Size = UDim2.fromOffset(ID_WIDTH, 16),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Body,
				TextSize = Theme.TextSizes.Small,
				TextColor3 = Theme.Colors.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),

			scope:New("Frame")({
				Name = "Props",
				Position = UDim2.fromOffset(ID_WIDTH, 0),
				Size = UDim2.new(1, -ID_WIDTH, 0, 16),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,

				[Children] = Child({
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						Wraps = true,
						Padding = UDim.new(0, 4),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					scope:ForPairs(propKeys, function(_use, innerScope: Scope, index: number, prop: string)
						return index,
							PropChip(innerScope, {
								Name = prop,
								Value = props.State.PropValueOf(innerScope, props.ChainKey, props.Id, prop),
								LayoutOrder = index,
							})
					end),
				}),
			}),
		}),
	})
end

return InsertRow
