# plant family — cross-package orientation

This file is the **single source of truth** for cross-package, organisational knowledge in the
plant family. `CLAUDE.md` defers to this file so the same content serves every agent and tool.

It is authoritative **only for cross-package concerns**. Anything that lives entirely inside one
repo (how a function works, local build quirks) belongs in that repo's own `CLAUDE.md`/`AGENTS.md`,
not here.

> ⚠️ **Drift caveat.** This is hand-maintained prose, not generated from the code. Treat it as a map,
> not as ground truth. Before you rely on a specific file path, function name, artifact version, or
> dependency edge, **verify it in the relevant repo** — the repos move faster than this document.
> If you find drift, fix it here in the same change.

---

## The family (scope)

This document and the governance in `governance/` are scoped to the **plant family**, a subset of
the `traitecoevo` org. The org hosts other, unrelated families (e.g. the AusTraits trait-data stack,
governed by its own [`austraits-meta`](https://github.com/traitecoevo/austraits-meta)) — nothing here
applies to them.

The family is **hub-and-spoke around `plant`**, not a linear pipeline. `plant` is the core model;
everything else either builds on it, calibrates it, caches its runs, visualises it, documents it, or
applies it to a research project.

**Model-core packages** (the focus of this repo):

| Repo | Kind | Owns |
|------|------|------|
| `plant` | R + C++ package | The core **individual-based, size- and trait-structured forest demography model** (FF16 physiology, the SCM solver, patch/metapopulation dynamics, invasion fitness). The hub. |
| `odelia` | R + C++ (header-only) package | A standalone **ODE solver with automatic differentiation** (adaptive RK4-5), spun out of `plant`'s solver. The next-generation `plant` core links against it. |
| `phylloptim` | R + C++ (header-only) package | **Leaf gas exchange, hydraulics and leaf optimality**, extracted from `plant`'s TF24 strategy. FvCB photosynthesis coupled to an explicit soil→root→stem→leaf transport path, with the operating point chosen by profit maximisation. Home for several stomatal optimality models sharing one numerical core (they differ only in λ(state)); optimum Vcmax and optimum leaf lifespan are planned on the same machinery. **Was `leaf` / `leaf_cpp` until 2026-08-05** — `leaf` is taken on CRAN and `leaf_cpp` is not a legal R package name. |
| `regnans` | R package | **Community assembly + trait evolution** on top of `plant` (selection gradients, equilibria, stochastic/fitmax assembly). The fitness/equilibrium machinery was moved here out of `plant`. |
| `logpile` | R package | A **content-addressed cache** for expensive, deterministic `plant` simulations — built for simulation-based calibration. |
| `phytofile` | compendium (private) | **Bayesian/MCMC calibration** of `plant` parameters — infers suitable parameter distributions for the tree model. |
| `plant-meta` | this repo | Cross-package knowledge + governance (labels, board, playbooks). |

**Docs / visualisation:**

| Repo | Kind | Role |
|------|------|------|
| `overstorey` | Quarto site | The **narrative documentation** for `plant` (guides, theory, a version-pinned notebook). The API reference stays on `plant`'s pkgdown site. |
| `standviz` (pkg `trees3D`) | R package | **3D visualisation** of individual trees / stands via `rgl` (openGL). Standalone and largely dormant (circa 2016). |

**Applications / research projects** (in board #5 scope, outside the model core):

| Repo | Kind | Role |
|------|------|------|
| `floracle` | (nascent) | **Forecasting with the `plant` model.** Currently an empty repo; planned forecasting layer. |
| `mulgafutures` | project tracker (private) | ARC Linkage **project-delivery tracker** (mulga carbon-farming forecasts). WP3 calibrates/extends `plant` to mulga stands. Has its **own project board and a bespoke manuscript/work-package label taxonomy** — see the governance note below. |
| `mulga_plots_data` | data (private) | **Field-plot data** for the mulga project; feeds calibration. |

> **Governance scope (decided 2026-06-28):** the shared label taxonomy applies to the model-core,
> docs, and viz repos plus `floracle`. **`mulgafutures` is deliberately excluded** — it is a
> project-coordination repo with its own board and a deliberate bespoke taxonomy (work packages,
> draft stages); imposing the generic set there would be disruptive. `mulga_plots_data` is a private
> data repo applied only if it gains a real issue workflow. There are **no `pkg:` labels** — which
> repo an issue concerns is the board's `Repository` field. Still scoped to the family ONLY (never
> org-wide). `governance/apply-labels.sh` carries the explicit list and groups the project repos
> separately.

---

## How the pieces connect

There are **two graphs**, and they point different ways — the usual source of confusion:

### R-package install / build graph (who depends on whom)

```
odelia ─────────────(LinkingTo, next-gen plant core)────────────►  plant
                                                                     ▲
phylloptim ─────────(LinkingTo, TF24/TF24f leaf physiology)──────────┤
                                                                     │
                                          ┌──────────Depends─────────┤
                                          ▼                          ▼
                                   regnans               logpile  (Imports / Remotes plant)
```

(`phylloptim` itself `LinkingTo`s `odelia` — the dependency runs
`odelia → phylloptim → plant`.)

- **`plant`** is the hub. On the released `master` line it has **no intra-family R dependencies**
  (`LinkingTo: Rcpp, BH`). On the development line the C++ ODE core is being replaced by **`odelia`**
  (the next-generation `plant` `LinkingTo`/`Imports` it). Verify against the branch you're on.
- **`odelia`** is the spun-out ODE solver (originally Rich FitzJohn's solver inside `plant`). It has
  **no intra-family dependencies** — it's a foundational library others link against.
- **`phylloptim`** is the leaf model extracted from `plant`'s TF24 strategy. It `LinkingTo`s
  `odelia`, and the next-generation `plant` `LinkingTo`s it in turn, so it sits *between* the two.
  The coupling into `plant` is funnelled through a single shim header
  (`inst/include/plant/leaf_model.h`) that re-exports `phylloptim::Leaf` as `plant::Leaf`, which is
  what keeps `plant`'s ~17k lines of generated glue from having to move.
- **`regnans`** **Depends** on `plant` and pins a compatible version via
  [`.plant-interface-version`](https://github.com/traitecoevo/regnans) (the
  `plant`↔`regnans` interface — fitness/equilibrium machinery — was recently split out of
  `plant`). This is the most active cross-repo interface today.
- **`logpile`** **Imports**/`Remotes` `plant` (`traitecoevo/plant@develop`) — it caches `plant` runs.
- **`standviz`** and **`overstorey`** don't link `plant` as a build dependency; `overstorey` renders
  documentation against a pinned `plant` version, `standviz` is a standalone visualiser.

### Workflow / data flow (how a calibrated model gets produced and used)

```
   field data ──► mulga_plots_data ─┐
                                    ▼
                              phytofile  ──(MCMC: infers parameter distributions)──►  plant
                                    ▲                                                   │
                                    │                                                   │ simulations
   plant runs cached by logpile ◄──┘                                                    ▼
                                                          regnans · floracle · standviz · overstorey
                                                          (assembly/evolution · forecasts · viz · docs)
```

1. **`phytofile`** runs Bayesian/MCMC inference to find suitable **parameter distributions** for the
   `plant` model ("parameters for the tree model").
2. **`logpile`** caches the expensive, deterministic `plant` simulations that calibration and
   assembly campaigns repeatedly need (content-addressed by input hash, fault-tolerant, resumable).
3. **`plant`** (optionally via **`regnans`**) produces ecological/evolutionary predictions.
4. Those feed **`floracle`** (forecasting), **`standviz`** (3D visualisation), and are documented in
   **`overstorey`**.
5. The **mulga project** (`mulgafutures` WP3) applies this stack to mulga, with `mulga_plots_data`
   supplying the field observations.

The machine-readable version of all of this is in [`dependencies.yml`](dependencies.yml).

---

## Source-of-truth rules

| Concern | Authoritative repo | Everyone else |
|---------|--------------------|---------------|
| The forest model engine (physiology, SCM solver, patch/metapopulation dynamics) | **plant** | consume; don't fork the model |
| The ODE integrator + autodiff core | **odelia** | link against it; don't re-vendor |
| Leaf gas exchange, hydraulics and leaf optimality (λ(state), FvCB, the water-supply path) | **phylloptim** | link against it; `plant`'s copy is deleted, not forked |
| Community assembly / trait evolution machinery (fitness, equilibrium, selection gradients) | **regnans** | call it; it was deliberately moved out of `plant` |
| Calibrated parameter distributions for `plant` | **phytofile** | consume the inferred parameters |
| Per-model **scientific version** (`FF16@v1`, `TF24@v2`, …) | **plant** (`scientific_version` constant → `model_version()`/`model_id()`) | read it; don't hand-type versions |
| The simulation cache format / campaign state | **logpile** | use the pile; don't hand-roll caching |
| Narrative docs / theory | **overstorey** (API reference: `plant` pkgdown) | link, don't duplicate |

---

## Gotchas (the things that bite across boundaries)

- **The `plant` ↔ `regnans` interface is the live fault line.** Fitness/equilibrium code was
  moved out of `plant` into `regnans`, which pins a compatible `plant` via
  `.plant-interface-version`. Breaking changes in `plant`'s SCM / control / fitness API (e.g. the
  `build_schedule` → `run_scm(refine_schedule=TRUE)` consolidation) require a migration in
  `regnans`. See `governance/release-playbooks.md`.
- **`plant` has two living lines.** `master` is the released 2.x; `develop` is where the `odelia`
  migration and API consolidation happen. Always confirm which branch a dependent pins
  (`logpile` → `@develop`; `regnans` → a `develop` post-#459 ref) before reasoning about deps.
- **C++ compilation is part of every change to `plant`/`odelia`/`phylloptim`.** All three build C++
  via Rcpp; a change to `odelia`'s or `phylloptim`'s header-only core can break the next-gen `plant`
  at compile time, not just at runtime.
- **`phylloptim` was called `leaf` (repo `leaf_cpp`) until 2026-08-05.** Old references, issue links
  and `LinkingTo: leaf` in anything not yet updated all mean this package. GitHub redirects the repo
  name, but `LinkingTo: leaf` will silently resolve to the *unrelated CRAN package* of that name, so
  it fails confusingly rather than cleanly.
- **`logpile` caches by input hash, keyed partly on the model's scientific version.** Each `plant`
  model has a `scientific_version` (exposed as `model_id()`, e.g. `FF16@v1`) independent of the
  package `Version`; `logpile` folds it into the fingerprint. So invalidation is deliberate but
  *declarative*: bump the model's `scientific_version` in `plant` when a change alters outputs for
  the same inputs, and affected runs re-run automatically while software-only releases reuse the
  cache. The residual risk is a maintainer who changes behaviour **without** bumping the version —
  a drift-guard test in `plant` catches default-parameter changes, but pure equation changes rely on
  review. See `governance/release-playbooks.md` §3.
- **`mulgafutures` is a tracker, not a package.** It coordinates a funded project and has its own
  board + bespoke labels. Don't apply the family label taxonomy to it or treat it as model code.
- **`floracle` is empty today.** Treat references to it as forward-looking until it has commits.

---

## When you change something — ripple checklist

- **Changing `plant`'s public R API / SCM / fitness interface** → migrate `regnans` (bump
  `.plant-interface-version`); check `logpile` campaigns and `overstorey` notebook posts pinned to the
  affected version. Treat as `breaking` if dependents must change.
- **Changing `odelia`'s solver/headers** → recompile and test the next-gen `plant` core (LinkingTo),
  and `phylloptim`, which links `odelia` too.
- **Changing `phylloptim`'s headers or model** → recompile and test `plant`'s TF24/TF24f strategies
  (LinkingTo, via the `plant/leaf_model.h` shim), and re-check `phylloptim`'s golden file before
  assuming a numerical change is benign.
- **Changing `plant` simulation semantics** → bump the model's `scientific_version` in `plant` (same
  commit); `logpile` re-derives it and reruns affected campaigns automatically. No bump = silently
  stale caches.
- **Re-calibrating in `phytofile`** → new parameter distributions; update downstream `plant` runs that
  consume them.
- **Cutting a new `plant` release** → update version pins/badges in `overstorey`, `regnans`'s
  interface file, and any `logpile`/`floracle` campaigns.

See `governance/release-playbooks.md` for the step-by-step versions of these.

---

## Governance (in this repo)

- [`dependencies.yml`](dependencies.yml) — machine-readable package graph + cross-boundary artifacts.
- [`governance/labels.yml`](governance/labels.yml) — the family label taxonomy (single source of truth).
- [`governance/apply-labels.sh`](governance/apply-labels.sh) — idempotent sync of labels to the family
  repos. **Gated**: hard-coded repo list, run only with maintainer go-ahead.
- [`governance/project-board.md`](governance/project-board.md) — structure/conventions of family board
  [#5](https://github.com/orgs/traitecoevo/projects/5); labels-vs-board-fields division of labour.
- [`governance/auto-add-to-board.md`](governance/auto-add-to-board.md) — auto-add new issues to board #5.
- [`governance/issue-guide.md`](governance/issue-guide.md) — contributor guide for filing/labelling issues.
- [`governance/release-playbooks.md`](governance/release-playbooks.md) — cross-repo change sequences.
- [`governance/triage.md`](governance/triage.md) — contribution + triage discipline, plus open scope
  questions for maintainers.
- [`governance/commit-messages.md`](governance/commit-messages.md) — the PR title and body become the
  commit message under squash merge; what belongs there and what belongs in a PR comment instead.
- [`governance/model-robustness.md`](governance/model-robustness.md) — what a model should represent
  (zero growth, hydraulic shutdown) vs. refuse (physically unrealistic states), and what a failure
  message has to contain.
