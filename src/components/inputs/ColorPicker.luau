--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Common=require(script.Parent.Parent.Common)
local h=Element.h
local ColorPicker={}
local function hex(color)
	return string.format("#%02X%02X%02X",math.round(color.R*255),math.round(color.G*255),math.round(color.B*255))
end
function ColorPicker.ColorPicker(p)
	local env=Hooks.useEnvironment()
	local value,setValue=Common.controllable(p,env.theme:Get().accent)
	assert(typeof(value)=="Color3","ColorPicker requires a Color3 value")
	local open,setOpen=Hooks.useState(false)
	local draft,setDraft=Hooks.useState(hex(value))
	local invalid,setInvalid=Hooks.useState(false)
	local anchor=Hooks.useRef(nil)
	Hooks.useEffect(function() setDraft(hex(value)) end,{value})
	return h("Column",{name=p.name,style=p.style}, {
		p.label and h("Text",{text=p.label,style={font="$typography.medium",textSize=13}}) or false,
		h("Button",{ref=anchor,text=hex(value),disabled=p.disabled,onClick=function() setOpen(not open) end,
			accessibleName=p.accessibleName or p.label or "Choose color",style={textAlign="left",paddingX=42}}, {
			-- The button's 42px UIPadding also offsets children; leave the hex text unobstructed.
			h("Frame",{name="ColorSwatch",style={width=22,height=22,position=UDim2.new(0,-30,0.5,0),anchor=Vector2.new(0,0.5),radius=4,background=value,backgroundTransparency=0}}),
		}),
		h("Popover",{anchor=anchor,open=open and not p.disabled,onOpenChange=setOpen,width=290}, {
			h("Text",{text="Color channels",style={font="$typography.medium"}}),
			h("Slider",{label="Red",value=math.round(value.R*255),min=0,max=255,onChange=function(n) setValue(Color3.new(n/255,value.G,value.B)) end}),
			h("Slider",{label="Green",value=math.round(value.G*255),min=0,max=255,onChange=function(n) setValue(Color3.new(value.R,n/255,value.B)) end}),
			h("Slider",{label="Blue",value=math.round(value.B*255),min=0,max=255,onChange=function(n) setValue(Color3.new(value.R,value.G,n/255)) end}),
			h("TextInput",{label="Hex",value=draft,onChange=function(text) setDraft(text); setInvalid(false) end,onCommit=function(text)
				local match=string.match(text,"^#?([%x][%x][%x][%x][%x][%x])$")
				if not match then setInvalid(true); setDraft(hex(value)); return end
				setValue(Color3.fromRGB(tonumber(string.sub(match,1,2),16),tonumber(string.sub(match,3,4),16),tonumber(string.sub(match,5,6),16)))
			end}),
			invalid and h("Text",{text="Use a six-digit RGB hex color",style={color="$danger",textSize=12}}) or false,
		}),
	})
end
return ColorPicker
