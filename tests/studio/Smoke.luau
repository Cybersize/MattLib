-- Real Roblox client tests. Run from Bootstrap.client.luau in Studio Play mode.
return function(Library)
	local HttpService=game:GetService("HttpService")
	local RunService=game:GetService("RunService")
	local reports={}
	local serial=0
	local function equal(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
	local function test(name,callback)
		serial+=1
		local lib=Library.new({id="studio-smoke-"..serial,reducedMotion=true,capabilities={}})
		local ok,err=xpcall(function() callback(lib,lib.UI) end,debug.traceback)
		lib:Destroy(); RunService.Heartbeat:Wait()
		local counts=Library:GetDiagnostics()
		for key,value in counts do if key~="renders" and value~=0 then ok=false; err=tostring(err).."; leaked "..key.."="..value end end
		table.insert(reports,{name=name,passed=ok,error=if ok then nil else tostring(err)})
		print("MATTLIB_STUDIO_"..(if ok then "PASS " else "FAIL ")..name..(if ok then "" else ": "..tostring(err)))
	end
	test("functional updates preserve native instances",function(lib,UI)
		local set
		local function App() local count,update=UI.useState(0); set=update; return UI.h("Button",{name="count",text=tostring(count)}) end
		local root=UI.mount(UI.h(App)); local instance=root:Find("count")
		set(function(n) return n+1 end); set(function(n) return n+1 end); root:Flush()
		equal(root:Find("count"),instance); equal(instance.Text,"2")
	end)
	test("keyed reorder and removal",function(lib,UI)
		local function list(ids) return UI.h("Column",{},UI.list(ids,function(id) return UI.h("Text",{name=id,text=id}) end,function(id) return id end)) end
		local root=UI.mount(list({"a","b","c"})); local a,c=root:Find("a"),root:Find("c")
		root:Update(list({"c","a"})):Flush(); equal(root:Find("a"),a); equal(root:Find("c"),c); equal(a.LayoutOrder,2); equal(root:Find("b"),nil)
	end)
	test("effects and event cleanup",function(lib,UI)
		local cleanup=0
		local function App() UI.useEffect(function() return function() cleanup+=1 end end,{}); return UI.h("Button",{text="Events"}) end
		lib:_ensure(); RunService.Heartbeat:Wait(); local baseline=lib:GetDiagnostics()
		local root=UI.mount(UI.h(App)); root:Unmount(); equal(cleanup,1)
		equal(lib:GetDiagnostics().connections,baseline.connections); equal(lib:GetDiagnostics().instances,baseline.instances)
	end)
	test("native theme and state styles",function(lib,UI)
		local root=UI.mount(UI.h("Button",{name="theme",text="Themed",variant="primary"})); local instance=root:Find("theme")
		lib:SetTheme("Light"); equal(instance.BackgroundColor3,lib.Theme:Get().accent)
		lib.Theme:Extend({accent=Color3.fromRGB(30,110,220)}); equal(instance.BackgroundColor3,Color3.fromRGB(30,110,220))
	end)
	test("controlled text restores an unaccepted native edit",function(lib,UI)
		local changed=""
		local root=UI.mount(UI.h("TextInput",{name="text",value="fixed",onChange=function(value) changed=value end})); local box=root:Find("text")
		box.Text="edit"; RunService.Heartbeat:Wait(); lib:Flush()
		equal(changed,"edit"); equal(box.Text,"fixed")
	end)
	test("control library creates valid native properties",function(lib,UI)
		local root=UI.mount(UI.h("Column",{}, {
			UI.h("Toggle",{label="Toggle"}),UI.h("Checkbox",{label="Checkbox"}),UI.h("Slider",{}),UI.h("RangeSlider",{}),UI.h("TextInput",{}),UI.h("NumericInput",{}),
			UI.h("Dropdown",{options={"A","B"}}),UI.h("SearchableDropdown",{options={"A","B"}}),UI.h("MultiSelect",{options={"A","B"}}),
			UI.h("ColorPicker",{}),UI.h("Keybind",{}),UI.h("RadioGroup",{options={"A","B"}}),UI.h("SegmentedControl",{options={"A","B"}}),
			UI.h("LoadingIndicator",{}),UI.h("ProgressBar",{value=0.5}),UI.h("StatusIndicator",{text="Ready"}),UI.h("Icon",{glyph="◇"}),
			UI.h("Collapsible",{title="Open",defaultOpen=true},UI.h("Text",{text="Inside"})),
		}))
		RunService.Heartbeat:Wait(); root:Flush(); assert(root.alive)
	end)
	test("window geometry, visibility and lifecycle",function(lib,UI)
		local ref={}
		local root=UI.mount(UI.h("Window",{id="window",title="Native window",windowRef=ref,size={500,360}}))
		RunService.Heartbeat:Wait(); lib:Flush(); assert(ref.current)
		ref.current:Minimize(); root:Flush(); equal(ref.current:GetRect().height,44)
		ref.current:Restore(); root:Flush(); ref.current:Hide(); root:Flush(); equal(root:Find("Window:window").Visible,false)
		ref.current:Show(); root:Flush(); ref.current:SetSize(10000,10000)
		local rect=ref.current:GetRect(); local viewport=lib._env.runtime.layers.main.AbsoluteSize
		assert(rect.width<=viewport.X and rect.height<=viewport.Y)
		root:Unmount(); equal(ref.current,nil); equal(lib:GetDiagnostics().windows,0)
	end)
	test("native flex and modifiers",function(lib,UI)
		local root=UI.mount(UI.h("Row",{name="flex",style={height=80,distribute="fill",padding=12,radius=8,borderWidth=1,minWidth=100}}, {
			UI.h("Button",{text="A",style={grow=1}}),UI.h("Button",{text="B",style={grow=2}}),
		}))
		local frame=root:Find("flex"); equal(frame:FindFirstChildOfClass("UIListLayout").HorizontalFlex,Enum.UIFlexAlignment.Fill)
		assert(frame:FindFirstChildOfClass("UIPadding") and frame:FindFirstChildOfClass("UISizeConstraint"))
	end)
	test("HttpService config round trip and atomic validation",function(lib,UI)
		local bool,color=UI.signal(false),UI.signal(Color3.fromRGB(1,22,233))
		lib.Config:Register("bool",bool,false); lib.Config:Register("color",color,color:get())
		local json=assert(lib.Config:Export()); bool:set(true); color:set(Color3.new()); assert(lib.Config:Import(json))
		equal(bool:get(),false); equal(color:get(),Color3.fromRGB(1,22,233))
		equal(lib.Config:Import(HttpService:JSONEncode({schema="mattlib/config",version=1,values={bool=42}})),false)
		bool:Destroy(); color:Destroy()
	end)
	test("same-id initialization disposes the previous client",function(lib,UI)
		lib:Mount(UI.h("Button",{text="Previous"}))
		local replacement=Library.new({id=lib.options.id,reducedMotion=true,capabilities={}})
		replacement:Mount(replacement.UI.h("Text",{text="Replacement"})); equal(lib._destroyed,true); replacement:Destroy()
	end)
	test("portals and modal lifecycle",function(lib,UI)
		local root=UI.mount(UI.h("Modal",{title="Native modal"},UI.h("Button",{name="modal-action",text="Continue"})))
		RunService.Heartbeat:Wait(); assert(root:Find("modal-action"):IsDescendantOf(lib._env.runtime.layers.overlay))
		root:Update(nil):Flush(); equal(#lib._env.overlays.stack,0)
	end)
	test("menu facade renders shared inputs",function(lib)
		local window=lib:CreateWindow({Id="native-menu",Title="Facade"}); local tab=window:AddTab({Title="Main"}); local section=tab:AddSection({Title="Settings"})
		local toggle=section:AddToggle({Id="enabled",Title="Enabled",Default=false}); lib:Flush(); local native=toggle:GetInstance(); assert(native)
		toggle:SetValue(true); lib:Flush(); equal(toggle:GetInstance(),native); equal(native:GetAttribute("AsterValue"),"true")
		window:Destroy()
	end)
	test("native 360x640 constrained viewport layout",function(lib,UI)
		local env=lib:_ensure()
		for _,layer in env.runtime.layers do layer.Size=UDim2.fromOffset(360,640) end
		RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait()
		local ref={}
		local root=UI.mount(UI.h("Window",{id="mobile",title="Mobile layout",windowRef=ref,size={900,700}},UI.h("Sidebar",{items={
			{id="a",title="First",content=UI.h("Section",{title="Responsive"},UI.h("Button",{text="Action"}))},{id="b",title="Second",content=UI.h("Text",{text="Second panel"})},
		}})))
		RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait(); lib:Flush()
		local rect=ref.current:GetRect()
		assert(rect.width<=344 and rect.height<=624 and rect.x>=8 and rect.y>=8)
		equal(root:Find("TabNavigation").AbsoluteSize.Y,44)
		local modal=UI.mount(UI.h("Modal",{title="Constrained dialog"},UI.h("Paragraph",{text=string.rep("Scrollable dialog body. ",80)})))
		RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait(); lib:Flush()
		local group=modal:Find("Modal"); equal(group.AbsoluteSize.X,360); equal(group.AbsoluteSize.Y,640)
		modal:Unmount(); root:Unmount()
	end)
	local passed=0; for _,report in reports do if report.passed then passed+=1 end end
	local result={passed=passed,failed=#reports-passed,tests=reports,viewport={x=workspace.CurrentCamera.ViewportSize.X,y=workspace.CurrentCamera.ViewportSize.Y}}
	print("MATTLIB_STUDIO_RESULTS "..HttpService:JSONEncode(result))
	return result
end
