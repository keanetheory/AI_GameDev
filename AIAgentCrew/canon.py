"""Canon extracted from the Lighting the Storm design documents
(Executive Summary, Technical Strategy, AI Agent Strategy - 1 Oct 2026 review).

Agents receive this text as their source of truth. Edit here if canon changes.
"""

GAME_TITLE = "Lighting the Storm"

PITCH = (
    "Lighting the Storm is a first-person, single-player atmospheric folk-horror adventure "
    "for PC (Godot 4, GDScript). Isaac, the new hand, arrives at the lighthouse on Bracken Isle and "
    "keeper Ted lets him in. He feeds the boiler, opens the island gate for two stranded sailors, "
    "Arthur and Daniel, and then Ted finds the beacon's burner broken. Isaac crosses the Gullwater "
    "with Arthur in the steam launch to fetch a replacement burner from the Saltgate. On the way "
    "back the storm escalates, and he must reach the lighthouse and fit the burner to the beacon "
    "before a passenger ship runs aground."
)

# The creator's canonical story beats (2026-10-16). Every crew, doc and game data set follows this order.
STORY_BEATS = [
    "1. Arrival: the player starts OUTSIDE the lighthouse. Ted opens the door ('You're the new guy, then') "
    "and the player comes into the lighthouse.",
    "2. After a beat, Ted sends the player to the basement to shovel coal into the boiler.",
    "3. Two stranded sailors, Arthur and Daniel, moor at the dock; the player opens the island gate (on the "
    "path from the dock) to let them in. Daniel stays in the basement.",
    "4. The dynamo runs but the beacon stays dark: Ted takes the player up to the lantern room, finds the "
    "burner broken and says a new one is needed.",
    "5. First crossing (OUTBOUND): the player takes the steam launch across the Gullwater with Arthur and "
    "retrieves the replacement burner from the Saltgate quays.",
    "6. The storm escalates (RETURN): darker skies, heavier rain, lightning.",
    "7. The player must get back to the lighthouse and fit the burner to the beacon before the passenger "
    "ship runs aground (BEACON_RELIT).",
]

PILLARS = [
    "1. The light must return - everything leads back to the beacon.",
    "2. The storm sets the clock - pressure comes from the world (ship lights, weather, "
    "visibility, rocks), never a timer, meter or enemy.",
    "3. Your hands, your eyes - everything is first-person and physical; guidance comes from "
    "Ted and Arthur, not markers.",
    "4. Dread you can read - unease and ambiguity, never jump scares; the player always knows "
    "what to do and why they failed (one steering control, clear hazards, fair recoverable "
    "mistakes).",
]

RETURN_CROSSING_RULES = [
    "The return crossing is phase RETURN: burner aboard, Arthur is the only companion.",
    "The hidden ship deadline starts on the return-departure event; it is never shown as a number.",
    "The boat has ONE fixed speed (no throttle) and ONE steering axis.",
    "Hazards are rocks, reefs, buoys and floating debris. Wave hazards are a stretch goal and are NOT approved.",
    "Storm split: hazard density, route width and visibility needed to read hazards follow phase "
    "and ROUTE POSITION only - never elapsed time. Density should rise (never fall) along the route.",
    "The return crossing is harder than the outbound: denser hazards, lower visibility, narrower route.",
    "A minimum visibility of nearby hazards and the immediate route must be preserved on every preset.",
    "Shared hazard forecast: ONE safe-route signal per segment. No route branching (deferred to Gate 2).",
    "Arthur's calls read from the same safe-route signal; his warnings must never disagree with the forecast.",
    "Collisions cost time and recover to a nearby safe point; the burner is never permanently lost.",
    "Docking is automatic inside the lighthouse dock zone (DOCK_LIGHTHOUSE).",
    "On arrival Arthur says something like 'go go go, don't wait for me'.",
    "No visible timer, quest markers, combat, monsters, jump scares or non-first-person cameras.",
    "Do not add significant Saltgate detail; do not invent new major locations.",
]

CHARACTERS = {
    "Arthur": "Older, coarse seaman, the player's companion on both crossings. Reluctant, but he has "
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
    "arthur_calls": "ARTHUR_RET_<segment number>, e.g. ARTHUR_RET_03",
    "dock": "DOCK_LIGHTHOUSE",
    "events": "RETURN_DEPARTED, SEGMENT_ENTERED, HAZARD_COLLISION, RECOVERY, RETURN_ARRIVED",
}


