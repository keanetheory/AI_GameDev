"""The GER loop: plan -> assess (max 3 loops) -> creator approval -> execute -> assess (max 3 loops) -> report.

State lives in state/<creator>.json so a session can stop and resume. The creator (the human) is the only one who
can move a plan from 'awaiting_approval' to 'approved' (python ger.py approve <id> --quote "<your go-ahead>").
"""
import json
from datetime import datetime, timezone

from . import checks, knowledge, review
from .spec import ROOT, pair

MAX_LOOPS = 3
STATE = ROOT / "state"
REPORTS = ROOT / "reports"


def _now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load_state(cid: str) -> dict:
    p = STATE / f"{cid}.json"
    if p.exists():
        return json.loads(p.read_text(encoding="utf-8"))
    c, _ = pair(cid)
    return {"creator": cid, "phase": "new", "plan_loops": 0, "work_loops": 0,
            "objectives": sorted(c["objectives"], key=lambda o: (-o["priority"], o["id"])),
            "records": {}, "history": [], "approval": None}


def save_state(s: dict):
    STATE.mkdir(exist_ok=True)
    (STATE / f"{s['creator']}.json").write_text(json.dumps(s, indent=1), encoding="utf-8")


def _fmt(f: dict) -> str:
    return f"[{f['severity'].upper()}] {f['objective'] or 'plan'}: {f['message']}" + (f"  -> {f['fix']}" if f.get("fix") else "")


# ------------------------------------------------------------------ plan
def review_plan(cid: str, reset: bool = False) -> dict:
    c, a = pair(cid)
    s = load_state(cid)
    if reset:
        s = {"creator": cid, "phase": "new", "plan_loops": 0, "work_loops": 0,
             "objectives": sorted(c["objectives"], key=lambda o: (-o["priority"], o["id"])),
             "records": {}, "history": [], "approval": None}
    if s["phase"] in ("approved", "executing", "work_passed", "work_escalated"):
        raise SystemExit(f"{cid} is already past planning (phase {s['phase']}). Use --reset to start over.")
    k, note = knowledge.ensure(a)
    s["knowledge_note"] = note
    s["phase"] = "plan_in_review"
    for _ in range(MAX_LOOPS - s["plan_loops"]):
        findings = review.review_plan(c, a, s["objectives"], k)
        s["plan_loops"] += 1
        entry = {"kind": "plan_review", "loop": s["plan_loops"], "at": _now(), "findings": findings, "changes": []}
        s["history"].append(entry)
        if not any(f["severity"] == "block" for f in findings):
            break
        revised, log = review.apply_auto_fixes(c, a, s["objectives"], findings)
        entry["changes"] = log
        if not log:            # nothing the creator can fix by itself: it goes to the human
            break
        s["objectives"] = revised
    s["last_findings"] = review.review_plan(c, a, s["objectives"], k)   # final look at the final plan
    s["last_blocks"] = sum(1 for f in s["last_findings"] if f["severity"] == "block")
    s["phase"] = "awaiting_approval" if s["last_blocks"] == 0 else "plan_escalated"
    save_state(s)
    write_plan_report(c, a, s)
    return s


