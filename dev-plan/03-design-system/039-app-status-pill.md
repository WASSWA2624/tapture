# 039 — Status pill and badge

**Phase** 03 · Design system  |  **Depends on** [030](030-color-tokens.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every record and job status rendered one way — colour plus icon plus text — with a single mapping from `RecordStatus`
that no screen may bypass or extend.

## Files

- `frontend/lib/core/widgets/app_status_pill.dart` (new)

## Contract

```dart
class AppStatusPill extends StatelessWidget { final RecordStatus status; }
abstract final class StatusStyle { static (Color, IconData, String) of(RecordStatus s); }
```

## Steps

1. Map every value in the record lifecycle to a colour, an icon and a label; an unmapped status is a compile error, not
   a blank pill.
2. Provide the compact badge form for use inside `AppListTile` trailing slots.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; nothing clips at 200 percent text scale (FE-THEME-01,
  FE-A11Y-03).
- Gallery entry showing every status, plus goldens in light, dark and outdoor (FE-CONS-03).
- Colour is never the only signal: icon and text always accompany it (FE-THEME-05, FE-A11Y-05).
- Status labels come from the copy helper and the shared vocabulary, not invented per screen (FE-CONS-07).

## Definition of done

- [ ] A colour-blind user in direct sunlight can still read the status.
- [ ] Every status in the app renders through this widget; no screen maps status to colour itself.
- [ ] Tests: golden of every `RecordStatus` in light, dark and outdoor; unit test that `StatusStyle.of` is exhaustive
      over the enum.
