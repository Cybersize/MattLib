--!nonstrict
local Signal=require(script.Parent.Parent.core.Signal)
local Scope=require(script.Parent.Parent.utils.Scope)
local Notifications={}
Notifications.__index=Notifications
function Notifications.new(theme,animator)
	return setmetatable({signal=Signal.new({}),records={},serial=0,theme=theme,animator=animator},Notifications)
end
function Notifications:_publish()
	local items={}
	for _,record in self.records do table.insert(items,{id=record.id,options=table.clone(record.options),closing=record.closing}) end
	table.sort(items,function(a,b) return a.id<b.id end)
	self.signal:set(items)
end
function Notifications:_remove(id)
	local record=self.records[id]
	if not record then return end
	record.scope:Destroy(); self.records[id]=nil; self:_publish()
end
function Notifications:Dismiss(id)
	local record=self.records[id]
	if not record or record.closing then return end
	record.closing=true; self:_publish()
	if self.animator.reducedMotion then self:_remove(id)
	else record.scope:Delay(self.theme:Get().motion.normal,function() self:_remove(id) end) end
end
function Notifications:Push(options)
	options=options or {}
	local duration=if options.duration==nil then 5 else options.duration
	assert(duration==false or (type(duration)=="number" and duration>=0 and duration<math.huge),"Notification duration must be finite or false")
	self.serial+=1
	local id=self.serial
	local record={id=id,options=table.clone(options),scope=Scope.new(),closing=false}
	self.records[id]=record
	if duration~=false then record.scope:Delay(duration,function() self:Dismiss(id) end) end
	-- Bounded history keeps long-running notification producers from growing the tree indefinitely.
	local ids={}; for recordId in self.records do table.insert(ids,recordId) end; table.sort(ids)
	if #ids>8 then self:_remove(ids[1]) end
	self:_publish()
	local service=self
	return {id=id,Dismiss=function() service:Dismiss(id) end,Destroy=function() service:_remove(id) end,
		Update=function(_,patch)
			if not service.records[id] then return end
			for key,value in patch do record.options[key]=value end
			service:_publish()
		end}
end
function Notifications:Destroy()
	for _,record in self.records do record.scope:Destroy() end
	table.clear(self.records); self.signal:Destroy()
end
return Notifications
