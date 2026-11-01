return function(Library)
	local app=Library.new({id="mattlib-gallery",theme="Dark"})
	local UI=app.UI
	local h=UI.h
	local settings={enabled=UI.signal(true),checked=UI.signal(false),volume=UI.signal(64),range=UI.signal({20,80}),
		name=UI.signal("Workspace"),number=UI.signal(8),region=UI.signal("Singapore"),tags=UI.signal({"Design","Luau"}),
		color=UI.signal(app.Theme:Get().accent),key=UI.signal("F6"),radio=UI.signal("Balanced"),segment=UI.signal("Daily")}
	for id,signal in settings do app.Config:Register("gallery/"..id,signal,signal:get()) end
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
			h("Badge",{text="ASTER  /  COMPONENT STUDIO"}),
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
				h("Row",{}, {h("StatusIndicator",{status="success",text="Operational"}),h("StatusIndicator",{status="warning",text="Attention"}),h("Badge",{text="v1.0"})}),
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
	local function Appearance()
		local theme,setTheme=UI.useState("Dark"); local reduced,setReduced=UI.useState(false); local json,setJson=UI.useState("")
		return h("Column",{style={gap=16}}, {
			h("Text",{text="Make it yours",style={textSize=24,font="$typography.bold"}}),
			h("Section",{title="Appearance"}, {
				h("SegmentedControl",{label="Color theme",options={"Dark","Light"},value=theme,onChange=function(value) setTheme(value); app:SetTheme(value) end}),
				h("Toggle",{label="Reduce motion",description="Complete active transitions and stop looping animations.",value=reduced,onChange=function(value) setReduced(value); app:SetReducedMotion(value) end}),
				h("Button",{text="Use selected highlight color",onClick=function() app.Theme:Extend({accent=settings.color:get()}) end}),
			}),
			h("Section",{title="Configuration",description="Profiles use optional filesystem capabilities or an in-memory fallback."}, {
				h("Row",{style={distribute="fill"}}, {
					h("Button",{text="Export JSON",onClick=function() local text,err=app.Config:Export(); if text then setJson(text) else app:Notify({title="Export failed",message=err,status="error"}) end end}),
					h("Button",{text="Import JSON",onClick=function() local ok,err=app.Config:Import(json); app:Notify({title=if ok then "Imported" else "Import failed",message=err or "Settings restored",status=if ok then "success" else "error"}) end}),
				}),
				h("TextInput",{label="Profile JSON",value=json,onChange=setJson,multiline=true}),
				h("Button",{text="Reset defaults",onClick=function() app.Config:Reset() end}),
			}),
		})
	end
	local function App()
		return h("Window",{id="gallery",title="MattLib  /  Component Studio",size={940,650},minSize=Vector2.new(300,260),openKey="RightShift"},
			h("Sidebar",{items={{id="overview",title="Overview",content=h(Overview)},{id="inputs",title="Inputs & controls",content=h(Inputs)},
				{id="layout",title="Layout",content=h(Layouts)},{id="feedback",title="Feedback",content=h(FeedbackPanel)},{id="appearance",title="Appearance",content=h(Appearance)}}}))
	end
	local root=UI.mount(h(App))
	return {library=app,root=root,Destroy=function() app:Destroy(); for _,signal in settings do signal:Destroy() end end}
end
