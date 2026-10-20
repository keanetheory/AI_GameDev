---
id: changelog
type: changelog
---

# Changelog

## 2026-10-20: Waves and tides approved by the creator

- Waves are no longer a stretch goal. The sea has a state from 0 (glass) to 5 (storm). The first crossing (outbound) is easy, state 1 to 2; the return is hectic, state 3 to 5, building as the storm does; the water is calmer at both docks.
- The eclipse link (tides turn aggressive while the moon is covered) will be shown as a dimming cover over the supermoon on the return. No sphere is shown and the eclipse is not explained; the Flighted ship still arrives later.
- Crossing speed: 8 m/s, held as data, to be confirmed after playtest.
- Source: GERFramework/workshops/wave_design_workshop.md (D1-D10). The GDD Decisions log has NOT been edited; see GERFramework/reports/wave_gdd_decision_proposals.md.

## 2026-10-16: Story beats fixed by the creator

### Story beats (canon, in order)
1. **Arrival:** the player (Isaac, "the new guy") starts outside the lighthouse. Ted opens the door ("You're the new guy, then") and the player comes in.
2. **Coal:** after a beat, Ted sends the player to the basement to shovel coal into the boiler.
3. **Shelter and gate:** Arthur and Daniel moor their rowboat at the dock; the player opens the island gate (on the path from the dock to the lighthouse) to let them in. Daniel stays in the basement.
4. **Beacon diagnosis:** the dynamo runs but the beacon stays dark. Ted takes the player up to the lantern room, finds the burner broken and says a new one is needed. Ted identifies it, and only after the sailors are in.
5. **Outbound:** the player takes the steam launch across the Gullwater with Arthur and retrieves the replacement burner from the Saltgate quays.
6. **Return:** the storm escalates: darker skies, heavier rain, lightning between the clouds.
7. **Final repair:** the player gets back to the lighthouse and fits the burner to the beacon before the passenger ship runs aground. Win: the ship sails safely past and into port.

### Contradictions resolved
- **"Arc lamp head" vs. "burner":** the replacement part is **the burner**, which sits in the beacon's arc lamp. This supersedes the 2026-10-12 resolution that the part is "the arc lamp head". The steam-driven dynamo and electric arc lamp are unchanged.
- **When the broken part is found:** not in the first step. The burner has failed before the game begins, but Ted finds it only after the sailors are in, when the dynamo runs and the beacon stays dark.
- **"Abandoned outpost":** retired. The destination is always the Saltgate (its quays), Saint Calder's abandoned harbour.
- **Fail wording:** the passenger ship "runs aground".

### Flagged items resolved
- **Storm timing:** the outbound crossing is no longer calm. The rain sets in on the outbound crossing, and the storm escalates on the return.
- **Daniel's role while the player is away:** he stays in the basement.

### Edits
- WORLD.md prototype scenario rewritten to the seven beats; the player is named Isaac.
- chr_player, chr_ted, chr_arthur, chr_daniel, reg_bracken_isle, reg_saltgate, reg_gullwater and sys_steam_power updated to match ("lamp head" becomes "burner").

## 2026-10-12: Session 1

### Contradictions resolved
- **"Abandoned outpost" vs. "a port at the edge of the city":** resolved as option B. The Saltgate is the city's own harbour, abandoned as a dead district on the city's edge.
- **Beacon "gas burner" vs. "all lights are steam-driven":** resolved as option B. A steam-driven dynamo powers an electric arc lamp, and the replacement part is the arc lamp head.
- **Ted's navy vs. the Flighted's navy palette:** kept as a deliberate clue. Ted is a potential link to the Flighted.

### Edits
- Ted's term for city folk changed from "modern yuppies" to "new money toffs."

### Names confirmed
| Place | Name |
|---|---|
| Kingdom | Corvaine |
| City | Saint Calder |
| Island | Bracken Isle |
| Harbour | The Saltgate |
| Sea | Gullwater |
| River | The Marrow |
| Mountain | Greymantle |
| Fortresses | Fort Kestrel (west), Fort Heron (east) |

### Flagged (unresolved)
- **Storm timing:** Arthur and Daniel were caught in a storm before the game begins, yet the outbound crossing is calm. Is this a lull between squalls? (Resolved 2026-10-16: the outbound crossing is no longer calm.)
