"""Create or overwrite run-tools/dist/android/app-release.apk.

    python run-tools/build-or-update-deploys/android.py
    python run-tools/build-or-update-deploys/android.py --debug
    python run-tools/build-or-update-deploys/android.py --split
    python run-tools/build-or-update-deploys/android.py --clean
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from common import (  # noqa: E402
    DIST,
    FRONTEND,
    REPO_ROOT,
    BuildError,
    apply_branding,
    drop_regenerated_demo,
    flutter,
    gradle_env,
    info,
    main,
    step,
    tool,
)

_APK_DIR = DIST / "android"
_CANONICAL = _APK_DIR / "app-release.apk"


def drop_mismatched_android_package() -> None:
    """Remove the template package `flutter create` adds beside `com.tapture.app`.

    `--project-name tapture` matches pubspec.yaml, so the template writes
    `com.tapture.tapture`. The application id from task 019 is `com.tapture.app`.
    """
    kotlin = FRONTEND / "android" / "app" / "src" / "main" / "kotlin"
    expected = kotlin / "com" / "tapture" / "app"
    stray = kotlin / "com" / "tapture" / "tapture"
    if expected.is_dir() and stray.is_dir():
        shutil.rmtree(stray)
        info("removed template package com.tapture.tapture")


def refresh_platform(clean: bool, env: dict[str, str]) -> None:
    android_dir = FRONTEND / "android"
    recreate = clean or not android_dir.is_dir()
    if clean:
        step("Discarding build output")
        flutter(["clean"], env=env)
    if recreate:
        step("Refreshing the Android platform folder")
        flutter(
            [
                "create",
                "--platforms=android",
                "--org",
                "com.tapture",
                "--project-name",
                "tapture",
                ".",
            ],
            env=env,
        )
        drop_regenerated_demo()
        drop_mismatched_android_package()
        apply_branding()

    step("Resolving dependencies")
    flutter(["pub", "get"], env=env)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create or update the Tapture Android APK."
    )
    parser.add_argument("--debug", action="store_true", help="build the debug APK")
    parser.add_argument(
        "--split", action="store_true", help="split into one APK per ABI"
    )
    parser.add_argument(
        "--clean", action="store_true", help="flutter clean before refreshing"
    )
    return parser.parse_args()


def entry() -> None:
    args = parse_args()
    tool("flutter")
    env = gradle_env()
    mode = "debug" if args.debug else "release"
    dest = _APK_DIR / f"app-{mode}.apk"
    existed = dest.is_file()
    step(f"{'Updating' if existed else 'Creating'} {dest.relative_to(REPO_ROOT)}")
    info("A release APK often sits on Gradle for several minutes with no new lines.")

    refresh_platform(args.clean, env)

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
    produced = sorted(source.glob(f"*{mode}.apk"))
    if not produced:
        raise BuildError(f"the build reported success but no {mode} APK is in {source}")

    _APK_DIR.mkdir(parents=True, exist_ok=True)
    if args.split:
        for apk in produced:
            shutil.copy2(apk, _APK_DIR / apk.name)
            size_mb = apk.stat().st_size / (1024 * 1024)
            info(f"{apk.name}  ({size_mb:.1f} MB)")
    else:
        preferred = source / f"app-prod-{mode}.apk"
        chosen = preferred if preferred.is_file() else produced[0]
        shutil.copy2(chosen, dest)
        size_mb = dest.stat().st_size / (1024 * 1024)
        info(f"{dest.name}  ({size_mb:.1f} MB)")
    print(f"\nAPK ready in {dest.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main(entry)
