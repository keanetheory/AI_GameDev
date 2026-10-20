"""Deterministic checks an objective can carry. Each returns {type, ok: True|False|None, detail}; None = needs a human."""
import re
import subprocess
import sys
from pathlib import Path

from . import meshaudit
from .spec import CREW, REPO, ROOT

CACHE = ROOT / "state" / "mesh_cache"


def _p(rel: str) -> Path:
    return REPO / rel


def run_check(c: dict) -> dict:
    t = c["type"]
    try:
        if t == "file_exists":
            ok = _p(c["path"]).exists()
            return {"type": t, "ok": ok, "detail": f"{c['path']} {'exists' if ok else 'is missing'}"}
        if t == "grep":
            f = _p(c["path"])
            if not f.exists():
                return {"type": t, "ok": False, "detail": f"{c['path']} is missing"}
            n = len(re.findall(c["pattern"], f.read_text(encoding="utf-8", errors="replace"), re.M | re.I))
            lo, hi = c.get("min", 0 if "max" in c else 1), c.get("max")
            ok = n >= lo and (hi is None or n <= hi)
            need = f">= {lo}" + ("" if hi is None else f" and <= {hi}")
            return {"type": t, "ok": ok, "detail": f"{c['path']}: /{c['pattern']}/ matched {n} (need {need})"}
        if t == "scene_node":
            f = _p(c["scene"])
            names = re.findall(r'\[node name="([^"]+)"', f.read_text(encoding="utf-8", errors="replace"))
            n = sum(1 for x in names if re.fullmatch(c["pattern"], x))
            ok = n >= c.get("min", 1)
            return {"type": t, "ok": ok, "detail": f"{c['scene']}: {n} nodes match /{c['pattern']}/ (need >= {c.get('min', 1)})"}
        if t == "mesh_audit":
            f = _p(c["path"])
            if not f.exists():
                return {"type": t, "ok": False, "detail": f"{c['path']} is missing"}
            r = meshaudit.audit(f, CACHE)
            bad = []
            if c.get("no_empty_meshes", True):
                if r["empty_meshes"]:
                    bad.append(f"{len(r['empty_meshes'])} empty meshes")
                if r["unreferenced_meshes"]:
                    bad.append(f"{len(r['unreferenced_meshes'])} unreferenced meshes")
            for key, lim, label in (("size_mb", "max_mb", "MB"), ("tris", "max_tris", "tris"),
                                    ("hole_loops", "max_hole_loops", "hole loops"), ("boundary_ratio", "max_boundary_ratio", "open-edge ratio"),
                                    ("max_texture_px", "max_texture_px", "px texture"),
                                    ("vram_mb", "max_vram_mb", "MB VRAM")):
                if lim in c and r[key] > c[lim]:
                    bad.append(f"{r[key]:,} {label} > limit {c[lim]:,}")
            if "max_degenerate_ratio" in c and r["tris"] and r["degenerate_tris"] / r["tris"] > c["max_degenerate_ratio"]:
                bad.append(f"{r['degenerate_tris']} degenerate tris")
            return {"type": t, "ok": not bad, "detail": meshaudit.summarise(r) + ("  FAIL: " + "; ".join(bad) if bad else "")}
        if t == "crew_offline":  # an offline AI Crew command: no API key, no tokens
            if "--offline" not in c["command"] and "--check-only" not in c["command"]:
                return {"type": t, "ok": False, "detail": "refused: crew commands must include --offline or --check-only"}
            cmd = list(c["command"])
            if cmd[0] == "main_asset.py" and "--out" not in cmd:   # keep the crew's own tracked outputs untouched
                cmd += ["--out", str(ROOT / "state" / "crew_out")]
            p = subprocess.run([sys.executable, *cmd], cwd=CREW, capture_output=True, text=True, timeout=180)
            tail = (p.stdout + p.stderr).strip().splitlines()[-3:]
            return {"type": t, "ok": p.returncode == 0,
                    "detail": f"python {' '.join(c['command'])} -> rc {p.returncode}: " + " | ".join(tail)}
        if t == "manual":
            return {"type": t, "ok": None, "detail": c["note"]}
    except Exception as exc:  # a broken check is a finding, not a crash
        return {"type": t, "ok": False, "detail": f"check error: {type(exc).__name__}: {exc}"}
    return {"type": t, "ok": False, "detail": f"unknown check type '{t}'"}


def run_objective(o: dict) -> dict:
    results = [run_check(c) for c in o.get("checks", [])]
    if not results:
        status = "no_check"
    elif any(r["ok"] is False for r in results):
        status = "failing"
    elif any(r["ok"] is None for r in results):
        status = "needs_human"
    else:
        status = "passing"
    return {"status": status, "results": results}
