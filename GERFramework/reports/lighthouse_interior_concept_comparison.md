# Lighthouse interior: comparison with the blueprint and concept art (updated 2026-10-20, after the room build)

Compared against `ConceptArt/narrative_blueprints/Brussskania Lighthouse Blueprint Poster.png` (the title keeps the retired spelling; the canon name is Saint Calder) and the three views in `ConceptArt/lighthouse/`, using renders of the running level (`GERFramework/shoot_house.py`).

| Aspect | Blueprint / concept art | Build now | Verdict |
|---|---|---|---|
| Floors | B1, G, L1, L2, L3 | B1, G, L1 (house), L2 (tower landing ring), L3 (lamp room), all walkable | match; L2 is a tower landing because the roof leaves no house floor |
| Entry vestibule | arched door into a short entry | door, coats, boots, lanterns, rug | present |
| Hallway | narrow, posters and documents, dim | posters (two Flighted, one moon-cycle), notice board, tide table | present; posters are paper and text, no printed art |
| Keeper's office | desk, shelves, window, warm lamp | desk, lamp, ledgers, chart table, cabinet, clock, window | present |
| Storage room | crates and barrels | crates, barrels, shelving, rope | present |
| Boiler room | boiler, coal heaps, pipes, warm firebox glow | boiler with firebox glow and flicker, gauge, water glass, steam main, cistern, coal heap | present and interactive |
| Steam engine and dynamo | brass engine, flywheel, dynamo | engine with turning flywheel, dynamo, belt, switchboard | present, simplified |
| Workshop and stores | benches, shelves of parts | bench, vice, tool board, parts shelving | present, small |
| Foundation chamber | circular room under the tower | not built | deferred (needs an island collider carve) |
| Crawlspace and wall voids | whispers and bangs | five grilled voids with triggers | present, sound sources only |
| L1 keeper's quarters | kitchen and mess, sleeping, wash, radio and chart, linen | all five, plus the tower door | present |
| L2 control and diagnostics | electrical control room, instrument station, landing, tools | control cabinet, instrument station, locker on the landing ring | present, ring-shaped |
| Lamp room | glazed lantern, brass frame, big arc lamp, broken at start | continuous glass all round, brass and iron frame, Fresnel lens, burner bay, broken burner on the floor, lights when the burner is fitted | match, placeholder beam |
| Huts and annex | storage only | exterior only | as the blueprint says |
| Light mood | dim, warm, claustrophobic | warm lamps, at most six lit and two shadowed near the player | needs a Lighting agent pass |

Not compared: texture and decal work (everything is procedural colour and noise), props at concept-art density (paperwork, bottles, tools), and the final beacon look.
