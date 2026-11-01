--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local Input=require(script.Parent.Parent.Parent.runtime.Input)
local Common=require(script.Parent.Parent.Common)
local h=Element.h
local Sliders={}
function Sliders.quantize(value,min,max,step)
	return math.clamp(min+math.round((value-min)/step)*step,min,max)
end
local function slider(p,range)
	local min,max,step=p.min or 0,p.max or 100,p.step or 1
	assert(Common.finite(min) and Common.finite(max) and max>min,"Slider requires finite min < max")
	assert(Common.finite(step) and step>0,"Slider step must be positive")
	local value,setValue=Common.controllable(p,if range then {min,max} else min)
	if range then assert(type(value)=="table" and Common.finite(value[1]) and Common.finite(value[2]) and value[1]<=value[2],"RangeSlider requires {low, high}")
	else assert(Common.finite(value),"Slider value must be finite") end
	local low=math.clamp(if range then value[1] else min,min,max)
	local high=math.clamp(if range then value[2] else value,min,max)
	local env=Hooks.useEnvironment()
	local track=Hooks.useRef(nil)
	local active=Hooks.useRef(1)
	local latest=Common.latest({value=value,low=low,high=high,setValue=setValue,props=p})
	local capture=Hooks.useRef(nil)
	local function update(number,index)
		local state=latest.current
		number=Sliders.quantize(number,min,max,step)
		if range then
			local nextValue=if index==1 then {math.min(number,state.high),state.high} else {state.low,math.max(number,state.low)}
			state.low,state.high=nextValue[1],nextValue[2]
			if nextValue[1]~=state.value[1] or nextValue[2]~=state.value[2] then state.value=nextValue; state.setValue(nextValue) end
		else
			if state.value~=number then state.value=number; state.high=number; state.setValue(number) end
		end
	end
	local function fromPointer(position)
		local instance=track.current
		return min+math.clamp((position.X-instance.AbsolutePosition.X)/math.max(1,instance.AbsoluteSize.X),0,1)*(max-min)
	end
	Common.key(track,function(key)
		if p.disabled then return end
		if range and key==Enum.KeyCode.Space then active.current=if active.current==1 then 2 else 1; return true end
		local current=if range and active.current==1 then latest.current.low else latest.current.high
		if key==Enum.KeyCode.Left or key==Enum.KeyCode.Down then update(current-step,active.current)
		elseif key==Enum.KeyCode.Right or key==Enum.KeyCode.Up then update(current+step,active.current)
		elseif key==Enum.KeyCode.Home then update(min,active.current)
		elseif key==Enum.KeyCode.End then update(max,active.current)
		else return end
		if p.onCommit then p.onCommit(latest.current.value) end
		return true
	end)
	Hooks.useEffect(function() return function() if capture.current then capture.current() end end end,{min,max,step,p.disabled})
	local function thumb(ratio,key)
		return h("Frame",{key=key,style={width=14,height=14,position=UDim2.fromScale(ratio,0.5),anchor=Vector2.new(0.5,0.5),
			background=if p.disabled then "$disabled" else "$text",backgroundTransparency=0,radius="$radius.pill",zIndex=3}})
	end
	local lowRatio,highRatio=(low-min)/(max-min),(high-min)/(max-min)
	local formatted=if p.format then p.format(value) elseif range then string.format("%g – %g",low,high) else string.format("%g",high)
	return h("Column",{name=p.name,style=Style.merge({gap=4,paddingX=8},p.style)}, {
		h("Row",{}, {
			h("Text",{text=p.label or (if range then "Range" else "Value"),style={width=UDim.new(1,-120),height=22}}),
			h("Text",{text=formatted,style={width=112,height=22,textAlign="right",color="$muted",textSize=12}}),
		}),
		h("@TextButton",{name=(p.name or (if range then "RangeSlider" else "Slider"))..":Track",ref=track,disabled=p.disabled,role=if range then "range slider" else "slider",
			accessibleName=p.accessibleName or p.label,accessibleValue=formatted,native={Text=""},
			style={width="100%",height=28,backgroundTransparency=1,focus={borderWidth=1,borderColor="$accent",radius=4}},
			events={InputBegan=function(_,input)
				if p.disabled or not Input.isPointer(input) then return end
				local number=fromPointer(input.Position)
				active.current=if range and math.abs(number-latest.current.high)<math.abs(number-latest.current.low) then 2 else 1
				update(number,active.current)
				capture.current=env.input:Capture(input,function(position) update(fromPointer(position),active.current) end,function(cancelled)
					capture.current=nil
					if not cancelled and latest.current.props.onCommit then latest.current.props.onCommit(latest.current.value) end
				end)
			end}}, {
			h("Frame",{style={width="100%",height=5,position=UDim2.fromScale(0,0.5),anchor=Vector2.new(0,0.5),background="$input",backgroundTransparency=0,radius="$radius.pill"}}),
			h("Frame",{style={width=UDim.new(highRatio-lowRatio,0),height=5,position=UDim2.fromScale(lowRatio,0.5),anchor=Vector2.new(0,0.5),
				background=if p.disabled then "$disabled" else "$accent",backgroundTransparency=0,radius="$radius.pill",zIndex=2}}),
			if range then thumb(lowRatio,"low") else false,
			thumb(highRatio,"high"),
		}),
	})
end
function Sliders.Slider(p) return slider(p,false) end
function Sliders.RangeSlider(p) return slider(p,true) end
return Sliders
