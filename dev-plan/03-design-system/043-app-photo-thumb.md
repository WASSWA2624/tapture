# 043 — Photo thumbnail

**Phase** 03 · Design system  |  **Depends on** [030](030-color-tokens.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one square thumbnail every photo in the app renders through: type badge, caption indicator, selection state and an
error placeholder for a missing or unreadable file, loaded from the cached thumbnail rather than the original.

## Files

- `frontend/lib/core/widgets/app_photo_thumb.dart` (new)

## Contract

```dart
class AppPhotoThumb extends StatelessWidget {
  final PhotoAsset photo; final double size; final bool selected; final VoidCallback? onTap, onLongPress;
}
```

## Steps

1. Resolve the cached thumbnail path for the requested size; never decode a full image to draw a thumbnail.
2. Show the type badge and caption indicator as overlays that do not obscure the subject, and a placeholder when the
   file is missing rather than an exception.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- Gallery entry covering badge, caption, selected, unselected and error states, plus goldens in light, dark and outdoor
  (FE-CONS-03).
- Thumbnails are cached by hash and size with a cap on concurrent decodes; decoding a full photo for a 96dp square is
  a defect (FE-PERF-04).
- Sizing uses aspect ratio and `BoxFit`, never fixed pixel dimensions (FE-RESP-09).

## Definition of done

- [x] Every photo in the app renders through this widget (FE-CONS-06).
- [x] Scrolling a tray of thirty photos stays smooth, and a missing file shows a placeholder instead of throwing.
- [x] Tests: goldens of badge, caption, selection and error states in light, dark and outdoor; widget test asserting the
      full-size image is never decoded; widget test of the missing-file path.
