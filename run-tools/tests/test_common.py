"""Regressions for environment passed to the Android build's child JVMs."""

from __future__ import annotations

import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from common import gradle_env  # noqa: E402


class GradleEnvironmentTests(unittest.TestCase):
    def environment(self, existing: dict[str, str]) -> dict[str, str]:
        with (
            patch.dict(os.environ, existing, clear=True),
            patch("common._usable_jdk", return_value="D:/jdk"),
            patch("common._af_unix_scratch", return_value="D:/jtmp"),
            patch("common.info"),
        ):
            return gradle_env()

    def test_socket_option_reaches_launcher_and_spawned_daemon(self) -> None:
        env = self.environment({})
        option = "-Djdk.net.unixdomain.tmpdir=D:/jtmp"
        self.assertEqual(env["JAVA_TOOL_OPTIONS"], option)
        self.assertEqual(env["GRADLE_OPTS"], option)
        self.assertEqual(env["JAVA_HOME"], "D:/jdk")

    def test_preserves_unrelated_caller_options_and_environment(self) -> None:
        env = self.environment(
            {
                "JAVA_TOOL_OPTIONS": "-Xms64m",
                "GRADLE_OPTS": "-Duser.country=UG",
                "PATH": "tools",
            }
        )
        self.assertEqual(
            env["JAVA_TOOL_OPTIONS"], "-Xms64m -Djdk.net.unixdomain.tmpdir=D:/jtmp"
        )
        self.assertEqual(
            env["GRADLE_OPTS"], "-Duser.country=UG -Djdk.net.unixdomain.tmpdir=D:/jtmp"
        )
        self.assertEqual(env["PATH"], "tools")

    def test_repeated_setup_does_not_duplicate_the_option(self) -> None:
        env = self.environment({})
        self.assertEqual(self.environment(env), env)


if __name__ == "__main__":
    unittest.main()
