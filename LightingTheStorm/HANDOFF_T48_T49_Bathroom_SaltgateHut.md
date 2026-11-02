# HANDOFF - T48, T49: the first-floor bathroom, and the Saltgate walk-in hut

## 1. Task and goal

- T48 (score 7, Lighthouse Interior Creator with the creator): "Rebuild the L2 room: remove the stick in the bathroom and replace its props with FAL models". Creator, 30 Oct 2026: "the bathroom in the L2 has a random stick cutting through it and we need to generate FAL replacements for all of the props in that level". The creator confirmed on 1 Nov 2026 that "L2 bathroom" means the first-floor bathroom (code L1). Its props were already replaced in T45.
- T49 (score 7, Saltgate Creator with the creator): "Regenerate the Saltgate burner pickup area and replace the landing with a walk-in hut". Creator, 30 Oct 2026: "replace the landing with a hut that looks like a garage or equipment area that the player can walk into". Keep the pickup, carry and return invariants, the dark and eerie Saltgate, and a short walk.

Neither lists a requirement id. Commits, all 1 Nov 2026: 3c34872 (hut on the pier head; bathroom), 19c5aa7 (hut moved to dock level), 049c3e1 (back on the stone, the creator's call), 8d6c21d (steps simplified), f748681 (low-poly collision). Note written 2 Nov 2026 to close R21.

## 2. Files changed

T48 (3c34872):
- `scripts/world/interior/hero_props.gd`: `HIDE_ONLY` hides `L1_TowelRail` and `L1_Towel` (the "stick" across the wash-room doorway); the FAL washstand has its own towel bar. The office chart table turned to match its greybox.
- `scripts/world/interior_culling.gd`: skips meshes already hidden. It used to re-show every greybox piece when a level was shown again, so the box bath sat under the FAL tub and old boxes came back inside every generated prop after a floor change.
- `scripts/world/room_light_cards.gd`: a light pool looks past furniture tops (another surface within 1.2 m below) to the floor; the wash-room window pool had lain on the bath.
- `tools/test_interior_culling.gd`: checks replaced greybox stays hidden after culling.

T49 (final state after 049c3e1, 8d6c21d, f748681):
- `scripts/world/saltgate_hut.gd` (new): the FAL `slt_equipment_hut.glb` on the stone pier head, warm lamp, rain shelter volume, collision from `slt_equipment_hut_col.glb` (a welded, collapsed copy laid over the model by bounds) instead of the 37k-triangle model.
- `Assets/Models/prop/slt_equipment_hut_col.glb` (new).
- `scenes/Level.tscn`: `SaltgateHut` node and `SaltgateHutSteps` (a `stone_stairs.gd` flight from the quay at 3.1 m to the pier head at 4.4 m; no parapets, top flush, after 8d6c21d). The burner on the hut's workbench; DOCK_PORT's landing on the quay's south strip.
- `scripts/world/boat.gd`: the cargo slot removed (the burner stays in the hands from the hut to the lamp). `carry_socket.gd`, `carry_manager.gd`, `burner_pickup.gd`: comments to match. `toon_look.gd`: the steps are toon shaded.
- 19c5aa7's dock-level carve, piles, plank deck and baked quay collider were added and then removed again by 049c3e1.
- Tests: `test_disembark.gd` (landing, steps, hut and back), `test_carry.gd` (nowhere to put the burner down), `test_burner_pickup.gd`.

## 3. How to run and test

From `LightingTheStorm/` (creator's binary: `C:\Users\pmkea\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe`):

```
godot --headless --path . --script res://tools/test_interior_culling.gd
godot --headless --path . --script res://tools/test_room_lights.gd
godot --headless --path . --script res://tools/test_disembark.gd
godot --headless --path . --script res://tools/test_burner_pickup.gd
godot --headless --path . --script res://tools/test_carry.gd
godot --headless --path . --script res://tools/test_rain_shelter.gd
```

## 4. Observed behaviour

Run by me on 2 Nov 2026 (Godot 4.3.stable, at eba7a35):
- `test_interior_culling.gd`: ALL PASSED, including "replaced greybox stays hidden after the levels are culled and shown again []".
- `test_room_lights.gd`, `test_rain_shelter.gd`: ALL PASSED.
- `test_disembark.gd`: `RESULT: OK`. Up the steps to the hut (largest step 0.16 m), "[E] Pick up the burner" offered, BURNER_PICKED_UP, back down to the landing (no drop off an edge), back within the launch's board radius.
- `test_burner_pickup.gd` (15 PASS): the burner is 4.9 m from the landing; the boat leaves E to the burner; casting off with it fires RETURN_DEPARTED.
- `test_carry.gd` (17 PASS): "the boat has no cargo slot", nothing offers to take the burner on deck.
- `test_slice_playthrough.gd` and `-- fail`: OK.
- The 60-190 ms physics stalls inside the hut and the drop to two frames of 32-36 ms are from the f748681 commit message; I did not re-measure. That message says the collision copy is 4.5k triangles; the code comment says about 2.5k.

## 5. Not verified

- The hut and steps in play: whether the walk-in hut reads as a garage or equipment store, is dark and eerie enough, and whether the steps look right without parapets. The backlog summary still describes parapets and a top landing over the kerb; 8d6c21d removed them.
- Whether walking in the hut now feels smooth on the creator's machine.
- The first-floor bathroom by eye after a few floor changes (the culling fix is tested by node visibility only).
- T48's wider "rebuild the L2 room" scope: only the stick, the culling and the light pool were fixed; no new L2 props beyond T45.

## 6. Licences and provenance

`slt_equipment_hut.glb`: FAL Hunyuan3D v3 text-to-3D, generated with the creator's FAL account on 1 Nov 2026 (`slt_equipment_hut.fal_result.json`, ledger entry, $0.375). The repo records no licence or terms for FAL outputs (see `HANDOFF_T42_T43_T45_FALProps.md`, section 6). `slt_equipment_hut_col.glb` is derived from it in Blender.

## 7. Interface or contract changes proposed

PROPOSED: the boat's cargo slot is gone, so the only `CarrySocket` is the lamp socket. Any task that assumed the burner can be set down on the boat (QA_SCENARIOS S13 still says "can only be put in the boat's slot or the lamp socket") needs updating. No event IDs changed; DOCK_PORT keeps its id with a moved landing point.

## 8. Open creator decisions

- Is the hut on the stone "good for now" as a set piece (creator, 1 Nov: keep it simple), or does the burner area need more?
- Should `QA_SCENARIOS.md` S13 and the T49 backlog text be corrected (cargo slot, parapets)?
