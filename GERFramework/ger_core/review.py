"""Offline Assessment Agent logic: reviews a creator's prioritised plan, and the creator's finished work.

No model and no tokens. The reviewer is a rubric over the spec plus the assessor's own stored Lore/GDD understanding.
Findings have severity "block" (the plan cannot go to the creator while it stands) or "warn".
"""
import copy
import re
import sys

from . import checks
from .spec import CREW, REPO, known_collaborators

sys.path.insert(0, str(CREW))
try:
    from style_guide import ALWAYS_FORBIDDEN
except Exception:  # the crew is optional for the structural rubric
    ALWAYS_FORBIDDEN = {"retired city name": r"brusskania"}

REQUIRED = ("id", "title", "priority", "why_score", "detail", "acceptance", "owner")


def _text(o: dict) -> str:
    return " ".join(str(o.get(k, "")) for k in ("title", "detail", "why_score")).lower().replace("-", " ")


def _finding(sev, obj, msg, fix=None, auto=None):
    return {"severity": sev, "objective": obj, "message": msg, "fix": fix, "auto": auto}


def review_plan(creator: dict, assessor: dict, objectives: list, knowledge: dict) -> list:
    f = []
    ids = {o.get("id") for o in objectives}
    names = known_collaborators()
    # --- structure and scoring
    for o in objectives:
        oid = o.get("id", "?")
        for k in REQUIRED:
            if o.get(k) in (None, "", []):
                f.append(_finding("block", oid, f"missing '{k}'", f"add '{k}'"))
        p = o.get("priority")
        if not isinstance(p, int) or not 1 <= p <= 10:
            f.append(_finding("block", oid, f"priority must be an integer 1-10, got {p!r}", "score 1-10 (10 = absolute must)"))
        if not o.get("checks"):
            f.append(_finding("warn", oid, "no check attached: nothing can prove this objective done", "add a check or a manual check"))
        if o.get("needs_creator") and not o.get("decision"):
            f.append(_finding("block", oid, "marked needs_creator but states no decision to make", "state the decision, the options and a recommendation"))
        for ref in o.get("refs", []):
            if not (REPO / ref).exists():
                f.append(_finding("block", oid, f"reference does not exist: {ref}", "fix the path or remove the reference"))
        for d in o.get("depends_on", []):
            if d not in ids:
                f.append(_finding("block", oid, f"depends on unknown objective {d}", "fix the id"))
        for c in o.get("collaborates", []):
            if c not in names:
                f.append(_finding("warn", oid, f"collaborator '{c}' is not a known agent", "use a roster or GER agent name"))
        txt = " ".join(str(v) for v in (o.get("title"), o.get("detail")))
        for label, pat in ALWAYS_FORBIDDEN.items():
            if re.search(pat, txt, re.I):
                f.append(_finding("block", oid, f"contains a forbidden term ({label})", "use the canon name (Saint Calder)"))
    # --- dependency inversion: a must-have cannot rest on something less important
    pri = {o.get("id"): o.get("priority", 0) for o in objectives if isinstance(o.get("priority"), int)}
    for o in objectives:
        for d in o.get("depends_on", []):
            if d in pri and isinstance(o.get("priority"), int) and pri[d] < o["priority"]:
                f.append(_finding("block", o["id"], f"scores {o['priority']} but depends on {d} which scores {pri[d]}",
                                  f"raise {d} to {o['priority']}", {"op": "raise", "id": d, "to": o["priority"]}))
    # --- score honesty
    ps = [v for v in pri.values()]
    if ps:
        if max(ps) < 10:
            f.append(_finding("block", None, "no objective scores 10: a plan must name its absolute musts", "score the true must-haves 10"))
        if sum(1 for v in ps if v == 10) > 0.4 * len(ps):
            f.append(_finding("warn", None, "more than 40% of objectives score 10: priority inflation", "separate musts from needs"))
        if len(set(ps)) < 3:
            f.append(_finding("block", None, "fewer than 3 distinct scores: the plan is not really prioritised", "spread the scores"))
    # --- coverage: the assessor's own must-cover list (derived from the creator's brief, Lore and GDD)
    for m in assessor.get("must_cover", []):
        terms = [x.lower().replace("-", " ") for x in m["terms_any"]]
        match = [o for o in objectives if isinstance(o.get("priority"), int) and any(x in _text(o) for x in terms)]
        if any(o["priority"] >= m["min_priority"] for o in match):
            continue
        if match:   # covered, but scored below what the assessor requires: raise it, do not clone it
            best = max(match, key=lambda o: o["priority"])
            f.append(_finding("block", best["id"], f"coverage [{m['id']}]: {m['topic']} is covered only at {best['priority']}; the assessor requires >= {m['min_priority']}",
                              f"raise {best['id']} to {m['min_priority']}", {"op": "raise", "id": best["id"], "to": m["min_priority"]}))
        else:
            f.append(_finding("block", None, f"coverage gap [{m['id']}]: {m['topic']} (needs an objective scoring >= {m['min_priority']} mentioning one of {m['terms_any']})",
                              "add the objective", {"op": "add", "must": m["id"]}))
    # --- canon gates the assessor holds from its stored understanding
    for g in assessor.get("canon_gates", []):
        gated = [o for o in objectives if re.search(g["pattern"], _text(o))]
        if gated and not creator.get("gates_cleared", {}).get(g["id"]):
            f.append(_finding("block", None, f"canon gate [{g['id']}]: {g['message']}", g["fix"]))
    # --- knowledge present
    if not knowledge or not knowledge.get("files_read"):
        f.append(_finding("block", None, "assessor has not read the Lore and GDD", "run: python ger.py ingest"))
    return f


