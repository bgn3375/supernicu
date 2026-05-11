# React-19-Vite-Frontend — Eval Set

## Files

| File | Purpose | Tracked |
|------|---------|---------|
| `evals.json` | **Canonical** Anthropic-schema output-eval set. 20 cases. Each carries `id`, `prompt`, `expected_output`, `expectations[]`. Used by `run_eval.py` (Tier 3 output grader — tests generated code quality). | yes |
| `trigger-evals.json` | Trigger-eval set in `[{query, should_trigger}]` shape consumed by `scripts/run_loop.py` (Tier 2 router optimizer). 20 cases, 10 positive / 10 negative, stratified per Anthropic spec. Curated independently from `evals.json`: output-eval negatives test refusal/nuance (e.g. useActionState ban, compiler-trust), trigger-eval negatives test router discrimination (near-misses like Remix, Vue+Vite, React Native, Next.js). They overlap but are not 1:1 derived. | yes |
| `.runs/<timestamp>/` | Per-run outputs (results.json, report.html, log.txt). | no (gitignored) |
| `optimizer-run.log` | Last optimizer stdout dump. | no (gitignored) |
| `*-progress.log`, `*-results.json` (other than canonical) | Stale debug artifacts. | no (gitignored) |

## Known infrastructure bug — Windows + Python 3.13 — PATCHED

`scripts/run_loop.py` and `scripts/run_eval.py` invoke `claude -p` as a subprocess. On Windows + Python 3.13.x, the original `run_eval.py` uses `select.select()` on the subprocess stdout pipe. Windows `select()` is a Winsock2 wrapper that only accepts socket file descriptors, not pipes, so every call fails with:

```
Warning: query failed: [WinError 10038] An operation was attempted on something that is not a socket
```

Effect (before patch): every `trigger_rate` reads `0/N`. Negative cases trivially "pass"; positive cases trivially "fail". The score was **uninformative**.

**Patched in this repo** via `scripts/patch-skill-creator-windows.py`. The patch swaps the `select.select()` + `os.read()` block for a reader thread + `queue.Queue`, preserving all streaming JSON parsing and early-return logic. Run once after installing or upgrading skill-creator:

```powershell
python scripts/patch-skill-creator-windows.py
# rollback: python scripts/patch-skill-creator-windows.py --restore
```

The patch is idempotent and backs up the original to `run_eval.py.orig` on first apply.

**Additional Windows note**: also pass `--num-workers 1` to the loop — the `ProcessPoolExecutor` default of 10 workers spawns 10 ephemeral skill command files with identical descriptions, which confuses Claude's router and suppresses trigger rate. Serial execution (`--num-workers 1`) gives each query an unambiguous routing context.

With both mitigations in place, treat description tuning as **data-driven** (run the optimizer) rather than principles-only. Principles still apply:

- Lead with concrete user actions (`FIRE for ...`)
- Enumerate trigger phrases (10-20)
- Include explicit anti-triggers (`DO NOT fire for ...`) — disambiguates from sibling skills
- Cover oblique phrasings (`even on "I need a screen that shows X"`)
- Keep under 1024 chars (Anthropic spec)

## Re-running on Windows

Prerequisites: run `python scripts/patch-skill-creator-windows.py` once (see above). PowerShell example:

```powershell
$env:PYTHONUTF8 = "1"
$env:PYTHONPATH = "$HOME/.claude/skills/skill-creator"
python "$HOME/.claude/skills/skill-creator/scripts/run_loop.py" `
  --skill-path ./react-19-vite-frontend `
  --eval-set ./react-19-vite-frontend/evals/trigger-evals.json `
  --model claude-sonnet-4-6 `
  --num-workers 1 --max-iterations 3 --runs-per-query 5 --holdout 0.4 `
  --results-dir ./eval-runs --verbose
```

Flag rationale:
- `--num-workers 1` — serial execution; parallel workers create identical-description ephemeral skills that confuse the router (see note above).
- `--runs-per-query 5` — reduces variance on trigger_rate (3 is too noisy, 7+ is overkill for trigger tests).
- `--holdout 0.4` — matches the 60/40 train/test split in Anthropic's skill-creator guidance.

`PYTHONUTF8=1` is required because SKILL.md contains UTF-8 (em-dashes, arrows) and the default Windows codepage cp1252 chokes on read.

## Re-running output evals (Tier 3)

Same socket bug applies. Once fixed, run:

```bash
PYTHONUTF8=1 PYTHONPATH="$HOME/.claude/skills/skill-creator" \
  python "$HOME/.claude/skills/skill-creator/scripts/run_eval.py" \
  --skill-path ./react-19-vite-frontend \
  --eval-set ./react-19-vite-frontend/evals/evals.json \
  --model claude-sonnet-4-6
```

Output written to `evals/.runs/<timestamp>/`. Open `report.html` for per-eval grader verdicts against the `expectations[]` array.
