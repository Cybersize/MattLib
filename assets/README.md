# Wallpaper artwork

The production wallpapers for 1.2.1 are four separate 1536x1024 images, generated with the built-in imagegen tool. Each contains only one design. Runtime text, controls, panels and chrome are native Roblox GUI objects.

| Design | Production image |
| --- | --- |
| MintGlass | [mint-glass-v2.png](wallpapers/mint-glass-v2.png) |
| Ember | [ember-v2.png](wallpapers/ember-v2.png) |
| Vector | [vector-v2.png](wallpapers/vector-v2.png) |
| Aura | [aura-v2.png](wallpapers/aura-v2.png) |

The exact production prompt set is saved in [wallpapers/prompts.json](wallpapers/prompts.json). The previous atlas was the style reference. Files are cached separately and loaded only when their design is requested. Default wallpaper strength is lower than the artwork files themselves so controls stay legible.

[wallpapers-v1.png](wallpapers-v1.png) is retained as a historical reference and optional legacy atlas. It is no longer downloaded automatically. It is 1536x1024 with 768x512 tiles: MintGlass at (0,0), Ember at (768,0), Vector at (0,512), and Aura at (768,512). Legacy custom atlases use geometric clipping; the default runtime does not use sprite cropping.

The textured wallpaper pans slowly and has a separate moving light layer. It is not a video, shader, or simulation of cloth. Without an image adapter, the runtime uses native curved gradient strips or a native grid. The proposal UI images in docs/concepts are visual references, not screenshots of the implementation.

## Historical atlas generation prompt

Tool: built-in imagegen. References, in order: docs/concepts/mint-glass.png, ember.png, vector.png, aura.png. Transparent background: false.

> Use case: stylized-concept. Asset type: one production wallpaper TEXTURE ATLAS for a native Roblox interface, NOT a UI mockup. Input images 1 through 4 are STYLE REFERENCES ONLY for Mint Glass, Ember, Vector and Aura respectively. Create a landscape 1536 by 1024 image containing exactly four edge-to-edge rectangular wallpaper tiles in a precise 2-by-2 grid. Each tile occupies exactly one quarter of the image with absolutely no gutters, borders, labels or UI. TOP LEFT Mint Glass: near-black graphite #0A1216, extremely elegant flowing translucent mint/teal light ribbons, illuminated fine edges, small realistic dust/grain, a bright arc rising from lower left and a luminous fold near upper right. Center and upper left mostly dark so overlay text will be legible. This must look like the organic light ribbons in reference 1, not flat gradient bands. TOP RIGHT Ember: matte warm carbon #161514, subtle refined tactile grain, a soft orange glow and a slim diagonal ember seam in bottom right; largely dark and restrained like reference 2. BOTTOM LEFT Vector: deep midnight navy #0A121D, finely rendered precise cobalt graph grid with thin low-contrast lines, a few brighter blue line intersections, subtle cool atmospheric lighting, no text, no diagrams, no UI. BOTTOM RIGHT Aura: rich dark plum #1A1625 with beautifully sculpted translucent flowing lavender silk/glass folds, wide softly glowing ribbons with lilac highlights and shadows like the wallpaper hero in reference 4; keep center and upper left dark enough for overlay text. Four completely independent palettes, hard exact quadrant boundaries. Premium abstract digital material rendering with depth, curved surfaces, texture and soft lighting. Fill the canvas edge to edge. No frame, no monitor, no perspective view, no buttons, no text, no letters, no logos, no watermark. The only image content is wallpaper artwork. The references are interface concepts; REMOVE ALL their interface elements and retain only their wallpaper/material language.
