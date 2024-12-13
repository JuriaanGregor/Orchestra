--!strict
--!nolint LocalUnused
--!nolint LocalShadow

local Package = script.Parent.Parent
local Types = require(Package.Types)

--[[
    Contructs and returns a new Wire object, which is a instance that transports a signal from 
    one component to another.
]]

local Wire = {}
Wire.__index = Wire

function Wire.new()
	local self = {}
	self.type = "Wire"
	self.kind = "Component"

	return setmetatable(self :: any, Wire)
end

function Wire.__tostring()
	return "Wire"
end

function Wire:WireFrom(from: Instance | Types.Component)
end

function Wire:WireTo(to: Instance | Types.Component)
end 

function Wire:Destroy() 
end

return Wire