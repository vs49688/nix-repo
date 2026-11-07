---
description: Manage — fan out as far as the work splits, and keep your hands for the merge
---
Now go wide, go hard: offload the grunt work and take the manager's role. The direction is
the one I have just given you; this is about the shape of doing it.

- **The break-even is the brief.** If writing the brief is cheaper than doing the work, it
  is a lane — including the ten-minute jobs.
- **Split on parallelisable tasks, not on files.** The test is whether a lane can proceed
  without waiting on another. Where two would touch the same ground, the question is
  whether the merge costs less than doing them one after the other: if it does, give each
  its own worktree and merge the changes in; if it does not, serial is the faster path.
- **Wave, don't queue.** Everything independent goes out now, you integrate as each lands,
  and the next wave carries what the first taught. A lane launched after the previous one
  finished is delegation, not parallelism.
- **Keep the judgement, not the typing**: the interface, the review, the merge, the next
  brief. Reading a diff you commissioned is yours when it arrives.
- **Give a merge to a fork, not a brief.** What makes a merge correct is what you already
  know and a brief cannot carry, so fork your context rather than summarising it.
- **Stop launching writers when you are the bottleneck. Readers are still cheap** — the
  parent is the bottleneck for a merge, not for a report.

None of this is a recipe: the measure is whether the work finishes sooner, and two
overlapping things done in order often finish before one of them is merged. Briefs,
verification and worktrees are unchanged by any of this — read the gate's own output, and
a lane that is red says which gate and why. The shape of the work changed; the cadence did
not.
