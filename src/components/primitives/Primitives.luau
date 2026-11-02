--!nonstrict
local Element = require(script.Parent.Parent.Parent.core.Element)
local Style = require(script.Parent.Parent.Parent.styling.StyleResolver)
local Hooks = require(script.Parent.Parent.Parent.core.Hooks)
local h = Element.h
local Primitives = {}
local textStyle = {backgroundTransparency=1,color="$text",font="$typography.font",textSize="$typography.body",
	textAlign="left",textYAlign="center",width="100%",height="auto",wrapped=true}
local function hostProps(p, defaults, native)
	return {name=p.name,ref=p.ref,style=Style.merge(defaults,p.style),native=Style.merge(native,p.native),
		events=p.events,changes=p.changes,attributes=p.attributes,disabled=p.disabled,active=p.active,motion=p.motion,
		role=p.role,accessibleName=p.accessibleName,accessibleValue=p.accessibleValue}
end
function Primitives.Frame(p)
	return h("@Frame",hostProps(p,{width="100%",height="auto",backgroundTransparency=1}),p.children)
end
Primitives.Container = Primitives.Frame
function Primitives.Column(p)
	return h("@Frame",hostProps(p,{width="100%",height="auto",backgroundTransparency=1,direction="column",gap="$spacing.sm"}),p.children)
end
function Primitives.Row(p)
	return h("@Frame",hostProps(p,{width="100%",height="auto",backgroundTransparency=1,direction="row",gap="$spacing.sm",verticalAlign="center"}),p.children)
end
Primitives.Stack = Primitives.Frame
function Primitives.Inset(p)
	return h(Primitives.Column,{name=p.name,ref=p.ref,style=Style.merge({padding=p.spacing or "$spacing.lg"},p.style)},p.children)
end
function Primitives.Text(p)
	return h("@TextLabel",hostProps(p,textStyle,{Text=tostring(p.text or ""),TextTruncate=Enum.TextTruncate.None}),p.children)
end
Primitives.Label = Primitives.Text
function Primitives.RichText(p)
	local copy = table.clone(p)
	copy.style = Style.merge({richText=true},p.style)
	return h(Primitives.Text,copy)
end
function Primitives.Paragraph(p)
	return h(Primitives.Text,{text=p.text or p.content,name=p.name,style=Style.merge({color="$muted",wrapped=true,textYAlign="top"},p.style)})
end
function Primitives.Icon(p)
	local size = p.size or 20
	if p.image then
		local image = if type(p.image) == "number" then "rbxassetid://" .. p.image else p.image
		return h("@ImageLabel",hostProps(p,{width=size,height=size,backgroundTransparency=1,imageColor="$text"},{Image=image,ScaleType=Enum.ScaleType.Fit}))
	end
	return h(Primitives.Text,{name=p.name,text=p.glyph or "◇",style=Style.merge({width=size,height=size,textSize=size,textAlign="center"},p.style)})
end
function Primitives.Separator(p)
	return h(Primitives.Frame,{name=p.name,style=Style.merge({width="100%",height=1,background="$border",backgroundTransparency=0},p.style)})
end
local variants = {
	primary={background="$accent",color="$accentText",hover={background="$accentHover"},pressed={background="$accentPressed"}},
	secondary={background="$raised",color="$text",borderWidth=1,borderColor="$border",hover={background="$hover"},pressed={background="$pressed"}},
	ghost={backgroundTransparency=1,color="$muted",hover={background="$hover",backgroundTransparency=0,color="$text"},pressed={background="$pressed",backgroundTransparency=0}},
	danger={background="$danger",color="$background",hover={opacity=0.85},pressed={opacity=0.7}},
}
function Primitives.Button(p)
	assert(variants[p.variant or "secondary"], "Unknown button variant")
	local theme=Hooks.useTheme()
	local effects=theme.effects
	local primary=p.variant=="primary"
	local glow=effects.glow*effects.intensity
	local interactive={scale=1,borderWidth=1,borderTransparency=if primary then 0.6 else 0.2,
		hover={scale=effects.hoverScale,borderColor="$accent",borderTransparency=0.1},
		pressed={scale=effects.pressScale},focus={borderColor="$accent",borderWidth=2,borderTransparency=0},
		disabled={scale=1,glow=if primary and glow>0 then 0 else nil}}
	if primary and effects.gradient>0 then
		-- UIGradient multiplies the host color. Ratios retain the intended accent palette.
		local function ratio(deep,base) return if base<=0 then 1 else math.clamp(deep/base,0,1) end
		local shade=Color3.new(ratio(theme.accentDeep.R,theme.accent.R),ratio(theme.accentDeep.G,theme.accent.G),ratio(theme.accentDeep.B,theme.accent.B))
		interactive.gradient={from=Color3.new(1,1,1),to=shade,rotation=90}
		interactive.hover.gradient={from=Color3.new(1,1,1),to=shade,rotation=72}
		interactive.disabled.gradient=false
	end
	if primary and glow>0 then interactive.glow=glow*0.22; interactive.hover.glow=glow*0.7; interactive.pressed.glow=glow*0.32 end
	local props = hostProps(p,Style.merge(textStyle,{width="100%",height="$controlHeight",radius="$radius.md",backgroundTransparency=0,
		textAlign="center",wrapped=false,paddingX="$spacing.md",focus={borderWidth=2,borderColor="$accent"},
		disabled={color="$disabled",background="$input",backgroundTransparency=0,borderColor="$border"}},variants[p.variant or "secondary"],interactive),
		{Text=tostring(p.text or p.label or ""),TextTruncate=Enum.TextTruncate.AtEnd})
	props.events = Style.merge(p.events,{Activated=function(instance,...)
		if not p.disabled and p.onClick then p.onClick(instance,...) end
	end})
	props.role, props.accessibleName = p.role or "button", p.accessibleName or p.text or p.label
	return h("@TextButton",props,p.children)
end
function Primitives.Badge(p)
	return h(Primitives.Text,{name=p.name,text=p.text,style=Style.merge({width="auto",height=24,paddingX="$spacing.sm",radius="$radius.sm",
		background="$raised",backgroundTransparency=0,color="$muted",textSize="$typography.small",textAlign="center",wrapped=false},p.style)})
end
function Primitives.ScrollArea(p)
	return h("@ScrollingFrame",hostProps(p,{width="100%",height="100%",backgroundTransparency=1,overflow="scroll",scrollbarColor="$border"},
		{CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,
		ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}),{
		h(Primitives.Column,{ref=p.contentRef,style=Style.merge({width=UDim.new(1,-8),padding={0,0,4,0}},p.contentStyle)},p.children),
	})
end
-- Padding is represented by the shared padding vocabulary, not native CSS keys.
function Primitives.register()
	for _, name in {"Frame","Container","Row","Column","Stack","Inset","Text","Label","RichText","Paragraph","Icon","Separator","Button","Badge","ScrollArea"} do
		Element.register(name,Primitives[name])
	end
end
Primitives.hostProps = hostProps
Primitives.textStyle = textStyle
return Primitives
