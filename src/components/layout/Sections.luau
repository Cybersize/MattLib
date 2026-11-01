--!nonstrict
local Element = require(script.Parent.Parent.Parent.core.Element)
local Hooks = require(script.Parent.Parent.Parent.core.Hooks)
local Style = require(script.Parent.Parent.Parent.styling.StyleResolver)
local Scope = require(script.Parent.Parent.Parent.utils.Scope)
local Common = require(script.Parent.Parent.Common)
local h = Element.h
local Sections = {}
function Sections.Section(p)
	return h("Column",{name=p.name,style=Style.merge({background="$surface",backgroundTransparency=0,borderWidth=1,borderColor="$border",
		radius="$radius.lg",padding="$spacing.lg",gap="$spacing.md"},p.style)}, {
		p.title and h("Text",{text=p.title,style={font="$typography.medium",textSize=15}}) or false,
		p.description and h("Paragraph",{text=p.description}) or false,
		p.children,
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
