# FAL spend

_Started 2 Nov 2026 from the FAL dashboard export (`fal-ai-usage-2026-10-03T00_00_00Z-2026-11-02T08_05_25Z.csv`, copied here as [fal_usage_2026-10-03_to_2026-11-02.csv](fal_usage_2026-10-03_to_2026-11-02.csv) with the API key and account columns removed). One API key (LightingTheStorm_API_Key) made every charge. There were no discounts and no surge pricing._

## Total

**$33.90** across 14 daily line items, 12 Oct – 1 Nov 2026. Nothing was charged on 2 Nov up to 08:05 UTC, when the export was taken.

**Paid in: $40.00. Balance: $6.10** on 2 Nov morning; **$1.60** after the evening run below. (creator, 2 Nov 2026, from the FAL dashboard). $40.00 − $33.90 = $6.10, so the usage export and the balance agree to the cent: every dollar paid in is accounted for, and nothing was spent outside this export.

| Model | Spend | Share |
|---|---:|---:|
| `hunyuan3d-v3/text-to-3d` | $18.375 | 54% |
| `hunyuan3d-v3/image-to-3d` | $14.325 | 42% |
| `hunyuan3d/v2/multi-view` | $0.64 | 2% |
| `meshy/rigging` | $0.32 | 1% |
| `nano-banana-2/edit` (image edit) | $0.16 | <1% |
| `ideogram/v2` (image) | $0.08 | <1% |
| **Total** | **$33.90** | |

Hunyuan3D v3 bills $0.015 per unit. A text-to-3d model is 25 units ($0.375). Image-to-3d jobs vary in units, so count them from the result files, not from the bill.

## Day by day, matched to the work

| Date | Model | Amount | Units | What it paid for (from git history and memory) |
|---|---|---:|---|---|
| 12 Oct | nano-banana-2/edit | $0.08 | 1 image | Concept image edit (to be confirmed) |
| 15 Oct | hunyuan3d-v3/image-to-3d | $7.275 | 485 units | Craggy island and harbour (46318b0), Saint Calder city (87650aa), other first models — **biggest single day; needs a per-model breakdown** |
| 15 Oct | hunyuan3d/v2/multi-view | $0.64 | 4 generations | Older v2 multi-view trials |
| 15 Oct | nano-banana-2/edit | $0.08 | 1 image | Concept image edit (to be confirmed) |
| 16 Oct | hunyuan3d-v3/image-to-3d | $0.525 | 35 units | Stone dock and two-boat bay (ec3a510) |
| 19 Oct | hunyuan3d-v3/image-to-3d | $1.575 | 105 units | To be matched (likely the boiler, steam engine, arc lamp and burners committed 22 Oct, b2302c3) |
| 22 Oct | hunyuan3d-v3/text-to-3d | $1.875 | 125 units (5 models) | Lighthouse interior props: poster, shovel and others (b2302c3) |
| 22 Oct | ideogram/v2 | $0.08 | 1 image | Poster artwork (to be confirmed) |
| 24 Oct | hunyuan3d-v3/text-to-3d | $5.25 | 350 units (14 models) | Lighthouse Finisher, first batch (ledger: 14 props) |
| 26 Oct | hunyuan3d-v3/image-to-3d | $1.575 | 105 units | Island gate and passenger ship (a260c66) |
| 26 Oct | hunyuan3d-v3/text-to-3d | $0.375 | 25 units (1 model) | Same session, one text model |
| 31 Oct | hunyuan3d-v3/image-to-3d | $3.375 | 225 units | Character regeneration: Ted, Arthur, Daniel meshes (8dc00ea, cc054d3) |
| 31 Oct | meshy/rigging | $0.32 | 0.4 generations | Character rigging attempt on FAL (the 24-bone rig; the final rigs were done on Meshy web) |
| 1 Nov | hunyuan3d-v3/text-to-3d | $10.875 | 725 units (29 models) | T45 props (P1 + P2 + backlog), T42 buoys, T43 chair, T49 hut: 27 generated + 2 re-rolls (fca8f2e) |

By week: 12–18 Oct $8.60; 19–25 Oct $8.78; 26 Oct – 1 Nov $16.52.

## After the export (2 Nov 2026 evening)

| Date | Model | Amount | Units | What it paid for |
|---|---|---:|---|---|
| 2 Nov | hunyuan3d-v3/text-to-3d | $4.50 | 300 units (12 models) | T69 greybox props pass 2, ranks 1-12: pressure gauge, coal bin front, wall grille, valve wheel, burner cloth, fire hose coil, barograph, water can, rope coil, ledger book, pot shelf, wall shelf with books (creator approved; ledger updated) |

Total spent to date **$38.40**; balance **$1.60** (to confirm on the dashboard). The lighthouse pages and posters cost nothing on FAL: the creator made them with ChatGPT.

## Against the repo's own record

- `GERFramework/reports/lighthouse_finisher_fal_ledger.json` records **$16.125** (24 Oct $5.25 + 1 Nov $10.875). Both match the dashboard to the cent.
- The other **$17.775** (52%) has no cost record in the repo. Those runs left `*.fal_result.json` files (about 42) without a charge field.

## Open questions

1. ~~**Balance now.**~~ Closed 2 Nov: **$6.10** left (creator). The $10.875 prop batch did come after the $16.98 reading on 1 Nov.
2. ~~**Top-ups.**~~ Closed 2 Nov: **$40.00** paid in (creator). Paid in − spent = $40.00 − $33.90 = $6.10, the balance. Reconciled.
3. **The 15 Oct batch ($7.275, 485 units)** needs a per-model breakdown from the fal_result files and the git history.
4. **The image edits and the ideogram image** (12, 15 and 22 Oct, $0.24 total): confirm what they were and whether they ended up in the game.
5. **Meshy web** (lampposts, characters) was paid for outside FAL, so it is not in this CSV. Audit it separately.

## Next steps

- [ ] Before any new FAL generation: the balance is $6.10, about 16 text-to-3d models at $0.375. Larger batches need a top-up (the creator decides FAL spend).

- [ ] One ledger for every FAL generation (`Game Audit/fal_ledger.json`), seeded from this CSV, which every generation script appends to from now on.
- [ ] Match each `*.fal_result.json` to a dashboard day.
- [ ] Add a cost column to the asset licence/credits list (needed for itch.io, T53).
