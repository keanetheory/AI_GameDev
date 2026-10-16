"""Applies the creator's 'pick one' decisions to the live revised opening dialogue.

Input : sample_output_live_revised/ (56 lines, crew output after one revision round)
Output: sample_output_picked/ (dialogue_opening.json, DIALOGUE_OPENING.md, handoffs/, run_log.json)

The picks were made line by line in a walkthrough with the Canon and Review Orchestrator's rules (2026-10-15).
Every group becomes a single line, so the game has no random alternates left. The review in handoffs/ is
computed from the data by deterministic checks (it is not a model review); the live crew review of the 56-line
set is kept in sample_output_live_revised/.

After the picks, story_beats.revise() puts the lines in the creator's canon story order (2026-10-16: arrival
outside the lighthouse, coal, sailors, then Ted finds the burner broken, then the Saltgate crossing). The brief's
steps and events come from canon.py, so the data always matches the canon order.

Run: python apply_creator_picks.py   (then copy sample_output_picked/dialogue_opening.json into the game with
--install, which writes LightingTheStorm/data/dialogue/dialogue_opening.json)
"""
import json
import re
import sys
from pathlib import Path

from canon import OPENING_DIALOGUE_RULES, OPENING_EVENTS, OPENING_STEPS
from story_beats import revise

from dialogue_integrator import build_game_data, review_list
from schemas import DialogueBrief, OpeningDialogue, ReviewReport
from validators import (DEADLINE_WORDS, GENDERED_ADDRESS, SHIP_WORD, SUPERNATURAL, check_dialogue,
                        check_dialogue_brief, check_review)

HERE = Path(__file__).parent
SRC = HERE / "sample_output_live_revised"
OUT = HERE / "sample_output_picked"

# group (trigger) -> the line the creator kept; every other line in the group is dropped
PICKS = {
    "GAME_STARTED": "TED_S1_03", "COAL_LOADED_FIRST": "TED_S1_05", "COAL_LOADED_HALF": "TED_S1_08",
    "SAILORS_MOORED": "TED_S2_01", "GATE_APPROACHED": "ARTHUR_S2_02", "GATE_OPENED": "ARTHUR_S2_04",
    "DANIEL_IN_BASEMENT": "DANIEL_OPT_02",
    "BURNER_BRIEFING": "TED_S3_02", "BOARDING_THRESHOLD": "ARTHUR_S3_01", "BOAT_CAST_OFF": "ARTHUR_S3_03",
    "OUTBOUND_NEAR_MISS": "ARTHUR_S3_07", "OUTBOUND_COLLISION": "ARTHUR_S3_08", "SHIP_SIGHTED": "ARTHUR_S3_11",
    "BASEMENT_TALK": "DANIEL_OPT_04", "BASEMENT_BANG": "DANIEL_OPT_06", "WALL_WHISPER_HEARD": "DANIEL_OPT_08",
    "POSTER_EXAMINED": "ARTHUR_S0_13",
}
# The collision lines both implied a reverse control (the boat has one speed, A and D only).
REWORD = {"ARTHUR_S3_08": "Hold on! Swing wide of the rock and steer clear. Gently now."}

PICK_NOTE = ("Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group "
             "was dropped.")

OPEN_DECISIONS = [
    "Which lines are voiced is a cost decision for the creator; subtitles exist for every line.",
    "Why Arthur and Daniel were on the water (smugglers?) remains open; no line states or implies a reason.",
    "Ted and Arthur's relationship is TBD in the lore; the 'drowned by now' exchange (ARTHUR_S2_05, TED_S2_04) is a proposal only.",
    "Arthur-knows-more thread: the picks DANIEL_OPT_04 ('Arthur says it's just weather') and ARTHUR_S0_13 (uneasy about the poster) together hint that Arthur knows about the Flighted. His link to them is undecided in the lore.",
    "ARTHUR_S3_08 was reworded by the creator's pick (drops 'back her off', which implied a reverse control); needs a Dialogue agent and Canon re-review.",
    "Story-beat revision (2026-10-16): TED_S1_01, TED_S1_09, TED_S1_10, TED_S1_11, TED_S3_02, ARTHUR_S3_04 and the new TED_S3_00 were rewritten to the creator's beat order; they need a Dialogue agent and Canon re-review before recording.",
    "Fail-reason and outcome lines belong to the Story / Fail-State agent and are not written here.",
    "Where the Flighted poster physically sits is still undecided; ARTHUR_S0_13 is location-neutral.",
]


