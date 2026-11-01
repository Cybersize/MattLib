--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local Common=require(script.Parent.Parent.Common)
local h=Element.h
local Boolean={}
local function control(p,kind)
	local value,setValue=Common.controllable(p,false)
	assert(type(value)=="boolean",kind.." value must be boolean")
	local checkbox=kind=="checkbox"
	return h("Button",{name=p.name,ref=p.ref,text="",disabled=p.disabled,variant="ghost",onClick=function() setValue(not value) end,
		role=kind,accessibleName=p.accessibleName or p.label or kind,accessibleValue=tostring(value),
		style=Style.merge({height=if p.description then 62 else 44,paddingX=8},p.style)}, {
		h("Column",{style={width=UDim.new(1,-64),height="auto",position=UDim2.new(0,0,0.5,0),anchor=Vector2.new(0,0.5),gap=2}}, {
			h("Text",{text=p.label or (if checkbox then "Checkbox" else "Toggle"),style={color=if p.disabled then "$disabled" else "$text"}}),
			p.description and h("Paragraph",{text=p.description,style={textSize=12}}) or false,
		}),
		h("Frame",{style={width=if checkbox then 22 else 40,height=22,position=UDim2.new(1,-4,0.5,0),anchor=Vector2.new(1,0.5),
			background=if p.disabled then "$disabled" elseif value then "$accent" else "$input",backgroundTransparency=0,
			radius=if checkbox then "$radius.sm" else "$radius.pill",borderWidth=1,borderColor=if value then "$accent" else "$border"}}, {
			if checkbox then h("Text",{text=if value then "✓" else "",style={width="100%",height="100%",textAlign="center",color="$accentText",textSize=18}})
			else h("Frame",{motion=true,style={width=16,height=16,position=UDim2.new(0,if value then 21 else 3,0.5,0),anchor=Vector2.new(0,0.5),
				background=if value then "$accentText" else "$muted",backgroundTransparency=0,radius="$radius.pill"}}),
		}),
	})
end
function Boolean.Toggle(p) return control(p,"switch") end
Boolean.Switch=Boolean.Toggle
function Boolean.Checkbox(p) return control(p,"checkbox") end
return Boolean
