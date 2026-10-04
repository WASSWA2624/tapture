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
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import (  # noqa: E402
    FRONTEND,
    BuildError,
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


def served_announcement(text: str) -> bool:
    """True when Flutter has finished the compile and is serving the app.

    `flutter_bootstrap.js` and even the compiled entry are available while the
    first debug compile is still running. A browser that loads then keeps a
    failed module script, so the tab stays blank until a refresh. Flutter
    prints this line only after that compile.
    """
    return "is being served at" in text


def _open_chrome(url: str) -> None:
    """Open [url] in a Chrome window, without a remote-debugging port.

    `flutter run -d chrome` adds that port, and current Chrome never answers
    Debugger.enable. A normal window still loads the dev server, which is what
    hot reload attaches to.
    """
    info(f"opening {url} in Chrome")
    if sys.platform == "win32":
        # The first quoted argument of `start` is a window title. This opens a
        # tab in the Chrome the operator already runs, which is the window that
        # reaches the dev server. A separate profile never completes that step.
        subprocess.run(
            ["cmd", "/c", "start", "", "chrome", url],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return
    import webbrowser

    webbrowser.open(url)


def _run_flutter(command: list[str], port: int, open_browser: bool) -> None:
    """Stream Flutter and open Chrome only after the app is being served."""
    executable = tool("flutter")
    info(
        f"$ {executable} {' '.join(command)}   (in frontend)"
    )
    process = subprocess.Popen(
        [executable, *command],
        cwd=str(FRONTEND),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    opened = False
    window = ""
    try:
        assert process.stdout is not None
        while True:
            chunk = process.stdout.read(256)
            if not chunk:
                break
            sys.stdout.write(chunk)
            sys.stdout.flush()
            if open_browser and not opened:
                window = (window + chunk)[-400:]
                if served_announcement(window):
                    opened = True
                    _open_chrome(f"http://localhost:{port}")
    except KeyboardInterrupt:
        process.terminate()
        process.wait()
        raise
    code = process.wait()
    if code != 0:
        raise BuildError(f"command failed ({code}): {executable} {' '.join(command)}")


def entry() -> None:
    args = parse_args()
    if not (FRONTEND / "web").is_dir():
        raise BuildError(
            "frontend/web is missing. Run: python run-tools/build-or-update-deploys/web.py"
        )
    tool("flutter")

    step("Freeing the port")
    free_port(args.port, args.keep_ports)

    # `-d chrome` drives the page through Chrome's remote debugger. On this
    # Windows/Chrome pair Debugger.enable never returns, so that launch exits
    # before the app is usable. The dev server still hot-reloads; Chrome is
    # opened when Flutter reports that the app is being served.
    where = "this machine" if args.server else "Chrome"
    step(f"Starting the web app for {where} at http://localhost:{args.port}")
    command = [
        "run",
        "-d",
        "web-server",
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
    _run_flutter(command, args.port, open_browser=not args.server)


if __name__ == "__main__":
    main(entry)
