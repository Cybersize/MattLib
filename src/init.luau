--!nonstrict
local Element=require(script.core.Element)
local Hooks=require(script.core.Hooks)
local Signal=require(script.core.Signal)
local Renderer=require(script.core.Renderer)
local Theme=require(script.styling.Theme)
local Style=require(script.styling.StyleResolver)
local Adapter=require(script.runtime.Adapter)
local Input=require(script.runtime.Input)
local Overlays=require(script.runtime.Overlays)
local Manager=require(script.window.Manager)
local Animator=require(script.animation.Animator)
local Config=require(script.config.Config)
local Notifications=require(script.feedback.Notifications)
local Scope=require(script.utils.Scope)
local Diagnostics=require(script.utils.Diagnostics)
local Primitives=require(script.components.primitives.Primitives)
local Sections=require(script.components.layout.Sections)
local OverlayComponents=require(script.components.layout.Overlays)
local Windows=require(script.components.layout.Window)
local Tabs=require(script.components.navigation.Tabs)
local Boolean=require(script.components.inputs.Boolean)
local TextInputs=require(script.components.inputs.TextInput)
local Sliders=require(script.components.inputs.Slider)
local Dropdowns=require(script.components.inputs.Dropdown)
local Selection=require(script.components.inputs.Selection)
local ColorPicker=require(script.components.inputs.ColorPicker)
local Keybind=require(script.components.inputs.Keybind)
local Feedback=require(script.components.feedback.Feedback)
local Facade=require(script.menu.Facade)
Primitives.register()
for _,group in {Sections,OverlayComponents,Windows,Tabs,Boolean,TextInputs,Dropdowns,Selection,ColorPicker,Keybind,Feedback} do
	for name,component in group do Element.register(name,component) end
end
Element.register("Slider",Sliders.Slider); Element.register("RangeSlider",Sliders.RangeSlider)
Element.register("CollapsibleSection",Sections.Collapsible)
local Library={}
Library.__index=Library
function Library.new(options)
	options=options or {}
	local self=setmetatable({Version="1.0.0",options=options,_roots={},_scope=Scope.new(),_destroyed=false},Library)
	self.Theme=Theme.new(options.theme or "Dark")
	self.Config=Config.new(game:GetService("HttpService"),Adapter.capabilities(options.capabilities),options.config)
	self.UI={h=Element.h,Fragment=Element.Fragment,portal=Element.portal,list=Element.list,signal=Signal.new,derived=Signal.derived,batch=Signal.batch,
		useState=Hooks.useState,useRef=Hooks.useRef,useMemo=Hooks.useMemo,useEffect=Hooks.useEffect,useSignal=Hooks.useSignal,useTheme=Hooks.useTheme,
		useEnvironment=Hooks.useEnvironment,mergeStyles=Style.merge,
		when=function(condition,yes,no) return if condition then yes else no end,
		mount=function(element,parent,opts) return self:Mount(element,parent,opts) end,
		flush=function(root) if root then return root:Flush() end; self:Flush() end}
	self.new=Library.new
	return self
end
function Library:_ensure()
	assert(not self._destroyed,"Library is destroyed; create another with Library.new()")
	if self._env then return self._env end
	local runtime=Adapter.new(self.options,function() self:Destroy() end)
	local input=Input.new(runtime.services.UserInputService,runtime.services.GuiService)
	local animator=Animator.new(runtime.services.TweenService,self.options.reducedMotion)
	local overlays=Overlays.new(input)
	local windows=Manager.new(runtime,input,overlays)
	local notifications=Notifications.new(self.Theme,animator)
	self._env={runtime=runtime,input=input,animator=animator,overlays=overlays,windows=windows,notifications=notifications,theme=self.Theme,library=self}
	self:Mount(Windows and Element.h(Windows.RecoveryHost),runtime.layers.main)
	self:Mount(Element.h(Feedback.ToastHost),runtime.layers.toast)
	return self._env
end
function Library:Mount(element,parent,options)
	local env=self:_ensure()
	options=options or {}
	local root=Renderer.mount(element,parent or env.runtime.layers.main,env,{onError=options.onError or self.options.onError,
		onUnmount=function(unmounted) self._roots[unmounted]=nil end})
	if self._destroyed then root:Unmount(); error("Library was destroyed during mounting",2) end
	if root.alive then self._roots[root]=true end
	return root
end
function Library:Flush()
	for root in table.clone(self._roots) do if root.alive then root:Flush() end end
end
function Library:CreateWindow(options) return Facade.create(self,options) end
function Library:SetTheme(theme) assert(not self._destroyed,"Library is destroyed"); self.Theme:Set(theme) end
function Library:SetReducedMotion(value) self:_ensure().animator:SetReducedMotion(value) end
function Library:Notify(options) return self:_ensure().notifications:Push(options) end
function Library:Confirm(options)
	self:_ensure(); options=table.clone(options or {})
	local original=options.onResult
	local root,finished
	local function finish(result)
		if finished then return end
		finished=true
		options.open=false
		if root and root.alive then root:Update(Element.h("ConfirmationDialog",options)) end
		self._scope:Delay(if self._env.animator.reducedMotion then 0 else self.Theme:Get().motion.normal,function() if root then root:Unmount() end end)
		if original then original(result) end
	end
	options.onResult=finish; options.open=true
	root=self:Mount(Element.h("ConfirmationDialog",options))
	return {Close=function() finish(false) end,Destroy=function() finished=true; root:Unmount() end,root=root}
end
function Library:GetDiagnostics() return Diagnostics.snapshot() end
function Library:GetRuntimeInfo()
	local capabilities={}
	for name in Adapter.capabilities(self.options.capabilities) do capabilities[name]=true end
	return {capabilities=capabilities,parentMode=self._env and self._env.runtime.parentMode or "uninitialized",version=self.Version}
end
function Library:Destroy()
	if self._destroyed then return end
	self._destroyed=true
	for root in table.clone(self._roots) do root:Unmount() end
	self._scope:Destroy()
	if self._env then
		self._env.notifications:Destroy(); self._env.windows:Destroy(); self._env.overlays:Destroy()
		self._env.input:Destroy(); self._env.animator:Destroy(); self._env.runtime:Destroy()
	end
	self.Config:Destroy(); self.Theme:Destroy()
end
return Library.new()
