# Style Guide GER Agent Group

Enforces the *Lighting the Storm* style guide on generated dialogue with a Generator -> Evaluator -> Refiner loop and no human in it.

| Agent | Claude Code agent | Job |
|---|---|---|
| Style Generator | `.claude/agents/ger-style-generator.md` | Writes the content it is asked for, including off-brand test content |
| Style Evaluator | `.claude/agents/ger-style-evaluator.md` | `SCORE: [X/10]` and `REASON: [...]` against 16 rules in 5 constraint types |
| Style Refiner | `.claude/agents/ger-style-refiner.md` | Rewrites from the REASON until the Evaluator gives 10/10 (max 3 rewrites) |

```bash
python GERFramework/style_guide_group/run_loop.py            # run all cases in cases.json (Claude Code headless, no API key)
python GERFramework/style_guide_group/run_loop.py --backend api --cases ex1_tone
python GERFramework/style_guide_group/style_lint.py draft.txt # deterministic checks only
python GERFramework/style_guide_group/test_style_lint.py      # 40 approved lines must lint clean, violations must be caught
python GERFramework/style_guide_group/build.py                # regenerate STYLE_GUIDE.md and the three agents
python GERFramework/style_guide_group/make_submission.py      # SUBMISSION.md from the latest run
```

`style_guide.json` is the source of truth (rule, weight, source document). `prompts/*.md` are the agent prompts; `build.py` and `run_loop.py` both render them from it, so the Claude Code agents and the script never drift apart. Run output goes to `runs/<timestamp>/` (JSON per case plus `RESULTS.md`). The submission is [SUBMISSION.md](SUBMISSION.md).

The loop calls a model, so it spends tokens (Claude Code headless, or the API with `--backend api`). It is not part of the offline-by-default assessor commands in `GERFramework/README.md`; run it when you want it.
