## Your sandbox

On Linux you run inside `ccbwrap`. Read the script that made this namespace —
`cat "$(command -v ccbwrap)"` — for the exact bind list. What it cannot tell you, and
what you need to know before you write anything:

- `$HOME` is a fresh tmpfs and only a named list of paths is bound into it. Writes
  outside that list *succeed* and are gone at exit: tool config under `~/.config`,
  `go install`, `npm -g`, `pip --user`, a scratch file in `~`. Anything that must
  survive goes in the working directory — the repository you are in — and reading it
  back within the session proves nothing about tomorrow.
- `/tmp` is a private tmpfs that dies with the process. Nothing large, nothing to
  keep; the host's `/tmp` is not what you are writing to. A gate that writes a work
  directory leaves it behind on every run, so sweep it as you integrate — it is RAM,
  and it is yours.
- Background processes die with the session (`--unshare-pid`, `--die-with-parent`).
- There is no `~/.ssh` and no signing key in here: `git commit` needs `--no-gpg-sign`.
- Memory is the host's, zram included. Nearly-full swap and a low `free` figure are
  normal, and `MemAvailable` is the number that matters — but you share that RAM with
  the machine, so a wide `nix build -j` can genuinely hurt it.
