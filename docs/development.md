# Build, compatibility and troubleshooting

## Source layout

```text
src/core/           Elements, hooks, signals, matching, renderer and native hosts
src/styling/        Tokens, theme services, style resolution and layout modifiers
src/components/     Primitives, layouts, navigation, inputs and feedback
src/animation/      Central interruptible TweenService utility
src/window/         Pointer/keyboard geometry and window registry
src/config/         Versioned JSON settings and optional filesystem storage
src/runtime/        Parenting/capabilities, shared input dispatch and overlay focus
src/menu/           Imperative handles rendered by shared functional components
src/feedback/       Owned notification queue/timers
src/utils/          Cleanup scopes and diagnostics
examples/           Four executable ModuleScript factories
tests/              CLI regression suite, engine double, Studio tests/results
scripts/            Deterministic bundle/test/place/package tools
dist/               Standalone Lua, source manifest and offline showcase place
```

## Reproducible development commands

Use Python 3.10+ and the official Luau CLI. The recorded checks use Luau 0.744. Python tooling uses the standard library only.

Optionally run `python scripts/fetch_luau.py` to download the official 0.744 platform archive into `.tools/0.744`. It verifies a pinned release SHA-256 before extraction and does not execute the downloaded tools. Supply `--destination` to use an external development-tools folder. The framework itself never runs this downloader.

```text
python scripts/build.py
python scripts/build_preview.py
python scripts/build.py --check
python scripts/build_preview.py --check
python scripts/test.py --luau /absolute/path/luau --compiler /absolute/path/luau-compile
python -m unittest discover -s scripts/tests -v
python scripts/studio_place.py
python scripts/package.py
```

Windows tool executables have `.exe` suffixes; quote paths containing spaces. Test tooling accepts `--work-dir` to place generated runners outside the repository. The generated runner executes the **actual standalone bundle**, including optional multiple independent bundle copies, with lexical engine doubles. It is not a rewritten implementation of the state engine. Results go to `tests/results.json`. Compile checks include source, examples, Studio scripts, the distribution and runner. The compiler does not provide Roblox strict-type validation; most dynamic modules deliberately use nonstrict mode.

The bundler resolves static `require(script.Parent...)` imports against the source hierarchy, rejects imports escaping src, unsupported/dynamic requires, unresolved imports and cycles, then emits dependency-ordered factories with a local module cache. Its manifest includes source/bundle SHA-256 hashes and dependencies. It contains no runtime ModuleScript resolution, loadstring, fetch or package-manager bootstrap. Build output is deterministic. If source changes, rebuild both Library.lua and the showcase place before testing/distributing.

`default.project.json` maps the modular library, all example factories, Smoke module and client Bootstrap through Rojo. The generated `.rbxlx` uses the same bundle and examples without requiring Rojo. Change the Bootstrap LocalScript's `Example` attribute to `Dashboard`, `Basic`, or `Declarative` to open another demo. Default is `Gallery`.

## Studio validation

Open `dist/MattLib-Showcase.rbxlx`, press F5 (Play, not server-only Run) and inspect Output for `MATTLIB_STUDIO_RESULTS` and `MATTLIB_GALLERY_READY`. Smoke runs on the real client, validates native property assignments, state/reconciliation, cleanup, configuration, menus, portals and constrained viewport geometry. It cleans test clients before opening the gallery. `tests/studio/Smoke.luau` can also be required/called from another client LocalScript with the Library object.

Automated geometry checks do not establish a polished visual layout or physical input behavior. Before a production release, complete the checklist in [verification.md](verification.md) on target devices. Keep native log evidence limited to project markers/results rather than sharing full Studio logs.

## Performance and ownership

- Keep function types and sibling keys stable. A fresh component function defined during render remounts its subtree.
- Keep state near the component that changes. Parent state updates naturally rerender descendants; sibling-local state does not rerender the whole window.
- Treat tables as immutable. Reuse stable dependency/option tables when possible, and useMemo for expensive filters.
- useSignal owns a subscription; the model owner must destroy shared/derived signals. Effects must return cleanup for any application-created timers/connections.
- Tabs retain inactive pages by default. Use unmountInactive for expensive hidden content. Collections are reconciled but **not virtualized**; paginate/virtualize very large data sets at the application layer.
- Avoid continuously changing Instance props behind the renderer. Use refs for intentional imperative ownership, as window geometry does.
- `app:GetDiagnostics()` reports aggregate active roots/components/instances/connections/subscriptions/tweens/windows and cumulative renders for all apps sharing that loaded bundle copy. Scope-managed native connections and signal/input subscriptions are counted. External application connections/instances are not counted.
- `Destroy` releases native instances, helper modifiers, subscriptions, input captures, notification timers and tweens. A user-retained destroyed handle remains a user-owned Lua reference; do not keep unbounded handle histories.

