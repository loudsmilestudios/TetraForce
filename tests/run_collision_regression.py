"""Run Godot regression checks and fail on engine errors as well as assertions."""

import argparse
import os
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--rendering", action="store_true",
        help="Run rendered pixel checks using the Compatibility renderer (requires a display)",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    command = [
        os.environ.get("GODOT_BIN", "godot"),
        "--path",
        str(root),
    ]
    command += ["--rendering-method", "gl_compatibility"] if args.rendering else ["--headless"]
    suites = ("rendering_regression",) if args.rendering else (
        "collision_regression", "migration_regression", "rendering_regression",
    )
    failed = False
    for suite in suites:
        arguments = command + [f"res://tests/{suite}.tscn"]
        if args.rendering:
            arguments += ["--", "--require-rendering"]
        result = subprocess.run(
            arguments,
            cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, timeout=120, check=False,
        )
        print(result.stdout, end="")
        # Godot may continue after a signal callback raises a script error
        # and still exit with code 0. Don't silently pass that failure.
        failed |= result.returncode != 0 or "ERROR:" in result.stdout
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
