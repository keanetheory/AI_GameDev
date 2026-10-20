# Proposed GDD edits for the creator to approve (not applied)

The Wave Creator Agent does not edit the GDD without your say-so. These are the edits the 2026-10-20 workshop implies.

## Decisions to be made.md

- **Decision 20 (Wave hazards).** Move from "Stretch goals" to decided. Proposed text: "20. Waves (20 October 2026). Waves are approved for the prototype and the full game. The sea has a state from 0 to 5: the first crossing runs at 1 to 2, the return builds from 3 to 5, the docks are sheltered. Waves push the boat only through the existing push hook, never by more than A/D steering can cancel; they are switchable off, and the reduced hazard-intensity preset multiplies wave height and push by 0.6. A wave hit costs nothing outbound; on the return it slows the boat briefly and adds water, with no capsize."
- **Decision 24 (Boat speed).** Currently "The boat stays at 10 m/s until the waves are complete." Proposed: "24. Boat speed (20 October 2026). The boat runs at 8 m/s, held as data, to be confirmed after playtest." Note the built level's lighthouse-to-quay distance is about 510 m, so a leg takes about 65 s at 8 m/s (about 170 s at 3 m/s, about 51 s at 10 m/s). boat_spec.json's 1,500 m leg length is the original crew estimate and does not match the level.

## Technical Strategy.md / Exec Summary.md

- Replace "Wave hazards are a stretch goal ... first thing cut" with the Decision 20 wording, and keep "the crossings must work without waves" as the waves-off setting.
