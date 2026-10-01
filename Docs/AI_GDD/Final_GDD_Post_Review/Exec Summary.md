# Lighting the Storm — Executive Summary

Status: build brief derived from the source GDD, updated 1 October 2026 after the six-reviewer design review. Items marked Decided (review) were settled by the creator in response to that review and are canon. Items marked Proposed still need the creator’s approval. Open questions are tracked in Decisions to be made; ideas beyond the full-game scope are kept in Dreams for the game.

Change log (post-review amendments to the 25 September 2026 version)

- The rowboat crash is removed. Jeff and Daniel, overwhelmed by the storm, moor on the island seeking shelter; Ted sees them from the window and the player opens the island gate.
- Fail-state contract added: what the player perceives when the deadline expires, per location, and what happens next.
- Deadline timer now starts when the player, with the burner aboard, begins the return crossing to the lighthouse (not on boarding). There is no fail state before then, so the outbound crossing and the outpost let the player get a feel for the boat. The ship is introduced at the boarding threshold.
- Storm escalation is split: what the player perceives follows elapsed time; what the player collides with follows phase and route position.
- Core folk-horror discoveries move to the lighthouse and island, before boarding. The outpost keeps a lighter set.
- Ted’s presence is to be locked by the end of week 3; he is staged at the lamp for the final repair and both outcomes (voice and position only).
- Jeff’s motivation stated. Daniel’s role fixed (basement, no reaction recorded).
- Gate 1 includes two repairs; further repairs move to Gate 2 and the full game.
- Gate 1 retry model is “fail, then restart the slice”; the full retry and save model is settled before Gate 2. “Unlocked routes” is dropped; route branching is a Gate 2 cut-list candidate.
- A Gate 2+ estimate and ranked cut list placeholder is added. Decisions log added at the end.
- Engine confirmed by the creator as Godot 4 with GDScript (decisions log updated).
- Fail-state contract restated: three fail states, all after the return crossing begins (return crossing, lamp room, stairs). There is no fail state before then.
- Outpost kept minimal until the prototype is considered complete; further folk-horror, canon clues and documentation are parked in Dreams for the game. Deadline length is to be reviewed once the return crossing from the outpost is tested.

## Pitch and player promise

A new apprentice repairs the failing lighthouse on Bracken Isle with keeper Ted. Overwhelmed by the storm, two sailors, Jeff and Daniel, moor their rowboat on the island and look for shelter. Ted sees them from the window and tells the apprentice to open the island gate. Jeff, who can see the storm turning nasty, then crosses the water with the apprentice for a replacement beacon burner. The player must bring it back and restore the light before a passenger ship reaches the rocks. This is a first-person, single-player, atmospheric adventure for PC, designed for a 30 minute complete playthrough. The central player skill is steering a powered boat past rocks and other hazards while the storm worsens. Wave hazards are a stretch goal (see Scope and release target).

The experience should deliver sustained dread, hands-on mechanical work, and a consequential ending. It has no combat, monster reveal, or jump scares. Folk-horror details invite interpretation without confirming a supernatural cause.

Design pillars
1. The light must return: everything leads back to the beacon. It is what you repair, it guides you home, and it decides whether the ship lives. Test: does this connect to getting the light back, or to what happens if it fails?
2. The storm sets the clock: pressure comes from the world (the approaching ship’s lights, worsening weather, falling visibility, and rocks in the dark), never from a timer, meter, or enemy. Elapsed time drives what the player perceives (sound, lightning, wind, the ship’s lights); phase and route position drive what the player collides with (hazard density). Test: can the player feel time running out without any UI?
3. Your hands, your eyes: everything is first-person and physical. You fix things by hand, see the sailors arrive from the window, and see or hear the ship’s fate from where you stand; guidance comes from Ted and Jeff, not markers. Test: is this happening to the player in the world, or being shown to them?
4. Dread you can read: sustained unease and ambiguity, never jump scares or a confirmed monster, but the player always knows what to do and why they failed (one steering control, clear hazards, fair and recoverable mistakes, and a stated reason on failure). Test: does this add unease without adding confusion?

Scope rule: small world, read closely. One lighthouse, one stretch of sea, one abandoned outpost, and no new major locations.

The pillars and the scope rule govern cuts and reviews. A feature that fails a pillar’s test, or expands the world without deepening the main loop, should be deferred.

## Story and gameplay sequence

