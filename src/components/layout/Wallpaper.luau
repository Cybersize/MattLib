--!nonstrict
local Element=require(script.Parent.Parent.Parent.core.Element)
local Hooks=require(script.Parent.Parent.Parent.core.Hooks)
local Scope=require(script.Parent.Parent.Parent.utils.Scope)
local Style=require(script.Parent.Parent.Parent.styling.StyleResolver)
local h=Element.h
local Wallpaper={}
local white=Color3.new(1,1,1)
local function point(curve,t,w,hgt)
	local u=1-t
	return (u^3*curve[1][1]+3*u*u*t*curve[2][1]+3*u*t*t*curve[3][1]+t^3*curve[4][1])*w,
		(u^3*curve[1][2]+3*u*u*t*curve[2][2]+3*u*t*t*curve[3][2]+t^3*curve[4][2])*hgt
end
local paths={
	MintGlass={{{-0.12,1.12},{0.02,0.13},{0.68,1.12},{1.12,-0.12}},{{0.16,1.2},{0.46,0.1},{0.94,1.04},{1.15,0.14}}},
	Ember={{{0.12,1.2},{0.55,0.96},{0.74,0.3},{1.14,0.22}},{{0.35,1.23},{0.65,0.84},{0.86,0.49},{1.14,0.48}}},
	Aura={{{-0.14,0.92},{0.48,-0.42},{0.46,1.57},{1.15,-0.02}},{{-0.08,0.34},{0.38,1.55},{0.64,-0.22},{1.14,0.72}}},
}
local function ribbons(theme,w,hgt,index,intensity)
	local name=theme.design.name
	local curve=(paths[name] or paths.MintGlass)[index]
	local steps=if index==1 then 26 else 20
	local thickness=math.min(w,hgt)*(if name=="Aura" then 0.17 elseif name=="Ember" then 0.075 else 0.105)
	local strength=(if name=="Aura" then 0.43 elseif name=="Ember" then 0.27 else 0.38)*intensity
	local elements={}
	for step=1,steps do
		local t=(step-0.5)/steps
		local x1,y1=point(curve,(step-1)/steps,w,hgt)
		local x2,y2=point(curve,step/steps,w,hgt)
		local dx,dy=x2-x1,y2-y1
		local x,y=(x1+x2)/2,(y1+y2)/2
		local length=math.sqrt(dx*dx+dy*dy)+1.5
		local angle=math.deg(math.atan2(dy,dx))
		local envelope=math.sin(math.pi*t)^0.6
		local breadth=math.max(1,thickness*(0.22+0.78*math.sin(math.pi*t)^1.6))
		for side=1,2 do
			local sign=if side==1 then 1 else -1
			table.insert(elements,h("Frame",{key=step..":"..side,motion=false,style={width=length,height=breadth,
				position=UDim2.fromOffset(x-dy/(length-1.5)*breadth*sign/2,y+dx/(length-1.5)*breadth*sign/2),
				anchor=Vector2.new(0.5,0.5),rotation=angle,background=white,backgroundTransparency=1-strength*envelope,
				gradient={from=if index==1 then "$accent" else "$accentDeep",to="$background",rotation=if side==1 then 90 else 270,transparency={0.12,1}}}}))
		end
		table.insert(elements,h("Frame",{key=step..":edge",motion=false,style={width=length,height=1,position=UDim2.fromOffset(x,y),anchor=Vector2.new(0.5,0.5),
			rotation=angle,background="$accent",backgroundTransparency=1-strength*envelope*0.7}}))
	end
	return elements
end
local function grid(theme,w,hgt,intensity)
	local elements={}
	for x=0,math.min(64,math.ceil(w/36)) do
		table.insert(elements,h("Frame",{key="x"..x,motion=false,style={width=1,height="100%",position=UDim2.fromOffset(x*36,0),background="$accent",backgroundTransparency=1-0.065*intensity}}))
	end
	for y=0,math.min(48,math.ceil(hgt/36)) do
		table.insert(elements,h("Frame",{key="y"..y,motion=false,style={width="100%",height=1,position=UDim2.fromOffset(0,y*36),background="$accent",backgroundTransparency=1-0.065*intensity}}))
	end
	return elements
