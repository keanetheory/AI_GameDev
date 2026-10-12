"""Offline scripted LLM for the opening-dialogue crew (no API key needed).

Like offline_llm.py it runs the REAL CrewAI agents, tasks, context passing and guardrails; only the
model's text is scripted. The Production Orchestrator's brief is built from canon.py. The Dialogue
agent replays the draft in offline_dialogue_draft.json (the 61 lines first written for the creator to
review). The Canon and Review Orchestrator builds its evidence from the validated handoffs.

Like the crossing crew's Dialogue agent, the first attempt deliberately contains faults so the
guardrail feedback loop (validator -> agent retry) is exercised on every offline run. Pass
inject_errors=False to replay the clean draft straight away.

This is NOT the creative engine: run without --offline to have a real model write the lines.
"""
import copy
import json
from pathlib import Path
from typing import Any

from crewai import BaseLLM

from validators import SHIP_WORD
from canon import (MAX_WORDS_PER_LINE, OPENING_DIALOGUE_RULES, OPENING_EVENTS, OPENING_OPEN_DECISIONS,
                   OPENING_STEPS, PLAYER_TERM, SHIP_NAMED_FROM)

DRAFT = Path(__file__).with_name("offline_dialogue_draft.json")

# Faults the first offline attempt contains (each one is caught by a different check).
FAULTS = {
    "TED_S1_01": "Hrmph. You're the new apprentice. Welcome to Bracken Isle. Try not to fall off it.",
    "TED_S2_01": "Oi! Window! The passenger ship's lights are out there, and a rowboat is tied up at the dock.",
    "TED_S3_02": "Small thing, under a foot tall. Brass and iron, thick glass. The lamp head's spare. Can't miss it.",
}


