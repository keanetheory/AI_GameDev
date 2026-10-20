"""Visual regression check: renders fixed camera views of the real level and fails any view with large black areas.

  python tools/visual_check.py [--only name,name] [--views tools/visual_views.json]

It is a coarse backstop: shadowed rock and a black unlit wall can look alike to a pixel measure, so it only fails gross cases
(a view from inside rock scores 100%). Geometry faults are covered by tools/test_cliff_clean.gd. It runs GERFramework/shoot.sh (a real renderer, so it needs the GPU and a display) once per view, then measures each
picture: the share of near-black pixels, and how many cells of an 8 x 6 grid are almost entirely black. A black wall,
a hanging unlit sheet or a hole to a black void shows up as a large dark area. It cannot judge beauty; it catches
the faults a headless ray test cannot see. Results go to GERFramework/reports/visual_check.md and shots/.
"""
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
SHOTS = REPO / "GERFramework" / "shots"
# Git Bash by full path: a bare "bash" can resolve to the WSL stub on Windows
BASH = shutil.which("bash") or "C:/Program Files/Git/usr/bin/bash.exe"


def measure(png: Path, dark_luma: int) -> tuple[float, int]:
    """(share of 10 px blocks that are dark AND flat, black grid cells). Flat-dark blocks are unlit or empty areas:
    shadowed rock has texture, so a smooth dark block is a hole, an unlit back face or a view from inside the rock."""
    im = Image.open(png).convert("L")
    w, h = im.size
    im = im.crop((0, int(h * 0.06), w, int(h * 0.86)))      # ignore the HUD strip and the subtitle band
    w, h = im.size
    px = im.load()
    blk, tot, flat = 10, 0, 0
    for by in range(0, h - blk, blk):
        for bx in range(0, w - blk, blk):
            v = [px[x, y] for y in range(by, by + blk, 2) for x in range(bx, bx + blk, 2)]
            m = sum(v) / len(v)
            sd = (sum((a - m) ** 2 for a in v) / len(v)) ** 0.5
            tot += 1
            flat += (m < dark_luma and sd < 3.5)
    cells = 0
    cw, ch = w // 8, h // 6
    for cy in range(6):
        for cx in range(8):
            n = d = 0
            for y in range(cy * ch, (cy + 1) * ch, 4):
                for x in range(cx * cw, (cx + 1) * cw, 4):
                    n += 1
                    d += px[x, y] < 14
            if n and d / n > 0.9:
                cells += 1
    return flat / tot, cells


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--views", default=str(HERE / "visual_views.json"))
    ap.add_argument("--only", default="")
    ap.add_argument("--no-render", action="store_true", help="measure the pictures already in shots/")
    a = ap.parse_args()
    cfg = json.loads(Path(a.views).read_text(encoding="utf-8"))
    only = set(filter(None, a.only.split(",")))
    rows, fails = [], 0
    for v in cfg["views"]:
        if only and v["name"] not in only:
            continue
        png = SHOTS / f"{v['name']}.png"
        if not a.no_render:
            args = [BASH, (REPO / "GERFramework" / "shoot.sh").as_posix(), v["name"], *map(str, v["from"]), *map(str, v["to"])]
            if v.get("phase"):
                args += [v["phase"], str(v.get("sea_state", 1))]
            subprocess.run(args, capture_output=True, text=True, timeout=200)
        if not png.exists():
            rows.append((v["name"], None, None, "NO PICTURE", v.get("note", "")))
            fails += 1
            continue
        ratio, cells = measure(png, cfg["dark_luma"])
        bad = ratio > cfg["max_dark_ratio"] or cells > cfg["max_black_cells"]
        fails += bad
        rows.append((v["name"], ratio, cells, "FAIL" if bad else "pass", v.get("note", "")))
    out = ["# Visual check", "", f"Limits: flat-dark share <= {cfg['max_dark_ratio']:.0%}, almost-black grid cells <= {cfg['max_black_cells']} of 48.", "",
           "| View | Flat-dark share | Black cells | Result | What it shows |", "|---|---|---|---|---|"]
    for n, r, c, res, note in rows:
        out.append(f"| {n} | {'' if r is None else f'{r:.0%}'} | {'' if c is None else c} | {res} | {note} |")
    (REPO / "GERFramework" / "reports" / "visual_check.md").write_text("\n".join(out), encoding="utf-8")
    for n, r, c, res, note in rows:
        print(f"{res:<10} {n:<16} dark {'' if r is None else f'{r:.0%}':>4}  black cells {c}")
    print(f"\n{'ALL PASSED' if fails == 0 else str(fails) + ' FAILED'}  (pictures in GERFramework/shots/)")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
