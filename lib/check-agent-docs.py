#!/usr/bin/env python3
"""Coherence checks for the agent configuration under modules/home/pi.

Run by the `agent-docs` flake check. Prints every problem and exits non-zero if
there is one.

  1. Every skill's frontmatter is valid: a closed --- block, a name matching the
     Agent Skills pattern, and a non-empty description within the length limit.
     An invalid name or a missing description does not warn at load time -- the
     skill is simply never loaded -- so this is the only signal it gets.
  2. The frontmatter name matches the directory name.
  3. Every skill directory is mounted in default.nix, and every skills mount
     resolves to a directory containing SKILL.md. Installing a skill is two edits
     in two files, and missing the second leaves it in git and nowhere on disk.
  4. Every `<name>` skill reference in AGENTS.md names a skill that exists.

What it deliberately does not check is whether a rule is in the right file --
AGENTS.md against a skill. That is a judgement about content, and a text-matcher
for it would report false confidence rather than catch anything.
"""

from __future__ import annotations

import os
import re
import sys

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
DESC_MAX = 1024
MOUNT_RE = re.compile(
    r'"\.pi/agent/skills/(?P<name>[^"]+)"\s*\.source\s*=\s*\./(?P<src>[A-Za-z0-9_./-]+)'
)
REF_RE = re.compile(r"`([a-z0-9][a-z0-9-]*)`\s+skill\b")


def read_frontmatter(path):
    """Return (fields, error) for a SKILL.md's frontmatter block."""
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    if not lines or lines[0].strip() != "---":
        return None, "no frontmatter block"
    try:
        end = lines.index("---", 1)
    except ValueError:
        return None, "frontmatter block is never closed"
    fields = {}
    for raw in lines[1:end]:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if ":" not in raw:
            return None, f"not a key: value line: {raw!r}"
        key, value = raw.split(":", 1)
        fields[key.strip()] = value.strip()
    return fields, None


def main(root):
    problems = []
    agents = os.path.join(root, "AGENTS.md")
    default_nix = os.path.join(root, "default.nix")

    skills = {}
    for entry in sorted(os.listdir(root)):
        skill_md = os.path.join(root, entry, "SKILL.md")
        if not os.path.isfile(skill_md):
            continue
        skills[entry] = skill_md

        fields, err = read_frontmatter(skill_md)
        if err:
            problems.append(f"{entry}/SKILL.md: {err}")
            continue

        name = fields.get("name", "")
        desc = fields.get("description", "")

        if not name:
            problems.append(f"{entry}/SKILL.md: frontmatter has no name")
        elif not NAME_RE.match(name):
            problems.append(
                f"{entry}/SKILL.md: name {name!r} is not lowercase-with-hyphens"
            )
        elif name != entry:
            problems.append(
                f"{entry}/SKILL.md: name {name!r} does not match the directory name"
            )

        if not desc:
            problems.append(
                f"{entry}/SKILL.md: frontmatter has no description, so it will never load"
            )
        elif len(desc) > DESC_MAX:
            problems.append(
                f"{entry}/SKILL.md: description is {len(desc)} chars, limit is {DESC_MAX}"
            )

    with open(default_nix, encoding="utf-8") as fh:
        nix = fh.read()

    mounted = {}
    for match in MOUNT_RE.finditer(nix):
        name, src = match.group("name"), match.group("src")
        mounted[name] = src
        if not os.path.isfile(os.path.join(root, src, "SKILL.md")):
            problems.append(f"default.nix: skills/{name} -> ./{src} has no SKILL.md")

    for name in sorted(set(skills) - set(mounted)):
        problems.append(f"default.nix: {name}/SKILL.md exists but nothing mounts it")
    for name in sorted(set(mounted) - set(skills)):
        problems.append(f"default.nix: skills/{name} is mounted but has no SKILL.md")

    if not os.path.isfile(agents):
        problems.append("AGENTS.md: missing")
        return problems

    with open(agents, encoding="utf-8") as fh:
        text = fh.read()
    for ref in sorted(set(REF_RE.findall(text))):
        if ref not in skills:
            problems.append(f"AGENTS.md: refers to the {ref!r} skill, which does not exist")

    return problems


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: check-agent-docs.py <path to modules/home/pi>")
    found = main(sys.argv[1])
    for problem in found:
        print(f"error: {problem}", file=sys.stderr)
    if found:
        sys.exit(f"{len(found)} problem(s) in the agent configuration")
    print("agent docs: ok")
