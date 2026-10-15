# REPORT - WORLD SPECS

**What was delegated:** boat spec (Boat / Physics agent), player movement spec (Player Movement agent), lighting spec (Lighting agent), canon review (Canon and Review Orchestrator).

**What passed review:** 9 pillar and Decisions-log checks, plus every deterministic check.

**What failed and why:** Nothing in the final output (guardrail retries are in the console log).

**What remains:** build the Tide / Wave agent after the traversable Godot level exists; playtest; creator decisions below.

**Creator decisions that are blocking:**
- Whether the earlier return-crossing data (6 m/s) should be regenerated at the confirmed 3 m/s.
- Whether Arthur, as a passenger, moves around the boat while it is steered.
- How bright the eclipsed moon's silver rim may be.
- Whether Saint Calder should flicker or stay fully steady.
- Whether to add controller support at Gate 1.
- Whether sprint is allowed inside the lighthouse.
