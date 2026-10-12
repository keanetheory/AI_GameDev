# Lighting the Storm — What’s Changed (Concise)

Post-review amendments, 1 October 2026, compared with the 25 September 2026 originals. The originals are unchanged. See “What’s Changed.md” for the full detail.

---

## Exec Summary

### Player Experience changes
- No crash. Jeff and Daniel, overwhelmed by the storm, moor on the island seeking shelter. Ted sees them from the window and the player opens the island gate. Daniel goes to the basement; Jeff wants to stop the ship being wrecked and tells the player to go on after the second crossing.
- Storm split. What the player perceives follows elapsed time; what they collide with follows phase and route position.
- Discoveries. Core folk-horror discoveries move to the lighthouse and island. The outpost stays minimal until the prototype is complete.
- Ted is staged at the lamp (voice and position only), with presence locked by the end of week 3. Gate 1 has two repairs. The apprentice never speaks.

### Timings and Fail-State Changes
- Deadline starts on the return crossing, when the player has the burner aboard and sets off for the lighthouse. There is no fail state before then, so the outbound crossing is steering practice. Ted introduces the ship at the boarding threshold.
- Fail-state contract (new). Three fail states, all after the return crossing begins: on the crossing (audio only: horn, crash sounds, silence, “Failed” screen), in the lamp room (the ship is seen and heard), and on the stairs (audio only unless a window sightline exists). A short reason line is always shown.
- Retry. Gate 1 fails restart the slice; the full retry and save model is settled before Gate 2. “Unlocked routes” is dropped; route branching is a Gate 2 cut-list candidate.
- Gate 2+ estimate and cut-list placeholder, and a decisions log (including Godot 4 confirmed).

---

## Technical Strategy

- Gates and schedule. Gate 1 now has two repairs, the return-crossing clock start and a restart on a fail. Hazard forecast added to week 2; Ted locked in week 3; week 4 rebalanced with an early deadline tuning pass; week 5 flagged as heavily loaded.
- Boat and weather. Two weather channels (perception by elapsed time, hazards by phase and position). Docking is automatic; leaving the corridor triggers a recovery. Outbound collisions cost no deadline time; penalty rules are loose for Gate 1.
- Engine is now *Godot 4* with GDScript, confirmed. The contracts are engine-neutral.

### State changes
• State contract. CRASH_AND_GATE becomes SHELTER_AND_GATE; “unlocked routes” removed; the clock starts on a return-departure event; the outcome resolves once per attempt. Gate 2 snapshots must restore time and weather together.
• Fail-state presentation specified for the three fail states, with a lamp-room sightline and a subtitle or visual alternative for audio-only cues.
• Fail State deadline length is reviewed once the return crossing from the outpost is tested.

---

## AI Agent Strategy

- Added Orchestrators: 
  - A Production Orchestrator and a Canon and Review Orchestrator delegate to the workers, hold the contracts, check handoffs, and escalate canon decisions. The creator keeps merge authority.
  - New worker roles. Hazard Forecast, and Story/Fail-State. Existing roles updated for the amended design.
  - Handoff format (new). Godot text files (.tscn, .gd, .tres), JSON or .tres data with stable IDs, a HANDOFF.md per task, and a REPORT.md from orchestrators, each with fixed headings.
  - Rules and sequence. Treat the decisions log as canon; no significant outpost detail until the prototype is complete; no work on Proposed, deferred or cut-list items without approval. Sequence expanded to ten steps; example orchestrator brief and review checklist added.

---

## Also changed

• Design Submission and Design Brief (MD and PDF) regenerated to match.
• Additional/Decisions to be made.md rewritten: 14 decided items, 19 still open.
• Additional/Dreams for the game.md: new “More outpost detail” entry.
