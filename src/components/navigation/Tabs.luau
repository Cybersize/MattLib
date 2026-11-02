--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Scope=require(script.Parent.Parent.Parent.utils.Scope)
local Common=require(script.Parent.Parent.Common)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local h=Element.h
local Tabs={}
local function Panel(p)
	local env=Hooks.useEnvironment()
	local theme=Hooks.useTheme()
	local ref,content=Hooks.useRef(nil),Hooks.useRef(nil)
	local present=Common.presence(p.active,theme.motion.tab)
	Hooks.useEffect(function()
		if not present then return end
		local scope=Scope.new()
		if p.active then content.current.Position=UDim2.fromOffset(theme.motion.distance,0) end
		scope:Add(env.animator:Fade(ref.current,if p.active then 1 else 0,theme.motion.tab,{from=if p.active then 0 else nil}))
		scope:Add(env.animator:To(content.current,{Position=UDim2.fromOffset(if p.active then 0 else -theme.motion.distance,0)},theme.motion.tab,{channel="tab"}))
		return function() scope:Destroy() end
	end,{p.active,present,theme.design.name})
	return h("@Frame",{ref=ref,motion=false,attributes={MattTab=p.id,MattActive=p.active},style={width="100%",height="100%",visible=present,zIndex=if p.active then 3 else 2,overflow="hidden"}}, {
		h("Frame",{ref=content,style={width="100%",height="100%"}},p.children),
	})
