---
name: review-panel
description: Reviews the code you have changed but not pushed — unpushed commits, staged, unstaged and untracked — with a panel of thirty independent reviewers, each a different mind with its own context, then a critic that attacks their findings before you see them. Covers defects, design, the change itself, the shipped product, platform behaviour and repository integrity. Use when asked for a review, a code review, a second opinion, a panel review, a multi-perspective review, or to check my changes before pushing. Run it in this session, not in a subagent.
allowed-tools: Agent, Bash, Read, Grep, Glob, AskUserQuestion
---

# Review panel

Thirty reviewers read the same changeset at the same time, in separate contexts, each forbidden
from reviewing the other twenty-nine's territory. Then a thirty-first reads *their reports* and
throws out what does not survive. The value is not thirty times the effort — it is that a narrow
lens finds what a general reviewer skims past, and that **two reviewers arriving independently at
the same line is real corroboration** in a way one reviewer's confidence is not.

Three findings shape this design. Most defects a review turns up do not affect visible
functionality at all — they are evolvability defects, which is why most of these lenses are not
bug hunts. The reviewer's largest unmet need is *understanding the change*, not spotting faults,
which is why `review-comprehension` exists. And relative code churn predicts defects better than
almost anything else available, which is why `review-history` reads the git log rather than the
diff.

**Run this in the main session.** The fan-out is the delegation; wrapping the whole procedure in
one more agent buys nothing and costs a report hop.

The panel is read-only from end to end. It never edits, stages, commits or pushes. Applying a
finding happens afterwards, only if the developer asks.

## Step 1 — pin the changeset

```bash
bash ~/.claude/skills/review-panel/scripts/review-scope.sh
```

One call. It prints the **base sha**, how that base was resolved, the unpushed commits, the
changed-file stat, the untracked files and the total size. Every reviewer diffs against that one
sha, so all thirty see the identical changeset even if the tree moves underneath them.

- `NOTHING TO REVIEW` — say so and stop. Do not review the last push instead.
- A `WARNING` in `BASE_SOURCE` means no upstream or default branch was found, so committed work is
  **not** covered. Surface that line to the developer before reviewing anything.
- The developer may name a different scope — a branch, a PR, one directory. Honour it, and pass
  the range you actually used to the panel.

Show the developer a two-line summary of what is about to be reviewed, then go to Step 2.

**Size gate.** A thirty-lens panel is a large amount of work, so check before spending it:

- Beyond roughly **25 files or 2000 changed lines**, do not start silently. Say how big it is and
  ask with one `AskUserQuestion` whether to run the full panel, review the unpushed commits only,
  or review a named subdirectory.
- The developer may also ask for a **named subset** of lenses — "just the bug ones", "skip the
  product ones". Honour that, and say in the report which lenses did not run. A subset the
  developer chose is not a coverage gap; a subset you chose silently is.

Otherwise go straight to Step 2 without asking permission — they asked for a review.

## Step 2 — wave one, all thirty

Thirty `Agent` calls, issued **concurrently and without any other work between them**. Put them in
one message; if the harness limits how many tool uses a single message may carry, continue in the
next message immediately and never drop a lens to fit. If it caps how many run at once, the rest
queue, which is fine.

Each gets its own context and re-reads the code itself — do not paste the diff into the prompts.

**Defects and runtime**

| Agent | Lens |
|---|---|
| `review-correctness` | inputs, edge cases, error paths, ordering, lifetime |
| `review-concurrency` | races, deadlock, reentrancy, thread affinity, async |
| `review-security` | trust boundaries, injection, secrets, failure modes |
| `review-performance` | cost per call, complexity, allocation, hot paths |
| `review-memory-lifetime` | what the change keeps alive, and who releases it |
| `review-error-handling` | what each layer promises its caller when things fail |
| `review-ai-authored` | symbols, keys and comments that are plausible but not real |

**Design and judgement**

| Agent | Lens |
|---|---|
| `review-architecture` | placement, altitude, coupling, reuse |
| `review-alternatives` | a different solution to the same problem, argued then judged |
| `review-simplicity` | same approach, less of it — what can be deleted |
| `review-maintainability` | naming, readability, house style, leftovers |
| `review-api-ergonomics` | whether the right call is easier to write than the wrong one |

**The change itself**

| Agent | Lens |
|---|---|
| `review-comprehension` | whether the change tells its own story |
| `review-completeness` | the sibling call sites and parallel implementations that did *not* change |
| `review-history` | churn hotspots, and what `git blame` says about the lines being removed |
| `review-requirements` | the ticket or spec it claims to implement, requirement by requirement |
| `review-verification` | what is tested, whether the test would fail without the change |
| `review-regression-risk` | which existing features the change can reach |

**What ships**

