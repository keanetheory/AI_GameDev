"""World crew - CrewAI pipeline for Lighting the Storm.

Three specialist agents and the reviewer, run in sequence, each output validated before the next starts:

  1. Boat / Physics agent            canon + lore            -> BoatSpec            (dock <-> port, fixed speed, A/D steering)
  2. Player Movement agent           canon + known issues    -> PlayerMovementSpec  (smooth walking and turning)
  3. Lighting agent                  canon + style guide     -> LightingSpec        (moon, lightning, lighthouse, Saint Calder)
  4. Canon and Review Orchestrator   all three               -> ReviewReport

The Tide / Wave agent is NOT in this crew on purpose: it is built after a traversable Godot environment exists.
The Boat spec carries a tide_hook and waves_enabled = false so that agent has a place to plug in.
"""
import json

from crewai import Agent, Crew, Process, Task

from roles import WORLD_PIPELINE
from schemas import ReviewReport
from style_guide import StyleGuide, style_block
from validators import check_review, parse
from world_canon import boat_canon, lighting_canon, player_canon, world_canon_block
from world_schemas import BoatSpec, LightingSpec, PlayerMovementSpec
from world_validators import check_boat, check_lighting, check_player

JSON_RULE = (
    "Respond with ONLY a single JSON object that matches the JSON schema below. "
    "No markdown fences, no commentary. Use only single quotes inside text values.\nJSON SCHEMA:\n"
)


def _schema(model) -> str:
    return json.dumps(model.model_json_schema(), indent=1)


