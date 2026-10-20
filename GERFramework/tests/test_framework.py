"""Tests for the GER Framework. Run: python GERFramework/tests/test_framework.py   (offline, no tokens, no network)."""
import copy
import json
import struct
import sys
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
from ger_core import checks, knowledge, loop, meshaudit, review, spec  # noqa: E402

FAILS = []


def check(name, cond, detail=""):
    print(("PASS " if cond else "FAIL ") + name + (f"  [{detail}]" if detail and not cond else ""))
    if not cond:
        FAILS.append(name)


def make_glb(path, meshes, extra_empty=False, orphan=False):
    """meshes: list of (positions Nx3 float32, indices Mx3 uint32). One node per mesh unless orphan."""
    blob, views, accs, mlist = b"", [], [], []
    for pos, idx in meshes:
        for arr, target, ctype, typ in ((pos.astype(np.float32), 34962, 5126, "VEC3"), (idx.astype(np.uint32).reshape(-1), 34963, 5125, "SCALAR")):
            b = arr.tobytes()
            views.append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(b), "target": target})
            a = {"bufferView": len(views) - 1, "componentType": ctype, "count": len(arr) if typ == "VEC3" else arr.size, "type": typ}
            if typ == "VEC3":
                a["min"], a["max"] = arr.min(0).tolist(), arr.max(0).tolist()
            accs.append(a)
            blob += b + b"\0" * (-len(b) % 4)
        mlist.append({"primitives": [{"attributes": {"POSITION": len(accs) - 2}, "indices": len(accs) - 1}]})
    if extra_empty:
        mlist.append({"name": "empty", "primitives": []})
    nodes = [{"mesh": i} for i in range(len(meshes))] if not orphan else [{"mesh": 0}]
    js = {"asset": {"version": "2.0"}, "buffers": [{"byteLength": len(blob)}], "bufferViews": views, "accessors": accs,
          "meshes": mlist, "nodes": nodes, "scenes": [{"nodes": list(range(len(nodes)))}], "scene": 0}
    if extra_empty:
        js["nodes"].append({"mesh": len(mlist) - 1})
    jb = json.dumps(js).encode()
    jb += b" " * (-len(jb) % 4)
    total = 12 + 8 + len(jb) + 8 + len(blob)
    path.write_bytes(struct.pack("<4sII", b"glTF", 2, total) + struct.pack("<II", len(jb), 0x4E4F534A) + jb
                     + struct.pack("<II", len(blob), 0x004E4942) + blob)


def cube(skip_faces=()):
    v = np.array([[x, y, z] for x in (0, 1) for y in (0, 1) for z in (0, 1)], dtype=np.float32)
    quads = {0: (0, 1, 3, 2), 1: (4, 6, 7, 5), 2: (0, 4, 5, 1), 3: (2, 3, 7, 6), 4: (0, 2, 6, 4), 5: (1, 5, 7, 3)}
    tris = []
    for f, (a, b, c, d) in quads.items():
        if f not in skip_faces:
            tris += [[a, b, c], [a, c, d]]
    return v, np.array(tris)


def test_mesh_audit(tmp):
    make_glb(tmp / "closed.glb", [cube()])
    r = meshaudit.audit(tmp / "closed.glb")
    check("closed cube: zero hole loops", r["hole_loops"] == 0 and r["boundary_edges"] == 0, r)
    make_glb(tmp / "onehole.glb", [cube(skip_faces=(5,))])
    r = meshaudit.audit(tmp / "onehole.glb")
    check("cube missing one face: exactly one hole loop found", r["hole_loops"] == 1, r)
    make_glb(tmp / "twohole.glb", [cube(skip_faces=(4, 5))])
    check("cube missing two faces: two hole loops found", meshaudit.audit(tmp / "twohole.glb")["hole_loops"] == 2)
    make_glb(tmp / "empty.glb", [cube()], extra_empty=True)
    r = meshaudit.audit(tmp / "empty.glb")
    check("empty mesh is reported", len(r["empty_meshes"]) == 1, r)
    v, t = cube()
    make_glb(tmp / "orphan.glb", [(v, t), (v + 5, t)], orphan=True)
    check("unreferenced mesh is reported", len(meshaudit.audit(tmp / "orphan.glb")["unreferenced_meshes"]) == 1)
    v2 = np.concatenate([v, v[:1] + 0.5])
    t2 = np.concatenate([t, [[0, 0, 8]]])
    make_glb(tmp / "degen.glb", [(v2, t2)])
    check("degenerate triangle is reported", meshaudit.audit(tmp / "degen.glb")["degenerate_tris"] >= 1)
    # split vertices at a seam (as UV seams do) must NOT count as a hole
    vs = np.concatenate([v, v])
    ts = np.concatenate([t[:6], t[6:] + 8])
    make_glb(tmp / "seam.glb", [(vs, ts)])
    check("duplicate (UV-seam) vertices are welded, not reported as holes", meshaudit.audit(tmp / "seam.glb")["hole_loops"] == 0)
    res = checks.run_check({"type": "mesh_audit", "path": str((tmp / "onehole.glb").relative_to(Path("/")) if False else "x"), "max_hole_loops": 0})
    check("mesh_audit check on a missing file fails cleanly", res["ok"] is False)


