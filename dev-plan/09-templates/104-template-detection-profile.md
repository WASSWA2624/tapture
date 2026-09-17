# 104 — Detection profile editor

**Phase** 09 · Templates  |  **Depends on** [088](088-template-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The per-template detection profile that decides how a photo is matched to a template, and the screen that edits it:
object classes, keywords, identifier patterns, linked datasets and negative keywords.

## Files

- `frontend/lib/features/templates/presentation/detection_profile_screen.dart` (new)

## Steps

1. Every template carries a profile. A shipped template arrives with one; a blank template gets an empty profile it
   still works without.
2. Negative keywords exclude a template that would otherwise match, so two similar templates can be told apart.
3. Identifier patterns reuse the validation patterns a field already declares rather than restating them.

## Constraints

- Keywords and patterns are template content stored as user data, not localisation keys (FE-L10N-07).

## Definition of done

- [ ] Every template carries a profile, with sensible defaults for shipped ones and a working empty one for blanks.
- [ ] A negative keyword demotes a template that the positive keywords would have matched.
- [ ] Tests: widget test of `detection_profile_screen.dart` covering empty and failure states; unit test that a negative keyword excludes an otherwise-matching profile.
