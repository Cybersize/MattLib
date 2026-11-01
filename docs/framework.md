# Elements, state and lifecycle

Use `local UI = app.UI`. Declarative properties are lower camel case. The imperative facade uses the PascalCase properties documented in [application.md](application.md).

## Elements and roots

`UI.h(type, props?, children?)` creates an element. `type` is a registered component name, a function, `UI.Fragment`, or a whitelisted native class prefixed with `@`. Props are copied; `props.children` is a normalized array. Children can be an element, a dense nested array, false, or nil. False/nil render nothing. Use false inside conditional arrays to avoid nil holes. String children are deliberately rejected: use `Text`.

```lua
local function Card(props)
    return UI.h("Section", { title = props.title }, props.children)
end
local element = UI.h(Card, { title = "Reusable" }, {
    UI.h("Text", { text = "A native component tree" }),
})
local root = UI.mount(element) -- app runtime's safe main layer
root:Update(UI.h(Card, { title = "Updated" }, {})) -- deferred update
root:Flush() -- synchronous commit when needed
local native = root:Find("MyNamedHost") -- tree-aware lookup, including portals
root:Unmount() -- idempotent, recursive destruction
```

`UI.mount(element, parent?, {onError = function(message) ... end}?)` accepts an explicit native parent. `app:Mount` is equivalent. `app:Flush()`/`UI.flush()` flush all owned roots; `UI.flush(root)` flushes one. `root:Update(nil)` clears a root without unmounting the root handle. Updating or flushing an unmounted root throws. Setters captured from an unmounted component safely stop scheduling work.

`UI.when(condition, yes, no?)` returns the chosen value. It does not defer evaluation of its arguments.

## Identity, collections and fragments

Function references are component types: define them outside render bodies. Remounting with a different function/type resets its state. Siblings match by key and type; numeric key `1` and string key `"1"` are different. Keys must be unique among siblings. Unkeyed children match by flattened position. A reorder writes native `LayoutOrder`; it does not recreate keyed controls.

```lua
local rows = UI.list(items, function(item)
    return UI.h("Text", { text = item.name })
end, function(item) return item.id end)

return UI.h(UI.Fragment, {}, {
    UI.h("Text", { text = "No wrapper instance" }),
    UI.h("Column", {}, rows),
})
```

`UI.portal(children, nativeParent)` preserves logical hook/cleanup ownership and places hosts under a different native parent. Modal/Popover/Toast use this separation to escape window/scroll clipping. Do not reparent or destroy renderer-owned instances yourself; unmount the owner instead. Destroying the application's marked ScreenGui is additionally handled as full application destruction.

## Hooks

Call hooks unconditionally in the same order inside a functional component. Do not call them in event handlers, loops, arbitrary helper callbacks, or outside rendering. A regular helper that always invokes the same hooks is usable as a custom hook. Render functions must not yield, perform side effects or update state.

| Hook | Contract |
| --- | --- |
| `UI.useState(initial)` | Returns `value, setter`. A function initializer runs on the first render only. A function passed to the setter receives the latest state, including preceding updates in the same batch. Tables are immutable snapshots; return a new table to change them. |
| `UI.useEffect(setup, deps?)` | Runs after a successful complete commit, in scheduling/declaration order. Return a cleanup function or nil. Cleanup runs before changed-dependency setup and on unmount. `{}` runs once; omitted deps run after each render. Effects are synchronous commit effects, not browser post-paint effects. |
| `UI.useMemo(compute, deps?)` | Recomputes when a dependency identity changes. Useful for filtering collections. Do not use it to own subscriptions or effects. |
| `UI.useRef(initial?)` | Returns a stable mutable `{current = ...}` table. Assigning it does not rerender. Use it as a host ref, or for gesture-local data. |
| `UI.useSignal(signal)` | Reads and subscribes this component to a shared signal. Automatically reconnects if the signal object changes and disconnects at unmount. |
| `UI.useTheme()` | Reads/subscribes the inherited immutable token table. Prefer `$token` styles when a component only needs colors/typography. |
| `UI.useEnvironment()` | Advanced integration: inherited library services. Internal service details are less stable than public `app` methods; use them when writing integrations such as custom pointer controls. |

