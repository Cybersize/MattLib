# MattLib on GitHub

Repository: [Cybersize/MattLib](https://github.com/Cybersize/MattLib).

Version 1.1 includes MintGlass, Ember, Vector and Aura. The preview opens a live design chooser. Scripters can pass `Design="Ember"` to CreateWindow and call `window:SetDesign("Aura")` later. See [the design API](docs/designs.md).

Full gallery preview:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Cybersize/MattLib/main/Preview.lua"))()
```

Library only:

```lua
local MattLib=loadstring(game:HttpGet("https://raw.githubusercontent.com/Cybersize/MattLib/main/dist/MattLib.lua"))()
```

For reproducible application integration, replace `main` in either URL with the desired Git commit SHA. The branch URL follows the repository's current main branch. The library itself performs no remote source fetches. Preview.lua embeds both the runtime and the gallery, returning the example app with `Destroy()`.

Before pushing source changes, rebuild and verify:

```text
python scripts/build.py
python scripts/build_preview.py
python scripts/studio_place.py
python scripts/build.py --check
python scripts/build_preview.py --check
python scripts/test.py --luau /path/to/luau --compiler /path/to/luau-compile
python -m unittest discover -s scripts/tests -v
```

Commit the source, both distribution names, Preview.lua, manifests, current tests and the matching Studio place together. Keep credentials and local generated work directories out of the repository.
