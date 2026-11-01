--!nonstrict
local Diagnostics = require(script.Parent.Diagnostics)
local Scope = {}
Scope.__index = Scope

function Scope.new()
	return setmetatable({ alive = true, tasks = {} }, Scope)
end

function Scope:Add(cleanup)
	assert(type(cleanup) == "function", "Scope:Add expects a cleanup function")
	if not self.alive then cleanup(); return cleanup end
	self.tasks[cleanup] = true
	return cleanup
end

function Scope:Remove(cleanup, run)
	if self.tasks[cleanup] then
		self.tasks[cleanup] = nil
		if run then cleanup() end
	end
end

function Scope:Connect(signal, callback)
	local connection = signal:Connect(callback)
	Diagnostics.add("connections", 1)
	local connected = true
	local function disconnect()
		if connected then
			connected = false
			connection:Disconnect()
			Diagnostics.add("connections", -1)
		end
	end
	self:Add(disconnect)
	return function() self:Remove(disconnect, true) end
end

function Scope:Delay(seconds, callback)
	assert(type(seconds) == "number" and seconds >= 0, "Invalid delay")
	local thread
	local pending = true
	local function cancel()
		if pending then
			pending = false
			if thread then pcall(task.cancel, thread) end
		end
	end
	self:Add(cancel)
	thread = task.delay(seconds, function()
		if not pending or not self.alive then return end
		pending = false
		self:Remove(cancel, false)
		callback()
	end)
	return function() self:Remove(cancel, true) end
end

function Scope:Destroy()
	if not self.alive then return end
	self.alive = false
	local tasks = self.tasks
	self.tasks = {}
	for cleanup in tasks do
		local ok, err = pcall(cleanup)
		if not ok then warn("MattLib cleanup: " .. tostring(err)) end
	end
end

return Scope
