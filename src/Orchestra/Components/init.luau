--!strict
return table.freeze({
	["Routing"] = require("@self/Routing"),
	["Stream"] = require("@self/Stream"),
	["Output"] = require("@self/Output"),
	["Fader"] = require("@self/Fader"),
	["Layer"] = require("@self/Layer"),
	["InsertChain"] = require("@self/InsertChain"),
	["Wire"] = require("@self/Wire"),
	["Effects"] = require("@self/Effects"),
	["Transforms"] = require("@self/Transforms"),
	["Analyzers"] = require("@self/Analyzers"),
	--["Parameter"] = require("@self/Parameter")
})
