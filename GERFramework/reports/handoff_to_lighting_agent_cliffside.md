# Handoff: Cliffside Creator Agent to Lighting agent

Creator instruction, 2026-10-20: the Lighting agent takes the fog and distance visibility on the cliffside.

## What the Cliffside agent found (measured from real renders)

- **RETURN phase:** with `hazard_visibility_m` 70 and fog density 0.014, the cliff face disappears beyond about 150 m and reads as a black silhouette, with only the city lights and the trees' edge visible. OUTBOUND is readable.
- No emissive leak and no flat shading on the cliff in OUTBOUND or RETURN.
- Not captured: lightning flashes, BEACON_RELIT.
- The earth path (new) is dark in storm light even after brightening; it needs a little ambient or moonlight pickup so it reads against the grass.

## What the Lighting agent now owns

- Fog and distance-visibility tuning on the cliff line, including the old CLF-11 idea of visibility ranges and a cheaper distant stand-in: if it is done, it must not pop and must keep the cliff silhouette readable from the boat.
- The cliff line is about 700 m long and is in view for the whole crossing.

## Constraints from the Cliffside side

- Do not change cliff material roughness or albedo without telling the Cliffside agent: the walkway uses a copy of the cliff material.
- The sea state is available as `Sea.state` (0 to 5); the creator wants the moon dimmed (cover only) as the return sea rises (Wave plan WAV-14).

Screenshots can be taken with `GERFramework/shoot.sh name x y z tx ty tz [phase] [sea_state]`.
