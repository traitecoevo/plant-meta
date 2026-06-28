# Triage & contribution discipline (family-wide)

Uniform conventions across the plant family so an issue/PR behaves the same in any family repo.
The label taxonomy lives in [`labels.yml`](labels.yml); board conventions in
[`project-board.md`](project-board.md).

## Labelling discipline

Every issue should end triage with:

- **work-type** — `bug` / `task` / `epic` (the shared org-wide core; same names as the AusTraits
  family).
- **Which repo** is the board's `Repository` field (automatic) — there are **no `pkg:` labels**. For a
  sub-area within a repo, prefix the title `[area]` (e.g. `[SCM] ...`, `[env drivers] ...`). See
  `project-board.md`.
- **Board Status** — set on the board card, **not** as a label. The board owns it; there are no
  `status:` labels. A new issue with **no Status** *is* the triage queue — there is no `triage` label
  (see [`project-board.md`](project-board.md) → "Division of labour"). Board #5 has no Priority field.
- **`blocked` / `needs-info`** — orthogonal flags that can apply at any board Status.

Add cross-package signals whenever work spans repos:

- **`cross-package`** — has consequences beyond this repo: coordinated changes/rebuilds across
  packages (see `release-playbooks.md`).
- **`breaking`** — a breaking change with downstream impact (often paired with `cross-package`; e.g. a
  `plant` interface change that forces a `regnans` migration).

`question` is the one community label.

## New issue → done (the short version)

1. New issue lands → auto-added to board #5 with **no Status** (= the triage queue); add a work-type
   (`bug`/`task`/`epic`).
2. Triaged → set board **Status = Backlog** (and `Area` if relevant).
3. Started → board **Status = In Progress**.
4. Cross-package? → add `cross-package` (and `breaking` if it breaks dependents) and **link the partner
   issues in the other repos**. Use the relevant playbook in `release-playbooks.md`.
5. Done → board **Status = Done**, close (comment the resolution rather than labelling it).

## PR discipline (family-wide)

- All work goes through a **feature branch + PR**; never commit to a repo's default branch.
- Default branches vary across the family — confirm before branching:
  `plant` → `develop`, `odelia` → `master`, `regnans` → `master`, `logpile` → `main`,
  `phytofile` → `master`, `overstorey` → `master`, `standviz` → `master`, `plant-meta` → `main`.
- R packages: PRs must pass `R CMD check` / testthat (see each repo's `.github/workflows/`).
  `plant` and `odelia` compile C++ — a green check means it built, not just that R code parsed.
- For cross-package changes, link the PRs to each other and to the tracking issue, and label
  `cross-package` (+ `breaking` if dependents must change). The `plant` ↔ `regnans` interface
  (`.plant-interface-version`) is the one to watch.

## Source-of-truth reminders (don't fight the architecture)

- The forest model engine → **plant**. Don't fork the model downstream.
- The ODE integrator + autodiff → **odelia**. Link against it; don't re-vendor.
- Assembly / evolution machinery → **regnans** (moved out of `plant` deliberately).
- Calibrated parameters → **phytofile**. The simulation cache → **logpile**.
- See [`../AGENTS.md`](../AGENTS.md) for the full rules and gotchas.

---

## Scope decisions

**Decided 2026-06-28 — governance covers the model-core, docs, and viz repos plus `floracle`.** The
label taxonomy applies to: model core (`plant`, `odelia`, `regnans`, `logpile`, `phytofile`,
`plant-meta`), docs/viz (`overstorey`, `standviz`), and `floracle`. Each is listed explicitly in
`apply-labels.sh`. Still family-scoped — never org-wide.

**`mulgafutures` is excluded.** It is a project-delivery tracker with its **own board** and a
deliberate, bespoke taxonomy (work packages WP1/WP2/WP3, draft stages, `at-risk`, `dans-eyes`, …).
Imposing the generic family set would be disruptive. `mulga_plots_data` (private data repo) is
excluded until it gains a real issue workflow. Revisit if either adopts board #5.

### Resolved

- **No `pkg:` labels** (2026-06-28). "Which repo" = the board's `Repository` field; sub-area =
  `[prefix]` title; cross-package impact = `cross-package`/`breaking`.
- **Community labels trimmed** — dropped `good first issue` / `help wanted` / `duplicate` / `invalid` /
  `wontfix` / `documentation` (comment on close instead). No `triage` label (no-Status = triage queue).
- **Core recoloured** — `bug`/`task`/`epic` converged onto the shared palette (red/blue/purple); the
  old plant colours had `task` and `epic` both blue.

### Open

- `On-going` Status option on board #5? (austraits #9 has one.)
- A Priority field on board #5? (austraits #9 has one; plant currently doesn't.)
