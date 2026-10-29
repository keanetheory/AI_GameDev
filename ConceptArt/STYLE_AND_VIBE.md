# Lighting the Storm: Style and Vibe

Reference for generating the remaining assets: concept art, 3D models, textures and UI.

It brings together the locked style guide (`Docs/Lore Build/world/style_guide.md`), the lighting spec (`LightingTheStorm/data/world/lighting_spec.json`), the sea look (`data/world/wave_spec.json`) and the cel-shading values the game uses (`scripts/world/toon_look.gd`, `interior/kit.gd`). If anything here disagrees with the style guide, the style guide wins.

---

## 1. The vibe in one line

**A grim, rain-lashed 1800s lighthouse on a black sea under a moon something is swallowing: dark, eerie and full of unanswered questions, with dry gallows humour from the people stuck in it.**

### Mood
- **Dark, grim, eerie.** Every scene should raise more questions than it answers. Nothing is explained by the art.
- **Cold outside, warm inside.** Outside is cold, wet slate and silver. Inside is warm amber lamplight on lime plaster and dark timber. That contrast is the game's emotional core: shelter against the storm.
- **Abandoned and watched.** There are lit forts with nobody on the walls, a dead harbour, and posters praising the moon. Places look recently left, not ruined.
- **Haunted but physical.** The creepiness comes from real things: people hiding in the walls, bangs, whispers. Nothing is supernatural, glowing or ghostly.
- **Gallows humour.** The characters (Ted, Arthur, Daniel) are snarky against the grim setting. Characters can be a little exaggerated and expressive; the world stays heavy and serious.

### Era and world
- Mid-to-late 1800s, gaslight and steam. Buildings are mid-1800s stone and brick.
- Technology: coal boilers, steam engines, dynamos, carbon-arc lamps, brass gauges, riveted iron, oil and gas lamps.
- Coastal working life: oilskin, heavy wool, oily leather, rope, tar, barnacled timber, chain.
- Odd details are deliberate: soldiers in chain mail and nose-guard helmets in a steam age.

### The four pillars, as art
| Pillar | What the art should do |
|---|---|
| A creepy, haunted lighthouse | Narrow spaces, deep shadow pockets, cracks and gaps in walls, rooms that look lived in moments ago |
| The mystery of the moon | A huge low silver supermoon; the black sphere eclipsing it; circle, sphere and wave-line motifs |
| Funny, snarky characters | Readable, characterful silhouettes and faces, weather-hunched, each in their personal colour |
| An intriguing city | Saint Calder far across the water: Gothic spires, a cathedral, rows of small amber and gold windows, closed off |

---

## 2. Art style

### Descriptors (use these in prompts)
- gritty dark cel-shaded
- heavy ink outlines
- flat cel shading with hard-edged shadow shapes
- hand-traced, rotoscope-style linework
- grimy hand-painted textures
- muted, desaturated palette

Do **not** name reference works or artists in prompts. The touchstones (A Scanner Darkly, Borderlands) are for people only.

### Shapes and silhouettes
- **Architecture:** heavy, squat, weather-beaten masonry. Rough-dressed blocks in visible courses, arched windows and doors with dressed stone surrounds, steep roofs of rust-red clay tile or slate, brick chimneys with clay pots, iron brackets and railings. Slightly irregular, never perfectly square or clean.
- **Rock and cliffs:** fractured, angular slate and basalt with sharp facets, mossy green-olive tops, mustard lichen at the waterline, sea stacks like broken teeth.
- **Timber:** grey, split, salt-bleached planks; dark wet piles with weed and barnacles; rope lashings and iron straps.
- **Coastfolk:** bulky, rounded, weather-hunched. Oilskin coat, thick jumper, heavy black boots, plus their personal colour.
- **Garrisons:** tall and rigid. Chain mail, steel, nose-guard helmets, mail shoulders.
- **The Flighted (iconography only):** circles, spheres and wave lines in crude printed ink. The recurring icon is a dark sphere eclipsing a silver moon above waves.

### Surfaces
- Everything is worn: chipped edges, soot, rust streaks running down from iron fixings, water staining, moss in the joints, salt bloom.
- Surfaces are matte. The only shine comes from wet rock and timber in the storm, brass and glass. No clean gloss anywhere.

---

## 3. Colour schemes

