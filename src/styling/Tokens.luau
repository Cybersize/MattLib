--!nonstrict
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local shared = {
	spacing = { none = 0, xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32 },
	radius = { sm = 4, md = 7, lg = 11, pill = 999 },
	typography = { font = Enum.Font.BuilderSans, medium = Enum.Font.BuilderSansMedium,
		bold = Enum.Font.BuilderSansBold, small = 12, body = 14, title = 18, display = 26 },
	motion = { fast = 0.12, normal = 0.18, slow = 0.24, reveal=0.22, tab=0.18, distance=10, stagger=0.04 },
	controlHeight = 38,
	design={name="Classic",label="Classic",navigation="sidebar",sidebarWidth=168,navHeight=44,titleHeight=44,section="card",indicator="line",inset=0},
	effects={intensity=1,glow=0,hoverScale=1.012,pressScale=0.975,gradient=0,ambient=0},
	control={switchWidth=40,switchHeight=22,thumbSize=16,switchRadius=999,rowHeight=44},
}
local Tokens = {}
Tokens.Dark = {
	background = rgb(17, 19, 25), surface = rgb(24, 27, 35), raised = rgb(31, 35, 45),
	input = rgb(20, 23, 30), border = rgb(48, 54, 68), accent = rgb(132, 153, 255),
	accentHover = rgb(153, 171, 255), accentPressed = rgb(109, 130, 232),
	accentText = rgb(15, 21, 42), hover = rgb(40, 45, 58), pressed = rgb(48, 54, 69),
	text = rgb(232, 236, 245), muted = rgb(154, 165, 185), subtle = rgb(113, 125, 148),
	disabled = rgb(82, 92, 112), danger = rgb(249, 119, 133), success = rgb(104, 210, 166),
	warning = rgb(239, 191, 104), overlay = rgb(3, 5, 12),
	accentDeep=rgb(109,130,232),accentSoft=rgb(33,42,63),chrome=rgb(24,27,35),
	profile=rgb(24,27,35),profileText=rgb(232,236,245),profileMuted=rgb(154,165,185),
}
Tokens.Light = {
	background = rgb(242, 244, 249), surface = rgb(255, 255, 255), raised = rgb(234, 238, 246),
	input = rgb(247, 249, 252), border = rgb(211, 218, 230), accent = rgb(77, 94, 205),
	accentHover = rgb(63, 80, 188), accentPressed = rgb(50, 65, 164),
	accentText = rgb(255, 255, 255), hover = rgb(229, 234, 245), pressed = rgb(218, 225, 239),
	text = rgb(28, 34, 49), muted = rgb(90, 104, 128), subtle = rgb(114, 125, 147),
	disabled = rgb(151, 160, 177), danger = rgb(185, 47, 69), success = rgb(26, 125, 87),
	warning = rgb(151, 99, 17), overlay = rgb(12, 17, 29),
	accentDeep=rgb(63,80,188),accentSoft=rgb(228,234,251),chrome=rgb(247,249,252),
	profile=rgb(255,255,255),profileText=rgb(28,34,49),profileMuted=rgb(90,104,128),
}
for _, theme in { Tokens.Dark, Tokens.Light } do
	for key, value in shared do theme[key] = value end
end
return Tokens
