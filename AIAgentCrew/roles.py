"""Agent roster for Lighting the Storm.

Taken from the design submission (updated 1 October 2026, post-review), Part 3
"AI Architecture" and Part 4 "Agent roles and working rules": ten worker roles,
each owning one department, overseen by two orchestrators. These are roles, not
ten agents running at once; one agent takes successive bounded tasks.

`in_crossing_crew` marks the roles this crew actually runs for the return
crossing. The other roles are defined here so the roster matches the design
document, and are built the same way when their gate needs them.
"""
from dataclasses import dataclass


@dataclass(frozen=True)
class Role:
    name: str                  # CrewAI role string; matches the design submission
    kind: str                  # "orchestrator" or "worker"
    pillars: tuple[int, ...]   # pillars the role serves
    owns: str                  # what it owns (Part 4 table; orchestrators: responsibility)
    input_contract: str        # what it needs from others
    builds: tuple[str, ...]    # what it builds
    review_gate: str           # how its work is accepted
    in_crossing_crew: bool = False


ORCHESTRATORS = (
    Role("Production Orchestrator", "orchestrator", (1, 2, 3, 4),
         "Turns a goal or gate into task briefs, assigns workers, orders dependencies, tracks the "
         "schedule, holds event IDs and contracts, assembles the integrated build",
         "Creator goal, decisions log, schedule",
         ("Task briefs", "Dependency order", "Integrated build", "REPORT.md"),
         "Escalates when an exit test is missed, a contract must change, two tasks conflict, or week 5 slips",
         True),
    Role("Canon and Review Orchestrator", "orchestrator", (1, 2, 3, 4),
         "Checks every handoff against the pillars, the scope rule and the decisions log; blocks work "
         "that decides unresolved story; keeps the decisions log current",
         "Every worker handoff, decisions log",
         ("Pillar and decisions-log checks", "Review verdicts", "Decisions log updates"),
         "Escalates when a canon question appears (Ted, retry model, penalty rules) or a pillar test fails",
         True),
)

WORKERS = (
    Role("Boat / Physics agent", "worker", (4,),
         "Boat scene, controller, tuning resource",
         "Hazard forecast API, one steering axis, recovery event",
         ("Boat controller at one fixed speed", "Hazard collisions and recovery",
          "Tuning values held as data", "Stretch: wave layer behind an on/off setting"),
         "The developer plays the week-2 steering spike and makes the go/no-go call on feel"),
    Role("Player Movement agent", "worker", (3, 4),
         "On-foot controller spec: walking, turning, collision handling and glitch checks",
         "Level collision rules, input actions, capsule and camera facts",
         ("Player movement tuning as data", "Glitch checks with a repeatable test for each",
          "Smooth turning and moving at the same time"),
         "The developer walks the island with no snagging, jitter or camera lag (added after the Oct 2026 design submission)"),
    Role("Level Layout agent", "worker", (3,),
         "Greybox scenes, anchors",
         "Location sizes, beacon visibility, interaction anchors",
         ("Greybox lighthouse, sea corridor and outpost", "Interaction anchors for other agents",
          "Sightline checks for the window view and the ending"),
         "Traversal and sightline checks in the engine"),
    Role("Gameplay / Systems agent", "worker", (1, 2),
         "Phase controller, save state, repairs, deadline",
         "Stable event and save IDs",
         ("Phase controller and save state", "Repair jobs from data",
          "Sailors' arrival trigger, island gate, boarding and return-departure clock trigger",
          "Hidden deadline, cargo, win and fail"),
         "The 10-minute slice plays end to end with no dead ends"),
    Role("Hazard Forecast agent", "worker", (2, 4),
         "Shared forecast, safe-route signal",
         "Route data, hazard placement, difficulty presets",
         ("Shared hazard forecast", "One safe-route signal", "Difficulty-based call timing"),
         "Jeff's calls never disagree with the world; one route only until branching is approved",
         True),
    Role("Story / Fail-State agent", "worker", (1, 3, 4),
         "Fail presentation, ship reveal, Ted's lamp staging",
         "Fail-state contract, phase events, decisions log",
         ("Fail sequence: horn, crash, silence, Failed screen", "Reason line",
          "Ship reveal and Ted's lamp staging"),
         "A tester can say why they failed from every expiry location"),
    Role("Lighting agent", "worker", (1, 2, 4),
         "Light rigs, visibility presets",
         "Scene anchors, performance budget, visibility rules",
         ("Beacon sweep and dynamic lights", "Storm visibility presets by phase",
          "Minimum hazard-visibility rules"),
         "The beacon and hazards stay legible at every phase"),
    Role("Sound agent", "worker", (2, 4),
         "Audio banks, mix states",
         "Escalation events, speaker priority",
         ("Layered wind, rain, machinery, foghorn and ship impact", "State-based mix and escalation",
          "Source list and licences"),
         "Jeff's warnings remain audible at peak storm"),
    Role("Asset agent", "worker", (3, 4),
         "Source meshes, import settings",
         "Scale, pivot, collision, palette, reference sheet",
         ("First-pass props and set dressing", "Source meshes and import notes",
          "Provenance records for every asset"),
         "Assets import cleanly and fit the approved reference sheet"),
    Role("Dialogue agent", "worker", (3, 4),
         "Dialogue and journal data",
         "Character voices, phase events, ambiguity rule",
         ("Lines for Ted, Jeff and Daniel as data", "Subtitle and difficulty variants", "Journal text"),
         "The developer approves voice and lore before anything is recorded",
         True),
    Role("QA agent", "worker", (1, 2, 3, 4),
         "Scenario list, bug reports",
         "Playable build, event log, acceptance checklist",
         ("Reproducible scenario list", "Bug reports against acceptance checks",
          "Checks with waves on and off"),
         "The developer reproduces and prioritises each finding"),
)

ROSTER = ORCHESTRATORS + WORKERS

# The agents the return-crossing crew runs, in pipeline order.
CROSSING_PIPELINE = (
    "Production Orchestrator",
    "Hazard Forecast agent",
    "Dialogue agent",
    "Canon and Review Orchestrator",
)


# The agents the world crew runs (world_crew.py), in pipeline order.
WORLD_PIPELINE = (
    "Boat / Physics agent",
    "Player Movement agent",
    "Lighting agent",
    "Canon and Review Orchestrator",
)

# The agent the asset review crew runs (asset_crew.py), once per FAL submission.
ASSET_PIPELINE = ("Asset agent",)


# The agents the opening-dialogue crew runs (dialogue_crew.py), in pipeline order.
DIALOGUE_PIPELINE = (
    "Production Orchestrator",
    "Dialogue agent",
    "Canon and Review Orchestrator",
)


def role(name: str) -> Role:
    return next(r for r in ROSTER if r.name == name)


assert len(ORCHESTRATORS) == 2 and len(WORKERS) == 11
assert {r.name for r in ROSTER if r.in_crossing_crew} == set(CROSSING_PIPELINE)
