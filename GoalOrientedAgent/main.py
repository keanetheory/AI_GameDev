"""Goal-Oriented Coding Agent for Lighting the Storm.

    python main.py              survey + analyse (first run), then the human-in-the-loop task cycle
    python main.py --dry-run    survey only: show what the agent would read, no API calls
    python main.py --rescan     throw away open tasks and re-analyse against the current files

The cycle:  SURVEY -> ANALYSE -> PROPOSE -> (human picks) -> IMPLICATIONS -> (human all-clear) -> EXECUTE
            -> REVIEW diff (keep / undo) -> UPDATE goal state -> back to PROPOSE, until the human says done.
"""
import argparse
import difflib
import sys
import textwrap
from datetime import datetime

from goa import config, docs, survey
from goa.state import State, SessionLog
from goa.tools import undo_from_disk

W = 100


def out(s=""):
    print(s, flush=True)


def wrap(s, indent="   "):
    return textwrap.fill(str(s), W, initial_indent=indent, subsequent_indent=indent)


def ask(prompt, log):
    try:
        ans = input(prompt).strip()
    except EOFError:
        ans = "done"
        out("done (end of input)")
    log.human(ans)
    return ans


# ---- rendering ---------------------------------------------------------------------------------------
def show_progress(state):
    pct, met, part, unmet = state.progress()
    bar = "#" * int(pct / 5) + "." * (20 - int(pct / 5))
    out(f"\nGOAL PROGRESS [{bar}] {pct:.0f}%   requirements: {met} met, {part} partial, {unmet} unmet")


def show_backlog(state, everything=False):
    show_progress(state)
    tasks = state.open_tasks()
    out("\nPRIORITISED TASKS  (10 = absolute must, 1 = not required, nice to do some day)")
    out("-" * W)
    for t in tasks:
        flag = "" if t["agent_can_execute"] else "  [needs you]"
        waiting = state.waiting_on(t)
        if waiting:
            flag += f"  [waiting on {', '.join(waiting)}]"
        out(f" {t['id']}  [{t['priority']:>2}/10] {'#' * t['priority']:<10} {t['title']}{flag}")
        out(f"       {t['category']} | {t['owner_role']} | effort {t['effort']}")
    if not tasks:
        out(" (no open tasks)")
    if everything:
        closed = [t for t in state.tasks if t["status"] != "open"]
        if closed:
            out("\nCLOSED")
            for t in closed:
                out(f" {t['id']}  {t['status']:<8} {t['title']}")
    out("-" * W)


def show_task(t):
    out(f"\n{t['id']} [{t['priority']}/10] {t['title']}")
    out(wrap(t["summary"]))
    out(wrap("Why this score: " + t["why_this_score"]))
    for e in t["evidence"]:
        out(wrap("- " + e, "     "))
    if t["blocked_by"]:
        out(wrap("Blocked by: " + t["blocked_by"]))
    if t.get("depends_on"):
        out(wrap("Depends on: " + ", ".join(t["depends_on"])))


def show_requirements(state):
    show_progress(state)
    for r in state.requirements:
        out(f" {r['id']}  {r['status'].upper():<8} {r['text']}")
        out(wrap(f"({r['source']}) {r['evidence']}", "           "))


def show_plan(plan):
    out("\nIMPLICATIONS AND PLAN")
    out("-" * W)
    out(wrap(plan["approach"]))
    out("\n Steps:")
    for i, s in enumerate(plan["steps"], 1):
        out(wrap(f"{i}. {s}", "   "))
    if plan.get("files_to_change"):
        out("\n Files to change:  " + ", ".join(plan["files_to_change"]))
    if plan.get("files_to_create"):
        out(" Files to create:  " + ", ".join(plan["files_to_create"]))
    imp = plan["implications"]
    out("\n Implications:")
    for k, label in (("player", "Player"), ("performance", "Performance"),
                     ("contracts_and_other_agents", "Contracts / other agents"),
                     ("canon_and_docs", "Canon / docs"), ("reversibility", "Reversibility")):
        out(wrap(f"{label}: {imp.get(k, '')}", "   "))
    for key, label in (("risks", "Risks"), ("needs_human_check", "You will need to check")):
        if plan.get(key):
            out(f"\n {label}:")
            for x in plan[key]:
                out(wrap("- " + x, "   "))
    if plan.get("estimated_agent_effort"):
        out(f"\n Agent effort: {plan['estimated_agent_effort']}")
    if not plan.get("ready", True):
        out("\n BLOCKED - the creator must decide first:")
        for q in plan.get("blocked_questions", []):
            out(wrap("? " + q, "   "))
    out("-" * W)


def diff_of(sb):
    parts, summary = [], []
    for rel, kind in sb.manifest.items():
        new = (config.ROOT / rel).read_text(encoding="utf-8", errors="replace").splitlines() if (config.ROOT / rel).exists() else []
        old = (sb.backup_dir / rel).read_text(encoding="utf-8", errors="replace").splitlines() if kind == "modified" else []
        d = list(difflib.unified_diff(old, new, f"a/{rel}", f"b/{rel}", lineterm="", n=2))
        add = sum(1 for l in d if l.startswith("+") and not l.startswith("+++"))
        rem = sum(1 for l in d if l.startswith("-") and not l.startswith("---"))
        summary.append(f"{kind:<9} {rel}  (+{add} -{rem})")
        parts += d
    return "\n".join(summary), "\n".join(parts)


