# MattLib verification

MattLib is the renamed distribution of the AsterUI framework. The native Studio evidence is preserved unchanged under its original name and hash; the renamed distribution has fresh CLI and build results.

| Check | Result | Evidence and limits |
| --- | --- | --- |
| Luau compilation | **47 files compiled** with official Luau 0.744 | Modular source, examples/loaders, Studio scripts, both distribution names, standalone Preview.lua and generated runners. This is compilation, not a strict Roblox typecheck. |
| MattLib bundled runtime | **54 passed, 0 failed** | [tests/results.json](../tests/results.json). Actual bundle against the limited engine double, including all four example factories. |
| Build/distribution tests | **10 passed** | [tests/build-results.json](../tests/build-results.json). Dependency resolution/cache, deterministic output, rejected unknown/dynamic/escaping/cyclic imports, identical distribution aliases, self-contained preview and matching offline place. |
| Actual Preview.lua | **Passed** | [tests/preview-results.json](../tests/preview-results.json). The complete preview mounted the gallery and released every counted resource/native listener on destruction in the engine double. |
| Native Roblox Studio | **12 passed before rename** | [Original native evidence](../tests/studio/results.json). Real Studio 0.745.0.7451137 Play client at camera viewport 812x675, 2 November 2026 06:23:22 +07:00. Not a native test of the subsequently renamed MattLib revision. |
| Native gallery startup | **Observed before rename** | Original AsterUI gallery reported ready after native smoke cleanup. No screenshot approval is claimed. |
| Native 360x640 fixture | **Not run** | The thirteenth Studio test was added after the successful twelve-case run. Computer use was stopped with physical Escape before running it. |
| Small-screen geometry in CLI | **Passed at 360x640** | Boundary/navigation calculations against the test double; does not replace native mobile testing. |
| Executor capabilities | **Fixtures passed; no live executor test** | Optional gethui and filesystem success/failure/fallback behavior was tested through fixtures. |
| Visual/physical device QA | **Outstanding** | Studio screenshot capture timed out. Physical touch, gamepad, virtual-keyboard occlusion and long-duration profiling remain unverified. |

The original successful native bundle hash is `84caa1ee6bcddf0ef8888035eacd1369b550da8eab8304e9d3b1b9ac3ae8e571`. The historical result file retains that hash. MattLib changes branding, runtime namespaces and configuration schema naming; fresh hashes for the current files are in [dist/manifest.json](../dist/manifest.json) and [dist/preview-manifest.json](../dist/preview-manifest.json). No native/executor success is inferred from the rename or CLI runs.

The regression suite covers functional updates and coalescing; keyed identity/removal; conditional rendering; effects/order/cleanup; refs/fragments/portals; signal batching/derivation/replacement; theme switching without remounts; controlled and uncontrolled inputs; Unicode/numeric/hex validation; simulated pointer and keyboard calculations; dropdown filtering/multiselect/key capture; modal focus logic; window geometry/lifecycle; JSON/schema/migrations; optional runtime/file capabilities; cross-bundle replacement; facade state/configuration/ownership; notification timers; interrupted/reduced-motion tweens; and all four working examples. It checks repeated mounts and rapid updates for stable managed resource counts, without claiming a frame-rate benchmark.

The native suite independently checked real property assignments, state updates, keyed instances, lifecycle cleanup, live themes, a rejected controlled TextBox edit under native delivery, control property creation, programmatic window lifecycle/current safe-area geometry, flex/modifiers, HttpService JSON, same-id replacement, portal ownership and shared facade inputs. It did not synthesize physical/native Activated events.

## Remaining release checks

- Open [dist/MattLib-Showcase.rbxlx](../dist/MattLib-Showcase.rbxlx), press F5, and verify all 13 native smoke cases after the rename. The constrained 360x640 fixture uses native layers rather than a physical phone.
- Review dark/light/custom themes, wrapping, truncation, scrolling, contrast, glyph coverage and long/localized labels at desktop and phone sizes.
- Exercise every input with real mouse/touch/keyboard, including pointer capture outside controls, range-thumb crossing, search/selection, numeric/hex validation and key capture cancellation.
- Drag/resize overlapping windows to each boundary, minimize/restore/hide/show, use the touch restore tray, rotate devices and check safe-area/virtual-keyboard behavior.
- Verify nested overlay Tab/Escape/selection restoration with keyboard/gamepad, tooltip timers, context-menu touch long press and reduced-motion transitions.
- Run the dashboard natively; create/filter/reorder/remove tasks and confirm disclosure state follows task ids.
- Profile realistic target workloads and test parenting/filesystem behavior in the particular standalone environment to be supported.

The implementation and shipped APIs are functional; the remaining visual/device acceptance is not represented as completed production validation.
