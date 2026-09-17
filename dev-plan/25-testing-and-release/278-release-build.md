# 278 — Release build configuration

**Phase** 25 · Testing and release  |  **Depends on** [242](../23-hardening/242-branding-assets.md), [277](277-ci-pipeline.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A signed, shrunk, split-ABI release variant produced by one documented command, with the signing key supplied from the
environment and no keystore in the repository.

## Files

- `frontend/android/app/build.gradle` (edit)
- `frontend/android/key.properties.example` (new)
- `frontend/docs/release-build.md` (new)

## Steps

1. Configure the release variant: signing config read from `key.properties` or environment variables, resource and code
   shrinking on, and per-ABI splits.
2. Document the signing key handling in `frontend/docs/release-build.md` — where the keystore lives, how it reaches the
   pipeline, how it is rotated. Never commit a keystore or a password.
3. Name the single build command in that document and use the same one in the pipeline.

## Constraints

- Credentials come from secure storage or the environment, never the repository or the built artefact (FE-SEC-01).
- The build is reproducible: same commit and same key produce the same artefact set.

## Definition of done

- [ ] A release build is produced from one documented command, signed, shrunk and split by ABI.
- [ ] A missing signing key fails the build with a clear message rather than falling back to a debug key.
- [ ] Tests: `frontend/test/tool/release_build_config_test.dart` parses `build.gradle` and asserts shrinking, splits and
      an environment-sourced signing config, and asserts no keystore, password or key alias is committed anywhere.
