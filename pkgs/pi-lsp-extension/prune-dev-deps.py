#!/usr/bin/env python3
"""Rewrite the upstream manifest and lockfile down to the runtime closure.

Upstream keeps the host-provided Pi packages and its build tools in
devDependencies. Their workspace entries land in package-lock.json without
integrity hashes, which makes prefetch-npm-deps abort, and none of them are
needed here: dist/ is checked in and Pi supplies the peer packages itself.
"""

import json
import sys


def main(paths):
    for path in paths:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)

        if path.endswith("package-lock.json"):
            data["packages"] = {
                name: entry
                for name, entry in data["packages"].items()
                if not entry.get("dev")
            }
            data["packages"][""].pop("devDependencies", None)
        else:
            data.pop("devDependencies", None)

        with open(path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
            fh.write("\n")


if __name__ == "__main__":
    main(sys.argv[1:])
