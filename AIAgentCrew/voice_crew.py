"""Voice Casting Crew - voice categorisation and ElevenLabs prep for the opening dialogue.

  1. Sound agent                    validated dialogue + canon voice notes -> VoiceCastingPlan
  2. Canon and Review Orchestrator  dialogue + plan                         -> ReviewReport

Same pattern as the other crews: schema + deterministic guardrail + retry feedback. Nothing is sent to
ElevenLabs; the integrator only writes request files for the creator to approve.
"""
import json

from crewai import Agent, Crew, Process, Task

from canon import dialogue_canon_block
from dialogue_crew import JSON_RULE, REVIEWER_BACKSTORY, _schema
from roles import VOICE_PIPELINE
from schemas import ReviewReport
from validators import check_review, parse
from voice_schemas import VoiceCastingPlan
from voice_validators import ALLOWED_TAGS, CANON_VOICE, MAX_TAGS_PER_LINE, check_voice_plan

SOUND_BACKSTORY = (
    "You cast and direct voices for Lighting the Storm, a folk-horror game. You write ElevenLabs Voice Design "
    "prompts that describe only the sound (age, timbre, accent, pace, energy), never a real person or actor. "
    "You never rewrite a script line: you only add a few [audio tags] and pick expressive settings. You keep "
    "the three coastfolk voices clearly distinct so players can tell them apart in a storm."
)


def build_voice_crew(llm, dialogue, verbose: bool = True, state: dict | None = None):
    state = {} if state is None else state
    state.setdefault("log", [])
    state["dialogue"] = dialogue
    attempts: dict[str, int] = {}

    def record(task, agent, ok, errors):
        attempts[task] = attempts.get(task, 0) + 1
        state["log"].append({"task": task, "agent": agent, "attempt": attempts[task], "passed": ok, "errors": errors})

    def plan_guard(out):
        plan, err = parse(out.raw, VoiceCastingPlan)
        problems = [err] if err else check_voice_plan(plan, dialogue)
        record("VOICE_CASTING_PLAN", VOICE_PIPELINE[0], not problems, problems)
        if problems:
            return False, "Fix these contract violations: " + " | ".join(problems)
        state["voice_plan"] = plan
        return True, plan.model_dump_json(indent=2)

    def review_guard(out):
        report, err = parse(out.raw, ReviewReport)
        problems = [err] if err else check_review(report)
        record("VOICE_CASTING_REVIEW", VOICE_PIPELINE[1], not problems, problems)
        if problems:
            return False, " | ".join(problems)
        state["voice_review"] = report
        return True, report.model_dump_json(indent=2)

    common = dict(llm=llm, allow_delegation=False, verbose=verbose, max_iter=5)
    sound = Agent(role=VOICE_PIPELINE[0],
                  goal="Categorise and describe a distinct voice for each speaker and prepare every line for ElevenLabs.",
                  backstory=SOUND_BACKSTORY, **common)
    reviewer = Agent(role=VOICE_PIPELINE[1],
                     goal="Check the casting plan against canon, the pillars and the Decisions log; write the verdict.",
                     backstory=REVIEWER_BACKSTORY, **common)

    script = json.dumps([{"line_id": l.line_id, "speaker": l.speaker, "kind": l.kind, "text": l.text,
                          "delivery": l.delivery} for l in dialogue.lines])
    canon_voices = "\n".join(f"- {k}: {v['source']}" for k, v in CANON_VOICE.items())

    plan_task = Task(
        description=(
            f"[TASK VOICE_CASTING_PLAN]\n{dialogue_canon_block()}\n\nCANON CASTING NOTES (Lore Build):\n{canon_voices}\n\n"
            "Produce the voice casting plan for the opening dialogue. For TED, ARTHUR and DANIEL write one profile "
            "each: a casting category, gender, age band, accent, timbre, pace, energy, a Voice Design "
            "voice_description (sound only: no real people, actors or 'sounds like'; it must carry the canon "
            "casting note words), a preview_text of 100-1000 characters made of that character's real script lines "
            "joined together, model ids (design_model_id eleven_ttv_v3, tts_model_id eleven_v3), voice settings, "
            "canon_basis and a contrast_note saying how the voice differs from the other two. Then give every script "
            "line an entry in `lines`: tts_text is the script text EXACTLY as given, optionally with at most "
            f"{MAX_TAGS_PER_LINE} [audio tags] taken only from {sorted(ALLOWED_TAGS)} that match the line's delivery "
            "note (for example '[coughs]' where Ted coughs). Set stability lower for frantic or shouted delivery and "
            "higher for flat, slow and clear delivery. Use ONLY single quotes inside text values. Put anything the "
            "creator should decide in `suggestions` and `open_creator_decisions`; do not decide which lines are "
            f"voiced.\n\nSCRIPT ({len(dialogue.lines)} lines):\n{script}\n\n{JSON_RULE}{_schema(VoiceCastingPlan)}"
        ),
        expected_output="A VoiceCastingPlan JSON object.", agent=sound, guardrail=plan_guard, guardrail_max_retries=3)
    review_task = Task(
        description=(
            f"[TASK VOICE_CASTING_REVIEW]\n{dialogue_canon_block()}\n\nReview the VoiceCastingPlan against the script and "
            "canon. Write exactly four pillar_checks (one per pillar, in order) and decisions_log_checks covering at "
            "least: canon casting notes honoured, no real-person likeness, script text unchanged, no timer wording, "
            "no supernatural confirmation, voices distinct. Each check has result pass/fail and concrete evidence "
            "citing line IDs or speakers. verdict is PASS only if every check passes. Carry forward "
            "open_creator_decisions. handoff_summary is 2-4 factual sentences.\n\n"
            f"{JSON_RULE}{_schema(ReviewReport)}"
        ),
        expected_output="A ReviewReport JSON object.", agent=reviewer, context=[plan_task],
        guardrail=review_guard, guardrail_max_retries=3)

    crew = Crew(agents=[sound, reviewer], tasks=[plan_task, review_task], process=Process.sequential, verbose=verbose)
    return crew, state
