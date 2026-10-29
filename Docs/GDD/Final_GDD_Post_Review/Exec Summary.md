# Lighting the Storm — Executive Summary

Status: build brief derived from the source GDD, updated 1 October 2026 after the six-reviewer design review, and on 16 October 2026 to match the creator’s fixed story beats. Items marked Decided (review) were settled by the creator in response to that review and are canon. Items marked Proposed still need the creator’s approval. Open questions are tracked in Decisions to be made; ideas beyond the full-game scope are kept in Dreams for the game.

Change log (post-review amendments to the 25 September 2026 version)

- The rowboat crash is removed. Arthur and Daniel, overwhelmed by the storm, moor at the island’s dock seeking shelter; Ted sees them from the window and the player opens the island gate.
- Fail-state contract added: what the player perceives when the deadline expires, per location, and what happens next.
- Deadline timer now starts when the player, with the burner aboard, begins the return crossing to the lighthouse (not on boarding). There is no fail state before then, so the outbound crossing and the Saltgate let the player get a feel for the boat. The ship is introduced at the boarding threshold.
- Storm escalation is split: what the player perceives follows elapsed time; what the player collides with follows phase and route position.
- Core folk-horror discoveries move to the lighthouse and island, before boarding. The Saltgate keeps a lighter set.
- Ted’s presence is to be locked by the end of week 3; he is staged at the lamp for the final repair and both outcomes (voice and position only).
- Arthur’s motivation stated. Daniel’s role fixed (basement, no reaction recorded).
- Gate 1 includes two repairs; further repairs move to Gate 2 and the full game.
- Gate 1 retry model is “fail, then restart the slice”; the full retry and save model is settled before Gate 2. “Unlocked routes” is dropped; route branching is a Gate 2 cut-list candidate.
- A Gate 2+ estimate and ranked cut list placeholder is added. Decisions log added at the end.
- Engine confirmed by the creator as Godot 4 with GDScript (decisions log updated).
- Fail-state contract restated: three fail states, all after the return crossing begins (return crossing, lamp room, stairs). There is no fail state before then.
- The Saltgate kept minimal until the prototype is considered complete; further folk-horror, canon clues and documentation are parked in Dreams for the game. Deadline length is to be reviewed once the return crossing from the Saltgate is tested.
- 16 October 2026, story beats fixed by the creator: the player (Isaac, “the new guy”) starts outside the lighthouse and Ted opens the door; Ted then sends him to the basement to shovel coal into the boiler; the sailors moor at the dock and the player opens the island gate; only then does Ted take the player to the lantern room and find the beacon’s burner broken. The crossing’s destination is the Saltgate quays (Saint Calder’s abandoned harbour; “abandoned outpost” is retired). The fail wording is “runs aground” again. The Gate 1 hands-on work is feeding the boiler and fitting the burner, replacing the generic “two repairs”.

## Pitch and player promise

A new apprentice, Isaac, arrives at the failing lighthouse on Bracken Isle. Keeper Ted opens the door to “the new guy” and, after a beat, sends him down to the basement to shovel coal into the boiler. Overwhelmed by the storm, two sailors, Arthur and Daniel, moor their rowboat at the island’s dock and look for shelter; Ted sees them from the window and tells the apprentice to open the island gate. The dynamo runs, but the beacon stays dark: Ted takes the apprentice up to the lantern room and finds the burner broken. Arthur, who can see the storm turning nasty, crosses the Gullwater with the apprentice to fetch a replacement burner from the Saltgate, Saint Calder’s abandoned harbour. The player must bring it back through the worsening storm and fit it to the beacon before a passenger ship runs aground. This is a first-person, single-player, atmospheric adventure for PC, designed for a 30 minute complete playthrough. The central player skill is steering a powered boat past rocks and other hazards while the storm worsens. The sea builds from a calm first crossing to a hectic return, with waves that push the boat (see Scope and release target).

The experience should deliver sustained dread, hands-on mechanical work, and a consequential ending. It has no combat, monster reveal, or jump scares. Folk-horror details invite interpretation without confirming a supernatural cause.

