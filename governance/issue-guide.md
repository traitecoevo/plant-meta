# Filing & labelling issues — plant family

A short contributor guide for issues across the plant family (`plant`, `odelia`, `plant.assembly`,
`logpile`, `phytofile`, `overstorey`, `standviz`, `floracle`). The family is tracked on one board,
[#5](https://github.com/orgs/traitecoevo/projects/5); new issues are **auto-added** to it.

## Where to file

File in the repo the issue is *about*. Unsure which? File in the most likely one — maintainers
re-home it. For cross-package work, file in the primary repo and link the others. See
[`../AGENTS.md`](../AGENTS.md) for who owns what (`plant` = the model engine, `odelia` = the ODE
solver, `plant.assembly` = assembly/evolution, `phytofile` = calibration, `logpile` = the simulation
cache).

## Title

Write a specific, action-oriented title. For a sub-area within a repo, **prefix with `[area]`** —
the org convention — e.g. `[SCM] solver fails on degenerate patch`, `[env drivers] add seasonal
light`. (Which repo the issue is about is the board's `Repository` field — there are no `pkg:` labels.)

## Labels (what to add)

Pick **one work-type**, plus context:

| Label | Use it for |
|-------|------------|
| `bug` | Existing feature not functioning as intended |
| `task` | A discrete piece of work toward a feature |
| `epic` | A new feature/capability spanning multiple tasks (use the board's sub-issues to break it down) |

Then add, as relevant:
- **`cross-package`** — if the change has consequences beyond this repo (e.g. a `plant` interface
  change that forces a `plant.assembly` migration). Add **`breaking`** too if dependents must change.
  See [`release-playbooks.md`](release-playbooks.md).
- **`blocked` / `needs-info`** — if it's waiting on a dependency or on more information.
- **`question`** — if it's a question rather than a work item.

**Status is set on the board, not as a label** — leave it to triage. A new issue starts with **no
Status** (the triage queue). Board #5 has no Priority field. See [`project-board.md`](project-board.md).

## What happens next

1. Your issue auto-adds to board #5 with no Status (the triage queue).
2. A maintainer triages: confirms the work-type, sets board **Status = Backlog** (and `Area`).
3. Cross-package issues get `cross-package` (+ `breaking`) and are linked to partner issues in the
   other repos.

## For maintainers
Full triage discipline is in [`triage.md`](triage.md); the taxonomy is [`labels.yml`](labels.yml).