# ---- the cycle -----------------------------------------------------------------------------------------
def do_analysis(agent, state, log, first):
    res = agent.analyse()
    if not first:
        state.tasks = [t for t in state.tasks if t["status"] != "open"]
    state.requirements = res["requirements"]
    state.add_tasks(res["tasks"])
    state.analysed_at = datetime.now().isoformat(timespec="seconds")
    state.log("-", "analysed", f"{len(res['requirements'])} requirements, {len(res['tasks'])} tasks")
    state.save()
    docs.write_backlog(state)
    out("\n" + wrap(res["summary"], ""))
    log.add("Analysis summary", res["summary"])


def work_on(task, agent, state, log):
    show_task(task)
    plan = agent.plan(task)
    show_plan(plan)
    log.add(f"Plan {task['id']}", "```json\n" + __import__("json").dumps(plan, indent=2) + "\n```")
    state.log(task["id"], "planned")
    if not plan.get("ready", True) or not task["agent_can_execute"]:
        out("\nThis task cannot be executed by the agent as it stands (see above).")
        a = ask("Record it as blocked and go back to the list? [y = yes / n = stay]: ", log).lower()
        if a.startswith("y"):
            task["blocked_by"] = task["blocked_by"] or "; ".join(plan.get("blocked_questions", [])) or "needs the creator"
            state.log(task["id"], "blocked", task["blocked_by"])
        return
    note = ""
    while True:
        a = ask("\nAll clear to execute? [y = go / n = cancel / or type a change to the plan]: ", log)
        if a.lower() in ("y", "yes", "go"):
            break
        if a.lower() in ("n", "no", "cancel", ""):
            out("Cancelled. Nothing was changed.")
            state.log(task["id"], "cancelled")
            return
        note = a
        out("Noted; I will pass that to the executing agent as an instruction.")
        log.agent(f"plan amended by creator: {a}")
        break
    if note and ask("Go ahead with that change? [y/n]: ", log).lower() not in ("y", "yes"):
        out("Cancelled. Nothing was changed.")
        state.log(task["id"], "cancelled")
        return

    def confirm_cmd(cmd, why):
        out(f"\n   The agent wants to run:  {cmd}\n   Why: {why}")
        return ask("   Allow this command? [y/n]: ", log).lower() in ("y", "yes")

    agent.confirm_cmd = confirm_cmd
    try:
        result, sb = agent.execute(task, plan, note)
    except Exception as e:
        out(f"\nExecution stopped: {type(e).__name__}: {e}")
        log.add(f"Execute {task['id']} failed", f"{type(e).__name__}: {e}")
        state.log(task["id"], "execute-error", str(e))
        return
    summary, full = diff_of(sb)
    out(f"\nRESULT: {result['outcome'].upper()}")
    out(wrap(result["summary"]))
    out("\n Changed:\n   " + ("\n   ".join(summary.splitlines()) or "(no files changed)"))
    for key, label in (("verified", "Verified"), ("needs_human_check", "You still need to check"), ("open_issues", "Open issues")):
        if result.get(key):
            out(f"\n {label}:")
            for x in result[key]:
                out(wrap("- " + x, "   "))
    log.add(f"Execute {task['id']} diff", "```diff\n" + full[:60000] + "\n```")
    while True:
        a = ask("\n[k]eep / [u]ndo / [d]iff to see the full diff: ", log).lower()
        if a.startswith("d"):
            out(full[:20000] + ("\n... (more in the session log)" if len(full) > 20000 else ""))
        elif a.startswith("u"):
            for line in sb.undo():
                out("   restored " + line)
            state.log(task["id"], "undone")
            out("Undone. The files are back as they were.")
            return
        elif a.startswith("k"):
            break
    task["status"] = "done" if result["outcome"] == "done" else "open"
    task["result"] = result
    for u in result.get("requirement_updates", []):
        for r in state.requirements:
            if r["id"] == u["id"]:
                r["status"], r["evidence"] = u["status"], u["evidence"]
    state.add_tasks(result.get("follow_up_tasks", []))
    state.log(task["id"], "executed", f"{result['outcome']}: {result['summary'][:200]}")
    docs.append_devlog(task, plan, result, summary)
    state.save()
    docs.write_backlog(state)
    if result.get("follow_up_tasks"):
        out(f"\n{len(result['follow_up_tasks'])} follow-up task(s) were added to the backlog.")


