# plant-meta

Cross-package organisational knowledge, dependency map, and governance for the **plant family** of
repositories in the [`traitecoevo`](https://github.com/traitecoevo) org.

This repo holds the knowledge that doesn't belong to any single package because it spans them: what
each repo is, which package is the source of truth for what, which artifacts cross repo boundaries,
and the shared label/triage conventions.

## What's here

| File | Purpose |
|------|---------|
| [`AGENTS.md`](AGENTS.md) | **Start here.** Authoritative cross-package orientation (the family, dependency direction, source-of-truth rules, gotchas). |
| [`.claude/CLAUDE.md`](.claude/CLAUDE.md) | Defers to `AGENTS.md` (kept in sync by reference, not duplication). |
| [`dependencies.yml`](dependencies.yml) | Machine-readable package graph + cross-boundary artifacts. |
| [`governance/labels.yml`](governance/labels.yml) | Family label taxonomy — single source of truth. |
| [`governance/apply-labels.sh`](governance/apply-labels.sh) | Idempotent sync of labels to family repos (**gated**; hard-coded repo list). |
| [`governance/project-board.md`](governance/project-board.md) | Structure & conventions of family board [#5](https://github.com/orgs/traitecoevo/projects/5); labels-vs-board-fields division of labour. |
| [`governance/auto-add-to-board.md`](governance/auto-add-to-board.md) | How new issues from all repos auto-add to board #5 (workflow + token secret). |
| [`governance/issue-guide.md`](governance/issue-guide.md) | Contributor guide: how to file & label issues across the family (repos point here). |
| [`governance/release-playbooks.md`](governance/release-playbooks.md) | Cross-repo change sequences (e.g. "plant interface change → migrate regnans"). |
| [`governance/triage.md`](governance/triage.md) | Contribution + triage discipline; open scope questions. |
| [`governance/commit-messages.md`](governance/commit-messages.md) | Squash merge makes the PR title + body the permanent commit message — what belongs there, and what belongs in a PR comment instead. |
| [`governance/model-robustness.md`](governance/model-robustness.md) | What a model should represent (zero growth, shutdown) vs. refuse (physically unrealistic states); what a failure message must contain. |

## Scope

The **plant family only** — a subset of the `traitecoevo` org. Nothing here applies org-wide or to
other families (e.g. the AusTraits trait-data stack, which has its own `austraits-meta`). Model-core
repos: `plant`, `odelia`, `regnans`, `logpile`, `phytofile`, and this repo. See `AGENTS.md`
for the full list.

This convention is deliberately aligned with [`austraits-meta`](https://github.com/traitecoevo/austraits-meta)
so the two families stay consistent as the org grows. The work-type core (`bug`/`task`/`epic`) is
identical across both.

## Maintainers

Maintained by the plant-model team (lead: Daniel Falster, `daniel.falster@unsw.edu.au`).

## ⚠️ Drift caveat

This repo is **hand-maintained prose, not generated from the code**. It is a map, not ground truth.
Before relying on a specific path, function, artifact version, or dependency edge, verify it in the
relevant repo — the packages move faster than this documentation. Found drift? Fix it here in the same
change.
