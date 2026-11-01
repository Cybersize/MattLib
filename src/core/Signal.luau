--!nonstrict
local Diagnostics = require(script.Parent.Parent.utils.Diagnostics)
local Signal = {}
Signal.__index = Signal
local depth, draining = 0, false
local pending, order = {}, {}

local function drain()
	if depth > 0 or draining then return end
	draining = true
	local index = 1
	while index <= #order do
		assert(index < 10000, "MattLib: cyclic signal updates")
		local signal = order[index]
		local previous = pending[signal]
		pending[signal] = nil
		index += 1
		if signal.alive and previous and previous.value ~= signal.value then
			local listeners = table.clone(signal.listeners)
			for listener in listeners do
				if signal.listeners[listener] then
					local ok, err = pcall(listener, signal.value, previous.value)
					if not ok then warn("MattLib subscriber: " .. tostring(err)) end
				end
			end
		end
	end
	pending, order, draining = {}, {}, false
end

function Signal.new(value)
	return setmetatable({ value = value, listeners = {}, alive = true }, Signal)
end
function Signal.is(value)
	return type(value) == "table" and getmetatable(value) == Signal
end
function Signal:get() return self.value end
function Signal:set(value)
	assert(self.alive, "Cannot update a destroyed signal")
	if self.value == value then return end
	if not pending[self] then
		pending[self] = { value = self.value }
		table.insert(order, self)
	end
	self.value = value
	drain()
end
function Signal:update(updater)
	assert(type(updater) == "function", "Signal:update expects a function")
	self:set(updater(self.value))
end
function Signal:subscribe(listener)
	assert(self.alive and type(listener) == "function", "Invalid signal subscription")
	-- A token per subscription permits the same callback to be subscribed twice.
	local token = function(...) listener(...) end
	self.listeners[token] = true
	Diagnostics.add("subscriptions", 1)
	return function()
		if self.listeners[token] then
			self.listeners[token] = nil
			Diagnostics.add("subscriptions", -1)
		end
	end
end
function Signal:Destroy()
	if not self.alive then return end
	self.alive = false
	for token in self.listeners do
		self.listeners[token] = nil
		Diagnostics.add("subscriptions", -1)
	end
end
function Signal.batch(callback)
	depth += 1
	local result = table.pack(pcall(callback))
	depth -= 1
	drain()
	if not result[1] then error(result[2], 0) end
	return table.unpack(result, 2, result.n)
end
function Signal.derived(dependencies, compute)
	assert(type(compute) == "function", "derived expects a compute function")
	local function evaluate()
		local values = {}
		for i, dependency in dependencies do
			assert(Signal.is(dependency), "Derived dependencies must be signals")
			values[i] = dependency:get()
		end
		return compute(table.unpack(values, 1, #dependencies))
	end
	local output = Signal.new(evaluate())
	local disconnects = {}
	for _, dependency in dependencies do
		table.insert(disconnects, dependency:subscribe(function() output:set(evaluate()) end))
	end
	local baseDestroy = output.Destroy
	function output:Destroy()
		for _, disconnect in disconnects do disconnect() end
		table.clear(disconnects)
		baseDestroy(self)
	end
	return output
end
return Signal
