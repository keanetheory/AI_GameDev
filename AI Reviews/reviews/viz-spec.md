# Visualization Spec: Interactive Review Board (Round 5)

Target file: `review-viz.html` (project root). Single self-contained file, vanilla JS, inline CSS and SVG. No libraries, no external assets.

Source of truth: `reviews/viz-data.json` for all rendered values. This spec was written alongside the data-extractor, before the JSON existed. So:
- Field names below are the **expected** names. If the extractor used different names for the same meaning, map them. Do not invent or restructure data to fit this spec.
- The **Verification counts** (Section 9) come from a hand-read of the review files. They are checks for the builder and the auditor, not data to hardcode. If the JSON disagrees with them, render the JSON and flag the mismatch in a builder note.

---

## 0. Global design rules (apply to every visualization)

These carry over from the project's Round 4 design system (CLAUDE.md) so both reports read as one family and work on a classroom projector.

- **Palette.** Background #16181D. Panels #1F232B. Text #E8E6E1. Muted text #8A8F98. Hairlines #2A2F38.
- **Only severity gets color.** BLOCKING #E5484D, MAJOR #F5A623, MINOR #5A6270. Everything else is monochrome. Reviewer identity, edge type and cross-exam outcome use **line style, weight, opacity and labels, never hue.**
- **Severity stamps.** Small caps, letterspaced, with a 1px solid border in the severity color and a transparent fill. Use them everywhere severity appears as text, including in tooltips.
- **Type.** Condensed grotesque display face ("Arial Narrow", "Helvetica Neue Condensed", sans-serif-condensed fallback) for headings, numerals and axis labels. System UI stack for body text. Minimum 18px for body text and chart labels. Chart numerals 24px or larger.
- **Shapes.** No border radius above 4px, no shadows, no gradients, no icons, no emoji.
- **Motion.** At most one fade-up per section on load, disabled under `prefers-reduced-motion`. Hover and selection changes are instant: an opacity or outline change with no easing.
- **Layout.** Single column, max-width 1100px, at least 64px between sections.
- **Interaction.** Every interaction must also work by keyboard: Tab/Enter/Space, and Esc to clear. Every chart has a visually hidden `<table>` equivalent, or a visible "Show as table" toggle where specified.
- **Shared selection state.** One global `selectedReviewer` (or null). Clicking a reviewer name or chip anywhere sets it. All six visualizations then dim non-matching elements to 25% opacity. A persistent "Showing: <reviewer> [Clear]" bar sits under the sticky nav while a reviewer is selected. Esc clears it.
- **Fidelity.** Show finding text verbatim from the JSON, trimmed with an ellipsis only where a size limit is stated below. Never paraphrase.

---

## Page layout (top to bottom)

| # | Section | Visualization | Approx. height |
|---|---------|---------------|----------------|
| - | Masthead + stat strip | (not a viz; 3 stat blocks) | 320px |
| - | Sticky nav | links to sections below and the reviewer-selection bar | 56px |
| 1 | Top 5 Issues | **V1 Drill-down cards** | 5 x ~220px collapsed |
| 2 | Who Flagged What | **V2 Issue coverage matrix** | ~420px |
| 3 | The Disagreements | **V3 Position panels (A-E)** | ~5 x 260px |
| 4 | How Severity Moved | **V4 Severity flow + per-reviewer breakdown** | ~520px |
| 5 | Cross-examination | **V5 Engagement network** | ~620px |
| 6 | Full Board | **V6 Findings explorer** (filterable table) | variable |
| - | Footer | method note + source line | - |

Masthead stats read from the JSON: total Round 1 findings, BLOCKING count after Round 2, and number of unresolved disagreements. Label the BLOCKING stat "BLOCKING (after cross-exam)" so it isn't confused with the Round 1 count.

---

## V1. Top 5 Issues: expandable drill-down cards (centerpiece)

**Insight.** What the board thinks matters most, and the evidence trail behind each item.