The library has no RenderStepped polling loops. LoadingIndicator uses a managed repeating TweenService tween; reduced motion stops it. A renderer commit has an update-loop guard, and duplicate keys/hook-order violations fail visibly. A failed render/commit unmounts that root instead of leaving half-created UI behind. Async render errors use onError or warn.

## Compatibility boundaries

- Native Roblox client UI is the baseline. Server scripts and non-Roblox Luau runtimes do not provide the required services/types; the CLI suite supplies an explicit test double.
- Current Roblox UIListLayout flex properties and UIFlexItem are used when requested. Clients lacking those features should use non-flex Row/Column layouts; an unsupported native assignment fails visibly rather than silently approximating CSS.
- Screen safe-area constraints apply to library windows/layers. Custom absolute layouts, very large minimum sizes, localization and virtual-keyboard occlusion need application/device testing.
- CanvasGroup provides subtree opacity but has Roblox offscreen-texture/memory/clipping constraints. Windows/overlays use it intentionally; avoid deep unnecessary CanvasGroup nesting in large custom UIs.
- No React, Roact or Fusion element/hook interoperability is claimed. JSX/roblox-ts is not shipped as an authoring frontend. A build-time adapter is possible but must emit this library's actual API.
- Optional executor-style gethui/filesystem functions were tested through capability fixtures, not a live standalone executor. No environment-specific guarantee is implied.
- NumericInput uses tonumber rather than locale-aware decimal formatting. ColorPicker is RGB/hex, Keybind captures keyboard keys, and Icon accepts glyphs or supplied image assets.
- Native selection/text focus, semantic metadata, readable labels, disabled gates and keyboard alternatives are implemented. There is no browser ARIA bridge or guaranteed screen-reader compatibility. Physical touch/gamepad/virtual-keyboard/IME behavior requires device checks.

## Troubleshooting

| Symptom | Check / correction |
| --- | --- |
| LocalPlayer unavailable | Run from a client LocalScript in Play mode, not a server Script or the edit-time command bar. |
| Nothing appears after requiring | Requiring is lazy. Call UI.mount or CreateWindow. Check ScreenGui Enabled, supplied parent, and Output/onError. |
| Window vanished after reloading | Same application id intentionally replaces its earlier instance. Use distinct ids for independent applications. Hidden windows appear in the restore tray; RightShift is the default toggle key. |
| Full subtree resets on reorder | Supply unique stable keys and stable function references. Do not use a changing array index as a data identity. |
| Controlled input appears stuck | Its parent must accept onChange and supply the new value. Use defaultValue for internal state. False is valid; nil means uncontrolled. |
| Hook count/order error | Move conditional branches after unconditional hook calls, or split the conditional subtree into its own component. |
| RichText/Unicode looks different | Roblox font/platform glyph coverage varies. Use image assets for exact icons. Use native RichText syntax. |
| Scroll content clipped | Give ScrollArea a bounded viewport height; use contentStyle for padding/gap. Avoid percentage-height children under an auto-height parent. Popover/Modal provide scrollable bodies. |
| Gap/flex differs from a web mockup | Native Roblox layout is not CSS flexbox. Use explicit UDim sizes for precise arrangements. |
| Save uses memory | Optional writefile is absent/disabled. GetRuntimeInfo reports detected functions. Studio has no standard local filesystem API; export/import JSON works there. |
| Disk save/load fails | Check returned error, relative folder, optional folder-creation capability and profile name. No successful-disk-write claim is made after failure. |
| Configuration import rejected | Check schema/version, registered types/validators, Color3 tags, dense arrays and migration chain. Failed import is atomic. |
| Input or resources remain active | Unmount roots or destroy the app, unsubscribe external subscriptions and destroy externally owned signals. Compare active diagnostics before/after. |
| Async error dismissed a root | Read onError/Output. Correct invalid props, duplicate keys, hook order or failing effect. Create a new root after the failed root is unmounted. |

When filing a bug, include a minimal Luau component, client version, viewport/device, source/bundle hash, expected/actual behavior and active diagnostic deltas. Do not include credentials or unrelated executor features.
