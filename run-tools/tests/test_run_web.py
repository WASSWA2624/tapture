"""The web launcher opens Chrome only after Flutter finishes compiling."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


def _run_web():
    path = Path(__file__).resolve().parents[1] / "run-web.py"
    spec = importlib.util.spec_from_file_location("run_web", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


run_web = _run_web()
served_announcement = run_web.served_announcement


class ServedAnnouncementTests(unittest.TestCase):
    def test_compile_progress_does_not_open_the_browser(self) -> None:
        self.assertFalse(
            served_announcement(
                "Waiting for connection from debug service on Web Server..."
            )
        )
        self.assertFalse(served_announcement("Launching lib\\main.dart on Web Server"))

    def test_served_line_opens_the_browser(self) -> None:
        self.assertTrue(
            served_announcement(
                "lib\\main.dart is being served at http://localhost:5173"
            )
        )


class IsolationTests(unittest.TestCase):
    """--isolated serves COOP and COEP, so speech can use the threaded engine."""

    def test_default_sends_no_isolation_headers(self) -> None:
        self.assertEqual(run_web.isolation_arguments(False), [])

    def test_isolated_sends_coop_and_credentialless_coep(self) -> None:
        self.assertEqual(
            run_web.isolation_arguments(True),
            [
                "--web-header=Cross-Origin-Opener-Policy=same-origin",
                "--web-header=Cross-Origin-Embedder-Policy=credentialless",
            ],
        )


if __name__ == "__main__":
    unittest.main()