def apply_auto_fixes(creator: dict, assessor: dict, objectives: list, findings: list) -> tuple[list, list]:
    """The creator's mechanical response to feedback. Returns (revised objectives, human-readable change log)."""
    objs, log = copy.deepcopy(objectives), []
    templates = {m["id"]: m for m in assessor.get("must_cover", [])}
    for fd in findings:
        a = fd.get("auto")
        if not a:
            continue
        if a["op"] == "raise":
            for o in objs:
                if o["id"] == a["id"] and o["priority"] < a["to"]:
                    log.append(f"{o['id']}: raised {o['priority']} -> {a['to']} ({fd['message'][:110]})")
                    o["priority"] = a["to"]
        elif a["op"] == "add":
            m = templates[a["must"]]
            tpl = m.get("template")
            if not tpl or any(o["id"] == tpl["id"] for o in objs):
                continue
            o = dict(tpl)
            o.setdefault("priority", m["min_priority"])
            o.setdefault("owner", creator["name"])
            objs.append(o)
            log.append(f"{o['id']}: added '{o['title']}' ({o['priority']}) to close coverage gap {m['id']}")
    objs.sort(key=lambda o: (-o.get("priority", 0), o.get("id", "")))
    return objs, log


def review_work(assessor: dict, objectives: list, recorded: dict) -> tuple[list, dict]:
    """Independent re-run of every objective's checks plus the assessor's own work_checks."""
    results, f = {}, []
    for o in objectives:
        r = checks.run_objective(o)
        results[o["id"]] = r
        rec = recorded.get(o["id"], {})
        for res in r["results"]:
            if res["ok"] is False:
                f.append(_finding("block" if o["priority"] >= 8 else "warn", o["id"], res["detail"], "fix and re-run"))
        if r["status"] == "passing" and rec.get("status") == "blocked":
            f.append(_finding("warn", o["id"], "recorded as blocked but checks pass: update the record", "record it"))
        if rec.get("status") == "done" and r["status"] == "failing":
            f.append(_finding("block", o["id"], "recorded done but checks fail", "reopen and fix"))
    for i, c in enumerate(assessor.get("work_checks", [])):
        res = checks.run_check(c)
        results[f"{assessor['id']}#{i}"] = {"status": "passing" if res["ok"] else ("needs_human" if res["ok"] is None else "failing"), "results": [res]}
        if res["ok"] is False:
            f.append(_finding("block", None, f"assessor check failed: {res['detail']}", "fix and re-run"))
    return f, results