def test_checks():
    check("crew_offline refuses a command without --offline/--check-only",
          checks.run_check({"type": "crew_offline", "command": ["main_world.py"]})["ok"] is False)
    check("manual check is 'needs human', not pass", checks.run_check({"type": "manual", "note": "x"})["ok"] is None)
    g = {"type": "grep", "path": "GERFramework/README.md", "pattern": "zzz-never-present-zzz", "max": 0}
    check("grep with only max passes when there are no matches (min defaults to 0)", checks.run_check(g)["ok"] is True)
    check("grep with only a pattern still needs one match", checks.run_check(dict(g, max=None) | {"max": None} if False else {"type": "grep", "path": "GERFramework/README.md", "pattern": "zzz-never-present-zzz"})["ok"] is False)
    check("unknown check type fails", checks.run_check({"type": "nope"})["ok"] is False)
    r = checks.run_check({"type": "crew_offline", "command": ["main_asset.py", "sample_submissions/island_craggy_hunyuan_v3.fal.json", "--check-only"]})
    check("offline crew check runs with no API key", r["ok"] is True, r["detail"])


def test_specs():
    C, A = spec.creators(), spec.assessors()
    check("5 creators and 7 assessors", len(C) == 5 and len(A) == 7)
    for c in C.values():
        check(f"{c['id']}: assessor exists", c["assessor"] in A)
        ids = [o["id"] for o in c["objectives"]]
        check(f"{c['id']}: unique objective ids", len(ids) == len(set(ids)))
        check(f"{c['id']}: all priorities 1-10 ints", all(isinstance(o["priority"], int) and 1 <= o["priority"] <= 10 for o in c["objectives"]))
        check(f"{c['id']}: has at least one 10", any(o["priority"] == 10 for o in c["objectives"]))
    for a in A.values():
        check(f"{a['id']}: reviews exists or is null", a["reviews"] is None or a["reviews"] in C)


def test_review_logic():
    C, A = spec.creators(), spec.assessors()
    c, a = C["island_creator"], A["island_assessor"]
    k = {"files_read": 1}
    base = c["objectives"]
    check("island plan passes the rubric as written", not [f for f in review.review_plan(c, a, base, k) if f["severity"] == "block"])
    # remove the load-time objective entirely -> coverage gap -> creator adds the template
    objs = [o for o in base if o["id"] != "ISL-03"]
    objs = [{k: (v.replace("load", "x") if isinstance(v, str) else v) for k, v in o.items()} for o in objs]
    f = review.review_plan(c, a, objs, k)
    check("missing coverage is blocked", any("coverage" in x["message"] for x in f if x["severity"] == "block"))
    revised, log = review.apply_auto_fixes(c, a, objs, f)
    check("creator closes the gap by adding the template objective", any(o["id"] == "ISL-T2" for o in revised) and log)
    # priority too low -> raise, not clone
    objs = [dict(o, priority=5) if o["id"] == "ISL-04" else o for o in base]
    f = review.review_plan(c, a, objs, k)
    revised, log = review.apply_auto_fixes(c, a, objs, f)
    check("under-scored coverage is raised, not duplicated", next(o for o in revised if o["id"] == "ISL-04")["priority"] >= 9 and len(revised) == len(objs), log)
    # dependency inversion
    objs = [dict(o, priority=3) if o["id"] == "ISL-01" else o for o in base]
    check("dependency inversion is blocked", any("depends on" in x["message"] for x in review.review_plan(c, a, objs, k)))
    # structure
    objs = copy.deepcopy(base)
    objs[0]["priority"] = 11
    check("priority 11 is blocked", any("1-10" in x["message"] for x in review.review_plan(c, a, objs, k)))
    objs = copy.deepcopy(base)
    objs[0]["refs"] = ["does/not/exist.png"]
    check("missing reference is blocked", any("does not exist" in x["message"] for x in review.review_plan(c, a, objs, k)))
    objs = copy.deepcopy(base)
    objs[0]["detail"] += " the Brusskania lighthouse"
    check("retired brand name is blocked", any("forbidden" in x["message"] for x in review.review_plan(c, a, objs, k)))
    objs = [dict(o, priority=10) for o in base]
    check("all-10 plan is flagged as inflated/unprioritised", any("40%" in x["message"] or "distinct" in x["message"] for x in review.review_plan(c, a, objs, k)))
    # waves canon gate
    wc, wa = C["wave_creator"], A["waves_assessor"]
    check("wave plan passes with the gate cleared", not [x for x in review.review_plan(wc, wa, wc["objectives"], k) if x["severity"] == "block"])
    uncleared = dict(wc, gates_cleared={})
    check("wave plan is BLOCKED while the waves canon gate is not cleared", any("canon gate" in x["message"] for x in review.review_plan(uncleared, wa, wc["objectives"], k)))


