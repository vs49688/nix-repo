# Agent Guidance — Global Conventions

## Commit Style

Use a style similar to the Linux Kernel and FFmpeg. **Do not use Conventional Commits** (`feat:`, `fix:`, `chore:`, `docs:`, `style:`, `refactor:`, `test:`, `ci:`).

Format:
```
component: short description

Optional longer description if the change warrants it.
```

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
persistence: add ExcludeNSFW filter to V4SearchResourceOptions     ← interface

backend/graph: respect user NSFW preference in resource search     ← caller

Apply ExcludeNSFW filter in searchResources() and getRelatedResources()
based on the user's content.show_nsfw property. Anonymous users and
users with show_nsfw=false (default) never see NSFW resources.
```

Multiple packages sharing the same logical change can go in one commit with a compound prefix:

```
backend/graph/{blog,comment,resource}: validate urls in markdown content
```

### Interface Changes That Break Compilation

When an interface change would otherwise break the build, it's acceptable to fix or stub the immediate downstream callers in the same commit. If the downstream changes are obvious (e.g., a new parameter that must be passed everywhere), the subject can just name the interface change — no need to enumerate every file:

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
persistence: add includeArchived parameter to V4ListResources

Add includeArchived parameter to V4ListResources and update
relevant downstreams.
```

Do not add a body that merely restates what the subject already says:

```
backend/graph: decouple Revision types from persistence structs
```

not

```
backend/graph: decouple Revision types from persistence structs

Remove model bindings, add converters, and update all callers
to use the new types.
```

This avoids a commit that doesn't compile on its own. More involved caller work — new behaviour, feature wiring, logic changes — still goes in a separate commit.

## Contributing

- Rebase branches against current master before submitting PRs.
- Merge commits are not accepted except at maintainer discretion (e.g., octopus merges, or cases where preserving branch history has clear value).
- When in doubt, rebase.

## General

- Use proper parsers for structured formats (HTML, URLs, etc.), not regex.
- Generated code should be clearly separated and never hand-edited.
- When a project lacks a formal test suite, do not attempt to add or run tests unless explicitly instructed.
- Run project-level formatters before committing — check the project's own `AGENTS.md` for specifics.
