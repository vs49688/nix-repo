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

## Cloning Repositories

Agents may lack the user's SSH keys (e.g. in a sandbox), and HTTPS clones
may be rewritten to SSH by `url.<host>.insteadOf` rules in the user's git
config. Check the effective rewrites first:

    git config --show-origin --get-regexp '^url\.'

If a rule covers the URL being cloned, or a plain clone fails with an
access-rights error, bypass the global config for that command:

    GIT_CONFIG_GLOBAL=/dev/null git clone https://host/owner/repo

Do the same for `git fetch`/`git pull` in https-origin repos.
`GIT_CONFIG_GLOBAL=/dev/null` also drops identity/signing — do not commit
with it set. `git -c url.<base>.insteadOf=...` overrides do **not** beat
the file-level rule.

## Pushing

Never push (`git push`) to any remote — not even as a test. Do not
debug push failures or try to work around the SSH key problem (including
with the Forgejo token, which is for the Forgejo API only, never for git
pushes).

Pushing is the user's job. Agent commits are unsigned (`--no-gpg-sign`),
and the user re-signs every commit with a manual pass / forced rebase,
so anything an agent pushed would be published unsigned — and it would
fail anyway, since sandboxed agents have no SSH keys. Finish with local
commits and a clear handoff; leave pushing to the user.

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

Your context is sacred — don't blow it on menial tasks that a subagent
can do with minimal context, e.g. provenance investigations, research.
Subagents may be available; take advantage of them.

- Delegate: self-contained tasks with checkable outcomes and a small
  context footprint — provenance investigations, research, enumerating
  registries or tables, generating testdata, running known command
  matrices. Write a complete task spec (paths, constraints, expected
  output, commit rules) so the subagent needs no back-and-forth.
- Keep in the parent: design decisions, anything needing the user's
  agreement or taste, cross-cutting refactors. The subagent knows only
  what the task spec provides (fresh or inherited context) — never
  assume it knows anything the spec doesn't say.
- Verify before accepting: review the diff and run the build/tests the
  task claims pass. One writer per working tree — the parent reviews and
  applies fixes.

## Go

- Never invoke `gofmt` directly — use `go fmt`, the module-aware wrapper
  and canonical invocation (same bytes, but the command is the rule):
  `go fmt ./...` for the whole tree, `go fmt ./<file>` to format a single
  file after an edit.
- Greenfield repos: checkpoint commits may freely include vendor churn.
- Mature repos: keep dependency *updates* in their own commit — `go get -u ./... && go mod tidy && go mod vendor`, commit as `vendor: update`, separate from any code changes.
- Mature repos: a *new* dependency goes in the same commit as the code that first imports it. `go mod vendor` only vendors packages that are actually imported, so a dependency added without its consumer either can't be vendored or gets dropped by the next vendor operation.
