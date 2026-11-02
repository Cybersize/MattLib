--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local Common=require(script.Parent.Parent.Common)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local h=Element.h
local Boolean={}
local function control(p,kind)
	local value,setValue=Common.controllable(p,false)
	assert(type(value)=="boolean",kind.." value must be boolean")
	local checkbox=kind=="checkbox"
	local theme=Hooks.useTheme()
	local controls=theme.control
	local width,height,thumb=controls.switchWidth,controls.switchHeight,controls.thumbSize
	local inset=(height-thumb)/2
	local function ratio(deep,base) return if base<=0 then 1 else math.clamp(deep/base,0,1) end
	local shade=Color3.new(ratio(theme.accentDeep.R,theme.accent.R),ratio(theme.accentDeep.G,theme.accent.G),ratio(theme.accentDeep.B,theme.accent.B))
	return h("Button",{name=p.name,ref=p.ref,text="",disabled=p.disabled,variant="ghost",onClick=function() setValue(not value) end,
		role=kind,accessibleName=p.accessibleName or p.label or kind,accessibleValue=tostring(value),
		style=Style.merge({height=if p.description then controls.rowHeight+14 else controls.rowHeight,paddingX=0,scale=1,radius=0,
			borderWidth=0,hover={scale=1,backgroundTransparency=0.8},pressed={scale=1},disabled={backgroundTransparency=1}},p.style)}, {
		h("Column",{style={width=UDim.new(1,-64),height="auto",position=UDim2.new(0,0,0.5,0),anchor=Vector2.new(0,0.5),gap=2}}, {
			h("Text",{text=p.label or (if checkbox then "Checkbox" else "Toggle"),style={color=if p.disabled then "$disabled" else "$text"}}),
			p.description and h("Paragraph",{text=p.description,style={textSize=12}}) or false,
		}),
		h("Frame",{style={width=if checkbox then height else width,height=height,position=UDim2.new(1,-4,0.5,0),anchor=Vector2.new(1,0.5),
			background=if p.disabled then "$disabled" elseif value then "$accent" else "$input",backgroundTransparency=0,
			radius=if checkbox then "$radius.sm" else controls.switchRadius,borderWidth=1,borderColor=if value then "$accent" else "$border",
			gradient=if value and theme.effects.gradient>0 then {from=Color3.new(1,1,1),to=shade,rotation=90} else false}}, {
			if checkbox then h("Text",{text=if value then "✓" else "",style={width="100%",height="100%",textAlign="center",color="$accentText",textSize=18}})
			else h("Frame",{motion=true,style={width=thumb,height=thumb,position=UDim2.new(0,if value then width-thumb-inset else inset,0.5,0),anchor=Vector2.new(0,0.5),
				background=if value then "$text" else "$muted",backgroundTransparency=0,radius="$radius.pill"}}),
		}),
	})
end
function Boolean.Toggle(p) return control(p,"switch") end
Boolean.Switch=Boolean.Toggle
function Boolean.Checkbox(p) return control(p,"checkbox") end
return Boolean