|Step                  |Player action                                                                                                                         |Result / gate                                                                                  |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
|1. Repairs            |Follow Ted’s live guidance; diagnose and fix a small set of mechanical systems using a fixed toolkit. The Gate 1 slice has two repairs; later repairs belong to Gate 2 and the full game.|The beacon alone still flickers. Repair work teaches interaction. Untimed lighthouse exploration and its discoveries sit here.|
|2. Shelter and gate   |Ted prompts the player to look out of the window, where Jeff and Daniel’s rowboat has moored on the island, the sailors overwhelmed by the storm. Ted tells the player to open the island gate.|Jeff and Daniel make their own way into the lighthouse. Daniel goes down to the basement and stays there. Ted explains that the burner must be collected from the abandoned outpost.|
|3. Boarding           |Meet Jeff at the engine boat. At the boarding threshold Ted names the passenger ship’s lights as the reason for the errand, and the ship appears on the horizon.|No deadline yet. The outbound crossing is free steering practice; the hidden passenger-ship deadline starts later, when the burner is aboard and the return crossing begins.|
|4. Outbound           |Steer the boat past rocks and debris in the storm while Jeff shouts directions.                                                       |Reach the abandoned outpost.                                                                   |
|5. Pickup             |Find and pick up the replacement burner.                                                                                              |The burner is aboard.                                                                          |
|6. Return             |With the burner aboard, steer back through a worsening storm, with denser hazards and lower visibility, guided by Jeff’s directions. The hidden deadline starts as the boat sets off.                          |Reach the lighthouse. On arrival Jeff says something like “go go go, don’t wait for me.”      |
|7. Final repair       |Climb to the lamp, where Ted waits, and fit the burner.                                                                               |The beacon is restored, or the deadline runs out first.                                        |
|8. Outcome            |Watch the ship from the lamp room.                                                                                                    |Win: the ship sails calmly into port; Ted reacts. Fail: the ship crashes into the island; Ted reacts (see Fail-state contract).|

Until the player has picked up the burner and the boat sets off on the return crossing, there is no ship deadline: lighthouse exploration, the outbound crossing and the outpost are all untimed. From then on, the same ship deadline keeps running through the return crossing and the final repair; there is no separate timer. The approaching ship and changing weather communicate urgency without a numeric display. Most crossing errors cost time and create recoverable problems. Missing the deadline triggers the fail state.

All viewpoints are first-person. There are no cutaway or exterior cameras; the sailors’ arrival, the ship, and the outcome are all seen (or, during the crossings, heard) from where the player stands.

## Fail-state contract

The deadline only runs from the start of the return crossing, so there is no fail state before then and the outbound crossing is practice. There are three fail states, depending on where the player is when the deadline expires. In every case the sequence is: the foghorn sounds, the ship crashes into the island, silence, and then a “Failed” title screen.

|Where the deadline expires      |What the player perceives                                                                                                  |
|--------------------------------|---------------------------------------------------------------------------------------------------------------------------|
|On the return crossing (burner aboard) |Audio only: ship horn, crash sounds, silence, then the “Failed” title screen. No cutaway camera.|
|In the lamp room                |The player sees the ship hit the island from the lamp room, and the audio still sounds. The lamp room needs a clear sightline to the ship’s route and the island rocks.|
|Elsewhere in the lighthouse (stairs) |Audio only, as on the crossing, unless a window sightline exists.                                                    |

Every fail shows a short line saying why the player failed (for example, that the beacon was not relit in time), delivered by Ted or Jeff or recorded in the journal, so Pillar 4 holds. Ted reacts to both outcomes from the lamp room using voice lines only; his reaction is staged by position, not a separate cutscene.

Retry model: for Gate 1, a fail returns the player to the start of the slice (fail, then restart). The full retry and save model is settled before Gate 2 (see Technical Strategy). Any future save must not store remaining time in a way that can produce an unwinnable save.

## Cast and atmosphere

• Apprentice: the player. Never speaks; characterised by actions and a handwritten objective journal. Moral beats are given to the apprentice by others, which is intended.
- Ted: gruff, experienced keeper; gives spoken directions during repairs, with a guarded sense of care. He sees the sailors from the window, names the ship at the boarding threshold, and waits at the lamp for the final repair and the outcome. Presence is to be locked by the end of week 3 (see Decisions log).
- Jeff: older, coarse seaman and the player’s companion on both crossings. He has realised the storm is getting nasty and wants to stop the ship being wrecked, which is why he helps despite his reluctance. After the second crossing he tells the player to go on without him. His reaction to the outcome is not recorded.
- Daniel: younger sailor from the rowboat; shaken by the storm and just glad to be alive. He goes to the basement and stays there. His reaction to the outcome is not recorded.

Two boats appear and must stay visibly distinct: Jeff and Daniel’s rowboat, moored on Bracken Isle, and the powered engine boat the player steers.

The lighthouse uses warm lamplight against blue-grey storm light. The beam remains a navigational and dramatic anchor. The abandoned outpost, log fragments, shrines, symbols, and subtly strange architecture suggest a history without settling its cause. Audio favours wind, rain, machinery, buoy bells, and a distant foghorn over musical stingers.

