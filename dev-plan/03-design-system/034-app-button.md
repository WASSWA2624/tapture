# 034 — Buttons, icon buttons and the primary action

**Phase** 03 · Design system  |  **Depends on** [030](030-color-tokens.md), [031](031-theme-assembly.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole button vocabulary: one variant-driven button with loading and disabled states, an icon-only action that
cannot be built without a label, and the large thumb-reachable primary action capture and review both use. After this
task no feature constructs a Material button.

## Files

- `frontend/lib/core/widgets/app_button.dart` (new)
- `frontend/lib/core/widgets/app_icon_button.dart` (new)
- `frontend/lib/core/widgets/app_primary_action.dart` (new)

## Contract

```dart
enum AppButtonVariant { primary, secondary, text, destructive }
class AppButton extends StatelessWidget {
  final String label; final VoidCallback? onPressed; final AppButtonVariant variant;
  final bool busy; final IconData? icon;
}
class AppIconButton extends StatelessWidget {
  final IconData icon; final String semanticLabel; final String tooltip; final VoidCallback? onPressed;
}
class AppPrimaryAction extends StatelessWidget {
  final String label; final String? caption; final VoidCallback? onPressed; final bool busy;
}
```

## Steps

1. `AppButton`: render all four variants from tokens, show an inline spinner while `busy`, and swallow taps while busy
   so a double submission is impossible.
2. `AppIconButton`: make `semanticLabel` and `tooltip` required constructor arguments, so an unlabelled icon button
   cannot compile.
3. `AppPrimaryAction`: full width, tall, with an optional caption line under the label and its own busy state.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; 48dp minimum target and a semantic label on every
  interactive element; nothing clips at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- Each of the three gets a gallery entry covering every variant and state, and goldens in light, dark and outdoor
  (FE-CONS-03).
- The primary action sits within thumb reach on a large phone and is glove-friendly (FE-A11Y-09).

## Definition of done

- [x] No feature constructs an `ElevatedButton`, `TextButton`, `OutlinedButton` or `IconButton` directly.
- [x] A busy button ignores taps; an icon button without a semantic label fails to compile.
- [x] Capture and review use the identical primary action control.
- [x] Tests: goldens per variant and state in light, dark and outdoor; widget test that a busy button swallows taps;
      widget test asserting all three controls satisfy the 48dp accessibility matcher.
