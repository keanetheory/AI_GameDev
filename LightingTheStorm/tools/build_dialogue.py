"""Builds the opening-dialogue data for Lighting the Storm (Gate 1 slice, steps 1-3).

Source of truth is this file. It writes:
  data/dialogue/dialogue_opening.json   -> loaded by Godot 4 (scripts/dialogue/dialogue_loader.gd)
  ../Docs/Lore Build/dialogue/DIALOGUE_OPENING.md -> creator review list (voice + lore approval)

Rules enforced here come from the Agent Crew canon (canon.py, validators.py) and the
Executive Summary: stable IDs, 'NAME: ' subtitles, short shouted lines, no timer words,
no confirmed supernatural cause, the player ("the new guy") never speaks, no visible markers.

SUPERSEDED: this was the first authoring script. The same checks now live in
Agent Crew/storm_crew/storm_crew/validators.py and the Opening Dialogue Crew
(main_dialogue.py) writes the game data. Running this overwrites the crew's output, so it
needs --force.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent            # LightingTheStorm/
DOCS = ROOT.parent / "Docs" / "Lore Build" / "dialogue"
OUT_JSON = ROOT / "data" / "dialogue" / "dialogue_opening.json"
OUT_MD = DOCS / "DIALOGUE_OPENING.md"

MAX_WORDS = 22
BANNED = re.compile(r"\b(seconds?|minutes?|hours?|countdown|timer|clock|deadline)\b|\d", re.I)

SPEAKERS = {
    "TED": {"name": "Ted", "colour": "#1F2A44", "role": "Lighthouse master (boss)"},
    "JEFF": {"name": "Jeff", "colour": "#2F4A34", "role": "Sailor, guides the crossing"},
    "DANIEL": {"name": "Daniel", "colour": "#7A2620", "role": "Young sailor, shelters in the basement"},
}

STEPS = [
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

# (id, step, emitted_by, note, existing)
EVENTS = [
    ("GAME_STARTED", 1, "Gameplay / Systems", "New game begins at the lighthouse entrance.", False),
    ("ENGINE_ROOM_ENTERED", 1, "Level Layout anchor", "Player enters the basement engine room.", False),
    ("COAL_LOADED_FIRST", 1, "Gameplay / Systems", "First shovelful lands in the firebox.", False),
    ("COAL_LOADED_HALF", 1, "Gameplay / Systems", "Steam gauge reaches roughly half.", False),
    ("BOILER_FED", 1, "Gameplay / Systems", "Gauge reaches working pressure; dynamo whines, beacon flickers.", False),
    ("LAMP_ROOM_ENTERED", 1, "Level Layout anchor", "Player enters the lantern room.", False),
    ("BURNER_DIAGNOSED", 1, "Gameplay / Systems", "Player inspects the arc lamp and finds the burner broken.", False),
    ("SAILORS_MOORED", 2, "Gameplay / Systems", "Rowboat appears moored at the dock (no crash).", False),
    ("WINDOW_LOOKED", 2, "Level Layout anchor", "Player looks out of the window at the dock.", False),
    ("GATE_APPROACHED", 2, "Level Layout anchor", "Player reaches the island gate.", False),
    ("GATE_OPENED", 2, "Gameplay / Systems", "Player opens the island gate.", False),
    ("SAILORS_INSIDE", 2, "Gameplay / Systems", "Jeff and Daniel reach the lighthouse hall.", False),
    ("DANIEL_IN_BASEMENT", 2, "Gameplay / Systems", "Daniel reaches the basement and stays there.", False),
    ("BURNER_BRIEFING", 3, "Gameplay / Systems", "Player talks with Ted and Jeff in the hall.", False),
    ("BOARDING_THRESHOLD", 3, "Level Layout anchor", "Player reaches the launch at the dock.", False),
    ("SHIP_SIGHTED", 3, "Story / Fail-State", "Passenger ship's lights appear on the horizon.", False),
    ("BOAT_CAST_OFF", 3, "Boat / Physics", "Outbound crossing begins (untimed steering practice).", False),
    ("OUTBOUND_NEAR_MISS", 3, "Boat / Physics", "Boat clears a hazard narrowly.", False),
    ("OUTBOUND_COLLISION", 3, "Boat / Physics", "Boat hits a hazard (recoverable).", False),
    ("OUTPOST_REACHED", 3, "Level Layout anchor", "Boat docks at the abandoned outpost.", False),
    ("BURNER_PICKED_UP", 3, "Gameplay / Systems", "Replacement burner is aboard.", False),
    ("RETURN_DEPARTED", 3, "Gameplay / Systems", "Existing crew event. Hands over to JEFF_RET_* calls.", True),
    ("POSTER_EXAMINED", 0, "Interaction anchor", "Optional: player examines a Flighted poster.", False),
    ("WALL_WHISPER_HEARD", 0, "Audio trigger", "Optional: whisper in the lighthouse walls.", False),
    ("BASEMENT_BANG", 0, "Audio trigger", "Optional: bang in the basement wall.", False),
    ("BASEMENT_TALK", 0, "Interaction anchor", "Optional: player stands near Daniel.", False),
    ("IDLE_STEP_1", 1, "Dialogue loader", "Player has made no progress on step 1 (call loader.idle).", False),
    ("IDLE_STEP_2", 2, "Dialogue loader", "Player has made no progress on step 2.", False),
    ("IDLE_STEP_3", 3, "Dialogue loader", "Player has made no progress on step 3 (reaching the dock).", False),
    ("IDLE_OUTPOST", 3, "Dialogue loader", "Player has not found the burner at the outpost.", False),
]

LINES = []


def L(id, step, beat, speaker, kind, trigger, text, delivery, **kw):
    LINES.append({"line_id": id, "step": step, "beat": beat, "speaker": speaker, "kind": kind,
                  "trigger": trigger, "text": text, "delivery": delivery, **kw})


# ============================ STEP 1 - FEED THE BOILER ============================
B = "S1_WELCOME"
L("TED_S1_01", 1, B, "TED", "intro", "GAME_STARTED",
  "Hrmph. You're the new guy. Welcome to Bracken Isle. Try not to fall off it.",
  "gruff, dry; a cough after")
L("TED_S1_02", 1, B, "TED", "setting", "GAME_STARTED",
  "No moon tonight. Something's sat on it again, and the sea hates it. Tides go savage, storms follow.",
  "flat, matter-of-fact; he has said this before", pause_before=0.8)
L("TED_S1_03", 1, B, "TED", "setting", "GAME_STARTED",
  "Across the water's the Saltgate. Dead harbour. The new money toffs in Saint Calder won't say why.",
  "bitter on 'new money toffs'", pause_before=0.6)
L("TED_S1_04", 1, B, "TED", "setting", "GAME_STARTED",
  "Out here, my light's all that keeps ships off the rocks. Which is why it had better work.",
  "gruff, a grunt on the last clause", pause_before=0.6)
L("TED_S1_05", 1, B, "TED", "objective", "GAME_STARTED",
  "Beacon runs on steam, steam runs on coal. Get down to the basement engine room and feed that boiler.",
  "barked order", pause_before=0.6,
  assist_text="Go down to the basement engine room. Take the shovel, scoop coal from the heap and load the boiler.",
  journal_id="JRN_01")

B = "S1_NUDGE"
L("TED_S1_N1", 1, B, "TED", "nudge", "IDLE_STEP_1",
  "Well? Basement. Boiler. Coal. It's not complicated.", "impatient", tier=1, once=False)
L("TED_S1_N2", 1, B, "TED", "nudge", "IDLE_STEP_1",
  "What are you looking at, you a new money toff?? Get off your arse and sort out the light!",
  "shouted; canon sample line", tier=2, once=False)
L("TED_S1_N3", 1, B, "TED", "nudge", "IDLE_STEP_1",
  "Stairs down, shovel by the coal heap, coal into the boiler. Slowly, if you must.",
  "weary, spelling it out", tier=3, once=False)

B = "S1_ENGINE"
L("TED_S1_06", 1, B, "TED", "reaction", "ENGINE_ROOM_ENTERED",
  "That big iron beast with the fire in it is the boiler. Shovel's by the heap.",
  "shouted down the stairwell", staging="Ted is above; his voice carries down the stairs.")
L("TED_S1_07", 1, B, "TED", "objective", "COAL_LOADED_FIRST",
  "Good. Keep feeding her. Watch the gauge needle. It climbs when she's happy.",
  "grudging approval", assist_text="Keep shovelling until the steam gauge needle reaches the marked band.")
L("TED_S1_08a", 1, B, "TED", "reaction", "COAL_LOADED_HALF", "Keep going. She's thirsty.",
  "short, gruff", group="S1_HALF")
L("TED_S1_08b", 1, B, "TED", "reaction", "COAL_LOADED_HALF", "More. A boiler's like a sailor. Never full.",
  "dry joke, a grunt after", group="S1_HALF")
L("TED_S1_09a", 1, B, "TED", "objective", "BOILER_FED",
  "There she goes! Hear the dynamo whine? Steam's up. Now get up to the lantern room.",
  "pleased, then barked", group="S1_FED", journal_id="JRN_02",
  assist_text="Climb the stairs to the lantern room at the top of the lighthouse.")
L("TED_S1_09b", 1, B, "TED", "objective", "BOILER_FED",
  "Not bad for a new money toff. Steam's up. Lantern room, now, and mind the stairs.",
  "reluctant praise", group="S1_FED", journal_id="JRN_02",
  assist_text="Climb the stairs to the lantern room at the top of the lighthouse.")

B = "S1_LAMP"
L("TED_S1_10", 1, B, "TED", "objective", "LAMP_ROOM_ENTERED",
  "See that? Flickering like a wet match. Steam's good, so the fault's in the lamp. Take a proper look.",
  "pointing, grim", assist_text="Walk up to the arc lamp and inspect the burner at its centre.",
  staging="Ted is standing at the lamp.")
L("TED_S1_11", 1, B, "TED", "reaction", "BURNER_DIAGNOSED",
  "Cracked glass, rods burnt to stubs. That burner's finished. Hrmph. And I've no spare.",
  "quiet, then a grunt", journal_id="JRN_03")
L("TED_S1_12", 1, B, "TED", "reaction", "BURNER_DIAGNOSED",
  "No burner, no light. No light, and the rocks do what rocks do.",
  "gallows humour, deadpan", pause_before=1.0)

# ============================ STEP 2 - LET THE SAILORS IN ============================
B = "S2_WINDOW"
L("TED_S2_01", 2, B, "TED", "objective", "SAILORS_MOORED",
  "Oi! Window! There's a rowboat tied up at the dock. Two men, soaked to the bone.",
  "sudden, urgent", pause_before=1.5, assist_text="Walk to the lantern room window and look at the dock.",
  staging="Ted is already at the window and sees the rowboat first.")
L("TED_S2_02", 2, B, "TED", "objective", "WINDOW_LOOKED",
  "Fools, out in this. They'll want shelter, and the only way up is the gate. Go down and open it.",
  "gruff, then an order", journal_id="JRN_04",
  assist_text="Leave the lighthouse, follow the path down to the iron gate and open it.")

B = "S2_NUDGE"
L("TED_S2_N1", 2, B, "TED", "nudge", "IDLE_STEP_2",
  "The gate, new guy. Those two won't dry themselves on the dock.", "impatient", tier=1, once=False)
L("TED_S2_N2", 2, B, "TED", "nudge", "IDLE_STEP_2",
  "Down the path to the iron gate. Open it. The sea isn't polite.", "sharper", tier=2, once=False)
L("TED_S2_N3", 2, B, "TED", "nudge", "IDLE_STEP_2",
  "Out the door, down the path, iron gate. Open it. Go.", "bellowed", tier=3, once=False)

B = "S2_GATE"
L("JEFF_S2_01a", 2, B, "JEFF", "reaction", "GATE_APPROACHED",
  "Open the gate, would you? I've been wet since breakfast and I'm starting to take it personally!",
  "shouted over the wind, wry", group="S2_GATE_JEFF")
L("JEFF_S2_01b", 2, B, "JEFF", "reaction", "GATE_APPROACHED",
  "Oi! Gate! Open up before the sea finishes what the storm started!",
  "shouted, frantic", group="S2_GATE_JEFF")
L("DANIEL_S2_01", 2, B, "DANIEL", "reaction", "GATE_APPROACHED",
  "Please! My hands have gone numb and I think my boots are full of fish!",
  "high, anxious, a nervous laugh", pause_before=0.5)
L("JEFF_S2_02", 2, B, "JEFF", "reaction", "GATE_OPENED",
  "Bless you. You'll be Ted's new guy, then. Jeff. The shivering one's Daniel.",
  "friendly but wary", pause_before=0.6)
L("DANIEL_S2_02", 2, B, "DANIEL", "reaction", "GATE_OPENED",
  "Thank you, thank you! This was my first trip out. I might just stay on this flipping lighthouse!",
  "light-hearted, anxious; canon sample line", pause_before=0.4)
L("JEFF_S2_03", 2, B, "JEFF", "reaction", "GATE_OPENED",
  "Don't ask what we were doing out there. Ask me when I'm dry.",
  "evasive, a snort", pause_before=0.8,
  note="Open hook: why Jeff and Daniel were on the water in eclipse season. Not answered.")

B = "S2_HALL"
L("TED_S2_03", 2, B, "TED", "reaction", "SAILORS_INSIDE", "Jeff. Thought you'd have drowned by now.",
  "dry", note="Ted and Jeff's relationship is TBD in the lore; this keeps it neutral.")
L("JEFF_S2_04", 2, B, "JEFF", "reaction", "SAILORS_INSIDE",
  "Lovely to see you too, Ted. Still charming the guests, I see.", "wry", pause_before=0.5)
L("TED_S2_04", 2, B, "TED", "reaction", "SAILORS_INSIDE",
  "Warm's down in the engine room. Take the boy and dry out. Don't touch my boiler.",
  "gruff, to Daniel", pause_before=0.5, journal_id="JRN_05")
L("DANIEL_S2_03", 2, B, "DANIEL", "reaction", "DANIEL_IN_BASEMENT",
  "Oh, it's warm. It's lovely. Nobody mind me. I'm staying right here.",
  "relieved, slightly giddy", staging="Daniel stays in the basement for the rest of the slice.")

# ============================ STEP 3 - FETCH THE BURNER ============================
B = "S3_BRIEFING"
L("TED_S3_01", 3, B, "TED", "setting", "BURNER_BRIEFING",
  "Now listen. The burner's gone and I've no spare. There's one at the old outpost across the Gullwater.",
  "serious, gruff",
  staging="Ted talks with the player in the hall.")
L("TED_S3_02", 3, B, "TED", "setting", "BURNER_BRIEFING",
  "Small thing, under a foot tall. Brass and iron, thick glass, carbon rods. Can't miss it.",
  "gruff, describing with his hands", pause_before=0.6)
L("TED_S3_03", 3, B, "TED", "objective", "BURNER_BRIEFING",
  "Launch is at the dock. Jeff knows that water better than I do. Go with him and do as he says.",
  "an order, a cough", pause_before=0.6, journal_id="JRN_06",
  assist_text="Go to the dock and board the steam launch with Jeff.")
L("JEFF_S3_01a", 3, B, "JEFF", "reaction", "BURNER_BRIEFING",
  "Cross the Gullwater? In this? Hrmph. Fine. That sky's turning nasty, and somebody has to do it.",
  "reluctant, then resolved", pause_before=0.8, group="S3_JEFF_AGREES")
L("JEFF_S3_01b", 3, B, "JEFF", "reaction", "BURNER_BRIEFING",
  "Back out there? I've only just got dry! ...Aye, all right. Better the light's mended than we're sorry.",
  "groaning, then resolved", pause_before=0.8, group="S3_JEFF_AGREES")

B = "S3_NUDGE"
L("TED_S3_N1", 3, B, "TED", "nudge", "IDLE_STEP_3",
  "Dock. Launch. Jeff's waiting, and he's not known for patience.", "impatient", tier=1, once=False)
L("TED_S3_N2", 3, B, "TED", "nudge", "IDLE_STEP_3",
  "Down the path, through the gate you opened, to the jetty. Steam launch.", "sharper", tier=2, once=False)
L("TED_S3_N3", 3, B, "TED", "nudge", "IDLE_STEP_3",
  "Jetty. Launch. Burner. In that order.", "flat, final", tier=3, once=False)

B = "S3_BOARDING"
L("JEFF_S3_02", 3, B, "JEFF", "reaction", "BOARDING_THRESHOLD", "In you get. Mind the rail. It bites.",
  "brisk, from the launch")
L("TED_S3_04", 3, B, "TED", "reaction", "BOARDING_THRESHOLD",
  "Wait! Look out on the water! Lights! That's a passenger ship!",
  "shouted, carried on the wind", pause_before=1.2,
  staging="Shouted from the lighthouse; the ship's lights appear as he speaks.")
L("TED_S3_05", 3, B, "TED", "reaction", "SHIP_SIGHTED",
  "What the hell is a passenger ship doing coming here, now?? It's not in the log!",
  "shocked; canon sample line")
L("JEFF_S3_03", 3, B, "JEFF", "reaction", "SHIP_SIGHTED",
  "A passenger ship? NOW? But the lighthouse beacon is broken!",
  "frantic; canon sample line shared with Ted", pause_before=0.6)
L("TED_S3_06", 3, B, "TED", "objective", "SHIP_SIGHTED",
  "She's making for the Saltgate. Without my light she'll find the reef instead. Get me that burner!",
  "bellowed", pause_before=0.8)
L("JEFF_S3_04", 3, B, "JEFF", "reaction", "SHIP_SIGHTED",
  "Right. That settles it. Cast off, and hold on to something.", "grim, resolved", pause_before=0.6)

B = "S3_OUTBOUND"
L("JEFF_S3_05", 3, B, "JEFF", "objective", "BOAT_CAST_OFF",
  "One wheel, one speed. She goes where you point her, and not a yard faster. Mind the rocks.",
  "shouted over the engine", journal_id="JRN_07",
  assist_text="Steer left and right to keep clear of rocks. The boat's speed is fixed. Head for the outpost.")
L("JEFF_S3_06", 3, B, "JEFF", "reaction", "BOAT_CAST_OFF",
  "Easy does it. Get the feel of her.", "calmer, for now", pause_before=4.0)
L("JEFF_S3_N1a", 3, B, "JEFF", "reaction", "OUTBOUND_NEAR_MISS",
  "Close! Another hand's width and we'd be lunch for the reef!", "shouted", group="S3_NEAR", once=False)
L("JEFF_S3_N1b", 3, B, "JEFF", "reaction", "OUTBOUND_NEAR_MISS",
  "Steady! That rock didn't move. You did.", "shouted, dry", group="S3_NEAR", once=False)
L("JEFF_S3_C1a", 3, B, "JEFF", "reaction", "OUTBOUND_COLLISION",
  "Ugh! Gently! She's a boat, not a battering ram!", "pained", group="S3_HIT", once=False)
L("JEFF_S3_C1b", 3, B, "JEFF", "reaction", "OUTBOUND_COLLISION",
  "That's the rocks saying hello. Back on course!", "wry, then urgent", group="S3_HIT", once=False)

B = "S3_OUTPOST"
L("JEFF_S3_07", 3, B, "JEFF", "objective", "OUTPOST_REACHED",
  "That's the outpost. Find the burner. Brass, glass, under a foot tall. I'll hold the boat.",
  "brisk", assist_text="Search the outpost for the replacement burner. It is small, brass and glass.")
L("JEFF_S3_N2", 3, B, "JEFF", "nudge", "IDLE_OUTPOST",
  "It's small, it's brass, and it won't find itself.", "impatient", tier=1, once=False)
L("JEFF_S3_N3", 3, B, "JEFF", "nudge", "IDLE_OUTPOST",
  "Look about, new guy. Brass and glass, under a foot tall.", "sharper", tier=2, once=False)
L("JEFF_S3_08", 3, B, "JEFF", "reaction", "BURNER_PICKED_UP",
  "That's the one! Hold it tight. Aboard, and we go back.", "relieved, urgent",
  note="Hands over to the Agent Crew's JEFF_RET_* calls at RETURN_DEPARTED.")

# ============================ OPTIONAL DISCOVERIES (no step) ============================
B = "OPT"
L("TED_OPT_01", 0, B, "TED", "discovery", "POSTER_EXAMINED",
  "Hrmph. Leave that. Old paper, older than my knees.", "too quick, evasive",
  note="Ted's link to the Flighted is undecided. This hints without answering.")
L("TED_OPT_02", 0, B, "TED", "discovery", "WALL_WHISPER_HEARD",
  "Wind in the walls. Always is. Ignore it.", "flat, a beat too fast")
L("DANIEL_OPT_01", 0, B, "DANIEL", "discovery", "BASEMENT_BANG",
  "Did the wall just... no. No, it's the boiler. It's definitely the boiler.", "anxious, talking himself round")
L("DANIEL_OPT_02", 0, B, "DANIEL", "reaction", "BASEMENT_TALK",
  "Best seat in the house, this. Warm, dry, and only mildly creaky.", "light-hearted", group="DAN_TALK", once=False)
L("DANIEL_OPT_03", 0, B, "DANIEL", "reaction", "BASEMENT_TALK",
  "Don't mind me. I'll just sit here and keep the boiler company.", "light-hearted, a little lost",
  group="DAN_TALK", once=False)

JOURNAL = [
    ("JRN_01", 1, "GAME_STARTED", "Ted wants the boiler fed. Coal into the firebox, in the basement engine room. Watch the gauge."),
    ("JRN_02", 1, "BOILER_FED", "Steam is up and the beacon flickers. Ted wants me in the lantern room."),
    ("JRN_03", 1, "BURNER_DIAGNOSED", "The burner is cracked and burnt out. No burner, no light. Ted has no spare."),
    ("JRN_04", 2, "WINDOW_LOOKED", "Two sailors have moored at the dock. Ted says open the island gate."),
    ("JRN_05", 2, "SAILORS_INSIDE", "Jeff and Daniel are in. Daniel is warming up by the boiler."),
    ("JRN_06", 3, "BURNER_BRIEFING", "A spare burner is at the old outpost across the Gullwater. Take the launch with Jeff."),
    ("JRN_07", 3, "BOAT_CAST_OFF", "A ship's lights on the water. We need that burner. Keep clear of the rocks."),
]

OPEN_QUESTIONS = [
    "Lore vs GDD: WORLD.md puts the ship reveal before the crossing; the GDD (1 Oct 2026) puts it at the boarding threshold. This list follows the GDD.",
    "Lore says 'lamp head'; the GDD says 'burner'. Dialogue uses 'burner' throughout.",
    "The engine room is assumed to be the basement (Daniel's shelter). Level Layout should confirm.",
    "Ted's position in steps 2-3 (lantern room, hall, shouting from the dock) is approved as written for now.",
    "The player is addressed as 'the new guy' (creator decision). Nobody uses 'lad', 'lass' or 'man' for the player. Ted's 'the boy' refers to Daniel only.",
    "Ted and Jeff's relationship is TBD in the lore. The 'drowned by now' exchange is a proposal.",
    "Why Jeff and Daniel were on the water (smugglers?) is left open by JEFF_S2_03.",
    "Which lines are voiced is a cost decision (the AI Agent Strategy allows voice for Ted at the lamp). Subtitles are provided for every line.",
    "Fail-reason and outcome lines belong to the Story / Fail-State agent and are not included here.",
    "Step 1 is the only repair covered. The GDD's second Gate 1 repair is not part of this request.",
]


# ------------------------------- build + validate -------------------------------
def build():
    event_ids = {e[0] for e in EVENTS}
    for ln in LINES:
        ln["subtitle"] = f"{ln['speaker']}: {ln['text']}"
        ln.setdefault("once", True)
        ln.setdefault("pause_before", 0.0)
    problems = []
    ids = [ln["line_id"] for ln in LINES]
    problems += [f"duplicate line_id {i}" for i in {x for x in ids if ids.count(x) > 1}]
    groups = {}
    for ln in LINES:
        words = len(ln["text"].split())
        if words > MAX_WORDS:
            problems.append(f"{ln['line_id']}: {words} words (max {MAX_WORDS})")
        if BANNED.search(ln["text"]):
            problems.append(f"{ln['line_id']}: timer word or digit")
        if ln["speaker"] not in SPEAKERS:
            problems.append(f"{ln['line_id']}: unknown speaker")
        if ln["trigger"] not in event_ids:
            problems.append(f"{ln['line_id']}: unknown trigger {ln['trigger']}")
        if re.search(r"\b(lad|lass|man)\b", ln["text"], re.I):
            problems.append(f"{ln['line_id']}: gendered address of the player")
        if ln["kind"] == "nudge" and "tier" not in ln:
            problems.append(f"{ln['line_id']}: nudge without tier")
        if ln.get("group"):
            groups.setdefault(ln["group"], []).append(ln)
        if ln.get("journal_id") and ln["journal_id"] not in {j[0] for j in JOURNAL}:
            problems.append(f"{ln['line_id']}: unknown journal_id")
    for g, members in groups.items():
        if len({m["trigger"] for m in members}) != 1:
            problems.append(f"group {g}: members use different triggers")
        if len(members) < 2:
            problems.append(f"group {g}: needs at least two options")
    for trig in ("IDLE_STEP_1", "IDLE_STEP_2", "IDLE_STEP_3", "IDLE_OUTPOST"):
        tiers = sorted(ln["tier"] for ln in LINES if ln["trigger"] == trig)
        if tiers != list(range(1, len(tiers) + 1)):
            problems.append(f"{trig}: tiers not consecutive from 1 ({tiers})")
    for j in JOURNAL:
        if j[2] not in event_ids:
            problems.append(f"{j[0]}: unknown trigger")
    if problems:
        print("VALIDATION FAILED:")
        for p in problems:
            print("  -", p)
        sys.exit(1)

    data = {
        "status": "proposed",
        "game": "Lighting the Storm",
        "slice": "Gate 1 opening: steps 1-3",
        "notes": "Creator approves voice and lore before recording (AI Agent Strategy, Dialogue agent).",
        "speakers": SPEAKERS,
        "steps": STEPS,
        "events": [{"event_id": e[0], "step": e[1], "emitted_by": e[2], "note": e[3],
                    "existing_crew_event": e[4]} for e in EVENTS],
        "lines": LINES,
        "journal": [{"journal_id": j[0], "step": j[1], "trigger": j[2], "text": j[3]} for j in JOURNAL],
    }
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return data


def md(data):
    out = ["# Opening Dialogue: Steps 1-3 (Gate 1 slice)", "",
           "Status: **proposed**. Generated from `LightingTheStorm/tools/build_dialogue.py`. "
           "The creator approves voice and lore before anything is recorded.", "",
           "**Voice rules used** (from the Lore Build and Agent Crew canon): Ted is gruff, snarky and old-school, "
           "calls city folk \"new money toffs\", and grunts and coughs. Jeff is wry, wiry and frantic under pressure. "
           "Daniel is light-hearted and anxious. The player, called the new guy, never speaks. Nothing mentions a timer, shows a marker "
           "or confirms a supernatural cause.", "",
           "Lines marked *(canon)* reuse the sample lines in the character files. "
           "**Pick one** means the game plays one option at random.", ""]
    by_step = {}
    for ln in data["lines"]:
        by_step.setdefault(ln["step"], []).append(ln)
    for st in STEPS + [{"step": 0, "title": "Optional discoveries", "location": "Lighthouse and basement",
                        "player_action": "Unprompted reactions to the haunted-lighthouse details (Pillar 1).",
                        "starts_on": "", "ends_on": ""}]:
        label = f"Step {st['step']}: {st['title']}" if st["step"] else st["title"]
        out += [f"## {label}", "", f"*Location:* {st['location']}  ", f"*Player does:* {st['player_action']}", ""]
        seen, order = set(), []
        for ln in by_step[st["step"]]:
            if ln["trigger"] not in seen:
                seen.add(ln["trigger"])
                order.append(ln["trigger"])
        for trig in order:
            ev = next(e for e in data["events"] if e["event_id"] == trig)
            out += [f"### On `{trig}`", f"*{ev['note']}*", ""]
            group_seen = set()
            for ln in (x for x in by_step[st["step"]] if x["trigger"] == trig):
                tag = []
                if ln["kind"] == "nudge":
                    tag.append(f"nudge tier {ln['tier']}")
                else:
                    tag.append(ln["kind"])
                if ln.get("group"):
                    g = ln["group"]
                    if g not in group_seen:
                        group_seen.add(g)
                        out.append("- **Pick one:**")
                    out.append(f"  - **{ln['speaker']}** `{ln['line_id']}` ({', '.join(tag)}): \"{ln['text']}\"  ")
                    out.append(f"    *delivery: {ln['delivery']}*")
                else:
                    out.append(f"- **{ln['speaker']}** `{ln['line_id']}` ({', '.join(tag)}): \"{ln['text']}\"  ")
                    out.append(f"  *delivery: {ln['delivery']}*")
                if ln.get("assist_text"):
                    out.append(f"  *assist hint:* {ln['assist_text']}")
                if ln.get("staging"):
                    out.append(f"  *staging:* {ln['staging']}")
                if ln.get("note"):
                    out.append(f"  *note:* {ln['note']}")
            out.append("")
    out += ["## Objective journal (handwritten, player's own words)", "", "| ID | Step | Written on | Entry |", "|---|---|---|---|"]
    out += [f"| `{j['journal_id']}` | {j['step']} | `{j['trigger']}` | {j['text']} |" for j in data["journal"]]
    out += ["", "## Open questions and assumptions", ""] + [f"{i}. {q}" for i, q in enumerate(OPEN_QUESTIONS, 1)]
    counts = {s: sum(1 for ln in data["lines"] if ln["speaker"] == s) for s in SPEAKERS}
    out += ["", f"*{len(data['lines'])} lines: " + ", ".join(f"{SPEAKERS[s]['name']} {n}" for s, n in counts.items()) + ".*", ""]
    DOCS.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text("\n".join(out), encoding="utf-8")


if __name__ == "__main__":
    if "--force" not in sys.argv:
        sys.exit("Superseded by the Opening Dialogue Crew (see the docstring). Pass --force to overwrite its output.")
    d = build()
    md(d)
    print(f"OK: {len(d['lines'])} lines, {len(d['events'])} events, {len(d['journal'])} journal entries")
    print(f"  {OUT_JSON}\n  {OUT_MD}")
