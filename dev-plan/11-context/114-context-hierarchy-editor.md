# 114 — Define the context hierarchy

**Phase** 11 · Context  |  **Depends on** [094](../09-templates/094-field-list-editor.md), [113](113-context-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A screen where a project's context levels are chosen from the template's field keys and ordered by drag. Zero levels
is a valid configuration and leaves the rest of the feature dormant.

## Files

- `frontend/lib/features/context/presentation/context_hierarchy_screen.dart` (new)

## Steps

1. Offer the template's field keys from the field list editor (162); a key already used as a level is not offered twice.
2. Drag to order; each level binds exactly one field key.
3. Persist the hierarchy through `ContextRepository` on each change, and allow removing every level.

## Constraints

- Level names are template content, not interface text, and are never sent to the localisation catalogue (FE-L10N-07).
- Reordering uses the design system's reorderable list; no bespoke drag affordance (FE-CONS-01).

## Definition of done

- [ ] A project with no hierarchy shows no context bar anywhere and behaves as if the feature were absent.
- [ ] Reordering or removing a level persists immediately and survives leaving the screen.
- [ ] Tests: widget test of `context_hierarchy_screen.dart` covering zero levels, a three-level hierarchy, reorder persistence and a repository write failure.
