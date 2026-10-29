"""Offline rule check for proposed_ted_lines.json (and the T18 lines in the game data). No LLM, no credits."""
import json, re, sys
from pathlib import Path
from canon import MAX_WORDS_PER_LINE, PLAYER_TERM, SHIP_NAMED_FROM
from validators import TIMER_WORDS, DEADLINE_WORDS, GENDERED_ADDRESS, SUPERNATURAL, SHIP_WORD

HERE = Path(__file__).resolve().parent
GAME = HERE.parent / "LightingTheStorm" / "data" / "dialogue" / "dialogue_opening.json"
T18 = ["TED_S1_01", "TED_S1_09", "TED_S1_10", "TED_S1_11", "TED_S3_02", "ARTHUR_S3_04", "TED_S3_00"]
POST_BOARDING = {"RETURN_ARRIVED", "LAMP_ROOM_REENTERED", "BURNER_FITTED", "SHIP_WIN", "SHIP_FAIL", "BURNER_DIAGNOSED"}


def check(lid, trigger, text):
    e = []
    n = len(text.split())
    if n > MAX_WORDS_PER_LINE: e.append(f"{n} words (max {MAX_WORDS_PER_LINE})")
    if TIMER_WORDS.search(text) or DEADLINE_WORDS.search(text): e.append("timer, deadline or number")
    if re.search(r"\bapprentice\b", text, re.I): e.append("'apprentice'")
    if GENDERED_ADDRESS.search(text): e.append("lad/lass/man")
    if re.search(r"\blamp head\b", text, re.I): e.append("'lamp head'")
    if SUPERNATURAL.search(text): e.append("confirms a supernatural cause")
    if SHIP_WORD.search(text) and trigger not in POST_BOARDING and not trigger.startswith("IDLE") \
            and trigger in ("GAME_STARTED", "LIGHTHOUSE_ENTERED", "BOILER_FED", "BEACON_STILL_DARK", "LAMP_ROOM_ENTERED"):
        e.append(f"names the ship before {SHIP_NAMED_FROM}")
    return e


def main():
    bad = 0
    prop = json.loads((HERE / "proposed_ted_lines.json").read_text(encoding="utf-8"))["lines"]
    game = {l["line_id"]: l for l in json.loads(GAME.read_text(encoding="utf-8"))["lines"]}
    rows = [("proposed", l["line_id"], l["trigger"], l["text"]) for l in prop]
    rows += [("t18", i, game[i]["trigger"], game[i]["text"]) for i in T18 if i in game]
    for src, lid, trig, text in rows:
        errs = check(lid, trig, text)
        bad += bool(errs)
        print(f"{'FAIL' if errs else 'ok  '} [{src}] {lid} ({trig}, {len(text.split())}w) {'; '.join(errs)}")
    names = sum(PLAYER_TERM in l["text"] for l in prop)
    print(f"'{PLAYER_TERM}' used in {names} of {len(prop)} proposed lines (canon aims for about one in five).")
    sys.exit(1 if bad else 0)


main()
