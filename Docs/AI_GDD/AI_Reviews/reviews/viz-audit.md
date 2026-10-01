# Visualization Audit: review-viz.html (Round 5, Phase 3)

Sources checked: `review-viz.html`, `reviews/viz-data.json`, `reviews/viz-spec.md`, the six reviewer files, and `reviews/SYNTHESIS.md`.

Method: I read the HTML source in full and traced the rendering logic by hand. I did not open the page in a browser, so the layout findings (U3, U5, U8) are predictions from the CSS and SVG geometry and should be checked on screen.

**Builder claims, checked:**
- **"The full JSON is embedded as `const DATA`": confirmed.** The embedded block (HTML lines 495-1222) is line-for-line the same length as the JSON (729 lines, offset 494). Spot checks at the start, the BA findings, the engagement block, the top-issue flags, the counts and the end all match exactly.
- **Masthead numbers: correct.** It computes 30 findings, BLOCKING 8 (5 in Round 1) and 5 disagreements from the arrays.
- **Section insight numbers: correct.** "BLOCKING 5→8, MINOR 6→3, 6 upgraded, 0 downgraded", "21 conflicts and 33 connections", and "Issues #1 and #5 reached by all six" all match the data and the review files.
- **Network in-degrees: correct.** I recomputed them from the item arrays: PP 15, SD 14, QA 12, NC 10, FL 9, BA 7, total 67 = 24 conflict + 43 connection items. The insight line ("Player Psychologist (15) and Systems Designer (14)") is right. The spec had *guessed* QA and PP would be the hubs; the data says otherwise, and the page follows the data.
- **Partial withdrawals shown as 3, not 4: the page is correct.** viz-spec §9 explicitly says PP F2 withdrew a *fix*, not part of the finding, and should count as a revised recommendation. So 3 sub-point withdrawals (SD F1, NC F4, BA F3) plus 4 revised recommendations is right. The mismatch is in the JSON's precomputed `counts.withdrawals_partial` (4). The builder logs a console warning but shows nothing on the page (see U10).
- **Top-5 links and network edges derived by the builder: checked, sound with one exception.** The `parseRefs` / `flagInfo` matching resolves every reference correctly (for example BA "Round 2 X2" → BA-X2, and PP "Ted is the onboarding" → PP-X5). Where the synthesis says only "Round 2 connection" (FL at #2 and #5, QA and NC at #5), the page honestly says the item isn't named instead of guessing. The exception is the narrative-critic "F4 (4.2)" sub-point reference: see A1.
- I checked every conflict, connection and revision item in the JSON against the Round 2 section of each review file. Counts, targets and change types all match: SD 3/6/5, NC 3/6/6, PP 4/6/5, FL 4/6/4, QA 4/5/4, BA 3/4/4.

---

## 1. Accuracy errors

### A1. Narrative-critic is shown as rating Issue #1 BLOCKING and placed on a side of Disagreement A. The source gives no rating and no side. **MUST-FIX**
- **What the source says:** SYNTHESIS #1 credits "narrative-critic (#4.2)" with **no severity**. The JSON matches: `severity_given: null` for that flag. NC's Round 2 upgrade of F4 to BLOCKING is justified by the ship never being introduced (PP F4) and the fail state often not being showable (QA F1). It is not about the retry/checkpoint trap. Disagreement A's BLOCKING side is systems-designer, adversarial-qa and player-psychologist only.
- **What the HTML shows:**
  - The V2 matrix, row #1, narrative-critic column, shows a red **BLOCKING** stamp with "F4 (4.2)" and "was MAJOR".
  - The clash line under row #1 reads, in effect, "Clash: see A · BLOCKING: SD, NC, PP, QA vs MAJOR: FL". That puts NC on the BLOCKING side of Disagreement A.
  - The V1 card #1 trail row for NC shows `MAJOR → BLOCKING` with the whole F4 finding. This is less wrong, because it is F4's real rating history, but it reads as NC rating Issue #1 BLOCKING.
- **Cause:** `flagInfo` treats any reference starting with "F<n>" as a full Round 1 finding, and the cell uses that finding's post-Round-2 severity.
- **Fix:** When `severity_given` is null and the reference names a sub-point (for example "(4.2)"), render the cell as an unrated reference (a muted "sub-point" label, no stamp) and leave it out of `sevCells`. The clash line would then read "BLOCKING: SD, PP, QA vs MAJOR: FL", which matches SYNTHESIS and viz-spec §9.

### A2. The masthead says "Reviewed 30 September 2026", but no source gives a review date. **SHOULD-FIX**
- **What the JSON says:** `meta.review_date` is `null`, with a note that no review file states a date.
- **What the HTML does:** hardcodes `REVIEW_DATE = '30 September 2026'` (the Round 5 run date) and labels it "Reviewed …" in both the masthead and the footer.
- **Fix:** Relabel it "Report generated 30 September 2026", or drop it and keep only "document compiled 29 September 2026".

### A3. Disagreement D's "Also noted" line refers to a "side A" the page never shows. **SHOULD-FIX**
- The JSON's `other_positions` is rendered verbatim as "Also noted: narrative-critic partly agrees with side A." The page labels the columns "Position 1" and "Position 2", so "side A" means nothing to a reader. It is also easy to confuse with *Disagreement* A.
- The same fact already appears inside Position 1's text ("narrative-critic partly agrees: …"), so the line is also a duplicate.
- **Fix:** Drop the line, or rewrite it as "narrative-critic partly agrees with Position 1".

### A4. Minor fidelity nits (NICE-TO-FIX)
- **V2 cell for PP, row #5 ("F2 and F3"):** clicking it opens only F2. The tooltip does list both.
- **Masthead BLOCKING count (8):** it includes BA F3, which the reviewer scoped to "the full-production decision only". This follows the spec, but the masthead gives no hint. A "1 scoped" note in the sub-line would stop someone concluding the prototype has 8 blockers.

No findings are missing, duplicated or invented. Titles, reviewer attributions, severities (Round 1 and after Round 2), cross-examination outcomes (#1, #2, #3, #5 STRENGTHENED; #4 SURVIVED), the flagged-by lists, the quick wins, the verdict and all five disagreement positions match SYNTHESIS.md and the review files. The split severity on #4 (BLOCKING NC / MAJOR BA · FL · QA) is shown correctly.

---

## 2. Usability issues

### U1. The theme follows the OS, so a laptop in light mode puts a light page on the classroom projector. **MUST-FIX**
- **The problem:** `data-theme="auto"` plus `prefers-color-scheme: light` switches the whole page to a light palette unless someone finds the "Theme: auto" link and clicks it twice.
- **Why it matters:** CLAUDE.md and viz-spec §0 define a dark-only palette, chosen for a projector. In light mode the stamp *text* turns black for every severity, leaving a 1px coloured border as the only severity cue. The MAJOR amber border (#F5A623) on white is about 1.9:1 contrast and will vanish on a projector. The page's signature element stops working.
- **Fix:** Default `mode` to `'dark'`. Keeping the toggle as an opt-in is fine.

### U2. Chart and supporting text is below the 18px minimum; some labels will be unreadable from the back of the room. **SHOULD-FIX**
- **The spec:** viz-spec §0 sets 18px minimum for body text and chart labels, and 24px or more for chart numerals.
- **The severity flow SVG:** it is drawn at 600px wide but lives in a column about 445px wide, so it is scaled to about 0.74. Its 16px labels render at about 12px (band labels, BLOCKING/MAJOR/MINOR words, column heads). The 32px numerals render at about 24px, which just passes.
- **Other small text:** per-reviewer bar labels, the axis and the "R1/R2" labels are 13px. Matrix "F1" refs and "was MAJOR" are 13px. Stamps are 14px, and 13px in tooltips.
- **Findings text itself:** the expanded "Fix proposed" and "Source passage" rows and the "Engaged by colleagues" list are 16px; trail text and Round 2 lists are 17px.
- **Fix:** Draw the flow SVG at its display width (or give V4 a stacked full-width layout) and raise every label to 18px or more.

### U3. The network's detail panel sits below a 620px-tall SVG, and hover details vanish as you move toward them. **SHOULD-FIX**
- **Placement:** the spec puts the panel to the right of the SVG on desktop. Here it is underneath. On a 1080p screen or projector with the sticky nav, you cannot see the upper edges and the panel at the same time.
- **Hover content disappears:** on `mouseleave` the SVG clears `HOVER`, so moving the pointer down to read or click the panel resets it to placeholder text. The details only stay if you click to pin.
- **Duplicated text:** edge tooltips repeat the same text as the panel.
- **Fix options:** put the panel beside the SVG, or shrink the SVG, or drop hover-driven panel content and keep hover for tooltips only (click pins).

### U4. The "solid chip = Round 1 finding" legend is contradicted by chips elsewhere. **SHOULD-FIX**
- The legend above V1 defines solid = Round 1 finding and dashed = joined in cross-examination.
- Quick-win and disagreement chips are always drawn solid. For example, business-analyst is credited on Quick win 1 through a Round 2 connection (X2), not a Round 1 finding.
- **Fix:** Scope the legend to the Top 5 cards only, or use a neutral chip style outside V1.

### U5. The masthead is cramped: the stats take about 620px and leave about 370px for title, verdict and "single change". **SHOULD-FIX** (verify on screen)
- **Why:** with `grid-template-columns: 1fr auto`, three stat blocks at about 206px each leave the text column about 370px wide.
- **Result:** a 60px title wraps to 3-4 lines, the 24px verdict to about 5 lines, and the "single change" paragraph to about 8 lines. The first projector screen would be almost all masthead, with the verdict squeezed.
- **Fix:** Put the stats in a row under the title, or cap them at about 40% of the width.

### U6. Disagreement C's 2×2 grid reads as two pairings. **NICE-TO-FIX**
- The "Position 1-4" grid (PP+SD | FL / QA | BA) has no "vs" divider, so it reads as "1 vs 2" and "3 vs 4". FL and QA are really both on the "no" side, and BA is "defer".
- Generic "Position N" labels throughout V3 also drop the stance.
- **Fix:** Label the positions by stance, for example "Yes", "No (prototype)", "No (exploitable)", "Defer".

### U7. Network edge filter leaves the node numerals unchanged. **NICE-TO-FIX**
- With "Conflicts only" selected, circle sizes and numerals still show combined conflict and connection in-degree.

### U8. Curved-edge geometry is a visual risk. **NICE-TO-FIX** (verify on screen)
- Control points are offset 40px for conflicts and 92px for connections, much more than the spec's 18px. On a hexagon whose sides are 205px, connection curves between neighbouring nodes will bulge outward toward the node labels. Many opposite-node edges cross the centre.
- Check for edges crossing name labels.

### U9. Minor interaction and state glitches. **NICE-TO-FIX**
- **Sticky hover:** hovering a node and then moving onto blank SVG space leaves that node's highlight on until the pointer leaves the whole SVG.
- **Pinned edge vs hover:** with an edge pinned, hovering a node highlights the node's edges while the panel still shows the pinned edge.
- **Selection bar can be wrong:** `openFinding` from another reviewer's cell clears the board filter but keeps the global selection. The bar then says "Showing: Systems Designer" over an unfiltered board.
- **Dead tab stops:** the 36 per-reviewer bar segments are `tabindex=0` but do nothing except show a tooltip.
- **Filter bar scrolls away:** the spec asks for a sticky filter bar in the Full Board. It isn't sticky, so it scrolls out of view in long lists.
- **Silent side effect:** clicking any reviewer chip anywhere also re-filters the Full Board. This is intended, but the only sign is the selection bar.

### U10. The withdrawal-count mismatch is flagged only in the console. **NICE-TO-FIX**
- The page's 3 is correct per the spec (see the builder checks above), but a presenter comparing it with the JSON will see 4.
- **Fix:** Add a one-line footnote under the flow chart: "PP F2 withdrew a preferred fix; counted under recommendations revised."

**What works well:** severity is the only colour, and stamps and chips follow the spec. The top-5 cards, the coverage matrix (apart from A1), the disagreement panels and the Full Board filters, sort, search and URL hash all behave as their labels say. Keyboard support, Esc-to-clear, reduced motion and the hidden table equivalents are all present. The empty-state line for disagreements is implemented.

---

## 3. Verdict

**Needs another pass before it goes on the projector. The fixes are small.**

- **Accuracy:** 3 errors (A1-A3) plus minor nits (A4). A1 is **MUST-FIX**: the coverage matrix and clash line credit narrative-critic with a BLOCKING rating and a side in Disagreement A that the synthesis doesn't give.
- **Usability:** 10 issues. U1 (light theme by default) is **MUST-FIX** for the classroom use. U2-U5 are SHOULD-FIX. U6-U10 are NICE-TO-FIX.
- **MUST-FIX total: 2** (A1, U1). Both are small code changes: skip unrated sub-point references when building severity cells, and default the theme to dark.

Per the user's instruction, no rebuild was started.
