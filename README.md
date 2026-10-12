# AI_GameDev

## Generated Artifact #1: Intro Splash Screen

![Lighting the Storm intro splash screen](LightingTheStorm/INTRO_SPLASH_SCREEN.png)

**File:** `LightingTheStorm/INTRO_SPLASH_SCREEN.png` (1920x1080)
**Generator:** `LightingTheStorm/tools/build_intro_splash.py` (Python + Pillow, re-run it to regenerate the image)

### What was provided

Claude read the GDD and the Lore Build (`Docs/Lore Build/world/WORLD.md`, `style_guide.md`, `pillars.md`, `systems/sys_eclipse.md`, `factions/fac_flighted.md`) and produced a title screen for *Lighting the Storm* straight from the lore:

- **Setting:** the Bracken Isle lighthouse in a mid-1800s gaslight-and-steam storm. It is unlit, its lens is cracked ("Tonight the beacon has failed"), and a silhouetted figure stands in a dim window (pillar 1, the haunted lighthouse).
- **The eclipse:** a near-perfect black sphere sits over a silver moon with a thin silver rim all round. There is only a faint tilted seam and a barely-there keel point to hint it may be a ship (pillar 2, the mystery of the moon).
- **The storm:** layered cel-shaded storm clouds, a lightning strike, driving rain, a rough sea and a steam liner pitching toward the isle with one dim amber lamp.
- **Style and palette:** built from the style guide's palette (ink black, navy, sea slate, stone grey, silver, amber), with wobbly hand-traced ink outlines, hard-edged cel shadows and grimy paint texture.
- **Title treatment:** "LIGHTING THE STORM" in a weathered, misregistered slab-serif letterpress style, with the tagline "Tonight the beacon has failed." and a small "PRESS ANY KEY" at bottom right.

### How it was made: chat history

**1. First request**

> based on the GDD and Lore build folders, generate an intro screen with the game title in a suitable vibe, and save it to the "LightingTheStorm" root folder as INTRO_SPLASH_SCREEN.png

Claude drew a first version: lighthouse, eclipse and a stormy sea.

**2. Reset to the lore**

> reset that image according to the lore - this is a world set in the mid 1800s and is gritty with supernatural / alien overtones. Make the darkshape covering the moon more like a space ship of sorts (only show minor hints that it may be a space ship) and don't forget to show the storm

Claude added a steam-liner ship, heavy storm clouds, lightning, rain and grit, and gave the dark shape some ship-like details.

**3. Challenge: put it through the agent crew**

> run this image through the appropriate member of the agent crew and list their suggestions

The crew in `Agent Crew/roles.py` has no art director, so Claude used the **Asset agent** (palette, style and reference-sheet fit), with the Lighting agent and Canon and Review Orchestrator checks added. The review ran as a subagent playing that role; the real CrewAI pipeline was not run, because it is built for return-crossing data, not image review. Its suggestions:

1. Eclipse sphere is too explicit as a ship (mast, keel spike, portholes, rivets). Keep one faint seam or keel point.
2. The eclipse sits beside the moon, not over it. Centre it on a full silver disc with a thin rim all round.
3. Stray amber glows read as a second light source. Remove them.
4. The sky behind the eclipse is too bright and moonlit. Darken it toward navy and ink.
5. The beacon reads as lit, which undercuts "the beacon has failed".
6. No strong story light. Add hard-edged cel shadow and a cold lightning rim light.
7. Rendering is clean vector, not heavy ink outlines, hand-traced linework or grimy hand-painted texture.
8. The ship is tiny with toy-like yellow lights. Make it a clearer steam silhouette with smoke and one dim amber lamp.
9. The foreground pebbles look like cartoon ovals.
10. Title fill is too clean and bright. Grime it toward silver.
11. Tagline and "PRESS ANY KEY" are low contrast.
12. Pillar 1 (haunted lighthouse) is not hinted. Add a silhouetted shape at a dark window.

**4. Decisions**

> Agreed with 1. Agreed with 2. Agreed with 3. Agreed with 4 (make it stormy clouds) Agreed with 5, turn off the light of the lighthouse and crack the lens. Agreed with 6. Agreed with 7. Agreed with 8. Remove the pebbles. Agreed with 10. Move the "press any key" to bottom right of the screen and make it smaller. Agreed with 12.

Claude applied every accepted change and produced the final image above.
