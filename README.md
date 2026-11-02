# MattLib

A dependency-free, React-inspired Luau framework that renders native Roblox GUI instances. Functional components, local hooks, shared signals, keyed reconciliation, semantic themes, a component library, window management, and a small menu facade share one renderer.

**New in 1.2.2:** a persistent floating **M** icon toggles each window on touch devices. It stays available while the window is hidden and preserves your controls. Scripters can force it on desktop or disable it per window. Direct text rendering, separate full-resolution wallpapers and all four designs remain included. [Mobile toggle API](docs/application.md#mobile-toggle).

## Quick preview

Paste this into an environment that provides Roblox client APIs, `game:HttpGet` and `loadstring`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Cybersize/MattLib/main/Preview.lua?v=1.2.2"))()
```

It opens the complete interactive gallery: four designs, inputs, layouts, notifications, dialogs, themes, configuration and window controls. `Preview.lua` embeds all framework and gallery code and requires no runtime ModuleScripts. Supported executors download only the requested design's 1536x1024 wallpaper and cache it under `MattLib/wallpaper-<design>-v2.png`. The old atlas cache is not reused. Without image/filesystem capabilities, or when a download fails, native animated artwork remains available. Re-running replaces the previous MattLib gallery. **RightShift** toggles visibility on desktop; touch devices automatically get a floating **M** toggle. The restore tray remains available for windows without a floating toggle.

To load only the reusable library:

```lua
local MattLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Cybersize/MattLib/main/dist/MattLib.lua?v=1.2.2"))()
local window = MattLib:CreateWindow({Title="My UI", Design="Aura"})
window:SetDesign("Ember") -- MintGlass, Ember, Vector, Aura
```

[Minimal menu loader](examples/menu-loader.lua) · [Gallery loader](examples/preview-loader.lua) · [Repository](https://github.com/Cybersize/MattLib)

The current runtime passes 96 regression tests, including simulated touch activation, state retention and launcher cleanup. Native Studio evidence covers the earlier 1.2.1 runtime; the new mobile feature has not been checked on a physical phone. See [verification](docs/verification.md). Studio users should require the supplied ModuleScript instead of using the HTTP loader.

Start with **[dist/MattLib-Showcase.rbxlx](dist/MattLib-Showcase.rbxlx)** in Roblox Studio and press **F5**. It runs native smoke tests and opens the interactive gallery. The **[verification report](docs/verification.md)** distinguishes executed checks from remaining visual/device testing.

## Installation

**Studio, bundled:** create a ModuleScript named `MattLib` in ReplicatedStorage and paste the entire contents of [dist/Library.lua](dist/Library.lua) into its Source. Require it from a client LocalScript. Studio does not need loadstring or filesystem capabilities.

**Studio, modular:** use [default.project.json](default.project.json) with Rojo, or preserve the `src` directory hierarchy as ModuleScripts with `src/init.luau` as the root ModuleScript. Requires are ordinary `script.Parent` references.

**Standalone:** execute the local distribution in an environment that already supplies Roblox client APIs and a Luau compiler. The bundle returns the library object. For example, where `readfile` and `loadstring` are supported:

```lua
local Library = assert(loadstring(readfile("Library.lua")))()
```

The library never downloads source or assumes those functions exist. Standard Studio client scripts cannot use this loading snippet; use ModuleScript installation there.

## A declarative application

```lua
local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("MattLib"))
local app = Library.new({ id = "my-application", theme = "Dark" })
local UI = app.UI

local function Counter()
    local count, setCount = UI.useState(0)
    return UI.h("Section", { title = "Welcome" }, {
        UI.h("Text", { text = "Count: " .. count }),
        UI.h("Button", {
            text = "Increment", variant = "primary",
            onClick = function()
                setCount(function(previous) return previous + 1 end)
            end,
        }),
    })
end

local root = UI.mount(UI.h("Window", {
    id = "main", title = "My application", size = { 680, 480 },
}, {
    UI.h("Tabs", {}, {
        UI.h("Tab", { id = "home", title = "Home" }, { UI.h(Counter) }),
    }),
}))

