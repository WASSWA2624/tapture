# run-tools

Python 3, from the repo root.

```bash
python run-tools/run-web.py
python run-tools/run-backend.py
python run-tools/build-or-update-deploys/android.py
python run-tools/build-or-update-deploys/web.py
python run-tools/build-or-update-deploys/backend.py
```

On Windows you can also run `run-tools\build-or-update-deploys\android.cmd` (same for web and backend). Do not invoke the `.py` file without `python` — Windows then uses pythonw and the build has no console.

The last three write `run-tools/dist/{android/app-release.apk,web/,backend/tapture-backend.zip}`, creating or overwriting. `--help` on each.
