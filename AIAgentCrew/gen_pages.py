"""Generate the lighthouse's printed pages as images through FAL (text-to-image), from GERFramework/pages/pages.json.
usage: python gen_pages.py [--go] [--only Name ...] [--model fal-ai/ideogram/v2]
Dry run by default. Output: GERFramework/pages/generated/<name>.png and a manifest. Needs FAL_KEY in .env."""
import argparse, io, json, os, sys, time
from pathlib import Path
import requests

PAGES = Path(__file__).resolve().parent.parent / "GERFramework" / "pages"
RATIOS = {"1:1": 1.0, "3:4": 0.75, "4:3": 1.333, "2:3": 0.667, "3:2": 1.5, "9:16": 0.5625, "16:9": 1.778, "10:16": 0.625, "16:10": 1.6}


def ratio(aspect):
    return min(RATIOS, key=lambda k: abs(RATIOS[k] - aspect))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--go", action="store_true")
    ap.add_argument("--only", nargs="*")
    ap.add_argument("--model", default="fal-ai/ideogram/v2")
    a = ap.parse_args()
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass
    pages = json.loads((PAGES / "pages.json").read_text(encoding="utf-8"))
    out = PAGES / "generated"
    out.mkdir(exist_ok=True)
    key = os.environ.get("FAL_KEY")
    hdr = {"Authorization": f"Key {key}", "Content-Type": "application/json"}
    for e in pages:
        if a.only and e["name"] not in a.only:
            continue
        aspect = e["size_m"][0] / e["size_m"][1]
        body = {"prompt": e["prompt"], "negative_prompt": e["negative_prompt"], "aspect_ratio": ratio(aspect), "style": "design", "expand_prompt": False}
        print(f"[img] {e['name']}: {body['aspect_ratio']}")
        if not a.go:
            continue
        r = requests.post(f"https://queue.fal.run/{a.model}", headers=hdr, json=body, timeout=120)
        r.raise_for_status()
        job = r.json()
        while True:
            st = requests.get(job["status_url"], headers=hdr, timeout=60).json()
            if st.get("status") == "COMPLETED":
                break
            time.sleep(2)
        res = requests.get(job["response_url"], headers=hdr, timeout=60).json()
        url = res["images"][0]["url"]
        (out / f"{e['name']}.png").write_bytes(requests.get(url, timeout=120).content)
        print(f"[img] saved {e['name']}.png")
    if not a.go:
        print("dry run: add --go (about $0.08 an image on ideogram/v2)")


if __name__ == "__main__":
    sys.exit(main())
