"""Run the Tapture backend locally under nodemon, so it reloads on every edit.

    python run-tools/run-backend.py                  # port 3000, reloads on change
    python run-tools/run-backend.py --port 4000
    python run-tools/run-backend.py --keep-ports     # fail on a busy port instead

Running it again refreshes the server: any previous instance is stopped first,
so the command is always safe to repeat. The backend and web ports are freed of
whatever holds them before the server starts. Stop it with Ctrl-C.

The backend itself is built in dev-plan phase 24; until `backend/package.json`
exists this script says what is missing rather than pretending to start.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import (  # noqa: E402
    BACKEND,
    REPO_ROOT,
    BuildError,
    info,
    is_alive,
    listeners_on,
    main,
    process_name,
    release_port,
    run,
    step,
    terminate,
    tool,
)

DEFAULT_BACKEND_PORT = 3000
DEFAULT_WEB_PORT = 5173

PID_FILE = REPO_ROOT / "run-tools" / ".run-backend.pid"

# Checked in order; the first that exists is the server entry point.
ENTRY_POINTS = (
    "src/server.ts",
    "src/index.ts",
    "src/main.ts",
    "src/server.js",
    "src/index.js",
)

# A TypeScript entry point needs a loader; the first one installed wins.
TS_RUNNERS = ("tsx", "ts-node")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the Tapture backend under nodemon."
    )
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.environ.get("BACKEND_PORT", DEFAULT_BACKEND_PORT)),
        help=f"backend port (default {DEFAULT_BACKEND_PORT}, or $BACKEND_PORT)",
    )
    parser.add_argument(
        "--web-port",
        type=int,
        default=DEFAULT_WEB_PORT,
        help=f"web port to free alongside it (default {DEFAULT_WEB_PORT})",
    )
    parser.add_argument(
        "--keep-ports",
        action="store_true",
        help="fail on a busy port instead of stopping whatever holds it",
    )
    return parser.parse_args()


def local_bin(name: str) -> str | None:
    """An executable installed into backend/node_modules/.bin."""
    base = BACKEND / "node_modules" / ".bin" / name
    for candidate in (base.with_suffix(".cmd"), base.with_suffix(".exe"), base):
        if candidate.is_file():
            return str(candidate)
    return None


def require_backend() -> None:
    manifest = BACKEND / "package.json"
    if not manifest.is_file():
        raise BuildError(
            "backend/package.json does not exist, so there is no server to run. "
            "The backend is built in dev-plan phase 24, starting at task 245."
        )
    try:
        json.loads(manifest.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise BuildError(f"backend/package.json is not valid JSON: {error}") from error


def resolve_nodemon() -> list[str]:
    installed = local_bin("nodemon")
    if installed:
        return [installed]
    if shutil.which("npx"):
        info("nodemon is not installed in backend/; using npx to fetch it")
        return [tool("npx"), "--yes", "nodemon"]
    raise BuildError(
        "nodemon is not available. Install it in the backend with "
        "`npm install --save-dev nodemon`, or put npx on PATH."
    )


def resolve_entry() -> tuple[str, str]:
    """The entry point relative to backend/, and the bare command that runs it.

    Both are returned unquoted and without a directory, because nodemon hands
    --exec to a shell: an absolute path containing a space (a Windows user
    profile, typically) is re-split by cmd.exe and the run fails. nodemon puts
    node_modules/.bin on PATH for the exec, so a bare name resolves there.
    """
    for relative in ENTRY_POINTS:
        entry = BACKEND / relative
        if entry.is_file():
            break
    else:
        looked = ", ".join(ENTRY_POINTS)
        raise BuildError(
            f"no server entry point in backend/ (looked for {looked}). "
            "Task 460 creates backend/src/server.ts."
        )

    relative_entry = entry.relative_to(BACKEND).as_posix()
    if entry.suffix == ".js":
        tool("node")  # fail here, with a clear message, rather than inside nodemon
        return relative_entry, "node"

    for runner in TS_RUNNERS:
        if local_bin(runner):
            return relative_entry, runner
    raise BuildError(
        f"{relative_entry} is TypeScript but neither "
        f"{' nor '.join(TS_RUNNERS)} is installed in backend/. "
        "Run: python run-tools/deploy/update-backend.py"
    )


def stop_previous() -> None:
    """Stop an earlier run of this script, so re-running refreshes the server."""
    if not PID_FILE.is_file():
        info("no previous instance recorded")
        return
    try:
        pid = int(PID_FILE.read_text(encoding="utf-8").strip())
    except (ValueError, OSError):
        PID_FILE.unlink(missing_ok=True)
        return
    if pid != os.getpid() and is_alive(pid):
        info(f"stopping the previous server: {process_name(pid)} (pid {pid})")
        terminate(pid)
    PID_FILE.unlink(missing_ok=True)


def free_ports(backend_port: int, web_port: int, keep: bool) -> None:
    """Free both ports.

    The backend port is required, so failing to free it stops the run. The web
    port is a convenience for whatever runs the app next; the server does not
    need it, so a port held by something unkillable is a warning, not a wall.
    """
    for port, label, required in (
        (backend_port, "backend", True),
        (web_port, "web", False),
    ):
        holders = listeners_on(port)
        if not holders:
            info(f"{label} port {port} is free")
            continue
        if keep:
            names = ", ".join(f"{process_name(p)} (pid {p})" for p in sorted(holders))
            message = f"{label} port {port} is held by {names} and --keep-ports was given."
            if required:
                raise BuildError(message)
            info(f"WARNING: {message}")
            continue
        try:
            release_port(port, label)
        except BuildError:
            if required:
                raise
            names = ", ".join(f"{process_name(p)} (pid {p})" for p in sorted(holders))
            info(f"WARNING: left {label} port {port} to {names}; the backend does not need it")


def entry_point() -> None:
    args = parse_args()
    require_backend()

    step("Refreshing any running instance")
    stop_previous()

    step("Freeing the ports")
    free_ports(args.port, args.web_port, args.keep_ports)

    entry, runner = resolve_entry()
    nodemon = resolve_nodemon()

    step(f"Starting the backend on http://localhost:{args.port}")
    info("nodemon watches backend/src; save a file and the server restarts")
    command = [
        *nodemon,
        "--watch",
        "src",
        "--ext",
        "ts,js,json,env",
        "--exec",
        f"{runner} {entry}",
    ]

    environment = dict(os.environ)
    environment["PORT"] = str(args.port)
    environment["BACKEND_PORT"] = str(args.port)

    PID_FILE.write_text(str(os.getpid()), encoding="utf-8")
    try:
        run(command, cwd=BACKEND, env=environment)
    finally:
        PID_FILE.unlink(missing_ok=True)


if __name__ == "__main__":
    main(entry_point)
