#!/usr/bin/env python3
import json
import sys
from textwrap import dedent


def exit(err=True, why=None):
    file, code = (sys.stderr, 1) if err else (sys.stdout, 0)
    if why is not None:
        print(why, file=file)
    print(dedent(f"""\

    Usage: {sys.argv[0]} FILENAME

    Where FILENAME identifies a JSON file containing a simple object with only
    strings for keys and values. The program will join this object into a property
    in the correct format for supervisord's `environment=` value.
    """), file=file)
    raise SystemExit(code)


if __name__ == '__main__':
    try:
        filename = sys.argv[1]
    except IndexError:
        exit()
    if filename in ('-h', '--help'):
        exit(err=False)
    with open(filename) as f:
        try:
            env_obj = json.load(f)
        except json.decoder.JSONDecodeError:
            exit(why=f"ERROR: Could not parse JSON at {filename}")
    print(','.join(f'{k}={json.dumps(v)}' for k, v in env_obj.items()))
