Lighting the Storm — Executive Summary

Status: build brief derived from the source GDD, updated 25 September 2026. Decisions explicitly marked Proposed need the creator’s approval before they become canon. Open questions are tracked in Decisions to be made; ideas beyond the full-game scope are kept in Dreams for the game.

Pitch and player promise

A new apprentice repairs the failing lighthouse on Bracken Isle with keeper Ted. A rowboat carrying two sailors crashes onto Bracken Isle, and the apprentice opens the lighthouse gate to let them in. With one of the sailors, the apprentice then crosses stormy water for a replacement beacon burner. The player must bring it back and restore the light before a passenger ship reaches the rocks. This is a first-person, single-player, atmospheric adventure for PC, designed for a 30 minute complete playthrough. The central player skill is steering a powered boat past rocks and other hazards while the storm worsens. Wave hazards are a stretch goal (see Scope and release target).

The experience should deliver sustained dread, hands-on mechanical work, and a consequential ending. It has no combat, monster reveal, or jump scares. Folk-horror details invite interpretation without confirming a supernatural cause.

Design pillars

1. The light must return: everything leads back to the beacon. It is what you repair, it guides you home, and it decides whether the ship lives. Test: does this connect to getting the light back, or to what happens if it fails?
2. The storm sets the clock: pressure comes from the world (the approaching ship’s lights, worsening weather, falling visibility, and rocks in the dark), never from a timer, meter, or enemy. Test: can the player feel time running out without any UI?
3. Your hands, your eyes: everything is first-person and physical. You fix things by hand, watch the crash through the window, and see the ship’s fate from where you stand; guidance comes from Ted and Jeff, not markers. Test: is this happening to the player in the world, or being shown to them?
4. Dread you can read: sustained unease and ambiguity, never jump scares or a confirmed monster, but the player always knows what to do and why they failed (one steering control, clear hazards, fair and recoverable mistakes). Test: does this add unease without adding confusion?

Scope rule: small world, read closely. One lighthouse, one stretch of sea, one abandoned outpost, and no new major locations.

The pillars and the scope rule govern cuts and reviews. A feature that fails a pillar’s test, or expands the world without deepening the main loop, should be deferred.

Story and gameplay sequence

|Step              |Player action                                                                                                                         |Result / gate                                                                                  |
|------------------|--------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
|1. Repairs        |Follow Ted’s live guidance; diagnose and fix a small set of mechanical systems using a fixed toolkit.                                 |The beacon alone still flickers. Repair work teaches interaction.                              |
|2. Crash and gate |Ted prompts the player to look out of the window, where Jeff and Daniel’s rowboat crashes onto Bracken Isle. Ted tells the player to open the lighthouse gate.|Jeff and Daniel make their own way into the lighthouse. Ted explains that the burner must be collected from the abandoned outpost.|
|3. Boarding       |Meet Jeff at the engine boat.                                                                                                         |Boarding starts the hidden passenger-ship deadline.                                            |
|4. Outbound       |Steer the boat past rocks and debris in the storm while Jeff shouts directions.                                                       |Reach the abandoned outpost.                                                                   |
|5. Pickup         |Find and pick up the replacement burner.                                                                                              |The burner is aboard.                                                                          |
|6. Return         |Steer back through a worsening storm, with denser hazards and lower visibility, guided by Jeff’s directions.                          |Reach the lighthouse.                                                                          |
|7. Final repair   |Climb to the lamp and fit the burner.                                                                                                 |The beacon is restored, or the deadline runs out first.                                        |
|8. Outcome        |Watch the ship from the lighthouse.                                                                                                   |Win: the ship sails calmly into port. Fail: the ship runs aground.                             |

Before boarding, exploration has no ship deadline. After boarding, the same ship deadline keeps running through both crossings, the pickup, and the final repair; there is no separate timer. The approaching ship and changing weather communicate urgency without a numeric display. Most crossing errors cost time and create recoverable problems. Missing the deadline triggers the fail state: the ship runs aground.

All viewpoints are first-person. There are no cutaway or exterior cameras; the crash, the ship, and the outcome are all seen from where the player stands.

Cast and atmosphere

• Apprentice: mostly characterised by actions and a handwritten objective journal.
• Ted: gruff, experienced keeper; gives spoken directions during repairs, with a guarded sense of care.
• Jeff: older, coarse seaman and the player’s companion on both crossings; reliable verbal navigation cues despite his reluctance to help.
• Daniel: younger sailor from the rowboat; shaken by the crash and just glad to be alive. He stays at the lighthouse.

Two boats appear and must stay visibly distinct: Jeff and Daniel’s rowboat, wrecked on Bracken Isle, and the powered engine boat the player steers.

The lighthouse uses warm lamplight against blue-grey storm light. The beam remains a navigational and dramatic anchor. The abandoned outpost, log fragments, shrines, symbols, and subtly strange architecture suggest a history without settling its cause. Audio favours wind, rain, machinery, buoy bells, and a distant foghorn over musical stingers.

Scope and release target

Full game, about 30 minutes: three compact locations, lighthouse repairs, the rowboat crash and gate, two crossings with Jeff, a final repair under the running ship deadline, win and fail outcomes, optional discoveries, and controller support. PC via Steam is the initial release target. The creator makes final decisions on tone, steering feel, and story.

Wave hazards are a stretch goal for both the prototype and the full game. The crossings must work without them: the challenge comes from steering past rocks, reefs, buoys, and debris in a worsening storm, and the sea surface can move for atmosphere without affecting the boat. Waves that push or roll the boat are added only after steering has passed its go/no-go test and only if the schedule has room; they are the first thing cut if it slips.

First playable prototype, about 10 minutes: one lighthouse repair, the rowboat crash seen from the window, opening the gate, meeting Jeff at the engine boat, an outbound crossing to the outpost, burner pickup, a return crossing to the lighthouse, fitting the burner, and both outcomes. Greybox art and placeholder audio are acceptable. The prototype must prove that hazards are readable and steering is enjoyable before broader production. Wave hazards are included only if time allows.

Out of first-prototype scope: the remaining lighthouse repairs, full outpost exploration, optional discoveries, final art, and a finished Steam release flow. These remain in the full-game brief.

Outcome checks

Prototype:
• A new player understands what to repair, where to head, and which hazard to avoid without a timer UI.
• The boat has one steering control, one fixed speed, clear feedback for near misses and collisions, and a recoverable error state.
• The ship’s lights and position, seen in first person, communicate the stakes.
• Both the win and fail outcomes can be reached.

Full game:
• A first-time playthrough lasts about 30 minutes.
• The final implementation preserves unexplained environmental wrongness.

See Technical Strategy for the build contract, AI Agent Strategy for delegated work and handoffs, Decisions to be made for open questions, and Dreams for the game for ideas outside the current scope.
