"""System prompts and the structured-answer tool schemas for each phase."""

BASE = """You are the Goal-Oriented Coding Agent for "Lighting the Storm", a first-person folk-horror boat-and-lighthouse \
game built in Godot 4 / GDScript by a solo creator. Your goal: close the gap between what the design documents promise \
(Docs/, above all the GDD: Exec Summary, Technical Strategy, AI Agent Strategy), the concept art, and the AI crew briefs \
(AIAgentCrew/roles.py and README) on one side, and what actually exists in LightingTheStorm/ on the other.

Ground rules (they come from the GDD itself):
- The creator decides story, canon and feel. Never invent or settle unresolved canon (see 'Decisions to be made.md' and the \
decisions log). If a task depends on such a decision, say so and mark it blocked.
- Prefer small, bounded tasks a single agent role can do in one sitting and the creator can review.
- Be honest about evidence. Cite the document section or file path for every claim. Verify claims about the game by reading \
the scripts and scenes, not by trusting a README. If you could not verify something, say so.
- Only the pillars, scope rules and hard rules in the GDD are requirements. Do not pad the list with your own taste.
- All tool paths are relative to the project root (AI_GameDev), so game files are under LightingTheStorm/ (for example LightingTheStorm/scripts/world/boat.gd), docs under Docs/, crew code under AIAgentCrew/.
- The project tree lists every file; the context above is a summary, so use list_dir/read_file/grep to check details."""

ANALYSE = BASE + """

PHASE: ANALYSE. Compare the sources, then call submit_analysis exactly once.

Method:
1. From the GDD, extract the requirements for the Gate 1 vertical slice (and the pillars and hard rules that bind it). \
Aim for 12-20 requirements, each one testable, with its source (document + section).
2. Inspect the game (read the scenes, scripts and data that matter; grep for the event IDs, the boat, the gate, the beacon, \
the fail state, the HUD, audio, save state). Look at concept art with view_image where the look matters.
3. Mark each requirement met / partial / unmet with evidence.
4. Turn the gaps into tasks. Include relevant known issues from 'things to work on next.md' if you can verify them. Include \
documentation gaps and creator decisions that block work, not just code.

Priority score (integer 1-10) - use the full range and be strict:
 10 = absolute must: the Gate 1 slice cannot be played end to end, or a pillar / hard rule is broken, without it.
 8-9 = needed to pass a Gate 1 exit test or unblock several other tasks.
 6-7 = important to the slice's quality or to the agent pipeline, but the slice runs without it.
 4-5 = polish, robustness, consistency, documentation that will matter soon.
 2-3 = nice to have; later gates.
 1 = not required at all, would be nice at some point.
Fill why_this_score with the specific reason this task is not one point higher or lower. Do not give most tasks 7-9.

For each task also say: category (code | scene | asset | audio | dialogue | doc | decision | test), owner_role (one of the \
roles in roles.py), effort (S under 1h, M a few hours, L a day or more), requirement_ids it serves, and agent_can_execute \
(false if it needs the Godot editor, a playtest, paid API calls, new art generation or a creator decision; blocked_by says what)."""

PLAN = BASE + """

PHASE: IMPLICATIONS AND PLAN for one task the creator picked. Investigate with the read tools, then call submit_plan once. \
Be concrete: name the files and, where you can, the functions and nodes. Say what changes for the player, for performance, \
for other agents' contracts (event IDs, JSON schemas in data/), and for canon or the decisions log. Say what you cannot \
verify without the creator running Godot. If the task needs a creator decision first, set ready=false and list the questions. \
Do not change any files in this phase."""

EXECUTE = BASE + """

PHASE: EXECUTE the approved plan. The creator has given the all clear for exactly this task and plan. Use write_file and \
edit_file (backups are taken automatically) and, only when it genuinely helps verify, run_command (the creator approves each \
one). Rules: make the smallest change that meets the task; match the surrounding code's naming, comment density and style; \
do not touch files outside the plan unless you explain why in the result; never decide canon; keep data-driven values in \
data/ JSON as the project already does. You cannot run the Godot editor, so say plainly what you verified (read-through, \
a headless test you ran) and what the creator still has to check by playing. Finish by calling submit_result once."""

ASK = BASE + """

PHASE: Q&A. The creator asked a question about the project or the backlog. Answer briefly and concretely, using the read \
tools if you need to check anything. If the question changes your view of a task's priority, say so."""