def write_plan_report(c: dict, a: dict, s: dict):
    REPORTS.mkdir(exist_ok=True)
    base = {o["id"]: checks.run_objective(o) for o in s["objectives"]}
    L = [f"# {c['name']}: prioritised plan", "",
         f"- Assessor: **{a['name']}** ({s.get('knowledge_note', '')})",
         f"- Phase: **{s['phase']}** | plan review loops used: {s['plan_loops']} of {MAX_LOOPS}",
         f"- Blocking findings left: **{s['last_blocks']}**", "",
         f"**Mission:** {c['mission']}", "", "## Objectives (10 = absolute must)", "",
         "| ID | Score | Objective | Needs you | Baseline today |", "|---|---|---|---|---|"]
    for o in s["objectives"]:
        L.append(f"| {o['id']} | **{o['priority']}** | {o['title']} | {'YES' if o.get('needs_creator') else ''} | {'decision pending' if o.get('needs_creator') else base[o['id']]['status']} |")
    L += ["", "## Detail", ""]
    for o in s["objectives"]:
        L += [f"### {o['id']} [{o['priority']}/10] {o['title']}", o["detail"], "",
              f"- Why this score: {o['why_score']}",
              "- Done when: " + "; ".join(o["acceptance"]),
              f"- Owner: {o['owner']}" + (f" | works with: {', '.join(o['collaborates'])}" if o.get("collaborates") else ""),
              ("- Depends on: " + ", ".join(o["depends_on"])) if o.get("depends_on") else "- Depends on: nothing",
              ("- Baseline evidence:\n" + "\n".join(f"  - {r['detail']}" for r in base[o['id']]['results'])) if base[o['id']]['results'] else ""]
        if o.get("needs_creator"):
            L.append(f"- **Decision for you:** {o['decision']}")
        L.append("")
    qs = [o for o in s["objectives"] if o.get("needs_creator")]
    L += ["## Questions for you", ""] + ([f"- **{o['id']}**: {o['decision']}" for o in qs] or ["- None"]) + ["", "## Review history", ""]
    for h in s["history"]:
        if h["kind"] != "plan_review":
            continue
        L.append(f"### Loop {h['loop']} ({h['at']})")
        L += [f"- {_fmt(f)}" for f in h["findings"]] or ["- no findings"]
        L += [f"- CREATOR CHANGE: {x}" for x in h["changes"]]
        L.append("")
    if s["phase"] == "plan_escalated":
        L += ["## Escalated to you", "These blocks need a human or an edit to the spec; the creator could not fix them mechanically:", ""]
        L += [f"- {_fmt(f)}" for f in s["last_findings"] if f["severity"] == "block"]
    (REPORTS / f"{c['id']}_plan.md").write_text("\n".join(L), encoding="utf-8")


# ------------------------------------------------------------------ approval and execution
def approve(cid: str, quote: str) -> dict:
    s = load_state(cid)
    if s["phase"] != "awaiting_approval":
        raise SystemExit(f"{cid} is in phase '{s['phase']}', not awaiting_approval. Run review-plan first.")
    if len(quote.strip()) < 3:
        raise SystemExit("approval needs --quote with the creator's go-ahead, verbatim.")
    s["approval"] = {"at": _now(), "quote": quote.strip()}
    s["phase"] = "approved"
    save_state(s)
    return s


def execute_brief(cid: str) -> str:
    s = load_state(cid)
    if s["phase"] not in ("approved", "executing"):
        raise SystemExit(f"{cid} is not approved (phase '{s['phase']}'). The creator must give the all clear first.")
    c, a = pair(cid)
    s["phase"] = "executing"
    save_state(s)
    L = [f"# EXECUTION BRIEF: {c['name']}", f"Approved {s['approval']['at']}: \"{s['approval']['quote']}\"",
         f"Work review loops used: {s['work_loops']} of {MAX_LOOPS}. Assessor: {a['name']}.", "",
         "Work top-down by score. Record each result with: python ger.py record <id> <OBJ> done|blocked|in_progress --note \"...\"",
         "Then run: python ger.py review-work <id>. Fix every BLOCK it returns and run it again (max 3 loops).", ""]
    for o in s["objectives"]:
        rec = s["records"].get(o["id"], {}).get("status", "open")
        L += [f"## {o['id']} [{o['priority']}] {o['title']}  ({rec})", o["detail"], "Done when: " + "; ".join(o["acceptance"]),
              "Refs: " + ", ".join(o.get("refs", [])) if o.get("refs") else "",
              ("NEEDS CREATOR DECISION (do not decide): " + o["decision"]) if o.get("needs_creator") else "", ""]
    return "\n".join(x for x in L if x is not None)


def record(cid: str, oid: str, status: str, note: str):
    s = load_state(cid)
    if oid not in {o["id"] for o in s["objectives"]}:
        raise SystemExit(f"unknown objective {oid}")
    s["records"][oid] = {"status": status, "note": note, "at": _now()}
    save_state(s)