Dependencies are dense arrays and compare values by identity. Do not use nil holes; use a false sentinel where necessary. Mutating a dependency table in place is not a change notification. Effects and renderer errors are visible; a failed render/commit unmounts its root to release a partially updated tree. Event errors go to the root `onError` callback (or warn) without silently destroying unrelated roots.

```lua
local function Watcher(props)
    local count, setCount = UI.useState(0)
    local button = UI.useRef(nil)
    UI.useEffect(function()
        local connection = props.source.Changed:Connect(function()
            setCount(function(previous) return previous + 1 end)
        end)
        return function() connection:Disconnect() end
    end, { props.source })
    return UI.h("Button", { ref = button, text = "Changes: " .. count })
end
```

This is MattLib's lifecycle contract. It does not implement React's scheduler, Suspense, concurrent mode, class components, synthetic events, error-boundary components or React context API.

## Signals and derived values

```lua
local volume = UI.signal(40)
local enabled = UI.signal(true)
local effective = UI.derived({volume, enabled}, function(level, isEnabled)
    return if isEnabled then level else 0
end)
local disconnect = effective:subscribe(function(value, previous)
    print(previous, "->", value)
end)
UI.batch(function()
    volume:set(65)
    enabled:set(false)
end)
print(effective:get()) -- 0
disconnect()
effective:Destroy() -- releases dependency subscriptions
volume:Destroy()
enabled:Destroy()
```

Signals expose `get`, `set`, `update(function(previous) ... end)`, `subscribe(function(value, previous) ... end)` and `Destroy`. Notifications are coalesced inside `UI.batch`, and all batched values are assigned before subscribers run. Subscriptions do not immediately emit the current value. Equal values do not notify. Subscriber errors are warned while other listeners continue. Destroy shared/derived signals when their application/model owner ends; `useSignal` owns the subscription, not the signal itself.

## Controlled and uncontrolled controls

An input with `value ~= nil` is controlled. It calls `onChange(nextValue)` and displays the value the parent supplies. Otherwise it owns state initialized from `defaultValue` or its documented default. It never invokes `onChange` during initialization. False is a valid controlled value. Do not switch between controlled and uncontrolled modes during one component's lifetime; that throws. Use a new key when intentionally replacing the mode.

```lua
local enabled, setEnabled = UI.useState(false)
return UI.h("Column", {}, {
    UI.h("Toggle", { label = "Controlled", value = enabled, onChange = setEnabled }),
    UI.h("Toggle", { label = "Internal state", defaultValue = true }),
})
```

NumericInput commits a numeric value on focus loss/Enter; its text draft can contain temporary invalid input. Slider updates continuously and additionally calls `onCommit` when a gesture ends. MultiSelect and RangeSlider emit new arrays. Keybind uses a KeyCode name string and `"None"` as its cleared value. ColorPicker uses Color3.

## Custom components and native hosts

Compose existing controls first. For a new native primitive, use `@Frame`, `@CanvasGroup`, `@TextLabel`, `@TextButton`, `@TextBox`, `@ImageLabel`, `@ImageButton` or `@ScrollingFrame`.

```lua
local function HealthCard(props)
    return UI.h("Section", { title = props.title or "System health" }, {
        UI.h("StatusIndicator", { status = props.healthy and "success" or "warning", text = props.healthy and "Healthy" or "Review required" }),
        UI.h("ProgressBar", { value = props.utilization }),
    })
end

local ref = { current = nil }
local native = UI.h("@TextButton", {
    name = "CustomAction", ref = ref,
    native = { Text = "Action", AutoButtonColor = false },
    style = { width = "100%", height = 40, background = "$raised", color = "$text" },
    events = { Activated = function(instance) print(instance.Name) end },
    changes = { AbsoluteSize = function(instance) print(instance.AbsoluteSize) end },
    role = "button", accessibleName = "Custom action",
})
```

Native event/change callbacks receive the Instance first, then native event arguments. Callback closures update without reconnecting the native listener. Connections disappear when their event prop is removed. Controlled writes suppress change callbacks while applying props. Removed native/style properties reset to their original host defaults. `Parent`, native class, modifiers and child ordering belong to the renderer. Raw host behavior does not infer `Text` from `props.text`; use `native.Text` or the `Text` primitive.

Refs can be stable tables or callbacks receiving the instance and later nil. Avoid allocating callback refs every render if they cause expensive ref cleanup. Existing refs remain stable through keyed reorders and prop updates.
