#!/usr/bin/env bash
# run_all_tests.sh - QA-09: run every headless test in LightingTheStorm/tools, time each one, re-run a failure once
# (to tell a flaky test from a real fault), write a summary table, and exit non-zero on any failure.
#
#   bash LightingTheStorm/tools/run_all_tests.sh [-j N] [-o OUT.md] [-k PATTERN]
#     -j N        run N tests at once (default 1; the long playthroughs always run alone at the end)
#     -o OUT.md   summary file (default GERFramework/reports/playtest_qa_suite_table.md)
#     -k PATTERN  only tests whose file name contains PATTERN
#   GODOT=/path/to/Godot_console.exe overrides the Godot binary.
#
# A test passes when its output has "RESULT: OK". No RESULT line (a crash, a script error or the timeout) is a failure.
# test_slice_playthrough.gd runs twice: the win (default) and "-- fail" (S01 and S02 in QA_SCENARIOS.md).
# Observes only: it never edits project files. Logs go to $LOGDIR (default: a temp folder, printed at the end).
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(cd "$HERE/.." && pwd)"
REPO="$(cd "$PROJ/.." && pwd)"
GODOT="${GODOT:-/c/Users/pmkea/Downloads/Godot_v4.3-stable_win64.exe/Godot_v4.3-stable_win64_console.exe}"
JOBS=1
OUT="$REPO/GERFramework/reports/playtest_qa_suite_table.md"
PATTERN=""
TIMEOUT_DEFAULT=600
TIMEOUT_LONG=1500
while getopts "j:o:k:" opt; do
  case $opt in
    j) JOBS="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    k) PATTERN="$OPTARG" ;;
    *) echo "usage: $0 [-j N] [-o OUT.md] [-k PATTERN]"; exit 2 ;;
  esac
done
LOGDIR="${LOGDIR:-$(mktemp -d 2>/dev/null || echo "$REPO/GERFramework/reports/.suite_logs")}"
mkdir -p "$LOGDIR"
[ -x "$GODOT" ] || { echo "Godot not found at $GODOT (set GODOT=...)"; exit 2; }

# name|script|args|timeout
cases=()
long=()
for f in "$PROJ"/tools/test_*.gd; do
  b="$(basename "$f" .gd)"
  [ -n "$PATTERN" ] && [[ "$b" != *"$PATTERN"* ]] && continue
  if [ "$b" = "test_slice_playthrough" ]; then
    long+=("test_slice_playthrough|$b||$TIMEOUT_LONG")
    long+=("test_slice_playthrough -- fail|$b|fail|$TIMEOUT_LONG")
  else
    cases+=("$b|$b||$TIMEOUT_DEFAULT")
  fi
done

run_one() {  # name script args timeout attempt -> writes $LOGDIR/<slug>.<attempt>.log and .res
  local name="$1" script="$2" args="$3" to="$4" att="$5"
  local slug="${name// /_}"; slug="${slug//--/}"
  local log="$LOGDIR/$slug.$att.log" t0 t1 rc status nfail
  t0=$(date +%s)
  if [ -n "$args" ]; then
    (cd "$PROJ" && timeout "$to" "$GODOT" --headless --path . --script "res://tools/$script.gd" -- $args) >"$log" 2>&1
  else
    (cd "$PROJ" && timeout "$to" "$GODOT" --headless --path . --script "res://tools/$script.gd") >"$log" 2>&1
  fi
  rc=$?
  t1=$(date +%s)
  # The tests report in three styles: "RESULT: OK (n failed)", "PASS/FAIL ... ALL PASSED", and the walk reports
  # ("REACHED THE END" / "DID NOT REACH", "DONE"). Any FAIL line, a non-zero exit or a walk that did not arrive is a failure.
  nfail=$(grep -cE "^FAIL|RESULT: FAILED|DID NOT REACH" "$log" || true)
  if [ $rc -eq 124 ]; then status=TIMEOUT
  elif [ "$nfail" -gt 0 ] || [ $rc -ne 0 ]; then status=FAIL
  elif grep -qE "RESULT: OK|ALL PASSED|^PASS|REACHED|^DONE" "$log"; then status=PASS
  elif grep -qE "^SKIP" "$log"; then status=SKIP
  else status=NO_RESULT
  fi
  echo "$status|$((t1 - t0))|$nfail|$rc" >"$LOGDIR/$slug.$att.res"
  echo "  [$status] $name (${att}) $((t1 - t0)) s"
}

