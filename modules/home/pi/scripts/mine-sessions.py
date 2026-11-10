#!/usr/bin/env python3
"""Query the subagent briefs in the pi session store.

A `subagent` call carries its brief as structured data: one `task`, or one per
lane in a `tasks` array. So the population of briefs on some subject is a query,
not a mining job.
This is the query. It was written to converge on a subagent definition from the
briefs that preceded it, which is why the default filter is the
transcript-mining keyword set rather than nothing.

    mine-sessions --stats                 # the population, and which agents
    mine-sessions --list                  # one line per brief
    mine-sessions --dump /tmp/briefs      # each brief, in full
    mine-sessions --show 0e3554035        # one, by hash
    mine-sessions --kind steer --list     # what parents said *after* launching
    mine-sessions --all --list            # every brief ever written

Three kinds of call are told apart: `brief` (a `task`, a `workflow`, or the
lanes of a `tasks` array), `steer` (a message to a running child) and `other`
(status, resume, and so on). Only `brief` is a brief; the steers are worth
reading separately because they are where a parent corrects the brief it wrote.

`workflowScript` is a fourth form, historical: pi-subagents removed it in 0.77.0
in favour of `workflow: true` or a path, and its lanes live inside one JavaScript
string with no boundary this tool can see. Those calls are `other`.

The filter is a net, not a classifier: it looks for a named transcript plus a
mining verb, and it catches a few briefs that only mention one in passing. Use
`--list` and read them; do not quote the count as if it were exact.

Deduplicated by content, so the same parent text twice is one brief with a
count. Hash prefixes are stable, so a number written down keeps its answer.
"""

from __future__ import annotations

import argparse
import glob
import hashlib
import json
import os
import re
import sys

DEFAULT_ROOT = os.path.expanduser("~/.pi/agent/sessions")

# Names a transcript as an input, and asks for it to be read rather than
# merely mentioned. Deliberately generous: dropping a real brief costs more
# than listing a false one, because the false one is visible in --list.
DEFAULT_PATTERN = (
    r"(?:transcript|session\.jsonl|session\.html|PI_SESSION_FILE).*?"
    r"(?:\bmine|\bmining|extract|harvest|residue|archaeolog"
    r"|what (?:the owner|the human|did|was)|evidence gathering)"
    r"|(?:\bmine|\bmining|extract|harvest).*?"
    r"(?:transcript|session\.jsonl|session\.html)"
)


def records(args):
    """Yield (kind, agent, key, text) for each brief one call carries.

    A fleet call puts one brief per lane in `tasks`, so it is several briefs and
    each is yielded on its own; yielding the array whole would collapse ninety
    distinct briefs into one row with no text at all. Everything else is one.

    `workflowScript` is historical -- pi-subagents removed it in 0.77.0 in favour
    of `workflow: true` or a path -- and its lanes live inside one JavaScript
    string with no boundary this tool can see, so those calls are `other`.
    """
    lanes = args.get("tasks")
    if not isinstance(lanes, list):
        # The `subagent` tool takes `workflow: "parallel"` with the per-lane
        # briefs one level down in `args.tasks`; the store keeps the call as it
        # was made, so both shapes are in it.
        inner = args.get("args")
        lanes = inner.get("tasks") if isinstance(inner, dict) else None
    if isinstance(lanes, list) and lanes:
        for lane in lanes:
            if not isinstance(lane, dict):
                continue
            task = lane.get("task")
            if isinstance(task, str) and task.strip():
                agent = lane.get("agent")
                if not isinstance(agent, str) or not agent:
                    agent = "?"
                yield "brief", agent.split("/")[0].strip(), task.strip(), task.strip()
        return

    if "task" in args or "workflow" in args:
        kind = "brief"
    elif "steer" in args or "message" in args:
        kind = "steer"
    else:
        kind = "other"
    primary = next((args[k] for k in ("task", "workflow", "steer", "message")
                    if isinstance(args.get(k), str) and args[k].strip()), "")
    # The brief first, so `--show` opens with what the brief is about rather
    # than with the agent's name or the working directory.
    rest = [args[k] for k in args if isinstance(args[k], str) and args[k] is not primary]
    text = "\n".join([primary] + rest) if primary else "\n".join(rest)
    yield kind, "?", primary.strip(), text.strip()


