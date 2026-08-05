# Commit messages and PR descriptions (family-wide)

Every family repo squash-merges, so **the PR title and body *are* the commit message**. GitHub
copies them verbatim into permanent history and appends ` (#NNN)` to the subject. A PR description
is therefore not a place to think out loud — it is the message someone reads in three years while
bisecting, with none of the surrounding conversation in view.

The working detail still matters, and it has a home: **post it as the first comment on the PR.**
That comment is permanent too, and the `(#NNN)` in the squashed subject links straight to it. So
keeping detail out of the commit loses nothing — it relocates it to where it is already reachable,
and where a reader who wants it will actually be looking.

## Shape

- **Subject** — imperative, sentence case, no full stop, **≤50 characters as typed**. GitHub adds
  ` (#NNN)`; the hard ceiling including that tail is 72. Don't put the issue number in the title —
  double tails like `(#571) (#574)` are what pushed subjects past 100 characters. Put `Closes #571`
  in the body instead.
- **Body** — **≤10 lines / ~100 words**, wrapped at 72. Hard ceiling 20 lines. Two short paragraphs
  at most: why the change was needed, then what changed in observable behaviour.
- **Trailers** — `Closes #NNN`, then a single `Co-authored-by:` in that casing.
- **Type prefixes** — `docs:` / `ci:` / `chore:` are welcome for changes with no behavioural
  effect, and only for those. Substantive changes get a plain imperative subject. (`logpile` and
  `overstorey` already work this way; no repo needs to change to match.)

An `[area]` title prefix is an **issue** convention ([`issue-guide.md`](issue-guide.md)), not a PR
one — the board's `Repository` field and the diff already say where a PR lands, so on a PR the
prefix only spends characters the subject doesn't have.

## What goes where

| In the commit — durable | In the first PR comment — transient |
|---|---|
| What changed in observable behaviour | What you tried first, and in what order |
| Why it was needed | Hypotheses that turned out wrong, and self-corrections |
| What breaks, and how to migrate | Alternatives considered and rejected |
| One line of magnitude if results moved, with a pointer | Benchmark tables, sweep grids, profiling output |
| `Closes #NNN` | Test counts, pass/fail totals, new test filenames |
| | Per-file changelogs — that is `git diff --stat` |
| | Branch, stack, and rebase bookkeeping |
| | Replies to review comments |
| | Caveats and remaining work — **file issues instead** |
| | Unchecked `- [ ]` checklists |

**The test: would this sentence help someone reading `git log` in three years?** If it only makes
sense relative to the PR conversation — "now targets `develop` directly", "reverses what I wrote
yesterday", "worth reviewer attention" — it belongs in the comment.

Two consequences worth stating plainly, because both have been done the other way here:

- **A results-moving change still has to state its blast radius**, but one line does it: the
  magnitude and where the breakdown lives (*"moves 240 golden cells; split by cause in #15"*). The
  full table goes in the comment.
- **Never write a commit whose purpose is to correct an earlier commit message.** Two exist in
  `phylloptim` and they document nothing a reader of the code can use. Correct the record on the
  issue or the PR, where it is a reply rather than a permanent artefact.

## A worked pair

Both real, both from `plant` `develop`. This is `3adeba84` — 5 lines, and complete:

```
ci: skip R-CMD-check and benchmarks on docs-only (**.md) pushes

Add paths-ignore: ['**.md'] to the push trigger so documentation-only
changes (README, CLAUDE.md, etc.) don't trigger the compile/test jobs.
PR triggers are left intact so checks still gate merges.
```

Against it, `ac844ce4` — 147 lines, 1204 words, five `##` sections. It carries a hypothesis it
disproves (*"the hypothesised `soil_moist_residual` / ψ-clamp leak **does not exist**"*), a
suite count (*"2540 passing, zero failures"*), a list of new test filenames, a ~250-word
`## What this does *not* fix` describing a bug that a later PR fixed, and a knife-edge sweep grid
(*"fails at θ₀ = 0.005–0.03 but not 0.001 or ≥ 0.05"*). Every one of those was worth writing down
somewhere; none of it is worth carrying in `git log` forever, and the sweep grid in particular is
now misleading, because the case it describes is fixed.

## Why this is written down

Measured on `plant` `develop`, 2026-08-05 — the last 40 commits against the 40 before 2026:

| | subject median | body lines median | body words median | body words max |
|---|---|---|---|---|
| Jun–Jul 2026 | 68.5 | 34.5 | 171 | 1204 |
| pre-2026 | 38 | 2 | 17 | 155 |

Roughly ten times the words. The split is entirely between squash merges (median 40 body lines)
and hand-typed commits (median 1), which is what identifies this as a PR-description habit rather
than a commit-writing one — and what makes it fixable by moving text one box down the page.

## Mechanics

One repo setting and one habit make this the path of least resistance:

- **Squash defaults** — a repo must be set to use the PR title and body, or GitHub builds the commit
  message from the individual commit subjects instead and the description never reaches history at
  all. **All ten family repos are already set correctly** (checked 2026-08-05); verify with
  `gh api repos/traitecoevo/<repo> --jq '{squash_merge_commit_title, squash_merge_commit_message}'`,
  which should return `PR_TITLE` and `PR_BODY`.
- **`.github/PULL_REQUEST_TEMPLATE.md`** — keep it minimal. A PR body is copied into the commit
  *including HTML comments*, so a commented-out questionnaire ends up in history; the template
  should hold only the parts that belong in a commit.
- **Post the comment when you open the PR**, not at merge time. Written after the fact it becomes
  a summary; written as you go it is the thing you would otherwise have padded the description
  with.

The `---------` line above the `Co-authored-by:` block in older commits is **not** a symptom of any
of this — it is GitHub's own separator, added automatically when it aggregates co-author trailers
from the commits being squashed. Nothing to fix.

---

**Added 2026-08-05.** Prompted by the measurement above. See [`triage.md`](triage.md) for the rest
of the PR discipline and [`issue-guide.md`](issue-guide.md) for issue titles and labels.