-- Later: root:Unmount() removes this tree; app:Destroy() removes the whole application.
```

Ordinary state changes rerender the affected component subtree, diff properties and reuse native instances. Stable keyed children preserve hook state through reordering. Mounts are synchronous; subsequent changes coalesce using `task.defer`. `root:Flush()` is available for deterministic integration/tests.

## A small menu

```lua
local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("MattLib"))
local app = Library.new({ id = "my-menu" })
local window = app:CreateWindow({ Id = "settings", Title = "Settings", Theme = "Dark" })
local tab = window:AddTab({ Title = "General", Icon = "controls", Columns = 2 })
local section = tab:AddSection({ Title = "Preferences" })
local enabled = section:AddToggle({
    Id = "enabled", Title = "Enable feature", Default = false,
    Callback = function(value) print("Enabled:", value) end,
})
section:AddSlider({ Id = "volume", Title = "Volume", Min = 0, Max = 100, Default = 50 })
enabled:SetValue(true)
```

The facade renders the same `Toggle`, `Slider`, `Window`, `Tabs` and `Section` components. `Columns=2` places sections beside one another when the window is wide enough and stacks them when narrow. Explicit control ids register configuration under `<window Id>/<control Id>`.

## Included components

- Layout: Window, Frame/Container, Row, Column, AdaptiveGrid, Stack, Inset, ScrollArea, Section, Collapsible/CollapsibleSection, Separator, Wallpaper.
- Navigation and overlays: Tabs/Tab, Sidebar, Modal, Popover, ContextMenu, Tooltip, ConfirmationDialog.
- Controls: Button, Toggle/Switch, Checkbox, Slider, RangeSlider, Dropdown, SearchableDropdown, MultiSelect, TextInput, NumericInput, ColorPicker, Keybind, RadioGroup, SegmentedControl.
- Feedback: Text/Label, RichText, Paragraph, Icon, Badge, Toast/Notification, ProgressBar, LoadingIndicator, StatusIndicator.

Dark and light themes, custom semantic tokens, runtime theme changes, reduced motion, mouse/touch pointer capture, keyboard alternatives, safe-area window bounds, restoration controls, JSON profiles, optional file storage, diagnostics and automatic cleanup are included. There is no HTML parser, CSS cascade, runtime package fetch, privileged GUI-parent requirement or React compatibility claim.

## Documentation

- [Architecture and source research](docs/architecture.md)
- [Elements, hooks, signals and custom components](docs/framework.md)
- [Every component and its properties](docs/components.md)
- [Styling, layout, themes and animation](docs/styling.md)
- [Four designs and live switching](docs/designs.md)
- [Windows, menus, notifications and configuration](docs/application.md)
- [Build, testing, compatibility and troubleshooting](docs/development.md)
- [Executed verification and remaining checks](docs/verification.md)

Working examples: [basic menu](examples/basic/init.luau), [declarative counter](examples/declarative/init.luau), [complete component gallery](examples/component-gallery/init.luau), [interactive task dashboard](examples/complex-dashboard/init.luau).

## Build and test

Python 3.10+ and the [official Luau CLI](https://github.com/luau-lang/luau/releases) are development tools; the distribution needs neither.

```text
python scripts/build.py
python scripts/build_preview.py
python scripts/build.py --check
python scripts/build_preview.py --check
python scripts/test.py --luau /path/to/luau --compiler /path/to/luau-compile
python scripts/studio_place.py
```

The builder resolves static module imports, validates the graph, caches each factory and emits a reproducible bundle plus SHA-256 manifest. It does not concatenate unresolved ModuleScript code. See [docs/development.md](docs/development.md) for Studio verification and the visual/device checklist.

MIT licensed. No upstream framework code, fonts or icon packs are bundled. The generated wallpaper artwork, source concepts and generation notes are included under [assets](assets/README.md) and docs/concepts.
