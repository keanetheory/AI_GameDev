"""Run the Opening Dialogue Crew for Lighting the Storm.

Examples:
  python main_dialogue.py --offline                          # no API key: scripted model, real agents and guardrails
  python main_dialogue.py                                    # real LLM writes the lines (needs an API key)
  python main_dialogue.py --offline --out dialogue_output --godot-dir ../../../LightingTheStorm
"""
import argparse
import json
import os
import shutil
import sys
from pathlib import Path

from dialogue_crew import build_dialogue_crew
from dialogue_integrator import write_outputs
from dialogue_revision import build_revision_crew
from schemas import DialogueBrief, OpeningDialogue, ReviewReport

DEFAULT_GOAL = (
    "Write the opening dialogue for the Gate 1 slice, following the canon story beats. The game starts outside "
    "the lighthouse: Ted opens the door and greets the player as the new guy. Inside, after a beat, Ted sets the "
    "scene and the objectives: 1) load coal into the basement boiler, 2) let the stranded sailors in through the "
    "island gate, 3) once they are in, Ted finds the beacon's burner broken and sends the player across the "
    "Gullwater with Arthur to fetch the replacement from the Saltgate. Include Arthur and Daniel. Call the player "
    "'Isaac'."
)


def load_state(folder: Path) -> dict:
    """Rebuild a crew state from a saved run so a revision can continue from it."""
    h = folder / "handoffs"
    return {
        "dialogue_brief": DialogueBrief.model_validate_json((h / "01_dialogue_brief.json").read_text(encoding="utf-8")),
        "dialogue": OpeningDialogue.model_validate_json((h / "02_dialogue.json").read_text(encoding="utf-8")),
        "dialogue_review": ReviewReport.model_validate_json((h / "03_dialogue_review.json").read_text(encoding="utf-8")),
        "log": json.loads((folder / "run_log.json").read_text(encoding="utf-8")),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Opening Dialogue Crew - Lighting the Storm")
    ap.add_argument("--offline", action="store_true", help="use the scripted offline LLM (no API key)")
    ap.add_argument("--no-demo-errors", action="store_true",
                    help="offline only: replay the clean draft instead of a first attempt with faults")
    ap.add_argument("--max-words", type=int, default=22, help="words per line limit given to the brief")
    ap.add_argument("--max-revisions", type=int, default=2,
                    help="revision rounds allowed when the reviewer says REVISE (0 = never revise)")
    ap.add_argument("--revise-from", help="folder of an earlier run (with handoffs/ and run_log.json) to revise")
    ap.add_argument("--simulate-revise", action="store_true",
                    help="offline only: the first review returns REVISE, to test the revision loop")
    ap.add_argument("--goal", default=DEFAULT_GOAL)
    ap.add_argument("--out", default="dialogue_output")
    ap.add_argument("--godot-dir", help="Godot project folder; copies dialogue_opening.json to data/dialogue/")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass

    if args.offline:
        from offline_dialogue_llm import OfflineDialogueLLM
        llm = OfflineDialogueLLM(model="offline-scripted-dialogue", max_words=args.max_words,
                                 inject_errors=not args.no_demo_errors, simulate_revise=args.simulate_revise)
    else:
        from crewai import LLM
        model = os.getenv("CREW_MODEL", "anthropic/claude-sonnet-5-5")
        key_var = {"anthropic": "ANTHROPIC_API_KEY", "openai": "OPENAI_API_KEY",
                   "gemini": "GEMINI_API_KEY"}.get(model.split("/")[0])
        if key_var and not os.getenv(key_var):
            print(f"[crew] {key_var} is not set for model '{model}'. Add it to .env, "
                  "or run with --offline.", file=sys.stderr)
            return 2
        extra = {}
        workspace = os.getenv("ANTHROPIC_WORKSPACE_ID")
        if workspace:  # needed when the API key is not scoped to a workspace
            extra["client_params"] = {"default_headers": {"anthropic-workspace-id": workspace}}
        llm = LLM(model=model, max_tokens=16000, **extra)  # no temperature: newer models reject it

    state: dict = {}
    if args.revise_from:  # continue from a saved run: skip the first pass, go straight to revision
        state = load_state(Path(args.revise_from))
        print(f"[crew] loaded {args.revise_from}: verdict {state['dialogue_review'].verdict}, "
              f"{len(state['log'])} earlier guardrail attempts")
    if args.offline:
        llm.state = state  # the offline reviewer builds its evidence from the validated handoffs
    if not args.revise_from:
        crew, state = build_dialogue_crew(llm, args.goal, verbose=not args.quiet, state=state,
                                          max_words=args.max_words)
        try:
            crew.kickoff()
        except Exception as exc:
            print(f"\n[crew] stopped: {type(exc).__name__}: {exc}", file=sys.stderr)

    # Revision loop: a REVISE verdict sends the reviewer's issues back to the Dialogue agent.
    rounds = len(state.get("history", []))
    while ("dialogue_review" in state and state["dialogue_review"].verdict == "REVISE"
           and rounds < args.max_revisions):
        rounds += 1
        print(f"[crew] reviewer said REVISE ({len(state['dialogue_review'].issues)} issues): "
              f"starting revision round {rounds}")
        crew, state = build_revision_crew(llm, state, rounds, verbose=not args.quiet)
        try:
            crew.kickoff()
        except Exception as exc:
            print(f"\n[crew] revision round {rounds} stopped: {type(exc).__name__}: {exc}", file=sys.stderr)
            break

    out, problems = write_outputs(state, args.out, "offline" if args.offline else "llm")
    for e in state.get("log", []):
        status = "PASS" if e["passed"] else f"BLOCKED ({len(e['errors'])} error(s))"
        print(f"[guardrail] {e['task']} attempt {e['attempt']}: {status}")
    if problems:
        print("\n[crew] BLOCKED - game data not written:\n  " + "\n  ".join(problems))
        return 1
    if args.godot_dir:
        dest = Path(args.godot_dir) / "data" / "dialogue"
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copy(out / "dialogue_opening.json", dest / "dialogue_opening.json")
        print(f"[crew] copied game data to {dest}")
    print(f"\n[crew] done. Game data: {out / 'dialogue_opening.json'}  |  notes: HANDOFF.md, REPORT.md")
    return 0


if __name__ == "__main__":
    sys.exit(main())
