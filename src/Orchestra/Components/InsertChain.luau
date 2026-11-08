--!strict

-- Import > Packages
local Dependencies = require("../Dependencies")
local t = Dependencies.t
local Trove = Dependencies.Trove

-- Import > Package
local Fader = require("./Fader")
local Wire = require("./Wire")

-- Types
local Types = require("../Types")

-- An insert is any component with an `In` and `Out` audio instance and a `Destroy` method: an effect, a transform
-- or a Fader
local function isInsert(value: any): boolean
	return typeof(value) == "table"
		and typeof(value.In) == "Instance"
		and typeof(value.Out) == "Instance"
		and typeof(value.Destroy) == "function"
		and Types.tAudioMembers(value.In.ClassName) == true
		and Types.tAudioMembers(value.Out.ClassName) == true
end

---------------------------------------------------------------------
local InsertChain = {}
InsertChain.__index = InsertChain

--[=[
	@class InsertChain
	@tag Base

	An ordered list of inserts (effects, transforms or Faders) between a fixed `In` and `Out`. Adding or removing an
	insert rewires the chain; anything wired into `In` or out of `Out` stays connected. With no inserts, `In` is wired
	straight to `Out`, and the chain passes audio through unchanged.

	Every mix bus and the Main layer have one, see [Orchestra.Inserts] and [Orchestra.MainInserts].

	```lua
	local chain = Orchestra.Inserts.Music
	local eq = Orchestra.Effects.new(Enums.Effect.Equalizer, chain.Instance, { Name = "Tone" })

	chain:Add(eq)
	```

	An insert belongs to the chain once added: destroying the chain destroys it, and destroying the insert removes it
	from the chain. [InsertChain:Remove] hands it back without destroying it.
]=]

--[=[
	@prop Instance Folder
	@within InsertChain
	@readonly

	The folder holding the chain's `In` and `Out` Faders and its wires. A good parent for the inserts.
]=]

--[=[
	@prop In AudioFader
	@within InsertChain
	@readonly

	The instance to wire into: a Fader at volume 1.
]=]

--[=[
	@prop Out AudioFader
	@within InsertChain
	@readonly

	The instance to wire from: a Fader at volume 1.
]=]

--[=[
	@prop Routing Routing
	@within InsertChain
	@readonly

	The `Out` Fader's [Routing], used to wire the chain onwards.
]=]

--[=[
	@prop Fader Fader
	@within InsertChain
	@readonly

	The `Out` [Fader]. It stays at volume 1, except while [Presets] dip the chain to rebuild it.
]=]

local tInsertChain = t.tuple(t.Instance, t.optional(t.map(t.string, t.any)))

--[=[
	@within InsertChain
	Creates an empty InsertChain: a folder under `parent` holding an `In` and an `Out` Fader, wired together.

	@param parent Instance -- Where the chain's folder is created
	@param props { Name: string? }? -- `Name` of the folder, defaults to `InsertChain`
	@return InsertChain
]=]
function InsertChain.new(parent: Instance, props: { [string]: any }?)
	assert(tInsertChain(parent, props))

	local self = {}
	self.Type = "Base"
	self.ClassName = "InsertChain"

	self._trove = Trove.new()
	-- The wires between In, the inserts and Out. Cleaned and rebuilt on every change
	self._wireTrove = self._trove:Extend()
	-- One Trove per insert, holding its Destroying connections
	self._insertTroves = {} :: { [any]: any }
	self._inserts = {} :: { any }
	self._destroyed = false

	local folder = Instance.new("Folder")
	folder.Name = if props and typeof(props.Name) == "string" then props.Name else "InsertChain"
	folder.Parent = parent
	self.Instance = folder

	local inFader = self._trove:Construct(Fader, folder, { Name = "In" })
	local outFader = self._trove:Construct(Fader, folder, { Name = "Out" })

	self.In = inFader.Instance
	self.Out = outFader.Instance
	self.Routing = outFader.Routing
	self.Fader = outFader

	-- Destroying the folder destroys the chain, inserts included
	self._trove:Add(folder)

	local chain = setmetatable(self :: any, InsertChain)

	self._trove:Connect(folder.Destroying, function()
		chain:Destroy()
	end)

	chain:_rewire()

	return chain
end