HELP = """Commands:
  <id>  or  do <id>     work on a task (e.g. T03 or 3): shows implications, waits for your all clear, then executes
  list / all            show open tasks / show open and closed tasks
  show <id>             full detail for a task
  goal                  requirements checklist and progress
  ask <question>        ask the agent about the project or the backlog (read-only)
  score <id> <1-10>     change a task's priority score
  skip <id> [note]      drop a task (kept in the record)
  defer <id> [note]     park a task for later work (goes in the handoff)
  rescan                re-run the analysis against the current files
  undo <id>             restore the files from a task you kept (while its backup exists)
  done                  requirements are met or documented: write HANDOFF.md and finish
  help"""


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true", help="survey only, no API calls")
    ap.add_argument("--rescan", action="store_true", help="re-analyse and replace open tasks")
    ap.add_argument("--no-images", action="store_true", help="do not attach concept-art thumbnails")
    ap.add_argument("--model", help="override the model")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    config.load_env()
    if args.model:
        config.MODEL = args.model

    out("=" * W + "\n GOAL-ORIENTED CODING AGENT - Lighting the Storm\n" + "=" * W)
    out("[SURVEY] Reading Docs/, ConceptArt/, AIAgentCrew/ and LightingTheStorm/ ...")
    sv = survey.build(images=not args.no_images)
    st = sv["stats"]
    out(f"   GDD text {st['gdd_chars']:,} chars | context ~{st['approx_tokens']:,} tokens | "
        f"{st['art_folders']} concept-art folders ({st['art_images_attached']} images attached) | {st['game_scripts']} game scripts")
    if args.dry_run:
        out("\n--dry-run: stopping before any model call. Context preview (first 2500 chars):\n")
        out(sv["text"][:2500])
        return

    client = config.make_client()
    state, log = State.load(), SessionLog()
    from goa.agent import Agent
    agent = Agent(client, log, sv, state, say=out)
    log.add("Survey", f"```\n{st}\n```")

    first = not state.tasks
    if first or args.rescan:
        do_analysis(agent, state, log, first)
    else:
        out(f"\nLoaded the existing backlog from {state.analysed_at} ({len(state.open_tasks())} open tasks). Type 'rescan' to re-analyse.")

    qa_history, reason = [], "the creator ended the session"
    show_backlog(state)
    out("\nType a task id to work on it, or 'help'.")
    while True:
        raw = ask("\ngoal-agent> ", log)
        cmd, _, rest = raw.partition(" ")
        cmd = cmd.lower()
        if cmd in ("done", "quit", "exit"):
            open_n = len(state.open_tasks())
            if open_n and cmd != "done":
                if ask(f"{open_n} tasks are still open. Write the handoff and finish? [y/n]: ", log).lower() != "y":
                    continue
            reason = "the creator said the requirements are met" if cmd == "done" else reason
            break
        elif cmd in ("help", "?", ""):
            out(HELP)
        elif cmd in ("list", "l"):
            show_backlog(state)
        elif cmd == "all":
            show_backlog(state, everything=True)
        elif cmd == "goal":
            show_requirements(state)
        elif cmd == "rescan":
            do_analysis(agent, state, log, first=False)
            show_backlog(state)
        elif cmd == "ask":
            if not rest:
                out("Usage: ask <question>")
                continue
            ans = agent.ask(rest, qa_history)
            out("\n" + ans)
            log.agent(ans)
        elif cmd in ("show", "score", "skip", "defer", "undo", "do") or raw[:1].upper() == "T" or raw.isdigit():
            tid, _, tail = (rest if cmd in ("show", "score", "skip", "defer", "undo", "do") else raw).partition(" ")
            try:
                t = state.get(tid)
            except ValueError:
                t = None
            if not t:
                out("No such task. Type 'list'.")
                continue
            if cmd == "show":
                show_task(t)
            elif cmd == "score":
                try:
                    t["priority"] = max(1, min(10, int(tail)))
                    state.log(t["id"], "rescored", str(t["priority"]))
                except ValueError:
                    out("Usage: score <id> <1-10>")
            elif cmd in ("skip", "defer"):
                t["status"] = "skipped" if cmd == "skip" else "deferred"
                t["note"] = tail
                state.log(t["id"], t["status"], tail)
                out(f"{t['id']} marked {t['status']}.")
            elif cmd == "undo":
                restored = []
                import glob as _g
                for d in sorted(config.BACKUP_DIR.glob(f"{t['id']}_*"), reverse=True):
                    restored = undo_from_disk(d.name)
                    break
                out("\n".join("   restored " + r for r in restored) or "No backup found for that task.")
                if restored:
                    t["status"], t["result"] = "open", None
                    state.log(t["id"], "undone")
            else:
                work_on(t, agent, state, log)
            state.save()
            docs.write_backlog(state)
            if cmd not in ("show",):
                show_backlog(state)
        else:
            out("Unknown command. Type 'help'.")

    state.log("-", "session-end", reason)
    state.save()
    docs.write_backlog(state)
    docs.write_handoff(state, log.path, reason)
    show_progress(state)
    out("\nWrote GoalOrientedAgent/HANDOFF.md, BACKLOG.md, DEVLOG.md (if tasks ran) and the session log:")
    out(f"   {log.path}")


if __name__ == "__main__":
    main()
