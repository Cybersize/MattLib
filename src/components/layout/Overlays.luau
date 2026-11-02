--!nonstrict
local Element = require(script.Parent.Parent.Parent.core.Element)
local Hooks = require(script.Parent.Parent.Parent.core.Hooks)
local Style = require(script.Parent.Parent.Parent.styling.StyleResolver)
local Scope = require(script.Parent.Parent.Parent.utils.Scope)
local Common = require(script.Parent.Parent.Common)
local h = Element.h
local Overlays = {}
local function fade(ref, open, present)
	local env=Hooks.useEnvironment()
	local mounted=Hooks.useRef(false)
	Hooks.useEffect(function()
		if not present or not ref.current then mounted.current=false; return end
		if not mounted.current then ref.current.GroupTransparency=1; mounted.current=true end
		local scope=Scope.new()
		local scale=ref.current:FindFirstChildOfClass("UIScale")
		if scale and open then scale.Scale=0.97 end
		scope:Add(env.animator:To(ref.current,{GroupTransparency=if open then 0 else 1},env.theme:Get().motion.normal))
		if scale then scope:Add(env.animator:To(scale,{Scale=if open then 1 else 0.97},env.theme:Get().motion.normal)) end
		return function() scope:Destroy() end
	end,{open,present})
end
function Overlays.Modal(p)
	local open,setOpen=Common.controllable(p,true,"open","onOpenChange","defaultOpen")
	local present=Common.presence(open)
	local env=Hooks.useEnvironment()
	local group,panel=Hooks.useRef(nil),Hooks.useRef(nil)
	local viewport=Hooks.useSignal(env.runtime.viewport)
	local content=Hooks.useRef(nil)
	local contentHeight,setContentHeight=Hooks.useState(120)
	local latest=Common.latest(function() if p.dismissible~=false then setOpen(false) end end)
	local z=Hooks.useMemo(function() return env.overlays:NextZ() end,{})
	fade(group,open,present)
	Hooks.useEffect(function()
		if not present then return end
		local scope=Scope.new()
		local function measure() if content.current then setContentHeight(content.current.AbsoluteSize.Y) end end
		scope:Connect(content.current:GetPropertyChangedSignal("AbsoluteSize"),measure); measure()
		return function() scope:Destroy() end
	end,{present})
	Hooks.useEffect(function()
		if not present or not open then return end
		return env.overlays:Attach(panel.current,function() latest.current() end,true,nil,z)
	end,{present,open})
	if not present then return nil end
	return Element.portal(h("@CanvasGroup",{ref=group,name=p.name or "Modal",style={width="100%",height="100%",zIndex=z}}, {
		h("@TextButton",{name="ModalBackdrop",native={Text="",Modal=true,Active=true},style={width="100%",height="100%",background="$overlay",backgroundTransparency=0.35},
			events={Activated=function() latest.current() end}}),
		h("Column",{ref=panel,style=Style.merge({width=UDim.new(1,-32),maxWidth=p.width or 440,height="auto",maxHeight=math.max(1,viewport.Y-16),
			position=UDim2.fromScale(0.5,0.5),anchor=Vector2.new(0.5,0.5),background="$surface",backgroundTransparency=0,
			borderWidth=1,borderColor="$border",radius="$radius.lg",padding="$spacing.xl",gap="$spacing.lg",zIndex=2},p.style)}, {
			p.title and h("Text",{text=p.title,style={textSize="$typography.title",font="$typography.bold"}}) or false,
			h("ScrollArea",{contentRef=content,style={height=math.max(1,math.min(contentHeight,viewport.Y-140))},contentStyle={gap=16}},p.children),
		}),
	}),env.runtime.layers.overlay)
