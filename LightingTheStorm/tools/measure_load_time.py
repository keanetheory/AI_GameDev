"""Runs tools/measure_load_time.gd for each part of the level, one process each, and prints a table.

  python tools/measure_load_time.py [--godot <console exe>] [--repeat 2]
Headless, so this is CPU load time only (no GPU upload); it is the part the creator's machine spends in loading and _ready.
"""
import argparse
import re
import subprocess
from pathlib import Path

GODOT = r"C:\Users\pmkea\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe"
PARTS = ["all", "no_cliffside", "cliffside", "island", "saltgate"]


def run(godot: str, part: str) -> int:
    p = subprocess.run([godot, "--headless", "--path", str(Path(__file__).resolve().parent.parent), "--script",
                        "res://tools/measure_load_time.gd", "--", part], capture_output=True, text=True, timeout=300)
    m = re.search(r"part=%s total=(\d+) ms" % part, p.stdout)
    return int(m.group(1)) if m else -1


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--godot", default=GODOT)
    ap.add_argument("--repeat", type=int, default=2, help="runs per part; the fastest is reported (the first warms the disk cache)")
    a = ap.parse_args()
    res = {p: min(x for x in (run(a.godot, p) for _ in range(a.repeat)) if x > 0) for p in PARTS}
    print(f"{'part':<14}{'ms':>8}")
    for p, ms in res.items():
        print(f"{p:<14}{ms:>8}")
    print(f"\ncliffside cost (all - no_cliffside): {res['all'] - res['no_cliffside']} ms")


if __name__ == "__main__":
    main()
