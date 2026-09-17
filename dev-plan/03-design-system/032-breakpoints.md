# 032 — Breakpoints, responsive builder and readable width

**Phase** 03 · Design system  |  **Depends on** [013](../01-orchestration/013-design-token-test.md), [030](030-color-tokens.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one definition of the three size classes, a builder that gives each class its own layout without duplicating
widgets, and a constraint that caps and centres readable content. After this task no feature reads a screen width.

## Files

- `frontend/lib/core/widgets/responsive/breakpoints.dart` (new)
- `frontend/lib/core/widgets/responsive/responsive_builder.dart` (new)
- `frontend/lib/core/widgets/responsive/content_constraint.dart` (new)

## Contract

```dart
enum SizeClass { compact, medium, expanded }
extension SizeClassX on BuildContext {
  SizeClass get sizeClass;
  T responsive<T>({required T compact, T? medium, T? expanded});
}
class ResponsiveBuilder extends StatelessWidget { final WidgetBuilder compact; final WidgetBuilder? medium, expanded; }
class ContentConstraint extends StatelessWidget { final Widget child; final double maxWidth; }
```

## Steps

1. Define compact below 600dp, medium 600–1023dp and expanded 1024dp and above; `SizeClass` is the only place those
   numbers exist.
2. `responsive<T>` and `ResponsiveBuilder` both fall back to the next smaller value or builder when one is not given.
3. `ContentConstraint` centres its child at a default maximum readable width, overridable per screen.

## Constraints

- These three files are the only place a `MediaQuery` width is read; features ask for a value per size class or use
  `ResponsiveBuilder` (FE-RESP-01, FE-RESP-02).
- Changing size class must not lose in-progress input or navigation state (FE-RESP-03).
- `ContentConstraint` gets a gallery entry and goldens in light, dark and outdoor; the helpers are exercised at all
  three widths (FE-CONS-03, FE-RESP-10).

## Definition of done

- [ ] No widget outside `core/widgets/responsive/` compares a `MediaQuery` width.
- [ ] A two-pane layout becomes a one-line change in a screen.
- [ ] Text and forms stay centred and capped on expanded rather than stretching edge to edge.
- [ ] Tests: unit test of size-class resolution at 599, 600, 1023 and 1024dp; widget test of `ResponsiveBuilder`
      fallback at three widths; goldens of `ContentConstraint` in light, dark and outdoor.

## Out of scope

- Adaptive navigation (bottom bar, rail, rail plus pane); that belongs to the navigation phase.
