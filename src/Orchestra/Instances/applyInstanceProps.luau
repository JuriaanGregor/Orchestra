--!strict
--!nolint LocalUnused
--!nolint LocalShadow

--[[
    Applies properties to an instance
]]

local Package = script.Parent.Parent

-- Utility
local xtypeof = require(Package.Utility.xtypeof)

-- Logging
local parseError = require(Package.Logging.parseError)

local function unsafePropertySet(instance: Instance, property: string, value: unknown)
	(instance :: any)[property] = value
end

local function testPropertyAssignable(instance: Instance, property: string)
	(instance :: any)[property] = (instance :: any)[property]
end

local function setTag(instance: Instance, tag: string)
	instance:AddTag(tag)
end

local function setAttribute(instance: Instance, attribute: string, value: unknown)
	local ok, response = pcall(function()
		return instance:SetAttribute(attribute, value)
	end)

	if not ok then
		warn(
			string.format(
				"[applyInstanceProps] - Failed to set attribute '%s' on %s: %s",
				tostring(attribute),
				tostring(instance.ClassName),
				tostring(response)
			)
		)
		return
	end
end

local function setProperty(instance: Instance, property: string, value: unknown)
	local unsafeSuccess, _unsafeErr = xpcall(unsafePropertySet :: any, parseError, instance, property, value)
	if not unsafeSuccess then
		local propAssignable = pcall(function()
			return testPropertyAssignable(instance, property)
		end)

		if not propAssignable then
			warn(
				string.format(
					"[applyInstanceProps] - Cannot assign property '%s' on %s",
					tostring(property),
					tostring(instance.ClassName)
				)
			)

			return
		else
			-- Property is assignable, but not settable since likely the wrong type is received
			local propValue = typeof(value)
			local expectedValue = typeof((instance :: any)[property])

			if propValue == expectedValue then
				warn(
					string.format(
						"[applyInstanceProps] - Failed to set property '%s' on %s for an unknown reason.",
						tostring(property),
						tostring(instance.ClassName)
					)
				)
			else
				warn(
					string.format(
						"[applyInstanceProps] - Invalid type for property '%s' on %s. Expected %s, got %s.",
						tostring(property),
						tostring(instance.ClassName),
						tostring(expectedValue),
						tostring(propValue)
					)
				)
			end
		end
	end
end

local function applyInstanceProps(applyTo: Instance, props: { [string]: any })
	for propIndex, propValue in props do
		local keyType = xtypeof(propIndex)

		if keyType == "string" then
			if propIndex == "Tag" or propIndex == "Tags" then
				if typeof(propValue) == "table" then
					for _, tag in propValue do
						if not (typeof(tag) == "string") then
							continue
						end

						setTag(applyTo, tag)
					end
				end
			elseif propIndex == "Attributes" then
				if typeof(propValue) == "table" then
					for attrIndex, attrValue in propValue do
						if not (typeof(attrIndex) == "string") then
							continue
						end

						setAttribute(applyTo, attrIndex, attrValue)
					end
				else
					error(
						string.format(
							"[applyInstanceProps] - Invalid type for 'Attributes' on %s. Expected table, got %s.",
							tostring(applyTo.ClassName),
							tostring(typeof(propValue))
						),
						2
					)
				end
			else
				-- Set the property on the instance
				setProperty(applyTo, propIndex, propValue)
			end
		end
	end
end

return applyInstanceProps
