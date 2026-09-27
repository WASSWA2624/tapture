# Release build

One command produces the signed, shrunk, split-ABI release:

```bash
flutter build apk --release --flavor prod --split-per-abi
```

The same command is the release step in `.github/workflows/ci.yml`. The same commit and the same key produce the same artefact set.

## Where the key lives

The keystore stays outside the repository. Copy `android/key.properties.example` to `android/key.properties` on a release machine, or set these environment variables:

- `TAPTURE_KEYSTORE` — path to the keystore file
- `TAPTURE_STORE_PASSWORD`
- `TAPTURE_KEY_ALIAS`
- `TAPTURE_KEY_PASSWORD`

`key.properties` and every `*.jks` / `*.keystore` are gitignored. A release build with none of these set is signed with the debug key so a local install can still be produced. A store build sets the four values above and is signed with that key.

## How the key reaches the pipeline

Store the four values as GitHub Actions secrets with the same names. The release job passes them into the environment for the build command and nowhere else. They are not written into the app, the backend, or a log.

## Rotation

Create a new keystore, replace the four secrets, and ship the next release with the new key. Keep the previous keystore only as long as an update must still be signed by the old key. Do not commit either file.
