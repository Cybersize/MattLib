--!nonstrict
local Scope=require(script.Parent.Parent.utils.Scope)
local Diagnostics=require(script.Parent.Parent.utils.Diagnostics)
local Signal=require(script.Parent.Parent.core.Signal)
local Input=require(script.Parent.Parent.runtime.Input)
local Manager={}
Manager.__index=Manager
local Entry={}
Entry.__index=Entry
function Manager.clamp(rect,viewport,minSize,maxSize)
	local margin=math.min(8,math.max(0,(math.min(viewport.X,viewport.Y)-1)/2))
	local availableW,availableH=math.max(1,viewport.X-margin*2),math.max(1,viewport.Y-margin*2)
	local minW,minH=math.min((minSize or {}).X or 280,availableW),math.min((minSize or {}).Y or 180,availableH)
	local maxW,maxH=math.max(minW,math.min((maxSize or {}).X or availableW,availableW)),math.max(minH,math.min((maxSize or {}).Y or availableH,availableH))
	local width,height=math.clamp(rect.width,minW,maxW),math.clamp(rect.height,minH,maxH)
	return {x=math.clamp(rect.x,margin,math.max(margin,viewport.X-width-margin)),y=math.clamp(rect.y,margin,math.max(margin,viewport.Y-height-margin)),width=width,height=height}
end
function Manager.new(runtime,input,overlays)
	local self=setmetatable({runtime=runtime,input=input,overlays=overlays,entries={},scope=Scope.new(),serial=0,hidden=Signal.new({})},Manager)
	self.scope:Add(runtime.viewport:subscribe(function() for _,entry in self.entries do entry:_apply() end end))
	return self
end
function Manager:_viewport()
	-- Signals can be delivered later under Roblox's deferred event mode.
	-- A gesture/explicit resize must use the current native safe-area dimensions.
	local actual=self.runtime.layers.main.AbsoluteSize
	if actual.X>0 and actual.Y>0 then return actual end
	local viewport=self.runtime.viewport:get()
	if viewport.X<1 or viewport.Y<1 then
		local camera=workspace.CurrentCamera
		return if camera then camera.ViewportSize else Vector2.new(800,600)
	end
	return viewport
end
function Manager:_publish()
	local hidden={}
	for _,entry in self.entries do if not entry.visible then table.insert(hidden,entry) end end
	table.sort(hidden,function(a,b) return a.order<b.order end)
	self.hidden:set(hidden)
end
function Entry:_apply()
	if not self.alive then return end
	local minSize=if self.minimized then Vector2.new(self.minSize.X,self.headerHeight) else self.minSize
	self.rect=Manager.clamp(self.rect,self.manager:_viewport(),minSize,self.maxSize)
	self.frame.Position=UDim2.fromOffset(self.rect.x,self.rect.y)
	self.frame.Size=UDim2.fromOffset(self.rect.width,self.rect.height)
end
function Entry:Focus()
	if not self.alive then return end
	self.manager.serial+=1
	self.frame.ZIndex=self.manager.serial
end
function Entry:Show()
	if not self.alive then return end
	self.visible=true; self.options.onVisible(true); self:Focus(); self.manager:_publish()
end
function Entry:Hide()
	if not self.alive then return end
	self.visible=false; self.options.onVisible(false); self.manager:_publish()
end
function Entry:Minimize()
	if not self.alive or self.minimized then return end
	self.savedHeight=self.rect.height; self.rect.height=self.headerHeight; self.minimized=true
	self.options.onMinimized(true); self:_apply()
end
function Entry:Restore()
	if not self.alive then return end
	if self.minimized then
		self.rect.height=self.savedHeight or self.options.size[2]; self.minimized=false
		self.options.onMinimized(false); self:_apply()
	end
	self:Show()
end
function Entry:SetSize(width,height)
	assert(type(width)=="number" and width>0 and width<math.huge and type(height)=="number" and height>0 and height<math.huge,"Window size must be finite and positive")
	if not self.alive then return end
	self.rect.width=width
	if self.minimized then self.savedHeight=height; self.rect.height=self.headerHeight else self.rect.height=height end
	self:_apply()
end
function Entry:SetTitleHeight(height)
	assert(type(height)=="number" and height>=30 and height<=100,"Invalid window title height")
	if not self.alive then return end
	self.headerHeight=height
	if self.minimized then self.rect.height=height; self:_apply() end
end
function Entry:GetRect() return table.clone(self.rect) end
function Entry:Close()
	if self.alive and not self.closing then self.closing=true; self.options.onClose() end
