--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local Scope=require(script.Parent.Parent.Parent.utils.Scope)
local Common=require(script.Parent.Parent.Common)
local h=Element.h
local Feedback={}
local statuses={success="$success",warning="$warning",error="$danger",info="$accent",idle="$subtle"}
function Feedback.StatusIndicator(p)
	local color=statuses[p.status or "info"]
	assert(color,"Unknown status")
	return h("Row",{name=p.name,style=Style.merge({width="auto",height=24,gap=6},p.style)}, {
		h("Frame",{style={width=7,height=7,radius="$radius.pill",background=color,backgroundTransparency=0}}),
		p.text and h("Text",{text=p.text,style={width="auto",height=24,color="$muted",textSize=12}}) or false,
	})
end
function Feedback.ProgressBar(p)
	local value=p.value or 0
	assert(Common.finite(value),"Progress value must be finite")
	value=math.clamp(value,0,1)
	return h("Column",{name=p.name,style=p.style}, {
		p.label and h("Text",{text=p.label.."  "..math.round(value*100).."%",style={textSize=12,color="$muted"}}) or false,
		h("Frame",{role="progressbar",accessibleName=p.label,accessibleValue=tostring(value),style={height=p.height or 6,background="$input",backgroundTransparency=0,radius="$radius.pill",overflow="hidden"}}, {
			h("Frame",{motion=true,style={width=UDim.new(value,0),height="100%",background=p.color or "$accent",backgroundTransparency=0,radius="$radius.pill"}}),
		}),
	})
end
function Feedback.LoadingIndicator(p)
	local env=Hooks.useEnvironment()
	local ref=Hooks.useRef(nil)
	Hooks.useEffect(function()
		return env.animator:To(ref.current,{Rotation=360},0.9,{repeatCount=-1,easing=Enum.EasingStyle.Linear})
	end,{})
	return h("Row",{name=p.name,style=Style.merge({width="auto",height=28},p.style)}, {
		h("Text",{ref=ref,text="◌",style={width=22,height=22,textSize=22,textAlign="center",color="$accent"}}),
		h("Text",{text=p.text or "Loading…",style={width="auto",height=28,color="$muted"}}),
	})
end
function Feedback.Tooltip(p)
	local open,setOpen=Hooks.useState(false)
	local ref=Hooks.useRef(nil)
	local scope=Common.scope()
	local pending=Hooks.useRef(nil)
	local env=Hooks.useEnvironment()
	local function hide()
		if pending.current then pending.current(); pending.current=nil end
		setOpen(false)
	end
	local function show()
		if p.disabled then return end
		if pending.current then pending.current() end
		pending.current=scope:Delay(p.delay or 0.45,function() pending.current=nil; setOpen(true) end)
	end
	Hooks.useEffect(function()
		local connectionScope=Scope.new()
		connectionScope:Connect(env.input.guiService:GetPropertyChangedSignal("SelectedObject"),function()
			local selected=env.input.guiService.SelectedObject
			if selected and ref.current and selected:IsDescendantOf(ref.current) then show() else hide() end
		end)
		return function() connectionScope:Destroy() end
	end,{})
	return h(Element.Fragment,{}, {
		h("Frame",{ref=ref,name=p.name,style=p.style,events={MouseEnter=show,MouseLeave=hide}},p.children),
		h("Popover",{anchor=ref,open=open,onOpenChange=setOpen,width=p.width or 240,maxHeight=180}, {
			h("Text",{text=p.text,style={textSize=12,color="$text",wrapped=true}}),
		}),
	})
end
function Feedback.Toast(p)
	local open,setOpen=Common.controllable(p,true,"open","onOpenChange","defaultOpen")
	local present=Common.presence(open)
	local env=Hooks.useEnvironment()
	local ref=Hooks.useRef(nil)
	Hooks.useEffect(function()
		if not present or not ref.current then return end
		if open then ref.current.GroupTransparency=1 end
		return env.animator:To(ref.current,{GroupTransparency=if open then 0 else 1},env.theme:Get().motion.normal)
	end,{open,present})
	Hooks.useEffect(function()
		if p.duration and open then
			local scope=Scope.new(); scope:Delay(p.duration,function() setOpen(false) end)
			return function() scope:Destroy() end
		end
	end,{open,p.duration})
	if not present then return nil end
	return h("@CanvasGroup",{ref=ref,name=p.name or "Toast",role="status",accessibleName=(p.title or "Notification")..": "..(p.message or ""),
		style=Style.merge({width="100%",height="auto",background="$surface",backgroundTransparency=0,borderWidth=1,borderColor="$border",
			radius="$radius.lg",padding=14,direction="column",gap=8},p.style)}, {
		h("Row",{}, {
			h(Feedback.StatusIndicator,{status=p.status or "info"}),
			h("Text",{text=p.title or "Notification",style={width=UDim.new(1,-59),height=24,font="$typography.medium"}}),
			h("Button",{text="×",variant="ghost",accessibleName="Dismiss notification",style={width=26,height=26,paddingX=0},onClick=function() setOpen(false) end}),
		}),
		p.message and h("Paragraph",{text=p.message,style={textSize=13}}) or false,
	})
end
Feedback.Notification=Feedback.Toast
function Feedback.ToastHost()
	local env=Hooks.useEnvironment()
	local items=Hooks.useSignal(env.notifications.signal)
	return h("Column",{name="Notifications",style={width=UDim.new(1,-32),maxWidth=350,height="auto",position=UDim2.new(1,-16,0,16),anchor=Vector2.new(1,0),gap=10}},
		Element.list(items,function(item)
			return h(Feedback.Toast,{title=item.options.title,message=item.options.message,status=item.options.status,open=not item.closing,
				onOpenChange=function(open) if not open then env.notifications:Dismiss(item.id) end end})
		end,function(item) return item.id end))
end
return Feedback
