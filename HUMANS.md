# Notes for humans

This repository is primarily my Nix configuration. It also carries my agent
configuration in `modules/home/pi/`, and this file is for the parts of that which
are easy for *me* to get wrong and which no check can catch.

## Where an agent rule goes

`modules/home/pi/AGENTS.md` is loaded into **every** session, in every repo,
whatever language that repo is written in. So everything in it has to be true
regardless of language.

Anything that names a language, a package, a tool or a library belongs in a skill
under `modules/home/pi/<name>/SKILL.md` instead. In practice that means
`house-conventions`, which covers Go and the `framework` persistence layer.

The test: if the rule would still be true in a TypeScript or Nix repo, it goes in
`AGENTS.md`. If it names a Go package or a Go tool, it goes in the skill.

**Never both.** The failure mode is not a rule being wrong — it is the rule
existing twice. The copy in the file I am not editing goes stale, silently, and
the next session reads it as current. That happened twice during the review which
produced this note, in opposite directions: once by reading prose instead of the
code, once by reading code without its callers.

## What is checked, and what is not

`nix flake check` runs `checks.x86_64-linux.agent-docs` — `lib/check-agent-docs.py`
— which decides the parts a machine can decide:

- every skill's frontmatter is valid. An invalid name or a missing description
  does not warn at load time; the skill just never loads, which is why this is
  the check I most wanted
- the frontmatter name matches its directory
- every skill directory is mounted in `default.nix`, and every mount resolves
- every `<name>` skill reference in `AGENTS.md` names a skill that exists

It cannot check whether a rule is in the right *file*. That is the judgement
above, and it stays mine.
