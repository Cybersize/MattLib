--!nonstrict
local Signal=require(script.Parent.Parent.core.Signal)
local Config={}
Config.__index=Config
local function finite(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end
local function transform(value,decode,depth,seen)
	depth=depth or 0; seen=seen or {}
	assert(depth<=16,"Configuration nesting exceeds 16 levels")
	local kind=typeof(value)
	if kind=="Color3" and not decode then return {["$type"]="Color3",r=value.R,g=value.G,b=value.B} end
	if kind=="nil" or kind=="boolean" then return value end
	if kind=="number" then assert(finite(value),"Configuration numbers must be finite"); return value end
	if kind=="string" then assert(#value<=65536,"Configuration string is too large"); return value end
	assert(kind=="table","Unsupported configuration type: "..kind)
	assert(not seen[value],"Cyclic configuration table"); seen[value]=true
	if decode and value["$type"]~=nil then
		assert(value["$type"]=="Color3" and finite(value.r) and finite(value.g) and finite(value.b),"Invalid tagged configuration value")
		for _,channel in {value.r,value.g,value.b} do assert(channel>=0 and channel<=1,"Invalid color channel") end
		seen[value]=nil; return Color3.new(value.r,value.g,value.b)
	end
	local output,count,hasNumber,hasString={ },0,false,false
	for key,child in value do
		count+=1; assert(count<=4096,"Configuration table is too large")
		assert((type(key)=="string" and key~="$type") or (finite(key) and key>=1 and key%1==0),"Configuration keys must be strings or array indexes")
		if type(key)=="number" then hasNumber=true else hasString=true end
		output[key]=transform(child,decode,depth+1,seen)
	end
	assert(not (hasNumber and hasString),"Mixed configuration tables cannot be serialized predictably")
	if hasNumber then for index=1,count do assert(value[index]~=nil,"Configuration arrays must be dense") end end
	seen[value]=nil; return output
end
local function copy(value) return transform(transform(value,false),true) end
local function compatible(default,value)
	if typeof(default)~=typeof(value) then return false,"Expected "..typeof(default) end
	if type(default)=="table" then
		if #default>0 then
			for _,child in value do if typeof(child)~=typeof(default[1]) then return false,"Array item type changed" end end
		end
	end
	return true
end
function Config.new(http,capabilities,options)
	options=options or {}
	return setmetatable({http=http,capabilities=capabilities or {},entries={},memory={},migrations={},version=options.version or 1,folder=options.folder or "MattLib"},Config)
end
function Config:Register(id,signal,default,validate)
	assert(type(id)=="string" and #id>0 and #id<=128 and not self.entries[id],"Configuration ids must be nonempty and unique")
	assert(Signal.is(signal),"Config:Register requires a signal")
	assert(default~=nil,"Configuration defaults cannot be nil")
	local entry={signal=signal,default=copy(default),validate=validate}
	self.entries[id]=entry
	return function() if self.entries[id]==entry then self.entries[id]=nil end end
end
function Config:RegisterMigration(fromVersion,migrate)
	assert(type(fromVersion)=="number" and fromVersion%1==0 and type(migrate)=="function","Invalid migration")
	self.migrations[fromVersion]=migrate
end
function Config:Export()
	local ok,result=pcall(function()
		local values={}
		for id,entry in self.entries do
			local current=entry.signal:get()
			local valid,reason=compatible(entry.default,current); assert(valid,"Invalid "..id..": "..tostring(reason))
			if entry.validate then valid,reason=entry.validate(current); assert(valid,"Invalid "..id..": "..tostring(reason or "validation failed")) end
			values[id]=transform(current,false)
		end
		return self.http:JSONEncode({schema="mattlib/config",version=self.version,values=values})
	end)
	if ok then return result end
	return nil,tostring(result)
end
function Config:Import(json,options)
	local ok,result=pcall(function()
		assert(type(json)=="string" and #json<=1048576,"Configuration must be a JSON string under 1 MiB")
		local data=self.http:JSONDecode(json)
		assert(type(data)=="table" and data.schema=="mattlib/config" and type(data.version)=="number" and data.version%1==0,"Invalid configuration schema")
		assert(data.version>=1 and data.version<=self.version,"Unsupported configuration version")
		while data.version<self.version do
			local migrate=self.migrations[data.version]
			assert(migrate,"Missing configuration migration")
			local previous=data.version
			data=migrate(data)
			assert(type(data)=="table" and data.version==previous+1,"Migration must advance exactly one version")
		end
		assert(type(data.values)=="table","Missing configuration values")
		local updates={}
		for id,encoded in data.values do
			local entry=self.entries[id]
			if not entry then assert(not (options and options.strict),"Unknown configuration id: "..tostring(id))
			else
				local value=transform(encoded,true)
				local valid,reason=compatible(entry.default,value)
				assert(valid,"Invalid "..id..": "..tostring(reason))
				if entry.validate then valid,reason=entry.validate(value); assert(valid,"Invalid "..id..": "..tostring(reason or "validation failed")) end
				table.insert(updates,{signal=entry.signal,value=value})
			end
		end
		Signal.batch(function() for _,update in updates do update.signal:set(update.value) end end)
		return true
	end)
	if ok then return result end
	return false,tostring(result)
end
function Config:Reset()
	Signal.batch(function() for _,entry in self.entries do entry.signal:set(copy(entry.default)) end end)
end
function Config:_path(name)
	assert(type(name)=="string" and #name>0 and #name<=64 and string.match(name,"^[%w_-]+$"),"Profile names use only letters, numbers, _ and -")
	assert(not string.find(self.folder,"..",1,true) and not string.match(self.folder,"^[/\\]") and not string.find(self.folder,":",1,true),"Configuration folder must be a relative path")
	return self.folder.."/"..name..".json"
end
function Config:Save(name)
	local json,err=self:Export(); if not json then return false,err end
	local ok,result=pcall(function()
		local path=self:_path(name)
		if not self.capabilities.writefile then self.memory[path]=json; return "memory" end
		if self.capabilities.makefolder and (not self.capabilities.isfolder or not self.capabilities.isfolder(self.folder)) then self.capabilities.makefolder(self.folder) end
		self.capabilities.writefile(path,json); self.memory[path]=json; return "file"
	end)
	return ok,if ok then result else tostring(result)
end
function Config:Load(name)
	local ok,result=pcall(function()
		local path=self:_path(name)
		if self.memory[path] and not self.capabilities.writefile then return self.memory[path] end
		if self.capabilities.readfile then
			if self.capabilities.isfile then assert(self.capabilities.isfile(path),"Configuration profile does not exist") end
			return self.capabilities.readfile(path)
		end
		assert(self.memory[path],"Configuration profile does not exist")
		return self.memory[path]
	end)
	if not ok then return false,tostring(result) end
	return self:Import(result)
end
function Config:Destroy() table.clear(self.entries); table.clear(self.memory) end
return Config
