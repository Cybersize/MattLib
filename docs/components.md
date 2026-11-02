# Component reference

Create components with `UI.h("Name", props, children)`. All components participate in renderer ownership and recursive destruction; they do not require separate manual Destroy calls. Use an owning root/window handle to remove them.

Most composed components accept `style` and `name`. Native primitives additionally accept `ref`, `native`, `events`, `changes`, `attributes`, `motion`, `role`, `accessibleName` and `accessibleValue`. For a wrapper with multiple hosts, the table below specifies which style/ref applies. Do not assume every native escape-hatch prop passes through every composed component.

Interactive inputs accept `disabled`, `value`, `defaultValue`, `onChange(value)`, and an appropriate `label`. Disabled native controls block their interaction callbacks. Value props are immutable snapshots. See [framework.md](framework.md) for controlled semantics and [styling.md](styling.md) for focus/hover/active precedence.

## Layout and navigation

| Component | Properties and behavior |
| --- | --- |
| `Frame`, `Container` | Transparent native Frame; full width and automatic height by default. Native host/ref/props supported. No automatic child layout. |
| `Column` | Frame with vertical UIListLayout, full width, automatic height, spacing.sm gap. Accepts native host/ref/props. |
| `Row` | Frame with horizontal UIListLayout, center cross alignment, full width, automatic height. Use fixed/UDim child widths or `distribute="fill"`. Native host/ref/props supported. |
| `AdaptiveGrid` | Responsive wrapping section layout. `columns=2` is a maximum; `minColumnWidth=240`, `gap=12`. Measures its container and changes cell widths without reparenting keyed children. Use an outer Inset for padding. |
| `Stack` | Same primitive as Frame; positioned/overlapping children. Set an explicit height when children have relative/absolute positions. |
| `Inset` | Column with padding; `spacing` defaults to spacing.lg. Exterior spacing is expressed by a wrapper, not CSS margins. |
| `ScrollArea` | Native ScrollingFrame, vertical AutomaticCanvasSize, thin semantic scrollbar. `style` applies to viewport; `contentStyle` applies to the inner Column. `ref` targets the ScrollingFrame. `native` can override scrolling direction/canvas behavior. |
| `Separator` | One-pixel semantic border line. Override width/height/position via style. |
| `Section` | Surface, border, rounded padding and vertical content. `title?`, `description?`, `style`, children. |
| `Collapsible`, `CollapsibleSection` | Same section behavior with an accessible disclosure button. `title`, `open?`, `defaultOpen=false`, `onOpenChange(boolean)`, `disabled`. Measures content and tweens clipped body height. Children retain state while closed. |
| `Window` | See window properties below. Owns native Frames and header controls; text renders directly. Children fill its content area; put scrolling/navigation inside. |
| `Tabs` | `items={{id,title,content,disabled?,icon?},...}` or direct `Tab` children. `value?`, `defaultValue?`, `onChange(id)`, `orientation="design"|"top"|"sidebar"`, optional sidebarWidth/tabWidth/padding, `unmountInactive=false`. Sidebar follows the actual container width and becomes top navigation below 640px. Panels scroll. Icon names use the built-in line symbols. |
| `Tab` | Metadata consumed by its direct Tabs/Sidebar parent: `id`, `title`, `disabled`, children. Rendering it outside Tabs is an error. |
| `Sidebar` | Tabs with sidebar orientation. Same selection and item/child properties. |
| `DesignPicker` | Selects MintGlass/Ember/Vector/Aura. Default dropdown or `presentation="segments"`; name, label, value, onChange, disabled, style. Without onChange it calls the owning application's SetDesign. |
| `Reveal` | Native Frame entrance with direct object opacity/scale tweens. order=0, delay?, replayKey?, name/style; skips delayed motion when reduced motion is enabled. |
| `Wallpaper` | Full-size animated artwork; optional `image`, `speed=1` (>0, <=4), `opacity=1` (0..1), `motion=false`, `active=false`, name/style. Lazily loads the selected design's individual image when supported, otherwise uses native ribbons/grid. Pauses while hidden or reduced motion is enabled. Set an explicit height in flow layouts. See [designs.md](designs.md). |

Inactive panels remain mounted and preserve local state. Set `unmountInactive=true` for expensive pages that should release resources when inactive. Disabled tabs cannot be activated through their buttons; the application should choose an enabled default/controlled value. An unavailable selected id falls back to the first item visually.

```lua
UI.h("Tabs", { defaultValue = "settings" }, {
    UI.h("Tab", { id = "home", title = "Home" }, { UI.h("Text", { text = "Home" }) }),
    UI.h("Tab", { id = "settings", title = "Settings" }, {
        UI.h("Section", { title = "Audio" }, { UI.h("Slider", { label = "Volume", defaultValue = 50 }) }),
    }),
})
```

## Window

