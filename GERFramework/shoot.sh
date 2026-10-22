#!/bin/bash
# Render one still of the real level (needs a GPU window, so not --headless) and save it as shots/<name>.png
# usage: shoot.sh name x y z tx ty tz [phase ISLAND|OUTBOUND|RETURN|BEACON_RELIT] [sea_state 0-5]
# Set SHOT_DIR to save somewhere else and GODOT to your Godot 4.3 console exe.
HERE="$(cd "$(dirname "$0")" && pwd)"
SP="${SHOT_DIR:-$HERE/shots}"; mkdir -p "$SP"; SPW="$(cygpath -m "$SP" 2>/dev/null || echo "$SP")"
GODOT="${GODOT:-/c/Users/pmkea/Downloads/Godot_v4.3-stable_win64.exe/Godot_v4.3-stable_win64_console.exe}"
cd "$HERE/../LightingTheStorm"
rm -f "$SP/$1_"*.png
timeout 110 "$GODOT" --path . --write-movie "$SPW/$1_.png" --fixed-fps 10 --quit-after ${SHOT_FRAMES:-12} --script res://tools/shot.gd -- $2 $3 $4 $5 $6 $7 $8 $9 >/dev/null 2>&1
LAST=$(printf "%08d" $(( ${SHOT_FRAMES:-12} - 1 )))
cp "$SP/$1_$LAST.png" "$SP/$1.png" 2>/dev/null && rm -f "$SP/$1_"*.png "$SP/$1_.wav"; ls "$SP/$1.png"
