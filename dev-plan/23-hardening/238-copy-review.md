# 238 — Copy pass and localisation scaffolding

**Phase** 23 · Hardening  |  **Depends on** [040](../03-design-system/040-app-empty-state.md), [046](../03-design-system/046-copy-helper.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One pass over every user-facing string for plain language and one voice, then all of them extracted into ARB files and
verified against a pseudo-locale. Nothing is translated yet; nothing needs a code change when it is.

## Files

- `frontend/lib/core/copy/copy.dart` (edit)
- `frontend/lib/l10n/` (new)

## Steps

1. Replace jargon, and make every error state (069) say what happened and what to do next, in the same voice
   everywhere (FE-SIMP-10, FE-CONS-11).
2. Move every visible literal out of widgets into the generated localisations behind the copy helper (081); keys name
   meaning, not position (FE-L10N-01, FE-L10N-02).
3. Use placeholders with descriptions and ICU plurals and selects; never assemble a sentence from fragments
   (FE-L10N-03).
4. Run the pseudo-locale, expanded 35 percent, through the responsive matrix and fix the layouts it breaks
   (FE-L10N-06).

## Constraints

- Template field labels, option lists and template names are user data and are never localised or matched against a
  translation (FE-L10N-07).
- A key without a translation fails the release build rather than reaching a user (FE-L10N-09).
- Dates, numbers and percentages come from `intl` with the active locale, never hand-built (FE-L10N-04).

## Definition of done

- [ ] No message contains a technical term the user cannot act on, and no user-facing literal remains in a widget.
- [ ] Adding a language later requires no code change, and switching locale rebuilds the interface without losing an
      in-progress capture (FE-L10N-10).
- [ ] Tests: a scanner test failing on a string literal in a widget file; an ARB completeness test failing on a key
      missing from a locale; a pseudo-locale layout run over the primary screens.
