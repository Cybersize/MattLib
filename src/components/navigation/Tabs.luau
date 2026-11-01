--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Common=require(script.Parent.Parent.Common)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local h=Element.h
local Tabs={}
local function Panel(p)
	local env=Hooks.useEnvironment()
	local ref=Hooks.useRef(nil)
	Hooks.useEffect(function()
		if p.active then
			ref.current.GroupTransparency=0.2
			return env.animator:To(ref.current,{GroupTransparency=0},env.theme:Get().motion.fast)
		end
	end,{p.active})
	return h("@CanvasGroup",{ref=ref,style={width="100%",height="100%",visible=p.active}},p.children)
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
	local seen={}
	for _,item in items do assert(item.id~=nil and not seen[item.id],"Tab ids must be unique"); seen[item.id]=true end
	local value,setValue=Common.controllable(p,items[1] and items[1].id)
	local env=Hooks.useEnvironment()
	local viewport=Hooks.useSignal(env.runtime.viewport)
	local sidebar=(p.orientation=="sidebar") and viewport.X>=600
	local selected=value
	if not seen[selected] then selected=items[1] and items[1].id end
	local navigation=Element.list(items,function(item)
		return h("Button",{name="Tab:"..tostring(item.id),text=item.title or tostring(item.id),disabled=item.disabled,variant="ghost",active=selected==item.id,
			style={width=if sidebar then "100%" else p.tabWidth or 120,height=38,textAlign=if sidebar then "left" else "center",
				active={background="$hover",backgroundTransparency=0,color="$accent"}},
			onClick=function() setValue(item.id) end,accessibleName=(item.title or tostring(item.id))..(if selected==item.id then ", selected tab" else ", tab")})
	end,function(item) return item.id end)
	local panels=Element.list(items,function(item)
		return h(Panel,{active=selected==item.id},if p.unmountInactive and selected~=item.id then {} else {
			h("ScrollArea",{contentStyle={padding=p.padding or 16,gap=16}},item.content or {}),
		})
	end,function(item) return item.id end)
	return h("Frame",{name=p.name,style=Style.merge({width="100%",height="100%"},p.style)}, {
		h("ScrollArea",{name="TabNavigation",style={width=if sidebar then p.sidebarWidth or 168 else "100%",height=if sidebar then "100%" else 44},
			contentStyle={direction=if sidebar then "column" else "row",gap=4,padding=4},
			native={AutomaticCanvasSize=if sidebar then Enum.AutomaticSize.Y else Enum.AutomaticSize.X,
				ScrollingDirection=if sidebar then Enum.ScrollingDirection.Y else Enum.ScrollingDirection.X}},navigation),
		h("Frame",{name="TabPanels",style={width=if sidebar then UDim.new(1,-(p.sidebarWidth or 168)-8) else "100%",height=if sidebar then "100%" else UDim.new(1,-48),
			position=if sidebar then UDim2.fromOffset((p.sidebarWidth or 168)+8,0) else UDim2.fromOffset(0,48)}},panels),
	})
end
function Tabs.Sidebar(p)
	local copy=table.clone(p); copy.orientation="sidebar"
	return h(Tabs.Tabs,copy)
end
return Tabs
