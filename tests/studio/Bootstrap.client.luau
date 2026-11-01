local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Library=require(ReplicatedStorage:WaitForChild("MattLib"))
local Smoke=require(ReplicatedStorage:WaitForChild("AsterSmoke"))
local ok,result=xpcall(function() return Smoke(Library) end,debug.traceback)
if not ok then warn("MATTLIB_STUDIO_BOOT_FAILURE "..tostring(result)) end
local example=script:GetAttribute("Example") or "Gallery"
local factory=require(ReplicatedStorage:WaitForChild("AsterExamples"):WaitForChild(example))
local exampleOk,app=xpcall(function() return factory(Library) end,debug.traceback)
if exampleOk then
	print("MATTLIB_GALLERY_READY "..example)
	script.Destroying:Connect(function() app.Destroy() end)
else warn("MATTLIB_GALLERY_FAILURE "..tostring(app)) end
