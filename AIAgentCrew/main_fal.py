"""Send a reviewed FAL submission (*.fal.json) to FAL and save the 3D model into the Godot project.

Examples:
  python main_fal.py sample_submissions/lighthouse_hunyuan_multiview.fal.json            # dry run: shows the request, spends nothing
  python main_fal.py sample_submissions/lighthouse_hunyuan_multiview.fal.json --go       # really generate (costs money)
  python main_fal.py <file> --go --textured                                              # textured mesh (3x the price)

Needs FAL_KEY in AIAgentCrew/.env. The Asset agent review (main_asset.py) should be APPROVE first.
"""
import argparse
import base64
import io
import json
import os
import sys
import time
from pathlib import Path

import requests
from PIL import Image

from world_schemas import FalSubmission

GODOT_ROOT = Path(__file__).resolve().parent.parent / "LightingTheStorm"
QUEUE = "https://queue.fal.run"
PRICE_NOTE = "v2 multi-view: ~$0.16 white / $0.48 textured. v3: $0.225 white / $0.375 textured, +$0.15 for extra views, +$0.15 for a custom face count"


def data_uri(path: Path, max_side: int = 1024) -> str:
    img = Image.open(path).convert("RGB")
    img.thumbnail((max_side, max_side))
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=92)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def build_payload(sub: FalSubmission, base: Path, args) -> dict:
    if "hunyuan3d-v3" in sub.fal_model:
        views = sub.view_images
        if "front" not in views:
            sys.exit("[fal] view_images needs a 'front' image")
        payload = {"input_image_url": data_uri((base / views["front"]).resolve()),
                   "generate_type": "Normal" if args.textured else "Geometry"}
        for v in ("back", "left", "right"):
            if v in views:
                payload[f"{v}_image_url"] = data_uri((base / views[v]).resolve())
        if args.face_count:
            payload["face_count"] = args.face_count
        return payload
    if "multi-view" not in sub.fal_model:
        sys.exit(f"[fal] unsupported model {sub.fal_model}")
    missing = {"front", "back", "left"} - sub.view_images.keys()
    if missing:
        sys.exit(f"[fal] view_images is missing: {sorted(missing)}")
    payload = {f"{v}_image_url": data_uri((base / p).resolve()) for v, p in sub.view_images.items()}
    payload["textured_mesh"] = args.textured
    payload["octree_resolution"] = args.octree
    if args.seed is not None:
        payload["seed"] = args.seed
    return payload


def main() -> int:
    ap = argparse.ArgumentParser(description="Send a FAL submission to FAL")
    ap.add_argument("submission")
    ap.add_argument("--go", action="store_true", help="actually call FAL (default is a dry run)")
    ap.add_argument("--textured", action="store_true")
    ap.add_argument("--octree", type=int, default=256)
    ap.add_argument("--seed", type=int)
    ap.add_argument("--face-count", type=int, help="v3 only, 40000-1500000")
    args = ap.parse_args()
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass

    path = Path(args.submission).resolve()
    sub = FalSubmission.model_validate_json(path.read_text(encoding="utf-8"))
    payload = build_payload(sub, path.parent, args)
    out_dir = GODOT_ROOT / "Assets" / "Models" / sub.category
    out_file = out_dir / f"{sub.asset_id}.glb"

    shown = {k: (v[:40] + f"... ({len(v) // 1024} KB)" if k.endswith("_url") else v) for k, v in payload.items()}
    print(f"[fal] model:  {sub.fal_model}\n[fal] cost:   {PRICE_NOTE}\n[fal] output: {out_file}\n[fal] payload: {json.dumps(shown, indent=2)}")
    if not args.go:
        print("[fal] dry run - nothing sent. Add --go to generate.")
        return 0

    key = os.environ.get("FAL_KEY")
    if not key:
        print("[fal] FAL_KEY is not set (add it to AIAgentCrew/.env)", file=sys.stderr)
        return 2
    headers = {"Authorization": f"Key {key}", "Content-Type": "application/json"}
    r = requests.post(f"{QUEUE}/{sub.fal_model}", headers=headers, json=payload, timeout=120)
    r.raise_for_status()
    job = r.json()
    print(f"[fal] queued request {job['request_id']}")
    while True:
        st = requests.get(job["status_url"], headers=headers, timeout=60).json()
        print(f"[fal] {st.get('status')}")
        if st.get("status") == "COMPLETED":
            break
        time.sleep(5)
    result = requests.get(job["response_url"], headers=headers, timeout=60)
    result.raise_for_status()
    result = result.json()

    out_dir.mkdir(parents=True, exist_ok=True)
    mesh = result.get("model_glb") or result["model_mesh"]
    glb = requests.get(mesh["url"], timeout=300)
    glb.raise_for_status()
    out_file.write_bytes(glb.content)
    (out_dir / f"{sub.asset_id}.fal_result.json").write_text(
        json.dumps({"submission": sub.model_dump(), "request_id": job["request_id"], "seed": result.get("seed"),
                    "textured": args.textured, "request": {k: v for k, v in payload.items() if not k.endswith("_url")}}, indent=2), encoding="utf-8")
    print(f"[fal] saved {out_file} ({len(glb.content) // 1024} KB), seed {result.get('seed')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
