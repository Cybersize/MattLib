--!strict
local counts: {[string]: number} = {
	roots = 0, components = 0, instances = 0, connections = 0,
	subscriptions = 0, tweens = 0, windows = 0, renders = 0,
}
local Diagnostics = {}
function Diagnostics.add(name: string, delta: number)
	counts[name] = (counts[name] or 0) + delta
	assert(counts[name] >= 0, "MattLib: negative diagnostic counter " .. name)
end
function Diagnostics.snapshot(): {[string]: number}
	return table.clone(counts)
end
return Diagnostics
