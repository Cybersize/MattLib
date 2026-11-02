--!nonstrict
-- Deliberately limited engine test double. This is NOT a Roblox rendering emulator.
local Mock={time=0,queue={},serial=0,instances={},warnings={},viewport=nil}
local function valueType(kind,fields)
	local mt={__type=kind}
	mt.__eq=function(a,b) for _,field in fields do if a[field]~=b[field] then return false end end; return true end
	return mt
end
local vecMT=valueType("Vector2",{"X","Y"})
vecMT.__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y},vecMT) end
vecMT.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y},vecMT) end
local Vector2={new=function(x,y) return setmetatable({X=x or 0,Y=y or 0},vecMT) end}
local colorMT=valueType("Color3",{"R","G","B"})
local Color3={new=function(r,g,b) return setmetatable({R=r or 0,G=g or 0,B=b or 0},colorMT) end}
Color3.fromRGB=function(r,g,b) return Color3.new(r/255,g/255,b/255) end
local colorSequenceMT=valueType("ColorSequence",{"From","To"})
local ColorSequence={new=function(from,to) return setmetatable({From=from,To=to or from,Keypoints={{Time=0,Value=from},{Time=1,Value=to or from}}},colorSequenceMT) end}
local numberSequenceMT=valueType("NumberSequence",{"From","To"})
local NumberSequence={new=function(from,to) return setmetatable({From=from,To=to or from,Keypoints={{Time=0,Value=from},{Time=1,Value=to or from}}},numberSequenceMT) end}
local dimMT=valueType("UDim",{"Scale","Offset"})
local UDim={new=function(scale,offset) return setmetatable({Scale=scale or 0,Offset=offset or 0},dimMT) end}
local dim2MT=valueType("UDim2",{"X","Y"})
local UDim2={new=function(xs,xo,ys,yo) return setmetatable({X=UDim.new(xs,xo),Y=UDim.new(ys,yo)},dim2MT) end}
UDim2.fromScale=function(x,y) return UDim2.new(x,0,y,0) end
UDim2.fromOffset=function(x,y) return UDim2.new(0,x,0,y) end
Mock.viewport=Vector2.new(1024,768)
local Enum={}
local enumNames={
	Font={"BuilderSans","BuilderSansMedium","BuilderSansBold","Code"},AutomaticSize={"None","X","Y","XY"},
	FillDirection={"Horizontal","Vertical"},SortOrder={"LayoutOrder","Name","Custom"},HorizontalAlignment={"Left","Center","Right"},
	VerticalAlignment={"Top","Center","Bottom"},TextXAlignment={"Left","Center","Right"},TextYAlignment={"Top","Center","Bottom"},
	UIFlexAlignment={"None","Fill","SpaceBetween","SpaceAround","SpaceEvenly"},UIFlexMode={"None","Grow","Shrink","Fill","Custom"},
	ApplyStrokeMode={"Border","Contextual"},ScaleType={"Fit","Stretch","Crop"},ResamplerMode={"Default","Pixelated"},ScrollingDirection={"X","Y","XY"},
	ElasticBehavior={"WhenScrollable","Never","Always"},UserInputType={"Keyboard","MouseButton1","MouseButton2","MouseMovement","Touch","Gamepad1"},
	UserInputState={"Begin","Change","End","Cancel"},PlaybackState={"Completed","Cancelled","Playing"},EasingStyle={"Quad","Linear","Sine"},EasingDirection={"Out","In","InOut"},
	ZIndexBehavior={"Sibling","Global"},ScreenInsets={"CoreUISafeInsets","DeviceSafeInsets","None"},TextTruncate={"None","AtEnd","SplitWord"},
	KeyCode={"Unknown","Return","Space","Up","Down","Left","Right","Home","End","Escape","Tab","LeftShift","RightShift","LeftControl","RightControl","Backspace","Delete","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"},
}
for name,items in enumNames do
	local group={Name=name}
	for index,item in items do group[item]=setmetatable({Name=item,Value=index-1,EnumType=group},{__type="EnumItem",__tostring=function(v) return "Enum."..name.."."..v.Name end}) end
	Enum[name]=setmetatable(group,{__index=function(_,key) error("Invalid Enum."..name.."."..tostring(key),2) end})
end
local function typeof(value)
	local mt=if type(value)=="table" then getmetatable(value) else nil
	return if type(mt)=="table" and mt.__type then mt.__type else type(value)