| Property | Default / meaning |
| --- | --- |
| `id` | Stable generated id; duplicate explicit id replaces the earlier managed window in that application. |
| `title` | `"Application"` |
| `size` | `{720,500}` pixel pair. Clamped against safe-area bounds. |
| `position` | Optional `{x,y}` safe-layer pixel offsets; centered initially when omitted. |
| `minSize` / `maxSize` | Optional Vector2 constraints; default minimum 280×180. Small screens take precedence over minimums. |
| `fixedSize` | false; disables pointer/keyboard resize controls. Programmatic SetSize remains available. |
| `openKey` | `"RightShift"`, a KeyCode name/EnumItem, or false to disable. Pauses while typing or an overlay is open. |
| `defaultVisible` | true. Show/Hide are window-handle operations. Hidden windows get a scrollable restore tray for touch users. |
| `theme` | Optional `"Dark"`, `"Light"`, custom token table, or Theme service. Omitted inherits the application's live theme. |
| `design` | Optional MintGlass, Ember, Vector or Aura scoped override. Omitted follows the application. See [designs.md](designs.md). |
| `wallpaper` | Defaults to quiet animated design artwork. `false` removes it. Table options: `Image?`, `Speed=1`, `Opacity=0..1` (default depends on design), `Motion=false` for static artwork. |
| `windowRef` | Table receiving the managed window handle in `.current`, later nil. This differs from a native host ref. |
| `onReady(handle)` | Called after native refs are committed and the manager registers the window. |
| `onMove(rect)` / `onResize(rect)` | Called on successful pointer gesture completion. Rect has x,y,width,height. |
| `onVisibleChange(boolean)` | Called by Show/Hide operations. |
| `onClose()` | Header close requests a fade and eventual removal of native content. Parent-owned conditional state can also remove the Window. |

Handles support `Show`, `Hide`, `Minimize`, `Restore`, `Focus`, `SetSize(width,height)`, `GetRect`, `Close`, `Destroy`. `Destroy` requests close and detaches manager connections; unmount the owning root to immediately release its entire functional tree. Header close removes the closed window's native tree after its exit transition; the parent root remains available. Destroy the root/application when no longer needed. Titlebars and resize grips can be selected and moved/resized with arrow keys. Windows focus through pointer interaction and use sibling z ordering. See [application.md](application.md) for menu handles.

## Buttons and boolean controls

| Component | Properties |
| --- | --- |
| `Button` | `text` (or label), `onClick(instance, ...nativeActivatedArgs)`, `variant="primary"|"secondary"|"ghost"|"danger"`, disabled, active, style, children and native props. Default full width and controlHeight. Return/Space activates a selected button; mouse/touch/gamepad use native Activated. |
| `Toggle`, `Switch` | Boolean value/defaultValue=false, label, description, onChange(boolean). Full labelled row is clickable; thumb animation uses shared TweenService. `ref` targets the native row button. |
| `Checkbox` | Same boolean API, with square indicator and check mark. |

## Numeric and text inputs

| Component | Properties and callbacks |
| --- | --- |
| `Slider` | `min=0`, `max=100`, `step=1`, numeric value/defaultValue=min, `label`, `format(value)->string`, `onChange(number)`, `onCommit(number)`. Values are clamped and snapped relative to min. Track pointer capture handles dragging outside its bounds. Arrow keys adjust by one step; Home/End choose bounds. |
| `RangeSlider` | Same bounds/step API; value/defaultValue is `{low,high}`. Picks the nearest thumb and prevents crossing. Space on the selected track switches the active keyboard thumb. Emits a new pair. |
| `TextInput` | String value/defaultValue="", label, description, placeholder, multiline=false, maxLength? (Unicode codepoints), disabled, `inputStyle`, outer `style`, `onChange(string)`, `onCommit(string, enterPressed)`. `ref` targets TextBox. Controlled rejected edits are restored on the next commit. |
| `NumericInput` | Finite number value/defaultValue=0, optional min/max/positive step, label, placeholder, description, inputStyle, outer style. Text draft permits temporary invalid syntax. Commit on FocusLost/Enter clamps and optionally snaps, calls onChange and onCommit(number). Invalid input reverts and shows validation text; optional `onInvalid(text)`. `ref` targets TextBox. |

Pointer sliders support mouse and touch. Focused native text boxes suppress application keybinds. Standard Roblox text input/virtual keyboard behavior is used; locale-specific numeric separators are not parsed. NumericInput uses Luau `tonumber`.

## Selection controls

Options are dense arrays of strings/numbers or `{value=stringOrNumber,label=string?,disabled=boolean?}`. Values must be unique, including their type. The normal label defaults to tostring(value). An empty string represents an initially unselected single dropdown unless it is itself a valid option.

