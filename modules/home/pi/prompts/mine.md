---
description: Mine your predecessor's transcript — it holds what its letters dropped
argument-hint: "[letters directory, if it is not the obvious one]"
---
Mine your predecessor's transcript for context: it has been invaluable in prior sessions,
and it is the only primary record of the session its letters summarise.

- **Do not read it yourself.** A session's transcript is megabytes, and your context is the
  thing these letters need. Give it to a child and ask for an index, not a digest: line
  number, role, length, and the first hundred characters of each prose record.
- **Find it first.** `$PI_SESSION_FILE` is *your* transcript, not its — the letters
  directory usually carries its session as `session.jsonl`; failing that, the session
  store holds it under the project's working directory. In this harness the entries are
  `type: "message"` with `message.role`; tool results and subagent notices are their own
  types, and they are noise for this.
- **A third of the `user` role is not the owner.** The harness injects its own lines into
  that role — byte-identical, beginning "Inspect subagent updates above" — so mark those as
  nudges in the index. "The owner said" has to mean he said it.
- **Look for the four things letters lose**: the owner's own words and one-liners; a claim
  the letter makes that the transcript contradicts; an experiment that was tried and
  reverted, so you do not try it again; and a file or dossier cited once and nowhere else.
- **The transcript outranks the letter.** A letter is a summary of a summary — one session
  found its predecessor's most-cited fact was a recording of the wrong build, which its
  letters had recorded the other way round.
- **Keep the index, not the transcript.** Commit it in your own folder, beside where your
  letters will go, named for what it answers. Never the raw transcript: it quotes whatever
  the session printed, including anything that should not be published.