end
local task={}
function task.delay(seconds,callback)
	Mock.serial+=1
	local item={at=Mock.time+seconds,callback=callback,serial=Mock.serial,cancelled=false}
	table.insert(Mock.queue,item)
	return item
end
function task.defer(callback) return task.delay(0,callback) end
task.spawn=task.defer
function task.cancel(item) item.cancelled=true end
local Signal={}
Signal.__index=Signal
function Signal.new() return setmetatable({listeners={}},Signal) end
function Signal:Connect(callback)
	local connection={Connected=true}
	self.listeners[connection]=callback
	function connection:Disconnect() self.Connected=false end
	return connection
end
function Signal:Fire(...)
	for connection,callback in table.clone(self.listeners) do if connection.Connected then callback(...) end end
end
function Signal:DisconnectAll() for connection in self.listeners do connection:Disconnect() end end
local common={Name="Instance",Parent=false,Archivable=true}
local gui={Size=UDim2.fromOffset(100,100),Position=UDim2.new(),AnchorPoint=Vector2.new(),AbsoluteSize=Vector2.new(),AbsolutePosition=Vector2.new(),
	BackgroundTransparency=0,BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=1,BorderColor3=Color3.new(),Visible=true,Active=false,Interactable=true,
	Selectable=false,SelectionOrder=0,LayoutOrder=0,ZIndex=1,ClipsDescendants=false,Rotation=0,AutomaticSize=Enum.AutomaticSize.None}
local text={Text="",TextColor3=Color3.new(),TextTransparency=0,TextSize=14,Font=Enum.Font.BuilderSans,TextWrapped=false,RichText=false,
	TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.None}
local classProps={Frame={},CanvasGroup={GroupTransparency=0,GroupColor3=Color3.new(1,1,1)},
	TextLabel={},TextButton={AutoButtonColor=true,Modal=false},TextBox={ClearTextOnFocus=true,MultiLine=false,PlaceholderText="",PlaceholderColor3=Color3.new(),TextEditable=true,CursorPosition=1},
	ImageLabel={Image="",ImageColor3=Color3.new(1,1,1),ImageTransparency=0,ImageRectOffset=Vector2.new(),ImageRectSize=Vector2.new(),ScaleType=Enum.ScaleType.Stretch,ResampleMode=Enum.ResamplerMode.Default},ImageButton={Image="",ImageColor3=Color3.new(1,1,1),ImageTransparency=0,ImageRectOffset=Vector2.new(),ImageRectSize=Vector2.new(),ScaleType=Enum.ScaleType.Stretch,ResampleMode=Enum.ResamplerMode.Default,AutoButtonColor=true,Modal=false},
	ScrollingFrame={CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollBarThickness=12,ScrollBarImageColor3=Color3.new(),ScrollingDirection=Enum.ScrollingDirection.XY,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,CanvasPosition=Vector2.new()},
	ScreenGui={ResetOnSpawn=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=0,IgnoreGuiInset=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ClipToDeviceSafeArea=true,Enabled=true},
	UIListLayout={FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.Name,Padding=UDim.new(),HorizontalAlignment=Enum.HorizontalAlignment.Left,VerticalAlignment=Enum.VerticalAlignment.Top,
		HorizontalFlex=Enum.UIFlexAlignment.None,VerticalFlex=Enum.UIFlexAlignment.None,Wraps=false,AbsoluteContentSize=Vector2.new()},
	UIPadding={PaddingTop=UDim.new(),PaddingBottom=UDim.new(),PaddingLeft=UDim.new(),PaddingRight=UDim.new()},
	UICorner={CornerRadius=UDim.new(0,8)},UIStroke={Thickness=1,Color=Color3.new(),Transparency=0,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual},
	UIScale={Scale=1},UIGradient={Color=ColorSequence.new(Color3.new(1,1,1)),Transparency=NumberSequence.new(0),Rotation=0,Offset=Vector2.new()},
	UISizeConstraint={MinSize=Vector2.new(),MaxSize=Vector2.new(100000,100000)},UIFlexItem={FlexMode=Enum.UIFlexMode.None,GrowRatio=0,ShrinkRatio=0},
	BindableFunction={OnInvoke=false},PlayerGui={},Player={},Folder={},UserInputService={},GuiService={SelectedObject=false},TweenService={},HttpService={},RunService={},Players={LocalPlayer=false},
}
local guiClasses={Frame=true,CanvasGroup=true,TextLabel=true,TextButton=true,TextBox=true,ImageLabel=true,ImageButton=true,ScrollingFrame=true}
local textClasses={TextLabel=true,TextButton=true,TextBox=true}
local eventNames={Destroying=true,InputBegan=true,InputChanged=true,InputEnded=true,MouseEnter=true,MouseLeave=true,SelectionGained=true,SelectionLost=true,
	Activated=true,Focused=true,FocusLost=true,TouchLongPress=true,WindowFocusReleased=true,Heartbeat=true}
