--!strict
--[[
	Ties a component's Trove to its instance, so destroying either one cleans up both:

	- When the instance is destroyed (by anyone), the Trove is cleaned up.
	- When the Trove is cleaned up (component:Destroy()), the Routing (and with it the wires) and the instance are destroyed.

	Unlike Trove:AttachToInstance, this works for instances that aren't in the game hierarchy yet.
	Call it last in a constructor, so anything added to the Trove before it is cleaned up before the instance goes.
]]

-- `trove` is `any`: Trove.new() doesn't match Trove's exported type exactly
local function bindLifetime(trove: any, instance: Instance, routing: { Destroy: (any) -> () }?)
	-- Trove:Clean is a no-op while it's already cleaning, so this is safe when we destroy the instance ourselves
	trove:Connect(instance.Destroying, function()
		trove:Destroy()
	end)

	if routing then
		trove:Add(routing)
	end

	trove:Add(instance)
end

return bindLifetime
