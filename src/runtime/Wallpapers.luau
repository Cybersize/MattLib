--!nonstrict
local Signal=require(script.Parent.Parent.core.Signal)
local Wallpapers={}
Wallpapers.__index=Wallpapers
local url="https://raw.githubusercontent.com/Cybersize/MattLib/main/assets/wallpapers-v1.png"
local cache="MattLib/wallpapers-v1.png"
local function png(data)
	-- A bounded PNG atlas, with the dimensions used by ImageRectOffset/ImageRectSize.
	return type(data)=="string" and #data>=32 and #data<=5*1024*1024 and string.sub(data,1,8)=="\137PNG\r\n\26\n"
		and string.sub(data,13,16)=="IHDR" and string.sub(data,17,24)==string.char(0,0,6,0,0,0,4,0)
end
function Wallpapers.new(options,capabilities)
	local self=setmetatable({signal=Signal.new(nil),mode="native",alive=true},Wallpapers)
	if options.wallpaperImage~=nil then
		assert(type(options.wallpaperImage)=="number" or type(options.wallpaperImage)=="string","wallpaperImage must be the wallpaper atlas asset id or URI")
		self.signal:set(options.wallpaperImage); self.mode="texture"; return self
	end
	local asset=capabilities.getcustomasset or capabilities.getsynasset
	if options.wallpaperAssets==false or not asset or not capabilities.readfile or not capabilities.writefile then return self end
	self.mode="loading"
	self.thread=task.defer(function()
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
				assert(png(data),"Wallpaper response is not the expected PNG atlas")
				if not self.alive then return end
				if capabilities.makefolder then pcall(capabilities.makefolder,"MattLib") end
				capabilities.writefile(cache,data)
			end
			if not self.alive then return end
			local image=asset(cache)
			assert(type(image)=="string" and #image>0,"Image adapter returned no asset URI")
			self.mode="texture"; self.signal:set(image)
		end)
		if not ok and self.alive then self.mode="native"; self.error=tostring(err) end
	end)
	return self
end
function Wallpapers:Destroy()
	if not self.alive then return end
	self.alive=false
	if self.thread then pcall(task.cancel,self.thread) end
	self.signal:Destroy()
end
return Wallpapers
