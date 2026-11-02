# Four selectable designs

MattLib 1.2.1 includes **MintGlass**, **Ember**, **Vector**, and **Aura**. These presets change the palette, window chrome, navigation layout, control density, corner shapes, section treatment, wallpaper, effects and motion timing. They use the same renderer/components; changing a design retains window geometry, selected tabs, controlled values and local component state.

| API name | Look and navigation | Controls / motion |
| --- | --- | --- |
| `MintGlass` | Graphite and mint, translucent-looking native surfaces, spacious sidebar with an accent rail | 38px controls, 8px corners, accent halos, 220ms window reveal |
| `Ember` | Warm carbon/orange, horizontal tabs, ruled sections and an ivory profile pane in the gallery | 36px controls, 5px corners, tactile 100ms presses, 200ms reveal |
| `Vector` | Midnight/cobalt, workspace-tree navigation, compact inspector sections | 34px controls, 4px corners, crisp focus borders, 200ms reveal |
| `Aura` | Plum/lavender, floating pill navigation and soft inset surfaces | 42px controls, 13px corners, softer hover scaling, 240ms reveal |

Sidebar/tree navigation becomes horizontal when its own container is below 640px, even on a large monitor. At widths below 900px the sidebar uses 148px; wider layouts use at most 176px. Horizontal navigation scrolls when needed. The control gallery uses two columns whenever its content area can fit two 230px cards and a 12px gap. Resizing retains the same keyed input instances and values.

Every design has animated background artwork: mint ribbons, an orange sweep, cobalt grid lighting or lavender waves. Supported executors lazily load a separate [1536x1024 image for each design](../assets/README.md) and cache it. The default artwork uses no atlas or ImageRect cropping. Native gradients and curved strips provide a fallback in Studio and environments without image capabilities. All controls, text and layouts remain native instances. Panel translucency and layered borders approximate glass/glow; live scene blur and exact concept-image fidelity are not claimed.

Shared windows, tabs, sections, dialogs, popovers and toasts use Frames and direct per-object opacity tweens. Their text is not flattened into CanvasGroup textures. Roblox documents that [CanvasGroup texture quality depends on client quality level](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup); eliminating those nested compositing layers addresses the reported soft text without requiring a graphics-setting change. Explicit user-authored native CanvasGroups remain supported.

Original visual references: [Mint Glass](concepts/mint-glass.png), [Ember](concepts/ember.png), [Vector](concepts/vector.png), [Aura](concepts/aura.png). These are proposal images, not screenshots of the running library.

## Choose a design when creating a menu

```lua
local MattLib=loadstring(game:HttpGet("https://raw.githubusercontent.com/Cybersize/MattLib/main/dist/MattLib.lua"))()
local window=MattLib:CreateWindow({
    Id="my-menu",
    Title="My application",
    Design="Ember", -- MintGlass, Ember, Vector, Aura
})
local tab=window:AddTab({Title="Main"})
tab:AddToggle({Id="enabled",Title="Enabled",Default=false})

window:SetDesign("Aura") -- keeps this menu's values and component identities
print(window:GetDesign())
```

`Design` is a per-window override. Multiple windows can use different designs at the same time. Omit it to inherit the application's live design. `window:SetDesign(name)` validates before scheduling an update. `Navigation="Top"` or `"Sidebar"` explicitly overrides the design's navigation choice when an application needs a fixed arrangement.

## Application-wide and declarative use

```lua
local app=MattLib.new({id="my-app",design="Vector"})
local UI=app.UI
local root=UI.mount(UI.h("Window",{
    id="declarative", title="Tools", design="Aura",
},UI.h("Tabs",{orientation="design"}, {
    UI.h("Tab",{id="home",title="Home"}, {
        UI.h("Section",{title="Settings"}, {
            UI.h("Toggle",{label="A stateful control",defaultValue=true}),
        }),
    }),
})))

app:SetDesign("Ember") -- changes inheriting windows and application notifications
print(app:GetDesign())
for _,name in app.Designs do print(name) end -- immutable ordered name list
for _,info in app:GetDesigns() do print(info.name,info.label,info.description) end
```

A declarative Window's `design` prop behaves like facade `Design`. `ThemeProvider` also accepts `design`. Local overrides do not follow an unrelated global design change. Native properties/events and custom component APIs remain the same across all presets.

## Add a live picker

```lua
UI.h("DesignPicker",{presentation="segments"})
```

By default the picker displays the inherited design and calls `app:SetDesign`. Its default presentation is a dropdown; `presentation="segments"` uses the shared segmented control. Props include `name`, `label`, `value`, `onChange`, `disabled` and `style`. To target a particular facade window, pass `value=window:GetDesign()` and an onChange callback that calls `window:SetDesign(value)` from an application component that tracks that selection.

The standalone Preview.lua opens the **Appearance** page. It offers all four choices, animated artwork, interaction examples, intensity/reduced-motion controls and Apply appearance. The **Configs** page saves, loads, exports, imports and resets profiles. Preview profiles register the chosen design, effect intensity and reduced-motion setting alongside the normal control values. Facade designs are not implicitly persisted unless the application registers its own design signal; facade control ids continue to persist normally.

## Effects, palettes and motion

