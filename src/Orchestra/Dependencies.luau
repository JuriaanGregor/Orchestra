--!strict
--[[
	Resolves Orchestra's external dependencies.

	Orchestra expects its dependencies to sit next to it. That is how Wally lays out a package's
	dependencies, and test.project.json mounts Orchestra inside `ReplicatedStorage.Packages` to match.
	Every other module requires its dependencies through this file, so this is the only place that
	knows where they live.
]]

local Packages = script.Parent.Parent

local t = require(Packages.t)
local Trove = require(Packages.Trove)
local EnumList = require(Packages.EnumList)
local Signals = require(Packages.Signals)
local Promise = require(Packages.Promise)

export type Trove = Trove.Trove
export type EnumList = EnumList.EnumList
export type EnumItem = EnumList.EnumItem
export type Getter<T> = Signals.getter<T>

return {
	t = t,
	Trove = Trove,
	EnumList = EnumList,
	Signals = Signals,
	Promise = Promise,
}
