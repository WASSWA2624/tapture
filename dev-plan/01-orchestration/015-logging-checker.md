# 015 — Logging discipline and secret scan

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two source scanners sharing one pattern file: `check_logging.dart` bans `print` and the logging of forbidden values,
`check_secrets.dart` fails when a key, token or credential appears anywhere in the repository, and
`secret_patterns.yaml` is the single definition both read.

## Files

- `frontend/tool/check_logging.dart` (new)
- `frontend/tool/check_secrets.dart` (new)
- `frontend/tool/secret_patterns.yaml` (new)

## Contract

```dart
// frontend/tool/check_logging.dart
Future<int> main(List<String> args);
// frontend/tool/check_secrets.dart — patterns loaded from frontend/tool/secret_patterns.yaml
Future<int> main(List<String> args);
```

## Steps

1. Fail on any `print(` or `debugPrint(` outside `frontend/tool/` and `frontend/test/`.
2. Fail when a log call interpolates an identifier matching key, secret, token, password, credential, caption, transcript or value.
3. Require every log call to pass a level and a tag.
4. Define, in `secret_patterns.yaml`, named patterns for provider keys, bearer tokens, private keys, connection strings and long base64 blobs; this file is also what the logger's redaction and the log-export test read.
5. Scan `frontend/lib/`, `frontend/android/`, `frontend/ios/` and the asset files; allow documented placeholders in test fixtures only.
6. Report file, line and the matched pattern name without echoing the matched value.

## Constraints

- `print` and `debugPrint` do not exist in `lib/`; every log call carries a level and a tag and never logs a key, token, caption, transcript, field value or file content (FE-CODE-08).
- Keys and credentials belong in platform secure storage and nowhere else — not the database, logs, exports, bundles or preferences (FE-SEC-01).
- Nothing ships with a provider key compiled in, so a match in `lib/`, a Gradle file or an asset is a failure, not a warning (FE-SEC-02).

## Definition of done

- [ ] Logging an API key variable fails `check_logging.dart` with the file and line; a log call missing a level or a tag fails too.
- [ ] A pasted provider key in a Dart file, a Gradle file or an asset fails `check_secrets.dart`, and neither checker ever prints the matched value.
- [ ] Every pattern in `secret_patterns.yaml` is named, so a violation report is readable without opening the file.
- [ ] Tests: `frontend/test/tool/check_logging_test.dart` covers each banned pattern; `frontend/test/tool/check_secrets_test.dart` covers one fixture per pattern plus an allowed placeholder fixture.
