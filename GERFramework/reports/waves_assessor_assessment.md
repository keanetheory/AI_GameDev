# Waves - Assessment Agent: assessment of existing work

- knowledge up to date; 51 docs read, 60 hard rules, 13 open questions held
- Feedback goes to: wave_creator, Boat / Physics agent, Lighting agent
- Failing checks: **1**

**Mandate:** Hold the Wave Creator Agent to the lore (the eclipse makes tides aggressive and storms follow), the GDD (waves are a stretch goal; the crossings must work without them; reduced-intensity preset; wave hits cost no deadline time outbound) and the creator's intent (the first crossing is easy and simple, the last is hectic and stormy). Guard the canon gate: waves are unapproved in canon.py, validators.py, schemas.py and world_canon.py until the creator clears it.

| ID | Score (1-10) | Result | Evidence |
|---|---|---|---|
| WAV-03 | 8 | FAIL | LightingTheStorm/data/world/wave_spec.json is missing |
| WAV-01 | 4 | PASS | LightingTheStorm/scripts/world/boat.gd: /water_push/ matched 3 (need >= 2) |
| WAV-02 | 4 | PASS | LightingTheStorm/scripts/world/sea.gd: /wave_height/ matched 4 (need >= 2) |

## Open questions this assessor will not let anyone settle silently

- - **backstory:** caught in the storm and sought shelter on Bracken Isle. Why he and Daniel were out on the water is TBD (smugglers?).  (Docs/Lore Build/characters/chr_arthur.md:53)
- | Possible communication with the Flighted | fac_flighted / sys_eclipse | TBD | TBD | TBD |  (Docs/Lore Build/characters/chr_ted.md:50)
- - **Size and terrain:** roughly 330 m long and 140 m wide (about three football pitches by two). Rocky and windswept, with a few wind-battered trees that flower in spring (species TBD).  (Docs/Lore Build/regions/reg_bracken_isle.md:17)
- | The lighthouse | Single building | Guards the approach to the Saltgate. During eclipses it is the only true light by which ships can see the rocks. | TBD | Stone and mortar, battered but robust. Hau  (Docs/Lore Build/regions/reg_bracken_isle.md:23)
- - **sfx:** TBD (proposed: a low, sub-audible hum under the storm)  (Docs/Lore Build/systems/sys_eclipse.md:54)
- - "While the moon is covered, tides become more aggressive and storm season begins. The object therefore affects the moon's physical pull, not only its visibility (cause TBD, L4/L5)."  (Docs/Lore Build/world/geography.md:7)
- - Cold, wet, windswept maritime coast (proposed; latitude TBD).  (Docs/Lore Build/world/geography.md:29)
- - Prevailing wind direction: TBD. It should match the lean of Bracken Isle's trees.  (Docs/Lore Build/world/geography.md:33)