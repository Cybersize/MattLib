# Architecture decision: a small, native Luau renderer

Research reviewed on 2 November 2026. This is an original implementation; upstream libraries were reviewed for their architecture and public API, not vendored.

| Approach | Benefits | Costs for this project | Decision |
| --- | --- | --- | --- |
| React Lua / ReactRoblox | Mature React model, hooks, Roblox host renderer, established ecosystem | Multiple cooperating packages and module resolution need bundling; React's scheduler and compatibility surface are much larger than this library needs | Prefer it for existing React Roblox applications. Do not emulate its full compatibility contract here. |
| Fusion | Native reactive values, derived computations, explicit scopes and cleanup, portable Luau | Different authoring model from the requested functional-component/hook API; wrapping it would add two lifecycle systems | Strong alternative for a signal-first application. Borrow the principle of explicit ownership, without a dependency. |
| Independent runtime | One dependency-free distribution, predictable synchronous commits, small public API, environment isolation | Reconciliation, lifecycle, cleanup, and input behavior become our responsibility and need regression tests | **Selected.** MattLib has its own documented semantics, with React-inspired authoring. |
| TypeScript / JSX | Build-time types and convenient nested syntax | roblox-ts's documented Roact JSX targets Roact's factory and conventions; it is not automatically an MattLib frontend | Optional future custom transformer/adaptor. No JSX compatibility is advertised or required. Luau examples are executable. |

## Primary references

- [React Lua repository and package status](https://github.com/jsdotlua/react-lua), [React API and deviations](https://github.com/jsdotlua/react-lua/blob/main/docs/api-reference/react.md): functional components, stable keys, effects and refs are useful; partial React compatibility should be explicit.
- [Roblox UI overview](https://create.roblox.com/docs/ui), [list and flex layouts](https://create.roblox.com/docs/ui/list-flex-layouts), [UIFlexItem](https://create.roblox.com/docs/reference/engine/classes/UIFlexItem): native instances support layout, modifiers, scrolling and flex distribution, but not a browser box model.
- [ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui), [GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject), [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService): safe insets, hierarchical z ordering, mouse/touch/keyboard input, selection and text focus must be handled at the client boundary.
- [Fusion](https://github.com/dphfox/Fusion), [Fusion scopes](https://elttob.uk/Fusion/0.3/tutorials/fundamentals/scopes/): ownership of subscriptions and destruction is a first-class concern.
- [roblox-ts Roact JSX guide](https://roblox-ts.com/docs/guides/roact-jsx/): JSX is compilation syntax, not runtime HTML.
- [BobloUI public API](https://github.com/bobloscript/BobloUI), [Fluent's author-maintained example](https://github.com/dawid-scripts/Fluent/blob/master/Example.lua), [Rayfield window API](https://github.com/SiriusSoftwareLtd/docs/blob/main/rayfield/windows.mdx): window/tab/section/control handles are approachable for menu authors. MattLib maps this facade onto the same declarative controls. Executor-related features outside UI are excluded.

## Boundaries

`core/Element` owns element construction and name registration. `Reconciler` performs pure O(n) sibling matching. `Renderer` owns fibers and commits; `Host` owns native instances, property resets, decorator instances, native events, refs and pseudo states. Component modules only compose elements, hooks and shared behaviors. They do not implement another renderer.

`Hooks` owns per-fiber state. Setters are stable, updater functions consume the latest queued value, and changes enqueue the affected functional fiber. A task-deferred root scheduler coalesces updates. An ancestor rendered in the same commit subsumes its dirty descendants. Existing instances and connections are reused. A root has a finite commit-loop guard. Errors are surfaced and that root is unmounted so partially committed trees cannot linger. Other roots remain independent.

Hooks have fixed order and count. Render functions must not yield, perform side effects or set state. Effects run synchronously **after a complete commit**, not after a browser paint. Cleanup precedes reruns and unmount. There is no concurrent rendering, Suspense, React context API, class-component API, synthetic event system or promise scheduling. Dependency arrays compare values by identity; use dense arrays without nil holes. `useMemo` is a cache for filters/derived presentation, not a lifecycle guarantee. `useSignal` reconnects if the signal changes. Signals can be shared outside a tree; derived signals declare dependencies explicitly and must be destroyed by their owner.

Keys are unique among siblings and include their Luau type. Matching uses key plus element type; unkeyed children use their flattened position. Reordering changes `LayoutOrder` without remounting. Fragments add no instances. Portals retain logical ownership but render under another native parent. Theme providers override the inherited theme service without global singleton state.

`styling` resolves semantic token references and a bounded style vocabulary into properties and owned modifiers. Pseudo states have precedence active < hover < pressed < focus < disabled. Native flex is opt-in. There is no selector language, cascade, DOM, HTML parser, percentage margin model or full CSS engine. Use parent padding/gap or the `Inset` component for exterior spacing. CanvasGroup is used when descendant opacity is needed; ordinary opacity applies to the object's own visible properties.

`runtime/Adapter` is the only capability-detection and parenting boundary. It uses an explicit parent, then a successful optional gethui, then PlayerGui. It never requests privileged CoreGui parenting or installs concealment. A marked ScreenGui and a disposal BindableFunction allow synchronous replacement of the same library id across separately loaded copies; Destroying is an additional cleanup path. Namespaced ids allow independent applications. No external source is fetched at runtime.

`runtime/Input` shares one set of service listeners, pointer capture and ordered keyboard dispatch per library. Window geometry updates native properties during a gesture, avoiding component-tree work per pointer move. Window frames live under a safe-inset layer and are clamped against its actual size. Overlays use portals to escape scrolling clips; modal focus and outside dismissal are owned and restored. Native GUI selection, readable labels, disabled gates and keyboard alternatives are provided, without claiming web ARIA or universal screen-reader support.

`animation/Animator` replaces interrupted tweens by instance/channel, disconnects completion handlers, and releases tweens on destruction. Reduced motion completes active goals and prevents looping motion. No RenderStepped polling is used.

`config` validates and decodes every incoming registered value before applying any changes. JSON uses a named schema and version, bounded data structures and tagged Color3 values. Migrations are explicit. Optional file APIs are detected independently, and memory storage works without them. File errors are returned to the caller.

## Distribution and verification policy

Source modules use ordinary Studio `script.Parent` requires. The Python builder resolves only static source-module requires, rejects unknown imports/cycles, wraps each module in a cached factory and emits a dependency-ordered registry. `dist/Library.lua` does not use loadstring, external packages or runtime ModuleScripts. A Rojo project and generated Studio place support native development.

CLI regression tests run actual bundled Luau against a deliberately limited Roblox test double. They establish reconciliation/state/cleanup and input calculations, not engine rendering fidelity. Studio smoke tests and interactive gallery verification are separately reported in `verification.md`. A binary compiler check is not represented as a strict Roblox typecheck or a visual test. No executor-specific behavior is claimed without testing that environment.