end
function Entry:Detach()
	if not self.alive then return end
	self.alive=false; self.scope:Destroy()
	if self.manager.entries[self.id]==self then self.manager.entries[self.id]=nil end
	Diagnostics.add("windows",-1); self.manager:_publish()
end
function Entry:Destroy()
	if not self.alive then return end
	self:Close(); self:Detach()
end
function Manager:Register(options)
	assert(type(options.id)=="string","Window id must be a string")
	if self.entries[options.id] then self.entries[options.id]:Destroy() end
	local viewport=self:_viewport()
	local size=options.size or {720,500}
	assert(type(size[1])=="number" and size[1]>0 and size[1]<math.huge and type(size[2])=="number" and size[2]>0 and size[2]<math.huge,"Invalid window size")
	local point=options.position or {(viewport.X-size[1])/2,(viewport.Y-size[2])/2}
	self.serial+=1
	local entry=setmetatable({manager=self,id=options.id,options=options,scope=Scope.new(),alive=true,frame=options.frame,
		visible=options.visible~=false,minimized=false,minSize=options.minSize or Vector2.new(280,180),maxSize=options.maxSize,
		order=self.serial,headerHeight=options.titleHeight or 44,rect={x=point[1],y=point[2],width=size[1],height=size[2]}},Entry)
	self.entries[entry.id]=entry; Diagnostics.add("windows",1)
	local cancelCapture
	entry.scope:Add(function() if cancelCapture then cancelCapture(); cancelCapture=nil end end)
	entry.scope:Connect(options.frame.InputBegan,function(input) if Input.isPointer(input) then entry:Focus() end end)
	entry.scope:Connect(options.titlebar.InputBegan,function(input)
		if not Input.isPointer(input) then return end
		for _,child in options.titlebar:GetDescendants() do if child:IsA("GuiButton") and Input.inside(child,input.Position) then return end end
		entry:Focus()
		local start,rect=input.Position,entry:GetRect()
		cancelCapture=self.input:Capture(input,function(pointNow)
			entry.rect.x,entry.rect.y=rect.x+pointNow.X-start.X,rect.y+pointNow.Y-start.Y; entry:_apply()
		end,function(cancelled) cancelCapture=nil; if not cancelled and options.onMove then options.onMove(entry:GetRect()) end end)
	end)
	if options.grip and not options.fixedSize then
		entry.scope:Connect(options.grip.InputBegan,function(input)
			if not Input.isPointer(input) or entry.minimized then return end
			entry:Focus()
			local start,rect=input.Position,entry:GetRect()
			cancelCapture=self.input:Capture(input,function(pointNow)
				entry.rect.width,entry.rect.height=rect.width+pointNow.X-start.X,rect.height+pointNow.Y-start.Y; entry:_apply()
			end,function(cancelled) cancelCapture=nil; if not cancelled and options.onResize then options.onResize(entry:GetRect()) end end)
		end)
		entry.scope:Add(self.input:OnKey({current=options.grip},function(key)
			local dx=if key==Enum.KeyCode.Right then 10 elseif key==Enum.KeyCode.Left then -10 else 0
			local dy=if key==Enum.KeyCode.Down then 10 elseif key==Enum.KeyCode.Up then -10 else 0
			if dx~=0 or dy~=0 then entry:SetSize(entry.rect.width+dx,entry.rect.height+dy); return true end
		end))
	end
	entry.scope:Add(self.input:OnKey({current=options.titlebar},function(key)
		local dx=if key==Enum.KeyCode.Right then 10 elseif key==Enum.KeyCode.Left then -10 else 0
		local dy=if key==Enum.KeyCode.Down then 10 elseif key==Enum.KeyCode.Up then -10 else 0
		if dx~=0 or dy~=0 then entry.rect.x+=dx; entry.rect.y+=dy; entry:_apply(); return true end
	end))
	if options.openKey~=false then
		local name=options.openKey or "RightShift"
		if typeof(name)=="EnumItem" then name=name.Name end
		assert(type(name)=="string","openKey must be a KeyCode name, EnumItem, or false")
		entry.scope:Add(self.input:Subscribe("began",function(input,processed)
			if not input or processed or #self.overlays.stack>0 or self.input.uis:GetFocusedTextBox() then return end
			if input.KeyCode.Name==name then if entry.visible then entry:Hide() else entry:Show() end end
		end))
	end
	entry:_apply(); entry:Focus(); self:_publish()
	return entry
end
function Manager:Destroy()
	for _,entry in table.clone(self.entries) do entry:Detach() end
	self.scope:Destroy(); self.hidden:Destroy()
end
return Manager
