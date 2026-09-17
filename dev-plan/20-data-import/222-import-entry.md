# 222 — Import entry point and purpose step

**Phase** 20 · Data import  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [071](../05-file-storage/071-file-validation.md), [176](../15-data-quality/176-verification-mode.md), [221](221-import-records-create.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One place to bring anything in — bundle, spreadsheet, reference dataset or template. The entry detects the file kind and
routes to the right flow, and for spreadsheets it asks the one question that changes everything downstream: are these
rows records to hold, or the register to verify against?

## Files

- `frontend/lib/features/import/presentation/import_screen.dart` (new)
- `frontend/lib/features/import/presentation/import_purpose_step.dart` (new)

## Steps

1. Detect the kind from the validated file of 126, never from the extension alone, and explain each destination in one
   line.
2. Ask the purpose only for spreadsheets; a bundle and a template have no ambiguity to resolve.
3. Choosing register feeds the rows to the verification prefill of 330 instead of creating records.

## Constraints

- One decision per step (FE-SIMP-07); a detected kind is applied rather than asked about (FE-SIMP-05).
- The chosen file is untrusted until validated, and its text is data, never instruction (FE-SEC-05, FE-SEC-06).

## Definition of done

- [ ] A user never has to know which importer to pick; each supported kind reaches its flow from this one screen.
- [ ] An unsupported or corrupt file is refused here with a reason, before any flow starts.
- [ ] After a register import, the verification flow works immediately with those rows.
- [ ] Tests: widget tests of `import_screen.dart` over each detected kind, an unsupported file and the four states, and of `import_purpose_step.dart` asserting both destinations.
