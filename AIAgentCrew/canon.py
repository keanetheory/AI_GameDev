"""Canon extracted from the Lighting the Storm design documents
(Executive Summary, Technical Strategy, AI Agent Strategy - 1 Oct 2026 review).

Agents receive this text as their source of truth. Edit here if canon changes.
"""

GAME_TITLE = "Lighting the Storm"

PITCH = (
    "Lighting the Storm is a first-person, single-player atmospheric folk-horror adventure "
    "for PC (Godot 4, GDScript). A new apprentice repairs the failing lighthouse on Bracken "
    "Isle with keeper Ted. Sailors Jeff and Daniel moor on the island seeking shelter. Jeff "
    "crosses the water with the apprentice in a powered engine boat to fetch a replacement "
    "beacon burner from an abandoned outpost. The player must bring it back and relight the "
    "beacon before a passenger ship reaches the rocks."
)

PILLARS = [
    "1. The light must return - everything leads back to the beacon.",
    "2. The storm sets the clock - pressure comes from the world (ship lights, weather, "
    "visibility, rocks), never a timer, meter or enemy.",
    "3. Your hands, your eyes - everything is first-person and physical; guidance comes from "
    "Ted and Jeff, not markers.",
    "4. Dread you can read - unease and ambiguity, never jump scares; the player always knows "
    "what to do and why they failed (one steering control, clear hazards, fair recoverable "
    "mistakes).",
]

RETURN_CROSSING_RULES = [
    "The return crossing is phase RETURN: burner aboard, Jeff is the only companion.",
    "The hidden ship deadline starts on the return-departure event; it is never shown as a number.",
    "The boat has ONE fixed speed (no throttle) and ONE steering axis.",
    "Hazards are rocks, reefs, buoys and floating debris. Wave hazards are a stretch goal and are NOT approved.",
    "Storm split: hazard density, route width and visibility needed to read hazards follow phase "
    "and ROUTE POSITION only - never elapsed time. Density should rise (never fall) along the route.",
    "The return crossing is harder than the outbound: denser hazards, lower visibility, narrower route.",
    "A minimum visibility of nearby hazards and the immediate route must be preserved on every preset.",
    "Shared hazard forecast: ONE safe-route signal per segment. No route branching (deferred to Gate 2).",
    "Jeff's calls read from the same safe-route signal; his warnings must never disagree with the forecast.",
    "Collisions cost time and recover to a nearby safe point; the burner is never permanently lost.",
    "Docking is automatic inside the lighthouse dock zone (DOCK_LIGHTHOUSE).",
    "On arrival Jeff says something like 'go go go, don't wait for me'.",
    "No visible timer, quest markers, combat, monsters, jump scares or non-first-person cameras.",
    "Do not add significant outpost detail; do not invent new major locations.",
]

CHARACTERS = {
    "Jeff": "Older, coarse seaman, the player's companion on both crossings. Reluctant, but he has "
            "realised the storm is turning nasty and wants to stop the ship being wrecked. Shouts "
            "short, practical directions over the wind.",
    "Ted": "Gruff keeper, staged at the lamp in the second half. Not present on the boat.",
    "Apprentice": "The player. Never speaks.",
}

OPEN_DECISIONS = [
    "Exact crossing penalty costs are loose for Gate 1 and must be written down for the full game.",
    "Deadline length is reviewed once the return crossing has been tested.",
    "Whether pausing can be exploited (before Gate 2).",
    "Final retry and save model (before Gate 2).",
]

STABLE_IDS = {
    "phase": "RETURN",
    "segments": "SEG_01, SEG_02 ... (two digits)",
    "hazards": "HZ_<segment number>_<index>, e.g. HZ_03_02",
    "safe_points": "SAFE_<segment number>, e.g. SAFE_03",
    "jeff_calls": "JEFF_RET_<segment number>, e.g. JEFF_RET_03",
    "dock": "DOCK_LIGHTHOUSE",
    "events": "RETURN_DEPARTED, SEGMENT_ENTERED, HAZARD_COLLISION, RECOVERY, RETURN_ARRIVED",
}


def canon_block() -> str:
    """Render canon as a single block of text for agent prompts."""
    ids = "\n".join(f"- {k}: {v}" for k, v in STABLE_IDS.items())
    chars = "\n".join(f"- {k}: {v}" for k, v in CHARACTERS.items())
    return (
        f"GAME: {GAME_TITLE}\n{PITCH}\n\nDESIGN PILLARS:\n" + "\n".join(PILLARS)
        + "\n\nRETURN CROSSING RULES (canon, Decisions log):\n"
        + "\n".join(f"- {r}" for r in RETURN_CROSSING_RULES)
        + f"\n\nCHARACTERS:\n{chars}\n\nSTABLE IDS:\n{ids}\n\nOPEN CREATOR DECISIONS (do not decide these):\n"
        + "\n".join(f"- {d}" for d in OPEN_DECISIONS)
    )