end
function Overlays.Popover(p)
	local open,setOpen=Common.controllable(p,false,"open","onOpenChange","defaultOpen")
	local present=Common.presence(open)
	local env=Hooks.useEnvironment()
	local ownPanel=Hooks.useRef(nil)
	local panel=p.panelRef or ownPanel
	local content=Hooks.useRef(nil)
	local contentHeight,setContentHeight=Hooks.useState(32)
	local latest=Common.latest(function() setOpen(false) end)
	local z=Hooks.useMemo(function() return env.overlays:NextZ() end,{})
	local rect,setRect=Hooks.useState({x=16,y=16,width=p.width or 280,maxHeight=p.maxHeight or 320})
	local previous=Hooks.useRef(nil)
	Hooks.useEffect(function()
		if not present then return end
		local scope=Scope.new()
		local anchor=p.anchor and p.anchor.current
		local layer=env.runtime.layers.overlay
		local function position()
			local viewport,origin=layer.AbsoluteSize,layer.AbsolutePosition
			local width=math.max(1,math.min(p.width or (anchor and anchor.AbsoluteSize.X) or 280,viewport.X-16))
			local x,y,bottom=16,16,16
			if p.position then x,y=p.position.X-origin.X,p.position.Y-origin.Y; bottom=y
			elseif anchor then
				x,y=anchor.AbsolutePosition.X-origin.X,anchor.AbsolutePosition.Y-origin.Y
				bottom=y+anchor.AbsoluteSize.Y+6
			end
			local available=math.max(32,math.min(p.maxHeight or 320,viewport.Y-16))
			local actual=panel.current and panel.current.AbsoluteSize.Y or available
			local top=bottom
			if top+actual>viewport.Y-8 then top=math.max(8,y-math.min(actual,available)-6) end
			local nextRect={x=math.clamp(x,8,math.max(8,viewport.X-width-8)),y=top,width=width,maxHeight=math.max(1,math.min(available,viewport.Y-top-8))}
			local old=previous.current
			if not old or old.x~=nextRect.x or old.y~=nextRect.y or old.width~=nextRect.width or old.maxHeight~=nextRect.maxHeight then
				previous.current=nextRect; setRect(nextRect)
			end
		end
		if anchor then
			scope:Connect(anchor:GetPropertyChangedSignal("AbsolutePosition"),position)
			scope:Connect(anchor:GetPropertyChangedSignal("AbsoluteSize"),position)
		end
		scope:Connect(layer:GetPropertyChangedSignal("AbsoluteSize"),position)
		if panel.current then scope:Connect(panel.current:GetPropertyChangedSignal("AbsoluteSize"),position) end
		position()
		return function() scope:Destroy() end
	end,{present,p.width,p.maxHeight,p.position,p.anchor})
	fade(panel,open,present)
	Hooks.useEffect(function()
		if not present or p.scrollable==false then return end
		local scope=Scope.new()
		local function measure() if content.current then setContentHeight(content.current.AbsoluteSize.Y) end end
		scope:Connect(content.current:GetPropertyChangedSignal("AbsoluteSize"),measure); measure()
		return function() scope:Destroy() end
	end,{present,p.scrollable})
	Hooks.useEffect(function()
		if not present or not open then return end
		return env.overlays:Attach(panel.current,function() latest.current() end,false,p.anchor and p.anchor.current,z)
	end,{present,open,p.anchor})
	if not present then return nil end
	return Element.portal(h("@CanvasGroup",{ref=panel,name=p.name or "Popover",style=Style.merge({width=rect.width,height=if p.scrollable==false then "auto" else math.max(1,math.min(contentHeight,rect.maxHeight-16))+16,maxHeight=rect.maxHeight,
		position=UDim2.fromOffset(rect.x,rect.y),background="$raised",backgroundTransparency=0,borderWidth=1,borderColor="$border",
		radius="$radius.md",padding="$spacing.sm",direction="column",gap="$spacing.xs",zIndex=z,overflow="hidden",scale=1},p.style)},
		if p.scrollable==false then p.children else {h("ScrollArea",{contentRef=content,style={height=math.max(1,math.min(contentHeight,rect.maxHeight-16))},contentStyle={gap=4}},p.children)}),env.runtime.layers.overlay)
end
function Overlays.ConfirmationDialog(p)
	local open,setOpen=Common.controllable(p,true,"open","onOpenChange","defaultOpen")
	local answered=Hooks.useRef(false)
	Hooks.useEffect(function() if open then answered.current=false end end,{open})
	local function answer(value)
		if answered.current then return end
		answered.current=true; setOpen(false)
		if p.onResult then p.onResult(value) end
	end
	return h(Overlays.Modal,{name=p.name,title=p.title or "Confirm action",open=open,onOpenChange=function(nextOpen)
		if not nextOpen then answer(false) end
	end,dismissible=p.dismissible,width=p.width}, {
		h("Paragraph",{text=p.message or "Continue with this action?"}),
		h("Row",{style={distribute="fill"}}, {
			h("Button",{text=p.cancelText or "Cancel",onClick=function() answer(false) end}),
			h("Button",{text=p.confirmText or "Confirm",variant=p.danger and "danger" or "primary",onClick=function() answer(true) end}),
		}),
	})
end
function Overlays.ContextMenu(p)
	local open,setOpen=Hooks.useState(false)
	local point,setPoint=Hooks.useState(Vector2.new())
	return h(Element.Fragment,{}, {
		h("Frame",{name=p.name,style=p.style,events={InputBegan=function(_,input)
			if input.UserInputType==Enum.UserInputType.MouseButton2 and not p.disabled then setPoint(Vector2.new(input.Position.X,input.Position.Y)); setOpen(true) end
		end,TouchLongPress=function(_,positions,state)
			if state==Enum.UserInputState.End and positions[1] and not p.disabled then setPoint(positions[1]); setOpen(true) end
		end}},p.children),
		h(Overlays.Popover,{open=open,onOpenChange=setOpen,position=point,width=p.width or 220},
			Element.list(p.items or {},function(item)
				return h("Button",{text=item.label,disabled=item.disabled,variant="ghost",style={textAlign="left"},onClick=function()
					setOpen(false); if item.onSelect then item.onSelect() end
				end})
			end,function(item) return item.id or item.label end)),
	})
end
return Overlays
