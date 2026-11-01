--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local Common=require(script.Parent.Parent.Common)
local h=Element.h
local Inputs={}
function Inputs.TextInput(p)
	local value,setValue=Common.controllable(p,"")
	assert(type(value)=="string","TextInput value must be a string")
	assert(p.maxLength==nil or (Common.finite(p.maxLength) and p.maxLength>=0 and p.maxLength%1==0),"maxLength must be a nonnegative integer")
	local env=Hooks.useEnvironment()
	local theme=Hooks.useSignal(env.theme.signal)
	local props={name=p.name,ref=p.ref,disabled=p.disabled,role="textbox",accessibleName=p.accessibleName or p.label or p.placeholder,
		style=Style.merge({width="100%",height=if p.multiline then 94 else "$controlHeight",background="$input",backgroundTransparency=0,
			color="$text",font="$typography.font",textSize="$typography.body",textAlign="left",textYAlign=if p.multiline then "top" else "center",
			paddingX=12,paddingY=8,radius="$radius.md",borderWidth=1,borderColor="$border",focus={borderColor="$accent",borderWidth=2},
			disabled={color="$disabled"}},p.inputStyle),
		native={Text=value,PlaceholderText=p.placeholder or "",PlaceholderColor3=theme.subtle,ClearTextOnFocus=false,MultiLine=p.multiline or false,
			TextWrapped=p.multiline or false,Selectable=not p.disabled},
		changes={Text=function(instance)
			local text=instance.Text
			if p.maxLength then
				local length=utf8.len(text)
				if length and length>p.maxLength then text=string.sub(text,1,utf8.offset(text,p.maxLength+1)-1) end
			end
			setValue(text)
		end},events={FocusLost=function(instance,enter)
			if p.onCommit then p.onCommit(instance.Text,enter) end
		end}}
	return h("Column",{style=Style.merge({gap=6},p.style)}, {
		p.label and h("Text",{text=p.label,style={textSize=13,font="$typography.medium"}}) or false,
		h("@TextBox",props),
		p.description and h("Paragraph",{text=p.description,style={textSize=12}}) or false,
	})
end
function Inputs.NumericInput(p)
	local value,setValue=Common.controllable(p,0)
	assert(Common.finite(value),"NumericInput value must be finite")
	local min,max=p.min or -math.huge,p.max or math.huge
	assert(min<=max,"NumericInput min must not exceed max")
	local draft,setDraft=Hooks.useState(tostring(value))
	local errorText,setError=Hooks.useState("")
	Hooks.useEffect(function() setDraft(tostring(value)) end,{value})
	local function commit(text)
		local number=tonumber(text)
		if not Common.finite(number) then setDraft(tostring(value)); setError("Enter a valid number"); if p.onInvalid then p.onInvalid(text) end; return end
		number=math.clamp(number,min,max)
		if p.step then
			assert(Common.finite(p.step) and p.step>0,"step must be positive")
			local base=if min>-math.huge then min else 0
			number=math.clamp(base+math.round((number-base)/p.step)*p.step,min,max)
		end
		setDraft(tostring(if p.value~=nil then value else number)); setError(""); setValue(number)
		if p.onCommit then p.onCommit(number) end
	end
	return h("Column",{style=p.style}, {
		h(Inputs.TextInput,{name=p.name,ref=p.ref,label=p.label,placeholder=p.placeholder,disabled=p.disabled,value=draft,
			onChange=function(text) setDraft(text); setError("") end,onCommit=commit,inputStyle=p.inputStyle,description=p.description}),
		errorText~="" and h("Text",{text=errorText,style={color="$danger",textSize=12}}) or false,
	})
end
return Inputs
