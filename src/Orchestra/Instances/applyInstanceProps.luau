--!strict
--!nolint LocalUnused
--!nolint LocalShadow

local Package = script.Parent.Parent
local Types = require(Package.Types)
local parseError = require(Package.Logging.parseError)

local function trySetProperty(instance: Instance, property: string, value: unknown)
	(instance :: any)[property] = value
end

local function isPropertyAssignable(instance: Instance, property: string)
	(instance :: any)[property] = (instance :: any)[property]
end

local function setProperty(instance: Instance, property: string, value: unknown): boolean
	local success = xpcall(trySetProperty :: any, parseError, instance, property, value)
	if not success then
		if not pcall(isPropertyAssignable, instance, property) then
			warn(
				string.format(
					"[Orchestra > Instance] Property can not be assigned at %s, with property %s",
					instance.ClassName,
					property
				)
			)
			return false
		else
			local typeExpected = typeof((instance :: any)[property])
			local typeReceived = typeof(value)

			if typeExpected ~= typeReceived then
				warn(string.format("[Orchestra > Instance] Expected %s type, received %s", typeExpected, typeReceived))
				return false
			else
				warn(string.format("[Orchestra > Instance] Property %s could not set to the value", property))
				return false
			end
		end
	end

	return true
end

local function applyInstanceProps(
	applyTo: Instance, 
	properties: Types.PropertyTable
)

	-- Make sure we don't have any duplicates or nil values..
	local props: {[string]: any} = {}
	for key, value in properties do
		if value ~= nil then
			if props[key] then
				warn(string.format("[Orchestra > Instance] Duplicate property %s", key))
				continue
			end

			props[key] = value
		end
	end

	for key, value in props do
		if key == "Attributes" then
			if typeof(value) ~= "table" then
				warn("[Orchestra > Instance] Attributes must be a table of key-value pairs")
				continue
			end

			for attribute, attributeValue in value do
				applyTo:SetAttribute(attribute, attributeValue)
			end

			continue
		elseif key == "Tag" then
			if typeof(value) == "string" then
				applyTo:AddTag(value)
				continue
			elseif typeof(value) == "table" then
				for _, tag in ipairs(value) do
					applyTo:AddTag(tag)
				end
				continue
			else 
				warn("[Orchestra > Instance] Tag must be a string or a table of strings")
				continue
			end
		else 
			if not setProperty(applyTo, key, value) then
				warn(string.format("[Orchestra > Instance] Could not set property %s", key))
				continue
			end
		end
	end

	return applyTo
end

return applyInstanceProps