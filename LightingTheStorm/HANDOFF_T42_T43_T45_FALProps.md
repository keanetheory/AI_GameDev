# HANDOFF - T42, T43, T45: the FAL prop batch (lighthouse props, buoys, Daniel's chair)

## 1. Task and goal

- T45 (score 8, Asset agent): "List the greyboxed lighthouse props and plan their FAL replacements". Creator, 30 Oct 2026: "we need to list out the remaining props in the lighthouse that have been greyboxed so we can generate FAL replacements for them".
- T42 (score 6, creator with the Asset agent): "Generate the buoy models for the sea hazards". Creator, 30 Oct 2026: "additional backlog item is to generate assets for the buoys in the sea".
- T43 (score 6, creator with the Asset agent): "Generate a chair for Daniel in front of the boiler". Creator, 30 Oct 2026: "it's better for us to generate a chair for him to sit on in front of the boiler".

None lists a requirement id. Commits: dd0a8cb (the list), fca8f2e (27 models generated, 1 Nov), 6e6dc6f (placed), 5ce4ed5 (two stale tests fixed). The Saltgate hut came from the same batch; its placement is in `HANDOFF_T48_T49_Bathroom_SaltgateHut.md`. Note written 2 Nov 2026 to close R21.

## 2. Files changed

- `LIGHTHOUSE_GREYBOX_PROPS.md` (new): 1,290 interior meshes dumped, 916 primitives (mostly architecture that stays); 30 proposed models in three priorities, nine free reuses, costs against the cap, the import process, two creator questions.
- `AIAgentCrew/sample_submissions/lighthouse_props_t45/*.fal.json` (27): one submission per model, each passing `main_asset.py --check-only`.
- `Assets/Models/prop/`: 27 new `.glb` with `.fal_result.json`, `.import` and a 1024 texture (`*_texture_20250901.jpg`; the hut keeps 2048). Re-decimated in Blender (weld, collapse) to 1.5k-3.5k triangles. Originals (`*_4k_texture.glb`, `*_full2k.glb`) are in `Assets/Models/prop/source/` (git-ignored).
- `GERFramework/reports/lighthouse_finisher_fal_ledger.json`: 29 entries, batch "T45 + backlog props, 1 Nov 2026"; cap raised to $19.425.
- `scripts/world/interior/hero_props.gd`: in-place mode (`IN_PLACE`, `LAMPS`, `build_in_place`): each model fitted into the greybox bounds it replaces, back to the measured wall (30 props); 16 sconces and pendants fitted round each lamp's glowing glass. The greybox is hidden and keeps its collision.
- `scripts/world/interior_rooms.gd`: calls `build_in_place`.
- `scripts/world/crossing_hazards.gd`, `data/world/crossing_sequence.json` (`hazards.buoy.models`): red channel buoy and bell buoy take turns by hazard id, sized to the 1 m collision radius, sunk 0.45 m, red lamp in the cage or on the frame; the primitive buoy stays as the fallback.
- `scripts/world/sailors_sequence.gd`, `data/world/sailors_sequence.json` (`daniel_chair`, `daniel_chair_path`, `daniel_sits_in_basement` true), `scripts/character/npc.gd` (`sit(..., bench := true)`): Daniel walks out of the coal bin, round the lobby barrel and sits on the chair with no plank.
- Tests: `test_sailors_sequence.gd`, `test_interior_culling.gd` (thresholds 100 to 50), `test_hero_props.gd` (counts the in-place props and lamps; new 600k limit for everything placed), `test_title_settings.gd` (GAME_STARTED fires at the knock, not at load).

## 3. How to run and test

