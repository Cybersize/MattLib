-- This file is appended by scripts/test.py to the actual bundle and the engine double.
local passed,failed=0,0
local libraries={}
local function eq(actual,expected,message)
	assert(actual==expected,(message or "Values differ")..": "..tostring(actual).." ~= "..tostring(expected))
end
local function raises(callback,pattern)
	local ok,err=pcall(callback); assert(not ok,"Expected an error")
	if pattern then assert(string.find(tostring(err),pattern,1,true),tostring(err)) end
end
local function new(options)
	options=options or {}; options.id=options.id or "test"; if options.reducedMotion==nil then options.reducedMotion=true end
	options.capabilities=options.capabilities or {}
	local library=Library.new(options); table.insert(libraries,library); return library
end
local function test(name,callback)
	table.clear(Mock.warnings)
	local ok,err=pcall(callback)
	for _,library in libraries do
		local cleanupOk,cleanupErr=pcall(function() library:Destroy() end)
		if not cleanupOk then ok,err=false,tostring(err).."; cleanup: "..tostring(cleanupErr) end
	end
	table.clear(libraries)
	local settle,settleErr=pcall(function() Mock.advance(2) end)
	if not settle then ok,err=false,tostring(err).."; scheduler: "..tostring(settleErr) end
	local counts=Library:GetDiagnostics()
	for key,count in counts do if key~="renders" and count~=0 then ok,err=false,tostring(err).."; leaked "..key.."="..count end end
	if Mock.nativeConnections()~=0 then ok,err=false,tostring(err).."; native listeners="..Mock.nativeConnections() end
	if #Mock.warnings>0 then ok,err=false,tostring(err).."; warnings="..table.concat(Mock.warnings," | ") end
	if ok then passed+=1; print("PASS "..name) else failed+=1; print("FAIL "..name.."\n"..tostring(err)) end
end

