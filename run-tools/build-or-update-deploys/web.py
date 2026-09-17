"""Create or overwrite run-tools/dist/web/.

    python run-tools/build-or-update-deploys/web.py
    python run-tools/build-or-update-deploys/web.py --base-href /tapture/
    python run-tools/build-or-update-deploys/web.py --debug
    python run-tools/build-or-update-deploys/web.py --clean
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
    info,
    main,
    reset_dir,
    step,
    tool,
)

_BUNDLE = DIST / "web"


def refresh_platform(clean: bool) -> None:
    if clean:
        step("Discarding build output")
        flutter(["clean"])

    step("Refreshing the web platform folder")
    flutter(["create", "--platforms=web", "--project-name", "tapture", "."])
    drop_regenerated_demo()
    apply_branding()

    step("Resolving dependencies")
    flutter(["pub", "get"])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create or update the Tapture web bundle."
    )
    parser.add_argument(
        "--base-href",
        default="/",
        help="path the site is served from (default /); must start and end with /",
    )
    parser.add_argument("--debug", action="store_true", help="build unoptimised")
    parser.add_argument(
        "--clean", action="store_true", help="flutter clean before refreshing"
    )
    return parser.parse_args()


def entry() -> None:
    args = parse_args()
    if not args.base_href.startswith("/") or not args.base_href.endswith("/"):
        raise BuildError("--base-href must start and end with '/', for example /tapture/")
    tool("flutter")

    marker = _BUNDLE / "index.html"
    existed = marker.is_file()
    step(f"{'Updating' if existed else 'Creating'} {_BUNDLE.relative_to(REPO_ROOT)}")

    refresh_platform(args.clean)

    step("Building the web bundle")
    flutter(
        [
            "build",
            "web",
            "--debug" if args.debug else "--release",
            "--base-href",
            args.base_href,
        ]
    )

    source = FRONTEND / "build" / "web"
    if not (source / "index.html").is_file():
        raise BuildError(f"the build reported success but {source}/index.html is missing")

    target = reset_dir(_BUNDLE)
    shutil.copytree(source, target, dirs_exist_ok=True)
    files = [p for p in target.rglob("*") if p.is_file()]
    total = sum(p.stat().st_size for p in files)
    info(f"{len(files)} files, {total / (1024 * 1024):.1f} MB")
    print(f"\nWeb bundle ready in {target.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main(entry)
