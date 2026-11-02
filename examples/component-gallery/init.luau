return function(Library,options)
	options=options or {}
	local app=Library.new({id="mattlib-gallery",design=options.design or "MintGlass",reducedMotion=options.reducedMotion})
	local UI=app.UI
	local h=UI.h
	local settings={enabled=UI.signal(true),checked=UI.signal(false),volume=UI.signal(64),range=UI.signal({20,80}),
		name=UI.signal("Workspace"),number=UI.signal(8),region=UI.signal("Singapore"),tags=UI.signal({"Design","Luau"}),
		color=UI.signal(app.Theme:Get().accent),key=UI.signal("F6"),radio=UI.signal("Balanced"),segment=UI.signal("Daily"),
		design=UI.signal(app:GetDesign()),intensity=UI.signal(1),reduced=UI.signal(options.reducedMotion==true)}
	for id,signal in settings do
        app.Config:Register("gallery/"..id,signal,signal:get(),function(value)
            if id=="design" then return table.find(app.Designs,value)~=nil,"Unknown design" end
            if id=="intensity" then return type(value)=="number" and value>=0 and value<=1,"Intensity must be 0..1" end
            return true
        end)
    end
	local disconnects={}
	table.insert(disconnects,settings.design:subscribe(function(name)
		if app:GetDesign()~=name then app:SetDesign(name); app:SetEffectIntensity(settings.intensity:get()) end
	end))
	table.insert(disconnects,app.Theme.signal:subscribe(function(theme) if settings.design:get()~=theme.design.name then settings.design:set(theme.design.name) end end))
	table.insert(disconnects,settings.intensity:subscribe(function(value) app:SetEffectIntensity(value) end))
	table.insert(disconnects,settings.reduced:subscribe(function(value) app:SetReducedMotion(value) end))
	local function bind(name)
		return UI.useSignal(settings[name]),function(value) settings[name]:set(value) end
	end
	local function Metric(p)
		return h("Section",{style={width=UDim.new(1/3,-8),padding=16,gap=4}}, {
			h("Text",{text=p.label,style={color="$muted",textSize=12}}),
			h("Text",{text=p.value,style={textSize=26,font="$typography.bold"}}),
			h("StatusIndicator",{text=p.note,status="success"}),
		})
	end
	local function Overview()
		local clicks,setClicks=UI.useState(0)
		return h("Column",{style={gap=18}}, {
			h("Badge",{text="MATTLIB  /  COMPONENT STUDIO"}),
			h("Text",{text="A considered interface.",style={textSize=28,font="$typography.bold"}}),
			h("Paragraph",{text="A native Luau component system for interfaces that feel intentional. Explore the controls, change the theme, and build something of your own."}),
			h("Row",{style={gap=12}}, {
				h(Metric,{label="RENDERING",value="Incremental",note="Keyed reconciliation"}),
				h(Metric,{label="RUNTIME",value="Native",note="No external dependencies"}),
				h(Metric,{label="AUTHORING",value="Composable",note="One shared component system"}),
			}),
			h("Section",{title="Small interactions, shared foundations",description="State updates preserve the underlying native instances."}, {
				h("Row",{style={distribute="fill"}}, {
					h("Button",{name="GalleryCounter",text="Count  ·  "..clicks,variant="primary",onClick=function() setClicks(function(n) return n+1 end) end}),
					h("Tooltip",{text="Tooltips respond to pointer hover and native selection."},h("Button",{text="A little context",variant="secondary"})),
				}),
				h("RichText",{text="Compose <b>functional components</b>, share <i>signals</i>, and let the renderer own the lifecycle.",style={color="$muted"}}),
			}),
			h("ContextMenu",{items={{id="notify",label="Show notification",onSelect=function() app:Notify({title="Context action",message="The menu uses the shared popover and button components."}) end},
				{id="light",label="Switch to light",onSelect=function() app:SetTheme("Light") end}}},
				h("Section",{title="A secondary action",description="Right-click here, or long-press on a touch device, to open a context menu."},h("StatusIndicator",{status="info",text="Pointer and touch"}))),
		})
	end
	local function Inputs()
		local enabled,setEnabled=bind("enabled"); local checked,setChecked=bind("checked"); local volume,setVolume=bind("volume"); local range,setRange=bind("range")
		local name,setName=bind("name"); local number,setNumber=bind("number"); local region,setRegion=bind("region"); local tags,setTags=bind("tags")
		local color,setColor=bind("color"); local key,setKey=bind("key"); local radio,setRadio=bind("radio"); local segment,setSegment=bind("segment")
		return h("Column",{style={gap=16}}, {
			h("Text",{text="Inputs & controls",style={textSize=24,font="$typography.bold"}}),
			h("Section",{title="Boolean controls"}, {
				h("Toggle",{name="GalleryToggle",label="Enable notifications",description="A controlled switch backed by a shared signal.",value=enabled,onChange=setEnabled}),
				h("Checkbox",{label="Include experimental features",value=checked,onChange=setChecked}),
				h("Toggle",{label="Unavailable setting",disabled=true,value=false}),
			}),
			h("Section",{title="Continuous values"}, {
				h("Slider",{label="Output level",min=0,max=100,value=volume,onChange=setVolume,format=function(n) return n.."%" end}),
				h("RangeSlider",{label="Operating range",min=0,max=100,value=range,onChange=setRange}),
			}),
			h("Section",{title="Text & selection"}, {
				h("TextInput",{label="Workspace name",value=name,onChange=setName,maxLength=48}),
				h("NumericInput",{label="Concurrency",min=1,max=32,step=1,value=number,onChange=setNumber}),
				h("Dropdown",{label="Region",options={"Singapore","Tokyo","Frankfurt","Virginia"},value=region,onChange=setRegion}),
				h("SearchableDropdown",{label="Search regions",options={"Singapore","Tokyo","Frankfurt","Virginia","Sydney","London","Mumbai"},value=region,onChange=setRegion}),
				h("MultiSelect",{label="Project tags",options={"Design","Luau","Research","Testing","Release"},value=tags,onChange=setTags}),
			}),
			h("Section",{title="Specialized controls"}, {
				h("ColorPicker",{label="Highlight color",value=color,onChange=setColor}),
				h("Keybind",{label="Quick action",value=key,onChange=setKey,onTrigger=function() app:Notify({title="Keybind",message="Your configured keyboard shortcut fired."}) end}),
				h("RadioGroup",{label="Performance profile",options={"Economy","Balanced","Performance"},value=radio,onChange=setRadio}),
				h("SegmentedControl",{label="Time period",options={"Daily","Weekly","Monthly"},value=segment,onChange=setSegment}),
			}),
		})
	end
	local function Layouts()
		return h("Column",{style={gap=16}}, {
			h("Text",{text="Layout & hierarchy",style={textSize=24,font="$typography.bold"}}),
			h("Section",{title="Rows and columns",description="Native list layouts with shared gap and padding utilities."}, {
				h("Row",{style={distribute="fill"}}, {h("Button",{text="One"}),h("Button",{text="Two"}),h("Button",{text="Three"})}),
				h("Separator"),h("Paragraph",{text="Use percentages or UDim values for fluid widths. Use Inset, gap, and parent padding for spacing."}),
			}),
			h("CollapsibleSection",{title="Progressive disclosure",defaultOpen=true}, {
				h("Paragraph",{text="The section measures its content and animates its clipped container. Its children keep their state while collapsed."}),
				h("Checkbox",{label="State survives collapsing"}),
			}),
			h("Section",{title="Stacked positioning"},h("Stack",{style={height=110}}, {
				h("Frame",{style={width="100%",height=100,background="$raised",backgroundTransparency=0,radius=8}}),
				h("Text",{text="Positioned content",style={position=UDim2.fromOffset(16,16),width=UDim.new(1,-32),height=28,font="$typography.medium"}}),
				h("Badge",{text="Layer 2",style={position=UDim2.fromOffset(16,58),zIndex=2}}),
			})),
		})
	end
	local function FeedbackPanel()
		local progress,setProgress=UI.useState(0.64); local modal,setModal=UI.useState(false)
		return h("Column",{style={gap=16}}, {
			h("Text",{text="Feedback & overlays",style={textSize=24,font="$typography.bold"}}),
			h("Section",{title="Status and progress"}, {
				h("Row",{}, {h("StatusIndicator",{status="success",text="Operational"}),h("StatusIndicator",{status="warning",text="Attention"}),h("Badge",{text="v1.1"})}),
				h("ProgressBar",{label="Release preparation",value=progress}),
				h("Slider",{label="Preview progress",min=0,max=100,value=math.round(progress*100),onChange=function(n) setProgress(n/100) end}),
				h("LoadingIndicator",{text="Waiting for your next idea…"}),
			}),
			h("Section",{title="Notifications and dialogs"}, {
				h("Button",{text="Show notification",onClick=function() app:Notify({title="Everything is up to date",message="Your workspace settings have been saved.",status="success"}) end}),
				h("Button",{text="Open modal",onClick=function() setModal(true) end}),
				h("Button",{text="Confirm an action",variant="primary",onClick=function() app:Confirm({title="Publish this release?",message="This demo only shows a confirmation. It does not publish anything.",onResult=function(result)
				app:Notify({title=if result then "Confirmed" else "Cancelled",message="The dialog returned a boolean result."})
			end}) end}),
			}),
			h("Modal",{open=modal,onOpenChange=setModal,title="A focused moment"}, {
				h("Paragraph",{text="Modal focus is contained. Tab cycles through controls, Escape dismisses, and the previous selection is restored."}),
				h("TextInput",{label="A note",placeholder="Try keyboard focus…"}),
				h("Button",{text="Done",variant="primary",onClick=function() setModal(false) end}),
			}),
		})
	end
	local headings={MintGlass="Make it your own.",Ember="Control the feel.",Vector="Precision in every detail.",Aura="Find your flow."}
	local descriptions={MintGlass="A little depth. A lot more character.",Ember="Warm contrast and tactile controls.",Vector="A focused workspace with precise interactions.",Aura="A softer take on powerful controls."}
	local function Configurations()
		local profile,setProfile=UI.useState("default")
		local json,setJson=UI.useState("")
		local function report(title,ok,result)
			app:Notify({title=title,message=if ok then tostring(result or "Settings restored") else tostring(result),status=if ok then "success" else "error"})
		end
		return h("Column",{style={gap=18}}, {
			h("Text",{text="Your workspace, saved.",style={textSize=28,font="$typography.bold"}}),
			h("Paragraph",{text="Profiles include the selected design, effect intensity, reduced motion and registered control values."}),
			h("Section",{title="Profiles"}, {
				h("TextInput",{label="Profile name",value=profile,onChange=setProfile}),
				h("Row",{style={distribute="fill"}}, {
					h("Button",{text="Save profile",variant="primary",onClick=function() local ok,result=app.Config:Save(profile); report("Save profile",ok,result) end}),
					h("Button",{text="Load profile",onClick=function() local ok,result=app.Config:Load(profile); report("Load profile",ok,result) end}),
				}),
				h("Button",{text="Reset defaults",variant="ghost",onClick=function() app.Config:Reset() end}),
			}),
			h("Section",{title="JSON transfer",revealOrder=1}, {
				h("TextInput",{label="Profile JSON",value=json,onChange=setJson,multiline=true}),
				h("Row",{style={distribute="fill"}}, {
					h("Button",{text="Export JSON",onClick=function() local text,err=app.Config:Export(); if text then setJson(text) else report("Export failed",false,err) end end}),
					h("Button",{text="Import JSON",onClick=function() local ok,err=app.Config:Import(json); report("Import profile",ok,err) end}),
				}),
			}),
		})
	end
	local function DesignLab()
		local theme=UI.useTheme()
		local design,setDesign=bind("design")
		local intensity,setIntensity=bind("intensity")
		local reduced,setReduced=bind("reduced")
		local stageRef=UI.useRef(nil)
		local width,setWidth=UI.useState(700)
		UI.useEffect(function()
			local function measure() if stageRef.current and stageRef.current.AbsoluteSize.X>0 then setWidth(stageRef.current.AbsoluteSize.X) end end
			local connection=stageRef.current:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure); measure()
			return function() connection:Disconnect() end
		end,{})
		local split=width>=650
		local small=width<480
		return h("Column",{ref=stageRef,style={gap=18}}, {
			h("Text",{text="MATTLIB  /  DESIGN STUDIO",style={textSize=11,font=Enum.Font.Code,color="$accent"}}),
			h("Text",{text=headings[design],style={textSize=if design=="Vector" then 25 else 31,font="$typography.bold"}}),
			h("Paragraph",{text=descriptions[design]}),
			h("DesignPicker",{name="GalleryDesignPicker",presentation=if small then "dropdown" else "segments",label="Choose your design",value=design,onChange=setDesign}),
			h("Frame",{style={width="100%",height="auto",direction=if split then "row" else "column",gap=16,verticalAlign="start"}}, {
				h("Section",{name="DesignEffects",title="Feel & motion",style={width=if split then UDim.new(0.62,-8) else "100%"}}, {
					h("Toggle",{label="Smooth transitions",description="Window reveals, moving tab indicators and hover feedback.",value=not reduced,onChange=function(value) setReduced(not value) end}),
					h("Toggle",{label="Ambient effects",description="Accent halos and subtle window lighting.",value=intensity>0,onChange=function(value) setIntensity(if value then 1 else 0) end}),
					h("Slider",{name="DesignIntensity",label="Effect intensity",value=math.round(intensity*100),min=0,max=100,onChange=function(value) setIntensity(value/100) end,format=function(value) return value.."%" end}),
					h("Separator"),
					h("Text",{text="Interaction preview",style={font="$typography.medium"}}),
					h("Button",{name="DesignTryButton",text="Try interaction",variant="primary",onClick=function()
						app:Notify({title=theme.design.label,message="Hover, press, switch tabs and explore the controls.",status="success"})
					end}),
					h("Row",{style={distribute="fill"}}, {
						h("Button",{text="Show dialog",onClick=function() app:Confirm({title="A focused moment",message="This dialog shares the selected design.",onResult=function() end}) end}),
						h("Button",{text="Test notification",onClick=function() app:Notify({title="Theme ready",message="The entire application uses "..theme.design.label..".",status="success"}) end}),
					}),
					h("Toggle",{label="Reduced motion",value=reduced,onChange=setReduced}),
				}),
				h("Section",{name="CurrentDesign",revealOrder=1,style={width=if split then UDim.new(0.38,-8) else "100%",background="$profile",backgroundTransparency=0}}, {
					h("Text",{text="CURRENT DESIGN",style={font=Enum.Font.Code,textSize=11,color="$profileMuted"}}),
					h("Text",{text=theme.design.label,style={font="$typography.bold",textSize=28,color="$profileText"}}),
					h("Text",{text="M",style={font="$typography.bold",textSize=68,height=80,color="$accent"}}),
					h("Paragraph",{text=app:GetDesigns()[table.find(app.Designs,design)].description,style={color="$profileMuted",textSize=13}}),
					h("Separator"),
					h("Text",{text="CORNERS   "..theme.radius.md.." px\nCONTROLS  "..theme.controlHeight.." px\nREVEAL    "..math.round(theme.motion.reveal*1000).." ms",style={font=Enum.Font.Code,textSize=12,color="$profileText"}}),
					h("Button",{name="DesignApply",text="Save appearance",variant="primary",onClick=function()
						local ok,result=app.Config:Save("default")
						app:Notify({title=if ok then "Appearance saved" else "Save failed",message=tostring(result),status=if ok then "success" else "error"})
					end}),
				}),
			}),
			h("Section",{title="For scripters",revealOrder=2}, {
				h("Text",{text='local window = MattLib:CreateWindow({\n    Title = "My UI",\n    Design = "'..design..'",\n})\nwindow:SetDesign("Aura")',style={font=Enum.Font.Code,textSize=12,color="$muted"}}),
			}),
		})
	end

	local function App()
		return h("Window",{id="gallery",title="MattLib  /  Component Studio",size={1060,730},minSize=Vector2.new(300,260),openKey="RightShift"},
			h("Tabs",{orientation="design",defaultValue="designs",items={{id="designs",title="Designs",content=h(DesignLab)},{id="overview",title="Overview",content=h(Overview)},{id="inputs",title="Inputs & controls",content=h(Inputs)},
				{id="layout",title="Layout",content=h(Layouts)},{id="feedback",title="Feedback",content=h(FeedbackPanel)},{id="config",title="Configs",content=h(Configurations)}}}))
	end
	local root=UI.mount(h(App))
	return {library=app,root=root,Destroy=function() for _,disconnect in disconnects do disconnect() end; app:Destroy(); for _,signal in settings do signal:Destroy() end end}
end
