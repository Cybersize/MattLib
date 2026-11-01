--!nonstrict
local Scope = require(script.Parent.Parent.utils.Scope)
local Input = require(script.Parent.Input)
local Overlays = {}
Overlays.__index = Overlays
function Overlays.new(input)
	return setmetatable({input=input,stack={},serial=0},Overlays)
end
function Overlays:Allows(instance)
	for index=#self.stack,1,-1 do
		local record=self.stack[index]
		if record.modal then return instance==record.root or (instance and instance:IsDescendantOf(record.root)) end
	end
	return true
end
function Overlays:NextZ() self.serial+=1; return self.serial end
local function targets(root)
	local output = {}
	for _, instance in root:GetDescendants() do
		if instance:IsA("GuiObject") and instance.Selectable and instance.Interactable and Input.visible(instance) then table.insert(output,instance) end
	end
	table.sort(output,function(a,b) return a.SelectionOrder < b.SelectionOrder end)
	return output
end
function Overlays:Attach(root, dismiss, modal, anchor, priority)
	local scope = Scope.new()
	local uis, gui = self.input.uis, self.input.guiService
	local record = {root=root,modal=modal,previous=gui.SelectedObject,focused=uis:GetFocusedTextBox(),priority=priority or 0}
	table.insert(self.stack,record)
	table.sort(self.stack,function(a,b) return a.priority<b.priority end)
	local function top() return self.stack[#self.stack] == record end
	local function selectTarget(target)
		if not target then return end
		gui.SelectedObject = target
		if target:IsA("TextBox") then target:CaptureFocus() end
	end
	if modal then
		local didFocus=false
		local function initialFocus()
			if didFocus or not top() then return end
			local first=targets(root)[1]
			if first then didFocus=true; selectTarget(first) end
		end
		initialFocus()
		scope:Delay(0,initialFocus)
		scope:Connect(root:GetPropertyChangedSignal("AbsoluteSize"),function() if not didFocus then scope:Delay(0,initialFocus) end end)
	end
	scope:Add(self.input:Subscribe("began",function(input)
		if not top() or not input then return end
		local key = input.KeyCode
		if key == Enum.KeyCode.Escape then if dismiss then dismiss() end; return true end
		if modal and key == Enum.KeyCode.Tab then
			local candidates=targets(root)
			if #candidates>0 then
				local selected=uis:GetFocusedTextBox() or gui.SelectedObject
				local index=table.find(candidates,selected) or 0
				local direction=if uis:IsKeyDown(Enum.KeyCode.LeftShift) or uis:IsKeyDown(Enum.KeyCode.RightShift) then -1 else 1
				local focused=uis:GetFocusedTextBox()
				if focused then focused:ReleaseFocus() end
				selectTarget(candidates[(index-1+direction)%#candidates+1])
			end
			return true
		end
		if not modal and Input.isPointer(input) and not Input.inside(root,input.Position)
			and not (anchor and Input.inside(anchor,input.Position)) then
			if dismiss then dismiss() end
		end
	end))
	if modal then
		scope:Connect(gui:GetPropertyChangedSignal("SelectedObject"),function()
			local selected=gui.SelectedObject
			if top() and selected and selected~=root and not selected:IsDescendantOf(root) then selectTarget(targets(root)[1]) end
		end)
	end
	return function()
		local wasTop=top()
		local index=table.find(self.stack,record)
		if index then table.remove(self.stack,index) end
		scope:Destroy()
		if wasTop then
			local focused=uis:GetFocusedTextBox()
			if focused and focused:IsDescendantOf(root) then focused:ReleaseFocus() end
			if record.previous and Input.visible(record.previous) then gui.SelectedObject=record.previous
			elseif gui.SelectedObject and gui.SelectedObject:IsDescendantOf(root) then gui.SelectedObject=nil end
			if record.focused and not record.focused:IsDescendantOf(root) and Input.visible(record.focused) then record.focused:CaptureFocus() end
		end
	end
end
function Overlays:Destroy() table.clear(self.stack) end
return Overlays
