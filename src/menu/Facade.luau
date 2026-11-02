--!nonstrict
local Element=require(script.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.core.Hooks)
local Signal=require(script.Parent.Parent.core.Signal)
local Scope=require(script.Parent.Parent.utils.Scope)
local Common=require(script.Parent.Parent.components.Common)
local Designs=require(script.Parent.Parent.styling.Designs)
local h=Element.h
local Facade={}
local Handle={}
Handle.__index=Handle
local Control={}
Control.__index=Control
local windowSerial,serial=0,0
local valueKinds={Toggle=true,Switch=true,Checkbox=true,Slider=true,RangeSlider=true,Dropdown=true,SearchableDropdown=true,MultiSelect=true,
	TextInput=true,NumericInput=true,ColorPicker=true,Keybind=true,RadioGroup=true,SegmentedControl=true,ProgressBar=true}
local function defaults(kind,options,library)
	if options.Value~=nil then return options.Value end
	if options.Default~=nil then return options.Default end
	if kind=="Toggle" or kind=="Switch" or kind=="Checkbox" then return false end
	if kind=="Slider" then return options.Min or 0 end
	if kind=="NumericInput" then return options.Min or 0 end
	if kind=="ProgressBar" then return 0 end
	if kind=="RangeSlider" then return {options.Min or 0,options.Max or 100} end
	if kind=="MultiSelect" then return {} end
	if kind=="ColorPicker" then return library.Theme:Get().accent end
	if kind=="Keybind" then return "None" end
	if kind=="RadioGroup" or kind=="SegmentedControl" then local optionsList=Common.options(options.Options or {}); return optionsList[1] and optionsList[1].value or "" end
	return ""
end
local function validate(kind,value,options)
	if kind=="Toggle" or kind=="Switch" or kind=="Checkbox" then return type(value)=="boolean","Expected boolean" end
	if kind=="Slider" then return Common.finite(value) and value>=(options.Min or 0) and value<=(options.Max or 100),"Number is outside the slider range" end
	if kind=="ProgressBar" then return Common.finite(value) and value>=0 and value<=1,"Progress must be 0..1" end
	if kind=="NumericInput" then
		return Common.finite(value) and value>=(options.Min or -math.huge) and value<=(options.Max or math.huge),"Number is outside the configured range"
	end
	if kind=="RangeSlider" then
		return type(value)=="table" and #value==2 and Common.finite(value[1]) and Common.finite(value[2]) and value[1]<=value[2]
			and value[1]>=(options.Min or 0) and value[2]<=(options.Max or 100),"Expected ordered {low, high} in range"
	end
	if kind=="ColorPicker" then return typeof(value)=="Color3","Expected Color3" end
	if kind=="MultiSelect" then
		if type(value)~="table" then return false,"Expected an array of options" end
		local seen={}
		for _,entry in value do
			if seen[entry] or not Common.label(Common.options(options.Options or {}),entry) then return false,"Unknown or duplicate selected option" end
			seen[entry]=true
		end
		return true
	end
	if kind=="Dropdown" or kind=="SearchableDropdown" or kind=="RadioGroup" or kind=="SegmentedControl" then
		return value=="" or Common.label(Common.options(options.Options or {}),value)~=nil,"Unknown selected option"
	end
	if kind=="Keybind" then
		if value=="None" then return true end
		local ok,item=pcall(function() return Enum.KeyCode[value] end)
		return ok and item~=nil,"Unknown KeyCode"
	end
	return type(value)=="string","Expected string"
end
local function propsFor(record)
	local o=record.options
	local p={name=record.name,label=o.Title,text=o.Text or o.Title,description=o.Description,style=o.Style,disabled=o.Disabled,accessibleName=o.AccessibleName,
		min=o.Min,max=o.Max,step=o.Step,options=o.Options,placeholder=o.Placeholder,searchable=o.Searchable,multiple=o.Multiple,
		multiline=o.Multiline,maxLength=o.MaxLength,variant=o.Variant,format=o.Format,onCommit=o.OnCommit,onTrigger=o.Triggered,
		symbol=o.Symbol,glyph=o.Glyph,image=o.Image,size=o.Size,status=o.Status,message=o.Message,content=o.Content}
	if record.kind=="Button" then p.onClick=o.Callback end
	if record.kind=="Paragraph" then p.text=o.Content or o.Text or o.Title end
	return p
