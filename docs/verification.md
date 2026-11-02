# MattLib 1.2 verification

The current runtime and self-contained preview contain MintGlass, Ember, Vector and Aura, native animated wallpapers, optional textured wallpapers and responsive control columns. Results below identify executed checks separately from remaining visual/device testing.

| Check | Result | Evidence and limits |
| --- | --- | --- |
| Luau compilation | **53 files compiled** with official Luau 0.744 | Source, five example factories, loaders, Studio scripts, distribution aliases, Preview.lua and generated runners. Compilation is not a strict Roblox typecheck. |
| Runtime regression suite | **85 passed, 0 failed** | [tests/results.json](../tests/results.json). Actual bundle against a limited engine double, including all four designs, state-preserving switching, adaptive layout, wallpaper lifetime/caching/failure fixtures and all five examples. |
| Build/distribution suite | **10 passed** | [tests/build-results.json](../tests/build-results.json). Graph/cache validation, deterministic output, rejected imports, matching aliases, preview and Studio place. |
| Actual Preview.lua | **Passed** | [tests/preview-results.json](../tests/preview-results.json). Full live-picker gallery mounts and destroys without managed instance/listener/subscription/tween leaks in the engine double. |
| Native Roblox Studio 1.2 | **23 passed, 0 failed** | [tests/studio/results.json](../tests/studio/results.json). Real Studio 0.745.0.7451137 Play client; tested bundle and gallery sources match the final distribution/preview. Camera viewport 812x675. |
| Native designs and gallery | **All four passed** | Native runtime checked gradient/scale/glow creation and removal, layout/state identity through switches, scoped window designs and each of the four gallery factory variants. The gallery also reported ready after smoke cleanup. |
| Native constrained mobile layout | **Passed at 360x640** | A real native-layer constraint fixture, including window bounds, top-navigation fallback and modal sizing. This is not a physical phone test. |
| Native dense gallery layout | **Passed at 790x640** | 148px sidebar, 582px content area, two 285px cards separated by 12px. Actual engine positions establish non-overlap. See the stored layout_metrics. |
| Native wallpaper motion | **Passed** | Actual ribbon Position changed over time. Reduced motion stops it, hidden windows release the loops, and showing/resuming restarts them. Adaptive-grid tests check row positions and input identity through wrapping. |
| Executor compatibility | **Capability fixtures only** | Optional gethui/filesystem/image-adapter success, cache hits, download failure and native fallback are covered. No live executor was used; the generated texture has not been visually checked in an executor. |
| Visual and physical-device review | **Outstanding** | Two current Studio screenshot attempts failed with FrameArrived/window-capture channel timeouts. No screenshot acceptance or exact match to the concepts is claimed. Native measurements and movement tests are independently recorded. |

Exact runtime/preview hashes are in [dist/manifest.json](../dist/manifest.json) and [dist/preview-manifest.json](../dist/preview-manifest.json). Native evidence records the matching bundle hash and UTC timestamp. Historical evidence is retained separately as [results-v1.0.json](../tests/studio/results-v1.0.json) and [results-v1.1.json](../tests/studio/results-v1.1.json); those are not used to claim current-version validation.

## Regression coverage

The suite covers declarative creation/props/removal, stable hooks, updater batching, keyed reconciliation, fragments/portals, effect order/cleanup, signals and derived state, controlled/uncontrolled inputs, Unicode/numeric/hex validation, dropdown/multiselect/keybind behavior, modal keyboard/focus logic, window movement/resize calculations, safe-area constraints, JSON/schema/migrations, optional capabilities, cross-bundle replacement, facade ownership, notifications and interrupted/reduced-motion tweens.

Design-specific tests check distinct preset metadata and colors; real navigation orientation changes; repeated design cycles retaining window/tab/component/native/control state and stable resource counts; per-window independence; Dark/Light behavior; validation before mutation; animated native scale/stroke/gradient goals; interruption without stale colors; effect-intensity cleanup; title-height changes while minimized; retained clamped geometry; tab-state retention; cancelled reveal timers; a shared DesignPicker; gallery startup under every design; and config restoration of the selected design.

A switching regression found that an Ember section separator shifted unkeyed content. Internal keyed fragments now preserve child identity across section treatments. Another check verifies that old hover-tween goals cannot overwrite a newly selected palette. These are behavioral regressions, not mirror tests of a theme table.

The native suite checks actual engine assignments, property delivery, lifecycle resources, HttpService JSON, native flex/modifiers, per-design chrome/navigation and gallery startup. It does not synthesize Activated events or establish physical input/visual fidelity.

The wallpaper suite verifies bounded repeating tweens, no component rerenders during steady animation, hide/minimize/disabled-ScreenGui pause and resume, retained inactive-tab behavior, reduced-motion resume, design-specific artwork, image tile selection, cache reuse, rejected invalid PNG metadata and cancellation before deferred fetch work. PNG decoding and executor-specific asset rendering remain separate from these fixtures. The generated artwork is 1536x1024; the optional adapter validates those atlas dimensions before caching it.

## Remaining acceptance

- Review the final preview visually at desktop and phone sizes: typography, contrast, glyphs, halos, wrapping, scroll behavior and localization. The four PNGs under docs/concepts are proposed visual directions, not runtime screenshots.
- Exercise mouse, touch, gamepad and virtual-keyboard flows on physical devices, including dragging/resizing, range capture, dropdown search, focus restoration and context-menu long press.
- Review animation timing, rapid interruptions and reduced motion in a target client, and profile realistic long-running workloads.
- Verify a particular standalone environment's parenting/filesystem functions before promising compatibility with it.

Implementation and automated/native functional checks are complete. Remaining visual/device acceptance is explicitly unverified.
