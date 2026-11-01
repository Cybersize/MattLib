--!nonstrict
local Signal = require(script.Parent.Signal)
local Hooks = {}
local current = nil
local function slot(kind)
	assert(current, "Hooks can only run inside a functional component")
	local fiber = current
	fiber.cursor += 1
	local hook = fiber.hooks[fiber.cursor]
	if hook then assert(hook.kind == kind, "Hook order changed; hooks cannot be conditional")
	else hook = { kind = kind, index = fiber.cursor }; fiber.hooks[fiber.cursor] = hook end
	return hook, fiber
end
local function same(a, b)
	if a == nil or b == nil or #a ~= #b then return false end
	for index, value in a do if value ~= b[index] then return false end end
	return true
end
function Hooks.begin(fiber)
	local previous = current
	current, fiber.cursor = fiber, 0
	return previous
end
function Hooks.finish(fiber, previous, success)
	current = previous
	if success then
		assert(fiber.hookCount == nil or fiber.hookCount == fiber.cursor, "Hook count changed")
		fiber.hookCount = fiber.cursor
	end
end
function Hooks.useState(initial)
	local hook, fiber = slot("state")
	if not hook.initialized then
		hook.initialized = true
		hook.value = if type(initial) == "function" then initial() else initial
		hook.setter = function(nextValue)
			if not fiber.alive then return end
			assert(not current, "State updates during render are unsupported")
			local value = if type(nextValue) == "function" then nextValue(hook.value) else nextValue
			if value ~= hook.value then hook.value = value; fiber.root:enqueue(fiber) end
		end
	end
	return hook.value, hook.setter
end
function Hooks.useRef(initial)
	local hook = slot("ref")
	if not hook.ref then hook.ref = { current = initial } end
	return hook.ref
end
function Hooks.useMemo(compute, dependencies)
	local hook = slot("memo")
	if not hook.initialized or not same(hook.dependencies, dependencies) then
		hook.value = compute()
		hook.dependencies = if dependencies then table.clone(dependencies) else nil
		hook.initialized = true
	end
	return hook.value
end
function Hooks.useEffect(effect, dependencies)
	local hook, fiber = slot("effect")
	if not hook.initialized or not same(hook.dependencies, dependencies) then
		hook.effect = effect
		hook.nextDependencies = if dependencies then table.clone(dependencies) else nil
		fiber.root.effectSerial=(fiber.root.effectSerial or 0)+1
		hook.sequence=fiber.root.effectSerial
		fiber.root.effects[hook] = fiber
	end
end
function Hooks.useSignal(signal)
	assert(Signal.is(signal), "useSignal expects UI.signal()")
	local hook, fiber = slot("signal")
	if hook.signal ~= signal then
		if hook.disconnect then hook.disconnect() end
		hook.signal = signal
		hook.disconnect = signal:subscribe(function() if fiber.alive then fiber.root:enqueue(fiber) end end)
	end
	return signal:get()
end
function Hooks.useEnvironment()
	assert(current, "useEnvironment can only run in a component")
	return current.env
end
function Hooks.useTheme()
	return Hooks.useSignal(Hooks.useEnvironment().theme.signal)
end
function Hooks.cleanup(fiber)
	for _, hook in fiber.hooks do
		fiber.root.effects[hook] = nil
		if hook.disconnect then hook.disconnect(); hook.disconnect = nil end
		if hook.cleanup then
			local cleanup = hook.cleanup
			hook.cleanup = nil
			local ok, err = pcall(cleanup)
			if not ok then warn("MattLib effect cleanup: " .. tostring(err)) end
		end
	end
end
function Hooks.commit(root)
	local effects = root.effects
	root.effects = {}
	local ordered={}
	for hook,fiber in effects do table.insert(ordered,{hook=hook,fiber=fiber}) end
	table.sort(ordered,function(a,b) return a.hook.sequence<b.hook.sequence end)
	for _,entry in ordered do
		local hook,fiber=entry.hook,entry.fiber
		if fiber.alive then
			if hook.cleanup then hook.cleanup(); hook.cleanup = nil end
			hook.dependencies, hook.initialized = hook.nextDependencies, true
			local cleanup = hook.effect()
			assert(cleanup == nil or type(cleanup) == "function", "Effects must return a cleanup function or nil")
			if not fiber.alive and cleanup then cleanup() else hook.cleanup = cleanup end
		end
	end
end
return Hooks
