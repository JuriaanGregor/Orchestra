local runStep = require("@scripts/processExecution").runStep

runStep("Selene check", { "selene", "src" })
runStep("Style check", { "stylua", "-c", "src" })
runStep(
	"Type check",
	{ "luau-lsp", "analyze", "--definitions=@roblox=globalTypes.d.luau", "--sourcemap", "sourcemap.json", "src" }
)