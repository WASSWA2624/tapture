"""Shared helpers for the Tapture run and build-or-update scripts.

Every script in `run-tools/` resolves paths through here so that the repository
can be moved or cloned anywhere without editing a script.
"""

from __future__ import annotations

import contextlib
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
FRONTEND = REPO_ROOT / "frontend"
BACKEND = REPO_ROOT / "backend"
DIST = REPO_ROOT / "run-tools" / "dist"


class BuildError(RuntimeError):
    """A step failed; the message is already user-facing."""


def info(message: str) -> None:
    print(f"  {message}", flush=True)


def step(message: str) -> None:
    print(f"\n==> {message}", flush=True)


def tool(name: str) -> str:
    """Absolute path to an executable on PATH, or a clear failure."""
    found = shutil.which(name)
    if found is None:
        raise BuildError(
            f"{name!r} is not on PATH. Install it, or open a shell where it is."
        )
    return found


def _usable_jdk() -> str | None:
    """A JDK_HOME whose java executable actually exists.

    JAVA_HOME on a developer machine often points at a JDK that has since been
    upgraded or removed; Gradle then fails with a misleading error.
    """
    candidates: list[Path] = []
    env_home = os.environ.get("JAVA_HOME")
    if env_home:
        candidates.append(Path(env_home))
    java_on_path = shutil.which("java")
    if java_on_path:
        candidates.append(Path(java_on_path).resolve().parent.parent)
    for base in (
        Path("C:/Program Files/Microsoft"),
        Path("C:/Program Files/Eclipse Adoptium"),
        Path("C:/Program Files/Java"),
        Path("C:/Program Files/Android/Android Studio/jbr"),
    ):
        if base.is_dir():
            candidates.extend(sorted(base.glob("jdk*"), reverse=True))
            if (base / "bin").is_dir():
                candidates.append(base)
    for candidate in candidates:
        launcher = candidate / "bin" / ("java.exe" if os.name == "nt" else "java")
        if launcher.is_file():
            return str(candidate)
    return None


def _af_unix_scratch() -> str | None:
    """A socket directory whose path has no spaces.

    The JVM opens an AF_UNIX socket under `java.io.tmpdir` for every NIO
    selector. Where that path contains a space or an 8.3 short name, the
    connect fails and Gradle reports "Unable to establish loopback connection".
    """
    default = Path(tempfile.gettempdir())
    if " " not in str(default) and "~" not in str(default):
        return None
    scratch = Path(REPO_ROOT.anchor or "/") / "jtmp"
    try:
        scratch.mkdir(parents=True, exist_ok=True)
    except OSError:
        return None
    return str(scratch)


def gradle_env() -> dict[str, str]:
    """Environment for a Gradle-backed build, with known JDK traps corrected."""
    env = dict(os.environ)
    jdk = _usable_jdk()
    if jdk and env.get("JAVA_HOME") != jdk:
        info(f"JAVA_HOME -> {jdk}")
        env["JAVA_HOME"] = jdk
    scratch = _af_unix_scratch()
    if scratch:
        info(f"AF_UNIX socket dir -> {scratch}")
        option = f"-Djdk.net.unixdomain.tmpdir={scratch}"
        existing = env.get("JAVA_TOOL_OPTIONS", "")
        if option not in existing:
            env["JAVA_TOOL_OPTIONS"] = f"{existing} {option}".strip()
    return env


def run(
    args: list[str],
    cwd: Path,
    env: dict[str, str] | None = None,
    check: bool = True,
) -> int:
    """Run a command, streaming its output, and fail loudly."""
    printable = " ".join(args)
    info(f"$ {printable}   (in {cwd.relative_to(REPO_ROOT) if cwd != REPO_ROOT else '.'})")
    completed = subprocess.run(args, cwd=str(cwd), env=env)
    if check and completed.returncode != 0:
        raise BuildError(f"command failed ({completed.returncode}): {printable}")
    return completed.returncode


def flutter(args: list[str], env: dict[str, str] | None = None) -> None:
    run([tool("flutter"), *args], cwd=FRONTEND, env=env)


def drop_regenerated_demo() -> None:
    """Remove the counter demo `flutter create` restores on every run.

    The template rewrites test/widget_test.dart whenever a platform is
    regenerated. It tests a widget this app does not have, so it fails the
    suite the moment it reappears.
    """
    demo = FRONTEND / "test" / "widget_test.dart"
    if demo.is_file():
        demo.unlink()
        info(f"removed regenerated demo test {demo.name}")


def apply_branding() -> None:
    """Stamp branding/ masters onto launcher icons, splash and favicons.

    `flutter create` restores the template Flutter logo; this puts Tapture
    back. Pillow must be installed for the rasters.
    """
    script = REPO_ROOT / "branding" / "tool" / "apply.py"
    run([sys.executable, str(script)], cwd=REPO_ROOT)


