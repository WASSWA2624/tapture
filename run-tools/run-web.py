"""Run the Tapture web application locally.

    python run-tools/run-web.py                 # open in Chrome
    python run-tools/run-web.py --server        # serve only, print the URL
    python run-tools/run-web.py --port 9090
    python run-tools/run-web.py --release       # run the optimised build

Stop it with Ctrl-C.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import BuildError, FRONTEND, flutter, main, step, tool  # noqa: E402

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
    return parser.parse_args()


def entry() -> None:
    args = parse_args()
    if not (FRONTEND / "web").is_dir():
        raise BuildError(
            "frontend/web is missing. Run: python run-tools/build-or-update-deploys/web.py"
        )
    tool("flutter")

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
