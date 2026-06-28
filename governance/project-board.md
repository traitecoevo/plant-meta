# Project board #5 — structure & conventions

Documents the **structure and conventions** of the family board, not its live card contents.

- **Board:** Plant model development — https://github.com/orgs/traitecoevo/projects/5
- **Owner:** `traitecoevo` org
- **Scope:** development across the plant modelling stack — the `plant` model and the packages that
  build on it (`odelia`, `regnans`, `logpile`, `phytofile`), its docs/viz (`overstorey`,
  `standviz`), and applications (`floracle`). The mulga project (`mulgafutures`) tracks its
  deliverables on its **own** board and is not managed here.

This is the **single, family-scoped board**. Because it covers exactly one family, labels stay
family-local and there is no cross-family `family:` axis.

## Fields (as configured)

| Field | Type | Notes |
|-------|------|-------|
| Title, Assignees, Repository, Milestone | built-in | — |
| Linked pull requests, Reviewers, Parent issue, Sub-issues progress | built-in | — |
| Start date, Created / Updated / Closed | built-in dates | — |
| **Status** | single-select | options below |
| **Area** | single-select | options below |
| Labels | built-in (mirrors repo labels) | this is where `governance/labels.yml` surfaces |

### Status options
`Backlog`, `In Progress`, `Done`. New issues land with **no Status** = the triage queue.
(There is **no `On-going` option** here — austraits #9 has one; plant can add it if a recurring
"maintenance / always-on" bucket becomes useful. Open question, below.)

### Area options
`dev`, `data` — the cross-cutting cut, mirroring austraits #9's `Area` field (added 2026-06-28).
A pre-existing `interface` option is retained. Saved views **"Dev"** (`Area = dev`) and **"Data"**
(`Area = data`) slice the one board.

### No Priority field (by choice)
Board #5 has **no Priority field** today (unlike austraits #9). That's fine — don't add
`priority:` labels to compensate; if priority tracking is wanted, add it as a board field, not labels.

## Division of labour: labels vs board fields (decided 2026-06-28)

Board single-selects and repo labels are **separate** GitHub primitives — setting a label does NOT
set the board field, and vice versa. Rather than mirror them (which drifts), we split ownership:

| Concern | Owner | Notes |
|---------|-------|-------|
| **Status** (Backlog / In Progress / Done) | **Board Status field** | The single source of truth. No mirrored `status:` labels. |
| **Priority** | **(no field today)** | Add a board field if needed; **no `priority:` labels**. |
| Which **repo** | **Board `Repository` field** | Automatic per item. **No `pkg:` labels** — they just duplicate this and clutter every repo's picker. |
| Which **sub-area within a repo** | **`[prefix]` in the issue title** | Org convention plant already uses (e.g. `[env drivers] ...`). Lightweight; good for modules inside one repo. |
| Kind of work | **`bug` / `task` / `epic` labels** | Shared org-wide core (== austraits). `epic` pairs with the board's native Parent/Sub-issues fields. |
| Triage queue | **no board Status** | A new issue with no Status set *is* the triage queue. No `triage` label. A saved "🔍 Triage" view filters Status = empty. |
| Orthogonal flags | `blocked` / `needs-info` | Bare labels (not `status:`) — they coexist with any board Status. |
| Cross-package impact | `cross-package` / `breaking` | No board column. `cross-package` = ripples beyond this repo; `breaking` = dependents must change. |

### Grouping — `Repository` + `[prefix]` titles (both families)

Both families group the same way, at different granularities:

- **Which repo** → the board's **`Repository`** field (automatic). No `pkg:` labels in either family.
- **Sub-area within a repo** → a **`[prefix]` in the issue title** (`[env drivers] ...`, `[SCM] ...`).
  plant relies on this heavily (much of the work is in the one big `plant` repo); as the family goes
  multi-repo, `Repository` carries the coarse axis and `[prefix]` the finer grain.
- **Cross-cutting cut (dev/data)** → the board **`Area`** field (above).

### Dev vs data — the `Area` field

One board, sliced by an **`Area` single-select field** (`dev` / `data`) — mirroring austraits #9 —
rather than a second board. Most of the split already falls out of `Repository` (the R packages ≈
dev; `mulga_plots_data` / calibration inputs ≈ data); the `Area` field mainly helps when data work
shows up inside a code repo. The field is a board object, not a label.

## Triage workflow (proposed — needs maintainer confirmation)

1. **New issue** → auto-added to board #5 (see [`auto-add-to-board.md`](auto-add-to-board.md)) with
   **no Status** (= triage queue); add a work-type (`bug` / `task` / `epic`) label.
2. **Triaged** → set board **Status = Backlog** (and `Area` if relevant).
3. **Started** → board **Status = In Progress**, assignee set.
4. **Cross-package** → add `cross-package` (+ `breaking` if dependents must change) and link the issues
   in the other affected repos (see `release-playbooks.md`).
5. **Done** → board **Status = Done**, issue closed (comment the resolution rather than labelling it).

## TODOs for maintainers to define

- [ ] Add a saved **"🔍 Triage"** board view (filter: Status is empty).
- [ ] Add saved **"Dev"** / **"Data"** views once the `Area` options are populated on cards.
- [ ] Confirm the triage workflow above (or replace with the real one).
- [ ] Decide whether to add an **`On-going`** Status option (austraits #9 has one).
- [ ] Decide whether plant wants a **Priority** field (austraits #9 has one; plant currently doesn't).
