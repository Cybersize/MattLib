# Applications, windows and persistence

## Application ownership

```lua
local app = Library.new({
    id = "acme-settings", -- stable namespace; same id replaces its earlier ScreenGui
    theme = "Dark",
    design = "MintGlass", -- MintGlass, Ember, Vector, Aura
    reducedMotion = false,
    displayOrder = 50,
    config = { folder = "AcmeSettings", version = 1 },
    onError = function(message) warn(message) end,
})
```

The returned bundle itself is a lazy default application with the same methods. Prefer `Library.new` with a stable id for reusable integrations. `parent` can provide an explicit GUI parent. `capabilities` can provide a table of optional functions for an embedding environment or `{}` to disable capability discovery. It is not a privilege request.

GUI creation waits until the first Mount/CreateWindow/Notify/Confirm/SetReducedMotion call. Theme and Config services are available before mounting. `app:Destroy()` is idempotent and destroys all owned roots, menu handles, windows, service listeners, notifications, tweens, timers and configuration registrations. A destroyed application cannot be mounted again; `Library.new` creates another. Distinct application ids coexist. Same id disposal uses a marked ScreenGui/BindableFunction, including across separately loaded copies of the bundle. Unmarked UI is never removed.

Optional parenting order is explicit parent, successful optional gethui, then the local player's PlayerGui. `GetRuntimeInfo()` reports version, parentMode and a boolean capability map. No CoreGui privilege, getgenv, network loader, concealment, input spoofing, anti-cheat bypass or unrelated executor API is required.

## Declarative window handles

```lua
local windowRef = {}
local root = UI.mount(UI.h("Window", {
    id = "editor", title = "Editor", size = { 800, 560 },
    minSize = Vector2.new(300, 240), openKey = "F8", windowRef = windowRef,
}, UI.h("ScrollArea", { contentStyle = { padding = 16 } }, {
    UI.h("Text", { text = "Scrollable workspace" }),
})))

windowRef.current:Minimize()
windowRef.current:Restore()
windowRef.current:Hide()
windowRef.current:Show()
windowRef.current:SetSize(720, 500)
windowRef.current:Focus()
print(windowRef.current:GetRect().width)
root:Unmount()
```

Each window has independent geometry/visibility/minimize state. The titlebar handles mouse/touch movement, the lower-right grip handles resize, and selected titlebar/grip arrow keys provide keyboard alternatives. Fixed-size windows omit resizing. Manager gestures use current native safe-area bounds and direct instance geometry updates, avoiding a functional-tree render per pointer movement. Header minimize uses the selected design's titlebar height; resizing while minimized changes the later restore size. Show/Hide can be bound to a KeyCode or disabled. Touch devices automatically get a persistent floating M toggle. A shared restore tray keeps windows without an icon recoverable without a keyboard. ScreenGui uses CoreUISafeInsets where available and standard IgnoreGuiInset=false as an older-client fallback.

## Mobile toggle

On touch devices, each window automatically gets a 48x48 floating **M** button along the right edge of the safe area. Tap it to hide the window; tap again to show it. The icon is a sibling of the managed window, so hiding that window leaves the icon visible. Multiple icons form a scrollable stack. They are removed when their windows close or the application is destroyed.

```lua
local window=MattLib:CreateWindow({
    Title="My UI",
    -- MobileToggle omitted: automatic on touch devices
    MobileToggle=true, -- also show it on desktop; false disables it
})
window:Update({MobileToggle=false}) -- can be changed at runtime
```