run_batch() {  # attempt, then the case list
  local att="$1"; shift
  local running=0
  for c in "$@"; do
    IFS='|' read -r name script args to <<<"$c"
    run_one "$name" "$script" "$args" "$to" "$att" &
    running=$((running + 1))
    if [ "$running" -ge "$JOBS" ]; then wait -n 2>/dev/null || wait; running=$((running - 1)); fi
  done
  wait
}

slugof() { local s="${1// /_}"; echo "${s//--/}"; }
echo "Running ${#cases[@]} tests (+${#long[@]} playthroughs), $JOBS at a time; logs in $LOGDIR"
T_START=$(date +%s)
run_batch 1 "${cases[@]}"
for c in "${long[@]}"; do run_batch 1 "$c"; done

# Re-run every failure once, alone.
all=("${cases[@]}" "${long[@]}")
retry=()
for c in "${all[@]}"; do
  IFS='|' read -r name _ _ _ <<<"$c"
  IFS='|' read -r st _ _ _ <"$LOGDIR/$(slugof "$name").1.res"
  [ "$st" != PASS ] && [ "$st" != SKIP ] && retry+=("$c")
done
if [ ${#retry[@]} -gt 0 ]; then
  echo "Re-running ${#retry[@]} failure(s) once"
  for c in "${retry[@]}"; do run_batch 2 "$c"; done
fi
T_END=$(date +%s)

# Summary
npass=0; nfail=0; nflaky=0; nskip=0
{
  echo "| Test | Run 1 | Run 1 s | Run 2 (re-run of a failure) | Run 2 s | Verdict | FAIL lines |"
  echo "|---|---|---|---|---|---|---|"
  for c in "${all[@]}"; do
    IFS='|' read -r name _ _ _ <<<"$c"
    s="$(slugof "$name")"
    IFS='|' read -r st1 sec1 nf1 _ <"$LOGDIR/$s.1.res"
    st2="-"; sec2="-"; nf2=""
    [ -f "$LOGDIR/$s.2.res" ] && IFS='|' read -r st2 sec2 nf2 _ <"$LOGDIR/$s.2.res"
    if [ "$st1" = PASS ]; then v=pass; npass=$((npass + 1))
    elif [ "$st1" = SKIP ]; then v=skip; nskip=$((nskip + 1))
    elif [ "$st2" = PASS ]; then v=flaky; nflaky=$((nflaky + 1))
    else v=FAIL; nfail=$((nfail + 1))
    fi
    echo "| $name | $st1 | $sec1 | $st2 | $sec2 | $v | ${nf1}${nf2:+ / $nf2} |"
  done
} >"$LOGDIR/table.md"
{
  echo "# Headless suite summary"
  echo
  echo "Run $(date '+%Y-%m-%d %H:%M'), $JOBS at a time, $((T_END - T_START)) s wall clock. Godot: \`$GODOT\`. Logs: \`$LOGDIR\`."
  echo
  echo "**$npass pass, $nskip skipped (the test says why), $nflaky flaky (failed then passed), $nfail fail** of ${#all[@]}."
  echo
  cat "$LOGDIR/table.md"
  echo
  echo "## Output of each failure"
  for c in "${all[@]}"; do
    IFS='|' read -r name _ _ _ <<<"$c"
    s="$(slugof "$name")"
    IFS='|' read -r st1 _ _ _ <"$LOGDIR/$s.1.res"
    { [ "$st1" = PASS ] || [ "$st1" = SKIP ]; } && continue
    for a in 1 2; do
      [ -f "$LOGDIR/$s.$a.log" ] || continue
      echo
      echo "### $name, run $a"
      echo '```'
      grep -E "^FAIL|RESULT:|DID NOT REACH|SCRIPT ERROR|ERROR: .*res://|Parse Error|Invalid " "$LOGDIR/$s.$a.log" | grep -v 'Parameter "m" is null' | head -40
      echo '```'
    done
  done
} >"$OUT"
cat "$LOGDIR/table.md"
echo
echo "$npass pass, $nskip skipped, $nflaky flaky, $nfail fail of ${#all[@]}  ->  $OUT"
[ $((nfail + nflaky)) -eq 0 ]
