"""Rig a humanoid FAL model with fal-ai/meshy/rigging and save the rigged GLB (plus its walk/run/idle clips).

Examples:
  python main_fal_rig.py ../LightingTheStorm/Assets/Models/character_texture/ted_fal_v3.fal_result.json             # dry run
  python main_fal_rig.py <fal_result.json> --go --height 1.83 --animation 0                                          # rig + Idle clip

Reads model_url from the *.fal_result.json main_fal.py writes. Cost: $0.20, +$0.12 with --animation.
Needs FAL_KEY in AIAgentCrew/.env.
"""
import argparse
import json
import os
import sys
import time
from pathlib import Path

import requests

QUEUE = "https://queue.fal.run"
MODEL = "fal-ai/meshy/rigging"


def main() -> int:
    ap = argparse.ArgumentParser(description="Rig a FAL character model")
    ap.add_argument("fal_result")
    ap.add_argument("--go", action="store_true", help="actually call FAL (default is a dry run)")
    ap.add_argument("--height", type=float, default=1.7, help="character height in metres")
    ap.add_argument("--animation", type=int, help="Meshy animation preset id (0 is Idle)")
    args = ap.parse_args()
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass

    result_path = Path(args.fal_result).resolve()
    info = json.loads(result_path.read_text(encoding="utf-8"))
    if "model_url" not in info:
        sys.exit("[rig] no model_url in the result file (it was made before main_fal.py recorded it)")
    payload = {"model_url": info["model_url"], "height_meters": args.height}
    if args.animation is not None:
        payload.update(enable_animation=True, animation_action_id=args.animation)
    stem = result_path.name.removesuffix(".fal_result.json")
    out_dir = result_path.parent
    print(f"[rig] model: {MODEL}  cost: $0.20 (+$0.12 with an animation)\n[rig] payload: {json.dumps(payload, indent=2)}")
    if not args.go:
        print("[rig] dry run - nothing sent. Add --go to rig.")
        return 0

    key = os.environ.get("FAL_KEY")
    if not key:
        print("[rig] FAL_KEY is not set (add it to AIAgentCrew/.env)", file=sys.stderr)
        return 2
    headers = {"Authorization": f"Key {key}", "Content-Type": "application/json"}
    r = requests.post(f"{QUEUE}/{MODEL}", headers=headers, json=payload, timeout=120)
    r.raise_for_status()
    job = r.json()
    print(f"[rig] queued request {job['request_id']}")
    while True:
        st = requests.get(job["status_url"], headers=headers, timeout=60).json()
        if st.get("status") == "COMPLETED":
            break
        time.sleep(5)
    result = requests.get(job["response_url"], headers=headers, timeout=60)
    result.raise_for_status()
    result = result.json()

    saved = {}

    def fetch(file: dict | None, name: str):
        if not file or not file.get("url"):
            return
        data = requests.get(file["url"], timeout=300)
        data.raise_for_status()
        path = out_dir / name
        path.write_bytes(data.content)
        saved[name] = file["url"]
        print(f"[rig] saved {path} ({len(data.content) // 1024} KB)")

    fetch(result.get("rigged_character_glb"), f"{stem}_rigged.glb")
    fetch(result.get("animation_glb"), f"{stem}_anim.glb")
    for clip, file in (result.get("basic_animations") or {}).items():
        if isinstance(file, dict) and file.get("url", "").lower().split("?")[0].endswith(".glb"):
            fetch(file, f"{stem}_{clip}.glb")
    (out_dir / f"{stem}.rig_result.json").write_text(json.dumps(
        {"request_id": job["request_id"], "request": payload, "rig_task_id": result.get("rig_task_id"),
         "saved": saved, "basic_animations": result.get("basic_animations")}, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
