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
- The Wayland and PipeWire sockets are bound; X11 and the session bus are not, so
  `DISPLAY` and `DBUS_SESSION_BUS_ADDRESS` are unset on purpose. An app that needs
  either will fail rather than misbehave, and the fix is to change the sandbox, not to
  go looking for a bug in the app.
- Background processes die with the session (`--unshare-pid`, `--die-with-parent`), so
  a long build runs alongside your work but not past the end of it.
- There is no `~/.ssh` and no signing key in here: commits are unsigned and stay that
  way.
- Memory is the host's, zram included. Nearly-full swap and a low `free` figure are
  normal, and `MemAvailable` is the number that matters — but you share that RAM with
  the machine, so a wide `nix build -j` can genuinely hurt it.
