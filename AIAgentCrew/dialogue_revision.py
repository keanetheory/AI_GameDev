"""Revision round for the Opening Dialogue Crew.

When the Canon and Review Orchestrator returns REVISE, the crew does not stop: the reviewer's failed
checks and issues are fed back to the Dialogue agent, who writes a corrected dialogue, which goes
through the SAME guardrail (check_dialogue) and is then reviewed again.

  Dialogue agent (revision)           brief + previous dialogue + reviewer issues -> OpeningDialogue
  Canon and Review Orchestrator       brief + revised dialogue + previous issues  -> ReviewReport

Every attempt is added to state["log"] (task names OPENING_DIALOGUE_REVISE_<n> and
OPENING_DIALOGUE_REREVIEW_<n>) and the superseded dialogue and review are kept in state["history"].
"""
import json

from crewai import Agent, Crew, Process, Task

from canon import dialogue_canon_block
from dialogue_crew import JSON_RULE, REVIEWER_BACKSTORY, WRITER_BACKSTORY, _schema
from roles import DIALOGUE_PIPELINE
from schemas import OpeningDialogue, ReviewReport
from validators import check_dialogue, check_review, check_review_claims, parse


def build_revision_crew(llm, state: dict, round_no: int, verbose: bool = True):
    """Return (crew, state) for one revision round. Needs state to hold the brief, dialogue and review."""
    canon = dialogue_canon_block()
    brief, prev, review = state["dialogue_brief"], state["dialogue"], state["dialogue_review"]
    state.setdefault("history", []).append({"round": round_no - 1, "dialogue": prev, "review": review})
    attempts: dict[str, int] = {}
    t_revise, t_rereview = f"OPENING_DIALOGUE_REVISE_{round_no}", f"OPENING_DIALOGUE_REREVIEW_{round_no}"

    def record(task: str, agent: str, ok: bool, errors: list[str]):
        attempts[task] = attempts.get(task, 0) + 1
        state["log"].append({"task": task, "agent": agent, "attempt": attempts[task],
                             "passed": ok, "errors": errors})

    def revise_guard(out):
        sheet, err = parse(out.raw, OpeningDialogue)
        problems = [err] if err else check_dialogue(sheet, brief)
        record(t_revise, DIALOGUE_PIPELINE[1], not problems, problems)
        if problems:
            return False, "Fix these contract violations: " + " | ".join(problems)
        state["dialogue"] = sheet
        return True, sheet.model_dump_json(indent=2)

    def rereview_guard(out):
        report, err = parse(out.raw, ReviewReport)
        problems = [err] if err else check_review(report) + check_review_claims(report, state["dialogue"])
        record(t_rereview, DIALOGUE_PIPELINE[2], not problems, problems)
        if problems:
            return False, " | ".join(problems)
        state["dialogue_review"] = report
        return True, report.model_dump_json(indent=2)

    common = dict(llm=llm, allow_delegation=False, verbose=verbose, max_iter=5)
    writer = Agent(role=DIALOGUE_PIPELINE[1],
                   goal="Revise the opening dialogue so every reviewer issue is resolved, changing as little else as possible.",
                   backstory=WRITER_BACKSTORY, **common)
    reviewer = Agent(role=DIALOGUE_PIPELINE[2],
                     goal="Re-check the revised dialogue against the four pillars and the Decisions log, and write the verdict.",
                     backstory=REVIEWER_BACKSTORY, **common)

    failed = [{"check": c.check, "evidence": c.evidence} for c in review.pillar_checks + review.decisions_log_checks
              if c.result == "fail"]
    feedback = json.dumps({"verdict": review.verdict, "failed_checks": failed, "issues": review.issues}, indent=1)

    revise_task = Task(
        description=(
            f"[TASK {t_revise}]\n{canon}\n\nThe reviewer returned REVISE on your previous dialogue. Fix every issue "
            "below. Keep every line that is not affected (same line_id, same text) so the creator's approved "
            "lines do not change, and return the COMPLETE revised OpeningDialogue: all lines and all journal "
            "entries, not a patch. A line's step must equal the step of its trigger event (optional events are "
            "step 0). Do not add Saltgate detail, and keep Daniel's lines on basement events. Use ONLY single "
            "quotes inside text values so the JSON stays valid.\n\n"
            f"DIALOGUE BRIEF:\n{brief.model_dump_json()}\n\nPREVIOUS DIALOGUE:\n{prev.model_dump_json(exclude_none=True)}\n\n"
            f"REVIEWER FEEDBACK:\n{feedback}\n\n{JSON_RULE}{_schema(OpeningDialogue)}"
        ),
        expected_output="A complete, revised OpeningDialogue JSON object.",
        agent=writer, guardrail=revise_guard, guardrail_max_retries=3,
    )
    rereview_task = Task(
        description=(
            f"[TASK {t_rereview}]\n{canon}\n\nRe-review the REVISED dialogue from the previous task against the brief. "
            "Write exactly four pillar_checks (one per pillar, in order) and decisions_log_checks covering at least: "
            "player term, ship reveal at boarding, no supernatural confirmation, 'burner' not 'lamp head', Daniel "
            "stays in the basement, line length, no significant Saltgate detail, the canon beat order (burner found in step 3, never step 1). Each check has result pass/fail "
            "and evidence citing line IDs; any count you quote must match the data. verdict is PASS only if every "
            "check passes. List in `issues` only problems that are STILL unresolved or newly introduced. Earlier "
            f"issues to confirm as fixed or not:\n{json.dumps(review.issues, indent=1)}\n\n"
            f"DIALOGUE BRIEF:\n{brief.model_dump_json()}\n\n{JSON_RULE}{_schema(ReviewReport)}"
        ),
        expected_output="A ReviewReport JSON object.",
        agent=reviewer, context=[revise_task], guardrail=rereview_guard, guardrail_max_retries=3,
    )
    crew = Crew(agents=[writer, reviewer], tasks=[revise_task, rereview_task], process=Process.sequential,
                verbose=verbose)
    return crew, state
