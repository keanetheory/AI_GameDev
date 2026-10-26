"""Deterministic style lint for Lighting the Storm dialogue records.

The Style Evaluator agent judges tone; this lint catches what a script can prove (vocabulary, record
format, length, lore continuity) and hands the Evaluator hard evidence. Rule ids match style_guide.json.

    python style_lint.py file.txt          # or: cat file.txt | python style_lint.py -
"""
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent / "AIAgentCrew"))
import canon  # noqa: E402  (the project's own canon module: the event list and speaker rules)

GUIDE = json.loads((HERE / "style_guide.json").read_text(encoding="utf-8"))
MAX_WORDS = GUIDE["max_words_per_line"]
SPEAKERS = set(GUIDE["speakers"])

EVENT_ORDER = [e[0] for e in canon.OPENING_EVENTS]
KNOWN_EVENTS = set(EVENT_ORDER) | {e[0] for e in canon.LATER_EVENTS}
ARTHUR_RET = re.compile(r"^ARTHUR_RET_\d{2}$")
CROSSING_EVENTS = {"BOAT_CAST_OFF", "OUTBOUND_NEAR_MISS", "OUTBOUND_COLLISION", "SALTGATE_REACHED",
                   "BURNER_PICKED_UP", "IDLE_SALTGATE", "RETURN_DEPARTED", "RETURN_ARRIVED"}

RECORD = re.compile(r'^([A-Za-z]+) \[([A-Za-z0-9_]+)\]: "(.*)"$')


def _words(*alts: str) -> re.Pattern:
    return re.compile(r"\b(" + "|".join(alts) + r")\b", re.I)


BAD_PLAYER_TERMS = _words("apprentice", "lad", "lass", "kid", "rookie", "newbie", "greenhorn")
BAD_MAN = re.compile(r"(,\s*man\b|\bman\s*[,!?.]|^man\b)", re.I)
BAD_PART = _words("lamp heads?", "lamphead", "bulbs?", "mantles?", "filaments?")
BAD_PLACE = _words("outposts?", "harbou?r towns?", "the port", "saint-calder", "st\\.? calder")
BAD_TOFF = _words("posh", "rich kids?", "yuppies?", "elites?", "snobs?")
BAD_CRAFT = _words("yachts?", "schooners?", "dinghy", "dinghies", "speedboats?", "motorboats?", "ferry", "steamer")
CLOCK = _words("timers?", "countdown", "clock", "deadline", "minutes?", "seconds?", "hours?", "ticking")
SHIP = _words("ships?", "passenger ships?", "liner")
BROKEN = _words("broken", "busted", "bust", "cracked", "dead", "blown", "shot", "kaput")
SUPERNATURAL = _words("ghosts?", "monsters?", "demons?", "haunted", "curse[ds]?", "spirits?", "undead", "witch(?:es)?",
                      "supernatural", "ghouls?", "possessed")
NUMBER_WORDS = _words("ten", "twenty", "thirty", "forty", "fifty", "sixty", "hundred", "thousand", "dozen", "decades?")
MODERN = _words("okay", "ok", "guys", "awesome", "cool", "dude", "phone", "wifi", "plastic", "neon", "bro", "yay",
                "hi", "hey guys", "no worries", "totally", "super")
CHEERFUL = _words("wonderful", "delighted", "thrilled", "amazing", "lovely", "fantastic", "so excited", "excited",
                  "fabulous", "can't wait", "great to see you", "delightful", "super happy", "welcome")
EMOJI = re.compile("[\U0001F000-\U0001FAFF☀-➿⬀-⯿]")
STAGE = re.compile(r"[*_#`<>\[\]{}]|\([^)]*\)")


@dataclass
class Finding:
    rule: str
    line: int
    message: str
    evidence: str = ""

    def __str__(self) -> str:
        ev = f" [{self.evidence}]" if self.evidence else ""
        return f"{self.rule} (line {self.line}): {self.message}{ev}"


