Lighthouse Keeper’s Apprentice — Executive Summary

Status: build brief derived from the source GDD, 22 September 2026. Decisions explicitly marked Proposed need the creator’s approval before they become canon.

Pitch and player promise

A new apprentice repairs a failing lighthouse with keeper Ted, rescues two sailors after a nearby wreck, and crosses stormy water for a replacement beacon burner. The player must bring it back and restore the light before a passenger ship reaches the rocks. This is a first-person, single-player, atmospheric adventure for PC, designed for a 45–60 minute complete playthrough. The central player skill is steering a powered boat through readable waves while the storm worsens.

The experience should deliver sustained dread, hands-on mechanical work, and a consequential ending. It has no combat, monster reveal, or jump scares. Folk-horror details invite interpretation without confirming a supernatural cause.

Design rules

1. Dread, not shock: build tension with weather, distance, light, sound, and uncertainty.
2. The sea is the antagonist: danger comes from waves, rocks, visibility, and time.
3. Legible under pressure: one steering input, strong visual and audio feedback, no visible countdown.
4. Small world, read closely: one lighthouse, one stretch of sea, one abandoned outpost.

These rules govern cuts and reviews. A feature that weakens readability or expands the world without deepening the main loop should be deferred.

Story and gameplay sequence

|Phase     |Player action                                                                                       |Result / gate                                                                             |
|----------|----------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
|Lighthouse|Follow Ted’s live guidance; diagnose and fix a small set of systems using a fixed toolkit.          |The beacon alone still flickers. Repair work teaches interaction and opens the dock route.|
|Wreck     |Respond to Ted’s alarm; find Jeff and Daniel and escort both to safety.                             |Ted explains that the burner must be collected from the outpost.                          |
|Choice    |Choose Jeff or Daniel as boat companion.                                                            |Jeff gives spoken warnings; Daniel uses a fast visual flashlight cue that can mislead.    |
|Outbound  |Board the powered boat, triggering the hidden passenger-ship deadline; steer through moderate waves.|Reach the abandoned outpost and recover the burner.                                       |
|Return    |Bring fragile cargo back through stronger waves, with the chosen companion’s help.                  |Reach the lighthouse; lost cargo must have a recoverable route.                           |
|Climax    |Fit the burner and restore the beacon.                                                              |Ship passes safely if the light returns in time; otherwise it runs aground.               |

Before boarding, exploration has no ship deadline. After boarding, the approaching ship and changing weather communicate urgency without a numeric timer. Most crossing errors cost time and create recoverable problems. Missing the ship deadline changes the ending rather than erasing the run.

Cast and atmosphere

• Apprentice: mostly characterised by actions and a handwritten objective journal.
• Ted: gruff, experienced keeper; gives spoken directions during repairs, with a guarded sense of care.
• Jeff: older, coarse seaman; reliable verbal navigation cues despite his reluctance to help.
• Daniel: younger steersman; defensive about the wreck; quick flashlight guidance that is occasionally wrong.

The lighthouse uses warm lamplight against blue-grey storm light. The beam remains a navigational and dramatic anchor. The abandoned outpost, log fragments, shrines, symbols, and subtly strange architecture suggest a history without settling its cause. Audio favours wind, rain, machinery, buoy bells, and a distant foghorn over musical stingers.

Scope and release target

Full game: three compact locations, lighthouse repairs, rescue and companion choice, two crossings, one timed final repair, two principal ship outcomes, optional discoveries, and controller support. PC via Steam is the initial release target. The creator makes final decisions on tone, steering feel, and story.

First playable prototype, approximately 10 minutes: one lighthouse repair, the beacon fault and departure, one short powered-boat crossing with one companion, burner pickup, and a short return ending in a beacon interaction. Greybox art and placeholder audio are acceptable. The prototype must prove that waves are readable and steering is enjoyable before broader production.

Out of first-prototype scope: complete rescue escort, both companion branches, full outpost exploration, hidden coda, Full Gale mode, final art, and a finished Steam release flow. These remain in the full-game brief.

Outcome checks

• A new player understands what to repair, where to head, and which wave to avoid without a timer UI.
• The boat has one steering control, clear feedback for risky angles, and a recoverable error state.
• Beacon and ship positions visibly communicate the stakes from exterior viewpoints.
• Both ship outcomes can be reached in the full game; either companion completes the route.
• The final implementation preserves unexplained environmental wrongness.

Decisions to settle before full production

1. Ted’s presence: the GDD describes both live barked directions and a keeper heard only in recordings. Proposed: Ted is present and speaks live; recordings and journals belong to earlier keepers. Confirm before recording dialogue.
2. Hidden coda: it currently promises to reveal what symbols “actually mean,” conflicting with permanent ambiguity. Proposed: reveal historical relationships or events while leaving the supernatural explanation open.
3. Boat terminology: survivors wreck a rowboat; the player’s crossing uses a separate powered boat. Keep these visibly distinct.
4. Ship arrival rules: specify deadline, pause behaviour, checkpoint handling, and whether a late beacon repair still completes the run. Proposed implementation is in Technical Strategy.

See Technical Strategy for the build contract and AI Agent Strategy for delegated work and handoffs.