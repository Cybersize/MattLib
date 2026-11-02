-- Creates four independent windows; each menu can change its own design.
return function(MattLib)
	local app=MattLib.new({id="mattlib-design-selection"})
	local windows={}
	for index,design in app.Designs do
		local window=app:CreateWindow({Id=design,Title="MattLib / "..design,Design=design,Size={480,420},Position={20+(index-1)*50,20+(index-1)*36},OpenKey=false})
		local tab=window:AddTab({Title="Settings"})
		local section=tab:AddSection({Title="Choose your design"})
		section:AddDropdown({Title="Design",Options=app.Designs,Default=design,Callback=function(value) window:SetDesign(value) end})
		section:AddToggle({Id="enabled",Title="State survives design changes",Default=true})
		section:AddSlider({Id="level",Title="Level",Min=0,Max=100,Default=60})
		section:AddButton({Title="Try notification",Variant="primary",Callback=function() app:Notify({title=window:GetDesign(),message="Each window has its own design."}) end})
		table.insert(windows,window)
	end
	return {library=app,windows=windows,window=windows[1],Destroy=function() app:Destroy() end}
end
