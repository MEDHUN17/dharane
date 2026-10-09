#!/usr/bin/env python3
"""Validate a Compose file against the official compose-spec JSON schema (JSON Schema 2020-12).

Usage:  python3 validate-compose.py compose.yaml compose-spec.json
Get the schema (once): curl -O https://raw.githubusercontent.com/compose-spec/compose-spec/main/schema/compose-spec.json
Needs:  pip install jsonschema pyyaml   (jsonschema 4+ for Draft 2020-12)

This proves the keys and value types are valid Compose; it does not prove that an image works
with them. Use the 2020-12 validator: the older Draft 7 validator silently ignores the schema's
strictness keywords and would accept typos.
Exit status: 0 valid | 1 schema errors | 2 usage error
"""
import json
import sys

import jsonschema
import yaml


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    with open(argv[2], encoding="utf-8") as f:
        schema = json.load(f)
    with open(argv[1], encoding="utf-8") as f:
        doc = yaml.safe_load(f)
    validator = jsonschema.Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(doc), key=lambda e: list(e.path))
    for e in errors:
        print(f"{'/'.join(str(p) for p in e.path) or '<root>'}: {e.message[:200]}")
    print(f"{len(errors)} schema error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