def reset_dir(path: Path) -> Path:
    """An empty directory at `path`, creating or clearing it."""
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


def main(entry) -> None:
    """Run a script entry point, turning BuildError into a clean exit."""
    try:
        entry()
    except BuildError as error:
        print(f"\nFAILED: {error}", file=sys.stderr)
        raise SystemExit(1) from error
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        raise SystemExit(130) from None


# --- ports -----------------------------------------------------------------

# PIDs that must never be signalled: the Windows idle and System processes.
_PROTECTED_PIDS = {0, 4}


def _listeners_windows(port: int) -> set[int]:
    output = subprocess.run(
        ["netstat", "-ano", "-p", "TCP"], capture_output=True, text=True
    ).stdout
    pids: set[int] = set()
    for line in output.splitlines():
        parts = line.split()
        if len(parts) < 5 or parts[3].upper() != "LISTENING":
            continue
        # "0.0.0.0:3000" and "[::]:3000" both end in the port.
        if parts[1].rsplit(":", 1)[-1] == str(port):
            with contextlib.suppress(ValueError):
                pids.add(int(parts[4]))
    return pids


def _listeners_posix(port: int) -> set[int]:
    if shutil.which("lsof"):
        result = subprocess.run(
            ["lsof", "-nP", f"-iTCP:{port}", "-sTCP:LISTEN", "-t"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            return {int(line) for line in result.stdout.split() if line.isdigit()}
    if shutil.which("ss"):
        result = subprocess.run(
            ["ss", "-lptnH", f"sport = :{port}"], capture_output=True, text=True
        )
        if result.returncode == 0:
            # Only pid=N is a process id; the rest of the line holds ports and inodes.
            return {int(pid) for pid in re.findall(r"pid=(\d+)", result.stdout)}
    return set()


def listeners_on(port: int) -> set[int]:
    """PIDs listening on `port`, never including this process or its parent."""
    found = _listeners_windows(port) if os.name == "nt" else _listeners_posix(port)
    mine = {os.getpid(), os.getppid()}
    return {pid for pid in found if pid not in _PROTECTED_PIDS and pid not in mine}


def process_name(pid: int) -> str:
    if os.name == "nt":
        result = subprocess.run(
            ["tasklist", "/FI", f"PID eq {pid}", "/NH", "/FO", "CSV"],
            capture_output=True,
            text=True,
        )
        match = re.match(r'"([^"]+)"', result.stdout.strip())
        return match.group(1) if match else "unknown"
    result = subprocess.run(
        ["ps", "-p", str(pid), "-o", "comm="], capture_output=True, text=True
    )
    return result.stdout.strip() or "unknown"


def is_alive(pid: int) -> bool:
    if os.name == "nt":
        result = subprocess.run(
            ["tasklist", "/FI", f"PID eq {pid}", "/NH", "/FO", "CSV"],
            capture_output=True,
            text=True,
        )
        return f'"{pid}"' in result.stdout
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def _wait_gone(pid: int, seconds: float = 2.0) -> bool:
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if not is_alive(pid):
            return True
        time.sleep(0.1)
    return not is_alive(pid)


def terminate(pid: int) -> bool:
    """Stop one process and its children. Returns whether it actually died."""
    if pid in _PROTECTED_PIDS:
        return False
    if os.name == "nt":
        subprocess.run(
            ["taskkill", "/PID", str(pid), "/T", "/F"], capture_output=True, text=True
        )
        return _wait_gone(pid)
    with contextlib.suppress(ProcessLookupError, PermissionError):
        os.kill(pid, signal.SIGTERM)
    if _wait_gone(pid):
        return True
    with contextlib.suppress(ProcessLookupError, PermissionError):
        os.kill(pid, signal.SIGKILL)
    return _wait_gone(pid)


def release_port(port: int, label: str) -> None:
    """Free `port` by stopping whatever is listening on it.

    The caller has asked for this port, so anything already holding it is
    stopped -- named in the output, so it is never a silent kill.
    """
    if port < 1024:
        raise BuildError(
            f"refusing to release {label} port {port}: ports below 1024 belong to "
            "system services. Choose an application port instead."
        )
    holders = listeners_on(port)
    if not holders:
        return
    for pid in sorted(holders):
        name = process_name(pid)
        info(f"releasing {label} port {port}: stopping {name} (pid {pid})")
        if not terminate(pid):
            raise BuildError(
                f"could not stop {name} (pid {pid}) holding {label} port {port}. "
                "It may belong to another user; stop it yourself or pass a different port."
            )
    remaining = listeners_on(port)
    if remaining:
        raise BuildError(f"port {port} is still held by {sorted(remaining)}")
