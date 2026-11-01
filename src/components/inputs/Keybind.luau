--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Input=require(script.Parent.Parent.Parent.runtime.Input)
local Common=require(script.Parent.Parent.Common)
local h=Element.h
local Keybind={}
function Keybind.Keybind(p)
	local value,setValue=Common.controllable(p,"None")
	assert(type(value)=="string","Keybind values are KeyCode names or 'None'")
	if value~="None" then assert(pcall(function() return Enum.KeyCode[value] end),"Unknown KeyCode: "..value) end
	local listening,setListening=Hooks.useState(false)
	local env=Hooks.useEnvironment()
	local ref=Hooks.useRef(nil)
	local latest=Common.latest({props=p,value=value,change=setValue,listening=listening})
	Hooks.useEffect(function()
		return env.input:Subscribe("began",function(input,processed)
			local current=latest.current
			if not input or not Input.visible(ref.current) or not env.overlays:Allows(ref.current) or current.props.disabled then return end
			if input.UserInputType~=Enum.UserInputType.Keyboard then return end
			if current.listening then
				if input.KeyCode==Enum.KeyCode.Escape then setListening(false); return true end
				if input.KeyCode==Enum.KeyCode.Unknown then return true end
				current.change(if input.KeyCode==Enum.KeyCode.Backspace or input.KeyCode==Enum.KeyCode.Delete then "None" else input.KeyCode.Name)
				current.listening=false; setListening(false); return true
			end
			if not processed and not env.input.uis:GetFocusedTextBox() and input.KeyCode.Name==current.value and current.props.onTrigger then current.props.onTrigger(input) end
		end)
	end,{})
	return h("Column",{name=p.name,style=p.style}, {
		p.label and h("Text",{text=p.label,style={font="$typography.medium",textSize=13}}) or false,
		h("Button",{ref=ref,text=if listening then "Press a key…  Esc cancels" else value,disabled=p.disabled,active=listening,
			style={active={borderColor="$accent",color="$accent"}},onClick=function() setListening(true) end,
			accessibleName=(p.label or "Keybind")..", "..value}),
	})
end
return Keybind
