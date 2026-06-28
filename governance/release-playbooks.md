# Release & cross-repo change playbooks

Cross-package change sequences for the plant family. The family is **hub-and-spoke around `plant`**,
so most ripples start there. See [`../AGENTS.md`](../AGENTS.md) and [`../dependencies.yml`](../dependencies.yml)
for the graph.

> ⚠️ These are templates, not verified runbooks. Confirm exact commands/scripts in each repo before
> executing. **TODO (maintainer):** replace bracketed steps with the real commands.

---

## 1. `plant` interface change → migrate `regnans`

**The `plant` ↔ `regnans` interface is the live fault line.** The fitness/equilibrium machinery
was moved out of `plant` into `regnans`, which pins a compatible `plant` via
`.plant-interface-version`. A change to `plant`'s SCM / control / fitness API is a **breaking change**
for `regnans`. Default to treating it as breaking.

1. **plant** — make the change on `develop`; note the public-API delta (e.g. the
   `build_schedule` → `run_scm(refine_schedule=TRUE)` / `scm_base_control()` → `control()`
   consolidation).
2. **regnans** — migrate call sites; update `.plant-interface-version` with the new `plant`
   ref and the `applied_breaking_changes` list. Run its test suite against the installed `plant`.
3. Check **`logpile`** campaigns and **`overstorey`** notebook posts pinned to the affected `plant`
   version still build / reproduce.
4. Cut the affected issues with `cross-package` + `breaking`; link across repos.

---

## 2. `odelia` solver/header change → recompile the next-gen `plant` core

1. **odelia** — make the change; if a header signature or the autodiff path changed, this affects
   anything that `LinkingTo` it.
2. Run odelia's own tests / `R CMD check` (it compiles C++).
3. **plant** (next-gen / `develop`, which links `odelia`) — recompile and run tests; a header change
   can break `plant` at **compile time**, not just runtime.
4. Label `cross-package` (the header-only solver is a cross-boundary artifact).

---

## 3. `plant` simulation-semantics change → invalidate `logpile` caches

1. **plant** — if a change alters simulation **outputs for the same inputs** (a behavioural change,
   not a pure refactor), the `logpile` content-address (SHA-256 of inputs) will NOT notice it.
2. **logpile** — invalidate or namespace the affected piles deliberately (e.g. bump a model/version
   token in the request) so stale results aren't reused.
3. Re-run affected calibration/assembly campaigns.

---

## 4. Re-calibration (`phytofile`) → updated parameters for `plant`

1. **phytofile** — re-run the MCMC inference (stateline / remake pipeline) over the field/literature
   inputs (incl. `mulga_plots_data` for the mulga project).
2. Produce the updated **parameter distributions** for the `plant` model.
3. Update downstream `plant` runs / `floracle` forecasts that consume them; note the parameter
   version.

---

## 5. Cutting a new `plant` release → update pins downstream

1. **plant** — finalise on `master`, bump version + `NEWS.md`, tag the release.
2. **regnans** — bump `.plant-interface-version` to the released ref if it should track it.
3. **overstorey** — update the pinned `plant` version + version badges for released-line posts.
4. **logpile** / **floracle** — update any pinned `traitecoevo/plant@…` refs.

---

## Quick ripple reference

| You changed… | Must rebuild/check… |
|--------------|----------------------|
| `plant` SCM/control/fitness API | migrate `regnans` (+ `.plant-interface-version`); `logpile`/`overstorey` pins (breaking) |
| `odelia` solver/headers | recompile next-gen `plant` core (LinkingTo) |
| `plant` simulation semantics | invalidate `logpile` caches for same inputs |
| `phytofile` calibration | downstream `plant` runs / `floracle` forecasts consuming the parameters |
| `plant` release/version | version pins/badges in `regnans`, `overstorey`, `logpile`, `floracle` |
