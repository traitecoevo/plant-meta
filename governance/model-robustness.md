# What a model should represent, and what it should refuse (family-wide)

The principle, for any model in the family (`plant` strategies and environments, `regnans`
assembly, `odelia` numerics):

> **Models should run across a wide range of plant strategies and environmental conditions
> and produce sensible biological outputs — which includes zero growth, zero transpiration,
> zero reproduction, or failure to establish — rather than crash.**
>
> **But where a state is physically unrealistic, the model should fail.** Continuing from an
> impossible state produces output that looks like a result and isn't.

Both halves matter. The first alone invites guards that swallow real breakage; the second
alone makes any harsh environment un-runnable.

## The decision rule

When a model hits an awkward state, ask **"is this state physically attainable?"**

| | Attainable | Not attainable |
|---|---|---|
| **Examples** | zero growth; hydraulic shutdown (no flow, zero transpiration); net production negative; no recruitment; a cohort that never establishes; light fully attenuated | negative mass or leaf area; non-finite ψ, rate, or density; water balance not conserved; density outside [0, ∞); a probability outside [0, 1] |
| **Do** | **represent it.** Return the value the state implies (usually a zero), and make it observable in the outputs | **fail**, naming the quantity, its value, and the constraint it violated |
| **Never** | throw, so that a whole run dies because one plant is in a legitimate state | silently clamp, substitute a fallback, or continue — this is the failure mode that costs the most time |

A third case sits between them: **a numerical method reaching its limits** (an interpolator
that cannot resolve a feature, a root-find that will not bracket, a solver at minimum step).
Fail — but the message must say what was exhausted *and where*, because the cause is usually
somewhere else entirely. A resolution complaint that names no location sends the reader after
the wrong thing.

## Better than either: design the awkward limit out

The strongest version of this principle is applied when choosing the functional form, not when
adding a guard. If a limit is well-behaved by construction there is nothing to represent and
nothing to refuse.

The worked case is `plant`'s density boundary condition, `n = birth_rate · pr_estab / g` at the
introduction size. Taken naively that diverges as growth `g → 0⁺`, and a diverging density
would be a genuinely unrealistic state needing a guard. It doesn't diverge, because
`establishment_probability` was chosen so that it can't: for net production `P > 0` it is

```
pr_estab = 1 / ((a_d0 · A_0 / P)² + 1) · decay(t)
```

which is **quadratic** in `P` as `P → 0⁺`, while `g` is only **linear** in `P`. So
`n = O(P) → 0`: the singularity cancels with a power to spare, and density falls smoothly to
zero as growth does. The `g <= 0` branch returning density exactly zero is then the *continuous
extension* of that limit rather than an arbitrary choice, and "nothing establishes when nothing
can grow" is a sensible biological output rather than a special case.

Worth knowing when reading such a branch: `if (g > 0) ... else 0` can look like a guard bolted
on to dodge a division, when it is the limit of a form deliberately built to have one. Check
before "fixing" it.

## What "fail" has to look like

An error is a diagnosis, not a notification. It should name the quantity, its value, the
location (height, layer, time, cohort), and the constraint violated. "Interpolated function
as refined as currently possible" satisfies none of that; the same failure reported as
*"stalled at x = 15.6202, where the target jumps 0.9786 → 1, and 62 of 93 cohorts there have
zero density"* is a five-minute diagnosis instead of an afternoon.

Corollary: **a guard that returns a plausible number is worse than a crash.** A crash is
found by the next test run; a plausible number is found months later, or not at all. If you
cannot tell which side of the table a state falls on, make it fail and loudly — then relax it
once you know.

## Worked examples

These are the cases that produced this document (`plant`, 2026-07):

- **Hydraulic shutdown → represent.** `Leaf::dprofit_droot_collar_psi` returns a zero
  acclimation gradient when the water-potential gradient reverses (no flow). Physically
  legitimate, already represented elsewhere as zero transpiration, and measured at 0% of
  gradient evaluations in a well-watered run versus 0.55% in a dryland one. Aborting a whole
  dryland site over it would be the first half of the principle violated
  ([plant #570](https://github.com/traitecoevo/plant/pull/570)).
- **A fictitious step in the light profile → fail, with a location.** Refinement failed on a
  discontinuity that only existed because a quadrature grid had lost its ordering. Failing was
  right; failing without saying *where* is what cost the time
  ([plant #571](https://github.com/traitecoevo/plant/issues/571),
  [#573](https://github.com/traitecoevo/plant/pull/573),
  [#574](https://github.com/traitecoevo/plant/pull/574)).
- **A cohort at exactly zero density whose trajectory grows to canopy height → represent, and
  do not mistake it for a defect.** This one is worth spelling out because it reads like a bug
  and isn't. In the method of characteristics a cohort *is* a trajectory, and the density
  transported along it is a separate quantity. A characteristic carrying zero density says
  exactly what it should: a plant that had germinated at that moment would by now be 15 m tall,
  and none did, because the flux into the size distribution was zero when growth was. Both
  halves of that are outputs the model is supposed to produce. The mistake to avoid is reading
  "a 15 m plant with no density" as physically impossible and reaching for the second half of
  the principle: nothing impossible has happened, and `density = 0` in the output *is* the
  disclosure that nothing established.
- **A NaN rate written into the soil state → refuse.** A layer at the residual moisture floor
  gave `psi_soil` ≈ 9.3e7 MPa, the leaf solve returned a non-finite depletion, and the
  positivity guard meant to catch it did not, because `NaN < 0.0` is `false`. A non-finite
  water flux is not a state the soil can be in, so continuing from it can only produce
  nonsense — this is what the second half of the principle is for
  ([plant #549](https://github.com/traitecoevo/plant/issues/549), fixed).
- **A spline evaluated outside its domain → decide which side it is on.** If conductivity
  really is ~0 out there, clamping is a physical statement and the model should continue; if
  not, it should fail. Either way the error must name the spline, the point, and the domain
  ([plant #576](https://github.com/traitecoevo/plant/issues/576)).

## In review

Reasonable questions to ask of a PR that adds or removes a guard:

- Which side of the table is this state on, and how do you know? Beware of classifying a state
  as impossible because the *numbers look odd* — check what the model's representation actually
  means first (the zero-density characteristic above is the cautionary case).
- Could the awkward limit be designed out instead of guarded? And conversely: is the branch you
  are about to "fix" actually the limit of a form built to be well-behaved?
- How often does the branch fire — never in healthy runs, or constantly? Measure it; the answer
  usually settles the argument.
- If it returns a value rather than failing, is the state **observable** in the outputs? A state
  that can only be inferred (e.g. "transpiration happens to be 0") is not disclosed, because
  nobody looks.
- If it fails, does the message name the quantity, the value, and the location?

---

**Added 2026-07-29**, from the review discussion on
[plant #570](https://github.com/traitecoevo/plant/pull/570) — "worried about whether we
essentially get an undisclosed error when the model should really just break" — and the #571
family of dry-corner failures. See [`triage.md`](triage.md) for contribution discipline and
[`../AGENTS.md`](../AGENTS.md) for the architecture rules.
