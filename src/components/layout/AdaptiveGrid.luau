--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local h=Element.h
local Layout={}
-- Wrapping changes widths, never the parent or key of a child. Focus and local state survive resizing.
function Layout.AdaptiveGrid(p)
	local ref=Hooks.useRef(nil)
	local width,setWidth=Hooks.useState(0)
	local gap=p.gap or 12
	local minimum=p.minColumnWidth or 240
	local maximum=p.columns or 2
	assert(type(minimum)=="number" and minimum>0,"minColumnWidth must be positive")
	assert(type(maximum)=="number" and maximum>=1 and maximum%1==0,"columns must be a positive integer")
	assert(type(gap)=="number" and gap>=0,"Grid gap must be nonnegative")
	Hooks.useEffect(function()
		local function measure() setWidth(math.floor(ref.current.AbsoluteSize.X+0.5)) end
		local connection=ref.current:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure)
		measure()
		return function() connection:Disconnect() end
	end,{})
	local columns=math.clamp(math.floor((width+gap)/(minimum+gap)),1,maximum)
	local children={}
	for index,child in p.children do
		children[index]=h("Column",{key=child.key or index,name="GridCell:"..index,
			style={width=UDim.new(1/columns,-gap*(columns-1)/columns-0.1),height="auto",gap=0}},child)
	end
	return h("Frame",{ref=ref,name=p.name or "AdaptiveGrid",attributes={MattColumns=columns},
		style=Style.merge({height="auto",direction="row",wrap=true,gap=gap,verticalAlign="start"},p.style)},children)
end
return Layout
