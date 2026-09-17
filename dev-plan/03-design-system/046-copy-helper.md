# 046 — User-facing copy helper

**Phase** 03 · Design system  |  **Depends on** [011](../01-orchestration/011-naming-checker.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One place every visible string in the catalogue comes from, keyed by meaning and shaped so translation can arrive later
without touching a widget.

## Files

- `frontend/lib/core/copy/copy.dart` (edit)

## Contract

```dart
abstract final class Copy {
  static String get notDetected;
  static String recordsCount(int n);
}
```

## Steps

1. Key by meaning, never by position: `captureSaveRaw`, not `screen3Button2`.
2. Use placeholders and ICU plurals for anything with a count; never build a sentence by concatenation.
3. Prefer a stated absence to a blank: "Not detected" rather than an empty string or `null`.

## Constraints

- No user-facing literal remains in a catalogue widget (FE-L10N-01, FE-L10N-02, FE-L10N-03).
- The same word for the same concept as `lib/core/naming/domain_names.dart` uses — record, capture, context, template,
  bundle, merge, refine; a synonym fails the naming checker (FE-CONS-07).
- Template field labels, option lists and template names are user data and never pass through here (FE-L10N-07).

## Definition of done

- [ ] No inline user-facing string remains in any `core/widgets/` file.
- [ ] A count reads correctly at zero, one and many.
- [ ] Tests: unit tests of the plural forms at 0, 1 and 2, and a test asserting no `Copy` value uses a synonym the
      naming checker rejects.