Folk-horror discoveries: the core discoveries are placed in the lighthouse and on the island, before boarding, where there is no ship deadline, and are tied to why the beacon failed. The outpost keeps a lighter set. This keeps the signature content outside the timed act. Until the prototype is considered complete, no significant detail is added to the outpost; further folk-horror, canon clues and documentation are tracked in Dreams for the game.

## Scope and release target

Full game, about 30 minutes: three compact locations, lighthouse repairs, the sailors’ arrival and the island gate, two crossings with Jeff, a final repair under the running ship deadline, win and fail outcomes, optional discoveries, and controller support. PC via Steam is the initial release target. The creator makes final decisions on tone, steering feel, and story.

Wave hazards are a stretch goal for both the prototype and the full game. The crossings must work without them: the challenge comes from steering past rocks, reefs, buoys, and debris in a worsening storm, and the sea surface can move for atmosphere without affecting the boat. Waves that push or roll the boat are added only after steering has passed its go/no-go test and only if the schedule has room; they are the first thing cut if it slips.

First playable prototype (Gate 1), about 10 minutes: two lighthouse repairs, Ted seeing the rowboat moored from the window, opening the island gate, meeting Jeff at the engine boat, an outbound crossing to the outpost, burner pickup, a return crossing to the lighthouse, fitting the burner, and both outcomes. Greybox art and placeholder audio are acceptable. The prototype must prove that hazards are readable and steering is enjoyable before broader production. Wave hazards are included only if time allows. Crossing penalty rules are deliberately loose for Gate 1 and must be reviewed for the full-game build.

Out of first-prototype scope: further lighthouse repairs beyond the first two, full outpost exploration, optional discoveries, final art, route branching on the return crossing, and a finished Steam release flow. These remain in the full-game brief or on the cut list.

## Gate 2+ estimate and ranked cut list (placeholder)

The review found that the document has no schedule, estimate, or cut list beyond the prototype. To be completed after Gate 1 playtests, using measured data. Provisional cut-list order, first cut first:
1. Wave hazards (stretch goal).
2. Return-crossing route branching (a riskier shortcut; deferred from Gate 1).
3. Additional repairs beyond the first two.
4. Outpost optional discoveries beyond the light set.
Each item must be assigned an estimate and a decision owner before Gate 2 begins.

## Outcome checks

Prototype:
- A new player understands what to repair, where to head, and which hazard to avoid without a timer UI.
- The boat has one steering control, one fixed speed, clear feedback for near misses and collisions, and a recoverable error state.
- The ship is introduced at the boarding threshold, and its lights and position communicate the stakes.
- Both the win and fail outcomes can be reached, and a failed player can say why they failed.
- After a fail, the player can restart the slice.

Full game:
- A first-time playthrough lasts about 30 minutes.
- The final implementation preserves unexplained environmental wrongness.
- The final retry and save model has been decided and tested for unwinnable saves.

## Decisions log (review, 1 October 2026)

|Decision                         |Outcome                                                                                                                       |
|---------------------------------|------------------------------------------------------------------------------------------------------------------------------|
|Retry model at Gate 1            |Fail, then restart the slice. Full retry and save model settled before Gate 2.                                                |
|Storm escalation                 |Split: sound, lightning, wind and the ship’s lights follow elapsed time; hazard density follows phase and route position.     |
|Return-crossing shortcut         |Dropped for now. “Unlocked routes” removed from the save contract. Branching is a Gate 2 cut-list candidate.                  |
|Folk-horror discoveries          |Core discoveries in the lighthouse and island, before boarding, tied to why the beacon failed; lighter set at the outpost. No significant outpost detail until the prototype is complete.|
|Ted                              |Lock his presence by the end of week 3. Staged at the lamp for the climax and outcome, voice and position only.               |
|Sailors’ arrival                 |No crash. Jeff and Daniel moor on the island seeking shelter; Ted sees them from the window; the player opens the island gate.|
|Jeff                             |Motivated by stopping the ship from crashing. Tells the player to go on without him after the second crossing.               |
|Daniel                           |In the basement; no reaction to the outcome recorded.                                                                         |
|Repairs                          |Two for Gate 1; more at Gate 2 and in the full game.                                                                          |
|Apprentice                       |Never speaks; others give the moral beat.                                                                                     |
|Crossing penalties               |Loose for Gate 1; to be reviewed for the full game.                                                                           |
|Fail presentation                |Horn, ship crashes into the island, silence, “Failed” title screen. Three fail states, all after the return crossing begins; the crash is seen only from the lamp room.|
|Clock start                      |Starts when the burner is aboard and the boat sets off on the return crossing. No fail state before then, so the outbound crossing is steering practice.|
|Engine                           |Godot 4 with GDScript, confirmed by the creator after reviewing the Engine Comparison pros and cons.                          |

See Technical Strategy for the build contract, AI Agent Strategy for delegated work, orchestration and handoffs, Decisions to be made for open questions, and Dreams for the game for ideas outside the current scope.