| Agent | Lens |
|---|---|
| `review-compatibility` | what breaks for an existing consumer |
| `review-data` | what happens to data that already exists |
| `review-operability` | blast radius, detection, reversibility in the field |
| `review-config-defaults` | what happens to everyone who never sets this |
| `review-docs` | what the change made the published documentation wrong about |
| `review-logging-telemetry` | whether the log it produces says what happened |

**Platform and repository**

| Agent | Lens |
|---|---|
| `review-platform-behavior` | DPI, RTL, localization, theming, accessibility, wording |
| `review-cross-target` | framework, runtime and OS divergence |
| `review-build-packaging` | project files, targets, references, what actually ships |
| `review-generated-artifacts` | converted and generated output still in step with its sources |
| `review-standards-compliance` | the rules this repo actually writes down |
| `review-dependency` | what the change makes you depend on |

**The roster is fixed — always all thirty, unless the developer named a subset in Step 1.** A lens
with nothing to say is cheap and reports one line; a lens quietly skipped is a coverage gap nobody
sees. Most are built to self-limit and exit in a line when the changeset does not reach them —
`review-dependency` when no manifest moved, `review-data` when nothing is persisted,
`review-concurrency` when the code is single-threaded — and that one-line answer is itself a result
worth having.

Each prompt carries the same four facts and nothing else:

1. the pinned **base sha**, with the exact command — `git diff <BASE>`;
2. the **untracked files** by path, to be read in full since no diff shows them;
3. the repo root and the branch;
4. anything the developer said about what the change is *for*. Give it verbatim to
   `review-comprehension`, `review-alternatives` and `review-requirements` — the first compares its
   own cold reading against it, the second needs the problem statement, the third needs the ticket.

Do not editorialise in the prompt. Telling a reviewer what you think is wrong is how thirty
independent contexts collapse into one opinion.

## Step 3 — wave two, the critic

One `Agent` call to `review-panel-critic`, with all thirty reports in the prompt plus the same base
sha. It reviews *them*, not the code, and returns findings sorted into rejected, re-ranked and
standing, plus a note on the panel's blind spots and whether the volume is proportionate.

This wave is not optional at this roster size. The characteristic failure of a thirty-lens panel is
not missing things — it is producing a list long enough to be skimmed, in which the two findings
that mattered are buried. A separate context does it rather than you, because the session that
wrote the fan-out prompts is the worst-placed judge of what came back.

The critic advises; it does not decide. You still own Step 4, and where you disagree with it, say
so in one line rather than silently overriding it.

## Step 4 — consolidate

The reports are input, not output. Never relay thirty-one reports; produce one.

1. **Start from the critic's verdict.** Drop what it rejected, apply its re-rankings, keep what it
   flagged as real consensus.
2. **Merge by location.** Group surviving findings by `file:line`. Where two or more reviewers
   landed on the same line from different lenses *for different reasons*, that goes to the top and
   is labelled with who agreed — it is the single strongest signal the panel produces.
3. **Verify the top of the list yourself.** For every `blocker` and `major` still standing, open
   the file and confirm the claim. Two independent checks on the findings that will actually cost
   the developer time is the right amount; say how many you dropped at this stage.
4. **Facts over preference.** A finding backed by a concrete failing case, a named convention or a
   quoted rule outranks one backed by taste. There is no perfect code, only better code — do not
   hold a change hostage to a rewrite when the listed fixes would do.
5. **Resolve disagreement rather than hiding it.** Where two lenses genuinely conflict — a shape
   that is safer but less readable, a test the design makes impossible, `review-alternatives`
   wanting a different approach and `review-simplicity` wanting less of this one — present both
   positions in one row and name the trade-off. Do not average them into a bland recommendation.

## Step 5 — the deliverable

**One table first**, ranked by severity, most severe at top:

| Severity | Location | Finding | Raised by | Fix |
|---|---|---|---|---|

Then, and only then, the detail for each `blocker` and `major` — the failure case, the cost, the
concrete fix. Minors and nits stay in the table as one line each; cap nits at ten and say how many
were dropped.

Close with:

- **Verdict** — one sentence. Ready to push, ready with the listed fixes, or not ready and why.
- **Consensus** — the lines more than one reviewer flagged, if any.
- **The alternative** — `review-alternatives`' verdict in one line, even when it is "keep what you
  wrote". A design that was independently reconsidered and held up is worth telling the developer.
- **Before you push** — the concrete actions other than code edits that the panel turned up:
  regenerate an artifact, add a release note, re-check a named feature, test a round trip.
- **Coverage** — a compact list of all thirty and what each returned, including the ones that
  reported nothing, plus how many findings the critic rejected. A lens that found nothing is a
  result; a lens whose absence goes unmentioned reads as coverage the panel never had.

Then stop. Offer to apply the fixes; do not apply them unasked, and never commit or push.
