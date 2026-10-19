"""Story-beat revision of the opening dialogue (creator decision, 2026-10-16).

The creator fixed the order of the opening (canon.STORY_BEATS): the player starts OUTSIDE the lighthouse
and Ted opens the door ("you're the new guy"); inside, after a beat, Ted sends the player to the boiler;
the player lets the stranded sailors in through the island gate; only THEN does Ted find the beacon's
burner broken; the player fetches the replacement from the Saltgate (never "the outpost") with Arthur.

revise() applies that order to an existing line set (the creator-picked lines and the offline draft), so the
creator's picks survive: lines keep their IDs (voice and subtitle references stay valid) and only move
trigger, step or text where the new order needs it. Used by apply_creator_picks.py and, once, to rewrite
offline_dialogue_draft.json.
"""
import re

# Events that moved from step 1 to step 3, and events that were renamed.
MOVED_TO_STEP_3 = {"LAMP_ROOM_ENTERED", "BURNER_DIAGNOSED"}
RENAMED = {"OUTPOST_REACHED": "SALTGATE_REACHED", "IDLE_OUTPOST": "IDLE_SALTGATE"}

# Generic wording fixes: the crossing's destination is the Saltgate quays.
WORDING = [
    (r"\bthe old outpost\b", "the Saltgate"),
    (r"\bthe outpost landing\b", "the Saltgate quays"),
    (r"\bthe abandoned outpost\b", "the Saltgate quays"),
    (r"\bthe outpost\b", "the Saltgate quays"),
    (r"\bOutpost\b", "The Saltgate"),
    (r"\boutpost\b", "Saltgate"),
]

NOTE = "Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken)."

# New lines for the two new events. Both line sets get them.
NEW_LINES = [
    {"line_id": "TED_S3_00", "step": 3, "beat": "S3_BEACON", "speaker": "TED", "kind": "objective", "trigger": "BEACON_STILL_DARK",
     "delivery": "Gruff and uneasy, looking up the stairs; the hum of the dynamo under him.", "pause_before": 1.5,
     "text": "Dynamo's running and still no light. Something's wrong up top. Lantern room, Isaac. With me.",
     "assist_text": "Follow Ted up the tower stairs to the lantern room.",
     "staging": "Ted at the foot of the tower stairs, looking up at the dark lantern."},
]

# Per line-set overrides: line_id -> fields to set. "picked" = the creator-picked set, "draft" = offline draft.
OVERRIDES = {
    "picked": {
        "TED_S1_01": {"text": "Hrmph. You're the new guy, then. Storm season, and they send me a new money toff. In.",
                      "staging": "Isaac stands outside the lighthouse door in the wind; Ted opens it and looks him over."},
        "TED_S1_03": {"trigger": "LIGHTHOUSE_ENTERED", "pause_before": 2.0,
                      "staging": "Inside the hall, after a beat. Ted points toward the basement stairs."},
        "TED_S1_09": {"text": "Hear that dynamo whine? Good. Now we'll see if the old girl lights.", "assist_text": None},
        "TED_S1_10": {"text": "Arc lamp's in the middle. Let's open her up and see what's ailing her."},
        "TED_S1_11": {"text": "Cracked clean through. The burner's finished. Hrmph. We need a new one."},
        "TED_S3_02": {"text": "No burner, no beacon. There's a spare at the Saltgate, across the Gullwater. Go with Arthur, Isaac.",
                      "assist_text": "Board the steam launch with Arthur and cross the Gullwater to the Saltgate quays to fetch the replacement burner."},
        "ARTHUR_S3_04": {"text": "There's the Saltgate quay. Fetch the burner. I'll keep the engine turning."},
    },
    "draft": {
        "TED_S1_01": {"text": "Hrmph. You're the new guy, then. Isaac. In you come, out of the wind.",
                      "staging": "Isaac stands outside the lighthouse door; Ted opens it."},
        "TED_S1_02": {"text": "Storm season. The sea's turning, the tides go savage, and the storms follow."},
        "TED_S1_05": {"trigger": "LIGHTHOUSE_ENTERED", "pause_before": 2.0},
        "TED_S1_09a": {"text": "There she goes! Hear the dynamo whine? Steam's up. Now let's see if she lights.", "assist_text": None},
        "TED_S1_09b": {"text": "Not bad for a new money toff. Steam's up. Now we'll see about the light.", "assist_text": None},
        "TED_S1_10": {"text": "See that? Dark as a dead match. Steam's good, so the fault's in the lamp. Let's take a look.",
                      "assist_text": "Stand by the arc lamp while Ted opens it up.",
                      "staging": "Ted opens the arc lamp."},
        "TED_S1_11": {"text": "Cracked glass, rods burnt to stubs. That burner's finished. Hrmph. We need a new one."},
        "TED_S3_01": {"text": "Now listen. The burner's gone and I've no spare. There's one at the Saltgate, across the Gullwater."},
    },
}
JOURNAL_OVERRIDES = {
    "picked": {
        "JRN_01": {"text": "Ted has let me in. The beacon is starved: shovel coal into the boiler in the basement engine room until the gauge climbs."},
        "JRN_03": {"text": "Ted found the beacon's burner cracked. Cross the Gullwater with Arthur, fetch the replacement burner from the Saltgate quays, and bring it back."},
    },
    "draft": {
        "JRN_01": {"text": "Ted has let me in. He wants the boiler fed: coal into the firebox, in the basement engine room. Watch the gauge."},
        "JRN_02": {"text": "Steam is up and the dynamo whines, but the beacon is still dark."},
    },
}


