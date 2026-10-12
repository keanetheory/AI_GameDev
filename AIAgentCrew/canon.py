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


# ---------------------------------------------------------------------------------------------
# Opening dialogue (Gate 1 slice, steps 1-3). Used by the Dialogue task in dialogue_crew.py.
# Sources: Exec Summary (step table, ship reveal at the boarding threshold, apprentice never
# speaks) and the Lore Build character files (voices, colours, sample lines).
# ---------------------------------------------------------------------------------------------
PLAYER_TERM = "the new guy"  # creator decision: how every character refers to the player
MAX_WORDS_PER_LINE = 22

OPENING_SPEAKERS = {
    "TED": "Lighthouse master and the player's boss. Gruff, snarky, old-school; calls city folk 'new money "
           "toffs'; grunts and coughs. Introduces the setting and each objective.",
    "JEFF": "Older sailor, wry and frantic under pressure. Friendly but wary. Guides the crossing.",
    "DANIEL": "Younger sailor, light-hearted and anxious. Shelters in the basement and stays there.",
}

OPENING_STEPS = [
    {"step": 1, "title": "Feed the boiler", "location": "Engine room (basement), then lantern room",
     "player_action": "Shovel coal into the boiler, then find the beacon's burner is broken.",
     "starts_on": "GAME_STARTED", "ends_on": "BURNER_DIAGNOSED"},
    {"step": 2, "title": "Let the sailors in", "location": "Lantern-room window, path, island gate",
     "player_action": "Look out of the window, go down the path and open the gate for Jeff and Daniel.",
     "starts_on": "SAILORS_MOORED", "ends_on": "DANIEL_IN_BASEMENT"},
    {"step": 3, "title": "Fetch the burner", "location": "Dock, steam launch, outpost",
     "player_action": "Board the launch with Jeff, cross the Gullwater and pick up the replacement burner.",
     "starts_on": "BURNER_BRIEFING", "ends_on": "RETURN_DEPARTED"},
]

# (event_id, step, note, existing_crew_event). Order matters: the ship may not be named before BOARDING_THRESHOLD.
OPENING_EVENTS = [
    ("GAME_STARTED", 1, "New game begins at the lighthouse entrance.", False),
    ("ENGINE_ROOM_ENTERED", 1, "Player enters the basement engine room.", False),
    ("COAL_LOADED_FIRST", 1, "First shovelful lands in the firebox.", False),
    ("COAL_LOADED_HALF", 1, "Steam gauge reaches roughly half.", False),
    ("BOILER_FED", 1, "Gauge reaches working pressure; dynamo whines, beacon flickers.", False),
    ("LAMP_ROOM_ENTERED", 1, "Player enters the lantern room.", False),
    ("BURNER_DIAGNOSED", 1, "Player inspects the arc lamp and finds the burner broken.", False),
    ("SAILORS_MOORED", 2, "Rowboat appears moored at the dock (no crash).", False),
    ("WINDOW_LOOKED", 2, "Player looks out of the window at the dock.", False),
    ("GATE_APPROACHED", 2, "Player reaches the island gate.", False),
    ("GATE_OPENED", 2, "Player opens the island gate.", False),
    ("SAILORS_INSIDE", 2, "Jeff and Daniel reach the lighthouse hall.", False),
    ("DANIEL_IN_BASEMENT", 2, "Daniel reaches the basement and stays there.", False),
    ("BURNER_BRIEFING", 3, "Player talks with Ted and Jeff in the hall.", False),
    ("BOARDING_THRESHOLD", 3, "Player reaches the launch at the dock.", False),
    ("SHIP_SIGHTED", 3, "Passenger ship's lights appear on the horizon.", False),
    ("BOAT_CAST_OFF", 3, "Outbound crossing begins (untimed steering practice).", False),
    ("OUTBOUND_NEAR_MISS", 3, "Boat clears a hazard narrowly.", False),
    ("OUTBOUND_COLLISION", 3, "Boat hits a hazard (recoverable).", False),
    ("OUTPOST_REACHED", 3, "Boat docks at the abandoned outpost.", False),
    ("BURNER_PICKED_UP", 3, "Replacement burner is aboard.", False),
    ("RETURN_DEPARTED", 3, "Existing crew event. Hands over to JEFF_RET_* calls.", True),
    ("POSTER_EXAMINED", 0, "Optional: player examines a Flighted poster.", False),
    ("WALL_WHISPER_HEARD", 0, "Optional: whisper in the lighthouse walls.", False),
    ("BASEMENT_BANG", 0, "Optional: bang in the basement wall.", False),
    ("BASEMENT_TALK", 0, "Optional: player stands near Daniel.", False),
    ("IDLE_STEP_1", 1, "Player has made no progress on step 1.", False),
    ("IDLE_STEP_2", 2, "Player has made no progress on step 2.", False),
    ("IDLE_STEP_3", 3, "Player has made no progress on step 3 (reaching the dock).", False),
    ("IDLE_OUTPOST", 3, "Player has not found the burner at the outpost.", False),
]

SHIP_NAMED_FROM = "BOARDING_THRESHOLD"  # Exec Summary: the ship is introduced at the boarding threshold

OPENING_DIALOGUE_RULES = [
    f"Refer to the player only as '{PLAYER_TERM}' (never 'apprentice'). The player never speaks.",
    "Ted introduces the setting (eclipse, storm season, the Saltgate) and each step's objective.",
    "Step 1: shovel coal into the boiler in the basement engine room. Step 2: let the stranded sailors in "
    "through the island gate. Step 3: retrieve the replacement burner from the outpost across the Gullwater.",
    "Ted never names the passenger ship before the boarding threshold (BOARDING_THRESHOLD).",
    "Say 'burner', never 'lamp head'. No timers, countdowns, numbers or deadline talk.",
    "Never confirm a supernatural cause. Flighted and wall-whisper details stay ambiguous.",
    "Do not address the player as lad, lass or man. Ted's 'the boy' means Daniel.",
    "Add no significant outpost detail. Daniel stays in the basement.",
    "Reuse the canon sample lines where they fit. Lines stay short enough to shout over a storm.",
    "Every IDLE_* event gets a nudge ladder of consecutive tiers (hint, sharper, explicit).",
    "Alternates share a group and a trigger; every group has at least two options.",
]

OPENING_OPEN_DECISIONS = [
    "Which lines are voiced is a cost decision; subtitles exist for every line.",
    "Why Jeff and Daniel were on the water (smugglers?) is left open.",
    "Ted and Jeff's relationship is TBD in the lore; the 'drowned by now' exchange is a proposal.",
    "Fail-reason and outcome lines belong to the Story / Fail-State agent.",
]


def dialogue_canon_block() -> str:
    """Canon text for the dialogue agents (the crossing canon_block stays untouched)."""
    voices = "\n".join(f"- {k}: {v}" for k, v in OPENING_SPEAKERS.items())
    return (
        f"GAME: {GAME_TITLE}\n{PITCH}\n\nDESIGN PILLARS:\n" + "\n".join(PILLARS)
        + f"\n\nVOICES:\n{voices}\n\nDIALOGUE RULES (canon, Decisions log):\n"
        + "\n".join(f"- {r}" for r in OPENING_DIALOGUE_RULES)
        + "\n\nOPEN CREATOR DECISIONS (do not decide these):\n"
        + "\n".join(f"- {d}" for d in OPENING_OPEN_DECISIONS)
    )
