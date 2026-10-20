# things to work on next

> **Updated 2026-10-20.** Items 1 and 3 below described the old way the cliff walkway was made (cutting triangles out of the cliff
> at load time). That is gone: the walkway is now a ledge built against the uncut cliff from a baked profile, so there are no
> jagged teeth and the carving cost is gone (the cliffside takes about 2.5 s). See `GERFramework/reports/cliffside_recommendations.md`.
> Item 2 (dark walkway) still applies, and belongs to the Lighting agent now. Items 4 and 5 are unchanged.


Known rough edges in the level, with where they come from and what would fix them.

## 1. Jagged teeth along the base of the cliff walkway's rock wall

**What you see:** a band of jagged grey slivers sticks up along the bottom of the rock wall on the cliff walkway, where the wall meets the floor.

**Why:** `scripts/world/mainland.gd` cuts the walkway out of the cliff meshes by removing whole triangles whose centre falls inside the cut volume, and the wall is a copy of the removed cliff faces set back from the edge. The cliff's triangles are large and uneven, so triangles that straddle the floor line are either kept (poking up into the walkway) or copied (leaving a ragged bottom edge on the wall).

**Ideas:**
- Clip the triangles properly at the floor plane instead of keeping or dropping whole triangles.
- Or hide the junction with a rubble or stone skirt strip along the foot of the wall.
- Or push the wall copy's bottom vertices down below the floor so the edge is buried.

## 2. The walkway is very dark

**What you see:** at the game's own lighting the ledge, its floor and the rock wall read almost black. (My review screenshots used an extra fill light, so they looked brighter than the game really is.)

**Why:** the level's sun, ambient light and fog are dim and cold by design. The walkway floor and walls are vertex-coloured and fairly dark to start with, and the cut sits in the shadow of the cliff above it.

**Ideas:**
- Lighten the floor colour and the vertex tones in `_build_gallery()` in `mainland.gd`.
- Add a few warm lanterns or lamp posts along the ledge. The Lighting agent's spec in `AIAgentCrew/world_output/lighting_spec.json` should say what light sources fit the setting.
- Check it against the final lighting pass before changing the colours much.

## 3. Level load time

**What you see:** the level takes noticeably longer to load than before the mainland work. In headless runs it went from about 7 s to about 10 s, and it is probably worse on a slower machine. It happens every time the scene loads, including in the editor.

**Why:** `mainland.gd` does a lot of work in `_ready()`:
- It measures the real cliff-top heights by walking every face of the cliff meshes (`_measure_tops()`).
- It carves the walkway out of three large cliff meshes and builds a copy of the removed rock (`_carve_mesh()`), roughly 22,000 triangles.
- It builds concave (exact) collision for the carved cliffs, the rock wall copy, the walkway floor and the plateau terrain.
- It generates the terrain, roads and about 2,600 trees from code.
- The island also carves its old dock out of the mesh on every load (`collider_builder.gd`).

**Ideas:**
- Bake the result: save the carved cliff meshes and the cliff-top height table into the project, so nothing is measured or cut at load time.
- Keep the code builders for the editor only, and load the baked meshes in the game.
- Build the collision offline too (for example as `.res` shapes).
- Cut the triangle counts of the cliff pieces and the generated models before baking, which also reduces collision cost.

## 4. Re-record the dialogue lines the story beats changed

**What you see:** six lines already have ElevenLabs audio in `AIAgentCrew/voice_output_picked_live/elevenlabs/lines/` that no longer matches their text: TED_S1_01, TED_S1_09, TED_S1_10, TED_S1_11, TED_S3_02 and ARTHUR_S3_04. The new TED_S3_00 has no audio at all. The game does not play line audio yet, so nothing breaks today.

**Why:** the 2026-10-16 story-beat revision (`AIAgentCrew/story_beats.py`) rewrote those lines and added TED_S3_00 so the opening follows the canon order.