def build_world_crew(llm, guide: StyleGuide, verbose: bool = True, state: dict | None = None):
    """Return (crew, state). `state` collects each validated handoff as it is produced."""
    state = {} if state is None else state
    canon = world_canon_block()

    def make_guard(key, model, check, record_name):
        def guard(out):
            obj, err = parse(out.raw, model)
            if err:
                return False, err
            problems = check(obj)
            if problems:
                return False, "Fix these contract violations: " + " | ".join(problems)
            state[key] = obj
            return True, obj.model_dump_json(indent=2)
        guard.__name__ = record_name
        return guard

    boat_guard = make_guard("boat", BoatSpec, check_boat, "boat_guard")
    player_guard = make_guard("player", PlayerMovementSpec, check_player, "player_guard")
    lighting_guard = make_guard("lighting", LightingSpec, lambda s: check_lighting(s, guide), "lighting_guard")
    review_guard = make_guard("review", ReviewReport, check_review, "review_guard")

    common = dict(llm=llm, allow_delegation=False, verbose=verbose, max_iter=5)
    boat_agent = Agent(
        role=WORLD_PIPELINE[0],
        goal="Specify how the steam launch travels from the lighthouse dock to the Saltgate port and back, at one fixed speed, steered only by A and D.",
        backstory=(
            "You own the boat controller for Lighting the Storm. You know the game's rule: one fixed speed, one "
            "steering axis, no throttle. You make steering smooth and forgiving so a first-time player can read the "
            "hazards and thread the channel. You never add waves or tides yourself: another agent will, later."
        ),
        **common,
    )
    player_agent = Agent(
        role=WORLD_PIPELINE[1],
        goal="Specify first-person walking so moving and turning are smooth, simultaneous and glitch-free on a rough AI-generated island.",
        backstory=(
            "You are a character-controller specialist for Godot 4.3. You know why controllers feel bad: smoothed "
            "mouse look, frame-rate dependent movement, hard stops on slopes, snagging on trimesh lips, floating "
            "after steps, camera clipping. For every glitch you write the cause, the fix and a repeatable test."
        ),
        **common,
    )
    lighting_agent = Agent(
        role=WORLD_PIPELINE[2],
        goal="Specify the whole lighting rig: eclipsed moon, lightning, the lighthouse lights and distant Saint Calder, in the locked style.",
        backstory=(
            "You light Lighting the Storm. The moon is eclipsed, so the only strong light is electric arc and steam. "
            "Storm light is cold and high-contrast; Saint Calder is a warm amber and gold glow far away. You protect "
            "hazard readability above mood, stay inside the style guide palette, never strobe, and never turn a light "
            "into a quest marker."
        ),
        **common,
    )
    reviewer = Agent(
        role=WORLD_PIPELINE[3],
        goal="Check the boat, player and lighting specs against the four pillars and the Decisions log, and write the handoff verdict.",
        backstory=(
            "You guard canon for Lighting the Storm. You block work that breaks a pillar, uses an unapproved feature "
            "(waves, branching, visible timers, markers) or silently decides an open creator question. You cite spec "
            "fields as evidence."
        ),
        **common,
    )

    boat_task = Task(
        description=(
            f"[TASK BOAT_SPEC]\n{canon}\n\n{boat_canon()}\n\n"
            "Write the BoatSpec: how the steam launch goes from DOCK_LIGHTHOUSE to DOCK_PORT (OUTBOUND) and back "
            "(RETURN). One fixed speed. Steering left and right with A and D (actions move_left and move_right); W and S "
            "have no effect. Describe steering response, maximum turn rate, a rudder that returns to centre, "
            "a little drift for weight, waypoints per leg (WP_OUT_01.., WP_RET_01..), automatic docking zones, "
            "collision recovery to a safe point, the waves_enabled=false tide_hook, and at least five handling checks "
            "(including docking, steering at full lock, releasing the keys, and threading a narrow gap). Use speed_mps 3.0 (confirmed). Put open "
            "questions in open_creator_decisions; speed, W/S and the port are already decided, so do not list them."
            f"\n\n{JSON_RULE}{_schema(BoatSpec)}"
        ),
        expected_output="A BoatSpec JSON object.", agent=boat_agent,
        guardrail=boat_guard, guardrail_max_retries=3,
    )
    player_task = Task(
        description=(
            f"[TASK PLAYER_SPEC]\n{canon}\n\n{player_canon()}\n\n"
            "Write the PlayerMovementSpec for walking the island. Give numeric tuning that is smooth and responsive "
            "(short acceleration, unsmoothed mouse look, delta-time movement, turning while moving). Include at least "
            "seven glitch_checks MOVE_01.. each with symptom, likely cause, mitigation and a repeatable test, covering at "
            "least: slopes, steps and lips, turning while moving, getting stuck in corners, falling through geometry, "
            "frame-rate dependence and camera jitter or clipping."
            f"\n\n{JSON_RULE}{_schema(PlayerMovementSpec)}"
        ),
        expected_output="A PlayerMovementSpec JSON object.", agent=player_agent,
        guardrail=player_guard, guardrail_max_retries=3,
    )
    lighting_task = Task(
        description=(
            f"[TASK LIGHTING_SPEC]\n{canon}\n\n{style_block(guide)}\n\n{lighting_canon()}\n\n"
            "Write the LightingSpec. Four phases ISLAND, OUTBOUND, RETURN, BEACON_RELIT (return is darker, foggier and "
            "more thundery than outbound; relit beacon improves visibility). The moon is absent or eclipsed. Lightning "
            "is safe (capped flash rate), driven by phase and route position, and reveals hazards. Sources must include "
            "the lighthouse beacon, arc lamp, steam glow, a boat lamp, windows, and the distant Saint Calder lights "
            "(amber and gold only, never a navigation marker). Use ONLY palette colours from the style guide. Keep "
            "dynamic lights and shadow casters within budget. Give at least four legibility_checks covering hazards, "
            "lightning, the beacon and Saint Calder."
            f"\n\n{JSON_RULE}{_schema(LightingSpec)}"
        ),
        expected_output="A LightingSpec JSON object.", agent=lighting_agent,
        guardrail=lighting_guard, guardrail_max_retries=3,
    )
    review_task = Task(
        description=(
            f"[TASK WORLD_REVIEW]\n{canon}\n\nReview the BoatSpec, PlayerMovementSpec and LightingSpec together. "
            "Write exactly four pillar_checks (one per pillar, in order) and decisions_log_checks covering at least: "
            "one fixed speed and A/D steering, no waves or tides, no timer, no markers (Saint Calder and beacon are "
            "scenery), the moon absent or eclipsed, hazards readable. Each check has result pass or fail and concrete "
            "evidence citing spec fields. verdict is PASS only if every check passes, otherwise REVISE with issues "
            "listed. Carry forward open_creator_decisions. handoff_summary is 2-4 factual sentences."
            f"\n\n{JSON_RULE}{_schema(ReviewReport)}"
        ),
        expected_output="A ReviewReport JSON object.", agent=reviewer,
        context=[boat_task, player_task, lighting_task],
        guardrail=review_guard, guardrail_max_retries=3,
    )

    crew = Crew(
        agents=[boat_agent, player_agent, lighting_agent, reviewer],
        tasks=[boat_task, player_task, lighting_task, review_task],
        process=Process.sequential, verbose=verbose,
    )
    return crew, state