end
local function ControlView(p)
	local record=p.record
	Hooks.useSignal(record.revision)
	local props=propsFor(record)
	if record.signal then
		props.value=Hooks.useSignal(record.signal)
		props.onChange=function(value) record:SetValue(value) end
	end
	return h(record.kind,props)
end
local function ContainerView(p)
	local record=p.record
	Hooks.useSignal(record.revision)
	local children=Element.list(record.children,function(child)
		return h(if child.container then ContainerView else ControlView,{record=child})
	end,function(child) return child.id end)
	return h(if record.kind=="Section" then "Section" elseif record.kind=="Collapsible" then "Collapsible" elseif record.options.Columns then "AdaptiveGrid" else "Column",
		{title=record.options.Title,description=record.options.Description,defaultOpen=record.options.DefaultOpen,style=record.options.Style,revealOrder=p.order or 0,
			columns=record.options.Columns,minColumnWidth=record.options.MinColumnWidth,gap=record.options.Gap},children)
end
local function WindowView(p)
	local window=p.window
	Hooks.useSignal(window.revision)
	local items={}
	for _,tab in window.children do
		table.insert(items,{id=tab.id,title=tab.options.Title or "Tab",icon=tab.options.Icon,content=h(ContainerView,{record=tab})})
	end
	local o=window.options
	return h("Window",{id=window.id,name=window.name,title=o.Title or "Application",size=o.Size or {720,500},position=o.Position,
		minSize=o.MinSize,maxSize=o.MaxSize,fixedSize=o.FixedSize,openKey=o.OpenKey,theme=o.Theme,design=o.Design,wallpaper=o.Wallpaper,windowRef=window.windowRef,
		onClose=function()
			window.scope:Delay(if window.library._env.animator.reducedMotion then 0 else window.library.Theme:Get().motion.normal,function() window:Destroy() end)
			if o.OnClose then o.OnClose() end
		end}, {
		h("Tabs",{items=items,orientation=if o.Navigation=="Top" then "top" elseif o.Navigation=="Sidebar" then "sidebar" else "design",defaultValue=items[1] and items[1].id}),
	})
end
local function bump(record) if record.alive then record.revision:update(function(n) return n+1 end) end end
local function newContainer(parent,kind,options)
	assert(parent.alive,"Container is destroyed")
	serial+=1
	local record=setmetatable({id=kind..":"..serial,kind=kind,container=true,alive=true,options=table.clone(options or {}),children={},parent=parent,
		library=parent.library,window=parent.window or parent,scope=Scope.new(),revision=Signal.new(0)},Handle)
	table.insert(parent.children,record); bump(parent)
	return record
end
function Handle:AddTab(options)
	assert(self.kind=="Window","AddTab belongs to a window")
	return newContainer(self,"Tab",options)
end
function Handle:AddSection(options) return newContainer(self,"Section",options) end
function Handle:AddCollapsible(options) return newContainer(self,"Collapsible",options) end
function Handle:Update(patch)
	assert(self.alive,"Handle is destroyed")
	for key,value in patch do self.options[key]=value end
	bump(self)
end
function Control:SetValue(value)
	assert(self.alive and self.signal,"Control has no mutable value")
	local ok,reason=validate(self.kind,value,self.options); assert(ok,reason)
	self.signal:set(value)
end
function Control:GetValue() assert(self.signal,"Control has no value"); return self.signal:get() end
function Control:OnChanged(callback)
	assert(self.alive and self.signal,"Control has no value")
	local disconnect=self.signal:subscribe(callback)
	self.scope:Add(disconnect)
	return function() self.scope:Remove(disconnect,true) end
