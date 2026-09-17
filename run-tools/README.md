# run-tools

Python 3, from the repo root. No extra packages.

```bash
python run-tools/run-web.py                                 # :5173, Chrome
python run-tools/run-backend.py                             # :3000
python run-tools/build-or-update-deploys/android.py         # dist/android/app-release.apk
python run-tools/build-or-update-deploys/web.py             # dist/web/
python run-tools/build-or-update-deploys/backend.py         # dist/backend/tapture-backend.zip
```

The last three create the artefact if missing and overwrite it if present. `--help` on each.
