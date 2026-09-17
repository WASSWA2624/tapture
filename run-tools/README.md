# run-tools

Plain Python 3. No extra packages. Safe to run twice. Paths resolve from the repo root.

```bash
python run-tools/run-web.py                 # web on :5173, opens Chrome
python run-tools/run-web.py --server        # bind 0.0.0.0
python run-tools/run-backend.py             # backend on :3000, nodemon reload
```

`--port` / `$BACKEND_PORT` change the backend port; `--web-port` changes the web one. Ports below 1024 are refused.
Busy ports are freed first (`--keep-ports` fails instead). The web port is optional; a held backend port is not.
Until `backend/package.json` exists, `run-backend.py` says so and exits.

| Artefact    | Build                                        | Update                                        |
| :---------- | :------------------------------------------- | :-------------------------------------------- |
| Android APK | `python run-tools/deploy/build-android.py` | `python run-tools/deploy/update-android.py` |
| Web bundle  | `python run-tools/deploy/build-web.py`     | `python run-tools/deploy/update-web.py`     |
| Backend zip | `python run-tools/deploy/build-backend.py` | `python run-tools/deploy/update-backend.py` |

Output: `run-tools/dist/{android,web,backend}/` (gitignored). `update-*` after a `pubspec.yaml` or Flutter change.
Flags: `--debug` `--split` (Android), `--base-href` (web), `--name` (backend), `--clean` (update). `--help` on each.

`common.py` repairs a stale `JAVA_HOME` and a space-in-temp JVM loopback failure for Android only; neither is written into the repo.

These scripts do not replace `dart run tool/verify.dart`. Signing and CI are tasks 278 and 277.
