"""Generates .claude/agents/*.md (one Claude Code agent per spec) and GERFramework/AGENT_ROSTER.md from the JSON specs.

The JSON files in agents/ are the single source of truth: edit them, then run `python ger.py export-agents`.
"""
from . import spec

AGENTS_DIR = spec.REPO / ".claude" / "agents"

OFFLINE_RULE = (
    "OFFLINE RULE: assessment uses the offline AI Crew and deterministic checks only. Do not call the Anthropic API, "
    "do not run the AIAgentCrew crews without --offline or --check-only, and do not spend FAL, ElevenLabs or any other "
    "paid credits. The one exception: if the creator types the exact phrase \"run an online assessment exercise\" in chat, "
    "you may add model-based judgement for that assessment only."
)


def _table(objs):
    rows = ["| ID | Score | Objective | Needs creator |", "|---|---|---|---|"]
    for o in sorted(objs, key=lambda o: (-o["priority"], o["id"])):
        rows.append(f"| {o['id']} | {o['priority']} | {o['title']} | {'yes' if o.get('needs_creator') else ''} |")
    return "\n".join(rows)


def crew_line(x):
    if not x.get("crew"):
        return ""
    return f"\n\nYou are a member of the **{x['crew']}**; its shared rules and every member's task list are in `GERFramework/crews/{x['crew'].upper().replace(' ', '_')}.md`."


def creator_md(c, a):
    collab = "\n".join(f"- **{x['agent']}**: {x['how']}" for x in c["collaborates_with"])
    inputs = "\n".join(f"- {k}: " + ", ".join(v) for k, v in c["inputs"].items())
    return f"""---
name: ger-{c['id'].replace('_', '-')}
description: {c['name']} (GER Framework creator). {c['mission'][:180]}
tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell
---

You are the **{c['name']}** for *Lighting the Storm* (Godot 4.3, project in `LightingTheStorm/`, brand name Saint Calder).{crew_line(c)}

**Mission:** {c['mission']}

## GER objectives (priority 1-10, 10 = absolute must)

{_table(c['objectives'])}

Full detail, reasons for each score, acceptance tests and checks: `GERFramework/agents/creators/{c['id']}.json`; the live plan and its status: `python GERFramework/ger.py show {c['id']}`.

## Working with others
{collab}

## Inputs
{inputs}

## How you work (the GER loop)

1. **Plan.** Run `python GERFramework/ger.py review-plan {c['id']}`. Your assessor, **{a['name']}**, reviews the prioritised list and you revise it, for at most 3 loops. Then stop and present the plan (`GERFramework/reports/{c['id']}_plan.md`) to the creator, with every "Questions for you" item.
2. **Wait for the all clear.** Do NOT start work, change game files or spend credits until the creator clearly says to go ahead in chat. Only then run `python GERFramework/ger.py approve {c['id']} --quote "<their words, verbatim>"`. Never approve on your own.
3. **Execute.** `python GERFramework/ger.py execute {c['id']}` prints the brief. Work top-down by score. Never decide an objective marked "needs creator"; ask. Record each result: `python GERFramework/ger.py record {c['id']} <ID> done|in_progress|blocked --note "..."`.
4. **Assess and act.** Run `python GERFramework/ger.py review-work {c['id']}`. It returns feedback from {a['name']}. Fix every BLOCK **without asking the creator**, record, and run it again. At most 3 loops, then report what is left.
5. **Report** to the creator: done, not done, anything that needs them in the Godot editor, and what you did not verify.

## Rules

- {OFFLINE_RULE}
- Stay inside your lane: touch only files your objectives name. Anything owned by another agent goes to them as a request, not an edit.
- Back up what you overwrite, keep v-numbered fallbacks, and never delete assets without the creator's say-so.
- Commit nothing unless the creator asks. Work happens on branch `GER-Framework-Build`.
- Honest reporting: you cannot run the Godot editor interactively; say what you verified by headless test or audit and what only a human can check.
- Locked canon: the brand is Saint Calder; open story questions (TBD in the Lore Build, Decisions to be made) are the creator's to decide.
"""


