# 233 — Treat imported text as data

**Phase** 22 · Privacy and security  |  **Depends on** [015](../01-orchestration/015-logging-checker.md), [149](../13-processing/149-extraction-request.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A wrapper type that makes it impossible to interpolate OCR output, transcripts, imported cells, bundle content or file
names into an instruction, a query or a path. Such text travels as a delimited data block and is escaped where it is
rendered.

## Files

- `frontend/lib/core/security/untrusted_text.dart` (new)

## Contract

```dart
class UntrustedText {
  const UntrustedText(this.raw);
  final String raw;
  String asDataBlock(String label);
  String forDisplay();
  String forFileName();
}
```

## Steps

1. Wrap at the boundary: the OCR reader, transcript writer, spreadsheet importer, bundle reader and file scanner all
   return `UntrustedText`, so a raw `String` from those sources cannot reach a request builder.
2. Change the extraction request (274) to accept `UntrustedText` for these fields and emit them only inside a labelled,
   delimiter-escaped data block.
3. `forDisplay` escapes for rendering; `forFileName` transliterates to ASCII and strips separators and traversal
   sequences. Neither rewrites `raw`, which stays the stored evidence.

## Constraints

- No sanitising in place: the record keeps the text exactly as captured (FE-SEC-08, FE-L10N-11).
- No query, prompt, path or shell argument is built by concatenation anywhere in the app (FE-SEC-05).

## Definition of done

- [ ] A crafted caption cannot change what the provider is asked to do, and still appears verbatim on the record.
- [ ] Passing a plain `String` from OCR, import or bundle content into the request builder fails to compile.
- [ ] Tests: fixture cases for an instruction-shaped caption, a delimiter-closing caption, an SQL fragment and a
      traversal file name, each asserting the composed request structure, the rendered widget and the written filename
      are unaffected.
