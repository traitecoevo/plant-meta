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
| **Examples** | zero growth; hydraulic shutdown (no flow, zero transpiration); net production negative; no recruitment; a cohort that never establishes; light fully attenuated | negative mass or leaf area; non-finite ψ, rate, or density; soil water potential above zero (a negative suction, where a model stores ψ as a suction, as TF24 does); negative transpiration, in a model that assumes E ≥ 0; water balance not conserved; density outside [0, ∞); a probability outside [0, 1] |
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

## A ladder of remedies

When a system is hard to integrate or a state can leave its domain, try these in order, and go down a rung only when the one above cannot do the job.

0. **Design out stiffness.** Choose the coupling structure and the pointwise nonlinearity so that the system is tractable to integrate. These are separate axes, and a change must say which one it addresses. `plant`'s TF24 soil is the worked case. Drainage from a layer depends on that layer's moisture alone (free drainage: Darcy's law with the matric gradient dropped), which removes the upward coupling between layers: the soil Jacobian is lower-bidiagonal rather than tridiagonal. It leaves the pointwise nonlinearity, a conductivity with an exponent of about 16 in moisture, which no decoupling reaches. This rung can change the physics: decoupled layers are no longer Richards' equation and carry no upward capillary flux. Record such a trade in the model's documentation, not only in a code comment, because a reader comparing against the literature will otherwise assume the standard form. (TF24 records it only in a code comment so far; [plant #796](https://github.com/traitecoevo/plant/issues/796) tracks that.)
1. **Make the bound follow from the functional form.** Factor a signed net rate into non-negative fluxes, each with its own smooth limiter, instead of gating the net rate behind a test. The bound is then a property of the exact flow. A finite step can still overshoot it, so rung 3 backs this rung up rather than being replaced by it. The worked case is TF24's storage pool, split into a charge and a drain whose difference is exactly the old net flux, and declared non-negative for the solver as well ([plant #609](https://github.com/traitecoevo/plant/issues/609)).
2. **Make the bound follow from the basis.** Integrate a transformed state with the right support, such as `log S` or `S = w²`, and recover the quantity through the link. There are two caveats. A transform only enforces a bound that the exact vector field already respects: if the flow itself leaves the domain, the transform turns a bound violation into a blow-up or a stall, so rung 1 comes first. And it is not neutral for the solver: an absolute tolerance on `log S` is a relative tolerance on `S`.
3. **Let the solver reject the step.** An odelia system can declare which states are valid, and a step that ends outside them is rejected and retried with a smaller step ([odelia #55](https://github.com/traitecoevo/odelia/issues/55)). In `plant`, a model lists its non-negative states in `non_negative_states()`, and `Patch::ode_state_valid()` also refuses a non-finite environment state. Write such a predicate as "is the state inside the domain", never as "is it outside": `NaN < 0.0` is false, so the second form lets a NaN through (the plant #549 case below). And check the state itself, not a quantity derived from it: TF24's soil water potential is computed from the moisture state, so its bound is a bound on moisture.
4. **Fail loudly**, for the physically impossible only, as in the table above.

The ladder exists so that rung 4 is rarely needed; it does not replace it. Failing loudly stays better than clamping quietly.

## Smooth, not stepped

Prefer smooth responses to stepped ones. This is a modelling concern before it is a numerical one. A broken-stick response claims that something changes character at exactly one value, which is rarely what anyone means. The smooth version is easier to defend, kinder to the step-size controller, and differentiable, which matters because a kink in a rate propagates into every derivative taken through it.

| Class | Looks like | Verdict |
|---|---|---|
| Discontinuous | step functions, thresholds, an `if` returning different values on either side | **Never** |
| C⁰, kinked | `min`, `max`, `abs`, broken sticks, clamps | **Avoid.** The derivative jumps, which breaks derivatives and misleads the step-size controller |
| C¹ | value and first derivative continuous | **The working minimum** |
| C∞ | all derivatives continuous | **The target**, where it costs nothing |

"No branches" is too strong. The rule is **no branch that is not the continuous extension of the form around it**, as with the density boundary condition above. A rung-3 validity predicate is not a problem either: it chooses which step is taken rather than contributing to a value.

The usual substitutions:

| Instead of | Use | In `plant` |
|---|---|---|
| `max(x, 0)` | softplus, `0.5·(x + sqrt(x² + ε²))` | TF24's positive part of net production, `Ppos` |
| a threshold at `a` | logistic, `1 / (1 + exp(-(x − a) / w))` | TF24's storage gate, `G` |
| `min(x, x_max)` or a hard cap | `x_max·tanh(x / x_max)`, or `x·x_max / (x + x_max)` | — |
| `abs(x)` | `sqrt(x² + ε²)` | — |

**Every surrogate brings a width (`ε`, `w`, `k`), and the width must scale with the quantity it smooths, never be an absolute constant.** States in these models span orders of magnitude, so a fixed width is a step function at one end of the range and noise at the other. TF24's `storage_prod_eps = 1e-4` kg/yr is the live case: an absolute constant against fluxes that span six orders of magnitude, and larger than a seedling's whole storage pool ([plant #609](https://github.com/traitecoevo/plant/issues/609), [#620](https://github.com/traitecoevo/plant/issues/620)). For the same reason, smoothness has to hold across the whole parameter range being explored, not only near the defaults.

## At the edge of viability

When a quantity vanishes at the edge of viability, and something downstream divides by a quantity that vanishes with it, **the numerator must vanish to a strictly higher order.** Matching orders leave a finite non-zero limit, and a lower order diverges. The density boundary condition above is the worked case: establishment is quadratic in net production, growth only linear. Establishment probability's `else 0` branch is C¹ but not C², since its value and first derivative tend to zero from above and its second derivative does not. That is the right target. (The density itself is only C⁰ there, with a kink, because it is linear in net production.)

Flattening harder is not better. `exp(-1/P)` is C∞, with every derivative vanishing at the edge, and it is numerically awful, which puts it at odds with rung 0. Prefer raising the polynomial order to flattening exponentially: quadratic over linear is the cheapest thing that works.

## Any strategy, any environment

Any strategy should run in any environment, however ill-suited, and return low growth and low fitness rather than an error. Reading code finds clamps and branches. A wide sweep of parameters and environments is what finds, systematically, where a model quietly stops making sense with neither present, as with a badly scaled width such as `storage_prod_eps`. Before a sweep can test anything, "behaves reasonably" needs an operational definition. The candidates are:

- the run finishes without error;
- growth and fitness are finite and non-negative;
- fitness moves in the expected direction along the obvious gradients;
- no state leaves its domain.

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
- **A spline evaluated outside its domain → check who is asking before deciding whether to clamp.** Posed here as "clamp or widen?", and the answer turned out to be *neither*. The lookup that failed was the inverse transport curve, asked for the stem potential that would carry a **negative** sap flux from a collar at the critical potential — i.e. a potential wetter than saturation, which does not exist. The spline was right to refuse; the caller was wrong to ask, because it was asking in the hydraulic shut-down state, which the feasibility analysis one level up had already rejected. Clamping would have returned a plausible stem potential for an impossible state — the exact failure mode this table's `Never` row warns about — and widening was aimed at the wrong end of the domain anyway.

  Two lessons worth carrying:

  1. **An out-of-domain lookup is often a question that should not have been asked.** Before reaching for the domain, find the caller and check whether the state it is evaluating at is one the model already knows is infeasible.
  2. **Where a state is handled in two places, check both.** The bug was an asymmetry: one gradient method took the zero-gradient branch in shutdown, its sibling did not. The fix was to make them agree, not to touch the numerics.

  The reporting half of the original entry stands, and paid for itself immediately: naming the spline, the point, the distance outside, the domain and the calling function turned a four-call-site bisect into one read. Two additions from doing it — **name the bracket, not just the point** (a failure inside a solve is usually a property of the interval the caller chose, which is invisible from where it is thrown), and **do not tighten a NaN comparison while you are in there**: `u < lo || u > hi` is false for NaN by design in some callers, so negating it into an in-range test reads like a diagnostic improvement and is really a behaviour change. This does not contradict rung 3 of the ladder above. A *new* validity predicate should be written as an in-range test so that a NaN fails; an *existing* check whose NaN behaviour callers rely on is a contract, and changing it is a separate, deliberate change, not a side effect of improving a message ([plant #576](https://github.com/traitecoevo/plant/issues/576), [#582](https://github.com/traitecoevo/plant/pull/582), fixed).

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
- Is this bound enforced by the form, the basis, the solver, or a clamp?
- Does this rate stay at least C¹ across the whole parameter range, and does every smoothing width scale with the quantity it smooths?
- **Is the guard in the right place — is the caller even entitled to ask?** A guard added where a failure *surfaces* can be correct code in the wrong file. Walk one level up: if the state being evaluated was already ruled infeasible there, the fix belongs there (plant #576).
- **If the same state is handled in more than one place, do they agree?** Two code paths for the same thing that disagree about an edge case is a common shape for these bugs, and it means the edge case is only reachable through one of them (plant #576).

---

**Extended 2026-11-16** with the ladder, smoothness, edge-of-viability and parameter-sweep criteria from [plant #610](https://github.com/traitecoevo/plant/issues/610).

**Added 2026-07-29**, from the review discussion on
[plant #570](https://github.com/traitecoevo/plant/pull/570) — "worried about whether we
essentially get an undisclosed error when the model should really just break" — and the #571
family of dry-corner failures. See [`triage.md`](triage.md) for contribution discipline and
[`../AGENTS.md`](../AGENTS.md) for the architecture rules.
