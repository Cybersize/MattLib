return function(Library)
	local app=Library.new({id="mattlib-dashboard"})
	local UI=app.UI; local h=UI.h
	local initial={{id=1,name="Design system audit",category="Design",done=true},{id=2,name="Validate native layouts",category="Engineering",done=false},
		{id=3,name="Prepare release notes",category="Release",done=false},{id=4,name="Review keyboard flows",category="Design",done=false}}
	local nextId=4
	local function TaskRow(p)
		local expanded,setExpanded=UI.useState(false)
		return h("Section",{style={padding=12,gap=8}}, {
			h("Checkbox",{label=p.task.name,description=p.task.category,value=p.task.done,onChange=function(value) p.onToggle(p.task.id,value) end}),
			h("Row",{style={distribute="fill"}}, {
				h("Button",{text=if expanded then "Hide details" else "Details",variant="ghost",onClick=function() setExpanded(not expanded) end}),
				h("Button",{text="Remove",variant="ghost",onClick=function() p.onRemove(p.task.id) end}),
			}),
			expanded and h("Paragraph",{text="Task #"..p.task.id.." keeps this local disclosure state when the keyed list is reordered."}) or false,
		})
	end
	local function Dashboard()
		local tasks,setTasks=UI.useState(initial); local filter,setFilter=UI.useState("All"); local search,setSearch=UI.useState("")
		local draft,setDraft=UI.useState(""); local inspector,setInspector=UI.useState(false)
		local visible=UI.useMemo(function()
			local result={}
			for _,task in tasks do if (filter=="All" or (filter=="Done")==task.done) and string.find(string.lower(task.name),string.lower(search),1,true) then table.insert(result,task) end end
			return result
		end,{tasks,filter,search})
		local done=0; for _,task in tasks do if task.done then done+=1 end end
		local function toggle(id,value)
			setTasks(function(previous) local result={}; for _,task in previous do local copy=table.clone(task); if copy.id==id then copy.done=value end; table.insert(result,copy) end; return result end)
		end
		local function remove(id)
			setTasks(function(previous) local result={}; for _,task in previous do if task.id~=id then table.insert(result,task) end end; return result end)
		end
		local function add()
			if not string.find(draft,"%S") then return end
			nextId+=1; local task={id=nextId,name=draft,category="Inbox",done=false}
			setTasks(function(previous) local result=table.clone(previous); table.insert(result,task); return result end); setDraft("")
		end
		return h(UI.Fragment,{}, {
			h("Window",{id="dashboard",title="Orbit  /  Release workspace",size={1000,680},openKey="F8"},
				h("Tabs",{items={{id="workspace",title="Workspace",content=h("Column",{style={gap=16}}, {
					h("Row",{}, {h("Text",{text="Release overview",style={width=UDim.new(1,-110),textSize=26,font="$typography.bold"}}),h("Badge",{text="SPRINT 08"})}),
					h("Paragraph",{text="A working application composed from reusable controls. Filter, reorder, create and remove keyed task components."}),
					h("Section",{title="Readiness",description=done.." of "..#tasks.." tasks complete"}, {
						h("ProgressBar",{value=if #tasks>0 then done/#tasks else 0}),
						h("Row",{style={distribute="fill"}}, {
							h("Button",{text="Reverse order",onClick=function() setTasks(function(previous) local result={}; for i=#previous,1,-1 do table.insert(result,previous[i]) end; return result end) end}),
							h("Button",{text="Open inspector",onClick=function() setInspector(true) end}),
							h("Button",{text="Prepare release",variant="primary",onClick=function() app:Confirm({title="Prepare a release?",message="The demo records a local notification only.",onResult=function(result) if result then app:Notify({title="Release prepared",message="The local review is complete.",status="success"}) end end}) end}),
						}),
					}),
					h("Row",{style={distribute="fill"}}, {
						h("TextInput",{placeholder="Search tasks…",value=search,onChange=setSearch}),
						h("SegmentedControl",{options={"All","Open","Done"},value=filter,onChange=setFilter}),
					}),
					h("Row",{}, {h("TextInput",{style={width=UDim.new(1,-116)},placeholder="Add a task…",value=draft,onChange=setDraft,onCommit=function(_,enter) if enter then add() end end}),h("Button",{text="Add task",style={width=108},onClick=add})}),
					h("Column",{},UI.list(visible,function(task) return h(TaskRow,{task=task,onToggle=toggle,onRemove=remove}) end,function(task) return task.id end)),
					#visible==0 and h("Section",{title="Nothing here",description="Change the filter or add your first task."}) or false,
				})},{id="activity",title="Activity",content=h("Section",{title="Application lifecycle"}, {
					h("Paragraph",{text="Open the inspector to review current managed counts. This demo uses no background polling loops."}),
					h("StatusIndicator",{status="success",text="Native renderer connected"}),
					h("Keybind",{label="Workspace shortcut",defaultValue="F7",onTrigger=function() app:Notify({title="Workspace",message="Shortcut activated"}) end}),
				})}}})),
			inspector and h("Window",{key="inspector",id="inspector",title="Workspace inspector",size={360,350},position={40,70},openKey=false,onClose=function() setInspector(false) end},
				h("ScrollArea",{contentStyle={padding=16}}, {
					h("Section",{title="Current snapshot"},UI.list({"components","instances","connections","subscriptions","windows"},function(name)
					return h("Text",{text=name.."  ·  "..tostring(app:GetDiagnostics()[name])})
				end,function(name) return name end)),
					h("Paragraph",{text="Counts are a render-time snapshot. Closing this window releases its instances and connections."}),
				})) or false,
		})
	end
	local root=UI.mount(h(Dashboard))
	return {library=app,root=root,Destroy=function() app:Destroy() end}
end
