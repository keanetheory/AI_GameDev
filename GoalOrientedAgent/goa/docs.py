"""Markdown outputs: BACKLOG.md (always current), DEVLOG.md (append-only), HANDOFF.md (written at the end)."""
from datetime import datetime

from . import config

STATUS_ICON = {"met": "MET", "partial": "PARTIAL", "unmet": "UNMET"}


def _tasks_table(tasks):
    rows = ["| ID | Score | Task | Category | Owner role | Effort | Status |", "|---|---|---|---|---|---|---|"]
    for t in tasks:
        rows.append(f"| {t['id']} | **{t['priority']}** | {t['title']} | {t['category']} | {t['owner_role']} | "
                    f"{t['effort']} | {t['status']} |")
    return "\n".join(rows)


def write_backlog(state):
    pct, met, part, unmet = state.progress()
    out = [f"# Backlog\n\n_Generated {datetime.now():%Y-%m-%d %H:%M} by the Goal-Oriented Agent. "
           f"Do not edit by hand; the source of truth is `state/backlog.json`._\n",
           f"**Goal:** {state.goal}\n",
           f"**Goal progress:** {pct:.0f}% ({met} met, {part} partial, {unmet} unmet of {len(state.requirements)} requirements)\n",
           "## Requirements\n", "| ID | Status | Requirement | Source | Evidence |", "|---|---|---|---|---|"]
    for r in state.requirements:
        out.append(f"| {r['id']} | {STATUS_ICON.get(r['status'], r['status'])} | {r['text']} | {r['source']} | {r['evidence']} |")
    ordered = sorted(state.tasks, key=lambda t: (t["status"] != "open", -t["priority"], t["id"]))
    out += ["\n## Tasks (open first, highest score first)\n", _tasks_table(ordered)]
    waves = {}
    for t in state.tasks:
        if t["status"] == "open" and "build_wave" in t:
            waves.setdefault(t["build_wave"], []).append(t)
    if waves:
        out += ["\n## Build order (dependencies first; see `GOA Dependency Order.md`)\n",
                "| Wave | Order | ID | Task | Depends on | Waiting on |", "|---|---|---|---|---|---|"]
        for w in sorted(waves):
            for t in sorted(waves[w], key=lambda t: t.get("build_order", 0)):
                out.append(f"| {w} | {t.get('build_order', '')} | {t['id']} | {t['title']} | "
                           f"{', '.join(t.get('depends_on', [])) or '-'} | {', '.join(state.waiting_on(t)) or 'ready'} |")
    out.append("\n## Task detail\n")
    for t in ordered:
        out.append(f"### {t['id']} [{t['priority']}/10] {t['title']}  ({t['status']})\n")
        out.append(f"{t['summary']}\n")
        out.append(f"- **Why {t['priority']}:** {t['why_this_score']}")
        if t["evidence"]:
            out.append("- **Evidence:** " + "; ".join(t["evidence"]))
        if t["blocked_by"]:
            out.append(f"- **Blocked by:** {t['blocked_by']}")
        if t.get("depends_on"):
            waiting = state.waiting_on(t)
            out.append(f"- **Depends on:** {', '.join(t['depends_on'])}"
                       + (f" (still open: {', '.join(waiting)})" if waiting else " (all closed)"))
        if not t["agent_can_execute"]:
            out.append("- **Needs the creator** (cannot be done by the agent alone)")
        if t.get("result"):
            r = t["result"]
            out.append(f"- **Result ({r.get('outcome')}):** {r.get('summary', '')}")
        out.append("")
    (config.AGENT_DIR / "BACKLOG.md").write_text("\n".join(out), encoding="utf-8")


def append_devlog(task, plan, result, diff_summary, note=""):
    p = config.AGENT_DIR / "DEVLOG.md"
    if not p.exists():
        p.write_text("# Development log\n\nAppend-only record of what the Goal-Oriented Agent changed, newest last.\n", encoding="utf-8")
    lines = [f"\n## {datetime.now():%Y-%m-%d %H:%M} - {task['id']} {task['title']} (score {task['priority']})\n",
             f"**Outcome:** {result.get('outcome')}  {('- ' + note) if note else ''}\n", result.get("summary", ""), ""]
    for key, label in (("files_changed", "Files changed"), ("decisions", "Decisions"), ("verified", "Verified"),
                       ("needs_human_check", "Creator still needs to check"), ("open_issues", "Open issues")):
        if result.get(key):
            lines.append(f"**{label}:**\n" + "\n".join(f"- {x}" for x in result[key]) + "\n")
    if diff_summary:
        lines.append("**Diff summary:**\n```\n" + diff_summary + "\n```\n")
    with p.open("a", encoding="utf-8") as f:
        f.write("\n".join(lines))


def write_handoff(state, session_log_path, reason):
    pct, met, part, unmet = state.progress()
    open_t = state.open_tasks()
    done_t = [t for t in state.tasks if t["status"] == "done"]
    other = [t for t in state.tasks if t["status"] in ("deferred", "skipped")]
    out = [f"# Handoff for further work\n\n_Written {datetime.now():%Y-%m-%d %H:%M}. Closed because: {reason}._\n",
           f"**Goal:** {state.goal}\n",
           f"**Progress:** {pct:.0f}% ({met} met, {part} partial, {unmet} unmet of {len(state.requirements)} requirements)\n",
           f"**Session log:** `{session_log_path.relative_to(config.AGENT_DIR).as_posix()}`\n",
           "## Done this project\n"]
    out += [f"- {t['id']} {t['title']} - {(t.get('result') or {}).get('summary', '')}" for t in done_t] or ["- nothing yet"]
    out += ["\n## Outstanding, in the order to do them\n", _tasks_table(open_t) if open_t else "Nothing open."]
    for t in open_t:
        out.append(f"\n### {t['id']} [{t['priority']}/10] {t['title']}\n{t['summary']}\n"
                   + (f"- Blocked by: {t['blocked_by']}\n" if t["blocked_by"] else "")
                   + ("- Needs the creator, not just the agent\n" if not t["agent_can_execute"] else ""))
    if other:
        out += ["\n## Deferred or skipped (with the creator's note)\n"] + [f"- {t['id']} {t['title']} ({t['status']}): {t.get('note', '')}" for t in other]
    unmet_r = [r for r in state.requirements if r["status"] != "met"]
    if unmet_r:
        out += ["\n## Requirements not yet met\n"] + [f"- {r['id']} ({r['status']}) {r['text']} - {r['evidence']}" for r in unmet_r]
    issues = [i for t in state.tasks if t.get("result") for i in (t["result"].get("open_issues") or [])]
    if issues:
        out += ["\n## Open issues recorded during execution\n"] + [f"- {i}" for i in issues]
    checks = [f"- {t['id']}: {c}" for t in done_t if t.get("result") for c in (t["result"].get("needs_human_check") or [])]
    if checks:
        out += ["\n## Things the creator still has to check in Godot\n"] + checks
    out.append("\nTo resume: `python main.py` (it reloads `state/backlog.json`; `rescan` re-analyses against the current files).")
    (config.AGENT_DIR / "HANDOFF.md").write_text("\n".join(out) + "\n", encoding="utf-8")
