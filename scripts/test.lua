local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:FindFirstChild("Packages") or error("Packages folder not found")
local DevPackages = ReplicatedStorage:FindFirstChild("DevPackages") or error("DevPackages folder not found")

local Jest = require(DevPackages:FindFirstChild("Jest") or error("Jest not found in DevPackages"))

-- Only Orchestra's own tests: other packages under Packages ship jest.config files too
local Orchestra = Packages:FindFirstChild("Orchestra") or error("Orchestra not found in Packages")
assert(Orchestra:FindFirstChild("jest.config"), "Orchestra has no jest.config")

local status, result = Jest.runCLI(Orchestra, {
	ci = true,
	verbose = false,
}, { Orchestra }):awaitStatus()

if status == "Rejected" then
	print(result)
	error("Tests failed")
elseif result.results.numFailedTestSuites > 0 or result.results.numFailedTests > 0 then
	error(`Tests failed: {result.results.numFailedTests} failed tests, {result.results.numFailedTestSuites} failed suites`)
end