end
function Tabs.Tab() error("Tab must be a direct child of Tabs or Sidebar",2) end
function Tabs.Tabs(p)
	local items=p.items
	if not items then
		items={}
		for _,child in p.children do
			assert(child.type=="Tab" or child.type==Tabs.Tab,"Tabs children must be Tab elements")
			local props=child.props
			table.insert(items,{id=props.id or props.title,title=props.title,disabled=props.disabled,content=props.children})
		end
	end
	local seen,first={}
	for _,item in items do
		assert(item.id~=nil and not seen[item.id],"Tab ids must be unique"); seen[item.id]=true
		if not first and not item.disabled then first=item.id end
	end
	local value,setValue=Common.controllable(p,first)
	local env=Hooks.useEnvironment()
	local theme=Hooks.useTheme()
	local viewport=Hooks.useSignal(env.runtime.viewport)
	local frame=Hooks.useRef(nil)
	local available,setAvailable=Hooks.useState(viewport.X)
	Hooks.useEffect(function()
		local function measure() if frame.current.AbsoluteSize.X>0 then setAvailable(math.floor(frame.current.AbsoluteSize.X)) end end
		local connection=frame.current:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure); measure()
		return function() connection:Disconnect() end
	end,{})
	local layout=if p.orientation==nil or p.orientation=="design" then theme.design.navigation else p.orientation
	local side=(layout=="sidebar" or layout=="tree") and math.min(available,viewport.X)>=640
	if not side and layout~="pills" then layout="top" end
	local width=p.sidebarWidth or math.min(theme.design.sidebarWidth,if available<900 then 148 else 176)
	local height=if layout=="pills" then theme.design.navHeight else (if side then 0 else 44)
	local selected=value
	if not seen[selected] then selected=first end
	local refs=Hooks.useRef({})
	local nav,indicator=Hooks.useRef(nil),Hooks.useRef(nil)
	for _,item in items do refs.current[item.id]=refs.current[item.id] or {} end
	for id in refs.current do if not seen[id] then refs.current[id]=nil end end
	Hooks.useEffect(function()
		local scope=Scope.new()
		local selectedRef=refs.current[selected]
		local button=selectedRef and selectedRef.current
		local target=indicator.current
		if not button or not nav.current or not target then return end
		local function place()
			local origin,size=nav.current.AbsolutePosition,nav.current.AbsoluteSize
			local pos,extent=button.AbsolutePosition,button.AbsoluteSize
			if extent.X<=0 or extent.Y<=0 then return end
			local x,y,w,hh=pos.X-origin.X,pos.Y-origin.Y,extent.X,extent.Y
			if side and theme.design.indicator=="rail" then x,w,y,hh=2,3,y+7,math.max(4,hh-14)
			elseif not side and layout~="pills" then x,w,y,hh=x+10,math.max(4,w-20),y+hh-2,2 end
			target.Visible=x+w>0 and y+hh>0 and x<size.X and y<size.Y
			scope:Remove(scope.motion,false)
			if scope.motion then scope.motion() end
			scope.motion=scope:Add(env.animator:To(target,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,hh)},theme.motion.tab,{channel="indicator"}))
		end
		scope:Connect(button:GetPropertyChangedSignal("AbsolutePosition"),place)
		scope:Connect(button:GetPropertyChangedSignal("AbsoluteSize"),place)
		scope:Connect(nav.current:GetPropertyChangedSignal("AbsolutePosition"),place)
		scope:Connect(nav.current:GetPropertyChangedSignal("AbsoluteSize"),place)
		place()
		return function() scope:Destroy() end
	end,{selected,layout,side,width,height,theme.design.name,#items})
	local navigation=Element.list(items,function(item)
		local active=selected==item.id
		local block=layout=="tree"
		local icon=side and item.icon and not block
		return h("Button",{name="Tab:"..tostring(item.id),ref=refs.current[item.id],text=if icon then "" else (if block then "›  " else "")..(item.title or tostring(item.id)),
			disabled=item.disabled,variant="ghost",active=active,style={width=if side then "100%" else p.tabWidth or math.clamp((available-32)/math.max(1,#items),88,126),height=if block then 32 else 40,
				textAlign=if side then "left" else "center",radius=if layout=="pills" then "$radius.pill" else "$radius.md",scale=1,
				paddingX=if side then 12 else 8,textSize=13,borderWidth=0,
				color=if active and (block or layout=="pills") then "$accentText" elseif active then "$accent" else "$muted",
				active={background=if block then "$accent" else "$accentSoft",backgroundTransparency=if layout=="pills" then 1 elseif side then 0.28 else 1},
				hover={background=if active and block then "$accent" else "$hover",backgroundTransparency=if layout=="pills" and active then 1 else 0,scale=1},pressed={scale=0.98}},
			onClick=function() setValue(item.id) end,accessibleName=(item.title or tostring(item.id))..(if active then ", selected tab" else ", tab")},if icon then {
				h("Icon",{symbol=item.icon,size=20,color=if active then "$accent" else "$muted",style={position=UDim2.new(0,0,0.5,-10)}}),
				h("Text",{text=item.title or tostring(item.id),style={width=UDim.new(1,-30),height="100%",position=UDim2.fromOffset(30,0),textSize=13,wrapped=false,color=if active then "$text" else "$muted"}}),
			} else {})
	end,function(item) return item.id end)
	local panels=Element.list(items,function(item)
		return h(Panel,{active=selected==item.id,id=item.id},if p.unmountInactive and selected~=item.id then {} else {
			h("ScrollArea",{contentStyle={padding=p.padding or (if available<900 then 14 else 22),gap=12}},item.content or {}),
		})
	end,function(item) return item.id end)
	local inset=if layout=="pills" then theme.design.inset else 0
	local treeHeader=if side then 32 else 0
	local footer=if side then 64 else 0
	return h("Frame",{name=p.name,ref=frame,style=Style.merge({width="100%",height="100%"},p.style),attributes={MattNavigation=layout}}, {
		h("Frame",{name="TabNavigation",ref=nav,style={width=if side then width else UDim.new(1,-inset*2),height=if side then "100%" else height,
			position=UDim2.fromOffset(inset,if layout=="pills" then 8 else 0),background=if layout=="pills" then "$raised" else "$chrome",
			backgroundTransparency=if layout=="pills" then 0.18 else 0.28,radius=if layout=="pills" then "$radius.pill" else 0,overflow="hidden"}}, {
			h("Text",{text="WORKSPACE",style={height=treeHeader,visible=treeHeader>0,paddingX=16,textSize=10,font=Enum.Font.Code,color="$subtle"}}),
			h("Frame",{ref=indicator,name="TabIndicator",motion=false,native={Size=UDim2.new(),Visible=false},
				style={background="$accent",backgroundTransparency=0,radius=if layout=="pills" then "$radius.pill" else "$radius.sm",zIndex=if layout=="pills" or layout=="tree" then 1 else 3}}),
			h("ScrollArea",{name="TabNavigationScroll",style={width="100%",height=UDim.new(1,-treeHeader-footer),position=UDim2.fromOffset(0,treeHeader),zIndex=2},
				contentStyle={direction=if side then "column" else "row",width=if side then UDim.new(1,-16) else (if available>=#items*88+32 then "100%" else "auto"),
					horizontalAlign=if side then "start" else "center",gap=4,padding=if side then {4,4,4,8} else 4},
				native={AutomaticCanvasSize=if side then Enum.AutomaticSize.Y else Enum.AutomaticSize.X,ScrollingDirection=if side then Enum.ScrollingDirection.Y else Enum.ScrollingDirection.X}},navigation),
			h("Column",{name="NavigationFooter",style={height=footer,visible=side,width=UDim.new(1,-28),position=UDim2.new(0,14,1,-footer),gap=5,paddingY=10}}, {
				h("Separator",{style={backgroundTransparency=0.5}}),
				h("Text",{text="●  Local workspace",style={textSize=11,color="$muted"}}),
				h("Text",{text=theme.design.label.."  /  v1.2.1",style={textSize=10,font=Enum.Font.Code,color="$subtle"}}),
			}),
		}),
		h("Frame",{name="TabPanels",style={width=if side then UDim.new(1,-width-8) else "100%",height=if side then "100%" else UDim.new(1,-height-inset),
			position=if side then UDim2.fromOffset(width+8,0) else UDim2.fromOffset(0,height+inset)}},panels),
	})
end
function Tabs.Sidebar(p)
	local copy=table.clone(p); copy.orientation="sidebar"
	return h(Tabs.Tabs,copy)
end
return Tabs