class OfflineDialogueLLM(BaseLLM):
    model: str = "offline-scripted-dialogue"
    state: dict = {}
    max_words: int = MAX_WORDS_PER_LINE
    inject_errors: bool = True
    first_attempt_done: bool = False
    simulate_revise: bool = False  # first review returns REVISE, to exercise the revision loop offline

    def supports_function_calling(self) -> bool:
        return False

    def call(self, messages, tools=None, callbacks=None, available_functions=None,
             from_task=None, from_agent=None, response_model=None) -> Any:
        text = json.dumps(messages) if not isinstance(messages, str) else messages
        if "[TASK OPENING_DIALOGUE_REREVIEW" in text:
            payload = self._review()
        elif "[TASK OPENING_DIALOGUE_REVIEW]" in text:
            payload = self._review(revise=self.simulate_revise)
        elif "[TASK OPENING_DIALOGUE_REVISE" in text:
            payload = self._dialogue(corrected=True)
        elif "[TASK OPENING_DIALOGUE_WRITE]" in text:
            payload = self._dialogue(corrected="Fix these contract violations" in text)
        else:
            payload = self._brief()
        return "Thought: I now can give a great answer\nFinal Answer: " + json.dumps(payload)

    # -------- scripted outputs --------
    def _brief(self):
        return {
            "task_id": "GATE1_OPENING_DIALOGUE",
            "slice": "Gate 1 opening: steps 1-3 (coal, sailors, burner)",
            "max_words_per_line": self.max_words,
            "player_term": PLAYER_TERM,
            "speakers": ["TED", "JEFF", "DANIEL"],
            "steps": OPENING_STEPS,
            "events": [{"event_id": e[0], "step": e[1], "note": e[2], "existing_crew_event": e[3]}
                       for e in OPENING_EVENTS],
            "constraints": OPENING_DIALOGUE_RULES,
            "open_creator_decisions": OPENING_OPEN_DECISIONS,
        }

    def _dialogue(self, corrected: bool):
        draft = json.loads(DRAFT.read_text(encoding="utf-8"))
        if self.inject_errors and not corrected and not self.first_attempt_done:
            draft = copy.deepcopy(draft)
            for ln in draft["lines"]:
                if ln["line_id"] in FAULTS:
                    ln["text"] = FAULTS[ln["line_id"]]
                    ln["subtitle"] = f"{ln['speaker']}: {ln['text']}"
        if not corrected:
            self.first_attempt_done = True
        return draft

    def _review(self, revise: bool = False):
        brief, dlg = self.state["dialogue_brief"], self.state["dialogue"]
        lines = dlg.lines
        longest = max(lines, key=lambda x: len(x.text.split()))
        speakers = {s: sum(1 for x in lines if x.speaker == s) for s in brief.speakers}
        groups = {x.group for x in lines if x.group}
        ladders = [e.event_id for e in brief.events if e.event_id.startswith("IDLE")]
        order = [e.event_id for e in brief.events]
        ship_lines = sorted((x for x in lines if SHIP_WORD.search(x.text) and x.trigger in order),
                            key=lambda x: order.index(x.trigger))
        first_ship = ship_lines[0] if ship_lines else None
        n_term = sum(1 for x in lines if brief.player_term in x.text.lower())
        p = lambda c, e: {"check": c, "result": "pass", "evidence": e}
        report = self._report(p, brief, dlg, lines, longest, speakers, groups, ladders, first_ship, n_term)
        if revise:  # simulated reviewer finding, for testing the loop without a model
            report["verdict"] = "REVISE"
            report["decisions_log_checks"][-1] = {"check": "Line length", "result": "fail",
                                                  "evidence": "Simulated finding to exercise the revision loop."}
            report["issues"] = ["Simulated issue: re-check line length (offline loop test)."]
        return report

    def _report(self, p, brief, dlg, lines, longest, speakers, groups, ladders, first_ship, n_term):
        return {
            "verdict": "PASS",
            "pillar_checks": [
                p("1. The light must return",
                  "Every objective points back to the beacon: boiler (TED_S1_05), burner briefing (TED_S3_03), "
                  "ship stakes (TED_S3_06)."),
                p("2. The storm sets the clock",
                  f"No timer, deadline or number in any of {len(lines)} lines or {len(dlg.journal)} journal entries."),
                p("3. Your hands, your eyes",
                  "Guidance is spoken by Ted and Jeff; assist hints are opt-in text, never markers. "
                  f"The player is only called '{brief.player_term}' and never speaks."),
                p("4. Dread you can read",
                  f"Each step has an objective line and a {len(ladders)}-ladder nudge system; "
                  "whispers and the poster stay ambiguous (TED_OPT_01, TED_OPT_02)."),
            ],
            "decisions_log_checks": [
                p("Player term", f"No line says 'apprentice'; '{brief.player_term}' appears in {n_term} lines."),
                p("Ship reveal at boarding", f"First line naming the ship is {first_ship.line_id} on {first_ship.trigger} "
                                             f"(allowed from {SHIP_NAMED_FROM})."),
                p("No supernatural confirmation", "No line names a ghost, curse or monster."),
                p("Say burner", "No line says 'lamp head'."),
                p("Daniel stays in the basement", "DANIEL_S2_03 is staged in the basement; no later Daniel line leaves it."),
                p("Line length", f"Longest line is {longest.line_id} at {len(longest.text.split())} words "
                                 f"(limit {brief.max_words_per_line})."),
            ],
            "issues": [],
            "open_creator_decisions": brief.open_creator_decisions + ["Creator to approve all voices before recording"],
            "handoff_summary": (f"Opening dialogue for Gate 1: {len(lines)} lines "
                                f"(Ted {speakers.get('TED', 0)}, Jeff {speakers.get('JEFF', 0)}, "
                                f"Daniel {speakers.get('DANIEL', 0)}), {len(groups)} alternate groups, "
                                f"{len(ladders)} nudge ladders, {len(dlg.journal)} journal entries. "
                                "All contract checks pass. Voice and lore need creator approval before recording."),
        }