Design pillars
1. The light must return: everything leads back to the beacon. It is what you repair, it guides you home, and it decides whether the ship lives. Test: does this connect to getting the light back, or to what happens if it fails?
2. The storm sets the clock: pressure comes from the world (the approaching ship’s lights, worsening weather, falling visibility, and rocks in the dark), never from a timer, meter, or enemy. Elapsed time drives what the player perceives (sound, lightning, wind, the ship’s lights); phase and route position drive what the player collides with (hazard density). Test: can the player feel time running out without any UI?
3. Your hands, your eyes: everything is first-person and physical. You fix things by hand, see the sailors arrive from the window, and see or hear the ship’s fate from where you stand; guidance comes from Ted and Arthur, not markers. Test: is this happening to the player in the world, or being shown to them?
4. Dread you can read: sustained unease and ambiguity, never jump scares or a confirmed monster, but the player always knows what to do and why they failed (one steering control, clear hazards, fair and recoverable mistakes, and a stated reason on failure). Test: does this add unease without adding confusion?

Scope rule: small world, read closely. One lighthouse, one stretch of sea, one abandoned harbour (the Saltgate), and no new major locations.

The pillars and the scope rule govern cuts and reviews. A feature that fails a pillar’s test, or expands the world without deepening the main loop, should be deferred.

## Story and gameplay sequence

|Step                  |Player action                                                                                                                         |Result / gate                                                                                  |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
|1. Arrival and coal   |Start outside the lighthouse. Ted opens the door (“You’re the new guy, then”) and the player comes in. After a beat, Ted sends the player down to the basement to shovel coal into the boiler.|Steam is up and the dynamo runs. Feeding the boiler teaches interaction. Untimed lighthouse exploration and its discoveries sit here.|
|2. Shelter and gate   |Ted, at the window, sees Arthur and Daniel’s rowboat moored at the dock, the sailors overwhelmed by the storm. He tells the player to open the island gate, on the path from the dock to the lighthouse.|Arthur and Daniel make their own way into the lighthouse. Daniel goes down to the basement and stays there.|
|3. Beacon diagnosis   |The dynamo runs but the beacon stays dark. Follow Ted up to the lantern room, where he opens the arc lamp.                               |Ted finds the burner broken and says a new one is needed: a spare must be fetched from the Saltgate quays, with Arthur.|
|4. Boarding           |Meet Arthur at the engine boat. At the boarding threshold Ted names the passenger ship’s lights as the reason for the errand, and the ship appears on the horizon.|No deadline yet. The outbound crossing is free steering practice; the hidden passenger-ship deadline starts later, when the burner is aboard and the return crossing begins.|
|5. Outbound           |Steer the boat across the Gullwater, past rocks and debris, as the rain sets in, while Arthur shouts directions.                          |Reach the Saltgate quays (Saint Calder’s abandoned harbour).                                   |
|6. Pickup             |Find and pick up the replacement burner.                                                                                              |The burner is aboard.                                                                          |
|7. Return             |With the burner aboard, steer back as the storm escalates (darker skies, heavier rain, lightning between the clouds), with denser hazards and lower visibility, guided by Arthur’s directions. The hidden deadline starts as the boat sets off.|Reach the lighthouse. On arrival Arthur says something like “go go go, don’t wait for me.”      |
|8. Final repair       |Climb to the lamp, where Ted waits, and fit the burner to the beacon.                                                                 |The beacon is restored, or the deadline runs out first.                                        |
|9. Outcome            |Watch the ship from the lamp room.                                                                                                    |Win: the ship sails safely past the rocks and into port; Ted reacts. Fail: the ship crashes on the rock next to the island; Ted reacts (see Fail-state contract).|

Until the player has picked up the burner and the boat sets off on the return crossing, there is no ship deadline: lighthouse exploration, the outbound crossing and the Saltgate are all untimed. From then on, the same ship deadline keeps running through the return crossing and the final repair; there is no separate timer. The approaching ship and changing weather communicate urgency without a numeric display. Most crossing errors cost time and create recoverable problems. Missing the deadline triggers the fail state. The placeholder deadline for Gate 1 testing is 3 minutes 30 seconds (creator, 26 October 2026; Decisions A28); the final length is set from playtests.

All viewpoints are first-person. There are no cutaway or exterior cameras; the sailors’ arrival, the ship, and the outcome are all seen (or, during the crossings, heard) from where the player stands.

## Fail-state contract

