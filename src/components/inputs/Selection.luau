--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Common=require(script.Parent.Parent.Common)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local h=Element.h
local Selection={}
function Selection.RadioGroup(p)
	local options=Hooks.useMemo(function() return Common.options(p.options or {}) end,{p.options})
	local value,setValue=Common.controllable(p,options[1] and options[1].value or "")
	local ref=Hooks.useRef(nil)
	local function nextOption(direction)
		if p.disabled or #options==0 then return end
		local index=1
		for i,item in options do if item.value==value then index=i; break end end
		for _=1,#options do
			index=(index-1+direction)%#options+1
			if not options[index].disabled then setValue(options[index].value); return true end
		end
	end
	Common.key(ref,function(key)
		if key==Enum.KeyCode.Left or key==Enum.KeyCode.Up then return nextOption(-1)
		elseif key==Enum.KeyCode.Right or key==Enum.KeyCode.Down then return nextOption(1) end
	end,true)
	return h("Column",{name=p.name,ref=ref,style=p.style}, {
		p.label and h("Text",{text=p.label,style={font="$typography.medium",textSize=13}}) or false,
		h(if p.horizontal then "Row" else "Column",{style=if p.horizontal then {distribute="fill",gap=4} else {gap=4}},
			Element.list(options,function(item)
				return h("Button",{text=(if p.segmented then "" elseif value==item.value then "◉  " else "○  ")..item.label,
					disabled=p.disabled or item.disabled,variant=if p.segmented and value==item.value then "primary" else "ghost",
					style={textAlign=if p.segmented then "center" else "left",color=if value==item.value and not p.segmented then "$accent" else nil},
					onClick=function() setValue(item.value) end,role="radio",accessibleName=item.label,accessibleValue=tostring(value==item.value)})
			end,function(item) return item.key end)),
	})
end
function Selection.SegmentedControl(p)
	local copy=table.clone(p); copy.segmented=true; copy.horizontal=true
	return h(Selection.RadioGroup,copy)
end
return Selection
