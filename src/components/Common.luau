--!nonstrict
local Hooks = require(script.Parent.Parent.core.Hooks)
local Scope = require(script.Parent.Parent.utils.Scope)
local Common = {}
function Common.latest(value)
	local ref = Hooks.useRef(value)
	ref.current = value
	return ref
end
function Common.controllable(props, fallback, valueName, callbackName, defaultName)
	valueName, callbackName, defaultName = valueName or "value", callbackName or "onChange", defaultName or "defaultValue"
	local controlled = props[valueName] ~= nil
	local mode = Hooks.useRef(controlled)
	assert(mode.current == controlled, "A control cannot switch between controlled and uncontrolled modes")
	local internal, setInternal = Hooks.useState(function() return if props[defaultName] ~= nil then props[defaultName] else fallback end)
	local _, force = Hooks.useState(0)
	local value = if controlled then props[valueName] else internal
	local function update(nextValue)
		if props.disabled then return end
		if not controlled then setInternal(nextValue) end
		force(function(n) return n + 1 end)
		if props[callbackName] and value ~= nextValue then props[callbackName](nextValue) end
	end
	return value, update
end
function Common.scope()
	local scope = Hooks.useMemo(Scope.new, {})
	Hooks.useEffect(function() return function() scope:Destroy() end end, {})
	return scope
end
function Common.presence(open)
	local env = Hooks.useEnvironment()
	local present, setPresent = Hooks.useState(open)
	Hooks.useEffect(function()
		if open then setPresent(true); return end
		if env.animator.reducedMotion then setPresent(false); return end
		local scope = Scope.new()
		scope:Delay(env.theme:Get().motion.normal, function() setPresent(false) end)
		return function() scope:Destroy() end
	end, {open})
	return present or open
end
function Common.key(ref, callback, descendants)
	local env = Hooks.useEnvironment()
	local latest = Common.latest(callback)
	Hooks.useEffect(function()
		return env.input:OnKey(ref, function(...) return latest.current(...) end, descendants)
	end, {ref, descendants})
end
function Common.finite(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end
function Common.options(options)
	assert(type(options) == "table", "options must be an array")
	local count=0
	for key in options do assert(type(key)=="number" and key>=1 and key%1==0,"options must be a dense array"); count+=1 end
	assert(count==#options,"options must be a dense array")
	local result, seen = {}, {}
	for index, option in options do
		local item = if type(option) == "table" then table.clone(option) else {value=option,label=tostring(option)}
		assert(type(item.value) == "string" or Common.finite(item.value), "Option values must be strings or finite numbers")
		local key = type(item.value) .. ":" .. tostring(item.value)
		assert(not seen[key], "Duplicate option value: " .. tostring(item.value))
		seen[key] = true
		item.label, item.key, item.index = item.label or tostring(item.value), key, index
		result[index] = item
	end
	return result
end
function Common.label(options, value)
	for _, item in options do if item.value == value then return item.label end end
	return nil
end
return Common