### 3.1 Core palette (locked)
| Swatch | Hex | Name | Meaning and use |
|---|---|---|---|
| ![](https://placehold.co/16x16/0E0E10/0E0E10.png) | `#0E0E10` | Black | The Flighted. The darkest storm cloud, night silhouettes |
| ![](https://placehold.co/16x16/1F2A44/1F2A44.png) | `#1F2A44` | Navy | The Flighted, and Ted (a deliberate clue linking him to them). Night ambient light |
| ![](https://placehold.co/16x16/2C3A40/2C3A40.png) | `#2C3A40` | Sea slate | The Gullwater. Fog, cloud undersides |
| ![](https://placehold.co/16x16/6B6B66/6B6B66.png) | `#6B6B66` | Stone grey | Bracken Isle and the lighthouse |
| ![](https://placehold.co/16x16/B9BEC4/B9BEC4.png) | `#B9BEC4` | Silver | The Flighted (the moon). Moonlight, lightning, the beacon, the arc lamp, rain, foam |
| ![](https://placehold.co/16x16/C07A1E/C07A1E.png) | `#C07A1E` | Amber | Saint Calder's royal standard. Lamplight, fire, furnace, lit windows |
| ![](https://placehold.co/16x16/B8962E/B8962E.png) | `#B8962E` | Gold | Saint Calder's royal standard (always paired with amber). Brass, the boat lamp |
| ![](https://placehold.co/16x16/2F4A34/2F4A34.png) | `#2F4A34` | Green | Arthur |
| ![](https://placehold.co/16x16/7A2620/7A2620.png) | `#7A2620` | Red | Daniel |

### 3.2 Reserved colours: keep them consistent
- **Navy `#1F2A44` belongs to Ted and the Flighted.** Do not give navy to anyone or anything else that the player could read as a clue: no navy coats on extras, no navy props. Ink outlines must never be navy.
- **Black, silver and navy together mean the Flighted.** Use that combination only on their posters, papers and iconography.
- **Amber and gold together mean Saint Calder's crown.** Use them for city banners, royal seals and the city's windows.
- **Green means Arthur and red means Daniel.** Keep those exact hues for their clothing accents. Background greens are moss (olive, desaturated) and background reds are rust and clay tile (orange-brown), never these clean character hues.

### 3.3 Exterior and environment palette
These are taken from the concept art and the game's materials. Hex values are approximate targets for albedo (the unlit surface colour).

| Material | Approx. hex | Notes |
|---|---|---|
| Lighthouse limestone | `#9E917A` | Warm cream-grey blocks with ochre and rust staining, darker in the joints |
| Footing and plinth stone | `#6B6B66` | Cold grey, mustard lichen near the ground |
| Worn stair stone | `#3B342F` | Dark grey-brown, smoothed by feet |
| Clay roof tile | about `#8A4A30` | Rust red-brown, mottled with moss and soot |
| Weathered timber | `#735E4C` / `#45382E` | Grey-brown, salt-bleached on top, near black when wet |
| Iron (rails, lantern frame, brackets) | `#2B2E33` | Near black, with rust bleeding orange below fixings |
| Rock (island, sea stacks, cliffs) | about `#3A3A3C` | Dark slate with olive moss tops; goes darker and glossier in the storm (the game darkens it to 72% when soaked) |
| Moss | about `#4A5130` | Olive, desaturated; never bright green |
| Lichen | about `#8F7A3A` | Mustard, in patches near the waterline |

### 3.4 Interior palette (warm, no neutral greys)
| Material | Hex | | Material | Hex |
|---|---|---|---|---|
| Lime plaster | `#8F8069` | | Brass (aged gold) | `#9E8538` |
| Plaster, shadowed | `#756652` | | Copper | `#80543B` |
| Whitewash | `#A69982` | | Boiler iron | `#544A45` |
| Floor planks | `#AD9985` | | Coal | `#38383D` |
| Timber | `#735E4C` | | Old paper | `#998F70` |
| Dark timber | `#45382E` | | Flighted poster paper | `#121729` |
| Flagstones | `#99A1A8` | | Rug | `#3D2B26` |
| Brick | `#A89994` | | Canvas | `#807861` |

### 3.5 Sky, sea and weather
| Element | Hex | Notes |
|---|---|---|
| Sky zenith | `#05080F` | Near black navy |
| Sky horizon | `#12171F` | |
| Cloud tops | `#6B6B66` early, `#0E0E10` in the full storm | |
| Cloud undersides | `#2C3A40` | |
| Fog | `#2C3A40` | Thickens as the storm builds |
| Sea trough | `#030913` | Deep navy-black |
| Sea body | `#05172B` | Dark blue |
| Wave face | `#0A3D4C` | Translucent teal, the main colour note of the sea |
| Thin crest | `#2B7580` | Pale cyan where the light comes through |
| Foam | `#B8C2C9` | Silver, in long wind streaks |
| Rain | `#B9BEC4` | Silver streaks |

### 3.6 Light colours
Only two families of light exist: **cold silver** (moon, lightning, electric arc) and **warm amber and gold** (fire, gas, oil, furnace). Nothing else glows.

| Source | Colour | Character |
|---|---|---|
| Supermoon | `#B9BEC4` | Huge, low in the north, cold; the steady light on the water |
| Lightning | `#B9BEC4` | Cloud-to-cloud, strobing 2 to 4 times; rocks drop to black silhouette |
| Beacon | `#B9BEC4` | Rotating beam: dark, then a failing flicker, then a steady sweep |
| Arc lamp | `#B9BEC4` | Harsh, crackling, with a dynamo-hum flicker |
| Furnace and boiler | `#C07A1E` | Slow pulse that rises when coal is fed |
| Windows | `#C07A1E` | Dim, warm, with a slight gas flicker |
| Boat lantern | `#B8962E` | Steady brass light that sways with the hull |
| Saint Calder | `#C07A1E` and `#B8962E` | A scatter of small window lights across the water; never brighter than the beacon |

### 3.7 How the palette moves through the game
| Phase | Feel | Dominant colours |
|---|---|---|
| **Island** (start) | Cold moonlit dusk; the storm gathering; light rain | Navy ambient, slate fog, grey cloud banks, a clear silver moon, warm amber windows |
| **Outbound** crossing | Darker and fuller; rain starting; the city's windows ahead | Slate and navy, with the moon flickering through wisps |
| **Return** crossing | The storm breaks; heavy driven rain; lightning | Near-black cloud and ambient, silver flashes, rocks as black shapes |
| **Beacon relit** | The storm holds; the beacon sweeps the cloud base | Navy ambient again, silver beam; the sea is readable |
| **Eclipse** (later) | A black sphere with a faint silver rim covers the moon; moonlight drops away | Ambient and fog fall almost to black; only amber and arc light remain |

### 3.8 Colour rules
- Muted and desaturated everywhere. The strongest saturation in any frame is amber light or the teal of a wave face.
- Keep values low overall. Dark scenes read through **silhouettes and light shapes**, not through midtone detail.
- Warm inside and cold outside. A window or doorway should always show that contrast.
- Hazards (rocks, wrecks) must read **darker than the sea**, even in a lightning flash.
- Never use bright saturated colours, neon, clean whites, pure black or pure grey.

---

## 4. Cel-shading settings (in engine)

These are the values the game runs with (Godot 4.3, `scripts/world/toon_look.gd`). Generated assets should be authored to suit them (see 4.3).

### 4.1 Shading
| Setting | Value | Meaning |
|---|---|---|
| Diffuse mode | Toon | A hard step between light and shadow |
| Specular mode | Off (toon materials) | No specular glints |
| `toon_roughness` | **0.22** | How sharp the light/dark step is; lower is crisper |
| `fill` (interior only) | **0.05** | Each surface gives off 5% of its own colour, so rooms never fall to dead black |
| `fill_tint` (interior only) | `#FFBD6B` (1.0, 0.74, 0.42) | Amber, so unlit corners stay warm instead of grey |
| Exterior surfaces | Toon, no fill, distance fog kept | Island, rock patches, harbour, stairs, gate, lighthouse walls |
| Wet rock (storm) | Albedo to 72%, roughness down to 0.35 | Driven by sea state |

### 4.2 Ink outline
| Setting | Value | Meaning |
|---|---|---|
| Colour | **`#0A0A0B` on screen** (sRGB 0.04, 0.04, 0.045) | Neutral charcoal. Not pure black, and **never navy or blue** |
| Thickness | **1.2 px at 1080p**, scaled with screen height | Thin. The old 1.8 px line was too heavy |
| Where it draws | Silhouettes, depth steps and sharp creases | Flat surfaces get no line |
| Fade | From 40 m out to 110 m | Distant detail does not turn to noise |
| Masked to | The lighthouse and the island (cut off at sea level, y 0.9) | The sea is not outlined by this pass |
| Sea | Its own cel shader: hard foam edges (`band_softness` 0.03), softer water bands (0.11), foam outlined in `#03050A` | |

### 4.3 Authoring assets for this shading
- **Paint colour and grime, not lighting.** The toon step adds the light and shadow. Do not bake strong highlights, ambient occlusion gradients or cast shadows into textures. Light AO in deep crevices and joints is fine.
- **Do not paint ink lines into 3D textures.** The engine draws the outline. Painted lines double up and shimmer. (2D art, UI and posters should keep their own hand-drawn linework.)
- **Give clear forms.** The outline shows silhouettes and creases, so chunky bevels, deep joints and strong overhangs read well. Fine surface noise does not.
- **Keep albedo mid-to-dark** and inside the palette ranges above. Very bright albedo blows out under the moon and the beacon; near-black albedo loses its shape in the storm.
- **Surfaces stay matte.** Metallic 0 for stone, wood and cloth. Keep metallic only for iron, brass and copper, and keep it dulled.
- **Nothing emits light** except the light sources in 3.6 (window glass, lamps, furnace mouth, lit city windows).

---

## 5. Generating assets

### 5.1 2D concept and reference images
- **For 3D conversion:** one object, centred, on a **flat neutral mid-grey background**, soft even light, no cast shadows on the ground, full silhouette in frame. Turnaround sheets (front, side, back, three-quarter) work best, matching the existing lighthouse, boat and character sheets.
- **For mood and scene art:** night or storm dusk, silver moon or lightning as key light, amber windows as accents, heavy rain, dark teal sea with silver foam. "Stormbound Abandoned Port Approach" in `channel_scenes/` is the benchmark for mood.
- **Characters:** T-pose turnaround on grey, as in `characters/`.

**Prompt template**
```
[subject], mid-1800s [setting/material details], gritty dark cel-shaded, heavy ink outlines,
flat cel shading with hard-edged shadow shapes, hand-traced rotoscope-style linework,
grimy hand-painted textures, muted desaturated palette of slate grey, sea slate, navy and stone,
[warm amber lamplight | cold silver moonlight], weathered, wet, salt-stained
```

**Negative prompt (always)**
```
modern clothing, cars, plastic, neon, smartphones, modern electrical fixtures, bright saturated colours,
smooth photoreal rendering, clean glossy surfaces, anime style, text artefacts, real artist names,
franchise characters
```
Add `navy clothing` to the negative prompt for any character who is not Ted.

### 5.2 3D models
- Image-to-3D with FAL Hunyuan3D v3 (textured) from the grey-background reference.
- v3 ships a 4096 texture. **Downscale it to 2048** with `python -I LightingTheStorm/tools/downscale_glb_texture.py <model.glb>`. The 4K original stays in the asset's `source/` folder (which is kept out of git).
- Every new `.glb` needs a `.glb.import` with `import_script/path="res://tools/import_scale_pivot.gd"`; copy one from a neighbouring model.
- Check that metallic is 0 on non-metal surfaces (v3 sets 0; older v2 models defaulted to 1).
- Keep the FAL spending cap in mind and dry-run before submitting.

### 5.3 UI, posters and documents
- UI (suggested, not locked): crude printed paper, stencilled lettering, storm-stained edges.
- Posters: crude letterpress, heavy serif or slab type, slightly misregistered ink.
- Flighted material: black, silver and navy only, with the eclipsed-moon icon.
- Saint Calder material: amber and gold seals and banners.

---

## 6. Quick checklist for every new asset
- [ ] Fits the 1800s gaslight-and-steam era; nothing modern
- [ ] Worn, wet, grimy, matte
- [ ] Colours from the palette; muted; reserved colours (navy, the Flighted trio, amber with gold, Arthur's green, Daniel's red) used only where they belong
- [ ] Reads as a clear silhouette against a dark sea and sky
- [ ] Texture has no baked lighting and no painted outlines (3D)
- [ ] Only the light sources in 3.6 glow
- [ ] Texture 2048, import script set, metallic correct (3D)
- [ ] Raises a question rather than answering one