**Pattern.** Five full-width stacked cards, ranked 1-5. Collapsed by default, one click to expand. More than one card can be open at once.

**Data read.** `synthesis.top_issues[]`, each with:
- `rank`, `title` (one-line problem), `severity` (may be a split string, e.g. issue #4 is "BLOCKING (narrative-critic) / MAJOR (others)")
- `problem` (full paragraph)
- `flagged_by[]`: `{reviewer, ref, severity?, via}`, where `via` is "round1" or "round2-connection"
- `cross_exam_outcome`: SURVIVED | STRENGTHENED | WEAKENED
- `cross_exam_notes` (paragraph)
- `related_disagreements[]`: disagreement ids (A-E)
- Links to underlying findings: `finding_ids[]` pointing into `findings[]`. If the extractor didn't provide these, match on `flagged_by.reviewer` + `ref`.

**Collapsed card (~220px).**
- Left: the rank numeral at ~90px, condensed face, muted color at about 25% opacity.
- Right, top row: severity stamp(s). For a split severity like issue #4, render two stamps (BLOCKING and MAJOR) with small reviewer labels under each, so the split is visible without expanding. Next comes the outcome tag, a monochrome outline stamp reading STRENGTHENED, SURVIVED or WEAKENED (no color).
- Problem title at 28px.
- Reviewer chips, outlined and monochrome. A chip with a **solid** outline means a Round 1 finding. A **dashed** outline means the reviewer joined in Round 2 (connection). Put a one-line legend above the first card: "solid = Round 1 finding · dashed = joined in cross-examination".
- Right edge: "Show trail" text button.

**Expanded card.** Three stacked blocks separated by hairlines. No nested boxes.
1. **The problem.** The full `problem` paragraph.
2. **The trail.** One row per `flagged_by` entry: reviewer name, their finding ref (e.g. "F1"), severity stamp as rated in Round 1, then an arrow and the Round 2 severity if it changed (e.g. `MAJOR -> BLOCKING`), and the first ~200 characters of that finding's text with a "read full finding" link. The link scrolls to that row in V6 and opens it. Round 2-connection rows show the connection text instead of a severity.
3. **Cross-examination.** The `cross_exam_notes` paragraph, plus "See Disagreement A" style links for each `related_disagreements` id. The links scroll to V3 and briefly outline that panel for 1.5s (a static outline if reduced motion is on).

**Interactions.**
- Click a card header or press Enter to toggle expand. `aria-expanded` reflects the state.
- Hovering a chip shows a tooltip: "<reviewer> · <ref> · <severity or 'Round 2 connection'>".
- Clicking a chip sets the global `selectedReviewer`.
- An "Expand all / Collapse all" control sits above the cards.

---

## V2. Issue coverage matrix (reviewer agreement)

**Insight.** Consensus is broad. Issues #1 and #5 were reached by all six reviewers, which is the multi-agent argument in one grid. It also shows where reviewers agreed on the problem but clashed on severity. Those clashes lead into V3.

**Pattern.** A grid with 5 rows (Top 5 issues, labelled "#1" plus a short title of up to 40 characters) and 6 columns (reviewers, in the fixed order systems-designer, narrative-critic, player-psychologist, feasibility-lead, adversarial-qa, business-analyst). A right-hand "reach" column shows "6/6", "5/6" and so on in the display face.

**Data read.** `synthesis.top_issues[].flagged_by[]` (reviewer, ref, severity, via) and `synthesis.disagreements[]` (to find severity clashes).

**Cell encoding (monochrome except severity).**
- **Round 1 finding.** A severity stamp showing the reviewer's rating after Round 2 (e.g. "BLOCKING"), with the finding ref in small muted text under it ("F1"). If the rating changed in Round 2, show a small muted "was MAJOR" line.
- **Round 2 connection only.** A dashed outline cell with the text "R2 link".
- **Not flagged.** An empty cell with a centered muted dot.
- **Severity clash marker.** If reviewers in the same row rated the issue at different severities *and* the synthesis records a disagreement about it (row #1 goes to Disagreement A, row #4 to Disagreement E), draw a 2px #E8E6E1 bracket under the row and label it "Clash: see A" or "Clash: see E". Rows #1 and #4 are the expected cases, but derive this from the data.

**Interactions.**
- Hovering a cell shows a tooltip with the finding title and the first ~160 characters of its text.
- Clicking a cell opens that finding in V6 (scroll to it and expand).
- Clicking a column header sets `selectedReviewer`.
- Clicking a row label scrolls to the matching V1 card and expands it.
- Clicking a clash bracket scrolls to the matching V3 panel.

**Size.** Full width. Cells about 140 x 64px. Readable at projector distance.

**Accessibility.** The grid is a real `<table>` with `<th scope>`, so no separate table view is needed.

---

## V3. The Disagreements: position-vs-position panels

**Insight.** The five decisions the board could not settle, who sits on which side, and the exact question being escalated.

**Pattern.** One panel per disagreement (A-E), stacked. Each panel has:
- A header: the letter in the display face at ~48px in muted color, plus the disagreement title.
- **Position columns.** Two columns for two-sided disputes (A, B, D, E). Disagreement C has four positions: shortcut yes (player-psychologist, systems-designer), no in prototype (feasibility-lead), no because it's exploitable (adversarial-qa), and defer (business-analyst). Render C as a 2 x 2 grid. Never merge distinct positions to force two columns. Each column has reviewer chip(s) at the top, then the argument summary verbatim from the synthesis. Columns are separated by a vertical hairline with a small "vs" in the display face.
- A **"Common ground"** line (only for A, where the data supplies it).
- An **"Escalated decision"** line at the bottom, full width at 22px in primary text, prefixed with the label "DECISION NEEDED" in small letterspaced muted caps.

**Data read.** `synthesis.disagreements[]`: `{id, title, positions[]: {reviewers[], summary}, common_ground?, escalated_decision}`.

**Interactions.**
- Clicking a reviewer chip sets `selectedReviewer`. Non-matching position columns dim, which makes it easy to trace one reviewer's stance across all five disputes.
- Each position column has a "source" link that opens that reviewer's Round 2 section in V6.
- **Empty state.** If `disagreements` is empty, show a single line: "The board reached consensus — rerun Round 2 if that seems too easy."

**No chart here.** The content is argument text, and a chart would add nothing.

---

## V4. How severity moved: Round 1 to after cross-examination

**Insight.** Cross-examination made the review harsher, not softer. BLOCKING went from 5 to 8 and MINOR from 6 to 3, and no whole finding was withdrawn, only sub-points. The per-reviewer breakdown shows who moved.

**Pattern.** One section with two linked views side by side on desktop, stacked below 900px.

**V4a. Aggregate flow (left, ~45% width, ~440px tall).** A two-column flow diagram drawn in hand-built SVG.
- Left column: Round 1 severity bars (BLOCKING, MAJOR, MINOR) stacked vertically, with height proportional to count and a count label at 24px or larger.
- Right column: severity after Round 2, same ordering.
- Bands connect left to right for each transition that exists in the data (expected: B->B, M->B, M->M, Mi->M, Mi->Mi). Band fill takes the **destination** severity color at 35% opacity. Unchanged bands are 20% opacity, so the changes stand out.
- Beneath the chart, a muted line: "Partial withdrawals (sub-points, finding kept): N" plus "Recommendations revised: N". Both are clickable and filter V6 to those rows.

**V4b. Per-reviewer breakdown (right, ~55% width).** Six rows, one per reviewer. Each row holds two thin horizontal stacked bars (16px tall, 4px gap): "R1" above and "R2" below. Segments are BLOCKING, MAJOR and MINOR in severity colors, with segment width equal to count. Put a count numeral inside a segment if it's at least 28px wide, otherwise above it. Reviewer name sits at left at 18px.
- A shared x-axis scale (0-5 findings), since every reviewer has 5 Round 1 findings.

**Data read.** `findings[]`: `{id, reviewer, number, title, severity_r1, severity_r2, r2_change: "upgraded"|"downgraded"|"unchanged"|"withdrawn"|"partially_withdrawn"|"revised_recommendation", r2_rationale}`. Compute counts client-side from `findings[]`. Don't trust a precomputed summary if one disagrees with the array; use the array and log a console warning.

**Interactions.**
- Hovering a band shows a tooltip listing the findings in it ("MINOR -> MAJOR: systems-designer F5, feasibility-lead F5, business-analyst F5").
- Clicking a band filters V6 to those findings and scrolls there.
- Hovering a V4b segment shows a tooltip with the finding titles in that segment.
- Clicking a V4b reviewer name sets `selectedReviewer`. V4a then redraws bands for that reviewer only, with a "(filtered: <reviewer>)" caption.

**Conditional upgrades.** adversarial-qa F5 ("frozen-ship bullet: MINOR to MAJOR *if* Player Psychologist #4 is adopted") and business-analyst F3 ("BLOCKING, for the full-production decision only") are qualified upgrades.
- BA F3 counts as BLOCKING (the reviewer states the upgrade), with a small "scoped" marker in the tooltip.
- QA F5 stays MINOR (the upgrade is conditional and covers one bullet only), with a "conditional upgrade" note in the tooltip and in V6.
- If the JSON encodes these differently, follow the JSON and mention it in the builder note.

---

## V5. Cross-examination network

**Insight.** This is the multi-agent payoff. Every reviewer engaged with several colleagues. It shows who argued with whom (conflicts) versus who built on whom (connections), and which reviewers were the most-engaged "hubs". Expected: adversarial-qa and player-psychologist are the most-cited targets.

**Pattern.** A node-link diagram with **fixed positions**. The six nodes sit on a regular hexagon in the same reviewer order as V2, clockwise from the top. No force simulation, no animation. The SVG is about 620 x 560, centered.

- **Nodes.** Circles with a 1.5px #E8E6E1 outline and a #1F232B fill. Radius scales with total engagements received (min 28px, max 48px). The reviewer's name is outside the circle at 18px. Show the in-degree numeral inside the circle at 22px.
- **Edges.** Directed, from the reviewer writing Round 2 to the colleague whose finding they engaged. One edge per (source, target, type) pair, with stroke width 1.5 + 1.5 x count (capped at 7px).
  - **Conflict** = solid line. **Connection** = dashed line (6 3). Both #E8E6E1 at 55% opacity. No hue.
  - A small arrowhead at the target end. If A->B and B->A both exist, curve each edge slightly (quadratic offset of 18px) so they don't overlap.
- **Legend** above the chart: "solid = conflict (argued against) · dashed = connection (combined findings) · line weight = number of engagements · circle size = times engaged by others".
- **Toggle** (two text buttons): "All · Conflicts only · Connections only".

**Data read.** `cross_exam.edges[]`: `{from, to, type: "conflict"|"connection", source_ref, target_ref, summary}`. If the extractor stored engagements per reviewer instead (e.g. `reviewers[].round2.conflicts[]` with a target field), flatten them into this shape client-side. When one Round 2 item cites several colleagues (e.g. feasibility-lead's "Systems Designer #1 and Adversarial QA #2"), create one edge per cited colleague.

**Interactions.**
- **Hover a node.** Its incident edges go to 100% opacity and all others to 10%. A side panel (right of the SVG on desktop, below it on narrow screens, 320px wide) lists "<reviewer> engaged: N conflicts, N connections · was engaged by: N".
- **Click a node.** Sets `selectedReviewer`, same highlight, and it persists.
- **Hover an edge.** A tooltip shows "<from> -> <to> · CONFLICT/CONNECTION · <source_ref> on <target_ref>" plus the first ~180 characters of `summary`.
- **Click an edge.** Pins that edge's full `summary` in the side panel, with a "open in Full Board" link to the Round 2 section in V6.
- **"Show as table" toggle.** Replaces the SVG with a 6 x 6 matrix (rows = from, columns = to). Each cell reads "2 C · 1 L" (conflicts · connections), with empty cells as a muted dot. This is also the accessible fallback.

**Why the network and not a matrix only.** With six nodes the fixed hexagon stays readable and makes the density of cross-talk visible at a glance, which a table of counts does not. The matrix is still available through the toggle for exact numbers.

---

## V6. Full Board: findings explorer (filterable, sortable)

**Insight.** The complete drill-down. Every finding from every reviewer, with its Round 2 fate. This is where every other viz sends clicks.

**Pattern.** A filter bar, then a table-like list of rows separated by hairlines, with no boxes. Each row expands in place.

**Filter bar** (sticky within the section, one line on desktop):
- **Reviewer.** Six toggle chips plus "All". Multi-select. Kept in sync with `selectedReviewer`: selecting one chip sets it, and selecting several clears the global state but filters locally.
- **Severity.** BLOCKING / MAJOR / MINOR stamp toggles, multi-select.
- **Severity basis.** "Round 1 rating" versus "After cross-exam". Default: after cross-exam.
- **Round 2 change.** All · Upgraded · Downgraded · Unchanged · Partly withdrawn · Recommendation revised.
- **In Top 5.** A checkbox: "Only findings cited in Top 5".
- **Text search.** Matches title and body, debounced 150ms.
- A live result count, "Showing 12 of 30", plus a "Reset filters" link.

**Row (collapsed, one line, about 64px):** severity stamp (current basis), then the change indicator in muted text (e.g. `MINOR -> MAJOR`, or "sub-point withdrawn"), then the reviewer name, the finding number, the title at 20px, and on the right any Top 5 badges ("#1", "#5") as monochrome outline chips.

**Row (expanded):** the full finding text (problem, source, needed/fix), then a hairline, then a "Round 2" block with the reviewer's revision rationale for this finding, then "Engaged by colleagues", which lists incoming V5 edges that target this finding (from + type + summary snippet).

**Per-reviewer Round 2 sections.** Below the list, a collapsible "Round 2 cross-examination: <reviewer>" block for each reviewer, holding their full Conflicts / Connections / Revisions text. V3 and V5 "source" links scroll here.

**Sort** (a dropdown): Severity (default: BLOCKING first, then by reviewer order), Reviewer, Most engaged (the incoming edge count from V5), Biggest change (upgrades first).

**Data read.** `findings[]` (all fields above plus `body` or its equivalent), `reviewers[].round2` text, `cross_exam.edges[]` for the incoming counts, and `synthesis.top_issues[].finding_ids` for the badges.

**Behaviour.**
- The filter state is reflected in the URL hash (e.g. `#board?r=adversarial-qa&s=BLOCKING`) so a presenter can link to a view.
- Links from other visualizations set the filters, clear the search, scroll here, and expand the target row.
- When no rows match: "No findings match these filters." with a Reset link.

---

## 7. Considered and cut

- **Standalone severity donut or pie.** Duplicates V4 and gives a worse reading of change. Cut.
- **Timeline of rounds.** There are only three rounds and no timestamps, so it would be decorative. Cut.
- **Word cloud or theme clustering.** Not traceable to verbatim findings, and it violates the fidelity rule. Cut.
- **Separate "reviewer agreement heatmap" of reviewer x reviewer similarity.** It would need an invented similarity score. V2 (agreement on concrete issues) and V5 (actual engagements) show the same thing from real data. Cut.
- **Quick Wins.** Not a visualization. Render the three quick wins as a short text list at the end of V1's section (verbatim, with reviewer chips), since they are part of the synthesis.

---

## 8. Cross-visualization links (summary)

| From | Action | Goes to |
|------|--------|---------|
| V1 chip / V2 column / V3 chip / V4b name / V5 node / V6 reviewer chip | click | sets global `selectedReviewer` (everything dims to match) |
| V1 trail "read full finding" | click | V6 row, expanded |
| V1 "See Disagreement X" | click | V3 panel X |
| V2 cell | click | V6 row |
| V2 row label | click | V1 card, expanded |
| V2 clash bracket | click | V3 panel |
| V4a band / withdrawal line | click | V6 filtered |
| V5 edge "open in Full Board" / V3 source link | click | V6 Round 2 section for that reviewer |

---

## 9. Verification counts (hand-read from reviews/*.md, for builder and auditor)

These are checks only. Render from the JSON.

**Round 1:** 30 findings (5 per reviewer). BLOCKING 5 (SD F1, NC F1, PP F1, QA F1, QA F2). MAJOR 19. MINOR 6 (every reviewer's F5).

**After Round 2:** BLOCKING 8, MAJOR 19, MINOR 3.
- Upgrades MAJOR -> BLOCKING: NC F4, PP F4, BA F3 (scoped to the full-production decision).
- Upgrades MINOR -> MAJOR: SD F5, FL F5, BA F5.
- Remaining MINOR: NC F5, PP F5, QA F5 (QA F5 has a conditional one-bullet upgrade).
- No downgrades of a whole finding's severity. Softened framing: QA F4 (Ted half softened), BA F3 (agent-process sub-point withdrawn).
- Partial withdrawals (sub-points): SD F1 ("first boarding"), NC F4 ("sails calmly into port"), BA F3 (process-overhead sub-point). PP F2 withdrew its preferred *fix*, not the finding, so it counts as a revised recommendation.

**Top 5 coverage (V2 expected):**

| Issue | SD | NC | PP | FL | QA | BA | Reach |
|---|---|---|---|---|---|---|---|
| #1 retry/checkpoint trap | F1 B | F4.2 | F1 B | F3 M | F2 B | R2 X2 | 6/6 |
| #2 fail can't be shown / read | F3 M | F4 (B after R2) | F1 B | R2 link | F1 B | - | 5/6 |
| #3 ship never introduced | - | F4 (B after R2) | F4 (B after R2) | - | F5 bullet | R2 X4 | 4/6 |
| #4 Ted undecided / vanishes | - | F1 B | R2 link | F3 M | F4 M | F4 M | 5/6 |
| #5 hidden clock punishes wrong players | F2 M | R2 link | F2+F3 M | R2 link | R2 link | R2 X1 | 6/6 |

Severity clashes: #1 (FL MAJOR vs SD/QA/PP BLOCKING, linked to Disagreement A) and #4 (NC BLOCKING vs BA/FL/QA MAJOR, linked to Disagreement E).

**Cross-exam outcomes:** #1, #2, #3 and #5 STRENGTHENED. #4 SURVIVED. None WEAKENED.

**Disagreements:** 5 (A-E). C has four distinct positions.

**Round 2 engagements (approximate, by source reviewer; conflicts / connections).** The exact edge count depends on how the extractor splits multi-target items.
- systems-designer: 3 / 6 (targets QA, FL, NC; PP x3, QA x2, FL)
- narrative-critic: 3 / 6 (targets BA, SD, QA; PP x2, QA, SD, FL, BA)
- player-psychologist: 4 / 6 (targets QA, BA, SD, FL; SD x2, QA x2, NC, FL)
- feasibility-lead: 4 items / 6 items (several cite two colleagues)
- adversarial-qa: 4 / 5 (targets FL, PP x2, NC; SD x2, SD+FL, NC, PP)
- business-analyst: 3 / 4 items (several cite two or three colleagues)

Every reviewer engaged at least four distinct colleagues. If the JSON shows any reviewer with fewer than two distinct targets, treat that as an extraction error.
