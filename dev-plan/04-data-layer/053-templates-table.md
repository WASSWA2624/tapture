# 053 — Templates, template fields and template rows tables

**Phase** 04 · Local database  |  **Depends on** [052](052-projects-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole template definition in one schema: the template header with its source and version, the field definitions the
capture and export engines read, and the predefined checklist rows with their aliases.

## Files

- `frontend/lib/core/db/tables/templates.dart` (new)
- `frontend/lib/core/db/tables/template_fields.dart` (new)
- `frontend/lib/core/db/tables/template_rows.dart` (new)

## Steps

1. Templates: `projectId` nullable so shipped entries are project-free, `name`, `kind`, `source`, `sourceFilePath`,
   `sheetName`, `headerRow`, `identityFields`, `detection`, `version`.
2. Template fields: `templateId`, `fieldKey`, `label`, `type`, `outputColumn`, `required`, `inputMode`, `stickable`,
   `contextLevel`, `autoFill`, `defaultValue`, `options`, `unit`, `validation`, `lookup`, `refine`, `sortOrder`.
3. Unique index on `templateId` plus `fieldKey`; read order is `sortOrder` then `label`.
4. Template rows: `templateId`, `outputRowNumber`, `identifier`, `label`, `aliases`, `metadata`, `foundStatus`; index on
   `templateId` plus `identifier`.
5. Store `options`, `validation`, `lookup`, `aliases` and `metadata` as JSON validated on write.

## Constraints

- All three tables declare the shared merge columns through `MergeColumns` in the migration that creates them; two
  devices editing the same template merge field by field on `rev` (FE-SEC-09).
- Editing a template bumps `version` on the header rather than rewriting history: records keep the version they were
  captured against.
- Imported sheet names, headers and cell text are stored as data, never interpolated into a query or a provider
  instruction (FE-SEC-05).

## Definition of done

- [ ] A template with fields and rows round-trips, and a duplicate `fieldKey` within one template is refused by the
      unique index rather than by application code.
- [ ] A shipped template with no `projectId` coexists with project-scoped templates.
- [ ] Tests: `frontend/test/core/db/tables/templates_test.dart` covers header insert, version bump and the shipped case;
      `template_fields_test.dart` asserts the unique constraint and sort order; `template_rows_test.dart` covers alias
      lookup. All against an in-memory database, covering their migration steps.
