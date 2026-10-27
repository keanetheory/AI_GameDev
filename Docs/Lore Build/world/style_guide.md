---
id: style_guide
type: style_guide
art_style: gritty dark cel-shaded
global_palette: ["#0E0E10", "#1F2A44", "#2C3A40", "#6B6B66", "#B9BEC4", "#C07A1E", "#B8962E"]
status: locked
---

# Style Guide

## Global Art Direction
- **Style descriptors (use these in prompts):**
  - gritty dark cel-shaded
  - heavy ink outlines
  - flat cel shading with hard-edged shadow shapes
  - hand-traced, rotoscope-style linework
  - grimy hand-painted textures
  - muted, desaturated palette
- **Era:** mid-to-late 1800s gaslight and steam, with mid-1800s stone and brick buildings.
- **Mood:** dark, grim, eerie, with more questions than answers.
- **Lighting:**
  - Electric arc light and steam-driven light are the only strong sources during eclipse.
  - Moonlight is absent or eclipsed.
  - Storm lighting is cold, wet, and high-contrast.
- **Reference touchstones** (A Scanner Darkly, Borderlands) are for human reference only. Never name them in prompts.

## In-Engine Cel Look (Godot)
How the game draws the cel-shaded look at run time. Agents building or checking anything in the level follow these values; the prompt descriptors above are for generated art only. Set by the creator on 2026-10-27, first on the lighthouse (`LightingTheStorm/scripts/world/toon_look.gd`, `toon_outline.gdshader`).
- **Outline (ink) colour:** neutral near-black charcoal, about #0C0C0C on screen (ToonLook `ink_colour` 0.04, 0.04, 0.045 in sRGB). Never pure black, and never navy or blue: navy is reserved for the Flighted and Ted.
- **Outline weight:** thin, 1.2 px at 1080p (ToonLook `ink_thickness`), scaled with screen height. Not the heavy 1.8 px line used before 27 Oct 2026.
- **Where the outline is drawn:** silhouettes, depth steps and sharp creases only; flat surfaces carry no line. It fades out between 40 m and 110 m so distant detail does not turn to noise.
- **Shading:** toon diffuse with a hard light/dark step (ToonLook `toon_roughness` 0.22) and a small amber fill (`fill_tint`) so unlit interior walls keep the warm palette instead of falling to grey.
- **Interior surfaces:** warm, muted materials (lime plaster cream, dark timber, worn stone); no neutral greys.

## Colour Meanings
| Colour | Hex | Meaning |
|---|---|---|
| Amber | #C07A1E | Saint Calder's royal standard (paired with gold) |
| Gold | #B8962E | Saint Calder's royal standard (paired with amber) |
| Black | #0E0E10 | The Flighted |
| Silver | #B9BEC4 | The Flighted (the moon) |
| Navy | #1F2A44 | The Flighted. Also Ted's colour: **a deliberate clue linking him to the Flighted**. Keep it consistent. |
| Green | #2F4A34 | Arthur |
| Red | #7A2620 | Daniel |
| Stone grey | #6B6B66 | Bracken Isle, the lighthouse |
| Sea slate | #2C3A40 | The Gullwater |

## Culture Quick Reference
| Culture | Palette | Shapes | Materials | Silhouette keywords |
|---|---|---|---|---|
| Coastfolk | Personal colour plus black boots | Bulky, rounded, weather-hunched | Oilskin, heavy wool, oily leather | Oilskin coat, thick jumper, heavy boots |
| Garrisons | TBD | Tall, rigid | Chain mail, steel | Nose-guard helmet, mail shoulders |
| Saint Calder elite | TBD (amber and gold accents likely) | TBD | TBD | TBD |
| The Flighted (iconography only) | Black, silver, navy | Circles, spheres, wave lines | Printed paper, crude ink | A dark sphere over the moon |

## UI Direction
TBD. Suggested: crude printed paper, stencilled lettering, and storm-stained edges, echoing the propaganda posters.

## Typography & Iconography
- **Posters:** crude letterpress, heavy serif or slab type, slightly misregistered ink.
- **Recurring icon:** a dark sphere eclipsing a silver moon above waves.

## Audio Direction
- **Lighthouse:** whispering, random bangs inside the walls, the hiss and thump of the steam engine, the dynamo's whine, the arc lamp's crackle.
- **Crossing:** quiet chugging of the steam launch outbound, then wind, rain, and a roaring storm on the return.

## Global Negative Prompts
modern clothing, cars, plastic, neon, smartphones, modern electrical fixtures, bright saturated colours, smooth photoreal rendering, clean glossy surfaces, anime style, text artefacts, real artist names, franchise characters