**Ideas:**
- First get the seven lines through a Dialogue agent and Canon review (see item 5).
- Then regenerate them with `python main_elevenlabs.py tts --casting voice_output_picked_live --lines TED_S1_01 TED_S1_09 TED_S1_10 TED_S1_11 TED_S3_02 ARTHUR_S3_04 TED_S3_00` (dry run first; add `--send` to spend credits).

## 5. Review the rewritten opening lines

**What you see:** TED_S1_01 (the door greeting), TED_S1_09, TED_S1_10, TED_S1_11, TED_S3_02, ARTHUR_S3_04 and the new TED_S3_00 were written for the story beats and have only passed the deterministic checks.

**Why:** they need a Dialogue agent and Canon re-review, and the creator's sign-off on voice and lore, before recording.

**Ideas:**
- Run the dialogue crew live over them, or walk them through like the 2026-10-15 creator picks.
- Record the outcome in `Docs/Lore Build/dialogue/DIALOGUE_OPENING_CREATOR_PICKS.md`.

## 6. Confirm the GDD's week 5 fallback wording

**What you see:** the risk plan in the GDD now reads "simplifying the lantern-room diagnosis and burner fit" (it was "dropping the second repair", which no longer exists).

**Why:** the wording was written during the story-beat clean-up, not by the creator.

**Ideas:** confirm or rewrite it in `Docs/GDD/Final_GDD_Post_Review/Technical Strategy.md` and `AI Agent Strategy.md`.

## 7. Wire the story events into the level

**What you see:** most of the opening dialogue does not play in a normal playthrough. The `GameState` and `Dialogue` autoloads exist (`scripts/core/game_state.gd`, `scripts/dialogue/dialogue_loader.gd`) and already report GAME_STARTED (Ted's door greeting), BOAT_CAST_OFF, SALTGATE_REACHED, RETURN_DEPARTED (needs BURNER_PICKED_UP first; F11 fires it for testing) and RETURN_ARRIVED. The level has no lighthouse door, no island gate and no lantern-room trigger, so nothing yet reports LIGHTHOUSE_ENTERED, BOILER_FED, SAILORS_MOORED, GATE_OPENED, DANIEL_IN_BASEMENT, BEACON_STILL_DARK, LAMP_ROOM_ENTERED, BURNER_DIAGNOSED, BURNER_BRIEFING, BOARDING_THRESHOLD, BURNER_PICKED_UP or the IDLE_* nudges.

**Why:** the level work so far has been terrain, the dock, the stairs and lighting. The event bus is in place (see `HANDOFF_T01_GameState.md`); what is missing is the scenery that fires the events.

**Ideas:**
- Start the player outside the lighthouse door, with Ted there (beat 1).
- Add trigger areas for the lighthouse door, the basement, the island gate on the path from the dock and the lantern room, plus the boiler and burner interactions, each calling `GameState.emit_event("EVENT_ID")` (never `Dialogue.trigger()` or the phase directly).
- Add the beacon-relit trigger for the lighting rig's BEACON_RELIT phase (beat 7), which has none yet.

## 6. Lighthouse interior rough edges (added 2026-10-20)

The interior is now furnished (see `GERFramework/reports/handoff_lighthouse_interior.md`). Still rough:

- **Everything is procedural greybox**: textures are generated noise, props are boxes and cylinders, posters are paper and text. The Asset agent can replace them one prop at a time; the kit is `scripts/world/interior/kit.gd`.
- **The first floor and the lamp room are lit by placeholder lamps.** The Lighting agent owns the mood and the beacon's final look; `lamp_beacon.gd` exports every number.
- **The foundation chamber under the tower is not built** (needs a carve in the island collider; no story use).
- **The shovel's pose in the hands** and the **burner's pose in the lamp socket** were set by eye; check both in the editor (`coal_job.gd` `held_*`, `lantern.gd` `mount_rotation_deg`).
- **L2 is a landing ring, not a house floor**: the house roof leaves no headroom above y 6.9.