def canon_block() -> str:
    """Render canon as a single block of text for agent prompts."""
    ids = "\n".join(f"- {k}: {v}" for k, v in STABLE_IDS.items())
    chars = "\n".join(f"- {k}: {v}" for k, v in CHARACTERS.items())
    return (
        "STORY BEATS (creator canon, in order):\n" + "\n".join(STORY_BEATS) + "\n\n"
        + f"GAME: {GAME_TITLE}\n{PITCH}\n\nDESIGN PILLARS:\n" + "\n".join(PILLARS)
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
PLAYER_TERM = "Isaac"  # creator decision: how every character refers to the player
MAX_WORDS_PER_LINE = 22

OPENING_SPEAKERS = {
    "TED": "Lighthouse master and the player's boss. Gruff, snarky, old-school; calls city folk 'new money "
           "toffs'; grunts and coughs. Introduces the setting and each objective.",
    "ARTHUR": "Older sailor, wry and frantic under pressure. Friendly but wary. Guides the crossing.",
    "DANIEL": "Younger sailor, light-hearted and anxious. Shelters in the basement and stays there.",
}

# The three dialogue steps cover story beats 1-5 (beats 6-7 belong to the crossing crew and the
# Story / Fail-State agent).
OPENING_STEPS = [
    {"step": 1, "title": "Arrive and feed the boiler", "location": "Outside the lighthouse door, the hall, the basement engine room",
     "player_action": "Wait outside until Ted opens the door, step into the lighthouse, then go down to the basement "
                      "and shovel coal into the boiler until the gauge reaches working pressure.",
     "starts_on": "GAME_STARTED", "ends_on": "BOILER_FED"},
    {"step": 2, "title": "Let the sailors in", "location": "Lighthouse window, the path from the dock, the island gate",
     "player_action": "Notice the moored rowboat, go down the path and open the island gate for the stranded sailors "
                      "Arthur and Daniel. Daniel goes down to the basement and stays there.",
     "starts_on": "SAILORS_MOORED", "ends_on": "DANIEL_IN_BASEMENT"},
    {"step": 3, "title": "Fetch a new burner", "location": "Lantern room, hall, dock, steam launch, the Saltgate quays",
     "player_action": "Follow Ted up to the lantern room, where he finds the burner broken; then board the steam launch "
                      "with Arthur, cross the Gullwater and pick up the replacement burner at the Saltgate quays.",
     "starts_on": "BEACON_STILL_DARK", "ends_on": "RETURN_DEPARTED"},
]

# (event_id, step, note, existing_crew_event). Order matters: the ship may not be named before BOARDING_THRESHOLD.
OPENING_EVENTS = [
    ("GAME_STARTED", 1, "New game begins OUTSIDE the lighthouse; Ted opens the door.", False),
    ("LIGHTHOUSE_ENTERED", 1, "Player steps inside; after a beat Ted sends them to the boiler.", False),
    ("ENGINE_ROOM_ENTERED", 1, "Player enters the basement engine room.", False),
    ("COAL_LOADED_FIRST", 1, "First shovelful lands in the firebox.", False),
    ("COAL_LOADED_HALF", 1, "Steam gauge reaches roughly half.", False),
    ("BOILER_FED", 1, "Gauge reaches working pressure; the dynamo whines (the beacon stays dark).", False),
    ("SAILORS_MOORED", 2, "Rowboat appears moored at the dock (no crash).", False),
    ("WINDOW_LOOKED", 2, "Player looks out of the window at the dock.", False),
    ("GATE_APPROACHED", 2, "Player reaches the island gate.", False),
    ("GATE_OPENED", 2, "Player opens the island gate.", False),
    ("SAILORS_INSIDE", 2, "Arthur and Daniel reach the lighthouse hall.", False),
    ("DANIEL_IN_BASEMENT", 2, "Daniel reaches the basement and stays there.", False),
    ("BEACON_STILL_DARK", 3, "Dynamo running but the beacon stays dark; Ted heads up to the lantern room.", False),
    ("LAMP_ROOM_ENTERED", 3, "Player follows Ted into the lantern room.", False),
    ("BURNER_DIAGNOSED", 3, "Ted opens the arc lamp, finds the burner broken and says a new one is needed.", False),
    ("BURNER_BRIEFING", 3, "Player talks with Ted and Arthur in the hall.", False),
    ("BOARDING_THRESHOLD", 3, "Player reaches the launch at the dock.", False),
    ("SHIP_SIGHTED", 3, "Passenger ship's lights appear on the horizon.", False),
    ("BOAT_CAST_OFF", 3, "Outbound crossing begins (untimed steering practice).", False),
    ("OUTBOUND_NEAR_MISS", 3, "Boat clears a hazard narrowly.", False),
    ("OUTBOUND_COLLISION", 3, "Boat hits a hazard (recoverable).", False),
    ("SALTGATE_REACHED", 3, "Boat docks at the Saltgate quays.", False),
    ("BURNER_PICKED_UP", 3, "Replacement burner is aboard.", False),
    ("RETURN_DEPARTED", 3, "Existing crew event. Hands over to ARTHUR_RET_* calls.", True),
    ("POSTER_EXAMINED", 0, "Optional: player examines a Flighted poster.", False),
    ("WALL_WHISPER_HEARD", 0, "Optional: whisper in the lighthouse walls.", False),
    ("BASEMENT_BANG", 0, "Optional: bang in the basement wall.", False),
    ("BASEMENT_TALK", 0, "Optional: player stands near Daniel.", False),
    ("IDLE_STEP_1", 1, "Player has made no progress on step 1.", False),
    ("IDLE_STEP_2", 2, "Player has made no progress on step 2.", False),
    ("IDLE_STEP_3", 3, "Player has made no progress on step 3 (reaching the dock).", False),
    ("IDLE_SALTGATE", 3, "Player has not found the burner at the Saltgate quays.", False),
]

SHIP_NAMED_FROM = "BOARDING_THRESHOLD"  # Exec Summary: the ship is introduced at the boarding threshold

OPENING_DIALOGUE_RULES = [
    f"Refer to the player only as '{PLAYER_TERM}' (never 'apprentice'). The player never speaks.",
    "The game starts outside the lighthouse: Ted opens the door and greets Isaac as the new guy, then, once "
    "Isaac is inside, introduces the setting (storm season, the Saltgate) and each step's objective.",
    "Step 1: shovel coal into the boiler in the basement engine room. Step 2: let the stranded sailors in "
    "through the island gate. Step 3: Ted finds the burner broken in the lantern room (only after the sailors "
    "are in), then Isaac retrieves the replacement from the Saltgate quays across the Gullwater.",
    "The burner is found broken in step 3, never in step 1. The destination is the Saltgate, never 'the outpost'.",
    "Ted never names the passenger ship before the boarding threshold (BOARDING_THRESHOLD).",
    "Say 'burner', never 'lamp head'. No timers, countdowns, numbers or deadline talk.",
    "Never confirm a supernatural cause. Flighted and wall-whisper details stay ambiguous.",
    "Do not address the player as lad, lass or man. Ted's 'the boy' means Daniel.",
    "Add no significant Saltgate detail. Daniel stays in the basement.",
    "Reuse the canon sample lines where they fit. Lines stay short enough to shout over a storm.",
    "Every IDLE_* event gets a nudge ladder of consecutive tiers (hint, sharper, explicit).",
    "Alternates share a group and a trigger; every group has at least two options.",
]

OPENING_OPEN_DECISIONS = [
    "Which lines are voiced is a cost decision; subtitles exist for every line.",
    "Why Arthur and Daniel were on the water (smugglers?) is left open.",
    "Ted and Arthur's relationship is TBD in the lore; the 'drowned by now' exchange is a proposal.",
    "Fail-reason and outcome lines belong to the Story / Fail-State agent.",
]


def dialogue_canon_block() -> str:
    """Canon text for the dialogue agents (the crossing canon_block stays untouched)."""
    voices = "\n".join(f"- {k}: {v}" for k, v in OPENING_SPEAKERS.items())
    return (
        "STORY BEATS (creator canon, in order):\n" + "\n".join(STORY_BEATS) + "\n\n"
        + f"GAME: {GAME_TITLE}\n{PITCH}\n\nDESIGN PILLARS:\n" + "\n".join(PILLARS)
        + f"\n\nVOICES:\n{voices}\n\nDIALOGUE RULES (canon, Decisions log):\n"
        + "\n".join(f"- {r}" for r in OPENING_DIALOGUE_RULES)
        + "\n\nOPEN CREATOR DECISIONS (do not decide these):\n"
        + "\n".join(f"- {d}" for d in OPENING_OPEN_DECISIONS)
    )
