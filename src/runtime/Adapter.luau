--!nonstrict
local Scope = require(script.Parent.Parent.utils.Scope)
local Signal = require(script.Parent.Parent.core.Signal)
local Diagnostics = require(script.Parent.Parent.utils.Diagnostics)
local Adapter = {}
Adapter.__index = Adapter
function Adapter.capabilities(overrides)
	local environment = getfenv(0)
	local result = {}
	for _, name in { "gethui", "readfile", "writefile", "isfile", "makefolder", "isfolder" } do
		local value = if overrides then overrides[name] else environment[name]
		if type(value) == "function" then result[name] = value end
	end
	return result
end
function Adapter.parent(services, capabilities, explicit)
	if explicit then
		assert(typeof(explicit) == "Instance", "parent must be a Roblox Instance")
		return explicit, "explicit"
	end
	if capabilities.gethui then
		local ok, parent = pcall(capabilities.gethui)
		if ok and typeof(parent) == "Instance" then return parent, "gethui" end
	end
	local player = services.Players.LocalPlayer
	assert(player, "MattLib runs on the client. Use a LocalScript in Studio Play mode.")
	return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10), "PlayerGui"
end
local function make(self, className, name, parent)
	local instance = Instance.new(className)
	Diagnostics.add("instances", 1)
	self.scope:Add(function() instance:Destroy(); Diagnostics.add("instances", -1) end)
	instance.Name, instance.Parent = name, parent
	return instance
end
function Adapter.new(options, onDestroy)
	options = options or {}
	local services = {}
	for _, name in { "Players", "UserInputService", "GuiService", "TweenService", "HttpService", "RunService" } do services[name] = game:GetService(name) end
	local capabilities = Adapter.capabilities(options.capabilities)
	local parent, mode = Adapter.parent(services, capabilities, options.parent)
	assert(parent, "PlayerGui is unavailable")
	local id = options.id or "default"
	assert(type(id) == "string" and #id > 0, "Library id must be a nonempty string")
	local name = "MattLib:" .. id
	for _, previous in parent:GetChildren() do
		if previous.Name == name and previous:GetAttribute("MattLibRoot") == true then
			local dispose = previous:FindFirstChild("__AsterDispose")
			if dispose and dispose:IsA("BindableFunction") then pcall(function() dispose:Invoke() end) end
			previous:Destroy()
		end
	end
	local self = setmetatable({scope=Scope.new(), services=services, capabilities=capabilities, parentMode=mode, alive=true}, Adapter)
	self.screen = make(self, "ScreenGui", name, parent)
	self.screen.ResetOnSpawn, self.screen.ZIndexBehavior = false, Enum.ZIndexBehavior.Sibling
	self.screen.DisplayOrder = options.displayOrder or 50
	self.screen.IgnoreGuiInset = false
	-- Older clients keep the standard IgnoreGuiInset=false behavior.
	pcall(function() self.screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets; self.screen.ClipToDeviceSafeArea = true end)
	self.screen:SetAttribute("MattLibRoot", true)
	local dispose = make(self, "BindableFunction", "__AsterDispose", self.screen)
	dispose.OnInvoke = onDestroy
	self.scope:Connect(self.screen.Destroying, function() if self.alive then onDestroy() end end)
	self.layers = {}
	for index, layerName in { "main", "overlay", "toast" } do
		local layer = make(self, "Frame", layerName, self.screen)
		layer.Size, layer.BackgroundTransparency, layer.BorderSizePixel = UDim2.fromScale(1, 1), 1, 0
		layer.ZIndex = index * 1000
		self.layers[layerName] = layer
	end
	local camera=workspace.CurrentCamera
	self.viewport = Signal.new(if camera then camera.ViewportSize else Vector2.new(800,600))
	self.layoutReady=false
	self.scope:Connect(self.layers.main:GetPropertyChangedSignal("AbsoluteSize"), function()
		if self.layoutReady then self.viewport:set(self.layers.main.AbsoluteSize) end
	end)
	-- Read engine layout after its first frame; freshly parented GUI sizes can be provisional.
	local disconnect
	disconnect=self.scope:Connect(services.RunService.Heartbeat,function()
		disconnect(); self.layoutReady=true
		self.viewport:set(self.layers.main.AbsoluteSize)
	end)
	return self
end
function Adapter:Destroy()
	if not self.alive then return end
	self.alive = false
	self.scope:Destroy()
	self.viewport:Destroy()
end
return Adapter