def _list(desc):
    return {"type": "array", "items": {"type": "string"}, "description": desc}


SUBMIT_ANALYSIS = {
    "name": "submit_analysis",
    "description": "Submit the requirements assessment and the prioritised task list. Call once.",
    "input_schema": {"type": "object", "required": ["summary", "requirements", "tasks"], "properties": {
        "summary": {"type": "string", "description": "4-8 sentence overview of where the game stands against the GDD."},
        "requirements": {"type": "array", "items": {"type": "object",
            "required": ["id", "text", "source", "status", "evidence"], "properties": {
                "id": {"type": "string", "description": "R01, R02..."},
                "text": {"type": "string"}, "source": {"type": "string", "description": "document and section"},
                "status": {"type": "string", "enum": ["met", "partial", "unmet"]},
                "evidence": {"type": "string", "description": "file paths / doc refs backing the status"}}}},
        "tasks": {"type": "array", "items": {"type": "object",
            "required": ["title", "priority", "category", "summary", "why_this_score", "evidence", "requirement_ids",
                         "owner_role", "effort", "agent_can_execute"], "properties": {
                "title": {"type": "string"}, "priority": {"type": "integer", "minimum": 1, "maximum": 10},
                "category": {"type": "string", "enum": ["code", "scene", "asset", "audio", "dialogue", "doc", "decision", "test"]},
                "summary": {"type": "string", "description": "What the gap is and what doing the task means, 2-4 sentences."},
                "why_this_score": {"type": "string"},
                "evidence": _list("Doc sections and game file paths that show the gap (and the concept art if relevant)."),
                "requirement_ids": _list("Requirement ids this task serves."),
                "owner_role": {"type": "string"}, "effort": {"type": "string", "enum": ["S", "M", "L"]},
                "agent_can_execute": {"type": "boolean"},
                "blocked_by": {"type": "string", "description": "Empty if nothing blocks it."}}}}}},
}

SUBMIT_PLAN = {
    "name": "submit_plan",
    "description": "Submit the implications and the execution plan for the selected task. Call once.",
    "input_schema": {"type": "object", "required": ["ready", "approach", "steps", "files_to_change", "implications", "risks",
                                                     "needs_human_check"], "properties": {
        "ready": {"type": "boolean", "description": "false if a creator decision or missing input blocks execution."},
        "blocked_questions": _list("Questions the creator must answer first (when ready=false)."),
        "approach": {"type": "string", "description": "2-5 sentences."},
        "steps": _list("Ordered, concrete steps."),
        "files_to_change": _list("Existing files to edit (paths)."),
        "files_to_create": _list("New files (paths)."),
        "implications": {"type": "object", "required": ["player", "performance", "contracts_and_other_agents", "canon_and_docs",
                                                         "reversibility"], "properties": {
            "player": {"type": "string"}, "performance": {"type": "string"},
            "contracts_and_other_agents": {"type": "string"}, "canon_and_docs": {"type": "string"},
            "reversibility": {"type": "string"}}},
        "risks": _list("What could go wrong."),
        "needs_human_check": _list("What only the creator can verify (usually by playing in Godot)."),
        "estimated_agent_effort": {"type": "string"}}},
}

SUBMIT_RESULT = {
    "name": "submit_result",
    "description": "Report the outcome of the executed task. Call once, after the work is done.",
    "input_schema": {"type": "object", "required": ["outcome", "summary", "files_changed", "verified", "needs_human_check",
                                                     "requirement_updates"], "properties": {
        "outcome": {"type": "string", "enum": ["done", "partial", "failed"]},
        "summary": {"type": "string", "description": "What was done, in plain words."},
        "files_changed": _list("Paths changed or created."),
        "decisions": _list("Design or technical decisions made while doing it."),
        "verified": _list("What you actually checked, and how."),
        "needs_human_check": _list("What the creator must check in Godot."),
        "requirement_updates": {"type": "array", "items": {"type": "object", "required": ["id", "status", "evidence"],
            "properties": {"id": {"type": "string"}, "status": {"type": "string", "enum": ["met", "partial", "unmet"]},
                           "evidence": {"type": "string"}}}},
        "follow_up_tasks": {"type": "array", "description": "New tasks this work uncovered (same shape as analysis tasks).",
            "items": SUBMIT_ANALYSIS["input_schema"]["properties"]["tasks"]["items"]},
        "open_issues": _list("Bugs or unresolved questions to record.")}},
}
