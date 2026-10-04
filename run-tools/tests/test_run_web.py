"""The web launcher opens Chrome only after Flutter finishes compiling."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


def _served_announcement():
    path = Path(__file__).resolve().parents[1] / "run-web.py"
    spec = importlib.util.spec_from_file_location("run_web", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.served_announcement


served_announcement = _served_announcement()


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


if __name__ == "__main__":
    unittest.main()
