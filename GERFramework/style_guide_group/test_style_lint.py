"""Calibration tests for style_lint: the creator-approved opening dialogue must lint clean, and each
violation class must be caught. Run: python test_style_lint.py"""
import re
import sys
from pathlib import Path

from style_lint import lint

FINAL = Path(__file__).resolve().parents[2] / "Docs" / "Lore Build" / "dialogue" / "DIALOGUE_OPENING_FINAL.md"


def approved_records() -> list[str]:
    event, out = None, []
    for line in FINAL.read_text(encoding="utf-8").splitlines():
        if m := re.match(r"### On `([A-Z0-9_]+)`", line):
            event = m.group(1)
        elif m := re.match(r'- \*\*([A-Z]+)\*\* `[A-Z0-9_]+` \([^)]*\): "(.*)"', line):
            out.append(f'{m.group(1)} [{event}]: "{m.group(2)}"')
    return out


def rules(text: str) -> set[str]:
    return {f.rule for f in lint(text)}


def main() -> int:
    bad = 0
    recs = approved_records()
    assert len(recs) >= 30, f"expected the approved lines, got {len(recs)}"
    for r in recs:
        found = lint(r)
        if found:
            bad += 1
            print("FALSE POSITIVE on approved line:", r, "->", [str(f) for f in found])
    cases = [
        ('TED [GAME_STARTED]: "Welcome, apprentice!! So delighted you are here!"', {"V1", "T1"}),
        ('ARTHUR [BURNER_PICKED_UP]: "Got the lamp head from the outpost, hurry, ten minutes left!"', {"V2", "V3", "L1"}),
        ('TED [BOAT_CAST_OFF]: "Mind the rocks."', {"L3"}),
        ('TED [GAME_STARTED]: "The passenger ship is coming."', {"L2"}),
        ('TED [ENGINE_ROOM_ENTERED]: "The burner is broken already."', {"L2"}),
        ('Ted says: "hello"', {"F1"}),
        ('TED [LAMP_ROOM_ENTERED]: "*coughs* Hrmph (looks away)."', {"F2"}),
        ('TED [LAMP_ROOM_ENTERED]: "' + " ".join(["word"] * 30) + '."', {"N1"}),
        ('DANIEL [DANIEL_IN_BASEMENT]: "It is a ghost, I swear."', {"T3"}),
        ('TED [BURNER_DIAGNOSED]: "Forty years that lamp ran."', {"L4"}),
    ]
    for text, want in cases:
        got = rules(text)
        if not want <= got:
            bad += 1
            print("MISSED", want - got, "in", text)
    print("OK" if not bad else f"{bad} problem(s)", f"({len(recs)} approved lines, {len(cases)} violation cases)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