| Component | Properties and behavior |
| --- | --- |
| `Dropdown` | options, value/defaultValue="", label, placeholder, onChange(value), disabled, searchable=false, multiple=false, menuWidth?, maxHeight=320. Trigger uses a portal popover. Outside click and Escape close; Up/Down highlight options; Return selects. |
| `SearchableDropdown` | Dropdown with searchable=true. Search is case-insensitive plain substring matching, with no pattern interpretation. |
| `MultiSelect` | Dropdown with multiple=true, searchable=true by default. Value/defaultValue is an array, default `{}`. Selection emits a fresh array; the menu stays open for additional choices. |
| `RadioGroup` | options, value/defaultValue=first option, onChange(value), label, disabled, horizontal=false. Buttons have selected labels; arrow keys change to enabled options. |
| `SegmentedControl` | RadioGroup with horizontal segments and an accent selected button. |
| `ColorPicker` | Color3 value/defaultValue=current theme accent, onChange(Color3), label, disabled. Opens RGB sliders plus six-digit RGB hex text entry. Invalid hex reverts with an error. No HSV-plane or alpha-channel API is advertised. |
| `Keybind` | KeyCode name string value/defaultValue="None", label, onChange(keyName), `onTrigger(inputObject)`, disabled. Click to capture a keyboard key; Escape cancels, Backspace/Delete clears. Repeated normal key presses invoke onTrigger. Processed input, text focus, hidden controls and outside modal scope suppress triggering. Keyboard key capture only; it is not a macro/hold-toggle engine. |

```lua
UI.h("SearchableDropdown", {
    label = "Region",
    options = { "Singapore", "Tokyo", { value = "eu", label = "Europe", disabled = true } },
    defaultValue = "Tokyo",
    onChange = function(region) print(region) end,
})
```

## Display and feedback

| Component | Properties |
| --- | --- |
| `Text`, `Label` | text, style, native props/ref. Full width and automatic height, wrapped, semantic body typography. |
| `RichText` | Text with Roblox RichText enabled. Caller owns the markup; this is not HTML. |
| `Paragraph` | text or content, semantic muted/wrapped text. |
| `Icon` | image as numeric asset id or Roblox image URI; otherwise glyph string (default ◇). size=20, style. No icon service or external icon pack is fetched. |
| `Badge` | text and style; automatic width, 24px height, semantic muted surface. |
| `ProgressBar` | value=0 in 0..1 (clamped), optional label, height=6, color token/Color3, style. Fill size transitions use shared animation. |
| `LoadingIndicator` | text="Loading…", style. A repeating TweenService rotation plus textual label; reduced motion stops/avoids the loop. |
| `StatusIndicator` | status="info"|"success"|"warning"|"error"|"idle", optional text, style. Semantic dot plus readable text. |
| `Toast`, `Notification` | title, message, status, open?/defaultOpen=true, onOpenChange(boolean), optional duration seconds, style. Standalone declarative toast; use app:Notify for a stacked timed service. |
| `Tooltip` | text, children, delay=0.45, width=240, disabled, wrapper style. Opens after hover or descendant native selection. Owns/cancels delay timers. |

## Overlays

| Component | Properties and lifecycle |
| --- | --- |
| `Modal` | title?, children, open?/defaultOpen=true, onOpenChange(boolean), width=440, dismissible=true, style. Portal backdrop, reduced-motion-aware entry/exit, scrollable body, keyboard Tab cycling, Escape/outside dismissal, native selection/text-focus restoration. |
| `Popover` | anchor ref or `position=Vector2` in absolute screen coordinates; open?/defaultOpen=false, onOpenChange, width? (anchor width or 280), maxHeight=320, style. Constrains/flips placement against the safe layer. Body scrolls by default. `scrollable=false` is for a child that already owns a correctly sized scrolling viewport. Does not trap focus. |
| `ContextMenu` | children, `items={{id,label,onSelect,disabled?},...}`, width=220, disabled, wrapper style. Right-click or touch long-press opens the shared popover. Menu item selection closes it. |
| `ConfirmationDialog` | Modal with title, message, confirmText="Confirm", cancelText="Cancel", danger=false, onResult(boolean), open?/defaultOpen=true, onOpenChange, dismissible, width. Answers once per opening; cancel/Escape/backdrop return false. |

```lua
local anchor = UI.useRef(nil)
local open, setOpen = UI.useState(false)
return UI.h(UI.Fragment, {}, {
    UI.h("Button", { ref = anchor, text = "Details", onClick = function() setOpen(not open) end }),
    UI.h("Popover", { anchor = anchor, open = open, onOpenChange = setOpen }, {
        UI.h("Paragraph", { text = "A reusable floating panel." }),
    }),
})
```

All overlays own their listeners and delayed exits. Native selection support and semantic metadata assist input navigation, but Roblox does not provide a browser ARIA tree. Gamepad, physical touch and screen-reader behavior still need device-specific verification. Text glyph rendering depends on platform fonts; supply image assets when a precise icon shape matters.