function InsertChain:__tostring()
	return string.format("InsertChain<%s>: %d inserts", self.Instance.Name, #self._inserts)
end

-- Rebuilds every wire: In -> insert 1 -> ... -> insert n -> Out
function InsertChain:_rewire()
	if self._destroyed then
		return
	end

	self._wireTrove:Clean()

	local previous: Instance = self.In
	for _, insert in self._inserts do
		self:_connect(previous, insert.In)
		previous = insert.Out
	end

	self:_connect(previous, self.Out)
end

function InsertChain:_connect(from: Instance, to: Instance)
	self._wireTrove:Construct(Wire, self.Instance, {
		SourceInstance = from,
		TargetInstance = to,
		Name = string.format("%s -> %s", from.Name, to.Name),
	})
end

-- Takes an insert out of the list and drops our connections to it, without rewiring or destroying it
function InsertChain:_detach(insert: any)
	local index = table.find(self._inserts, insert)
	if index then
		table.remove(self._inserts, index)
	end

	local insertTrove = self._insertTroves[insert]
	if insertTrove then
		self._insertTroves[insert] = nil
		self._trove:Remove(insertTrove)
	end
end

local tAdd = t.tuple(t.any, t.optional(t.number))

--[=[
	@within InsertChain
	Adds an insert at `index` (default: the end, just before `Out`) and rewires the chain.
	Errors if `insert` has no `In` / `Out` audio instance, is already in the chain, or `index` is out of range.

	@param insert Effect | Transform | Fader -- Any component with an `In` and `Out`
	@param index number? -- 1 to the number of inserts + 1
	@return Effect | Transform | Fader -- The insert
]=]
function InsertChain:Add(insert: any, index: number?)
	assert(tAdd(insert, index))
	assert(not self._destroyed, "InsertChain:Add - The chain is destroyed")
	assert(isInsert(insert), "InsertChain:Add - The insert needs an In and Out audio instance, and a Destroy method")

	if table.find(self._inserts, insert) then
		error("InsertChain:Add - The insert is already in this chain")
	end

	local count = #self._inserts
	local position = index or count + 1
	if position ~= math.floor(position) or position < 1 or position > count + 1 then
		error(string.format("InsertChain:Add - Index %s is out of range (1 - %d)", tostring(index), count + 1))
	end

	table.insert(self._inserts, position, insert)
	self:_attach(insert)
	self:_rewire()

	return insert
end

--[=[
	@within InsertChain
	Replaces the inserts with `inserts`, in that order, and rewires the chain once. Inserts already in the chain keep
	their instances; inserts left out are removed but not destroyed, and returned.
	Errors if an item isn't an insert or is listed twice.

	@param inserts { Effect | Transform | Fader }
	@return { Effect | Transform | Fader } -- The inserts that were removed
]=]
function InsertChain:SetInserts(inserts: { any }): { any }
	assert(t.array(t.any)(inserts))
	assert(not self._destroyed, "InsertChain:SetInserts - The chain is destroyed")

	for index, insert in inserts do
		assert(
			isInsert(insert),
			"InsertChain:SetInserts - The insert needs an In and Out audio instance, and a Destroy method"
		)

		if table.find(inserts, insert) ~= index then
			error("InsertChain:SetInserts - An insert is listed twice")
		end
	end

	local removed = {}
	for _, insert in table.clone(self._inserts) do
		if not table.find(inserts, insert) then
			self:_detach(insert)
			table.insert(removed, insert)
		end
	end

	for _, insert in inserts do
		if not self._insertTroves[insert] then
			self:_attach(insert)
		end
	end

	self._inserts = table.clone(inserts)
	self:_rewire()

	return removed
end

-- Watches an insert: destroying it takes it out of the chain, and the chain heals around it
function InsertChain:_attach(insert: any)
	local insertTrove = self._trove:Extend()
	self._insertTroves[insert] = insertTrove

	local function onDestroying()
		-- While the chain is being destroyed, its folder takes inserts parented under it along
		if self._destroyed then
			return
		end

		self:_detach(insert)
		self:_rewire()
	end

	insertTrove:Connect(insert.In.Destroying, onDestroying)
	if insert.Out ~= insert.In then
		insertTrove:Connect(insert.Out.Destroying, onDestroying)
	end
end

--[=[
	@within InsertChain
	Removes an insert and rewires the chain around it. The insert is not destroyed and is no longer owned by the chain.
	Errors if it isn't in the chain.

	@param insert Effect | Transform | Fader
	@return Effect | Transform | Fader -- The insert
]=]
function InsertChain:Remove(insert: any)
	assert(not self._destroyed, "InsertChain:Remove - The chain is destroyed")

	if not table.find(self._inserts, insert) then
		error("InsertChain:Remove - The insert is not in this chain")
	end

	self:_detach(insert)
	self:_rewire()

	return insert
end

--[=[
	@within InsertChain
	Returns the inserts in order, from `In` to `Out`. The list is a copy.

	@return { Effect | Transform | Fader }
]=]
function InsertChain:GetInserts(): { any }
	return table.clone(self._inserts)
end

--[=[
	@within InsertChain
	Destroys the chain: its inserts, its `In` and `Out` Faders (and every wire into or out of them), and its folder.
	Destroying the folder directly does the same.
]=]
function InsertChain:Destroy()
	if self._destroyed then
		return
	end

	self._destroyed = true

	local inserts: { any } = self._inserts
	self._inserts = {}

	-- Drops the insert connections first, so destroying an insert doesn't try to rewire us
	self._trove:Destroy()

	for _, insert in inserts do
		insert:Destroy()
	end
end

return InsertChain
