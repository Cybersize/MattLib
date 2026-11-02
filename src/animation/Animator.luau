--!nonstrict
local Scope = require(script.Parent.Parent.utils.Scope)
local Diagnostics = require(script.Parent.Parent.utils.Diagnostics)
local Signal = require(script.Parent.Parent.core.Signal)
local Animator = {}
Animator.__index = Animator
function Animator.new(service, reducedMotion)
	return setmetatable({ service = service, reducedMotion = reducedMotion == true, motion=Signal.new(reducedMotion~=true), active = {},
		visualBases=setmetatable({},{__mode="k"}),alive = true }, Animator)
end
function Animator:RegisterVisual(instance,properties)
	local values={}
	for _,property in {"BackgroundTransparency","TextTransparency","ImageTransparency","Transparency"} do
		if type(properties[property])=="number" then values[property]=properties[property] end
	end
	self.visualBases[instance]=values
end
-- Fade the original native objects. CanvasGroup would rasterize and downsample their text.
function Animator:Fade(root,opacity,duration,options)
	options=options or {}
	local scope=Scope.new()
	local function visit(instance)
		if instance:GetAttribute("MattWallpaper")~=nil then return end
		if instance~=root and instance:IsA("GuiObject") and not instance.Visible then return end
		local goals={}
		for property,base in self.visualBases[instance] or {} do
			if base<1 then
				if options.from~=nil and not self.reducedMotion then instance[property]=1-(1-base)*options.from end
				local target=1-(1-base)*opacity
				if instance[property]~=target then goals[property]=target end
			end
		end
		if next(goals) then scope:Add(self:To(instance,goals,duration,{channel="native-fade"})) end
		for _,child in instance:GetChildren() do visit(child) end
	end
	visit(root)
	return function() scope:Destroy() end
end
function Animator:Cancel(instance, channel, finish)
	local channels = self.active[instance]
	local record = channels and channels[channel or "default"]
	if not record then return end
	channels[channel or "default"] = nil
	if next(channels) == nil then self.active[instance] = nil end
	record.scope:Destroy()
	record.tween:Cancel()
	Diagnostics.add("tweens", -1)
	if finish then for property, value in record.goals do instance[property] = value end end
	if finish and record.onComplete then record.onComplete() end
end
function Animator:To(instance, goals, duration, options)
	assert(self.alive, "Animator is destroyed")
	options = options or {}
	local channel = options.channel or "default"
	local previous=(self.active[instance] or {})[channel]
	if options.merge and previous then
		local combined=table.clone(previous.goals)
		for property,value in goals do combined[property]=value end
		goals=combined
	end
	self:Cancel(instance, channel)
	if self.reducedMotion or duration == 0 then
		for property, value in goals do instance[property] = value end
		if options.onComplete then options.onComplete() end
		return function() end
	end
	local tween = self.service:Create(instance, TweenInfo.new(duration or 0.18,
		options.easing or Enum.EasingStyle.Quad, options.direction or Enum.EasingDirection.Out,
		options.repeatCount or 0, options.reverses or false), goals)
	local record = { tween = tween, goals = goals, scope = Scope.new(),onComplete=options.onComplete }
	self.active[instance] = self.active[instance] or {}
	self.active[instance][channel] = record
	Diagnostics.add("tweens", 1)
	record.scope:Connect(tween.Completed, function(state)
		if (self.active[instance] or {})[channel] ~= record then return end
		self.active[instance][channel] = nil
		if next(self.active[instance]) == nil then self.active[instance] = nil end
		record.scope:Destroy()
		Diagnostics.add("tweens", -1)
		if state == Enum.PlaybackState.Completed and options.onComplete then options.onComplete() end
	end)
	tween:Play()
	return function() if (self.active[instance] or {})[channel] == record then self:Cancel(instance, channel) end end
end
function Animator:Forget(instance)
	local channels = self.active[instance]
	if channels then for channel in table.clone(channels) do self:Cancel(instance, channel) end end
	self.visualBases[instance]=nil
end
function Animator:SetReducedMotion(value)
	self.reducedMotion = value == true
	if self.reducedMotion then
		for instance, channels in table.clone(self.active) do
			for channel in table.clone(channels) do self:Cancel(instance, channel, true) end
		end
	end
	self.motion:set(not self.reducedMotion)
end
function Animator:Destroy()
	if not self.alive then return end
	for instance in table.clone(self.active) do self:Forget(instance) end
	self.motion:Destroy()
	self.alive = false
end
return Animator
