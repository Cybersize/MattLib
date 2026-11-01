--!nonstrict
local Element = { Fragment = table.freeze({}), Portal = table.freeze({}), Provider = table.freeze({}) }
local registry = {}
local function flatten(value, output)
	if value == nil or type(value) == "boolean" then return end
	assert(type(value) == "table", "Children must be elements or arrays; use Text for strings")
	if value._element then table.insert(output, value); return end
	local count=0
	for key in value do
		assert(type(key) == "number" and key >= 1 and key % 1 == 0, "Children must be dense arrays")
		count+=1
	end
	local n = #value
	assert(count==n,"Children must be dense arrays; use false for conditional children")
	for index = 1, n do
		assert(value[index] ~= nil, "Children cannot contain nil holes; use false")
		flatten(value[index], output)
	end
end
function Element.children(value)
	local output = {}
	flatten(value, output)
	return output
end
function Element.register(name, component)
	assert(not registry[name] and type(component) == "function", "Duplicate component " .. name)
	registry[name] = component
end
function Element.resolve(kind)
	if type(kind) == "string" and string.sub(kind, 1, 1) ~= "@" then
		assert(registry[kind], "Unknown MattLib component: " .. kind .. "; native classes use @Frame, @TextBox, etc.")
		return registry[kind]
	end
	return kind
end
function Element.h(kind, props, children)
	assert(type(kind) == "function" or type(kind) == "string" or kind == Element.Fragment
		or kind == Element.Portal or kind == Element.Provider, "Invalid element type")
	props = table.clone(props or {})
	assert(props.key == nil or type(props.key) == "string" or type(props.key) == "number", "Keys must be strings or numbers")
	props.children = Element.children(if children ~= nil then children else props.children)
	return { _element = true, type = kind, key = props.key, props = props }
end
function Element.list(items, render, keyOf)
	assert(type(keyOf) == "function", "UI.list requires a stable key function")
	local output = {}
	for index, item in items do
		local child = render(item, index)
		if child ~= nil and child ~= false then
			assert(child._element, "List render must return an element")
			local props = table.clone(child.props)
			props.key = keyOf(item, index)
			assert(props.key ~= nil, "List keys cannot be nil")
			table.insert(output, Element.h(child.type, props))
		end
	end
	return output
end
function Element.portal(children, target)
	return Element.h(Element.Portal, { target = target }, children)
end
return Element