def review_work(cid: str) -> dict:
    s = load_state(cid)
    if s["phase"] not in ("executing", "work_escalated"):
        raise SystemExit(f"{cid} is in phase '{s['phase']}': approve and execute first.")
    if s["work_loops"] >= MAX_LOOPS:
        raise SystemExit(f"{cid} has used all {MAX_LOOPS} work review loops; the report has gone to the creator.")
    c, a = pair(cid)
    findings, results = review.review_work(a, s["objectives"], s["records"])
    s["work_loops"] += 1
    s["history"].append({"kind": "work_review", "loop": s["work_loops"], "at": _now(), "findings": findings,
                         "statuses": {k: v["status"] for k, v in results.items()}})
    blocks = [f for f in findings if f["severity"] == "block"]
    open_items = [o for o in s["objectives"] if s["records"].get(o["id"], {}).get("status") != "done" and not o.get("needs_creator")]
    if not blocks and not open_items:
        s["phase"] = "work_passed"
    elif s["work_loops"] >= MAX_LOOPS:
        s["phase"] = "work_escalated"
    s["last_work"] = {"blocks": len(blocks), "open": [o["id"] for o in open_items]}
    save_state(s)
    write_work_report(c, a, s, results, findings)
    return s


def write_work_report(c, a, s, results, findings):
    L = [f"# {c['name']}: work review", "", f"- Phase: **{s['phase']}** | work review loops: {s['work_loops']} of {MAX_LOOPS}",
         f"- Assessor: {a['name']}", "", "| ID | Score | Recorded | Checks | Title |", "|---|---|---|---|---|"]
    for o in s["objectives"]:
        L.append(f"| {o['id']} | {o['priority']} | {s['records'].get(o['id'], {}).get('status', 'open')} | {results[o['id']]['status']} | {o['title']} |")
    L += ["", "## Feedback to the creator agent (act on every BLOCK without asking the user)", ""]
    L += [f"- {_fmt(f)}" for f in findings] or ["- none"]
    L += ["", "## Needs the creator (decisions / in-editor checks)", ""]
    L += [f"- {o['id']}: {o['decision']}" for o in s["objectives"] if o.get("needs_creator")] or ["- none"]
    L += [f"- {o['id']}: " + "; ".join(r["detail"] for r in results[o["id"]]["results"] if r["ok"] is None)
          for o in s["objectives"] if results[o["id"]]["status"] == "needs_human"]
    (REPORTS / f"{c['id']}_work.md").write_text("\n".join(L), encoding="utf-8")


# ------------------------------------------------------------------ assessors with no creator (existing work)
def assess_existing(aid: str) -> str:
    from .spec import assessors
    a = assessors()[aid]
    k, note = knowledge.ensure(a)
    rows, fails = [], 0
    for i, w in enumerate(a.get("work_checks", []), 1):
        r = checks.run_check(w)
        st = "PASS" if r["ok"] else ("HUMAN" if r["ok"] is None else "FAIL")
        fails += st == "FAIL"
        rows.append((f"{aid[:3].upper()}-{i:02d}", w.get("priority", 8 if st == "FAIL" else 4), st, r["detail"]))
    rows.sort(key=lambda x: (x[2] != "FAIL", -x[1]))
    L = [f"# {a['name']}: assessment of existing work", "", f"- {note}; {k['files_read']} docs read, {len(k['hard_rules'])} hard rules, {len(k['open_questions'])} open questions held",
         f"- Feedback goes to: {', '.join(a['feedback_to'])}", f"- Failing checks: **{fails}**", "", f"**Mandate:** {a['mandate']}", "",
         "| ID | Score (1-10) | Result | Evidence |", "|---|---|---|---|"]
    L += [f"| {i} | {p} | {s} | {d.replace('|', '/')} |" for i, p, s, d in rows]
    L += ["", "## Open questions this assessor will not let anyone settle silently", ""]
    L += [f"- {q['text'][:200]}  ({q['src']})" for q in k["open_questions"][:8]] or ["- none found"]
    REPORTS.mkdir(exist_ok=True)
    out = REPORTS / f"{aid}_assessment.md"
    out.write_text("\n".join(L), encoding="utf-8")
    return f"{aid}: {fails} failing of {len(rows)} checks -> {out.relative_to(ROOT.parent)}"
