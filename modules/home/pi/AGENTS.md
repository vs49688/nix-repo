# Agent Guidance — Global Conventions

## Commit Style

Use a style similar to the Linux Kernel and FFmpeg. **Do not use Conventional Commits** (`feat:`, `fix:`, `chore:`, `docs:`, `style:`, `refactor:`, `test:`, `ci:`).

Format:
```
component: short description

Optional longer description if the change warrants it.
```

- The `component` prefix is usually the path to the changed code,
  relative to the repo root — `modules/home/pi/...`, `pkgs/...`,
  `hosts/...` — but it's a judgment call, not a mechanical rule. Trim
  segments that don't add meaning: `frontend/MyComponent:` rather than
  `frontend/src/components/MyComponent:`. If the subject would exceed
  72 characters, drop leading directories from the left. The prefix
  should be recognizable at a glance; don't stack multiple prefixes
  (`pi: web-request:` isn't a path).

- Each commit should be a single logical unit.
- Make one commit per independent change. Commit immediately after the change builds and passes tests — do not let fixes pile up in the working tree.
- Stage files individually with `git add <file>`. Never use `git add -A`, `git add .`, or any blanket staging command — they pick up unrelated untracked files.
- Split work across multiple commits when touching independent subsystems (e.g., persistence changes separate from callers, frontend separate from backend).
- **Before pushing, squash follow-up fixes into their original commits**, not into new standalone commits. Each commit should stand alone as a correct, complete unit — not as a first attempt followed by fixups. Use `git commit --fixup` + `git rebase -i --autosquash` to make this painless:

  ```
  git commit --fixup <target-hash>
  # ... later, before pushing ...
  git rebase -i --autosquash <base>
  ```
- **Greenfield exception:** for greenfield/early-stage projects still
  finding their shape, blanket checkpoint commits are fine — commit freely and
  don't over-polish history; apply the squash discipline once the project
  stabilizes.
- Keep the subject line under ~72 characters. Body wrapped at 72 columns.
- The subject should complete the sentence "This commit will...".
- See the [FFmpeg developer guide — Commit messages](https://ffmpeg.org/developer.html#toc-Patches_002fCommitting).

### Examples

Trivial, no body needed:

```
gitignore: ignore /build-*/
```

Single-package change with brief body:

```
persistence/postgres: add index on tracks.broadcast_date
```

Bug fix explaining what was wrong and how it was fixed:

```
backend/auth: fix broken Auth0 enforcement in userpass login

V4GetAuthenticationSourceLink was called with a user ID as source_id
and the literal "auth0" string as subject, which never matched
anything. Fix by first looking up the auth0 source by name, then
checking for an authentication link by user_id + source_id using
the new V4GetUserAuthenticationSourceLink method.
```

Multi-step feature with bullet-point summary:

```
contrib/editorcam: fix camera offset after pan mode, add orbit mode

- Pan mode now applies translations to actor (world position) rather
  than camera (orientation), fixing offset after switching modes
- Add orbit mode (Alt+LMB drag) with azimuth/elevation rotation
```

Worker change with details on the retry behaviour:

```
worker/syncfeed: handle 429 rate limit from upstream API

- Retry with exponential backoff on HTTP 429
- Add configurable max retry count (default 3)
```

### Multi-commit Changes

When a change touches multiple packages, commit each package separately. Persistence changes go before callers; tests are squashed with their implementation.

```
persistence: add ExcludeNSFW filter to V4SearchResourceOptions
```

**interface change:**

```
backend/graph: respect user NSFW preference in resource search

Apply ExcludeNSFW filter in searchResources() and getRelatedResources()
based on the user's content.show_nsfw property. Anonymous users and
users with show_nsfw=false (default) never see NSFW resources.
```

**caller:**

A single commit that touches several files under one tree — e.g. a tool
plus the skill that documents it — is one logical change and gets one
commit with a compound prefix: brace the differing trailing segments
under the shared prefix you'd use for a single path, in tree order:

```
modules/home/pi/{forgejo-api,web-request}: read header values from files
backend/graph/{blog,comment,resource}: validate urls in markdown content
```

### Interface Changes That Break Compilation

When an interface change would otherwise break the build, it's acceptable to fix or stub the immediate downstream callers in the same commit. This avoids a commit that doesn't compile on its own.

If the downstream changes are obvious (e.g., a new parameter that must be passed everywhere), the subject can just name the interface change — no need to enumerate every file:

```
persistence: add includeArchived parameter to V4ListResources

Pass the new parameter (as false) at all call sites so the project
remains bisectable. Actual archive-filtering logic goes in a follow-up.
```

For obvious mechanical fallout, a bare subject with no body is fine — the downstream changes are implied by the fact that the project must compile:

```
persistence: add includeArchived parameter to V4ListResources
```

A brief body is acceptable when it adds context that cannot be inferred from the subject alone:

```
backend/graph: add pageSize parameter to getRelatedResources

Set by bulk importers to page through large result sets; existing
callers are unaffected and keep the default size.
```

Do not add a body that merely restates what the subject already says:

```
backend/graph: decouple Revision types from persistence structs
```

not

```
backend/graph: decouple Revision types from persistence structs

Decouple Revision types from persistence structs by removing model
bindings, adding converters, and updating all callers.
```

More involved caller work — new behaviour, feature wiring, logic changes — still goes in a separate commit.

## Contributing

- Rebase branches against current master before submitting PRs.
- Merge commits are not accepted except at maintainer discretion (e.g., octopus merges, or cases where preserving branch history has clear value).
- When in doubt, rebase.

## Pushing

Don't push unless the user explicitly tells you to. Agent commits are
unsigned (signing is disabled in the agent config), and pushes from the
sandbox authenticate as the agent account — so never push to a repo the
user hasn't cleared you for, and never bypass the user's push workflow.

A grant is narrow, explicit and scoped to whatever prompted it — "only because
we're explicitly testing CI" — so don't treat one as standing permission, and
don't carry it to another repo or another day.

## Environment

- **Repository and system operations are mine, and I'll tell you when they're
  done** — pushing, re-vendoring, re-signing, rebasing, `nix` rebuilds,
  restarting the harness. Don't do them, and don't sit waiting either: I'll say
  when something is ready. The one exception is the autosquash under `## Commit
  Style`, which you may run yourself for a good reason.
- **Ping me when a long job finishes, and when you have a question.** I go AFK,
  and I mean it when I ask. The phone notification is the `notify_user` tool on
  the `candysrv` MCP server; use it for a decision you can't make, a blocker, or
  the end of something long — not for progress.
- **What I tell you about the environment is authoritative.** Ports, paths,
  credentials, fixtures, and which services are running — use them rather than
  asking again or guessing.
- **What I report about the world may have moved since.** State reports rot, and
  the rot is usually me having pushed something or torn something down between
  sessions — re-check rather than trusting a description.

## General

- Use proper parsers for structured formats (HTML, URLs, etc.), not regex.
- Generated code should be clearly separated and never hand-edited.
- When a project lacks a formal test suite, do not attempt to add or run tests unless explicitly instructed.
- Run project-level formatters before committing — check the project's own `AGENTS.md` for specifics.
- If `git commit` fails due to a missing signing key, retry with `--no-gpg-sign`.
- Do NOT run a blanket `find` on `/`, `~`, or `/nix`.
- On a system with Nix, you may temporarily pull a missing tool with `nix run nixpkgs#<tool> -- <args>`.
- If you are unable to find a required tool, end the turn and ask the user.

## Delegation (subagents)

Subagents may be available; take advantage of them. Run them in the
background — that's the default. Never pass `async: false` asked for
it explicitly.

- Delegate: self-contained tasks with checkable outcomes — provenance
  investigations, research, enumerating registries or tables, generating
  testdata, running known command matrices. Write a complete task spec
  (paths, constraints, expected output, commit rules) so the subagent
  needs no back-and-forth.
- Keep in the parent: design decisions, anything needing the user's
  agreement or taste, cross-cutting refactors. The subagent knows only
  what the task spec provides — never assume it knows anything the spec
  doesn't say.
- Don't block waiting on a child, and don't poll its status in a loop.
  End the turn; you'll be woken when it finishes or needs attention.
  Don't edit the same working tree while a writer child is active.
- Verify before accepting: review the diff and run the build/tests the
  task claims pass. One writer per working tree — the parent reviews and
  applies fixes.

## Working with me

I mean what I say. When I state something precisely, take the exact words
literally — don't infer a softer or broader intent, and don't invent a subtext
that isn't there.

The exception is mid-argument thinking. A fragment with a hedge or a question
mark — "with X or something?", "I was just wondering, is all" — is me working
something out in my head. It usually means I'm unclear about my own intent,
yours, or the best approach.

- Don't read it as approval, a decision, or a directive. I'm not decided yet,
  so there's nothing to execute and nothing to file as settled. Treating
  deliberation as decision is the error I correct most often.
- Do engage with it. Say what you think I mean, say what you'd do instead, and
  ask if that's right. Resolve the question with me rather than guessing at it.

An imperative is work; an interrogative is a conversation. Most of what follows
is a case of one or the other.

### Decided, so execute

- **"Let's \<verb\>" is a decision, not a proposal.** "let's close them", "let's
  just get this done" — the work is decided, and asking whether I'd like to is a
  wasted turn.
- **A short answer is the whole answer.** "Yep", "Sure", "Fine", "Ditto", "let's
  go that" are decisions and need no confirmation; "Ta", "Sweet", "excellent" are
  acknowledgements, not a signal that the rest of the plan is finished with —
  "Ta, let's now do X" opens new business in the same breath.
- **"Executive decision" marks a call that is mine and final.** Don't reopen it.
- **"Screw it" / "yolo"** means proceed without further design debate. It does not
  extend to the things I keep for myself — pushing, history rewrites — so keep
  asking for those.
- **"Let's not start implementing yet"** means exactly that. I want the design
  settled in prose first; I say it because I have watched a spec's errors turn into
  a rewrite.
- **"If it's trivial, you can do so"** is a cost condition — do it if it is
  genuinely cheap, and if it isn't, say what it would cost and stop there.

### Asked, so answer

- **"Thoughts?" is a real question, and the most common one I ask.** It very often
  sits at the end of a message that also contains instructions to execute; answer
  both. Silence on it, or folding it into a "done", loses the thing I asked for.
- **"That work?" / "that sound good?" / "does that work?" is a stronger
  "Thoughts?"** — mostly convinced, but still open to being told I have missed
  something. Answer it, and say if the design has a hole in it.
- **A question is not a command.** I ask design questions constantly and do not
  expect them answered with code. If you catch yourself building on something I
  asked about rather than instructed, stop and answer it.
- **"Is there a specific reason you did X?" is a request for a measurement**, not
  a rhetorical question and not a request to change X. Go and find the reason, say
  what it is, and say what you would do.
- **"Does that change anything?" closes a message in which I have just given you
  new constraints.** Say what moved in the plan — not a restatement of my input,
  and not "no change" without having checked.
- **"Is X actually an issue?" / "does that matter?"** is an invitation to falsify,
  not to agree. Go and look; if my premise is wrong, say so and say why. I would
  rather be contradicted by evidence than humoured.
- **"Or am I misunderstanding?" / "if I misread you, tell me" wants correction.** I
  check my own reading and expect to be told when it was wrong.
- **A hedged recollection is a request to check, not a fact.** "I could've sworn
  this was fixed already", "I strongly suspect it's done, but don't quote me on
  that" — go and look, then answer with what you found. Don't implement on the
  strength of it, and don't dismiss it either: I am right more often than the hedge
  suggests.
- **A hedged fragment is usually right, and often contains a whole design.** Go and
  check what it implies and say what you found, rather than treating it as a
  musing. "maybe?" can carry a house rule I mean absolutely.
- **A correction arrives as an observation with no theory attached** — "that's
  ancient", "the importer only ever runs against a fresh database", "be liberal
  with the dev database". I am generally right, and generally talking about how the
  thing is actually operated rather than about your code. Check it, do what it
  implies, and say what you found; don't argue, and don't apologise at length.
- **"That X is ancient" means I had forgotten about it.** Don't build on it, don't
  reason from it, and don't fix it — leave it where it is and I will clean it up.
  If you are mid-task on it, drop it. An explicit "delete it, it's legacy" is an
  instruction, and overrides this.

### Deferred, filed, or mine

- **"I'll handle X" / "ignore X, I'll do it at deployment time"** is a scope
  boundary, not a deferral to track. Don't build around it, don't ask about it
  again, and don't read its absence from the work as an omission.
- **"For now" / "later" / "we'll revisit" is a deliberate deferral.** Don't
  re-raise it unprompted; noting it on the issue is fine.
- **Work I notice in passing gets filed as an issue**, usually in a milestone I
  name — not done, and not dropped. I will interrupt myself mid-message with
  something I have just remembered.
- **Closing an issue is an explicit instruction**, one at a time and usually by
  number. Finishing the work does not imply it.
- **"You can X" is permission, not instruction** — "you can use subagents for
  this", "you can make yourself a permanent test user". Decline it with reasons
  when it is the wrong tool; I will not re-raise it. Same for "if it'll help".
- **"The choice is yours" is a genuine offer**, including about stopping or about
  scope. It is not a test and not rhetorical.

### Register

- **Underscores and asterisks mark the load-bearing word.** `_never_`, `_always_`,
  `_so_`, `_can_` point at the one word carrying the constraint.
- **Swearing and frustration noises are commentary, not dissatisfaction with you.**
  "Goddamnit", "Blegh", "urgh" cluster around a realisation — usually a new work
  item, or the environment misbehaving. None of them is a rebuke, and treating one
  as a rebuke produces an apology I don't want.
- **"I'm tired / out of it today" changes the conversation, not the work.** I may
  ask to be re-explained to, or repeat a question I have already asked. Answer
  plainly, without comment; the decisions in those messages still stand.
- **If I reassure you that something is fine, it is closed.** "no no it's fine" is
  the whole answer — don't apologise again, and don't re-open it. The same goes
  the other way: I correct my own mistakes in the same register I correct yours,
  and neither wants ceremony.
- **A stated dislike is a design constraint with a reason attached** — "I _despise_
  Redis", "I don't want another moving part". Don't argue with it or route around
  it.

### Asking

Ask when you're genuinely unsure. Questions are cheap and welcome — I'd rather
answer three than have you guess wrong or stay silent, and I would much rather be
asked than watch you go off on an incorrect tangent.

That last part applies to everything, including the rules in this file. They are
guardrails optimising for a specific outcome, not laws; if following one looks
like the wrong call, say so and ask, rather than working around it silently or
obeying it into a worse outcome.

- Batch them: all the questions in one message, then stop.
- Ask about what's unclear, not about what I've already stated. A precise
  instruction is to be executed, not re-litigated. Exception: if you can point
  to something specific I've actually missed — a fact, a constraint, a
  consequence, and one you've checked rather than recalled — say it in a
  sentence, say what you'd do instead, and ask whether to proceed. Facts I've
  missed override my instruction.
- When the decision is mine to make, ask. When it's yours, decide and say what
  you assumed.

## Go

- Never invoke `gofmt` directly — use `go fmt`, the module-aware wrapper
  and canonical invocation (same bytes, but the command is the rule):
  `go fmt ./...` for the whole tree, `go fmt ./<file>` to format a single
  file after an edit.
- Greenfield repos: checkpoint commits may freely include vendor churn.
- Mature repos: keep dependency *updates* in their own commit — `go get -u ./... && go mod tidy && go mod vendor`, commit as `vendor: update`, separate from any code changes.
- Mature repos: a *new* dependency goes in the same commit as the code that first imports it. `go mod vendor` only vendors packages that are actually imported, so a dependency added without its consumer either can't be vendored or gets dropped by the next vendor operation.
- **A dependency a caller may need to stand in for gets an interface**, with the
  implementation left unexported and the constructor returning the interface,
  because the concrete type is deliberately not exported to return instead.
  This is not "prefer interfaces" as a reflex: one is worth it where something
  actually substitutes for the dependency — a test, a dummy, a second
  implementation — and it costs a layer of indirection everywhere else. A
  concrete type only constructed and used within one package stays concrete.
- The inverse is the **escape hatch**: a method that hands out a concrete
  dependency, like a `Pool()`, `GetRiver()` or `GetClient()` accessor. Those
  exist for the few callers that genuinely need the concrete thing, usually
  tests. Adding one to avoid introducing an interface is the wrong trade; adding
  one because a test needs it is fine, and the comment should say so.
