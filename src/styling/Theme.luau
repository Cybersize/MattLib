--!nonstrict
local Signal = require(script.Parent.Parent.core.Signal)
local Tokens = require(script.Parent.Tokens)
local Theme = {}
Theme.__index = Theme
local function copy(value,depth,seen)
	if typeof(value) ~= "table" then return value end
	depth,seen=depth or 0,seen or {}
	assert(depth<=16 and not seen[value],"Theme tokens must be acyclic tables under 16 levels")
	seen[value]=true
	local output = {}
	for key, child in value do output[key] = copy(child,depth+1,seen) end
	seen[value]=nil
	return output
end
local function validate(value,expected,path)
	assert(typeof(value)==typeof(expected),"Invalid theme token: "..path)
	if typeof(expected)=="table" then
		for key,child in expected do validate(value[key],child,path.."."..key) end
	elseif type(expected)=="number" then
		assert(value==value and value>=0 and value<math.huge,"Theme numeric tokens must be finite and nonnegative: "..path)
	elseif typeof(expected)=="EnumItem" then
		assert(value.EnumType==expected.EnumType,"Invalid enum token: "..path)
	end
end
local function merge(base, overrides)
	local result = copy(base)
	for key, value in overrides or {} do
		if typeof(value) == "table" and typeof(result[key]) == "table" then result[key] = merge(result[key], value)
		else result[key] = copy(value) end
	end
	return result
end
local function freeze(value)
	if typeof(value) == "table" and not table.isfrozen(value) then
		for _, child in value do freeze(child) end
		table.freeze(value)
	end
	return value
end
function Theme.resolve(theme)
	if type(theme) == "string" then
		assert(Tokens[theme], "Unknown theme " .. theme)
		return freeze(copy(Tokens[theme]))
	end
	assert(type(theme) == "table", "Theme must be Dark, Light, or a token table")
	local resolved = merge(Tokens.Dark, theme)
	for key, expected in Tokens.Dark do validate(resolved[key],expected,key) end
	return freeze(resolved)
end
function Theme.new(theme)
	return setmetatable({ signal = Signal.new(Theme.resolve(theme or "Dark")) }, Theme)
end
function Theme:Set(theme)
	local resolved=Theme.resolve(theme)
	if not (type(theme)=="table" and theme.design) then
		local current=self:Get()
		-- Palette changes retain the selected design's geometry, effects and motion.
		for _,key in {"design","radius","spacing","motion","control","controlHeight","effects"} do resolved=merge(resolved,{[key]=current[key]}) end
	end
	self.signal:set(freeze(resolved))
end
function Theme:Get() return self.signal:get() end
function Theme:Extend(overrides) self:Set(merge(self:Get(), overrides)) end
function Theme:Destroy() self.signal:Destroy() end
function Theme.token(theme, value)
	if type(value) ~= "string" or string.sub(value, 1, 1) ~= "$" then return value end
	local result = theme
	for segment in string.gmatch(string.sub(value, 2), "[^.]+") do
		assert(type(result) == "table" and result[segment] ~= nil, "Unknown theme token " .. value)
		result = result[segment]
	end
	return result
end
Theme.merge = merge
return Theme
