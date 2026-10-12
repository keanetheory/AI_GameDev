"""Opening Dialogue Crew - CrewAI pipeline for Lighting the Storm (Gate 1 steps 1-3).

A second pipeline beside the Storm Crossing Crew (crew.py), built from the same roster (roles.py)
and the same contract style (schemas.py + validators.py). Three agents run in sequence, each
consuming the previous agent's validated output:

  1. Production Orchestrator       creator goal + canon      -> DialogueBrief
  2. Dialogue agent                DialogueBrief             -> OpeningDialogue  (the new Dialogue task)
  3. Canon and Review Orchestrator brief + dialogue          -> ReviewReport

Each task has a guardrail. A failing check is sent back to the agent as feedback and the agent
retries (up to 3 times), so bad lines never reach the next agent or the game data. Every guardrail
attempt is recorded in state["log"] so a run leaves evidence of what the checks caught.
"""
import json

from crewai import Agent, Crew, Process, Task

from canon import MAX_WORDS_PER_LINE, OPENING_EVENTS, dialogue_canon_block
from roles import DIALOGUE_PIPELINE
from schemas import DialogueBrief, OpeningDialogue, ReviewReport
from validators import check_dialogue, check_dialogue_brief, check_review, check_review_claims, parse

EVENT_LIST = json.dumps([{"event_id": e[0], "step": e[1], "note": e[2], "existing_crew_event": e[3]}
                         for e in OPENING_EVENTS])

JSON_RULE = (
    "Respond with ONLY a single JSON object that matches the JSON schema below. "
    "No markdown fences, no commentary.\nJSON SCHEMA:\n"
)


WRITER_BACKSTORY = (
    "You write for three coastfolk characters. Ted is a gruff, snarky lighthouse master who "
    "calls city folk 'new money toffs' and introduces the setting and each objective. Jeff is a "
    "wry, wiry sailor, friendly but wary. Daniel is a light-hearted, anxious young sailor. The "
    "player never speaks and is only ever called 'the new guy', used sparingly (about one line in "
    "five at most). You never mention a timer, never confirm anything supernatural and never name "
    "the passenger ship before the boarding threshold."
)
REVIEWER_BACKSTORY = (
    "You guard canon for Lighting the Storm. You block work that breaks a pillar or silently "
    "decides an open creator question. You report facts with line IDs as evidence, not intentions. "
    "You count carefully: any number you quote must match the data."
)


def _schema(model) -> str:
    return json.dumps(model.model_json_schema(), indent=1)