def _words(text: str) -> str:
    for pat, rep in WORDING:
        text = re.sub(pat, rep, text)
    return text


def revise(data: dict, which: str) -> dict:
    """Return a copy of {'lines': [...], 'journal': [...]} in the canon story-beat order."""
    lines, journal = [], []
    over = OVERRIDES[which]
    for ln in data["lines"]:
        ln = dict(ln)
        ln["trigger"] = RENAMED.get(ln["trigger"], ln["trigger"])
        if ln["trigger"] in MOVED_TO_STEP_3:
            ln["step"] = 3
        for field in ("text", "assist_text", "staging"):
            if ln.get(field):
                ln[field] = _words(ln[field])
        if ln.get("beat"):
            ln["beat"] = re.sub(r"\b[Oo]utpost\b", "Saltgate", ln["beat"])
        changed = ln["line_id"] in over
        for k, v in over.get(ln["line_id"], {}).items():
            ln[k] = v
        if ln["trigger"] in MOVED_TO_STEP_3 or changed:
            ln["note"] = (ln["note"] + " | " if ln.get("note") else "") + NOTE
        ln["subtitle"] = f"{ln['speaker']}: {ln['text']}"
        lines.append(ln)
    have = {x["line_id"] for x in lines}
    template = {k: None for k in data["lines"][0]}   # same fields as the set's own lines
    for new in NEW_LINES:
        if new["line_id"] in have:
            continue
        ln = dict(template)
        ln.update({k: v for k, v in new.items()})
        ln.setdefault("once", True)
        if "once" in template and ln.get("once") is None:
            ln["once"] = True
        ln["subtitle"] = f"{ln['speaker']}: {ln['text']}"
        ln["note"] = NOTE
        lines.append(ln)
    jover = JOURNAL_OVERRIDES[which]
    for j in data["journal"]:
        j = dict(j)
        j["trigger"] = RENAMED.get(j["trigger"], j["trigger"])
        if j["trigger"] in MOVED_TO_STEP_3:
            j["step"] = 3
        j["text"] = _words(j["text"])
        j.update(jover.get(j["journal_id"], {}))
        journal.append(j)
    order = {e: i for i, e in enumerate(_event_order())}
    lines.sort(key=lambda x: (order.get(x["trigger"], 999)))
    return {**data, "lines": lines, "journal": journal}


def _event_order() -> list[str]:
    from canon import OPENING_EVENTS
    return [e[0] for e in OPENING_EVENTS]