local Methods={}
local Instance={}
local instanceMT={__type="Instance"}
instanceMT.__index=function(self,key)
	if Methods[key] then return Methods[key] end
	if key=="ClassName" then return self._class end
	if eventNames[key] then if not self._events[key] then self._events[key]=Signal.new() end; return self._events[key] end
	if self._allowed[key] then local result=self._props[key]; return if result==false and (key=="Parent" or key=="SelectedObject" or key=="LocalPlayer") then nil else result end
	error("Unknown "..self._class.." property "..tostring(key),2)
end
local function changed(self,key,old,new)
	if self._changed[key] then self._changed[key]:Fire() end
	if key=="SelectedObject" then
		if old and typeof(old)=="Instance" and not old._destroyed then old.SelectionLost:Fire() end
		if new then new.SelectionGained:Fire() end
	end
end
instanceMT.__newindex=function(self,key,value)
	assert(self._allowed[key],"Unknown "..self._class.." property "..tostring(key))
	local old=self._props[key]
	if old==value then return end
	if key=="Parent" then
		if old and old~=false then local index=table.find(old._children,self); if index then table.remove(old._children,index) end end
		if value then assert(not value._destroyed,"Parent is destroyed"); table.insert(value._children,self) end
	end
	self._props[key]=value
	self._sets[key]=(self._sets[key] or 0)+1
	changed(self,key,old,value)
end
function Instance.new(class)
	assert(classProps[class],"Unknown mock class: "..class)
	local defaults=table.clone(common)
	if guiClasses[class] then for k,v in gui do defaults[k]=v end end
	if textClasses[class] then for k,v in text do defaults[k]=v end end
	for k,v in classProps[class] do defaults[k]=v end
	local allowed={}; for k in defaults do allowed[k]=true end
	local self=setmetatable({_class=class,_props=defaults,_allowed=allowed,_children={},_events={},_changed={},_attributes={},_sets={},_destroyed=false},instanceMT)
	self.Name=class; table.insert(Mock.instances,self)
	return self
end
function Methods:IsA(class) return self._class==class or class=="Instance" or (class=="GuiObject" and guiClasses[self._class]) or (class=="GuiButton" and (self._class=="TextButton" or self._class=="ImageButton")) end
function Methods:GetChildren() return table.clone(self._children) end
function Methods:GetDescendants()
	local result={}
	local function visit(parent) for _,child in parent._children do table.insert(result,child); visit(child) end end
	visit(self); return result
end
function Methods:IsDescendantOf(parent) local node=self.Parent; while node do if node==parent then return true end; node=node.Parent end; return false end
function Methods:FindFirstChild(name,recursive)
	for _,child in self._children do if child.Name==name then return child end end
	if recursive then for _,child in self._children do local found=child:FindFirstChild(name,true); if found then return found end end end
end
function Methods:FindFirstChildOfClass(class) for _,child in self._children do if child:IsA(class) then return child end end end
function Methods:WaitForChild(name) return assert(self:FindFirstChild(name),"Mock cannot yield for missing child "..name) end
function Methods:GetPropertyChangedSignal(key)
	assert(self._allowed[key],"Unknown property signal "..key)
	if not self._changed[key] then self._changed[key]=Signal.new() end
	return self._changed[key]
end
function Methods:SetAttribute(key,value) self._attributes[key]=value end
function Methods:GetAttribute(key) return self._attributes[key] end
function Methods:GetFullName() return self.Name end
function Methods:Destroy()
	if self._destroyed then return end
	rawset(self,"_destroyed",true)
	self.Destroying:Fire()
	for _,child in table.clone(self._children) do child:Destroy() end
	self.Parent=nil
	for _,signal in self._events do signal:DisconnectAll() end
	for _,signal in self._changed do signal:DisconnectAll() end
