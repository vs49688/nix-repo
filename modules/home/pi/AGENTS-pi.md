## Editing files

Change a file's text with the `edit` tool. The reason is not tidiness: every layer
between you and the bytes — shell quoting, the interpreter's string literal, the
regex engine, the replacement template — is another chance for a backslash to be
eaten, and each of them fails silently.

- `sed 's/c & d/e & f/'` gives `e c & d f`: in sed's replacement, `&` is the whole
  match. `&` is the column separator in every LaTeX table and `align`.
- `s.replace('\toprule', ...)` written inside a `python -c` string is a tab and
  `oprule`, which matches nothing, so the script reports success having changed
  nothing. `\t`, `\b` and `\v` are all LaTeX command prefixes, and a quoted heredoc
  keeps the shell off the backslashes but not the interpreter.
- `re.sub` reads `\1` as a backreference and needs every backslash in the
  replacement doubled — the same escaping, one layer further in.

`edit` passes each character once, as JSON, and matches the text you quote
unescaped. It refuses rather than writing when a match is stale, ambiguous or
overlapping, and its diff is in the transcript, where I read it.

A script is fine when you have a reason that beats `edit`: a deliberately
file-wide change, or a transformation that is a computation rather than a
replacement. Say what the reason is. Where the job is a plain replacement, prefer
`str.replace` with the count asserted over `re.sub` — a count that comes back
wrong is how the silent version announces itself.
