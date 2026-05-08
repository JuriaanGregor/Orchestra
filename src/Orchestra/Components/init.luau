--!strict
return table.freeze({
	["Routing"] = require(script.Routing),
	["Stream"] = require(script.Stream),
	["Output"] = require(script.Output),
	["Fader"] = require(script.Fader),
	["Layer"] = require(script.Layer),
	["Wire"] = require(script.Wire),
	["Effects"] = require(script.Effects),
	["Transforms"] = require(script.Transforms),
	["Analyzers"] = require(script.Analyzers),
	--["Parameter"] = require(script.Parameter)
})
