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
		print("MATTLIB_STUDIO_CASE "..HttpService:JSONEncode(reports[#reports]))
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
	test("all four native design layouts preserve state and instances",function(lib,UI)
		local setCount
		local function Page()
			local count,set=UI.useState(0); setCount=set
			return UI.h("Section",{title="Stable section"},UI.h("Button",{name="design-value",text=tostring(count),variant="primary"}))
		end
		local root=UI.mount(UI.h("Window",{id="designs"},UI.h("Tabs",{name="design-tabs",items={{id="one",title="One",content=UI.h(Page)},{id="two",title="Two"}}})))
		RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait(); lib:Flush()
		local frame,button=root:Find("Window:designs"),root:Find("design-value")
		setCount(7); root:Flush()
		for _,name in lib.Designs do
			lib:SetDesign(name); lib:Flush(); RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait(); lib:Flush()
			equal(root:Find("Window:designs"),frame); equal(root:Find("design-value"),button); equal(button.Text,"7"); equal(frame:GetAttribute("MattDesign"),name)
			assert(root:Find("TabIndicator") and button:FindFirstChildOfClass("UIScale"))
		end
	end)
	test("native glow gradient and scale modifiers cleanly change",function(lib,UI)
		local root=UI.mount(UI.h("Button",{name="effects",text="Effects",variant="primary"})); local button=root:Find("effects")
		assert(button:FindFirstChildOfClass("UIGradient") and button:FindFirstChildOfClass("UIScale") and button:FindFirstChild("Matt_halo"))
		lib:SetEffectIntensity(0); lib:Flush(); equal(button:FindFirstChild("Matt_halo"),nil)
		lib:SetDesign("Vector"); lib:Flush(); equal(root:Find("effects"),button)
	end)
	test("native per-window designs and minimized header sizes",function(lib)
		local window=lib:CreateWindow({Id="scoped",Title="Scoped",Design="Ember"}); window:AddTab({Title="Main"}); lib:Flush()
		local frame=window:GetInstance(); equal(frame:GetAttribute("MattDesign"),"Ember")
		window:Minimize(); lib:Flush(); equal(window:GetRect().height,48)
		window:SetDesign("Aura"); lib:Flush(); equal(window:GetInstance(),frame); equal(frame:GetAttribute("MattDesign"),"Aura"); equal(window:GetRect().height,54)
		window:Restore(); lib:Flush(); window:Destroy()
	end)
	for _,design in {"MintGlass","Ember","Vector","Aura"} do
		test("native gallery factory "..design,function()
			local factory=require(game:GetService("ReplicatedStorage").AsterExamples.Gallery)
			local demo=factory(Library,{design=design,reducedMotion=true})
			local ok,err=xpcall(function()
				RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait(); demo.library:Flush()
				assert(demo.root.alive and demo.root:Find("GalleryDesignPicker") and demo.root:Find("DesignTryButton"))
				equal(demo.library:GetDesign(),design)
			end,debug.traceback)
			demo.Destroy(); if not ok then error(err,0) end
		end)
	end
	test("native adaptive grid wraps without overlap and preserves input identity",function(lib,UI)
		local function view(width)
			return UI.h("Frame",{style={width=width,height=500}},UI.h("AdaptiveGrid",{name="native-grid",minColumnWidth=230}, {
				UI.h("Section",{key="first",title="First"},UI.h("TextInput",{name="native-grid-input",defaultValue="Keep me"})),
				UI.h("Section",{key="second",title="Second"},UI.h("Toggle",{label="Enabled",defaultValue=true})),
				UI.h("Section",{key="third",title="Third"},UI.h("Text",{text="Another row"})),
			}))
		end
		local function settle() for _=1,5 do RunService.Heartbeat:Wait(); lib:Flush() end end
		local root=UI.mount(view(620)); settle()
		local input=root:Find("native-grid-input")
		local a,b,c=root:Find("GridCell:1"),root:Find("GridCell:2"),root:Find("GridCell:3")
		equal(root:Find("native-grid"):GetAttribute("MattColumns"),2)
		assert(a.AbsolutePosition.X+a.AbsoluteSize.X<=b.AbsolutePosition.X+1,"Grid cells overlap horizontally")
		assert(math.abs(a.AbsolutePosition.Y-b.AbsolutePosition.Y)<1,"First two cards must share a row")
		assert(c.AbsolutePosition.Y>=a.AbsolutePosition.Y+math.max(a.AbsoluteSize.Y,b.AbsoluteSize.Y),"Next row overlaps")
		root:Update(view(320)):Flush(); settle(); equal(root:Find("native-grid"):GetAttribute("MattColumns"),1)
		equal(root:Find("native-grid-input"),input); equal(input.Text,"Keep me")
		assert(b.AbsolutePosition.Y>=a.AbsolutePosition.Y+a.AbsoluteSize.Y,"Single-column cards overlap")
	end)
	test("native wallpaper moves and stops for reduced motion and hidden windows",function(lib,UI)
		lib:SetReducedMotion(false)
		local ref={}
		local root=UI.mount(UI.h("Window",{windowRef=ref,wallpaper={Speed=4}}))
		for _=1,3 do RunService.Heartbeat:Wait(); lib:Flush() end
		local ribbon=root:Find("WallpaperRibbon1"); local initial=ribbon.Position
		task.wait(0.35); assert(ribbon.Position~=initial,"Wallpaper did not move")
		local wallpaper=root:Find("WindowAtmosphere"); equal(wallpaper:GetAttribute("MattWallpaperAnimated"),true)
		lib:SetReducedMotion(true); lib:Flush(); equal(wallpaper:GetAttribute("MattWallpaperAnimated"),false); equal(lib:GetDiagnostics().tweens,0)
		lib:SetReducedMotion(false); lib:Flush(); equal(wallpaper:GetAttribute("MattWallpaperAnimated"),true)
		ref.current:Hide(); lib:Flush(); task.wait(0.3); equal(wallpaper:GetAttribute("MattWallpaperAnimated"),false); equal(lib:GetDiagnostics().tweens,0)
		ref.current:Show(); lib:Flush(); task.wait(0.3); equal(wallpaper:GetAttribute("MattWallpaperAnimated"),true)
	end)
	test("native gallery uses two control columns at screenshot width",function()
		local factory=require(game:GetService("ReplicatedStorage").AsterExamples.Gallery)
		local demo=factory(Library,{page="inputs",reducedMotion=true})
		local ok,err=xpcall(function()
			local env=demo.library._env
			for _,layer in env.runtime.layers do layer.Size=UDim2.fromOffset(790,640) end
			for _=1,8 do RunService.Heartbeat:Wait(); demo.library:Flush() end
			local grid=demo.root:Find("GalleryControlsGrid"); equal(grid:GetAttribute("MattColumns"),2)
			local nav=demo.root:Find("TabNavigation"); assert(nav.AbsoluteSize.X<=148)
			local a,b=demo.root:Find("GridCell:1"),demo.root:Find("GridCell:2")
			assert(a.AbsolutePosition.X+a.AbsoluteSize.X<=b.AbsolutePosition.X+1)
			print("MATTLIB_LAYOUT_METRICS "..HttpService:JSONEncode({viewport={x=790,y=640},columns=grid:GetAttribute("MattColumns"),sidebarWidth=nav.AbsoluteSize.X,
				contentWidth=grid.AbsoluteSize.X,firstCard={x=a.AbsolutePosition.X,y=a.AbsolutePosition.Y,w=a.AbsoluteSize.X,h=a.AbsoluteSize.Y},secondCard={x=b.AbsolutePosition.X,y=b.AbsolutePosition.Y,w=b.AbsoluteSize.X,h=b.AbsoluteSize.Y}}))
		end,debug.traceback)
		demo.Destroy(); if not ok then error(err,0) end
	end)
	test("native shared UI avoids CanvasGroup text rasterization",function(lib,UI)
		local root=UI.mount(UI.h("Window",{},UI.h("Tabs",{items={{id="main",title="Main",content=UI.h("Section",{title="Native resolution"},UI.h("Text",{name="native-sharp-text",text="Directly rendered text"}))}}})))
		UI.mount(UI.h("Modal",{title="Native dialog"},UI.h("Text",{text="Native dialog text"})))
		lib:Notify({title="Native notification",message="No flattened text"})
		for _=1,3 do RunService.Heartbeat:Wait(); lib:Flush() end
		for _,instance in lib._env.runtime.screen:GetDescendants() do assert(not instance:IsA("CanvasGroup"),"Unexpected text-flattening layer: "..instance:GetFullName()) end
		equal(root:Find("native-sharp-text").TextTransparency,0)
	end)
	test("native direct fades restore text and stroke transparency",function(lib,UI)
		lib:SetReducedMotion(false)
		local root=UI.mount(UI.h("Section",{name="native-fade",title="Native fade"},UI.h("Text",{name="native-fade-text",text="Crisp text"})))
		task.wait(0.35); lib:Flush()
		local frame,label=root:Find("native-fade"),root:Find("native-fade-text")
		lib._env.animator:Fade(frame,0,0.05); task.wait(0.1); equal(label.TextTransparency,1)
		lib._env.animator:Fade(frame,1,0.05); task.wait(0.1); equal(label.TextTransparency,0)
		local stroke=frame:FindFirstChildOfClass("UIStroke"); assert(math.abs(stroke.Transparency-0.28)<0.001)
		lib:SetReducedMotion(true); equal(lib:GetDiagnostics().tweens,0)
	end)
	test("native swatch leaves the hex text inset clear",function(lib,UI)
		local root=UI.mount(UI.h("ColorPicker",{defaultValue=Color3.fromRGB(104,240,203)}))
		for _=1,3 do RunService.Heartbeat:Wait(); lib:Flush() end
		local swatch=root:Find("ColorSwatch"); local button=swatch.Parent
		local textStart=button.AbsolutePosition.X+button:FindFirstChildOfClass("UIPadding").PaddingLeft.Offset
		assert(swatch.AbsolutePosition.X>=button.AbsolutePosition.X,"Swatch is outside its button")
		assert(swatch.AbsolutePosition.X+swatch.AbsoluteSize.X+4<=textStart,"Swatch overlaps hex text")
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
	print("MATTLIB_STUDIO_SUMMARY "..HttpService:JSONEncode({passed=passed,failed=#reports-passed,version=Library.Version,viewport=result.viewport}))
	return result
end
