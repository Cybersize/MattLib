--!nonstrict
local Element = require(script.Parent.Parent.Parent.core.Element)
local Hooks = require(script.Parent.Parent.Parent.core.Hooks)
local Style = require(script.Parent.Parent.Parent.styling.StyleResolver)
local Scope = require(script.Parent.Parent.Parent.utils.Scope)
local Common = require(script.Parent.Parent.Common)
local h = Element.h
local Sections = {}
function Sections.Reveal(p)
	local env=Hooks.useEnvironment()
	local theme=Hooks.useTheme()
	local ref=Hooks.useRef(nil)
	Hooks.useEffect(function()
		local instance=ref.current
		local scale=instance:FindFirstChildOfClass("UIScale")
		local scope=Scope.new()
		if env.animator.reducedMotion then env.animator:Fade(instance,1,0); if scale then scale.Scale=1 end
		else
			env.animator:Fade(instance,0,0)
			if scale then scale.Scale=0.985 end
			scope:Delay(math.min(0.32,p.delay or (p.order or 0)*theme.motion.stagger),function()
				scope:Add(env.animator:Fade(instance,1,theme.motion.reveal))
				if scale then scope:Add(env.animator:To(scale,{Scale=1},theme.motion.reveal,{channel="reveal"})) end
			end)
		end
		return function() scope:Destroy() end
	end,{theme.design.name,p.replayKey})
	return h("@Frame",{name=p.name,ref=ref,motion=false,style=Style.merge({width="100%",height="auto",direction="column",gap="$spacing.sm",scale=1},p.style)},p.children)
end
function Sections.Section(p)
	local theme=Hooks.useTheme()
	local mode=theme.design.section
	local base={background="$surface",backgroundTransparency=if mode=="glass" then 0.24 elseif mode=="inspector" then 0.14 else 0,borderWidth=1,borderColor="$border",borderTransparency=0.28,
		radius="$radius.lg",padding="$spacing.md",gap="$spacing.sm"}
	if mode=="ruled" then base.backgroundTransparency=1; base.borderWidth=0; base.radius=0; base.padding={8,0,14,0}
	elseif mode=="soft" then base.background="$raised"; base.backgroundTransparency=0.27; base.borderWidth=1; base.borderTransparency=0.6 end
	return h(Sections.Reveal,{name=p.name,order=p.revealOrder or 0,style=Style.merge(base,p.style)}, {
		p.title and h("Text",{key="heading",text=if mode=="inspector" or mode=="ruled" then string.upper(p.title) else p.title,
			style={font=if mode=="inspector" then Enum.Font.Code else "$typography.medium",textSize=if mode=="soft" then 18 elseif mode=="inspector" then 12 else 15,
				color=if mode=="inspector" then "$muted" else "$text"}}) or false,
		mode=="ruled" and h("Separator",{key="rule"}) or false,
		p.description and h("Paragraph",{key="description",text=p.description}) or false,
		h(Element.Fragment,{key="content"},p.children),
	})
end
function Sections.Collapsible(p)
	local open, setOpen = Common.controllable(p,false,"open","onOpenChange","defaultOpen")
	local env = Hooks.useEnvironment()
	local content, body = Hooks.useRef(nil), Hooks.useRef(nil)
	local height,setHeight = Hooks.useState(0)
	Hooks.useEffect(function()
		local scope = Scope.new()
		local function measure() setHeight(content.current.AbsoluteSize.Y) end
		scope:Connect(content.current:GetPropertyChangedSignal("AbsoluteSize"),measure)
		measure()
		return function() scope:Destroy() end
	end,{})
	Hooks.useEffect(function()
		return env.animator:To(body.current,{Size=UDim2.new(1,0,0,if open then height else 0)},env.theme:Get().motion.normal)
	end,{open,height})
	return h("Section",{name=p.name,style=p.style},{
		h("Button",{text=(if open then "▾  " else "▸  ") .. (p.title or "Section"),variant="ghost",disabled=p.disabled,
			style={textAlign="left"},onClick=function() setOpen(not open) end,accessibleName=(p.title or "Section") .. (if open then ", expanded" else ", collapsed")}),
		h("Frame",{ref=body,style={height=0,overflow="hidden"}}, {
			h("Column",{ref=content,style={paddingY="$spacing.sm"}},p.children),
		}),
	})
end
return Sections
