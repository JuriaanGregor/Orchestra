--!strict
-- The live mix: a row per bus, in the engine's order, then the Main layer

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.DevPackages.Fusion)
local MixState = require("../MixState")
local BusRow = require("./BusRow")

local Children = Fusion.Children
local Child = Fusion.Child

type Scope = Fusion.Scope<typeof(Fusion)>

export type Props = {
	State: MixState.MixState,
	LayoutOrder: number?,
}

local function MixView(scope: Scope, props: Props): Fusion.Child
	return scope:New("Frame")({
		Name = "Mix",
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		[Children] = Child({
			scope:New("UIListLayout")({
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			scope:ForPairs(props.State.BusNames, function(_use, innerScope: Scope, index: number, bus: string)
				return index,
					BusRow(innerScope, {
						State = props.State,
						ChainKey = bus,
						LayoutOrder = index,
					})
			end),

			BusRow(scope, {
				State = props.State,
				ChainKey = props.State.MainKey,
				-- After every bus
				LayoutOrder = 10000,
			}),
		}),
	})
end

return MixView
