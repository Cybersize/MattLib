--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Theme=require(script.Parent.Parent.Parent.styling.Theme)
local Designs=require(script.Parent.Parent.Parent.styling.Designs)
local Common=require(script.Parent.Parent.Common)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local h=Element.h
local Window={}
local serial=0
function Window.ThemeProvider(p)
	local inherited=Hooks.useEnvironment().theme
	local external=if type(p.theme)=="table" and p.theme.signal then p.theme else nil
	local source=external or inherited
	local tokens=Hooks.useSignal(source.signal)
	local localStyle=p.design~=nil or (p.theme~=nil and not external)
	local tokenKey=if localStyle and (external or not p.design) then tokens else false
	local service=Hooks.useMemo(function()
		if not localStyle then return source end
		local name=p.design or tokens.design.name
		local palette=if external then tokens else p.theme
		return Theme.new(if name=="Classic" then palette or tokens else Designs.resolve(name,palette))
	end,{p.design,p.theme,source,tokenKey})
	Hooks.useEffect(function() return function() if service~=source then service:Destroy() end end end,{service})
	return h(Element.Provider,{service=service},p.children)
end
local function WindowBase(p)
	local env=Hooks.useEnvironment()
	local theme=Hooks.useTheme()
	local header=theme.design.titleHeight
	local frame,title,grip,handle,chrome=Hooks.useRef(nil),Hooks.useRef(nil),Hooks.useRef(nil),Hooks.useRef(nil),Hooks.useRef(nil)
	local visible,setVisible=Hooks.useState(p.defaultVisible~=false)
	local minimized,setMinimized=Hooks.useState(false)
	local closed,setClosed=Hooks.useState(false)
	local present=Common.presence(not closed,theme.motion.reveal)
	local id=Hooks.useMemo(function() serial+=1; return p.id or "window-"..serial end,{p.id})
	local latest=Common.latest(p)
	Hooks.useEffect(function()
		if not present then return end
		local entry=env.windows:Register({id=id,title=p.title,frame=frame.current,titlebar=title.current,grip=grip.current,size=p.size or {760,540},
			position=p.position,minSize=p.minSize,maxSize=p.maxSize,fixedSize=p.fixedSize,openKey=p.openKey,visible=visible,titleHeight=header,
			onVisible=function(show) setVisible(show); if latest.current.onVisibleChange then latest.current.onVisibleChange(show) end end,
			onMinimized=setMinimized,onMove=p.onMove,onResize=p.onResize,onClose=function()
				setClosed(true); if latest.current.onClose then latest.current.onClose() end
			end})
		handle.current=entry
		if p.windowRef then p.windowRef.current=entry end
		if p.onReady then
			local ok,err=pcall(p.onReady,entry)
			if not ok then entry:Detach(); if p.windowRef then p.windowRef.current=nil end; error(err,0) end
		end
		return function() entry:Detach(); handle.current=nil; if p.windowRef then p.windowRef.current=nil end end
	end,{id,present})
	Hooks.useEffect(function() if handle.current then handle.current:SetTitleHeight(header) end end,{header})
	Hooks.useEffect(function()
		if not present or not chrome.current then return end
		local instance=chrome.current
		if visible and not closed then
			instance.GroupTransparency=1
			instance.Position=UDim2.new(0.5,0,0.5,theme.motion.distance)
		end
		return env.animator:To(instance,{GroupTransparency=if closed then 1 else 0,
			Position=UDim2.new(0.5,0,0.5,if closed then theme.motion.distance else 0)},theme.motion.reveal,{channel="presence"})
	end,{present,visible,closed,theme.design.name})
	if not present then return nil end
	local glow=theme.effects.glow*theme.effects.intensity
	local ambient=theme.effects.ambient*theme.effects.intensity
	local chromeStyle=Style.merge({width="100%",height="100%",background="$background",backgroundTransparency=0,
		borderWidth=1,borderColor="$border",radius="$radius.lg",overflow="hidden",position=UDim2.fromScale(0.5,0.5),anchor=Vector2.new(0.5,0.5)},p.style)
	return h("@Frame",{ref=frame,name=p.name or "Window:"..id,role="window",accessibleName=p.title or "Application",native={Active=true},
		attributes={MattDesign=theme.design.name},style={width=(p.size or {760,540})[1],height=(p.size or {760,540})[2],visible=visible,
			backgroundTransparency=1,radius="$radius.lg",glow=if glow>0 then (if closed then 0 else glow*0.5) else nil}}, {
		h("@CanvasGroup",{ref=chrome,name="WindowChrome",motion=false,style=chromeStyle}, {
			h("Frame",{name="WindowAtmosphere",style={width="100%",height="100%",background="$accent",backgroundTransparency=1-ambient,
				gradient={from="$accent",to="$background",rotation=if theme.design.name=="Aura" then 135 else 45,transparency={0.7,1}},zIndex=0}}),
			h("Frame",{ref=title,name="WindowTitlebar",native={Active=true,Selectable=true},accessibleName="Move window with arrow keys",
				style={width="100%",height=header,background="$chrome",backgroundTransparency=0.05,zIndex=2}}, {
				h("Text",{text="M",style={position=UDim2.fromOffset(14,0),width=24,height=header,font="$typography.bold",textSize=22,color="$accent",textAlign="center"}}),
				h("Text",{text=p.title or "MattLib",style={position=UDim2.fromOffset(48,0),width=UDim.new(1,-184),height=header,font="$typography.medium",wrapped=false},native={TextTruncate=Enum.TextTruncate.AtEnd}}),
				h("Button",{name="WindowMinimize",text=if minimized then "▢" else "−",variant="ghost",accessibleName=if minimized then "Restore window" else "Minimize window",
					style={width=30,height=28,position=UDim2.new(1,-106,0,(header-28)/2),paddingX=0},onClick=function() if handle.current then if minimized then handle.current:Restore() else handle.current:Minimize() end end end}),
				h("Button",{name="WindowHide",text="⌄",variant="ghost",accessibleName="Hide window",style={width=30,height=28,position=UDim2.new(1,-72,0,(header-28)/2),paddingX=0},
					onClick=function() if handle.current then handle.current:Hide() end end}),
				h("Button",{name="WindowClose",text="×",variant="ghost",accessibleName="Close window",style={width=30,height=28,position=UDim2.new(1,-38,0,(header-28)/2),paddingX=0,hover={color="$danger",background="$hover"}},
					onClick=function() if handle.current then handle.current:Close() end end}),
			}),
			h("Separator",{style={position=UDim2.fromOffset(0,header),zIndex=3}}),
			h("Frame",{name="WindowContent",style={width="100%",height=UDim.new(1,-header-1),position=UDim2.fromOffset(0,header+1),visible=not minimized,zIndex=2}},p.children),
			h("Button",{ref=grip,name="WindowResize",text="◢",variant="ghost",accessibleName="Resize window with arrow keys",
				style={width=26,height=26,position=UDim2.new(1,-26,1,-26),visible=not p.fixedSize and not minimized,textSize=12,paddingX=0,zIndex=5}}),
		}),
	})
end
function Window.Window(p)
	return h(Window.ThemeProvider,{theme=p.theme,design=p.design},h(WindowBase,p))
end
function Window.RecoveryHost()
	local env=Hooks.useEnvironment()
	local hidden=Hooks.useSignal(env.windows.hidden)
	local viewport=Hooks.useSignal(env.runtime.viewport)
	if #hidden==0 then return nil end
	return h("Frame",{name="RestoreWindows",style={width=170,height=math.min(#hidden*44,math.max(44,viewport.Y-16)),position=UDim2.new(0,8,1,-8),anchor=Vector2.new(0,1),zIndex=1000000}}, {
		h("ScrollArea",{contentStyle={gap=6}},Element.list(hidden,function(entry)
			return h("Button",{text="↗  "..(entry.options.title or entry.id),onClick=function() entry:Restore() end,accessibleName="Restore "..(entry.options.title or entry.id)})
		end,function(entry) return entry.id end)),
	})
end
return Window