def lint(text: str) -> list[Finding]:
    out: list[Finding] = []
    lines = [(i, l.rstrip()) for i, l in enumerate(text.splitlines(), 1) if l.strip()]
    if not lines:
        return [Finding("F1", 0, "empty output")]
    boarding = EVENT_ORDER.index("BOARDING_THRESHOLD")
    diagnosed = EVENT_ORDER.index("BURNER_DIAGNOSED")
    for n, raw in lines:
        m = RECORD.match(raw)
        if not m:
            out.append(Finding("F1", n, 'not a record of the form SPEAKER [EVENT_ID]: "text"', raw[:70]))
            body, speaker, event = raw, None, None
        else:
            speaker, event, body = m.group(1), m.group(2), m.group(3)
            if speaker not in SPEAKERS:
                rule = "L3" if speaker.upper() in {"ISAAC", "PLAYER", "APPRENTICE"} else "F1"
                out.append(Finding(rule, n, "speaker must be TED, ARTHUR or DANIEL in capitals "
                                            "(the player never speaks)", speaker))
            if event not in KNOWN_EVENTS and not ARTHUR_RET.match(event):
                out.append(Finding("F1", n, "EVENT_ID is not in the game's event list", event))
            on_boat = event in CROSSING_EVENTS or bool(ARTHUR_RET.match(event))
            if on_boat and speaker in {"TED", "DANIEL"}:
                out.append(Finding("L3", n, f"{speaker} is never on the boat; only ARTHUR speaks on crossing events", event))
            if speaker not in {"TED", None} and re.search(r"toffs?", body, re.I):
                out.append(Finding("V4", n, "only Ted says 'new money toff'", speaker))
            idx = EVENT_ORDER.index(event) if event in EVENT_ORDER else None
            if idx is not None and idx < boarding and (hit := SHIP.search(body)):
                out.append(Finding("L2", n, "the passenger ship may not be named before BOARDING_THRESHOLD", hit.group(0)))
            if idx is not None and idx < diagnosed and re.search(r"burner", body, re.I) and BROKEN.search(body):
                out.append(Finding("L2", n, "the burner is found broken only at BURNER_DIAGNOSED (step 3)", body[:60]))
        words = len(body.split())
        if words > MAX_WORDS:
            out.append(Finding("N1", n, f"{words} words; the limit is {MAX_WORDS}"))
        if m and (STAGE.search(body) or EMOJI.search(body)):
            out.append(Finding("F2", n, "stage direction, bracket, asterisk or emoji inside the spoken text",
                               (STAGE.search(body) or EMOJI.search(body)).group(0)))
        if body.count("!") > 2:
            out.append(Finding("T1", n, f"{body.count('!')} exclamation marks; at most two", ""))
        for rule, pat, why in [
            ("V1", BAD_PLAYER_TERMS, "the player is only ever 'Isaac'"),
            ("V1", BAD_MAN, "never address the player as 'man'"),
            ("V2", BAD_PART, "the part is the 'burner'"),
            ("V3", BAD_PLACE, "use the Saltgate, the Gullwater, Bracken Isle, Saint Calder"),
            ("V4", BAD_TOFF, "Ted's word is 'new money toff'"),
            ("V5", BAD_CRAFT, "the player's craft is the steam launch; the sailors' is a rowboat"),
            ("L1", CLOCK, "no timer, clock, countdown or deadline talk"),
            ("L4", NUMBER_WORDS, "invented number or span of time; open lore stays open"),
            ("T3", SUPERNATURAL, "never confirm or name a supernatural cause"),
            ("T4", MODERN, "modern idiom in 1800s speech"),
            ("T1", CHEERFUL, "cheerful, gushing register"),
        ]:
            hit = pat.search(body)
            if hit:
                out.append(Finding(rule, n, why, hit.group(0)))
        if re.search(r"\d", body):
            out.append(Finding("L1", n, "digits in spoken text (no numbers or deadline talk)", re.search(r"\d+", body).group(0)))
    return out


def summary(findings: list[Finding]) -> str:
    return "\n".join(str(f) for f in findings) if findings else "LINT CLEAN: no machine-checkable violations."


if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "-"
    data = sys.stdin.read() if src == "-" else Path(src).read_text(encoding="utf-8")
    res = lint(data)
    print(summary(res))
    sys.exit(1 if res else 0)