def main() -> None:
    raw = json.loads((SRC / "dialogue_opening.json").read_text(encoding="utf-8"))
    brief_raw = json.loads((SRC / "handoffs" / "01_dialogue_brief.json").read_text(encoding="utf-8"))
    # steps, events and rules follow the canon story beats (the live run predates them)
    brief_raw["steps"] = OPENING_STEPS
    brief_raw["events"] = [{"event_id": e[0], "step": e[1], "note": e[2], "existing_crew_event": e[3]} for e in OPENING_EVENTS]
    keep = [c for c in brief_raw["constraints"] if not re.search(r"outpost|eclipse|step 1 shovel|IDLE_OUTPOST", c, re.I)]
    brief_raw["constraints"] = OPENING_DIALOGUE_RULES[:3] + keep
    brief = DialogueBrief.model_validate(brief_raw)
    log = json.loads((SRC / "run_log.json").read_text(encoding="utf-8"))
    ids = {ln["line_id"] for ln in raw["lines"]}
    unknown = [i for i in PICKS.values() if i not in ids]
    assert not unknown, f"unknown picked IDs: {unknown}"

    kept = []
    for ln in raw["lines"]:
        trig = ln["trigger"]
        if ln.get("group") and trig in PICKS and PICKS[trig] != ln["line_id"]:
            continue  # unchosen alternate
        ln = dict(ln)
        if ln.get("group"):
            ln["group"] = None  # single option now; the game plays it every time
            ln.pop("group")
            ln["note"] = (ln["note"] + " | " if ln.get("note") else "") + PICK_NOTE
        if ln["line_id"] in REWORD:
            old = ln["text"]
            ln["text"] = REWORD[ln["line_id"]]
            ln["subtitle"] = f"{ln['speaker']}: {ln['text']}"
            ln["note"] = ln["note"] + f" Reworded from: \"{old}\""
        kept.append(ln)
    left = [t for t in PICKS if sum(1 for x in raw["lines"] if x["trigger"] == t and x.get("group")) == 0]
    assert not left, f"picks for groups that do not exist: {left}"

    dialogue = OpeningDialogue.model_validate(revise({"lines": kept, "journal": raw["journal"]}, "picked"))
    problems = check_dialogue_brief(brief) + check_dialogue(dialogue, brief)
    assert not problems, problems

    # ---- deterministic review (facts computed from the data) ----
    lines = dialogue.lines
    order = [e.event_id for e in brief.events]
    ship = sorted((x for x in lines if SHIP_WORD.search(x.text) and x.trigger in order), key=lambda x: order.index(x.trigger))
    longest = max(lines, key=lambda x: len(x.text.split()))
    isaac = [x.line_id for x in lines if "isaac" in x.text.lower()]
    ok = lambda c, e: {"check": c, "result": "pass", "evidence": e}
    no_timer = not any(DEADLINE_WORDS.search(x.text) for x in lines) and not any(DEADLINE_WORDS.search(j.text) for j in dialogue.journal)
    no_super = not any(SUPERNATURAL.search(x.text) for x in lines)
    no_gender = not any(GENDERED_ADDRESS.search(x.text) for x in lines)
    obj = {s: [x.line_id for x in lines if x.step == s and x.assist_text] for s in (1, 2, 3)}
    spk = {k: sum(1 for x in lines if x.speaker == k) for k in brief.speakers}
    chk = lambda c, good, e: {"check": c, "result": "pass" if good else "fail", "evidence": e}
    report = ReviewReport.model_validate({
        "verdict": "PASS" if (no_timer and no_super and no_gender and "apprentice" not in " ".join(x.text.lower() for x in lines)) else "REVISE",
        "pillar_checks": [
            ok("1. The light must return", "Each step keeps an objective line with an assist hint: " + "; ".join(f"step {s}: {', '.join(v)}" for s, v in obj.items()) + "."),
            chk("2. The storm sets the clock", no_timer, f"Regex check: no timer, deadline or number word in {len(lines)} lines or {len(dialogue.journal)} journal entries."),
            ok("3. Your hands, your eyes", "Guidance is spoken by Ted and Arthur; assist hints are opt-in text. The player never speaks; 'Isaac' appears in " + f"{len(isaac)} of {len(lines)} lines ({', '.join(isaac)})."),
            chk("4. Dread you can read", no_super, "Regex check: no ghost, haunted, curse, spirit or monster word in any line. Whether the Daniel and poster lines stay ambiguous is a human judgement made in the creator walkthrough."),
        ],
        "decisions_log_checks": [
            ok("Player term", f"No line says 'apprentice'; '{brief.player_term}' appears in {len(isaac)} lines."),
            ok("Ship reveal at boarding", (f"First line naming the ship is {ship[0].line_id} on {ship[0].trigger}" if ship else "No line names the ship") + "."),
            chk("No gendered address of the player", no_gender, "No line says lad, lass or man."),
            ok("Line length", f"Longest line is {longest.line_id} at {len(longest.text.split())} words (limit {brief.max_words_per_line})."),
        ],
        "issues": [],
        "open_creator_decisions": OPEN_DECISIONS,
        "handoff_summary": (f"Creator-picked opening dialogue: {len(lines)} lines (Ted {spk['TED']}, Arthur {spk['ARTHUR']}, Daniel {spk['DANIEL']}), "
                            f"{len(dialogue.journal)} journal entries, no random alternates. All deterministic contract checks pass. "
                            "This review is computed, not a model review; ARTHUR_S3_08 was reworded and needs a crew re-review."),
    })
    assert not check_review(report)

    state = {"dialogue_brief": brief, "dialogue": dialogue, "dialogue_review": report, "log": log, "history": []}
    data = build_game_data(state, "creator_picks")
    data["status"] = "creator_picked"
    data["notes"] = ("Creator walkthrough picks applied on 2026-10-15 to the live revised crew output, then the "
                     "creator's story-beat order applied on 2026-10-16. Creator still approves voice and lore before recording.")
    data["generated_by"].update({"pipeline": "dialogue_crew.py + apply_creator_picks.py", "source": "sample_output_live_revised",
                                 "creator_picks": len(PICKS), "lines_dropped": len(raw["lines"]) - len(kept),
                                 "review_verdict": "PASS (deterministic, not a model review)"})

    OUT.mkdir(exist_ok=True)
    (OUT / "handoffs").mkdir(exist_ok=True)
    (OUT / "dialogue_opening.json").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    md = review_list(data, report.open_creator_decisions)
    md = re.sub(r"Status: \*\*.*?\n", "Status: **creator_picked**. Creator walkthrough picks applied (17 'pick one' groups, one line kept each) "
                "to the live revised crew output, then the 2026-10-16 story-beat order. Review below is deterministic, not a model review.\n", md, count=1)
    md = md.replace("**Pick one** means the game plays one option at random.", "There are no random alternates left: the creator chose one line per group.")
    (OUT / "DIALOGUE_OPENING.md").write_text(md, encoding="utf-8")
    (OUT / "handoffs" / "01_dialogue_brief.json").write_text(brief.model_dump_json(indent=2), encoding="utf-8")
    (OUT / "handoffs" / "02_dialogue.json").write_text(dialogue.model_dump_json(indent=2), encoding="utf-8")
    (OUT / "handoffs" / "03_dialogue_review.json").write_text(report.model_dump_json(indent=2), encoding="utf-8")
    (OUT / "run_log.json").write_text(json.dumps(log, indent=2), encoding="utf-8")
    if "--install" in sys.argv:
        game = HERE.parent / "LightingTheStorm" / "data" / "dialogue" / "dialogue_opening.json"
        game.write_text((OUT / "dialogue_opening.json").read_text(encoding="utf-8"), encoding="utf-8")
        print(f"installed {game}")
    (OUT / "creator_picks.json").write_text(json.dumps({"picks": PICKS, "rewords": REWORD,
                                                        "dropped": sorted(ids - {x.line_id for x in lines})}, indent=2), encoding="utf-8")
    print(f"wrote {OUT}: {len(dialogue.lines)} lines ({len(raw['lines']) - len(kept)} dropped), verdict {report.verdict}")


if __name__ == "__main__":
    main()
