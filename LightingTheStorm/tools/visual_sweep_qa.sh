#!/usr/bin/env bash
# visual_sweep_qa.sh - QA-06 (Playtest QA), observe only: render every view in tools/visual_views.json with its "env"
# (SHOT_INTERIOR, SHOT_INTRO, SHOT_BOARD, SHOT_ROWBOAT, SHOT_NPC, SHOT_CROSSING, SHOT_SHIP, and SHOT_CAST for the characters)
# through tools/shot_qa.gd, then score them with visual_check.py --no-render and build a contact sheet.
#   bash LightingTheStorm/tools/visual_sweep_qa.sh [name-prefix]      e.g. "qa_" for the QA views only
# Needs the GPU and a display (not headless). Pictures: GERFramework/shots/<name>.png. Report: GERFramework/reports/visual_check.md.
# Contact sheet: GERFramework/reports/playtest_qa_contact_sheet.png.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(cd "$HERE/.." && pwd)"
REPO="$(cd "$PROJ/.." && pwd)"
GODOT="${GODOT:-/c/Users/pmkea/Downloads/Godot_v4.3-stable_win64.exe/Godot_v4.3-stable_win64_console.exe}"
SHOTS="$REPO/GERFramework/shots"; mkdir -p "$SHOTS"
SW="$(cygpath -m "$SHOTS" 2>/dev/null || echo "$SHOTS")"
PREFIX="${1:-}"
FRAMES=${SHOT_FRAMES:-12}

python -I - "$HERE/visual_views.json" "$PREFIX" >"$SHOTS/.sweep_list" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
for v in d["views"]:
    if sys.argv[2] and not v["name"].startswith(sys.argv[2]):
        continue
    env = ";".join(f"{k}={val}" for k, val in (v.get("env") or {}).items())
    args = [*map(str, v["from"]), *map(str, v["to"])]
    if v.get("phase"):
        args += [v["phase"], str(v.get("sea_state", 1))]
    print(v["name"] + "\x1f" + env + "\x1f" + " ".join(args))
EOF

names=()
while IFS=$'\x1f' read -r name env args; do   # a non-blank separator, so an empty env stays an empty field
  names+=("$name")
  rm -f "$SHOTS/${name}_"*.png "$SHOTS/$name.png"
  (
    cd "$PROJ"
    IFS=';' read -ra kv <<<"$env"
    for e in "${kv[@]}"; do [ -n "$e" ] && export "$e"; done
    timeout 150 "$GODOT" --path . --write-movie "$SW/${name}_.png" --fixed-fps 10 --quit-after "$FRAMES" --script res://tools/shot_qa.gd -- $args >/dev/null 2>&1
  )
  last=$(printf "%08d" $((FRAMES - 1)))
  if cp "$SHOTS/${name}_$last.png" "$SHOTS/$name.png" 2>/dev/null; then echo "rendered $name"; else echo "NO PICTURE $name"; fi
  rm -f "$SHOTS/${name}_"*.png "$SHOTS/${name}_.wav"
done <"$SHOTS/.sweep_list"

only="$(IFS=,; echo "${names[*]}")"
(cd "$PROJ" && python -I tools/visual_check.py --no-render --only "$only")
rc=$?

python -I - "$SHOTS" "$REPO/GERFramework/reports/playtest_qa_contact_sheet.png" "${names[@]}" <<'EOF'
import sys
from pathlib import Path
from PIL import Image, ImageDraw
shots, out, names = Path(sys.argv[1]), sys.argv[2], sys.argv[3:]
W, H, cols = 400, 225, 4
rows = (len(names) + cols - 1) // cols
sheet = Image.new("RGB", (cols * W, rows * (H + 18)), (24, 24, 24))
dr = ImageDraw.Draw(sheet)
for i, n in enumerate(names):
    x, y = (i % cols) * W, (i // cols) * (H + 18)
    p = shots / f"{n}.png"
    if p.exists():
        sheet.paste(Image.open(p).convert("RGB").resize((W, H)), (x, y + 18))
    dr.text((x + 4, y + 3), n if p.exists() else n + " (NO PICTURE)", fill=(255, 255, 255))
sheet.save(out)
print("contact sheet:", out)
EOF
exit $rc
