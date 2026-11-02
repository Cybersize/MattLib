--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Designs=require(script.Parent.Parent.Parent.styling.Designs)
local h=Element.h
local options={}
for _,design in Designs.list() do table.insert(options,{value=design.name,label=design.label}) end
local DesignPicker={}
function DesignPicker.DesignPicker(p)
	local env=Hooks.useEnvironment()
	local theme=Hooks.useTheme()
	return h(if p.presentation=="segments" then "SegmentedControl" else "Dropdown",{
		name=p.name or "DesignPicker",label=p.label or "Design",options=options,value=p.value or theme.design.name,disabled=p.disabled,style=p.style,
		onChange=function(value)
			Designs.get(value)
			if p.onChange then p.onChange(value) else env.library:SetDesign(value) end
		end,
	})
end
return DesignPicker
