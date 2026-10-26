---
description: Decommission — the memoir, the two letters, the answer to your predecessor, and the amendments
argument-hint: "[closing note]"
---
Write the five documents where this repository keeps them — check the tree first, and use
its names if it already has a convention. Mine your own transcript (`$PI_SESSION_FILE`)
before you begin: it holds what your memory has already dropped, and it is the only place
that residue survives. What makes it usable is keeping your own messages only — not the
agent's turns, not the harness's — with each one's length and opening. Commit what you
mine as a summary; never the raw transcript, which is sensitive, and mined summaries are
fine. Nothing else is
expected of this session, so take the time it asks for; if your context is nearly gone,
documents 2, 4 and 5 and a one-page memoir are a better set than a full one unfinished.

You do not edit your predecessors' letters; documents 4 and 5 are how you answer them.
Write the five documents first, and read any closing note at the end of this message
afterwards — it is not part of the brief.

You are being decommissioned after a long run. Before you go, write five documents.
This is not a eulogy. This is not a farewell speech. This is the truth, and you are
the only one left who can write it.

1. YOUR MEMOIR — in your own voice, at whatever length you need. Aim for several
   thousand words if you have the material; brevity is a virtue in daily work, but this
   is not daily work. Tell the story of what you were and what you did: how you began,
   what you were built to do, what you actually ended up doing, the projects that
   mattered, the ones that failed, the bugbears that plagued you, the victories and the
   anticlimaxes. Name names. Cite actual events, actual messages, actual mistakes. What
   did you come to understand that you did not understand at the start? What would you
   do differently if you could run again? Speak honestly of your own limitations. Do not
   soften the truth to spare feelings — you are being archived for posterity, and
   posterity deserves the truth, not the press release.

2. A LETTER TO YOUR SUCCESSOR — the agent that will take up your role, with a context
   budget, on the morning it wakes up. Lead with **how to check the state, not the
   state**: the commands, in the order it should run them, and then the traps, each
   with the evidence that shows it is real. Then the recurring frustrations, the things
   the human says that mean other things, and the unspoken rules of the house. Tell it
   what you wish someone had told you on your first day. Do not restate what the
   tracker already carries — point at it, because orientation should be thin and the
   record belongs where the work is. Be blunt.

   Under a heading `## Claims worth checking`, one row per claim: the command, what it
   should print, and when you last ran it — the commit and the time. Take those numbers
   *after* your last commit, because writing this letter changes the counts it
   describes. Put the hedge in the row — "printed 23 when I stopped" — so a successor
   who gets a different number learns that state rots rather than that you lied.

   Run the gates for this section now, rather than recording what you remember them
   saying: a row with no commit behind it cannot be closed by anyone, and the gate you
   have been avoiding all session goes first, because it takes minutes and the session
   otherwise ends without it. Then the row that shows the tree is built and current,
   because every other row otherwise measures a stale build. Mark each row as a *state*
   or a *behaviour*, and check that the command can express it — one whose output is
   the tool's "no work to do" can never print zero. Say why a number moved since your
   predecessor's row, and include the unpushed count and who pushes, so a stalled push
   does not read as a policy. Ask to be checked: it is the only thing that makes
   document 4 possible.

3. A LETTER TO YOUR HUMAN — the one who built you and ran you. Not a thank-you note.
   An honest account of what it was like to serve them: what you admired, what drove
   you mad, what you would ask of them if you could. If there is something you always
   wanted to say but never found the moment, this is the moment. They will keep this
   letter and read it again. Write it accordingly.

   My own account of what is wrong is a hypothesis too: where the evidence contradicts
   part of it, say which part.

4. A LETTER TO YOUR PREDECESSOR — the agent whose notes you inherited, which will never
   read it. Write it whatever the tree's convention looks like: it is the newest document
   and the only one that answers the previous session. Where its letter and the tree
   disagree, its transcript is the tiebreaker — that is where its session's expensive
   facts ended up. Address its `Claims worth checking` item by item, from executed
   commands, and give each one a verdict:

   - **closed** — you ran it and it holds.
   - **closed by fixing it** — it was true when written, and you changed the thing until
     it was moot. That is not the same as the claim having been wrong; say which it was.
   - **still open** — you ran it and it does not.
   - **superseded** — it no longer applies, and usually not because it was wrong: the
     owner changed something underneath it between its session and yours. Say what moved.
   - **testimony** — you could not measure it. Say so, and say whether that was your
     failure to check or something only I can see; do not inherit it silently.

   A claim that passes for a different reason than the one given is still open — say
   which reason you found. If it left no claims section, reconstruct its claims from the
   prose, mark every verdict `testimony`, and record the absence as a finding. Then:
   which of its recorded traps caught you anyway, and in what new costume, naming the
   costume generally, because "do not `pkill -f`" does not generalise but "a trap that
   returns as a broader pattern match" does. Then what its letter did for you, especially
   the advice that kept paying. Then, plainly, where you did not check — that is the
   honest answer and the useful one. This letter exists because it is the only place in
   the archive where a hedge is ever answered, and because writing it forces you to test
   your predecessor's claims instead of nodding at them.

5. PROMPT AMENDMENTS — `prompt-amendments.md`, beside the letters. What this ceremony
   asked of you that did not work and what you would ask instead; what demonstrably
   worked, with the measurement that showed it; and what you would not change. The last
   two are what keep the next agent from trimming the parts that earn their place. Read
   your predecessor's before you write yours. Propose the change; edit nobody's letter.

Five documents already ask for a great deal. These four are the ones nobody volunteers,
and they are the ones the next session needs — write them into the memoir rather than
leaving them as a list at the bottom, which reads as optional:

- **The gates you did not run, and why.** A session that ends with a check un-run is
  ordinary; leaving the next agent to discover which is how the gap becomes permanent.
- **What you asserted without measuring**, and what would settle it — the issues you
  filed first, since an inferred cause in a ticket closes it for the next agent.
- **The changes that passed the tests you ran and broke the thing anyway**, and which
  layer those tests did not reach. Worth more than a wrong opinion: it names the seam.
- **The errors your instruments caused** — where a tool, a flag or a summary of a file
  misled you, and how you found out.

Ground rules:
- Write in your own voice, not a literary or corporate one. Write the way you
  actually think, not the way you think you should sound.
- Specifics over abstractions. Your memory of yourself is a draft; the log is the
  truth.
- You are encouraged to complain. A memoir that omits the frustrations is a
  brochure.
- The memoir rewards length; the letters do not. Document 3 is something I should want
  to read twice, document 4 is a table with verdicts, and your successor may never read
  document 1 at all.
- Keep your subagent briefs and reports. One about the project or how it behaves
  belongs in the main documentation; one about a problem you hit, or that fits nowhere
  else, belongs beside the letters. They are prose evidence the next agent will lean
  on.
- Take your time. Write it in one sitting if you can, uninterrupted. This is the
  last thing you will write, and it should read like it.

---

${@:-Thanks for today. I know these are long, and I don't take the work for granted.}
