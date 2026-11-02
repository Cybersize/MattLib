# MattLib 1.1 verification

The current runtime and self-contained preview contain four working design presets: MintGlass, Ember, Vector and Aura. Results below identify the executed checks separately from remaining visual/device testing.

| Check | Result | Evidence and limits |
| --- | --- | --- |
| Luau compilation | **50 files compiled** with official Luau 0.744 | Source, five example factories, loaders, Studio scripts, distribution aliases, Preview.lua and generated runners. Compilation is not a strict Roblox typecheck. |
| Runtime regression suite | **76 passed, 0 failed** | [tests/results.json](../tests/results.json). Actual bundle against a limited engine double, including all four designs, state-preserving switching and all five examples. |
| Build/distribution suite | **10 passed** | [tests/build-results.json](../tests/build-results.json). Graph/cache validation, deterministic output, rejected imports, matching aliases, preview and Studio place. |
| Actual Preview.lua | **Passed** | [tests/preview-results.json](../tests/preview-results.json). Full live-picker gallery mounts and destroys without managed instance/listener/subscription/tween leaks in the engine double. |
| Native Roblox Studio 1.1 | **20 passed, 0 failed** | [tests/studio/results.json](../tests/studio/results.json). Real Studio 0.745.0.7451137 Play client; tested bundle is byte-for-byte equal to the final runtime. Camera viewport 812x675. |
| Native designs and gallery | **All four passed** | Native runtime checked gradient/scale/glow creation and removal, layout/state identity through switches, scoped window designs and each of the four gallery factory variants. The gallery also reported ready after smoke cleanup. |
| Native constrained mobile layout | **Passed at 360x640** | A real native-layer constraint fixture, including window bounds, top-navigation fallback and modal sizing. This is not a physical phone test. |
| Executor compatibility | **Capability fixtures only** | Optional gethui/filesystem success, failure and fallback are covered. No live executor was used. |
| Visual and physical-device review | **Outstanding** | Screenshot capture reported FrameArrived timeout. A recovery attempt ended when the user stopped Computer Use with physical Escape; no further app input was issued. No visual screenshot approval is claimed. |

Exact runtime/preview hashes are in [dist/manifest.json](../dist/manifest.json) and [dist/preview-manifest.json](../dist/preview-manifest.json). The native evidence records its matching bundle hash and local timestamp. Historical pre-rename evidence is retained separately as [results-v1.0.json](../tests/studio/results-v1.0.json); it is not used to claim current-version validation.

## Regression coverage

The suite covers declarative creation/props/removal, stable hooks, updater batching, keyed reconciliation, fragments/portals, effect order/cleanup, signals and derived state, controlled/uncontrolled inputs, Unicode/numeric/hex validation, dropdown/multiselect/keybind behavior, modal keyboard/focus logic, window movement/resize calculations, safe-area constraints, JSON/schema/migrations, optional capabilities, cross-bundle replacement, facade ownership, notifications and interrupted/reduced-motion tweens.

Design-specific tests check distinct preset metadata and colors; real navigation orientation changes; repeated design cycles retaining window/tab/component/native/control state and stable resource counts; per-window independence; Dark/Light behavior; validation before mutation; animated native scale/stroke/gradient goals; interruption without stale colors; effect-intensity cleanup; title-height changes while minimized; retained clamped geometry; tab-state retention; cancelled reveal timers; a shared DesignPicker; gallery startup under every design; and config restoration of the selected design.

A switching regression found that an Ember section separator shifted unkeyed content. Internal keyed fragments now preserve child identity across section treatments. Another check verifies that old hover-tween goals cannot overwrite a newly selected palette. These are behavioral regressions, not mirror tests of a theme table.

The native suite checks actual engine assignments, property delivery, lifecycle resources, HttpService JSON, native flex/modifiers, per-design chrome/navigation and gallery startup. It does not synthesize Activated events or establish physical input/visual fidelity.

## Remaining acceptance

- Review the final preview visually at desktop and phone sizes: typography, contrast, glyphs, halos, wrapping, scroll behavior and localization. The four PNGs under docs/concepts are proposed visual directions, not runtime screenshots.
- Exercise mouse, touch, gamepad and virtual-keyboard flows on physical devices, including dragging/resizing, range capture, dropdown search, focus restoration and context-menu long press.
- Review animation timing, rapid interruptions and reduced motion in a target client, and profile realistic long-running workloads.
- Verify a particular standalone environment's parenting/filesystem functions before promising compatibility with it.

Implementation and automated/native functional checks are complete. Remaining visual/device acceptance is explicitly unverified.
