--!nonstrict
local Theme=require(script.Parent.Theme)
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local presets={
	MintGlass={
		label="Mint Glass",description="Luminous mint, translucent surfaces, a spacious sidebar.",
		tokens={background=rgb(10,18,22),surface=rgb(16,27,32),raised=rgb(23,38,43),input=rgb(12,23,28),chrome=rgb(13,23,28),
			border=rgb(43,72,76),accent=rgb(104,240,203),accentHover=rgb(139,255,222),accentPressed=rgb(67,205,174),accentDeep=rgb(31,181,162),accentSoft=rgb(24,60,56),accentText=rgb(4,29,26),
			text=rgb(239,249,246),muted=rgb(159,185,190),subtle=rgb(104,132,140),
			profile=rgb(16,27,32),profileText=rgb(239,249,246),profileMuted=rgb(159,185,190),
			design={name="MintGlass",label="Mint Glass",navigation="sidebar",sidebarWidth=188,navHeight=48,titleHeight=44,section="glass",indicator="rail",inset=0},
			radius={sm=5,md=8,lg=12,pill=999},effects={intensity=1,glow=0.65,hoverScale=1.018,pressScale=0.97,gradient=1,ambient=0.12},
			motion={fast=0.12,normal=0.18,slow=0.24,reveal=0.22,tab=0.18,distance=10,stagger=0.04}},
	},
	Ember={
		label="Ember",description="Matte carbon, warm orange, top tabs and precise separators.",
		tokens={background=rgb(22,21,20),surface=rgb(29,28,26),raised=rgb(39,37,34),input=rgb(23,22,21),chrome=rgb(26,25,23),
			border=rgb(67,61,54),accent=rgb(255,108,34),accentHover=rgb(255,140,71),accentPressed=rgb(224,78,15),accentDeep=rgb(222,76,14),accentSoft=rgb(65,38,24),accentText=rgb(28,12,3),
			text=rgb(249,244,234),muted=rgb(183,176,164),subtle=rgb(125,119,109),
			profile=rgb(246,239,225),profileText=rgb(31,28,24),profileMuted=rgb(105,95,82),
			design={name="Ember",label="Ember",navigation="top",sidebarWidth=64,navHeight=46,titleHeight=48,section="ruled",indicator="underline",inset=0},
			radius={sm=3,md=5,lg=7,pill=999},spacing={none=0,xs=4,sm=8,md=12,lg=16,xl=24,xxl=32},
			controlHeight=36,control={switchWidth=38,switchHeight=20,thumbSize=14,switchRadius=5,rowHeight=42},
			effects={intensity=1,glow=0.16,hoverScale=1.009,pressScale=0.95,gradient=0.35,ambient=0.025},
			motion={fast=0.1,normal=0.18,slow=0.22,reveal=0.2,tab=0.18,distance=8,stagger=0.04}},
	},
	Vector={
		label="Vector",description="Cobalt precision, compact controls and a workspace tree.",
		tokens={background=rgb(10,18,29),surface=rgb(15,27,42),raised=rgb(23,39,58),input=rgb(10,22,36),chrome=rgb(14,27,43),
			border=rgb(44,65,88),accent=rgb(57,123,255),accentHover=rgb(90,151,255),accentPressed=rgb(33,96,220),accentDeep=rgb(31,101,232),accentSoft=rgb(16,51,96),accentText=rgb(246,250,255),
			text=rgb(234,243,255),muted=rgb(150,178,210),subtle=rgb(100,128,160),
			profile=rgb(15,27,42),profileText=rgb(234,243,255),profileMuted=rgb(150,178,210),
			design={name="Vector",label="Vector",navigation="tree",sidebarWidth=206,navHeight=40,titleHeight=40,section="inspector",indicator="block",inset=0},
			radius={sm=2,md=4,lg=5,pill=999},spacing={none=0,xs=3,sm=6,md=10,lg=12,xl=20,xxl=28},
			typography={small=11,body=13,title=17,display=25},controlHeight=34,
			control={switchWidth=38,switchHeight=20,thumbSize=14,switchRadius=999,rowHeight=38},
			effects={intensity=1,glow=0,hoverScale=1,pressScale=0.985,gradient=0.2,ambient=0.025},
			motion={fast=0.1,normal=0.16,slow=0.2,reveal=0.2,tab=0.18,distance=6,stagger=0.025}},
	},
	Aura={
		label="Aura",description="Lavender depth, plush surfaces and floating pill navigation.",
		tokens={background=rgb(26,22,37),surface=rgb(37,31,51),raised=rgb(49,40,66),input=rgb(29,24,42),chrome=rgb(31,25,45),
			border=rgb(76,61,96),accent=rgb(205,166,255),accentHover=rgb(225,196,255),accentPressed=rgb(178,134,235),accentDeep=rgb(161,113,224),accentSoft=rgb(66,43,89),accentText=rgb(37,19,58),
			text=rgb(251,244,255),muted=rgb(190,174,210),subtle=rgb(133,113,156),
			profile=rgb(49,40,66),profileText=rgb(251,244,255),profileMuted=rgb(190,174,210),
			design={name="Aura",label="Aura",navigation="pills",sidebarWidth=184,navHeight=60,titleHeight=54,section="soft",indicator="pill",inset=14},
			radius={sm=8,md=13,lg=18,pill=999},spacing={none=0,xs=5,sm=10,md=14,lg=20,xl=28,xxl=36},controlHeight=42,
			control={switchWidth=46,switchHeight=26,thumbSize=20,switchRadius=999,rowHeight=48},
			effects={intensity=1,glow=0.55,hoverScale=1.025,pressScale=0.965,gradient=1,ambient=0.16},
			motion={fast=0.14,normal=0.2,slow=0.28,reveal=0.24,tab=0.18,distance=14,stagger=0.04}},
	},
}
local Designs={Names=table.freeze({"MintGlass","Ember","Vector","Aura"})}
function Designs.get(name)
	assert(type(name)=="string" and presets[name],"Unknown MattLib design: "..tostring(name)..". Choose MintGlass, Ember, Vector, or Aura.")
	return presets[name]
end
function Designs.resolve(name,theme)
	local preset=Designs.get(name)
	local result=Theme.merge(Theme.resolve("Dark"),preset.tokens)
	if theme~=nil and theme~="Dark" then
		if type(theme)=="string" then
			local palette=Theme.resolve(theme)
			for _,key in {"background","surface","raised","input","chrome","border","text","muted","subtle","disabled","danger","success","warning","overlay","profile","profileText","profileMuted"} do result[key]=palette[key] end
		else result=Theme.merge(result,theme) end
	end
	result.design=Theme.merge(preset.tokens.design,{})
	return Theme.resolve(result)
end
function Designs.list()
	local list={}
	for _,name in Designs.Names do local preset=presets[name]; table.insert(list,{name=name,label=preset.label,description=preset.description}) end
	return list
end
return Designs
