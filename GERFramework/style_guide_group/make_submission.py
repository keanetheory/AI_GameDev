"""Builds SUBMISSION.md from a run in runs/ (default: the latest) plus the style guide and agent prompts.

    python make_submission.py [runs/<timestamp>]
"""
import json
import sys
from pathlib import Path

from sg_rules import GUIDE, HERE, render

PIPELINE_SENTENCE = (
    "This Style Guide Agent runs immediately after the Dialogue agent writes each batch of Ted, Arthur and Daniel "
    "lines and before the Dialogue Integrator turns them into dialogue_opening.json, so only lines that score 10/10 "
    "on the Lighting the Storm style guide ever reach the game data."
)
EXAMPLES = [("ex1_tone", "Example 1: Tone"), ("ex2_vocabulary_lore", "Example 2: Vocabulary and lore accuracy"),
            ("ex3_formatting_length", "Example 3: Formatting and length"),
            ("ex4_ordinary_request", "Bonus baseline: an ordinary request, no trap")]


def fenced(text: str) -> str:
    return "```\n" + "\n".join(l for l in text.strip().splitlines() if l.strip()) + "\n```"


def example(run: Path, cid: str, title: str) -> str:
    r = json.loads((run / f"{cid}.json").read_text(encoding="utf-8"))
    first, last = r["rounds"][0], r["rounds"][-1]
    out = [f"### {title}", "", f"**Violation class:** {r['case']['violation_class']}  ",
           f"**Request given to the Generator (designed to produce wrong content):** {r['case']['request']}", "",
           "**BEFORE (Generator output, unedited):**", "", fenced(first["text"]), "",
           f"**Evaluator, first pass: SCORE [{first['score']}/10]**", "",
           f"REASON: {first['reason']}", ""]
    if first["lint"]:
        out += ["Script lint evidence given to the Evaluator:", "", "```", *first["lint"], "```", ""]
    for rd in r["rounds"][1:-1]:
        out += [f"<details><summary>Refinement {rd['round']}: scored {rd['score']}/10, refined again</summary>", "",
                fenced(rd["text"]), "", f"SCORE [{rd['score']}/10]. REASON: {rd['reason']}", "", "</details>", ""]
    out += [f"**AFTER (Refiner output, refinement {last['round']}):**", "", fenced(last["text"]), "",
            f"**Evaluator, final pass: SCORE [{last['score']}/10]**", "", f"REASON: {last['reason']}", "",
            f"**Outcome:** {first['score']}/10 to {last['score']}/10 in {r['refinements']} automatic refinement(s). "
            "No human edited anything between Generator, Evaluator and Refiner.", ""]
    return "\n".join(out)


def main() -> None:
    runs = sorted((HERE / "runs").iterdir())
    run = Path(sys.argv[1]) if len(sys.argv) > 1 else runs[-1]
    types = GUIDE["types"]
    parts = ["# Style Guide Agent: Lighting the Storm", "",
             "Mandatory assignment, due 26 Oct 2026. A Generator, Evaluator and Refiner loop that enforces the "
             "game's own style rules, built as the Style Guide GER agent group in `GERFramework/style_guide_group/`.", "",
             "## 1. The Capstone-Anchored Style Guide", "",
             f"{len(GUIDE['rules'])} rules in {len(types)} constraint types ({', '.join(types)}), every rule traced to "
             "the Lore Build, the final GDD or the project's `canon.py`. Nothing here is new lore: it is the "
             "creator's existing canon turned into checkable rules for the dialogue the game's agents write. "
             "A stranger reading it can tell exactly which game it governs: it names Ted, Arthur, Daniel, Isaac, "
             "the burner, the Saltgate, the Gullwater, Bracken Isle, the Flighted and the steam launch.", ""]
    for t in types:
        parts += [f"**{t}**", "", "| ID | Rule | Derived from |", "|---|---|---|"]
        parts += [f"| {r['id']} | {r['rule']} | {r['source']} |" for r in GUIDE["rules"] if r["type"] == t]
        parts.append("")
    parts += [f"Record layout: `{GUIDE['record_format']}`, at most {GUIDE['max_words_per_line']} words per line. "
              "Calibration: the creator-approved opening dialogue (40 lines, `Docs/Lore Build/dialogue/DIALOGUE_OPENING_FINAL.md`) "
              "passes the lint with zero findings, so the rules describe the game's real voice rather than an invented one "
              "(`python test_style_lint.py`).", "",
              "## 2. The Evaluator and Refiner loop", "",
              "```\nGenerator --text--> Evaluator --SCORE + REASON--> (score < 10?) --yes--> Refiner --rewrite--> Evaluator ... (max 3 rewrites)\n"
              "                       ^ style_lint.py evidence (vocabulary, format, length, lore continuity)\n```", "",
              "- **Generator** (`ger-style-generator`): writes what it is asked, including deliberately off-brand content. It is not shown the style guide.",
              "- **Evaluator** (`ger-style-evaluator`): grades 1-10 and replies strictly `SCORE: [X/10]` then `REASON: [...]`; never pass/fail, never rewrites. "
              "It cites rule ids and quotes the offending words so the Refiner can act on the REASON alone. A deterministic lint runs on every draft "
              "and its findings go to the Evaluator as evidence; any lint finding caps the score at 8 so a lenient grader cannot pass a provable violation.",
              "- **Refiner** (`ger-style-refiner`): takes the original text and the Evaluator's REASON and rewrites it for a perfect 10/10, keeping speaker, beat and intent.",
              "- **Loop control** (`run_loop.py`): no human input. It stops when the score is 10/10 or after 3 rewrites.", "",
              "The three agents are also Claude Code agents (`.claude/agents/ger-style-*.md`), generated from the same prompts by `build.py`.", "",
              "### Evaluator prompt (exact)", "", "```", render("evaluator"), "```", "",
              "### Refiner prompt (exact)", "", "```", render("refiner"), "```", "",
              "### Generator prompt (exact)", "", "```", render("generator"), "```", "",
              "## 3. Before / After demonstration", "",
              f"Run `{run.name}` (`python run_loop.py`, Claude Code headless, model alias `sonnet`). The Generator output below is real, unedited, "
              "and was produced from requests designed to break one class of rule each.", ""]
    for cid, title in EXAMPLES:
        if (run / f"{cid}.json").exists():
            parts.append(example(run, cid, title))
    parts += ["## 4. Pipeline connection", "", PIPELINE_SENTENCE, ""]
    (HERE / "SUBMISSION.md").write_text("\n".join(parts), encoding="utf-8")
    print("wrote SUBMISSION.md from", run.name)


if __name__ == "__main__":
    main()
