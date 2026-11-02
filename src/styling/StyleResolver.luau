--!nonstrict
local Theme = require(script.Parent.Theme)
local Style = {}
local valid = {}
for _, name in { "background", "backgroundTransparency", "color", "font", "textSize", "textAlign", "textYAlign",
	"wrapped", "richText", "width", "height", "position", "anchor", "minWidth", "minHeight", "maxWidth", "maxHeight",
	"padding", "paddingX", "paddingY", "borderColor", "borderWidth", "radius", "opacity", "direction", "gap",
	"horizontalAlign", "verticalAlign", "distribute", "wrap", "grow", "shrink", "visible", "overflow", "zIndex",
	"rotation", "hover", "pressed", "focus", "active", "disabled", "imageColor", "imageTransparency", "scrollbarColor",
	"gradient","scale","borderTransparency","glow","glowColor",
} do valid[name] = true end
local function dim(value)
	if typeof(value) == "UDim" then return value end
	if type(value) == "number" then return UDim.new(0, value) end
	if type(value) == "string" then
		local percent = string.match(value, "^([%d%.]+)%%$")
		if percent then return UDim.new(tonumber(percent) / 100, 0) end
	end
	error("Dimensions must be pixels, UDim, percentages, or 'auto'", 3)
end
local function enum(mapping, value, property)
	assert(mapping[value], "Invalid " .. property .. ": " .. tostring(value))
	return mapping[value]
end
function Style.merge(...)
	local result = {}
	for index = 1, select("#", ...) do
		local style = select(index, ...)
		for key, value in style or {} do
			if typeof(value) == "table" and typeof(result[key]) == "table" then
				result[key] = Style.merge(result[key], value)
			else result[key] = value end
		end
	end
	return result
