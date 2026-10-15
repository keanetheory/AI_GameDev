"""Run the Asset agent over FAL submissions (*.fal.json) and check them against the style guide.

Examples:
  python main_asset.py sample_submissions --offline               # every *.fal.json in a folder
  python main_asset.py my_lighthouse.fal.json                     # one file, real model
  python main_asset.py sample_submissions --check-only            # deterministic checks only, no agent

Each submission is a JSON file: {"asset_id", "category", "fal_model", "prompt", "negative_prompt",
"source_image" (optional), "notes" (optional)}.
"""
import argparse
import json
import sys
from pathlib import Path

from asset_crew import build_asset_crew
from style_guide import load_style_guide
from world_schemas import FalSubmission
from world_validators import check_asset_review, check_submission


def collect(paths: list[str]) -> list[Path]:
    files = []
    for p in map(Path, paths):
        files += sorted(p.glob("*.fal.json")) if p.is_dir() else [p]
    return files


def main() -> int:
    ap = argparse.ArgumentParser(description="Asset agent - FAL submission review")
    ap.add_argument("submissions", nargs="+", help="*.fal.json files or folders of them")
    ap.add_argument("--offline", action="store_true", help="use the scripted offline LLM (no API key)")
    ap.add_argument("--check-only", action="store_true", help="run only the deterministic style checks")
    ap.add_argument("--out", default="asset_reviews")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass

    guide = load_style_guide()
    files = collect(args.submissions)
    if not files:
        print("[asset] no *.fal.json files found", file=sys.stderr)
        return 2
    llm = None
    if not args.check_only:
        if args.offline:
            from offline_world_llm import OfflineWorldLLM
            llm = OfflineWorldLLM(model="offline-scripted-world", inject_errors=False)
        else:
            from llm_factory import make_real_llm
            llm = make_real_llm()
            if llm is None:
                return 2

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    summary, exit_code = [], 0
    for f in files:
        sub = FalSubmission.model_validate_json(f.read_text(encoding="utf-8"))
        findings, metrics = check_submission(sub, guide, base_dir=f.parent)
        verdict = "APPROVE" if not findings else "REVISE"
        if llm is not None:
            llm.state = {"sub": sub, "findings": findings, "metrics": metrics, "guide": guide}
            crew, state = build_asset_crew(llm, guide, sub, findings, metrics, verbose=not args.quiet)
            try:
                crew.kickoff()
            except Exception as exc:
                print(f"[asset] {sub.asset_id}: stopped: {type(exc).__name__}: {exc}", file=sys.stderr)
            review = state.get("review")
            if review is None or check_asset_review(review, sub, findings, guide):
                print(f"[asset] {sub.asset_id}: BLOCKED - no valid review")
                exit_code = 1
                continue
            verdict = review.verdict
            (out / f"{sub.asset_id}.review.json").write_text(review.model_dump_json(indent=2), encoding="utf-8")
            (out / f"{sub.asset_id}.approved_prompt.txt").write_text(
                f"PROMPT:\n{review.revised_prompt}\n\nNEGATIVE PROMPT:\n{review.revised_negative_prompt}\n\n"
                f"GODOT FOLDER: {review.godot_target_folder}\nIMPORT NOTES:\n"
                + "\n".join(f"- {n}" for n in review.import_notes), encoding="utf-8")
        print(f"[asset] {sub.asset_id} ({sub.category}): {verdict}, {len(findings)} finding(s)")
        for fi in findings:
            print(f"          - {fi}")
        summary.append({"asset_id": sub.asset_id, "category": sub.category, "verdict": verdict,
                        "findings": findings, "image_metrics": metrics})
    (out / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"\n[asset] {sum(s['verdict'] == 'APPROVE' for s in summary)} approved, "
          f"{sum(s['verdict'] == 'REVISE' for s in summary)} need revision. Output: {out}")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
