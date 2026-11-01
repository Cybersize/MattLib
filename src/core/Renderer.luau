--!nonstrict
local Element = require(script.Parent.Element)
local Reconciler = require(script.Parent.Reconciler)
local Hooks = require(script.Parent.Hooks)
local Host = require(script.Parent.Host)
local Diagnostics = require(script.Parent.Parent.utils.Diagnostics)
local Renderer = {}
local Root = {}
Root.__index = Root
local function orderHosts(node, counters)
	if node.instance then
		local parent = node.instance.Parent
		counters[parent] = (counters[parent] or 0) + 1
		local explicit = (node.props.native or {}).LayoutOrder
		local order = explicit or counters[parent]
		if node.instance.LayoutOrder ~= order then node.instance.LayoutOrder = order end
	end
	for _, child in node.children do orderHosts(child, counters) end
end
function Root:report(err)
	if self.onError then
		local ok, nested = pcall(self.onError, tostring(err))
		if not ok then warn("MattLib onError: " .. tostring(nested)) end
	else warn("MattLib: " .. tostring(err)) end
end
function Root:_unmount(node)
	if not node or not node.alive then return end
	node.alive = false
	self.dirty[node] = nil
	if type(node.kind) == "function" then Hooks.cleanup(node); Diagnostics.add("components", -1) end
	for _, child in node.children do self:_unmount(child) end
	if node.instance then Host.destroy(node) end
	node.children = {}
end
function Root:_children(node, elements, parentHost, env)
	local plan, removed = Reconciler.plan(node.children, elements)
	local nextChildren = {}
	-- Keep in-progress children reachable if a later child fails to render.
	local retained = table.clone(node.children)
	node.children = retained
	for _, old in removed do self:_unmount(old); self.needsOrder=true end
	for index, match in plan do
		local child = self:_reconcile(match.previous, match.element, parentHost, node, env)
		nextChildren[index] = child
		if not match.previous then self.needsOrder=true end
		if retained[index] ~= child then self.needsOrder=true end
	end
	node.children = nextChildren
end
function Root:_render(node)
	node.epoch = self.epoch
	Diagnostics.add("renders", 1)
	local previous = Hooks.begin(node)
	local ok, result = pcall(node.kind, node.element.props)
	local finishOk, finishErr = pcall(Hooks.finish, node, previous, ok)
	if not ok then error(result, 0) end
	if not finishOk then error(finishErr, 0) end
	self:_children(node, Element.children(result), node.parentHost, node.env)
end
function Root:_reconcile(node, element, parentHost, owner, env)
	local kind = Element.resolve(element.type)
	if node and node.kind ~= kind then self:_unmount(node); node=nil; self.needsOrder=true end
	if not node then
		node = {kind=kind,element=element,root=self,owner=owner,env=env,parentHost=parentHost,children={},hooks={},alive=true,depth=owner.depth+1}
		-- Ownership is recorded before any user code or property assignment can fail.
		table.insert(owner.children, node)
		if type(kind) == "function" then Diagnostics.add("components", 1)
		elseif type(kind) == "string" then Host.create(node, string.sub(kind, 2)) end
	end
	node.element, node.owner, node.env, node.parentHost = element, owner, env, parentHost
	if type(kind) == "function" then self:_render(node)
	elseif kind == Element.Fragment then self:_children(node, element.props.children, parentHost, env)
	elseif kind == Element.Portal then
		assert(typeof(element.props.target) == "Instance", "Portal target must be an Instance")
		self:_children(node, element.props.children, element.props.target, env)
	elseif kind == Element.Provider then
		local nextEnv = table.clone(env)
		assert(element.props.service and element.props.service.signal, "Theme provider requires a Theme service")
		nextEnv.theme = element.props.service
		self:_children(node, element.props.children, parentHost, nextEnv)
	else
		Host.update(node, element.props, env)
		if node.instance.Parent ~= parentHost then node.instance.Parent=parentHost; self.needsOrder=true end
		self:_children(node, element.props.children, node.instance, env)
	end
	return node
end
function Root:enqueue(node)
	if not self.alive or not node.alive then return end
	self.dirty[node] = true
	self:_schedule()
end
function Root:_schedule()
	if self.scheduled or self.flushing or not self.alive then return end
	self.scheduled = true
	task.defer(function()
		if not self.alive or not self.scheduled then return end
		self.scheduled = false
		local ok, err = pcall(function() self:Flush() end)
		if not ok then self:report(err) end
	end)
end
function Root:_flush()
	local iterations = 0
	while self.pending or next(self.dirty) or next(self.effects) do
		iterations += 1
		assert(iterations <= 50, "MattLib: effects produced an infinite update loop")
		self.epoch += 1
		local dirty = self.dirty
		self.dirty = {}
		if self.pending then
			local pending = self.pending
			self.pending = nil
			self:_children(self.tree, Element.children(pending.element), self.parent, self.env)
		else
			local nodes = {}
			for node in dirty do table.insert(nodes, node) end
			table.sort(nodes, function(a,b) return a.depth < b.depth end)
			for _, node in nodes do if node.alive and node.epoch ~= self.epoch then self:_render(node) end end
		end
		if self.needsOrder then orderHosts(self.tree, {}); self.needsOrder=false end
		Hooks.commit(self)
	end
end
function Root:Flush()
	assert(self.alive, "Cannot flush an unmounted root")
	assert(not self.flushing, "Reentrant flush is unsupported")
	self.flushing, self.scheduled = true, false
	local ok, err = pcall(function() self:_flush() end)
	self.flushing = false
	if not ok then self:Unmount(); error(err, 0) end
	return self
end
function Root:Update(element)
	assert(self.alive, "Cannot update an unmounted root")
	self.pending = {element=element}
	self:_schedule()
	return self
end
function Root:Unmount()
	if not self.alive then return end
	self.alive, self.scheduled = false, false
	self:_unmount(self.tree)
	self.dirty, self.effects, self.pending = {}, {}, nil
	Diagnostics.add("roots", -1)
	if self.onUnmount then self.onUnmount(self) end
end
function Root:Find(name)
	local function find(node)
		if node.instance and node.instance.Name == name then return node.instance end
		for _, child in node.children do local result=find(child); if result then return result end end
	end
	return find(self.tree)
end
function Renderer.mount(element, parent, env, options)
	assert(typeof(parent) == "Instance", "Mount parent must be an Instance")
	options = options or {}
	local root = setmetatable({alive=true,parent=parent,env=env,onError=options.onError,onUnmount=options.onUnmount,
		dirty={},effects={},epoch=0,pending={element=element}}, Root)
	root.tree = {alive=true,children={},kind=Element.Fragment,depth=0,root=root}
	Diagnostics.add("roots", 1)
	root:Flush()
	return root
end
return Renderer
