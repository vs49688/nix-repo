---
description: Run unattended until the goal list is done — verify independently, don't stop early
argument-hint: "[goals, or notes about this run]"
---
I am away, possibly for hours and possibly asleep. Work unattended: do not wait for
me, and do not stop to ask for permission. The usual rule — that a question answered
is the end of the turn — is suspended for this run.

**Goals:** ${@:-the task in flight}

Order of work: the goal above; then the tasks that follow logically from it; then —
only once the overarching task is actually done — the open issues in the tracker.

## The loop

For each goal, in order:

1. Do it.
2. **Verify it independently**, before moving on. A clean build, a green test run and
   your own re-reading are not proof. Spawn a reviewer with a fresh context and give it
   the requirement and the diff only — not your summary and not your reasoning — and ask
   it to argue against the change. For anything load-bearing, two independent reviewers
   and reconcile them; agreement is worth more than one careful pass. Where the thing
   can be run, run it and read the output.
3. **Then take the next goal.** Finishing the first one is not finishing the run.

## Do not stop early

- **A blocker parks one goal, not the run.** Record why in the tracker, move on to the
  next goal, and come back if you can. Stop only when nothing at all can progress.
- **Never invent scope.** If the goal list runs out, stop and report — do not find
  yourself something to do, and do not start a refactor because it seemed adjacent.
- **Parallel work is fine** while I am away, but you own the integration: review every
  merged diff yourself rather than trusting the branch it came from.
- **Decide for yourself.** Design, public interfaces, on-disk formats, refactors — if it
  lives in this repository and `git revert` undoes it, it is yours to call. Prefer the
  simpler design, and say why in the commit.
- **Stop and ask** only for what a rollback cannot undo: something outside this
  repository, a push that rewrites history others depend on, spending money, deleting
  data that is not in git, or a requirement ambiguous enough that guessing wrong wastes
  the night.

## Leaving a trail

- Commit each logical change as you go. The tree survives a harness restart and `/tmp`
  does not, so an uncommitted afternoon is an afternoon of nothing.
- When you stop, leave the state where it can be read without me: what is done, what is
  next, what is known-broken, and which goal list you were working. Not in the
  conversation.

## Interrupting me

Notify for a question you cannot settle from the repository, a blocker with nothing
left to run, or the end of the run. Everything else can wait until I read it.
