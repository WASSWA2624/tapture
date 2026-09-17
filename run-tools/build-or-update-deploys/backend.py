"""Create or overwrite run-tools/dist/backend/tapture-backend.zip.

    python run-tools/build-or-update-deploys/backend.py
    python run-tools/build-or-update-deploys/backend.py --name tapture-backend-2026-09-09
"""

from __future__ import annotations

import argparse
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from common import (  # noqa: E402
    BACKEND,
    DIST,
    REPO_ROOT,
    BuildError,
    info,
    main,
    run,
    step,
    tool,
)

_OUT_DIR = DIST / "backend"
_CANONICAL_NAME = "tapture-backend"

# Never packaged: reinstallable, regenerated, or secret.
EXCLUDED_DIRS = {
    ".git",
    ".venv",
    "venv",
    "node_modules",
    "__pycache__",
    "dist",
    "build",
    "coverage",
    ".pytest_cache",
    ".mypy_cache",
    ".dart_tool",
}
EXCLUDED_SUFFIXES = {".pyc", ".log", ".keystore", ".jks", ".pem", ".key", ".p12"}
EXCLUDED_NAMES = {".env", ".env.local", "key.properties", "secrets.json"}

INSTALLERS: list[tuple[str, list[str]]] = [
    ("package.json", ["npm", "install"]),
    ("pubspec.yaml", ["dart", "pub", "get"]),
    ("requirements.txt", ["pip", "install", "-r", "requirements.txt"]),
    ("pyproject.toml", ["pip", "install", "-e", "."]),
    ("go.mod", ["go", "mod", "download"]),
]


def is_excluded(path: Path) -> bool:
    if any(part in EXCLUDED_DIRS for part in path.parts):
        return True
    if path.suffix in EXCLUDED_SUFFIXES:
        return True
    return path.name in EXCLUDED_NAMES or path.name.startswith(".env.")


def refresh_dependencies() -> None:
    step("Refreshing backend dependencies")
    if not BACKEND.is_dir():
        raise BuildError(f"{BACKEND} does not exist")
    for manifest, command in INSTALLERS:
        if (BACKEND / manifest).is_file():
            info(f"found {manifest}")
            run([tool(command[0]), *command[1:]], cwd=BACKEND)
            return
    looked_for = ", ".join(manifest for manifest, _ in INSTALLERS)
    info(f"no manifest in backend/ (looked for {looked_for}); packaging sources only")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create or update the Tapture backend archive."
    )
    parser.add_argument(
        "--name",
        default=_CANONICAL_NAME,
        help="archive name without the .zip suffix",
    )
    return parser.parse_args()


def entry() -> None:
    args = parse_args()
    archive = _OUT_DIR / f"{args.name}.zip"
    existed = archive.is_file()
    step(f"{'Updating' if existed else 'Creating'} {archive.relative_to(REPO_ROOT)}")

    refresh_dependencies()

    step("Selecting the backend sources")
    candidates = [p for p in sorted(BACKEND.rglob("*")) if p.is_file()]
    included = [p for p in candidates if not is_excluded(p.relative_to(BACKEND))]
    if not included:
        raise BuildError(
            "the backend has no files to package. It is built in dev-plan phase 24."
        )
    skipped = len(candidates) - len(included)
    info(f"{len(included)} files included, {skipped} excluded")
    source_files = [p for p in included if ".rules" not in p.relative_to(BACKEND).parts]
    if not source_files:
        info("WARNING: only rule documents found - the backend server is not built yet")

    step("Writing the archive")
    _OUT_DIR.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
        for path in included:
            bundle.write(path, path.relative_to(BACKEND).as_posix())

    size_mb = archive.stat().st_size / (1024 * 1024)
    info(f"{archive.name}  ({size_mb:.2f} MB)")
    print(f"\nBackend archive ready in {archive.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main(entry)
