# 071 — Imported file validation

**Phase** 05 · File storage  |  **Depends on** [015](../01-orchestration/015-logging-checker.md), [021](../02-foundation/021-result-and-failures.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One gate every file from outside the app passes before a byte of it is parsed: extension, magic bytes, declared size and
archive structure, each refusal naming what was wrong in plain language.

## Files

- `frontend/lib/core/files/file_validation.dart` (new)

## Contract

```dart
enum ImportKind { image, document, spreadsheet, audio, bundle }

abstract interface class FileValidation {
  Future<Result<ImportKind>> validate(File file, {Set<ImportKind> allowed});
  Future<Result<void>> validateArchive(File archive);
}
```

## Steps

1. Check the extension against the allow-list, then sniff magic bytes and reject any file whose content contradicts its
   name.
2. Enforce per-kind size ceilings from `AppConstants` before reading further, reading only the header for the sniff.
3. For archives, walk entries and reject any that escapes the extraction root, is absolute, is a symlink, or whose
   declared uncompressed total exceeds the ceiling.
4. Return a typed `Failure` naming the file and the reason; treat the file name itself as data when rendering it.

## Constraints

- Validation happens before parsing, never during it, and nothing partially validated reaches a parser (FE-SEC-06).
- File names, cell text and archive entry names are quoted as data — never interpolated into a query, a shell command or
  a provider instruction, and escaped where rendered (FE-SEC-05).
- Sniffing reads a bounded header, not the whole file (FE-PERF-07).

## Definition of done

- [x] A `.xlsx` that is really an executable, an oversized image and a zip with a `../` entry are each refused with a
      message naming the reason.
- [x] A valid file of each supported kind passes and reports its kind.
- [x] No rejected file is ever opened by a parser, and none leaves a copy behind.
- [x] Tests: `frontend/test/core/files/file_validation_test.dart` runs crafted inputs — mismatched magic bytes, empty
      file, oversized file, traversal zip, symlink entry, zip bomb declaration — and asserts one refusal each plus the
      passing cases.
