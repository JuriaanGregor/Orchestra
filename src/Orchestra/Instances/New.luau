--!strict
--!nolint LocalUnused
--!nolint LocalShadow

--[[
    Constucts and returns a new instance, with the ability to set properties, 
    event handlers and other attributes on the instance right away
]]

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

-- Statics
local Package = script.Parent.Parent

-- Includes
local Types = require(Package.Types)
local defaultProps = require(Package.Instances.defaultProps)
local applyProps = require(Package.Instances.applyInstanceProps)

type Component = (Types.PropertyTable) -> Instance 

local function New(
    className: string
)

    if (className :: any) == nil then
        warn("[Orchestra > Instance] No classname provided")
    end 

    return function(
        props: Types.PropertyTable
    ): (Instance, string)
        local ok, instance = pcall(Instance.new, className)
        if not ok then
            warn("[Orchestra > Instance] Not a valid classname, or can not be created using Instance.new()")
        end

        local classDefaults = defaultProps[className]
        if classDefaults ~= nil then
            for defaultProp, defaultValue in classDefaults do 
                (instance :: any)[defaultProp] = defaultValue
            end 
        end

        -- Apply properties
        applyProps(instance, props)

        -- Add Orchestra tag and our GUID to the instance for later tracking..
        instance:AddTag("Orchestra")

        -- Generate a GUID for the instance
        local GUID = HttpService:GenerateGUID(false)
        instance:SetAttribute("GUID", GUID)

        return instance, GUID
    end
end

return New