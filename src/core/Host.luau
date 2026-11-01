--!nonstrict
local Scope = require(script.Parent.Parent.utils.Scope)
local Diagnostics = require(script.Parent.Parent.utils.Diagnostics)
local Style = require(script.Parent.Parent.styling.StyleResolver)
local Input = require(script.Parent.Parent.runtime.Input)
local Host = {}
local classes = {Frame=true,CanvasGroup=true,TextLabel=true,TextButton=true,TextBox=true,ImageLabel=true,ImageButton=true,ScrollingFrame=true}
local tweenable = {BackgroundColor3=true,BackgroundTransparency=true,TextColor3=true,TextTransparency=true,
	ImageColor3=true,ImageTransparency=true,Position=true,Size=true,Rotation=true,GroupTransparency=true}
local function setRef(ref, value)
	if type(ref) == "function" then ref(value)
	elseif ref ~= nil then assert(type(ref) == "table", "ref must be a table or callback"); ref.current = value end
end
local function protected(node, callback, ...)
	local ok, err = pcall(callback, ...)
	if not ok then node.root:report(err) end
end
local function updateProperties(node, desired, animate)
	local instance, goals = node.instance, {}
	node.applying = true
	for property in node.assigned do
		if desired[property] == nil then
			node.env.animator:Cancel(instance, "style")
			instance[property] = node.original[property]
		end
	end
	for property, value in desired do
		assert(property ~= "Parent" and property ~= "ClassName", "Renderer owns " .. property)
		if node.original[property] == nil then node.original[property] = instance[property] end
		if node.assigned[property] ~= value or (property == "Text" and instance[property] ~= value) then
			if animate and tweenable[property] and node.assigned[property] ~= nil and node.assigned[property] ~= value then goals[property] = value
			elseif instance[property] ~= value then instance[property] = value end
		end
	end
	node.assigned, node.applying = desired, false
	if next(goals) then node.env.animator:To(instance, goals, node.env.theme:Get().motion.fast, {channel="style",merge=true}) end
end
function Host.refresh(node, animate)
	if not node.alive then return end
	local props, decorations = Style.resolve(node.props.style, node.env.theme:Get(), node.states, node.className)
	local desired = {BorderSizePixel=0, BackgroundTransparency=1}
	for key, value in node.props.native or {} do desired[key] = value end
	for key, value in props do desired[key] = value end
	desired.Name = node.props.name or node.className
	if node.instance:IsA("GuiButton") then
		desired.AutoButtonColor, desired.Active = false, not node.props.disabled
		desired.Selectable, desired.Interactable = not node.props.disabled, not node.props.disabled
	end
	if node.className == "TextBox" then desired.TextEditable = not node.props.disabled end
	updateProperties(node, desired, animate and node.props.motion ~= false)
	for key, instance in table.clone(node.decorations) do
		if not decorations[key] then
			node.env.animator:Forget(instance)
			instance:Destroy(); node.decorations[key] = nil; Diagnostics.add("instances", -1)
		end
	end
	for key, spec in decorations do
		local instance = node.decorations[key]
		if not instance then
			instance = Instance.new(spec.class)
			instance.Name = "Matt_" .. key
			node.decorations[key] = instance
			Diagnostics.add("instances", 1)
		end
		for property, value in spec do if property ~= "class" and instance[property] ~= value then instance[property] = value end end
		instance.Parent = node.instance
	end
end
local function state(node, name, value)
	if node.states[name] == value then return end
	node.states[name] = value
	Host.refresh(node, true)
end
local function syncBindings(node, category, definitions)
	local bindings = node[category]
	for name, binding in table.clone(bindings) do
		if not definitions[name] then binding.disconnect(); bindings[name] = nil end
	end
	for name, callback in definitions do
		assert(type(callback) == "function", category .. " callbacks must be functions")
		if bindings[name] then bindings[name].callback = callback
		else
			local signal = if category == "changes" then node.instance:GetPropertyChangedSignal(name) else node.instance[name]
			local binding = {callback=callback}
			binding.disconnect = node.scope:Connect(signal, function(...)
				if not node.alive or node.applying or node.props.disabled then return end
				protected(node, binding.callback, node.instance, ...)
			end)
			bindings[name] = binding
		end
	end