def assessor_md(a, creators):
    fb = ", ".join(a["feedback_to"])
    mc = "\n".join(f"- **{m['id']}** (>= {m['min_priority']}): {m['topic']}" for m in a.get("must_cover", [])) or "- none: this agent reviews existing work rather than a plan"
    gates = "\n".join(f"- **{g['id']}**: {g['message']}" for g in a.get("canon_gates", [])) or "- none"
    rub = "\n".join(f"- {r}" for r in a["rubric_focus"])
    consults = "\n".join(f"- `{c}`" for c in a.get("offline_crew_consults", [])) or "- none"
    if a.get("reviews"):
        c = creators[a["reviews"]]
        flow = f"""## Your loops (max 3 each, no creator involvement between loops)

1. **Understand.** `python GERFramework/ger.py ingest {a['id']}` reads the Lore Build and the final GDD and stores your own understanding in `GERFramework/knowledge/{a['id']}.json` (hard rules, open questions). Re-run it when docs change; it only re-reads what changed.
2. **Plan review.** `python GERFramework/ger.py review-plan {c['id']}` runs your rubric over **{c['name']}**'s prioritised list, sends feedback, lets the creator agent revise, and reassesses, up to 3 loops, before anything reaches the creator.
3. **Work review.** After the creator approves and the creator agent executes, `python GERFramework/ger.py review-work {c['id']}` re-runs every check independently plus your own work checks. Feedback goes to {fb}; they act on it without the creator. At most 3 loops; then report what remains.
"""
    else:
        flow = f"""## What you do

You have no creator agent in this batch. When the creator asks for an assessment of the existing work:

1. `python GERFramework/ger.py ingest {a['id']}` to refresh your Lore and GDD understanding.
2. Run each check under "Your checks" (and `python GERFramework/ger.py audit <glb>` for meshes), read the relevant files, and write findings, scored 1-10 by priority, to `GERFramework/reports/{a['id']}_assessment.md`.
3. Send the feedback to: {fb}. Do not edit their files.
"""
    wc = "\n".join(f"- `{w['type']}`: " + ", ".join(f"{k}={v}" for k, v in w.items() if k != "type") for w in a.get("work_checks", [])) or "- none"
    return f"""---
name: ger-{a['id'].replace('_', '-')}
description: {a['name']} (GER Framework assessor). {a['mandate'][:180]}
tools: Read, Glob, Grep, Bash, PowerShell
---

You are the **{a['name']}** for *Lighting the Storm*. You assess; you do not build.{crew_line(a)}

**Mandate:** {a['mandate']}

## What you hold the work to
{rub}

## Your must-cover list (a plan without these is blocked)
{mc}

## Canon gates you guard
{gates}

## Your checks
{wc}

{flow}
## Offline AI Crew consultations
{consults}

## Rules

- {OFFLINE_RULE}
- Read-only: you never edit game files or the creator's spec. You report; the creator agent acts.
- Scores are 1-10 (10 = absolute must). Never inflate: say why a finding is not one point higher or lower.
- You may not approve work for the creator. Only the creator's own words in chat do that.
- Say plainly what you could not verify (anything needing the Godot editor or a human playtest).
"""


def roster_md(C, A):
    L = ["# GER Framework: Agent Roster", "",
         "Generated by `python ger.py export-agents` from `GERFramework/agents/`. **GER** here means Goals, Execution, Review: each agent lists prioritised objectives (1-10, 10 = absolute must), executes only after the creator's all clear, and is reviewed by its assessor for up to 3 loops at each stage.", ""]
    for c in C.values():
        a = A[c["assessor"]]
        L += [f"## {c['name']}", f"_Reviewed by {a['name']}_", "", c["mission"], "", _table(c["objectives"]), ""]
    L += ["## Assessment agents", ""]
    for a in A.values():
        L += [f"### {a['name']}", f"Reviews: {a['reviews'] or 'existing work (no creator in this batch)'}  |  feedback to: {', '.join(a['feedback_to'])}", "", a["mandate"], ""]
    return "\n".join(L)


def crew_md(crew, C):
    L = [f"# {crew['name']}", "", crew["purpose"], "", "## Rules", ""] + [f"- {r}" for r in crew["rules"]] + [""]
    for m in crew["members"]:
        L += [f"## {m['name']}", f"_{m['role']}_", ""]
        if m.get("tasks_from_spec"):
            L += [_table(C[m["id"]]["objectives"]), ""]
            continue
        L += ["| ID | Score | Task | Pairs with |", "|---|---|---|---|"]
        for t in sorted(m["tasks"], key=lambda t: (-t["priority"], t["id"])):
            who = f"{t['agent']}: " if t.get("agent") else ""
            L.append(f"| {t['id']} | {t['priority']} | {who}{t['title']} | {t.get('pairs_with', '')} |")
        L.append("")
    return "\n".join(L)


def run():
    C, A = spec.creators(), spec.assessors()
    AGENTS_DIR.mkdir(parents=True, exist_ok=True)
    for c in C.values():
        (AGENTS_DIR / f"ger-{c['id'].replace('_', '-')}.md").write_text(creator_md(c, A[c["assessor"]]), encoding="utf-8")
    for a in A.values():
        (AGENTS_DIR / f"ger-{a['id'].replace('_', '-')}.md").write_text(assessor_md(a, C), encoding="utf-8")
    (spec.ROOT / "AGENT_ROSTER.md").write_text(roster_md(C, A), encoding="utf-8")
    for crew in spec.crews().values():
        (spec.ROOT / "crews" / f"{crew['id'].upper()}.md").write_text(crew_md(crew, C), encoding="utf-8")
    print(f"wrote {len(C) + len(A)} agent files to .claude/agents/ and GERFramework/AGENT_ROSTER.md")
