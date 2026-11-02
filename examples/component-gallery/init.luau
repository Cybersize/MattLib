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
		return h("Column",{style={gap=12}}, {
			h("Text",{text="Inputs & controls",style={textSize=24,font="$typography.bold"}}),
			h("AdaptiveGrid",{name="GalleryControlsGrid",minColumnWidth=230,gap=12}, {
			h("Section",{key="boolean",title="Boolean controls"}, {
				h("Toggle",{name="GalleryToggle",label="Notifications",description="Share state across controls.",value=enabled,onChange=setEnabled}),
				h("Separator",{style={backgroundTransparency=0.45}}),
				h("Checkbox",{label="Experimental features",value=checked,onChange=setChecked}),
				h("Toggle",{label="Unavailable setting",disabled=true,value=false}),
			}),
			h("Section",{key="continuous",title="Continuous values",revealOrder=1}, {
				h("Slider",{label="Output level",min=0,max=100,value=volume,onChange=setVolume,format=function(n) return n.."%" end}),
				h("RangeSlider",{label="Operating range",min=0,max=100,value=range,onChange=setRange}),
				h("StatusIndicator",{text="Live values",status="success"}),
			}),
			h("Section",{key="text",title="Workspace",revealOrder=2}, {
				h("TextInput",{label="Workspace name",value=name,onChange=setName,maxLength=48}),
				h("NumericInput",{label="Concurrency",min=1,max=32,step=1,value=number,onChange=setNumber}),
				h("SegmentedControl",{label="Time period",options={"Daily","Weekly","Monthly"},value=segment,onChange=setSegment}),
			}),
			h("Section",{key="selection",title="Selection",revealOrder=3}, {
				h("Dropdown",{label="Region",options={"Singapore","Tokyo","Frankfurt","Virginia"},value=region,onChange=setRegion}),
				h("SearchableDropdown",{label="Search regions",options={"Singapore","Tokyo","Frankfurt","Virginia","Sydney","London","Mumbai"},value=region,onChange=setRegion}),
				h("MultiSelect",{label="Project tags",options={"Design","Luau","Research","Testing","Release"},value=tags,onChange=setTags}),
			}),
			h("Section",{key="special",title="Personalization",revealOrder=4}, {
				h("ColorPicker",{label="Highlight color",value=color,onChange=setColor}),
				h("Keybind",{label="Quick action",value=key,onChange=setKey,onTrigger=function() app:Notify({title="Keybind",message="Your configured keyboard shortcut fired."}) end}),
			}),
			h("Section",{key="profile",title="Performance",revealOrder=5}, {
				h("RadioGroup",{label="Performance profile",options={"Economy","Balanced","Performance"},value=radio,onChange=setRadio}),
			}),
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
				h("Row",{}, {h("StatusIndicator",{status="success",text="Operational"}),h("StatusIndicator",{status="warning",text="Attention"}),h("Badge",{text="v1.2"})}),
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
		local color,setColor=bind("color")
		local surface=if theme.background.R+theme.background.G+theme.background.B>1.5 then "Light" else "Dark"
		local profileTheme=UI.useMemo(function()
			return UI.mergeStyles(theme,if design=="Ember" then {text=theme.profileText,muted=theme.profileMuted,
				input=Color3.fromRGB(242,234,219),raised=Color3.fromRGB(231,221,204),border=Color3.fromRGB(199,187,168),
				hover=Color3.fromRGB(224,212,193),pressed=Color3.fromRGB(214,199,177)} else {})
		end,{theme,design})
		local split=width>=500
		local small=width<400
		local function showNotification() app:Notify({title="Appearance updated",message=theme.design.label.." is ready.",status="success"}) end
		return h("Column",{ref=stageRef,style={gap=12}}, {
			h("Text",{text="APPEARANCE  /  "..string.upper(theme.design.label),style={textSize=10,font=Enum.Font.Code,color="$accent"}}),
			h("Text",{text=headings[design],style={textSize=if small then 25 elseif design=="Vector" then 28 else 34,font="$typography.bold"}}),
			h("Paragraph",{text=descriptions[design],style={textSize=15}}),
			h("DesignPicker",{name="GalleryDesignPicker",presentation=if small then "dropdown" else "segments",value=design,onChange=setDesign}),
			h("Frame",{style={width="100%",height="auto",direction=if split then "row" else "column",gap=12,verticalAlign="start"}}, {
				h("Section",{name="DesignEffects",title="Visual effects",style={width=if split then UDim.new(0.55,-6) else "100%",padding=14,gap=6}}, {
					h("Separator",{style={backgroundTransparency=0.35}}),
					h("Toggle",{label="Interface motion",description="Animated reveals & feedback.",value=not reduced,onChange=function(value) setReduced(not value) end}),
					h("Separator",{style={backgroundTransparency=0.6}}),
					h("Toggle",{label="Live wallpaper",description="Ribbons, light & moving layers.",value=intensity>0,onChange=function(value) setIntensity(if value then 1 else 0) end}),
					h("Separator",{style={backgroundTransparency=0.6}}),
					h("Toggle",{label="Reduced motion",value=reduced,onChange=setReduced}),
					h("Separator",{style={backgroundTransparency=0.35}}),
					h("Slider",{name="DesignIntensity",label="Effect intensity",value=math.round(intensity*100),min=0,max=100,onChange=function(value) setIntensity(value/100) end,format=function(value) return value.."%" end,style={paddingX=0}}),
				}),
				h("ThemeProvider",{theme=profileTheme},h("Section",{name="CurrentDesign",title=if design=="Ember" then "Your profile" else "Accent & surface",revealOrder=1,
				style={width=if split then UDim.new(0.45,-6) else "100%",background=if design=="Ember" then "$profile" else "$surface",backgroundTransparency=if design=="Ember" then 0 else 0.24,padding=14,gap=10}}, {
					h("Frame",{name="WallpaperPreview",style={height=112,background="$background",backgroundTransparency=0,radius="$radius.md",borderWidth=1,borderColor="$border",overflow="hidden"}}, {
						h("Wallpaper",{opacity=1}),
						h("Frame",{style={width="56%",height=86,position=UDim2.fromOffset(12,13),background="$raised",backgroundTransparency=0.18,radius="$radius.md",borderWidth=1,borderColor="$border"}}, {
							h("Text",{text="M",style={width=34,height=40,position=UDim2.fromOffset(12,8),textSize=32,font="$typography.bold",color="$accent"}}),
							h("Frame",{style={width="40%",height=6,position=UDim2.new(0,50,0,20),background="$muted",backgroundTransparency=0.55,radius=3}}),
							h("Frame",{style={width="28%",height=5,position=UDim2.new(0,50,0,33),background="$muted",backgroundTransparency=0.75,radius=3}}),
							h("Frame",{style={width="60%",height=16,position=UDim2.fromOffset(12,56),background="$accent",backgroundTransparency=0,radius=4}}),
						}),
					}),
					h("ColorPicker",{label="Highlight color",value=color,onChange=setColor}),
					h("Dropdown",{label="Surface",options={"Dark","Light"},value=surface,onChange=function(value) app:SetTheme(value); app:SetEffectIntensity(intensity) end}),
					h("Text",{text=theme.design.label.."  /  "..math.round(theme.motion.reveal*1000).." ms reveal",style={font=Enum.Font.Code,textSize=10,color=if design=="Ember" then "$profileMuted" else "$muted"}}),
				})),
			}),
			h("Section",{title="Preview",revealOrder=2,style={padding=14,gap=10}}, {
				h("StatusIndicator",{text="Live workspace",status="success"}),
				h("Row",{style={distribute="fill",gap=10,wrap=true}}, {
					h("Button",{name="DesignApply",text="Apply appearance  ›",variant="primary",style={width=if small then "100%" else UDim.new(0.55,-5)},onClick=function()
						local ok,result=app.Config:Save("default")
						app:Notify({title=if ok then "Appearance updated" else "Save failed",message=if ok then "Your appearance is saved." else tostring(result),status=if ok then "success" else "error"})
					end}),
					h("Button",{name="DesignTryButton",text="Test interaction",style={width=if small then "100%" else UDim.new(0.45,-5)},onClick=showNotification}),
				}),
			}),
			h("CollapsibleSection",{title="For scripters",defaultOpen=false,style={padding=12}}, {
				h("Text",{text='local window = MattLib:CreateWindow({\n    Title = "My UI", Design = "'..design..'",\n})\nlocal tab = window:AddTab({Title = "Main", Columns = 2})',style={font=Enum.Font.Code,textSize=12,color="$muted"}}),
			}),
		})
	end

	local function App()
		return h("Window",{id="gallery",title="MattLib  /  Component Studio",size={1060,700},minSize=Vector2.new(300,260),openKey="RightShift"},
			h("Tabs",{orientation="design",defaultValue=options.page or "designs",items={{id="designs",title="Appearance",icon="appearance",content=h(DesignLab)},{id="overview",title="Overview",icon="home",content=h(Overview)},{id="inputs",title="Controls",icon="controls",content=h(Inputs)},
				{id="layout",title="Layout",icon="layout",content=h(Layouts)},{id="feedback",title="Feedback",icon="activity",content=h(FeedbackPanel)},{id="config",title="Configs",icon="settings",content=h(Configurations)}}}))
	end
	local root=UI.mount(h(App))
	return {library=app,root=root,Destroy=function() for _,disconnect in disconnects do disconnect() end; app:Destroy(); for _,signal in settings do signal:Destroy() end end}
end