```lua
app:SetEffectIntensity(0.5) -- 0..1: wallpaper visibility and accent halos
app:SetReducedMotion(true) -- completes active tween goals and prevents new animation
app:SetTheme("Light")       -- light surfaces; retains the chosen design and its accent
app:SetTheme("Dark")        -- restores the chosen design's dark palette
app.Theme:Extend({accent=Color3.fromRGB(115,190,255)}) -- custom tokens
```

Choosing a new design applies its preset tokens and resets token overrides/intensity to that preset. The preview explicitly reapplies its registered intensity preference. The reduced-motion runtime setting remains independent. `Theme="Dark"` does not replace an explicitly selected design's accent with the legacy palette. Named Light changes surfaces/text while retaining the design accent. Custom theme tables can override tokens; prefer app:SetTheme for design-aware palette changes and Theme:Extend for custom values.

Motion includes native UIScale hover/press feedback, animated stroke/focus changes, switch thumbs, a travelling tab indicator, crossfading/sliding tab panels, window slide/fade, popover/toast scale/fade and staggered Reveal sections. No RenderStepped polling is added. Every timer/tween and decorator is owned and released on removal; interrupted style goals cannot restore an old design's colors.

Wallpaper uses at most two repeating TweenService animations per visible wallpaper. It pauses when an ancestor is hidden, its ScreenGui is disabled, its window is minimized, reduced motion is enabled, or intensity is zero. Turning motion back on resumes the loops. Resizing recomputes native curve geometry; animation does not rerender the component tree each frame.

## Wallpaper and responsive layouts

```lua
local window=MattLib:CreateWindow({
    Title="My UI", Design="MintGlass",
    Wallpaper={Speed=1,Opacity=0.3}, -- or false to remove the wallpaper
})
local tab=window:AddTab({Title="Main",Icon="controls",Columns=2,MinColumnWidth=240,Gap=12})
tab:AddSection({Title="General"}):AddToggle({Title="Enabled",Default=true})
tab:AddSection({Title="Output"}):AddSlider({Title="Volume",Default=64})
```

`Wallpaper` accepts `Speed` (>0, up to 4), `Opacity` (0..1), `Motion=false`, and optional `Image` (an ordinary Roblox image URI or numeric asset id). Default window opacity is 0.32 for MintGlass, 0.16 for Ember, 0.22 for Vector and 0.30 for Aura; effect intensity multiplies that value. Custom images are gently panned with a separate light layer. Standalone Wallpaper components default to opacity 1 for artwork previews. Studio applications can supply a published image using `Wallpaper={Image="rbxassetid://YOUR_IMAGE_ID"}`. No custom-asset APIs or HTTP security changes are required for the native fallback.

Executor texture loading requires `getcustomasset` (or `getsynasset`), `readfile`, `writefile`, and a working HTTP adapter. `makefolder` is used when present. Explicit capability overrides can provide `httpget`, `request` or `http_request`. `MattLib.new({wallpaperAssets=false})` disables texture loading. `app:GetRuntimeInfo()` exposes `wallpaper` (`native`, `loading`, `texture`) and an optional `wallpaperError`; an image-adapter failure does not prevent the GUI from mounting. No remote source code is fetched by the framework.

To supply application-wide individual images, use `MattLib.new({wallpaperImages={MintGlass=mintUri,Ember=emberUri,Vector=vectorUri,Aura=auraUri}})`. Only supplied entries are overridden. To use a custom image for one window, use `Wallpaper.Image`.

Legacy `MattLib.new({wallpaperImage=uri})` remains available for an existing 2x2 atlas with 3:2 tiles. It clips an oversized image by geometry rather than combining ImageRect cropping with Crop scaling. The atlas stays stationary and its light layer animates, preventing neighboring tiles from entering the viewport during a pan. New automatically downloaded art never uses this path.

Declarative equivalents:

```lua
UI.h("Window",{wallpaper={Speed=1,Opacity=0.3}},children)
UI.h("AdaptiveGrid",{columns=2,minColumnWidth=240,gap=12},sections)
UI.h("Wallpaper",{image="rbxassetid://YOUR_IMAGE_ID",speed=0.7,opacity=0.8,style={height=160}})
UI.h("Icon",{symbol="controls",size=20,color="$accent"})
```

`AdaptiveGrid` measures its own content width and wraps without reparenting its children. Supported built-in line symbols are `home`, `controls`, `layout`, `appearance`, `activity` and `settings`; image and glyph icons remain available.

`Reveal` is also reusable:

```lua
UI.h("Reveal",{order=2},UI.h("Text",{text="A staged entrance"}))
UI.h("Section",{title="Later section",revealOrder=2},children)
```

`Reveal` accepts order, optional delay (seconds), replayKey, name and style. It combines opacity and scale and skips delayed animation with reduced motion. Native styling additionally supports `scale`, `gradient={from,to,rotation?,transparency?,offset?}`, `borderTransparency`, `glow` and `glowColor`. Glow requires a host without its own list layout; wrap flow content in a non-list Frame. See [styling.md](styling.md).

Use [examples/design-selection/init.luau](../examples/design-selection/init.luau) for independent windows and [the full gallery](../examples/component-gallery/init.luau) for persisted global selection. Live executor/device visual acceptance remains separate from CLI and native smoke results in [verification.md](verification.md).