end
function Wallpaper.Wallpaper(p)
	local env=Hooks.useEnvironment()
	local theme=Hooks.useTheme()
	Hooks.useSignal(env.runtime.wallpaper.signal)
	local texture=env.runtime.wallpaper:Get(theme.design.name)
	local image=p.image or (texture and texture.uri)
	local atlas=p.image==nil and texture~=nil and texture.atlas
	local ref,first,second=Hooks.useRef(nil),Hooks.useRef(nil),Hooks.useRef(nil)
	local size,setSize=Hooks.useState(Vector2.new(800,500))
	local speed=p.speed or 1
	local opacity=p.opacity or 1
	assert(type(speed)=="number" and speed>0 and speed<=4,"Wallpaper speed must be > 0 and <= 4")
	assert(type(opacity)=="number" and opacity>=0 and opacity<=1,"Wallpaper opacity must be 0..1")
	local intensity=theme.effects.intensity*opacity
	Hooks.useEffect(function()
		if p.image==nil and intensity>0 then env.runtime.wallpaper:Load(theme.design.name) end
	end,{theme.design.name,p.image,intensity})
	Hooks.useEffect(function()
		local function measure()
			local nextSize=ref.current.AbsoluteSize
			if nextSize.X>0 and nextSize.Y>0 then setSize(Vector2.new(math.floor(nextSize.X+0.5),math.floor(nextSize.Y+0.5))) end
		end
		local connection=ref.current:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure); measure()
		return function() connection:Disconnect() end
	end,{})
	Hooks.useEffect(function()
		local scope=Scope.new()
		local motion=Scope.new()
		local ancestors={}
		local node=ref.current
		while node do
			if node:IsA("GuiObject") or node:IsA("ScreenGui") then table.insert(ancestors,node) end
			node=node.Parent
		end
		local function refresh()
			motion:Destroy(); motion=Scope.new()
			local running=p.active~=false and p.motion~=false and intensity>0 and not env.animator.reducedMotion
			for _,ancestor in ancestors do
				if ancestor:IsA("GuiObject") and not ancestor.Visible then running=false end
				if ancestor:IsA("ScreenGui") and not ancestor.Enabled then running=false end
			end
			ref.current:SetAttribute("MattWallpaperAnimated",running)
			if not running then return end
			if atlas and first.current then first.current.Position=UDim2.new(); first.current.Rotation=0 end
			for index,layer in {first.current,second.current} do
				if layer and not (atlas and index==1) then
					layer.Position=UDim2.new(); layer.Rotation=0
					local direction=if index==1 then 1 else -1
					motion:Add(env.animator:To(layer,{Position=UDim2.fromOffset(direction*18,-direction*12),Rotation=direction*2},(if index==1 then 12 else 17)/speed,
						{channel="wallpaper",repeatCount=-1,reverses=true,easing=Enum.EasingStyle.Sine,direction=Enum.EasingDirection.InOut}))
				end
			end
		end
		for _,ancestor in ancestors do scope:Connect(ancestor:GetPropertyChangedSignal(if ancestor:IsA("ScreenGui") then "Enabled" else "Visible"),refresh) end
		scope:Add(env.animator.motion:subscribe(refresh))
		refresh()
		return function() motion:Destroy(); scope:Destroy() end
	end,{theme.design.name,intensity,p.active,p.motion,speed,image,atlas})
	local artwork={}
	if intensity>0 then
		if image then
			assert(type(image)=="string" or type(image)=="number","Wallpaper image must be an asset URI or id")
			-- Crop legacy atlases with geometry; new files each contain one full-resolution design.
			local column=if theme.design.name=="Ember" or theme.design.name=="Aura" then 1 else 0
			local row=if theme.design.name=="Vector" or theme.design.name=="Aura" then 1 else 0
			local coverWidth=math.max(size.X,size.Y*1.5)
			local coverHeight=math.max(size.Y,size.X/1.5)
			table.insert(artwork,h("Frame",{key="image",ref=first,motion=false,style={width="100%",height="100%"}},
				h("@ImageLabel",{name="WallpaperImage",native={Image=if type(image)=="number" then "rbxassetid://"..image else image,
					ScaleType=if atlas then Enum.ScaleType.Stretch else Enum.ScaleType.Crop,ResampleMode=Enum.ResamplerMode.Default},
					style={width=if atlas then coverWidth*2 else "108%",height=if atlas then coverHeight*2 else "108%",
						position=if atlas then UDim2.fromOffset((size.X-coverWidth)/2-column*coverWidth,(size.Y-coverHeight)/2-row*coverHeight) else UDim2.fromScale(-0.04,-0.04),
						backgroundTransparency=1,imageTransparency=1-intensity}})))
			table.insert(artwork,h("Frame",{key="light",ref=second,name="WallpaperLight",motion=false,style={width="100%",height="100%"}},
				h("Frame",{style={width="70%",height="140%",position=UDim2.fromScale(0.48,-0.1),rotation=24,background=white,backgroundTransparency=1-0.08*intensity,
					gradient={from="$accent",to="$background",rotation=0,transparency={0.7,1}}}})))
		elseif theme.design.name=="Vector" then
			table.insert(artwork,h("Frame",{key="grid",name="WallpaperGrid",style={width="100%",height="100%"}},grid(theme,size.X,size.Y,intensity)))
			table.insert(artwork,h("Frame",{key="scan",ref=first,name="WallpaperScan",motion=false,style={width="100%",height="100%"}}, {
				h("Frame",{style={width="75%",height="130%",position=UDim2.fromScale(0.5,-0.1),rotation=22,background=white,backgroundTransparency=1-0.16*intensity,
					gradient={from="$accent",to="$background",rotation=0,transparency={0.7,1}}}}),
			}))
		else
			for index,layer in {first,second} do
				table.insert(artwork,h("Frame",{key="ribbon"..index,ref=layer,name="WallpaperRibbon"..index,motion=false,
					style={width="100%",height="100%"}},ribbons(theme,size.X,size.Y,index,intensity)))
			end
		end
	end
	return h("Frame",{ref=ref,name=p.name or "Wallpaper",motion=false,attributes={MattWallpaper=theme.design.name,MattWallpaperMode=if image then "texture" else "native"},
		style=Style.merge({width="100%",height="100%",overflow="hidden",zIndex=0},p.style)},artwork)
end
return Wallpaper