def build_dialogue_crew(llm, goal: str, verbose: bool = True, state: dict | None = None,
                        max_words: int = MAX_WORDS_PER_LINE):
    """Return (crew, state). `state` collects each validated handoff and a guardrail log."""
    canon = dialogue_canon_block()
    state = {} if state is None else state
    state.setdefault("log", [])
    attempts: dict[str, int] = {}

    def record(task: str, agent: str, ok: bool, errors: list[str]):
        attempts[task] = attempts.get(task, 0) + 1
        state["log"].append({"task": task, "agent": agent, "attempt": attempts[task],
                             "passed": ok, "errors": errors})

    # ---------------- guardrails (contract enforcement between agents) ----------------
    def brief_guard(out):
        brief, err = parse(out.raw, DialogueBrief)
        problems = [err] if err else check_dialogue_brief(brief, max_words)
        record("OPENING_DIALOGUE_BRIEF", DIALOGUE_PIPELINE[0], not problems, problems)
        if problems:
            return False, "Fix these contract violations: " + " | ".join(problems)
        state["dialogue_brief"] = brief
        return True, brief.model_dump_json(indent=2)

    def dialogue_guard(out):
        sheet, err = parse(out.raw, OpeningDialogue)
        problems = [err] if err else check_dialogue(sheet, state["dialogue_brief"])
        record("OPENING_DIALOGUE_WRITE", DIALOGUE_PIPELINE[1], not problems, problems)
        if problems:
            return False, "Fix these contract violations: " + " | ".join(problems)
        state["dialogue"] = sheet
        return True, sheet.model_dump_json(indent=2)

    def review_guard(out):
        report, err = parse(out.raw, ReviewReport)
        problems = [err] if err else check_review(report) + check_review_claims(report, state["dialogue"])
        record("OPENING_DIALOGUE_REVIEW", DIALOGUE_PIPELINE[2], not problems, problems)
        if problems:
            return False, " | ".join(problems)
        state["dialogue_review"] = report
        return True, report.model_dump_json(indent=2)

    # ---------------- agents (same roles as the roster; backstories for this task) ----------------
    common = dict(llm=llm, allow_delegation=False, verbose=verbose, max_iter=5)

    orchestrator = Agent(
        role=DIALOGUE_PIPELINE[0],
        goal="Turn the creator's goal into a precise, canon-safe brief for the opening dialogue.",
        backstory=(
            "You plan and sequence work for a solo developer making Lighting the Storm in Godot 4. "
            "You write briefs with stable event IDs, limits and constraints. You never decide open "
            "canon questions; you list them for the creator."
        ),
        **common,
    )
    dialogue_writer = Agent(
        role=DIALOGUE_PIPELINE[1],
        goal="Write the opening dialogue for Ted, Jeff and Daniel as data that follows the brief exactly.",
        backstory=WRITER_BACKSTORY,
        **common,
    )
    reviewer = Agent(
        role=DIALOGUE_PIPELINE[2],
        goal="Check the dialogue against the four pillars and the Decisions log, and write the handoff verdict.",
        backstory=REVIEWER_BACKSTORY,
        **common,
    )

    # ---------------- tasks ----------------
    brief_task = Task(
        description=(
            f"[TASK OPENING_DIALOGUE_BRIEF]\n{canon}\n\nCREATOR GOAL: {goal}\n\n"
            "Write the task brief for the Gate 1 opening dialogue. Use task_id 'GATE1_OPENING_DIALOGUE'. Set "
            f"max_words_per_line to {max_words}, player_term to the creator's decision, the three speakers TED, "
            "JEFF, DANIEL, the three steps (coal, sailors, burner), the constraints the writer must follow and "
            "the open creator decisions this work touches. The game already defines its events: copy EXACTLY "
            "these events, in this order, as the brief's events (the game reports them; do not invent, rename "
            f"or drop any):\n{EVENT_LIST}\n\n{JSON_RULE}{_schema(DialogueBrief)}"
        ),
        expected_output="A DialogueBrief JSON object.",
        agent=orchestrator,
        guardrail=brief_guard,
        guardrail_max_retries=3,
    )
    dialogue_task = Task(
        description=(
            f"[TASK OPENING_DIALOGUE_WRITE]\n{canon}\n\nUsing the DialogueBrief from the previous task, write "
            "the opening dialogue. Ted introduces the setting and each step's objective. Cover every event "
            "with at least one line (except existing crew events). Add: a nudge ladder (consecutive tiers, "
            "hint then sharper then explicit) for every IDLE_* event; alternates (same group, same trigger, "
            "at least two) for repeated or key moments; assist_text on at least one objective line per step; "
            "one journal entry per step. Line IDs look like TED_S1_01, JEFF_S3_N1a, DANIEL_OPT_01. "
            "Subtitles are 'SPEAKER: text'. Keep every line within max_words_per_line and call the player "
            "only by the brief's player_term. Every IDLE_* event in the brief needs its own lines with tier 1, "
            "2 and 3. Use ONLY single quotes inside text values (never a double quote) so the JSON stays valid; "
            f"trigger values must be event IDs from the brief.\n\n{JSON_RULE}{_schema(OpeningDialogue)}"
        ),
        expected_output="An OpeningDialogue JSON object.",
        agent=dialogue_writer,
        context=[brief_task],
        guardrail=dialogue_guard,
        guardrail_max_retries=3,
    )
    review_task = Task(
        description=(
            f"[TASK OPENING_DIALOGUE_REVIEW]\n{canon}\n\nReview the DialogueBrief and OpeningDialogue together. "
            "Write exactly four pillar_checks (one per pillar, in order) and decisions_log_checks covering at "
            "least: player term, ship reveal at boarding, no supernatural confirmation, 'burner' not 'lamp "
            "head', Daniel stays in the basement, line length. Each check has result pass/fail and concrete "
            "evidence citing line IDs. verdict is PASS only if every check passes, otherwise REVISE with "
            "issues listed. Carry forward open_creator_decisions. handoff_summary is 2-4 factual sentences "
            f"for HANDOFF.md.\n\n{JSON_RULE}{_schema(ReviewReport)}"
        ),
        expected_output="A ReviewReport JSON object.",
        agent=reviewer,
        context=[brief_task, dialogue_task],
        guardrail=review_guard,
        guardrail_max_retries=3,
    )

    crew = Crew(
        agents=[orchestrator, dialogue_writer, reviewer],
        tasks=[brief_task, dialogue_task, review_task],
        process=Process.sequential,
        verbose=verbose,
    )
    return crew, state