test("native component creation and idempotent unmount",function()
	local lib=new(); local UI=lib.UI
	local root=UI.mount(UI.h("Button",{name="hello",text="Hello"}))
	eq(root:Find("hello").Text,"Hello"); Mock.flush()
	root:Unmount(); root:Unmount(); eq(root:Find("hello"),nil)
end)
test("functional state updates coalesce and preserve native identity",function()
	local lib=new(); local UI=lib.UI; local update; local renders=0
	local function App()
		renders+=1; local count,setCount=UI.useState(0); update=setCount
		return UI.h("Button",{name="counter",text=tostring(count),onClick=function() setCount(function(n) return n+1 end) end})
	end
	local root=UI.mount(UI.h(App)); Mock.flush(); local button=root:Find("counter"); local before=lib:GetDiagnostics()
	update(function(n) return n+1 end); update(function(n) return n+1 end); update(function(n) return n+1 end)
	Mock.flush(); eq(button.Text,"3"); eq(root:Find("counter"),button); eq(renders,2)
	eq(lib:GetDiagnostics().instances,before.instances); eq(lib:GetDiagnostics().connections,before.connections)
	button.Activated:Fire(); Mock.flush(); eq(button.Text,"4")
end)
test("state updates render only the affected sibling subtree",function()
	local lib=new(); local UI=lib.UI; local update; local left,right=0,0
	local function Left() left+=1; local n,set=UI.useState(0); update=set; return UI.h("Text",{text=n}) end
	local function Right() right+=1; return UI.h("Text",{text="unchanged"}) end
	UI.mount(UI.h("Column",{}, {UI.h(Left),UI.h(Right)})); update(1); Mock.flush()
	eq(left,2); eq(right,1)
end)
test("prop replacement, property reset and latest event closures",function()
	local lib=new(); local UI=lib.UI; local clicked=""
	local root=UI.mount(UI.h("Button",{name="prop",text="A",style={rotation=17},onClick=function() clicked="old" end}))
	local button=root:Find("prop"); eq(button.Rotation,17)
	root:Update(UI.h("Button",{name="prop",text="B",onClick=function() clicked="new" end})):Flush()
	eq(root:Find("prop"),button); eq(button.Text,"B"); eq(button.Rotation,0)
	button.Activated:Fire(); eq(clicked,"new")
end)
test("conditional removal runs effects and disconnects events",function()
	local lib=new(); local UI=lib.UI; local cleanup=0; local update
	local function Child()
		UI.useEffect(function() return function() cleanup+=1 end end,{})
		return UI.h("Button",{name="child",text="child"})
	end
	local function App() local show,set=UI.useState(true); update=set; return UI.h("Column",{}, {show and UI.h(Child) or false}) end
	local root=UI.mount(UI.h(App)); local instance=root:Find("child"); local before=lib:GetDiagnostics().connections
	update(false); Mock.flush(); eq(root:Find("child"),nil); eq(cleanup,1); assert(instance._destroyed)
	assert(lib:GetDiagnostics().connections<before)
end)
test("keyed reorder preserves hooks, refs, instances and host order",function()
	local lib=new(); local UI=lib.UI; local cleanup=0
	local function Item(p)
		local identity=UI.useRef({})
		UI.useEffect(function() return function() cleanup+=1 end end,{})
		return UI.h("Text",{name=p.id,text=p.id,attributes={identity=tostring(identity.current)}})
	end
	local function list(ids) return UI.h("Column",{},UI.list(ids,function(id) return UI.h(Item,{id=id}) end,function(id) return id end)) end
	local root=UI.mount(list({"a","b","c"})); local a,b=root:Find("a"),root:Find("b")
	root:Update(list({"c","a","b"})):Flush(); eq(root:Find("a"),a); eq(root:Find("b"),b); eq(a.LayoutOrder,2); eq(b.LayoutOrder,3); eq(cleanup,0)
	root:Update(list({"a","b"})):Flush(); eq(cleanup,1)
end)
test("duplicate keys fail visibly and leave no root-owned instances",function()
	local lib=new(); local UI=lib.UI
	raises(function() UI.mount(UI.h("Column",{}, {UI.h("Text",{key="x"}),UI.h("Text",{key="x"})})) end,"Duplicate sibling key")
	Mock.flush()
end)
test("key type changes replace components",function()
	local lib=new(); local UI=lib.UI
	local root=UI.mount(UI.h("Column",{}, {UI.h("Text",{key=1,name="item"})})); local old=root:Find("item")
	root:Update(UI.h("Column",{}, {UI.h("Text",{key="1",name="item"})})):Flush(); assert(root:Find("item")~=old); assert(old._destroyed)
end)
test("fragments flatten host order and portals retain logical cleanup",function()
	local lib=new(); local UI=lib.UI; lib:_ensure()
	local root=UI.mount(UI.h(UI.Fragment,{}, {UI.h("Text",{name="one"}),UI.h(UI.Fragment,{}, {UI.h("Text",{name="two"})}),
		UI.portal(UI.h("Text",{name="portal"}),lib._env.runtime.layers.overlay)}))
	eq(root:Find("one").LayoutOrder,1); eq(root:Find("two").LayoutOrder,2); eq(root:Find("portal").Parent,lib._env.runtime.layers.overlay)
	local portal=root:Find("portal"); root:Unmount(); assert(portal._destroyed)
end)
test("effects commit, rerun cleanup, memoize and stop after unmount",function()
	local lib=new(); local UI=lib.UI; local update; local effects,cleanups,computes=0,0,0
	local function App()
		local n,set=UI.useState(0); update=set
		local cached=UI.useMemo(function() computes+=1; return n*2 end,{n})
		UI.useEffect(function() effects+=1; return function() cleanups+=1 end end,{n})
		return UI.h("Text",{name="memo",text=cached})
	end
	local root=UI.mount(UI.h(App)); eq(effects,1); update(1); Mock.flush(); eq(effects,2); eq(cleanups,1); eq(computes,2)
	root:Unmount(); eq(cleanups,2); update(99); Mock.flush()
end)
test("hook order violations and render errors clean partial trees",function()
	local lib=new(); local UI=lib.UI; local update
	local function App()
		local n,set=UI.useState(false); update=set
		if n then UI.useRef(nil) end
		return UI.h("Text",{name="hook"})
	end
	local errors={}; local root=UI.mount(UI.h(App),nil,{onError=function(err) table.insert(errors,err) end})
	update(true); Mock.flush(); eq(root.alive,false); eq(#errors,1)
	raises(function() UI.useState(0) end,"inside a functional component")
end)
test("signals batch atomically, derive and unsubscribe",function()
	local lib=new(); local UI=lib.UI; local a,b=UI.signal(1),UI.signal(2)
	local derived=UI.derived({a,b},function(x,y) return x+y end); local seen={}
	local unsubscribe=a:subscribe(function() table.insert(seen,b:get()) end)
	UI.batch(function() a:set(3); b:set(4) end); eq(derived:get(),7); eq(seen[1],4)
	local function App() return UI.h("Text",{name="signal",text=UI.useSignal(derived)}) end
	local root=UI.mount(UI.h(App)); a:set(9); Mock.flush(); eq(root:Find("signal").Text,"13")
	root:Unmount(); unsubscribe(); derived:Destroy(); a:Destroy(); b:Destroy()
end)
test("runtime signal replacement disconnects the previous dependency",function()
	local lib=new(); local UI=lib.UI; local a,b=UI.signal("A"),UI.signal("B")
	local function App(p) return UI.h("Text",{name="value",text=UI.useSignal(p.signal)}) end
	local root=UI.mount(UI.h(App,{signal=a})); root:Update(UI.h(App,{signal=b})):Flush()
	a:set("old"); b:set("new"); Mock.flush(); eq(root:Find("value").Text,"new")
	root:Unmount(); a:Destroy(); b:Destroy()
end)
test("dark, light, custom and scoped themes update existing hosts",function()
	local lib=new(); local UI=lib.UI
	local root=UI.mount(UI.h(UI.Fragment,{}, {UI.h("Button",{name="global",text="Global",variant="primary"}),
		UI.h("ThemeProvider",{theme="Light"},UI.h("Button",{name="local",text="Local",variant="primary"}))}))
	local global,scoped=root:Find("global"),root:Find("local"); local localColor=scoped.BackgroundColor3
	lib:SetTheme("Light"); eq(global.BackgroundColor3,lib.Theme:Get().accent); eq(scoped.BackgroundColor3,localColor)
	lib.Theme:Extend({accent=Color3.fromRGB(1,2,3)}); eq(global.BackgroundColor3,Color3.fromRGB(1,2,3)); eq(root:Find("global"),global)
end)
test("controlled toggle accepts parent updates and gates disabled callbacks",function()
	local lib=new(); local UI=lib.UI; local changed=0
	local function App()
		local value,set=UI.useState(false)
		return UI.h("Toggle",{name="toggle",label="Enabled",value=value,onChange=function(nextValue) changed+=1; set(nextValue) end})
	end
	local root=UI.mount(UI.h(App)); local toggle=root:Find("toggle"); toggle.Activated:Fire(); Mock.flush(); eq(toggle:GetAttribute("AsterValue"),"true"); eq(changed,1)
	root:Update(UI.h("Toggle",{name="toggle",label="Disabled",value=false,disabled=true,onChange=function() changed+=1 end})):Flush()
	root:Find("toggle").Activated:Fire(); eq(changed,1)
end)
test("controlled text rejects unaccepted edits without losing native identity",function()
	local lib=new(); local UI=lib.UI; local input=""
	local root=UI.mount(UI.h("TextInput",{name="input",value="fixed",onChange=function(text) input=text end})); local box=root:Find("input")
	box.Text="edit"; Mock.flush(); eq(input,"edit"); eq(box.Text,"fixed"); eq(root:Find("input"),box)
end)
test("uncontrolled text and numeric commit validation",function()
	local lib=new(); local UI=lib.UI; local number=0
	local root=UI.mount(UI.h("Column",{}, {UI.h("TextInput",{name="text",defaultValue="start"}),
		UI.h("NumericInput",{name="number",defaultValue=4,min=0,max=10,step=2,onChange=function(n) number=n end})}))
	local box=root:Find("text"); box.Text="typed"; Mock.flush(); eq(box.Text,"typed")
	local numeric=root:Find("number"); numeric.Text="9"; Mock.flush(); numeric.FocusLost:Fire(false); Mock.flush(); eq(number,10)
	numeric.Text="nan?"; Mock.flush(); numeric.FocusLost:Fire(false); Mock.flush(); eq(numeric.Text,"10")
end)
test("slider pointer, keyboard, range ordering and cleanup",function()
	local lib=new(); local UI=lib.UI; local number,range=0,{0,100}
	local root=UI.mount(UI.h("Column",{}, {UI.h("Slider",{name="slider",defaultValue=0,min=0,max=100,step=5,onChange=function(n) number=n end}),
		UI.h("RangeSlider",{name="range",defaultValue={20,80},min=0,max=100,onChange=function(v) range=v end})})); Mock.flush()
	local track=root:Find("slider:Track"); local x,y=track.AbsolutePosition.X,track.AbsolutePosition.Y
	track.InputBegan:Fire(Mock.input("MouseButton1",nil,x+track.AbsoluteSize.X*0.52,y+5)); Mock.flush(); eq(number,50)
	Mock.services.UserInputService.InputChanged:Fire(Mock.input("MouseMovement",nil,x+track.AbsoluteSize.X*0.86,y)); Mock.flush(); eq(number,85)
	Mock.services.UserInputService.InputEnded:Fire(Mock.input("MouseButton1"),false)
	Mock.services.GuiService.SelectedObject=track; Mock.key("Left"); eq(number,80)
	local rangeTrack=root:Find("range:Track"); Mock.services.GuiService.SelectedObject=rangeTrack; Mock.key("End"); assert(range[1]<=range[2])
	root:Unmount(); eq(lib._env.input.capture,nil)
end)
test("searchable dropdown filters, selects, and closes",function()
	local lib=new(); local UI=lib.UI; local chosen=""
	local root=UI.mount(UI.h("SearchableDropdown",{name="choose",options={"Alpha","Beta","Gamma"},onChange=function(value) chosen=value end})); Mock.flush()
	root:Find("choose:Trigger").Activated:Fire(); Mock.flush(); local search=root:Find("DropdownSearch"); assert(search)
	search.Text="bet"; Mock.flush(); local option=Mock.findText(lib._env.runtime.screen,"    Beta"); assert(option); option.Activated:Fire(); Mock.flush()
	eq(chosen,"Beta"); eq(root:Find("choose:Menu"),nil)
end)
test("multi select updates immutable selections without duplicate options",function()
	local lib=new(); local UI=lib.UI; local selected={}
	local root=UI.mount(UI.h("MultiSelect",{name="multi",options={"A","B"},onChange=function(value) selected=value end})); Mock.flush()
	root:Find("multi:Trigger").Activated:Fire(); Mock.flush(); Mock.findText(lib._env.runtime.screen,"    A").Activated:Fire(); Mock.flush(); eq(selected[1],"A")
	Mock.findText(lib._env.runtime.screen,"✓  A").Activated:Fire(); Mock.flush(); eq(#selected,0)
end)
test("keybind capture, Escape cancellation and trigger gating",function()
	local lib=new(); local UI=lib.UI; local triggered=0; local changed=""
	local root=UI.mount(UI.h("Keybind",{name="bind",defaultValue="K",onChange=function(value) changed=value end,onTrigger=function() triggered+=1 end})); Mock.flush()
	Mock.key("K"); eq(triggered,1)
	local button=Mock.findText(lib._env.runtime.screen,"K"); button.Activated:Fire(); Mock.flush(); Mock.key("J"); eq(changed,"J")
	Mock.key("J"); eq(triggered,2); Mock.key("J",true); eq(triggered,2)
	root:Unmount(); Mock.key("J"); eq(triggered,2)
end)
test("modal traps selection, Escape dismisses, and focus restores",function()
	local lib=new(); local UI=lib.UI
	local root=UI.mount(UI.h("Column",{}, {UI.h("Button",{name="outside",text="Outside"})})); Mock.flush()
	local outside=root:Find("outside"); Mock.services.GuiService.SelectedObject=outside
	local dialog=UI.mount(UI.h("Modal",{title="Dialog"},UI.h("Button",{name="inside",text="Inside"}))); Mock.flush()
	eq(Mock.services.GuiService.SelectedObject,dialog:Find("inside")); Mock.key("Tab"); Mock.key("Escape"); Mock.flush()
	eq(dialog:Find("Modal"),nil); eq(Mock.services.GuiService.SelectedObject,outside)
end)
test("all exported controls and layouts mount as native UI",function()
	local lib=new(); local UI=lib.UI
	local controls={
		UI.h("Checkbox",{label="Check"}),UI.h("Toggle",{label="Toggle"}),UI.h("TextInput",{label="Text"}),UI.h("NumericInput",{label="Number"}),
		UI.h("Slider",{label="Slider"}),UI.h("RangeSlider",{label="Range"}),UI.h("Dropdown",{options={"One","Two"}}),
		UI.h("SearchableDropdown",{options={"One","Two"}}),UI.h("MultiSelect",{options={"One","Two"}}),UI.h("ColorPicker",{}),
		UI.h("Keybind",{}),UI.h("RadioGroup",{options={"One","Two"}}),UI.h("SegmentedControl",{options={"One","Two"}}),
		UI.h("ProgressBar",{value=0.4}),UI.h("LoadingIndicator",{}),UI.h("StatusIndicator",{status="success",text="Ready"}),
		UI.h("Badge",{text="Stable"}),UI.h("Icon",{glyph="◇"}),UI.h("RichText",{text="<b>Rich</b>"}),UI.h("Paragraph",{text="Paragraph"}),
		UI.h("Tooltip",{text="Help"},UI.h("Button",{text="Hover"})),UI.h("Collapsible",{title="Details",defaultOpen=true},UI.h("Text",{text="Content"})),
		UI.h("ContextMenu",{items={{id="one",label="Action",onSelect=function() end}}},UI.h("Text",{text="Right click"})),
	}
	local root=UI.mount(UI.h("Window",{title="Everything",id="all",openKey=false},UI.h("Sidebar",{items={{id="gallery",title="Gallery",content=UI.h("Section",{title="Controls"},controls)}}})))
	Mock.flush(); assert(lib:GetDiagnostics().components>50); assert(root:Find("Window:all"))
end)
test("window drag, resize, minimize, hide, restore and independent focus",function()
	local lib=new(); local UI=lib.UI; local first,second={},{}
	local root=UI.mount(UI.h(UI.Fragment,{}, {UI.h("Window",{id="one",title="One",size={500,360},windowRef=first}),UI.h("Window",{id="two",title="Two",windowRef=second})})); Mock.flush()
	local entry=first.current; entry:Minimize(); Mock.flush(); eq(entry:GetRect().height,44); entry:Restore(); Mock.flush(); eq(entry:GetRect().height,360)
	entry:Hide(); Mock.flush(); eq(entry.frame.Visible,false); assert(lib._env.windows.hidden:get()[1]); entry:Show(); Mock.flush(); eq(entry.frame.Visible,true)
	entry:Focus(); assert(entry.frame.ZIndex>second.current.frame.ZIndex)
	local title=entry.options.titlebar; local before=entry:GetRect(); title.InputBegan:Fire(Mock.input("MouseButton1",nil,50,50))
	Mock.services.UserInputService.InputChanged:Fire(Mock.input("MouseMovement",nil,80,70)); eq(entry:GetRect().x,before.x+30)
	Mock.services.UserInputService.InputEnded:Fire(Mock.input("MouseButton1"),false)
	local grip=entry.options.grip; local width=entry:GetRect().width; grip.InputBegan:Fire(Mock.input("MouseButton1",nil,0,0))
	Mock.services.UserInputService.InputChanged:Fire(Mock.input("MouseMovement",nil,20,20)); eq(entry:GetRect().width,width+20)
	root:Unmount(); eq(first.current,nil); eq(second.current,nil); eq(lib:GetDiagnostics().windows,0)
end)
test("desktop and mobile viewport constraints keep window controls reachable",function()
	local lib=new(); local UI=lib.UI; local ref={}
	UI.mount(UI.h("Window",{id="mobile",title="Responsive",windowRef=ref,size={900,700}})); Mock.flush()
	Mock.viewport=Vector2.new(360,640); Mock.flush(); local rect=ref.current:GetRect()
	assert(rect.width<=344 and rect.height<=624 and rect.x>=8 and rect.y>=8)
	ref.current:SetSize(5000,5000); rect=ref.current:GetRect(); assert(rect.x+rect.width<=352 and rect.y+rect.height<=632)
	Mock.viewport=Vector2.new(1024,768); Mock.flush()
end)
test("configuration JSON round trips false, escaping, arrays and Color3",function()
	local lib=new(); local UI=lib.UI; local enabled=UI.signal(false); local color=UI.signal(Color3.fromRGB(1,22,233)); local text=UI.signal('quote " slash \\ newline\n')
	local array=UI.signal({"A","B"})
	lib.Config:Register("enabled",enabled,false); lib.Config:Register("color",color,color:get()); lib.Config:Register("text",text,text:get()); lib.Config:Register("array",array,array:get())
	local json,err=lib.Config:Export(); assert(json,err); enabled:set(true); color:set(Color3.new()); text:set("changed"); array:set({"C"})
	local ok,reason=lib.Config:Import(json); assert(ok,reason); eq(enabled:get(),false); eq(color:get(),Color3.fromRGB(1,22,233)); eq(text:get(),'quote " slash \\ newline\n'); eq(array:get()[2],"B")
	for _,signal in {enabled,color,text,array} do signal:Destroy() end
end)
test("configuration validation is atomic, rejects malformed and future data",function()
	local lib=new(); local a,b=lib.UI.signal(1),lib.UI.signal(false)
	lib.Config:Register("a",a,1,function(value) return value<=10,"too large" end); lib.Config:Register("b",b,false)
	local ok=lib.Config:Import('{"schema":"mattlib/config","version":1,"values":{"a":5,"b":42}}'); eq(ok,false); eq(a:get(),1); eq(b:get(),false)
	eq(lib.Config:Import("{"),false); eq(lib.Config:Import('{"schema":"mattlib/config","version":99,"values":{}}'),false)
	eq(lib.Config:Import('{"schema":"mattlib/config","version":1,"values":{"a":999}}'),false)
	a:Destroy(); b:Destroy()
end)
test("configuration reset, memory profiles and path validation",function()
	local lib=new(); local signal=lib.UI.signal(2); local unregister=lib.Config:Register("n",signal,2)
	signal:set(8); local ok,mode=lib.Config:Save("profile"); eq(ok,true); eq(mode,"memory"); lib.Config:Reset(); eq(signal:get(),2)
	assert(lib.Config:Load("profile")); eq(signal:get(),8); eq(lib.Config:Load("missing"),false); eq(lib.Config:Save("../bad"),false)
	unregister(); signal:Destroy()
end)
test("optional filesystem capabilities and explicit failure reporting",function()
	local files={}; local lib=new({capabilities={writefile=function(path,content) files[path]=content end,readfile=function(path) return files[path] end,isfile=function(path) return files[path]~=nil end}})
	local signal=lib.UI.signal(true); lib.Config:Register("v",signal,true); local ok,mode=lib.Config:Save("good"); eq(ok,true); eq(mode,"file")
	signal:set(false); assert(lib.Config:Load("good")); eq(signal:get(),true); signal:Destroy()
	local broken=new({id="broken",capabilities={writefile=function() error("disk denied") end}}); local success,err=broken.Config:Save("test"); eq(success,false); assert(string.find(err,"disk denied",1,true))
end)
test("runtime parenting falls back from unavailable gethui to PlayerGui",function()
	local lib=new({capabilities={gethui=function() error("unavailable") end}}); lib:Mount(lib.UI.h("Text",{text="Fallback"})); eq(lib:GetRuntimeInfo().parentMode,"PlayerGui")
	local alternate=Instance.new("PlayerGui"); local other=new({id="optional",capabilities={gethui=function() return alternate end}})
	other:Mount(other.UI.h("Text",{text="Other"})); eq(other:GetRuntimeInfo().parentMode,"gethui"); other:Destroy(); alternate:Destroy()
end)
test("repeated initialization synchronously disposes only the matching library id",function()
	local first=new({id="same"}); first:Mount(first.UI.h("Button",{text="First"}))
	local independent=new({id="independent"}); independent:Mount(independent.UI.h("Text",{text="Independent"}))
	local second=new({id="same"}); second:Mount(second.UI.h("Text",{text="Second"})); eq(first._destroyed,true); eq(independent._destroyed,false)
	local count=0; for _,child in Mock.playerGui:GetChildren() do if child.Name=="MattLib:same" then count+=1 end end; eq(count,1)
end)
test("external ScreenGui destruction unmounts hooks and service subscriptions",function()
	local lib=new(); lib:Mount(lib.UI.h("Button",{text="External"})); lib._env.runtime.screen:Destroy(); eq(lib._destroyed,true)
end)
test("menu facade uses shared controls, configuration and native identity",function()
	local lib=new(); local changes=0
	local window=lib:CreateWindow({Id="facade",Title="Menu",OpenKey=false}); local tab=window:AddTab({Title="Main"}); local section=tab:AddSection({Title="Settings"})
	local toggle=section:AddToggle({Id="enabled",Title="Enabled",Default=false,Callback=function() changes+=1 end})
	local number=section:AddSlider({Id="amount",Title="Amount",Min=0,Max=10,Default=2}); Mock.flush()
	local instance=toggle:GetInstance(); assert(instance); toggle:SetValue(true); Mock.flush(); eq(changes,1); eq(toggle:GetInstance(),instance); eq(toggle:GetValue(),true)
	local json=assert(lib.Config:Export()); toggle:SetValue(false); assert(lib.Config:Import(json)); Mock.flush(); eq(toggle:GetValue(),true)
	number:Update({Title="Updated"}); Mock.flush(); eq(number:GetValue(),2)
	toggle:Destroy(); Mock.flush(); assert(instance._destroyed); window:Destroy(); Mock.flush(); eq(lib:GetDiagnostics().windows,0)
end)
test("notifications auto-dismiss, bounded queues and confirmation cleanup",function()
	local lib=new(); local toast=lib:Notify({title="Saved",message="Configuration saved",duration=1}); Mock.flush(); assert(Mock.findText(lib._env.runtime.screen,"Saved"))
	Mock.advance(1); eq(#lib._env.notifications.signal:get(),0); toast:Dismiss()
	for index=1,20 do lib:Notify({title=tostring(index),duration=false}) end; Mock.flush(); eq(#lib._env.notifications.signal:get(),8)
	local result; local dialog=lib:Confirm({title="Question",onResult=function(value) result=value end}); Mock.flush(); dialog:Close(); Mock.flush(); eq(result,false); eq(dialog.root.alive,false)
end)
test("interrupted and reduced-motion animations release tween connections",function()
	local lib=new({reducedMotion=false}); local root=lib:Mount(lib.UI.h("Frame",{name="animate",style={height=100}})); local instance=root:Find("animate"); local animator=lib._env.animator
	animator:To(instance,{Rotation=20},1); animator:To(instance,{Rotation=40},1); eq(lib:GetDiagnostics().tweens,1)
	Mock.advance(1); eq(instance.Rotation,40); eq(lib:GetDiagnostics().tweens,0)
	animator:To(instance,{Rotation=90},10); lib:SetReducedMotion(true); eq(instance.Rotation,90); eq(lib:GetDiagnostics().tweens,0)
end)
test("invalid public inputs fail explicitly without fake components",function()
	local lib=new(); local UI=lib.UI
	raises(function() UI.mount(UI.h("Unknown",{})) end,"Unknown MattLib component")
	raises(function() UI.mount(UI.h("Slider",{min=5,max=1})) end,"min < max")
	raises(function() UI.mount(UI.h("Text",{style={madeUpProperty=true}})) end,"Unsupported style property")
	raises(function() UI.mount(UI.h("Dropdown",{options={"same","same"}})) end,"Duplicate option")
end)
test("repeated mounts and rapid value updates keep listener and instance counts stable",function()
	local lib=new(); local UI=lib.UI
	lib:_ensure(); Mock.flush(); local baseline=lib:GetDiagnostics()
	for _=1,25 do
		local set; local function App() local value,update=UI.useState(0); set=update; return UI.h("Button",{text=tostring(value)}) end
		local root=UI.mount(UI.h(App)); local instances=lib:GetDiagnostics().instances; local connections=lib:GetDiagnostics().connections
		for index=1,50 do set(index) end; Mock.flush(); eq(lib:GetDiagnostics().instances,instances); eq(lib:GetDiagnostics().connections,connections)
		root:Unmount()
	end
	eq(lib:GetDiagnostics().instances,baseline.instances); eq(lib:GetDiagnostics().connections,baseline.connections)
end)

test("effect declaration order is deterministic",function()
	local lib=new(); local UI=lib.UI; local order={}
	local function App()
		UI.useEffect(function() table.insert(order,"first") end,{})
		UI.useEffect(function() table.insert(order,"second") end,{})
		return UI.h("Text",{text="Effects"})
	end
	UI.mount(UI.h(App)); eq(table.concat(order,","),"first,second")
end)
test("theme overrides preserve window and control identity",function()
	local lib=new(); local window=lib:CreateWindow({Id="theme",Title="Theme"}); local tab=window:AddTab({Title="Main"})
	local toggle=tab:AddToggle({Title="Value",Default=true}); Mock.flush(); local native=toggle:GetInstance(); local frame=window:GetInstance()
	window:SetTheme("Light"); Mock.flush(); eq(toggle:GetInstance(),native); eq(window:GetInstance(),frame); eq(toggle:GetValue(),true)
	window:SetTheme("Dark"); Mock.flush(); eq(toggle:GetInstance(),native)
end)
test("uncontrolled text length limits handle Unicode and unchanged values",function()
	local lib=new(); local UI=lib.UI
	local root=UI.mount(UI.h("TextInput",{name="limited",defaultValue="é",maxLength=1})); local input=root:Find("limited")
	input.Text="é好"; Mock.flush(); eq(input.Text,"é")
end)
test("controlled numeric input restores a rejected commit",function()
	local lib=new(); local UI=lib.UI; local rejected
	local root=UI.mount(UI.h("NumericInput",{name="number",value=4,onChange=function(value) rejected=value end})); local input=root:Find("number")
	input.Text="8"; Mock.flush(); input.FocusLost:Fire(false); Mock.flush(); eq(rejected,8); eq(input.Text,"4")
end)
test("standalone confirmation closes on answer exactly once",function()
	local lib=new(); local UI=lib.UI; local count=0
	local root=UI.mount(UI.h("ConfirmationDialog",{title="Answer",onResult=function(value) eq(value,true); count+=1 end})); Mock.flush()
	local button=Mock.findText(lib._env.runtime.screen,"Confirm"); button.Activated:Fire(); button.Activated:Fire(); Mock.flush(); eq(count,1); eq(root:Find("Modal"),nil)
end)
test("color picker edits channels and validates hex",function()
	local lib=new(); local UI=lib.UI; local color
	local root=UI.mount(UI.h("ColorPicker",{name="picker",defaultValue=Color3.fromRGB(0,0,0),onChange=function(value) color=value end})); Mock.flush()
	Mock.findText(lib._env.runtime.screen,"#000000").Activated:Fire(); Mock.flush()
	local input=Mock.findText(lib._env.runtime.screen,"#000000")
	for _,instance in lib._env.runtime.screen:GetDescendants() do if instance:IsA("TextBox") then input=instance end end
	input.Text="#FF8000"; Mock.flush(); input.FocusLost:Fire(false); Mock.flush(); eq(color,Color3.fromRGB(255,128,0))
	input.Text="bad"; Mock.flush(); input.FocusLost:Fire(false); Mock.flush(); eq(color,Color3.fromRGB(255,128,0))
	root:Unmount()
end)
test("configuration migration and readonly capability memory fallback",function()
	local lib=new({config={version=2},capabilities={readfile=function() error("no file") end}}); local value=lib.UI.signal(1)
	lib.Config:Register("current",value,1)
	lib.Config:RegisterMigration(1,function(data) return {schema=data.schema,version=2,values={current=data.values.old}} end)
	assert(lib.Config:Import('{"schema":"mattlib/config","version":1,"values":{"old":7}}')); eq(value:get(),7)
	local ok,mode=lib.Config:Save("memory"); eq(ok,true); eq(mode,"memory"); value:set(9); assert(lib.Config:Load("memory")); eq(value:get(),7); value:Destroy()
end)
test("configuration rejects cyclic values and duplicate registrations",function()
	local lib=new(); local value=lib.UI.signal({"valid"}); lib.Config:Register("unique",value,{"valid"})
	raises(function() lib.Config:Register("unique",value,{}) end,"unique")
	local cycle={}; cycle[1]=cycle; value:set(cycle); local exported,err=lib.Config:Export(); eq(exported,nil); assert(err)
	value:Destroy()
end)
test("cross-bundle reexecution disposes old native connections",function()
	local first=new({id="cross-bundle"}); first:Mount(first.UI.h("Button",{text="Old copy"}))
	local another=createBundle().new({id="cross-bundle",reducedMotion=true,capabilities={}})
	another:Mount(another.UI.h("Button",{text="New copy"})); eq(first._destroyed,true)
	another:Destroy(); local counts=another:GetDiagnostics(); for key,count in counts do if key~="renders" then eq(count,0,key) end end
end)
test("facade destruction releases library-owned handle references",function()
	local lib=new(); lib:_ensure(); local before=0; for _ in lib._scope.tasks do before+=1 end
	for _=1,20 do local window=lib:CreateWindow({Title="Temporary"}); window:Destroy() end
	local after=0; for _ in lib._scope.tasks do after+=1 end; eq(after,before)
end)
test("layout changes reset previously assigned native flex properties",function()
	local lib=new(); local UI=lib.UI
	local root=UI.mount(UI.h("Row",{name="layout",style={distribute="fill",wrap=true}})); local layout=root:Find("layout"):FindFirstChildOfClass("UIListLayout")
	eq(layout.HorizontalFlex,Enum.UIFlexAlignment.Fill); eq(layout.Wraps,true)
	root:Update(UI.h("Row",{name="layout"})):Flush(); eq(layout.HorizontalFlex,Enum.UIFlexAlignment.None); eq(layout.Wraps,false)
end)
test("minimized resize retains titlebar height and updates restore size",function()
	local lib=new(); local UI=lib.UI; local ref={}; UI.mount(UI.h("Window",{windowRef=ref})); Mock.flush()
	ref.current:Minimize(); ref.current:SetSize(600,400); eq(ref.current:GetRect().height,44); ref.current:Restore(); eq(ref.current:GetRect().height,400)
end)
test("sparse child arrays and options fail explicitly",function()
	local lib=new(); local UI=lib.UI
	raises(function() UI.h("Column",{}, {[1]=UI.h("Text"),[3]=UI.h("Text")}) end,"dense")
	raises(function() UI.mount(UI.h("Dropdown",{options={a="A"}})) end,"dense array")
end)

for _,name in {"basic","declarative","component-gallery","complex-dashboard"} do
	test("working example factory: "..name,function()
		local example=Examples[name](Library)
		table.insert(libraries,example.library)
		Mock.flush()
		local root=example.root or example.window.root
		assert(root.alive,"Example failed to mount")
		assert(example.library:GetDiagnostics().windows>=1)
		example.Destroy()
	end)
end

print(string.format("RESULT %d passed, %d failed",passed,failed))
assert(failed==0,"MattLib regression suite failed")
