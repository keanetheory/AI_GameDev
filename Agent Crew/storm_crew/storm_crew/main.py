"""Run the Storm Crossing Crew for Lighting the Storm.

Examples:
  python main.py --offline                    # no API key needed (smoke test)
  python main.py                              # real LLM, model from CREW_MODEL or default
  python main.py --preset assist --segments 4 --out output_assist
"""
import argparse
import os
import sys

from crew import build_crew
from integrator import write_outputs

DEFAULT_GOAL = (
    "Give me data for the Gate 1 return crossing from the outpost to the lighthouse: harder than "
    "the outbound run, readable for a first-time player, with Jeff calling the way through."
)


def main() -> int:
    ap = argparse.ArgumentParser(description="Storm Crossing Crew - Lighting the Storm")
    ap.add_argument("--offline", action="store_true", help="use the scripted offline LLM (no API key)")
    ap.add_argument("--preset", choices=["standard", "assist"], default="standard")
    ap.add_argument("--segments", type=int, default=5, choices=range(3, 9))
    ap.add_argument("--goal", default=DEFAULT_GOAL, help="the creator's goal for this run")
    ap.add_argument("--out", default="output")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass

    if args.offline:
        from offline_llm import OfflineLLM
        llm = OfflineLLM(model="offline-scripted", preset=args.preset, segments=args.segments)
    else:
        from crewai import LLM
        model = os.getenv("CREW_MODEL", "anthropic/claude-sonnet-4-5")
        key_var = {"anthropic": "ANTHROPIC_API_KEY", "openai": "OPENAI_API_KEY",
                   "gemini": "GEMINI_API_KEY"}.get(model.split("/")[0])
        if key_var and not os.getenv(key_var):
            print(f"[crew] {key_var} is not set for model '{model}'. Add it to .env, "
                  "or run with --offline for the no-key smoke test.", file=sys.stderr)
            return 2
        llm = LLM(model=model, temperature=0.4)

    state: dict = {}  # shared handoff store, filled by each task's guardrail
    if args.offline:
        llm.state = state  # offline LLM builds each answer from the previous validated handoff
    crew, state = build_crew(llm, args.goal, args.preset, args.segments,
                             verbose=not args.quiet, state=state)

    try:
        crew.kickoff()
    except Exception as exc:  # report cleanly instead of a stack trace mid-pipeline
        print(f"\n[crew] stopped: {type(exc).__name__}: {exc}", file=sys.stderr)

    out, problems = write_outputs(state, args.out, "offline" if args.offline else "llm")
    if problems:
        print("\n[crew] BLOCKED - game data not written:\n  " + "\n  ".join(problems))
        return 1
    print(f"\n[crew] done. Game data: {out / 'return_crossing.json'}  |  notes: HANDOFF.md, REPORT.md")
    return 0


if __name__ == "__main__":
    sys.exit(main())
