--!nonstrict
-- Pure O(n) sibling matching. Key types are intentionally distinguished.
local Reconciler = {}
local function identity(element, index)
	if element.key == nil then return "index:" .. index end
	return type(element.key) .. ":" .. tostring(element.key)
end
function Reconciler.plan(previous, elements)
	local available, seen, plan = {}, {}, {}
	for index, node in previous do available[identity(node.element, index)] = node end
	for index, element in elements do
		local key = identity(element, index)
		assert(not seen[key], "Duplicate sibling key: " .. key)
		seen[key] = true
		plan[index] = { element = element, previous = available[key] }
		available[key] = nil
	end
	return plan, available
end
return Reconciler