def walk(path):
    """Yield (kind, agent, text) for every subagent tool call in one session."""
    with open(path, errors="ignore") as fh:
        for line in fh:
            if "subagent" not in line or len(line) < 120:
                continue
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            content = (entry.get("message") or {}).get("content")
            if not isinstance(content, list):
                continue
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") != "toolCall" or block.get("name") != "subagent":
                    continue
                args = block.get("arguments")
                if isinstance(args, str):
                    try:
                        args = json.loads(args)
                    except ValueError:
                        args = {"task": args}
                if not isinstance(args, dict):
                    continue
                default_agent = args.get("agent")
                if not isinstance(default_agent, str) or not default_agent:
                    default_agent = "workflow" if "workflow" in args else "?"
                for kind, agent, key, text in records(args):
                    if not text:
                        continue
                    if agent == "?":
                        agent = default_agent.split("/")[0].strip()
                    yield kind, agent, key, text


def main():
    ap = argparse.ArgumentParser(
        description="Query the subagent briefs in the pi session store.",
        epilog=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--root", default=DEFAULT_ROOT)
    ap.add_argument("--kind", choices=["brief", "steer", "other", "all"], default="brief")
    ap.add_argument("--all", action="store_true", help="skip the keyword filter")
    ap.add_argument("--pattern", help="override the keyword filter (a regex)")
    ap.add_argument("--stats", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--dump", metavar="DIR")
    ap.add_argument("--show", metavar="HASH")
    args = ap.parse_args()

    args.root = os.path.expanduser(args.root)
    if not os.path.isdir(args.root) and not os.path.isfile(args.root):
        sys.exit(f"no session store or session file at {args.root}")
    pattern = re.compile(args.pattern or DEFAULT_PATTERN, re.I | re.S)

    found = {}
    kinds = {}
    agents = {}
    sessions = 0
    # A root may be one session file, which is how a miner points this at the
    # single transcript it was given; a directory is a whole store or letters
    # tree, and returns every session under it.
    if os.path.isfile(args.root):
        paths = [args.root]
    else:
        paths = sorted(glob.glob(os.path.join(args.root, "**", "*.jsonl"), recursive=True))
    for path in paths:
        sessions += 1
        for kind, agent, key, text in walk(path):
            kinds[kind] = kinds.get(kind, 0) + 1
            if args.kind != "all" and kind != args.kind:
                continue
            if not args.all and not pattern.search(text):
                continue
            # The hash is of the primary text alone, so it is stable against
            # the other fields a call happens to carry.
            digest = hashlib.sha1((key or text).encode()).hexdigest()[:10]
            entry = found.setdefault(
                digest, {"text": text, "key": key or text, "agent": agent, "uses": 0})
            entry["uses"] += 1
            agents[agent] = agents.get(agent, 0) + 1

    if not found and not (args.show or args.dump):
        print("no calls matched; check --kind, --all and that the root holds a "
              "session (a .jsonl), not a rendered session.html", file=sys.stderr)

    if args.show:
        if args.show not in found:
            sys.exit(f"no {args.kind} matching {args.show!r}; try --all or --list")
        print(found[args.show]["text"])
        return

    if args.stats:
        print(f"sessions scanned : {sessions}")
        for kind in ("brief", "steer", "other"):
            print(f"  {kind:6s} records : {kinds.get(kind, 0)}")
        print(f"matched          : {len(found)} distinct, "
              f"{sum(e['uses'] for e in found.values())} instances")
        if agents:
            print("\nagent in the call:")
            for agent, count in sorted(agents.items(), key=lambda kv: (-kv[1], kv[0])):
                print(f"  {count:4d}  {agent}")
        return

    if args.list:
        for digest, entry in sorted(found.items(), key=lambda kv: -len(kv[1]["text"])):
            head = next((l for l in entry["key"].splitlines() if l.strip()), "")
            print(f"{digest}  {entry['agent']:12s} {len(entry['key']):5d}B  "
                  f"x{entry['uses']}  {head[:70]!r}")
        print(f"\n{len(found)} distinct", file=sys.stderr)
        return

    if args.dump:
        os.makedirs(args.dump, exist_ok=True)
        for digest, entry in found.items():
            with open(os.path.join(args.dump, digest + ".md"), "w", encoding="utf-8") as fh:
                fh.write(entry["text"])
        print(f"wrote {len(found)} to {args.dump}")
        return

    ap.print_help()


if __name__ == "__main__":
    main()