The deadline only runs from the start of the return crossing, so there is no fail state before then and the outbound crossing is practice. There are three fail states, depending on where the player is when the deadline expires. In every case the sequence is: the foghorn sounds, the ship crashes on the rock next to the island, silence, and then a “Failed” title screen.

|Where the deadline expires      |What the player perceives                                                                                                  |
|--------------------------------|---------------------------------------------------------------------------------------------------------------------------|
|On the return crossing (burner aboard) |The ship crashes on the rock next to the island in the world; the player hears the horn and the crash and sees it if the island is in view. No cutaway camera, and the game does not wait. Then silence and the “Failed” title screen.|
|In the lamp room                |The player sees the ship run aground on the island from the lamp room, and the audio still sounds. The lamp room needs a clear sightline to the ship’s route and the island rocks.|
|Elsewhere in the lighthouse |The player hears the crash. Looking out of a window shows the ship crashing on the rock. On the stairs with no window they see nothing.|

The fail is not audio only (creator, 26 October 2026, Decisions A30): the crash happens in the world and the game does not wait for the player. Ted's fail dialogue plays at SHIP_FAIL (A31). Every fail shows a short line saying why the player failed (for example, that the beacon was not relit in time), delivered by Ted or Arthur or recorded in the journal, so Pillar 4 holds. Ted reacts to both outcomes from the lamp room using voice lines only; his reaction is staged by position, not a separate cutscene.

Retry model: for Gate 1, a fail returns the player to the start of the slice (fail, then restart). The full retry and save model is settled before Gate 2 (see Technical Strategy). Any future save must not store remaining time in a way that can produce an unwinnable save.

## Cast and atmosphere

• Apprentice: the player, Isaac, “the new guy”. Never speaks; characterised by actions and a handwritten objective journal. Moral beats are given to the apprentice by others, which is intended.
- Ted: gruff, experienced keeper; gives spoken directions throughout, with a guarded sense of care. He opens the lighthouse door to the new apprentice and sends him to feed the boiler, sees the sailors from the window, finds the beacon’s burner broken in the lantern room, names the ship at the boarding threshold, and waits at the lamp for the final repair and the outcome. He is present throughout (A19) and reacts by voice to the burner fit, the win and the fail (lines picked 29 October 2026, Decisions A33). On a fail, after the crash line he says the reason line: “That ship...we didn’t get the burner out in time...those poor souls on board...we’ve failed...FAILED!!”
- Arthur: older, coarse seaman and the player’s companion on both crossings. He has realised the storm is getting nasty and wants to stop the ship being wrecked, which is why he helps despite his reluctance. After the second crossing he tells the player to go on without him. His reaction to the outcome is not recorded.
- Daniel: younger sailor from the rowboat; shaken by the storm and just glad to be alive. He goes to the basement and stays there. His reaction to the outcome is not recorded.

Two boats appear and must stay visibly distinct: Arthur and Daniel’s rowboat, moored on Bracken Isle, and the powered engine boat the player steers.

The lighthouse uses warm lamplight against blue-grey storm light. The beam remains a navigational and dramatic anchor. The abandoned Saltgate quays, log fragments, shrines, symbols, and subtly strange architecture suggest a history without settling its cause. Audio favours wind, rain, machinery, buoy bells, and a distant foghorn over musical stingers.

Folk-horror discoveries: the core discoveries are placed in the lighthouse and on the island, before boarding, where there is no ship deadline, and are tied to why the beacon failed. The Saltgate keeps a lighter set. This keeps the signature content outside the timed act. Until the prototype is considered complete, no significant detail is added to the Saltgate; further folk-horror, canon clues and documentation are tracked in Dreams for the game.

## Scope and release target

Full game, about 30 minutes: three compact locations, the arrival and lighthouse work (feeding the boiler, then further repairs), the sailors’ arrival and the island gate, Ted’s discovery of the broken burner, two crossings with Arthur, a final repair under the running ship deadline, win and fail outcomes, optional discoveries, and controller support. PC via Steam is the initial release target. The creator makes final decisions on tone, steering feel, and story.

