"""Build the Tapture Android APK.

    python run-tools/deploy/build-android.py              # release APK
    python run-tools/deploy/build-android.py --debug
    python run-tools/deploy/build-android.py --split      # one APK per ABI

The APK is copied to run-tools/dist/android/.
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from common import (  # noqa: E402
    BuildError,
    DIST,
    FRONTEND,
    REPO_ROOT,
    flutter,
    gradle_env,
    info,
    main,
    reset_dir,
    step,
    tool,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build the Tapture Android APK.")
    parser.add_argument("--debug", action="store_true", help="build the debug APK")
    parser.add_argument(
        "--split", action="store_true", help="split into one APK per ABI"
    )
    return parser.parse_args()


def entry() -> None:
    args = parse_args()
    if not (FRONTEND / "android").is_dir():
        raise BuildError(
            "frontend/android is missing. Run: python run-tools/deploy/update-android.py"
        )
    tool("flutter")
    env = gradle_env()

    mode = "debug" if args.debug else "release"
    step(f"Building the {mode} APK")
    command = [
        "build",
        "apk",
        f"--{mode}",
        "--flavor",
        "prod",
        "--dart-define=FLAVOR=prod",
    ]
    if args.split:
        command.append("--split-per-abi")
    flutter(command, env=env)

    source = FRONTEND / "build" / "app" / "outputs" / "flutter-apk"
    # Match only this mode: an earlier build of the other mode leaves its APK
    # in the same directory, and a debug build must never ship as a release.
    produced = sorted(source.glob(f"*{mode}.apk"))
    if not produced:
        raise BuildError(f"the build reported success but no {mode} APK is in {source}")

    step("Collecting the artefacts")
    target = reset_dir(DIST / "android")
    for apk in produced:
        shutil.copy2(apk, target / apk.name)
        size_mb = apk.stat().st_size / (1024 * 1024)
        info(f"{apk.name}  ({size_mb:.1f} MB)")
    print(f"\nAPK ready in {target.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main(entry)
