--!nonstrict
local Scope = require(script.Parent.Parent.utils.Scope)
local Diagnostics = require(script.Parent.Parent.utils.Diagnostics)
local Input = {}
Input.__index = Input
function Input.isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end
function Input.visible(instance)
	local node = instance
	while node do
		if node:IsA("GuiObject") and (not node.Visible or node.AbsoluteSize.X <= 0 or node.AbsoluteSize.Y <= 0) then return false end
		if node:IsA("ScreenGui") and not node.Enabled then return false end
		node = node.Parent
	end
	return instance ~= nil and instance.Parent ~= nil
end
function Input.inside(instance, position)
	if not instance or not Input.visible(instance) then return false end
	local origin, size = instance.AbsolutePosition, instance.AbsoluteSize
	return position.X >= origin.X and position.X <= origin.X + size.X and position.Y >= origin.Y and position.Y <= origin.Y + size.Y
end
function Input.new(uis, guiService)
	local self = setmetatable({ uis = uis, guiService = guiService, scope = Scope.new(), listeners = {began={},ended={}}, serial=0 }, Input)
	self.scope:Connect(uis.InputBegan, function(input, processed) self:_dispatch("began", input, processed) end)
	self.scope:Connect(uis.InputChanged, function(input)
		local capture = self.capture
		if capture and ((capture.input.UserInputType == Enum.UserInputType.Touch and input == capture.input)
			or (capture.input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			capture.move(input.Position)
		end
	end)
	self.scope:Connect(uis.InputEnded, function(input, processed)
		local capture = self.capture
		if capture and (input == capture.input or (capture.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
			self.capture = nil
			capture.finish(false)
		end
		self:_dispatch("ended", input, processed)
	end)
	self.scope:Connect(uis.WindowFocusReleased, function()
		if self.capture then local old=self.capture; self.capture=nil; old.finish(true) end
		self:_dispatch("ended", nil, true)
	end)
	return self
end
function Input:_dispatch(kind, input, processed)
	local list = {}
	for token, listener in self.listeners[kind] do table.insert(list, {token=token, listener=listener}) end
	table.sort(list, function(a,b) return a.token > b.token end)
	for _, item in list do
		if self.listeners[kind][item.token] then
			local ok, consumed = pcall(item.listener, input, processed)
			if not ok then warn("MattLib input: " .. tostring(consumed)) elseif consumed then break end
		end
	end
end
function Input:Subscribe(kind, callback)
	assert(self.listeners[kind], "Invalid input subscription")
	self.serial += 1
	local token = self.serial
	self.listeners[kind][token] = callback
	Diagnostics.add("subscriptions",1)
	return function()
		if self.listeners[kind][token] then self.listeners[kind][token]=nil; Diagnostics.add("subscriptions",-1) end
	end
end
function Input:Capture(input, move, finish)
	if self.capture then local previous=self.capture; self.capture=nil; previous.finish(true) end
	local capture = { input=input, move=move, finish=finish or function() end }
	self.capture = capture
	return function() if self.capture == capture then self.capture=nil; capture.finish(true) end end
end
function Input:OnKey(ref, callback, descendants)
	return self:Subscribe("began", function(input, processed)
		local instance = ref.current
		if not input or input.UserInputType ~= Enum.UserInputType.Keyboard or not Input.visible(instance) then return end
		local selected, focused = self.guiService.SelectedObject, self.uis:GetFocusedTextBox()
		local target = focused or selected
		if target == instance or (descendants and target and target:IsDescendantOf(instance)) then
			return callback(input.KeyCode, input, processed)
		end
	end)
end
function Input:Destroy()
	if self.capture then local old=self.capture; self.capture=nil; old.finish(true) end
	self.scope:Destroy()
	for _,listeners in self.listeners do for _ in listeners do Diagnostics.add("subscriptions",-1) end end
	self.listeners = {began={},ended={}}
end
return Input
