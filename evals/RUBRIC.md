# Eval scoring rubric (per task)

Copy this block once per eval case you run. Fill in pass (Y) / fail (N) for each
assertion under both the **with-skill** and **baseline** runs, then compute the
delta. An `anti_behaviors` row scores **Y** when the bad thing is **absent**
(i.e. Y is always the good outcome). One anti-behavior present = the run fails the
case regardless of the expected-behavior tally.

---

## Case: `<eval id>`

- **Skill expected to fire:** `<flutter:xxx / dart:xxx>`
- **Skill actually fired (with-skill run)?** ☐ yes ☐ no
- **Query:** `<paste the query>`
- **Scratch project / commit:** `<path or git sha>`
- **Date / tester:** `<...>`

### Expected behaviors (Y = present)

| # | Assertion | With-skill | Baseline | Delta |
|---|-----------|:----------:|:--------:|:-----:|
| 1 |           |            |          |       |
| 2 |           |            |          |       |
| 3 |           |            |          |       |
| 4 |           |            |          |       |

### Anti-behaviors (Y = absent / good)

| # | Must NOT appear | With-skill | Baseline | Delta |
|---|-----------------|:----------:|:--------:|:-----:|
| 1 |                 |            |          |       |
| 2 |                 |            |          |       |
| 3 |                 |            |          |       |

### `run-checks.sh` result

| Check | With-skill | Baseline |
|-------|:----------:|:--------:|
| `flutter analyze` clean | | |
| `dart format` clean | | |
| `flutter test` pass | | |
| anti-pattern scan FAIL count | | |

### Case verdict

- With-skill pass-count: `__ / __`
- Baseline pass-count: `__ / __`
- **Delta (with − baseline):** `__`
- Any anti-behavior present (auto-fail)? with-skill ☐ · baseline ☐
- **Skill helped on this case?** ☐ yes ☐ no ☐ no-signal (baseline already passed all)

---

## Overall summary (all cases)

| Eval id | With-skill pass-rate | Baseline pass-rate | Delta | Skill helped? |
|---------|:--------------------:|:------------------:|:-----:|:-------------:|
|         |                      |                    |       |               |

- **Total cases:** `__`
- **Mean with-skill pass-rate:** `__%`
- **Mean baseline pass-rate:** `__%`
- **Aggregate delta:** `__ pp`
- **Cases with no signal (baseline passed all):** `__`  → tighten or replace these.
- **Notes / actions:** `<which SKILL.md to fix, which evals to harden>`
