"""Prepare freshly generated FAL prop models for Godot (Lighthouse Finisher Agent, LHF-08).
For each Assets/Models/prop/<id>.glb given (or every lhi_*.glb that has no .import yet): downscale its 4096 texture to 2048 (the 4K
original goes to prop/source/), and write a .glb.import copied from a sibling that already uses import_scale_pivot.gd.
  python -I tools/import_new_props.py lhi_oak_barrel lhi_keeper_desk ...
Then run Godot once with --headless --import so the .scn files are made.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROP = ROOT / "Assets" / "Models" / "prop"
TEMPLATE = PROP / "lhi_boiler.glb.import"


def main(ids):
    tmpl = TEMPLATE.read_text(encoding="utf-8")
    for i in ids:
        glb = PROP / f"{i}.glb"
        if not glb.exists():
            print("missing", glb)
            continue
        r = subprocess.run([sys.executable, "-I", str(ROOT / "tools" / "downscale_glb_texture.py"), str(glb)], capture_output=True, text=True)
        print(i, "downscale:", (r.stdout.strip().splitlines() or [r.stderr.strip()[-120:]])[-1])
        imp = PROP / f"{i}.glb.import"
        if imp.exists():
            continue
        t = tmpl.replace("lhi_boiler", i)
        t = re.sub(r'^uid=.*\n', '', t, flags=re.M)
        t = re.sub(r'^path=.*\n', '', t, flags=re.M)
        t = re.sub(r'^dest_files=.*\n', '', t, flags=re.M)
        imp.write_text(t, encoding="utf-8")
        print("  wrote", imp.name)


if __name__ == "__main__":
    main(sys.argv[1:])