Waves are part of the initial release (creator, 29 October 2026; Decisions A32). The sea has a state from 0 to 5: the first crossing is easy (1 to 2) and the return is hectic (3 to 5), with both docks sheltered. Waves push the boat only through one hook and never by more than A/D steering can cancel, and they are switchable off, so the crossings must still work without them: the challenge comes from steering past rocks, reefs, buoys, and debris in a worsening storm. A reduced hazard-intensity preset multiplies wave height and push by 0.6. A wave hit costs nothing outbound; on the return it slows the boat briefly and adds water, with no capsize.

First playable prototype (Gate 1), about 10 minutes: arriving outside the lighthouse as Ted opens the door, shovelling coal into the boiler, Ted seeing the rowboat moored at the dock from the window, opening the island gate, Ted finding the burner broken in the lantern room, meeting Arthur at the engine boat, an outbound crossing to the Saltgate quays, burner pickup, a return crossing to the lighthouse as the storm escalates, fitting the burner, and both outcomes. Greybox art and placeholder audio are acceptable. The prototype must prove that hazards are readable and steering is enjoyable before broader production. Waves are included, behind an on/off setting. Crossing penalty rules are deliberately loose for Gate 1 and must be reviewed for the full-game build.

Out of first-prototype scope: further lighthouse repairs beyond feeding the boiler and fitting the burner, full Saltgate exploration, optional discoveries, final art, route branching on the return crossing, and a finished Steam release flow. These remain in the full-game brief or on the cut list.

## Gate 2+ estimate and ranked cut list (placeholder)

The review found that the document has no schedule, estimate, or cut list beyond the prototype. To be completed after Gate 1 playtests, using measured data. Provisional cut-list order, first cut first:
1. Return-crossing route branching (a riskier shortcut; deferred from Gate 1).
2. Additional repairs beyond feeding the boiler and fitting the burner.
3. Saltgate optional discoveries beyond the light set.
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
|Folk-horror discoveries          |Core discoveries in the lighthouse and island, before boarding, tied to why the beacon failed; lighter set at the Saltgate. No significant Saltgate detail until the prototype is complete.|
|Ted                              |Lock his presence by the end of week 3. Staged at the lamp for the climax and outcome, voice and position only.               |
|Sailors’ arrival                 |No crash. Arthur and Daniel moor at the dock seeking shelter; Ted sees them from the window; the player opens the island gate.|
|Arthur                             |Motivated by stopping the ship from running aground. Tells the player to go on without him after the second crossing.               |
|Daniel                           |In the basement; no reaction to the outcome recorded.                                                                         |
|Repairs                          |Gate 1: feeding the boiler with coal, then fitting the burner (16 October 2026, replacing “two repairs”); more at Gate 2 and in the full game.|
|Apprentice                       |Never speaks; others give the moral beat.                                                                                     |
|Crossing penalties               |Loose for Gate 1; to be reviewed for the full game.                                                                           |
|Fail presentation                |Horn, the ship crashes on the rock next to the island and the game does not wait, silence, “Failed” title screen. Three fail states, all after the return crossing begins; the crash is seen from the windows, the lamp room and the crossing when the island is in view, and only heard on the stairs with no window.|
|Clock start                      |Starts when the burner is aboard and the boat sets off on the return crossing. No fail state before then, so the outbound crossing is steering practice.|
|Waves (29 October 2026)          |Part of the initial release: sea state 0 to 5, easy outbound, hectic return, sheltered docks, switchable off (Decisions A32).      |
|Boat speed (29 October 2026)     |8 m/s, held as data (Decisions A24).                                                                                          |
|Deadline length                  |Placeholder 3 minutes 30 seconds for Gate 1 testing; final value from playtests (Decisions A28).                              |
|Engine                           |Godot 4 with GDScript, confirmed by the creator after reviewing the Engine Comparison pros and cons.                          |
|Story beats (16 October 2026)    |Arrival outside (Ted opens the door) → coal into the boiler → sailors moor at the dock, player opens the island gate, Daniel stays in the basement → beacon still dark, Ted finds the burner broken in the lantern room → outbound to the Saltgate quays with Arthur → storm escalates on the return → fit the burner before the ship runs aground. The part is “the burner”; the destination is the Saltgate.|

See Technical Strategy for the build contract, AI Agent Strategy for delegated work, orchestration and handoffs, Decisions to be made for open questions, and Dreams for the game for ideas outside the current scope.