Declarative windows accept `mobileToggle=true` or `false`. `MattLib.new({mobileToggle=false})` disables automatic launchers application-wide; a window can override that with `MobileToggle=true`. Omitting the setting uses [UserInputService.TouchEnabled](https://create.roblox.com/docs/reference/engine/classes/UserInputService#TouchEnabled), and taps use the shared button's cross-platform [Activated event](https://create.roblox.com/docs/reference/engine/classes/GuiButton#Activated).

Hiding keeps the existing controls and state. Reopening a hidden minimized window restores its full height. Hiding with the M button releases focus from text inputs in that window, allowing the virtual keyboard to dismiss. A modal dialog owns interaction until dismissed; the icon does not toggle a window behind an active modal. Windows with a launcher do not also appear in the restore tray. Desktop keyboard shortcuts remain available.

Closing a declarative window fades/removes its native content, while its owning root remains a handle. Unmount that root/application when finished. A conditional parent may remove the Window immediately in onClose; that intentionally skips the internal exit transition. Do not retain/use native instances after unmount.

## Menu facade

```lua
local window = app:CreateWindow({
    Id = "preferences", Title = "Preferences", Size = { 760, 540 },
    Theme = "Dark", OpenKey = "RightShift", Navigation = "Sidebar",
})
local tab = window:AddTab({ Title = "General" })
local section = tab:AddSection({ Title = "Behavior", Description = "Application preferences" })
local enabled = section:AddToggle({ Id = "enabled", Title = "Enabled", Default = false })
local disconnect = enabled:OnChanged(function(value) print(value) end)
enabled:SetValue(true)
enabled:Update({ Title = "Feature enabled", Disabled = false })
print(enabled:GetValue())
print(enabled.ConfigId) -- preferences/enabled
disconnect()
```

CreateWindow accepts `Id`, `Title`, `Size`, `Position`, `MinSize`, `MaxSize`, `FixedSize`, `OpenKey`, `Theme`, `Navigation` ("Top" or "Sidebar"), and `OnClose`. Window handles expose `AddTab`, `Show`, `Hide`, `Minimize`, `Restore`, `Focus`, `SetSize`, `SetTheme`, `GetRect`, `GetInstance`, `Update`, `Destroy`, and `.Config` (the application Config service). Header close schedules full facade destruction after its transition. Explicit `window:Destroy()` immediately unmounts and releases the complete model/config tree.

CreateWindow also accepts `Design="MintGlass"|"Ember"|"Vector"|"Aura"`; `window:SetDesign(name)` and `window:GetDesign()` manage a scoped design. Omitted Navigation uses the selected design's layout. Application methods `SetDesign`, `GetDesign`, `GetDesigns`, `SetEffectIntensity` and the immutable `.Designs` name list are documented in [designs.md](designs.md). Changing designs retains control state and geometry.

Tabs and sections accept AddSection/AddCollapsible and the Add methods below. Tab controls render in its normal content Column; sections are optional. Container `Update` changes presentation. `Destroy` recursively removes the container and its descendants.

| Add method | Principal PascalCase properties |
| --- | --- |
| AddButton | Title/Text, Callback, Variant, Disabled |
| AddToggle / AddSwitch / AddCheckbox | Title, Description, Default/Value, Callback |
| AddSlider / AddRangeSlider | Title, Min, Max, Step, Default/Value, Format, Callback, OnCommit |
| AddDropdown / AddSearchableDropdown / AddMultiSelect | Title, Options, Default/Value, Placeholder, Searchable, Callback |
| AddTextInput | Title, Default/Value, Placeholder, Description, Multiline, MaxLength, Callback, OnCommit |
| AddNumericInput | Title, Default/Value, Min, Max, Step, Callback, OnCommit |
| AddColorPicker | Title, Color3 Default/Value, Callback |
| AddKeybind | Title, string Default/Value, Callback (changed key), Triggered(inputObject) |
| AddRadioGroup / AddSegmentedControl | Title, Options, Default/Value, Callback |
| AddProgressBar | Title, Default/Value in 0..1, Callback?; SetValue updates the bar |
| AddText / AddLabel / AddRichText | Title/Text, Style |
| AddParagraph | Title/Text/Content, Style |
| AddIcon | Glyph/Image, Size, Style |
| AddBadge | Title/Text, Style |
| AddSeparator | Style |
| AddLoadingIndicator | Title/Text, Style |
| AddStatusIndicator | Title/Text, Status, Style |

Controls also accept `Id`, `Name`, `Style`, `Disabled`, `AccessibleName`. Value controls return `SetValue`, `GetValue`, `OnChanged`, `Update`, `GetInstance`, `Destroy`, and `.ConfigId` when registered. Methods are colon methods. OnChanged returns an unsubscribe function. Callback/OnChanged fire for actual signal changes, including programmatic SetValue/import/reset, and do not fire during initialization. Update changes presentation/options; Id/Default/Value cannot be changed through it. Use SetValue for values. Invalid values throw instead of quietly corrupting state. Statics have no mutable value and reject value methods.

Each facade control renders a keyed shared declarative component. Structural changes update their owning container; value signals update only their control view. Destroying a facade releases its retained library-scope ownership reference as well as native resources.

## Notifications and confirmations

```lua
local toast = app:Notify({
    title = "Saved", message = "Your preferences were saved.", status = "success", duration = 4,
})
toast:Update({ message = "Saved to a local profile." })
toast:Dismiss() -- animated exit
-- toast:Destroy() removes it immediately

local dialog = app:Confirm({
    title = "Reset preferences?", message = "Your registered defaults will be restored.",
    confirmText = "Reset", danger = true,
    onResult = function(confirmed) if confirmed then app.Config:Reset() end end,
})
-- dialog:Close() answers false; dialog:Destroy() removes without answering
```

Notify defaults to five seconds; `duration=false` keeps a notification until dismissed. The stack is capped at eight entries to bound long-running producers. Update changes its displayed title/message/status; it does not restart the lifetime timer. Timers and entry/exit connections are owned. Confirmation callbacks answer once, and service-created roots are released after exit. Declarative Toast/Modal/ConfirmationDialog are available when the application wants to own open state itself.

## Configuration

Config is local settings infrastructure, not a Roblox DataStore, credential vault or server replication layer. It stores only explicitly registered state.

```lua
local volume = UI.signal(50)
local unregister = app.Config:Register("volume", volume, 50, function(value)
    return value >= 0 and value <= 100, "volume must be between 0 and 100"
end)
local json, exportError = app.Config:Export()
if not json then warn(exportError) end
local ok, importError = app.Config:Import(json)
if not ok then warn(importError) end
app.Config:Reset()
local saved, backendOrError = app.Config:Save("default") -- true,"memory" or true,"file"
local loaded, loadError = app.Config:Load("default")
unregister()
volume:Destroy()
```

Register requires a nonempty unique id (up to 128 bytes), a signal, a non-nil serializable default, and an optional validator returning boolean and optional error text. It returns unregister; it does not own the signal. The facade namespaces registered ids by window id and unregisters automatically.

Supported values: booleans, finite numbers, strings (up to 64 KiB), dense homogeneous JSON arrays, string-keyed JSON objects, nested supported tables, and Color3. Colors use a reserved `$type="Color3"` record. Instance/functions/EnumItems, cyclic data, sparse/mixed tables, infinity and NaN are rejected. Keybinds persist KeyCode name strings. Table limits are 4,096 entries per table, 16 nested levels, and a 1 MiB imported JSON string. Empty JSON tables retain their values but do not preserve a distinct Luau array/object identity; use a custom validator when shape matters.

Export validates registered current values and returns JSON or nil,error. Import checks `schema="mattlib/config"`, version and values. It decodes/validates every applicable entry **before assigning any**; rejected data leaves all registered state unchanged. Defaults enforce the basic type (and default array item type). Supply a validator for semantic constraints or complex object shape. Missing entries retain their existing values; unknown ids are ignored unless `Import(json,{strict=true})` is requested. Malformed JSON/future versions/missing migrations return false,error. Reset copies defaults before assigning in one batch.

Schema version defaults to 1. Configure a later version and register explicit one-step migrations:

```lua
local app = Library.new({ id = "migrated", config = { version = 2 } })
app.Config:RegisterMigration(1, function(data)
    return { schema = data.schema, version = 2, values = { volume = data.values.oldVolume } }
end)
```

Save/Load detect readfile, writefile, isfile, makefolder and isfolder independently. Without writing support, Save stores a profile in this application's memory, which Load can read even in a read-only embedding environment. With writing support, the default relative folder is `MattLib`; profile names permit letters, numbers, underscores and hyphens only. Missing files and filesystem errors are returned; the library does not silently claim a successful disk write. A writer without folder-creation capability must supply a usable existing folder. Memory profiles end with app destruction/process exit. Autosaving, autoloading and remote sync are deliberately explicit application decisions.
