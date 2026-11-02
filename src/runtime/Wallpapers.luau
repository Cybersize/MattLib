--!nonstrict
local Signal=require(script.Parent.Parent.core.Signal)
local Wallpapers={}
Wallpapers.__index=Wallpapers
local names={MintGlass="mint-glass",Ember="ember",Vector="vector",Aura="aura"}
local function png(data)
	return type(data)=="string" and #data>=32 and #data<=5*1024*1024 and string.sub(data,1,8)=="\137PNG\r\n\26\n"
		and string.sub(data,13,16)=="IHDR" and string.sub(data,17,24)==string.char(0,0,6,0,0,0,4,0)
end
local function image(value)
	return type(value)=="number" or (type(value)=="string" and #value>0)
end
function Wallpapers.new(options,capabilities)
	local self=setmetatable({signal=Signal.new(0),images={},modes={},errors={},threads={},alive=true,options=options,capabilities=capabilities},Wallpapers)
	if options.wallpaperImage~=nil then
		assert(image(options.wallpaperImage),"wallpaperImage must be an atlas asset id or URI")
		for name in names do self.images[name]={uri=options.wallpaperImage,atlas=true}; self.modes[name]="texture" end
	end
	if options.wallpaperImages~=nil then
		assert(type(options.wallpaperImages)=="table","wallpaperImages must map design names to image URIs")
		for name,value in options.wallpaperImages do
			assert(names[name] and image(value),"wallpaperImages needs a known design name and image URI")
			self.images[name]={uri=value,atlas=false}; self.modes[name]="texture"
		end
	end
	return self
end
function Wallpapers:Get(name) return self.images[name] end
function Wallpapers:Status(name) return self.modes[name] or "native",self.errors[name] end
function Wallpapers:Load(name)
	if not names[name] then return end
	if not self.alive or self.images[name] or self.modes[name]=="loading" or self.errors[name] then return end
	local capabilities=self.capabilities
	local asset=capabilities.getcustomasset or capabilities.getsynasset
	if self.options.wallpaperAssets==false or not asset or not capabilities.readfile or not capabilities.writefile then return end
	self.modes[name]="loading"
	local filename=names[name].."-v2.png"
	local url="https://raw.githubusercontent.com/Cybersize/MattLib/main/assets/wallpapers/"..filename
	local cache="MattLib/wallpaper-"..filename
	self.threads[name]=task.defer(function()
		if not self.alive then return end
		local ok,err=pcall(function()
			local readable,data=pcall(capabilities.readfile,cache)
			if not readable or not png(data) then
				if capabilities.httpget then data=capabilities.httpget(url)
				elseif capabilities.request or capabilities.http_request then
					local response=(capabilities.request or capabilities.http_request)({Url=url,Method="GET"})
					assert(type(response)=="table" and response.StatusCode==200,"Wallpaper request failed")
					data=response.Body
				else data=game:HttpGet(url) end
				assert(png(data),"Wallpaper response is not the expected 1536x1024 PNG")
				if not self.alive then return end
				if capabilities.makefolder then pcall(capabilities.makefolder,"MattLib") end
				capabilities.writefile(cache,data)
			end
			if not self.alive then return end
			local uri=asset(cache)
			assert(type(uri)=="string" and #uri>0,"Image adapter returned no asset URI")
			self.images[name]={uri=uri,atlas=false}; self.modes[name]="texture"
			self.signal:update(function(revision) return revision+1 end)
		end)
		if not ok and self.alive then self.modes[name]="native"; self.errors[name]=tostring(err) end
	end)
end
function Wallpapers:Destroy()
	if not self.alive then return end
	self.alive=false
	for _,thread in self.threads do pcall(task.cancel,thread) end
	self.signal:Destroy()
end
return Wallpapers
