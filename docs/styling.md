# Styling, tokens and motion

Styles are Luau tables with a fixed vocabulary. Unknown keys throw an actionable error. There are no CSS strings, selectors, browser layout rules or implicit cascading.

```lua
UI.h("Button", {
    text = "Save changes", variant = "primary",
    style = {
        width = "100%", height = 40, radius = "$radius.md",
        font = "$typography.medium",
        hover = { background = "$accentHover" },
        focus = { borderColor = "$accent", borderWidth = 2 },
    },
})
```

## Style vocabulary

| Property | Values / native mapping |
| --- | --- |
| background, backgroundTransparency | Color3 or `$token`; native BackgroundColor3 and 0..1 transparency. |
| color, font, textSize | TextColor3, Enum.Font, pixel TextSize; token references allowed. |
| textAlign, textYAlign | left/center/right and top/center/bottom. |
| wrapped, richText | Boolean native text flags. |
| width, height | Pixel number, UDim, percentage string (`"50%"`), or `"auto"`. Auto uses native AutomaticSize; explicit dimensions use Size. |
| position, anchor | UDim2 and Vector2. Use explicit parent height for positioned stacks. |
| minWidth, minHeight, maxWidth, maxHeight | Pixel numbers; an owned UISizeConstraint. |
| padding | Pixel number or `{top,right,bottom,left}` / `{vertical,horizontal}` pixel array; owned UIPadding. A token can stand for the whole numeric padding. |
| paddingX, paddingY | Numeric/token axis overrides. |
| radius | Numeric/token pixel corner radius; owned UICorner. |
| borderWidth, borderColor | Positive pixel thickness and Color3/token; owned UIStroke in Border mode. Zero/absent width removes the stroke. |
| opacity | 0..1. CanvasGroup sets GroupTransparency for the subtree. Other hosts affect their own background/text/image opacity. |
| direction | row/column; owned UIListLayout sorted by LayoutOrder. |
| gap | Pixel/token list gap. |
| horizontalAlign, verticalAlign | start/center/end; native list alignment. |
| distribute | fill/between/around/evenly; native main-axis UIFlexAlignment. Opt-in to native flex behavior. |
| wrap | Boolean UIListLayout.Wraps. |
| grow, shrink | Nonnegative ratios; owned UIFlexItem in Custom mode. Parent must use an appropriate native flex layout. |
| visible | Boolean native Visible. |
| overflow | visible/hidden; scroll requires a ScrollingFrame (normally use ScrollArea). |
| zIndex, rotation | Native numeric layer/rotation. ScreenGui uses hierarchical sibling ordering. |
| imageColor, imageTransparency | ImageLabel/ImageButton native appearance. |
| scrollbarColor | ScrollingFrame ScrollBarImageColor3. |
| hover, pressed, focus, active, disabled | Partial style tables; applied over base in this order: active, hover, pressed, focus, disabled. |

Each top-level scalar style value can use `$token.path`. Padding arrays use literal numeric entries. `UI.mergeStyles(base, overrides, ...)` returns a new table and merges nested state maps. Caller props override component defaults. When both `native` and `style` specify a mapped property, style wins. Use `name`, not native.Name, for host naming. The renderer owns Parent and LayoutOrder unless `native.LayoutOrder` explicitly requests an order.

Pseudo states track native MouseEnter/Leave, pointer press/release, SelectionGained/Lost and TextBox focus. `active` and `disabled` are explicit component/host props. A global input release resets pressed state even after a pointer leaves a control. Disabled styles have highest precedence.

## Predictable layout

```lua
UI.h("Row", { style = { gap = 12, verticalAlign = "center" } }, {
    UI.h("Column", { style = { width = UDim.new(1, -132), gap = 4 } }, {
        UI.h("Text", { text = "Workspace", style = { font = "$typography.medium" } }),
        UI.h("Paragraph", { text = "A fluid column beside a fixed action." }),
    }),
    UI.h("Button", { text = "Open", style = { width = 120 } }),
})
```

Use parent padding/gap or Inset for margin-like spacing. Native `UIListLayout` places direct child hosts; absolute Position does not override list placement. Put overlapping/positioned content inside a Stack/Frame instead of mixing it with flow children. Avoid auto-sized parents whose children's percentage height depends on that same automatic height. Give scrolling viewports a bounded height, and let their inner content grow automatically.

Native flex uses Roblox's intrinsic size and AutomaticSize rules, not the web flexbox algorithm. For exact desktop/mobile arrangements use explicit UDim widths and responsive component branches. Tabs perform their own sidebar-to-top change using actual safe-area width.

## Theme services

```lua
app:SetTheme("Light")
app.Theme:Extend({
    accent = Color3.fromRGB(68, 124, 216),
    typography = { body = 15 },
    radius = { md = 8 },
})
local tokens = app.Theme:Get() -- immutable

-- Scoped theme; children retain component identity across theme changes.
UI.h("ThemeProvider", { theme = "Dark" }, {
    UI.h("Button", { text = "Always dark" }),
})
```

`Library.new({theme = ...})`, `app:SetTheme`, `app.Theme:Set` and Window.theme accept Dark, Light or a custom token table. Custom tables merge over Dark; missing nested fields inherit defaults. `Theme:Extend` merges over the current theme. Known token shapes/types are validated; numeric tokens are finite/nonnegative. A provider can also receive `app.Theme` (a service) to share live changes. Providers create/destroy their own services for string/table themes and do not destroy an externally supplied service.

Semantic color tokens:

| Role | Tokens |
| --- | --- |
| Backgrounds | background, surface, raised, input, overlay |
| Text | text, muted, subtle, disabled, accentText |
| Boundaries | border |
| Interactive | accent, accentHover, accentPressed, hover, pressed |
| Status | success, warning, danger |

Shared scales:

| Group | Defaults |
| --- | --- |
| spacing | none=0, xs=4, sm=8, md=12, lg=16, xl=24, xxl=32 |
| radius | sm=4, md=7, lg=11, pill=999 |
| typography | font=BuilderSans, medium=BuilderSansMedium, bold=BuilderSansBold; small=12, body=14, title=18, display=26 |
| motion | fast=0.12, normal=0.18, slow=0.24 seconds |
| controlHeight | 38 pixels; switches/check rows are 44px for a larger target |

Every built-in color scheme comes from these tokens. Application-specific RGB edits are explicit values, not another embedded component palette. To increase interactive target size and readability use a custom controlHeight and typography scale, plus component-specific styles where necessary.

## Animation

State color/position/size changes, slider/progress fills, switch thumbs, window/modal/popover/toast fades, tabs and collapsible heights use one owned TweenService utility. A new tween on an instance/channel cancels its predecessor and releases its completion connection. Style transitions carry unfinished goals across quick interruptions. Unmount forgets active tweens; there is no RenderStepped loop.

```lua
app:SetReducedMotion(true) -- complete active goals, stop loops, make later goals immediate
```

Set `Library.new({reducedMotion=true})` for reduced motion from startup. `motion=false` on a primitive/host makes its style changes immediate.

Advanced custom components can access `UI.useEnvironment().animator:To(instance, goals, seconds, options?)`. It returns a cancellation function suitable for an effect cleanup. Options are `channel`, `easing`, `direction`, `repeatCount`, `reverses`, `onComplete`, and `merge`. Channels must animate disjoint properties; renderer-controlled property changes take ownership when the declared prop changes. Do not continuously mutate a declared property behind the renderer. Window geometry and measured disclosure size are intentionally managed through dedicated instance ownership.
