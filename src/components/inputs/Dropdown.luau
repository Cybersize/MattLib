--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Common=require(script.Parent.Parent.Common)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local h=Element.h
local Dropdowns={}
function Dropdowns.Dropdown(p)
	local options=Hooks.useMemo(function() return Common.options(p.options or {}) end,{p.options})
	local multiple=p.multiple==true
	local value,setValue=Common.controllable(p,if multiple then {} else "")
	assert((multiple and type(value)=="table") or (not multiple and (type(value)=="string" or type(value)=="number")),"Invalid dropdown value")
	local open,setOpen=Hooks.useState(false)
	local query,setQuery=Hooks.useState("")
	local highlighted,setHighlighted=Hooks.useState(1)
	local anchor,search,panel=Hooks.useRef(nil),Hooks.useRef(nil),Hooks.useRef(nil)
	local env=Hooks.useEnvironment()
	local viewport=Hooks.useSignal(env.runtime.viewport)
	local filtered=Hooks.useMemo(function()
		local result={}
		for _,item in options do if string.find(string.lower(item.label),string.lower(query),1,true) then table.insert(result,item) end end
		return result
	end,{options,query})
	local latest=Common.latest(value)
	local function selected(option) return if multiple then table.find(value,option)~=nil else value==option end
	local function choose(item)
		if item.disabled or p.disabled then return end
		if multiple then
			local nextValue=table.clone(latest.current)
			local index=table.find(nextValue,item.value)
			if index then table.remove(nextValue,index) else table.insert(nextValue,item.value) end
			latest.current=nextValue; setValue(nextValue)
		else setValue(item.value); setOpen(false); env.input.guiService.SelectedObject=anchor.current end
	end
	local function toggle()
		if p.disabled then return end
		setOpen(not open); setHighlighted(1); setQuery("")
		env.input.guiService.SelectedObject=anchor.current
	end
	local function keyboard(key)
		if p.disabled then return end
		if key==Enum.KeyCode.Down or key==Enum.KeyCode.Up then
			if not open then toggle(); return true end
			local direction=if key==Enum.KeyCode.Down then 1 else -1
			local index=highlighted
			for _=1,#filtered do
				index=(index-1+direction)%#filtered+1
				if not filtered[index].disabled then setHighlighted(index); break end
			end
			return true
		elseif key==Enum.KeyCode.Return then
			if open then if filtered[highlighted] then choose(filtered[highlighted]) end else toggle() end
			return true
		elseif key==Enum.KeyCode.Escape and open then setOpen(false); return true end
	end
	Common.key(anchor,keyboard)
	Common.key(search,keyboard)
	Common.key(panel,keyboard,true)
	Hooks.useEffect(function()
		if open and search.current then search.current:CaptureFocus() end
	end,{open})
	Hooks.useEffect(function() if p.disabled then setOpen(false) end end,{p.disabled})
	local labels={}
	if multiple then for _,option in value do table.insert(labels,Common.label(options,option) or tostring(option)) end end
	local label=if multiple then (#labels>0 and table.concat(labels,", ") or p.placeholder or "Select options")
		else Common.label(options,value) or p.placeholder or "Select an option"
	return h("Column",{name=p.name,style=Style.merge({gap=6},p.style)}, {
		p.label and h("Text",{text=p.label,style={textSize=13,font="$typography.medium"}}) or false,
		h("Button",{name=(p.name or "Dropdown")..":Trigger",ref=anchor,text=label.."   ▾",disabled=p.disabled,onClick=toggle,
			style={textAlign="left",background="$input"},role=multiple and "multiselect" or "combobox",accessibleName=p.accessibleName or p.label,accessibleValue=label}),
		h("Popover",{name=(p.name or "Dropdown")..":Menu",panelRef=panel,anchor=anchor,open=open,onOpenChange=setOpen,width=p.menuWidth,maxHeight=p.maxHeight or 320,scrollable=false}, {
			p.searchable and h("TextInput",{name="DropdownSearch",ref=search,value=query,placeholder="Search…",onChange=function(text) setQuery(text); setHighlighted(1) end}) or false,
			h("ScrollArea",{style={height=math.max(1,math.min(240,math.max(38,#filtered*38),math.min(p.maxHeight or 320,viewport.Y-16)-(if p.searchable then 64 else 24)))},contentStyle={gap=2}},
				if #filtered==0 then {h("Text",{text="No matches",style={color="$muted",height=36}})}
				else Element.list(filtered,function(item,index)
					return h("Button",{text=(if selected(item.value) then "✓  " else "    ")..item.label,disabled=item.disabled,variant="ghost",
						style={height=36,textAlign="left",color=if selected(item.value) then "$accent" else "$text",background="$hover",backgroundTransparency=if highlighted==index then 0 else 1},
						onClick=function() choose(item) end,accessibleName=item.label..(if selected(item.value) then ", selected" else "")})
				end,function(item) return item.key end)),
		}),
	})
end
function Dropdowns.SearchableDropdown(p)
	local copy=table.clone(p); copy.searchable=true
	return h(Dropdowns.Dropdown,copy)
end
function Dropdowns.MultiSelect(p)
	local copy=table.clone(p); copy.multiple=true; copy.searchable=if p.searchable==nil then true else p.searchable
	return h(Dropdowns.Dropdown,copy)
end
return Dropdowns