From `LightingTheStorm/` (creator's binary: `C:\Users\pmkea\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe`):

```
godot --headless --path . --script res://tools/test_hero_props.gd
godot --headless --path . --script res://tools/test_interior_budget.gd
godot --headless --path . --script res://tools/audit_lighthouse.gd -- check
godot --headless --path . --script res://tools/test_crossing_sequence.gd
godot --headless --path . --script res://tools/test_sailors_sequence.gd
godot --headless --path . --script res://tools/test_interior_culling.gd
godot --headless --path . --script res://tools/test_title_settings.gd
```

A new prop follows the five steps at the end of `LIGHTHOUSE_GREYBOX_PROPS.md` (check-only, dry run, `--go`, ledger entry, import, decimate, `hero_props.gd` entry, audit).

## 4. Observed behaviour

Run by me on 2 Nov 2026 (Godot 4.3.stable, at eba7a35):
- `test_hero_props.gd`: ALL PASSED. 68 of 68 placed, 279 greybox nodes hidden; furniture 385,958 triangles (limit 450k), everything placed 548,404 (limit 600k), largest model 24,034 (limit 40k).
- `audit_lighthouse.gd -- check`: ALL PASSED, exit 0. Triangles 884,145 of 900,000; surfaces 1,323 of 1,600; nodes 2,949 of 3,200; **materials 120 of 120, exactly at the limit**.
- `test_interior_budget.gd`, `test_sailors_sequence.gd` (43 PASS; "Daniel's chair stands in the basement", "he walks to the chair and sits on it (3.5 s)"), `test_crossing_sequence.gd` (40 PASS; 4 buoys placed, "the bells ring from the two buoys"), `test_interior_culling.gd`: all OK.
- `test_title_settings.gd`: `RESULT: OK (0 failed)`, but the process exited with code 139 (a crash during shutdown, after the RESULT line, with leaked-RID messages). A runner that checks the exit code would count it as failed.
- Ledger: 29 charges of $0.375 = $10.875 on 1 Nov (27 models plus re-rolls of `lhi_boot_bench` and `lhi_radio_desk`), all `ok`. `Game Audit/FAL_SPEND.md` matches it to the FAL dashboard.

## 5. Not verified

- No test checks that a buoy is the FAL model rather than the fallback cylinder, or that the lamp sits in the cage. The backlog notes `blink_s` is set but nothing blinks the buoy lamp yet.
- The 30 in-place props and 16 lamps have not been looked at room by room in play by me: fit against walls, scale, orientation (the office chart table was turned on 1 Nov, 3c34872), and whether the Blender collapse to 1.5k-3.5k triangles looks too crude up close.
- Daniel's seated pose against the chair (clipping) is checked only in a render noted in the backlog.
- **Backup gap:** the 27 originals of 1 Nov are only in the git-ignored `source/` folder. `C:\bkupConceptArt\FAL_3D_Models\prop\` holds none of them (it stops at the October props).

## 6. Licences and provenance

All 27 are FAL Hunyuan3D v3 text-to-3D (`fal-ai/hunyuan3d-v3/text-to-3d`) generations, made with the creator's FAL API key and paid from the creator's account. The prompt, request id and FAL URL are recorded in each `*.fal_result.json`. The repo records **no licence or terms** for these outputs: there is no `SOURCES.md` in `Assets/Models/prop/`, and `Assets/Characters/SOURCES.md` says only "confirm both services' commercial terms before release" for the FAL character meshes. No third-party models or textures were used.

## 7. Interface or contract changes proposed

PROPOSED (internal data fields, not events): `hazards.buoy.models` in `crossing_sequence.json`; `daniel_chair` and `daniel_chair_path` in `sailors_sequence.json`; the `bench` parameter on `npc.sit()`. No event IDs or phases changed.

## 8. Open creator decisions

- Confirm FAL's commercial terms for Hunyuan3D outputs and where the credits list lives (T53, Game Audit).
- `lhi_buoy_green` is generated but unused (a green buoy contradicts the forecast's "red buoy light"): use it to mark the safe lane, or leave it out?
- Priority 3 (eight small dressing models, $3.00) and the nine free reuses: go ahead, or leave as greybox for Gate 1?
- The material count is at its 120 limit: raise the limit or merge materials before the next prop goes in?
- Back up the 1 Nov originals to `C:\bkupConceptArt\FAL_3D_Models\prop\`?