end
function Host.create(node, className)
	assert(classes[className], "Unsupported native host class: " .. className)
	node.instance, node.className, node.scope = Instance.new(className), className, Scope.new()
	node.decorations, node.assigned, node.original, node.events, node.changes, node.attributes = {}, {}, {}, {}, {}, {}
	node.states = {hover=false,pressed=false,focus=false,active=false,disabled=false}
	Diagnostics.add("instances", 1)
end
function Host.update(node, props, env)
	local oldRef = node.props and node.props.ref
	node.props, node.env = props, env
	node.states.disabled, node.states.active = props.disabled == true, props.active == true
	if node.theme ~= env.theme then
		if node.themeDisconnect then node.scope:Remove(node.themeDisconnect, true) end
		node.theme = env.theme
		node.themeDisconnect = node.scope:Add(env.theme.signal:subscribe(function() Host.refresh(node, false) end))
	end
	Host.refresh(node, node.mounted == true)
	syncBindings(node, "events", props.events or {})
	syncBindings(node, "changes", props.changes or {})
	local attributes = table.clone(props.attributes or {})
	attributes.AsterRole, attributes.AsterLabel, attributes.AsterValue = props.role, props.accessibleName, props.accessibleValue
	for name in node.attributes do if attributes[name] == nil then node.instance:SetAttribute(name, nil) end end
	for name, value in attributes do node.instance:SetAttribute(name, value) end
	node.attributes = attributes
	local wantsStates = props.style and (props.style.hover or props.style.pressed or props.style.focus)
	if wantsStates and not node.stateScope then
		node.stateScope = Scope.new()
		node.stateScope:Connect(node.instance.MouseEnter, function() state(node,"hover",true) end)
		node.stateScope:Connect(node.instance.MouseLeave, function() state(node,"hover",false); state(node,"pressed",false) end)
		node.stateScope:Connect(node.instance.SelectionGained, function() state(node,"focus",true) end)
		node.stateScope:Connect(node.instance.SelectionLost, function() state(node,"focus",false) end)
		if node.className == "TextBox" then
			node.stateScope:Connect(node.instance.Focused, function() state(node,"focus",true) end)
			node.stateScope:Connect(node.instance.FocusLost, function() state(node,"focus",false) end)
		end
		node.stateScope:Connect(node.instance.InputBegan, function(input)
			if not node.props.disabled and Input.isPointer(input) then state(node,"pressed",true) end
		end)
		node.stateScope:Add(env.input:Subscribe("ended", function() state(node,"pressed",false) end))
	elseif not wantsStates and node.stateScope then node.stateScope:Destroy(); node.stateScope=nil end
	if node.instance:IsA("GuiButton") and not node.keyboard then
		node.keyboard = node.scope:Add(env.input:OnKey({current=node.instance}, function(key)
			if not node.props.disabled and not env.input.uis:GetFocusedTextBox() and (key == Enum.KeyCode.Return or key == Enum.KeyCode.Space) then
				local binding = node.events.Activated
				if binding then protected(node, binding.callback, node.instance); return true end
			end
		end))
	end
	if oldRef ~= props.ref then setRef(oldRef, nil); setRef(props.ref, node.instance) end
	node.mounted = true
end
function Host.destroy(node)
	setRef(node.props and node.props.ref, nil)
	if node.stateScope then node.stateScope:Destroy() end
	node.scope:Destroy()
	node.env.animator:Forget(node.instance)
	for _, instance in node.decorations do node.env.animator:Forget(instance); instance:Destroy(); Diagnostics.add("instances", -1) end
	node.instance:Destroy()
	Diagnostics.add("instances", -1)
end
return Host
