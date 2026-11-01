--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Theme=require(script.Parent.Parent.Parent.styling.Theme)
local Common=require(script.Parent.Parent.Common)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local h=Element.h
local Window={}
local serial=0
function Window.ThemeProvider(p)
	local service=Hooks.useMemo(function() return if type(p.theme)=="table" and p.theme.signal then p.theme else Theme.new(p.theme or "Dark") end,{p.theme})
	Hooks.useEffect(function() return function() if service~=p.theme then service:Destroy() end end end,{service})
	return h(Element.Provider,{service=service},p.children)
end
local function WindowBase(p)
	local env=Hooks.useEnvironment()
	local frame,title,grip,handle=Hooks.useRef(nil),Hooks.useRef(nil),Hooks.useRef(nil),Hooks.useRef(nil)
	local visible,setVisible=Hooks.useState(p.defaultVisible~=false)
	local minimized,setMinimized=Hooks.useState(false)
	local closed,setClosed=Hooks.useState(false)
	local present=Common.presence(not closed)
	local id=Hooks.useMemo(function() serial+=1; return p.id or "window-"..serial end,{p.id})
	local latest=Common.latest(p)
	Hooks.useEffect(function()
		if not present then return end
		local entry=env.windows:Register({id=id,title=p.title,frame=frame.current,titlebar=title.current,grip=grip.current,size=p.size or {720,500},
			position=p.position,minSize=p.minSize,maxSize=p.maxSize,fixedSize=p.fixedSize,openKey=p.openKey,visible=visible,
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
		frame.current.GroupTransparency=1
		env.animator:To(frame.current,{GroupTransparency=0},env.theme:Get().motion.normal)
		return function() entry:Detach(); handle.current=nil; if p.windowRef then p.windowRef.current=nil end end
	end,{id,present})
	Hooks.useEffect(function()
		if closed and frame.current then return env.animator:To(frame.current,{GroupTransparency=1},env.theme:Get().motion.normal) end
	end,{closed})
	if not present then return nil end
	return h("@CanvasGroup",{ref=frame,name=p.name or "Window:"..id,role="window",accessibleName=p.title or "Application",native={Active=true},
		style=Style.merge({width=(p.size or {720,500})[1],height=(p.size or {720,500})[2],background="$background",backgroundTransparency=0,
			borderWidth=1,borderColor="$border",radius="$radius.lg",overflow="hidden",visible=visible},p.style)}, {
		h("Frame",{ref=title,name="WindowTitlebar",native={Active=true,Selectable=true},accessibleName="Move window with arrow keys",
			style={width="100%",height=44,background="$surface",backgroundTransparency=0}}, {
			h("Text",{text=p.title or "Application",style={position=UDim2.fromOffset(16,0),width=UDim.new(1,-142),height=44,font="$typography.medium",wrapped=false},native={TextTruncate=Enum.TextTruncate.AtEnd}}),
			h("Button",{name="WindowMinimize",text=if minimized then "▢" else "−",variant="ghost",accessibleName=if minimized then "Restore window" else "Minimize window",
				style={width=34,height=30,position=UDim2.new(1,-114,0,7)},onClick=function() if handle.current then if minimized then handle.current:Restore() else handle.current:Minimize() end end end}),
			h("Button",{name="WindowHide",text="⌄",variant="ghost",accessibleName="Hide window",style={width=34,height=30,position=UDim2.new(1,-78,0,7)},
				onClick=function() if handle.current then handle.current:Hide() end end}),
			h("Button",{name="WindowClose",text="×",variant="ghost",accessibleName="Close window",style={width=34,height=30,position=UDim2.new(1,-42,0,7),hover={color="$danger",background="$hover"}},
				onClick=function() if handle.current then handle.current:Close() end end}),
		}),
		h("Separator",{style={position=UDim2.fromOffset(0,44)}}),
		h("Frame",{name="WindowContent",style={width="100%",height=UDim.new(1,-45),position=UDim2.fromOffset(0,45),visible=not minimized}},p.children),
		h("Button",{ref=grip,name="WindowResize",text="◢",variant="ghost",accessibleName="Resize window with arrow keys",
			style={width=28,height=28,position=UDim2.new(1,-28,1,-28),visible=not p.fixedSize and not minimized,textSize=12,paddingX=0,zIndex=5}}),
	})
end
function Window.Window(p)
	local env=Hooks.useEnvironment()
	return h(Window.ThemeProvider,{theme=p.theme or env.theme},h(WindowBase,p))
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
