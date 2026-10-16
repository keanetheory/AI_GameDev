"""Run the Voice Casting Crew (Sound agent + Canon reviewer) over the opening dialogue.

  python main_voice.py --offline            # scripted model, real agents and guardrails
  python main_voice.py                      # real model
"""
import argparse
import json
import sys
from pathlib import Path

from schemas import OpeningDialogue
from voice_crew import build_voice_crew
from voice_integrator import write_outputs

DEFAULT_DIALOGUE = Path(__file__).with_name("sample_output_picked") / "dialogue_opening.json"  # the game's dialogue


def main() -> int:
    ap = argparse.ArgumentParser(description="Voice Casting Crew - Lighting the Storm")
    ap.add_argument("--offline", action="store_true")
    ap.add_argument("--no-demo-errors", action="store_true")
    ap.add_argument("--dialogue", default=str(DEFAULT_DIALOGUE), help="dialogue_opening.json to cast")
    ap.add_argument("--out", default="voice_output")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass
    raw = json.loads(Path(args.dialogue).read_text(encoding="utf-8"))
    dialogue = OpeningDialogue.model_validate({"lines": raw["lines"], "journal": raw["journal"]})
    state: dict = {}
    if args.offline:
        from offline_voice_llm import OfflineVoiceLLM
        llm = OfflineVoiceLLM(model="offline-scripted-voice", inject_errors=not args.no_demo_errors)
    else:
        from llm_factory import make_real_llm
        llm = make_real_llm()
        if llm is None:
            return 2
    crew, state = build_voice_crew(llm, dialogue, verbose=not args.quiet, state=state)
    if args.offline:
        llm.state = state
    try:
        crew.kickoff()
    except Exception as exc:
        print(f"\n[crew] stopped: {type(exc).__name__}: {exc}", file=sys.stderr)
    out, problems = write_outputs(state, args.out, "offline" if args.offline else "llm")
    for e in state.get("log", []):
        print(f"[guardrail] {e['task']} attempt {e['attempt']}: "
              + ("PASS" if e["passed"] else f"BLOCKED ({len(e['errors'])}): " + " | ".join(e["errors"])[:400]))
    if problems:
        print("\n[crew] BLOCKED:\n  " + "\n  ".join(problems))
        return 1
    print(f"\n[crew] done: {out / 'VOICE_CASTING.md'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