end
function Style.resolve(source, theme, state, className)
	local style = {}
	for key, value in source or {} do
		assert(valid[key], "Unsupported style property: " .. tostring(key) .. ". Use parent gap/padding or Inset for spacing.")
		if key ~= "hover" and key ~= "pressed" and key ~= "focus" and key ~= "active" and key ~= "disabled" then style[key] = value end
	end
	for _, key in { "active", "hover", "pressed", "focus", "disabled" } do
		if state[key] then
			for name, value in (source or {})[key] or {} do
				assert(valid[name], "Unsupported state style: " .. tostring(name))
				style[name] = value
			end
		end
	end
	for key, value in style do style[key] = Theme.token(theme, value) end
	local props, decorations = {}, {}
	local text = className == "TextLabel" or className == "TextButton" or className == "TextBox"
	local image = className == "ImageLabel" or className == "ImageButton"
	if style.background then props.BackgroundColor3 = style.background end
	if style.backgroundTransparency ~= nil then props.BackgroundTransparency = style.backgroundTransparency end
	if text then
		if style.color then props.TextColor3 = style.color end
		if style.font then props.Font = style.font end
		if style.textSize then props.TextSize = style.textSize end
		if style.wrapped ~= nil then props.TextWrapped = style.wrapped end
		if style.richText ~= nil then props.RichText = style.richText end
		if style.textAlign then props.TextXAlignment = enum({left=Enum.TextXAlignment.Left, center=Enum.TextXAlignment.Center, right=Enum.TextXAlignment.Right}, style.textAlign, "textAlign") end
		if style.textYAlign then props.TextYAlignment = enum({top=Enum.TextYAlignment.Top, center=Enum.TextYAlignment.Center, bottom=Enum.TextYAlignment.Bottom}, style.textYAlign, "textYAlign") end
	end
	if image then
		if style.imageColor then props.ImageColor3 = style.imageColor end
		if style.imageTransparency ~= nil then props.ImageTransparency = style.imageTransparency end
	end
	if style.opacity ~= nil then
		assert(type(style.opacity) == "number" and style.opacity >= 0 and style.opacity <= 1, "Opacity must be 0..1")
		if className == "CanvasGroup" then props.GroupTransparency = 1 - style.opacity
		else
			props.BackgroundTransparency = 1 - style.opacity * (1 - (props.BackgroundTransparency or 0))
			if text then props.TextTransparency = 1 - style.opacity end
			if image then props.ImageTransparency = 1 - style.opacity end
		end
	end
	if style.width ~= nil or style.height ~= nil then
		local w, h = style.width or "100%", style.height or "auto"
		local aw, ah = w == "auto", h == "auto"
		local x, y = if aw then UDim.new() else dim(w), if ah then UDim.new() else dim(h)
		props.Size = UDim2.new(x.Scale, x.Offset, y.Scale, y.Offset)
		props.AutomaticSize = if aw and ah then Enum.AutomaticSize.XY elseif aw then Enum.AutomaticSize.X elseif ah then Enum.AutomaticSize.Y else Enum.AutomaticSize.None
	end
	if style.position then props.Position = style.position end
	if style.anchor then props.AnchorPoint = style.anchor end
	if style.visible ~= nil then props.Visible = style.visible end
	if style.zIndex then props.ZIndex = style.zIndex end
	if style.rotation then props.Rotation = style.rotation end
	if style.overflow then
		assert(style.overflow == "hidden" or style.overflow == "visible" or style.overflow == "scroll", "Invalid overflow")
		assert(style.overflow ~= "scroll" or className == "ScrollingFrame", "Use ScrollArea for scrolling")
		props.ClipsDescendants = style.overflow ~= "visible"
	end
	if className == "ScrollingFrame" and style.scrollbarColor then props.ScrollBarImageColor3 = style.scrollbarColor end
	if style.radius then decorations.corner = { class = "UICorner", CornerRadius = UDim.new(0, style.radius) } end
	if style.borderWidth and style.borderWidth > 0 then
		decorations.stroke = { class = "UIStroke", Thickness = style.borderWidth, Color = style.borderColor or theme.border,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,Transparency=style.borderTransparency or 0 }
	end
	if style.scale~=nil then
		assert(type(style.scale)=="number" and style.scale>0 and style.scale<math.huge,"Scale must be finite and positive")
		decorations.scale={class="UIScale",Scale=style.scale}
	end
	if style.gradient and style.gradient~=false then
		local gradient=style.gradient
		assert(type(gradient)=="table","gradient must be {from,to,rotation?,transparency?}")
		local from=Theme.token(theme,gradient.from or "$accent")
		local to=Theme.token(theme,gradient.to or "$accentDeep")
		assert(typeof(from)=="Color3" and typeof(to)=="Color3","Gradient endpoints must be Color3 values or color tokens")
		local alpha=gradient.transparency or {0,0}
		for _,value in {alpha[1] or 0,alpha[2] or 0} do assert(type(value)=="number" and value>=0 and value<=1,"Gradient transparency must be 0..1") end
		decorations.gradient={class="UIGradient",Color=ColorSequence.new(from,to),Rotation=gradient.rotation or 90,
			Offset=gradient.offset or Vector2.new(),Transparency=NumberSequence.new(alpha[1] or 0,alpha[2] or 0)}
	end
	if style.glow~=nil then
		assert(type(style.glow)=="number" and style.glow>=0 and style.glow<=1,"Glow must be 0..1")
		assert(not style.direction,"Glow needs a non-list host; put a glowing Frame around flow content")
		local color=style.glowColor or theme.accent
		decorations.halo={class="Frame",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,8,1,8),
			Position=UDim2.fromOffset(-4,-4),ZIndex=0,Active=false,Selectable=false}
		decorations.haloCorner={class="UICorner",parentKey="halo",CornerRadius=UDim.new(0,(style.radius or theme.radius.md)+4)}
		decorations.haloStroke={class="UIStroke",parentKey="halo",Color=color,Thickness=8,Transparency=1-style.glow*0.22,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}
	end
	if style.padding ~= nil or style.paddingX ~= nil or style.paddingY ~= nil then
		local padding = style.padding or 0
		local t, r, b, l
		if type(padding) == "table" then
			t, r, b, l = padding[1] or 0, padding[2] or 0, padding[3] or padding[1] or 0, padding[4] or padding[2] or 0
		else t, r, b, l = padding, padding, padding, padding end
		if style.paddingX then r, l = style.paddingX, style.paddingX end
		if style.paddingY then t, b = style.paddingY, style.paddingY end
		decorations.padding = { class = "UIPadding", PaddingTop = dim(t), PaddingRight = dim(r), PaddingBottom = dim(b), PaddingLeft = dim(l) }
	end
	if style.minWidth or style.maxWidth or style.minHeight or style.maxHeight then
		decorations.constraint = { class = "UISizeConstraint", MinSize = Vector2.new(style.minWidth or 0, style.minHeight or 0),
			MaxSize = Vector2.new(style.maxWidth or 100000, style.maxHeight or 100000) }
	end
	if style.direction then
		assert(style.direction == "row" or style.direction == "column", "Direction must be row or column")
		local layout = { class = "UIListLayout", FillDirection = if style.direction == "row" then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = dim(style.gap or 0),
			HorizontalAlignment = enum({start=Enum.HorizontalAlignment.Left,center=Enum.HorizontalAlignment.Center,["end"]=Enum.HorizontalAlignment.Right}, style.horizontalAlign or "start", "horizontalAlign"),
			VerticalAlignment = enum({start=Enum.VerticalAlignment.Top,center=Enum.VerticalAlignment.Center,["end"]=Enum.VerticalAlignment.Bottom}, style.verticalAlign or "start", "verticalAlign"),
			HorizontalFlex=Enum.UIFlexAlignment.None,VerticalFlex=Enum.UIFlexAlignment.None,Wraps=style.wrap or false }
		if style.distribute then
			local flex = enum({fill=Enum.UIFlexAlignment.Fill,between=Enum.UIFlexAlignment.SpaceBetween,around=Enum.UIFlexAlignment.SpaceAround,evenly=Enum.UIFlexAlignment.SpaceEvenly}, style.distribute, "distribute")
			layout[if style.direction == "row" then "HorizontalFlex" else "VerticalFlex"] = flex
		end
		if style.wrap ~= nil then layout.Wraps = style.wrap end
		decorations.layout = layout
	end
	if style.grow or style.shrink then
		decorations.flex = { class = "UIFlexItem", FlexMode = Enum.UIFlexMode.Custom, GrowRatio = style.grow or 0, ShrinkRatio = style.shrink or 0 }
	end
	return props, decorations
end
Style.dim = dim
return Style