end
function Methods:Invoke(...) return self.OnInvoke(...) end
local services={}
function Methods:GetService(name) return assert(services[name],"Mock missing service "..name) end
function Methods:GetFocusedTextBox() return Mock.focused end
function Methods:IsKeyDown(key) return (Mock.keys or {})[key]==true end
function Methods:CaptureFocus()
	if Mock.focused and Mock.focused~=self then Mock.focused:ReleaseFocus() end
	Mock.focused=self; self.Focused:Fire()
end
function Methods:ReleaseFocus(enter)
	if Mock.focused==self then Mock.focused=nil; self.FocusLost:Fire(enter or false) end
end
function Methods:IsFocused() return Mock.focused==self end

-- JSON round trips use actual JSON text (including escaping), never a table-id cache.
local function encode(value)
	local kind=type(value)
	if value==nil then return "null" elseif kind=="boolean" or kind=="number" then return tostring(value)
	elseif kind=="string" then
		return '"'..string.gsub(value,'[%z\1-\31\\"]',function(c) return if c=='"' then '\\"' elseif c=='\\' then '\\\\' else string.format('\\u%04x',string.byte(c)) end)..'"'
	end
	assert(kind=="table","JSON cannot encode "..kind)
	local output={}
	if #value>0 then for i=1,#value do output[i]=encode(value[i]) end; return "["..table.concat(output,",").."]" end
	local keys={}; for key in value do table.insert(keys,key) end; table.sort(keys)
	for _,key in keys do table.insert(output,encode(tostring(key))..":"..encode(value[key])) end
	return "{"..table.concat(output,",").."}"
