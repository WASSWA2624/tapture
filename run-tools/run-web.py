"""Run the Tapture web application locally.

    python run-tools/run-web.py                 # open in Chrome
    python run-tools/run-web.py --server        # serve only, print the URL
    python run-tools/run-web.py --port 9090
    python run-tools/run-web.py --release       # run the optimised build
    python run-tools/run-web.py --keep-ports    # fail on a busy port instead

Running it again refreshes the app: whatever holds the web port is stopped
first, so the command is always safe to repeat. Stop it with Ctrl-C.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import (  # noqa: E402
    FRONTEND,
    BuildError,
    flutter,
    info,
    listeners_on,
    main,
    process_name,
    release_port,
    step,
    tool,
)

DEFAULT_PORT = 5173


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Tapture web app locally.")
    parser.add_argument(
        "--port", type=int, default=DEFAULT_PORT, help=f"port (default {DEFAULT_PORT})"
    )
    parser.add_argument(
        "--server",
        action="store_true",
        help="serve without opening a browser, so any device on the network can connect",
    )
    parser.add_argument(
        "--release", action="store_true", help="run the optimised build, not the debug build"
    )
    parser.add_argument(
        "--keep-ports",
        action="store_true",
        help="fail on a busy port instead of stopping whatever holds it",
    )
    return parser.parse_args()


def free_port(port: int, keep: bool) -> None:
    """Free the web port, so re-running this script always works.

    The dev server has to bind the port, and an earlier run of this script is
    usually what still holds it. Whatever is stopped is named in the output,
    so it is never a silent kill.
    """
    holders = listeners_on(port)
    if not holders:
        info(f"web port {port} is free")
        return
    if keep:
        names = ", ".join(f"{process_name(p)} (pid {p})" for p in sorted(holders))
        raise BuildError(
            f"web port {port} is held by {names} and --keep-ports was given."
        )
    release_port(port, "web")


def entry() -> None:
    args = parse_args()
    if not (FRONTEND / "web").is_dir():
        raise BuildError(
            "frontend/web is missing. Run: python run-tools/build-or-update-deploys/web.py"
        )
    tool("flutter")

    step("Freeing the port")
    free_port(args.port, args.keep_ports)

    device = "web-server" if args.server else "chrome"
    step(f"Starting the web app on {device} at http://localhost:{args.port}")
    command = [
        "run",
        "-d",
        device,
        "--web-port",
        str(args.port),
        # CanvasKit and the Flutter web SDK come from gstatic.com by default, so
        # the engine never boots on a machine that is offline or behind a proxy
        # that blocks it. The dev server already serves the SDK's own copy at
        # /canvaskit/; this makes the app load it from there.
        "--no-web-resources-cdn",
        "--release" if args.release else "--debug",
    ]
    if args.server:
        command += ["--web-hostname", "0.0.0.0"]
    flutter(command)


if __name__ == "__main__":
    main(entry)
