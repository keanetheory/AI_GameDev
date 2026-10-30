# HANDOFF - T36: lampposts on the docks

## 1. Task and goal

Creator, 31 Oct 2026: load the lamppost model and place two on the island dock, one either side of the opening, and one at the Saltgate dock where the boat docks. Serves R19 (warm lamplight against the blue-grey storm light) and the readability of the docks.

## 2. Files changed

New:
- `Assets/Models/lamppost/lamppost.glb` (+ `.import` and the three extracted textures): the Meshy "Vintage Gas Street Lamp" model, decimated from 459,022 to 30,000 triangles with Blender (`tools/decimate_glb.py`), textures downscaled from 2048 to 1024 (`tools/downscale_glb_texture.py`), imported through `tools/import_scale_pivot.gd` (new category `lamppost`, 3.4 m tall, pivot at the base centre). The full-detail original and the 2048 version are in `Assets/Models/lamppost/source/` (git-ignored, as for every generated original) and the original is backed up to `C:\bkupConceptArt\FAL_3D_Models\lamppost\`.
- `scripts/world/lampposts.gd` (one node, `Lampposts`, in `Level.tscn`), `data/world/lampposts.json`, `tools/test_lampposts.gd` (15 checks), `tools/probe_lamp_spots.gd`, `tools/probe_lamppost.gd`.

Edited: `scenes/Level.tscn` (one `Lampposts` node), `scripts/world/toon_look.gd` (the lampposts get the cel look and ink with the dock), `tools/import_scale_pivot.gd` (the `lamppost` height), `readme.md`.

Removed: the raw 21 MB Meshy file that had been committed in `Assets/Models/lamp/` (now in `source/`; it remains in git history).

## 2b. Model swap (creator, 30 Oct 2026)

The gas lamp was replaced by the Meshy "Verdigris Lantern" (same folder, same pipeline: 454k to 30k triangles, 1024 textures, 3.4 m, pivot at the base). Positions and yaws are unchanged. The OmniLight and the glowing head now sit at 2.96 m, the centre of the lantern glass (`light_height_m` in `data/world/lampposts.json`), and the test checks the light is on the lantern axis at that height. The old model and originals are in `Assets/Models/lamppost/source/`.

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_lampposts.gd
```

Where they stand: `Lamppost_IslandDock_North` and `_South` at the outer edge of each jetty near its tip, (-33.5, 14.0) and (-33.5, 27.0), 13 m apart and centred on the opening between the jetties (middle z 20.5); `Lamppost_Saltgate_Dock` at (3.4, 3.1, 537.0), 2.4 m from the landing and beside the berth where the launch docks. Each has a solid collider, an emissive lamp head that stays lit and fog-proof (so it shows from the sea), and a warm OmniLight (energy 2.6, range 16 m) that flickers like gas and is on only while the player is within 170 m. Everything is in `data/world/lampposts.json`.

## 4. Observed behaviour

`test_lampposts.gd`: OK. Three posts placed; the island pair stand on the jetty decks, level with each other, centred on the opening and outboard of the berths; the Saltgate post stands on the quay by the landing and the berth; the model is 3.4 m tall on its base; a sphere probe finds the collider; the lights follow the player (island lamps near the island, the Saltgate light off, and the other way round); the heads stay lit; the light flickers. The toon, island-walk, disembark, burner-pickup, NPC, sailors and other tests still pass (see the commit). A rendered still from the harbour mouth shows the two lamps either side of the opening with their ink outline and glowing heads.

## 5. Not verified

- **Light budget.** `Level.tscn` holds the interior's 15 OmniLights; the three lamp lights make 18, which is now the limit (`max_dynamic_lights` 18, creator, 31 Oct 2026). At most a few are live at once, because the lamps are gated by the player's distance.
- Not played: how bright the docks read at night and whether the lamp glow is enough (it is an OmniLight and an emissive head, no halo or rain-streak effect).
- The lamps are the model as generated: glass is part of the mesh (not see-through), no animation.
- The post colliders block the player on the jetty tips only slightly (28 cm radius); the boat does not collide with them (they are on the world layer, not the hazard layer).

## 6. Licences and provenance

The model is Meshy AI's "Vintage Gas Street Lamp", licensed **CC BY 4.0** (confirmed by the creator, 31 Oct 2026). CC BY requires attribution: the game's credits must name Meshy AI and the model title (recorded in `Assets/Models/lamppost/SOURCES.md`). Source and backup locations are above.

## 7. Interface or contract changes proposed

None.

## 8. Open creator decisions

- Resolved 31 Oct 2026: `max_dynamic_lights` is now 18 in `data/world/lighting_spec.json` (the interior's 15 plus the three lamps); the AI Crew schema allows up to 24 and its offline lighting spec says 18.
- More lamps (the Saltgate has only the one by the landing; the island has none up the stairs)?