end
local function decode(text)
	local index=1
	local function whitespace() while string.match(string.sub(text,index,index),"%s") do index+=1 end end
	local parse
	local function str()
		index+=1; local output={}
		while index<=#text do
			local char=string.sub(text,index,index); index+=1
			if char=='"' then return table.concat(output) end
			if char=='\\' then
				local escape=string.sub(text,index,index); index+=1
				if escape=="u" then local code=tonumber(string.sub(text,index,index+3),16); assert(code,"Invalid unicode escape"); index+=4; char=utf8.char(code)
				else char=assert(({['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'})[escape],"Invalid escape") end
			end
			table.insert(output,char)
		end
		error("Unterminated JSON string")
	end
	parse=function()
		whitespace(); local char=string.sub(text,index,index)
		if char=='"' then return str() end
		if char=='{' or char=='[' then
			index+=1; whitespace(); local result={}; local array=char=='['; local close=if array then ']' else '}'
			if string.sub(text,index,index)==close then index+=1; return result end
			while true do
				whitespace(); local key=if array then #result+1 else str()
				if not array then whitespace(); assert(string.sub(text,index,index)==':',"Missing colon"); index+=1 end
				result[key]=parse(); whitespace(); local nextChar=string.sub(text,index,index); index+=1
				if nextChar==close then break end
				assert(nextChar==',',"Missing comma")
			end
			return result
		end
		for literal,value in {['true']=true,['false']=false} do if string.sub(text,index,index+#literal-1)==literal then index+=#literal; return value end end
		if string.sub(text,index,index+3)=='null' then index+=4; return nil end
		local number=string.match(string.sub(text,index),'^-?%d+%.?%d*[eE]?[+-]?%d*')
		assert(number and tonumber(number),"Invalid JSON at "..index); index+=#number; return tonumber(number)
	end
	local result=parse(); whitespace(); assert(index>#text,"Trailing JSON"); return result
end
function Methods:JSONEncode(value) return encode(value) end
function Methods:JSONDecode(value) return decode(value) end
local TweenInfo={new=function(duration,easing,direction,repeatCount,reverses) return {Time=duration,RepeatCount=repeatCount,Reverses=reverses} end}
function Methods:Create(instance,info,goals)
	local tween={Completed=Signal.new(),cancelled=false}
	function tween:Play()
		if info.RepeatCount==-1 then return end
		self.thread=task.delay(info.Time,function()
			if self.cancelled then return end
			for property,value in goals do instance[property]=value end
			self.Completed:Fire(Enum.PlaybackState.Completed)
		end)
	end
	function tween:Cancel()
		if self.cancelled then return end
		self.cancelled=true; if self.thread then task.cancel(self.thread) end
		self.Completed:Fire(Enum.PlaybackState.Cancelled)
	end
	return tween
end
for _,name in {"Players","UserInputService","GuiService","TweenService","HttpService","RunService"} do services[name]=Instance.new(name) end
local game={GetService=Methods.GetService}
local player=Instance.new("Player")
local playerGui=Instance.new("PlayerGui"); playerGui.Parent=player
services.Players.LocalPlayer=player
local function computed(instance,key,value)
	local old=instance._props[key]
	if old~=value then instance._props[key]=value; changed(instance,key,old,value); return true end
	return false
end
function Mock.layout()
	local any=false
	local function visit(instance,parentSize,parentPosition)
		if instance._destroyed then return end
		local size,position=parentSize,parentPosition
		if guiClasses[instance.ClassName] then
			local dimension=instance.Size
			local width,height=parentSize.X*dimension.X.Scale+dimension.X.Offset,parentSize.Y*dimension.Y.Scale+dimension.Y.Offset
			if instance.AutomaticSize==Enum.AutomaticSize.Y or instance.AutomaticSize==Enum.AutomaticSize.XY then
				height=if textClasses[instance.ClassName] then math.max(instance.TextSize+6,18) else math.max(24,instance.AbsoluteSize.Y)
			end
			if instance.AutomaticSize==Enum.AutomaticSize.X or instance.AutomaticSize==Enum.AutomaticSize.XY then width=math.max(20,(textClasses[instance.ClassName] and #instance.Text*8) or instance.AbsoluteSize.X) end
			for _,child in instance._children do if child.ClassName=="UISizeConstraint" then width=math.clamp(width,child.MinSize.X,child.MaxSize.X); height=math.clamp(height,child.MinSize.Y,child.MaxSize.Y) end end
			size=Vector2.new(width,height)
			position=Vector2.new(parentPosition.X+parentSize.X*instance.Position.X.Scale+instance.Position.X.Offset-width*instance.AnchorPoint.X,
				parentPosition.Y+parentSize.Y*instance.Position.Y.Scale+instance.Position.Y.Offset-height*instance.AnchorPoint.Y)
			any=computed(instance,"AbsoluteSize",size) or any; any=computed(instance,"AbsolutePosition",position) or any
		end
		for _,child in table.clone(instance._children) do visit(child,size,position) end
	end
	for _,instance in Mock.instances do if instance.ClassName=="ScreenGui" and not instance._destroyed then visit(instance,Mock.viewport,Vector2.new()) end end
	return any
end
function Mock.flush()
	for _=1,100 do
		local ready,waiting={},{}
		for _,item in Mock.queue do if not item.cancelled then if item.at<=Mock.time then table.insert(ready,item) else table.insert(waiting,item) end end end
		Mock.queue=waiting
		table.sort(ready,function(a,b) return if a.at==b.at then a.serial<b.serial else a.at<b.at end)
		for _,item in ready do if not item.cancelled then item.callback() end end
		local changedLayout=Mock.layout()
		services.RunService.Heartbeat:Fire(1/60)
		local hasReady=false; for _,item in Mock.queue do if not item.cancelled and item.at<=Mock.time then hasReady=true end end
		if not hasReady and not changedLayout then return end
	end
	error("Mock scheduler did not settle")
end
function Mock.advance(seconds) Mock.time+=seconds; Mock.flush() end
function Mock.input(kind,key,x,y)
	return {UserInputType=Enum.UserInputType[kind],KeyCode=Enum.KeyCode[key or "Unknown"],Position=Vector2.new(x or 0,y or 0)}
end
function Mock.key(key,processed) services.UserInputService.InputBegan:Fire(Mock.input("Keyboard",key),processed or false); Mock.flush() end
function Mock.findText(parent,textValue)
	for _,instance in parent:GetDescendants() do if textClasses[instance.ClassName] and instance.Text==textValue then return instance end end
end
function Mock.nativeConnections()
	local count=0
	for _,instance in Mock.instances do for _,signals in {instance._events,instance._changed} do for _,signal in signals do for connection in signal.listeners do if connection.Connected then count+=1 end end end end end
	return count
end
Mock.Instance,Mock.Vector2,Mock.Color3,Mock.UDim,Mock.UDim2,Mock.Enum,Mock.typeof=Instance,Vector2,Color3,UDim,UDim2,Enum,typeof
Mock.task,Mock.game,Mock.services,Mock.TweenInfo,Mock.playerGui=task,game,services,TweenInfo,playerGui
Mock.ColorSequence,Mock.NumberSequence=ColorSequence,NumberSequence
Mock.workspace={CurrentCamera={ViewportSize=Mock.viewport}}
Mock.warn=function(...) table.insert(Mock.warnings,table.concat({...}," ")) end
return Mock
