"""Storm Crossing Crew - CrewAI pipeline for Lighting the Storm.

Four agents run in sequence, each consuming the previous agent's validated output:

  1. Production Orchestrator   creator goal + canon      -> CrossingBrief
  2. Hazard Forecast Designer  CrossingBrief             -> HazardForecast
  3. Companion Dialogue Writer HazardForecast + brief    -> JeffCallSheet
  4. Canon & Review Orchestrator  all three              -> ReviewReport

Each task has a guardrail that validates its JSON against the shared contract
(schemas.py + validators.py). A failing check is sent back to the agent as
feedback and the agent retries, so bad data never reaches the next agent.
"""
import json

from crewai import Agent, Crew, Process, Task

from canon import canon_block
from schemas import CrossingBrief, HazardForecast, JeffCallSheet, ReviewReport
from validators import check_brief, check_calls, check_forecast, check_review, parse

JSON_RULE = (
    "Respond with ONLY a single JSON object that matches the JSON schema below. "
    "No markdown fences, no commentary.\nJSON SCHEMA:\n"
)


def _schema(model) -> str:
    return json.dumps(model.model_json_schema(), indent=1)


def build_crew(llm, goal: str, preset: str, segments: int, verbose: bool = True, state: dict | None = None):
    """Return (crew, state). `state` collects each validated handoff as it is produced."""
    canon = canon_block()
    state = {} if state is None else state

    # ---------------- guardrails (contract enforcement between agents) ----------------
    def brief_guard(out):
        brief, err = parse(out.raw, CrossingBrief)
        if err:
            return False, err
        problems = check_brief(brief)
        if len(brief.segments) != segments:
            problems.append(f"The creator asked for exactly {segments} segments.")
        if brief.difficulty_preset != preset:
            problems.append(f"difficulty_preset must be '{preset}'.")
        if problems:
            return False, "Fix these contract violations: " + " | ".join(problems)
        state["brief"] = brief
        return True, brief.model_dump_json(indent=2)

    def forecast_guard(out):
        fc, err = parse(out.raw, HazardForecast)
        if err:
            return False, err
        problems = check_forecast(fc, state["brief"])
        if problems:
            return False, "Fix these contract violations: " + " | ".join(problems)
        state["forecast"] = fc
        return True, fc.model_dump_json(indent=2)

    def calls_guard(out):
        sheet, err = parse(out.raw, JeffCallSheet)
        if err:
            return False, err
        problems = check_calls(sheet, state["forecast"], state["brief"])
        if problems:
            return False, "Fix these contract violations: " + " | ".join(problems)
        state["calls"] = sheet
        return True, sheet.model_dump_json(indent=2)

    def review_guard(out):
        report, err = parse(out.raw, ReviewReport)
        if err:
            return False, err
        problems = check_review(report)
        if problems:
            return False, " | ".join(problems)
        state["review"] = report
        return True, report.model_dump_json(indent=2)

    # ---------------- agents ----------------
    common = dict(llm=llm, allow_delegation=False, verbose=verbose, max_iter=5)

    orchestrator = Agent(
        role="Production Orchestrator",
        goal="Turn the creator's goal into a precise, canon-safe task brief for the return crossing.",
        backstory=(
            "You plan and sequence work for a solo developer making Lighting the Storm in Godot 4. "
            "You write briefs with stable IDs, tuning values and constraints. You never decide "
            "open canon questions; you list them for the creator."
        ),
        **common,
    )
    hazard_designer = Agent(
        role="Hazard Forecast Designer",
        goal="Place readable hazards and one safe-route signal per segment, exactly as the brief specifies.",
        backstory=(
            "You own the shared hazard forecast that the boat, the hazards and Jeff's calls all read. "
            "Your rule: dread you can read. A first-time player steering with one control at one fixed "
            "speed must always be able to see the threat and the way through."
        ),
        **common,
    )
    dialogue_writer = Agent(
        role="Companion Dialogue Writer",
        goal="Write Jeff's shouted direction calls so they match the hazard forecast exactly.",
        backstory=(
            "You write for Jeff, an older, coarse seaman who is reluctant but wants to save the "
            "passenger ship. His calls are short, practical and shouted over wind. He never mentions "
            "a timer, never contradicts the safe route, and never confirms anything supernatural."
        ),
        **common,
    )
    reviewer = Agent(
        role="Canon and Review Orchestrator",
        goal="Check the whole crossing package against the four pillars and the Decisions log, and write the handoff verdict.",
        backstory=(
            "You guard canon for Lighting the Storm. You block work that breaks a pillar, uses an "
            "unapproved feature (waves, route branching, visible timers) or silently decides an open "
            "creator question. You report facts, not intentions."
        ),
        **common,
    )

    # ---------------- tasks ----------------
    brief_task = Task(
        description=(
            f"{canon}\n\nCREATOR GOAL: {goal}\n\n"
            f"Write the task brief for the Gate 1 RETURN crossing data. Use task_id 'GATE1_RETURN_CROSSING', "
            f"difficulty_preset '{preset}', exactly {segments} segments (SEG_01..). Choose a fixed boat speed "
            f"and Jeff call lead distance. Hazard density must rise along the route and route width must "
            f"narrow or hold (storm split: position-driven, never time-driven). allowed_hazards may only "
            f"include rock, reef, buoy, debris. List the constraints workers must follow and the open "
            f"creator decisions this work touches.\n\n{JSON_RULE}{_schema(CrossingBrief)}"
        ),
        expected_output="A CrossingBrief JSON object.",
        agent=orchestrator,
        guardrail=brief_guard,
        guardrail_max_retries=3,
    )
    forecast_task = Task(
        description=(
            f"{canon}\n\nUsing the CrossingBrief from the previous task, build the shared hazard forecast "
            f"for the return crossing. For every segment pick ONE safe_lane (left, centre or right) and "
            f"place hazards ONLY in the other lanes. The number of hazards per segment must never fall "
            f"along the route and should reflect hazard_density. Use hazard IDs HZ_<seg>_<index>, safe "
            f"points SAFE_<seg>, dock_zone_id DOCK_LIGHTHOUSE. Give each hazard a readability_cue "
            f"(silhouette, buoy bell, white water, beacon glint) so it is readable at the segment's "
            f"min_visibility_m.\n\n{JSON_RULE}{_schema(HazardForecast)}"
        ),
        expected_output="A HazardForecast JSON object.",
        agent=hazard_designer,
        context=[brief_task],
        guardrail=forecast_guard,
        guardrail_max_retries=3,
    )
    calls_task = Task(
        description=(
            f"{canon}\n\nUsing the CrossingBrief and the HazardForecast, write one Jeff direction call per "
            f"segment (call_id JEFF_RET_<seg>). Each call's direction MUST equal that segment's safe_lane, "
            f"and lead_m must be at least the brief's jeff_call_lead_m. Lines: max 14 words, shouted, "
            f"left/right/centre in plain words so the player is never confused; no timers or numbers of "
            f"seconds. Subtitles start 'JEFF: '. Also write arrival_line, Jeff's line on reaching the "
            f"lighthouse jetty, in the spirit of 'go go go, don't wait for me'.\n\n"
            f"{JSON_RULE}{_schema(JeffCallSheet)}"
        ),
        expected_output="A JeffCallSheet JSON object.",
        agent=dialogue_writer,
        context=[brief_task, forecast_task],
        guardrail=calls_guard,
        guardrail_max_retries=3,
    )
    review_task = Task(
        description=(
            f"{canon}\n\nReview the CrossingBrief, HazardForecast and JeffCallSheet together. Write exactly "
            f"four pillar_checks (one per pillar, in order) and decisions_log_checks covering at least: "
            f"storm split, no waves, single safe route (no branching), Jeff never disagrees with the "
            f"forecast, no visible timer, recoverable collisions. Each check has result pass/fail and "
            f"concrete evidence (cite IDs). verdict is PASS only if every check passes, otherwise REVISE "
            f"with issues listed. Carry forward open_creator_decisions. handoff_summary is 2-4 factual "
            f"sentences for HANDOFF.md.\n\n{JSON_RULE}{_schema(ReviewReport)}"
        ),
        expected_output="A ReviewReport JSON object.",
        agent=reviewer,
        context=[brief_task, forecast_task, calls_task],
        guardrail=review_guard,
        guardrail_max_retries=3,
    )

    crew = Crew(
        agents=[orchestrator, hazard_designer, dialogue_writer, reviewer],
        tasks=[brief_task, forecast_task, calls_task, review_task],
        process=Process.sequential,
        verbose=verbose,
    )
    return crew, state
