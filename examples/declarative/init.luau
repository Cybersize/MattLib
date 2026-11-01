return function(Library)
	local app=Library.new({id="mattlib-declarative"})
	local UI=app.UI
	local function Counter()
		local count,setCount=UI.useState(0)
		UI.useEffect(function()
			print("Counter mounted")
			return function() print("Counter unmounted") end
		end,{})
		return UI.h("Section",{title="A functional component"}, {
			UI.h("Text",{text="Count: "..count}),
			UI.h("Button",{text="Increment",variant="primary",onClick=function() setCount(function(previous) return previous+1 end) end}),
			UI.when(count>0,UI.h("Paragraph",{text="This conditional element is incrementally mounted."})),
		})
	end
	local function App()
		return UI.h("Window",{id="counter",title="Declarative Luau",size={620,440}}, {
			UI.h("Tabs",{}, {
				UI.h("Tab",{id="home",title="Home"}, {UI.h(Counter)}),
				UI.h("Tab",{id="about",title="About"}, {UI.h("Paragraph",{text="Native Roblox UI. Stable keys. Owned lifecycles."})}),
			}),
		})
	end
	local root=UI.mount(UI.h(App))
	return {library=app,root=root,Destroy=function() app:Destroy() end}
end