end
function Control:Update(patch)
	assert(self.alive,"Control is destroyed")
	assert(patch.Id==nil and patch.Default==nil and patch.Value==nil,"Use SetValue for values; Id and Default are immutable")
	local nextOptions=table.clone(self.options)
	for key,value in patch do nextOptions[key]=value end
	if self.signal then local ok,reason=validate(self.kind,self.signal:get(),nextOptions); assert(ok,reason) end
	self.options=nextOptions; bump(self)
end
function Control:GetInstance() return self.window.root and self.window.root:Find(self.name) end
local function destroy(record)
	if not record.alive then return end
	record.alive=false
	if record.disposeLibrary then record.library._scope:Remove(record.disposeLibrary,false); record.disposeLibrary=nil end
	if record.root then record.root:Unmount() end
	if record.children then for _,child in table.clone(record.children) do destroy(child) end; table.clear(record.children) end
	record.scope:Destroy()
	if record.signal then record.signal:Destroy() end
	record.revision:Destroy()
	if record.parent and record.parent.alive then
		local index=table.find(record.parent.children,record)
		if index then table.remove(record.parent.children,index); bump(record.parent) end
	end
end
function Handle:Destroy() destroy(self) end
Control.Destroy=Handle.Destroy
for _,method in {"Show","Hide","Minimize","Restore","Focus"} do
	Handle[method]=function(self)
		assert(self.kind=="Window" and self.alive,"Window handle is destroyed")
		local entry=self.windowRef.current
		if entry then entry[method](entry) end
	end
end
function Handle:SetSize(width,height)
	assert(self.kind=="Window" and self.alive,"Window handle is destroyed")
	if self.windowRef.current then self.windowRef.current:SetSize(width,height) end
end
function Handle:SetTheme(theme) self:Update({Theme=theme}) end
function Handle:SetDesign(design) Designs.get(design); self:Update({Design=design}); return self end
function Handle:GetDesign() return self.options.Design or self.library:GetDesign() end
function Handle:GetInstance() return self.root and self.root:Find(self.name) end
function Handle:GetRect() return self.windowRef.current and self.windowRef.current:GetRect() end
local function addControl(parent,kind,options)
	assert(parent.alive and parent.kind~="Window","Add controls to a tab or section")
	options=options or {}; serial+=1
	local record=setmetatable({id="control:"..serial,kind=kind,alive=true,options=table.clone(options),parent=parent,window=parent.window,
		library=parent.library,scope=Scope.new(),revision=Signal.new(0),name=options.Name or kind..":"..serial},Control)
	if valueKinds[kind] then
		local value=defaults(kind,options,parent.library)
		local ok,reason=validate(kind,value,options); assert(ok,reason)
		record.signal=Signal.new(value)
		if options.Id then
			record.ConfigId=parent.window.id.."/"..options.Id
			record.scope:Add(parent.library.Config:Register(record.ConfigId,record.signal,value,function(nextValue) return validate(kind,nextValue,record.options) end))
		end
		record.scope:Add(record.signal:subscribe(function(nextValue)
			if record.options.Callback then record.options.Callback(nextValue) end
		end))
	end
	table.insert(parent.children,record); bump(parent)
	return record
end
for _,kind in {"Button","Toggle","Switch","Checkbox","Slider","RangeSlider","Dropdown","SearchableDropdown","MultiSelect","TextInput","NumericInput",
	"ColorPicker","Keybind","RadioGroup","SegmentedControl","Text","Label","RichText","Paragraph","Icon","Badge","Separator","ProgressBar","LoadingIndicator","StatusIndicator"} do
	Handle["Add"..kind]=function(self,options) return addControl(self,kind,options) end
end
function Facade.create(library,options)
	library:_ensure()
	options=options or {}; windowSerial+=1
	local id=options.Id or "menu-"..windowSerial
	assert(type(id)=="string","Window Id must be a string")
	local window=setmetatable({id=id,name="MenuWindow:"..id,kind="Window",alive=true,library=library,options=table.clone(options),children={},
		revision=Signal.new(0),scope=Scope.new(),windowRef={},Config=library.Config},Handle)
	window.window=window
	window.root=library:Mount(h(WindowView,{window=window}))
	window.disposeLibrary=library._scope:Add(function() window:Destroy() end)
	return window
end
return Facade