def test_loop_and_gates(tmp):
    loop.STATE, loop.REPORTS = tmp / "state", tmp / "reports"
    loop.STATE.mkdir()
    loop.REPORTS.mkdir()
    s = loop.review_plan("island_creator")
    check("plan review reaches awaiting_approval", s["phase"] == "awaiting_approval", s["phase"])
    for fn, args in ((loop.execute_brief, ("island_creator",)), (loop.review_work, ("island_creator",))):
        try:
            fn(*args)
            check(f"{fn.__name__} refused before approval", False)
        except SystemExit:
            check(f"{fn.__name__} refused before approval", True)
    try:
        loop.approve("island_creator", " ")
        check("approval without a quote is refused", False)
    except SystemExit:
        check("approval without a quote is refused", True)
    loop.approve("island_creator", "all clear, go ahead")
    check("execute works after approval", "EXECUTION BRIEF" in loop.execute_brief("island_creator"))
    for i in range(3):
        s = loop.review_work("island_creator")
    check("work review stops at 3 loops and escalates", s["work_loops"] == 3 and s["phase"] == "work_escalated", (s["work_loops"], s["phase"]))
    try:
        loop.review_work("island_creator")
        check("4th work review is refused", False)
    except SystemExit:
        check("4th work review is refused", True)
    # plan loop cap: a plan the creator cannot fix mechanically escalates, never loops past 3
    c = spec.creators()["island_creator"]
    broken = copy.deepcopy(c["objectives"])
    broken[0]["refs"] = ["nope.png"]
    st = loop.load_state("saltgate_creator")
    st["objectives"] = [dict(o, refs=["nope.png"]) if o["id"] == "SLT-01" else o for o in st["objectives"]]
    loop.save_state(st)
    s = loop.review_plan("saltgate_creator")
    check("unfixable plan escalates to the creator", s["phase"] == "plan_escalated" and s["plan_loops"] <= 3, (s["phase"], s["plan_loops"]))


def test_knowledge(tmp):
    knowledge.ROOT = tmp
    (tmp / "knowledge").mkdir()
    a = spec.assessors()["island_assessor"]
    k, note = knowledge.ensure(a)
    check("assessor reads the Lore and GDD itself", k["files_read"] > 20 and k["hard_rules"], note)
    k2, note2 = knowledge.ensure(a)
    check("second ensure() reuses stored knowledge", "up to date" in note2, note2)
    k["sources"][next(iter(k["sources"]))]["sha"] = "stale"
    knowledge.path_for(a["id"]).write_text(json.dumps(k))
    check("changed docs are detected", bool(knowledge.stale(k)))


if __name__ == "__main__":
    with tempfile.TemporaryDirectory() as d:
        tmp = Path(d)
        (tmp / "g").mkdir()
        test_mesh_audit(tmp / "g")
        test_checks()
        test_specs()
        test_review_logic()
        (tmp / "l").mkdir()
        test_loop_and_gates(tmp / "l")
        (tmp / "k").mkdir()
        test_knowledge(tmp / "k")
    print(f"\n{len(FAILS)} failed" if FAILS else "\nall passed")
    sys.exit(1 if FAILS else 0)
